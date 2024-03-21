-- Set localleader to `,`
vim.g.maplocalleader = ","

-- Undercurl
vim.cmd([[let &t_Cs = "\e[4:3m]"]])
vim.cmd([[let &t_Ce = "\e[4:0m]"]])

local opt = vim.opt
opt.list = false -- Turn off list (hides certain characters, like tabs)
opt.pumwidth = 30 -- Wider menu
opt.cursorline = false -- Don't highlight current line
opt.scrolloff = 15 -- Start scrolling earlier

-- Settings for only when using the Neovide client
if vim.g.neovide then
  vim.o.guifont = "0xProto Nerd Font:17"

  vim.g.neovide_transparency = 0.7
  vim.g.neovide_window_blurred = true
  vim.g.neovide_floating_blur_amount_x = 10.0
  vim.g.neovide_floating_blur_amount_y = 10.0
  vim.g.neovide_hide_mouse_when_typing = true

  vim.g.neovide_cursor_animation_length = 0.13
  vim.g.neovide_cursor_animation_length = 0.07
  vim.g.neovide_cursor_trail_size = 0.03
end
