Hooks:PostHook(CopInventory, "init", "init_nwc", function (self)
	self._is_cop_inventory = true
end)

-- when a weapon is added to inventory, check for a replacement
local add_unit_original = CopInventory.add_unit
function CopInventory:add_unit(new_unit, ...)
	add_unit_original(self, new_unit, ...)
	local quality = NWC:get_quality_setting(self._unit)
	local replacement_data = self._is_cop_inventory and quality > 1 and NWC:get_weapon(NWC.weapon_unit_mappings[new_unit:name():key()])
	if replacement_data then
		local old_unit = new_unit
		local old_base = old_unit:base()

		-- load and spawn replacement weapon
		local factory_weapon = tweak_data.weapon.factory[replacement_data.factory_id]
		local ids_unit_name = Idstring(factory_weapon.unit)

		managers.dyn_resource:load(Idstring("unit"), ids_unit_name, managers.dyn_resource.DYN_RESOURCES_PACKAGE)

		new_unit = World:spawn_unit(Idstring(factory_weapon.unit), Vector3(), Rotation())

		local new_base = new_unit:base()
		local original_id = new_base._name_id

		-- save original name and set new name
		new_base._old_unit_name = old_unit:name()
		new_base._player_name_id = original_id:gsub("_crew", "")
		new_base._name_id = old_base._name_id .. "_" .. new_base._player_name_id .. (self._shield_unit and "_shield_nwc" or "_nwc")
		new_base._original_id =  original_id

		-- setup new tweak data
		if not tweak_data.weapon[new_base._name_id] then
			tweak_data.weapon[new_base._name_id] = deep_clone(tweak_data.weapon[old_base._name_id])
			if not NWC.settings.keep_sounds and not (NWC.settings.keep_sniper_sounds and tweak_data.weapon[new_base._name_id].sounds.prefix:find("sniper_npc")) then
				tweak_data.weapon[new_base._name_id].sounds = tweak_data.weapon[original_id].sounds
			end
			if not NWC.settings.keep_types and not self._shield_unit then
				tweak_data.weapon[new_base._name_id].anim_usage = tweak_data.weapon[original_id].anim_usage or tweak_data.weapon[original_id].usage
				tweak_data.weapon[new_base._name_id].hold = tweak_data.weapon[original_id].hold
				tweak_data.weapon[new_base._name_id].reload = tweak_data.weapon[original_id].reload
				tweak_data.weapon[new_base._name_id].pull_magazine_during_reload = tweak_data.weapon[original_id].pull_magazine_during_reload
			end
		end

		-- fix init data
		new_base:_create_use_setups()
		new_base:set_ammo_max(tweak_data.weapon[new_base._name_id].AMMO_MAX)
		new_base:set_ammo_total(new_base:get_ammo_max())
		new_base:set_ammo_max_per_clip(tweak_data.weapon[new_base._name_id].CLIP_AMMO_MAX)
		new_base:set_ammo_remaining_in_clip(new_base:get_ammo_max_per_clip())
		new_base._damage = old_base._damage

		-- disable thq if needed
		if quality < 3 then
			new_base.use_thq = function () return false end
		end

		-- plug old raycast function
		new_base._fire_raycast = old_base._fire_raycast

		new_base:set_factory_data(replacement_data.factory_id)
		new_base:set_cosmetics_data(replacement_data.cosmetics)
		new_base:assemble_from_blueprint(replacement_data.factory_id, replacement_data.blueprint)
		new_base:check_npc()

		local setup_data = old_base._setup
		setup_data.ignore_units = {
			self._unit,
			new_unit,
			self._shield_unit
		}
		new_base:setup(setup_data)

		if new_base.AKIMBO then
			new_base:create_second_gun()
		end

		add_unit_original(self, new_unit, ...)
	end
end

-- change the sync index to the original weapon's index and remove unneeded data
Hooks:PostHook(CopInventory, "save", "save_nwc", function (self, data)
	local old_name = alive(self:equipped_unit()) and self:equipped_unit():base()._old_unit_name
	if old_name then
		data.equipped_weapon_index = self._get_weapon_sync_index(old_name) or 4
		data.blueprint_string = nil
		data.cosmetics_string = "nil-1-0"
		data.gadget_on = nil
		data.gadget_color = nil
	end
end)

-- don't send equipped unit if it's a replaced one (as the original has been sent before anyways)
local _send_equipped_weapon_original = CopInventory._send_equipped_weapon
function CopInventory:_send_equipped_weapon(...)
	if self:equipped_unit():base()._old_unit_name then
		return
	end
	_send_equipped_weapon_original(self, ...)
end

-- create physics colliders for dropped weapons
local drop_weapon_original = CopInventory.drop_weapon
function CopInventory:drop_weapon(...)
	local selection = self._available_selections[self._equipped_selection]
	local weapon_unit = selection and selection.unit

	if weapon_unit and weapon_unit:damage() then
		return drop_weapon_original(self, ...)
	end

	if weapon_unit and weapon_unit:base() then
		self:_call_listeners("unequip")

		NWC:spawn_collision_box(weapon_unit, self._weapon_drop_dir, self._weapon_drop_vel)
		managers.game_play_central:weapon_dropped(weapon_unit)
		if weapon_unit:base().set_flashlight_enabled then
			weapon_unit:base():set_flashlight_enabled(false)
		end

		weapon_unit = weapon_unit:base()._second_gun
		if weapon_unit then
			NWC:spawn_collision_box(weapon_unit, self._weapon_drop_dir, self._weapon_drop_vel)
			managers.game_play_central:weapon_dropped(weapon_unit)
			if weapon_unit:base().set_flashlight_enabled then
				weapon_unit:base():set_flashlight_enabled(false)
			end
		end
	end
end
