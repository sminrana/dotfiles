local M = {}

function M.random_filename_with_ext(path)
  local ext = path:match("^.+(%..+)$") or ""
  local ts = os.date("%Y%m%d%H%M%S")
  local syllables = { "ka", "lo", "mi", "ra", "zu", "ve", "xo", "ni", "sa", "tu", "po", "qi", "wa", "jo", "fi" }
  local mystic = ""
  for _ = 1, 2 do
    local idx = math.random(#syllables)
    mystic = mystic .. syllables[idx]
  end
  return ts .. mystic .. ext
end

function M.get_globs_for_filetype(ft)
  local mapping = {
    typescript = { "*.ts", "*.tsx", "*.svelte" },
    typescriptreact = { "*.ts", "*.tsx", "*.svelte" },
    php = { "*.php", "*.blade.php", "*.ctp" },
    python = { "*.py" },
    javascript = { "*.js", "*.jsx", "*.svelte" },
  }
  return mapping[ft] or { "*" }
end

function M.wrap_selection(prefix, suffix)
  local mode = vim.api.nvim_get_mode().mode
  if mode == "v" or mode == "V" or mode == "\22" then
    local s = vim.fn.getpos("v")
    local e = vim.fn.getpos(".")
    if s[2] > e[2] or (s[2] == e[2] and s[3] > e[3]) then
      s, e = e, s
    end
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
    vim.schedule(function()
      local lines = vim.api.nvim_buf_get_text(0, s[2] - 1, s[3] - 1, e[2] - 1, e[3], {})
      if #lines > 0 then
        lines[1] = prefix .. lines[1]
        lines[#lines] = lines[#lines] .. suffix
        vim.api.nvim_buf_set_text(0, s[2] - 1, s[3] - 1, e[2] - 1, e[3], lines)
      end
    end)
  else
    local line = vim.api.nvim_get_current_line()
    if not (vim.startswith(line, prefix) and vim.endswith(line, suffix)) then
      vim.api.nvim_set_current_line(prefix .. line .. suffix)
    end
  end
end

return M
