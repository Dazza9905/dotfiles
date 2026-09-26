return {
  {
    "SUSTech-data/neopyter",
    event = { "BufReadPre *.ju.py", "BufNewFile *.ju.py" },
    dependencies = {
      "AbaoFromCUG/websocket.nvim", -- for mode="direct"
    },
    keys = {
      { "<leader>jr", "<cmd>Neopyter execute kernelmenu:restart<cr>", desc = "Restart kernel" },
      { "<leader>jn", "<cmd>Neopyter execute notebook:run-cell-and-select-next<cr>", desc = "Execute next" },
      { "<leader>jN", "<cmd>Neopyter execute notebook:run-all-above<cr>", desc = "Execute until selected" },
      {
        "<leader>jR",
        function()
          require("neopyter.async").run(function()
            local jupyterlab = require("neopyter.jupyter").jupyterlab
            jupyterlab:execute_cmd("notebook:restart-clear-output")
            -- jupyterlab:execute_cmd("notebook:run-all-cells")
          end)
        end,
        desc = "Restart, clear, and run all",
      },
      { "<leader>jc", "<cmd>Neopyter execute notebook:clear-cell-output<cr>", desc = "Clear cell output" },
      { "<leader>jC", "<cmd>Neopyter execute notebook:clear-all-cell-outputs<cr>", desc = "Clear all outputs" },
    },

    ---@type neopyter.Option
    opts = {
      mode = "direct",
      remote_address = "127.0.0.1:9001",
      file_pattern = { "*.ju.*" },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>j", group = "jupyter", icon = "󰠮" },
      },
    },
  },
}
