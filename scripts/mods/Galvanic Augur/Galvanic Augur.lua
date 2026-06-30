-- Mod: Galvanic Augur
-- Author: Wobin
-- Date: 30/06/2026
-- Version: 1.0.0

local mod = get_mod("Galvanic Augur")
mod.version = "1.0.0"

mod:io_dofile("Galvanic Augur/scripts/mods/Galvanic Augur/modules/Outlines")
mod:io_dofile("Galvanic Augur/scripts/mods/Galvanic Augur/modules/Zone")

local Unit = Unit
local table = table
local Promise = Promise
local Managers = Managers
local delay = Promise.delay
local ScriptUnit = ScriptUnit
local vector3_distance = Vector3.distance
local table_insert = table.insert
local playerManager = Managers.player
local unitWorldPosition = Unit.world_position
local managers_state = Managers.state
local game_mode_manager = Managers.state.game_mode
local has_extension = ScriptUnit.has_extension
local HEALTH_ALIVE = HEALTH_ALIVE
local CLASS = CLASS

mod.player = nil

mod.settings = {}

mod.refresh_settings = function()
	local s = mod.settings
	s.show_rings = mod:get("show_rings")
	s.show_outline = mod:get("show_outline")
	s.ring_transparency = mod:get("ring_transparency") or 50
	s.ring1_colour_R = mod:get("ring1_colour_R") or 160
	s.ring1_colour_G = mod:get("ring1_colour_G") or 32
	s.ring1_colour_B = mod:get("ring1_colour_B") or 240
	s.ring2_colour_R = mod:get("ring2_colour_R") or 0
	s.ring2_colour_G = mod:get("ring2_colour_G") or 80
	s.ring2_colour_B = mod:get("ring2_colour_B") or 255
	s.outline_colour_R = mod:get("outline_colour_R") or 0
	s.outline_colour_G = mod:get("outline_colour_G") or 80
	s.outline_colour_B = mod:get("outline_colour_B") or 255
end

local function will_be_disarmed(unit)
	local unit_data = has_extension(unit, "unit_data_system")
	if not unit_data then return false end
	local breed = unit_data:breed()
	if not breed then return false end
	return breed.ranged == true or breed.name == "renegade_netgunner"
end

mod.find_disarmable_enemies_in_radius = function(center, radius)
	local state_extension = managers_state.extension
	local side_system = state_extension and state_extension:system("side_system")
	local player_side = side_system and side_system:get_side_from_name("heroes")
	if not player_side then return {} end
	local enemy_units_list = player_side:relation_units("enemy")
	local enemy_units = {}

	for _, unit in ipairs(enemy_units_list) do
		if HEALTH_ALIVE and HEALTH_ALIVE[unit]
			and vector3_distance(center, unitWorldPosition(unit, 1)) <= radius
			and will_be_disarmed(unit) then
			table_insert(enemy_units, unit)
		end
	end
	return enemy_units
end

local retrieve_profile = function()
	local localplayer = playerManager:local_player_safe(1)
	if not localplayer then mod.player = nil return end
	local profile = localplayer:profile()
	mod.player = (profile and profile.archetype and profile.archetype.name == "cryptic") and localplayer or nil
end

mod.current_tier = function()
	local player = mod.player
	if not player then return 0 end
	local player_unit = player.player_unit
	if not player_unit or not Unit.is_valid(player_unit) then return 0 end
	local ability_ext = has_extension(player_unit, "ability_system")
	if not ability_ext then return 0 end
	local ability = ability_ext:ability_is_equipped("combat_ability")
	if not ability or ability.ability_template ~= "cryptic_discharge" then return 0 end
	local charges = ability_ext:remaining_ability_charges("combat_ability")
	if charges >= 2 then
		return 2
	elseif charges == 1 then
		return 1
	end
	return 0
end

local acceptable_locations = {}
acceptable_locations["coop_complete_objective"] = true
acceptable_locations["survival"] = true
acceptable_locations["shooting_range"] = true
acceptable_locations["expedition"] = true

mod.on_all_mods_loaded = function()
	mod:info(mod.version)
	mod.refresh_settings()
	mod:init()
end

mod.on_unload = function(exit_game)
	if mod.remove_all_outlines then mod.remove_all_outlines() end
	if mod.remove_zone then mod.remove_zone() end
end

mod.on_setting_changed = function(setting_id)
	mod.refresh_settings()
	if not setting_id then return end
	if setting_id:find("^outline_colour") then
		if mod.refresh_outline_colour then mod.refresh_outline_colour() end
		if mod.remove_all_outlines then mod.remove_all_outlines() end
	elseif setting_id:find("^ring") then
		if mod.remove_zone then mod.remove_zone() end
	end
end

mod.on_game_state_changed = function(status, sub_state_name)
	if sub_state_name == "GameplayStateRun" and status == "enter" then
		mod:init()
	end
	if status == "exit" then mod.on_unload() end
end

mod.init = function()
	game_mode_manager = Managers.state.game_mode
	if game_mode_manager then
		if acceptable_locations[game_mode_manager:game_mode_name()] then
			mod.correct_area = true
			delay(3):next(retrieve_profile):next(mod.init_zone)
		else
			mod.correct_area = false
			mod.on_unload()
		end
	end
end

mod:hook_safe(CLASS.InventoryBackgroundView, "on_exit", function()
	delay(3):next(retrieve_profile)
end)

local delta = 0

mod.update = function(dt)
	if not mod.correct_area then return end
	delta = delta + dt
	if delta < 0.3 then return end
	delta = 0

	if not mod.player then
		if mod.zoned_tier then mod.remove_zone() end
		mod.remove_all_outlines()
		return
	end

	local tier = mod.current_tier()

	if mod.settings.show_rings and tier > 0 then
		if mod.zoned_tier ~= tier then
			mod.manage_zone(tier)
		end
	elseif mod.zoned_tier then
		mod.remove_zone()
	end

	if mod.settings.show_outline and tier >= 2 then
		local center = Unit.world_position(mod.player.player_unit, 1)
		local enemies = mod.find_disarmable_enemies_in_radius(center, 30)
		mod.manage_outlines(enemies)
	else
		mod.remove_all_outlines()
	end
end
