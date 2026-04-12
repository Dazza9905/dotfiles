return { -- <--- Ensure you are returning the table
  "mikavilpas/yazi.nvim",
  version = "*",
  event = "VeryLazy",
  dependencies = {
    { "nvim-lua/plenary.nvim", lazy = true },
  },
  keys = {
    { "<leader>\\", mode = { "n", "v" }, "<cmd>Yazi<cr>", desc = "Open yazi at the current file" },
    { "<leader>cw", "<cmd>Yazi cwd<cr>", desc = "Open yazi in cwd" },
    { "<c-up>", "<cmd>Yazi toggle<cr>", desc = "Resume last yazi session" },
  },
  ---@type YaziConfig | {}
  opts = {
    open_for_directories = false,
    keymaps = {
      show_help = "<f1>",
    },
  },
  init = function()
    vim.g.loaded_netrwPlugin = 1
  end,
}
