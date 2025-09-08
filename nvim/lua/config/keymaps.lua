
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
    return { "*.ts", "*.tsx" }
  elseif ft == "php" then
    return { "*.php", "*.blade.php", "*.ctp" }
  elseif ft == "python" then
    return { "*.py" }
  elseif ft == "javascript" then
    return { "*.js", "*.jsx" }
  else
    return { "*" }
  end
end

local function file_diff()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("fzf-lua not installed!", vim.log.levels.ERROR)
    return
  end

  local first_file = nil

  local file_opts = {
    prompt = "Select first file to diff: ",
    file_icons = false,
    git_icons = false,
    actions = {
      ["default"] = function(selected)
        if not selected or #selected == 0 then
          vim.notify("No first file selected", vim.log.levels.WARN)
          return
        end
        
        first_file = selected[1]
        vim.notify("First file: " .. first_file, vim.log.levels.INFO)
        
        fzf.files({
          prompt = "Select second file to diff: ",
          file_icons = false,
          git_icons = false,
          actions = {
            ["default"] = function(selected2)
              if not selected2 or #selected2 == 0 then
                vim.notify("No second file selected", vim.log.levels.WARN)
                return
              end
              
              local second_file = selected2[1]
              vim.notify("Second file: " .. second_file, vim.log.levels.INFO)
              
              local abs_first = vim.fn.fnamemodify(first_file, ":p")
              local abs_second = vim.fn.fnamemodify(second_file, ":p")
              
              vim.schedule(function()
                local success, err = pcall(function()
                  vim.cmd("tabnew " .. vim.fn.fnameescape(abs_first))
                  vim.cmd("vert diffsplit " .. vim.fn.fnameescape(abs_second))
                  
                  -- Get both buffer numbers for this diff
                  local buf1 = vim.api.nvim_get_current_buf()
                  vim.cmd("wincmd w")
                  local buf2 = vim.api.nvim_get_current_buf()
                  vim.cmd("wincmd w")
                  
                  -- Disable diagnostics initially
                  vim.diagnostic.disable(buf1)
                  vim.diagnostic.disable(buf2)
                  
                  -- Create toggle function for this diff session
                  local diagnostics_enabled = false
                  local function toggle_diff_diagnostics()
                    if diagnostics_enabled then
                      vim.diagnostic.disable(buf1)
                      vim.diagnostic.disable(buf2)
                      diagnostics_enabled = false
                      vim.notify("Diff diagnostics disabled", vim.log.levels.INFO)
                    else
                      vim.diagnostic.enable(buf1)
                      vim.diagnostic.enable(buf2)
                      diagnostics_enabled = true
                      vim.notify("Diff diagnostics enabled", vim.log.levels.INFO)
                    end
                  end
                  
                  -- Add keybinding to toggle diagnostics (only in this tab)
                  vim.keymap.set('n', prefix .. 'td', toggle_diff_diagnostics, { 
                    buffer = buf1, 
                    desc = 'Toggle diff diagnostics' 
                  })
                  vim.keymap.set('n', prefix .. 'td', toggle_diff_diagnostics, { 
                    buffer = buf2, 
                    desc = 'Toggle diff diagnostics' 
                  })
                  
                  vim.notify("Diff opened (diagnostics disabled). Use <leader>td to toggle.", vim.log.levels.INFO)
                end)
                
                if not success then
                  vim.notify("Error: " .. tostring(err), vim.log.levels.ERROR)
                end
              end)
            end,
          },
        })
      end,
    },
  }

  fzf.files(file_opts)
end

local function folder_diff()
  vim.ui.input({ prompt = "First folder: " }, function(first)
    if not first or first == "" then return end
    vim.ui.input({ prompt = "Second folder: " }, function(second)
      if not second or second == "" then return end

      -- Merge STDERR to STDOUT
      local cmd = "diff -qr " .. vim.fn.shellescape(first) .. " " .. vim.fn.shellescape(second) .. " 2>&1"
      local handle = io.popen(cmd)
      if not handle then
        vim.notify("Failed to run diff.", vim.log.levels.ERROR)
        return
      end

      local result = handle:read("*a")
      handle:close()

      local diffs = {}
      for line in result:gmatch("[^\r\n]+") do
        local f1, f2 = line:match("^Files%s+(.+)%s+and%s+(.+)%s+differ")
        if f1 and f2 then
          table.insert(diffs, { f1, f2 })
        end
      end

      if #diffs == 0 then
        vim.notify("No differing files found.", vim.log.levels.INFO)
        return
      end

      local items = {}
      for _, pair in ipairs(diffs) do
        table.insert(items, pair[1] .. " <-> " .. pair[2])
      end

      vim.ui.select(items, { prompt = "Select file pair to diff:" }, function(choice, idx)
        if not choice or not idx then return end
        local pair = diffs[idx]
        if not pair then return end
        -- Open diff in new tab
        vim.cmd("tabnew " .. vim.fn.fnameescape(pair[1]))
        vim.cmd("vert diffsplit " .. vim.fn.fnameescape(pair[2]))
        vim.notify("Diff opened for: " .. pair[1] .. " <-> " .. pair[2], vim.log.levels.INFO)
      end)
    end)
  end)
end




-- General keymaps
map("n", "q", "<nop>", { noremap = true })
map("n", "Q", "q", { noremap = true, desc = "Record macro" })
map("n", "<M-q>", "Q", { noremap = true, desc = "Replay last register" })

map("n", "gO", "<Cmd>call append(line('.') - 1, repeat([''], v:count1))<CR>")
map("n", "go", "<Cmd>call append(line('.'), repeat([''], v:count1))<CR>")
map("n", "<leader>e", "<Cmd>Neotree reveal float<CR>")
map("n", "<leader>be", "<Cmd>Neotree buffers float<CR>")

-- ===============================Personal keymaps===================================


-- ======================================== TODO
map("n", prefix .. "tx", function()
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

vim.keymap.set("n", prefix .. "te", function()
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

map("n", prefix .. "t0", function()
  local line = vim.api.nvim_get_current_line()
  if line:match("%[ %]") then
    line = line:gsub("%[ %]", "[x]", 1)
  elseif line:match("%[x%]") then
    line = line:gsub("%[x%]", "[ ]", 1)
  end
  vim.api.nvim_set_current_line(line)
end)

vim.keymap.set("n", prefix .. "td", ":Today<CR>", { desc = "Insert Today's Log" })
vim.keymap.set("n", prefix .. "tw", ":Week<CR>", { desc = "Insert This Week's Plan" })

-- end of todo


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

local personal_keymaps = {
  { "C", "<Cmd>%y<CR>", "Copy All" },
  { "X", "<Cmd>%d<CR>", "Cut All" },
  { "S", "ggVG", "Select All" },
  { "P", "ggVGp", "Select All and Paste" },
  { "G", "<Cmd>tabe ~/Desktop/obs-v1/goals/goals.md<CR>" },
  { "D", "<Cmd>tabe ~/Desktop/obs-v1/goals/daily.md<CR>" },
  { "N", "<Cmd>tabe ~/Desktop/obs-v1/notes.md<CR>" },
  { "U", "<cmd>UndotreeToggle<cr>", "Toggle Undotree" },
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

for _, keymap in ipairs(personal_keymaps) do
  map("n", prefix .. keymap[1], keymap[2], { noremap = true, silent = true, desc = keymap[3] })
end


-- Open File
map("n", prefix .. "fo", function()
  local fzf = require("fzf-lua")
  fzf.files({
    cwd = "~", -- Set search directory to home folder
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

vim.keymap.set("n", prefix .. "df", file_diff, { desc = "Diff two files (fzf)" })
vim.keymap.set("n", prefix .. "dd", folder_diff, { desc = "Diff two folders" })


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
    vim.cmd("cfdo %s/" .. input .. ' | update')
  end)
end, { desc = "cfdo :%s substitution (all quickfix files)" })

map("n", prefix .. "rd", function()
  vim.ui.input({ prompt = "cdo substitute pattern (e.g. cdo s/foo/bar/g | update): " }, function(input)
    if not input or input == "" then
      vim.notify("No pattern entered.", vim.log.levels.WARN)
      return
    end
    vim.cmd("cdo s/" .. input .. ' | update')
  end)
end, { desc = "cdo :%s substitution (all quickfix matches/lines)" })

map("n", prefix .. "ra", function()
  vim.ui.input({ prompt = "argdo substitute pattern (e.g. argdo %s/foo/bar/g | update): " }, function(input)
    if not input or input == "" then
      vim.notify("No pattern entered.", vim.log.levels.WARN)
      return
    end
    vim.cmd("argdo %s/" .. input .. ' | update')
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

-- Copy LSP error
map("n", prefix .. "E", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line_nr = cursor[1]
  local diagnostics = vim.diagnostic.get(bufnr)
  local errors = {}

  -- Find diagnostics on the current line
  for _, d in ipairs(diagnostics) do
    if d.lnum + 1 == line_nr then
      table.insert(errors, d)
    end
  end

  -- If no diagnostics on the line, try to get diagnostics in the current function or class
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



vim.keymap.set("n", prefix .. "sw", function()
  local ft = vim.bo.filetype
  local word = vim.fn.expand("<cword>")
  local globs = {}

  globs = get_globs_for_filetype(ft)

  -- Build the glob args for ripgrep
  local glob_args = ""
  for _, g in ipairs(globs) do
    glob_args = glob_args .. string.format(" --glob '%s'", g)
  end

  -- Use ripgrep as grepprg
  vim.o.grepprg = "rg --vimgrep"
  vim.cmd("silent grep! -w " .. vim.fn.shellescape(word) .. glob_args)
  vim.cmd("copen")
end, { noremap = true, silent = true, desc = "Search for word under cursor in project files" })

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
