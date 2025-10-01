-- Helper: run curl command from a JSON file and show output in new tab

local function run_curl_from_json_file(json_path)
  local function trim(s)
    if type(s) ~= 'string' then return s end
    return (s:gsub('^%s+', ''):gsub('%s+$', ''))
  end
  local function sanitize_for_name(s)
    if type(s) ~= 'string' then return 'output' end
    -- drop scheme
    s = s:gsub('^[a-zA-Z][a-zA-Z0-9+.-]*://', '')
    -- replace whitespace with _
    s = s:gsub('[\r\n\t ]+', '_')
    -- replace characters not suitable for buffer/file names
    s = s:gsub('[\\/:%*%?"<>|#]+', '_')
    if #s == 0 then s = 'output' end
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
    ua = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
  end
  if ua then
    table.insert(curl_cmd, "-H"); table.insert(curl_cmd, "User-Agent: " .. ua)
  end

  -- Resolve bearer token: token | token_env | token_file | token_cmd
  local token = json.token
  if (not token) and json.token_env then
    token = vim.fn.getenv(json.token_env)
  end
  if (not token) and json.token_file then
    local t = vim.fn.readfile(json.token_file)
    if type(t) == 'table' then t = table.concat(t, "\n") end
    token = trim(t)
  end
  if (not token) and json.token_cmd then
    local t = vim.fn.system(json.token_cmd)
    token = trim(t)
  end
  if token and token ~= '' then
    table.insert(curl_cmd, "-H")
    table.insert(curl_cmd, "Authorization: Bearer " .. token)
  end

  -- Extra headers support: headers can be an array of strings or a map
  if type(json.headers) == 'table' then
    local is_array = (#json.headers > 0)
    if is_array then
      for _, h in ipairs(json.headers) do
        table.insert(curl_cmd, "-H"); table.insert(curl_cmd, tostring(h))
      end
    else
      for k, v in pairs(json.headers) do
        table.insert(curl_cmd, "-H"); table.insert(curl_cmd, string.format("%s: %s", k, v))
      end
    end
  end

  -- Optional: basic auth
  if json.user and json.password then
    table.insert(curl_cmd, "-u"); table.insert(curl_cmd, string.format("%s:%s", json.user, json.password))
  end

  -- Optional: timeout (seconds)
  if json.timeout then
    table.insert(curl_cmd, "--max-time"); table.insert(curl_cmd, tostring(json.timeout))
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
  if method == "GET" and payload_tbl and type(payload_tbl) == 'table' then
    -- encode as query params
    table.insert(curl_cmd, "-G")
    for k, v in pairs(payload_tbl) do
      local item = string.format("%s=%s", k, tostring(v))
      table.insert(curl_cmd, "--data-urlencode")
      table.insert(curl_cmd, item)
    end
  elseif (method == "POST" or method == "PUT" or method == "PATCH") and payload_tbl then
    if content_type == "application/json" then
      table.insert(curl_cmd, "-H"); table.insert(curl_cmd, "Content-Type: application/json")
      table.insert(curl_cmd, "-d"); table.insert(curl_cmd, vim.fn.json_encode(payload_tbl))
    elseif content_type == "application/x-www-form-urlencoded" then
      table.insert(curl_cmd, "-H"); table.insert(curl_cmd, "Content-Type: application/x-www-form-urlencoded")
      local parts = {}
      for k, v in pairs(payload_tbl) do table.insert(parts, string.format("%s=%s", k, tostring(v))) end
      table.insert(curl_cmd, "-d"); table.insert(curl_cmd, table.concat(parts, "&"))
    else
      -- custom content type; send as-is if payload is string else json
      table.insert(curl_cmd, "-H"); table.insert(curl_cmd, "Content-Type: " .. content_type)
      local data = payload_tbl
      if type(payload_tbl) ~= 'string' then data = vim.fn.json_encode(payload_tbl) end
      table.insert(curl_cmd, "-d"); table.insert(curl_cmd, data)
    end
  end
  -- Append URL last to ensure options apply
  table.insert(curl_cmd, url)

  -- Run curl and capture output
  local output = vim.fn.system(curl_cmd)
  -- Build request metadata (redacting sensitive values)
  local function is_sensitive_key(k)
    if type(k) ~= 'string' then return false end
    k = k:lower()
    return k:find('authorization') or k:find('token') or k:find('api%-?key') or k:find('secret')
  end

  local shown_headers = {}
  -- user-agent
  if ua then table.insert(shown_headers, { key = 'User-Agent', val = ua }) end
  -- content-type
  if (content_type and (method ~= 'GET' and payload_tbl)) then
    table.insert(shown_headers, { key = 'Content-Type', val = content_type })
  end
  -- explicit headers
  if type(json.headers) == 'table' then
    local is_array = (#json.headers > 0)
    if is_array then
      for _, h in ipairs(json.headers) do
        local k,v = tostring(h):match('^%s*([^:]+):%s*(.*)$')
        if k and v then table.insert(shown_headers, { key = k, val = v }) end
      end
    else
      for k, v in pairs(json.headers) do table.insert(shown_headers, { key = k, val = tostring(v) }) end
    end
  end
  -- authorization
  if token and token ~= '' then
    table.insert(shown_headers, { key = 'Authorization', val = 'Bearer <redacted>' })
  end

  -- Build a sanitized curl display command
  local display_cmd = { 'curl', '-i', '-sS', '-X', method }
  if ua then table.insert(display_cmd, '-H'); table.insert(display_cmd, 'User-Agent: ' .. ua) end
  for _, h in ipairs(shown_headers) do
    -- Avoid duplicating user-agent/content-type/authorization already added above
    local hk = (h.key or ''):lower()
    if hk ~= 'user-agent' and hk ~= 'content-type' and hk ~= 'authorization' then
      local hv = h.val
      if is_sensitive_key(h.key) then hv = '<redacted>' end
      table.insert(display_cmd, '-H'); table.insert(display_cmd, string.format('%s: %s', h.key, hv))
    end
  end
  if method == 'GET' and payload_tbl and type(payload_tbl) == 'table' then
    table.insert(display_cmd, '-G')
    for k,v in pairs(payload_tbl) do
      table.insert(display_cmd, '--data-urlencode'); table.insert(display_cmd, string.format('%s=%s', k, tostring(v)))
    end
  elseif (method == 'POST' or method == 'PUT' or method == 'PATCH') and payload_tbl then
    local data_preview = payload_tbl
    if type(payload_tbl) ~= 'string' then data_preview = vim.fn.json_encode(payload_tbl) end
    table.insert(display_cmd, '-H'); table.insert(display_cmd, 'Content-Type: ' .. content_type)
    table.insert(display_cmd, '-d'); table.insert(display_cmd, data_preview)
  end
  -- auth and options
  if json.user and json.password then table.insert(display_cmd, '-u'); table.insert(display_cmd, string.format('%s:%s', json.user, '****')) end
  if json.timeout then table.insert(display_cmd, '--max-time'); table.insert(display_cmd, tostring(json.timeout)) end
  if json.insecure == true then table.insert(display_cmd, '-k') end
  if json.verbose == true then table.insert(display_cmd, '-v') end
  table.insert(display_cmd, url)

  local function shelljoin(args)
    local esc = {}
    for _, a in ipairs(args) do table.insert(esc, vim.fn.shellescape(a)) end
    return table.concat(esc, ' ')
  end

  local request_lines = {}
  table.insert(request_lines, '# Request')
  table.insert(request_lines, string.format('- Method: %s', method))
  table.insert(request_lines, string.format('- URL: %s', url))
  if json.timeout then table.insert(request_lines, string.format('- Timeout: %ss', tostring(json.timeout))) end
  if json.insecure == true then table.insert(request_lines, '- Insecure TLS: true') end
  if json.user then table.insert(request_lines, string.format('- Basic Auth: %s:****', json.user)) end
  table.insert(request_lines, '')
  table.insert(request_lines, '## Headers')
  if #shown_headers == 0 then
    table.insert(request_lines, '(none)')
  else
    for _, h in ipairs(shown_headers) do
      local val = is_sensitive_key(h.key) and '<redacted>' or h.val
      table.insert(request_lines, string.format('- %s: %s', h.key, val))
    end
  end
  table.insert(request_lines, '')
  if payload_tbl then
    table.insert(request_lines, '## Payload')
    local payload_str = type(payload_tbl) == 'string' and payload_tbl or vim.fn.json_encode(payload_tbl)
    table.insert(request_lines, '```json')
    table.insert(request_lines, payload_str)
    table.insert(request_lines, '```')
    table.insert(request_lines, '')
  end
  table.insert(request_lines, '## curl')
  table.insert(request_lines, '```bash')
  table.insert(request_lines, shelljoin(display_cmd))
  table.insert(request_lines, '```')
  table.insert(request_lines, '')
  table.insert(request_lines, '## Response')
  table.insert(request_lines, '```')
  local resp_lines = vim.split(output, '\n')
  for _, l in ipairs(resp_lines) do table.insert(request_lines, l) end
  table.insert(request_lines, '```')

  -- Open new tab and show output
  vim.cmd("tabnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, request_lines)
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "buftype", "")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  -- Use a consistent, sanitized buffer name with .txt extension
  local name = "curl-" .. sanitize_for_name(url) .. ".txt"
  local existing = vim.fn.bufnr(name)
  if existing ~= -1 and vim.api.nvim_buf_is_valid(existing) then
    -- If buffer exists and is valid, reuse it in current window
    vim.api.nvim_set_current_buf(existing)
    if not vim.api.nvim_buf_get_option(existing, "modifiable") then
      vim.api.nvim_buf_set_option(existing, "modifiable", true)
    end
    vim.api.nvim_buf_set_lines(existing, 0, -1, false, vim.split(output, "\n"))
    vim.api.nvim_buf_set_option(existing, "filetype", "json")
    vim.api.nvim_buf_set_option(existing, "modifiable", false)
  else
    -- Use current window for new buffer
    vim.api.nvim_buf_set_name(buf, name)
    vim.api.nvim_buf_set_option(buf, "filetype", "json")
    vim.api.nvim_buf_set_option(buf, "buftype", "")
    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(buf, "swapfile", false)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
  end
  vim.notify("Curl command executed for " .. url, vim.log.levels.INFO)
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
