_G.NWC = {}
NWC.mod_path = ModPath
NWC.save_path = SavePath
NWC.tweak_setups = {}
NWC.dropable_weapon_mods = {}
NWC.weapons = {}
NWC.weapon_info = {
  beretta92_npc = { factory_id = "wpn_fps_pis_beretta" },
  c45_npc = { factory_id = "wpn_fps_pis_g17" },
  raging_bull_npc = { factory_id = "wpn_fps_pis_rage" },
  m4_npc = { factory_id = "wpn_fps_ass_m4" },
  m4_yellow_npc = { factory_id = "wpn_fps_ass_m4", menu_suffix = " (Taser)" },
  ak47_npc = { factory_id = "wpn_fps_ass_74", menu_suffix = " (Mobster)" },
  r870_npc = { factory_id = "wpn_fps_shot_r870" },
  mossberg_npc = { factory_id = "wpn_fps_shot_huntsman" },
  mp5_npc = { factory_id = "wpn_fps_smg_mp5" },
  mp5_tactical_npc = { factory_id = "wpn_fps_smg_mp5", menu_suffix = " (Cloaker)" },
  mp9_npc = { factory_id = "wpn_fps_smg_mp9" },
  mac11_npc = { factory_id = "wpn_fps_smg_mac10" },
  m14_sniper_npc = { factory_id = "wpn_fps_ass_g3", menu_suffix = " (Sniper)" },
  saiga_npc = { factory_id = "wpn_fps_shot_saiga" },
  m249_npc = { factory_id = "wpn_fps_lmg_m249" },
  benelli_npc = { factory_id = "wpn_fps_sho_ben" },
  g36_npc = { factory_id = "wpn_fps_ass_g36" },
  ump_npc = { factory_id = "wpn_fps_smg_schakal" },
  scar_npc = { factory_id = "wpn_fps_ass_scar" },
  rpk_lmg_npc = { factory_id = "wpn_fps_lmg_rpk" },
  svd_snp_npc = { factory_id = "wpn_fps_snp_siltstone", menu_suffix = " (Russian Sniper)" },
  akmsu_smg_npc = { factory_id = "wpn_fps_smg_akmsu" },
  asval_smg_npc = { factory_id = "wpn_fps_ass_asval" },
  sr2_smg_npc = { factory_id = "wpn_fps_smg_sr2" },
  ak47_ass_npc = { factory_id = "wpn_fps_ass_74", menu_suffix = " (Russian)" },
  x_c45_npc = { factory_id = "wpn_fps_pis_x_g17" },
  contraband_npc = { factory_id = "wpn_fps_ass_contraband" },
  svdsil_snp_npc = { factory_id = "wpn_fps_snp_siltstone", menu_suffix = " (Mobster Sniper)" },
  mini_npc = { factory_id = "wpn_fps_lmg_m134" },
  heavy_snp_npc = { factory_id = "wpn_fps_ass_g3", menu_suffix = " (ZEAL Sniper)" }
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

function NWC:get_weapon(weap_id)
  if not weap_id or not self.weapon_info[weap_id] then
    return
  end
  local saved_weapon = self.settings.weapons[weap_id] or {}
  if not self.weapons[weap_id] then
    local crafted = saved_weapon.category and saved_weapon.slot and managers.blackmarket:get_crafted_category_slot(saved_weapon.category, saved_weapon.slot)
    if crafted and self:check_npc_weapon_version(crafted.factory_id, crafted.blueprint) then
      self.weapons[weap_id] = {
        factory_id = crafted.factory_id .. "_npc",
        blueprint = crafted.blueprint,
        cosmetics = crafted.cosmetics,
        name = crafted.custom_name and "\"" .. crafted.custom_name .. "\"" or managers.localization:text(tweak_data.weapon[crafted.weapon_id].name_id),
        icon = managers.blackmarket:get_weapon_icon_path(crafted.weapon_id, crafted.cosmetics),
        category = saved_weapon.category,
        slot = saved_weapon.slot,
      }
    else
      self:clear_weapon(weap_id)
      local weapon_info = self.weapon_info[weap_id]
      local weapon_id = managers.weapon_factory:get_weapon_id_by_factory_id(weapon_info.factory_id)
      self.weapons[weap_id] = {
        factory_id = weapon_info.factory_id .. "_npc",
        blueprint = tweak_data.weapon.factory[weapon_info.factory_id].default_blueprint,
        name = managers.localization:text(tweak_data.weapon[weapon_id].name_id) .. " (" .. managers.localization:text("NWC_menu_mod_default") .. ")",
        icon = managers.blackmarket:get_weapon_icon_path(weapon_id)
      }
    end
  end
  if saved_weapon.random_mods and Utils:IsInGameState() then
    local w = deep_clone(self.weapons[weap_id])
    self:create_random_blueprint(w, saved_weapon.random_mods_chance or 0.5)
    return w
  end
  return self.weapons[weap_id]
end

function NWC:clear_weapon(weap_id)
  self.weapons[weap_id] = nil
  if self.settings.weapons[weap_id] then
    self.settings.weapons[weap_id].category = nil
    self.settings.weapons[weap_id].slot = nil
  end
end

function NWC:check_npc_weapon_version(factory_id, blueprint)
  local factory_data = factory_id and tweak_data.weapon.factory[factory_id .. "_npc"]
  if not factory_data or factory_data.custom and not DB:has(Idstring("unit"), factory_data.unit:id()) then
    return
  end
  for _, part_id in pairs(blueprint or {}) do
    factory_data = tweak_data.weapon.factory.parts[part_id]
    if not factory_data or factory_data.custom and not (factory_data.third_unit and DB:has(Idstring("unit"), factory_data.third_unit:id())) then
      return
    end
  end
  return true
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
  local tweak_table = unit:base()._tweak_table
  return (tweak_table:match("boss") or tweak_data.character[tweak_table].priority_shout) and true
end

function NWC:create_random_blueprint(weapon, random_mods_chance)
  if not self.dropable_weapon_mods[weapon.factory_id] then
    local weapon_id = managers.weapon_factory:get_weapon_id_by_factory_id(weapon.factory_id:gsub("_npc$", ""))
    if not weapon_id then
      return
    end
    self.dropable_weapon_mods[weapon.factory_id] = managers.blackmarket:get_dropable_mods_by_weapon_id(weapon_id)
  end
  for part_type, parts_data in pairs(self.dropable_weapon_mods[weapon.factory_id]) do
    if math.random() < random_mods_chance then
      local part_data = table.random(parts_data)
      if part_data then
        managers.weapon_factory:change_part_blueprint_only(weapon.factory_id, part_data[1], weapon.blueprint)
      end
    end
  end
end

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
      self.weapons[weap_id] = nil
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
    local crafted = not v.empty_slot and managers.blackmarket:get_crafted_category_slot(v.category, v.slot)
    if v.empty_slot or self:check_npc_weapon_version(crafted.factory_id, crafted.blueprint) then
      v.equipped = not v.empty_slot and weapon.slot == v.slot and weapon.category == v.category
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
  self:clear_weapon(weap_id)
  if data and not data.equipped then
    self.settings.weapons[weap_id] = self.settings.weapons[weap_id] or {}
    self.settings.weapons[weap_id].category = data.category
    self.settings.weapons[weap_id].slot = data.slot
  end
  self:save()
  gui:reload()
end

function NWC:show_weapon_actions(weap_id)
  local weapon = self:get_weapon(weap_id)
  local diag = MenuDialog:new({
    accent_color = self.menu_accent_color,
    highlight_color = self.menu_highlight_color,
    background_color = self.menu_background_color,
    border_size = 1,
    text_offset = self.menu_padding / 4,
    size = self.menu_items_size,
    items_size = self.menu_items_size
  })
  diag:Show({
    title = self:npc_weapon_name(weap_id),
    message = managers.localization:text("NWC_menu_weapon_message", { WEAPON = weapon.name }),
    yes = false,
    w = self.menu._panel:w() / 2,
    title_merge = {
      size = self.menu_title_size
    },
    create_items = function (menu)
      menu:Divider({
        h = self.menu_padding / 2
      })
      menu:Button({
        name = "select_primaries",
        text = "NWC_menu_select_from_primaries",
        localized = true,
        enabled = not Utils:IsInGameState(),
        on_callback = function (item)
          diag:hide()
          self:set_menu_state(false)
          self:open_weapon_category_menu("primaries", weap_id)
        end
      })
      menu:Button({
        name = "select_secondaries",
        text = "NWC_menu_select_from_secondaries",
        localized = true,
        enabled = not Utils:IsInGameState(),
        on_callback = function (item)
          diag:hide()
          self:set_menu_state(false)
          self:open_weapon_category_menu("secondaries", weap_id)
        end
      })
      menu:Button({
        name = "reset",
        text = "NWC_menu_use_default",
        localized = true,
        on_callback = function (item)
          diag:hide()
          self:clear_weapon(weap_id)
          self:save()
          self:refresh_menu()
        end
      })
      menu:Divider({
        h = self.menu_padding / 4
      })
      menu:Toggle({
        name = "random_mods",
        text = "NWC_menu_use_random_mods",
        help = "NWC_menu_use_random_mods_desc",
        localized = true,
        value = self.settings.weapons[weap_id] and self.settings.weapons[weap_id].random_mods,
        on_callback = function (item) self:change_menu_weapon_setting(item, weap_id) end
      })
      menu:Slider({
        name = "random_mods_chance",
        text = "NWC_menu_random_mods_chance",
        help = "NWC_menu_random_mods_chance_desc",
        localized = true,
        value = self.settings.weapons[weap_id] and self.settings.weapons[weap_id].random_mods_chance or 0.5,
        min = 0,
        max = 1,
        step = 0.05,
        floats = 2,
        wheel_control = true,
        enabled = self.settings.weapons[weap_id] and self.settings.weapons[weap_id].random_mods and true or false,
        on_callback = function (item) self:change_menu_weapon_setting(item, weap_id) end
      })
      menu:Divider({
        h = self.menu_padding / 4
      })
      menu:Button({
        name = "back",
        text = "menu_back",
        localized = true,
        text_align = "right",
        on_callback = function (item)
          diag:hide()
        end
      })
    end
  })
end

function NWC:npc_weapon_name(weap_id)
  local weapon_id = managers.weapon_factory:get_weapon_id_by_factory_id(self.weapon_info[weap_id].factory_id)
  return managers.localization:text(tweak_data.weapon[weapon_id].name_id) .. (self.weapon_info[weap_id].menu_suffix or "")
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

  self.menu_title_size = 22
  self.menu_items_size = 18
  self.menu_padding = 16
  self.menu_background_color = Color.black:with_alpha(0.75)
  self.menu_accent_color = Color("0bce99"):with_alpha(0.75)
  self.menu_highlight_color = self.menu_accent_color:with_alpha(0.075)

  self.menu = MenuUI:new({
    name = "NWCMenu",
    layer = 1000,
    background_blur = true,
    animate_toggle = true,
    text_offset = self.menu_padding / 4,
    show_help_time = 0.5,
    border_size = 1,
    accent_color = self.menu_accent_color,
    highlight_color = self.menu_highlight_color,
    localized = true,
    use_default_close_key = true
  })
  
  local menu_w = self.menu._panel:w()
  local menu_h = self.menu._panel:h()

  local menu_w_left = menu_w / 3 - self.menu_padding
  local menu_w_right = menu_w - menu_w_left - self.menu_padding * 2

  local menu = self.menu:Menu({
    name = "NWCMainMenu",
    background_color = self.menu_background_color
  })

  local title = menu:DivGroup({
    name = "NWCTitle",
    text = "NWC_menu_main_name",
    size = 26,
    background_color = Color.transparent,
    position = { self.menu_padding, self.menu_padding }
  })

  local base_settings = menu:DivGroup({
    name = "NWCBaseSettings",
    text = "NWC_menu_base_settings_name",
    size = self.menu_title_size,
    inherit_values = {
      size = self.menu_items_size
    },
    border_bottom = true,
    border_position_below_title = true,
    w = menu_w_left,
    position = { self.menu_padding, title:Bottom() + self.menu_padding }
  })

  base_settings:Toggle({
    name = "add_animations",
    text = "NWC_menu_add_animations",
    help = "NWC_menu_add_animations_desc",
    on_callback = function (item) self:change_menu_setting(item) end,
    value = self.settings.add_animations
  })

  base_settings:Toggle({
    name = "keep_types",
    text = "NWC_menu_keep_types",
    help = "NWC_menu_keep_types_desc",
    on_callback = function (item) self:change_menu_setting(item) end,
    value = self.settings.keep_types
  })

  base_settings:Toggle({
    name = "keep_sounds",
    text = "NWC_menu_keep_sounds",
    help = "NWC_menu_keep_sounds_desc",
    on_callback = function (item) self:change_menu_setting(item) end,
    value = self.settings.keep_sounds
  })

  base_settings:Divider({
    h = self.menu_padding * 2
  })

  local quality_settings = menu:DivGroup({
    name = "NWCQualitySettings",
    text = "NWC_menu_quality_settings_name",
    size = self.menu_title_size,
    inherit_values = {
      size = self.menu_items_size
    },
    border_bottom = true,
    border_position_below_title = true,
    w = menu_w_left,
    position = { self.menu_padding, base_settings:Bottom() }
  })

  quality_settings:Toggle({
    name = "force_hq",
    text = "NWC_menu_force_hq",
    help = "NWC_menu_force_hq_desc",
    on_callback = function (item) self:change_menu_setting(item) end,
    value = self.settings.force_hq,
  })

  quality_settings:Toggle({
    name = "jokers_hq",
    text = "NWC_menu_jokers_hq",
    help = "NWC_menu_jokers_hq_desc",
    enabled = not self.settings.force_hq,
    on_callback = function (item) self:change_menu_setting(item) end,
    value = self.settings.jokers_hq
  })

  quality_settings:Toggle({
    name = "specials_hq",
    text = "NWC_menu_specials_hq",
    help = "NWC_menu_specials_hq_desc",
    enabled = not self.settings.force_hq,
    on_callback = function (item) self:change_menu_setting(item) end,
    value = self.settings.specials_hq
  })

  menu:Button({
    name = "exit",
    text = "menu_back",
    size = 24,
    size_by_text = true,
    on_callback = function (item) self:set_menu_state(false) end,
    position = function (item) item:SetPosition(title:Right() - item:W() - self.menu_padding, title:Y()) end
  })

  local weapon_settings = menu:DivGroup({
    name = "NWCWeaponSettings",
    text = "NWC_menu_weapon_settings_name",
    size = self.menu_title_size,
    border_bottom = true,
    border_position_below_title = true,
    w = menu_w_right,
    align_method = "grid",
    scrollbar = true,
    max_height = menu_h - title:Bottom() - self.menu_padding * 2,
    position = { base_settings:Right() + self.menu_padding, title:Bottom() + self.menu_padding }
  })
  self.menu_weapon_settings = weapon_settings
  
  self.sorted_weap_ids = table.map_keys(self.weapon_info, function (a, b) return self:npc_weapon_name(a) < self:npc_weapon_name(b) end)
  for i, weap_id in ipairs(self.sorted_weap_ids) do
    local weap = self:get_weapon(weap_id)
    if weap then
      local button = weapon_settings:ImageButton({
        name = "weapon_button_" .. weap_id,
        texture = weap.icon,
        img_color = Color.white:with_alpha(weap.slot and 1 or 0.2),
        help_localized  = false,
        help = weap.name,
        w = menu_w_right / 3 - self.menu_padding,
        h = 128,
        on_callback = function (item) self:show_weapon_actions(weap_id) end
      })
      self:fit_texture(button, self.menu_padding / 2 + 18)
      button:Panel():text({
        text = self:npc_weapon_name(weap_id),
        font = "fonts/font_large_mf",
        align = "center",
        font_size = self.menu_items_size,
        y = self.menu_padding / 2
      })
    end
  end
  
end

function NWC:change_menu_setting(item)
  self.settings[item:Name()] = item:Value()
  if item:Name() == "force_hq" then
    item.parent:GetItem("jokers_hq"):SetEnabled(not self.settings[item:Name()])
    item.parent:GetItem("specials_hq"):SetEnabled(not self.settings[item:Name()])
  end
  self:save()
end

function NWC:change_menu_weapon_setting(item, weap_id)
  self.settings.weapons[weap_id] = self.settings.weapons[weap_id] or {}
  self.settings.weapons[weap_id][item:Name()] = item:Value()
  if item:Name() == "random_mods" then
    local chance = item.parent:GetItem("random_mods_chance")
    chance:SetEnabled(item:Value())
    self.settings.weapons[weap_id].random_mods_chance = self.settings.weapons[weap_id].random_mods_chance or item:Value() and chance:Value()
  end
  self:save()
end

function NWC:refresh_menu()
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
  local file = io.open(self.save_path .. "NPCWeaponSettings.txt", "w+")
  if file then
    file:write(json.encode(self.settings))
    file:close()
  end
end

function NWC:load()
  local file = io.open(self.save_path .. "NPCWeaponSettings.txt", "r")
  if file then
    local data = json.decode(file:read("*all")) or {}
    file:close()
    table.merge(self.settings, data)
    for weap_id, _ in pairs(self.settings.weapons) do
      if not self.weapon_info[weap_id] then
        self.settings.weapons[weap_id] = nil
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

Hooks:Add("MenuManagerBuildCustomMenus", "MenuManagerBuildCustomMenusNWC", function(menu_manager, nodes)
  
  if not BeardLib then
    log("[NPCWeaponCustomizer] ERROR: BeardLib is required for this mod to work properly!")
    return
  end

  NWC:load()

  MenuCallbackHandler.NWC_open_menu = function ()
    NWC:set_menu_state(true)
  end
  MenuHelperPlus:AddButton({
    id = "NWCMenu",
    title = "NWC_menu_main_name",
    desc = "NWC_menu_main_desc",
    node_name = "blt_options",
    callback = "NWC_open_menu"
  })

end)