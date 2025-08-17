return {
  "chrisgrieser/nvim-scissors",
  config = function()
    local snippet_path = vim.fn.expand("~/.config/nvim/snippets")

    local blink = require("blink.cmp")
    blink.setup({
      sources = {
        providers = {
          snippets = {
            opts = {
              search_paths = { snippet_path },
              -- auto-detects filetype from buffer, no manual ft list needed
            },
          },
        },
      },
    })

    -- reload snippets whenever you edit them
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = snippet_path .. "/*.json",
      callback = function()
        blink.setup({
          sources = {
            providers = {
              snippets = {
                opts = { search_paths = { snippet_path } },
              },
            },
          },
        })
        vim.notify("Snippets reloaded!", vim.log.levels.INFO)
      end,
    })
  end,
}
