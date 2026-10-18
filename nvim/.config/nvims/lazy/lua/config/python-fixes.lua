local M = {}

local function request(client, method, params, bufnr)
  local response = client:request_sync(method, params, 2000, bufnr)
  return response and not response.err and response.result or nil
end

function M.apply(bufnr)
  local uri = vim.uri_from_bufnr(bufnr)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if client.name == "ty" then
      local diagnostics = vim.tbl_filter(function(diagnostic)
        return diagnostic.source == "ty"
      end, vim.diagnostic.get(bufnr))
      -- Work backwards so edits below a diagnostic do not move its range.
      table.sort(diagnostics, function(a, b)
        return a.lnum > b.lnum or (a.lnum == b.lnum and a.col > b.col)
      end)
      for _, diagnostic in ipairs(diagnostics) do
        local original = diagnostic.user_data and diagnostic.user_data.lsp
        if original then
          local actions = request(client, "textDocument/codeAction", {
            textDocument = { uri = uri },
            range = original.range,
            context = { diagnostics = { original }, only = { "quickfix" }, triggerKind = 2 },
          }, bufnr) or {}
          local fixes = {}
          for _, action in ipairs(actions) do
            local title = action.title:lower()
            if not action.disabled and action.edit
              and not title:find("suppress") and not title:find("ignore")
            then
              fixes[#fixes + 1] = action
            end
          end
          -- Never choose between alternative fixes automatically.
          if #fixes == 1 then
            vim.lsp.util.apply_workspace_edit(fixes[1].edit, client.offset_encoding)
          end
        end
      end
    elseif client.name == "ruff" then
      local actions = request(client, "textDocument/codeAction", {
        textDocument = { uri = uri },
        range = { start = { line = 0, character = 0 }, ["end"] = { line = 0, character = 0 } },
        context = { diagnostics = {}, only = { "source.fixAll.ruff" }, triggerKind = 2 },
      }, bufnr) or {}
      for _, action in ipairs(actions) do
        if not action.disabled then
          if not action.edit and client:supports_method("codeAction/resolve") then
            action = request(client, "codeAction/resolve", action, bufnr) or action
          end
          if action.edit then
            vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
          end
        end
      end
    end
  end
end

return M
