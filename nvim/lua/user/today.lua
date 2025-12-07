-- today.lua (daily file per date)

local notes_dir = vim.fn.expand("~/Desktop/obs-v1/tasks/")

-- :Today command with full daily planner in a date-named file
local function insert_today()
  local date = os.date("%Y-%m-%d")
  local daily_file = notes_dir .. date .. "-daily.md"
  local today_header = "## " .. date

  -- Minimal daily template focused on essentials
  local template = string.format(
    [[%s

## Top 1 Goal
- [ ]

## Three Tasks
- [ ]
- [ ]
- [ ]

## Non-negotiable Habit
- [ ]

## Notes
-

## End of Day
- [ ] Top 1 done?
- Tomorrow’s top 1:
]],
    today_header
  )

  -- If file exists, just open it
  if vim.fn.filereadable(daily_file) == 1 then
    vim.cmd("edit " .. daily_file)
    vim.cmd("/" .. today_header)
    return
  end

  -- Split template into lines and write file
  local lines = vim.split(template, "\n", { trimempty = false })
  vim.fn.writefile(lines, daily_file)
  vim.cmd("edit " .. daily_file)
  vim.cmd("/" .. today_header)
end

vim.api.nvim_create_user_command("Today", insert_today, {})

-- :TaskFile command
local function create_task_file()
  vim.ui.input({ prompt = "Enter task file name (without .md): " }, function(input)
    if not input or input == "" then
      print("No file name provided.")
      return
    end
    local filename = input:gsub("%s+", "_") .. ".md"
    local filepath = vim.fn.expand("~/Desktop/obs-v1/tasks/" .. filename)
    local today = os.date("%Y-%m-%d %H:%M")
    local title = "# " .. input
    local content = string.format("%s\n\nDate: %s\n\n", title, today)
    if vim.fn.filereadable(filepath) == 1 then
      print("File already exists: " .. filepath)
      vim.cmd("edit " .. filepath)
      return
    end
    vim.fn.writefile(vim.split(content, "\n", { trimempty = false }), filepath)
    vim.cmd("edit " .. filepath)
  end)
end

vim.api.nvim_create_user_command("NewTask", create_task_file, {})
