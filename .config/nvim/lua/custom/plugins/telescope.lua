return { -- Fuzzy Finder (files, lsp, etc)
  {
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { -- If encountering errors, see telescope-fzf-native README for install instructions
        'nvim-telescope/telescope-fzf-native.nvim',

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = 'make',

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },

      -- Useful for getting pretty icons, but requires special font.
      --  If you already have a Nerd Font, or terminal set up with fallback fonts
      --  you can enable this
      -- { 'nvim-tree/nvim-web-devicons' }
    },
    config = function()
      -- Telescope is a fuzzy finder that comes with a lot of different things that
      -- it can fuzzy find! It's more than just a "file finder", it can search
      -- many different aspects of Neovim, your workspace, LSP, and more!
      --
      -- The easiest way to use telescope, is to start by doing something like:
      --  :Telescope help_tags
      --
      -- After running this command, a window will open up and you're able to
      -- type in the prompt window. You'll see a list of help_tags options and
      -- a corresponding preview of the help.
      --
      -- Two important keymaps to use while in telescope are:
      --  - Insert mode: <c-/>
      --  - Normal mode: ?
      --
      -- This opens a window that shows you all of the keymaps for the current
      -- telescope picker. This is really useful to discover what Telescope can
      -- do as well as how to actually do it!

      -- [[ Configure Telescope ]]
      -- See `:help telescope` and `:help telescope.setup()`
      require('telescope').setup {
        -- You can put your default mappings / updates / etc. in here
        --  All the info you're looking for is in `:help telescope.setup()`
        --
        -- defaults = {
        --   mappings = {
        --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
        --   },
        -- },
        pickers = {
          find_files = {
            find_command = { 'rg', '--files', '--hidden', '-g', '!.git' },
          },
        },
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      }

      -- Enable telescope extensions, if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', function()
        -- Live grep with inline path filter: type "pattern  path-fragment"
        local cwd = vim.fn.getcwd()
        local conf = require('telescope.config').values
        local finders = require('telescope.finders')
        local make_entry = require('telescope.make_entry')

        local function build_finder(term, dirs, globs, include_hidden)
          local args = vim.deepcopy(conf.vimgrep_arguments)
          if include_hidden then table.insert(args, '--hidden') end
          if globs then
            for _, g in ipairs(globs) do
              table.insert(args, '-g')
              table.insert(args, g)
            end
          end
          table.insert(args, '-e')
          table.insert(args, term)
          table.insert(args, '--')
          if dirs and #dirs > 0 then
            for _, d in ipairs(dirs) do table.insert(args, d) end
          else
            table.insert(args, cwd)
          end
          return finders.new_oneshot_job(args, { entry_maker = make_entry.gen_from_vimgrep({ cwd = cwd }) })
        end

        local opts = {
          prompt_title = 'Live Grep (pattern  path)',
          on_input_filter_cb = function(prompt)
            local pat, raw = prompt:match('^(.-)%s%s(.*)$')
            if not pat then
              pat = prompt
              raw = nil
            end

            local term = (pat or ''):gsub('^%s+', ''):gsub('%s+$', '')
            local include_hidden = term:sub(1, 1) == '.'

            local dirs, globs = nil, nil

            if raw and raw ~= '' then
              local fragment = raw:gsub('^%s+', ''):gsub('%s+$', '')
              local frag_hidden = fragment:sub(1, 1) == '.' or fragment:find('/%.') ~= nil
              include_hidden = include_hidden or frag_hidden

              local _dirs, _globs = {}, {}
              local any_hidden_dir = false
              for seg in fragment:gmatch('[^,]+') do
                seg = seg:gsub('^%s+', ''):gsub('%s+$', '')
                if seg ~= '' then
                  local expanded = vim.fn.expand(seg)
                  local abs = expanded:sub(1, 1) == '/' and expanded or (cwd .. '/' .. expanded)
                  if vim.fn.isdirectory(abs) == 1 then
                    table.insert(_dirs, abs)
                    if abs:find('/%.') or abs:match('/%.[^/]+') then any_hidden_dir = true end
                  elseif vim.fn.filereadable(abs) == 1 then
                    table.insert(_dirs, abs)
                    if abs:find('/%.') or abs:match('/%.[^/]+') then any_hidden_dir = true end
                  else
                    local glob = seg:find('[%*%?%[%]]') and seg or ('**' .. seg .. '**')
                    table.insert(_globs, glob)
                    if seg:find('/%.') or seg:sub(1,1) == '.' then any_hidden_dir = true end
                  end
                end
              end
              include_hidden = include_hidden or any_hidden_dir
              if #_dirs > 0 then dirs = _dirs end
              if #_globs > 0 then globs = _globs end
            end

            if term ~= '' then
              return { prompt = pat, updated_finder = build_finder(term, dirs, globs, include_hidden) }
            else
              return { prompt = pat }
            end
          end,
        }

        require('telescope.builtin').live_grep(opts)
      end, { desc = '[S]earch by [G]rep (pattern  path)' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

      -- Slightly advanced example of overriding default behavior and theme
      vim.keymap.set('n', '<leader>/', function()
        -- You can pass additional configuration to telescope to change theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      -- Also possible to pass additional configuration options.
      --  See `:help telescope.builtin.live_grep()` for information about particular keys
      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })

      -- Shortcut for searching your neovim configuration files
      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })

      -- Shortcut for searching home directory config
      vim.keymap.set('n', '<leader>sc', function()
        builtin.find_files { cwd = '$HOME/.config' }
      end, { desc = '[S]earch Home directory [C]onfig files' })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
