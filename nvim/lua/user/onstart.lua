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
        vim.notify("Helium backup failed (tar exit " .. tostring(code) .. ")", vim.log.levels.ERROR)
      end
    end,
  })
end

local function purge_downloads_async(days)
  days = tonumber(days) or 15
  local home = os.getenv("HOME")
  local downloads = home .. "/Downloads"
  if vim.fn.isdirectory(downloads) == 0 then
    return
  end

  -- Move files and directories older than N days to Trash local trash = home .. "/.Trash"
  if vim.fn.isdirectory(trash) == 0 then
    vim.fn.mkdir(trash, "p")
  end

  -- We find files and directories (non-empty too) and move them to ~/.Trash
  -- Use -print to capture moved paths for summary
  local moved = {}

  -- Use argv-based jobstart to avoid shell escaping issues, and exclude screenshots folder variants
  local mtime = "+" .. tostring(days)
  local exclude_screenshots = downloads .. "/screenshots/*"
  local exclude_Screenshots = downloads .. "/Screenshots/*"

  vim.fn.jobstart({
    "find",
    downloads,
    "-mindepth",
    "1",
    "-depth",
    "-mtime",
    mtime,
    "-not",
    "-path",
    exclude_screenshots,
    "-not",
    "-path",
    exclude_Screenshots,
    "-print",
    "-exec",
    "mv",
    "-f",
    "{}",
    trash,
    ";",
  }, {

    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      for _, line in ipairs(data or {}) do
        if line and line ~= "" then
          table.insert(moved, line)
        end
      end
    end,
    on_stderr = function(_, data)
      for _, line in ipairs(data or {}) do
        if line and line ~= "" then
          vim.notify("Downloads purge warn: " .. line, vim.log.levels.WARN)
        end
      end
    end,
    on_exit = function(_, code)
      if code == 0 then
        local count = #moved
        if count > 0 then
          vim.notify(
            string.format("Moved %d items older than %d days from Downloads to Trash", count, days),
            vim.log.levels.INFO
          )
        else
          vim.notify(string.format("No items older than %d days in Downloads", days), vim.log.levels.INFO)
        end
      else
        vim.notify("Downloads purge failed (exit " .. tostring(code) .. ")", vim.log.levels.ERROR)
      end
    end,
  })
end

vim.api.nvim_create_autocmd("VimEnter", {
  desc = "Backup Helium data on start (async)",
  callback = function()
    if vim.fn.argc() == 0 then
      vim.cmd("Neotree float")
    end
    purge_downloads_async(15)
  end,
})
