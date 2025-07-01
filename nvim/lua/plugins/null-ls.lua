return {
    "nvimtools/none-ls.nvim",
    opts = function(_, opts)
        local null_ls = require("null-ls")
        table.insert(opts.sources, null_ls.builtins.formatting.prettier.with({
            filetypes = { "blade" },
            command = "npx",
            args = { "prettier", "--stdin-filepath", "$FILENAME" },
        }))
    end,
}