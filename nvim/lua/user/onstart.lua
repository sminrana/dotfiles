vim.api.nvim_create_autocmd("VimEnter", {
  desc = "Backup data on start (async)",
  callback = function()
    if vim.fn.argc() == 0 then
      vim.cmd("Neotree float")
    end
  end,
})
