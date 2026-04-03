import SwiftUI

@main
struct VoxAIApp: App {
    @StateObject private var meetingStore = MeetingStore()
    @StateObject private var transcriptionService = TranscriptionService()

    var body: some Scene {
        // 对话悬浮窗（主入口，启动时自动打开，常驻置顶）
        WindowGroup("VoxAI", id: "dialog") {
            DialogView()
                .environmentObject(transcriptionService)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.topTrailing)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        // 会议记录窗口（按需打开，标准 macOS 窗口）
        Window("Meeting Notes", id: "meeting") {
            ContentView()
                .environmentObject(meetingStore)
                .environmentObject(transcriptionService)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 600)

        // 菜单栏图标
        MenuBarExtra("VoxAI", systemImage: "waveform.circle.fill") {
            MenuBarView()
                .environmentObject(transcriptionService)
                .environmentObject(meetingStore)
        }
        .menuBarExtraStyle(.window)
    }
}
