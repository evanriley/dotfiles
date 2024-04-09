return {
  {
    'f-person/auto-dark-mode.nvim',
    dependencies = {
      'EdenEast/nightfox.nvim',
    },
    priority = 1000, -- Make sure to load this before all the other start plugins.
    config = {
      update_interval = 1000,
      set_dark_mode = function()
        vim.api.nvim_set_option_value('background', 'dark', {})
        vim.cmd 'colorscheme duskfox'
      end,
      set_light_mode = function()
        vim.api.nvim_set_option_value('background', 'light', {})
        vim.cmd 'colorscheme dayfox'
      end,
    },
  },
}
