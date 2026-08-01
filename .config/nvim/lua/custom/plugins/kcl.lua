return {
  {
    'kcl-lang/kcl.nvim',
    -- ft = 'kcl',
    dependencies = {
      'neovim/nvim-lspconfig',
      'hrsh7th/nvim-cmp',
      'hrsh7th/cmp-nvim-lsp',
    },
    config = function()
      vim.lsp.config('kcl', {
        cmd = { 'kcl-language-server' },
        root_markers = { 'kcl.mod' },
        cmd_env = { PATH = vim.env.PATH, KCL_PKG_PATH = vim.env.HOME .. '/.kcl/kpm' },
        workspace_folders = {
          {
            uri = vim.uri_from_fname(vim.env.HOME .. '/.kcl/kpm'),
            name = 'kcl-kpm',
          },
        },
      })
      vim.lsp.enable('kcl')
    end,
  },
}
