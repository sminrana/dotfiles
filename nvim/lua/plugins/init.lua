return {
  -- INFO: LSP
  -- INFO: Linter
  -- {
  --   -- Remove phpcs linter.
  --   "mfussenegger/nvim-lint",
  --   event = { "BufReadPre", "BufNewFile" },
  --   config = function()
  --     local phpcs = require("lint").linters.phpcs
  --     phpcs.args = {
  --       "-q",
  --       -- <- Add a new parameter here
  --       "--standard=PSR12",
  --       "--report=json",
  --       "-",
  --     }

  --     -- swiftlint
  --     local lint = require("lint")
  --     local pattern = "[^:]+:(%d+):(%d+): (%w+): (.+)"
  --     local groups = { "lnum", "col", "severity", "message" }
  --     local defaults = { ["source"] = "swiftlint" }
  --     local severity_map = {
  --       ["error"] = vim.diagnostic.severity.ERROR,
  --       ["warning"] = vim.diagnostic.severity.WARN,
  --     }

  --     lint.linters.swiftlint = {
  --       cmd = "swiftlint",
  --       stdin = true,
  --       args = {
  --         "lint",
  --         "--use-stdin",
  --         "--config",
  --         os.getenv("HOME") .. "/.config/nvim/.swiftlint.yml",
  --         "-",
  --       },
  --       stream = "stdout",
  --       ignore_exitcode = true,
  --       parser = require("lint.parser").from_pattern(pattern, groups, severity_map, defaults),
  --     }

  --     -- setup
  --     lint.linters_by_ft = {
  --       swift = { "swiftlint" },
  --       javascript = { "eslint_d" },
  --       typescript = { "eslint_d" },
  --       javascriptreact = { "eslint_d" },
  --       typescriptreact = { "eslint_d" },
  --       vue = { "eslint_d" },
  --       sh = { "shellcheck" },
  --       fish = { "fish" },
  --       json = { "jsonlint" },
  --       markdown = { "markdownlint" },
  --       php = { "phpcs" },
  --       css = { "stylelint" },
  --       yaml = { "yamllint" },
  --       python = { "pylint" },
  --     }

  --     local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

  --     vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave", "TextChanged" }, {
  --       group = lint_augroup,
  --       callback = function()
  --         require("lint").try_lint()
  --       end,
  --     })

  --     -- vim.keymap.set("n", "<leader>ml", function()
  --     --   require("lint").try_lint()
  --     -- end, { desc = "Lint file" })
  --   end,
  -- },
  -- INFO: Formatter
  -- {
  --   "stevearc/conform.nvim",
  --   lazy = true,
  --   event = { "BufReadPre", "BufNewFile" },
  --   opts = {
  --     formatters_by_ft = {
  --       php = { "php-cs-fixer" },
  --       lua = { "stylua" },
  --       -- Conform will run multiple formatters sequentially
  --       python = { "isort", "black" },
  --       -- You can customize some of the format options for the filetype (:help conform.format)
  --       rust = { "rustfmt", lsp_format = "fallback" },
  --       -- Conform will run the first available formatter
  --       swift = { "swiftformat_ext" },
  --       javascript = { "prettier" },
  --       typescript = { "prettier" },
  --       javascriptreact = { "prettier" },
  --       typescriptreact = { "prettier" },
  --       svelte = { "prettier" },
  --       css = { "prettier" },
  --       html = { "prettier", "htmlbeautifier" },
  --       json = { "prettier" },
  --       yaml = { "prettier" },
  --       markdown = { "prettier" },
  --       graphql = { "prettier" },
  --       sql = { "sql-formatter" },
  --     },
  --     notify_on_error = true,
  --     -- format_on_save = {
  --     --   lsp_fallback = true,
  --     --   async = false,
  --     --   timeout_ms = 1000,
  --     -- },
  --     log_level = vim.log.levels.ERROR,
  --     formatters = {
  --       ["php-cs-fixer"] = {
  --         command = "php-cs-fixer",
  --         args = {
  --           "fix",
  --           "--rules=@PSR12", -- Formatting preset. Other presets are available, see the php-cs-fixer docs.
  --           "$FILENAME",
  --         },
  --         stdin = false,
  --       },
  --       swiftformat_ext = {
  --         command = "swiftformat",
  --         args = { "--config", "~/.config/nvim/.swiftformat", "--stdinpath", "$FILENAME" },
  --         range_args = function(ctx)
  --           return {
  --             "--config",
  --             "~/.config/nvim/.swiftformat",
  --             "--linerange",
  --             ctx.range.start[1] .. "," .. ctx.range["end"][1],
  --           }
  --         end,
  --         stdin = true,
  --         condition = function(ctx)
  --           return vim.fs.basename(ctx.filename) ~= "README.md"
  --         end,
  --       },
  --     },
  --   },
  -- },
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
    "saghen/blink.cmp",
    keys = {
      {
        "<leader>fa",
        function()
          require("fzf-lua").files({
            cwd = "~/app/",
            prompt_title = "App",
          })
        end,
        desc = "Live Grep in App Files",
      },
      {
        "<leader>fw",
        function()
          require("fzf-lua").files({
            cwd = "~/web/",
            prompt_title = "Web",
          })
        end,
        desc = "Live Grep in Web Files",
      },
      {
        "<leader>fx",
        function()
          require("fzf-lua").files({
            cwd = "~/Desktop/obs-v1/",
            prompt_title = "Desktop Notes",
          })
        end,
        desc = "Live Grep in Notes Files",
      },
      {
        "<leader>fs",
        function()
          require("fzf-lua").files({
            cwd = "~/Desktop/snippets/",
            prompt_title = "q Snippets",
          })
        end,
        desc = "Live Grep in Snippets Files",
      },
      {
        "<leader>fo",
        function()
          require("fzf-lua").lines({
            grep_open_files = true,
            prompt_title = "Open Lines",
          })
        end,
        desc = "Live Grep in in Open Lines",
      },
      {
        "<leader>f.",
        require("fzf-lua").blines,
        desc = "Current Buffer Fuzzy",
      },
      {
        "<leader>ft",
        require("fzf-lua").tabs,
        desc = "Open Tabs",
      },
    },
  },
}
