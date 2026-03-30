return {
  "CopilotC-Nvim/CopilotChat.nvim",
  dependencies = {
    { "nvim-lua/plenary.nvim", branch = "master" },
    { "zbirenbaum/copilot.lua" },
  },
  build = "make tiktoken",
  opts = {
    window = {
      layout = "float",
      width = 0.8,
      height = 0.8,
      border = "rounded",
    },
  },
  keys = {
    { "<leader>aa", "<cmd>CopilotChatToggle<cr>", desc = "Copilot Chat Toggle" },
    { "<leader>ax", "<cmd>CopilotChatReset<cr>", desc = "Copilot Chat Reset" },
    { "<leader>ad", "<cmd>CopilotChatDocs<cr>", desc = "Copilot Chat Doc" },
    { "<leader>ae", "<cmd>CopilotChatExplain<cr>", desc = "Copilot Chat Explain" },
    { "<leader>af", "<cmd>CopilotChatFix<cr>", desc = "Copilot Chat Fix" },
    { "<leader>ao", "<cmd>CopilotChatOptimize<cr>", desc = "Copilot Chat Optimize" },
    { "<leader>am", "<cmd>CopilotChatModels<cr>", desc = "Copilot Chat Models" },
    { "<leader>ac", "<cmd>CopilotChatCommit<cr>", desc = "Copilot Chat Commits" },
    {
      "<leader>aq",
      function()
        local input = vim.fn.input("Quick Chat: ")
        if input ~= "" then
          vim.cmd("CopilotChat " .. input)
        end
      end,
      desc = "Copilot Chat Quick",
    },
  }
}
