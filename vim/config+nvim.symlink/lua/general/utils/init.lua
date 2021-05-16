-- Utils

-- Helpers
Api, Cmd, Fn = vim.api, vim.cmd, vim.fn
Keymap, Execute, G = Api.nvim_set_keymap, Api.nvim_command, vim.g
Scopes = { o = vim.o, b = vim.bo, w = vim.wo }


-- Mappings wrapper, stolen from
-- https://github.com/ojroques/dotfiles/blob/master/nvim/init.lua#L8-L12
function Map(mode, lhs, rhs, opts)
	local options = { noremap = true }
	if opts then
		options = vim.tbl_extend('force', options, opts)
	end
	Keymap(mode, lhs, rhs, options)
end

-- Options wrapper, stolen from
-- https://github.com/ojroques/dotfiles/blob/master/nvim/init.lua#L14-L17
function Opt(scope, key, value)
	Scopes[scope][key] = value
	if scope ~= 'o' then
		Scopes['o'][key] = value
	end
end

-- For autocommands, extracted from
-- https://github.com/norcalli/nvim_utils
function Create_augroups(definitions)
	for group_name, definition in pairs(definitions) do
		Execute('augroup ' .. group_name)
		Execute('autocmd!')
		for _, def in ipairs(definition) do
			local command =
				table.concat(vim.tbl_flatten({ 'autocmd', def }), ' ')
			Execute(command)
		end
		Execute('augroup END')
	end
end

-- Check if string is empty or if it's nil
function Is_empty(str)
	return str == '' or str == nil
end

-- Search if a table have the value we are looking for,
-- useful for plugins management
function Has_value(tabl, val)
	for _, value in ipairs(tabl) do
		if value == val then
			return true
		end
	end

	return false
end

function Try(block)
	local status, result = pcall(block[1])
	if not status then
		block[2](result)
	end
	return result
end
