//
//  AppSettings.swift
//  VoxAI
//
//  Single source of truth for user-facing configuration.
//
//  Storage split:
//    - Most fields go through UserDefaults (sandbox-private, automatic
//      iCloud-key-value sync NOT used in v1).
//    - Cloud TTS API key goes through macOS Keychain (DR-009, stubbed
//      until Phase 2.4 wires up the actual KeychainHelper).
//    - MCP server port + token live in
//      `Application Support/VoxAI/mcp-config.json` and are owned by
//      MCPServer, not by AppSettings.
//
//  Why ObservableObject (and not @Observable):
//    Deployment target is macOS 13.0 (DR-005); the new Observation
//    runtime requires macOS 14+. Stick with ObservableObject for v1.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class AppSettings: ObservableObject {

    /// Singleton entry point. Service layer and views share this instance.
    /// Tests that need isolation can construct a fresh instance with a
    /// suite-specific UserDefaults via `init(defaults:)`.
    static let shared = AppSettings()

    // MARK: - Recognition

    enum RecognitionLanguage: String, CaseIterable, Identifiable {
        case auto
        case chineseSimplified = "zh-CN"
        case english = "en-US"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .auto: return "自动 / Auto"
            case .chineseSimplified: return "中文 (简体)"
            case .english: return "English"
            }
        }
    }

    @Published var recognitionLanguage: RecognitionLanguage {
        didSet { defaults.set(recognitionLanguage.rawValue, forKey: K.recognitionLanguage) }
    }

    // MARK: - TTS engine selection

    enum TTSEngineKind: String, CaseIterable, Identifiable {
        case system
        case cloud

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .system: return "System (内置 / built-in)"
            case .cloud:  return "Cloud (OpenAI 兼容)"
            }
        }
    }

    @Published var ttsEngine: TTSEngineKind {
        didSet { defaults.set(ttsEngine.rawValue, forKey: K.ttsEngine) }
    }

    // MARK: - System TTS voices
    //
    // `nil` means "let SystemTTSEngine pick a sensible default at runtime
    // based on what the OS exposes". v1.4 doesn't bake in voice IDs because
    // available voices depend on macOS version and downloaded voice packs.

    @Published var systemVoiceChinese: String? {
        didSet { defaults.setOrRemove(systemVoiceChinese, forKey: K.systemVoiceChinese) }
    }

    @Published var systemVoiceEnglish: String? {
        didSet { defaults.setOrRemove(systemVoiceEnglish, forKey: K.systemVoiceEnglish) }
    }

    // MARK: - Cloud TTS (OpenAI-compatible HTTP)

    /// Endpoint base URL. v1 ships with OpenAI's official endpoint; users
    /// who want OpenAI-compatible proxies (e.g. self-hosted edge-tts mirror,
    /// TokenMix) can edit this. See PROJECT.md / DR-008.
    @Published var cloudBaseURL: String {
        didSet { defaults.set(cloudBaseURL, forKey: K.cloudBaseURL) }
    }

    /// OpenAI TTS model. Common values: `tts-1` (fast), `tts-1-hd` (high
    /// quality), `gpt-4o-mini-tts` (newest tier).
    @Published var cloudModel: String {
        didSet { defaults.set(cloudModel, forKey: K.cloudModel) }
    }

    /// Voice ID. OpenAI standard set: alloy / echo / fable / onyx / nova /
    /// shimmer. Custom strings are allowed for compatible proxies.
    @Published var cloudVoice: String {
        didSet { defaults.set(cloudVoice, forKey: K.cloudVoice) }
    }

    /// Cloud TTS API key — Keychain-backed, **never** in UserDefaults (DR-009).
    ///
    /// Phase 2.4 will replace these stubs with calls into a `KeychainHelper`.
    /// Until then, getter returns nil (Cloud TTS effectively unavailable in
    /// pre-2.4 builds) and setter is a no-op. SettingsView still gets a
    /// usable property to bind against.
    var cloudAPIKey: String? {
        get {
            // TODO(Phase 2.4): KeychainHelper.read(service: "voxai.cloud", account: "openai-api-key")
            return nil
        }
        set {
            // TODO(Phase 2.4): KeychainHelper.write(newValue, service: "voxai.cloud", account: "openai-api-key")
            _ = newValue // silence unused-parameter warning in stub
        }
    }

    // MARK: - Speech rate

    /// Playback speed multiplier. 0.5 = half speed, 2.0 = double speed.
    /// Both System and Cloud engines clamp to their own valid ranges.
    @Published var speechRate: Double {
        didSet { defaults.set(speechRate, forKey: K.speechRate) }
    }

    // MARK: - "用嘴编程" UX (DR-020)

    /// Auto-copy transcribed text to NSPasteboard the moment recording stops.
    /// Defaults to `true` — this is the core "用嘴编程" flow win.
    @Published var autoCopyToClipboard: Bool {
        didSet { defaults.set(autoCopyToClipboard, forKey: K.autoCopyToClipboard) }
    }

    // MARK: - Storage

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        self.recognitionLanguage = RecognitionLanguage(
            rawValue: defaults.string(forKey: K.recognitionLanguage) ?? RecognitionLanguage.auto.rawValue
        ) ?? .auto

        self.ttsEngine = TTSEngineKind(
            rawValue: defaults.string(forKey: K.ttsEngine) ?? TTSEngineKind.system.rawValue
        ) ?? .system

        self.systemVoiceChinese = defaults.string(forKey: K.systemVoiceChinese)
        self.systemVoiceEnglish = defaults.string(forKey: K.systemVoiceEnglish)

        self.cloudBaseURL = defaults.string(forKey: K.cloudBaseURL) ?? Defaults.cloudBaseURL
        self.cloudModel   = defaults.string(forKey: K.cloudModel)   ?? Defaults.cloudModel
        self.cloudVoice   = defaults.string(forKey: K.cloudVoice)   ?? Defaults.cloudVoice

        self.speechRate = (defaults.object(forKey: K.speechRate) as? Double) ?? Defaults.speechRate

        // Default `autoCopyToClipboard` to true on first launch (DR-020),
        // but honor the user's choice on subsequent launches.
        if defaults.object(forKey: K.autoCopyToClipboard) == nil {
            self.autoCopyToClipboard = Defaults.autoCopyToClipboard
        } else {
            self.autoCopyToClipboard = defaults.bool(forKey: K.autoCopyToClipboard)
        }
    }

    // MARK: - Reset

    /// Restore every UserDefaults-backed field to its default. Useful for
    /// "Reset to Defaults" in Settings or for test setup.
    /// Does NOT touch Keychain — call `cloudAPIKey = nil` separately.
    func resetToDefaults() {
        for key in K.allUserDefaultsKeys {
            defaults.removeObject(forKey: key)
        }
        // Re-publish defaults so observers see the change immediately.
        recognitionLanguage = .auto
        ttsEngine           = .system
        systemVoiceChinese  = nil
        systemVoiceEnglish  = nil
        cloudBaseURL        = Defaults.cloudBaseURL
        cloudModel          = Defaults.cloudModel
        cloudVoice          = Defaults.cloudVoice
        speechRate          = Defaults.speechRate
        autoCopyToClipboard = Defaults.autoCopyToClipboard
    }

    // MARK: - Constants

    private enum Defaults {
        static let cloudBaseURL = "https://api.openai.com/v1"
        static let cloudModel   = "tts-1"
        static let cloudVoice   = "alloy"
        static let speechRate: Double = 1.0
        static let autoCopyToClipboard = true   // DR-020
    }

    private enum K {
        static let recognitionLanguage = "voxai.recognitionLanguage"
        static let ttsEngine           = "voxai.ttsEngine"
        static let systemVoiceChinese  = "voxai.systemVoiceChinese"
        static let systemVoiceEnglish  = "voxai.systemVoiceEnglish"
        static let cloudBaseURL        = "voxai.cloudBaseURL"
        static let cloudModel          = "voxai.cloudModel"
        static let cloudVoice          = "voxai.cloudVoice"
        static let speechRate          = "voxai.speechRate"
        static let autoCopyToClipboard = "voxai.autoCopyToClipboard"

        static let allUserDefaultsKeys: [String] = [
            recognitionLanguage, ttsEngine,
            systemVoiceChinese, systemVoiceEnglish,
            cloudBaseURL, cloudModel, cloudVoice,
            speechRate, autoCopyToClipboard,
        ]
    }
}

// MARK: - Helpers

private extension UserDefaults {
    /// Set the value, or remove the key if the value is nil. Keeps optional
    /// strings round-tripping cleanly through UserDefaults.
    func setOrRemove(_ value: String?, forKey key: String) {
        if let value {
            set(value, forKey: key)
        } else {
            removeObject(forKey: key)
        }
    }
}
