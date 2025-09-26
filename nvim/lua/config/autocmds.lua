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

-- Insert '- [ ] ' on the next line in markdown if the current line starts with '- [ ]'
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  group = vim.api.nvim_create_augroup("MarkdownAutoCheckbox", { clear = true }),
  callback = function(args)
    vim.keymap.set("i", "<CR>", function()
      local prev = vim.api.nvim_get_current_line()
      local indent, box = prev:match("^(%s*)(%- %[ %])")
      if indent and box then
        -- Insert newline, indent, and '- [ ] ', then place cursor after the space
        return "<CR>" .. indent .. "- [ ] "
      else
        return "<CR>"
      end
    end, { buffer = args.buf, expr = true, desc = "Auto '- [ ] ' after lines that start with '- [ ]'" })
  end,
})

-- Highlight trailing whitespace
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "php", "typescriptreact", "lua", "python", "javascript", "typescript" },
  callback = function(args)
    vim.cmd([[match ErrorMsg /\s\+$/]])
  end,
})

-- Automatically remove trailing blank lines on save
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function()
    if vim.fn.line("$") < 2500 then
      vim.cmd([[silent! %s#\($\n\s*\)\+\%$##]])
    end
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

vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function()
    local lastline = vim.fn.getline("$")
    if lastline == "" then
      vim.cmd([[%s/\%$/\r/e]])
    end
  end,
})

-- Auto-assign <leader>1..9 to listed buffers
local function setup_buffer_mappings()
  -- Clear old mappings
  for i = 1, 9 do
    pcall(vim.keymap.del, "n", "<leader>" .. i)
  end

  -- Get all listed buffers
  local bufs = vim.fn.getbufinfo({ buflisted = 1 })

  for i, buf in ipairs(bufs) do
    if i <= 9 then
      local id = buf.bufnr
      local name = vim.fn.fnamemodify(buf.name, ":t")

      vim.keymap.set("n", "<leader>" .. i, function()
        vim.cmd("buffer " .. id)
      end, {
        desc = "Go " .. id .. (name ~= "" and (": " .. name) or ""),
      })
    end
  end
end

-- Listen to both BufAdd and BufDelete
vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
  callback = setup_buffer_mappings,
})
