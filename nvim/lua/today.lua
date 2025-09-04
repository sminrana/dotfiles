-- today.lua

local notes_dir = vim.fn.expand("~/Desktop/obs-v1/goals/")
local daily_file = notes_dir .. "daily.md"
local weekly_file = notes_dir .. "weekly.md"

-- :Today command
local function insert_today()
  local today = os.date("%Y-%m-%d")
  local template = string.format([[
## %s

✅ 3 MIT (Most Important Tasks)
- [ ] 
- [ ] 
- [ ] 

🪶 Notes
-
]], today)

  local lines = {}
  if vim.fn.filereadable(daily_file) == 1 then
    lines = vim.fn.readfile(daily_file)
  end

  local today_header = "## " .. today
  for _, line in ipairs(lines) do
    if line:match(today_header) then
      vim.cmd("edit " .. daily_file)
      vim.cmd("/" .. today_header)
      return
    end
  end

  -- split template into separate lines
  local template_lines = vim.split(template, "\n", { trimempty = false })
  for _, l in ipairs(template_lines) do
    table.insert(lines, l)
  end

  vim.fn.writefile(lines, daily_file)
  vim.cmd("edit " .. daily_file)
  vim.cmd("/" .. today_header)
end


vim.api.nvim_create_user_command("Today", insert_today, {})

-- :Week command
local function insert_week()
  -- ISO week number (e.g. W34)
  local week = os.date("W%V")
  local year = os.date("%Y")
  local header = string.format("# 📅 Week %s (%s)", week, year)

  local template = string.format([[
%s

## 🎯 Focus
- Main focus for the week

## ✅ Tasks
- [ ] 
- [ ] 
- [ ] 

## 📝 Notes
-
]], header)

  local lines = {}
  if vim.fn.filereadable(weekly_file) == 1 then
    lines = vim.fn.readfile(weekly_file)
  end

  -- Check if this week's header already exists
  for _, line in ipairs(lines) do
    if line:match(header) then
      print("This week's entry already exists!")
      vim.cmd("edit " .. weekly_file)
      vim.cmd("/" .. header)
      return
    end
  end

  -- Split template into separate lines (fixes newline issues)
  local template_lines = vim.split(template, "\n", { trimempty = false })
  for _, l in ipairs(template_lines) do
    table.insert(lines, l)
  end

  vim.fn.writefile(lines, weekly_file)
  vim.cmd("edit " .. weekly_file)
  vim.cmd("/" .. header)
end


vim.api.nvim_create_user_command("Week", insert_week, {})
