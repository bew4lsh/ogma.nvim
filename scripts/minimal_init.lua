local deps_path = vim.fn.fnamemodify("deps/mini.nvim", ":p")

if not vim.uv.fs_stat(deps_path) then
  vim.fn.system({ "git", "clone", "--depth=1", "https://github.com/echasnovski/mini.nvim", deps_path })
end

vim.opt.rtp:prepend(deps_path)
vim.opt.rtp:prepend(vim.fn.fnamemodify(".", ":p"))

require("mini.test").setup()
