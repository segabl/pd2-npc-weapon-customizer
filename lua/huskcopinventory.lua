local _perform_switch_equipped_weapon_original = HuskCopInventory._perform_switch_equipped_weapon
function HuskCopInventory:_perform_switch_equipped_weapon(weap_index, ...)
  local default_id = weap_index <= #tweak_data.character.weap_ids and tweak_data.character.weap_ids[weap_index]
  local weap = default_id and NWC.settings.weapons[default_id]
  if NWC:check_weapon(weap) then
    NWC.npc_gun_added = { id = weap.id, default_id = default_id, unit = self._unit }
    self._unit:inventory():add_unit_by_factory_blueprint(weap.name, true, true, weap.blueprint or tweak_data.weapon.factory[weap.name].default_blueprint, weap.cosmetics)
    NWC.npc_gun_added = nil
  else
    _perform_switch_equipped_weapon_original(self, weap_index, ...)
  end
end

local _clbk_weapon_add_original = HuskCopInventory._clbk_weapon_add
function HuskCopInventory:_clbk_weapon_add(data, ...)
  self._weapon_add_clbk = nil
  if not alive(self._unit) then
    return
  end
  local default_id = data.equipped_weapon_index <= #tweak_data.character.weap_ids and tweak_data.character.weap_ids[data.equipped_weapon_index]
  local weap = default_id and NWC.settings.weapons[default_id]
  if NWC:check_weapon(weap) then
    NWC.npc_gun_added = { id = weap.id, default_id = default_id, unit = self._unit }
    self._unit:inventory():add_unit_by_factory_blueprint(weap.name, true, true, weap.blueprint or tweak_data.weapon.factory[weap.name].default_blueprint, weap.cosmetics)
    NWC.npc_gun_added = nil
  else
    _clbk_weapon_add_original(self, data, ...)
  end
end