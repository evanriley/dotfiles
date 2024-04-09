return {
  {
    'echasnovski/mini.nvim',
    config = function()
      -- simple autopairs
      require('mini.pairs').setup()
      -- Better Around/Inside textobjects
      require('mini.ai').setup { n_lines = 500 }
      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      require('mini.surround').setup()
      -- Better character jumps
      require('mini.jump').setup()
      -- Simpler git intergration
      require('mini.diff').setup()
      vim.keymap.set('n', '<leader>go', require('mini.diff').toggle_overlay)
      -- Jump between visible lines with ease
      require('mini.jump2d').setup {
        dim = true,
      }
      -- Simple and easy statusline.
      local statusline = require 'mini.statusline'
      -- set use_icons to true if you have a Nerd Font
      statusline.setup {}
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end
    end,
  },
}
