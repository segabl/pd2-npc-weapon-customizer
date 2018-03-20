_G.NWC = {}
NWC.mod_path = ModPath
NWC.save_path = SavePath
NWC.settings = {
  force_hq = false,
  weapons = {
    beretta92 = { id = "beretta92_npc", name = "wpn_fps_pis_beretta_npc" },
    c45 = { id = "c45_npc", name = "wpn_fps_pis_1911_npc" },
    raging_bull = { id = "raging_bull_npc", name = "wpn_fps_pis_rage_npc" },
    m4 = { id = "m4_npc", name = "wpn_fps_ass_m4_npc" },
    ak47 = { id = "ak47_npc", name = "wpn_fps_ass_74_npc" },
    r870 = { id = "r870_npc", name = "wpn_fps_shot_r870_npc" },
    mp5 = { id = "mp5_npc", name = "wpn_fps_smg_mp5_npc" },
    mp5_tactical = { id = "mp5_tactical_npc", name = "wpn_fps_smg_mp5_npc" },
    mac11 = { id = "mac11_npc", name = "wpn_fps_smg_mac10_npc" },
    saiga = { id = "saiga_npc", name = "wpn_fps_shot_saiga_npc" },
    m249 = { id = "m249_npc", name = "wpn_fps_lmg_m249_npc" },
    benelli = { id = "benelli_npc", name = "wpn_fps_sho_ben_npc" },
    g36 = { id = "g36_npc", name = "wpn_fps_ass_g36_npc" },
    ump = { id = "ump_npc", name = "wpn_fps_smg_schakal_npc" },
    scar_murky = { id = "scar_npc", name = "wpn_fps_ass_scar_npc" },
    rpk_lmg = { id = "rpk_lmg_npc", name = "wpn_fps_lmg_rpk_npc" },
    akmsu_smg = { id = "akmsu_smg_npc", name = "wpn_fps_smg_akmsu_npc" },
    asval_smg = { id = "asval_smg_npc", name = "wpn_fps_ass_asval_npc" },
    ak47_ass = { id = "ak47_ass_npc", name = "wpn_fps_ass_74_npc" },
    x_c45 = { id = "x_c45_npc", name = "wpn_fps_x_1911_npc" },
    sg417 = { id = "contraband_npc", name = "wpn_fps_ass_contraband_npc" }
  }
}

function NWC:get_weapon_id_index(weapon)
  local index = 1
  for i, v in pairs(tweak_data.character.weap_ids) do
    if v == weapon then
      index = i
      break
    end
  end
  return index
end

function NWC:setup_weapon(unit, new_id, husk, convert, mastermind_criminal, weapon_unit)
  weapon_unit = weapon_unit or unit:inventory():get_latest_addition_hud_data().unit
  local weapon_base = weapon_unit and weapon_unit:base()
  if not weapon_base then
    return false
  end
  
  weapon_base._original_id = weapon_base._name_id
  weapon_base._name_id = new_id
  
  tweak_data.weapon[weapon_base._name_id].sounds = tweak_data.weapon[weapon_base._original_id].sounds
  tweak_data.weapon[weapon_base._name_id].hold = tweak_data.weapon[weapon_base._original_id].hold
  tweak_data.weapon[weapon_base._name_id].reload = tweak_data.weapon[weapon_base._original_id].reload
  tweak_data.weapon[weapon_base._name_id].pull_magazine_during_reload = tweak_data.weapon[weapon_base._original_id].pull_magazine_during_reload

  weapon_base:set_ammo_max(tweak_data.weapon[weapon_base._name_id].AMMO_MAX)
  weapon_base:set_ammo_total(weapon_base:get_ammo_max())
  weapon_base:set_ammo_max_per_clip(tweak_data.weapon[weapon_base._name_id].CLIP_AMMO_MAX)
  weapon_base:set_ammo_remaining_in_clip(weapon_base:get_ammo_max_per_clip())

  local damage_multiplier = 1
  if convert then
    if alive(mastermind_criminal) then
      damage_multiplier = damage_multiplier * (mastermind_criminal:base():upgrade_value("player", "convert_enemies_damage_multiplier") or 1)
      damage_multiplier = damage_multiplier * (mastermind_criminal:base():upgrade_value("player", "passive_convert_enemies_damage_multiplier") or 1)
    else
      damage_multiplier = damage_multiplier * managers.player:upgrade_value("player", "convert_enemies_damage_multiplier", 1)
      damage_multiplier = damage_multiplier * managers.player:upgrade_value("player", "passive_convert_enemies_damage_multiplier", 1)
    end
  end
  
  weapon_base._damage = tweak_data.weapon[weapon_base._name_id].DAMAGE * damage_multiplier

  if not convert then
    weapon_base._alert_size = tweak_data.weapon[weapon_base._name_id].alert_size
    weapon_base._suppression = tweak_data.weapon[weapon_base._name_id].suppression
    weapon_base._bullet_slotmask = husk and managers.slot:get_mask("bullet_impact_targets_no_AI") or managers.slot:get_mask("bullet_impact_targets") or weapon_base._bullet_slotmask
    weapon_base._hit_player = true
    weapon_base._setup.alert_filter = unit:brain():SO_access()
    weapon_base._setup.hit_slotmask = weapon_base._bullet_slotmask
    weapon_base._setup.hit_player = weapon_base._hit_player
    weapon_base._setup.ignore_units = {
      unit,
      weapon_base._unit,
      unit:inventory()._shield_unit
    }
  end
  
  weapon_base._fire_raycast = NPCRaycastWeaponBase._fire_raycast
  
  if weapon_base.AKIMBO and alive(weapon_base._second_gun) then
    self:setup_weapon(unit, new_id, husk, convert, mastermind_criminal, weapon_base._second_gun)
  end
  
  return true
end

function NWC:open_weapon_category_menu(category, weapon)
  local loadout = self.settings.weapons[weapon] or {}
  local new_node_data = {category = category}
  local selected_tab = self:create_pages(new_node_data, weapon, "weapon", loadout.slot, tweak_data.gui.WEAPON_ROWS_PER_PAGE, tweak_data.gui.WEAPON_COLUMNS_PER_PAGE, tweak_data.gui.MAX_WEAPON_PAGES, loadout.category or "primaries")
  new_node_data.can_move_over_tabs = true
  new_node_data.selected_tab = selected_tab
  new_node_data.scroll_tab_anywhere = true
  new_node_data.hide_detection_panel = true
  new_node_data.custom_callback = {
    w_equip = callback(self, self, "select_weapon", weapon),
    w_unequip = callback(self, self, "select_weapon", weapon)
  }
  new_node_data.topic_id = "bm_menu_" .. category
  new_node_data.topic_params = {
    weapon_category = managers.localization:text("bm_menu_weapons")
  }
  managers.menu:open_node("blackmarket_node", {new_node_data})
end

function NWC:buy_new_weapon(data, gui)
  gui:open_weapon_buy_menu(data, function () return true end)
end

function NWC:create_pages(new_node_data, params, identifier, selected_slot, rows, columns, max_pages)
  local category = new_node_data.category
  rows = rows or 3
  columns = columns or 3
  max_pages = max_pages or 8
  local items_per_page = rows * columns
  local item_data = nil
  local selected_tab = 1
  for page = 1, max_pages, 1 do
    local index = 1
    local start_i = 1 + items_per_page * (page - 1)
    item_data = {}
    for i = start_i, items_per_page * page, 1 do
      item_data[index] = i
      index = index + 1
      if i == selected_slot then
        selected_tab = page
      end
    end
    local name_id = managers.localization:to_upper_text("bm_menu_page", {page = tostring(page)})
    table.insert(new_node_data, {
      prev_node_data = false,
      allow_preview = true,
      name = category,
      category = category,
      start_i = start_i,
      name_localized = name_id,
      on_create_func = callback(self, self, "populate_weapons", params),
      on_create_data = item_data,
      identifier = BlackMarketGui.identifiers[identifier],
      override_slots = {
        columns,
        rows
      }
    })
  end
  return selected_tab
end

function NWC:populate_weapons(weapon, data, gui)
  gui:populate_weapon_category_new(data)
  local loadout = self.settings.weapons[weapon] or {}
  for k, v in ipairs(data) do
    local tweak = tweak_data.weapon[v.name]
    v.equipped = loadout.slot == v.slot and loadout.category == v.category
    if v.equipped then
      v.buttons = {"w_unequip"}
    elseif not v.empty_slot then
      v.buttons = {"w_equip"}
    end
    v.comparision_data = nil
    v.mini_icons = nil
  end
end

function NWC:select_weapon(weapon, data, gui)
  local loadout = self.settings.weapons[weapon] or {}
  if not data or data.equipped then
    loadout = nil
  else
    local crafted = managers.blackmarket:get_crafted_category_slot(data.category, data.slot)
    loadout.name = crafted.factory_id .. "_npc"
    loadout.blueprint = crafted.blueprint
    loadout.cosmetics = crafted.cosmetics
    loadout.slot = data.slot
    loadout.category = data.category
  end
  self.settings.weapons[weapon] = loadout
  return gui and gui:reload()
end

function NWC:show_weapon_selection(weapon)
  local menu_title = managers.localization:text("NWC_menu_select_category")
  local menu_message = ""
  local menu_options = {
    {
      text = managers.localization:text("bm_menu_primaries"),
      callback = function () self:open_weapon_category_menu("primaries", weapon) end
    },
    {
      text = managers.localization:text("bm_menu_secondaries"),
      callback = function () self:open_weapon_category_menu("secondaries", weapon) end
    },
    {--[[seperator]]},
    {
      text = managers.localization:text("menu_back"),
      is_cancel_button = true
    }
  }
  QuickMenu:new(menu_title, menu_message, menu_options, true)
end

function NWC:save()
  local file = io.open(self.save_path .. "NWC_settings.txt", "w+")
  if file then
    file:write(json.encode(self.settings))
    file:close()
  end
end

function NWC:load()
  local file = io.open(self.save_path .. "NWC_settings.txt", "r")
  if file then
    local data = json.decode(file:read("*all")) or {}
    file:close()
    for k, v in pairs(data) do
      if type(v) == "table" then
        self.settings[k] = self.settings[k] or {}
        for k2, v2 in pairs(v) do
          self.settings[k][k2] = v2
        end
      else
        self.settings[k] = v
      end
    end
  end
end

Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInitNWC", function(loc)
  
  local system_language_key = SystemInfo:language():key()
  local system_is_english = system_language_key == Idstring("english"):key()
  local blt_language = BLT.Localization:get_language().language
  local language = "english"
  
  for _, filename in pairs(file.GetFiles(NWC.mod_path .. "loc/") or {}) do
    local str = filename:match("^(.*).txt$")
    if str then
      local system_match = not system_is_english and Idstring(str):key() == system_language_key
      local blt_match = system_is_english and str == blt_language
      local mod_match = false
      if system_match or blt_match or mod_match then
        language = str
        break
      end
    end
  end
  
  loc:load_localization_file(NWC.mod_path .. "loc/english.txt")
  loc:load_localization_file(NWC.mod_path .. "loc/" .. language .. ".txt")

end)

local menu_id_main = "NWCMenu"
Hooks:Add("MenuManagerSetupCustomMenus", "MenuManagerSetupCustomMenusNWC", function(menu_manager, nodes)
  MenuHelper:NewMenu(menu_id_main)
end)

Hooks:Add("MenuManagerPopulateCustomMenus", "MenuManagerPopulateCustomMenusNWC", function(menu_manager, nodes)

  NWC:load()

  MenuCallbackHandler.NWC_save = function ()
    NWC:save()
  end
  
  MenuCallbackHandler.NWC_toggle = function(self, item)
    NWC.settings[item:name()] = item:value() == "on"
  end

  MenuHelper:AddToggle({
    id = "force_hq",
    title = "NWC_menu_force_hq",
    desc = "NWC_menu_force_hq_desc",
    callback = "NWC_toggle",
    value = NWC.settings.force_hq,
    menu_id = menu_id_main,
    priority = 100
  })
  
  if not Utils:IsInGameState() then
    MenuHelper:AddDivider({
      id = "divider",
      size = 16,
      menu_id = menu_id_main,
      priority = 99
    })
    
    local priority = 90
    for k, v in pairs(NWC.settings.weapons) do
      
      priority = priority - 1
      
      MenuCallbackHandler["NWC_setup_" .. k] = function (self)
        NWC:show_weapon_selection(k)
      end
      
      MenuHelper:AddButton({
        id = "weapon_" .. k,
        title = k:pretty(),
        callback = "NWC_setup_" .. k,
        menu_id = menu_id_main,
        localized = false,
        priority = priority
      })
      
    end
  end
  
end)

Hooks:Add("MenuManagerBuildCustomMenus", "MenuManagerBuildCustomMenusPlayerNWC", function(menu_manager, nodes)
  nodes[menu_id_main] = MenuHelper:BuildMenu(menu_id_main, { back_callback = "NWC_save" })
  MenuHelper:AddMenuItem(nodes["blt_options"], menu_id_main, "NWC_menu_main_name", "NWC_menu_main_desc")
end)