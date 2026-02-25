return {
  "petertriho/nvim-scrollbar",
  event = "VeryLazy",
  dependencies = {
    "lewis6991/gitsigns.nvim",
  },
  opts = {
    -- Make the scrollbar itself thicker
    thickness = 10, -- default is 6
    min_size = 20, -- minimum size of handle

    handle = {
      color = "#6b7280",
    },

    marks = {
      Cursor = { color = "#22d3ee" },
      Search = { color = "#fbbf24" },
      Error = { color = "#ef4444" },
      Warn = { color = "#f97316" },

      -- Git signs (make these stand out more)
      GitAdd = { color = "#7EE787" },
      GitChange = { color = "#79C0FF" },
      GitDelete = { color = "#F85149" },
    },

    -- IMPORTANT: ensures highlights are applied strongly
    set_highlights = true,
  },
}
