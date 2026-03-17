return {
  "stevearc/conform.nvim",
  dependencies = { "mason.nvim" },
  lazy = true,
  cmd = "ConformInfo",
  opts = {
    formatters_by_ft = {
      php = { "pint" },
      html = { "prettier" },
      css = { "prettier" },
      javascript = { "prettier" },
      javascriptreact = { "prettier" },
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
      json = { "prettier" },
      svelte = { "prettier" },
      vue = { "prettier" },
      swift = { "swiftformat" },
      python = { "black" },
      go = { "gofumpt", "goimports" },
    },
    formatters = {
      pint = {
        prefer_local = "vendor/bin",
        extra_args = { "--quiet" },
      },
      blade_formatter = {
        extra_args = { "--indent-size", "4" },
      },
      prettier = {
        extra_args = {
          "--print-width",
          "100",
          "--single-quote",
          "--trailing-comma",
          "all",
        },
      },
      swiftformat = {
        extra_args = { "--indent", "4" },
      },
    },
  },
}
