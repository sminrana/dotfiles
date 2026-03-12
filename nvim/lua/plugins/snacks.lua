return {
  "folke/snacks.nvim",
  lazy = true,
  opts = {
    explorer = {
      enabled = false,
    },
  },
  keys = {
    {
      "<leader>e",
      function()
        require("snacks").explorer({
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
