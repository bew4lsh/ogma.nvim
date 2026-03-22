local platform = require("ogma.platform")
local state = require("ogma.state")

local M = {}

function M.start(on_exit)
  local ipc = platform.ipc_path()
  local args = { "mpv", "--no-video", "--no-terminal", "--input-ipc-server=" .. ipc, "-" }

  local handle = vim.fn.jobstart(args, {
    on_exit = function(_, code)
      M.cleanup_ipc()
      if on_exit then
        on_exit(code)
      end
    end,
  })

  if handle <= 0 then
    vim.notify("[ogma.nvim] failed to start mpv", vim.log.levels.ERROR)
    return nil
  end

  return handle
end

function M.write(handle, data)
  if handle and type(data) == "string" then
    vim.fn.chansend(handle, data)
  end
end

function M.close_stdin(handle)
  if handle then
    pcall(vim.fn.chanclose, handle, "stdin")
  end
end

function M.stop(handle)
  if handle then
    pcall(vim.fn.jobstop, handle)
  end
  M.cleanup_ipc()
  state.set("idle")
end

function M.cleanup_ipc()
  local ipc = platform.ipc_path()
  pcall(vim.uv.fs_unlink, ipc)
end

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
