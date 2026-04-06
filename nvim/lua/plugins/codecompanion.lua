return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
    { "nvim-lua/plenary.nvim" },
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
    { "<leader>av", "<cmd>CodeCompanion<cr>", mode = "n", desc = "CodeCompanion Inline" },
    { "<leader>av", ":'<,'>CodeCompanion<cr>", mode = "v", desc = "CodeCompanion Inline (Selection)" },
  },
}

