local config = require("ogma.config")

local M = {}

function M.stream(text, callbacks)
  local cfg = config.get()
  if not cfg.api_key then
    vim.notify("[ogma.nvim] no API key set (OPENAI_API_KEY or config.api_key)", vim.log.levels.ERROR)
    return nil
  end

  local body = vim.json.encode({
    model = cfg.model,
    input = text,
    voice = cfg.voice,
    speed = cfg.speed,
    response_format = cfg.format,
  })

  local handle = vim.fn.jobstart({
    "curl", "--silent", "--no-buffer",
    "--request", "POST",
    "--url", "https://api.openai.com/v1/audio/speech",
    "--header", "Content-Type: application/json",
    "--header", "Authorization: Bearer " .. cfg.api_key,
    "--data", body,
  }, {
    stdout_buffered = false,
    on_stdout = function(_, data)
      if callbacks.on_stdout then
        callbacks.on_stdout(data)
      end
    end,
    on_exit = function(_, code)
      if callbacks.on_exit then
        callbacks.on_exit(code)
      end
    end,
  })

  if handle <= 0 then
    vim.notify("[ogma.nvim] failed to start curl", vim.log.levels.ERROR)
    return nil
  end

  return handle
end

return M
