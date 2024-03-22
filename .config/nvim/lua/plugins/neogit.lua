-- [nfnl] Compiled from fnl/plugins/neogit.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local nvim = autoload("nvim")
return {{"NeogitOrg/neogit", dependencies = {"nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim", "sindrets/diffview.nvim", "ibhagwan/fzf-lua"}, cmd = "Neogit", config = true}}
