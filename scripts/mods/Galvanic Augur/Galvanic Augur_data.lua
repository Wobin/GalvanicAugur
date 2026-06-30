local mod = get_mod("Galvanic Augur")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "show_rings",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "ring_transparency",
				type = "numeric",
				default_value = 50,
				range = {0, 100},
			},
			{
				setting_id = "ring1_colour",
				type = "group",
				sub_widgets = {
					{ setting_id = "ring1_colour_R", type = "numeric", default_value = 160, range = {0, 255} },
					{ setting_id = "ring1_colour_G", type = "numeric", default_value = 32,  range = {0, 255} },
					{ setting_id = "ring1_colour_B", type = "numeric", default_value = 240, range = {0, 255} },
				},
			},
			{
				setting_id = "ring2_colour",
				type = "group",
				sub_widgets = {
					{ setting_id = "ring2_colour_R", type = "numeric", default_value = 0,   range = {0, 255} },
					{ setting_id = "ring2_colour_G", type = "numeric", default_value = 80,  range = {0, 255} },
					{ setting_id = "ring2_colour_B", type = "numeric", default_value = 255, range = {0, 255} },
				},
			},
			{
				setting_id = "show_outline",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "outline_colour",
				type = "group",
				sub_widgets = {
					{ setting_id = "outline_colour_R", type = "numeric", default_value = 0,   range = {0, 255} },
					{ setting_id = "outline_colour_G", type = "numeric", default_value = 80,  range = {0, 255} },
					{ setting_id = "outline_colour_B", type = "numeric", default_value = 255, range = {0, 255} },
				},
			},
		},
	},
}
