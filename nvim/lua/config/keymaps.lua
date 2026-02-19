-- Define a prefix for personal keymaps
local prefix = "<leader>j"

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

-- General keymaps
map("n", "q", "<nop>", { noremap = true })
map("n", "Q", "q", { noremap = true, desc = "Record macro" })
map("n", "<M-q>", "Q", { noremap = true, desc = "Replay last register" })

map("n", "gO", "<Cmd>call append(line('.') - 1, repeat([''], v:count1))<CR>")
map("n", "go", "<Cmd>call append(line('.'), repeat([''], v:count1))<CR>")
map("n", "<leader>e", "<Cmd>Neotree reveal float<CR>")
map("n", "<leader>be", "<Cmd>Neotree buffers float<CR>")
map("n", "<leader>F", "<Cmd>FzfLua<CR>")

-- ===============================Personal keymaps===================================

vim.keymap.set("n", prefix .. "md", function()
  local date = os.date("%b %d, %Y %H:%M:%S %Z")
  vim.api.nvim_put({ date }, "c", true, true)
end, { desc = "Add date here" })

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
-- =========================================== Markdown & TODO End ====================================

-- FZF keymaps
map("n", prefix .. "fa", function()
  require("fzf-lua").live_grep({ cwd = "~/app/" })
end, { desc = "Live Grep in App Files" })

map("n", prefix .. "fw", function()
  require("fzf-lua").live_grep({ cwd = "~/web/" })
end, { desc = "Live Grep in Web Files" })

map("n", prefix .. "fx", function()
  require("fzf-lua").live_grep({ cwd = "~/Desktop/obs-v1/" })
end, { desc = "Live Grep in Notes Files" })

map("n", prefix .. "fs", function()
  require("fzf-lua").live_grep({ cwd = "~/Desktop/snippets/" })
end, { desc = "Live Grep in Snippets Files" })

map("n", prefix .. "ba", function()
  require("fzf-lua").blines()
end, { desc = "Live Grep in Current Buffer" })

map("n", prefix .. "f7", copy_to_s3, { desc = "Upload current buffer to S3" })
map("n", prefix .. "f6", select_file_to_move_to_s3, { desc = "Upload file from /scr to S3" })
map("n", prefix .. "f5", send_file_to_s3, { desc = "Choose any file to S3" })

-- Convert .mov to YouTube-ready .mp4 with external audio
map("n", prefix .. "f8", function()
  if vim.fn.executable("ffmpeg") ~= 1 then
    vim.notify("ffmpeg is not installed or not in PATH.", vim.log.levels.ERROR)
    return
  end
  local mov = vim.fn.input("Input .mov file: ", "", "file")
  if mov == "" or vim.fn.filereadable(mov) == 0 then
    vim.notify("Invalid .mov file: " .. mov, vim.log.levels.ERROR)
    return
  end
  local audio = vim.fn.input("Input audio file (wav/mp3/m4a): ", "", "file")
  if audio == "" or vim.fn.filereadable(audio) == 0 then
    vim.notify("Invalid audio file: " .. audio, vim.log.levels.ERROR)
    return
  end
  local out = mov:gsub("%.mov$", "") .. "-yt.mp4"
  local args = {
    "-y",
    "-i",
    mov,
    "-stream_loop",
    "-1", -- loop audio if shorter
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
    "-shortest", -- trim when audio is longer
    out,
  }
  vim.notify("Converting to YouTube-ready MP4: " .. out, vim.log.levels.INFO)
  vim.loop.spawn("ffmpeg", { args = args, stdio = { nil, nil, nil } }, function(code, signal)
    vim.schedule(function()
      if code == 0 and vim.fn.filereadable(out) == 1 then
        vim.notify("Conversion complete: " .. out, vim.log.levels.INFO)
        vim.fn.setreg("+", out)
      else
        vim.notify("ffmpeg failed (exit " .. code .. ")", vim.log.levels.ERROR)
      end
    end)
  end)
end, { desc = "Convert MOV→MP4 + external audio (YouTube)" })

local personal_keymaps = {
  { "C", "<Cmd>%y<CR>", "Copy All" },
  { "X", "<Cmd>%d<CR>", "Cut All" },
  { "S", "ggVG", "Select All" },
  { "P", "ggVGp", "Select All and Paste" },
  { "D", "<Cmd>tabe ~/Desktop/obs-v1/goals/daily.md<CR>" },
  { "N", "<Cmd>tabe ~/Desktop/obs-v1/notes.md<CR>" },
  { "U", "<cmd>UndotreeToggle<cr>", "Toggle Undotree" },
  { "W", "<cmd>wa<cr>", "Save all buffers" },
  {
    "f1",
    function()
      local path = vim.fn.expand("%:p")
      vim.fn.setreg("+", path)
      vim.notify("Copied absolute path: " .. path, vim.log.levels.INFO)
    end,
    "Copy file absolute path",
  },
  {
    "f2",
    function()
      local path = vim.fn.expand("%:.")
      vim.fn.setreg("+", path)
      vim.notify("Copied relative path: " .. path, vim.log.levels.INFO)
    end,
    "Copy file relative path",
  },
  {
    "f3",
    function()
      local path = vim.fn.expand("%:t")
      vim.fn.setreg("+", path)
      vim.notify("Copied file name: " .. path, vim.log.levels.INFO)
    end,
    "Copy file name",
  },
  {
    "bo",
    function()
      local path = vim.fn.expand("%:p")
      if path == "" or vim.fn.filereadable(path) == 0 then
        vim.notify("Current buffer is not a file.", vim.log.levels.WARN)
        return
      end
      vim.fn.system({ "open", path })
      vim.notify("Opened in default app: " .. path, vim.log.levels.INFO)
    end,
    "Open buffer in default app (macOS)",
  },
  { "lh", "<Cmd>checkhealth<CR>", "Check health" },
  { "ll", "<cmd>Lazy<CR>", "Plugin Manager - [LazyVim]" },
  { "lm", "<cmd>Mason<CR>", "Package Manager - [Mason]" },
  { "le", "<cmd>LazyExtras<CR>", "Extras Manager - [LazyVim]" },
  { "li", "<cmd>LspInfo<CR>", "Lsp Info" },
  { "ls", "<cmd>Lazy sync<CR>", "Lazy sync" },
{
  "bp",
  function()
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
    vim.notify("Copied " .. #paths .. " buffer absolute paths.", vim.log.levels.INFO)
  end,
  "Copy all open buffer absolute paths",
},
}

table.insert(personal_keymaps, {
  "rw",
  function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    for i, line in ipairs(lines) do
      local indent = line:match("^(%s*)") or ""
      local content = line:sub(#indent + 1)
      content = content:gsub("%s+", "")
      lines[i] = indent .. content
    end
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.notify("All inner whitespace removed from buffer (indentation preserved).", vim.log.levels.INFO)
  end,
  "Remove all inner whitespace from buffer (preserve indentation)",
})

for _, keymap in ipairs(personal_keymaps) do
  map("n", prefix .. keymap[1], keymap[2], { noremap = true, silent = true, desc = keymap[3] })
end

-- Open File
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
end, { desc = "Open file in ~ (fzf)" })

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

map("n", prefix .. "Q", "<Cmd>qa<CR>", { noremap = true, silent = true, desc = "Quit all and exit Vim" })

-- Open Search and Replace
map("n", prefix .. "R", function()
  vim.ui.input({ prompt = "Substitute pattern (e.g. %s/foo/bar/g): " }, function(input)
    if not input or input == "" then
      vim.notify("No pattern entered.", vim.log.levels.WARN)
      return
    end
    vim.cmd("%s/" .. input)
  end)
end, { desc = "Start :%s substitution" })

map("n", prefix .. "rc", function()
  vim.ui.input({ prompt = "cfdo substitute pattern (e.g. cfdo %s/foo/bar/g | update): " }, function(input)
    if not input or input == "" then
      vim.notify("No pattern entered.", vim.log.levels.WARN)
      return
    end
    vim.cmd("cfdo %s/" .. input .. " | update")
  end)
end, { desc = "cfdo :%s substitution (all quickfix files)" })

map("n", prefix .. "rd", function()
  vim.ui.input({ prompt = "cdo substitute pattern (e.g. cdo s/foo/bar/g | update): " }, function(input)
    if not input or input == "" then
      vim.notify("No pattern entered.", vim.log.levels.WARN)
      return
    end
    vim.cmd("cdo s/" .. input .. " | update")
  end)
end, { desc = "cdo :%s substitution (all quickfix matches/lines)" })

map("n", prefix .. "ra", function()
  vim.ui.input({ prompt = "argdo substitute pattern (e.g. argdo %s/foo/bar/g | update): " }, function(input)
    if not input or input == "" then
      vim.notify("No pattern entered.", vim.log.levels.WARN)
      return
    end
    vim.cmd("argdo %s/" .. input .. " | update")
  end)
end, { desc = "argdo :%s substitution" })

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

table.insert(personal_keymaps, {
  "rw",
  function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    for i, line in ipairs(lines) do
      local indent = line:match("^(%s*)") or ""
      local content = line:sub(#indent + 1)
      content = content:gsub("%s+", "")
      lines[i] = indent .. content
    end
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.notify("All inner whitespace removed from buffer (indentation preserved).", vim.log.levels.INFO)
  end,
  "Remove all inner whitespace from buffer (preserve indentation)",
})

-- Copy LSP error
map("n", prefix .. "E", function()
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
      local type = node:type()
      if type:match("function") or type:match("class") then
        local start_row, _, end_row, _ = node:range()
        for _, d in ipairs(diagnostics) do
          if d.lnum >= start_row and d.lnum <= end_row then
            table.insert(errors, d)
          end
        end
        break
      end
      node = node:parent()
    end
  end

  if #errors == 0 then
    vim.notify("No LSP errors found on this line or code block.", vim.log.levels.INFO)
    return
  end

  local msgs = {}
  for _, d in ipairs(errors) do
    table.insert(msgs, string.format("[%s] %s (line %d)", vim.diagnostic.severity[d.severity], d.message, d.lnum + 1))
  end
  local text = table.concat(msgs, "\n")
  vim.fn.setreg("+", text)
  vim.notify("Copied LSP error(s) to clipboard.", vim.log.levels.INFO)
end, { desc = "Copy LSP error(s) on line or code block" })

-- Snippet keymaps
map({ "n", "x" }, prefix .. "sa", function()
  require("scissors").addNewSnippet()
end, { desc = "Snippet: Add" })

map("n", prefix .. "se", function()
  require("scissors").editSnippet()
end, { desc = "Snippet: Edit" })

vim.keymap.set("n", prefix .. "si", function()
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
end, { noremap = true, silent = true, desc = "Input search term for project files" })

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

vim.keymap.set("n", "<leader>ac", "<cmd>CodeCompanionActions<CR>", { desc = "CodeCompanionActions" })

vim.keymap.set("n", prefix .. "go", function()
  vim.cmd("tabnew")
  local files = vim.fn.systemlist("git diff --name-only HEAD")
  for _, f in ipairs(files) do
    if vim.fn.filereadable(f) == 1 then
      vim.cmd("edit " .. vim.fn.fnameescape(f))
      vim.cmd("bprevious")
    end
  end
end, { desc = "Open modified git files in new tabs" })

local function tabs_to_spaces()
  local ts = vim.bo.tabstop
  vim.bo.expandtab = true
  vim.cmd("retab")
  vim.notify(string.format("Converted tabs to spaces (ts=%d).", ts), vim.log.levels.INFO)
end

local function spaces_to_tabs()
  local ts = vim.bo.tabstop
  vim.bo.expandtab = false
  vim.cmd("retab!")
  vim.notify(string.format("Converted spaces to tabs (ts=%d).", ts), vim.log.levels.INFO)
end

local function toggle_indent_mode()
  if vim.bo.expandtab then
    spaces_to_tabs()
  else
    tabs_to_spaces()
  end
end

map("n", prefix .. "b<tab>", toggle_indent_mode, { desc = "Toggle tabs/spaces and retab" })
map("n", prefix .. "bs", tabs_to_spaces, { desc = "Convert tabs → spaces (retab)" })
map("n", prefix .. "bt", spaces_to_tabs, { desc = "Convert spaces → tabs (retab!)" })

map("n", prefix .. "bf", function()
  local path = vim.fn.expand("%:p")
  if path == "" or vim.fn.filereadable(path) == 0 then
    vim.notify("Current buffer is not a file.", vim.log.levels.WARN)
    return
  end
  vim.fn.system({ "open", "-R", path })
  vim.notify("Revealed in Finder: " .. path, vim.log.levels.INFO)
end, { desc = "Reveal buffer in Finder (macOS)" })

local function printfile()
  local file = vim.fn.expand("%:p")
  if vim.fn.has("macunix") == 1 then
    vim.fn.system({ "open", "-a", "TextEdit", file })
    vim.notify("Opened in TextEdit. Use File → Print to save as PDF.", vim.log.levels.INFO)
  elseif vim.fn.has("unix") == 1 then
    vim.notify("Print dialog not supported on Linux from Neovim.", vim.log.levels.ERROR)
  elseif vim.fn.has("win32") == 1 then
    vim.fn.system({ "powershell", "-Command", "Start-Process", file, "-Verb", "Print" })
    vim.notify("Opened print dialog (Windows).", vim.log.levels.INFO)
  else
    vim.notify("Printing not supported on this OS", vim.log.levels.ERROR)
  end
end

map("n", prefix .. "p", printfile, { desc = "Print current buffer" })

local function spotlight_app()
  local dirs = { "/Applications", "~/Applications" }
  local items = {}
  -- Collect applications
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
  -- Collect top-level home directories (non-hidden)
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
    vim.notify("No applications or folders found", vim.log.levels.WARN)
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
          if not name then
            vim.notify("Invalid app selection", vim.log.levels.ERROR)
            return
          end
          vim.fn.system({ "open", "-a", name })
          vim.notify("Opened app: " .. name, vim.log.levels.INFO)
        else
          vim.fn.system({ "open", full })
          vim.notify("Opened folder: " .. full, vim.log.levels.INFO)
        end
      end,
    },
  })
end

map("n", "<Leader>A", spotlight_app, { desc = "Open macOS Application (Spotlight-like)" })

-- Open root directory in VS Code
map("n", prefix .. "V", function()
  local cwd = vim.fn.getcwd()
  vim.fn.system({ "code", cwd })
  vim.notify("Opened in VS Code: " .. cwd, vim.log.levels.INFO)
end, { desc = "Open root directory in VS Code" })
