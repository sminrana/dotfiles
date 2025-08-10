-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Make BG tran
-- vim.api.nvim_create_augroup("nobg", { clear = true })
-- vim.api.nvim_create_autocmd({ "ColorScheme" }, {
--   desc = "Make all backgrounds transparent",
--   group = "nobg",
--   pattern = "*",
--   callback = function()
--     vim.api.nvim_set_hl(0, "Normal", { bg = "NONE", ctermbg = "NONE" })
--     vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "NONE", ctermbg = "NONE" })
--     vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "NONE", ctermbg = "NONE" })
--   end,
-- })
--
--
vim.api.nvim_create_autocmd("DirChanged", {
  callback = function()
    local cwd = vim.fn.getcwd()
    local hostname = vim.fn.hostname()
    os.execute('printf "\\033]7;file://' .. hostname .. cwd .. '\\033\\\\"')
  end,
})

vim.api.nvim_exec2("Neotree reveal float", {})
vim.cmd("wincmd p") -- Switch focus to the previous window (the newly opened Neotree)
vim.cmd("wincmd p") -- Sometimes needs to be called twice depending on window layout

-- vim.api.nvim_create_autocmd("BufWritePost", {
--   pattern = "*.md",
--   callback = function(args)
--     local src = args.file
--     local dest = os.getenv("HOME") .. "/Library/CloudStorage/Dropbox/Vault/" .. vim.fn.fnamemodify(src, ":t")
--     vim.fn.jobstart({ "cp", src, dest }, {
--       detach = true,
--       on_exit = function(_, code)
--         if code == 0 then
--           vim.schedule(function()
--             vim.notify("Copied to Dropbox Vault: " .. dest, vim.log.levels.INFO)
--           end)
--         else
--           vim.schedule(function()
--             vim.notify("Failed to copy to Dropbox Vault", vim.log.levels.ERROR)
--           end)
--         end
--       end,
--     })
--   end,
-- })


vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.svelte" },
  callback = function()
    local clients = vim.lsp.get_active_clients({ bufnr = 0 })
    if #clients > 0 then
      vim.lsp.buf.format()
    end
  end,
})


vim.api.nvim_create_autocmd("FocusLost", {
  pattern = "*",
  command = "silent! wa"
})

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    local save = vim.fn.winsaveview()
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
})