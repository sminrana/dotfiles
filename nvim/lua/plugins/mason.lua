return {
  "mason-org/mason.nvim",
  opts = {
    ensure_installed = {
      -- LSP
      "intelephense",
      "typescript-language-server",
      "vue-language-server",
      "pyright",
      "ruff",
      "rust-analyzer",
      "lua-language-server",

      -- formatters
      "pint",
      "php-cs-fixer",
      "prettier",
      "swiftformat",
    },
  },
}
