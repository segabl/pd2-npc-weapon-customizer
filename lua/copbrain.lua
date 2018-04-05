local convert_to_criminal_original = CopBrain.convert_to_criminal
function CopBrain:convert_to_criminal(...)
  convert_to_criminal_original(self, ...)

  local equipped_w_selection = unit:inventory():equipped_selection()
  local weap = equipped_w_selection and NWC:get_weapon_by_tweak_id(unit:inventory():equipped_unit():base()._name_id)
  if weap then
    -- switch default gun to customized gun
    local damage = inventory:equipped_unit():base()._damage
    unit:inventory():remove_selection(equipped_w_selection, true)
  
    NWC.npc_gun_added = { id = weap.id, sync_index = weap.sync_index, unit = self._unit }
    self._unit:inventory():add_unit_by_factory_blueprint(weap.factory_id, true, true, weap.blueprint, weap.cosmetics)
    NWC.npc_gun_added = nil
    
    local weapon_unit = self._unit:inventory():equipped_unit()
    weapon_unit:base()._damage = stats.damage or tweak_data.weapon[weap.id].DAMAGE
  end

end