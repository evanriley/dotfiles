local M = {}

M.theme_overrides = {
  normal_mode = {
    a = { fg = '#FCFBF9', bg = '#556995' }, -- white on blue
    b = { fg = '#556995', bg = '#FCFBF9' }, -- blue on white
    c = { fg = '#605A52', bg = '#F7F3EE' }, -- fg on lightest black
  },
  copy_mode = {
    a = { fg = '#FCFBF9', bg = '#8F5652' }, -- white on red
    b = { fg = '#8F5652', bg = '#FCFBF9' }, -- red on white
    c = { fg = '#605A52', bg = '#F7F3EE' },
  },
  search_mode = {
    a = { fg = '#FCFBF9', bg = '#83577D' }, -- white on magenta
    b = { fg = '#83577D', bg = '#FCFBF9' }, -- magenta on white
    c = { fg = '#605A52', bg = '#F7F3EE' },
  },
  window_mode = {
    a = { fg = '#FCFBF9', bg = '#477A7B' }, -- white on cyan
    b = { fg = '#477A7B', bg = '#FCFBF9' }, -- cyan on white
    c = { fg = '#605A52', bg = '#F7F3EE' },
  },
  resize_mode = {
    a = { fg = '#FCFBF9', bg = '#886A44' }, -- white on yellow
    b = { fg = '#886A44', bg = '#FCFBF9' }, -- yellow on white
    c = { fg = '#605A52', bg = '#F7F3EE' },
  },
  tab = {
    active = { fg = '#7686A9', bg = '#FCFBF9', bold = true }, -- cursor color on background
    inactive = { fg = '#605A52', bg = '#F7F3EE' }, -- foreground on lightest black
    inactive_hover = { fg = '#83577D', bg = '#FCFBF9' }, -- magenta on background
  },
}

return M
