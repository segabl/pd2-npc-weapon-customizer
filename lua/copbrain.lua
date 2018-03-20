local convert_to_criminal_original = CopBrain.convert_to_criminal
function CopBrain:convert_to_criminal(mastermind_criminal, ...)
  convert_to_criminal_original(self, mastermind_criminal, ...)

  local _, weap = self._unit:base():default_weapon_name()
  if weap then
    local equipped_w_selection = self._unit:inventory():equipped_selection()
    if equipped_w_selection then
      self._unit:inventory():remove_selection(equipped_w_selection, true)
    end
  
    TeamAIInventory.add_unit_by_factory_blueprint(self._unit:inventory(), weap.name, true, true, weap.blueprint or tweak_data.weapon.factory[weap.name].default_blueprint, weap.cosmetics)
    NWC:setup_weapon(self._unit, nil, weap.id, false, true, mastermind_criminal)
    
  end

end