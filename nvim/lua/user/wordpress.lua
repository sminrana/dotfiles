local M = {}

-- Local keymap utility (copied from your config)
local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  vim.keymap.set(mode, lhs, rhs, opts)
end

local function get_buffer_text()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return table.concat(lines, "\n")
end

local function to_html(text)
  local ft = vim.bo.filetype
  -- Prefer pandoc for markdown/text if present
  if (ft == "markdown" or ft == "md" or ft == "rmarkdown" or ft == "text") and vim.fn.executable("pandoc") == 1 then
    local tmp_in = vim.fn.tempname() .. ".md"
    local tmp_out = vim.fn.tempname() .. ".html"
    vim.fn.writefile(vim.split(text, "\n"), tmp_in)
    local cmd = { "pandoc", tmp_in, "-f", "markdown+raw_html", "-t", "html", "--wrap", "none", "-o", tmp_out }
    local ok = vim.fn.system(cmd)
    if vim.v.shell_error == 0 and vim.fn.filereadable(tmp_out) == 1 then
      local html = table.concat(vim.fn.readfile(tmp_out), "\n")
      vim.fn.delete(tmp_in)
      vim.fn.delete(tmp_out)
      return html
    else
      vim.notify("Pandoc conversion failed: " .. tostring(ok), vim.log.levels.WARN)
    end
  end
  -- Fallback: use buffer as-is wrapped in <pre>
  return "<pre>" .. vim.fn.escape(text, "<>") .. "</pre>"
end

local function require_wp_env()
  local url = vim.env.WP_URL
  local token = vim.env.WP_UPLOAD_TOKEN
  if not url or url == "" then
    return nil, "Missing env WP_URL"
  end
  if not token or token == "" then
    return nil, "Missing env WP_UPLOAD_TOKEN"
  end
  return { url = url, token = token }, nil
end

local function build_post_payload(html)
  local title = vim.fn.expand("%:t:r")
  title = title:gsub("^%s+", ""):gsub("%s+$", "")
  title = title:gsub("[_.%-]+", " ")
  title = title:gsub("%s+", " ")
  title = title:gsub("%.+$", "")
  title = title:gsub("^(.)", function(c)
    return string.upper(c)
  end)
  title = title:gsub("(%s)(%a)", function(space, c)
    return space .. string.upper(c)
  end)
  if title == "" then
    title = os.date("Post %Y-%m-%d %H:%M:%S")
  end
  -- Wrap in Gutenberg HTML block if not already a block
  if not html:match("<!%-%-%s*wp:") then
    html = "<!-- wp:html -->\n" .. html .. "\n<!-- /wp:html -->"
  end
  local payload = vim.fn.json_encode({
    token = vim.env.WP_UPLOAD_TOKEN,
    title = title,
    status = "published",
    content_html = html,
    author = 1,
  })
  return payload
end

function M.upload_current_buffer()
  local env, err = require_wp_env()
  if err then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end
  local text = get_buffer_text()
  local html = to_html(text)
  local payload = build_post_payload(html)

  local endpoint = vim.env.WP_URL

  if vim.fn.executable("curl") ~= 1 then
    vim.notify("curl is not installed or not in PATH", vim.log.levels.ERROR)
    return
  end

  vim.notify("Uploading current buffer to WordPress (draft)", vim.log.levels.INFO)

  -- Simple JSON POST to custom endpoint (no Authorization)
  local function run_post(url)
    local cmd = {
      "curl",
      "-sS",
      "-w",
      "\nHTTP_STATUS:%{http_code}",
      "-H",
      "Content-Type: application/json",
      "-X",
      "POST",
      url,
      "-d",
      payload,
    }
    local out = vim.fn.system(cmd)
    local exit = vim.v.shell_error
    return exit, out
  end

  -- Try primary endpoint then fallback
  local exit, out = run_post(endpoint)
  if exit ~= 0 then
    vim.notify("curl failed (exit " .. exit .. ")", vim.log.levels.ERROR)
    vim.notify(out, vim.log.levels.ERROR)
    return
  end

  local body, status = out:match("^(.*)\nHTTP_STATUS:(%d+)%s*$")
  status = tonumber(status)

  if not status then
    vim.notify("Could not read HTTP status from response", vim.log.levels.ERROR)
    vim.notify(out, vim.log.levels.ERROR)
    return
  end

  if status == 401 or status == 403 then
    vim.notify("Primary endpoint denied (" .. status .. "). Trying fallback.", vim.log.levels.WARN)
    exit, out = run_post(fallback_endpoint)
    if exit ~= 0 then
      vim.notify("curl failed on fallback (exit " .. exit .. ")", vim.log.levels.ERROR)
      vim.notify(out, vim.log.levels.ERROR)
      return
    end
    body, status = out:match("^(.*)\nHTTP_STATUS:(%d+)%s*$")
    status = tonumber(status)
  end

  if status < 200 or status >= 300 then
    vim.notify("WordPress error HTTP " .. tostring(status), vim.log.levels.ERROR)
    vim.notify(body or out, vim.log.levels.ERROR)
    return
  end

  local ok, data = pcall(vim.json.decode, body or out)
  if not ok or type(data) ~= "table" then
    vim.notify("Upload succeeded but response parse failed", vim.log.levels.WARN)
    vim.notify(body or out, vim.log.levels.WARN)
    return
  end

  local id = data.id
  local link = data.link or (base .. "/?p=" .. tostring(id or ""))
  vim.notify("WordPress draft created: ID=" .. tostring(id) .. "\n" .. link, vim.log.levels.INFO)
  vim.fn.setreg("+", link)
end

local prefix = "<leader>j"
map("n", prefix .. "wp", M.upload_current_buffer, { desc = "Upload current buffer to WordPress (draft)" })

return M
