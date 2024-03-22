-- [nfnl] Compiled from fnl/plugins/theme.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local nvim = autoload("nvim")
local function _2_()
  local theme = require("gruvbox")
  theme.setup({terminal_colors = true, transparent_mode = true, undrcurl = false, underline = false})
  return vim.cmd("colorscheme gruvbox")
end
do local _ = {{"ellisonleao/gruvbox.nvim", priority = 1000, name = "gruvbox", config = _2_, lazy = false}} end
local function _3_()
  local theme = require("poimandres")
  theme.setup({disable_italics = true})
  return vim.cmd("colorscheme poimandres")
end
return {{"olivercederborg/poimandres.nvim", prority = 1000, name = "poimandres", config = _3_, lazy = false}}
