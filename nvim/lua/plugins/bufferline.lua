return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  opts = {
    options = {
      numbers = function(opts)
        -- Show buffer ID followed by a colon
        return string.format("%s", opts.id)
      end,
    },
  },
}
