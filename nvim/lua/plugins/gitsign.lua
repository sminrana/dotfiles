return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },

  opts = {
    -- Gutter signs (visual but not noisy)
    signs = {
      add = { text = "│" },
      change = { text = "│" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "~" },
      untracked = { text = "┆" },
    },

    -- Inline blame (GitLens-style)
    current_line_blame = true,
    current_line_blame_opts = {
      delay = 300,
      virt_text_pos = "eol",
      ignore_whitespace = false,
    },
    current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> • <summary>",

    -- Popup preview styling
    preview_config = {
      border = "rounded",
      style = "minimal",
    },
  },

  config = function(_, opts)
    require("gitsigns").setup(opts)
    ------------------------------------------------------------------
    -- Vibrant Git colors (GitHub / VS Code inspired)
    ------------------------------------------------------------------
    local set = vim.api.nvim_set_hl

    -- Gutter signs
    set(0, "GitSignsAdd", { fg = "#7EE787", bold = true }) -- green
    set(0, "GitSignsChange", { fg = "#79C0FF", bold = true }) -- blue
    set(0, "GitSignsDelete", { fg = "#F85149", bold = true }) -- red
    set(0, "GitSignsTopdelete", { fg = "#F85149", bold = true })
    set(0, "GitSignsChangedelete", { fg = "#FFA657", bold = true }) -- orange

    -- Line background highlights (subtle glow)
    set(0, "GitSignsAddLn", { bg = "#0E4429" }) -- dark green
    set(0, "GitSignsChangeLn", { bg = "#0C2D6B" }) -- dark blue
    set(0, "GitSignsDeleteLn", { bg = "#5A1E1E" }) -- dark red

    -- Inline blame text
    set(0, "GitSignsCurrentLineBlame", {
      fg = "#A1A1AA",
      italic = true,
    })

    -- Preview window border
    set(0, "GitSignsPreviewBorder", { fg = "#79C0FF" })
  end,
}
