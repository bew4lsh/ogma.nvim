local M = {}

local defaults = {
  api_key = nil,
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
}

local config = vim.deepcopy(defaults)

local valid_voices = {
  alloy = true, ash = true, ballad = true, coral = true, echo = true,
  fable = true, onyx = true, nova = true, sage = true, shimmer = true,
}

local valid_models = { ["tts-1"] = true, ["tts-1-hd"] = true }
local valid_formats = { mp3 = true, opus = true, aac = true, flac = true, wav = true, pcm = true }

function M.validate(cfg)
  local errors = {}
  if cfg.voice and not valid_voices[cfg.voice] then
    table.insert(errors, "invalid voice: " .. cfg.voice)
  end
  if cfg.model and not valid_models[cfg.model] then
    table.insert(errors, "invalid model: " .. cfg.model)
  end
  if cfg.format and not valid_formats[cfg.format] then
    table.insert(errors, "invalid format: " .. cfg.format)
  end
  if cfg.speed and (cfg.speed < 0.25 or cfg.speed > 4.0) then
    table.insert(errors, "speed must be between 0.25 and 4.0")
  end
  if cfg.max_chars and cfg.max_chars < 1 then
    table.insert(errors, "max_chars must be positive")
  end
  return errors
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
  local errors = M.validate(config)
  if #errors > 0 then
    vim.notify("[ogma.nvim] config errors: " .. table.concat(errors, ", "), vim.log.levels.ERROR)
  end
end

function M.get()
  local cfg = vim.deepcopy(config)
  cfg.api_key = cfg.api_key or vim.env.OPENAI_API_KEY
  return cfg
end

return M
