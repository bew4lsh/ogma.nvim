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
    end,
  },
})

T["get()"] = new_set()

T["get()"]["defaults to idle"] = function()
  local state = require("ogma.state")
  eq(state.get(), "idle")
end

T["set()"] = new_set()

T["set()"]["changes state"] = function()
  local state = require("ogma.state")
  state.set("playing")
  eq(state.get(), "playing")
end

T["set()"]["fires OgmaStateChanged autocmd"] = function()
  local state = require("ogma.state")
  local fired = false
  local group = vim.api.nvim_create_augroup("ogma_state_test", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "OgmaStateChanged",
    callback = function()
      fired = true
    end,
  })

  state.set("playing")
  eq(fired, true)

  vim.api.nvim_del_augroup_by_id(group)
end

T["statusline()"] = new_set()

T["statusline()"]["returns empty string when idle"] = function()
  local state = require("ogma.state")
  eq(state.statusline(), "")
end

T["statusline()"]["returns icon when playing"] = function()
  local state = require("ogma.state")
  state.set("playing")
  eq(state.statusline(), "󰔊 Speaking")
end

T["statusline()"]["returns icon when paused"] = function()
  local state = require("ogma.state")
  state.set("paused")
  eq(state.statusline(), "󰏤 Paused")
end

return T
