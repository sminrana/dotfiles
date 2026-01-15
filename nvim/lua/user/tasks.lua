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

vim.api.nvim_create_user_command("Tasks", ensure_tasks, {})
