local pipeline = require("ogma.pipeline")
local player = require("ogma.player")
local state = require("ogma.state")

local M = {}

local items = {}
local active_handles = nil

local function play_next()
  if #items == 0 then
    active_handles = nil
    state.set("idle")
    return
  end

  local item = table.remove(items, 1)
  active_handles = pipeline.speak(item.text, item.bufnr, function()
    active_handles = nil
    vim.schedule(play_next)
  end)
end

function M.enqueue(text, bufnr)
  table.insert(items, { text = text, bufnr = bufnr })
  if not active_handles then
    play_next()
  end
end

function M.clear()
  items = {}
  if active_handles then
    if active_handles.curl then
      pcall(vim.fn.jobstop, active_handles.curl)
    end
    if active_handles.mpv then
      player.stop(active_handles.mpv)
    end
    active_handles = nil
  end
  state.set("idle")
end

function M.current_handle()
  return active_handles
end

return M
