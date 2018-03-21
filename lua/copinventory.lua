CopInventory.add_unit_by_factory_blueprint = HuskPlayerInventory.add_unit_by_factory_blueprint
CopInventory.add_unit_by_factory_name = HuskPlayerInventory.add_unit_by_factory_name

local save_original = CopInventory.save
function CopInventory:save(data, ...)
  save_original(self, data, ...)
  if self._equipped_selection and self:equipped_unit():base()._sync_index then
    -- change the sync index to the original weapon's index
    data.equipped_weapon_index = self:equipped_unit():base()._sync_index
  end
end

local _send_equipped_weapon_original = CopInventory._send_equipped_weapon
function CopInventory:_send_equipped_weapon(...)
  if self:equipped_unit():base()._sync_index then
    -- same thing here
    self._unit:network():send("set_equipped_weapon", self:equipped_unit():base()._sync_index, "", "nil-1-0")
  else
    _send_equipped_weapon_original(self, ...)
  end
end