-- Utility function to simplify keymap definitions
local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  vim.keymap.set(mode, lhs, rhs, opts)
end

local function random_filename_with_ext(path)
  local ext = path:match("^.+(%..+)$") or ""
  local ts = os.date("%Y%m%d%H%M%S")
  -- List of syllables for more meaningful pseudo-words
  local syllables = { "ka", "lo", "mi", "ra", "zu", "ve", "xo", "ni", "sa", "tu", "po", "qi", "wa", "jo", "fi" }
  local mystic = ""
  for _ = 1, 2 do
    mystic = mystic .. syllables[math.random(#syllables)]
  end
  return ts .. mystic .. ext
end

local function do_upload(finalFile)
  local filename = vim.fn.fnamemodify(finalFile, ":t")
  filename = random_filename_with_ext(filename)
  local bucket = "smindev" -- change this to your S3 bucket
  local s3_path = "s3://" .. bucket .. "/static/" .. filename
  local cmd = { "aws", "s3", "cp", finalFile, s3_path, "--acl", "public-read" }

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
        local url = "https://smin.dev/scr/" .. filename
        vim.fn.setreg("+", url)
        vim.notify("Public URL copied: " .. url, vim.log.levels.INFO)
      else
        vim.notify("Failed to upload: exit code " .. code, vim.log.levels.ERROR)
      end
    end)
  end)
end

local function upload_to_s3(file)

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
          do_upload(mp4_file)
        else
          vim.notify("ffmpeg conversion failed (exit " .. code .. "): " .. mp4_file, vim.log.levels.ERROR)
        end
      end)
    end)
    return
  end

  do_upload(file)
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

  upload_to_s3(file)
end

local function select_file_to_move_to_s3()
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
  vim.ui.select(files, { prompt = "Select file to upload to S3" }, function(choice)
    if not choice then
      return
    end
    local src = src_dir .. choice
    upload_to_s3(src)
  end)
end

local function copy_to_s3()
  local file = vim.fn.expand("%:p")
  upload_to_s3(file)
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

map("n", prefix .. "R", function()
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

map("n", prefix .. "f7", copy_to_s3, { desc = "Upload current buffer to S3" })
map("n", prefix .. "f6", select_file_to_move_to_s3, { desc = "Upload file from /scr to S3" })
map("n", prefix .. "f5", send_file_to_s3, { desc = "Choose any file to S3" })

local personal_keymaps = {
  { "C", "<Cmd>%y<CR>", "Copy All" },
  { "X", "<Cmd>%d<CR>", "Cut All" },
  { "S", "ggVG", "Select All" },
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
  { "ls", "<cmd>Lazy sync<CR>", "Lazy sync" },
  { "m1", "<Cmd>MarkdownPreview<CR>" },
  { "m2", "<Cmd>ObsidianNew<CR>" },
  { "m3", "<Cmd>ObsidianToday<CR>" },
}


map("n", prefix .. "r^", "<Cmd>%s/\r//g<CR>", { desc = "Remove ^M" })
map("v", prefix .. "rm", function()
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  for lnum = start_line, end_line do
    local line = vim.fn.getline(lnum)
    line = line:gsub("^[-+]+", "")
    vim.fn.setline(lnum, line)
  end
end, { desc = "Remove - and + from beginning of selected lines" })

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

map("n", prefix .. "c1", function()
  vim.ui.input({ prompt = "Shell command to run: " }, function(cmd)
    if not cmd or cmd == "" then
      vim.notify("No command entered.", vim.log.levels.WARN)
      return
    end
    vim.notify("Running in new tab: " .. cmd, vim.log.levels.INFO)
    vim.cmd("tabnew | terminal " .. cmd)
  end)
end, { desc = "Run shell command" })

map("n", prefix .. "c2", function()
  local script_dir = vim.fn.expand("~/Desktop/scripts/")
  local files = {}
  local p = io.popen('ls -1 "' .. script_dir .. '"')
  if p then
    for file in p:lines() do
      if file:match("%.sh$") then
        table.insert(files, file)
      end
    end
    p:close()
  end
  if #files == 0 then
    vim.notify("No shell scripts found in " .. script_dir, vim.log.levels.WARN)
    return
  end
  vim.ui.select(files, { prompt = "Select shell script to run:" }, function(choice)
    if not choice then
      return
    end
    local script_path = script_dir .. choice
    vim.notify("Running: " .. script_path .. " in terminal", vim.log.levels.INFO)
    vim.cmd("terminal bash '" .. script_path .. "'")
  end)
end, { desc = "Run shell script from ~/Desktop/scripts" })
