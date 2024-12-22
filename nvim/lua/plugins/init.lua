return {
  -- INFO: LSP
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      { "antosha417/nvim-lsp-file-operations", config = true },
      "mason.nvim",
      { "williamboman/mason-lspconfig.nvim", config = true },
    },
    config = function()
      -- import lspconfig plugin
      local lspconfig = require("lspconfig")

      -- import cmp-nvim-lsp plugin
      local cmp_nvim_lsp = require("cmp_nvim_lsp")

      local keymap = vim.keymap

      local opts = { noremap = true, silent = true }
      local on_attach = function(client, bufnr)
        opts.buffer = bufnr

        -- set keybinding
        opts.desc = "Show LSP references"
        keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)

        opts.desc = "Go to declaration"
        keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

        opts.desc = "Show LSP definitions"
        keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)

        opts.desc = "Show LSP implementations"
        keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)

        opts.desc = "Show LSP type definitions"
        keymap.set("n", "gT", "<cmd>Telescope lsp_type_definitions<CR>", opts)

        opts.desc = "See available code actions"
        keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

        opts.desc = "Smart rename"
        keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

        opts.desc = "Show buffer diagnostics"
        keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)

        opts.desc = "Show line diagnostics"
        keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)

        opts.desc = "Go to previous diagnostic"
        keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)

        opts.desc = "Go to next diagnostic"
        keymap.set("n", "]d", vim.diagnostic.goto_next, opts)

        opts.desc = "Show documentation for what is under cursor"
        keymap.set("n", "K", vim.lsp.buf.hover, opts)

        opts.desc = "Restart LSP"
        keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)
      end

      -- used to enable autocompletion (assign to every lsp server config)
      local capabilities = cmp_nvim_lsp.default_capabilities()

      -- Change the Diagnostic symbols in the sign column (gutter)
      -- (not in youtube nvim video)
      local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
      end

      -- PHP
      lspconfig["intelephense"].setup({
        capabilities = capabilities,
        on_attach = on_attach,
        cmd = { "intelephense", "--stdio" },
        filetypes = { "php", "blade", "php_only" },
        root_pattern = { "composer.json", ".git" },
        files = {
          associations = { "*.php", "*.blade.php" }, -- Associating .blade.php files as well
          maxSize = 5000000,
        },
      })

      lspconfig["cssls"].setup({
        capabilities = capabilities,
        on_attach = on_attach,
        cmd = { "--stdio" },
        filetypes = {
          "css",
          "scss",
          "less",
        },
      })

      lspconfig["yamlls"].setup({
        capabilities = capabilities,
        on_attach = on_attach,
        cmd = { "--stdio" },
        filetypes = {
          "yaml",
          "yml",
        },
      })

      lspconfig["bashls"].setup({
        capabilities = capabilities,
        on_attach = on_attach,
        cmd = {
          "bash-language-server",
          "start",
        },
        filetypes = { "sh", "zsh" },
      })

      lspconfig["clangd"].setup({
        capabilities = capabilities,
        on_attach = on_attach,
        cmd = {
          "clangd",
        },
        filetypes = {
          "c",
          "cpp",
          "objc",
          "objcpp",
          "cuda",
          "proto",
        },
      })

      lspconfig["pyright"].setup({
        capabilities = capabilities,
        on_attach = on_attach,
        cmd = { "pyright-langserver", "--stdio" },
        handlers = {
          ["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
            virtual_text = true, -- Move this function to make it accessible by all languages
            signs = true,
            underline = true,
            update_in_insert = true,
          }),
        },
      })

      lspconfig["ts_ls"].setup({
        capabilities = capabilities,
        on_attach = on_attach,
        filetypes = {
          "javascript",
          "javascriptreact",
          "javascript.jsx",
          "typescript",
          "typescriptreact",
          "typescript.tsx",
          "vue",
          "svelte",
          "astro",
        },
        settings = {
          complete_function_calls = true,
          vtsls = {
            enableMoveToFileCodeAction = true,
            autoUseWorkspaceTsdk = true,
            experimental = {
              completion = {
                enableServerSideFuzzyMatch = true,
              },
            },
          },
          typescript = {
            updateImportsOnFileMove = { enabled = "always" },
            suggest = {
              completeFunctionCalls = true,
            },
            inlayHints = {
              enumMemberValues = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              parameterNames = { enabled = "literals" },
              parameterTypes = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
              variableTypes = { enabled = false },
            },
          },
          codeAction = {
            disableRuleComment = {
              enable = true,
              location = "separateLine",
            },
            showDocumentation = {
              enable = true,
            },
          },
          codeActionOnSave = {
            enable = false,
            mode = "all",
          },
          experimental = {
            useFlatConfig = false,
          },
          format = true,
          nodePath = "",
          onIgnoredFiles = "off",
          problems = {
            shortenToSingleLine = false,
          },
          quiet = false,
          rulesCustomizations = {},
          run = "onType",
          useESLintClass = false,
          validate = "on",
          workingDirectory = {
            mode = "location",
          },
        },
      })

      -- HTML
      lspconfig["html"].setup({
        capabilities = capabilities,
        on_attach = on_attach,
        cmd = { "--stdio" },
        filetypes = {
          "html",
        },
        configurationSection = { "html", "css", "javascript" },
        embeddedLanguages = {
          css = true,
          javascript = true,
        },
        provideFormatter = true,
      })

      -- Swift
      lspconfig["sourcekit"].setup({
        capabilities = capabilities,
        on_attach = on_attach,
        cmd = {
          "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
        },
        root_dir = function(filename, _)
          local util = require("lspconfig.util")
          return util.root_pattern("buildServer.json")(filename)
            or util.root_pattern("*.xcodeproj", "*.xcworkspace")(filename)
            or util.find_git_ancestor(filename)
            or util.root_pattern("Package.swift")(filename)
        end,
      })

      -- configure lua server (with special settings)
      lspconfig["lua_ls"].setup({
        capabilities = capabilities,
        on_attach = on_attach,
        settings = { -- custom settings for lua
          Lua = {
            -- make the language server recognize "vim" global
            diagnostics = {
              globals = { "vim" },
            },
            workspace = {
              -- make language server aware of runtime files
              library = {
                [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                [vim.fn.stdpath("config") .. "/lua"] = true,
              },
            },
          },
        },
      })
    end,
  },
  -- INFO: Linter
  {
    -- Remove phpcs linter.
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local phpcs = require("lint").linters.phpcs
      phpcs.args = {
        "-q",
        -- <- Add a new parameter here
        "--standard=PSR12",
        "--report=json",
        "-",
      }

      -- swiftlint
      local lint = require("lint")
      local pattern = "[^:]+:(%d+):(%d+): (%w+): (.+)"
      local groups = { "lnum", "col", "severity", "message" }
      local defaults = { ["source"] = "swiftlint" }
      local severity_map = {
        ["error"] = vim.diagnostic.severity.ERROR,
        ["warning"] = vim.diagnostic.severity.WARN,
      }

      lint.linters.swiftlint = {
        cmd = "swiftlint",
        stdin = true,
        args = {
          "lint",
          "--use-stdin",
          "--config",
          os.getenv("HOME") .. "/.config/nvim/.swiftlint.yml",
          "-",
        },
        stream = "stdout",
        ignore_exitcode = true,
        parser = require("lint.parser").from_pattern(pattern, groups, severity_map, defaults),
      }

      -- setup
      lint.linters_by_ft = {
        swift = { "swiftlint" },
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        vue = { "eslint_d" },
        sh = { "shellcheck" },
        fish = { "fish" },
        json = { "jsonlint" },
        markdown = { "markdownlint" },
        php = { "phpcs" },
        css = { "stylelint" },
        yaml = { "yamllint" },
        python = { "pylint" },
      }

      local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave", "TextChanged" }, {
        group = lint_augroup,
        callback = function()
          require("lint").try_lint()
        end,
      })

      -- vim.keymap.set("n", "<leader>ml", function()
      --   require("lint").try_lint()
      -- end, { desc = "Lint file" })
    end,
  },
  -- INFO: Formatter
  {
    "stevearc/conform.nvim",
    lazy = true,
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      formatters_by_ft = {
        php = { "php-cs-fixer" },
        lua = { "stylua" },
        -- Conform will run multiple formatters sequentially
        python = { "isort", "black" },
        -- You can customize some of the format options for the filetype (:help conform.format)
        rust = { "rustfmt", lsp_format = "fallback" },
        -- Conform will run the first available formatter
        swift = { "swiftformat_ext" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        svelte = { "prettier" },
        css = { "prettier" },
        html = { "prettier", "htmlbeautifier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        graphql = { "prettier" },
        sql = { "sql-formatter" },
      },
      notify_on_error = true,
      -- format_on_save = {
      --   lsp_fallback = true,
      --   async = false,
      --   timeout_ms = 1000,
      -- },
      log_level = vim.log.levels.ERROR,
      formatters = {
        ["php-cs-fixer"] = {
          command = "php-cs-fixer",
          args = {
            "fix",
            "--rules=@PSR12", -- Formatting preset. Other presets are available, see the php-cs-fixer docs.
            "$FILENAME",
          },
          stdin = false,
        },
        swiftformat_ext = {
          command = "swiftformat",
          args = { "--config", "~/.config/nvim/.swiftformat", "--stdinpath", "$FILENAME" },
          range_args = function(ctx)
            return {
              "--config",
              "~/.config/nvim/.swiftformat",
              "--linerange",
              ctx.range.start[1] .. "," .. ctx.range["end"][1],
            }
          end,
          stdin = true,
          condition = function(ctx)
            return vim.fs.basename(ctx.filename) ~= "README.md"
          end,
        },
      },
    },
  },
  {
    "mbbill/undotree",
  },
  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
  },
  {
    "nvim-neotest/neotest",
    dependencies = { "olimorris/neotest-phpunit" },
    opts = { adapters = { "neotest-phpunit" } },
  },

  {
    "epwalsh/obsidian.nvim",
    version = "*", -- recommended, use latest release instead of latest commit
    lazy = true,
    ft = "markdown",
    -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
    -- event = {
    --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
    --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
    --   -- refer to `:h file-pattern` for more examples
    --   "BufReadPre path/to/my-vault/*.md",
    --   "BufNewFile path/to/my-vault/*.md",
    -- },
    dependencies = {
      -- Required.
      "nvim-lua/plenary.nvim",
      -- see below for full list of optional dependencies 👇
    },
    opts = {
      workspaces = {
        {
          name = "work",
          path = "~/Desktop/obs-v1/",
        },
      },
    },
  },
  {
    -- Add the Laravel.nvim plugin which gives the ability to run Artisan commands
    -- from Neovim.
    "adalessa/laravel.nvim",
    version = "2.2.1",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "tpope/vim-dotenv",
      "MunifTanjim/nui.nvim",
    },
    cmd = { "Sail", "Artisan", "Composer", "Npm", "Yarn", "Laravel" },

    --   { "<leader>la", ":Laravel artisan<cr>" },
    --   { "<leader>lr", ":Laravel routes<cr>" },
    --   { "<leader>lm", ":Laravel related<cr>" },
    -- },
    event = { "VeryLazy" },
    config = true,
    opts = {
      lsp_server = "intelephense",
      features = { null_ls = { enable = false } },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = function()
      require("nvim-treesitter.install").update({ with_sync = true })
    end,
    dependencies = {
      {
        "JoosepAlviste/nvim-ts-context-commentstring",
        opts = {
          custom_calculation = function(_, language_tree)
            if vim.bo.filetype == "blade" and language_tree._lang ~= "javascript" and language_tree._lang ~= "php" then
              return "{{-- %s --}}"
            end
          end,
        },
      },
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    opts = {
      ensure_installed = {
        "php",
      },
      auto_install = true,
      highlight = {
        enable = true,
      },
      -- Needed because treesitter highlight turns off autoindent for php files
      indent = {
        enable = true,
      },
    },
    config = function(_, opts)
      ---@class ParserInfo[]
      local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
      parser_config.blade = {
        install_info = {
          url = "https://github.com/EmranMR/tree-sitter-blade",
          files = {
            "src/parser.c",
            -- 'src/scanner.cc',
          },
          branch = "main",
          generate_requires_npm = true,
          requires_generate_from_grammar = true,
        },
        filetype = "blade",
      }

      require("nvim-treesitter.configs").setup(opts)
    end,
  },
  -- {
  --   "catppuccin/nvim",
  --   name = "catppuccin",
  --   priority = 1000,
  --   {
  --     "LazyVim/LazyVim",
  --     opts = {
  --       colorscheme = "catppuccin",
  --       style = "mocha",
  --       styles = {
  --         sidebars = "transparent",
  --         floats = "transparent",
  --       },
  --     },
  --   },
  -- },
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      colorscheme = "tokyonight",
      style = "night",
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },
  {
    "wojciech-kulik/xcodebuild.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-tree.lua", -- (optional) to manage project files
      "stevearc/oil.nvim", -- (optional) to manage project files
      "nvim-treesitter/nvim-treesitter", -- (optional) for Quick tests support (required Swift parser)
    },
    config = function()
      require("xcodebuild").setup({
        -- put some options here or leave it empty to use default settings
      })
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<leader>fa",
        function()
          require("telescope.builtin").live_grep({
            cwd = "~/app/",
            prompt_title = "App",
          })
        end,
        desc = "Live Grep in App Files",
      },
      {
        "<leader>fw",
        function()
          require("telescope.builtin").live_grep({
            cwd = "~/web/",
            prompt_title = "Web",
          })
        end,
        desc = "Live Grep in Web Files",
      },
      {
        "<leader>fx",
        function()
          require("telescope.builtin").live_grep({
            cwd = "~/Desktop/obs-v1/",
            prompt_title = "Desktop Notes",
          })
        end,
        desc = "Live Grep in Notes Files",
      },
      {
        "<leader>fs",
        function()
          require("telescope.builtin").live_grep({
            cwd = "~/Desktop/snippets/",
            prompt_title = "Code Snippets",
          })
        end,
        desc = "Live Grep in Snippets Files",
      },
      {
        "<leader>fo",
        function()
          require("telescope.builtin").live_grep({
            grep_open_files = true,
            prompt_title = "Open Files",
          })
        end,
        desc = "Live Grep in in Open Files",
      },
      {
        "<leader>/",
        require("telescope.builtin").current_buffer_fuzzy_find,
        desc = "Current Buffer Fuzzy",
      },
      {
        "<leader>.",
        require("telescope.builtin").live_grep,
        desc = "Live Grep (Root dir)",
      },
    },
  },
  {
    "L3MON4D3/LuaSnip",
    -- follow latest release.
    version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
    dependencies = { "rafamadriz/friendly-snippets" },
  },
  {
    "voldikss/vim-floaterm",
  },
  -- {
  --   "yetone/avante.nvim",
  --   event = "VeryLazy",
  --   lazy = false,
  --   version = false, -- set this if you want to always pull the latest change
  --   -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  --   build = "make",
  --   -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
  --   dependencies = {
  --     "stevearc/dressing.nvim",
  --     "nvim-lua/plenary.nvim",
  --     "MunifTanjim/nui.nvim",
  --     --- The below dependencies are optional,
  --     "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
  --     "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
  --     {
  --       -- Make sure to set this up properly if you have lazy=true
  --       "MeanderingProgrammer/render-markdown.nvim",
  --       opts = {
  --         file_types = { "markdown", "Avante" },
  --       },
  --       ft = { "markdown", "Avante" },
  --     },
  --   },
  --   opts = {
  --     -- add any opts here
  --     provider = "openai",
  --     -- openai = {
  --     --   endpoint = "https://api.openai.com/v1",
  --     --   model = "gpt-3.5-turbo",
  --     --   timeout = 30000, -- Timeout in milliseconds
  --     --   temperature = 0,
  --     --   max_tokens = 4096,
  --     -- },
  --   },
  --
  -- },
}
