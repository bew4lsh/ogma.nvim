local M = {}

local current = "idle"

function M.get()
  return current
end

function M.set(new_state)
  current = new_state
  vim.api.nvim_exec_autocmds("User", { pattern = "OgmaStateChanged" })
end

local status_icons = {
  playing = "󰔊 Speaking",
  paused = "󰏤 Paused",
}

function M.statusline()
  return status_icons[current] or ""
end

return M
