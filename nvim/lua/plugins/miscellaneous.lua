return {
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
        "<leader>fl",
        function()
          require("fzf-lua").lines({
            grep_open_files = true,
            prompt_title = "Open Lines",
          })
        end,
        desc = "Live Grep in in Open Lines",
      },
      {
        "<leader>a",
        require("fzf-lua").blines,
        desc = "Current Buffer Fuzzy",
      },
    },
  },
}
