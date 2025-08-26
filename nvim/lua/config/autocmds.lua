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

-- Show Neotree on a popup, disabling left sidebar
vim.api.nvim_exec2("Neotree reveal float", {})
vim.cmd("wincmd p") -- Switch focus to the previous window (the newly opened Neotree)
vim.cmd("wincmd p") -- Sometimes needs to be called twice depending on window layout

-- Format svelte file
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.svelte" },
  callback = function()
    local clients = vim.lsp.get_active_clients({ bufnr = 0 })
    if #clients > 0 then
      vim.lsp.buf.format()
    end
  end,
})

-- Auto save on focus lost
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

-- Insert `$` on the next line only when the current line starts with `$` (ignoring leading spaces)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "php",
  group = vim.api.nvim_create_augroup("PhpAutoDollarOnNewline", { clear = true }),
  callback = function(args)
    vim.keymap.set("i", "<CR>", function()
      local prev = vim.api.nvim_get_current_line()
      if prev:match("^%s*%$") then
        -- Let Neovim do its normal newline + indent, then insert $
        return "<CR>$"
      else
        return "<CR>"
      end
    end, { buffer = args.buf, expr = true, desc = "Auto `$` after lines that start with `$`" })
  end,
})

-- Highlight trailing whitespace
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function(args)
    vim.cmd [[match ErrorMsg /\s\+$/]]
  end,
})

-- Automatically remove trailing blank lines on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    vim.cmd [[silent! %s#\($\n\s*\)\+\%$##]]
  end,
})

-- Restore cursor position when reopening a file
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "*",
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})
