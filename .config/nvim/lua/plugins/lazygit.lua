-- [nfnl] Compiled from fnl/plugins/lazygit.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local nvim = autoload("nvim")
local function _2_()
  local lazy = require("lazy")
  return lazy.setup({})
end
local function _3_()
  return nvim.set_keymap("n", "<leader>gg", "<cmd>LazyGit<cr>", {noremap = true, silent = true})
end
return {{"kdheepak/lazygit.nvim", dependencies = {"nvim-lua/plenary.nvim"}, cmd = "LazyGit", config = _2_, init = _3_}}
