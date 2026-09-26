local function hide_notebook_diagnostics(err, result, ctx, config)
  local bufnr = result and result.uri and vim.uri_to_bufnr(result.uri)
  local filename = bufnr and vim.api.nvim_buf_get_name(bufnr) or ""

  if filename:match("%.ju%.py$") then
    result.diagnostics = {}
  end

  return vim.lsp.handlers["textDocument/publishDiagnostics"](err, result, ctx, config)
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pylsp = {
          handlers = {
            ["textDocument/publishDiagnostics"] = hide_notebook_diagnostics,
          },
          settings = {
            pylsp = {
              plugins = {
                -- These produce false positives for Neopyter's *.ju.py buffers.
                -- Ruff remains enabled as the Python diagnostic provider.
                pyflakes = { enabled = false },
                pycodestyle = { enabled = false },
                mccabe = { enabled = false },
              },
            },
          },
        },
        ruff = {
          handlers = {
            ["textDocument/publishDiagnostics"] = hide_notebook_diagnostics,
          },
        },
      },
    },
  },
}
