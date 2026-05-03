//
//  TranscriptionService.swift
//  VoxAI
//
//  Streaming speech-to-text built on SFSpeechRecognizer + AVAudioEngine.
//
//  Lineage:
//    Ported from VoxSage's TranscriptionService (the original full-feature
//    repo). The core "sessionGeneration" defensive-callback design is kept
//    intact; everything related to meeting mode, audio file recording,
//    Python MCP subprocess, and project-root discovery has been removed
//    because:
//      - VoxAI is App Store sandboxed (cannot spawn user-path processes)
//      - v1 deliberately does not ship meeting mode (DR-004)
//      - VoxAI's MCP server is a separate Swift service (Phase 2.5),
//        not a Python subprocess
//
//  Cross-architecture correctness fix (vs VoxSage):
//    VoxSage hard-coded `silenceLimit = Int(silenceSec * 43.0)` assuming
//    44100Hz / 1024 buffer. On Intel Macs the input format defaults can
//    differ (often 48000Hz), so the silence threshold drifted. v1 derives
//    `buffersPerSecond` from the actual `sampleRate / bufferSize`.
//
//  Threading model:
//    The class is @MainActor isolated. The AVAudioEngine tap callback
//    runs on a real-time audio thread; we keep all per-callback work in
//    captured locals (no `self` reads) and bounce back to the main actor
//    only when we need to mutate published state. This satisfies Swift 6
//    strict concurrency without locking.
//

import Foundation
import AppKit
import Speech
import AVFoundation
import Combine

// MARK: - Errors

enum TranscriptionError: LocalizedError {
    case speechRecognizerUnavailable
    case notAuthorized
    case audioEngineStartFailed(Error)
    case recognitionRequestUnavailable

    var errorDescription: String? {
        switch self {
        case .speechRecognizerUnavailable:
            return "语音识别器不可用（系统未支持当前语言或正在初始化）"
        case .notAuthorized:
            return "未获得麦克风或语音识别授权——请在系统设置 → 隐私与安全性中授予权限"
        case .audioEngineStartFailed(let e):
            return "音频引擎启动失败：\(e.localizedDescription)"
        case .recognitionRequestUnavailable:
            return "无法创建语音识别请求"
        }
    }
}

// MARK: - State

enum RecordingState: Equatable {
    case idle
    case recording
    case paused
}

// MARK: - TranscriptionService

@MainActor
final class TranscriptionService: ObservableObject {

    // MARK: Published

    @Published private(set) var state: RecordingState = .idle
    @Published private(set) var completedSegments: [String] = []
    @Published private(set) var activeSegment: String = ""

    /// Last error surfaced from the engine. Cleared automatically when a
    /// new session starts. Phase 3.2 will reflect this in the UI badge.
    @Published private(set) var lastError: TranscriptionError?

    /// Convenience: full transcript so far (completed + active), space-joined.
    var fullTranscript: String {
        let pieces = completedSegments + (activeSegment.isEmpty ? [] : [activeSegment])
        return pieces.joined(separator: " ")
    }

    // MARK: Hooks

    /// Fired once when the user has fully stopped recording (not on pause,
    /// not on internal session restarts). Receives the full final transcript
    /// after trimming. DialogView uses this to auto-copy to NSPasteboard
    /// when the user has DR-020 enabled.
    var onStopped: ((String) -> Void)?

    // MARK: Dependencies

    private let settings: AppSettings

    // MARK: Audio / Speech state

    private var recognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    /// Monotonically increasing generation counter. Every callback compares
    /// against the latest generation; a stale callback (from a session that
    /// was torn down by clearTranscript / restart / stop) becomes a no-op.
    private var sessionGeneration: Int = 0

    // MARK: Tunables (private — could surface in Settings later)

    /// Silence detection: how long the input must stay below `silenceThresholdDB`
    /// before we commit the active segment and start a new session.
    private let silenceDurationSeconds: Double = 1.5

    /// Silence threshold in dB. RMS levels quieter than this count as silence.
    private let silenceThresholdDB: Float = -40.0

    /// Audio tap buffer size. 1024 frames is a common sweet spot — small
    /// enough for ~20ms latency at 48kHz, large enough not to trash the CPU.
    private let bufferSize: AVAudioFrameCount = 1024

    // MARK: Init

    init(settings: AppSettings) {
        self.settings = settings
        setupRecognizer()
    }
    // Note: no `init(settings: AppSettings = .shared)` — default arguments
    // are evaluated in a nonisolated context in Swift 6, but
    // `AppSettings.shared` is @MainActor. Callers (DialogView, SettingsView,
    // VoxAIApp) run on the main actor and can pass `.shared` explicitly.

    deinit {
        // No `self` access in deinit body — Swift 6 isolation rules forbid
        // calling MainActor-isolated stopAudioEngine() from a non-isolated
        // deinit. The audio engine and tasks will tear themselves down when
        // their references are released. If a clean shutdown is required,
        // call `stopListening()` before the service is dropped.
    }

    // MARK: - Public API

    /// Request both Speech Recognition and Microphone authorizations.
    /// Returns `true` only if both are granted. Caller (Phase 1.6 DialogView)
    /// should call this on first launch / before the first record action.
    func requestPermissions() async -> Bool {
        // 1) Speech Recognition (Apple's framework auth)
        let speechGranted = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
        guard speechGranted else { return false }

        // 2) Microphone (system mic access — required separately on macOS 14+)
        let micGranted = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                cont.resume(returning: granted)
            }
        }
        return micGranted
    }

    /// Re-create the speech recognizer for the currently configured language.
    /// Call this from SettingsView after the user changes
    /// `AppSettings.recognitionLanguage`. The change takes effect on the
    /// **next** session start, not mid-recording.
    func updateLanguage() {
        setupRecognizer()
    }

    /// Begin a fresh recording. Clears any prior transcript first.
    /// No-op if already recording or paused.
    func startListening() {
        guard state == .idle else { return }
        completedSegments = []
        activeSegment = ""
        lastError = nil
        state = .recording
        do {
            try startAudioSession()
        } catch let err as TranscriptionError {
            lastError = err
            state = .idle
        } catch {
            lastError = .audioEngineStartFailed(error)
            state = .idle
        }
    }

    /// Pause: commit current segment, tear down audio engine, freeze state.
    /// Resume preserves the existing transcript.
    func pauseListening() {
        guard state == .recording else { return }
        commitActiveSegment()
        stopAudioEngine()
        state = .paused
    }

    /// Resume from pause. Starts a fresh session under the same generation
    /// chain (resume continues into a new active segment).
    func resumeListening() {
        guard state == .paused else { return }
        activeSegment = ""
        state = .recording
        do {
            try startAudioSession()
        } catch let err as TranscriptionError {
            lastError = err
            state = .paused
        } catch {
            lastError = .audioEngineStartFailed(error)
            state = .paused
        }
    }

    /// Stop completely. Commits any active segment, tears down everything,
    /// fires `onStopped` with the final transcript (trimmed). DialogView
    /// uses the hook to auto-copy to clipboard when DR-020 is enabled.
    func stopListening() {
        let wasRunning = (state != .idle)
        commitActiveSegment()
        stopAudioEngine()
        state = .idle

        guard wasRunning else { return }
        let finalText = fullTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !finalText.isEmpty {
            onStopped?(finalText)
        }
    }

    /// Clear all transcript text. If currently recording, the audio session
    /// is restarted with a fresh generation so the new buffers don't get
    /// appended to the just-cleared transcript.
    func clearTranscript() {
        completedSegments = []
        activeSegment = ""
        guard state == .recording else { return }
        sessionGeneration += 1
        stopAudioEngine()
        do {
            try startAudioSession()
        } catch let err as TranscriptionError {
            lastError = err
            state = .idle
        } catch {
            lastError = .audioEngineStartFailed(error)
            state = .idle
        }
    }

    // MARK: - Private

    private func setupRecognizer() {
        let lang = settings.recognitionLanguage
        switch lang {
        case .chineseSimplified:
            recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        case .english:
            recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        case .auto:
            // "Auto" is a UI affordance — SFSpeechRecognizer needs a concrete
            // locale at construction time. v1 prefers Chinese, falls back to
            // English. This matches VoxSage's behavior.
            recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
                ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        }
    }

    private func commitActiveSegment() {
        let trimmed = activeSegment.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            completedSegments.append(trimmed)
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
    }

    private func startAudioSession() throws {
        guard let recognizer, recognizer.isAvailable else {
            throw TranscriptionError.speechRecognizerUnavailable
        }

        // Capture the generation so callbacks from this session can recognize
        // themselves as still-current vs stale.
        let generation = sessionGeneration

        let req = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest = req
        req.shouldReportPartialResults = true
        if #available(macOS 13, *) {
            req.addsPunctuation = true
        }

        let inputNode = audioEngine.inputNode
        let fmt = inputNode.outputFormat(forBus: 0)

        // Cross-architecture correctness:
        // VoxSage hard-coded ~43 buffers/second (44100Hz / 1024). On hardware
        // that defaults to 48000Hz the silence threshold was off by ~10%.
        // Derive it from the actual format instead.
        let buffersPerSecond = fmt.sampleRate / Double(bufferSize)
        let silenceLimit = max(20, Int(silenceDurationSeconds * buffersPerSecond))
        let threshold = silenceThresholdDB
        // Captured-by-reference local; the audio thread is serial w.r.t.
        // itself, so this counter has no cross-thread contention.
        var silenceCount = 0

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: fmt) { [weak self] buf, _ in
            // Hot path: audio real-time thread. Avoid touching `self` here
            // beyond the weak hop into the main actor below.
            req.append(buf)

            let level = buf.rmsLevelDB()
            if level < threshold {
                silenceCount += 1
                if silenceCount >= silenceLimit {
                    silenceCount = 0
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        guard generation == self.sessionGeneration,
                              self.state == .recording,
                              !self.activeSegment
                                  .trimmingCharacters(in: .whitespaces)
                                  .isEmpty
                        else { return }
                        self.sessionGeneration += 1
                        self.commitActiveSegment()
                        self.stopAudioEngine()
                        try? self.startAudioSession()
                    }
                }
            } else {
                silenceCount = 0
            }
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            inputNode.removeTap(onBus: 0)
            recognitionRequest = nil
            throw TranscriptionError.audioEngineStartFailed(error)
        }

        recognitionTask = recognizer.recognitionTask(with: req) { [weak self] result, error in
            // SFSpeechRecognizer's task callback runs on an Apple-owned queue.
            // Bounce to main before touching any state.
            if let result {
                Task { @MainActor [weak self] in
                    guard let self,
                          generation == self.sessionGeneration
                    else { return }
                    self.activeSegment = result.bestTranscription.formattedString
                }
            }

            // The recognizer's own ~60s timeout surfaces as a non-nil error.
            // We treat that as a normal "rotate to a fresh session" event so
            // the user gets continuous transcription instead of a hard stop.
            if error != nil {
                Task { @MainActor [weak self] in
                    guard let self,
                          generation == self.sessionGeneration,
                          self.state == .recording
                    else { return }
                    self.sessionGeneration += 1
                    self.commitActiveSegment()
                    self.stopAudioEngine()
                    try? self.startAudioSession()
                }
            }
        }
    }
}

// MARK: - AVAudioPCMBuffer RMS extension

private extension AVAudioPCMBuffer {
    /// RMS level in dBFS. Returns -160 for empty / inaudible buffers.
    /// Audio-thread safe (pure function over the buffer's float channel data).
    func rmsLevelDB() -> Float {
        guard let data = floatChannelData?[0] else { return -160 }
        let count = Int(frameLength)
        guard count > 0 else { return -160 }
        var sum: Float = 0
        for i in 0..<count {
            let s = data[i]
            sum += s * s
        }
        let rms = sqrt(sum / Float(count))
        return rms > 0 ? 20 * log10(rms) : -160
    }
}
