-- replace low def with high def on minion convert
Hooks:PostHook(UnitNetworkHandler, "mark_minion", "mark_minion_nwc", function (self, unit)
	if NWC.settings.jokers_hq then
		local equipped_unit = alive(unit) and unit:inventory():equipped_unit()
		local old_name = equipped_unit and equipped_unit:base()._old_unit_name
		if old_name then
			unit:inventory():add_unit_by_name(old_name, true)
		end
	end
end)
