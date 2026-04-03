import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var transcriptionService: TranscriptionService

    @AppStorage("recognitionLanguage") var recognitionLanguage = "auto"
    @AppStorage("silenceDuration")     var silenceDuration     = "1.5"
    @AppStorage("cnEngine")            var cnEngine            = "cloud"
    @AppStorage("cnVoice")             var cnVoice             = "xiaoxiao"
    @AppStorage("speechSpeed")         var speechSpeed         = 1.0
    @AppStorage("hfToken")             var hfToken             = ""
    @State private var previewState: PreviewState = .idle

    enum PreviewState { case idle, generating, playing }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // ── 语音输入 ──
                SettingsSection(icon: "mic", title: "Speech Input & Recognition") {
                    SettingsRow(title: "Recognition Language") {
                        SettingsPicker(selection: $recognitionLanguage, options: [
                            ("auto", "Auto Detect"),
                            ("zh",   "Chinese"),
                            ("en",   "English"),
                        ])
                    }
                    Divider().padding(.horizontal, 16)
                    SettingsRow(title: "Silence Detection Duration",
                                subtitle: "Auto-submit after this pause duration") {
                        SettingsPicker(selection: $silenceDuration, options: [
                            ("0.5", "0.5s"),
                            ("1.0", "1.0s"),
                            ("1.5", "1.5s (Recommended)"),
                            ("2.0", "2.0s"),
                        ])
                    }
                }

                // ── 语音输出 ──
                SettingsSection(icon: "speaker.wave.2", title: "Voice Output (TTS)") {
                    SettingsRow(title: "Chinese Engine",
                                subtitle: "Cloud is better quality, local works offline") {
                        SettingsPicker(selection: $cnEngine, options: [
                            ("cloud", "Cloud (edge-tts)"),
                            ("local", "Local (Qwen3-TTS)"),
                        ])
                    }
                    Divider().padding(.horizontal, 16)
                    SettingsRow(title: "Chinese Voice") {
                        SettingsPicker(
                            selection: $cnVoice,
                            options: cnEngine == "local"
                                ? [("Vivian", "Vivian (Female)"), ("Dylan", "Dylan (Male)")]
                                : [("xiaoxiao", "Xiaoxiao (Female)"),
                                   ("yunxi",    "Yunxi (Male)"),
                                   ("xiaoyi",   "Xiaoyi (Female·Lively)")]
                        )
                    }
                    .onChange(of: cnEngine) { _, newEngine in
                        // 切换引擎时重置声音为对应引擎的默认值
                        cnVoice = newEngine == "local" ? "Vivian" : "xiaoxiao"
                    }
                    Divider().padding(.horizontal, 16)

                    // 语速滑块
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Speech Rate")
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            Text(String(format: "%.1fx", speechSpeed))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(hex: "4A6CF7"))
                        }
                        Slider(value: $speechSpeed, in: 0.5...2.0, step: 0.1)
                            .tint(Color(hex: "4A6CF7"))
                        GeometryReader { geo in
                            let w = geo.size.width
                            // 1.0x 在 0.5…2.0 范围内的精确比例位置 = (1.0-0.5)/(2.0-0.5) ≈ 33.3%
                            let pos1x = w * CGFloat((1.0 - 0.5) / (2.0 - 0.5))
                            Text("0.5x")
                                .font(.caption).foregroundStyle(.secondary)
                                .position(x: 12, y: 8)
                            Text("1.0x")
                                .font(.caption).foregroundStyle(.secondary)
                                .position(x: pos1x, y: 8)
                            Text("2.0x")
                                .font(.caption).foregroundStyle(.secondary)
                                .position(x: w - 12, y: 8)
                        }
                        .frame(height: 16)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    Divider().padding(.horizontal, 16)

                    HStack {
                        Spacer()
                        Button(action: previewVoice) {
                            HStack(spacing: 6) {
                                switch previewState {
                                case .idle:
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 11))
                                    Text("Preview Voice")
                                case .generating:
                                    ProgressView().scaleEffect(0.6).frame(width: 12, height: 12)
                                    Text("Generating…")
                                case .playing:
                                    Image(systemName: "waveform")
                                        .font(.system(size: 13))
                                        .symbolEffect(.variableColor.iterative)
                                    Text("Playing…")
                                }
                            }
                            .font(.system(size: 13))
                            .foregroundStyle(previewState == .idle
                                ? Color(NSColor.labelColor) : Color(hex: "4A6CF7"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(Color(NSColor.controlBackgroundColor),
                                        in: RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(
                                        previewState == .idle
                                            ? Color(NSColor.separatorColor)
                                            : Color(hex: "4A6CF7").opacity(0.4),
                                        lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(previewState != .idle)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                }

                // ── 说话人识别 ──
                SettingsSection(icon: "person.2", title: "Speaker Identification (Meeting Mode)") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("HuggingFace Token")
                                    .font(.system(size: 14, weight: .medium))
                                Text("For downloading speaker ID model (free signup)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            SecureField("hf_...", text: $hfToken)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13, design: .monospaced))
                                .frame(width: 180)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(NSColor.controlBackgroundColor),
                                            in: RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(Color(NSColor.separatorColor), lineWidth: 0.5)
                                )
                        }

                        if hfToken.isEmpty {
                            HStack(spacing: 5) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 11))
                                Text("No token configured, speaker ID will be skipped")
                                    .font(.system(size: 11))
                            }
                            .foregroundStyle(.orange)
                        } else {
                            HStack(spacing: 5) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 11))
                                Text("Token configured, model downloads on first use (~1.5 GB)")
                                    .font(.system(size: 11))
                            }
                            .foregroundStyle(.green)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

            }
            .padding(24)
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .onChange(of: recognitionLanguage) { _, _ in
            transcriptionService.updateLanguage()
            updateConfig()
        }
        .onChange(of: cnEngine)    { _, v in updateConfig(engine: v) }
        .onChange(of: cnVoice)     { _, v in updateConfig(voice: v) }
        .onChange(of: speechSpeed) { _, v in updateConfig(speed: v) }
        .onChange(of: hfToken)     { _, v in updateConfig(hfToken: v) }
        // silenceDuration 和 recognitionLanguage 由 TranscriptionService 在下次录音时动态读取，无需回调
    }

    func previewVoice() {
        guard let root = transcriptionService.projectRoot else { return }
        let edgeTTS = root.appendingPathComponent("venv/bin/edge-tts").path
        let voice = ["xiaoxiao": "zh-CN-XiaoxiaoNeural",
                     "yunxi":    "zh-CN-YunxiNeural",
                     "xiaoyi":   "zh-CN-XiaoyiNeural"][cnVoice] ?? "zh-CN-XiaoxiaoNeural"
        let tmp = NSTemporaryDirectory() + "voxsage_preview.mp3"

        previewState = .generating
        DispatchQueue.global(qos: .userInitiated).async {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: edgeTTS)
            proc.arguments = ["--voice", voice, "--text", "这是语音预览，你好。",
                               "--write-media", tmp]
            try? proc.run()
            proc.waitUntilExit()

            DispatchQueue.main.async { previewState = .playing }

            let player = Process()
            player.executableURL = URL(fileURLWithPath: "/usr/bin/afplay")
            player.arguments = [tmp]
            try? player.run()
            player.waitUntilExit()

            DispatchQueue.main.async { previewState = .idle }
        }
    }

    func updateConfig(engine: String? = nil, voice: String? = nil,
                      speed: Double? = nil, hfToken: String? = nil) {
        guard let root = transcriptionService.projectRoot else { return }
        let configPath = root.appendingPathComponent("config.json").path

        var cfg: [String: Any] = [:]
        if let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            cfg = json
        }

        // 写入各项设置
        cfg["recognition_language"] = recognitionLanguage
        cfg["silence_duration"]     = Double(silenceDuration) ?? 1.5
        if let e = engine    { cfg["cn_engine"] = e }
        if let v = voice     { cfg["cn_voice"]  = v }
        if let s = speed     { cfg["speed"]      = s }
        if let t = hfToken   {
            if t.isEmpty { cfg.removeValue(forKey: "hf_token") }
            else         { cfg["hf_token"] = t }
        }

        if let data = try? JSONSerialization.data(withJSONObject: cfg, options: .prettyPrinted) {
            try? data.write(to: URL(fileURLWithPath: configPath))
        }
    }
}

// ── 复用组件 ──────────────────────────────────────────────

struct SettingsSection<Content: View>: View {
    let icon: String
    let title: LocalizedStringKey
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color(NSColor.separatorColor), lineWidth: 0.5)
            )
        }
    }
}

struct SettingsRow<Content: View>: View {
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey? = nil
    @ViewBuilder let trailing: () -> Content

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                if let sub = subtitle {
                    Text(sub)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SettingsPicker: View {
    @Binding var selection: String
    let options: [(String, LocalizedStringKey)]

    var body: some View {
        Menu {
            ForEach(options, id: \.0) { value, label in
                Button(label) { selection = value }
            }
        } label: {
            HStack(spacing: 4) {
                Group {
                    if let currentLabel = options.first(where: { $0.0 == selection })?.1 {
                        Text(currentLabel)
                    } else {
                        Text(selection)
                    }
                }
                .font(.system(size: 14))
                .foregroundStyle(Color(NSColor.labelColor))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}
