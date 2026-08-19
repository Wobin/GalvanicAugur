-- Mod: Galvanic Augur
-- Author: Wobin
-- Date: 20/08/2026

local mod = get_mod("Galvanic Augur")

mod.colour_channel = function(id, index, default)
	local c = mod:get(id)

	if type(c) == "table" and #c >= 4 then
		return c[index + 1]
	end

	local suffix = (index == 1 and "_R") or (index == 2 and "_G") or "_B"
	local v = mod:get(id .. suffix)

	return type(v) == "number" and v or default
end

mod.version = mod.get_metadata and mod:get_metadata("version") or "unknown"

mod:io_dofile("Galvanic Augur/scripts/mods/Galvanic Augur/modules/Outlines")
mod:io_dofile("Galvanic Augur/scripts/mods/Galvanic Augur/modules/Zone")

local BreedSettings = require("scripts/settings/breed/breed_settings")

local Unit = Unit
local table = table
local Promise = Promise
local Managers = Managers
local delay = Promise.delay
local ScriptUnit = ScriptUnit
local Broadphase = Broadphase
local vector3_distance = Vector3.distance
local table_clear = table.clear
local playerManager = Managers.player
local unitWorldPosition = Unit.world_position
local unit_is_valid = Unit.is_valid
local managers_state = Managers.state
local game_mode_manager = Managers.state.game_mode
local has_extension = ScriptUnit.has_extension
local broadphase_query = Broadphase.query
local MINION_BREED_TYPE = BreedSettings.types.minion
local HEALTH_ALIVE = HEALTH_ALIVE
local CLASS = CLASS

local TICK_INTERVAL = 0.3
local OUTLINE_RADIUS = 30
local BROADPHASE_MARGIN = 2

mod.player = nil
mod.cached_tier = 0

local function live_player()
	local player = mod.player
	if not player then return nil end
	if player.__deleted then
		mod.player = nil
		return nil
	end
	return player
end

mod.live_player = live_player

mod.settings = {}

mod.refresh_settings = function()
	local s = mod.settings
	s.show_rings = mod:get("show_rings")
	s.show_outline = mod:get("show_outline")
	s.ring_transparency = mod:get("ring_transparency") or 50
	s.ring1_colour_R = mod.colour_channel("ring1_colour", 1, 160)
	s.ring1_colour_G = mod.colour_channel("ring1_colour", 2, 32)
	s.ring1_colour_B = mod.colour_channel("ring1_colour", 3, 240)
	s.ring2_colour_R = mod.colour_channel("ring2_colour", 1, 0)
	s.ring2_colour_G = mod.colour_channel("ring2_colour", 2, 80)
	s.ring2_colour_B = mod.colour_channel("ring2_colour", 3, 255)
	s.outline_colour_R = mod.colour_channel("outline_colour", 1, 0)
	s.outline_colour_G = mod.colour_channel("outline_colour", 2, 80)
	s.outline_colour_B = mod.colour_channel("outline_colour", 3, 255)
end

local function will_be_disarmed(unit)
	local unit_data = has_extension(unit, "unit_data_system")
	if not unit_data then return false end
	local breed = unit_data:breed()
	if not breed then return false end
	return breed.ranged == true or breed.name == "renegade_netgunner"
end

local Unit_has_node = Unit.has_node
local Unit_node = Unit.node

local function enemy_chest_position(unit)
	if Unit_has_node(unit, "j_spine") then
		return unitWorldPosition(unit, Unit_node(unit, "j_spine"))
	end
	return unitWorldPosition(unit, 1)
end

local function should_outline(unit, center, radius, player_unit, first_person_ext)
	if not HEALTH_ALIVE[unit] then return false end
	if not will_be_disarmed(unit) then return false end

	local enemy_pos = enemy_chest_position(unit)
	if vector3_distance(center, enemy_pos) > radius then return false end

	if not first_person_ext or not first_person_ext:is_within_default_view(enemy_pos) then return false end

	local perception_ext = has_extension(unit, "perception_system")
	if not perception_ext then return false end
	return perception_ext:immediate_line_of_sight_check(player_unit)
end

local broadphase_results = {}
local disarmable_enemies = {}

mod.find_disarmable_enemies_in_radius = function(center, radius, player_unit)
	table_clear(disarmable_enemies)

	if not player_unit or not unit_is_valid(player_unit) then return disarmable_enemies end

	local state_extension = managers_state.extension
	if not state_extension then return disarmable_enemies end

	local side_system = state_extension:system("side_system")
	local player_side = side_system and side_system:get_side_from_name("heroes")
	if not player_side then return disarmable_enemies end

	local broadphase_system = state_extension:system("broadphase_system")
	local broadphase = broadphase_system and broadphase_system.broadphase
	if not broadphase then return disarmable_enemies end

	local first_person_ext = has_extension(player_unit, "first_person_system")
	if not first_person_ext then return disarmable_enemies end

	table_clear(broadphase_results)
	local num_hits = broadphase_query(broadphase, center, radius + BROADPHASE_MARGIN, broadphase_results,
		player_side:relation_side_names("enemy"), MINION_BREED_TYPE)

	for i = 1, num_hits do
		local unit = broadphase_results[i]
		if should_outline(unit, center, radius, player_unit, first_person_ext) then
			disarmable_enemies[unit] = true
		end
	end
	return disarmable_enemies
end

local retrieve_profile = function()
	local localplayer = playerManager:local_player_safe(1)
	if not localplayer then mod.player = nil return end
	local profile = localplayer:profile()
	mod.player = (profile and profile.archetype and profile.archetype.name == "cryptic") and localplayer or nil
end

mod.current_tier = function(player_unit)
	if not player_unit then
		local player = live_player()
		if not player then return 0 end
		player_unit = player.player_unit
	end
	if not player_unit or not unit_is_valid(player_unit) then return 0 end
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
	mod.player = nil
	mod.cached_tier = 0
	mod.correct_area = false
	if mod.remove_all_outlines then mod.remove_all_outlines() end
	if mod.reset_outline_system then mod.reset_outline_system() end
	if mod.remove_zone then mod.remove_zone() end
	if mod.release_zone_package then mod.release_zone_package() end
end

mod.on_disabled = function(initial_call)
	mod.cached_tier = 0
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
	if status == "exit" then mod.on_unload() end
	if sub_state_name == "GameplayStateRun" and status == "enter" then
		mod:init()
	end
end

mod.init = function()
	game_mode_manager = Managers.state.game_mode
	if not game_mode_manager then return end

	if not acceptable_locations[game_mode_manager:game_mode_name()] then
		mod.on_unload()
		return
	end

	mod.correct_area = true
	delay(3):next(function()
		if not mod.correct_area then return end
		retrieve_profile()
		if mod.player then mod.init_zone() end
	end)
end

mod:hook_safe(CLASS.InventoryBackgroundView, "on_exit", function()
	delay(3):next(function()
		if not mod.correct_area then return end
		retrieve_profile()
		if mod.player then mod.init_zone() end
	end)
end)

local delta = 0

mod.update = function(dt)
	if not mod.correct_area or not mod:is_enabled() then return end
	delta = delta + dt
	if delta < TICK_INTERVAL then return end
	delta = 0

	local player = live_player()
	if not player then
		mod.cached_tier = 0
		if mod.zoned_tier then mod.remove_zone() end
		mod.remove_all_outlines()
		return
	end

	local player_unit = player.player_unit
	local tier = mod.current_tier(player_unit)
	mod.cached_tier = tier

	if mod.settings.show_rings and tier > 0 then
		if mod.zoned_tier ~= tier or mod.zoned_unit ~= player_unit then
			mod.manage_zone(tier, player_unit)
		end
	elseif mod.zoned_tier then
		mod.remove_zone()
	end

	if mod.settings.show_outline and tier >= 2 then
		local center = unitWorldPosition(player_unit, 1)
		mod.manage_outlines(mod.find_disarmable_enemies_in_radius(center, OUTLINE_RADIUS, player_unit))
	else
		mod.remove_all_outlines()
	end
end


mod.on_settings_reset = function()
	mod.refresh_settings()
	if mod.refresh_outline_colour then mod.refresh_outline_colour() end
	if mod.remove_all_outlines then mod.remove_all_outlines() end
	if mod.remove_zone then mod.remove_zone() end
end