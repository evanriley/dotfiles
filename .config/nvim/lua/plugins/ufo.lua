-- [nfnl] Compiled from fnl/plugins/ufo.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local nvim = autoload("nvim")
local function _2_()
  local ufo = require("ufo")
  local function _3_(bufnr, filetype, buftype)
    return {"treesitter", "indent"}
  end
  return ufo.setup({provider_selector = _3_})
end
local function _4_()
  nvim.set_keymap("n", "zR", "<cmd>lua require'ufo'.openAllFolds()<CR>", {noremap = true})
  return nvim.set_keymap("x", "zM", "<cmd>lua require'ufo'.closeAllFolds()<CR>", {noremap = true})
end
return {{"kevinhwang91/nvim-ufo", dependencies = {"kevinhwang91/promise-async"}, event = {"BufReadPost", "BufNewFile"}, config = _2_, init = _4_}}
