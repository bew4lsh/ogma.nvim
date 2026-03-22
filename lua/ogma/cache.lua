local config = require("ogma.config")
local platform = require("ogma.platform")

local M = {}

local entries = {}
local buf_keys = {}

local function cache_key(text)
  local cfg = config.get()
  local raw = text .. cfg.voice .. cfg.model .. tostring(cfg.speed) .. cfg.format
  return vim.fn.sha256(raw)
end

local function cache_path(key)
  local cfg = config.get()
  return platform.temp_dir() .. "/ogma-nvim-" .. key .. "." .. cfg.format
end

function M.get(text)
  local key = cache_key(text)
  local entry = entries[key]
  if entry and vim.uv.fs_stat(entry.path) then
    return entry.path
  end
  entries[key] = nil
  return nil
end

function M.put(text, bufnr, data)
  local key = cache_key(text)
  local path = cache_path(key)

  local fd = vim.uv.fs_open(path, "w", 438) -- 0o666
  if not fd then
    return
  end
  vim.uv.fs_write(fd, data)
  vim.uv.fs_close(fd)

  entries[key] = { path = path, bufnr = bufnr }

  if not buf_keys[bufnr] then
    buf_keys[bufnr] = {}
  end
  table.insert(buf_keys[bufnr], key)
end

function M.evict_buffer(bufnr)
  local keys = buf_keys[bufnr]
  if not keys then
    return
  end
  for _, key in ipairs(keys) do
    local entry = entries[key]
    if entry then
      pcall(vim.uv.fs_unlink, entry.path)
      entries[key] = nil
    end
  end
  buf_keys[bufnr] = nil
end

function M.setup()
  vim.api.nvim_create_autocmd({ "BufUnload", "BufDelete" }, {
    group = vim.api.nvim_create_augroup("ogma_cache", { clear = true }),
    callback = function(ev)
      M.evict_buffer(ev.buf)
    end,
  })
end

return M
