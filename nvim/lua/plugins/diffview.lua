return {
  "sindrets/diffview.nvim",
  event = "VeryLazy",
  config = function()
    local diffview = require("diffview")

    local actions = require("diffview.actions")
    diffview.setup({
      enhanced_diff_hl = true,

      view = {
        default = {
          layout = "diff2_horizontal", -- side-by-side like GitHub
          winbar_info = true,
        },
        merge_tool = {
          layout = "diff3_mixed",
        },
      },

      file_panel = {
        listing_style = "tree", -- fast mental map
        win_config = {
          width = 10,
        },
      },

      keymaps = {
        view = {
          ["q"] = actions.close,
        },
      },
    })

    -- 🔑 REVIEW HOTKEYS (muscle-memory friendly)
    vim.keymap.set("n", "<leader>gd", "<Cmd>DiffviewOpen<CR>", { desc = "Review: open Diffview" })
    vim.keymap.set("n", "<leader>gD", "<Cmd>DiffviewClose<CR>", { desc = "Review: close Diffview" })
    vim.keymap.set("n", "<leader>gF", "<Cmd>DiffviewFileHistory<CR>", { desc = "Review: files history" })
    vim.keymap.set("n", "<leader>gH", "<Cmd>DiffviewFileHistory %<CR>", { desc = "Review: current file history" })
    vim.keymap.set("n", "<leader>gm", "<Cmd>DiffviewOpen origin/main<CR>", { desc = "Review: vs origin/main" })
  end,
}
