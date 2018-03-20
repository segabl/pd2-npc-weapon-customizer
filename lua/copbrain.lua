local convert_to_criminal_original = CopBrain.convert_to_criminal
function CopBrain:convert_to_criminal(mastermind_criminal, ...)
  convert_to_criminal_original(self, mastermind_criminal, ...)

  local _, weap, default_id = self._unit:base():default_weapon_name()
  if NWC:check_weapon(weap) then
    local equipped_w_selection = self._unit:inventory():equipped_selection()
    if equipped_w_selection then
      self._unit:inventory():remove_selection(equipped_w_selection, true)
    end
  
    NWC.npc_gun_added = { id = weap.id, default_id = default_id, unit = self._unit }
    TeamAIInventory.add_unit_by_factory_blueprint(self._unit:inventory(), weap.name, true, true, weap.blueprint or tweak_data.weapon.factory[weap.name].default_blueprint, weap.cosmetics)
    NWC.npc_gun_added = nil
    
    local damage_multiplier = 1
    if alive(mastermind_criminal) then
      damage_multiplier = damage_multiplier * (mastermind_criminal:base():upgrade_value("player", "convert_enemies_damage_multiplier") or 1)
      damage_multiplier = damage_multiplier * (mastermind_criminal:base():upgrade_value("player", "passive_convert_enemies_damage_multiplier") or 1)
    else
      damage_multiplier = damage_multiplier * managers.player:upgrade_value("player", "convert_enemies_damage_multiplier", 1)
      damage_multiplier = damage_multiplier * managers.player:upgrade_value("player", "passive_convert_enemies_damage_multiplier", 1)
    end
    
    local weapon_unit = self._unit:inventory():equipped_unit()
    weapon_unit:base():add_damage_multiplier(damage_multiplier)
    
  end

end