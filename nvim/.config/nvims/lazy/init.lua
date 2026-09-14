-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("config.autocmds")
-- Add anywhere in init.lua after plugins load
vim.lsp.inlay_hint.enable(false)

-- vim.g.autoformat = false
