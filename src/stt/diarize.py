#!/usr/bin/env python3
"""
VoxSage 说话人识别脚本（whisperx 版）
输入：音频文件路径（WAV）、config.json 路径
输出：JSON 格式的带说话人标签的转录结果（打印到 stdout）

用法：
    python3 diarize.py <audio.wav> <config.json>
"""

import sys
import os
import json
import warnings
import io

os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")
warnings.filterwarnings("ignore")

# 确保 ffmpeg 可被找到（venv/bin/ffmpeg 是符号链接）
_venv_bin = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                         "..", "venv", "bin")
os.environ["PATH"] = os.path.normpath(_venv_bin) + os.pathsep + os.environ.get("PATH", "")


def diarize(audio_path: str, hf_token: str, language: str | None = "zh") -> list[dict]:
    import whisperx

    device = "cpu"
    compute_type = "int8"

    # ── 1. 转录 ───────────────────────────────────────────────
    model = whisperx.load_model("small", device=device, compute_type=compute_type,
                                language=language)
    audio = whisperx.load_audio(audio_path)
    result = model.transcribe(audio, batch_size=8, language=language)

    if not result.get("segments"):
        return []

    # ── 3. 说话人识别 ─────────────────────────────────────────
    from whisperx.diarize import DiarizationPipeline
    diarize_model = DiarizationPipeline(token=hf_token, device=device)
    diarize_segments = diarize_model(audio)

    # ── 4. 把说话人分配给每个转录段 ───────────────────────────
    result = whisperx.assign_word_speakers(diarize_segments, result)

    # ── 5. 整理输出 ───────────────────────────────────────────
    speaker_map: dict[str, str] = {}
    counter = 1
    output = []

    for seg in result["segments"]:
        text = seg.get("text", "").strip()
        if not text:
            continue
        raw_speaker = seg.get("speaker", "SPEAKER_00")
        if raw_speaker not in speaker_map:
            speaker_map[raw_speaker] = f"说话人 {counter}"
            counter += 1
        output.append({
            "start":   seg.get("start", 0.0),
            "end":     seg.get("end", 0.0),
            "speaker": speaker_map[raw_speaker],
            "text":    text,
        })

    return output


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({"error": "用法：diarize.py <audio.wav> [config.json]"}))
        sys.exit(1)

    audio_path = sys.argv[1]
    config_path = sys.argv[2] if len(sys.argv) > 2 else None

    hf_token = os.getenv("HF_TOKEN", "")
    language: str | None = "zh"

    if config_path:
        try:
            with open(config_path, encoding="utf-8") as f:
                cfg = json.load(f)
            hf_token = cfg.get("hf_token", hf_token)
            lang_setting = cfg.get("recognition_language", "zh")
            language = None if lang_setting == "auto" else lang_setting
        except Exception:
            pass

    if not hf_token:
        print(json.dumps({"error": "缺少 HuggingFace Token，请在设置页面填写"}))
        sys.exit(1)

    if not os.path.exists(audio_path):
        print(json.dumps({"error": f"音频文件不存在：{audio_path}"}))
        sys.exit(1)

    try:
        # 屏蔽模型加载时的杂项 stdout，只让 JSON 输出
        _real_stdout = sys.stdout
        sys.stdout = io.StringIO()
        try:
            result = diarize(audio_path, hf_token, language)
        finally:
            sys.stdout = _real_stdout
        print(json.dumps(result, ensure_ascii=False, indent=2))
    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)
