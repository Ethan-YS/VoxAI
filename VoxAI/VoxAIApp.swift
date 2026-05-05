//
//  VoxAIApp.swift
//  VoxAI
//
//  App entry. Wires up the AppDelegate (which owns the dialog NSPanel)
//  and exposes two SwiftUI Scenes:
//
//    1. Settings — system Settings window (⌘, affordance built-in).
//    2. MenuBarExtra — the only re-entry point because LSUIElement = YES
//       means VoxAI has no Dock icon.
//
//  The dialog window IS NOT a SwiftUI Scene anymore. AppDelegate owns it
//  as an NSPanel (see AppDelegate.swift). This is a deliberate departure
//  from Phase 1.7's design — under macOS 26 + LSUIElement = YES, SwiftUI
//  `Window` scene's window plumbing kept resetting `.floating` level
//  back to `.normal` during state transitions. NSPanel's
//  `isFloatingPanel = true` is OS-level and SwiftUI doesn't override it.
//

import SwiftUI

@main
struct VoxAIApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    /// Cached references so the SwiftUI scenes can pull them into their
    /// environment without re-creating singletons each render.
    @StateObject private var settings = AppSettings.shared
    @StateObject private var transcriptionService = TranscriptionService.shared

    var body: some Scene {
        // MARK: - Settings (system-managed window, ⌘, opens it)
        Settings {
            SettingsView()
                .environmentObject(settings)
        }

        // MARK: - Menu bar
        //
        // The only re-entry point because Info.plist has LSUIElement = YES
        // (no Dock icon). Triggers AppDelegate.showDialog() to bring the
        // panel back when the user has closed it.
        MenuBarExtra {
            MenuBarContent(
                state: transcriptionService.state,
                hasError: transcriptionService.lastError != nil,
                onShowDialog: { appDelegate.showDialog() }
            )
        } label: {
            // SF Symbol — see comment in earlier commit; the menu bar
            // pipeline doesn't render arbitrary SwiftUI compositions
            // reliably at small sizes.
            Image(systemName: menuBarSymbol)
                .accessibilityLabel(menuBarAccessibilityLabel(for: transcriptionService.state))
        }
    }

    /// Symbol used for the menu bar label.
    /// - Error always wins (warning triangle).
    /// - Otherwise reflect recording state with the canonical
    ///   `waveform.circle` / `waveform.circle.fill`.
    private var menuBarSymbol: String {
        if transcriptionService.lastError != nil {
            return "exclamationmark.triangle.fill"
        }
        switch transcriptionService.state {
        case .idle:                   return "waveform.circle"
        case .recording, .paused:     return "waveform.circle.fill"
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
    let hasError: Bool
    let onShowDialog: () -> Void

    var body: some View {
        // Status row — non-interactive, just confirms what the icon shows
        HStack {
            Image(systemName: hasError ? "exclamationmark.triangle.fill" : stateIcon)
                .foregroundStyle(hasError ? .orange : stateColor)
            Text(hasError ? "有错误 / Error" : stateLabel)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)

        Divider()

        Button(action: onShowDialog) {
            Label("显示浮窗 / Show Dialog", systemImage: "rectangle.on.rectangle")
        }
        .keyboardShortcut("d", modifiers: [.command, .shift])

        // Settings entry point.
        // SettingsLink (macOS 14+) gets us the standard ⌘, shortcut wiring;
        // on macOS 13 we fall back to the named selector that the Settings
        // scene registers.
        if #available(macOS 14, *) {
            SettingsLink {
                Label("设置 / Settings", systemImage: "gearshape")
            }
            .keyboardShortcut(",", modifiers: .command)
        } else {
            Button {
                openSettingsLegacy()
            } label: {
                Label("设置 / Settings", systemImage: "gearshape")
            }
            .keyboardShortcut(",", modifiers: .command)
        }

        Divider()

        Button("退出 VoxAI / Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }

    /// macOS 13 fallback for opening the Settings scene.
    /// SwiftUI's Settings scene registers itself with both the legacy
    /// `showPreferencesWindow:` selector (pre-14) and the newer
    /// `showSettingsWindow:` selector. Try the new one first, fall back.
    private func openSettingsLegacy() {
        let selectors: [Selector] = [
            Selector(("showSettingsWindow:")),
            Selector(("showPreferencesWindow:")),
        ]
        for sel in selectors where NSApp.responds(to: sel) {
            NSApp.sendAction(sel, to: nil, from: nil)
            return
        }
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
