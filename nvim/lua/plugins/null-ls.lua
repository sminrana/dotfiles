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

      null_ls.builtins.formatting.black.with({
        filetypes = { "python" },
        extra_args = { "--line-length", "88" }, -- 88 is black's default, change if needed
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
