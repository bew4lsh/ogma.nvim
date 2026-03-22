# tts.nvim — Product Requirements Document

## Overview

A Neovim plugin that speaks selected text using OpenAI's TTS API. The primary design goal is **low-latency playback** — audio should start within milliseconds of the request, not seconds.

## Platform Support

Must work on Linux (NixOS), macOS, and Windows from the start. All process spawning, piping, and file paths must account for platform differences.

## Architecture

### Streaming Pipeline

The critical path is a streaming pipeline that avoids buffering the full audio response:

1. Neovim extracts text from the buffer (async, non-blocking)
2. HTTP request to OpenAI TTS with chunked transfer encoding
3. Response bytes pipe directly to an audio player's stdin
4. Playback begins on first received chunk (~200-500ms target)

No temporary files in the hot path.

### Process Model

- All I/O runs via `vim.fn.jobstart` (or `vim.system`) so the editor never blocks
- The audio player runs as a child process with stdin pipe
- Player process handle is retained for stop/pause/resume control

### Audio Player

Use `mpv` as the primary playback backend:

- Available on all target platforms
- Supports stdin streaming (`mpv --no-video -`)
- IPC socket/pipe for pause/resume control
- Fallback: `ffplay` (less control, but widely available)

On Windows, `mpv` works via `mpv.exe --no-video -` with the same stdin pipe model.

## Features

### Core (MVP)

- **Speak selection** — visual selection, current line, paragraph, or buffer
- **Stop** — kill the player process immediately
- **Streaming playback** — pipe chunked HTTP response directly to player
- **Async** — never block the editor

### Configuration

- API key: `OPENAI_API_KEY` env var (primary), config option (fallback)
- Voice: one of `alloy`, `ash`, `ballad`, `coral`, `echo`, `fable`, `onyx`, `nova`, `sage`, `shimmer` (default: `nova`)
- Model: `tts-1` (default, optimized for speed) or `tts-1-hd`
- Speed: `0.25` to `4.0` (default: `1.0`)
- Output format: `mp3` (default), `opus`, `aac`, `flac`, `wav`, `pcm`
- Keymaps: configurable, sane defaults (see [Keymaps](#keymaps))

### Playback Control

- Stop (kill process)
- Pause / resume (via mpv IPC)
- Queue mode — multiple selections play in sequence

### Keymaps

Default prefix: `<leader>v` (voice). All mappings are opt-out — set a key to `false` in `setup()` to disable.

| Mode | Key          | Action            | Description               |
| ---- | ------------ | ----------------- | ------------------------- |
| `n`  | `<leader>vs` | `speak_line`      | Speak current line        |
| `v`  | `<leader>vs` | `speak_selection` | Speak visual selection    |
| `n`  | `<leader>vp` | `speak_paragraph` | Speak current paragraph   |
| `n`  | `<leader>vb` | `speak_buffer`    | Speak entire buffer       |
| `n`  | `<leader>vv` | `toggle_pause`    | Pause / resume playback   |
| `n`  | `<leader>vq` | `stop`            | Stop playback immediately |

### Quality of Life

- Audio cache — hash `text + voice + model + speed` to skip redundant API calls; cached files served directly to player. Cache is scoped to buffer lifetime and evicted on `BufUnload`/`BufDelete`. Speaking a previously cached segment plays instantly with no API call.
- Cost guard — configurable character limit with warning before sending large requests
- Status line integration — expose playback state (`playing` / `paused` / `idle`) for statusline plugins

## API Reference

### OpenAI TTS Endpoint

```
POST https://api.openai.com/v1/audio/speech
Content-Type: application/json
Authorization: Bearer $OPENAI_API_KEY

{
  "model": "tts-1",
  "input": "text to speak",
  "voice": "alloy",
  "speed": 1.0,
  "response_format": "mp3"
}
```

Response: streamed audio bytes (chunked transfer encoding).

## Non-Goals

- Supporting TTS providers other than OpenAI
- Speech-to-text
- Saving audio files as a primary workflow
- Built-in audio player (we depend on mpv/ffplay)

## Dependencies

- Neovim >= 0.10
- `curl` (for streaming HTTP) — available on all platforms including Windows 10+
- `mpv` (for audio playback) — user-installed
