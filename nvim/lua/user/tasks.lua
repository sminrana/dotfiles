-- Single simple tasks file management

local task_file = vim.fn.expand("~/Desktop/obs-v1/tasks/TODO.md")

local function ensure_tasks()
  vim.cmd("edit " .. task_file)
end

local function append_dated_section()
  local date = os.date("%Y-%m-%d")
  local header = string.format("\n## %s\n", date)
  local section = header .. [[
### Top 1
- [ ]

### Tasks
- [ ]
- [ ]
- [ ]

### Notes
-
]]
  local new_lines = vim.split(section, "\n", { trimempty = false })
  -- Ensure file exists first (open buffer)
  if vim.fn.filereadable(task_file) == 0 then
    ensure_tasks()
  end
  -- Read existing file lines (if any)
  local existing = {}
  if vim.fn.filereadable(task_file) == 1 then
    existing = vim.fn.readfile(task_file)
  end
  -- Prepend new section to existing content
  local all = {}
  for _, l in ipairs(new_lines) do
    table.insert(all, l)
  end
  for _, l in ipairs(existing) do
    table.insert(all, l)
  end
  vim.fn.writefile(all, task_file)
  vim.cmd("edit " .. task_file)
  vim.cmd("/## " .. date)
end

vim.api.nvim_create_user_command("Tasks", ensure_tasks, {})
vim.api.nvim_create_user_command("TaskAdd", append_dated_section, {})
