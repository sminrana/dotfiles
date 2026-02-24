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
        listing_style = "tree",
        win_config = {
          width = 30, -- bit wider for better readability
        },
      },
      keymaps = {
        view = {
          -- 🏗️ Navigation (while in the diff view)
          ["[q"] = actions.select_prev_entry,   -- Jump to previous file
          ["]q"] = actions.select_next_entry,   -- Jump to next file
          ["gf"] = actions.goto_file_edit,      -- Open file in normal buffer
          ["<C-w>gf"] = actions.goto_file_tab,  -- Open file in new tab
          ["<leader>e"] = actions.toggle_files, -- Toggle file panel
          ["q"] = actions.close,
        },
        file_panel = {
          ["j"] = actions.next_entry,
          ["k"] = actions.prev_entry,
          ["<cr>"] = actions.select_entry,
          ["o"] = actions.select_entry,
          ["s"] = actions.toggle_stage_entry,   -- Stage/unstage (approval)
          ["R"] = actions.refresh_files,        -- Refresh view
          ["[q"] = actions.select_prev_entry,
          ["]q"] = actions.select_next_entry,
          ["<leader>e"] = actions.toggle_files,
        },
        file_history_panel = {
          ["[q"] = actions.select_prev_entry,
          ["]q"] = actions.select_next_entry,
          ["<cr>"] = actions.select_entry,
          ["o"] = actions.select_entry,
        },
      },
      hooks = {
        diff_buf_read = function(bufnr)
          vim.api.nvim_buf_call(bufnr, function()
            vim.cmd("normal! zR") -- Auto-unfold all hunks
          end)
        end,
      },
    })

    -- 🔑 GLOBAL REVIEW HOTKEYS
    vim.keymap.set("n", "<leader>gd", "<Cmd>DiffviewOpen<CR>", { desc = "Review: open Diffview" })
    vim.keymap.set("n", "<leader>gD", "<Cmd>DiffviewClose<CR>", { desc = "Review: close Diffview" })
    vim.keymap.set("n", "<leader>gF", "<Cmd>DiffviewFileHistory<CR>", { desc = "Review: files history" })
    vim.keymap.set("n", "<leader>gH", "<Cmd>DiffviewFileHistory %<CR>", { desc = "Review: current file history" })
    vim.keymap.set("n", "<leader>gm", "<Cmd>DiffviewOpen origin/main<CR>", { desc = "Review: vs origin/main" })
    vim.keymap.set("n", "<leader>gp", "<Cmd>DiffviewOpen main...HEAD<CR>", { desc = "Review: current PR (vs main)" })
  end,
}