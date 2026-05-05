//
//  SettingsView.swift
//  VoxAI
//
//  v1.0 极简版设置面板。
//
//  Scope (per DR-021 / DR-022 / DR-023 / DR-024):
//    - ONLY one user-facing toggle: "auto-copy to clipboard" (DR-020)
//    - Plus an About card (version, privacy policy link, GitHub link)
//    - NOT included: language switcher (DR-023), TTS engine config
//      (DR-021), Cloud config (DR-021), MCP config (DR-022)
//
//  Why so spare:
//    v1.0 ships an MVP slice — the only user-tunable behavior is whether
//    auto-copy happens on stop. Every other setting either has no effect
//    in v1.0 (the field exists in AppSettings but no feature consumes it)
//    or doesn't exist yet. Keeping Settings small reduces user confusion
//    AND App Store review surface.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    /// Marketing version, read at runtime from the app bundle so we
    /// don't have to hard-code "1.0" here.
    private var marketingVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    /// Build number — useful when debugging "is this the build I just shipped".
    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    var body: some View {
        Form {
            // MARK: - 录音 / Recording

            Section {
                Toggle(isOn: $settings.autoCopyToClipboard) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("录音停止后自动复制到剪贴板")
                        Text("Auto-copy to clipboard on stop")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .help("关闭后，录音停止时不会自动复制——你需要点浮窗里的复制按钮。")
            } header: {
                Text("录音 / Recording")
            } footer: {
                Text("默认开启。这是 VoxAI 的核心体验——说完话立即可以在 Claude / Cursor 里 ⌘V 粘贴。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // MARK: - 关于 / About

            Section {
                LabeledContent("版本 / Version", value: "\(marketingVersion) (\(buildNumber))")

                Link(destination: URL(string: "https://ethan-ys.github.io/VoxAI/privacy.html")!) {
                    HStack {
                        Image(systemName: "hand.raised")
                            .foregroundStyle(.secondary)
                            .frame(width: 16)
                        Text("隐私政策 / Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Link(destination: URL(string: "https://github.com/Ethan-YS/VoxAI")!) {
                    HStack {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .foregroundStyle(.secondary)
                            .frame(width: 16)
                        Text("GitHub 仓库 / Source Code")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } header: {
                Text("关于 / About")
            } footer: {
                Text("VoxAI 由 Ethan 制作。MIT 协议开源。\n感谢使用。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }

            // MARK: - v1.x 占位提示
            //
            // Tells the user that more options will arrive in future versions.
            // This avoids "where's the language switcher?" / "where's TTS?"
            // confusion for users who try things and don't find them.

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("更多设置即将到来", systemImage: "sparkles")
                        .font(.callout)
                        .fontWeight(.medium)

                    Text("v1.0 聚焦「用嘴编程」主流程。基于早期用户反馈，未来版本会评估加入语言切换、AI 朗读、MCP 服务等高级功能。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("v1.0 focuses on the core dictation flow. Based on early user feedback, future versions will evaluate adding language switching, AI read-aloud, MCP server, and other advanced features.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 460)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings.shared)
}
