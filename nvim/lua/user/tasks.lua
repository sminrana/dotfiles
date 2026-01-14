-- Single simple tasks file management

local tasks_dir = vim.fn.expand("~/Desktop/obs-v1/tasks")

local function today_file()
  local date = os.date("%Y-%m-%d")
  return tasks_dir .. "/todo-" .. date .. ".md"
end

local function ensure_tasks()
  local task_file = today_file()
  vim.cmd("edit " .. task_file)
end

local function append_dated_section()
  local task_file = today_file()
  local section = [[
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
  -- If today's file does not exist, create it with the template
  if vim.fn.filereadable(task_file) == 0 then
    vim.fn.writefile(new_lines, task_file)
  end
  -- Open today's file
  vim.cmd("edit " .. task_file)
end

vim.api.nvim_create_user_command("Tasks", ensure_tasks, {})
vim.api.nvim_create_user_command("TaskAdd", append_dated_section, {})
