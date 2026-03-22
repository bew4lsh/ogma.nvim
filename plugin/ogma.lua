if vim.g.loaded_ogma then
  return
end
vim.g.loaded_ogma = true

local function guard()
  local ogma = require("ogma")
  if not ogma._setup_done then
    vim.notify("[ogma.nvim] call require('ogma').setup() first", vim.log.levels.WARN)
    return nil
  end
  return ogma
end

vim.api.nvim_create_user_command("OgmaSpeak", function(opts)
  local ogma = guard()
  if not ogma then
    return
  end
  if opts.range > 0 then
    ogma.speak_selection()
  else
    ogma.speak_line()
  end
end, { range = true, desc = "Ogma: speak text" })

vim.api.nvim_create_user_command("OgmaStop", function()
  local ogma = guard()
  if ogma then
    ogma.stop()
  end
end, { desc = "Ogma: stop playback" })

vim.api.nvim_create_user_command("OgmaPause", function()
  local ogma = guard()
  if ogma then
    ogma.toggle_pause()
  end
end, { desc = "Ogma: toggle pause" })
