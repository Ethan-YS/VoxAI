//
//  DialogView.swift
//  VoxAI
//
//  The product face for v1: a floating, always-on-top window where the
//  user dictates and the transcript flows into the clipboard automatically
//  (DR-020 — the core "用嘴编程" flow).
//
//  Three UI states:
//    1. idle + empty transcript     -> mic button to start
//    2. recording / paused          -> live lyrics + control bar
//    3. idle + non-empty transcript -> finished view (copy / clear / re-record)
//
//  "Auto copy on stop" is wired in `onAppear` via TranscriptionService.onStopped.
//  When AppSettings.autoCopyToClipboard is on (default true, DR-020), the
//  transcript lands on NSPasteboard the moment the user hits stop.
//

import SwiftUI
import AppKit
import Combine

// MARK: - Floating window setup
//
// macOS-native trick to turn the SwiftUI WindowGroup window into a borderless
// floating panel that stays above other apps. Captures the underlying NSWindow
// so the view can later hide it (close button) without holding the reference
// inside the service layer.

private struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        // Two-step async: SwiftUI's window initialization runs in stages,
        // and `view.window` is non-nil before SwiftUI has finished setting
        // its own level/style. Setting `.level = .floating` in the same
        // tick as `view.window` becomes available sometimes loses out to
        // SwiftUI's later override. Pushing level/collectionBehavior into
        // a second `async` (after style mutations) makes it stick reliably.
        // VoxSage hit the same race and used the same fix.
        DispatchQueue.main.async {
            guard let w = view.window else { return }
            w.styleMask = [.borderless, .fullSizeContentView]
            w.isOpaque = false
            w.backgroundColor = .clear
            w.isMovableByWindowBackground = true

            DispatchQueue.main.async {
                // .floating: float above all normal windows in this and
                //            every other app
                w.level = .floating
                // .canJoinAllSpaces: visible regardless of which Space the
                //                    user is currently on
                // .stationary: doesn't slide with Space transitions
                // .fullScreenAuxiliary: stays visible when other apps go
                //                       fullscreen (otherwise the dialog
                //                       would hide behind the fullscreen app)
                w.collectionBehavior = [
                    .canJoinAllSpaces,
                    .stationary,
                    .fullScreenAuxiliary,
                ]
                window = w
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - DialogView

struct DialogView: View {
    @EnvironmentObject private var ts: TranscriptionService
    @EnvironmentObject private var settings: AppSettings

    @State private var window: NSWindow?
    @State private var copyFlash = false        // brief checkmark state on copy
    @State private var permissionDenied = false  // shown if user denied mic/speech

    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(NSColor.windowBackgroundColor))
            .shadow(color: .black.opacity(0.12), radius: 20, y: 6)
            .overlay {
                VStack(spacing: 0) {
                    DialogTitleBar(
                        copyFlash: copyFlash,
                        onClose: closeWindow
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 10)

                    Divider().opacity(0.5)

                    contentArea
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, 20)

                    bottomBar
                }
            }
            .frame(width: 420, height: 420)
            .background(WindowAccessor(window: $window))
            .onAppear { wireServiceCallbacks() }
            .alert(
                "麦克风或语音识别权限被拒绝",
                isPresented: $permissionDenied,
                actions: {
                    Button("OK") {}
                },
                message: {
                    Text("请到 系统设置 → 隐私与安全性 → 麦克风/语音识别 中授予 VoxAI 权限。")
                }
            )
    }

    // MARK: - Content

    @ViewBuilder
    private var contentArea: some View {
        if ts.state != .idle {
            // recording or paused — live lyrics
            LyricsView(
                segments: ts.completedSegments,
                active: ts.activeSegment,
                isPaused: ts.state == .paused
            )
        } else if !ts.fullTranscript.isEmpty {
            // stopped, transcript still on screen — let the user re-read /
            // re-copy / clear before starting again.
            FinishedTranscriptView(text: ts.fullTranscript)
        } else {
            IdleContent()
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        if ts.state != .idle {
            ControlBar(
                isPaused: ts.state == .paused,
                onTogglePause: {
                    if ts.state == .recording {
                        ts.pauseListening()
                    } else {
                        ts.resumeListening()
                    }
                },
                onStop: { ts.stopListening() },
                onClear: { ts.clearTranscript() }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        } else if !ts.fullTranscript.isEmpty {
            FinishedActionsBar(
                copyFlash: copyFlash,
                onCopy: { copyCurrentTranscript() },
                onClear: { ts.clearTranscript() },
                onRestart: { startRecording() }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        } else {
            IdleMicButton { startRecording() }
                .padding(.bottom, 24)
        }
    }

    // MARK: - Actions

    private func wireServiceCallbacks() {
        // DR-020: auto-copy when the user hits stop, IF the setting is on.
        // Replaces any prior closure (DialogView is the only consumer in v1).
        ts.onStopped = { text in
            Task { @MainActor in
                if settings.autoCopyToClipboard {
                    writePasteboard(text)
                    flashCopyConfirmation()
                }
            }
        }
    }

    private func startRecording() {
        Task { @MainActor in
            // Always (re-)check authorization on each start. If the user
            // pre-granted, this returns instantly; if denied, we surface
            // a dialog instead of silently doing nothing.
            let granted = await ts.requestPermissions()
            if !granted {
                permissionDenied = true
                return
            }
            // Starting fresh wipes any leftover transcript from the previous
            // session — the user already had a chance to copy it.
            if !ts.fullTranscript.isEmpty {
                ts.clearTranscript()
            }
            ts.startListening()
        }
    }

    private func copyCurrentTranscript() {
        let text = ts.fullTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        writePasteboard(text)
        flashCopyConfirmation()
    }

    private func writePasteboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func flashCopyConfirmation() {
        withAnimation(.easeOut(duration: 0.15)) { copyFlash = true }
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.15)) { copyFlash = false }
            }
        }
    }

    private func closeWindow() {
        // Closing the dialog must also stop the mic; otherwise the engine
        // keeps running invisibly and the system mic indicator confuses users.
        if ts.state != .idle {
            ts.stopListening()
        }
        window?.orderOut(nil)
    }
}

// MARK: - Title bar

private struct DialogTitleBar: View {
    let copyFlash: Bool
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Logo
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(hex: "7B6CF6"), Color(hex: "5B8EF0")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 28, height: 28)
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text("VoxAI")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(NSColor.labelColor))

            // Copy-confirmation flag — shows briefly after auto-copy or
            // manual copy. Tells the user "your text is on the clipboard"
            // without an alert.
            if copyFlash {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                    Text("已复制")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.green.opacity(0.12), in: Capsule())
                .transition(.scale.combined(with: .opacity))
            }

            Spacer()

            // Close: hide window + stop mic. Re-opening is via MenuBarExtra
            // (Phase 1.7).
            Button(action: onClose) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("关闭浮窗")
        }
    }
}

// MARK: - Lyrics view

private struct LyricsView: View {
    let segments: [String]
    let active: String
    let isPaused: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { idx, seg in
                        Text(seg)
                            .font(.system(size: 16))
                            .foregroundStyle(opacity(for: idx, total: segments.count))
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if !active.isEmpty {
                        Text(active)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color(NSColor.labelColor))
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id("active")
                    } else if segments.isEmpty && !isPaused {
                        Text("Listening…")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                            .id("active")
                    }

                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.vertical, 8)
            }
            // The two-arg .onChange(of:initial:_:) is macOS 14+. Stay on
            // the single-arg version that works back to macOS 13.0.
            .onChange(of: active) { _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: segments.count) { _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

    /// Older segments fade gradually (0.4 oldest → 0.75 most recent).
    /// Edge case: a lone segment is BOTH the oldest and the most recent —
    /// it should look "fresh" (0.75), not "ancient" (0.4). Without this
    /// special case the formula picks 0.4 because index/total-1 = 0/1 = 0,
    /// which made the user's only-just-spoken sentence look ghosted.
    private func opacity(for index: Int, total: Int) -> Color {
        guard total > 0 else { return .secondary }
        if total == 1 { return Color(NSColor.labelColor).opacity(0.75) }
        let recency = Double(index) / Double(total - 1)
        let alpha = 0.4 + recency * 0.35
        return Color(NSColor.labelColor).opacity(alpha)
    }
}

// MARK: - Idle content

private struct IdleContent: View {
    var body: some View {
        VStack {
            Spacer()
            Text("按下话筒开始说话")
                .font(.system(size: 15))
                .foregroundStyle(Color.secondary.opacity(0.7))
            Text("Press the mic to start")
                .font(.system(size: 12))
                .foregroundStyle(Color.secondary.opacity(0.4))
                .padding(.top, 4)
            Spacer()
        }
    }
}

private struct IdleMicButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(hex: "5B7CF6"), Color(hex: "4A6CF7")],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: 64, height: 64)
                    .shadow(color: Color(hex: "4A6CF7").opacity(0.4), radius: 12, y: 4)
                Image(systemName: "mic.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .help("开始录音")
    }
}

// MARK: - Finished transcript (idle but transcript non-empty)

private struct FinishedTranscriptView: View {
    let text: String

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            Text(text)
                .font(.system(size: 16))
                .foregroundStyle(Color(NSColor.labelColor).opacity(0.85))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .textSelection(.enabled)
        }
    }
}

private struct FinishedActionsBar: View {
    let copyFlash: Bool
    let onCopy: () -> Void
    let onClear: () -> Void
    let onRestart: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            BarButton(icon: "trash", color: Color(NSColor.secondaryLabelColor)) { onClear() }
                .help("清空")

            BarButton(
                icon: copyFlash ? "checkmark" : "doc.on.doc",
                color: copyFlash ? .green : Color(NSColor.secondaryLabelColor),
                bg: copyFlash
                    ? Color.green.opacity(0.15)
                    : Color(NSColor.quaternaryLabelColor).opacity(0.3)
            ) { onCopy() }
            .help("复制到剪贴板")

            Spacer()

            // Re-record: prominent center-piece, same gradient as the idle
            // mic button so the user knows it's the "go again" affordance.
            Button(action: onRestart) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(hex: "5B7CF6"), Color(hex: "4A6CF7")],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(width: 48, height: 48)
                        .shadow(color: Color(hex: "4A6CF7").opacity(0.3), radius: 8, y: 2)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .help("重新录音")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 40)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        }
    }
}

// MARK: - Recording control bar

private struct ControlBar: View {
    let isPaused: Bool
    let onTogglePause: () -> Void
    let onStop: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            BarButton(icon: "trash", color: Color(NSColor.secondaryLabelColor)) { onClear() }
                .help("清空")

            if isPaused {
                HStack {
                    Spacer()
                    Text("Paused")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(height: 44)
            } else {
                WaveformView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }

            BarButton(
                icon: isPaused ? "play.fill" : "pause.fill",
                color: isPaused ? Color(hex: "4A6CF7") : Color(NSColor.secondaryLabelColor),
                bg: isPaused
                    ? Color(hex: "4A6CF7").opacity(0.12)
                    : Color(NSColor.quaternaryLabelColor).opacity(0.3)
            ) { onTogglePause() }
            .help(isPaused ? "继续" : "暂停")

            // Stop button: ends recording AND triggers onStopped (auto-copy
            // hook). This is the DR-020 path the user uses every time.
            BarButton(
                icon: "stop.fill",
                color: .white,
                bg: Color(hex: "4A6CF7")
            ) { onStop() }
            .help("停止并复制到剪贴板")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 40)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        }
    }
}

private struct BarButton: View {
    let icon: String
    var color: Color = .secondary
    var bg: Color = Color(NSColor.quaternaryLabelColor).opacity(0.3)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(bg).frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(color)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Waveform animation

private struct WaveformView: View {
    @State private var phase: CGFloat = 0
    private let barCount = 26
    private let timer = Timer.publish(every: 0.06, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "4A6CF7").opacity(0.7))
                    .frame(width: 3, height: barHeight(for: i))
                    .animation(.easeInOut(duration: 0.15), value: phase)
            }
        }
        .onReceive(timer) { _ in phase += 0.3 }
    }

    private func barHeight(for i: Int) -> CGFloat {
        let a = sin(CGFloat(i) * 0.5 + phase) * 0.5 + 0.5
        let b = sin(CGFloat(i) * 1.3 + phase * 1.7) * 0.3
        return max(4, (a + b) * 36)
    }
}

// MARK: - Color hex helper

private extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var n: UInt64 = 0
        Scanner(string: h).scanHexInt64(&n)
        self.init(
            red: Double((n >> 16) & 0xFF) / 255,
            green: Double((n >> 8)  & 0xFF) / 255,
            blue:  Double( n        & 0xFF) / 255
        )
    }
}
