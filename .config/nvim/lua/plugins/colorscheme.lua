return {
  "rebelot/kanagawa.nvim",
  lazy = true,
  priority = 1000,
  name = "kanagawa",
  config = function()
    require("kanagawa").setup({
      undercurl = false,
      transparent = true,
      dimInactive = true,
      keywordStyle = { italic = false },
    })
  end,

  vim.cmd([[hi LineNR guibg=NONE]]),
}
