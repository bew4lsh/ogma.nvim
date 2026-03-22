local config = require("ogma.config")

local M = {}

function M.check()
  vim.health.start("ogma.nvim")

  if vim.fn.has("nvim-0.10") == 1 then
    vim.health.ok("Neovim >= 0.10")
  else
    vim.health.error("Neovim >= 0.10 required")
  end

  if vim.fn.executable("curl") == 1 then
    vim.health.ok("curl found")
  else
    vim.health.error("curl not found (required for API calls)")
  end

  if vim.fn.executable("mpv") == 1 then
    vim.health.ok("mpv found")
  else
    vim.health.error("mpv not found (required for audio playback)")
  end

  local cfg = config.get()
  if cfg.api_key and cfg.api_key ~= "" then
    vim.health.ok("API key set")
  else
    vim.health.warn("OPENAI_API_KEY not set (set env var or pass api_key in setup)")
  end

  local errors = config.validate(cfg)
  if #errors == 0 then
    vim.health.ok("Config valid")
  else
    for _, err in ipairs(errors) do
      vim.health.error("Config: " .. err)
    end
  end
end

return M
