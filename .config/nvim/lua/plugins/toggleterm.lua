-- [nfnl] Compiled from fnl/plugins/toggleterm.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local nvim = autoload("nvim")
local function _2_()
  local toggleterm = require("toggleterm")
  local function size(term)
    if (term.direction == "horizontal") then
      return 15
    elseif (term.direction == "vertical") then
      return (vim.o.columns * 0.4)
    else
      return nil
    end
  end
  return toggleterm.setup({open_mapping = "<C-t>", direction = "float", insert_mappings = true, shade_terminals = true, float_opts = {border = "single", width = 250, height = 40, winblend = 0}, size = size})
end
return {{"akinsho/toggleterm.nvim", config = _2_, lazy = false}}
