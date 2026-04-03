import Foundation
import Combine

// 单条转录记录
struct TranscriptSegment: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let speaker: String      // "说话人 1" / "说话人 2" / ""
    let text: String

    init(speaker: String = "", text: String) {
        self.id        = UUID()
        self.timestamp = Date()
        self.speaker   = speaker
        self.text      = text
    }

    init(id: UUID, timestamp: Date, speaker: String, text: String) {
        self.id        = id
        self.timestamp = timestamp
        self.speaker   = speaker
        self.text      = text
    }
}

// 一次会议
struct Meeting: Identifiable, Codable {
    let id: UUID
    var title: String
    let startTime: Date
    var endTime: Date?
    var segments: [TranscriptSegment]
    var audioPath: String?   // 录音文件路径，用于重新触发说话人识别

    init(title: String = "") {
        self.id        = UUID()
        self.startTime = Date()
        self.title     = title.isEmpty ? Meeting.defaultTitle() : title
        self.segments  = []
    }

    static func defaultTitle() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MM月dd日 HH:mm"
        return "会议 \(fmt.string(from: Date()))"
    }

    var duration: String {
        let end = endTime ?? Date()
        let secs = Int(end.timeIntervalSince(startTime))
        return String(format: "%02d:%02d", secs / 60, secs % 60)
    }

    var fullTranscript: String {
        segments.map { seg in
            let t = DateFormatter.localizedString(from: seg.timestamp,
                                                   dateStyle: .none,
                                                   timeStyle: .medium)
            return seg.speaker.isEmpty
                ? "[\(t)] \(seg.text)"
                : "[\(t)] \(seg.speaker)：\(seg.text)"
        }.joined(separator: "\n")
    }
}

// 全局会议数据
class MeetingStore: ObservableObject {
    @Published var meetings: [Meeting] = []
    @Published var selectedID: UUID?
    @Published var diarizingMeetingID: UUID? = nil   // 正在处理说话人识别的会议
    @Published var diarizationError: String? = nil    // 说话人识别错误信息
    @Published var renamingID: UUID? = nil            // 正在重命名的会议（nil = 不在重命名状态）
    private var diarizationProcess: Process? = nil   // 当前识别进程，防止重复启动

    private let saveURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory,
                                           in: .userDomainMask).first!
            .appendingPathComponent("VoxAI", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir,
                                                  withIntermediateDirectories: true)
        return dir.appendingPathComponent("meetings.json")
    }()

    init() { load() }

    var selected: Meeting? {
        guard let id = selectedID else { return nil }
        return meetings.first { $0.id == id }
    }

    func newMeeting(title: String = "") -> Meeting {
        let m = Meeting(title: title)
        meetings.insert(m, at: 0)
        selectedID = m.id
        save()
        return m
    }

    func appendSegment(_ seg: TranscriptSegment, to meetingID: UUID) {
        guard let idx = meetings.firstIndex(where: { $0.id == meetingID }) else { return }
        meetings[idx].segments.append(seg)
        save()
    }

    func endMeeting(_ id: UUID) {
        guard let idx = meetings.firstIndex(where: { $0.id == id }) else { return }
        meetings[idx].endTime = Date()
        save()
    }

    func setAudioPath(_ id: UUID, path: String) {
        guard let idx = meetings.firstIndex(where: { $0.id == id }) else { return }
        meetings[idx].audioPath = path
        save()
    }

    // 说话人识别完成后，用带标签的段替换原始段
    func replaceSegments(_ segments: [TranscriptSegment], in meetingID: UUID) {
        guard let idx = meetings.firstIndex(where: { $0.id == meetingID }) else { return }
        meetings[idx].segments = segments
        save()
    }

    /// 批量重命名同一会议内所有相同说话人标签
    func renameSpeaker(in meetingID: UUID, from oldName: String, to newName: String) {
        guard let idx = meetings.firstIndex(where: { $0.id == meetingID }) else { return }
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != oldName else { return }
        meetings[idx].segments = meetings[idx].segments.map { seg in
            seg.speaker == oldName
                ? TranscriptSegment(id: seg.id, timestamp: seg.timestamp,
                                    speaker: trimmed, text: seg.text)
                : seg
        }
        save()
    }

    // 会后说话人识别：调用 diarize.py，结果替换原始段落
    func runDiarization(audioPath: URL, meetingID: UUID, projectRoot: URL) {
        // 如果已有进程在跑，先 kill 掉，防止重复
        if let existing = diarizationProcess, existing.isRunning {
            existing.terminate()
        }
        diarizationProcess = nil

        let python = projectRoot.appendingPathComponent("venv/bin/python3.13")
        let script = projectRoot.appendingPathComponent("src/stt/diarize.py")
        let config = projectRoot.appendingPathComponent("config.json")

        guard FileManager.default.fileExists(atPath: python.path),
              FileManager.default.fileExists(atPath: script.path) else {
            diarizationError = "找不到 diarize.py 或 Python 环境"
            diarizingMeetingID = nil
            return
        }

        let proc = Process()
        diarizationProcess = proc
        proc.executableURL = python
        proc.arguments = [script.path, audioPath.path, config.path]

        let outPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError  = Pipe()

        proc.terminationHandler = { [weak self] _ in
            guard let self else { return }
            let data = outPipe.fileHandleForReading.readDataToEndOfFile()

            DispatchQueue.main.async {
                self.diarizationProcess = nil
                self.diarizingMeetingID = nil

                // 错误格式：{"error": "..."}
                if let errObj = try? JSONDecoder().decode([String: String].self, from: data),
                   let msg = errObj["error"] {
                    self.diarizationError = msg
                    return
                }

                // 成功格式：[{"speaker":..., "text":...}, ...]
                guard let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                    self.diarizationError = "说话人识别结果解析失败"
                    return
                }

                let newSegments = arr.compactMap { d -> TranscriptSegment? in
                    guard let text = d["text"] as? String, !text.isEmpty else { return nil }
                    let speaker = d["speaker"] as? String ?? ""
                    return TranscriptSegment(speaker: speaker, text: text)
                }

                if newSegments.isEmpty {
                    self.diarizationError = "识别结果为空，请检查音频是否包含语音"
                    return
                }

                self.replaceSegments(newSegments, in: meetingID)
            }
        }

        try? proc.run()
    }

    func renameMeeting(_ id: UUID, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let idx = meetings.firstIndex(where: { $0.id == id }) else { return }
        meetings[idx].title = trimmed
        save()
    }

    func deleteMeeting(_ id: UUID) {
        meetings.removeAll { $0.id == id }
        if selectedID == id { selectedID = meetings.first?.id }
        save()
    }

    func export(_ meeting: Meeting, format: ExportFormat) -> URL? {
        let content: String
        switch format {
        case .markdown:
            content = "# \(meeting.title)\n\n**时间**：\(meeting.startTime.formatted())\n\n---\n\n\(meeting.fullTranscript)"
        case .txt:
            content = "\(meeting.title)\n时间：\(meeting.startTime.formatted())\n\n\(meeting.fullTranscript)"
        }
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(meeting.title).\(format.ext)")
        try? content.write(to: tmp, atomically: true, encoding: .utf8)
        return tmp
    }

    private func save() {
        // 在后台线程编码+写入，避免阻塞主线程导致 UI 卡顿
        // meetings 是值类型（struct 数组），copy 到后台线程安全
        let snapshot = meetings
        let url = saveURL
        DispatchQueue.global(qos: .utility).async {
            try? JSONEncoder().encode(snapshot).write(to: url)
        }
    }
    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let saved = try? JSONDecoder().decode([Meeting].self, from: data)
        else { return }
        meetings  = saved
        selectedID = saved.first?.id
    }
}

enum ExportFormat {
    case markdown, txt
    var ext: String { self == .markdown ? "md" : "txt" }
}
