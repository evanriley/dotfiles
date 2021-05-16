require('auto-session').setup({
	logLevel = 'info',
	auto_session_root_dir = Fn.stdpath('data') .. '/sessions/',
	auto_sesion_enabled = true,
	auto_session_enable_last_session = true,
})
