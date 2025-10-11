return {
  {
    -- ---------- LSP Servers ----------
    "neovim/nvim-lspconfig",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "LspInfo", "LspInstall", "LspUninstall", "LspStart", "LspStop", "LspRestart" },
    dependencies = {
      { "mason-org/mason.nvim", build = ":MasonUpdate" },
      "mason-org/mason-lspconfig.nvim",
    },
    config = function()
      local lspconfig = require("lspconfig")
      local util = require("lspconfig.util")

      -- === Shared capabilities ===
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities.textDocument.foldingRange = { dynamicRegistration = false, lineFoldingOnly = true }
      capabilities.textDocument.completion.completionItem.snippetSupport = true
      capabilities.textDocument.completion.completionItem.resolveSupport = {
        properties = { "documentation", "detail", "additionalTextEdits" },
      }

      -- === Diagnostics & UI ===
      vim.diagnostic.config({
        virtual_text = false,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = { border = "rounded", source = "always" },
      })
      local borders = { border = "rounded" }
      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, borders)
      vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, borders)

      -- === Common on_attach ===
      local function on_attach(client, bufnr)
        -- Inlay hints if supported
        if client.server_capabilities.inlayHintProvider then
          local ih = vim.lsp.inlay_hint
          if type(ih) == "function" then
            pcall(ih, bufnr, true)
          elseif type(ih) == "table" and ih.enable then
            pcall(ih.enable, bufnr, true)
          end
        end
      end

      -- === Server configurations ===
      local servers = {
        -- 🧩 React Native / JS / TS
        ts_ls = {
          cmd = { "typescript-language-server", "--stdio" },
          filetypes = {
            "javascript",
            "javascriptreact",
            "typescript",
            "typescriptreact",
            "json",
          },
          root_dir = function(fname)
            return util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git")(fname)
              or util.root_pattern("app.json", "index.js", "index.tsx")(fname)
              or vim.fn.getcwd()
          end,
          settings = {
            typescript = {
              preferences = { importModuleSpecifier = "non-relative" },
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayVariableTypeHints = true,
              },
            },
          },
        },

        -- 🐍 Python / Django
        pyright = {
          cmd = { "pyright-langserver", "--stdio" },
          filetypes = { "python" },
          root_dir = util.root_pattern("manage.py", "pyproject.toml", "setup.py", ".git"),
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "basic",
                useLibraryCodeForTypes = true,
              },
            },
          },
        },

        -- 🐘 PHP
        phpactor = {
          cmd = { "phpactor", "language-server" },
          filetypes = { "php" },
          root_dir = util.root_pattern("composer.json", ".git", ".phpactor.json"),
          init_options = {
            ["language_server_phpstan.enabled"] = false,
            ["language_server_psalm.enabled"] = false,
          },
        },

        -- 🦀 Rust
        rust_analyzer = {
          settings = {
            ["rust-analyzer"] = {
              cargo = { allFeatures = true },
              checkOnSave = { command = "clippy" },
            },
          },
        },

        -- 🧠 Others
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = { globals = { "vim" } },
              workspace = { checkThirdParty = false },
              telemetry = { enable = false },
            },
          },
        },
        sourcekit = {
          cmd = { "xcrun", "sourcekit-lsp" },
          filetypes = { "swift", "objective-c", "objective-cpp" },
          root_dir = util.root_pattern("Package.swift", ".git"),
        },
        cssls = {},
        html = {},
        jsonls = {},
        tailwindcss = {},
        emmet_ls = {},
        bashls = {},
        yamlls = {},
        dockerls = {},
        gopls = {},
        vuels = {},
        svelte = {},
      }

      -- Setup all servers
      for server, config in pairs(servers) do
        config = vim.tbl_deep_extend("force", {
          capabilities = capabilities,
          on_attach = on_attach,
        }, config)
        lspconfig[server].setup(config)
      end

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
  },
}
