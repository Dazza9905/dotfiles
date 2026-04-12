-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
-- Add anywhere in init.lua after plugins load
vim.lsp.inlay_hint.enable(false)
