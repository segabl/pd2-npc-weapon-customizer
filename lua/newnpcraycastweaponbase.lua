for k, v in pairs(NPCRaycastWeaponBase) do
  if type(v) == "function" and not NewNPCRaycastWeaponBase[k] then
    NewNPCRaycastWeaponBase[k] = v
  end
end

-- add weapon firing animation
local fire_original = NewNPCRaycastWeaponBase.fire
function NewNPCRaycastWeaponBase:fire(...)
  local result = fire_original(self, ...)
  if NWC.settings.add_animations and self._assembly_complete then
    self:tweak_data_anim_play("fire")
  end
  return result
end

local fire_blank_original = NewNPCRaycastWeaponBase.fire_blank
function NewNPCRaycastWeaponBase:fire_blank(...)
  local result = fire_blank_original(self, ...)
  if NWC.settings.add_animations and self._assembly_complete then
    self:tweak_data_anim_play("fire")
  end
  return result
end

local auto_fire_blank_original = NewNPCRaycastWeaponBase.auto_fire_blank
function NewNPCRaycastWeaponBase:auto_fire_blank(...)
  local result = auto_fire_blank_original(self, ...)
  if NWC.settings.add_animations and self._assembly_complete then
    self:tweak_data_anim_play("fire")
  end
  return result
end

local set_laser_enabled_original = NewNPCRaycastWeaponBase.set_laser_enabled
function NewNPCRaycastWeaponBase:set_laser_enabled(state, ...)
  -- use existing laser module (if there is one) instead of spawning a new one
  if self._laser_gadget_base == nil then
    self._laser_gadget_base = false
    if self._assembly_complete then
      local gadgets = managers.weapon_factory:get_parts_from_weapon_by_type_or_perk("gadget", self._factory_id, self._blueprint)
      for _, id in ipairs(gadgets) do
        local gadget = self._parts[id]
        local gadget_base = gadget and gadget.unit:base()
        if gadget_base and gadget_base.GADGET_TYPE == "laser" then
          gadget_base:set_npc()
          gadget_base:set_color_by_theme("cop_sniper")
          gadget_base:set_max_distace(10000)
          self._laser_gadget_base = gadget_base
          break
        end
      end
    end
  end
  if self._laser_gadget_base then
    if state then
      self._laser_gadget_base:set_on()
    else
      self._laser_gadget_base:set_off()
    end
  else
    return set_laser_enabled_original(self, state, ...)
  end
end
