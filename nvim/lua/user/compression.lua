local M = {}

-- Local keymap utility (copied from your config)
local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  vim.keymap.set(mode, lhs, rhs, opts)
end

local prefix = "<leader>j"

function M.gzip_sql_file()
  local default = ""
  local buf_path = vim.fn.expand("%:p")
  if buf_path:match("%.sql$") then
    default = buf_path
  end
  vim.ui.input({ prompt = "SQL file to gzip: ", default = default }, function(input)
    if not input or input == "" then
      vim.notify("No file specified.", vim.log.levels.WARN)
      return
    end
    if not input:match("%.sql$") then
      vim.notify("File must have .sql extension.", vim.log.levels.ERROR)
      return
    end
    if vim.fn.filereadable(input) == 0 then
      vim.notify("File does not exist: " .. input, vim.log.levels.ERROR)
      return
    end
    local gzfile = input .. ".gz"
    local cmd = { "gzip", "-c", input }
    local fd = assert(vim.loop.fs_open(gzfile, "w", 420)) -- 0644
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
          vim.notify("Exported gzipped SQL: " .. gzfile, vim.log.levels.INFO)
        else
          vim.notify("Failed to gzip file (exit " .. code .. ")", vim.log.levels.ERROR)
        end
      end)
    end)
    stdout:read_start(function(err, data)
      assert(not err, err)
      if data then
        vim.loop.fs_write(fd, data)
      end
    end)
    vim.notify("Gzipping in background: " .. input, vim.log.levels.INFO)
  end)
end

-- Set keymap for this module
map("n", prefix .. "g1", M.gzip_sql_file, { desc = "Export .sql file as .sql.gz (gzip, async)" })

return M
