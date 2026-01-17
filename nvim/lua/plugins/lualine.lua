-- ~/.config/nvim/lua/plugins/lualine.lua
-- This file is loaded by lazy.nvim and will modify lualine's options.
return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    -- create a custom component that shows tab settings
    local function tabinfo()
      local bo = vim.bo
      local ts = bo.tabstop or vim.o.tabstop
      local sw = bo.shiftwidth or vim.o.shiftwidth
      local sts = bo.softtabstop
      if sts == 0 or sts == nil then
        sts = ts
      end
      local et = bo.expandtab and "␣" or "⇥"
      return string.format("%d/%d/%d%s", ts, sw, sts, et)
    end

    table.insert(opts.sections.lualine_x, {
      tabinfo,
      cond = function()
        return true
      end,
    })

    return opts
  end,
}
