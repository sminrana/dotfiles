local M = {}

local function create_note(dir, template_content)
  local expanded_dir = vim.fn.expand(dir)
  if vim.fn.isdirectory(expanded_dir) == 0 then
    vim.fn.mkdir(expanded_dir, "p")
  end

  local filename = os.date("%Y-%m-%d") .. ".md"
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
    vim.notify("Created new journal: " .. filename, vim.log.levels.INFO)
    vim.fn.search("- ")
  else
    vim.notify("Failed to create file: " .. filepath, vim.log.levels.ERROR)
  end
end

function M.create_journal_note()
  local date = os.date("%Y-%m-%d")
  local template = string.format([[# Date: %s
]], date)

  create_note("~/Desktop/obs-v1/90-Journals", template)
end


-- Keymaps
local prefix = "<leader>j"
vim.keymap.set("n", prefix .. "j", M.create_journal_note, { desc = "Create Journal" })

_G.ObsidianNotes = M

return M
