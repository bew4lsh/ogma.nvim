local config = require("ogma.config")

local M = {}

function M.spawn(text)
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

  local stdout = vim.uv.new_pipe(false)
  local stderr = vim.uv.new_pipe(false)

  local handle
  handle = vim.uv.spawn("curl", {
    args = {
      "--silent", "--no-buffer",
      "--request", "POST",
      "--url", "https://api.openai.com/v1/audio/speech",
      "--header", "Content-Type: application/json",
      "--header", "Authorization: Bearer " .. cfg.api_key,
      "--data", body,
    },
    stdio = { nil, stdout, stderr },
  }, function()
    if not handle:is_closing() then
      handle:close()
    end
  end)

  if not handle then
    stdout:close()
    stderr:close()
    vim.notify("[ogma.nvim] failed to start curl", vim.log.levels.ERROR)
    return nil
  end

  vim.uv.read_start(stderr, function(_, data)
    if not data then
      vim.uv.read_stop(stderr)
      if not stderr:is_closing() then
        stderr:close()
      end
    end
  end)

  return { handle = handle, stdout = stdout }
end

return M
