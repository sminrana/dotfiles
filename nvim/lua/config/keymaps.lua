-- vim.keymap.set({ "i", "x", "n", "s" }, "<C-s>", "<nop>")
-- vim.keymap.set("n", "h", "<C-Left>", { desc = "Left arrow", remap = true })
-- vim.keymap.set("n", "k", "<C-Up>", { desc = "Up arrow", remap = true })
-- vim.keymap.set("n", "j", "<C-Down>", { desc = "Down arrow", remap = true })
-- vim.keymap.set("n", "l", "<C-Right>", { desc = "Right arrow", remap = true })

-- vim.keymap.set("i", "jj", "<Esc>", { desc = "Map jj to Esc", remap = true })

vim.keymap.set("n", "Q", "q", { desc = "Q for q" })
vim.keymap.set("n", "q", "<nop>", { desc = "Disable q" })
vim.keymap.set("n", "gO", "<Cmd>call append(line('.') - 1, repeat([''], v:count1))<CR>")
vim.keymap.set("n", "go", "<Cmd>call append(line('.'),     repeat([''], v:count1))<CR>")
vim.keymap.set("n", "<leader>e", "<Cmd>Neotree reveal float<CR>", {})

vim.keymap.set("n", "<leader>out", "<cmd>UndotreeToggle<cr>", { desc = "Toggle Undotree" })
vim.keymap.set("n", "<leader>oC", "<Cmd>%y<CR>", { noremap = true, silent = true, desc = "Copy All" })
vim.keymap.set("n", "<leader>oD", "<Cmd>%d<CR>", { noremap = true, silent = true, desc = "Delete All" })
vim.keymap.set("n", "<leader>oX", "ggVGx", { noremap = true, silent = true, desc = "Cut All" })
vim.keymap.set("n", "<leader>oS", "ggVG", { noremap = true, silent = true, desc = "Select All" })
vim.keymap.set("n", "<leader>ot", "<Cmd>tabe ~/Desktop/obs-v1/todo.md<CR>", { silent = true })
vim.keymap.set("n", "<leader>on", "<Cmd>tabe ~/Desktop/obs-v1/notes.md<CR>", { silent = true })
vim.keymap.set(
  "n",
  "<leader>ocp",
  ':let @+=expand("%:p")<CR>',
  { noremap = true, silent = true, desc = "Copy file absolute path" }
)

vim.keymap.set(
	{ "n", "x" },
	"<leader>osa",
	function() require("scissors").addNewSnippet() end,
	{ desc = "Snippet: Add" }
)

vim.keymap.set(
	"n",
	"<leader>ose",
	function() require("scissors").editSnippet() end,
	{ desc = "Snippet: Edit" }
)