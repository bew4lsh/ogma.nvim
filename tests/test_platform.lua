local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local T = new_set()

T["ipc_path()"] = new_set()

T["ipc_path()"]["contains current PID"] = function()
  local platform = require("ogma.platform")
  local path = platform.ipc_path()
  local pid = tostring(vim.fn.getpid())
  eq(path:find(pid, 1, true) ~= nil, true)
end

T["ipc_path()"]["ends with .sock on non-Windows"] = function()
  local platform = require("ogma.platform")
  if platform.is_windows then
    return
  end
  eq(vim.endswith(platform.ipc_path(), ".sock"), true)
end

T["temp_dir()"] = new_set()

T["temp_dir()"]["returns a non-empty string"] = function()
  local platform = require("ogma.platform")
  local dir = platform.temp_dir()
  eq(type(dir), "string")
  eq(#dir > 0, true)
end

T["OS flags"] = new_set()

T["OS flags"]["exactly one is true"] = function()
  local platform = require("ogma.platform")
  local count = 0
  if platform.is_linux then count = count + 1 end
  if platform.is_macos then count = count + 1 end
  if platform.is_windows then count = count + 1 end
  eq(count, 1)
end

return T
