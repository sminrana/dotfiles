-- Single simple tasks file management

local task_file = vim.fn.expand("~/Desktop/obs-v1/tasks/TODO.md")

local function ensure_tasks()
  if vim.fn.filereadable(task_file) == 1 then
    vim.cmd("edit " .. task_file)
    return
  end
  local template = [[# Tasks

## Top 1
- [ ]

## Next 3
- [ ]
- [ ]
- [ ]

## Notes
-
]]
  vim.fn.writefile(vim.split(template, "\n", { trimempty = false }), task_file)
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
  local lines = vim.split(section, "\n", { trimempty = false })
  -- Ensure file exists first
  if vim.fn.filereadable(task_file) == 0 then
    ensure_tasks()
  end
  vim.fn.writefile(lines, task_file, "a")
  vim.cmd("edit " .. task_file)
  vim.cmd("/## " .. date)
end

vim.api.nvim_create_user_command("Tasks", ensure_tasks, {})
vim.api.nvim_create_user_command("TaskAdd", append_dated_section, {})
