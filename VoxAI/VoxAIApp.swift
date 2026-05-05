//
//  VoxAIApp.swift
//  VoxAI
//
//  App entry. Wires up shared singletons (AppSettings, TranscriptionService)
//  and exposes three Scenes:
//
//    1. dialog (WindowGroup) — the primary, always-on-top floating panel
//       that hosts DialogView. Opens automatically at launch.
//    2. Settings — placeholder for v1.7; Phase 2.7 fills in the real UI.
//    3. MenuBarExtra — provides re-open access when the user has closed
//       the dialog window (and a Quit fallback).
//
//  Single-instance behavior:
//    macOS Launch Services already prevents double-launch of the same
//    bundle on a normal `open` invocation; the v1 build does NOT add an
//    explicit single-instance lock. Phase 2.5 (MCPServer port binding)
//    will revisit this if `open -n` style multi-launch becomes a real
//    failure mode.
//

import SwiftUI

@main
struct VoxAIApp: App {

    @StateObject private var settings: AppSettings
    @StateObject private var transcriptionService: TranscriptionService

    @Environment(\.openWindow) private var openWindow

    init() {
        // SwiftUI's App protocol is MainActor-isolated, so this init runs
        // on the main actor and can read AppSettings.shared (which is also
        // MainActor-isolated). Both shared singletons are wrapped as
        // StateObjects so SwiftUI manages their lifetime correctly.
        let appSettings = AppSettings.shared
        _settings = StateObject(wrappedValue: appSettings)
        _transcriptionService = StateObject(
            wrappedValue: TranscriptionService(settings: appSettings)
        )
    }

    var body: some Scene {
        // MARK: - Main floating dialog
        //
        // Why `Window` (singleton) and NOT `WindowGroup`:
        //   `WindowGroup` allows multiple instances of the same scene id —
        //   every `openWindow(id: "dialog")` from the menu bar would stack
        //   yet another floating panel on top, which is exactly what we
        //   saw the first time we tested. `Window` gives us a single
        //   instance that gets refocused (instead of recreated) when
        //   openWindow is called again.
        //
        // Window styling is applied inside DialogView via WindowAccessor —
        // .hiddenTitleBar here is just a cosmetic safety net.
        Window("VoxAI", id: "dialog") {
            DialogView()
                .environmentObject(transcriptionService)
                .environmentObject(settings)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.topTrailing)
        .commands {
            // Nothing to "create" in this app — hide the default New menu.
            CommandGroup(replacing: .newItem) {}
        }

        // MARK: - Settings (placeholder, Phase 2.7 fills in the real UI)
        //
        // Using SwiftUI's `Settings` scene gives us the standard ⌘,
        // affordance and a system-managed Settings window — no custom
        // Window plumbing required. The placeholder content is intentional
        // so v1.7 builds run without a fake "Settings…" menu item that
        // leads nowhere.
        Settings {
            SettingsPlaceholderView()
                .environmentObject(transcriptionService)
                .environmentObject(settings)
        }

        // MARK: - Menu bar
        //
        // Because Info.plist has LSUIElement = YES (menu-bar app, no Dock
        // icon), this is the user's only re-entry point once they close
        // the floating dialog. v1.7 keeps it minimal: state-aware icon +
        // "Show Dialog" + "Quit". Phase 2.7 will add a Settings link and
        // Phase 2.8 will add error-state badging.
        MenuBarExtra {
            MenuBarContent(
                state: transcriptionService.state,
                onShowDialog: { openWindow(id: "dialog") }
            )
        } label: {
            VoxAILogoMark(style: .template, size: 18)
                .accessibilityLabel(menuBarAccessibilityLabel(for: transcriptionService.state))
        }
    }

    private func menuBarAccessibilityLabel(for state: RecordingState) -> String {
        switch state {
        case .idle:      return "VoxAI idle"
        case .recording: return "VoxAI recording"
        case .paused:    return "VoxAI paused"
        }
    }
}

// MARK: - Menu bar content

private struct MenuBarContent: View {
    let state: RecordingState
    let onShowDialog: () -> Void

    var body: some View {
        // Status row — non-interactive, just confirms what the icon shows
        HStack {
            Image(systemName: stateIcon)
                .foregroundStyle(stateColor)
            Text(stateLabel)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)

        Divider()

        Button(action: onShowDialog) {
            Label("显示浮窗 / Show Dialog", systemImage: "rectangle.on.rectangle")
        }
        .keyboardShortcut("d", modifiers: [.command, .shift])

        Divider()

        Button("退出 VoxAI / Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }

    private var stateIcon: String {
        switch state {
        case .idle:      return "circle.dotted"
        case .recording: return "waveform"
        case .paused:    return "pause.circle"
        }
    }

    private var stateColor: Color {
        switch state {
        case .idle:      return .secondary
        case .recording: return .red
        case .paused:    return .orange
        }
    }

    private var stateLabel: String {
        switch state {
        case .idle:      return "待机 / Idle"
        case .recording: return "录音中 / Recording"
        case .paused:    return "已暂停 / Paused"
        }
    }
}

// MARK: - Settings placeholder (Phase 2.7 will replace this)

private struct SettingsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "gearshape")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("设置 / Settings")
                .font(.title2)
                .fontWeight(.semibold)
            Text("完整设置面板将在 Phase 2.7 加入。\nFull settings panel will be added in Phase 2.7.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(width: 480, height: 320)
    }
}
