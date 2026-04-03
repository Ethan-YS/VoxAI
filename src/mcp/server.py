#!/usr/bin/env python3
"""
VoxSage MCP Server
提供 speak() / list_voices() / stop_speaking() 工具给 Claude 调用

TTS 路由：
  中文 + 云端模式 → edge-tts CLI（需联网）
  中文 + 本地模式 → Qwen3-TTS via mlx-audio（离线，MLX 原生）
  英文            → Chatterbox TTS（离线）
"""

import os
import re
import json
import threading
import tempfile
import subprocess
import numpy as np
import torch

from fastmcp import FastMCP

PROJECT_ROOT  = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
VOICES_DIR    = os.path.join(PROJECT_ROOT, "voices")
CONFIG_PATH   = os.path.join(PROJECT_ROOT, "config.json")
EDGE_TTS_BIN  = os.path.join(PROJECT_ROOT, "venv", "bin", "edge-tts")

# Qwen3-TTS 模型 ID（HuggingFace，mlx-audio 自动缓存）
QWEN3_TTS_MODEL = "mlx-community/Qwen3-TTS-12Hz-0.6B-Base-8bit"
QWEN3_VOICE     = "Vivian"   # 中文女声，可选：Vivian / Dylan（北京话男声）

mcp = FastMCP("VoxSage")

# ── 默认配置 ──────────────────────────────────────────────
DEFAULT_CONFIG = {
    "cn_engine":  "cloud",               # "cloud" | "local"
    "cn_voice":   "xiaoxiao",            # cloud: xiaoxiao/yunxi/xiaoyi  local: zf_001/zm_010
    "en_voice":   "default",
    "speed":      1.0,                   # 0.5 ~ 2.0
    "language":   "auto",                # "auto" | "zh" | "en"
}

CLOUD_VOICES = {
    "xiaoxiao": "zh-CN-XiaoxiaoNeural",
    "yunxi":    "zh-CN-YunxiNeural",
    "xiaoyi":   "zh-CN-XiaoyiNeural",
}

# ── 全局状态 ──────────────────────────────────────────────
_chatterbox   = None
_tts_lock     = threading.Lock()
_play_thread: threading.Thread | None = None
_play_proc:   subprocess.Popen | None = None
_stop_flag    = threading.Event()


def _load_config() -> dict:
    if os.path.exists(CONFIG_PATH):
        try:
            with open(CONFIG_PATH) as f:
                cfg = json.load(f)
            return {**DEFAULT_CONFIG, **cfg}
        except Exception:
            pass
    return DEFAULT_CONFIG.copy()


def _is_chinese(text: str) -> bool:
    chinese = len(re.findall(r'[\u4e00-\u9fff]', text))
    return chinese / max(len(text), 1) > 0.2


# ── Chatterbox（英文） ─────────────────────────────────────
def _get_chatterbox():
    global _chatterbox
    if _chatterbox is None:
        from chatterbox.tts import ChatterboxTTS
        device = "mps" if torch.backends.mps.is_available() else "cpu"
        _chatterbox = ChatterboxTTS.from_pretrained(device=device)
    return _chatterbox


# ── Qwen3-TTS（中文本地，mlx-audio） ─────────────────────
def _speak_local_qwen(text: str, speed: float):
    """使用 mlx-audio 的 Qwen3-TTS 生成并播放中文语音。"""
    from mlx_audio.tts.generate import generate_audio
    import time
    tmp_dir = tempfile.mkdtemp()
    prefix  = "qwen_out"
    tmp     = os.path.join(tmp_dir, f"{prefix}.wav")
    try:
        generate_audio(
            text=text,
            model=QWEN3_TTS_MODEL,
            voice=QWEN3_VOICE,
            speed=speed,
            lang_code="zh",
            output_path=tmp_dir,
            file_prefix=prefix,
            audio_format="wav",
            save=True,
            verbose=False,
        )
        if os.path.exists(tmp):
            _play_file(tmp)
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)
        try:
            os.rmdir(tmp_dir)
        except Exception:
            pass


# ── 停止当前播放 ──────────────────────────────────────────
def _stop_current():
    global _play_proc
    _stop_flag.set()
    if _play_proc and _play_proc.poll() is None:
        _play_proc.terminate()
    if _play_thread and _play_thread.is_alive():
        _play_thread.join(timeout=2)
    _stop_flag.clear()


# ── 播放 PCM（Chatterbox 输出） ───────────────────────────
def _play_pcm(audio_data: np.ndarray, sample_rate: int):
    import pyaudio
    _stop_flag.clear()
    pa = pyaudio.PyAudio()
    stream = pa.open(format=pyaudio.paFloat32, channels=1,
                     rate=sample_rate, output=True)
    chunk = 1024
    offset = 0
    while offset < len(audio_data):
        if _stop_flag.is_set():
            break
        stream.write(audio_data[offset:offset + chunk].tobytes())
        offset += chunk
    stream.stop_stream()
    stream.close()
    pa.terminate()


# ── 播放音频文件（edge-tts / Kokoro 输出） ─────────────────
def _play_file(path: str):
    global _play_proc
    _stop_flag.clear()
    _play_proc = subprocess.Popen(["afplay", path])
    while _play_proc.poll() is None:
        if _stop_flag.is_set():
            _play_proc.terminate()
            break
        import time; time.sleep(0.05)
    _play_proc = None


# ── 云端中文 TTS（edge-tts CLI） ──────────────────────────
def _speak_cloud_cn(text: str, voice_name: str, speed: float):
    with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as f:
        tmp = f.name
    # edge-tts rate: +20% = speed 1.2x, -20% = speed 0.8x
    rate_pct = int((speed - 1.0) * 100)
    rate_str = f"+{rate_pct}%" if rate_pct >= 0 else f"{rate_pct}%"
    try:
        subprocess.run(
            [EDGE_TTS_BIN, "--voice", voice_name, "--text", text,
             "--rate", rate_str, "--write-media", tmp],
            check=True, capture_output=True, timeout=15
        )
        _play_file(tmp)
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)




# ── 英文 TTS（Chatterbox） ────────────────────────────────
def _speak_en(text: str, voice_id: str):
    with _tts_lock:
        tts = _get_chatterbox()
        prompt = None
        if voice_id not in ("default",):
            candidate = os.path.join(VOICES_DIR, f"{voice_id}.pt")
            if os.path.exists(candidate):
                prompt = candidate
        wav = tts.generate(text, audio_prompt_path=prompt) if prompt else tts.generate(text)
        sr  = tts.sr
    audio = wav.squeeze().cpu().numpy().astype(np.float32)
    _play_pcm(audio, sr)


# ── MCP 工具 ──────────────────────────────────────────────

@mcp.tool()
def speak(text: str, voice_id: str = "default") -> str:
    """
    将文字转为语音并播放。自动检测语言，根据配置选择引擎。

    Args:
        text:     要朗读的文字内容
        voice_id: 可选，覆盖配置中的声音设置

    Returns:
        播放结果描述
    """
    global _play_thread

    if not text.strip():
        return "文字为空，跳过播放"

    cfg = _load_config()
    _stop_current()

    # 判断语言
    lang = cfg["language"]
    if lang == "auto":
        use_chinese = _is_chinese(text)
    elif lang == "zh":
        use_chinese = True
    else:
        use_chinese = False

    # voice_id 参数可覆盖配置
    vid = voice_id if voice_id != "default" else (
        cfg["cn_voice"] if use_chinese else cfg["en_voice"]
    )
    speed = cfg["speed"]

    if use_chinese:
        engine = cfg["cn_engine"]
        if engine == "local":
            _play_thread = threading.Thread(
                target=_speak_local_qwen, args=(text, speed), daemon=True
            )
            engine_label = "本地 Qwen3-TTS"
        else:
            voice_name = CLOUD_VOICES.get(vid, CLOUD_VOICES["xiaoxiao"])
            _play_thread = threading.Thread(
                target=_speak_cloud_cn, args=(text, voice_name, speed), daemon=True
            )
            engine_label = f"云端 {vid}"
        _play_thread.start()
        return f"正在播放（中文，{len(text)} 字，{engine_label}）"
    else:
        _play_thread = threading.Thread(
            target=_speak_en, args=(text, vid), daemon=True
        )
        _play_thread.start()
        return f"正在播放（英文，{len(text)} 字，Chatterbox）"


@mcp.tool()
def list_voices() -> dict:
    """列出所有可用的声音 ID，按引擎分类。"""
    cloud_cn = list(CLOUD_VOICES.keys())
    local_cn = ["Vivian（女声）", "Dylan（男声/北京话）"]

    en_voices = ["default"]
    if os.path.isdir(VOICES_DIR):
        for f in sorted(os.listdir(VOICES_DIR)):
            if f.endswith(".pt"):
                en_voices.append(f[:-3])

    cfg = _load_config()
    return {
        "当前配置": cfg,
        "中文_云端(edge-tts)": cloud_cn,
        "中文_本地(Qwen3-TTS)": local_cn,
        "英文(Chatterbox)": en_voices,
    }


@mcp.tool()
def stop_speaking() -> str:
    """立即停止当前正在播放的语音。"""
    _stop_current()
    return "已停止播放"


@mcp.tool()
def update_voice_config(
    cn_engine: str = None,
    cn_voice: str = None,
    en_voice: str = None,
    speed: float = None,
    language: str = None,
) -> str:
    """
    更新语音配置（持久化到 config.json）。

    Args:
        cn_engine: 中文引擎 "cloud" 或 "local"
        cn_voice:  中文声音 ID（云端：xiaoxiao/yunxi/xiaoyi；本地：Vivian/Dylan）
        en_voice:  英文声音 ID
        speed:     语速，0.5~2.0，1.0 为正常
        language:  语言模式 "auto"/"zh"/"en"

    Returns:
        更新后的配置
    """
    cfg = _load_config()
    if cn_engine is not None: cfg["cn_engine"] = cn_engine
    if cn_voice  is not None: cfg["cn_voice"]  = cn_voice
    if en_voice  is not None: cfg["en_voice"]  = en_voice
    if speed     is not None: cfg["speed"]     = max(0.5, min(2.0, speed))
    if language  is not None: cfg["language"]  = language

    with open(CONFIG_PATH, "w") as f:
        json.dump(cfg, f, ensure_ascii=False, indent=2)

    return f"配置已更新：{json.dumps(cfg, ensure_ascii=False)}"


# ── 会议记录路径 ──────────────────────────────────────────
MEETINGS_PATH = os.path.expanduser(
    "~/Library/Application Support/VoxSage/meetings.json"
)


def _load_meetings() -> list:
    """读取 meetings.json，失败时返回空列表。"""
    if not os.path.exists(MEETINGS_PATH):
        return []
    try:
        with open(MEETINGS_PATH, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return []


@mcp.tool()
def list_meetings() -> list:
    """
    列出所有会议记录的概要信息。

    Returns:
        每条会议包含：id、title（标题）、startTime（开始时间）、
        endTime（结束时间）、segmentCount（片段数量）、preview（首条内容预览）
    """
    meetings = _load_meetings()
    result = []
    for m in meetings:
        segments = m.get("segments", [])
        result.append({
            "id":           m.get("id", ""),
            "title":        m.get("title", "未命名"),
            "startTime":    m.get("startTime", ""),
            "endTime":      m.get("endTime", ""),
            "segmentCount": len(segments),
            "preview":      segments[0]["text"][:50] if segments else "（无内容）",
        })
    return result


@mcp.tool()
def get_meeting(meeting_id: str) -> dict:
    """
    获取某场会议的完整内容，包括所有转录片段和说话人信息。

    Args:
        meeting_id: 会议 ID（可从 list_meetings() 获取）

    Returns:
        完整会议数据：id、title、startTime、endTime、
        segments（每条含 timestamp、speaker、text）
    """
    meetings = _load_meetings()
    for m in meetings:
        if m.get("id") == meeting_id:
            segments = m.get("segments", [])
            return {
                "id":        m.get("id", ""),
                "title":     m.get("title", "未命名"),
                "startTime": m.get("startTime", ""),
                "endTime":   m.get("endTime", ""),
                "segments":  [
                    {
                        "timestamp": s.get("timestamp", ""),
                        "speaker":   s.get("speaker", ""),
                        "text":      s.get("text", ""),
                    }
                    for s in segments
                ],
            }
    return {"error": f"未找到 ID 为 {meeting_id!r} 的会议"}


# ── 入口 ─────────────────────────────────────────────────
if __name__ == "__main__":
    print("VoxSage MCP Server 启动...")
    mcp.run()
