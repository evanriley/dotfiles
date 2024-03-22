-- [nfnl] Compiled from fnl/plugins/go.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local nvim = autoload("nvim")
local function _2_()
  nvim.g.go_def_mapping_enabled = 0
  return nil
end
return {{"fatih/vim-go", lazy = true, build = ":GoInstallBinaries", ft = {"go"}, init = _2_}}
