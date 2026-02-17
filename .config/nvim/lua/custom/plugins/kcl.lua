return {
  {
    'kcl-lang/kcl.nvim',
    ft = 'kcl',
    dependencies = {
      'neovim/nvim-lspconfig',
      'hrsh7th/nvim-cmp',
      'hrsh7th/cmp-nvim-lsp',
    },
    config = function()
      local lspconfig = require 'lspconfig'
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      lspconfig.kcl.setup {
        cmd = { '/Users/eduardokolomajr/Downloads/kclvm/bin/kclvm_cli', 'server' },
        cmd_env = { PATH = vim.env.PATH },
        capabilities = capabilities,
      }
    end,
  },
}
