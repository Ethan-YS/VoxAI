import SwiftUI

// 菜单栏下拉窗口
struct MenuBarView: View {
    @EnvironmentObject var transcriptionService: TranscriptionService
    @EnvironmentObject var meetingStore: MeetingStore
    @Environment(\.openWindow) var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 状态指示
            HStack(spacing: 8) {
                Circle()
                    .fill(transcriptionService.state == .idle ? Color.gray : Color.red)
                    .frame(width: 8, height: 8)
                Text(transcriptionService.state == .idle ? "VoxAI Ready" : "Recording…")
                    .font(.callout).fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // 快捷操作
            Group {
                MenuBarButton(icon: "waveform.circle", label: "Open Dialog Window") {
                    transcriptionService.meetingWindow?.orderOut(nil)
                    transcriptionService.isDialogMode = true
                    if transcriptionService.dialogWindow != nil {
                        transcriptionService.dialogWindow?.makeKeyAndOrderFront(nil)
                    } else {
                        openWindow(id: "dialog")
                    }
                }
                MenuBarButton(icon: "rectangle.and.text.magnifyingglass", label: "Meeting Notes") {
                    transcriptionService.dialogWindow?.orderOut(nil)
                    transcriptionService.isDialogMode = false
                    // 切换前停止对话模式的录音，否则 state != .idle，会议窗口无法新建
                    if transcriptionService.state != .idle {
                        transcriptionService.stopListening()
                    }
                    if transcriptionService.meetingWindow != nil {
                        transcriptionService.meetingWindow?.makeKeyAndOrderFront(nil)
                    } else {
                        openWindow(id: "meeting")
                    }
                    NSApp.activate(ignoringOtherApps: true)
                }
            }

            Divider().padding(.vertical, 4)

            // 最近会议
            if !meetingStore.meetings.isEmpty {
                Text("Recent Meetings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.top, 4)

                ForEach(meetingStore.meetings.prefix(3)) { meeting in
                    Button {
                        meetingStore.selectedID = meeting.id
                        NSApp.activate(ignoringOtherApps: true)
                    } label: {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundStyle(.secondary)
                            Text(meeting.title)
                                .lineLimit(1)
                            Spacer()
                            Text(meeting.duration)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider().padding(.vertical, 4)

            MenuBarButton(icon: "power", label: "Quit VoxAI") {
                NSApp.terminate(nil)
            }
            .padding(.bottom, 8)
        }
        .frame(width: 260)
    }
}

struct MenuBarButton: View {
    let icon: String
    let label: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .frame(width: 18)
                    .foregroundStyle(.secondary)
                Text(label)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
        }
        .buttonStyle(.plain)
    }
}
