return {
  "mfussenegger/nvim-dap",
  event = "VeryLazy",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "jay-babu/mason-nvim-dap.nvim",
    "leoluz/nvim-dap-go",
    "theHamsta/nvim-dap-virtual-text",
    "mfussenegger/nvim-dap-python",
    "nvim-neotest/nvim-nio"
  },

  config = function ()
    local dap = require('dap')
    local dapui = require('dapui')
    dapui.setup()

    require("dap-python").setup()
    require("dap-go").setup()

    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
    end
  end,
  keys = {
    {
      "<leader>db",
      function() require("dap").toggle_breakpoint() end,
      desc = "DAP: Toggle Breakpoint",
    },
    {
      "<leader>dc",
      function() require("dap").continue() end,
      desc = "DAP: Continue/Resume",
    },
    {
      "<leader>dp",
      function() require("dap").pause() end,
      desc = "DAP: Pause",
    },
    {
      "<leader>ds",
      function() require("dap").terminate() end,
      desc = "DAP: Stop",
    },
  },
}

