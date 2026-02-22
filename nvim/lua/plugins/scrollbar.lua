return {
  "petertriho/nvim-scrollbar",
  event = "VeryLazy",
  dependencies = {
    "lewis6991/gitsigns.nvim",
  },
  opts = {
    handle = { color = "#6b7280" },
    marks = {
      Cursor = { color = "#22d3ee" },
      Search = { color = "#fbbf24" },
      Error = { color = "#ef4444" },
      Warn = { color = "#f97316" },
      GitAdd = { color = "#7EE787" },
      GitChange = { color = "#79C0FF" },
      GitDelete = { color = "#F85149" },
    },
  },
}
