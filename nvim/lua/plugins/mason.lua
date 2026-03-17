return {
  "mason-org/mason.nvim",
  opts = {
    ensure_installed = {
      -- LSPs
      "intelephense", -- PHP
      "typescript-language-server", -- JS/TS
      "vue-language-server", -- Vue
      "pyright", -- Python
      "ruff", -- Python lint/format
      "lua-language-server", -- Lua
      "svelte-language-server", -- Svelte
      "tailwindcss-language-server", -- Tailwind

      -- Formatters
      "pint", -- PHP
      "prettier", -- JS/TS/HTML/CSS
      "swiftformat", -- Swift
    },

    automatic_installation = false,
  },
}
