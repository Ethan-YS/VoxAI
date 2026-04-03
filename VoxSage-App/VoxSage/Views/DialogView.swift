import SwiftUI
import AppKit

// ── 置顶 + 可拖拽 ─────────────────────────────────────────

private struct FloatingWindowSetup: NSViewRepresentable {
    @EnvironmentObject var ts: TranscriptionService

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.styleMask    = [.borderless, .fullSizeContentView]
            window.isOpaque     = false
            window.backgroundColor = .clear
            window.isMovableByWindowBackground = true
            DispatchQueue.main.async {
                window.level = .floating
                window.collectionBehavior = [.canJoinAllSpaces, .stationary]
                ts.dialogWindow = window   // 保存对话窗口引用
            }
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

// ── 主视图 ────────────────────────────────────────────────

struct DialogView: View {
    @EnvironmentObject var ts: TranscriptionService
    @Environment(\.openWindow) var openWindow
    @State private var copied = false

    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(NSColor.windowBackgroundColor))
            .shadow(color: .black.opacity(0.12), radius: 20, y: 6)
            .overlay {
                VStack(spacing: 0) {
                    // ── Title bar（close button 和 logo 同行）──
                    DialogTitleBar()
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 10)

                    Divider().opacity(0.5)

                    // ── 内容区 ──
                    if !ts.isDialogMode {
                        // 会议模式：浮窗显示状态指示
                        MeetingModeContent(isRecording: ts.state != .idle,
                                           isPaused: ts.state == .paused)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if ts.state != .idle {
                        // 对话模式录音中：显示实时转录
                        LyricsView(
                            segments: ts.completedSegments,
                            active: ts.activeSegment,
                            isPaused: ts.state == .paused
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, 20)
                    } else {
                        // 对话模式待机
                        IdleContent()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    // ── 底部控制 ──
                    if !ts.isDialogMode {
                        // 会议模式：底部显示"切换回对话"按钮
                        Button {
                            if ts.state != .idle { ts.stopListening() }
                            ts.isDialogMode = true
                            ts.meetingWindow?.orderOut(nil)
                            ts.dialogWindow?.makeKeyAndOrderFront(nil)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "waveform")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Switch to Dialog Mode")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundStyle(Color(hex: "4A6CF7"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(hex: "4A6CF7").opacity(0.1), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 24)
                    } else if ts.state != .idle {
                        // 对话模式录音中：控制条
                        ControlBar(
                            isPaused: ts.state == .paused,
                            copied: copied,
                            onTogglePause: {
                                ts.state == .recording ? ts.pauseListening() : ts.resumeListening()
                            },
                            onCopy: {
                                ts.copyTranscript()
                                withAnimation { copied = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation { copied = false }
                                }
                            },
                            onClear: { ts.clearTranscript() }
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    } else {
                        // 对话模式待机：麦克风按钮
                        IdleMicButton {
                            ts.onSegmentCommitted = nil
                            ts.isDialogMode = true
                            ts.startListening()
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
        .frame(width: 420, height: 420)
        .background(FloatingWindowSetup())
        .onAppear { ts.isDialogMode = true }
    }
}

// ── 顶部栏 ────────────────────────────────────────────────

// 关闭按钮 — 与 headphones / gearshape 同一 SF Symbols 风格
struct CloseButton: View {
    @EnvironmentObject var ts: TranscriptionService
    @State private var hovered = false

    var body: some View {
        Button {
            ts.dialogWindow?.orderOut(nil)
        } label: {
            Image(systemName: "xmark.circle")
                .font(.system(size: 15))
                .foregroundStyle(hovered ? Color.primary.opacity(0.8) : Color.secondary)
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .help("Close")
    }
}

struct DialogTitleBar: View {
    @EnvironmentObject var ts: TranscriptionService
    @Environment(\.openWindow) var openWindow

    var body: some View {
        HStack(spacing: 8) {
            // Logo
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(hex: "7B6CF6"), Color(hex: "5B8EF0")],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 28, height: 28)
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text("VoxAI")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(NSColor.labelColor))

            Spacer()

            HStack(spacing: 14) {
                Button {
                    if ts.state != .idle { ts.stopListening() }
                    ts.isDialogMode = false
                    ts.dialogWindow?.orderOut(nil)
                    openWindow(id: "meeting")
                } label: {
                    Image(systemName: "headphones")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain).help("Meeting Notes")

                Button {
                    ts.openSettingsOnShow = true
                    ts.dialogWindow?.orderOut(nil)
                    openWindow(id: "meeting")
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain).help("Settings")

                // 关闭按钮放在右侧末尾
                CloseButton()
            }
        }
    }
}

// ── 歌词式转录展示 ────────────────────────────────────────

struct LyricsView: View {
    let segments: [String]
    let active: String
    let isPaused: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    // 已完成的段落（逐渐变暗）
                    ForEach(Array(segments.enumerated()), id: \.offset) { idx, seg in
                        Text(seg)
                            .font(.system(size: 16))
                            .foregroundStyle(opacity(for: idx, total: segments.count))
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // 当前段（高亮）— 暂停时不重复显示状态文字
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

                    // 滚动锚点
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.vertical, 8)
            }
            .onChange(of: active) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: segments.count) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

    // 越旧的段落越暗：最新完成段 0.75，最老段 0.4（保持可读性）
    private func opacity(for index: Int, total: Int) -> Color {
        guard total > 0 else { return .secondary }
        let recency = Double(index) / Double(max(total - 1, 1))
        let alpha = 0.4 + recency * 0.35   // 0.4 … 0.75
        return Color(NSColor.labelColor).opacity(alpha)
    }
}

// ── 待机 ──────────────────────────────────────────────────

struct IdleContent: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Press button to start speaking")
                .font(.system(size: 15))
                .foregroundStyle(Color.secondary.opacity(0.6))
            Spacer()
        }
    }
}

// 会议模式下浮窗显示的状态视图
struct MeetingModeContent: View {
    let isRecording: Bool
    let isPaused: Bool

    @State private var elapsed = ""
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var startTime = Date()

    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "headphones")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Color.secondary.opacity(0.45))

            Text("Meeting Mode")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(NSColor.labelColor).opacity(0.75))

            if isRecording {
                HStack(spacing: 6) {
                    Circle()
                        .fill(isPaused ? Color.orange : Color.red)
                        .frame(width: 7, height: 7)
                    Text(isPaused ? String(localized: "Paused") : elapsed)
                        .font(.system(size: 13).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Record in meeting window")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
            Spacer()
        }
        .onAppear { startTime = Date() }
        .onReceive(timer) { _ in
            guard isRecording && !isPaused else { return }
            let secs = Int(Date().timeIntervalSince(startTime))
            elapsed = String(format: "%02d:%02d", secs / 60, secs % 60)
        }
    }
}

struct IdleMicButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(hex: "5B7CF6"), Color(hex: "4A6CF7")],
                        startPoint: .top, endPoint: .bottom))
                    .frame(width: 64, height: 64)
                    .shadow(color: Color(hex: "4A6CF7").opacity(0.4), radius: 12, y: 4)
                Image(systemName: "mic.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }
}

// ── 录音中控制栏 ──────────────────────────────────────────

struct ControlBar: View {
    let isPaused: Bool
    let copied: Bool
    let onTogglePause: () -> Void
    let onCopy: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // 清空
            BarButton(
                icon: "trash",
                color: Color(NSColor.secondaryLabelColor)
            ) { onClear() }

            // 波形 / 暂停状态
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

            // 暂停 / 继续
            BarButton(
                icon: isPaused ? "play.fill" : "pause.fill",
                color: isPaused ? Color(hex: "4A6CF7") : Color(NSColor.secondaryLabelColor),
                bg: isPaused ? Color(hex: "4A6CF7").opacity(0.12) : Color(NSColor.quaternaryLabelColor).opacity(0.3)
            ) { onTogglePause() }

            // 复制
            BarButton(
                icon: copied ? "checkmark" : "doc.on.doc",
                color: copied ? Color.green : Color(NSColor.secondaryLabelColor),
                bg: copied ? Color.green.opacity(0.15) : Color(NSColor.quaternaryLabelColor).opacity(0.3)
            ) { onCopy() }
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

struct BarButton: View {
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

// ── 波形动画 ──────────────────────────────────────────────

struct WaveformView: View {
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

// ── Color Hex ─────────────────────────────────────────────

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var n: UInt64 = 0
        Scanner(string: h).scanHexInt64(&n)
        self.init(
            red:   Double((n >> 16) & 0xFF) / 255,
            green: Double((n >> 8)  & 0xFF) / 255,
            blue:  Double( n        & 0xFF) / 255
        )
    }
}
