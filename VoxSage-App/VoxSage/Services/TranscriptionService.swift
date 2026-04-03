import Foundation
import AppKit
import Speech
import AVFoundation
import Combine

enum RecordingState {
    case idle, recording, paused
}

class TranscriptionService: ObservableObject {
    @Published var state: RecordingState = .idle
    @Published var completedSegments: [String] = []
    @Published var activeSegment: String = ""
    @Published var isDialogMode: Bool = false
    @Published var openSettingsOnShow: Bool = false
    weak var dialogWindow: NSWindow?    // 对话浮窗引用
    weak var meetingWindow: NSWindow?   // 会议窗口引用

    var fullTranscript: String {
        (completedSegments + (activeSegment.isEmpty ? [] : [activeSegment]))
            .joined(separator: " ")
    }

    private var recognizer: SFSpeechRecognizer?
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // 每次启动新 session 递增，回调通过对比代数来判断自己是否已过期
    private var sessionGeneration = 0

    var onTranscript: ((String) -> Void)?
    // 每次 segment 提交（timeout 续录 / 暂停 / 停止）时触发，会议模式用它自动存档
    var onSegmentCommitted: ((String) -> Void)?
    private var mcpProcess: Process?

    // 会议模式录音文件（每次会议独立一个 WAV）
    private var meetingAudioFile: AVAudioFile?
    /// 最近一次会议录音的本地路径，会后用于说话人识别
    @Published var lastMeetingAudioPath: URL?

    init() {
        setupRecognizer()
        startMCPServer()
    }

    // ── 公开 API ──────────────────────────────────────────

    private func setupRecognizer() {
        let lang = UserDefaults.standard.string(forKey: "recognitionLanguage") ?? "auto"
        switch lang {
        case "zh":
            recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        case "en":
            recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        default:  // auto：优先中文，fallback 英文
            recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
                ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        }
    }

    // 语言设置变更后调用，下一次录音生效
    func updateLanguage() { setupRecognizer() }

    func requestPermissions() async -> Bool {
        await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
    }

    // 开始新录音（清空历史）
    func startListening() {
        guard state == .idle else { return }
        completedSegments = []
        activeSegment = ""
        lastMeetingAudioPath = nil
        state = .recording
        do { try startAudioSession() } catch { state = .idle }
    }

    // 会议模式专用：开始新会议录音，创建独立的 WAV 文件
    func startMeetingListening() {
        guard state == .idle else { return }
        completedSegments = []
        activeSegment = ""
        // 在临时目录创建唯一的 WAV 文件
        let fileName = "voxsage_meeting_\(Int(Date().timeIntervalSince1970)).wav"
        lastMeetingAudioPath = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)
        state = .recording
        do { try startAudioSession() } catch {
            lastMeetingAudioPath = nil
            state = .idle
        }
    }

    // 暂停
    func pauseListening() {
        guard state == .recording else { return }
        commitActiveSegment()
        stopAudioEngine()
        state = .paused
    }

    // 继续
    func resumeListening() {
        guard state == .paused else { return }
        activeSegment = ""
        state = .recording
        do { try startAudioSession() } catch { state = .paused }
    }

    // 完全停止（供会议模式使用）—— 先提交当前活跃段再停
    func stopListening() {
        commitActiveSegment()
        stopAudioEngine()
        closeMeetingAudioFile()   // 停止后才关闭音频文件
        state = .idle
    }

    // 清空文字并重启 session（generation 递增，旧回调自动失效）
    func clearTranscript() {
        completedSegments = []
        activeSegment = ""
        lastMeetingAudioPath = nil
        guard state == .recording else { return }
        closeMeetingAudioFile()
        sessionGeneration += 1      // 使所有旧回调立刻失效
        stopAudioEngine()
        try? startAudioSession()    // 启动全新 session，代数已更新
    }

    // 复制到剪贴板
    func copyTranscript() {
        let text = fullTranscript
        guard !text.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        onTranscript?(text)
    }

    // ── 内部 ──────────────────────────────────────────────

    private func commitActiveSegment() {
        let seg = activeSegment.trimmingCharacters(in: .whitespacesAndNewlines)
        if !seg.isEmpty {
            completedSegments.append(seg)
            onSegmentCommitted?(seg)    // 通知会议模式保存
        }
        activeSegment = ""
    }

    private func stopAudioEngine() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        // 注意：不在这里关闭 meetingAudioFile，让 session 重启时继续写同一文件
        // meetingAudioFile 只在 stopListening() / clearTranscript() 中关闭
    }

    private func closeMeetingAudioFile() {
        meetingAudioFile = nil   // AVAudioFile deinit 时自动 flush 并关闭
    }

    private func startAudioSession() throws {
        let generation = sessionGeneration

        let req = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest = req
        req.shouldReportPartialResults = true
        if #available(macOS 13, *) { req.addsPunctuation = true }

        let inputNode = audioEngine.inputNode
        let fmt = inputNode.outputFormat(forBus: 0)

        // 会议模式：若有录音文件路径则创建 AVAudioFile 准备写入
        if !isDialogMode, let audioURL = lastMeetingAudioPath, meetingAudioFile == nil {
            meetingAudioFile = try? AVAudioFile(forWriting: audioURL, settings: fmt.settings)
        }

        // 会议模式静音检测：从设置读取静音时长，换算成 buffer 数
        // ~43 buffers/sec（44100Hz / 1024）
        var silenceCount = 0
        let silenceSec = Double(UserDefaults.standard.string(forKey: "silenceDuration") ?? "1.5") ?? 1.5
        let silenceLimit = max(20, Int(silenceSec * 43.0))
        let silenceThresholdDB: Float = -40.0

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: fmt) { [weak self] buf, _ in
            req.append(buf)
            // 会议模式：同步写入音频文件（用于会后说话人识别）
            if let self, !self.isDialogMode {
                try? self.meetingAudioFile?.write(from: buf)
            }

            // 对话模式不需要静音分段
            guard let self, !self.isDialogMode else { return }

            // 计算当前 buffer 的 RMS 音量（dB）
            let level = buf.rmsLevelDB()

            if level < silenceThresholdDB {
                silenceCount += 1
                // 达到静音阈值且有待提交内容 → 触发分段
                if silenceCount >= silenceLimit &&
                   !self.activeSegment.trimmingCharacters(in: .whitespaces).isEmpty {
                    silenceCount = 0
                    DispatchQueue.main.async { [weak self] in
                        guard let self,
                              generation == self.sessionGeneration,
                              self.state == .recording,
                              !self.activeSegment.trimmingCharacters(in: .whitespaces).isEmpty
                        else { return }
                        self.sessionGeneration += 1
                        self.commitActiveSegment()
                        self.stopAudioEngine()
                        try? self.startAudioSession()
                    }
                }
            } else {
                silenceCount = 0  // 有声音，重置计数
            }
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = recognizer?.recognitionTask(with: req) { [weak self] result, error in
            guard let self else { return }
            guard generation == self.sessionGeneration else { return }

            if let r = result {
                DispatchQueue.main.async {
                    guard generation == self.sessionGeneration else { return }
                    self.activeSegment = r.bestTranscription.formattedString
                }
            }

            // 识别器超时自然结束 → 提交当前段，重启新段（连续录音）
            if error != nil, self.state == .recording {
                DispatchQueue.main.async {
                    guard generation == self.sessionGeneration,
                          self.state == .recording else { return }
                    self.sessionGeneration += 1
                    self.commitActiveSegment()
                    self.stopAudioEngine()
                    try? self.startAudioSession()
                }
            }
        }
    }

    // ── MCP Server ────────────────────────────────────────

    func startMCPServer() {
        guard let root = findProjectRoot() else { return }
        let venv   = root.appendingPathComponent("venv/bin/python3.13")
        let server = root.appendingPathComponent("src/mcp/server.py")
        guard FileManager.default.fileExists(atPath: venv.path),
              FileManager.default.fileExists(atPath: server.path) else { return }
        let proc = Process()
        proc.executableURL  = venv
        proc.arguments      = [server.path]
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError  = FileHandle.nullDevice
        try? proc.run()
        mcpProcess = proc
    }

    var projectRoot: URL? { findProjectRoot() }

    func findProjectRoot() -> URL? {
        // 1. 先从 bundle 路径往上遍历（适用于 app 在项目目录内的打包场景）
        var url = Bundle.main.bundleURL
        for _ in 0..<10 {
            url = url.deletingLastPathComponent()
            if FileManager.default.fileExists(atPath:
                url.appendingPathComponent("src/mcp/server.py").path) { return url }
        }
        // 2. Xcode Debug 模式：bundle 在 DerivedData，改从已知开发路径找
        let devPath = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Program file/🔬 AI 探索/VoxSage")
        if FileManager.default.fileExists(atPath:
            devPath.appendingPathComponent("src/mcp/server.py").path) { return devPath }
        return nil
    }

    deinit {
        stopAudioEngine()
        mcpProcess?.terminate()
    }
}

// ── AVAudioPCMBuffer RMS 计算 ─────────────────────────────

private extension AVAudioPCMBuffer {
    /// 返回当前 buffer 的 RMS 音量（dB），无声时返回 -160
    func rmsLevelDB() -> Float {
        guard let data = floatChannelData?[0] else { return -160 }
        let count = Int(frameLength)
        guard count > 0 else { return -160 }
        var sum: Float = 0
        for i in 0..<count { sum += data[i] * data[i] }
        let rms = sqrt(sum / Float(count))
        return rms > 0 ? 20 * log10(rms) : -160
    }
}
