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

        // MARK: - Settings (real UI, Phase 2.1)
        //
        // SwiftUI's `Settings` scene gives us the standard ⌘, affordance
        // and a system-managed Settings window — no custom Window plumbing
        // required. v1.0 SettingsView is intentionally minimal: just the
        // "auto-copy to clipboard" toggle (DR-020) plus an About card.
        // Future versions will expand here as new features land.
        Settings {
            SettingsView()
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
                hasError: transcriptionService.lastError != nil,
                onShowDialog: { openWindow(id: "dialog") }
            )
        } label: {
            // Why an SF Symbol here instead of `VoxAILogoMark`:
            //   The menu bar pipeline expects a simple template image —
            //   it rasterizes label content into a small monochrome bitmap
            //   and applies the system's menu-bar tint. VoxAILogoMark is a
            //   composition of many tiny SwiftUI shapes (mic yoke, two
            //   sparkles, four waveform bars, ring, capsule) plus
            //   `Color.primary`, which doesn't always resolve correctly in
            //   the menu-bar context. Net result: at 18px the whole icon
            //   sometimes renders blank — visible in Rebecca's smoke test
            //   where the icon disappeared from the bar entirely.
            //
            // SF Symbols are designed for this surface: clean glyph,
            // automatic template tinting, weight that matches the bar.
            // We still use the rich VoxAILogoMark inside the dialog
            // title bar where 28px and full color rendering makes sense.
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
        // SettingsLink is macOS 14+ — gives us a button that opens the
        // Settings scene with the standard ⌘, shortcut. On macOS 13 we
        // fall back to manually invoking the standard "showSettingsWindow:"
        // Cocoa selector, which the Settings scene wires up.
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

// SettingsPlaceholderView was removed in Phase 2.1 — replaced by the
// real SettingsView in Views/SettingsView.swift.
