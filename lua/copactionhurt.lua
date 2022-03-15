function CopActionHurt:clbk_shooting_hurt()
	self._delayed_shooting_hurt_clbk_id = nil
	if not alive(self._weapon_unit) then
		return
	end
	local fire_obj = self._weapon_unit:get_object(Idstring("fire"))
	local rot = fire_obj and fire_obj:rotation()
	if rot and rot.cross then -- not sure what's happening there and why the function sometimes doesnt exist, if it doesnt, calling singleshot would crash
		self._weapon_unit:base():singleshot(fire_obj:position(), rot, 1, false, nil, nil, nil, nil)
	end
end

Hooks:PostHook(CopActionHurt, "_upd_hurt", "_upd_hurt_nwc", function (self, t)
	if not self._ext_anim.death then
		return
	end

	if not alive(self._right_hand_obj) then
		self._right_hand_obj = self._unit:get_object(Idstring("RightHandMiddle1"))
	end

	if alive(self._right_hand_obj) then
		if self._right_hand_pos then
			self._ext_inventory._weapon_drop_dir = self._ext_inventory._weapon_drop_dir or Vector3()
			self._ext_inventory._weapon_drop_vel = mvector3.direction(self._ext_inventory._weapon_drop_dir, self._right_hand_pos, self._right_hand_obj:position()) * 100
			mvector3.normalize(self._ext_inventory._weapon_drop_dir)
		end

		self._right_hand_pos = self._right_hand_pos or Vector3()
		mvector3.set(self._right_hand_pos, self._right_hand_obj:position())
	end
end)
