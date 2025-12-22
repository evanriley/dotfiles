rule = {
	matches = {
		{ { "device.name", "equals", "alsa_output.usb-Topping_DX5_II-00.pro-output-0" } },
	},
	apply_properties = {
		["audio.rate"] = 0, -- 0 = follow source rate
		["audio.allowed-rates"] = "44100,48000,88200,96000,176400,192000",
	},
}
