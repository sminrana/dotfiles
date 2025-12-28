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

local function normalize_entities(html)
  -- Replace smart punctuation with HTML entities to avoid mojibake on paste
  local map = {
    ["\226\128\153"] = "&rsquo;", -- ’ U+2019
    ["\226\128\156"] = "&ldquo;", -- “ U+201C
    ["\226\128\157"] = "&rdquo;", -- ” U+201D
    ["\226\128\148"] = "&ndash;", -- – U+2013
    ["\226\128\148"] = "&ndash;", -- duplicate safety
    ["\226\128\147"] = "&mdash;", -- — U+2014
    ["\226\128\141"] = "&#8209;", -- ‑ U+2011 non-breaking hyphen
  }
  for k, v in pairs(map) do
    html = html:gsub(k, v)
  end
  return html
end

local function to_html(text)
  local ft = vim.bo.filetype
  -- Prefer pandoc for markdown/text if present
  if (ft == "markdown" or ft == "md" or ft == "rmarkdown" or ft == "text") and vim.fn.executable("pandoc") == 1 then
    local tmp_in = vim.fn.tempname() .. ".md"
    local tmp_out = vim.fn.tempname() .. ".html"
    vim.fn.writefile(vim.split(text, "\n"), tmp_in)
    local cmd = {
      "pandoc",
      tmp_in,
      "-f",
      "commonmark",
      "-t",
      "html5",
      "--wrap",
      "none",
      "--standalone",
      "--metadata",
      "charset=UTF-8",
      "-o",
      tmp_out,
    }
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

local function to_wp_blocks(html)
  -- Convert common elements into Gutenberg blocks
  local blocks = html
  blocks = blocks:gsub("%s*<h1>(.-)</h1>%s*", '<!-- wp:heading {"level":1} -->\n<h1>%1</h1>\n<!-- /wp:heading -->\n')
  blocks = blocks:gsub("%s*<h2>(.-)</h2>%s*", '<!-- wp:heading {"level":2} -->\n<h2>%1</h2>\n<!-- /wp:heading -->\n')
  blocks = blocks:gsub("%s*<h3>(.-)</h3>%s*", '<!-- wp:heading {"level":3} -->\n<h3>%1</h3>\n<!-- /wp:heading -->\n')
  blocks = blocks:gsub("%s*<h4>(.-)</h4>%s*", '<!-- wp:heading {"level":4} -->\n<h4>%1</h4>\n<!-- /wp:heading -->\n')
  blocks = blocks:gsub("%s*<h5>(.-)</h5>%s*", '<!-- wp:heading {"level":5} -->\n<h5>%1</h5>\n<!-- /wp:heading -->\n')
  blocks = blocks:gsub("%s*<h6>(.-)</h6>%s*", '<!-- wp:heading {"level":6} -->\n<h6>%1</h6>\n<!-- /wp:heading -->\n')
  blocks = blocks:gsub("%s*<p>(.-)</p>%s*", "<!-- wp:paragraph -->\n<p>%1</p>\n<!-- /wp:paragraph -->\n")
  blocks = blocks:gsub(
    "%s*<blockquote>(.-)</blockquote>%s*",
    "<!-- wp:quote -->\n<blockquote>%1</blockquote>\n<!-- /wp:quote -->\n"
  )
  blocks = blocks:gsub(
    "%s*<pre><code>(.-)</code></pre>%s*",
    '<!-- wp:code -->\n<pre class="wp-block-code"><code>%1</code></pre>\n<!-- /wp:code -->\n'
  )
  blocks =
    blocks:gsub("%s*<pre>(.-)</pre>%s*", '<!-- wp:code -->\n<pre class="wp-block-code">%1</pre>\n<!-- /wp:code -->\n')
  blocks = blocks:gsub("%s*<ul>(.-)</ul>%s*", '<!-- wp:list {"ordered":false} -->\n<ul>%1</ul>\n<!-- /wp:list -->\n')
  blocks = blocks:gsub("%s*<ol>(.-)</ol>%s*", '<!-- wp:list {"ordered":true} -->\n<ol>%1</ol>\n<!-- /wp:list -->\n')
  blocks = blocks:gsub("<li>(.-)</li>", "<li><!-- wp:list-item -->%1<!-- /wp:list-item --></li>")
  blocks = blocks:gsub("%s*<figure>(.-)</figure>%s*", "<!-- wp:image -->\n<figure>%1</figure>\n<!-- /wp:image -->\n")
  blocks = blocks:gsub("%s*<img([^>]*)>%s*", "<!-- wp:image -->\n<img%1/>\n<!-- /wp:image -->\n")
  return blocks
end

local function build_post_payload(html)
  local title = vim.fn.expand("%:t:r")
  title = title:gsub("^%s+", ""):gsub("%s+$", "")
  title = title:gsub("[_.]+", " ")
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
  -- Convert to blocks if not already block-marked
  if not html:match("<!%-%-%s*wp:") then
    html = to_wp_blocks(html)
  end
  local payload = vim.fn.json_encode({
    token = vim.env.WP_UPLOAD_TOKEN,
    title = title,
    status = "publish",
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

  vim.notify("Publishing current buffer to WordPress", vim.log.levels.INFO)

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

function M.export_html_current_buffer()
  local text = get_buffer_text()
  local html = to_html(text)

  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname == nil or bufname == "" then
    vim.notify("Buffer has no file name; cannot determine output path", vim.log.levels.ERROR)
    return
  end

  local out = vim.fn.fnamemodify(bufname, ":r") .. ".html"
  local ok = pcall(vim.fn.writefile, vim.split(html, "\n"), out)
  if not ok then
    vim.notify("Failed to write HTML to " .. out, vim.log.levels.ERROR)
    return
  end

  vim.notify("Exported HTML: " .. out, vim.log.levels.INFO)
  vim.fn.setreg("+", out)

  if vim.fn.has("mac") == 1 or vim.loop.os_uname().sysname == "Darwin" then
    if vim.fn.executable("open") == 1 then
      vim.fn.jobstart({ "open", out }, { detach = true })
    else
      vim.notify("macOS 'open' not available in PATH", vim.log.levels.WARN)
    end
  else
    vim.notify("Not macOS; skipping auto-open", vim.log.levels.WARN)
  end
end

local prefix = "<leader>j"
map("n", prefix .. "wp", M.upload_current_buffer, { desc = "Upload current buffer to WordPress (draft)" })
map("n", prefix .. "mh", M.export_html_current_buffer, { desc = "Export Markdown to HTML file" })

function M.upload_adjacent_html()
  local env, err = require_wp_env()
  if err then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  local bufname = vim.api.nvim_buf_get_name(0)
  if not bufname or bufname == "" then
    vim.notify("Buffer has no filename; cannot locate HTML", vim.log.levels.ERROR)
    return
  end

  local out = vim.fn.fnamemodify(bufname, ":r") .. ".html"
  if vim.fn.filereadable(out) ~= 1 then
    vim.notify("HTML file not found: " .. out .. " — export first (leader j m h)", vim.log.levels.ERROR)
    return
  end

  local html = table.concat(vim.fn.readfile(out), "\n")
  local payload = build_post_payload(html)
  local endpoint = vim.env.WP_URL

  if vim.fn.executable("curl") ~= 1 then
    vim.notify("curl is not installed or not in PATH", vim.log.levels.ERROR)
    return
  end

  vim.notify("Publishing adjacent HTML to WordPress", vim.log.levels.INFO)

  local cmd = {
    "curl",
    "-sS",
    "-w",
    "\nHTTP_STATUS:%{http_code}",
    "-H",
    "Content-Type: application/json",
    "-X",
    "POST",
    endpoint,
    "-d",
    payload,
  }

  local outstr = vim.fn.system(cmd)
  local exit = vim.v.shell_error
  if exit ~= 0 then
    vim.notify("curl failed (exit " .. exit .. ")", vim.log.levels.ERROR)
    vim.notify(outstr, vim.log.levels.ERROR)
    return
  end

  local body, status = outstr:match("^(.*)\nHTTP_STATUS:(%d+)%s*$")
  status = tonumber(status)
  if not status or status < 200 or status >= 300 then
    vim.notify("WordPress error HTTP " .. tostring(status or "?"), vim.log.levels.ERROR)
    vim.notify(body or outstr, vim.log.levels.ERROR)
    return
  end

  local ok, data = pcall(vim.json.decode, body or outstr)
  if not ok or type(data) ~= "table" then
    vim.notify("Publish succeeded but response parse failed", vim.log.levels.WARN)
    vim.notify(body or outstr, vim.log.levels.WARN)
    return
  end

  local id = data.id
  local link = data.link or (vim.env.WP_URL .. "/?p=" .. tostring(id or ""))
  vim.notify("WordPress post created: ID=" .. tostring(id) .. "\n" .. link, vim.log.levels.INFO)
  vim.fn.setreg("+", link)

  if vim.fn.has("mac") == 1 or vim.loop.os_uname().sysname == "Darwin" then
    if vim.fn.executable("open") == 1 and link then
      vim.fn.jobstart({ "open", link }, { detach = true })
    end
  end
end

local prefix = "<leader>j"
map("n", prefix .. "wp", M.upload_current_buffer, { desc = "Upload current buffer to WordPress (draft)" })
map("n", prefix .. "mh", M.export_html_current_buffer, { desc = "Export Markdown to HTML file" })
map("n", prefix .. "wh", M.upload_adjacent_html, { desc = "Publish adjacent HTML to WordPress" })

return M
