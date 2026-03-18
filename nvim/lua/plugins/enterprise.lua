return {

  -- =====================================
  -- MASON: Manage LSP, linters, formatters
  -- =====================================
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- LSPs
        "gopls",
        "intelephense",
        "pyright",
        "typescript-language-server",
        "vue-language-server",
        "lua-language-server",
        "svelte-language-server",
        "tailwindcss-language-server",

        -- Formatters
        "gofumpt",
        "goimports",
        "pint",
        "ruff",
        "prettier",
        "swiftformat",

        -- Linters
        "golangci-lint",
        "phpstan",
      },
      automatic_installation = false, -- enterprise: explicit control
    },
  },

  -- =====================================
  -- LSP CONFIG
  -- =====================================
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Go
        gopls = {},

        -- PHP
        intelephense = {},

        -- Python
        pyright = {},

        -- JS/TS
        tsserver = {},

        -- Vue / Svelte / Tailwind / Lua / Rust
        vue_ls = {},
        svelte_ls = {},
        tailwindcss_ls = {},
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = { globals = { "vim" } },
            },
          },
        },
        rust_analyzer = {},
      },

      setup = {
        ["*"] = function(_, opts)
          opts.on_attach = function(client)
            -- disable formatting from LSP, handled by separate formatter
            client.server_capabilities.documentFormattingProvider = false
          end
        end,
      },
    },
  },

  -- =====================================
  -- FORMATTERS: conform.nvim
  -- =====================================
  {
    "stevearc/conform.nvim",
    dependencies = { "mason.nvim" },
    lazy = true,
    cmd = "ConformInfo",
    opts = {
      formatters_by_ft = {
        go = { "gofumpt", "goimports" },
        php = { "pint" },
        python = { "ruff_format" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        json = { "prettier" },
        svelte = { "prettier" },
        vue = { "prettier" },
        swift = { "swiftformat" },
        lua = { "lua_format" }, -- optional if needed
      },

      formatters = {
        ruff_format = {
          command = "ruff",
          args = { "format", "-" },
          stdin = true,
        },
        pint = { prefer_local = "vendor/bin", extra_args = { "--quiet" } },
        prettier = { extra_args = { "--print-width", "100", "--single-quote", "--trailing-comma", "all" } },
        swiftformat = { extra_args = { "--indent", "4" } },
      },
    },
  },

  -- =====================================
  -- LINTERS: nvim-lint
  -- =====================================
  {
    "mfussenegger/nvim-lint",
    event = "BufReadPre",
    opts = {
      linters_by_ft = {
        go = { "golangci_lint" },
        php = { "phpstan" },
        python = { "ruff" },
        javascript = { "eslint" },
        typescript = { "eslint" },
        swift = { "swiftlint" },
      },
    },
  },
}
