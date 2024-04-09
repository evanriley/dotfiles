-- sessionizer.lua
local w = require("wezterm")
local platform = require("platform")
local act = w.action

local M = {}

local fd = "/Users/evan/.cargo/bin/fd"
local srcPath = w.home_dir .. "/Code"

M.toggle = function(window, pane)
	local projects = {}
	local success, stdout, stderr = w.run_child_process({
		fd,
		"-HI",
		"-td",
		"--max-depth=4",
		"--prune",
		".",
		srcPath,
		srcPath .. "/personal",
		srcPath .. "/work",
		"/Users/evan/.config/",
	})

	if not success then
		w.log_error("Failed to run fd: " .. stderr)
		return
	end

	for line in stdout:gmatch("([^\n]*)\n?") do
		local project = platform.is_win and line:gsub("\\", "/") or line -- handles Windows backslash
		local label = project
		local id = project

		-- handle git bare repositories,
		-- assuming following name convention `myproject.git`
		if string.match(project, "%.git/$") then
			w.log_info("found .git " .. tostring(project))
			local success, stdout, stderr =
				w.run_child_process({ fd, "-HI", "-td", "--max-depth=1", ".", project .. "/worktrees" })
			if success then
				for wt_line in stdout:gmatch("([^\n]*)\n?") do
					local wt_project = platform.is_win and wt_line:gsub("\\", "/") or wt_line -- handles Windows backslash
					local wt_label = wt_project
					local wt_id = wt_project
					table.insert(projects, { label = tostring(wt_label), id = tostring(wt_id) })
				end
			else
				w.log_error("Failed to run fd: " .. stderr)
			end
		end

		table.insert(projects, { label = tostring(label), id = tostring(id) })
	end

	window:perform_action(
		act.InputSelector({
			action = w.action_callback(function(win, _, id, label)
				if not id and not label then
					w.log_info("Cancelled")
				else
					w.log_info("Selected " .. label)
					win:perform_action(act.SwitchToWorkspace({ name = id, spawn = { cwd = label } }), pane)
				end
			end),
			fuzzy = true,
			title = "Select project",
			choices = projects,
		}),
		pane
	)
end

return M
