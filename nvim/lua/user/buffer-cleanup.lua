
vim.api.nvim_create_user_command("CloseOldBuffers", function()
  local now = os.time()
  local bufs = vim.fn.getbufinfo({ buflisted = 1 })
  for _, buf in ipairs(bufs) do
    local lastused = buf.lastused or 0
    if now - lastused > 1800 then -- 1800 seconds = 30 minutes
      if buf.loaded == 1 and buf.hidden == 0 then
        vim.api.nvim_buf_delete(buf.bufnr, { force = true })
      end
    end
  end
end, { desc = "Close buffers not used in last 30 minutes" })
