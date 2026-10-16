-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<leader>uP", "<cmd>SyntaxPaletteToggle<cr>", { desc = "Toggle Syntax Palette" })

local diagnostic_hints_visible = true
local diagnostic_config

vim.keymap.set("n", "<leader>uH", function()
  diagnostic_config = diagnostic_config or vim.deepcopy(vim.diagnostic.config())
  diagnostic_hints_visible = not diagnostic_hints_visible

  if diagnostic_hints_visible then
    vim.diagnostic.config(diagnostic_config)
  else
    local config = vim.deepcopy(diagnostic_config)
    local severity = { min = vim.diagnostic.severity.INFO }

    for _, display in ipairs({ "virtual_text", "virtual_lines", "signs", "underline" }) do
      if config[display] then
        config[display] = type(config[display]) == "table"
            and vim.tbl_deep_extend("force", config[display], { severity = severity })
          or { severity = severity }
      end
    end

    vim.diagnostic.config(config)
  end

  vim.notify("Diagnostic hints " .. (diagnostic_hints_visible and "enabled" or "disabled"))
end, { desc = "Toggle Diagnostic Hints" })
