for k, v in pairs(NPCRaycastWeaponBase) do
  if not NewNPCRaycastWeaponBase[k] then
    NewNPCRaycastWeaponBase[k] = v
  end
end

local use_thq_original = NewNPCRaycastWeaponBase.use_thq
function NewNPCRaycastWeaponBase:use_thq(...)
  if self._force_tp == nil then
    self._force_tp = NWC and NWC.enemy_gun_added
  end
  if self._force_tp then
    return false
  end
  return use_thq_original(self, ...)
end