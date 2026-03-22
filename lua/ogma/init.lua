local config = require("ogma.config")
local cache = require("ogma.cache")
local text = require("ogma.text")
local queue = require("ogma.queue")
local player = require("ogma.player")
local state = require("ogma.state")

local M = {}

M._setup_done = false

local function map(mode, lhs, rhs, desc)
  if lhs then
    vim.keymap.set(mode, lhs, rhs, { desc = desc })
  end
end

function M.setup(opts)
  config.setup(opts)
  cache.setup()
  M._setup_done = true

  local km = config.get().keymaps
  map("n", km.speak_line, M.speak_line, "Ogma: speak line")
  map("v", km.speak_selection, M.speak_selection, "Ogma: speak selection")
  map("n", km.speak_paragraph, M.speak_paragraph, "Ogma: speak paragraph")
  map("n", km.speak_buffer, M.speak_buffer, "Ogma: speak buffer")
  map("n", km.toggle_pause, M.toggle_pause, "Ogma: toggle pause")
  map("n", km.stop, M.stop, "Ogma: stop")
end

function M.speak_line()
  queue.enqueue(text.current_line(), vim.api.nvim_get_current_buf())
end

function M.speak_selection()
  local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
  vim.api.nvim_feedkeys(esc, "nx", false)
  queue.enqueue(text.visual_selection(), vim.api.nvim_get_current_buf())
end

function M.speak_paragraph()
  queue.enqueue(text.paragraph(), vim.api.nvim_get_current_buf())
end

function M.speak_buffer()
  queue.enqueue(text.buffer(), vim.api.nvim_get_current_buf())
end

function M.stop()
  queue.clear()
end

function M.toggle_pause()
  player.toggle_pause()
end

function M.statusline()
  return state.statusline()
end

return M
