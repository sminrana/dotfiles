return {
  "nvimtools/none-ls.nvim",
  opts = function(_, opts)
    local null_ls = require("null-ls")

    opts.sources = vim.list_extend(opts.sources or {}, {

      null_ls.builtins.formatting.phpcsfixer.with({
        command = "php-cs-fixer",
        extra_args = { "fix", "--using-cache=no" },
        filetypes = { "php" },
      }),

      -- Prettier for blade and html with 4 spaces
      null_ls.builtins.formatting.blade_formatter.with({
        filetypes = {
          "blade",
        },
        extra_args = {
          "--single-quote",
          "true",
          "--trailing-comma",
          "all",
          "--print-width",
          "100",
          "--tab-width",
          "4",
        },
      }),
      null_ls.builtins.formatting.prettier.with({
        filetypes = {
          "blade",
          "html",
        },
        extra_args = {
          "--single-quote",
          "true",
          "--trailing-comma",
          "all",
          "--print-width",
          "100",
          "--tab-width",
          "4",
        },
      }),

      -- Prettier for other files with 2 spaces
      null_ls.builtins.formatting.prettier.with({
        filetypes = {
          "css",
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
          "json",
          "yaml",
          "svelte",
        },
        extra_args = {
          "--single-quote",
          "true",
          "--trailing-comma",
          "all",
          "--print-width",
          "100",
          "--tab-width",
          "2",
        },
      }),

      null_ls.builtins.formatting.ktlint.with({
        filetypes = { "kotlin", "java" },
      }),

      null_ls.builtins.formatting.swiftformat.with({
        command = "swiftformat", -- Ensure swiftformat is installed on your system
        filetypes = { "swift" },
        extra_args = { "--indent", "4" }, -- 4 spaces per indent, Swift default
      }),
    })

    null_ls.builtins.formatting.black.with({
      filetypes = { "python" },
      extra_args = {
        "--line-length",
        "88", -- default is 88, can change to 79, 100, 120, etc.
        "--skip-string-normalization", -- keeps your quote style
        "--target-version",
        "py39", -- specify Python version
      },
    })

    null_ls.builtins.formatting.isort.with({
      filetypes = { "python" },
      extra_args = {
        "--profile",
        "black", -- compatible with black
        "--line-length",
        "88",
        "--multi-line",
        "3",
      },
    })

    -- Python diagnostics/linting
    -- null_ls.builtins.diagnostics.flake8.with({
    --   filetypes = { "python" },
    --   extra_args = {
    --     "--max-line-length", "88",
    --     "--extend-ignore", "E203,W503",  -- ignore conflicts with black
    --   },
    -- })

    -- Autoformat on save
    opts.on_attach = function(client, bufnr)
      if client.supports_method("textDocument/formatting") then
        vim.api.nvim_create_autocmd("BufWritePre", {
          buffer = bufnr,
          callback = function()
            vim.lsp.buf.format({
              async = false,
              filter = function(fmt_client)
                return fmt_client.name == "null-ls"
              end,
            })
          end,
        })
      end
    end
  end,
}
