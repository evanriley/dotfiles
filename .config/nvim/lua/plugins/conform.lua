return {
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    opts = {
      format_on_save = {
        timeout_ms = 500,
        lsp_format = 'fallback',
      },
      formatters_by_ft = {
        lua = { 'stylua' },
        go = { 'gofmt', 'goimports' },
        gleam = { 'gleam' },
        kdl = { 'kdlfmt' },
        zigfmt = { 'zigfmt' },
        python = { 'ruff' },
      },
    },
  },
}
