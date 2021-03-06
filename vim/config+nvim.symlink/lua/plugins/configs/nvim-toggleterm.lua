require('toggleterm').setup({
	size = 20,
	open_mapping = [[<c-t>]],
	hide_numbers = true,
	shade_filetypes = {},
	shade_terminals = true,
	start_in_insert = true,
	persist_size = true,
	direction = 'horizontal',
	close_on_exit = true,
	float_opts = {
		border = 'curved',
		width = 70,
		height = 20,
		winblend = 0,
		highlights = {
			border = 'Special',
			background = 'Normal',
		},
	},
})
