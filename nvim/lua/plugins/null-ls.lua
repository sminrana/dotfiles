return {
  "nvimtools/none-ls.nvim",
  opts = function(_, opts)
    local null_ls = require("null-ls")

    opts.sources = {

      -- PHP
      null_ls.builtins.formatting.phpcsfixer.with({
        command = "/Users/smin/.local/bin/php-cs-fixer",
        extra_args = function()
          return {
            "--config=" .. vim.fn.getcwd() .. "/.php-cs-fixer.php",
            "--using-cache=no",
          }
        end,
      }),

      null_ls.builtins.formatting.pint.with({
        prefer_local = "/Users/smin/.composer/vendor/bin/pint",
        extra_args = { "--quiet" },
      }),

      -- Blade (4 spaces)
      null_ls.builtins.formatting.blade_formatter.with({
        extra_args = { "--indent-size", "4" },
      }),

      -- HTML (4 spaces)
      null_ls.builtins.formatting.prettier.with({
        filetypes = { "html" },
        extra_args = {
          "--tab-width",
          "4",
          "--print-width",
          "100",
          "--single-quote",
          "true",
          "--trailing-comma",
          "all",
        },
      }),

      -- JS/TS/CSS/etc (2 spaces)
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
          "vue",
        },
        extra_args = {
          "--tab-width",
          "2",
          "--print-width",
          "100",
          "--single-quote",
          "true",
          "--trailing-comma",
          "all",
        },
      }),

      -- Kotlin
      null_ls.builtins.formatting.ktlint,

      -- Swift
      null_ls.builtins.formatting.swiftformat.with({
        extra_args = { "--indent", "4" },
      }),

      -- Python
      null_ls.builtins.formatting.black.with({
        extra_args = {
          "--line-length",
          "88",
          "--skip-string-normalization",
          "--target-version",
          "py39",
        },
      }),

      null_ls.builtins.formatting.isort.with({
        extra_args = {
          "--profile",
          "black",
          "--line-length",
          "88",
        },
      }),
    }

    -- Format on save
    opts.on_attach = function(client, bufnr)
      if client.supports_method("textDocument/formatting") then
        vim.api.nvim_create_autocmd("BufWritePre", {
          buffer = bufnr,
          callback = function()
            vim.lsp.buf.format({
              async = false,
              filter = function(c)
                return c.name == "null-ls"
              end,
            })
          end,
        })
      end
    end
  end,
}
