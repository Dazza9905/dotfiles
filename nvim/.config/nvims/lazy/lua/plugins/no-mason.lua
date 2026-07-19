-- Disable mason entirely. LSP servers, formatters, and linters are expected
-- to come from PATH (project devenv/nix shells), not mason-installed copies.
return {
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
  { "jay-babu/mason-nvim-dap.nvim", enabled = false },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.setup = opts.setup or {}
      opts.setup["*"] = function(server, sopts)
        vim.lsp.config(server, sopts)
        vim.lsp.enable(server)
        return true -- tell LazyVim this server is handled, skip mason entirely
      end
    end,
  },
}
