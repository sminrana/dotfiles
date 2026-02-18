return {
  "sindrets/diffview.nvim",
  event = "VeryLazy",
  config = function()
    -- Basic setup (keeps defaults; customize if needed)
    require("diffview").setup({
       enhanced_diff_hl = true, -- Better syntax highlighting in diffs
        view = {
          merge_tool = {
            layout = "diff3_mixed",
          },
        },
    })

    -- Key mappings for common actions
    vim.keymap.set("n", "<leader>gdo", ":DiffviewOpen<CR>", { desc = "Diffview: open" })
    vim.keymap.set("n", "<leader>gdc", ":DiffviewClose<CR>", { desc = "Diffview: close" })
    vim.keymap.set("n", "<leader>gdh", ":DiffviewFileHistory<CR>", { desc = "Diffview: file history" })

    -- Open current file history in Diffview
    vim.keymap.set("n", "<leader>gdH", function()
      local file = vim.fn.expand("%")
      if file == "" then
        vim.notify("No file buffer to show history", vim.log.levels.WARN)
        return
      end
      vim.cmd("DiffviewFileHistory " .. vim.fn.fnameescape(file))
    end, { desc = "Diffview: current file history" })

    -- Open diff against main branch (customizable)
    vim.keymap.set("n", "<leader>gdm", function()
      vim.cmd("DiffviewOpen origin/main")
    end, { desc = "Diffview: diff vs origin/main" })
  end,
}
