-- Utility function to simplify keymap definitions
local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- General keymaps
map("n", "gO", "<Cmd>call append(line('.') - 1, repeat([''], v:count1))<CR>")
map("n", "go", "<Cmd>call append(line('.'), repeat([''], v:count1))<CR>")
map("n", "<leader>e", "<Cmd>Neotree reveal float<CR>")
map("n", "<leader>be", "<Cmd>Neotree buffers float<CR>")

-- FZF keymaps
map("n", "<leader>fa", function()
  require("fzf-lua").live_grep({ cwd = "~/app/" })
end, { desc = "Live Grep in App Files" })

map("n", "<leader>fw", function()
  require("fzf-lua").live_grep({ cwd = "~/web/" })
end, { desc = "Live Grep in Web Files" })

map("n", "<leader>fx", function()
  require("fzf-lua").live_grep({ cwd = "~/Desktop/obs-v1/" })
end, { desc = "Live Grep in Notes Files" })

map("n", "<leader>fs", function()
  require("fzf-lua").live_grep({ cwd = "~/Desktop/snippets/" })
end, { desc = "Live Grep in Snippets Files" })

map("n", "<leader>ba", function()
  require("fzf-lua").blines()
end, { desc = "Live Grep in Current Buffer" })

-- Add done emoji
map("n", "<leader>jmc", function()
  local emoji = "✅ Done - " .. os.date("%Y-%m-%d %H:%M:%S")
  local line = vim.api.nvim_get_current_line()
  vim.api.nvim_set_current_line(line .. " " .. emoji)
end, { desc = "Insert checkmark at end of line" })

-- Personal keymaps
-- Define a prefix for personal keymaps
local prefix = "<leader>j"

local personal_keymaps = {
  { "C", "<Cmd>%y<CR>", "Copy All" },
  { "D", "<Cmd>%d<CR>", "Delete All" },
  { "X", "ggVGx", "Cut All" },
  { "S", "ggVG", "Select All" },
  { "t", "<Cmd>tabe ~/Desktop/obs-v1/todo.md<CR>" },
  { "n", "<Cmd>tabe ~/Desktop/obs-v1/notes.md<CR>" },
  { "ut", "<cmd>UndotreeToggle<cr>", "Toggle Undotree" },
  { "fp", ':let @+=expand("%:p")<CR>', "Copy file absolute path" },
  { "fr", ':let @+=expand("%:." )<CR>', "Copy file relative path" },
  { "fn", ':let @+=expand("%:t")<CR>', "Copy file name" },
  { "lh", "<Cmd>checkhealth<CR>" },
  { "ll", "<cmd>Lazy<CR>", "Plugin Manager - [LazyVim]" },
  { "m", "<cmd>Mason<CR>", "Package Manager - [Mason]" },
  { "le", "<cmd>LazyExtras<CR>", "Extras Manager - [LazyVim]" },
  { "li", "<cmd>LspInfo<CR>", "Lsp Info" },
  { "mp", "<Cmd>MarkdownPreview<CR>" },
  { "mn", "<Cmd>ObsidianNew<CR>" },
  { "md", "<Cmd>ObsidianToday<CR>" },
  { "fc", "<Cmd>%s/\r//g<CR>", "Remove ^M" },
}

for _, keymap in ipairs(personal_keymaps) do
  map("n", prefix .. keymap[1], keymap[2], { noremap = true, silent = true, desc = keymap[3] })
end

-- Snippet keymaps
map({ "n", "x" }, prefix .. "sa", function()
  require("scissors").addNewSnippet()
end, { desc = "Snippet: Add" })

map("n", prefix .. "se", function()
  require("scissors").editSnippet()
end, { desc = "Snippet: Edit" })

-- Yazi keymaps
local yazi_keymaps = {
  { "yf", "<cmd>Yazi<cr>", "Open yazi at the current file" },
  { "yd", "<cmd>Yazi cwd<cr>", "Open the file manager in nvim's working directory" },
  { "yt", "<cmd>Yazi toggle<cr>", "Resume the last yazi session" },
}

for _, keymap in ipairs(yazi_keymaps) do
  map({ "n", "v" }, prefix .. keymap[1], keymap[2], { desc = keymap[3] })
end
