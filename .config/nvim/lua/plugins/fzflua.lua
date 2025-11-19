return {
  {
    'ibhagwan/fzf-lua',
    keys = {
      {
        '<leader>ff',
        function()
          require('fzf-lua').files()
        end,
      },
      {
        '<leader>fg',
        function()
          require('fzf-lua').git_files()
        end,
      },
      {
        '<leader>fs',
        function()
          require('fzf-lua').live_grep()
        end,
      },
      {
        '<leader>fr',
        function()
          require('fzf-lua').oldfiles()
        end,
      },
      {
        '<leader>bb',
        '<cmd>FzfLua buffers sort_mru=true sort_lastused=true<cr>',
      },
    },
    opts = {
      oldfiles = {
        include_current_session = true,
      },
      previewers = {
        builtin = {
          syntax_limit_b = 1024 * 100, -- 100KB
        },
      },
      grep = {
        rg_glob = true, -- enable glob parsing
        glob_flag = '--iglob', -- case insensitive globs
        glob_separator = '%s%-%-', -- query separator pattern (lua): ' --'
      },
    },
  },
}
