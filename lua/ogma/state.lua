local M = {}

local current = "idle"

function M.get()
  return current
end

function M.set(new_state)
  current = new_state
  vim.api.nvim_exec_autocmds("User", { pattern = "OgmaStateChanged" })
end

function M.statusline()
  if current == "idle" then
    return ""
  end
  return "[Ogma:" .. current .. "]"
end

return M
