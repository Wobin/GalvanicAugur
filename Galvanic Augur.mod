return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Galvanic Augur` encountered an error loading the Darktide Mod Framework.")

		new_mod("Galvanic Augur", {
			mod_script       = "Galvanic Augur/scripts/mods/Galvanic Augur/Galvanic Augur",
			mod_data         = "Galvanic Augur/scripts/mods/Galvanic Augur/Galvanic Augur_data",
			mod_localization = "Galvanic Augur/scripts/mods/Galvanic Augur/Galvanic Augur_localization",
		})
	end,
	version = "1.0.0",
	packages = {},
}
