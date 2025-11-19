return {
  {
    'stevearc/oil.nvim',
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {
      default_file_explorer = true,
      columns = { 'size' },
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
    },
    -- Optional dependencies
    dependencies = { { 'echasnovski/mini.icons', opts = {} } },
    keys = {
      { '-', '<cmd>Oil<CR>', desc = 'Oil' },
    },
    lazy = false,
  },
}
