return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {

      -- PHP
      intelephense = {},

      -- JS / TS
      ts_ls = {},

      -- Vue
      vue_ls = {},

      svelte = {},

      tailwindcss = {},

      -- Python
      pyright = {},

      -- Ruff linting
      ruff = {},

      -- Rust
      rust_analyzer = {},

      -- Lua
      lua_ls = {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
          },
        },
      },
    },

    setup = {
      ["*"] = function(_, opts)
        opts.on_attach = function(client)
          -- disable formatting from LSP
          client.server_capabilities.documentFormattingProvider = false
        end
      end,
    },
  },
}
