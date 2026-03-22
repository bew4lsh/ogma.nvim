local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local function set_buf_lines(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  return buf
end

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

T["current_line()"] = new_set()

T["current_line()"]["extracts the cursor line"] = function()
  local text = require("ogma.text")
  set_buf_lines({ "first line", "second line", "third line" })
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  eq(text.current_line(), "second line")
end

T["current_line()"]["trims whitespace"] = function()
  local text = require("ogma.text")
  set_buf_lines({ "  padded  " })
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  eq(text.current_line(), "padded")
end

T["paragraph()"] = new_set()

T["paragraph()"]["extracts paragraph around cursor"] = function()
  local text = require("ogma.text")
  set_buf_lines({ "para one", "", "line a", "line b", "line c", "", "para three" })
  vim.api.nvim_win_set_cursor(0, { 4, 0 })
  eq(text.paragraph(), "line a\nline b\nline c")
end

T["paragraph()"]["handles single-line paragraph"] = function()
  local text = require("ogma.text")
  set_buf_lines({ "", "alone", "" })
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  eq(text.paragraph(), "alone")
end

T["paragraph()"]["works at first line of buffer"] = function()
  local text = require("ogma.text")
  set_buf_lines({ "top a", "top b", "", "other" })
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  eq(text.paragraph(), "top a\ntop b")
end

T["paragraph()"]["works at last line of buffer"] = function()
  local text = require("ogma.text")
  set_buf_lines({ "other", "", "bottom a", "bottom b" })
  vim.api.nvim_win_set_cursor(0, { 4, 0 })
  eq(text.paragraph(), "bottom a\nbottom b")
end

T["buffer()"] = new_set()

T["buffer()"]["extracts full buffer content"] = function()
  local text = require("ogma.text")
  set_buf_lines({ "line 1", "line 2", "line 3" })
  eq(text.buffer(), "line 1\nline 2\nline 3")
end

T["buffer()"]["collapses excessive blank lines"] = function()
  local text = require("ogma.text")
  set_buf_lines({ "a", "", "", "", "", "b" })
  eq(text.buffer(), "a\n\nb")
end

T["buffer()"]["normalizes CRLF to LF"] = function()
  local text = require("ogma.text")
  set_buf_lines({ "line one\r", "line two\r" })
  local result = text.buffer()
  eq(result:find("\r"), nil)
  eq(result, "line one\nline two")
end

T["buffer()"]["trims leading and trailing whitespace"] = function()
  local text = require("ogma.text")
  set_buf_lines({ "", "", "content", "", "" })
  eq(text.buffer(), "content")
end

return T
