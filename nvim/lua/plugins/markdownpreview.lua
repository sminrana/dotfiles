return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  build = "cd app && yarn install",
  init = function()
    vim.g.mkdp_filetypes = { "markdown" }
  end,
  ft = { "markdown" },
  keys = {
    {
      "<leader>jm1",
      "<cmd>MarkdownPreviewToggle<cr>",
      desc = "Markdown Preview Toggle",
      ft = "markdown",
    },
  },
}
