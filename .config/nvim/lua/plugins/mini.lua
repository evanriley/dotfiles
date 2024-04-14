return {
  {
    'echasnovski/mini.nvim',
    keys = {
      {
        '<leader>bd',
        function()
          local bd = require('mini.bufremove').delete
          if vim.bo.modified then
            local choice = vim.fn.confirm(('Save changes to %q?'):format(vim.fn.bufname()), '&Yes\n&No\n&Cancel')
            if choice == 1 then -- Yes
              vim.cmd.write()
              bd(0)
            elseif choice == 2 then -- No
              bd(0, true)
            end
          else
            bd(0)
          end
        end,
      },
      {
        '<leader>bD',
        function()
          require('mini.bufremove').delete(0, true)
        end,
      },
    },
    config = function()
      -- autopairs
      require('mini.pairs').setup()
      -- Around/Inside textobjects
      require('mini.ai').setup { n_lines = 500 }
      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      require('mini.surround').setup()
      -- character jumps
      require('mini.jump').setup()
      -- git intergration
      require('mini.diff').setup()
      -- Highlight current level of indention
      require('mini.indentscope').setup {
        draw = {
          delay = 50,
          animation = require('mini.indentscope').gen_animation.none(),
        },
        -- symbol = "▏",
        symbol = '│',
        options = { try_as_border = true },
      }
      vim.keymap.set('n', '<leader>go', require('mini.diff').toggle_overlay)
      -- Jump between visible lines with ease
      require('mini.jump2d').setup {
        dim = true,
      }
      -- statusline.
      local statusline = require 'mini.statusline'
      statusline.setup {}
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end
      -- remove buffers
      require('mini.bufremove').setup()
    end,
  },
}
