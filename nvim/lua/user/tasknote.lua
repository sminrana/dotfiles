local M = {}

local function create_note(dir, template_content, type_name)
  local expanded_dir = vim.fn.expand(dir)
  if vim.fn.isdirectory(expanded_dir) == 0 then
    vim.fn.mkdir(expanded_dir, "p")
  end

  local filename = os.date("%Y-%m-%d-%H%M") .. ".md"
  local filepath = expanded_dir .. "/" .. filename

  if vim.fn.filereadable(filepath) == 1 then
    vim.notify("File already exists: " .. filepath, vim.log.levels.WARN)
    vim.cmd("tabnew " .. vim.fn.fnameescape(filepath))
    return
  end

  local f = io.open(filepath, "w")
  if f then
    f:write(template_content)
    f:close()
    vim.cmd("tabnew " .. vim.fn.fnameescape(filepath))
    vim.notify("Created new " .. type_name .. " note: " .. filename, vim.log.levels.INFO)
    vim.fn.search("- ")
  else
    vim.notify("Failed to create file: " .. filepath, vim.log.levels.ERROR)
  end
end

function M.create_task_note()
  local template = [[# Objectives
- 

# Technical Logs
- 

# Blockers
- 
]]
  create_note("~/Desktop/obs-v1/80-Tasks", template, "Task")
end

function M.create_meeting_note()
  local date_str = os.date("%Y-%m-%d")
  local template = string.format([[# Date: %s
# Attendees
- 

# Agenda
- 

# Action Items
- 
]], date_str)
  create_note("~/Desktop/obs-v1/70-Meetings", template, "Meeting")
end

-- Keymaps
local prefix = "<leader>j"
vim.keymap.set("n", prefix .. "tt", M.create_task_note, { desc = "Create Task Note" })
vim.keymap.set("n", prefix .. "tm", M.create_meeting_note, { desc = "Create Meeting Note" })

_G.ObsidianNotes = M

return M
