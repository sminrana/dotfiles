return {
   "ellisonleao/gruvbox.nvim",
    config = function(_, opts)
        vim.opt.background = "dark"
        vim.cmd [[colorscheme gruvbox]]
    end,
}
