-- Helper: run curl command from a JSON file and show output in new tab

local function run_curl_from_json_file(json_path)
  local function trim(s)
    if type(s) ~= "string" then
      return s
    end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
  end
  local function sanitize_for_name(s)
    if type(s) ~= "string" then
      return "output"
    end
    -- drop scheme
    s = s:gsub("^[a-zA-Z][a-zA-Z0-9+.-]*://", "")
    -- replace whitespace with _
    s = s:gsub("[\r\n\t ]+", "_")
    -- replace characters not suitable for buffer/file names
    s = s:gsub('[\\/:%*%?"<>|#]+', "_")
    if #s == 0 then
      s = "output"
    end
    return s
  end
  local file_content = vim.fn.readfile(json_path)
  local ok, json = pcall(function()
    return vim.fn.json_decode(file_content)
  end)
  if not ok or not json or not json.url or not json.method then
    local msg = "Invalid JSON file or missing required fields (url, method)."
    if not ok then
      msg = msg .. "\nJSON decode error: " .. tostring(json)
    end
    msg = msg .. "\nFile content:\n" .. table.concat(file_content, "\n")
    vim.notify(msg, vim.log.levels.ERROR)
    return
  end
  local url = json.url
  local method = string.upper(json.method)
  local curl_cmd = { "curl", "-i", "-sS", "-X", method }

  -- User-Agent: allow custom UA or Chrome-like UA
  local ua = json.user_agent
  if not ua and json.browser_ua == true then
    ua =
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
  end
  if ua then
    table.insert(curl_cmd, "-H")
    table.insert(curl_cmd, "User-Agent: " .. ua)
  end

  -- Resolve bearer token: token | token_env | token_file | token_cmd
  local token = json.token
  if (not token) and json.token_env then
    token = vim.fn.getenv(json.token_env)
  end
  if (not token) and json.token_file then
    local t = vim.fn.readfile(json.token_file)
    if type(t) == "table" then
      t = table.concat(t, "\n")
    end
    token = trim(t)
  end
  if (not token) and json.token_cmd then
    local t = vim.fn.system(json.token_cmd)
    token = trim(t)
  end
  if token and token ~= "" then
    table.insert(curl_cmd, "-H")
    table.insert(curl_cmd, "Authorization: Bearer " .. token)
  end

  -- Extra headers support: headers can be an array of strings or a map
  if type(json.headers) == "table" then
    local is_array = (#json.headers > 0)
    if is_array then
      for _, h in ipairs(json.headers) do
        table.insert(curl_cmd, "-H")
        table.insert(curl_cmd, tostring(h))
      end
    else
      for k, v in pairs(json.headers) do
        table.insert(curl_cmd, "-H")
        table.insert(curl_cmd, string.format("%s: %s", k, v))
      end
    end
  end

  -- Optional: basic auth
  if json.user and json.password then
    table.insert(curl_cmd, "-u")
    table.insert(curl_cmd, string.format("%s:%s", json.user, json.password))
  end

  -- Optional: timeout (seconds)
  if json.timeout then
    table.insert(curl_cmd, "--max-time")
    table.insert(curl_cmd, tostring(json.timeout))
  end

  -- Optional: insecure (skip TLS verify)
  if json.insecure == true then
    table.insert(curl_cmd, "-k")
  end

  -- Optional: verbose
  if json.verbose == true then
    table.insert(curl_cmd, "-v")
  end

  -- Payload handling
  local payload_tbl = json.payload
  local content_type = json.content_type or "application/json"
  if method == "GET" and payload_tbl and type(payload_tbl) == "table" then
    -- encode as query params
    table.insert(curl_cmd, "-G")
    for k, v in pairs(payload_tbl) do
      local item = string.format("%s=%s", k, tostring(v))
      table.insert(curl_cmd, "--data-urlencode")
      table.insert(curl_cmd, item)
    end
  elseif (method == "POST" or method == "PUT" or method == "PATCH") and payload_tbl then
    if content_type == "application/json" then
      table.insert(curl_cmd, "-H")
      table.insert(curl_cmd, "Content-Type: application/json")
      table.insert(curl_cmd, "-d")
      table.insert(curl_cmd, vim.fn.json_encode(payload_tbl))
    elseif content_type == "application/x-www-form-urlencoded" then
      table.insert(curl_cmd, "-H")
      table.insert(curl_cmd, "Content-Type: application/x-www-form-urlencoded")
      local parts = {}
      for k, v in pairs(payload_tbl) do
        table.insert(parts, string.format("%s=%s", k, tostring(v)))
      end
      table.insert(curl_cmd, "-d")
      table.insert(curl_cmd, table.concat(parts, "&"))
    else
      -- custom content type; send as-is if payload is string else json
      table.insert(curl_cmd, "-H")
      table.insert(curl_cmd, "Content-Type: " .. content_type)
      local data = payload_tbl
      if type(payload_tbl) ~= "string" then
        data = vim.fn.json_encode(payload_tbl)
      end
      table.insert(curl_cmd, "-d")
      table.insert(curl_cmd, data)
    end
  end
  -- Append URL last to ensure options apply
  table.insert(curl_cmd, url)

  -- Run curl and capture output
  local output = vim.fn.system(curl_cmd)
  -- Build request metadata (redacting sensitive values)
  local function is_sensitive_key(k)
    if type(k) ~= "string" then
      return false
    end
    k = k:lower()
    return k:find("authorization") or k:find("token") or k:find("api%-?key") or k:find("secret")
  end

  local shown_headers = {}
  -- user-agent
  if ua then
    table.insert(shown_headers, { key = "User-Agent", val = ua })
  end
  -- content-type
  if content_type and (method ~= "GET" and payload_tbl) then
    table.insert(shown_headers, { key = "Content-Type", val = content_type })
  end
  -- explicit headers
  if type(json.headers) == "table" then
    local is_array = (#json.headers > 0)
    if is_array then
      for _, h in ipairs(json.headers) do
        local k, v = tostring(h):match("^%s*([^:]+):%s*(.*)$")
        if k and v then
          table.insert(shown_headers, { key = k, val = v })
        end
      end
    else
      for k, v in pairs(json.headers) do
        table.insert(shown_headers, { key = k, val = tostring(v) })
      end
    end
  end
  -- authorization
  if token and token ~= "" then
    table.insert(shown_headers, { key = "Authorization", val = "Bearer <redacted>" })
  end

  -- Build a sanitized curl display command
  local display_cmd = { "curl", "-i", "-sS", "-X", method }
  if ua then
    table.insert(display_cmd, "-H")
    table.insert(display_cmd, "User-Agent: " .. ua)
  end
  for _, h in ipairs(shown_headers) do
    -- Avoid duplicating user-agent/content-type/authorization already added above
    local hk = (h.key or ""):lower()
    if hk ~= "user-agent" and hk ~= "content-type" and hk ~= "authorization" then
      local hv = h.val
      if is_sensitive_key(h.key) then
        hv = "<redacted>"
      end
      table.insert(display_cmd, "-H")
      table.insert(display_cmd, string.format("%s: %s", h.key, hv))
    end
  end
  if method == "GET" and payload_tbl and type(payload_tbl) == "table" then
    table.insert(display_cmd, "-G")
    for k, v in pairs(payload_tbl) do
      table.insert(display_cmd, "--data-urlencode")
      table.insert(display_cmd, string.format("%s=%s", k, tostring(v)))
    end
  elseif (method == "POST" or method == "PUT" or method == "PATCH") and payload_tbl then
    local data_preview = payload_tbl
    if type(payload_tbl) ~= "string" then
      data_preview = vim.fn.json_encode(payload_tbl)
    end
    table.insert(display_cmd, "-H")
    table.insert(display_cmd, "Content-Type: " .. content_type)
    table.insert(display_cmd, "-d")
    table.insert(display_cmd, data_preview)
  end
  -- auth and options
  if json.user and json.password then
    table.insert(display_cmd, "-u")
    table.insert(display_cmd, string.format("%s:%s", json.user, "****"))
  end
  if json.timeout then
    table.insert(display_cmd, "--max-time")
    table.insert(display_cmd, tostring(json.timeout))
  end
  if json.insecure == true then
    table.insert(display_cmd, "-k")
  end
  if json.verbose == true then
    table.insert(display_cmd, "-v")
  end
  table.insert(display_cmd, url)

  local function shelljoin(args)
    local esc = {}
    for _, a in ipairs(args) do
      table.insert(esc, vim.fn.shellescape(a))
    end
    return table.concat(esc, " ")
  end

  local request_lines = {}
  table.insert(request_lines, "# Request")
  table.insert(request_lines, string.format("- Method: %s", method))
  table.insert(request_lines, string.format("- URL: %s", url))
  if json.timeout then
    table.insert(request_lines, string.format("- Timeout: %ss", tostring(json.timeout)))
  end
  if json.insecure == true then
    table.insert(request_lines, "- Insecure TLS: true")
  end
  if json.user then
    table.insert(request_lines, string.format("- Basic Auth: %s:****", json.user))
  end
  table.insert(request_lines, "")
  table.insert(request_lines, "## Headers")
  if #shown_headers == 0 then
    table.insert(request_lines, "(none)")
  else
    for _, h in ipairs(shown_headers) do
      local val = is_sensitive_key(h.key) and "<redacted>" or h.val
      table.insert(request_lines, string.format("- %s: %s", h.key, val))
    end
  end
  table.insert(request_lines, "")
  if payload_tbl then
    table.insert(request_lines, "## Payload")
    local payload_str = type(payload_tbl) == "string" and payload_tbl or vim.fn.json_encode(payload_tbl)
    table.insert(request_lines, "```json")
    table.insert(request_lines, payload_str)
    table.insert(request_lines, "```")
    table.insert(request_lines, "")
  end
  table.insert(request_lines, "## curl")
  table.insert(request_lines, "```bash")
  table.insert(request_lines, shelljoin(display_cmd))
  table.insert(request_lines, "```")

  -- Build markdown with formatted response body
  local function split_headers_body(s)
    if not s or s == "" then
      return "", ""
    end
    local idx = s:match(".*()\r\n\r\n")
    local sep_len = 4
    if not idx then
      idx = s:match(".*()\n\n")
      sep_len = 2
    end
    if idx then
      local headers = s:sub(1, idx)
      local body = s:sub(idx + sep_len + 1)
      return headers, body
    end
    return "", s
  end

  local resp_headers, resp_body = split_headers_body(output)
  local header_lines = resp_headers ~= "" and vim.split(resp_headers, "\n") or {}

  local function body_lang_from_ct(ct)
    if not ct then
      return "text"
    end
    ct = ct:lower()
    if ct:find("json", 1, true) then
      return "json"
    end
    if ct:find("html", 1, true) then
      return "html"
    end
    if ct:find("xml", 1, true) then
      return "xml"
    end
    if ct:find("javascript", 1, true) then
      return "javascript"
    end
    if ct:find("text/", 1, true) then
      return "text"
    end
    return ""
  end

  local content_type_header
  for _, hl in ipairs(header_lines) do
    local m = hl:match("^%s*Content%-Type:%s*(.-)%s*$")
    if m then
      content_type_header = m
      break
    end
  end

  local body_lang = body_lang_from_ct(content_type_header)
  local pretty_body = resp_body or ""

  local function pretty_json(s)
    if not s or s == "" then
      return s
    end
    if vim.fn.executable("jq") == 1 then
      local jq_out = vim.fn.system({ "jq", "." }, s)
      if vim.v.shell_error == 0 and type(jq_out) == "string" and jq_out ~= "" then
        return jq_out
      end
    end
    local okj, decoded = pcall(vim.fn.json_decode, s)
    if okj and decoded ~= nil then
      local function is_array(t)
        if type(t) ~= "table" then
          return false
        end
        local n = 0
        for _ in ipairs(t) do
          n = n + 1
        end
        for k, _ in pairs(t) do
          if type(k) ~= "number" or k < 1 or k > n or k ~= math.floor(k) then
            return false
          end
        end
        return true
      end
      local function encode(val, indent)
        indent = indent or 0
        local indent_str = string.rep("  ", indent)
        local next_indent = string.rep("  ", indent + 1)
        local t = type(val)
        if t == "table" then
          if is_array(val) then
            local parts = {}
            for i = 1, #val do
              table.insert(parts, encode(val[i], indent + 1))
            end
            return "[\n" .. next_indent .. table.concat(parts, ",\n" .. next_indent) .. "\n" .. indent_str .. "]"
          else
            local parts = {}
            for k, v in pairs(val) do
              table.insert(parts, string.format('"%s": %s', tostring(k), encode(v, indent + 1)))
            end
            return "{\n" .. next_indent .. table.concat(parts, ",\n" .. next_indent) .. "\n" .. indent_str .. "}"
          end
        elseif t == "string" then
          local esc = val:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
          return '"' .. esc .. '"'
        elseif t == "number" or t == "boolean" then
          return tostring(val)
        else
          return "null"
        end
      end
      return encode(decoded, 0)
    end
    return s
  end

  if body_lang == "json" then
    pretty_body = pretty_json(resp_body)
  end

  local md_lines = vim.deepcopy(request_lines)
  table.insert(md_lines, "")
  table.insert(md_lines, "## Response")
  if #header_lines > 0 then
    table.insert(md_lines, "### Headers")
    table.insert(md_lines, "```http")
    for _, l in ipairs(header_lines) do
      table.insert(md_lines, l)
    end
    table.insert(md_lines, "```")
  end
  table.insert(md_lines, "")
  table.insert(md_lines, "### Body")
  local fence = body_lang ~= "" and ("```" .. body_lang) or "```"
  table.insert(md_lines, fence)
  for _, l in ipairs(vim.split(pretty_body or "", "\n")) do
    table.insert(md_lines, l)
  end
  table.insert(md_lines, "```")

  -- Save markdown to same directory as request file and open/update in current window
  local req_dir = vim.fn.fnamemodify(json_path, ":h")
  local req_base = vim.fn.fnamemodify(json_path, ":t:r")
  local out_path = req_dir .. "/" .. req_base .. ".response.txt"

  local ok_write, write_err = pcall(vim.fn.writefile, md_lines, out_path)
  if not ok_write then
    vim.notify("Failed to write response: " .. tostring(write_err), vim.log.levels.ERROR)
    return
  end

  local existing = vim.fn.bufnr(out_path)
  if existing ~= -1 and vim.api.nvim_buf_is_valid(existing) then
    if not vim.api.nvim_buf_get_option(existing, "modifiable") then
      vim.api.nvim_buf_set_option(existing, "modifiable", true)
    end
    vim.api.nvim_buf_set_lines(existing, 0, -1, false, md_lines)
    vim.api.nvim_buf_set_option(existing, "modifiable", false)
    vim.api.nvim_set_current_buf(existing)
    vim.api.nvim_buf_set_option(existing, "filetype", "markdown")
  else
    vim.cmd("edit " .. vim.fn.fnameescape(out_path))
    vim.bo.filetype = "markdown"
  end

  vim.notify("Curl response saved to " .. out_path, vim.log.levels.INFO)
end

vim.api.nvim_create_user_command("CurlFromJson", function()
  local buf = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(buf)
  if bufname == "" then
    vim.notify("Buffer has no file name. Please save the buffer first.", vim.log.levels.ERROR)
    return
  end
  run_curl_from_json_file(bufname)
end, {})
