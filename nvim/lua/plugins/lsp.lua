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

      local on_attach = function(client, bufnr)
        if client.name == "ts_ls" then
          client.server_capabilities.documentFormattingProvider = false
        end
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
        filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
      })

      -- =====================================================
      -- Vue
      -- =====================================================
      lspconfig.vue_ls.setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })

      -- 🟪 SvelteKit
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

      -- ---------------- Other servers ----------------
      -- 🐍 Python
      lspconfig.pyright.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        root_dir = util.root_pattern("pyproject.toml", ".git"),
      })

      -- 🐘 PHP
      lspconfig.intelephense.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        root_dir = util.root_pattern("composer.json", ".git"),
      })

      -- Keep Phpactor for refactors/code actions
      -- lspconfig.phpactor.setup({
      --   capabilities = capabilities,
      --   on_attach = on_attach,
      --   cmd = { "phpactor", "language-server" },
      --   filetypes = { "php" },
      --   root_dir = function(fname)
      --     return util.root_pattern("composer.json", "artisan", ".git", ".phpactor.json")(fname) or vim.fn.getcwd()
      --   end,
      --   init_options = {
      --     ["language_server_phpstan.enabled"] = false,
      --     ["language_server_psalm.enabled"] = false,
      --   },
      -- })

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
