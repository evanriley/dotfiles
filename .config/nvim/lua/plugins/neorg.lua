-- [nfnl] Compiled from fnl/plugins/neorg.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local nvim = autoload("nvim")
local function _2_()
  local neorg = require("neorg")
  return neorg.setup({load = {["core.dirman"] = {config = {workspaces = {notes = "~/Documents/Notes"}}}}})
end
return {{"nvim-neorg/neorg", build = ":Neorg sync-parsers", dependencies = {"nvim-lua/plenary.nvim"}, config = _2_, lazy = false}}
