return {
  {
    'ThePrimeagen/harpoon',
    config = function()
      local harpoon_ui = require 'harpoon.ui'
      local harpoon_mark = require 'harpoon.mark'
      vim.keymap.set('n', '<leader>ho', harpoon_ui.toggle_quick_menu)
      vim.keymap.set('n', '<leader>ha', harpoon_mark.add_file)
      vim.keymap.set('n', '<leader>hr', harpoon_mark.rm_file)
      vim.keymap.set('n', '<leader>hc', harpoon_mark.clear_all)
      vim.keymap.set('n', '<leader>1', function()
        harpoon_ui.nav_file(1)
      end)
      vim.keymap.set('n', '<leader>2', function()
        harpoon_ui.nav_file(2)
      end)
      vim.keymap.set('n', '<leader>3', function()
        harpoon_ui.nav_file(3)
      end)
      vim.keymap.set('n', '<leader>4', function()
        harpoon_ui.nav_file(4)
      end)
      vim.keymap.set('n', '<leader>5', function()
        harpoon_ui.nav_file(5)
      end)
    end,
  },
}
