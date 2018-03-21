local _set_converted_police_original = GroupAIStateBase._set_converted_police
function GroupAIStateBase:_set_converted_police(u_key, unit, ...)
  _set_converted_police_original(self, u_key, unit, ...)
  
  if not alive(unit) then
    return
  end
  
  -- changing joker's guns here so it works both as host and client
  local _, weap, default_id = unit:base():default_weapon_name()
  if NWC:check_weapon(weap) then
    local damage = tweak_data.weapon[weap.id].DAMAGE
    local equipped_w_selection = unit:inventory():equipped_selection()
    if equipped_w_selection then
      damage = unit:inventory():equipped_unit():base()._damage
      unit:inventory():remove_selection(equipped_w_selection, true)
    end
  
    NWC.npc_gun_added = { id = weap.id, default_id = default_id, unit = unit, is_joker = true }
    TeamAIInventory.add_unit_by_factory_blueprint(unit:inventory(), weap.name, true, true, weap.blueprint or tweak_data.weapon.factory[weap.name].default_blueprint, weap.cosmetics)
    NWC.npc_gun_added = nil
    
    local weapon_unit = unit:inventory():equipped_unit()
    weapon_unit:base()._damage = damage
    
  end
  
end