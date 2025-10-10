return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPost", "BufNewFile" },
  cmd = { "LspInfo", "LspInstall", "LspUninstall", "LspStart", "LspStop", "LspRestart" },
  config = function()
    local lspconfig = require("lspconfig")
    local util = require("lspconfig.util")

    -- === Shared capabilities ===
    local capabilities = vim.lsp.protocol.make_client_capabilities()

    -- === React Native / JS / TS ===
    lspconfig.ts_ls.setup({
      cmd = { "typescript-language-server", "--stdio" },
      filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "json",
      },
      root_dir = function(fname)
        -- detect React Native project roots more flexibly
        return util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git")(fname)
          or util.root_pattern("app.json", "index.js", "index.tsx")(fname)
          or vim.fn.getcwd()
      end,
      capabilities = capabilities,
      settings = {
        typescript = {
          preferences = { importModuleSpecifier = "non-relative" },
          inlayHints = {
            includeInlayParameterNameHints = "all",
            includeInlayFunctionParameterTypeHints = true,
            includeInlayVariableTypeHints = true,
          },
        },
        javascript = {
          inlayHints = {
            includeInlayParameterNameHints = "all",
            includeInlayVariableTypeHints = true,
          },
        },
      },
      single_file_support = true,
    })

    -- === Python / Django ===
    lspconfig.pyright.setup({
      cmd = { "pyright-langserver", "--stdio" },
      filetypes = { "python" },
      root_dir = util.root_pattern("manage.py", "pyproject.toml", "setup.py", ".git"),
      capabilities = capabilities,
      settings = {
        python = {
          analysis = {
            typeCheckingMode = "basic",
            autoSearchPaths = true,
            useLibraryCodeForTypes = true,
            diagnosticMode = "workspace",
          },
        },
      },
    })

    -- === Swift (SourceKit-LSP) ===
    lspconfig.sourcekit.setup({
      cmd = { "xcrun", "sourcekit-lsp" },
      filetypes = { "swift", "objective-c", "objective-cpp" },
      root_dir = util.root_pattern("Package.swift", ".git"),
      capabilities = capabilities,
    })

    -- === Optional: other servers you already had ===
    lspconfig.clangd.setup({ capabilities = capabilities })
    lspconfig.lua_ls.setup({
      capabilities = capabilities,
      settings = {
        Lua = {
          diagnostics = { globals = { "vim" } },
          workspace = { library = vim.api.nvim_get_runtime_file("", true), checkThirdParty = false },
          telemetry = { enable = false },
        },
      },
    })

    lspconfig.phpactor.setup({ capabilities = capabilities })

    lspconfig.rust_analyzer.setup({
      capabilities = capabilities,
      settings = {
        ["rust-analyzer"] = {
          cargo = { allFeatures = true },
          checkOnSave = {
            command = "clippy",
          },
        },
      },
    })

    lspconfig.cssls.setup({ capabilities = capabilities })

    lspconfig.html.setup({ capabilities = capabilities })

    lspconfig.jsonls.setup({ capabilities = capabilities })

    lspconfig.tailwindcss.setup({ capabilities = capabilities })

    lspconfig.emmet_ls.setup({
      capabilities = capabilities,
      filetypes = { "html", "css", "javascript", "typescript", "javascriptreact", "typescriptreact" },
    })

    lspconfig.bashls.setup({ capabilities = capabilities })

    lspconfig.yamlls.setup({ capabilities = capabilities })

    lspconfig.dockerls.setup({ capabilities = capabilities })

    lspconfig.gopls.setup({ capabilities = capabilities })

    lspconfig.vuels.setup({ capabilities = capabilities })

    lspconfig.svelte.setup({ capabilities = capabilities })

    -- === Keymaps (buffer-local) ===
    vim.api.nvim_create_autocmd("LspAttach", {
      desc = "LSP Actions",
      callback = function(args)
        local wk = require("which-key")
        local opts = { buffer = args.buf, silent = true }
        wk.register({
          K = { vim.lsp.buf.hover, "Hover info" },
          gd = { vim.lsp.buf.definition, "Go to definition" },
          gD = { vim.lsp.buf.declaration, "Go to declaration" },
          gI = { vim.lsp.buf.implementation, "Go to implementation" },
          gr = { vim.lsp.buf.references, "List references" },
          gK = { vim.lsp.buf.signature_help, "Signature help" },
        }, opts)
      end,
    })
  end,
}
