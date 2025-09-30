local qf_store_dir = vim.fn.stdpath("data") .. "/qf_lists"

-- Ensure directory exists
vim.fn.mkdir(qf_store_dir, "p")

-- Save quickfix list
vim.api.nvim_create_user_command("QFSave", function(opts)
  local name = opts.args ~= "" and opts.args or "default"
  local qf = vim.fn.getqflist()
  local file = qf_store_dir .. "/" .. name .. ".json"
  vim.fn.writefile({ vim.json.encode(qf) }, file)
  print("Quickfix list saved to " .. file)
end, { nargs = "?" })

-- Load quickfix list
vim.api.nvim_create_user_command("QFLoad", function(opts)
  local name = opts.args ~= "" and opts.args or "default"
  local file = qf_store_dir .. "/" .. name .. ".json"
  if vim.fn.filereadable(file) == 1 then
    local data = vim.fn.readfile(file)
    local ok, qf = pcall(vim.json.decode, table.concat(data, "\n"))
    if not ok or type(qf) ~= "table" then
      print("Failed to decode quickfix list from " .. file)
      return
    end
    vim.fn.setqflist(qf)
    vim.cmd("copen")
    print("Quickfix list loaded from " .. file)
  else
    print("No saved quickfix list: " .. file)
  end
end, { nargs = "?" })
