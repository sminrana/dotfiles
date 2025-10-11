return {
  "nvimtools/none-ls.nvim",
  opts = function(_, opts)
    local null_ls = require("null-ls")
    opts.sources = vim.list_extend(opts.sources or {}, {
      -- 🐘 PHP formatter
      null_ls.builtins.formatting.phpcsfixer.with({
        command = "php-cs-fixer",
        extra_args = { "fix", "--using-cache=no" },
        filetypes = { "php" },
      }),

      -- 💅 Prettier for React Native, HTML, CSS, etc.
      null_ls.builtins.formatting.prettier.with({
        filetypes = {
          "blade",
          "html",
          "css",
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
          "json",
          "yaml",
          "markdown",
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
    })

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
