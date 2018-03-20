local default_weapon_name_original = CopBase.default_weapon_name
function CopBase:default_weapon_name()
  return default_weapon_name_original(self), NWC.settings.weapons[self._default_weapon_id], self._default_weapon_id
end