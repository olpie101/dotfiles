return {
  name = 'stardust-lsp',
  dir = '.',
  virtual = true,
  config = function()
    vim.lsp.config('stardust', {
      cmd = { 'stardust', 'lsp' },
      root_markers = { '.stardust', '.git' },
    })

    vim.api.nvim_create_autocmd('BufReadPost', {
      group = vim.api.nvim_create_augroup('stardust.attach', { clear = true }),
      callback = function(args)
        vim.lsp.start({
          name = 'stardust',
          cmd = { 'stardust', 'lsp' },
          cmd_env = { PATH = vim.env.PATH, KCL_PKG_PATH = vim.env.HOME .. '/.kcl/kpm' },
          root_dir = vim.fs.root(args.buf, { '.stardust', '.git' }),
        })
      end,
    })
  end,
}
