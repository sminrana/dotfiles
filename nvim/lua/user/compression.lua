local M = {}

-- Local keymap utility (copied from your config)
local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  vim.keymap.set(mode, lhs, rhs, opts)
end

local prefix = "<leader>j"

function M.compress_file()
  local default = ""
  vim.ui.input({ prompt = "File to compress: ", default = default }, function(input)
    if not input or input == "" then
      vim.notify("No file specified.", vim.log.levels.WARN)
      return
    end
    input = vim.trim(input)
    input = vim.fn.fnamemodify(input, ":p")
    if vim.loop.fs_stat(input) == nil then
      vim.notify("File does not exist: " .. input, vim.log.levels.ERROR)
      return
    end

    local methods = {
      { name = "gzip", exe = "gzip", args = { "-c" }, ext = ".gz" },
      { name = "zstd", exe = "zstd", args = { "-c", "-T0" }, ext = ".zst" },
      { name = "xz", exe = "xz", args = { "-c" }, ext = ".xz" },
      { name = "bzip2", exe = "bzip2", args = { "-c" }, ext = ".bz2" },
    }

    -- Filter to installed methods
    local available = {}
    for _, m in ipairs(methods) do
      if vim.fn.executable(m.exe) == 1 then
        table.insert(available, m)
      end
    end
    if #available == 0 then
      vim.notify("No compression tools found (gzip/zstd/xz/bzip2)", vim.log.levels.ERROR)
      return
    end

    vim.ui.select(available, {
      prompt = "Choose compression method:",
      format_item = function(item)
        return item.name
      end,
    }, function(choice)
      if not choice then
        return
      end
      local target = input .. choice.ext
      local cmd = { choice.exe }
      for _, a in ipairs(choice.args) do
        table.insert(cmd, a)
      end
      table.insert(cmd, input)

      local fd = assert(vim.loop.fs_open(target, "w", 420)) -- 0644
      local stdout = vim.loop.new_pipe(false)
      local handle
      handle = vim.loop.spawn(cmd[1], {
        args = { unpack(cmd, 2) },
        stdio = { nil, stdout, nil },
      }, function(code, signal)
        vim.loop.fs_close(fd)
        stdout:close()
        handle:close()
        vim.schedule(function()
          if code == 0 then
            vim.notify("Compressed (" .. choice.name .. "): " .. target, vim.log.levels.INFO)
          else
            vim.notify("Compression failed (exit " .. code .. ")", vim.log.levels.ERROR)
          end
        end)
      end)
      stdout:read_start(function(err, data)
        assert(not err, err)
        if data then
          vim.loop.fs_write(fd, data)
        end
      end)
      vim.notify("Compressing in background (" .. choice.name .. "): " .. input, vim.log.levels.INFO)
    end)
  end)
end

-- Set keymap for this module
map("n", prefix .. "g1", M.compress_file, { desc = "Compress current/selected file (gzip/zstd/xz/bzip2)" })

return M
