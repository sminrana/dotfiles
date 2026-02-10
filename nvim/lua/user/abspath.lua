local M = {}
local winbar_cache = {}

local function escape_statusline(text)
  return text:gsub("%%", "%%%%"):gsub("#", "##")
end

local function build_winbar(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return ""
  end

  local stat = vim.loop.fs_stat(name)
  local info = {}

  if stat then
    table.insert(info, string.format("%03o", stat.mode % 512))
  end

  if vim.bo[bufnr].modified then
    table.insert(info, "+")
  end

  if vim.bo[bufnr].readonly then
    table.insert(info, "ro")
  end

  local dict = vim.b[bufnr].gitsigns_status_dict
  if dict then
    local parts = {}
    if dict.added and dict.added > 0 then
      table.insert(parts, "+" .. dict.added)
    end
    if dict.changed and dict.changed > 0 then
      table.insert(parts, "~" .. dict.changed)
    end
    if dict.removed and dict.removed > 0 then
      table.insert(parts, "-" .. dict.removed)
    end
    if #parts > 0 then
      table.insert(info, table.concat(parts, " "))
    end
  end

  if #info > 0 then
    return name .. "  |  " .. table.concat(info, "  |  ")
  end

  return name
end

local function set_abs_path_winbar(bufnr, winid)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  if vim.bo[bufnr].buftype ~= "" then
    return
  end

  local text = build_winbar(bufnr)
  if text == "" then
    return
  end

  if not winid or not vim.api.nvim_win_is_valid(winid) then
    return
  end

  local rendered = "%=" .. escape_statusline(text)
  if winbar_cache[winid] == rendered then
    return
  end

  winbar_cache[winid] = rendered
  vim.api.nvim_win_set_option(winid, "winbar", rendered)
end

function M.setup()
  vim.api.nvim_create_autocmd({
    "BufWinEnter",
    "BufFilePost",
    "BufWritePost",
    "WinEnter",
    "BufModifiedSet",
  }, {
    desc = "Show absolute path in winbar",
    callback = function(args)
      local winid = vim.api.nvim_get_current_win()
      set_abs_path_winbar(args.buf, winid)
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    pattern = "GitsignsStatusUpdated",
    desc = "Refresh winbar on git status change",
    callback = function(args)
      local winid = vim.api.nvim_get_current_win()
      set_abs_path_winbar(args.buf, winid)
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    desc = "Clear winbar cache on close",
    callback = function(args)
      local winid = tonumber(args.match)
      if winid then
        winbar_cache[winid] = nil
      end
    end,
  })
end

M.setup()

return M
