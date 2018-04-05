local init_original = CopInventory.init
function CopInventory:init(...)
  init_original(self, ...)
  self._is_cop_inventory = true
end

local add_unit_original = CopInventory.add_unit
function CopInventory:add_unit(new_unit, ...)
  -- right before a weapon is added to inventory, check for a replacement
  local replacement_data = self._is_cop_inventory and NWC:get_weapon(new_unit:base()._name_id)
  if replacement_data then
    local old_unit = new_unit
    local old_base = old_unit:base()

    -- load and spawn replacement weapon
    local factory_weapon = tweak_data.weapon.factory[replacement_data.factory_id]
    local ids_unit_name = Idstring(factory_weapon.unit)
    if not managers.dyn_resource:is_resource_ready(Idstring("unit"), ids_unit_name, managers.dyn_resource.DYN_RESOURCES_PACKAGE) then
      managers.dyn_resource:load(Idstring("unit"), ids_unit_name, managers.dyn_resource.DYN_RESOURCES_PACKAGE)
    end
    new_unit = World:spawn_unit(Idstring(factory_weapon.unit), Vector3(), Rotation())
    
    local new_base = new_unit:base()
    local original_id = new_base._name_id

    -- save original name
    new_base._old_name = old_unit:name()

    -- fix init data
    new_base._name_id = old_base._name_id
    new_base._damage = old_base._damage
    new_base:set_ammo_max(tweak_data.weapon[new_base._name_id].AMMO_MAX)
    new_base:set_ammo_total(new_base:get_ammo_max())
    new_base:set_ammo_max_per_clip(tweak_data.weapon[new_base._name_id].CLIP_AMMO_MAX)
    new_base:set_ammo_remaining_in_clip(new_base:get_ammo_max_per_clip())

    -- setup tweak data links
    if not NWC.tweak_setups[new_base._name_id] then
      if not NWC.settings.keep_sounds and not tweak_data.weapon[new_base._name_id].sounds.prefix:match("sniper_npc") then
        tweak_data.weapon[new_base._name_id].sounds = tweak_data.weapon[original_id].sounds
      end
      if not NWC.settings.keep_types and not self._shield_unit_name then
        tweak_data.weapon[new_base._name_id].hold = tweak_data.weapon[original_id].hold
        tweak_data.weapon[new_base._name_id].reload = tweak_data.weapon[original_id].reload
        tweak_data.weapon[new_base._name_id].pull_magazine_during_reload = tweak_data.weapon[original_id].pull_magazine_during_reload
      end
      NWC.tweak_setups[new_base._name_id] = true
    end

    -- disable thq if needed
    if not (NWC:is_joker(self._unit) and NWC.settings.jokers_hq) and not (NWC:is_special(self._unit) and NWC.settings.specials_hq) and not NWC.settings.force_hq then
      new_base.use_thq = function () return false end
    end

    -- plug old raycast function
    new_base._fire_raycast = NPCRaycastWeaponBase._fire_raycast

    new_base:set_factory_data(replacement_data.factory_id)
    new_base:set_cosmetics_data(replacement_data.cosmetics)
    new_base:assemble_from_blueprint(replacement_data.factory_id, replacement_data.blueprint)
    new_base:check_npc()

    local setup_data = old_base._setup
    setup_data.ignore_units = {
      self._unit,
      new_unit,
      self._shield_unit
    }
    new_base:setup(setup_data)

    if new_base.AKIMBO then
      new_base:create_second_gun()
    end

    -- remove originally spawned weapon
    if alive(old_base._second_gun) then
      old_base._second_gun:set_slot(0)
      World:delete_unit(old_base._second_gun)
    end
    old_unit:set_slot(0)
    World:delete_unit(old_unit)
  end
  return add_unit_original(self, new_unit, ...)
end

local save_original = CopInventory.save
function CopInventory:save(data, ...)
  save_original(self, data, ...)
  -- change the sync index to the original weapon's index
  local old_name = self._equipped_selection and self:equipped_unit():base()._old_name
  if old_name then
    data.equipped_weapon_index = self._get_weapon_sync_index(old_name) or 4
  end
end

local _send_equipped_weapon_original = CopInventory._send_equipped_weapon
function CopInventory:_send_equipped_weapon(...)
  -- same thing here
  local old_name = self:equipped_unit():base()._old_name
  if old_name then
    self._unit:network():send("set_equipped_weapon", self._get_weapon_sync_index(old_name) or 4, "", "nil-1-0")
  else
    _send_equipped_weapon_original(self, ...)
  end
end