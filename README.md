# VoxAI

> Give your AI a voice. Talk to Claude Code, local models, and CLI tools — and have them talk back.

![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

---

## The core idea

Most AI coding tools are text-only. You type, they type back.

VoxAI adds the missing voice layer — on **both sides**:

- **Input**: speak naturally, get real-time transcription
- **Output**: AI responses read aloud through a customizable voice, powered by an MCP server

Connect it to Claude Code, a local model, or any MCP-compatible tool, and you get a complete voice interface for AI-assisted development. **Code with your voice.**

The MCP server exposes TTS as a tool. Your AI calls `speak(text)` and VoxAI handles the rest — no audio pipeline plumbing needed on the AI side.

---

## Screenshots

<table>
  <tr>
    <td align="center" width="50%">
      <img src="docs/screenshots/dialog-idle.png" width="360" alt="Dialog mode — idle"/><br/>
      <sub>Dialog mode — idle</sub>
    </td>
    <td align="center" width="50%">
      <img src="docs/screenshots/dialog-recording.png" width="360" alt="Dialog mode — recording"/><br/>
      <sub>Dialog mode — recording</sub>
    </td>
  </tr>
</table>

<img src="docs/screenshots/meeting-mode.png" width="780" alt="Meeting mode with speaker diarization"/>
<sub>Meeting mode — multi-speaker transcription with speaker labels</sub>

<table>
  <tr>
    <td align="center" width="35%">
      <img src="docs/screenshots/menubar.png" width="240" alt="Menu bar"/><br/>
      <sub>Menu bar</sub>
    </td>
    <td align="center" width="65%">
      <img src="docs/screenshots/settings.png" width="480" alt="Settings"/><br/>
      <sub>Settings — voice engine, speaker diarization</sub>
    </td>
  </tr>
</table>

---

## Features

### 🎙️ Voice output for AI — via MCP
- Expose TTS as an MCP tool: any AI that supports MCP can call `speak(text)` to produce voice output
- Works with **Claude Code**, local models (Ollama, LM Studio), and any MCP-compatible CLI tool
- **Cloud engine**: `edge-tts` — high-quality Microsoft neural voices, no API key needed
- **Local engine**: `Qwen3-TTS` via `mlx-audio` — runs fully offline on Apple Silicon
- Customizable voice, language, and speech rate per session
- `stop_speaking` tool lets the AI interrupt itself mid-sentence

### 🗣️ Real-time voice input
- Floating overlay window stays on top of any app — speak, see text, keep working
- Powered by `SFSpeechRecognizer` + `AVAudioEngine` with automatic session restart at the 60s system limit
- Lyrics-style display: completed segments fade; the active segment stays bright
- Auto-punctuation on macOS 13+

### 📋 Meeting recorder with speaker diarization
- Full-window recording mode for multi-person sessions
- After recording, [whisperx](https://github.com/m-bain/whisperX) identifies and labels each speaker's lines
- Inline speaker renaming — click a label to rename; propagates across all segments
- Export as Markdown, or send directly to an AI for summarization

### ⚙️ Settings
- Switch between cloud and local TTS engine without restarting
- Per-language voice selection (separate Chinese / English voices)
- Silence detection threshold: 0.5s – 2.0s
- HuggingFace token for speaker diarization (optional)
- UI language follows macOS system setting (Chinese / English)

---

## How the MCP integration works

```
You speak
  → VoxAI transcribes in real time
  → text goes to your AI tool (Claude Code, CLI, etc.)
  → AI processes and calls speak(text) via MCP
  → VoxAI reads the response aloud
```

The MCP server runs locally alongside the app. Configure your AI tool to connect to it, and voice I/O is handled automatically.

Available MCP tools:

| Tool | Description |
|---|---|
| `speak(text, voice?, speed?)` | Speak text aloud with optional voice/speed override |
| `stop_speaking()` | Interrupt current playback |
| `list_voices()` | List available voices for current engine |
| `update_voice_config(...)` | Change engine, voice, or speed at runtime |
| `list_meetings()` | List all recorded meetings with metadata |
| `get_meeting(id)` | Get full transcript for a meeting |

---

## Tech stack

| Layer | Technology |
|---|---|
| App | Swift 5.9 + SwiftUI, macOS 14+ |
| Real-time ASR | `SFSpeechRecognizer` + `AVAudioEngine` |
| Offline transcription + diarization | [whisperx](https://github.com/m-bain/whisperX) 3.8.5 |
| Local TTS | [mlx-audio](https://github.com/Blaizzy/mlx-audio) + Qwen3-TTS-0.6B (Apple Silicon) |
| Cloud TTS | [edge-tts](https://github.com/rany2/edge-tts) |
| AI integration | [MCP](https://modelcontextprotocol.io/) server (Python) |
| Python runtime | venv (Python 3.13) |

---

## Architecture highlights

**Session generation counter** — `SFSpeechRecognizer` sessions timeout at ~60s. Each restart increments a generation counter; stale callbacks compare their captured generation and early-return if mismatched. This prevents old results from writing into the current segment after a restart.

**Continuous WAV recording across session restarts** — `AVAudioFile` stays open across recognition session restarts so meeting audio is one contiguous file, ready for whisperx diarization after the session ends.

**Window management via stored references** — rather than looking up windows by title (fragile with localization), `TranscriptionService` stores direct `NSWindow` references for both the floating dialog and meeting windows. Switching modes is an `orderOut` + `makeKeyAndOrderFront` on the stored references.

**Stable speaker colors** — Swift's `hashValue` is randomized per-launch. Speaker colors use a unicode scalar reduce hash instead, giving each speaker a stable color across sessions.

---

## Setup

### Requirements

- macOS 14 (Sonoma) or later
- Python 3.11+ (for the backend)
- Xcode 15+ (to build from source)

### Quick start

```bash
git clone https://github.com/Ethan-YS/VoxAI.git
cd VoxAI

# Set up Python backend
python3 -m venv venv
source venv/bin/activate
pip install whisperx mlx-audio edge-tts

# Configure
cp config.example.json config.json
# Edit config.json — add your HuggingFace token for speaker diarization (optional)

# Build and run the app
open VoxSage-App/VoxSage.xcodeproj
```

Grant microphone and speech recognition permissions when prompted.

### Connect to Claude Code

Add to your Claude Code MCP config:

```json
{
  "mcpServers": {
    "voxai": {
      "command": "/path/to/VoxAI/venv/bin/python3",
      "args": ["/path/to/VoxAI/src/mcp/server.py"]
    }
  }
}
```

### config.json options

```json
{
  "cn_engine": "cloud",
  "cn_voice": "xiaoxiao",
  "en_voice": "default",
  "speed": 1.0,
  "language": "auto",
  "hf_token": "hf_...",
  "silence_duration": 1.5,
  "recognition_language": "auto"
}
```

---

## Download

Pre-built `.dmg` for Apple Silicon is available on the [Releases](../../releases) page.

---

## Project structure

```
VoxSage-App/VoxSage/
├── VoxSageApp.swift              # Entry point — 3 scenes: dialog / meeting / menubar
├── ContentView.swift             # Meeting window — 3-panel layout
├── Views/
│   ├── DialogView.swift          # Floating overlay + lyrics view
│   ├── MeetingView.swift         # Menubar dropdown
│   └── SettingsView.swift        # Settings panel
├── Services/
│   └── TranscriptionService.swift  # Audio engine, ASR session management
├── Models/
│   └── MeetingStore.swift        # Meeting persistence + diarization orchestration
└── zh-Hans.lproj/
    └── Localizable.strings       # Chinese localization

src/
├── mcp/server.py                 # MCP server — TTS tools + meeting data access
└── stt/diarize.py                # whisperx diarization script
```

---

## License

MIT
