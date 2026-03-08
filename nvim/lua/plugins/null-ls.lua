return {
  "nvimtools/none-ls.nvim",
  opts = function(_, opts)
    local nls = require("null-ls")

    opts.sources = {

      -- PHP
      nls.builtins.formatting.phpcsfixer.with({
        extra_args = { "--config=.php-cs-fixer.php", "--using-cache=no" },
      }),

      nls.builtins.formatting.pint.with({
        prefer_local = "vendor/bin",
        extra_args = { "--quiet" },
      }),

      -- Blade
      nls.builtins.formatting.blade_formatter.with({
        extra_args = { "--indent-size", "4" },
      }),

      -- Prettier
      nls.builtins.formatting.prettier.with({
        filetypes = {
          "html",
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
          "--print-width", "100",
          "--single-quote", "true",
          "--trailing-comma", "all",
        },
      }),

      -- Swift
      nls.builtins.formatting.swiftformat.with({
        extra_args = { "--indent", "4" },
      }),

      -- Python
      nls.builtins.formatting.black,
    }
  end,
}
