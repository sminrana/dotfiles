-- vim.keymap.set({ "i", "x", "n", "s" }, "<C-s>", "<nop>")
-- vim.keymap.set("n", "h", "<C-Left>", { desc = "Left arrow", remap = true })
-- vim.keymap.set("n", "k", "<C-Up>", { desc = "Up arrow", remap = true })
-- vim.keymap.set("n", "j", "<C-Down>", { desc = "Down arrow", remap = true })
-- vim.keymap.set("n", "l", "<C-Right>", { desc = "Right arrow", remap = true })

-- vim.keymap.set("i", "jj", "<Esc>", { desc = "Map jj to Esc", remap = true })

vim.keymap.set("n", "Q", "q", { desc = "Q for q" })
vim.keymap.set("n", "q", "<nop>", { desc = "Disable q" })

-- Add empty lines before and after cursor line
vim.keymap.set("n", "gO", "<Cmd>call append(line('.') - 1, repeat([''], v:count1))<CR>")
vim.keymap.set("n", "go", "<Cmd>call append(line('.'),     repeat([''], v:count1))<CR>")
vim.keymap.set("n", "<leader>cu", "<cmd>UndotreeToggle<cr>", { desc = "Toggle Undotree" })

vim.keymap.set("n", "<leader>bC", "<Cmd>%y<CR>", { noremap = true, silent = true, desc = "Copy All" })
vim.keymap.set("n", "<leader>bD", "<Cmd>%d<CR>", { noremap = true, silent = true, desc = "Delete All" })
vim.keymap.set("n", "<leader>bX", "ggVGx", { noremap = true, silent = true, desc = "Cut all" })
vim.keymap.set("n", "<leader>e", ":Neotree reveal float<CR>", {})
