local convert_to_criminal_original = CopBrain.convert_to_criminal
function CopBrain:convert_to_criminal(...)
  convert_to_criminal_original(self, ...)

  local _, weap, sync_index = self._unit:base():default_weapon_name()
  if NWC:check_weapon(weap) then
    -- switch default gun to customized gun
    local damage = tweak_data.weapon[weap.id].DAMAGE
    local equipped_w_selection = self._unit:inventory():equipped_selection()
    if equipped_w_selection then
      damage = self._unit:inventory():equipped_unit():base()._damage
      self._unit:inventory():remove_selection(equipped_w_selection, true)
    end
  
    NWC.npc_gun_added = { id = weap.id, sync_index = sync_index, unit = self._unit }
    TeamAIInventory.add_unit_by_factory_blueprint(self._unit:inventory(), weap.name, true, true, weap.blueprint or tweak_data.weapon.factory[weap.name].default_blueprint, weap.cosmetics)
    NWC.npc_gun_added = nil
    
    local weapon_unit = self._unit:inventory():equipped_unit()
    weapon_unit:base()._damage = damage
  end

end