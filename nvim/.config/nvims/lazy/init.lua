-- bootstrap lazy.nvim, LazyVim and your plugins
-- Use Astral's ty from the active project environment instead of Pyright.
vim.g.lazyvim_python_lsp = "ty"

require("config.lazy")
require("config.autocmds")
-- Add anywhere in init.lua after plugins load
vim.lsp.inlay_hint.enable(false)

-- vim.g.autoformat = false
