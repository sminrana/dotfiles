return {
  -- Xcode build/run integration
  {
    "wojciech-kulik/xcodebuild.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("xcodebuild").setup({})
      -- Keymaps must be defined outside the setup() table
      local map = vim.keymap.set
      map("n", "<leader>jxb", "<cmd>XcodebuildBuild<cr>", { desc = "Xcode Build" })
      map("n", "<leader>jxr", "<cmd>XcodebuildBuildRun<cr>", { desc = "Xcode Build & Run" })
      map("n", "<leader>jxc", "<cmd>XcodebuildCancel<cr>", { desc = "Xcode Cancel Build" })
      map("n", "<leader>jxx", "<cmd>XcodebuildCleanBuild<cr>", { desc = "Xcode Clean Build" })
      map("n", "<leader>jxa", "<cmd>XcodebuildCreateNewFile<cr>", { desc = "Xcode Add New File" })
    end,
  },

  -- Swift linting via nvim-lint
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        swift = { "swiftlint" },
      }

      local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

      vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
        group = lint_augroup,
        callback = function()
          local buf = vim.api.nvim_get_current_buf()
          local name = vim.api.nvim_buf_get_name(buf)
          if not name:match("%.swiftinterface$") then
            lint.try_lint()
          end
        end,
      })
    end,
  },

  -- Swift syntax highlighting
  {
    "keith/swift.vim",
    ft = "swift",
  },
}
