-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
local opt = vim.opt -- for conciseness
opt.backspace = { "indent", "eol", "start" } -- allow backspace on indent, end of line or insert mode start position
opt.colorcolumn = "80"
opt.scrolloff = 10
opt.sidescrolloff = 8
opt.timeoutlen = 100
opt.ttimeoutlen = 0
--opt.clipboard:append("unnamedplus") -- use system clipboard as default register
opt.spelllang = "en_us"
opt.spell = true

vim.g.lazyvim_php_lsp = "intelephense"
