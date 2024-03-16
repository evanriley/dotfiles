return {
  "craftzdog/solarized-osaka.nvim",
  lazy = true,
  priority = 1000,
  opts = function()
    return {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
      hide_inactive_statusline = true,
    }
  end,
}
