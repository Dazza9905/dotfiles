return {
  {
    "SUSTech-data/neopyter",
    cmd = "Neopyter",
    event = { "BufReadPre *.ju.py", "BufNewFile *.ju.py" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "AbaoFromCUG/websocket.nvim", -- for mode="direct"
    },
    config = function(_, opts)
      local neopyter = require("neopyter")
      neopyter.setup(opts)
      neopyter.delay_setup()
    end,
    keys = {
      { "<leader>jp", function() require("config.notebook-pull").pull() end, desc = "Pull Saved Jupyter Notebook" },
      { "<leader>jr", "<cmd>Neopyter execute kernelmenu:restart<cr>", desc = "Restart kernel" },
      { "<leader>jn", "<cmd>Neopyter execute notebook:run-cell-and-select-next<cr>", desc = "Execute next" },
      { "<leader>jN", "<cmd>Neopyter execute notebook:run-all-above<cr>", desc = "Execute until selected" },
      {
        "<leader>jR",
        function()
          require("neopyter.async").run(function()
            local jupyterlab = require("neopyter.jupyter").jupyterlab
            jupyterlab:execute_command("notebook:restart-clear-output")
            jupyterlab:execute_command("notebook:run-all-cells")
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
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      for _, lang in ipairs({ "python", "markdown", "r" }) do
        if not vim.tbl_contains(opts.ensure_installed, lang) then
          table.insert(opts.ensure_installed, lang)
        end
      end
    end,
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
