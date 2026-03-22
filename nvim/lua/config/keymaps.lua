-- Define a prefix for personal keymaps
local prefix = "<leader>j"

local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- ================================ UTILITIES ================================

local function random_filename_with_ext(path)
  local ext = path:match("^.+(%..+)$") or ""
  local ts = os.date("%Y%m%d%H%M%S")
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
  local bucket = "smindev"
  local s3_path = "s3://" .. bucket .. "/static/" .. filename
  local cmd = { "aws", "s3", "cp", finalFile, s3_path, "--acl", "public-read" }

  vim.api.nvim_set_option("statusline", "%#WarningMsg#Uploading to S3: " .. filename .. "...%*")
  vim.notify("Uploading to S3 in background: " .. filename, vim.log.levels.INFO)

  vim.loop.spawn(cmd[1], {
    args = { unpack(cmd, 2) },
    stdio = { nil, nil, nil },
  }, function(code, signal)
    vim.schedule(function()
      vim.api.nvim_set_option("statusline", "")
      if code == 0 then
        vim.notify("Uploaded to S3: " .. filename, vim.log.levels.INFO)
        local url = "https://smin.dev/scr/" .. filename
        vim.fn.setreg("+", url)
        vim.notify("Public URL copied: " .. url, vim.log.levels.INFO)
      else
        vim.notify(
          "Failed to upload: exit code " .. code .. (signal ~= 0 and (", signal: " .. signal) or ""),
          vim.log.levels.ERROR
        )
        vim.notify("Check your AWS credentials, network connection, or S3 permissions.", vim.log.levels.ERROR)
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
  local src_dir = vim.fn.expand("~/Downloads/screenshots/")
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

local function get_globs_for_filetype(ft)
  if ft == "typescript" or ft == "typescriptreact" then
    return { "*.ts", "*.tsx", "*.svelte" }
  elseif ft == "php" then
    return { "*.php", "*.blade.php", "*.ctp" }
  elseif ft == "python" then
    return { "*.py" }
  elseif ft == "javascript" then
    return { "*.js", "*.jsx", "*.svelte" }
  else
    return { "*" }
  end
end

-- ================================ GENERAL ================================

map("n", "q", "<nop>", { noremap = true })
map("n", "Q", "q", { noremap = true, desc = "Record macro" })
map("n", "<M-q>", "Q", { noremap = true, desc = "Replay last register" })

map("n", "gO", "<Cmd>call append(line('.') - 1, repeat([''], v:count1))<CR>")
map("n", "go", "<Cmd>call append(line('.'), repeat([''], v:count1))<CR>")
map("n", "<leader>F", "<Cmd>FzfLua<CR>")

-- ================================ QUICK ACCESS ================================
-- j + key for frequently used actions

vim.keymap.set("n", prefix .. "md", function()
  local date = os.date("%b %d, %Y %H:%M:%S %Z")
  vim.api.nvim_put({ date }, "c", true, true)
end, { desc = "Insert current date" })

vim.keymap.set("n", prefix .. "m4", function()
  local line = vim.api.nvim_get_current_line()
  if not (vim.startswith(line, "~~") and vim.endswith(line, "~~")) then
    vim.api.nvim_set_current_line("~~" .. line .. "~~")
  end
end, { desc = "Wrap line with ~~ (strikethrough)" })

vim.keymap.set("n", prefix .. "m5", function()
  local line = vim.api.nvim_get_current_line()
  if not (vim.startswith(line, "**") and vim.endswith(line, "**")) then
    vim.api.nvim_set_current_line("**" .. line .. "**")
  end
end, { desc = "Wrap line with ** (bold)" })

vim.keymap.set("n", prefix .. "m6", function()
  local line = vim.api.nvim_get_current_line()
  if not (vim.startswith(line, "*") and vim.endswith(line, "*")) then
    vim.api.nvim_set_current_line("*" .. line .. "*")
  end
end, { desc = "Wrap line with * (italic)" })

map("n", prefix .. "D", "<Cmd>tabe ~/Desktop/obs-v1/goals/daily.md<CR>", { desc = "Open daily goals" })
map("n", prefix .. "N", "<Cmd>tabe ~/Desktop/obs-v1/notes.md<CR>", { desc = "Open notes" })
map("n", prefix .. "Q", "<Cmd>qa<CR>", { noremap = true, silent = true, desc = "Quit all" })

-- ================================ FILE OPERATIONS ================================
-- jf = File operations

map("n", prefix .. "fo", function()
  local fzf = require("fzf-lua")
  fzf.files({
    cwd = "~",
    prompt = "Open file: ",
    actions = {
      ["default"] = function(selected)
        if not selected or #selected == 0 then
          vim.notify("No file selected.", vim.log.levels.WARN)
          return
        end
        vim.cmd("tabnew " .. vim.fn.fnameescape(selected[1]))
      end,
    },
  })
end, { desc = "Open file in ~" })

map("n", prefix .. "fn", function()
  vim.ui.input({ prompt = "New file name: " }, function(input)
    if not input or input == "" then
      vim.notify("No file name entered.", vim.log.levels.WARN)
      return
    end
    vim.cmd("tabnew " .. vim.fn.fnameescape(input))
    vim.notify("Created new file: " .. input, vim.log.levels.INFO)
  end)
end, { desc = "Create new file" })

map("n", prefix .. "ff", function()
  local path = vim.fn.expand("%:p")
  if path == "" or vim.fn.filereadable(path) == 0 then
    vim.notify("Current buffer is not a file.", vim.log.levels.WARN)
    return
  end
  vim.fn.system({ "open", "-R", path })
  vim.notify("Revealed in Finder: " .. path, vim.log.levels.INFO)
end, { desc = "Reveal in Finder" })

map("n", prefix .. "fa", function()
  local path = vim.fn.expand("%:p")
  if path == "" or vim.fn.filereadable(path) == 0 then
    vim.notify("Current buffer is not a file.", vim.log.levels.WARN)
    return
  end
  vim.fn.system({ "open", path })
  vim.notify("Opened in default app: " .. path, vim.log.levels.INFO)
end, { desc = "Open in default app" })

local yazi_cmds = {
  { "fy", "<cmd>Yazi toggle<cr>", "Yazi toggle" },
}
for _, k in ipairs(yazi_cmds) do
  map({ "n", "v" }, prefix .. k[1], k[2], { desc = k[3] })
end

-- ================================ COPY PATHS ================================
-- jy = Yank (copy) paths

map("n", prefix .. "y1", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("Copied absolute path: " .. path, vim.log.levels.INFO)
end, { desc = "Copy absolute path" })

map("n", prefix .. "y2", function()
  local path = vim.fn.expand("%:.")
  vim.fn.setreg("+", path)
  vim.notify("Copied relative path: " .. path, vim.log.levels.INFO)
end, { desc = "Copy relative path" })

map("n", prefix .. "y3", function()
  local path = vim.fn.expand("%:t")
  vim.fn.setreg("+", path)
  vim.notify("Copied filename: " .. path, vim.log.levels.INFO)
end, { desc = "Copy filename" })

map("n", prefix .. "y4", function()
  local path = vim.fn.expand("%:p")
  local line = vim.fn.line(".")
  local result = path .. ":" .. line
  vim.fn.setreg("+", result)
  vim.notify("Copied path:line: " .. result, vim.log.levels.INFO)
end, { desc = "Copy path:line" })

map("n", prefix .. "yb", function()
  local paths = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.fn.buflisted(buf) == 1 then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" then
        table.insert(paths, vim.fn.fnamemodify(name, ":p"))
      end
    end
  end
  if #paths == 0 then
    vim.notify("No listed file buffers found.", vim.log.levels.WARN)
    return
  end
  local result = table.concat(paths, "\n")
  vim.fn.setreg("+", result)
  vim.notify("Copied " .. #paths .. " buffer paths.", vim.log.levels.INFO)
end, { desc = "Copy all buffer paths" })

-- ================================ SEARCH ================================
-- js = Search

map("n", prefix .. "sw", function()
  require("fzf-lua").live_grep({ cwd = "~/work/" })
end, { desc = "Search in ~/work" })

map("n", prefix .. "sx", function()
  require("fzf-lua").live_grep({ cwd = "~/Desktop/obs-v1/" })
end, { desc = "Search in Notes" })

map("n", prefix .. "ss", function()
  require("fzf-lua").live_grep({ cwd = "~/Desktop/snippets/" })
end, { desc = "Search in Snippets" })

map("n", prefix .. "sb", function()
  require("fzf-lua").blines()
end, { desc = "Search in buffer" })

map("n", prefix .. "si", function()
  vim.ui.input({ prompt = "Search for: " }, function(input)
    if not input or input == "" then
      vim.notify("No search term entered.", vim.log.levels.WARN)
      return
    end
    local ft = vim.bo.filetype
    local globs = get_globs_for_filetype(ft)
    local glob_args = ""
    for _, g in ipairs(globs) do
      glob_args = glob_args .. string.format(" --glob '%s'", g)
    end
    vim.o.grepprg = "rg --vimgrep"
    vim.cmd("silent grep! -w " .. vim.fn.shellescape(input) .. glob_args)
    vim.cmd("copen")
  end)
end, { noremap = true, silent = true, desc = "Project search (input)" })

-- ================================ SUBSTITUTE ================================
-- jr = Replace

map("n", prefix .. "r", function()
  vim.ui.input({ prompt = "Substitute (foo/bar/g): " }, function(input)
    if not input or input == "" then
      vim.notify("No pattern entered.", vim.log.levels.WARN)
      return
    end
    vim.cmd("%s/" .. input)
  end)
end, { desc = "Substitute in buffer" })

map("n", prefix .. "rc", function()
  vim.ui.input({ prompt = "cfdo substitute: " }, function(input)
    if not input or input == "" then
      vim.notify("No pattern entered.", vim.log.levels.WARN)
      return
    end
    vim.cmd("cfdo %s/" .. input .. " | update")
  end)
end, { desc = "Substitute in quickfix files" })

map("n", prefix .. "rd", function()
  vim.ui.input({ prompt = "cdo substitute: " }, function(input)
    if not input or input == "" then
      vim.notify("No pattern entered.", vim.log.levels.WARN)
      return
    end
    vim.cmd("cdo s/" .. input .. " | update")
  end)
end, { desc = "Substitute in quickfix lines" })

map("n", prefix .. "ra", function()
  vim.ui.input({ prompt = "argdo substitute: " }, function(input)
    if not input or input == "" then
      vim.notify("No pattern entered.", vim.log.levels.WARN)
      return
    end
    vim.cmd("argdo %s/" .. input .. " | update")
  end)
end, { desc = "Substitute in arg files" })

map("n", prefix .. "rm", function()
  vim.ui.input({ prompt = "Remove pattern (regex): " }, function(input)
    if not input or input == "" then
      vim.notify("No pattern entered.", vim.log.levels.WARN)
      return
    end
    vim.cmd("%s/" .. input .. "//g")
  end)
end, { desc = "Remove pattern from buffer" })

map("n", prefix .. "r^", "<Cmd>%s/\r//g<CR>", { desc = "Remove ^M (line endings)" })

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
end, { desc = "Remove -/+ from lines" })

-- ================================ EDITING ================================
-- je = Edit operations

map("n", prefix .. "bw", function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for i, line in ipairs(lines) do
    local indent = line:match("^(%s*)") or ""
    local content = line:sub(#indent + 1)
    content = content:gsub("%s+", "")
    lines[i] = indent .. content
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.notify("Removed inner whitespace.", vim.log.levels.INFO)
end, { desc = "Remove inner whitespace" })

local function toggle_indent_mode()
  if vim.bo.expandtab then
    local ts = vim.bo.tabstop
    vim.bo.expandtab = false
    vim.cmd("retab!")
    vim.notify("Converted to tabs (ts=" .. ts .. ")", vim.log.levels.INFO)
  else
    local ts = vim.bo.tabstop
    vim.bo.expandtab = true
    vim.cmd("retab")
    vim.notify("Converted to spaces (ts=" .. ts .. ")", vim.log.levels.INFO)
  end
end

map("n", prefix .. "bt", function()
  local ts = vim.bo.tabstop
  vim.bo.expandtab = false
  vim.cmd("retab!")
  vim.notify("Converted to tabs (ts=" .. ts .. ")", vim.log.levels.INFO)
end, { desc = "Convert to tabs" })

map("n", prefix .. "bs", function()
  local ts = vim.bo.tabstop
  vim.bo.expandtab = true
  vim.cmd("retab")
  vim.notify("Converted to spaces (ts=" .. ts .. ")", vim.log.levels.INFO)
end, { desc = "Convert to spaces" })

map("n", prefix .. "bi", toggle_indent_mode, { desc = "Toggle tabs/spaces" })

-- ================================ TERMINAL / SHELL ================================
-- jc = Terminal/Command

map("n", prefix .. "c1", function()
  vim.ui.input({ prompt = "Shell command: " }, function(cmd)
    if not cmd or cmd == "" then
      vim.notify("No command entered.", vim.log.levels.WARN)
      return
    end
    vim.notify("Running: " .. cmd, vim.log.levels.INFO)
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
    vim.notify("No .sh files in " .. script_dir, vim.log.levels.WARN)
    return
  end
  vim.ui.select(files, { prompt = "Select script:" }, function(choice)
    if not choice then
      return
    end
    local script_path = script_dir .. choice
    vim.notify("Running: " .. script_path, vim.log.levels.INFO)
    vim.cmd("terminal bash '" .. script_path .. "'")
  end)
end, { desc = "Run script from ~/Desktop/scripts" })

-- ================================ UPLOAD / S3 ================================
-- ju = Upload

map("n", prefix .. "u5", send_file_to_s3, { desc = "Upload any file to S3" })
map("n", prefix .. "u6", select_file_to_move_to_s3, { desc = "Upload from ~/Downloads/screenshots" })
map("n", prefix .. "u7", copy_to_s3, { desc = "Upload current buffer" })

map("n", prefix .. "u8", function()
  if vim.fn.executable("ffmpeg") ~= 1 then
    vim.notify("ffmpeg not found.", vim.log.levels.ERROR)
    return
  end
  local mov = vim.fn.input("Input .mov file: ", "", "file")
  if mov == "" or vim.fn.filereadable(mov) == 0 then
    vim.notify("Invalid .mov file.", vim.log.levels.ERROR)
    return
  end
  local audio = vim.fn.input("Input audio file: ", "", "file")
  if audio == "" or vim.fn.filereadable(audio) == 0 then
    vim.notify("Invalid audio file.", vim.log.levels.ERROR)
    return
  end
  local out = mov:gsub("%.mov$", "") .. "-yt.mp4"
  local args = {
    "-y",
    "-i",
    mov,
    "-stream_loop",
    "-1",
    "-i",
    audio,
    "-map",
    "0:v:0",
    "-map",
    "1:a:0",
    "-c:v",
    "libx264",
    "-pix_fmt",
    "yuv420p",
    "-profile:v",
    "high",
    "-level",
    "4.1",
    "-preset",
    "medium",
    "-crf",
    "20",
    "-c:a",
    "aac",
    "-b:a",
    "192k",
    "-ar",
    "48000",
    "-movflags",
    "+faststart",
    "-shortest",
    out,
  }
  vim.notify("Converting: " .. out, vim.log.levels.INFO)
  vim.loop.spawn("ffmpeg", { args = args, stdio = { nil, nil, nil } }, function(code, _)
    vim.schedule(function()
      if code == 0 and vim.fn.filereadable(out) == 1 then
        vim.notify("Done: " .. out, vim.log.levels.INFO)
        vim.fn.setreg("+", out)
      else
        vim.notify("ffmpeg failed", vim.log.levels.ERROR)
      end
    end)
  end)
end, { desc = "Convert MOV+Audio → YouTube MP4" })

-- ================================ PLUGINS ================================
-- jl = LazyVim / Plugin manager

map("n", prefix .. "ll", "<cmd>Lazy<CR>", { desc = "Open Lazy" })
map("n", prefix .. "ls", "<cmd>Lazy sync<CR>", { desc = "Lazy sync" })
map("n", prefix .. "le", "<cmd>LazyExtras<CR>", { desc = "Lazy extras" })
map("n", prefix .. "lm", "<cmd>Mason<CR>", { desc = "Mason (LSP)" })
map("n", prefix .. "li", "<cmd>LspInfo<CR>", { desc = "LSP info" })
map("n", prefix .. "lh", "<Cmd>checkhealth<CR>", { desc = "Check health" })
map("n", prefix .. "lu", "<cmd>UndotreeToggle<CR>", { desc = "Toggle Undotree" })

-- ================================ GIT ================================
-- jg = Git

map("n", prefix .. "go", function()
  vim.cmd("tabnew")
  local files = vim.fn.systemlist("git diff --name-only HEAD")
  for _, f in ipairs(files) do
    if vim.fn.filereadable(f) == 1 then
      vim.cmd("edit " .. vim.fn.fnameescape(f))
      vim.cmd("bprevious")
    end
  end
end, { desc = "Open modified files" })

-- ================================ SNIPPETS ================================
-- jn = Snippets

map({ "n", "x" }, prefix .. "na", function()
  require("scissors").addNewSnippet()
end, { desc = "Add new snippet" })

map("n", prefix .. "ne", function()
  require("scissors").editSnippet()
end, { desc = "Edit snippet" })


map("n", prefix .. "de", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line_nr = cursor[1]
  local diagnostics = vim.diagnostic.get(bufnr)
  local errors = {}
  for _, d in ipairs(diagnostics) do
    if d.lnum + 1 == line_nr then
      table.insert(errors, d)
    end
  end
  if #errors == 0 and vim.treesitter then
    local ts_utils = require("nvim-treesitter.ts_utils")
    local node = ts_utils.get_node_at_cursor()
    while node do
      local typ = node:type()
      if typ:match("function") or typ:match("class") then
        local sr, _, er, _ = node:range()
        for _, d in ipairs(diagnostics) do
          if d.lnum >= sr and d.lnum <= er then
            table.insert(errors, d)
          end
        end
        break
      end
      node = node:parent()
    end
  end
  if #errors == 0 then
    vim.notify("No diagnostics on this line.", vim.log.levels.INFO)
    return
  end
  local msgs = {}
  for _, d in ipairs(errors) do
    table.insert(msgs, string.format("[%s] %s (line %d)", vim.diagnostic.severity[d.severity], d.message, d.lnum + 1))
  end
  vim.fn.setreg("+", table.concat(msgs, "\n"))
  vim.notify("Copied diagnostics.", vim.log.levels.INFO)
end, { desc = "Copy LSP diagnostics" })

-- ================================ EXTERNAL APPS ================================
-- ja = Apps

map("n", "<Leader>jaa", function()
  local dirs = { "/Applications", "~/Applications" }
  local items = {}
  for _, d in ipairs(dirs) do
    local ed = vim.fn.expand(d)
    local p = io.popen('ls -1 "' .. ed .. '"')
    if p then
      for f in p:lines() do
        if f:match("%.app$") then
          table.insert(items, ed .. "/" .. f)
        end
      end
      p:close()
    end
  end
  local home = vim.fn.expand("~")
  local hp = io.popen('ls -1 "' .. home .. '"')
  if hp then
    for f in hp:lines() do
      local full = home .. "/" .. f
      local stat = vim.loop.fs_stat(full)
      if stat and stat.type == "directory" and not f:match("^%.") then
        table.insert(items, full)
      end
    end
    hp:close()
  end
  if #items == 0 then
    vim.notify("No apps found", vim.log.levels.WARN)
    return
  end
  table.sort(items, function(a, b)
    return a:lower() < b:lower()
  end)
  local fzf = require("fzf-lua")
  fzf.fzf_exec(items, {
    prompt = "Open App/Dir> ",
    actions = {
      ["default"] = function(sel)
        if not sel or #sel == 0 then
          return
        end
        local full = sel[1]
        if full:match("%.app$") then
          local name = full:match("([^/]+)%.app$")
          vim.fn.system({ "open", "-a", name })
          vim.notify("Opened: " .. name, vim.log.levels.INFO)
        else
          vim.fn.system({ "open", full })
          vim.notify("Opened: " .. full, vim.log.levels.INFO)
        end
      end,
    },
  })
end, { desc = "Open app (spotlight-like)" })

map("n", prefix .. "av", function()
  local cwd = vim.fn.getcwd()
  vim.fn.system({ "code", cwd })
  vim.notify("Opened in VS Code: " .. cwd, vim.log.levels.INFO)
end, { desc = "Open in VS Code" })

map("n", prefix .. "ap", function()
  local file = vim.fn.expand("%:p")
  if vim.fn.has("macunix") == 1 then
    vim.fn.system({ "open", "-a", "TextEdit", file })
    vim.notify("Opened in TextEdit", vim.log.levels.INFO)
  elseif vim.fn.has("win32") == 1 then
    vim.fn.system({ "powershell", "-Command", "Start-Process", file, "-Verb", "Print" })
    vim.notify("Print dialog opened", vim.log.levels.INFO)
  else
    vim.notify("Not supported on this OS", vim.log.levels.ERROR)
  end
end, { desc = "Print / Open in editor" })

-- ================================ MISC ================================
-- jm = Misc
map("n", prefix .. "C", "<Cmd>%y<CR>", { desc = "Yank all lines" })
map("n", prefix .. "X", "<Cmd>%d<CR>", { desc = "Delete all lines" })
map("n", prefix .. "S", "ggVG", { desc = "Select all" })
map("n", prefix .. "P", "ggVGp", { desc = "Select all and paste" })
map("n", prefix .. "W", "<cmd>wa<CR>", { desc = "Save all buffers" })
