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

-- use existing laser module (if there is one) instead of spawning a new one
function NewNPCRaycastWeaponBase:set_laser_enabled(state)
	if state and not alive(self._laser_unit) then
		if self._assembly_complete then
			local gadgets = managers.weapon_factory:get_parts_from_weapon_by_type_or_perk("gadget", self._factory_id, self._blueprint)
			for _, id in ipairs(gadgets) do
				local gadget = self._parts[id]
				local gadget_base = gadget and gadget.unit:base()
				if gadget_base and gadget_base.GADGET_TYPE == "laser" then
					self._laser_unit = gadget.unit
					self._remove_laser_unit = false
					break
				end
			end
		end

		if not self._laser_unit then
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

-- destroy the physics collider
Hooks:PreHook(NewNPCRaycastWeaponBase, "destroy", "destroy_nwc", function (self)
	if alive(self._collider_unit) then
		World:delete_unit(self._collider_unit)
	end
end)
