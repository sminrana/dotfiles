return {
  "sminrana/nvim-filediff",
  event = "VeryLazy", -- ensures keymaps load
  config = function()
    local filediff = require("filediff")

    vim.keymap.set("n", "<leader>jdf", "<cmd>FileDiff<CR>", { desc = "Diff two files" })
    vim.keymap.set("n", "<leader>jdi", "<cmd>FileDiffInput<CR>", { desc = "Diff via input paths" })
    vim.keymap.set("n", "<leader>jdd", "<cmd>FolderDiff<CR>", { desc = "Diff two folders" })
  end,
}

-- return {
--   dir = "~/github/nvim-filediff", -- exact path to your plugin directory
--   name = "filediff",
--   lazy = false, -- Changed to false so it loads immediately
--   config = function()
--     local filediff = require("filediff")

--       vim.keymap.set("n", "<leader>jdf", "<cmd>FileDiff<CR>", { desc = "Diff two files" })
--       vim.keymap.set("n", "<leader>jdi", "<cmd>FileDiffInput<CR>", { desc = "Diff via input paths" })
--       vim.keymap.set("n", "<leader>jdd", "<cmd>FolderDiff<CR>", { desc = "Diff two folders" })
--   end,
-- }
