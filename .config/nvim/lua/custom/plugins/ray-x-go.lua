return {
  {
    'ray-x/go.nvim',
    dependencies = { -- optional packages
      'ray-x/guihua.lua',
      'neovim/nvim-lspconfig',
      'nvim-treesitter/nvim-treesitter',
    },
    config = function()
      require('go').setup {
        floaterm = { -- position
          posititon = 'auto', -- one of {`top`, `bottom`, `left`, `right`, `center`, `auto`}
          width = 0.45, -- width of float window if not auto
          height = 0.98, -- height of float window if not auto
          title_colors = 'nord', -- default to nord, one of {'nord', 'tokyo', 'dracula', 'rainbow', 'solarized ', 'monokai'}
          -- can also set to a list of colors to define colors to choose from
          -- e.g {'#D8DEE9', '#5E81AC', '#88C0D0', '#EBCB8B', '#A3BE8C', '#B48EAD'}
        },
      }

      local autocmd = vim.api.nvim_create_autocmd

      autocmd({ 'BufWritePost' }, {
        pattern = { '*.go' },
        callback = function()
          local current_file = vim.fn.expand '%:p'
          local package_dir = vim.fn.fnamemodify(current_file, ':h')

          -- Run GoTest with the current package
          vim.cmd('GoTest ' .. package_dir)
        end,
      })
    end,
    event = { 'CmdlineEnter' },
    ft = { 'go', 'gomod' },
    build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
  },
}
