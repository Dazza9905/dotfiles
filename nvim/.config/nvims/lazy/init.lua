-- bootstrap lazy.nvim, LazyVim and your plugins
-- Select ty before LazyVim imports the Python extra.
vim.g.lazyvim_python_lsp = "ty"

require("config.lazy")
-- Add anywhere in init.lua after plugins load
vim.lsp.inlay_hint.enable(false)

-- vim.g.autoformat = false
