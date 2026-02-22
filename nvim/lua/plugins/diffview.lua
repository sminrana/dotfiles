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
          ["p"] = actions.prev_conflict,
          ["l"] = actions.select_next_entry,
          ["h"] = actions.select_prev_entry,
          ["o"] = actions.open_file,
          ["q"] = actions.close,
          ["]c"] = function()
            actions.next_conflict()
            -- if no more hunks in file, jump to next file
            local success = pcall(actions.select_next_entry)
            if not success then
              return
            end
          end,
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
