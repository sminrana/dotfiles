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
        jdtls = {},
        kotlin_language_server = {},
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
          local buf = args.buf
          local function n(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = buf, silent = true, noremap = true, desc = desc })
          end
          n("K", vim.lsp.buf.hover, "Hover info")
          n("gd", vim.lsp.buf.definition, "Go to definition")
          n("gD", vim.lsp.buf.declaration, "Go to declaration")
          n("gI", vim.lsp.buf.implementation, "Go to implementation")
          n("gR", function()
            require("fzf-lua").lsp_references({ jump_to_single_result = true })
          end, "List references (fzf)")
          n("gK", vim.lsp.buf.signature_help, "Signature help")
          n("gA", function()
            require("fzf-lua").lsp_code_actions()
          end, "List code actions (fzf)")
        end,
      })
    end,
  },
}
