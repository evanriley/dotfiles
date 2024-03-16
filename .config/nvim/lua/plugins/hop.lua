-- [nfnl] Compiled from fnl/plugins/hop.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local nvim = autoload("nvim")
local function _2_()
  local hop = require("hop")
  return hop.setup({teasing = false})
end
local function _3_()
  nvim.set_keymap("n", "s", "<cmd>lua require'hop'.hint_char1()<cr>", {noremap = true})
  nvim.set_keymap("x", "s", "<cmd>lua require'hop'.hint_char1()<cr>", {noremap = true})
  nvim.set_keymap("o", "x", "<cmd>lua require'hop'.hint_char1()<cr>", {noremap = true})
  nvim.set_keymap("n", "S", "<cmd>lua require'hop'.hint_lines()<cr>", {noremap = true})
  nvim.set_keymap("o", "X", "<cmd>lua require'hop'.hint_lines()<cr>", {noremap = true})
  nvim.set_keymap("x", "SS", "<cmd>lua require'hop'.hint_lines()<cr>", {noremap = true})
  nvim.set_keymap("n", "<C-s>", "<cmd>lua require'hop'.hint_char2()<cr>", {noremap = true})
  nvim.set_keymap("x", "<C-s>", "<cmd>lua require'hop'.hint_char2()<cr>", {noremap = true})
  return nvim.set_keymap("o", "<C-x>", "<cmd>lua require'hop'.hint_char2()<cr>", {noremap = true})
end
return {{"phaazon/hop.nvim", lazy = true, event = "BufReadPost", config = _2_, init = _3_, enabled = false}}
