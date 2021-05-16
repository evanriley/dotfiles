-- Check if the given plugin exists
function Check_plugin(plugin_path)
	return Fn.isdirectory(Fn.expand('$HOME/.local/share/nvim/site/pack/packer/start/' .. plugin_path)) == 1
end


-- Check for plugins updates
function Check_updates()
	Try({
		function()
			Log_message('+', 'Updating the outdated plugins ...', 2)
			Cmd('PackerSync')
			Log_message('+', 'Done', 2)
		end,
		Catch({
			function(_)
				Log_message('!', 'Unable to update plugins', 1)
			end,
		}),
	})
end

