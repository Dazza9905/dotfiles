return {
  {
    "RRethy/base16-nvim",
    lazy = false,
    priority = 1000,
    config = function()
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
