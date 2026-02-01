-- sessionizer.lua
local w = require("wezterm")
local platform = require("platform")
local act = w.action

local M = {}

local fd = "/home/evan/.cargo/bin/fd"
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
		srcPath .. "/Personal",
		srcPath .. "/Work",
		"/Users/evan/.config/",
	})

	if not success then
		w.log_error("Failed to run fd: " .. stderr)
		return
	end

	for line in stdout:gmatch("([^\n]*)\n?") do
		local project = platform.is_win and line:gsub("\\", "/") or line -- handles Windows backslash
		local label = project

		-- Split the project path and get the last part as the id
		local parts = {}
		for part in string.gmatch(project, "([^/]+)") do
			table.insert(parts, part)
		end
		local id = parts[#parts]

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
					local wt_parts = {}
					for wt_part in string.gmatch(wt_project, "([^/]+)") do
						table.insert(wt_parts, wt_part)
					end
					local wt_id = wt_parts[#wt_parts]
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
