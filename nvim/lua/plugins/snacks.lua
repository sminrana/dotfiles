return {
  "folke/snacks.nvim",
  lazy = true,
  opts = {
    explorer = {
      enabled = false,
      auto_close = true, -- closes explorer when file is opened
    },
    picker = {
      sources = {
        explorer = {
          hidden = true, -- show dotfiles (.git, .env)
          ignored = true, -- show .gitignored files
        },
      },
    },
  },
  keys = {
    {
      "<leader>e",
      function()
        require("snacks").explorer({
          auto_close = true, -- closes explorer when file is opened
          layout = {
            layout = {
              position = "float",
              border = "rounded",
              width = 0.5,
              height = 0.9,
            },
          },
        })
      end,
      desc = "Floating Explorer",
    },
  },
}
