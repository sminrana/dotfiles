return {
  "mfussenegger/nvim-lint",
  event = "LazyFile",
  opts = {
    linters_by_ft = {
      php = { "phpstan", "phpcs" },
      python = { "ruff" },
      javascript = { "eslint" },
      typescript = { "eslint" },
      swift = { "swiftlint" },
      go = { "golangcilint" },
    },
  },
}
