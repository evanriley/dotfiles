rule = {
	matches = {
		{
			-- Match the unique bus ID of your Topping DX5 II
			{ "device.bus_id", "matches", "usb-Topping_DX5_II-00" },
		},
	},
	actions = {
		-- IMPORTANT: This forces WirePlumber to wait until the device is fully initialized.
		["api.acp.auto-ports-wait"] = true,
		-- Optional: Give it a consistent, friendly name
		["device.name"] = "Topping_DX5_II_Audio",
	},
	priority = 500,
}

-- Insert the rule into the list of rules used by the ALSA monitor
table.insert(alsa_monitor.rules, rule)
