return {
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

    -- Diagnostics and UI tweaks
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
    capabilities.textDocument.foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true,
    }
    capabilities.textDocument.completion.completionItem.snippetSupport = true
    capabilities.textDocument.completion.completionItem.resolveSupport = {
      properties = { "documentation", "detail", "additionalTextEdits" },
    }

    -- on_attach: lightweight enhancements per buffer
    local function on_attach(client, bufnr)
      if client.server_capabilities.inlayHintProvider then
        local ih = vim.lsp.inlay_hint
        if type(ih) == "function" then
          pcall(ih, bufnr, true)
        elseif type(ih) == "table" and ih.enable then
          pcall(ih.enable, bufnr, true)
        end
      end
    end

    -- Server configurations
    local servers = {
      -- React Native / JS / TS
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
          -- detect React Native project roots more flexibly
          return util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git")(fname)
            or util.root_pattern("app.json", "index.js", "index.tsx")(fname)
            or vim.fn.getcwd()
        end,
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
      },

      -- Python / Django
      pyright = {
        cmd = { "pyright-langserver", "--stdio" },
        filetypes = { "python" },
        root_dir = util.root_pattern("manage.py", "pyproject.toml", "setup.py", ".git"),
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
      },

      -- Swift (SourceKit-LSP)
      sourcekit = {
        cmd = { "xcrun", "sourcekit-lsp" },
        filetypes = { "swift", "objective-c", "objective-cpp" },
        root_dir = util.root_pattern("Package.swift", ".git"),
      },

      -- Other servers
      clangd = {},
      lua_ls = {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { library = vim.api.nvim_get_runtime_file("", true), checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      },
      phpactor = {},
      rust_analyzer = {
        settings = {
          ["rust-analyzer"] = {
            cargo = { allFeatures = true },
            checkOnSave = {
              command = "clippy",
            },
          },
        },
      },
      cssls = {},
      html = {},
      jsonls = {},
      tailwindcss = {},
      emmet_ls = {
        filetypes = { "html", "css", "javascript", "typescript", "javascriptreact", "typescriptreact" },
      },
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

    -- Keymaps (buffer-local)
    local lsp_keymaps_grp = vim.api.nvim_create_augroup("LspKeymaps", { clear = true })
    vim.api.nvim_create_autocmd("LspAttach", {
      desc = "LSP Actions",
      group = lsp_keymaps_grp,
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
        n("gS", function()
          require("fzf-lua").lsp_document_symbols()
        end, "List document symbols (fzf)")
         n("gW", function()
          require("fzf-lua").lsp_workspace_symbols()
        end, "List workspace symbols (fzf)")
        n("gL", function()
          require("fzf-lua").lsp_live_workspace_symbols()
        end, "List live workspace symbols (fzf)")
         n("gA", function()
          require("fzf-lua").lsp_code_actions()
        end, "List code actions (fzf)")
      end,
      
    })
  end,
}
