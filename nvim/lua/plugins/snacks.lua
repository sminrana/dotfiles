return {
  "folke/snacks.nvim",
  lazy = true,
  opts = {
    explorer = {
      enabled = false,
      auto_close = true, -- closes explorer when file is opened
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
