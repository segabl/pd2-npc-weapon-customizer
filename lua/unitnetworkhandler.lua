local mark_minion_original = UnitNetworkHandler.mark_minion
function UnitNetworkHandler:mark_minion(unit, minion_owner_peer_id, convert_enemies_health_multiplier_level, passive_convert_enemies_health_multiplier_level, sender, ...)
  if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character_and_sender(unit, sender) then
    return
  end
  
  mark_minion_original(self, unit, minion_owner_peer_id, convert_enemies_health_multiplier_level, passive_convert_enemies_health_multiplier_level, sender, ...)

  local equipped_w_selection = unit:inventory():equipped_selection()
  local weap = equipped_w_selection and NWC:get_weapon_by_tweak_id(unit:inventory():equipped_unit():base()._name_id)
  if weap then
    -- switch default gun to customized gun
    unit:inventory():remove_selection(equipped_w_selection, true)
  
    NWC.npc_gun_added = { id = weap.id, sync_index = weap.sync_index, unit = unit }
    unit:inventory():add_unit_by_factory_blueprint(weap.factory_id, true, true, weap.blueprint, weap.cosmetics)
    NWC.npc_gun_added = nil
  end

end