local mod = get_mod("Galvanic Augur")
local decal_path = "content/levels/training_grounds/fx/decal_aoe_indicator"
local package_path = "content/levels/training_grounds/missions/mission_tg_basic_combat_01"

local Unit = Unit
local World = World
local Vector3 = Vector3
local Quaternion = Quaternion
local is_valid = Unit.is_valid

mod.zone_loaded = false

mod.init_zone = function()
	if mod.zone_loaded then return end

	local status = mod:package_status(package_path)
	if status == "loaded" then
		mod.zone_loaded = true
		return
	end
	if status then return end

	mod:load_package(package_path, function()
		mod.zone_loaded = true
	end)
end

mod.release_zone_package = function()
	mod.zone_loaded = false
	if mod:package_status(package_path) then
		mod:unload_package(package_path)
	end
end

local TIER_RADIUS = { [1] = 12, [2] = 30 }

mod.manage_zone = function(tier, player_unit)
	if not mod.zone_loaded then return end
	if not player_unit or not is_valid(player_unit) then return end

	mod.remove_zone()

	local world = Unit.world(player_unit)
	local position = Unit.world_position(player_unit, 1)

	local decal_unit = World.spawn_unit_ex(world, decal_path, nil, position)
	World.link_unit(world, decal_unit, 1, player_unit, 1)

	local radius = TIER_RADIUS[tier] or 12
	local diameter = radius * 2
	Unit.set_local_scale(decal_unit, 1, Vector3(diameter, diameter, 1))

	local prefix = (tier == 2) and "ring2_colour" or "ring1_colour"
	local alpha = (mod.settings.ring_transparency or 50) / 100

	local material_value = Quaternion.identity()
	Quaternion.set_xyzw(material_value,
		(mod.settings[prefix .. "_R"] or 0) / 255,
		(mod.settings[prefix .. "_G"] or 0) / 255,
		(mod.settings[prefix .. "_B"] or 255) / 255,
		alpha)
	Unit.set_vector4_for_material(decal_unit, "projector", "particle_color", material_value, true)
	Unit.set_scalar_for_material(decal_unit, "projector", "color_multiplier", alpha)

	mod.decal = decal_unit
	mod.zoned_tier = tier
	mod.zoned_unit = player_unit
end

mod.remove_zone = function()
	local decal = mod.decal
	mod.decal = nil
	mod.zoned_tier = nil
	mod.zoned_unit = nil

	if decal and is_valid(decal) then
		World.destroy_unit(Unit.world(decal), decal)
	end
end
