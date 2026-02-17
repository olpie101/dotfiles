return {
  {
    'refractalize/oil-git-status.nvim',
    opts = {},
    -- Optional dependencies
    dependencies = { { 'stevearc/oil.nvim', opts = {} } },

    config = function()
      require('oil-git-status').setup()
    end,
  },
}
