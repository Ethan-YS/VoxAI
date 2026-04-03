import SwiftUI

struct ContentView: View {
    @EnvironmentObject var meetingStore: MeetingStore
    @EnvironmentObject var transcriptionService: TranscriptionService
    @State private var selectedNav: NavItem = .meetings

    enum NavItem { case meetings, settings }

    var body: some View {
        HStack(spacing: 0) {
            NavSidebar(selected: $selectedNav)
                .frame(width: 160)

            Divider()

            if selectedNav == .meetings {
                MeetingListPanel()
                    .frame(width: 300)
                Divider()
                MeetingDetailPanel()
                    .frame(maxWidth: .infinity)
            } else {
                SettingsView()
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            // 保存会议窗口引用
            if let window = NSApp.windows.first(where: { $0.title == String(localized: "Meeting Notes") }) {
                transcriptionService.meetingWindow = window
            }
            if transcriptionService.openSettingsOnShow {
                selectedNav = .settings
                transcriptionService.openSettingsOnShow = false
            }
        }
        .onChange(of: transcriptionService.openSettingsOnShow) { _, flag in
            if flag {
                selectedNav = .settings
                transcriptionService.openSettingsOnShow = false
            }
        }
    }
}

// ── 最左导航栏 ──────────────────────────────────────────────

struct NavSidebar: View {
    @Binding var selected: ContentView.NavItem
    @EnvironmentObject var transcriptionService: TranscriptionService

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {

            // ── 切换回对话转录模式 ──
            Button {
                if transcriptionService.state != .idle {
                    transcriptionService.stopListening()
                }
                transcriptionService.isDialogMode = true
                transcriptionService.meetingWindow?.orderOut(nil)
                transcriptionService.dialogWindow?.makeKeyAndOrderFront(nil)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 14))
                    Text("Dialog Transcription")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(Color(hex: "4A6CF7"))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "4A6CF7").opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 4)

            Divider()
                .padding(.bottom, 4)

            NavItem(icon: "mic.fill", label: "Meeting Notes",
                    isSelected: selected == .meetings) {
                selected = .meetings
            }
            NavItem(icon: "gearshape.fill", label: "Preferences",
                    isSelected: selected == .settings) {
                selected = .settings
            }
            Spacer()
        }
        .padding(.top, 16)
        .padding(.horizontal, 12)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct NavItem: View {
    let icon: String
    let label: LocalizedStringKey
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? .white : Color(NSColor.secondaryLabelColor))
                    .frame(width: 18)
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? .white : Color(NSColor.labelColor))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "4A6CF7"))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// ── 会议列表面板 ────────────────────────────────────────────

struct MeetingListPanel: View {
    @EnvironmentObject var meetingStore: MeetingStore
    @EnvironmentObject var transcriptionService: TranscriptionService
    @State private var searchText = ""

    var filtered: [Meeting] {
        if searchText.isEmpty { return meetingStore.meetings }
        return meetingStore.meetings.filter {
            $0.title.contains(searchText) ||
            $0.fullTranscript.contains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("All Recordings")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button(action: createMeeting) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(
                            transcriptionService.state == .idle
                                ? Color(hex: "4A6CF7")
                                : Color(NSColor.tertiaryLabelColor)
                        )
                }
                .buttonStyle(.plain)
                .disabled(transcriptionService.state != .idle)
                .help(transcriptionService.state == .idle ? "New Recording" : "Recording in progress")
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13))
                TextField("Search", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            Divider()

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filtered) { meeting in
                        MeetingListRow(meeting: meeting,
                                       isSelected: meetingStore.selectedID == meeting.id)
                            .contentShape(Rectangle())
                            .onTapGesture { meetingStore.selectedID = meeting.id }
                            .contextMenu {
                                Button("Rename") {
                                    meetingStore.selectedID = meeting.id
                                    meetingStore.renamingID = meeting.id
                                }
                                Divider()
                                Button("Delete", role: .destructive) {
                                    meetingStore.deleteMeeting(meeting.id)
                                }
                            }
                    }
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }

    func createMeeting() {
        guard transcriptionService.state == .idle else { return }
        let m = meetingStore.newMeeting()
        transcriptionService.isDialogMode = false
        transcriptionService.onSegmentCommitted = { text in
            meetingStore.appendSegment(TranscriptSegment(text: text), to: m.id)
        }
        transcriptionService.startMeetingListening()
    }
}

struct MeetingListRow: View {
    let meeting: Meeting
    let isSelected: Bool
    @EnvironmentObject var transcriptionService: TranscriptionService

    var isRecording: Bool {
        transcriptionService.state != .idle && isSelected
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(meeting.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(isSelected ? .white : Color(NSColor.labelColor))
                        .lineLimit(1)
                    Spacer()
                    Text(meeting.startTime.formatted(.dateTime.month().day()))
                        .font(.system(size: 12))
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                    if isRecording {
                        Circle()
                            .fill(.red.opacity(0.9))
                            .frame(width: 7, height: 7)
                    }
                }
                HStack {
                    Text(meeting.segments.first?.text ?? String(localized: "No content..."))
                        .font(.system(size: 12))
                        .foregroundStyle(isSelected ? .white.opacity(0.75) : .secondary)
                        .lineLimit(1)
                    Spacer()
                    Text(meeting.duration)
                        .font(.system(size: 12, weight: .medium).monospacedDigit())
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color(hex: "4A6CF7"))
            }
        }
    }
}

// ── 会议详情面板 ────────────────────────────────────────────

struct MeetingDetailPanel: View {
    @EnvironmentObject var meetingStore: MeetingStore
    @EnvironmentObject var transcriptionService: TranscriptionService

    var body: some View {
        if let meeting = meetingStore.selected {
            MeetingDetail(meeting: meeting)
                .id(meeting.id)   // 切换会议时直接重建，避免过渡动画卡顿
        } else {
            EmptyDetailView()
        }
    }
}

struct MeetingDetail: View {
    let meeting: Meeting
    @EnvironmentObject var meetingStore: MeetingStore
    @EnvironmentObject var transcriptionService: TranscriptionService
    @State private var sentToSage = false
    @State private var exported = false
    @State private var isEditingTitle = false
    @State private var titleDraft = ""

    var isRecording: Bool  { transcriptionService.state != .idle }
    var isPaused: Bool     { transcriptionService.state == .paused }
    var hasContent: Bool   { !meeting.segments.isEmpty }
    var isDiarizing: Bool  { meetingStore.diarizingMeetingID == meeting.id }
    var diarizationError: String? { meetingStore.diarizationError }

    var body: some View {
        VStack(spacing: 0) {
            // ── 顶部标题栏 ──
            HStack(spacing: 12) {
                if isEditingTitle {
                    TextField("Meeting Name", text: $titleDraft)
                        .font(.system(size: 15, weight: .medium))
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(NSColor.textBackgroundColor),
                                    in: RoundedRectangle(cornerRadius: 7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(Color(hex: "4A6CF7"), lineWidth: 1.5)
                        )
                        .onSubmit { commitRename() }
                        .onExitCommand { cancelRename() }
                } else {
                    Text(meeting.title)
                        .font(.system(size: 17, weight: .semibold))
                        .lineLimit(1)
                        .help("Double-click to rename")
                        .onTapGesture(count: 2) { startRename() }
                }

                if isRecording {
                    RecordingBadge(isPaused: isPaused)
                }

                Spacer()

                HStack(spacing: 20) {
                    if isRecording {
                        // 录音/暂停中：显示"完成会议"按钮触发说话人识别
                        Button(action: completeMeeting) {
                            HStack(spacing: 5) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                Text("Done")
                                    .font(.system(size: 13, weight: .medium))
                                    .lineLimit(1)
                            }
                            .fixedSize()
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color(hex: "4A6CF7"), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .help("End meeting and identify speakers")
                    } else {
                        // 未录音：显示开始录音按钮
                        ToolbarButton(icon: "record.circle") { startRecording() }
                            .help("Start Recording")
                        // 重新识别按钮（有保存的音频文件时显示）
                        if !isDiarizing, let savedPath = meeting.audioPath,
                           FileManager.default.fileExists(atPath: savedPath) {
                            ToolbarButton(icon: "person.wave.2") { retryDiarization() }
                                .help("Re-identify Speakers")
                        }
                    }

                    ToolbarButton(
                        icon: exported ? "checkmark" : "square.and.arrow.up",
                        color: exported ? .green : Color(NSColor.secondaryLabelColor)
                    ) { exportMeeting() }
                    .help("Export")

                    ToolbarButton(
                        icon: sentToSage ? "checkmark" : "paperplane",
                        color: sentToSage ? .green : Color(NSColor.secondaryLabelColor)
                    ) { sendToSage() }
                    .help("Copy to AI for summary")

                    ToolbarButton(icon: "trash") {
                        meetingStore.deleteMeeting(meeting.id)
                    }
                    .help("Delete Recording")
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)

            Divider()

            // ── 内容区 ──
            let liveText = (isRecording && !isPaused) ? transcriptionService.activeSegment : ""
            let showTranscript = hasContent || !liveText.isEmpty

            if showTranscript {
                // 有已提交内容 或 有实时文字时，显示转录视图
                TranscriptScrollView(
                    segments: meeting.segments,
                    liveText: liveText,
                    isRecording: isRecording,
                    onRenameSpeaker: { oldName, newName in
                        meetingStore.renameSpeaker(in: meeting.id, from: oldName, to: newName)
                    }
                )
            } else if isRecording {
                // 录音中但还没说任何话
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: isPaused ? "pause.circle" : "waveform")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(isPaused ? Color.orange.opacity(0.6) : Color.red.opacity(0.6))
                    Text(LocalizedStringKey(isPaused ? "Paused" : "Recording, waiting for speech…"))
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                EmptyDetailView()
            }

            // ── 说话人识别处理中提示 ──
            if isDiarizing {
                Divider()
                HStack(spacing: 10) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Identifying speakers…")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(NSColor.windowBackgroundColor))
            }

            // ── 说话人识别错误提示 ──
            if let err = diarizationError {
                Divider()
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Dismiss") { meetingStore.diarizationError = nil }
                        .font(.system(size: 12))
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.08))
            }

            // ── 录音控制条（录音进行中常驻底部）──
            if isRecording {
                Divider()
                RecordingControlBar(
                    meeting: meeting,
                    isPaused: isPaused,
                    onToggle: {
                        if isPaused {
                            transcriptionService.resumeListening()
                        } else {
                            transcriptionService.pauseListening()
                        }
                    }
                )
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
        // 情况1：view 已存在时右键重命名（已选中的条目）
        .onChange(of: meetingStore.renamingID) { _, newID in
            if newID == meeting.id && !isEditingTitle {
                startRename()
            }
        }
        // 情况2：view 刚创建时（未选中的条目右键重命名，selectedID 和 renamingID 同时设置）
        .onAppear {
            if meetingStore.renamingID == meeting.id {
                startRename()
            }
        }
    }

    // ── 重命名 ──────────────────────────────────────────────

    func startRename() {
        titleDraft = meeting.title
        isEditingTitle = true
        meetingStore.renamingID = meeting.id
    }

    func commitRename() {
        meetingStore.renameMeeting(meeting.id, title: titleDraft)
        isEditingTitle = false
        meetingStore.renamingID = nil
    }

    func cancelRename() {
        isEditingTitle = false
        meetingStore.renamingID = nil
    }

    // 完成会议：停止录音并触发说话人识别
    func completeMeeting() {
        let audioPath = transcriptionService.lastMeetingAudioPath
        let root = transcriptionService.projectRoot
        transcriptionService.stopListening()
        meetingStore.endMeeting(meeting.id)
        meetingStore.diarizationError = nil
        if let audioPath, let root {
            meetingStore.setAudioPath(meeting.id, path: audioPath.path)
            meetingStore.diarizingMeetingID = meeting.id
            meetingStore.runDiarization(
                audioPath: audioPath,
                meetingID: meeting.id,
                projectRoot: root
            )
        }
    }

    // 重新触发说话人识别（用已保存的音频路径）
    func retryDiarization() {
        guard let root = transcriptionService.projectRoot,
              let savedPath = meeting.audioPath else { return }
        let audioURL = URL(fileURLWithPath: savedPath)
        guard FileManager.default.fileExists(atPath: savedPath) else {
            meetingStore.diarizationError = "音频文件已不存在，无法重新识别"
            return
        }
        meetingStore.diarizationError = nil
        meetingStore.diarizingMeetingID = meeting.id
        meetingStore.runDiarization(audioPath: audioURL, meetingID: meeting.id, projectRoot: root)
    }

    // 对已有会议继续追加录音
    func startRecording() {
        guard transcriptionService.state == .idle else { return }
        transcriptionService.isDialogMode = false
        transcriptionService.onSegmentCommitted = { text in
            meetingStore.appendSegment(TranscriptSegment(text: text), to: meeting.id)
        }
        transcriptionService.startMeetingListening()
    }

    func exportMeeting() {
        guard hasContent else { return }
        let content = "# \(meeting.title)\n\n**时间**：\(meeting.startTime.formatted())\n\n---\n\n\(meeting.fullTranscript)"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
        withAnimation { exported = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { exported = false }
        }
        if let url = meetingStore.export(meeting, format: .markdown) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    func sendToSage() {
        guard hasContent else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(
            "以下是会议记录，请帮我生成摘要和主要行动项：\n\n\(meeting.fullTranscript)",
            forType: .string
        )
        withAnimation { sentToSage = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { sentToSage = false }
        }
    }
}

// ── 录音状态徽标 ──────────────────────────────────────────

struct RecordingBadge: View {
    let isPaused: Bool

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(isPaused ? Color.orange : Color.red)
                .frame(width: 7, height: 7)
            Text(LocalizedStringKey(isPaused ? "Paused" : "Recording"))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isPaused ? Color.orange : Color.red)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            (isPaused ? Color.orange : Color.red).opacity(0.1),
            in: Capsule()
        )
    }
}

// ── 底部录音控制条 ────────────────────────────────────────

struct RecordingControlBar: View {
    let meeting: Meeting
    let isPaused: Bool
    let onToggle: () -> Void

    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var duration: String {
        let secs = max(0, Int(now.timeIntervalSince(meeting.startTime)))
        return String(format: "%02d:%02d", secs / 60, secs % 60)
    }

    var body: some View {
        HStack(spacing: 16) {
            // 实时计时
            Text(duration)
                .font(.system(size: 15, weight: .medium).monospacedDigit())
                .foregroundStyle(isPaused ? Color.secondary : Color(NSColor.labelColor))
                .frame(minWidth: 52, alignment: .leading)

            // 波形 / 暂停提示
            if isPaused {
                Text("Paused, tap to resume")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            } else {
                WaveformView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
            }

            // 暂停 / 继续（唯一按钮）
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(isPaused
                              ? Color(hex: "4A6CF7").opacity(0.12)
                              : Color(NSColor.quaternaryLabelColor).opacity(0.3))
                        .frame(width: 36, height: 36)
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(isPaused
                                         ? Color(hex: "4A6CF7")
                                         : Color(NSColor.secondaryLabelColor))
                }
            }
            .buttonStyle(.plain)
            .help(LocalizedStringKey(isPaused ? "Resume Recording" : "Pause Recording"))
        }
        .onReceive(timer) { t in now = t }
    }
}

// ── 转录内容滚动视图 ──────────────────────────────────────

// 同一说话人连续发言合并为一个 block
private struct SpeakerBlock {
    let firstID: UUID       // 用作 ForEach id
    let speaker: String
    let paragraphs: [String]
}

private func groupBySpeaker(_ segs: [TranscriptSegment]) -> [SpeakerBlock] {
    var blocks: [SpeakerBlock] = []
    for seg in segs {
        if let last = blocks.last, last.speaker == seg.speaker {
            blocks[blocks.count - 1] = SpeakerBlock(
                firstID: last.firstID,
                speaker: last.speaker,
                paragraphs: last.paragraphs + [seg.text]
            )
        } else {
            blocks.append(SpeakerBlock(firstID: seg.id, speaker: seg.speaker, paragraphs: [seg.text]))
        }
    }
    return blocks
}

struct TranscriptScrollView: View {
    let segments: [TranscriptSegment]
    var liveText: String = ""
    var isRecording: Bool = false
    var onRenameSpeaker: ((String, String) -> Void)? = nil  // (oldName, newName)
    let speakerColors: [Color] = [
        Color(hex: "4A6CF7"), Color(hex: "9B59B6"),
        Color(hex: "27AE60"), Color(hex: "E67E22")
    ]

    var groupedByMinute: [(String, [TranscriptSegment])] {
        var result: [(String, [TranscriptSegment])] = []
        var current: [TranscriptSegment] = []
        var currentMinute = ""

        for seg in segments {
            let minute = seg.timestamp.formatted(.dateTime.hour().minute())
            if minute != currentMinute {
                if !current.isEmpty { result.append((currentMinute, current)) }
                current = [seg]
                currentMinute = minute
            } else {
                current.append(seg)
            }
        }
        if !current.isEmpty { result.append((currentMinute, current)) }
        return result
    }

    func colorForSpeaker(_ speaker: String) -> Color {
        let hash = speaker.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }
        return speakerColors[abs(hash) % speakerColors.count]
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(groupedByMinute, id: \.0) { (time, segs) in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(time)
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 24)

                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(groupBySpeaker(segs), id: \.firstID) { block in
                                    SpeakerBlockView(
                                        speaker: block.speaker,
                                        paragraphs: block.paragraphs,
                                        speakerColor: colorForSpeaker(block.speaker),
                                        onRenameSpeaker: { newName in
                                            onRenameSpeaker?(block.speaker, newName)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }

                    // 实时预览行：正在识别、尚未 commit 的文字
                    if !liveText.isEmpty {
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 7, height: 7)
                                .padding(.top, 5)
                            Text(liveText)
                                .font(.system(size: 15))
                                .foregroundStyle(Color(NSColor.secondaryLabelColor))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 24)
                        .id("live")
                    }
                }
                .padding(.vertical, 20)
            }
            .onChange(of: liveText) { _, _ in
                guard isRecording else { return }
                withAnimation { proxy.scrollTo("live", anchor: .bottom) }
            }
            .onChange(of: segments.count) { _, _ in
                guard isRecording, let last = segments.last else { return }
                withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
            }
        }
    }
}

struct SpeakerBlockView: View {
    let speaker: String
    let paragraphs: [String]
    let speakerColor: Color
    var onRenameSpeaker: ((String) -> Void)? = nil

    @State private var isEditing = false
    @State private var draft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !speaker.isEmpty {
                if isEditing {
                    TextField("Speaker Name", text: $draft)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(speakerColor)
                        .onSubmit { commit() }
                        .onExitCommand { isEditing = false }
                } else {
                    HStack(spacing: 4) {
                        Text(speaker)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(speakerColor)
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { draft = speaker; isEditing = true }
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                ForEach(paragraphs.indices, id: \.self) { i in
                    Text(paragraphs[i])
                        .font(.system(size: 15))
                        .foregroundStyle(Color(NSColor.labelColor))
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(3)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    private func commit() {
        let name = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty { onRenameSpeaker?(name) }
        isEditing = false
    }
}

struct TranscriptSegmentView: View {
    let segment: TranscriptSegment
    let speakerColor: Color
    var onRenameSpeaker: ((String) -> Void)? = nil

    @State private var isEditing = false
    @State private var draft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !segment.speaker.isEmpty {
                if isEditing {
                    TextField("Speaker Name", text: $draft)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(speakerColor)
                        .onSubmit {
                            onRenameSpeaker?(draft)
                            isEditing = false
                        }
                        .onExitCommand { isEditing = false }
                } else {
                    HStack(spacing: 4) {
                        Text(segment.speaker)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(speakerColor)
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        draft = segment.speaker
                        isEditing = true
                    }
                }
            }
            Text(segment.text)
                .font(.system(size: 15))
                .foregroundStyle(Color(NSColor.labelColor))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct ToolbarButton: View {
    let icon: String
    var color: Color = Color(NSColor.secondaryLabelColor)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }
}

struct EmptyDetailView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform")
                .font(.system(size: 48))
                .foregroundStyle(.quaternary)
            Text("Select a recording or create new")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
