return {
  "chrisgrieser/nvim-scissors",
  config = function()
    local ft  = { "blade", "php", "html", "tsx", "ts", "ct", "javascript", "python", "svelte" }
    local snippet_path = vim.fn.expand("/Users/smin/.config/nvim/snippets")

    local scissors = require("blink.cmp")
    scissors.setup({
      sources = {
        providers = {
          snippets = {
            opts = {
              search_paths = { snippet_path },
              filetypes = ft,
            },
          },
        },
      },
    })


    local reload_snippets = function()
      scissors.setup({
        sources = {
          providers = {
            snippets = {
              opts = {
                search_paths = { snippet_path },
                filetypes = ft,
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