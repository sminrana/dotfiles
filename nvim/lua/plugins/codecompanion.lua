return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
    { "nvim-lua/plenary.nvim" },
    -- Test with blink.cmp
    {
      "saghen/blink.cmp",
      lazy = false,
      version = "*",
      opts = {
        keymap = {
          preset = "enter",
          ["<S-Tab>"] = { "select_prev", "fallback" },
          ["<Tab>"] = { "select_next", "fallback" },
        },
        cmdline = { sources = { "cmdline" } },
        sources = {
          default = { "lsp", "path", "buffer", "codecompanion" },
        },
      },
    },
  },
  opts = {
    adapters = {
      copilot = function()
        return require("codecompanion.adapters").extend("copilot")
      end,
    },
    strategies = {
      chat = { adapter = "copilot" },
      inline = { adapter = "copilot" },
      agent = { adapter = "copilot" },
    },
    log_level = "DEBUG",
  },
  keys = {
    { "<leader>axa", "<cmd>CodeCompanionActions<cr>", desc = "CodeCompanion Actions" },
    { "<leader>axc", "<cmd>CodeCompanionChat Toggle<cr>", desc = "CodeCompanion Chat Toggle" },
    { "<leader>axi", "<cmd>CodeCompanion<cr>", mode = "n", desc = "CodeCompanion Inline" },
    { "<leader>axi", ":'<,'>CodeCompanion<cr>", mode = "v", desc = "CodeCompanion Inline (Selection)" },
  },
}

