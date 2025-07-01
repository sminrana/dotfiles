return {
  "chrisgrieser/nvim-scissors",
  config = function()
    local scissors = require("blink.cmp")
    scissors.setup({
      sources = {
        providers = {
          snippets = {
            opts = {
              search_paths = { "/Users/smin/.config/nvim/snippets" },
              filetypes = { "blade", "php", "html", "tsx", "ts", "ct", "javascript", "python" },
            },
          },
        },
      },
    })

    local snippet_path = vim.fn.expand("/Users/smin/.config/nvim/snippets")
    local reload_snippets = function()
      scissors.setup({
        sources = {
          providers = {
            snippets = {
              opts = {
                search_paths = { snippet_path },
                filetypes = { "blade", "php", "html", "tsx", "ts", "ct", "javascript", "python" },
              },
            },
          },
        },
      })
      vim.notify("Snippets reloaded!", vim.log.levels.INFO)
    end

    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = snippet_path .. "/*.json",
      callback = reload_snippets,
    })
  end,
}