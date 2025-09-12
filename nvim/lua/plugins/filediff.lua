return {
  "sminrana/nvim-filediff",
  config = function()
    local filediff = require("filediff")
    vim.keymap.set("n", "<leader>jdf", filediff.FileDiff, { desc = "Diff two files" })
    vim.keymap.set("n", "<leader>jdi", filediff.FileDiffInputs, { desc = "Diff via input paths" })
    vim.keymap.set("n", "<leader>jdd", filediff.FolderDiff, { desc = "Diff two folders (require absolute path)" })
  end,
}
