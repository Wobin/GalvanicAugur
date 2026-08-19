local mod = get_mod("Galvanic Augur")
local function migrate_colour(id)
	if mod:get(id) ~= nil then
		return
	end

	local r = mod:get(id .. "_R")
	local g = mod:get(id .. "_G")
	local b = mod:get(id .. "_B")

	if type(r) == "number" and type(g) == "number" and type(b) == "number" then
		mod:set(id, { 255, r, g, b })
	end
end

migrate_colour("ring1_colour")
migrate_colour("ring2_colour")
migrate_colour("outline_colour")



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
				type = "color",
				default_value = { 255, 160, 32, 240 },
				has_alpha = false,
			},
			{
				setting_id = "ring2_colour",
				type = "color",
				default_value = { 255, 0, 80, 255 },
				has_alpha = false,
			},
			{
				setting_id = "show_outline",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "outline_colour",
				type = "color",
				default_value = { 255, 0, 80, 255 },
				has_alpha = false,
			},
		},
	},
}
