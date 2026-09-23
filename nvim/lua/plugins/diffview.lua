return {
  "sindrets/diffview.nvim",
  event = "VeryLazy",
  config = function()
    local diffview = require("diffview")
    local actions = require("diffview.actions")

    diffview.setup({
      default_args = {
        DiffviewOpen = { "--imply-local" },
      },
      enhanced_diff_hl = true,

      view = {
        default = {
          layout = "diff2_horizontal",
          winbar_info = true,
        },
        merge_tool = {
          layout = "diff3_mixed",
        },
      },

      file_panel = {
        listing_style = "list",
        win_config = {
          width = 30,
        },
      },

      keymaps = {
        -- 🔍 DIFF VIEW (actual diff buffers)
        view = {
          -- File navigation
          { "n", "[q", actions.select_prev_entry, { desc = "Previous changed file" } },
          { "n", "]q", actions.select_next_entry, { desc = "Next changed file" } },
          -- Conflict navigation
          { "n", "[h", actions.prev_conflict, { desc = "Previous conflict" } },
          { "n", "]h", actions.next_conflict, { desc = "Next conflict" } },
          { "n", "[x", actions.prev_conflict, { desc = "Previous conflict" } },
          { "n", "]x", actions.next_conflict, { desc = "Next conflict" } },
          -- Actions
          { "n", "gf", actions.goto_file_edit, { desc = "Open file in edit buffer" } },
          { "n", "<C-w>gf", actions.goto_file_tab, { desc = "Open file in new tab" } },
          { "n", "<leader>e", actions.toggle_files, { desc = "Toggle file panel" } },
          { "n", "q", actions.close, { desc = "Close Diffview" } },
        },

        -- 📁 FILE PANEL
        file_panel = {
          { "n", "j", actions.next_entry, { desc = "Next entry" } },
          { "n", "k", actions.prev_entry, { desc = "Previous entry" } },
          { "n", "<cr>", actions.select_entry, { desc = "Select entry" } },
          { "n", "s", actions.toggle_stage_entry, { desc = "Stage / unstage entry" } },
          { "n", "R", actions.refresh_files, { desc = "Refresh file list" } },
          { "n", "[q", actions.select_prev_entry, { desc = "Previous changed file" } },
          { "n", "]q", actions.select_next_entry, { desc = "Next changed file" } },
          { "n", "<leader>e", actions.toggle_files, { desc = "Toggle file panel" } },
          { "n", "q", actions.close, { desc = "Close Diffview" } },
        },
      },

      hooks = {
        -- 🚨 FORCE DIFF MODE (THIS FIXES [c / ]c)
        diff_buf_read = function(bufnr)
          vim.api.nvim_buf_call(bufnr, function()
            vim.opt_local.diff = true
            vim.cmd("normal! zR") -- open all folds
          end)
        end,
      },
    })

    -- 🔑 GLOBAL REVIEW HOTKEYS
    vim.keymap.set("n", "<leader>gd", "<Cmd>DiffviewOpen<CR>", { desc = "Review: open Diffview" })
    vim.keymap.set("n", "<leader>gD", "<Cmd>DiffviewClose<CR>", { desc = "Review: close Diffview" })
    vim.keymap.set("n", "<leader>gF", "<Cmd>DiffviewFileHistory<CR>", { desc = "Review: files history" })
    vim.keymap.set("n", "<leader>gH", "<Cmd>DiffviewFileHistory %<CR>", { desc = "Review: current file history" })
  end,
}
