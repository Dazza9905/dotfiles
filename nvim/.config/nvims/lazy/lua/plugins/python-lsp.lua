return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ty = {
          -- Prefer ty from PATH, but also support opening a devenv project from
          -- a Neovim process that was started before entering its shell.
          cmd = function(dispatchers, config)
            local executable = vim.fn.exepath("ty")
            local root_dir = config.root_dir or vim.fn.getcwd()
            local project_executable = vim.fs.joinpath(root_dir, ".devenv", "profile", "bin", "ty")

            if executable == "" and vim.fn.executable(project_executable) == 1 then
              executable = project_executable
            end

            return vim.lsp.rpc.start({ executable ~= "" and executable or "ty", "server" }, dispatchers, {
              cwd = root_dir,
              env = config.cmd_env,
              detached = config.detached,
            })
          end,
        },
      },
    },
  },
}
