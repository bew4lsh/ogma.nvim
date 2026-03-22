local M = {}

local function clean(str)
  str = str:gsub("\r\n", "\n")
  str = str:gsub("\n\n\n+", "\n\n")
  str = str:match("^%s*(.-)%s*$")
  return str
end

function M.current_line()
  return clean(vim.api.nvim_get_current_line())
end

function M.visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local mode = vim.fn.visualmode()
  local regions = vim.fn.getregion(start_pos, end_pos, { type = mode })
  return clean(table.concat(regions, "\n"))
end

function M.paragraph()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local total = #lines

  local start_row = row
  while start_row > 1 and lines[start_row - 1] ~= "" do
    start_row = start_row - 1
  end

  local end_row = row
  while end_row < total and lines[end_row + 1] ~= "" do
    end_row = end_row + 1
  end

  local paragraph_lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
  return clean(table.concat(paragraph_lines, "\n"))
end

function M.buffer()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return clean(table.concat(lines, "\n"))
end

return M
