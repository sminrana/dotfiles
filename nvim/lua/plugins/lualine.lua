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

    -- pick a section to put the info in (here: lualine_x)
    -- make sure we don't clobber existing config - merge the component
    opts.sections = opts.sections or {}
    opts.sections.lualine_x = opts.sections.lualine_x or {}
    -- append the tabinfo component at the end of lualine_x
    table.insert(opts.sections.lualine_x, {
      tabinfo,
      cond = function()
        return true
      end,
      -- optionally add separator or padding
    })

    return opts
  end,
}
