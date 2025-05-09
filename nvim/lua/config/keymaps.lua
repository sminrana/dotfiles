-- vim.keymap.set({ "i", "x", "n", "s" }, "<C-s>", "<nop>")
-- vim.keymap.set("n", "h", "<C-Left>", { desc = "Left arrow", remap = true })
-- vim.keymap.set("n", "k", "<C-Up>", { desc = "Up arrow", remap = true })
-- vim.keymap.set("n", "j", "<C-Down>", { desc = "Down arrow", remap = true })
-- vim.keymap.set("n", "l", "<C-Right>", { desc = "Right arrow", remap = true })

vim.keymap.set("i", "jj", "<Esc>", { desc = "Map jj to Esc", remap = true })
vim.keymap.set("n", "Q", "q", { desc = "Q for q" })
vim.keymap.set("n", "q", "<nop>", { desc = "Disable q" })
vim.keymap.set("n", "gO", "<Cmd>call append(line('.') - 1, repeat([''], v:count1))<CR>")
vim.keymap.set("n", "go", "<Cmd>call append(line('.'),     repeat([''], v:count1))<CR>")
vim.keymap.set("n", "<leader>e", "<Cmd>Neotree reveal float<CR>", {})

--- Keymap for blink.cmp
vim.keymap.set("n", "<leader>fa", function()
  require("fzf-lua").live_grep({
    cwd = "~/app/",
  })
end, { desc = "Live Grep in App Files" })

vim.keymap.set("n", "<leader>fw", function()
  require("fzf-lua").live_grep({
    cwd = "~/web/",
  })
end, { desc = "Live Grep in Web Files" })

vim.keymap.set("n", "<leader>fx", function()
  require("fzf-lua").live_grep({
    cwd = "~/Desktop/obs-v1/",
  })
end, { desc = "Live Grep in Notes Files" })

vim.keymap.set("n", "<leader>fs", function()
  require("fzf-lua").live_grep({
    cwd = "~/Desktop/snippets/",
  })
end, { desc = "Live Grep in Snippets Files" })

vim.keymap.set("n", "<leader>ba", function()
  require("fzf-lua").blines()
end, { desc = "Live Grep in Current Buffer" })

-- Personal keymaps start here, prefix <leader>o
local prefix = "<leader>o"

vim.keymap.set("n", prefix .. "C", "<Cmd>%y<CR>", { noremap = true, silent = true, desc = "Copy All" })
vim.keymap.set("n", prefix .. "D", "<Cmd>%d<CR>", { noremap = true, silent = true, desc = "Delete All" })
vim.keymap.set("n", prefix .. "X", "ggVGx", { noremap = true, silent = true, desc = "Cut All" })
vim.keymap.set("n", prefix .. "S", "ggVG", { noremap = true, silent = true, desc = "Select All" })
vim.keymap.set("n", prefix .. "t", "<Cmd>tabe ~/Desktop/obs-v1/todo.md<CR>", { silent = true })
vim.keymap.set("n", prefix .. "n", "<Cmd>tabe ~/Desktop/obs-v1/notes.md<CR>", { silent = true })
-- Personal keymaps start here prefix <leader>o
vim.keymap.set("n", "<leader>out", "<cmd>UndotreeToggle<cr>", { desc = "Toggle Undotree" })
vim.keymap.set("n", "<leader>oC", "<Cmd>%y<CR>", { noremap = true, silent = true, desc = "Copy All" })
vim.keymap.set("n", "<leader>oD", "<Cmd>%d<CR>", { noremap = true, silent = true, desc = "Delete All" })
vim.keymap.set("n", "<leader>oX", "ggVGx", { noremap = true, silent = true, desc = "Cut All" })
vim.keymap.set("n", "<leader>oS", "ggVG", { noremap = true, silent = true, desc = "Select All" })
vim.keymap.set("n", "<leader>ot", "<Cmd>tabe ~/Desktop/obs-v1/todo.md<CR>", { silent = true })
vim.keymap.set("n", "<leader>on", "<Cmd>tabe ~/Desktop/obs-v1/notes.md<CR>", { silent = true })
vim.keymap.set(
  "n",
  prefix .. "fp",
  ':let @+=expand("%:p")<CR>',
  { noremap = true, silent = true, desc = "Copy file absolute path" }
)

vim.keymap.set("n", "<leader>om", "<Cmd>MarkdownPreview<CR>", { silent = true })
vim.keymap.set("n", "<leader>och", "<Cmd>checkhealth<CR>", { silent = true })

vim.keymap.set("n", "<leader>om", "<Cmd>MarkdownPreview<CR>", { silent = true })
vim.keymap.set("n", "<leader>och", "<Cmd>checkhealth<CR>", { silent = true })

vim.keymap.set("n", prefix .. "ch", "<Cmd>checkhealth<CR>", { silent = true })
vim.keymap.set("n", prefix .. "cl", "<cmd>Lazy<CR>", { desc = "Plugin Manager - [LazyVim]" })
vim.keymap.set("n", prefix .. "cm", "<cmd>Mason<CR>", { desc = "Package Manager - [Mason]" })
vim.keymap.set("n", prefix .. "ce", "<cmd>LazyExtras<CR>", { desc = "Extras Manager - [LazyVim]" })
vim.keymap.set("n", prefix .. "ci", "<cmd>LspInfo<CR>", { desc = "Lsp Info" })

vim.keymap.set("n", prefix .. "m", "<Cmd>MarkdownPreview<CR>", { silent = true })
vim.keymap.set({ "n", "x" }, prefix .. "sa", function()
  require("scissors").addNewSnippet()
end, { desc = "Snippet: Add" })

vim.keymap.set("n", prefix .. "se", function()
  require("scissors").editSnippet()
end, { desc = "Snippet: Edit" })

vim.keymap.set({ "n", "v" }, prefix .. "yf", "<cmd>Yazi<cr>", { desc = "Open yazi at the current file" })
vim.keymap.set("n", prefix .."yd", "<cmd>Yazi cwd<cr>", { desc = "Open the file manager in nvim's working directory" })
vim.keymap.set("n", prefix .. "yt", "<cmd>Yazi toggle<cr>", { desc = "Resume the last yazi session" })