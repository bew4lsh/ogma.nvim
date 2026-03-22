# ogma.nvim

Speak text from Neovim using the OpenAI TTS API. Select text, fire a keymap, and hear it read aloud through [mpv](https://mpv.io).

## Requirements

- Neovim >= 0.10
- [mpv](https://mpv.io) — audio playback
- [curl](https://curl.se) — API requests
- An [OpenAI API key](https://platform.openai.com/api-keys)

## Install

### lazy.nvim

```lua
{
  "bew4lsh/ogma.nvim",
  config = function()
    require("ogma").setup({
      -- api_key = "sk-...",       -- or set OPENAI_API_KEY env var
      -- voice = "nova",           -- alloy, ash, ballad, coral, echo, fable, nova, onyx, sage, shimmer
      -- model = "tts-1",          -- tts-1, tts-1-hd
      -- speed = 1.0,              -- 0.25 to 4.0
      -- format = "mp3",           -- mp3, opus, aac, flac, wav, pcm
      -- max_chars = 4096,
    })
  end,
}
```

### packer.nvim

```lua
use {
  "bew4lsh/ogma.nvim",
  config = function()
    require("ogma").setup()
  end,
}
```

## Configuration

All options are optional. Defaults shown below:

```lua
require("ogma").setup({
  api_key = nil,              -- falls back to $OPENAI_API_KEY
  voice = "nova",
  model = "tts-1",
  speed = 1.0,
  format = "mp3",
  max_chars = 4096,
  keymaps = {
    speak_line = "<leader>vs",
    speak_selection = "<leader>vs",
    speak_paragraph = "<leader>vp",
    speak_buffer = "<leader>vb",
    toggle_pause = "<leader>vv",
    stop = "<leader>vq",
  },
})
```

Set any keymap to `false` to disable it and bind manually.

## Usage

### Keymaps

| Keymap       | Mode | Action              |
| ------------ | ---- | ------------------- |
| `<leader>vs` | n    | Speak current line  |
| `<leader>vs` | v    | Speak selection     |
| `<leader>vp` | n    | Speak paragraph     |
| `<leader>vb` | n    | Speak entire buffer |
| `<leader>vv` | n    | Toggle pause/resume |
| `<leader>vq` | n    | Stop playback       |

### Commands

| Command      | Description                                    |
| ------------ | ---------------------------------------------- |
| `:OgmaSpeak` | Speak current line (or selection with a range) |
| `:OgmaStop`  | Stop playback                                  |
| `:OgmaPause` | Toggle pause/resume                            |

### Statusline

Add playback state to your statusline:

```lua
require("ogma").statusline()
-- returns "" when idle, "[Ogma:playing]" or "[Ogma:paused]" otherwise
```

Example with lualine:

```lua
sections = {
  lualine_x = { require("ogma").statusline },
}
```

### Events

The `OgmaStateChanged` user autocmd fires on every state transition:

```lua
vim.api.nvim_create_autocmd("User", {
  pattern = "OgmaStateChanged",
  callback = function()
    print("State:", require("ogma.state").get())
  end,
})
```

## Health Check

Run `:checkhealth ogma` to verify your setup (mpv, curl, API key, config).

## License

MIT
