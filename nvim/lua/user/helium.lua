local Path = require("plenary.path")

local heliumbook = os.getenv("HOME") .. "/Library/Application Support/net.imput.helium/Default/Bookmarks"

-- Optional external config table support
local config = rawget(_G, "config") or {}

-- Use provided function to resolve backup directory
local function get_backup_dir()
  local base = config.backup_dir and vim.fn.expand(config.backup_dir)
  if not base or base == "" then
    base = vim.fn.expand("~/Desktop/backup")
  end
  return base
end

-- Backup file path within the backup directory
local backup_bookmarks = get_backup_dir() .. "/Bookmarks"

local function exists(file)
  local f = io.open(file, "r")
  if f then
    f:close()
    return true
  end
  return false
end

local function copy_file(src, dest)
  local p_src = Path:new(src)
  local p_dest = Path:new(dest)
  -- Ensure destination directory exists when copying a file
  Path:new(p_dest:parent()):mkdir({ parents = true, exists_ok = true })
  -- First try via plenary (libuv copy)
  local ok, res = pcall(function()
    return p_src:copy({ destination = p_dest, recursive = false, override = true })
  end)
  if ok and res then
    return true
  end
  -- Fallback: manual copy (read/write)
  local rf = io.open(p_src:absolute(), "rb")
  if not rf then
    return false, "cannot open source"
  end
  local wf = io.open(p_dest:absolute(), "wb")
  if not wf then
    rf:close()
    return false, "cannot open dest"
  end
  local chunk = rf:read("*a")
  if not chunk then
    rf:close()
    wf:close()
    return false, "read failed"
  end
  wf:write(chunk)
  rf:close()
  wf:close()
  return true
end

local function pull_bookmarks()
  if not exists(backup_bookmarks) then
    print("No backup bookmarks file found: " .. backup_bookmarks)
    return
  end
  print("Restoring bookmarks: " .. backup_bookmarks .. " -> " .. heliumbook)
  local ok, err = copy_file(backup_bookmarks, heliumbook)
  if not ok then
    print("Restore failed: " .. (err or "unknown error") .. ". Try closing Helium app and check file permissions.")
    return
  end
  print("Restored bookmarks from backup to Helium.")
end

local function push_bookmarks()
  if not exists(heliumbook) then
    print("No Helium bookmarks file found: " .. heliumbook)
    return
  end
  print("Backing up bookmarks: " .. heliumbook .. " -> " .. backup_bookmarks)
  local ok, err = copy_file(heliumbook, backup_bookmarks)
  if not ok then
    print("Backup failed: " .. (err or "unknown error") .. ". Try closing Helium app and check file permissions.")
    return
  end
  print("Backed up Helium bookmarks to " .. backup_bookmarks)
end

vim.api.nvim_create_user_command("HeliumBackup", push_bookmarks, {})
vim.api.nvim_create_user_command("HeliumRestore", pull_bookmarks, {})

-- Auto backup on Neovim exit (library -> backup)
local helium_group = vim.api.nvim_create_augroup("HeliumAutoBackup", { clear = true })
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = helium_group,
  callback = function()
    pcall(push_bookmarks)
  end,
  desc = "Backup Helium bookmarks on exit",
})

-- To also back up on start, uncomment below:
-- vim.api.nvim_create_autocmd("VimEnter", {
--   group = helium_group,
--   callback = function()
--     pcall(push_bookmarks)
--   end,
--   desc = "Backup Helium bookmarks on start",
-- })
