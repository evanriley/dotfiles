-- [nfnl] Compiled from fnl/plugins/comment.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local nvim = autoload("nvim")
local function _2_()
  local comment_nvim = require("Comment")
  return comment_nvim.setup({padding = true, sticky = true, toggler = {line = "gcc", block = "gbc"}, opleader = {line = "gc", block = "gb"}, mappings = {basic = true, extra = true, extended = false}})
end
return {{"numToStr/Comment.nvim", event = "BufReadPost", config = _2_}}
