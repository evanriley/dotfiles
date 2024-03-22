-- [nfnl] Compiled from fnl/plugins/octo.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local nvim = autoload("nvim")
local function _2_()
  local octo = require("octo")
  return octo.setup({})
end
return {{"pwntester/octo.nvim", dependencies = {"nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim", "nvim-tree/nvim-web-devicons"}, cmd = "Octo", config = _2_}}
