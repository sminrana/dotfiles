local function backup_helium_async()
  local home = os.getenv("HOME")
  local dest_dir = home .. "/Desktop/helium"
  local archive_path = dest_dir .. "/helium.tar.gz"

  if vim.fn.isdirectory(dest_dir) == 0 then
    vim.fn.mkdir(dest_dir, "p")
  end

  -- Use tar to avoid socket errors and run in background
  -- -C switches to the parent directory so we archive the folder name properly
  local src_parent = home .. "/Library/Application Support/net.imput.helium"
  local src_basename = "Default"
  local cmd = string.format("tar -czf %q -C %q %q", archive_path, src_parent, src_basename)

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_exit = function(_, code)
      if code == 0 then
        vim.notify("Helium backup created: " .. archive_path, vim.log.levels.INFO)
      else
        -- Read any stderr output for context
        vim.notify("Helium backup failed (tar exit " .. tostring(code) .. ")", vim.log.levels.ERROR)
      end
    end,
  })
end

-- Run on Neovim startup
vim.api.nvim_create_autocmd("VimEnter", {
  desc = "Backup Helium data on start (async)",
  callback = function()
    local ok, err = pcall(backup_helium_async)
    if not ok then
      vim.notify("Helium backup error: " .. tostring(err), vim.log.levels.ERROR)
    end
  end,
})
