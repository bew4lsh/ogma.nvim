local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local T = new_set({
  hooks = {
    pre_case = function()
      for key in pairs(package.loaded) do
        if key:match("^ogma%.") then
          package.loaded[key] = nil
        end
      end
      require("ogma.config").setup({})
    end,
  },
})

T["get()"] = new_set()

T["get()"]["returns nil for unknown text"] = function()
  local cache = require("ogma.cache")
  eq(cache.get("nonexistent text"), nil)
end

T["put() + get()"] = new_set()

T["put() + get()"]["roundtrip returns valid path"] = function()
  local cache = require("ogma.cache")
  cache.put("hello world", 1, "fake-audio-data")
  local path = cache.get("hello world")
  eq(type(path), "string")
  eq(#path > 0, true)
end

T["put() + get()"]["file contains original data"] = function()
  local cache = require("ogma.cache")
  local data = "test-audio-bytes-12345"
  cache.put("some text", 1, data)
  local path = cache.get("some text")

  local fd = vim.uv.fs_open(path, "r", 438)
  local stat = vim.uv.fs_fstat(fd)
  local content = vim.uv.fs_read(fd, stat.size)
  vim.uv.fs_close(fd)

  eq(content, data)
end

T["put() + get()"]["returns nil when file deleted externally"] = function()
  local cache = require("ogma.cache")
  cache.put("vanishing", 1, "data")
  local path = cache.get("vanishing")
  vim.uv.fs_unlink(path)
  eq(cache.get("vanishing"), nil)
end

T["put() + get()"]["key varies with config"] = function()
  local config = require("ogma.config")
  local cache = require("ogma.cache")

  config.setup({ voice = "nova" })
  cache.put("same text", 1, "audio-nova")
  local path_nova = cache.get("same text")

  for key in pairs(package.loaded) do
    if key:match("^ogma%.") then package.loaded[key] = nil end
  end
  config = require("ogma.config")
  cache = require("ogma.cache")

  config.setup({ voice = "echo" })
  cache.put("same text", 1, "audio-echo")
  local path_echo = cache.get("same text")

  eq(type(path_nova), "string")
  eq(type(path_echo), "string")
  eq(path_nova ~= path_echo, true)
end

T["evict_buffer()"] = new_set()

T["evict_buffer()"]["removes entries and deletes files"] = function()
  local cache = require("ogma.cache")
  cache.put("evict me", 42, "audio")
  local path = cache.get("evict me")
  eq(vim.uv.fs_stat(path) ~= nil, true)

  cache.evict_buffer(42)
  eq(cache.get("evict me"), nil)
  eq(vim.uv.fs_stat(path), nil)
end

T["evict_buffer()"]["clears all entries for a buffer"] = function()
  local cache = require("ogma.cache")
  cache.put("first", 7, "aaa")
  cache.put("second", 7, "bbb")
  local path1 = cache.get("first")
  local path2 = cache.get("second")

  cache.evict_buffer(7)
  eq(cache.get("first"), nil)
  eq(cache.get("second"), nil)
  eq(vim.uv.fs_stat(path1), nil)
  eq(vim.uv.fs_stat(path2), nil)
end

T["evict_buffer()"]["is idempotent for unknown bufnr"] = function()
  local cache = require("ogma.cache")
  cache.evict_buffer(99999)
end

return T
