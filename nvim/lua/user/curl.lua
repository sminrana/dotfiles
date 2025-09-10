-- Helper: run curl command from a JSON file and show output in new tab

local function run_curl_from_json_file(json_path)
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
  local payload = json.payload and vim.fn.json_encode(json.payload) or nil
  local curl_cmd = { "curl", "-i", "-X", method, url }
  if payload and method == "POST" then
    table.insert(curl_cmd, "-H")
    table.insert(curl_cmd, "Content-Type: application/json")
    table.insert(curl_cmd, "-d")
    table.insert(curl_cmd, payload)
  end
  -- Run curl and capture output
  local output = vim.fn.system(curl_cmd)
  -- Open new tab and show output
  vim.cmd("tabnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(output, "\n"))
  vim.api.nvim_buf_set_option(buf, "filetype", "json")
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "buftype", "")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  -- Use a consistent buffer name for this url
  local name = "curl: " .. url
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

vim.api.nvim_create_user_command("CurlFromJson", function(opts)
  if not opts.args or opts.args == "" then
    vim.notify("Usage: :CurlFromJson path/to/file.json", vim.log.levels.ERROR)
    return
  end
  run_curl_from_json_file(opts.args)
end, { nargs = 1, complete = "file" })
