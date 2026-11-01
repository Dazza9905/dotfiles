return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Use one Nix server; nixd also completes evaluated packages/options.
        nil_ls = { enabled = false },
        nixd = {
          mason = false,
          settings = {
            nixd = {
              nixpkgs = { expr = "import <nixpkgs> { config.allowUnfree = true; }" },
              formatting = { command = { "alejandra" } },
            },
          },
          before_init = function(_, config)
            local root = config.root_dir
            if not root or not vim.uv.fs_stat(vim.fs.joinpath(root, "flake.nix")) then
              return
            end

            -- Discover the checkout and host instead of embedding a home path.
            local flake = "builtins.getFlake " .. vim.json.encode(root)
            local host = vim.json.encode(vim.uv.os_gethostname())
            local pkgs = "(let flake = " .. flake .. "; in flake.inputs.nixpkgs or <nixpkgs>)"
            config.settings.nixd.nixpkgs.expr = "import " .. pkgs .. " { config.allowUnfree = true; }"
            config.settings.nixd.options = {
              nixos = {
                expr = "let flake = "
                  .. flake
                  .. "; in if builtins.hasAttr "
                  .. host
                  .. " (flake.nixosConfigurations or {}) then flake.nixosConfigurations."
                  .. host
                  .. ".options else (import ("
                  .. pkgs
                  .. ' + "/nixos") { configuration = {}; }).options',
              },
            }
          end,
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = { formatters_by_ft = { nix = { "alejandra" } } },
  },
}
