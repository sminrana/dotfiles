-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim-LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local autocmds_group = vim.api.nvim_create_augroup("config_autocmds", { clear = true })

-- Load project-specific .nvim.lua if present
local last_loaded = nil
local allowlist_path = vim.fn.stdpath("state") .. "/project-nvim-lua-allowlist.lua"

local function load_allowlist()
  local ok, data = pcall(dofile, allowlist_path)
  if ok and type(data) == "table" then
    return data
  end
  return {}
end

local function save_allowlist(list)
  local dir = vim.fn.fnamemodify(allowlist_path, ":h")
  vim.fn.mkdir(dir, "p")
  local lines = { "return {" }
  for path, allowed in pairs(list) do
    if allowed then
      table.insert(lines, string.format("  [%q] = true,", path))
    end
  end
  table.insert(lines, "}")
  vim.fn.writefile(lines, allowlist_path)
end

local function is_allowed(path)
  local allowlist = load_allowlist()
  return allowlist[path] == true
end

local function prompt_allow(path)
  local choice = vim.fn.confirm(
    "Load project config?\n" .. path,
    "&Yes\n&No\n&Always",
    2
  )
  if choice == 3 then
    local allowlist = load_allowlist()
    allowlist[path] = true
    save_allowlist(allowlist)
    return true
  end
  return choice == 1
end

local function load_project_config()
  local cwd = vim.fn.getcwd()
  if cwd == last_loaded then
    return
  end
  local project_config = cwd .. "/.nvim.lua"
  if vim.fn.filereadable(project_config) == 1 then
    if is_allowed(project_config) or prompt_allow(project_config) then
      pcall(dofile, project_config)
    end
    last_loaded = cwd
  end
end

vim.api.nvim_create_autocmd("VimEnter", {
  group = autocmds_group,
  callback = load_project_config,
})

vim.api.nvim_create_autocmd("DirChanged", {
  group = autocmds_group,
  callback = load_project_config,
})

vim.api.nvim_create_autocmd("DirChanged", {
  group = autocmds_group,
  callback = function()
    local cwd = vim.fn.getcwd()
    local hostname = vim.fn.hostname()
    os.execute('printf "\\033]7;file://' .. hostname .. cwd .. '\\033\\\\"')
  end,
})


-- Highlight trailing whitespace
vim.api.nvim_create_autocmd("FileType", {
  group = autocmds_group,
  pattern = { "php", "typescriptreact", "lua", "python", "javascript", "typescript", "vue" },
  callback = function()
    local win = vim.api.nvim_get_current_win()
    local existing = vim.w.trailing_ws_match_id
    if existing and vim.fn.matchdelete(existing, win) then
      vim.w.trailing_ws_match_id = nil
    end
    vim.w.trailing_ws_match_id = vim.fn.matchadd("ErrorMsg", [[\s\+$]])
  end,
})

-- Restore cursor position when reopening a file
vim.api.nvim_create_autocmd("BufReadPost", {
  group = autocmds_group,
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
  group = autocmds_group,
  callback = function()
    local view = vim.fn.winsaveview()
    if vim.fn.getline("$") ~= "" then
      vim.fn.append(vim.fn.line("$"), "")
    end
    if vim.fn.line("$") < 2500 then
      vim.cmd([[silent! %s#\($\n\s*\)\+\%$##]])
    end
    vim.fn.winrestview(view)
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
  group = autocmds_group,
  callback = setup_buffer_mappings,
})

vim.api.nvim_create_autocmd({ "FocusLost", "WinLeave" }, {
  group = autocmds_group,
  desc = "Switch to Normal mode on focus/tab/window leave if in Insert mode",
  callback = function()
    local mode = vim.api.nvim_get_mode().mode
    if mode == "i" or mode == "ic" then
      vim.cmd("stopinsert")
    end
  end,
})

