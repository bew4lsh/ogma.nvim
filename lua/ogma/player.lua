local platform = require("ogma.platform")
local state = require("ogma.state")

local M = {}

local function send_ipc_command(cmd)
  local ipc = platform.ipc_path()
  local pipe = vim.uv.new_pipe(false)
  pipe:connect(ipc, function(err)
    if err then
      pipe:close()
      return
    end
    local payload = vim.json.encode(cmd) .. "\n"
    pipe:write(payload, function()
      pipe:close()
    end)
  end)
end

function M.pause()
  send_ipc_command({ command = { "set_property", "pause", true } })
  state.set("paused")
end

function M.resume()
  send_ipc_command({ command = { "set_property", "pause", false } })
  state.set("playing")
end

function M.toggle_pause()
  if state.get() == "playing" then
    M.pause()
  elseif state.get() == "paused" then
    M.resume()
  end
end

return M
