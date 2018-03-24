local default_weapon_name_original = CopBase.default_weapon_name
function CopBase:default_weapon_name(...)
  -- in addition to the weapon name also return the weapon setup in the mod and the original weapon index
  return default_weapon_name_original(self, ...), NWC:get_weapon(self._default_weapon_id), NWC:get_weapon_id_index(self._default_weapon_id)
end