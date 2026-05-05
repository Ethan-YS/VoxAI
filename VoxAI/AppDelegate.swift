//
//  AppDelegate.swift
//  VoxAI
//
//  Owns the dialog NSPanel. Replaces the SwiftUI `Window` scene because
//  that scene didn't reliably honor `.floating` window level under
//  macOS 26 + LSUIElement = YES — SwiftUI's internal window plumbing
//  kept resetting the level back to .normal during state transitions.
//
//  NSPanel is macOS's purpose-built class for utility / floating windows.
//  Setting `isFloatingPanel = true` is an OS-level commitment; SwiftUI
//  doesn't touch it. We construct the panel once in
//  `applicationDidFinishLaunching`, host the SwiftUI DialogView inside
//  it via NSHostingController, and expose `showDialog()` / `hideDialog()`
//  to the rest of the app (the menu bar's "Show Dialog" entry, the
//  dialog's own close button).
//

import AppKit
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    /// Controller that the SwiftUI DialogView uses to ask the panel to
    /// close. Injected as an EnvironmentObject so DialogView's close
    /// button can call `controller.close()` without knowing anything
    /// about NSPanel.
    let dialogController = DialogPanelController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Build the panel + show it on launch. The user expects the
        // dialog to be visible immediately after launching VoxAI.
        showDialog()

        // SwiftUI quirk: with LSUIElement = YES and no `Window` /
        // `WindowGroup` scene declared (we host the dialog as an
        // NSPanel via this AppDelegate, not a SwiftUI scene), SwiftUI
        // falls back to opening its `Settings` scene at launch as the
        // "default visible window" — which is wrong; Settings should
        // only open when the user asks for it (⌘, or menu bar entry).
        // Close any window whose role looks like the Settings window
        // a beat after launch, once SwiftUI has had a chance to
        // materialize it.
        DispatchQueue.main.async {
            self.closeAutoOpenedSettingsWindow()
        }
    }

    /// Hunt down the Settings window that SwiftUI auto-opens on launch
    /// and close it. We identify it heuristically because SwiftUI doesn't
    /// expose a stable identifier for the Settings scene's window. The
    /// detection is conservative — it skips our floating dialog panel
    /// and the menu-bar status item window.
    private func closeAutoOpenedSettingsWindow() {
        for window in NSApp.windows {
            // Skip our own dialog panel.
            if window === dialogController.panel { continue }
            // Skip the menu-bar status window (NSStatusBarWindow private class).
            if String(describing: type(of: window)).contains("StatusBar") { continue }
            // Skip menu-bar popover host.
            if String(describing: type(of: window)).contains("PopoverWindow") { continue }
            // Skip windows that aren't visible (no need to close hidden ones).
            guard window.isVisible else { continue }

            // Anything else visible right after launch is almost certainly
            // the Settings window SwiftUI just opened. Close it.
            window.close()
        }
    }

    /// Re-open the dialog when the user activates the app from the
    /// menu bar (e.g. clicks the menu bar icon). This is the canonical
    /// "show me the window" entry point on macOS.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        showDialog()
        return false
    }

    func showDialog() {
        if dialogController.panel == nil {
            buildPanel()
        }
        dialogController.panel?.makeKeyAndOrderFront(nil)
    }

    func hideDialog() {
        dialogController.panel?.orderOut(nil)
    }

    // MARK: - Panel construction

    private func buildPanel() {
        let panelSize = NSSize(width: 420, height: 420)

        // .borderless: no title bar / standard window chrome.
        // .fullSizeContentView: SwiftUI content extends edge-to-edge.
        // .nonactivatingPanel: clicking the panel doesn't activate VoxAI
        //   as the foreground app (so user can dictate while another
        //   app keeps focus — important for the "用嘴编程" flow).
        let panel = VoxAIPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.borderless, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // The reason this whole file exists: NSPanel-level guarantees
        // that the SwiftUI Window scene wouldn't honor.
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true   // don't steal focus on click
        panel.hidesOnDeactivate = false        // stay visible when other app is frontmost
        panel.level = .floating                // float above all normal windows
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .fullScreenAuxiliary,
        ]

        // Visual: transparent background so SwiftUI's RoundedRectangle
        // shape mask shows through.
        panel.isOpaque = false
        panel.backgroundColor = .clear
        // hasShadow = true here is critical: with isOpaque = false,
        // macOS draws the window shadow following the contentView's
        // alpha mask (i.e. the SwiftUI RoundedRectangle outline) instead
        // of the panel's rectangular bounds. This gives us a rounded,
        // softly-shadowed card. Setting it to false (as I mistakenly did
        // in the first NSPanel commit) leaves the window with NO shadow
        // at all, so the floating dialog reads as just a flat shape with
        // no separation from whatever's behind it. SwiftUI's own
        // `.shadow(...)` modifier can't substitute — the shadow halo
        // extends past the SwiftUI .frame and gets clipped by the panel.
        panel.hasShadow = true

        // Drag-by-background — borderless windows are otherwise un-draggable.
        panel.isMovableByWindowBackground = true

        // Title bar invisible (we use .borderless but belt + suspenders).
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true

        // Inject the SwiftUI view as the content.
        //
        // Why NSHostingView (NSView subclass) instead of NSHostingController:
        //   When we used NSHostingController, the hosting layer's sizing
        //   ignored DialogView's `.frame(width: 420, height: 420)` and the
        //   outer RoundedRectangle ended up only filling the title-bar
        //   slice of the panel — the rest stayed transparent (Rebecca's
        //   "他现在看起来不像一个弹窗" smoke test). NSHostingView is the
        //   plain NSView wrapper, and combined with .width/.height
        //   autoresizing it makes the SwiftUI content authoritatively fill
        //   the panel's contentView. EnvironmentObjects flow the same way.
        let hostingView = NSHostingView(
            rootView: DialogView()
                .environmentObject(TranscriptionService.shared)
                .environmentObject(AppSettings.shared)
                .environmentObject(dialogController)
        )
        hostingView.frame = NSRect(origin: .zero, size: panelSize)
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView
        panel.setContentSize(panelSize)

        // Position: top-right of the main screen's visible frame, with
        // a 20pt inset so it doesn't kiss the menu bar.
        if let screen = NSScreen.main {
            let visible = screen.visibleFrame
            let origin = NSPoint(
                x: visible.maxX - panelSize.width - 20,
                y: visible.maxY - panelSize.height - 20
            )
            panel.setFrameOrigin(origin)
        }

        dialogController.panel = panel
    }
}

// MARK: - VoxAIPanel
//
// NSPanel by default refuses to become key when borderless. Overriding
// `canBecomeKey` makes the panel respond to keyboard input (necessary
// for the alert keyboard shortcuts and any future text fields).

final class VoxAIPanel: NSPanel {
    override var canBecomeKey: Bool { true }

    // We don't want the panel to be the "main" window — that's a SwiftUI/
    // AppKit concept tied to menu commands. Returning false here keeps
    // standard menus pointed at NSApp instead of our floating panel.
    override var canBecomeMain: Bool { false }
}

// MARK: - DialogPanelController
//
// Lightweight bridge between AppDelegate (which holds the panel
// reference) and DialogView (which needs to ask the panel to close
// when the user hits the ✕ button). Published as an EnvironmentObject
// so DialogView can access it without a hard reference to AppDelegate.

@MainActor
final class DialogPanelController: ObservableObject {
    /// Set by AppDelegate after `buildPanel()`. Held weakly so that if
    /// the panel ever gets dismantled, this controller doesn't keep it
    /// alive past its useful life.
    weak var panel: NSPanel?

    /// DialogView calls this from its close button.
    func close() {
        panel?.orderOut(nil)
    }
}
