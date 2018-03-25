_G.NWC = {}
NWC.mod_path = ModPath
NWC.save_path = SavePath
NWC.is_client = Network:is_client()
NWC.tweak_setups = {}
NWC.dropable_mods = {}
NWC.weapons = {}
NWC.weapon_info = {
  beretta92 = { id = "beretta92_npc", factory_id = "wpn_fps_pis_beretta" },
  c45 = { id = "c45_npc", factory_id = "wpn_fps_pis_g17" },
  raging_bull = { id = "raging_bull_npc", factory_id = "wpn_fps_pis_rage" },
  m4 = { id = "m4_npc", factory_id = "wpn_fps_ass_m4" },
  ak47 = { id = "ak47_npc", factory_id = "wpn_fps_ass_74" },
  r870 = { id = "r870_npc", factory_id = "wpn_fps_shot_r870" },
  mossberg = { id = "mossberg_npc", factory_id = "wpn_fps_shot_huntsman" },
  mp5 = { id = "mp5_npc", factory_id = "wpn_fps_smg_mp5" },
  mp5_tactical = { id = "mp5_tactical_npc", factory_id = "wpn_fps_smg_mp5" },
  mp9 = { id = "mp9_npc", factory_id = "wpn_fps_smg_mp9" },
  mac11 = { id = "mac11_npc", factory_id = "wpn_fps_smg_mac10" },
  m14_sniper_npc = { id = "m14_sniper_npc", factory_id = "wpn_fps_ass_g3" },
  saiga = { id = "saiga_npc", factory_id = "wpn_fps_shot_saiga" },
  m249 = { id = "m249_npc", factory_id = "wpn_fps_lmg_m249" },
  benelli = { id = "benelli_npc", factory_id = "wpn_fps_sho_ben" },
  g36 = { id = "g36_npc", factory_id = "wpn_fps_ass_g36" },
  ump = { id = "ump_npc", factory_id = "wpn_fps_smg_schakal" },
  scar_murky = { id = "scar_npc", factory_id = "wpn_fps_ass_scar" },
  rpk_lmg = { id = "rpk_lmg_npc", factory_id = "wpn_fps_lmg_rpk" },
  svd_snp = { id = "svd_snp_npc", factory_id = "wpn_fps_snp_siltstone" },
  akmsu_smg = { id = "akmsu_smg_npc", factory_id = "wpn_fps_smg_akmsu" },
  asval_smg = { id = "asval_smg_npc", factory_id = "wpn_fps_ass_asval" },
  sr2_smg = { id = "sr2_smg_npc", factory_id = "wpn_fps_smg_sr2" },
  ak47_ass = { id = "ak47_ass_npc", factory_id = "wpn_fps_ass_74" },
  x_c45 = { id = "x_c45_npc", factory_id = "wpn_fps_pis_x_g17" },
  sg417 = { id = "contraband_npc", factory_id = "wpn_fps_ass_contraband" },
  svdsil_snp = { id = "svdsil_snp_npc", factory_id = "wpn_fps_snp_siltstone" },
  mini = { id = "mini_npc", factory_id = "wpn_fps_lmg_m134" },
  heavy_zeal_sniper = { id = "heavy_snp_npc", factory_id = "wpn_fps_ass_g3" }
}
NWC.settings = {
  add_animations = true,
  force_hq = false,
  jokers_hq = true,
  specials_hq = false,
  keep_types = false,
  keep_sounds = false,
  weapons = {}
}

function NWC:get_sync_index(weapon)
  local index = 1
  for i, v in ipairs(tweak_data.character.weap_ids) do
    if v == weapon then
      index = i
      break
    end
  end
  return index
end

function NWC:get_weapon_by_tweak_id(tweak_id)
  for k, v in pairs(self.weapon_info) do
    if v.id == tweak_id then
      return self:get_weapon(k)
    end
  end
end

function NWC:get_weapon(weap_id)
  if self.weapons[weap_id] == nil then
    local weapon_info = self.weapon_info[weap_id]
    if not weapon_info then
      self:clear_weapon(weap_id)
      self.weapons[weap_id] = false
      return
    end
    local weapon = self.settings.weapons[weap_id]
    local crafted = weapon and weapon.category and weapon.slot and managers.blackmarket:get_crafted_category_slot(weapon.category, weapon.slot)
    if crafted and self:has_npc_weapon_version(crafted.factory_id) then
      self.weapons[weap_id] = {
        sync_index = self:get_sync_index(weap_id),
        id = self.weapon_info[weap_id].id,
        factory_id = crafted.factory_id .. "_npc",
        blueprint = crafted.blueprint,
        cosmetics = crafted.cosmetics,
        name = crafted.custom_name and "\"" .. crafted.custom_name .. "\"" or managers.localization:text(tweak_data.weapon[crafted.weapon_id].name_id),
        icon = managers.blackmarket:get_weapon_icon_path(crafted.weapon_id, crafted.cosmetics),
        category = weapon.category,
        slot = weapon.slot,
      }
    else
      self:clear_weapon(weap_id)
      local weapon_id = managers.weapon_factory:get_weapon_id_by_factory_id(self.weapon_info[weap_id].factory_id)
      self.weapons[weap_id] = {
        sync_index = self:get_sync_index(weap_id),
        id = self.weapon_info[weap_id].id,
        factory_id = self.weapon_info[weap_id].factory_id .. "_npc",
        blueprint = tweak_data.weapon.factory[self.weapon_info[weap_id].factory_id].default_blueprint,
        name = managers.localization:text(tweak_data.weapon[weapon_id].name_id) .. " (" .. managers.localization:text("NWC_menu_mod_default") .. ")",
        icon = managers.blackmarket:get_weapon_icon_path(weapon_id)
      }
    end
  end
  return self.weapons[weap_id]
end

function NWC:clear_weapon(weap_id)
  self.weapons[weap_id] = nil
  self.settings.weapons[weap_id] = nil
end

function NWC:has_npc_weapon_version(factory_id)
  local factory_data = factory_id and tweak_data.weapon.factory[factory_id .. "_npc"]
  return factory_data and (not factory_data.custom or DB:has(Idstring("unit"), factory_data.unit:id()))
end

function NWC:is_joker(unit)
  if not alive(unit) then
    return false
  end
  local u_key = unit:key()
  local gstate = managers.groupai:state()
  return gstate._police[u_key] and gstate._police[u_key].is_converted or false
end

function NWC:is_special(unit)
  if not alive(unit) then
    return false
  end
  return tweak_data.character[unit:base()._tweak_table].priority_shout and true
end

--[[
function NWC:create_random_blueprint(weapon)
  weapon.blueprint = weapon.blueprint or tweak_data.weapon.factory[weapon.name].default_blueprint
  if not self.dropable_mods[weapon.name] then
    local weapon_id = managers.weapon_factory:get_weapon_id_by_factory_id(weapon.name:gsub("_npc$", ""))
    if not weapon_id then
      return
    end
    self.dropable_mods[weapon.name] = managers.blackmarket:get_dropable_mods_by_weapon_id(weapon_id)
  end
  for part_type, parts_data in pairs(self.dropable_mods[weapon.name]) do
    if math.random() < 1 then
      local part_data = table.random(parts_data)
      if part_data then
        managers.weapon_factory:change_part_blueprint_only(weapon.name, part_data[1], weapon.blueprint)
      end
    end
  end
end
]]

function NWC:open_weapon_category_menu(category, weap_id)
  local new_node_data = {
    prev_node_data = false,
    category = category,
    can_move_over_tabs = true,
    scroll_tab_anywhere = true,
    hide_detection_panel = true,
    custom_callback = {
      w_equip = callback(self, self, "select_weapon", weap_id),
      w_unequip = callback(self, self, "select_weapon", weap_id)
    },
    back_callback = function ()
      self:set_menu_state(true)
    end,
    topic_id = "bm_menu_" .. category
  }
  new_node_data.selected_tab = self:create_pages(new_node_data, weap_id, "weapon", tweak_data.gui.WEAPON_ROWS_PER_PAGE, tweak_data.gui.WEAPON_COLUMNS_PER_PAGE, tweak_data.gui.MAX_WEAPON_PAGES)
  managers.menu:open_node("blackmarket_node", {new_node_data})
end

function NWC:create_pages(new_node_data, weap_id, identifier, rows, columns, max_pages)
  local category = new_node_data.category
  local weapon = self:get_weapon(weap_id) or {}
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
      if i == weapon.slot and category == weapon.category then
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
      on_create_func = callback(self, self, "populate_weapons", weap_id),
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

function NWC:populate_weapons(weap_id, data, gui)
  gui:populate_weapon_category_new(data)
  local weapon = self:get_weapon(weap_id) or {}
  for k, v in ipairs(data) do
    if v.empty_slot or self:has_npc_weapon_version(managers.weapon_factory:get_factory_id_by_weapon_id(v.name)) then
      v.equipped = not v.locked_slot and not v.empty_slot and weapon.slot == v.slot and weapon.category == v.category
      v.unlocked = true
      v.lock_texture = v.locked_slot and v.lock_texture
      v.lock_text = v.locked_slot and v.lock_text
      v.comparision_data = nil
      v.buttons = v.empty_slot and {v.locked_slot and "ew_unlock" or "ew_buy"} or {v.equipped and "w_unequip" or "w_equip", "w_mod", "w_preview", "w_sell"}
    else
      v.buttons = {}
      v.unlocked = false
      v.lock_texture = "guis/textures/pd2/lock_incompatible"
      v.lock_text = managers.localization:text("NWC_menu_locked_slot")
    end
  end
end

function NWC:select_weapon(weap_id, data, gui)
  self.weapons[weap_id] = nil
  if not data or data.equipped then
    self:clear_weapon(weap_id)
  else
    self.settings.weapons[weap_id] = self.settings.weapons[weap_id] or {}
    self.settings.weapons[weap_id].category = data.category
    self.settings.weapons[weap_id].slot = data.slot
  end
  self:save()
  gui:reload()
end

function NWC:show_weapon_selection(title, weap_id)
  local menu_title = title
  local weapon = self:get_weapon(weap_id)
  local menu_message
  if weapon and weapon.name then
    menu_message = managers.localization:text("NWC_menu_weapon_message", { WEAPON = weapon.name })
  else
    menu_message = managers.localization:text("NWC_menu_weapon_message_default")
  end
  local menu_options = {
    {
      text = managers.localization:text("NWC_menu_select_from_primaries"),
      callback = function ()
        self:set_menu_state(false)
        self:open_weapon_category_menu("primaries", weap_id)
      end
    },
    {
      text = managers.localization:text("NWC_menu_select_from_secondaries"),
      callback = function ()
        self:set_menu_state(false)
        self:open_weapon_category_menu("secondaries", weap_id)
      end
    },
    {
      text = managers.localization:text("NWC_menu_use_default"),
      callback = function ()
        self:clear_weapon(weap_id)
        self:save()
        self:refresh_menu()
      end
    },
    {--[[seperator]]},
    {
      text = managers.localization:text("menu_back"),
      is_cancel_button = true
    }
  }
  QuickMenu:new(menu_title, menu_message, menu_options, true)
end

function NWC:npc_weapon_name(weap_id)
  local loc = managers.localization
  local weapon_id = managers.weapon_factory:get_weapon_id_by_factory_id(self.weapon_info[weap_id].factory_id)
  NWC._weapon_names = NWC._weapon_names or {
    ak47 = loc:text("bm_w_ak74") .. " (Mobster)",
    mp5_tactical = loc:text("bm_w_mp5") .. " (Cloaker)",
    m14_sniper_npc = loc:text("bm_w_g3") .. " (Sniper)",
    svd_snp = loc:text("bm_w_siltstone") .. " (Russian Sniper)",
    ak47_ass = loc:text("bm_w_ak74") .. " (Russian)",
    svdsil_snp = loc:text("bm_w_siltstone") .. " (Mobster Sniper)",
    heavy_zeal_sniper = loc:text("bm_w_g3") .. " (ZEAL Sniper)"
  }
  return NWC._weapon_names[weap_id] or loc:text(tweak_data.weapon[weapon_id].name_id)
end

function NWC:fit_texture(item, h_offset)
  local texture_width = item.img:texture_width()
  local texture_height = item.img:texture_height()
  local panel_width, panel_height = item.img:parent():size()
  local target_w = item.img:parent():w()
  local target_h = item.img:parent():h() - h_offset
  local aspect = target_w / target_h
  local sw = math.max(texture_width, texture_height * aspect)
  local sh = math.max(texture_height, texture_width / aspect)
  local dw = texture_width / sw
  local dh = texture_height / sh
  item.img:set_size(math.round(dw * target_w), math.round(dh * target_h))
  item.img:set_center(target_w / 2, target_h / 2 + h_offset)
end

function NWC:check_create_menu()

  if self.menu then
    return
  end

  local padding = 16
  local accent = Color("0bce99")

  self.menu = MenuUI:new({
    name = "NWCMenu",
    layer = 1000,
    background_blur = true,
    animate_toggle = true,
    text_offset = 8,
    show_help_time = 0.5,
    border_size = 1,
    accent_color = accent:with_alpha(0.5),
    highlight_color = accent:with_alpha(0.075),
    localized = true,
    use_default_close_key = true
  })
  
  local menu_w = self.menu._panel:w()
  local menu_h = self.menu._panel:h()

  local menu_w_left = menu_w / 3 - padding
  local menu_w_right = menu_w - menu_w_left - padding * 2

  local menu = self.menu:Menu({
    name = "NWCMainMenu",
    background_color = Color.black:with_alpha(0.75)
  })

  local title = menu:DivGroup({
    name = "NWCTitle",
    text = "NWC_menu_main_name",
    size = 24,
    background_color = Color.transparent,
    position = { padding, padding }
  })

  local base_settings = menu:DivGroup({
    name = "NWCBaseSettings",
    text = "NWC_menu_base_settings_name",
    size = 20,
    border_bottom = true,
    border_position_below_title = true,
    w = menu_w_left,
    position = { padding, title:Bottom() + padding }
  })
  self.menu_base_settings = base_settings

  base_settings:Toggle({
    name = "add_animations",
    text = "NWC_menu_add_animations",
    help = "NWC_menu_add_animations_desc",
    size = 18,
    on_callback = function (item) self:change_menu_setting(item) end,
    value = self.settings.add_animations
  })

  base_settings:Toggle({
    name = "keep_types",
    text = "NWC_menu_keep_types",
    help = "NWC_menu_keep_types_desc",
    size = 18,
    on_callback = function (item) self:change_menu_setting(item) end,
    value = self.settings.keep_types
  })

  base_settings:Toggle({
    name = "keep_sounds",
    text = "NWC_menu_keep_sounds",
    help = "NWC_menu_keep_sounds_desc",
    size = 18,
    on_callback = function (item) self:change_menu_setting(item) end,
    value = self.settings.keep_sounds
  })

  local quality_settings = menu:DivGroup({
    name = "NWCQualitySettings",
    text = "NWC_menu_quality_settings_name",
    size = 20,
    border_bottom = true,
    border_position_below_title = true,
    w = menu_w_left,
    position = { padding, base_settings:Bottom() + padding * 2 }
  })
  self.menu_quality_settings = quality_settings

  quality_settings:Toggle({
    name = "force_hq",
    text = "NWC_menu_force_hq",
    help = "NWC_menu_force_hq_desc",
    size = 18,
    on_callback = function (item) self:change_hq_menu_setting(item) end,
    value = self.settings.force_hq,
  })

  quality_settings:Toggle({
    name = "jokers_hq",
    text = "NWC_menu_jokers_hq",
    help = "NWC_menu_jokers_hq_desc",
    size = 18,
    on_callback = function (item) self:change_menu_setting(item) end,
    value = self.settings.jokers_hq
  })

  quality_settings:Toggle({
    name = "specials_hq",
    text = "NWC_menu_specials_hq",
    help = "NWC_menu_specials_hq_desc",
    size = 18,
    on_callback = function (item) self:change_menu_setting(item) end,
    value = self.settings.specials_hq
  })

  menu:Button({
    name = "exit",
    text = "menu_back",
    size = 24,
    size_by_text = true,
    on_callback = function (item) self:set_menu_state(false) end,
    position = function (item) item:SetPosition(title:Right() - item:W(), title:Y()) end
  })

  local weapon_settings = menu:DivGroup({
    name = "NWCWeaponSettings",
    text = "NWC_menu_weapon_settings_name",
    size = 20,
    border_bottom = true,
    border_position_below_title = true,
    w = menu_w_right,
    align_method = "grid",
    scrollbar = true,
    max_height = menu_h - title:Bottom() - padding * 2,
    position = { base_settings:Right() + padding, title:Bottom() + padding }
  })
  self.menu_weapon_settings = weapon_settings
  
  self.sorted_weap_ids = table.map_keys(self.weapon_info, function (a, b) return self:npc_weapon_name(a) < self:npc_weapon_name(b) end)
  for i, weap_id in ipairs(self.sorted_weap_ids) do
    local weap = self:get_weapon(weap_id)
    if weap then
      local weap_name = self:npc_weapon_name(weap_id)
      local button = weapon_settings:ImageButton({
        name = "weapon_button_" .. weap_id,
        texture = weap.icon,
        img_color = Color.white:with_alpha(weap.slot and 1 or 0.2),
        help_localized  = false,
        help = weap.name,
        w = menu_w_right / 3 - padding,
        h = 128,
        on_callback = function (item) self:show_weapon_selection(weap_name, weap_id) end
      })
      self:fit_texture(button, padding / 2 + 18)
      button:Panel():text({
        text = weap_name,
        font = "fonts/font_large_mf",
        align = "center",
        font_size = 18,
        y = padding / 2
      })
    end
  end
  
end

function NWC:change_menu_setting(item)
  self.settings[item:Name()] = item:Value()
  self:save()
end

function NWC:change_hq_menu_setting(item)
  self.settings[item:Name()] = item:Value()
  item.parent:GetItem("jokers_hq"):SetEnabled(not self.settings[item:Name()])
  item.parent:GetItem("specials_hq"):SetEnabled(not self.settings[item:Name()])
  self:save()
end

function NWC:refresh_menu()
  self.menu_weapon_settings:SetEnabled(not Utils:IsInGameState())

  for _, weap_id in ipairs(self.sorted_weap_ids) do
    
    local weap = self:get_weapon(weap_id)
    local weapon_button = weap and self.menu_weapon_settings:GetItem("weapon_button_" .. weap_id)
    if weapon_button then
      weapon_button.help = weap.name
      weapon_button.img:set_image(weap.icon)
      weapon_button.img:set_color(Color.white:with_alpha(weap.slot and 1 or 0.2))
    end
    
  end
end

function NWC:get_menu_state()
  return self.menu and self.menu:Enabled()
end

function NWC:set_menu_state(enabled)
  self:check_create_menu()
  if enabled then
    self:refresh_menu()
    self.menu:Enable()
  else
    self.menu:Disable()
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
    table.merge(self.settings, data)
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

Hooks:Add("MenuManagerBuildCustomMenus", "MenuManagerBuildCustomMenusNWC", function(menu_manager, nodes)
  
  if not BeardLib then
    log("[NPCWeaponCustomizer] ERROR: BeardLib is required for this mod to work properly!")
    return
  end

  NWC:load()

  MenuCallbackHandler.NWC_toggle_menu = function ()
    NWC:check_create_menu()
    NWC:set_menu_state(not NWC.menu:Enabled())
  end
  MenuHelperPlus:AddButton({
    id = "NWCMenu",
    title = "NWC_menu_main_name",
    desc = "NWC_menu_main_desc",
    node_name = "blt_options",
    callback = "NWC_toggle_menu"
  })

end)