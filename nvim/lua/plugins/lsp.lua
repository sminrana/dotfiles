return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      { "mason-org/mason.nvim", build = ":MasonUpdate" },
      "mason-org/mason-lspconfig.nvim",
    },
    config = function()
      local lspconfig = require("lspconfig")
      local util = require("lspconfig.util")

      -- ---------------- Mason ----------------
      require("mason").setup()

      require("mason-lspconfig").setup({
        ensure_installed = {
          "ts_ls",
          "vue_ls",
          "pyright",
          "intelephense",
          "rust_analyzer",
          "lua_ls",
        },
        automatic_installation = true,
      })

      -- ---------------- Capabilities ----------------
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities.textDocument.completion.completionItem.snippetSupport = true

      -- ---------------- Diagnostics ----------------
      vim.diagnostic.config({
        virtual_text = true,
        severity_sort = true,
        float = { border = "rounded" },
      })

      -- =====================================================
      -- Global on_attach (Disable formatting for ALL LSPs)
      -- =====================================================
      local on_attach = function(client, bufnr)
        -- Disable formatting (use none-ls)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
      end

      -- =====================================================
      -- TypeScript & Vue (Hybrid Mode)
      -- =====================================================
      lspconfig.ts_ls.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        root_dir = util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git"),
        init_options = {
          plugins = {
            {
              name = "@vue/typescript-plugin",
              location = vim.fn.stdpath("data")
                .. "/mason/packages/vue-language-server/node_modules/@vue/language-server",
              languages = { "vue" },
            },
          },
        },
        filetypes = {
          "typescript",
          "javascript",
          "javascriptreact",
          "typescriptreact",
          "vue",
        },
      })

      -- =====================================================
      -- Vue
      -- =====================================================
      lspconfig.vue_ls.setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })

      -- 🟪 Svelte
      lspconfig.svelte.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        root_dir = util.root_pattern("package.json", "svelte.config.js", ".git"),
        filetypes = { "svelte" },
      })

      -- 🍏 Swift
      lspconfig.sourcekit.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        root_dir = util.root_pattern("Package.swift", ".git"),
        filetypes = { "swift" },
      })

      -- =====================================================
      -- 🐍 Python (Enterprise Strict)
      -- =====================================================
      lspconfig.pyright.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        root_dir = util.root_pattern(
          "pyproject.toml",
          "setup.py",
          "setup.cfg",
          "requirements.txt",
          "Pipfile",
          ".git"
        ),
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "strict",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "workspace",
              autoImportCompletions = true,
            },
          },
        },
      })

      -- 🐘 PHP
      lspconfig.intelephense.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        root_dir = util.root_pattern("composer.json", ".git"),
      })

      -- 🦀 Rust
      lspconfig.rust_analyzer.setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })

      -- 🌙 Lua
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
          },
          format = {
            enable = false,
          },
        },
      })

      -- ================= Keymaps =================
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local buf = args.buf
          local map = function(lhs, rhs)
            vim.keymap.set("n", lhs, rhs, { buffer = buf })
          end

          map("gd", vim.lsp.buf.definition)
          map("gD", vim.lsp.buf.declaration)
          map("gr", vim.lsp.buf.references)
          map("gi", vim.lsp.buf.implementation)
          map("K", vim.lsp.buf.hover)
        end,
      })
    end,
  },
}
