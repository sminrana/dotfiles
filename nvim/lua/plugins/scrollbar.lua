return {
  "petertriho/nvim-scrollbar",
  event = "VeryLazy",
  opts = {
    show = true,
    handle = {
      color = "#6b7280", -- subtle gray
    },
    marks = {
      Cursor = { color = "#22d3ee" },
      Search = { color = "#fbbf24" },
      Error = { color = "#ef4444" },
      Warn = { color = "#f97316" },
      Info = { color = "#38bdf8" },
      Hint = { color = "#a78bfa" },
    },
  },
}
