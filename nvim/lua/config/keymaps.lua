-- Utility function to simplify keymap definitions
local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- General keymaps
map("n", "q", "<nop>", { noremap = true })
map("n", "Q", "q", { noremap = true, desc = "Record macro" })
map("n", "<M-q>", "Q", { noremap = true, desc = "Replay last register" })

map("n", "gO", "<Cmd>call append(line('.') - 1, repeat([''], v:count1))<CR>")
map("n", "go", "<Cmd>call append(line('.'), repeat([''], v:count1))<CR>")
map("n", "<leader>e", "<Cmd>Neotree reveal float<CR>")
map("n", "<leader>be", "<Cmd>Neotree buffers float<CR>")

-- FZF keymaps
map("n", "<leader>fa", function()
  require("fzf-lua").live_grep({ cwd = "~/app/" })
end, { desc = "Live Grep in App Files" })

map("n", "<leader>fw", function()
  require("fzf-lua").live_grep({ cwd = "~/web/" })
end, { desc = "Live Grep in Web Files" })

map("n", "<leader>fx", function()
  require("fzf-lua").live_grep({ cwd = "~/Desktop/obs-v1/" })
end, { desc = "Live Grep in Notes Files" })

map("n", "<leader>fs", function()
  require("fzf-lua").live_grep({ cwd = "~/Desktop/snippets/" })
end, { desc = "Live Grep in Snippets Files" })

map("n", "<leader>ba", function()
  require("fzf-lua").blines()
end, { desc = "Live Grep in Current Buffer" })

-- ===============================Personal keymaps===================================
-- Define a prefix for personal keymaps
local prefix = "<leader>j"

-- ======================================== TODO
map("n", prefix .. "td", function()
  local date = os.date("%b %d, %Y %H:%M:%S %Z")
  local emoji = "✅ Done - " .. date
  local line = vim.api.nvim_get_current_line()
  vim.api.nvim_set_current_line(line .. " " .. emoji)
end, { desc = "Mark is as done" })

map("n", prefix .. "tc", function()
  local date = os.date("%b %d, %Y %H:%M:%S %Z")
  local emoji = "💬 Nafiz(" .. date .. "): "
  local line = vim.api.nvim_get_current_line()
  vim.api.nvim_set_current_line(line .. " " .. emoji)
  vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], #line + #emoji + 1 })
end, { desc = "Add your answer" })

vim.keymap.set("n", prefix .. "ta", function()
  vim.cmd([[normal! I🟩 ]])
end, { desc = "Add emoji at beginning of the line" })

map("n", prefix .. "tb", function()
  local date = os.date("%b %d, %Y %H:%M:%S %Z")
  local emoji = "❌ " .. date
  local line = vim.api.nvim_get_current_line()
  vim.api.nvim_set_current_line(line .. " " .. emoji)
end, { desc = "Mark it as bug" })

map("n", prefix .. "t?", function()
  local date = os.date("%b %d, %Y %H:%M:%S %Z")
  local emoji = "❓- Need Feedback - " .. date
  local line = vim.api.nvim_get_current_line()
  vim.api.nvim_set_current_line(line .. " " .. emoji)
end, { desc = "Mark it as unknown, send question" })

map("n", prefix .. "tl", function()
  local date = os.date("%b %d, %Y %H:%M:%S %Z")
  local emoji = "🕤 " .. date
  local line = vim.api.nvim_get_current_line()
  vim.api.nvim_set_current_line(line .. " " .. emoji)
end, { desc = "Mark it as delayed" })

map("n", prefix .. "tp", function()
  local date = os.date("%b %d, %Y %H:%M:%S %Z")
  local emoji = "🛠️" .. date
  local line = vim.api.nvim_get_current_line()
  vim.api.nvim_set_current_line(line .. " " .. emoji)
end, { desc = "Mark it as in progress" })

map("n", prefix .. "t1", function()
  local date = os.date("%b %d, %Y %H:%M:%S %Z")
  local emoji = "🚩🚩🚩 - High - " .. date
  local line = vim.api.nvim_get_current_line()
  vim.api.nvim_set_current_line(line .. " " .. emoji)
end, { desc = "Mark it as high priority" })

map("n", prefix .. "t2", function()
  local date = os.date("%b %d, %Y %H:%M:%S %Z")
  local emoji = "🚩🚩 - Medium - " .. date
  local line = vim.api.nvim_get_current_line()
  vim.api.nvim_set_current_line(line .. " " .. emoji)
end, { desc = "Mark it as medium priority" })

map("n", prefix .. "t3", function()
  local date = os.date("%b %d, %Y %H:%M:%S %Z")
  local emoji = "🚩 - Low - " .. date
  local line = vim.api.nvim_get_current_line()
  vim.api.nvim_set_current_line(line .. " " .. emoji)
end, { desc = "Mark it as low priority" })

map("n", prefix .. "r", function()
  vim.ui.input({ prompt = "Substitute pattern (e.g. foo/bar/g): " }, function(input)
    if not input or input == "" then
      vim.notify("No pattern entered.", vim.log.levels.WARN)
      return
    end
    vim.cmd("%s/" .. input)
  end)
end, { desc = "Start :%s substitution" })

-- =========================================== Markdown
vim.keymap.set("n", prefix .. "m4", function()
  local line = vim.api.nvim_get_current_line()
  if not (vim.startswith(line, "~~") and vim.endswith(line, "~~")) then
    vim.api.nvim_set_current_line("~~" .. line .. "~~")
  end
end, { desc = "Wrap current line with ~ for markdown strike through" })

vim.keymap.set("n", prefix .. "m5", function()
  local line = vim.api.nvim_get_current_line()
  if not (vim.startswith(line, "**") and vim.endswith(line, "**")) then
    vim.api.nvim_set_current_line("**" .. line .. "**")
  end
end, { desc = "Wrap current line with ** for markdown bold" })

vim.keymap.set("n", prefix .. "m6", function()
  local line = vim.api.nvim_get_current_line()
  if not (vim.startswith(line, "*") and vim.endswith(line, "*")) then
    vim.api.nvim_set_current_line("*" .. line .. "*")
  end
end, { desc = "Wrap current line with * for markdown italic" })

vim.keymap.set("n", prefix .. "m7", function()
  local date = os.date("%b %d, %Y %H:%M:%S %Z")
  vim.api.nvim_put({ date }, "c", true, true)
end, { desc = "Add date here" })

-- Copy file to Dropbox Vault START
local function copy_to_dropbox_vault()
  local file = vim.fn.expand("%:p")
  local target = vim.fn.expand("~/Library/CloudStorage/Dropbox/Vault/") .. vim.fn.expand("%:t")
  vim.fn.system({ "cp", file, target })
  vim.notify("Sent to Dropbox Vault: " .. target, vim.log.levels.INFO)
end

map("n", prefix .. "f7", copy_to_dropbox_vault, { desc = "Send file to Dropbox Vault" })

local function select_file_to_move_to_dropbox()
  local src_dir = vim.fn.expand("~/Downloads/scr/")
  local files = {}
  local p = io.popen('ls -1t "' .. src_dir .. '"')
  if p then
    for file in p:lines() do
      table.insert(files, file)
    end
    p:close()
  end
  if #files == 0 then
    vim.notify("No files found in " .. src_dir, vim.log.levels.WARN)
    return
  end
  vim.ui.select(files, { prompt = "Select file to copy to Dropbox Vault?" }, function(choice)
    if not choice then
      return
    end
    local src = src_dir .. choice
    local dst = vim.fn.expand("~/Library/CloudStorage/Dropbox/Vault/") .. choice
    vim.fn.system({ "mv", src, dst })
    vim.notify("Moved file: " .. choice, vim.log.levels.INFO)
  end)
end

map("n", prefix .. "f6", select_file_to_move_to_dropbox, { desc = "Move screenshot to Dropbox (choose)" })

-- Copy file to Dropbox Vault END

-- Copy file to S3 Bucket END

local function upload_to_s3(file)
  local filename = vim.fn.fnamemodify(file, ":t")
  filename = filename:gsub("%s+", "") -- remove all whitespace (spaces, tabs, etc.)
  local bucket = "smindev" -- change this to your S3 bucket
  local s3_path = "s3://" .. bucket .. "/static/" .. filename
  local cmd = { "aws", "s3", "cp", file, s3_path, "--acl", "public-read" }

  -- Show progress in statusline
  vim.api.nvim_set_option("statusline", "%#WarningMsg#Uploading to S3: " .. filename .. "...%*")
  vim.notify("Uploading to S3 in background: " .. filename, vim.log.levels.INFO)

  vim.loop.spawn(cmd[1], {
    args = { unpack(cmd, 2) },
    stdio = { nil, nil, nil },
  }, function(code, signal)
    -- Restore statusline (optional: you may want to save/restore original)
    vim.schedule(function()
      vim.api.nvim_set_option("statusline", "")
      if code == 0 then
        vim.notify("Uploaded to S3: " .. filename, vim.log.levels.INFO)
        local url = "https://" .. bucket .. ".s3.amazonaws.com/static/" .. filename
        vim.fn.setreg("+", url)
        vim.notify("Public URL copied: " .. url, vim.log.levels.INFO)
      else
        vim.notify("Failed to upload: exit code " .. code, vim.log.levels.ERROR)
      end
    end)
  end)
end

local function send_file_to_s3()
  local file = vim.fn.input("Enter file path to upload to S3: ", "", "file")
  if file == "" or vim.fn.filereadable(file) == 0 then
    vim.notify("Invalid file path: " .. file, vim.log.levels.ERROR)
    return
  end
  local confirm = vim.fn.input("Upload '" .. file .. "' to S3? (y/N): ")
  if confirm:lower() ~= "y" then
    vim.notify("Upload cancelled.", vim.log.levels.INFO)
    return
  end
  if not vim.fn.executable("aws") then
    vim.notify("AWS CLI is not installed or not in PATH.", vim.log.levels.ERROR)
    return
  end
  if not vim.fn.filereadable(file) then
    vim.notify("File does not exist: " .. file, vim.log.levels.ERROR)
    return
  end

  -- If file is .mov, convert to .mp4 first using ffmpeg (in background)
  if file:match("%.mov$") then
    local mp4_file = file:gsub("%.mov$", ".mp4")
    local ffmpeg_cmd = { "ffmpeg", "-y", "-i", file, "-vcodec", "libx264", "-acodec", "aac", mp4_file }
    if vim.fn.executable("ffmpeg") ~= 1 then
      vim.notify("ffmpeg is not installed or not in PATH.", vim.log.levels.ERROR)
      return
    end
    vim.notify("Converting .mov to .mp4 in background: " .. mp4_file, vim.log.levels.INFO)
    vim.loop.spawn(ffmpeg_cmd[1], {
      args = { unpack(ffmpeg_cmd, 2) },
      stdio = { nil, nil, nil },
    }, function(code, signal)
      vim.schedule(function()
        if code == 0 then
          vim.notify("ffmpeg conversion succeeded: " .. mp4_file, vim.log.levels.INFO)
          -- Continue upload with mp4_file
          upload_to_s3(mp4_file)
        else
          vim.notify("ffmpeg conversion failed (exit " .. code .. "): " .. mp4_file, vim.log.levels.ERROR)
        end
      end)
    end)
    return
  else
    upload_to_s3(file)
  end
end


map("n", prefix .. "f5", send_file_to_s3, { desc = "Send file to AWS S3 (public link copied)" })
-- Copy file to S3 Bucket END

local personal_keymaps = {
  { "C", "<Cmd>%y<CR>", "Copy All" },
  { "X", "<Cmd>%d<CR>", "Cut All" },
  { "S", "ggVG", "Select All" },
  { "R", "<Cmd>%s/\r//g<CR>", "Remove ^M" },
  { "d", "<Cmd>tabe ~/Desktop/obs-v1/todo.md<CR>" },
  { "n", "<Cmd>tabe ~/Desktop/obs-v1/notes.md<CR>" },
  { "u", "<cmd>UndotreeToggle<cr>", "Toggle Undotree" },
  { "f1", ':let @+=expand("%:p")<CR>', "Copy file absolute path" },
  { "f2", ':let @+=expand("%:." )<CR>', "Copy file relative path" },
  { "f3", ':let @+=expand("%:t")<CR>', "Copy file name" },
  { "lh", "<Cmd>checkhealth<CR>", "Check health" },
  { "ll", "<cmd>Lazy<CR>", "Plugin Manager - [LazyVim]" },
  { "lm", "<cmd>Mason<CR>", "Package Manager - [Mason]" },
  { "le", "<cmd>LazyExtras<CR>", "Extras Manager - [LazyVim]" },
  { "li", "<cmd>LspInfo<CR>", "Lsp Info" },
  { "m1", "<Cmd>MarkdownPreview<CR>" },
  { "m2", "<Cmd>ObsidianNew<CR>" },
  { "m3", "<Cmd>ObsidianToday<CR>" },
}

for _, keymap in ipairs(personal_keymaps) do
  map("n", prefix .. keymap[1], keymap[2], { noremap = true, silent = true, desc = keymap[3] })
end

-- Snippet keymaps
map({ "n", "x" }, prefix .. "sa", function()
  require("scissors").addNewSnippet()
end, { desc = "Snippet: Add" })

map("n", prefix .. "se", function()
  require("scissors").editSnippet()
end, { desc = "Snippet: Edit" })

-- Yazi keymaps
local yazi_keymaps = {
  { "yf", "<cmd>Yazi<cr>", "Open yazi at the current file" },
  { "yd", "<cmd>Yazi cwd<cr>", "Open the file manager in nvim's working directory" },
  { "yt", "<cmd>Yazi toggle<cr>", "Resume the last yazi session" },
}

for _, keymap in ipairs(yazi_keymaps) do
  map({ "n", "v" }, prefix .. keymap[1], keymap[2], { desc = keymap[3] })
end

map("n", prefix .. "c", function()
  vim.ui.input({ prompt = "Shell command to run: " }, function(cmd)
    if not cmd or cmd == "" then
      vim.notify("No command entered.", vim.log.levels.WARN)
      return
    end
    vim.notify("Running: " .. cmd, vim.log.levels.INFO)
    local stdout = vim.loop.new_pipe(false)
    local stderr = vim.loop.new_pipe(false)
    local output = {}
    local function on_read(err, data)
      if data then
        table.insert(output, data)
      end
    end
    vim.loop.spawn("sh", {
      args = { "-c", cmd },
      stdio = { nil, stdout, stderr },
    }, function(code, signal)
      stdout:read_stop()
      stderr:read_stop()
      stdout:close()
      stderr:close()
      vim.schedule(function()
        local result = table.concat(output)
        if result ~= "" then
          vim.notify(result, vim.log.levels.INFO, { title = "Shell Output" })
        end
        if code == 0 then
          vim.notify("Command finished: " .. cmd, vim.log.levels.INFO)
        else
          vim.notify("Command failed (exit " .. code .. "): " .. cmd, vim.log.levels.ERROR)
        end
      end)
    end)
    stdout:read_start(on_read)
    stderr:read_start(on_read)
  end)
end, { desc = "Run shell command in background" })
