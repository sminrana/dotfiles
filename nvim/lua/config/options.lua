-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
local opt = vim.opt -- for conciseness
opt.backspace = { "indent", "eol", "start" } -- allow backspace on indent, end of line or insert mode start position
opt.colorcolumn = "80"
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.timeoutlen = 150
opt.ttimeoutlen = 0
opt.clipboard = "unnamedplus" -- use system clipboard as default register
opt.spelllang = "en_us"
opt.spell = true
opt.incsearch = true
opt.hlsearch = true
opt.ignorecase = true
opt.smartcase = true
opt.shortmess:append("I")
opt.mouse = "a" -- enable mouse everywhere
opt.mousemoveevent = true
opt.mousescroll = "ver:2,hor:6"    -- smoother wheel speed (try ver:1~3)
opt.scrolloff = 8                  -- keep 8 lines above/below cursor
opt.sidescrolloff = 8
opt.wrap = true                    -- better long-line reading
opt.linebreak = true               -- wrap at words, not mid-word
vim.g.lazyvim_picker = "fzf"
vim.g.snacks_animate = false
vim.g.autoformat = true
