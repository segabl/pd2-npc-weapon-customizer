local add_weapons_original = CopMovement.add_weapons
function CopMovement:add_weapons()
  local _, weap, default_id = self._ext_base:default_weapon_name()
  if NWC:check_weapon(weap) then
    NWC.npc_gun_added = { id = weap.id, default_id = default_id, unit = self._unit }
    self._unit:inventory():add_unit_by_factory_blueprint(weap.name, true, true, weap.blueprint or tweak_data.weapon.factory[weap.name].default_blueprint, weap.cosmetics)
    NWC.npc_gun_added = nil
  else
    add_weapons_original(self)
  end
end