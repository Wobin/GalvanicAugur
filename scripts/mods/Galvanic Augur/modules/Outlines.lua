local mod = get_mod("Galvanic Augur")

local Unit = Unit
local Managers = Managers
local manager_state = Managers.state
local unit_alive = Unit.alive
local HEALTH_ALIVE = HEALTH_ALIVE

local outline_system
local cached_extension_manager
local outlined_units = {}
local tag_colour = "galvanic_augur"

local get_outline_system = function()
	local extension_manager = manager_state.extension
	if not extension_manager then
		outline_system = nil
		cached_extension_manager = nil
		return nil
	end
	if extension_manager ~= cached_extension_manager then
		cached_extension_manager = extension_manager
		outline_system = extension_manager:system("outline_system")
	end
	return outline_system
end

mod.reset_outline_system = function()
	outline_system = nil
	cached_extension_manager = nil
end

mod.remove_outline = function(unit)
	outlined_units[unit] = nil
	local system = get_outline_system()
	if not system or not unit_alive(unit) then return end
	system:remove_outline(unit, tag_colour)
end

mod.remove_all_outlines = function()
	if not next(outlined_units) then return end
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
		priority = 4,
		color = outline_colour(),
		material_layers = {
			"minion_outline",
			"minion_outline_reversed_depth",
		},
		visibility_check = function(unit)
			if not HEALTH_ALIVE[unit] then return false end
			return (mod.cached_tier or 0) >= 2
		end,
	}
	mod._galvanic_outline_cfg = settings.MinionOutlineExtension.galvanic_augur
end)

mod.refresh_outline_colour = function()
	if mod._galvanic_outline_cfg then
		mod._galvanic_outline_cfg.color = outline_colour()
	end
end

mod.manage_outlines = function(enemies)
	if not mod.settings.show_outline then return end
	local system = get_outline_system()
	if not system then return end

	for unit, _ in pairs(outlined_units) do
		if not enemies[unit] then
			mod.remove_outline(unit)
		end
	end

	for unit, _ in pairs(enemies) do
		if not outlined_units[unit] and unit_alive(unit) then
			system:remove_outline(unit, tag_colour)
			system:add_outline(unit, tag_colour)
			outlined_units[unit] = true
		end
	end
end
