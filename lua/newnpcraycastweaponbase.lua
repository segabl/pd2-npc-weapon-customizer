for k, v in pairs(NPCRaycastWeaponBase) do
	if type(v) == "function" and not NewNPCRaycastWeaponBase[k] then
		NewNPCRaycastWeaponBase[k] = v
	end
end

-- add weapon firing animation
Hooks:PostHook(NewNPCRaycastWeaponBase, "fire", "fire_nwc", function (self)
	if NWC.settings.add_animations and self._assembly_complete then
		self:tweak_data_anim_play("fire")
	end
end)

Hooks:PostHook(NewNPCRaycastWeaponBase, "fire_blank", "fire_blank_nwc", function (self)
	if NWC.settings.add_animations and self._assembly_complete then
		self:tweak_data_anim_play("fire")
	end
end)

Hooks:PostHook(NewNPCRaycastWeaponBase, "auto_fire_blank", "auto_fire_blank_nwc", function (self)
	if NWC.settings.add_animations and self._assembly_complete then
		self:tweak_data_anim_play("fire")
	end
end)

-- disable fire animations that don't have a unit to prevent crashing
Hooks:PreHook(NewNPCRaycastWeaponBase, "tweak_data_anim_play", "tweak_data_anim_play_nwc", function (self, anim)
	if self._checked_fire_anim or anim ~= "fire" then
		return
	end
	local unit_anim = self:_get_tweak_data_weapon_animation(anim)
	for _, data in pairs(self._parts) do
		if data.animations and data.animations[unit_anim] and not data.unit then
			data.animations[unit_anim] = nil
		end
	end
	self._checked_fire_anim = true
end)

-- check for usable gadgets
Hooks:PostHook(NewNPCRaycastWeaponBase, "clbk_assembly_complete", "clbk_assembly_complete_nwc", function (self)
	local gadgets = managers.weapon_factory:get_parts_from_weapon_by_type_or_perk("gadget", self._factory_id, self._blueprint)
	for _, id in ipairs(gadgets) do
		local gadget = self._parts[id]
		local gadget_base = gadget and gadget.unit:base()
		if gadget_base then
			if gadget_base.GADGET_TYPE == "laser" and not self._laser_unit then
				self._laser_unit = gadget.unit
			elseif gadget_base.GADGET_TYPE == "flashlight" and not self._flashlight_unit then
				self._flashlight_unit = gadget.unit
			elseif self._laser_unit and self._flashlight_unit then
				break
			end
		end
	end

	self:flashlight_state_changed()
end)

-- use existing laser module (if there is one) instead of spawning a new one
function NewNPCRaycastWeaponBase:set_laser_enabled(state)
	if state then
		if not alive(self._laser_unit) then
			local spawn_rot = self._unit:rotation()
			local spawn_pos = self._unit:position()
			spawn_pos = spawn_pos + spawn_rot:y() * 12 + spawn_rot:z() * 3
			self._laser_unit = World:spawn_unit(Idstring("units/payday2/weapons/wpn_npc_upg_fl_ass_smg_sho_peqbox/wpn_npc_upg_fl_ass_smg_sho_peqbox"), spawn_pos, spawn_rot)
			self._unit:link(self._unit:orientation_object():name(), self._laser_unit)
			self._remove_laser_unit = true
		end

		self._laser_unit:base():set_npc()
		self._laser_unit:base():set_on()
		self._laser_unit:base():set_color_by_theme("cop_sniper")
		self._laser_unit:base():set_max_distace(10000)
	elseif not state and alive(self._laser_unit) then
		if self._remove_laser_unit then
			self._laser_unit:unlink()
			World:delete_unit(self._laser_unit)
		else
			self._laser_unit:base():set_off()
		end
		self._laser_unit = nil
	end
end

local flashlight_state_changed_original = NewNPCRaycastWeaponBase.flashlight_state_changed
function NewNPCRaycastWeaponBase:flashlight_state_changed(...)
	if not self._original_id then
		return flashlight_state_changed_original(self, ...)
	end

	if not alive(self._flashlight_unit) then
		return
	end

	if self._flashlight_state and managers.game_play_central:flashlights_on() and NWC.settings.allow_flashlights then
		if math.random() < NWC.settings.flashlight_chance then
			self._flashlight_unit:base():set_on()
		end
	else
		self._flashlight_unit:base():set_off()
	end
end

local set_flashlight_enabled_original = NewNPCRaycastWeaponBase.set_flashlight_enabled
function NewNPCRaycastWeaponBase:set_flashlight_enabled(state, ...)
	if not self._original_id then
		return set_flashlight_enabled_original(self, state, ...)
	end

	self._flashlight_state = state
	self:flashlight_state_changed()
end

local set_gadget_on_original = NewNPCRaycastWeaponBase.set_gadget_on
function NewNPCRaycastWeaponBase:set_gadget_on(...)
	if not self._original_id then
		return set_gadget_on_original(self, ...)
	end
end

local has_flashlight_on_original = NewNPCRaycastWeaponBase.has_flashlight_on
function NewNPCRaycastWeaponBase:has_flashlight_on(...)
	return self._original_id and alive(self._flashlight_unit) and self._flashlight_unit:base():is_on() or has_flashlight_on_original(self, ...)
end

-- destroy the physics collider
Hooks:PreHook(NewNPCRaycastWeaponBase, "destroy", "destroy_nwc", function (self)
	if alive(self._collider_unit) then
		World:delete_unit(self._collider_unit)
	end
end)
