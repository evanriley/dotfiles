-- [nfnl] Compiled from fnl/plugins/surround.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local nvim = autoload("nvim")
local function _2_()
  local nvim_surround = require("nvim-surround")
  return nvim_surround.setup({})
end
return {{"kylechui/nvim-surround", version = "*", event = "VeryLazy", config = _2_}}
