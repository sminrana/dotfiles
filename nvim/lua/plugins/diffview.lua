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
          layout = "diff2_horizontal",
          winbar_info = true,
        },
        merge_tool = {
          layout = "diff3_mixed",
        },
      },

      file_panel = {
        listing_style = "tree",
        win_config = {
          width = 30,
        },
      },

      keymaps = {
        -- 🔍 DIFF VIEW (actual diff buffers)
        view = {
          -- FILE navigation
          ["[q"] = actions.select_prev_entry,
          ["]q"] = actions.select_next_entry,
          -- Actions
          ["gf"] = actions.goto_file_edit,
          ["<C-w>gf"] = actions.goto_file_tab,
          ["<leader>e"] = actions.toggle_files,
          ["p"] = actions.prev_conflict,
          ["q"] = actions.close,
        },

        -- 📁 FILE PANEL
        file_panel = {
          ["j"] = actions.next_entry,
          ["k"] = actions.prev_entry,
          ["<cr>"] = actions.select_entry,
          ["s"] = actions.toggle_stage_entry,
          ["R"] = actions.refresh_files,
          ["[q"] = actions.select_prev_entry,
          ["]q"] = actions.select_next_entry,
          ["<leader>e"] = actions.toggle_files,
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
