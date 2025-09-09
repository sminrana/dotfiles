local prefix = "<leader>j"

local function file_diff()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("fzf-lua not installed!", vim.log.levels.ERROR)
    return
  end
  
  local first_file = nil

  -- buffer config helper
  local function setup_diff_buffer(buf)
    vim.api.nvim_buf_set_option(buf, 'diff', true)
    vim.api.nvim_buf_set_option(buf, 'list', true)
    vim.api.nvim_buf_set_option(buf, 'cursorline', true)
    vim.api.nvim_buf_set_option(buf, 'number', true)
    vim.api.nvim_buf_set_option(buf, 'relativenumber', false)
    vim.api.nvim_buf_set_option(buf, 'filetype', vim.bo.filetype)
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_option(buf, 'buftype', '')
    vim.api.nvim_buf_set_option(buf, 'listchars', "tab:»·,trail:·,extends:>,precedes:<,nbsp:␣")
    vim.api.nvim_buf_set_option(buf, 'fillchars', "diff: ") -- no diagonal slashes
    vim.api.nvim_buf_set_option(buf, 'foldmethod', 'diff') -- fold unchanged blocks
  end

  local function open_diff(abs_first, abs_second)
    vim.schedule(function()
      local success, err = pcall(function()
        -- open first file in new tab
        vim.cmd("tabnew " .. vim.fn.fnameescape(abs_first))
        local buf1 = vim.api.nvim_get_current_buf()
        vim.cmd("file " .. vim.fn.fnameescape(abs_first))
        setup_diff_buffer(buf1)

        -- open second file in vertical diff split
        vim.cmd("vert diffsplit " .. vim.fn.fnameescape(abs_second))
        local buf2 = vim.api.nvim_get_current_buf()
        vim.cmd("file " .. vim.fn.fnameescape(abs_second))
        setup_diff_buffer(buf2)

        -- Equalize split sizes
        vim.cmd("wincmd =")

        -- Enable proper diff mode for both
        vim.cmd("windo diffthis")

        -- Highlight whitespace
        vim.cmd("highlight! SpecialKey guifg=#555555 ctermfg=240")
        vim.cmd("highlight! NonText guifg=#555555 ctermfg=240")
        vim.cmd("highlight! ExtraWhitespace guibg=#553333 ctermbg=52")
        vim.fn.matchadd("ExtraWhitespace", "\\s\\+$")

        -- Improved diff highlighting for better visibility
        vim.cmd("highlight DiffAdd    guifg=#00ff5f guibg=NONE gui=bold,underline ctermfg=46 ctermbg=NONE cterm=bold,underline")
        vim.cmd("highlight DiffChange guifg=#ff00ff guibg=NONE gui=bold,italic    ctermfg=201 ctermbg=NONE cterm=bold,italic")
        vim.cmd("highlight DiffDelete guifg=#ff005f guibg=NONE gui=bold           ctermfg=197 ctermbg=NONE cterm=bold")
        vim.cmd("highlight DiffText   guifg=#00dfff guibg=NONE gui=bold,italic    ctermfg=45  ctermbg=NONE cterm=bold,italic")

        -- Sync scrolling in Lua
        vim.api.nvim_create_augroup("DiffSyncScroll", { clear = true })
        vim.api.nvim_create_autocmd("WinScrolled", {
          group = "DiffSyncScroll",
          callback = function()
            if vim.wo.diff then
              vim.cmd("windo diffupdate")
            end
          end,
        })

        -- disable diagnostics initially
        vim.diagnostic.disable(buf1)
        vim.diagnostic.disable(buf2)

        -- toggle diagnostics function
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

        -- keymaps (scoped to buffers in this tab)
        local opts = { buffer = true }
        vim.keymap.set('n', prefix .. 'td', toggle_diff_diagnostics, vim.tbl_extend("force", opts, { desc = 'Toggle diff diagnostics' }))
        vim.keymap.set('n', prefix .. 'dg', ':diffget<CR>', vim.tbl_extend("force", opts, { desc = "Diff get (pull from other side)" }))
        vim.keymap.set('n', prefix .. 'dp', ':diffput<CR>', vim.tbl_extend("force", opts, { desc = "Diff put (push to other side)" }))

        vim.notify("Diff opened (diagnostics disabled). Use " .. prefix .. "td to toggle.", vim.log.levels.INFO)
      end)

      if not success then
        vim.notify("Error: " .. tostring(err), vim.log.levels.ERROR)
      end
    end)
  end

  -- pick first file
  fzf.files({
    prompt = "Select first file to diff: ",
    file_icons = false,
    git_icons = false,
    actions = {
      ["default"] = function(selected)
        if not selected or #selected == 0 then
          vim.notify("No first file selected", vim.log.levels.WARN)
          return
        end
        first_file = vim.fn.fnamemodify(selected[1], ":p")
        vim.notify("First file: " .. first_file, vim.log.levels.INFO)

        -- pick second file
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
              local second_file = vim.fn.fnamemodify(selected2[1], ":p")
              vim.notify("Second file: " .. second_file, vim.log.levels.INFO)
              open_diff(first_file, second_file)
            end,
          },
        })
      end,
    },
  })
end

vim.api.nvim_create_user_command("FileDiff", file_diff, {})


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

      -- Use vim.ui.select, but for large lists, prefer fzf-lua if available
      local function select_pair(callback)
        local ok, fzf = pcall(require, "fzf-lua")
        if ok then
          fzf.fzf_exec(items, {
        prompt = "Select file pair to diff: ",
        actions = {
          ["default"] = function(selected)
            if not selected or #selected == 0 then return end
            -- Find index in items
            local idx
            for i, v in ipairs(items) do
          if v == selected[1] then idx = i break end
            end
            if not idx then return end
            callback(diffs[idx], idx)
          end,
        },
          })
        else
          vim.ui.select(items, { prompt = "Select file pair to diff:" }, function(choice, idx)
        if not choice or not idx then return end
        callback(diffs[idx], idx)
          end)
        end
      end

      select_pair(function(pair, idx)
        if not pair then return end
        -- Open diff in new tab
        vim.cmd("tabnew " .. vim.fn.fnameescape(pair[1]))
        local buf1 = vim.api.nvim_get_current_buf()
        vim.cmd("vert diffsplit " .. vim.fn.fnameescape(pair[2]))
        local buf2 = vim.api.nvim_get_current_buf()

        -- Equalize split sizes
        vim.cmd("wincmd =")

        -- Enable proper diff mode for both
        vim.cmd("windo diffthis")

        -- Highlight whitespace
        vim.cmd("highlight! SpecialKey guifg=#555555 ctermfg=240")
        vim.cmd("highlight! NonText guifg=#555555 ctermfg=240")
        vim.cmd("highlight! ExtraWhitespace guibg=#553333 ctermbg=52")
        vim.fn.matchadd("ExtraWhitespace", "\\s\\+$")

        -- Improved diff highlighting for better visibility
        vim.cmd("highlight DiffAdd    guifg=#00ff5f guibg=NONE gui=bold,underline ctermfg=46 ctermbg=NONE cterm=bold,underline")
        vim.cmd("highlight DiffChange guifg=#ff00ff guibg=NONE gui=bold,italic    ctermfg=201 ctermbg=NONE cterm=bold,italic")
        vim.cmd("highlight DiffDelete guifg=#ff005f guibg=NONE gui=bold           ctermfg=197 ctermbg=NONE cterm=bold")
        vim.cmd("highlight DiffText   guifg=#00dfff guibg=NONE gui=bold,italic    ctermfg=45  ctermbg=NONE cterm=bold,italic")

        -- Sync scrolling in Lua
        vim.api.nvim_create_augroup("DiffSyncScroll", { clear = true })
        vim.api.nvim_create_autocmd("WinScrolled", {
          group = "DiffSyncScroll",
          callback = function()
            if vim.wo.diff then
              vim.cmd("windo diffupdate")
            end
          end,
        })

        -- disable diagnostics initially
        vim.diagnostic.disable(buf1)
        vim.diagnostic.disable(buf2)

        -- toggle diagnostics function
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

        -- keymaps (scoped to buffers in this tab)
        local opts = { buffer = true }
        vim.keymap.set('n', prefix .. 'td', toggle_diff_diagnostics, vim.tbl_extend("force", opts, { desc = 'Toggle diff diagnostics' }))
        vim.keymap.set('n', prefix .. 'dg', ':diffget<CR>', vim.tbl_extend("force", opts, { desc = "Diff get (pull from other side)" }))
        vim.keymap.set('n', prefix .. 'dp', ':diffput<CR>', vim.tbl_extend("force", opts, { desc = "Diff put (push to other side)" }))

        vim.notify("Diff opened for: " .. pair[1] .. " <-> " .. pair[2], vim.log.levels.INFO)
      end)
    end)
  end)
end


vim.api.nvim_create_user_command("FolderDiff", folder_diff, {})