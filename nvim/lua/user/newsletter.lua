local M = {}

-- Local keymap utility (same style as other user modules)
local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  vim.keymap.set(mode, lhs, rhs, opts)
end

local function parse_emails_from_csv(path)
  local emails = {}
  if vim.fn.filereadable(path) ~= 1 then
    return nil, "CSV not readable: " .. path
  end
  local lines = vim.fn.readfile(path)
  for _, line in ipairs(lines) do
    -- Trim whitespace
    line = line:gsub("^%s+", ""):gsub("%s+$", "")
    if line ~= "" then
      -- Simple CSV: accept first column as email, ignore header lines if they don't look like email
      local first = line:match("^([^,;]+)")
      if first then
        first = first:gsub('"', ""):gsub("'", "")
        -- Basic email shape check
        if first:match("^[%w%._%-%+]+@[%w%._%-]+%.[%a]+$") then
          table.insert(emails, first)
        end
      end
    end
  end
  if #emails == 0 then
    return nil, "No valid emails found in CSV"
  end
  return emails, nil
end

local last_csv_input = nil

local function require_newsletter_env(subject_override)
  local from_email = "hello@sminrana.com"
  local from_name = "Founder-Focused Indie App Review"
  local subject = subject_override or vim.env.NEWSLETTER_SUBJECT or "Newsletter"
  local region = vim.env.AWS_REGION or vim.env.AWS_DEFAULT_REGION or "us-east-1"

  if not from_email or from_email == "" then
    return nil, "Missing hardcoded from email"
  end
  if not region or region == "" then
    return nil, "Missing AWS region (set AWS_REGION)"
  end

  return {
    from_email = from_email,
    from_name = from_name,
    subject = subject,
    region = region,
  }, nil
end

local function send_one(env, html, email)
  -- Escape quotes/newlines for JSON
  local safe_html = html:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n")

  local json_payload = string.format(
    [[
{
  "FromEmailAddress": "%s <%s>",
  "Destination": {
    "ToAddresses": ["%s"]
  },
  "Content": {
    "Simple": {
      "Subject": {
        "Data": "%s",
        "Charset": "UTF-8"
      },
      "Body": {
        "Html": {
          "Data": "%s",
          "Charset": "UTF-8"
        }
      }
    }
  }
}
  ]],
    env.from_name,
    env.from_email,
    email,
    env.subject,
    safe_html
  )

  local out = vim.fn.system({
    "aws",
    "sesv2",
    "send-email",
    "--region",
    env.region,
    "--cli-input-json",
    json_payload,
  })

  local exit = vim.v.shell_error

  -- Try to extract MessageId
  local ok, data = pcall(vim.json.decode, out)
  if ok and type(data) == "table" and data.MessageId then
    out = out .. "\nMessageId: " .. data.MessageId
  end

  return exit, out
end

function M.send_newsletter()
  -- Prompt for subject every send (synchronous)
  local subject_input = vim.fn.input({ prompt = "Subject: ", default = vim.env.NEWSLETTER_SUBJECT or "Newsletter" })
  if not subject_input or subject_input == "" then
    vim.notify("Subject is required", vim.log.levels.ERROR)
    return
  end

  local env, err = require_newsletter_env(subject_input)
  if err then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end
  if vim.fn.executable("aws") ~= 1 then
    vim.notify("aws CLI is not installed or not in PATH", vim.log.levels.ERROR)
    return
  end

  -- Prompt for CSV path(s) (synchronous)
  vim.notify("Prompting for CSV path(s)...", vim.log.levels.INFO)
  local csv_input = vim.fn.input({ prompt = "CSV path(s), comma-separated: ", default = last_csv_input or "" })
  if not csv_input or csv_input == "" then
    vim.notify("CSV path is required", vim.log.levels.ERROR)
    return
  end
  last_csv_input = csv_input

  -- Use current buffer as HTML template
  local html = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  if not html or html == "" then
    vim.notify("Current buffer is empty; cannot send newsletter", vim.log.levels.ERROR)
    return
  end
  -- Support multiple CSVs comma-separated
  local emails = {}
  for path in (csv_input .. ","):gmatch("([^,]+),") do
    path = path:gsub("^%s+", ""):gsub("%s+$", "")
    local list, eerr = parse_emails_from_csv(path)
    if eerr then
      vim.notify(eerr, vim.log.levels.WARN)
    else
      for _, e in ipairs(list) do
        table.insert(emails, e)
      end
    end
  end
  if #emails == 0 then
    vim.notify("No emails found in provided CSV paths", vim.log.levels.ERROR)
    return
  end

  -- Preview buffer
  local preview_lines = {}
  table.insert(preview_lines, "Preview: Newsletter send")
  table.insert(preview_lines, "From: " .. env.from_name .. " <" .. env.from_email .. ">")
  table.insert(preview_lines, "Subject: " .. env.subject)
  table.insert(preview_lines, "Total recipients: " .. tostring(#emails))
  table.insert(preview_lines, "First 10 recipients:")
  for i = 1, math.min(10, #emails) do
    table.insert(preview_lines, "  - " .. emails[i])
  end
  table.insert(preview_lines, "")
  table.insert(preview_lines, "HTML (current buffer):")
  table.insert(preview_lines, string.rep("-", 40))
  for _, l in ipairs(vim.split(html, "\n")) do
    table.insert(preview_lines, l)
  end
  table.insert(preview_lines, string.rep("-", 40))
  local pbuf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_option(pbuf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(pbuf, "filetype", "markdown")
  vim.api.nvim_buf_set_lines(pbuf, 0, -1, false, preview_lines)
  vim.api.nvim_set_current_buf(pbuf)

  -- Ask for test send first
  local do_test = vim.fn.input({ prompt = "Run test send first? (y/N): ", default = "N" })
  if do_test and do_test:lower() == "y" then
    local test_recipient = vim.fn.input({ prompt = "Test recipient email: " })
    if not test_recipient or test_recipient == "" then
      vim.notify("Test recipient required to run test send", vim.log.levels.ERROR)
      return
    end
    vim.notify("Sending test email to " .. test_recipient, vim.log.levels.INFO)
    local t_exit, t_out = send_one(env, html, test_recipient)
    local t_msg = string.format("Test send => exit %d\n%s", t_exit, t_out or "")
    vim.notify(t_msg, t_exit == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
    local proceed = vim.fn.input({ prompt = "Proceed with full send? (y/N): ", default = "N" })
    if not proceed or proceed:lower() ~= "y" then
      vim.notify("Aborting full send", vim.log.levels.WARN)
      return
    end
  end

  vim.notify("Sending newsletter to " .. tostring(#emails) .. " recipients", vim.log.levels.INFO)

  local successes = 0
  local failures = 0
  local logs = {}

  for _, email in ipairs(emails) do
    local exit, out = send_one(env, html, email)
    if exit == 0 then
      successes = successes + 1
    else
      failures = failures + 1
    end
    table.insert(logs, string.format("%s => exit %d\n%s", email, exit, out or ""))
  end

  local summary = string.format("Newsletter finished: %d success, %d failed", successes, failures)
  if failures > 0 then
    vim.notify(summary, vim.log.levels.WARN)
  else
    vim.notify(summary, vim.log.levels.INFO)
  end

  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "log")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(table.concat(logs, "\n\n"), "\n"))
  vim.api.nvim_set_current_buf(buf)
end

local prefix = "<leader>j"
map("n", prefix .. "ns", M.send_newsletter, { desc = "Send newsletter via AWS SES" })

return M
