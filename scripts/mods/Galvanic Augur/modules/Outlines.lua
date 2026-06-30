local mod = get_mod("Galvanic Augur")

local Managers = Managers
local table_contains = table.contains
local manager_state = Managers.state
local outline_system
local outlined_units = {}
local tag_colour = "galvanic_augur"

local get_outline_system = function()
	local state_extension = manager_state.extension
	if not outline_system then
		outline_system = state_extension and state_extension:system("outline_system")
	end
	return outline_system
end

mod.remove_outline = function(unit)
	if outline_system then
		local ok = pcall(function()
			outline_system:remove_outline(unit, tag_colour, true)
		end)
		if not ok then
			outline_system = nil
		end
	end
	outlined_units[unit] = nil
end

mod.remove_all_outlines = function()
	for unit, _ in pairs(outlined_units) do
		mod.remove_outline(unit)
	end
end

local function outline_colour()
	local s = mod.settings or {}
	return {
		(s.outline_colour_R or 0) / 255,
		(s.outline_colour_G or 80) / 255,
		(s.outline_colour_B or 255) / 255,
	}
end

mod:hook_require("scripts/settings/outline/outline_settings", function(settings)
	settings.MinionOutlineExtension.galvanic_augur = {
		priority = 3,
		color = outline_colour(),
		material_layers = {
			"minion_outline",
			"minion_outline_reversed_depth",
		},
		visibility_check = function() return mod.player ~= nil and mod.current_tier() >= 2 end,
	}
	mod._galvanic_outline_cfg = settings.MinionOutlineExtension.galvanic_augur
end)

mod.refresh_outline_colour = function()
	if mod._galvanic_outline_cfg then
		mod._galvanic_outline_cfg.color = outline_colour()
	end
end

mod.manage_outlines = function(enemies)
	outline_system = outline_system or get_outline_system()
	if not mod.settings.show_outline or not outline_system then return end

	for unit, _ in pairs(outlined_units) do
		if not table_contains(enemies, unit) then
			mod.remove_outline(unit)
		end
	end

	for _, unit in ipairs(enemies) do
		if not outlined_units[unit] and outline_system then
			local ok = pcall(function()
				outline_system:remove_outline(unit, tag_colour)
				outline_system:add_outline(unit, tag_colour)
			end)
			if ok then
				outlined_units[unit] = true
			else
				outline_system = nil
			end
		end
	end
end
