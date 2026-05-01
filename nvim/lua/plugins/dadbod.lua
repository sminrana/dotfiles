return {
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      {
        "kristijanhusak/vim-dadbod-completion",
        ft = { "sql", "mysql", "plsql" },
        lazy = true,
      },
    },

    cmd = {
      "DBUI",
      "DBUIToggle",
      "DBUIAddConnection",
      "DBUIFindBuffer",
    },

    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
    end,

    keys = {
      {
        "<leader>jdb",
        "<cmd>DBUI<cr>",
        desc = "Open Database UI",
      },
      {
        "<leader>jdt",
        "<cmd>DBUIToggle<cr>",
        desc = "Toggle DB UI",
      },
      {
        "<leader>jdq",
        "<cmd>DBUIFindBuffer<cr>",
        desc = "Find DB Buffer",
      },
    },
  },
}
