-- Run synchronization outside buffer callbacks, after a short typing pause.
local M = {}

function M.setup()
  local group = vim.api.nvim_create_augroup("neopyter-live-sync", { clear = true })
  local revisions = {}
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP", "BufReadPost" }, {
    group = group,
    pattern = "*.ju.*",
    callback = function(event)
      local bufnr = event.buf
      revisions[bufnr] = (revisions[bufnr] or 0) + 1
      local revision = revisions[bufnr]
      vim.defer_fn(function()
        if revisions[bufnr] ~= revision or not vim.api.nvim_buf_is_valid(bufnr) then
          return
        end
        local lab = require("neopyter.jupyter").jupyterlab
        local notebook = lab and lab:get_notebook(bufnr)
        if not notebook then
          return
        end
        require("neopyter.async").run(function()
          if notebook:safe_sync() then
            notebook:parse()
            notebook:full_sync()
          end
        end, function(err)
          if err then
            vim.schedule(function()
              vim.notify("Neopyter live sync: " .. tostring(err), vim.log.levels.ERROR)
            end)
          end
        end)
      end, 120)
    end,
  })
end

return M
