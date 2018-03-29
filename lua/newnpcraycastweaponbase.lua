for k, v in pairs(NPCRaycastWeaponBase) do
  if type(v) == "function" and not NewNPCRaycastWeaponBase[k] then
    NewNPCRaycastWeaponBase[k] = v
  end
end

local use_thq_original = NewNPCRaycastWeaponBase.use_thq
function NewNPCRaycastWeaponBase:use_thq(...)
  -- change NPC weapons to third person (except for jokers)
  if self._use_third_person == nil then
    if not NWC.npc_gun_added then
      self._use_third_person = false
    elseif NWC.settings.force_hq then
      self._use_third_person = false
    else
      self._use_third_person = not (NWC:is_joker(NWC.npc_gun_added.unit) and NWC.settings.jokers_hq) and not (NWC:is_special(NWC.npc_gun_added.unit) and NWC.settings.specials_hq)
    end
  end
  if self._use_third_person then
    return false
  end
  return use_thq_original(self, ...)
end

-- add weapon firing animation
local fire_original = NewNPCRaycastWeaponBase.fire
function NewNPCRaycastWeaponBase:fire(...)
  local result = fire_original(self, ...)
  if NWC.settings.add_animations then
    self:tweak_data_anim_play("fire")
  end
  return result
end

local fire_blank_original = NewNPCRaycastWeaponBase.fire_blank
function NewNPCRaycastWeaponBase:fire_blank(...)
  local result = fire_blank_original(self, ...)
  if NWC.settings.add_animations then
    self:tweak_data_anim_play("fire")
  end
  return result
end

local auto_fire_blank_original = NewNPCRaycastWeaponBase.auto_fire_blank
function NewNPCRaycastWeaponBase:auto_fire_blank(...)
  local result = auto_fire_blank_original(self, ...)
  if NWC.settings.add_animations then
    self:tweak_data_anim_play("fire")
  end
  return result
end

local tweak_data_anim_play_original = NewNPCRaycastWeaponBase.tweak_data_anim_play
function NewNPCRaycastWeaponBase:tweak_data_anim_play(anim, ...)
  local unit_anim = self:_get_tweak_data_weapon_animation(anim)
  -- disable animations that don't have a unit to prevent crashing
  if NWC.settings.add_animations and not self._checked_anims[unit_anim] then
    for part_id, data in pairs(self._parts) do
      if data.animations and data.animations[unit_anim] and not data.unit then
        data.animations[unit_anim] = nil
      end
    end
    self._checked_anims[unit_anim] = true
  end
  return tweak_data_anim_play_original(self, anim, ...)
end

local set_laser_enabled_original = NewNPCRaycastWeaponBase.set_laser_enabled
function NewNPCRaycastWeaponBase:set_laser_enabled(state, ...)
  -- use laser module that's part of the gun (if there is one) instead of spawning a new one
  if state and self._assembly_complete and not alive(self._laser_unit) then
    local gadgets = managers.weapon_factory:get_parts_from_weapon_by_type_or_perk("gadget", self._factory_id, self._blueprint)
    for i, id in ipairs(gadgets) do
      gadget = self._parts[id]
      if gadget then
        local gadget_base = gadget.unit:base()
        if gadget_base.GADGET_TYPE == "laser" then
          self._laser_unit = gadget.unit
          self._laser_unit:base():set_npc()
          self._laser_unit:base():set_on()
          self._laser_unit:base():set_color_by_theme("cop_sniper")
          self._laser_unit:base():set_max_distace(10000)
          break
        end
      end
    end
  end
  return set_laser_enabled_original(self, state, ...)
end

local setup_original = NewNPCRaycastWeaponBase.setup
function NewNPCRaycastWeaponBase:setup(...)
  setup_original(self, ...)

  self._checked_anims = {}

  -- adjust the stats of the newly added NPC weapon, it needs to point to the tweak data of the original gun
  if not NWC.npc_gun_added then
    return
  end

  self._sync_index = NWC.npc_gun_added.sync_index
  self._original_id = self._name_id
  self._name_id = NWC.npc_gun_added.id
  
  managers.mutators:modify_value("CopInventory:add_unit_by_name", NWC.npc_gun_added.unit:inventory())
  if NWC.npc_gun_added.unit:inventory()._shield_unit_name then
    CopInventory._chk_spawn_shield(NWC.npc_gun_added.unit:inventory(), self._unit)
  end
  
  if not NWC.tweak_setups[self._name_id] then
    if not NWC.settings.keep_sounds and not tweak_data.weapon[self._name_id].sounds.prefix:match("sniper_npc") then
      tweak_data.weapon[self._name_id].sounds = tweak_data.weapon[self._original_id].sounds
    end
    if not NWC.settings.keep_types and not NWC.npc_gun_added.unit:inventory()._shield_unit_name then
      tweak_data.weapon[self._name_id].hold = tweak_data.weapon[self._original_id].hold
      tweak_data.weapon[self._name_id].reload = tweak_data.weapon[self._original_id].reload
      tweak_data.weapon[self._name_id].pull_magazine_during_reload = tweak_data.weapon[self._original_id].pull_magazine_during_reload
    end
    NWC.tweak_setups[self._name_id] = true
  end

  self:set_ammo_max(tweak_data.weapon[self._name_id].AMMO_MAX)
  self:set_ammo_total(self:get_ammo_max())
  self:set_ammo_max_per_clip(tweak_data.weapon[self._name_id].CLIP_AMMO_MAX)
  self:set_ammo_remaining_in_clip(self:get_ammo_max_per_clip())
  
  self._damage = tweak_data.weapon[self._name_id].DAMAGE

  if not NWC:is_joker(NWC.npc_gun_added.unit) then
    self._setup.alert_AI = not NWC.is_client
    self._setup.alert_filter = not NWC.is_client and NWC.npc_gun_added.unit:brain().SO_access and NWC.npc_gun_added.unit:brain():SO_access()
    self._setup.hit_slotmask = NWC.is_client and managers.slot:get_mask("bullet_impact_targets_no_AI") or managers.slot:get_mask("bullet_impact_targets") or self._bullet_slotmask
    self._setup.hit_player = true
    self._setup.ignore_units = {
      NWC.npc_gun_added.unit,
      self._unit,
      NWC.npc_gun_added.unit:inventory()._shield_unit
    }
  
    self._alert_size = tweak_data.weapon[self._name_id].alert_size
    self._suppression = tweak_data.weapon[self._name_id].suppression
    self._bullet_slotmask = self._setup.hit_slotmask
    self._hit_player = self._setup.hit_player
    self._alert_events = self._setup.alert_AI and {} or nil
  end
  
  self._fire_raycast = NPCRaycastWeaponBase._fire_raycast
end