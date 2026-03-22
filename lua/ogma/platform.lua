local M = {}

local uname = vim.uv.os_uname()

M.os = uname.sysname
M.is_windows = M.os == "Windows_NT"
M.is_macos = M.os == "Darwin"
M.is_linux = M.os == "Linux"

function M.ipc_path()
  local pid = vim.fn.getpid()
  if M.is_windows then
    return string.format([[\\.\pipe\ogma-nvim-%d]], pid)
  end
  return string.format("/tmp/ogma-nvim-%d.sock", pid)
end

function M.temp_dir()
  if M.is_windows then
    return vim.env.TEMP or vim.env.TMP or "C:\\Temp"
  end
  return vim.env.TMPDIR or "/tmp"
end

return M
