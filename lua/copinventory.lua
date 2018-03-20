function CopInventory:add_unit_by_factory_blueprint(...)
  NWC.enemy_gun_added = not NWC.settings.force_hq
  HuskPlayerInventory.add_unit_by_factory_blueprint(self, ...)
  NWC.enemy_gun_added = false
end

function CopInventory:add_unit_by_factory_name(...)
  HuskPlayerInventory.add_unit_by_factory_name(self, ...)
end

local save_original = CopInventory.save
function CopInventory:save(data, ...)
  save_original(self, data, ...)
  if self._equipped_selection and self:equipped_unit():base()._original_id then
    data.equipped_weapon_index = NWC:get_weapon_id_index(self:equipped_unit():base()._name_id)
  end
end

local _send_equipped_weapon_original = CopInventory._send_equipped_weapon
function CopInventory:_send_equipped_weapon(...)
  if self:equipped_unit():base()._original_id then
    local index = NWC:get_weapon_id_index(self:equipped_unit():base()._name_id)
    self._unit:network():send("set_equipped_weapon", index, "", "nil-1-0")
  else
    _send_equipped_weapon_original(self, ...)
  end
end