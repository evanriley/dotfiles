return {
  {
    'echasnovski/mini.nvim',
    config = function()
      require('mini.basics').setup {
        options = {
          basic = true,
          extra_ui = true,
          win_borders = 'bold',
        },
        mappings = {
          basic = true,
          windows = true,
        },
        autocommands = {
          basic = true,
          relnum_in_visual_mode = true,
        },
      }
      require('mini.bracketed').setup()
      require('mini.bufremove').setup()
      require('mini.jump').setup()
      require('mini.ai').setup { n_lines = 500 }
      require('mini.trailspace').setup()
      require('mini.surround').setup()
      require('mini.icons').setup()
      require('mini.move').setup {
        mappings = {
          left = '<M-S-h>',
          right = '<M-S-l>',
          down = '<M-S-j>',
          up = '<M-S-k>',
          line_left = '<M-S-h>',
          line_right = '<M-S-l>',
          line_down = '<M-S-j>',
          line_up = '<M-S-k>',
        },
      }
    end,
    keys = {
      {
        '<leader>bd',
        function()
          require('mini.bufremove').delete(0, false)
        end,
        desc = 'Delete current buffer',
      },
      {
        '<leader>bq',
        function()
          local bufs = vim.fn.getbufinfo { buflisted = 1 }
          for _, buf in ipairs(bufs) do
            require('mini.bufremove').delete(buf.bufnr, false)
          end
        end,
      },
      { '<S-l>', '<cmd>bnext<cr>', mode = 'n', desc = 'Next buffer' },
      { '<S-h>', '<cmd>bprevious<cr>', mode = 'n', desc = 'Previous buffer' },
    },
  },
}
