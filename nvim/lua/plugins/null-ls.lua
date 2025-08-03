return {
  "nvimtools/none-ls.nvim",
  opts = function(_, opts)
    local null_ls = require("null-ls")
    opts.sources = vim.list_extend(opts.sources or {}, {
      -- Formatting with phpcsfixer
      -- null_ls.builtins.formatting.phpcsfixer.with({
      --   command = "php-cs-fixer",
      --   extra_args = { "fix", "--using-cache=no" },
      -- }),
      --
      null_ls.builtins.diagnostics.phpstan.with({
        command = "phpstan",
        args = { "analyze", "--error-format", "raw", "$FILENAME" },
        method = null_ls.methods.DIAGNOSTICS_ON_SAVE,
      }),

      null_ls.builtins.formatting.prettier.with({
        filetypes = { "blade" },
        command = "npx",
        args = { "prettier", "--stdin-filepath", "$FILENAME" },
      }),
    })
  end,
}
