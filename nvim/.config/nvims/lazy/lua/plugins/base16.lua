return {
  {
    "RRethy/base16-nvim",
    lazy = false,
    priority = 1000,
    config = function()
      -- Noctalia rewrites matugen.lua when the wallpaper changes. Wrap the
      -- stable base16 entry point so syntax colors survive each regeneration.
      local base16 = require("base16-colorscheme")
      local setup = base16.setup
      base16.setup = function(colors, ...)
        local result = setup(colors, ...)
        require("noctalia-syntax").apply(base16.colors)
        return result
      end
      vim.api.nvim_create_user_command("SyntaxPaletteToggle", function()
        require("noctalia-syntax").toggle()
      end, { desc = "Toggle Noctalia and classic syntax colors" })
      require("matugen").setup()
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      -- Reapply Noctalia's generated palette after LazyVim initializes its UI.
      colorscheme = function()
        require("matugen").setup()
      end,
    },
  },
}
