return {
  {
    "mfussenegger/nvim-lint",
    optional = true,
    config = function()
      local phpcs = require("lint").linters.phpcs
      phpcs.args = {
        "-q",
        -- <- Add a new parameter here
        "--standard=PSR12",
        "--report=json",
        "-",
      }
    end,
    opts = {
      linters_by_ft = {
        php = { "phpcs" },
        markdown = { "markdownlint" },
        css = { "stylelint" },
      },
    },
  },
}
