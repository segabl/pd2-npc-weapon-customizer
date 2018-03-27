local convert_to_criminal_original = CopBrain.convert_to_criminal
function CopBrain:convert_to_criminal(...)
  convert_to_criminal_original(self, ...)

  local _, weap = self._unit:base():default_weapon_name()
  if weap then
    -- switch default gun to customized gun
    local stats = NWC:remove_equipped_gun(self._unit:inventory())
  
    NWC.npc_gun_added = { id = weap.id, sync_index = weap.sync_index, unit = self._unit }
    self._unit:inventory():add_unit_by_factory_blueprint(weap.factory_id, true, true, weap.blueprint, weap.cosmetics)
    NWC.npc_gun_added = nil
    
    local weapon_unit = self._unit:inventory():equipped_unit()
    weapon_unit:base()._damage = stats.damage or tweak_data.weapon[weap.id].DAMAGE
  end

end