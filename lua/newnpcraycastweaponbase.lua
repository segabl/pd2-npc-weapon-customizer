for k, v in pairs(NPCRaycastWeaponBase) do
  if type(v) == "function" and not NewNPCRaycastWeaponBase[k] then
    NewNPCRaycastWeaponBase[k] = v
  end
end

local use_thq_original = NewNPCRaycastWeaponBase.use_thq
function NewNPCRaycastWeaponBase:use_thq(...)
  -- change NPC weapons to third person (except for jokers)
  if self._force_tp == nil then
    self._force_tp = NWC.npc_gun_added and not NWC:is_joker(NWC.npc_gun_added.unit) and not NWC.settings.force_hq
  end
  if self._force_tp then
    return false
  end
  return use_thq_original(self, ...)
end

local setup_original = NewNPCRaycastWeaponBase.setup
function NewNPCRaycastWeaponBase:setup(...)
  setup_original(self, ...)

  -- adjust the stats of the newly added NPC weapon, it needs to point to the tweak data of the original gun
  if NWC.npc_gun_added then
    self._default_id = NWC.npc_gun_added.default_id
    self._original_id = self._name_id
    self._name_id = NWC.npc_gun_added.id
    
    if not NWC.tweak_setups[self._name_id] then
      tweak_data.weapon[self._name_id].sounds = tweak_data.weapon[self._original_id].sounds
      tweak_data.weapon[self._name_id].hold = tweak_data.weapon[self._original_id].hold
      tweak_data.weapon[self._name_id].reload = tweak_data.weapon[self._original_id].reload
      tweak_data.weapon[self._name_id].pull_magazine_during_reload = tweak_data.weapon[self._original_id].pull_magazine_during_reload
      tweak_data.weapon[self._name_id].muzzleflash = tweak_data.weapon[self._original_id].muzzleflash
      tweak_data.weapon[self._name_id].shell_ejection = tweak_data.weapon[self._original_id].shell_ejection
      
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
end