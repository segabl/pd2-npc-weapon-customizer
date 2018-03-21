_G.NWC = {}
NWC.mod_path = ModPath
NWC.save_path = SavePath
NWC.is_client = Network:is_client()
NWC.tweak_setups = {}
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
    sg417 = { id = "contraband_npc", name = "wpn_fps_ass_contraband_npc" },
    mini = { id = "mini_npc", name = "wpn_fps_lmg_m134_npc" }
  }
}

function NWC:get_weapon_id_index(weapon)
  local index = 1
  for i, v in ipairs(tweak_data.character.weap_ids) do
    if v == weapon then
      index = i
      break
    end
  end
  return index
end

function NWC:check_weapon(weapon)
  return weapon and weapon.id and weapon.name and tweak_data.weapon.factory[weapon.name] and true or false
end

function NWC:is_joker(unit)
  local movement = alive(unit) and unit:movement()
  local team = movement and movement.team and movement:team() or {}
  return team.id == "converted_enemy"
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

function NWC:create_pages(new_node_data, weapon, identifier, selected_slot, rows, columns, max_pages)
  local category = new_node_data.category
  local loadout = self.settings.weapons[weapon] or {}
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
      if i == selected_slot and category == loadout.category then
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
      on_create_func = callback(self, self, "populate_weapons", weapon),
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
    v.equipped = not v.locked_slot and not v.empty_slot and loadout.slot == v.slot and loadout.category == v.category and v.name
    v.unlocked = true
    v.lock_texture = nil
    v.lock_text = nil
    v.comparision_data = nil
    v.buttons = not v.empty_slot and {v.equipped and "w_unequip" or "w_equip", "w_mod", "w_preview", "w_sell"} or {v.locked_slot and "ew_unlock" or "ew_buy"}
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

function NWC:merge_tables(tbl1, tbl2)
  for k, v in pairs(tbl2) do
    if type(tbl1[k]) == "table" and type(v) == "table" then
      NWC:merge_tables(tbl1[k], v)
    else
      tbl1[k] = v
    end
  end
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
    NWC:merge_tables(self.settings, data)
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
  
end)

Hooks:Add("MenuManagerBuildCustomMenus", "MenuManagerBuildCustomMenusPlayerNWC", function(menu_manager, nodes)
  nodes[menu_id_main] = MenuHelper:BuildMenu(menu_id_main, { back_callback = "NWC_save" })
  MenuHelper:AddMenuItem(nodes["blt_options"], menu_id_main, "NWC_menu_main_name", "NWC_menu_main_desc")
end)