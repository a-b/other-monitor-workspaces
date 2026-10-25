-- Other Monitor Workspaces: <mods> + 1..0 switches the other monitor to its workspace N, numbered as
-- that monitor's bar numbers it (Omarchy 4.5 per-monitor workspaces). Loaded from
-- ~/.config/hypr/bindings.lua by the block ./setup adds; settings are documented in README.md.
local M = {}

function M.setup(opts)
	-- Omarchy before 4.5 has no per-monitor workspaces to target; bind nothing rather than broken keys.
	if not (o and o.workspaces and o.workspaces.focus) then
		return
	end
	opts = opts or {}
	local selectors = opts.selectors or { "+1" }
	local keep_focus = opts.keep_focus ~= false
	local mods = opts.mods or "SUPER + CTRL + SHIFT"

	-- Global so `hyprctl dispatch 'focus_other_monitor_workspace(3)'` and the keybindings menu can run it.
	function focus_other_monitor_workspace(slot)
		return function()
			local here, other = hl.get_active_monitor(), nil
			if not here then
				return
			end
			for _, selector in ipairs(selectors) do
				local m = hl.get_monitor(selector)
				if m and m.name ~= here.name and not m.is_mirror then
					other = m
					break
				end
			end
			if not other then
				return
			end

			local window, cursor = hl.get_active_window(), hl.get_cursor_pos()
			o.workspaces.focus(slot, other.name)()
			if not keep_focus then
				return
			end

			-- Focus first (it warps the pointer to the window's middle), then put the pointer back;
			-- cursor.move does not refocus the window under it, so focus stays put.
			if window and hl.get_window("address:" .. window.address) then
				hl.dispatch(hl.dsp.focus({ window = "address:" .. window.address }))
			else
				hl.dispatch(hl.dsp.focus({ monitor = here.name }))
			end
			if cursor then
				hl.dispatch(hl.dsp.cursor.move({ x = cursor.x, y = cursor.y }))
			end
		end
	end

	for slot = 1, 10 do
		local action = focus_other_monitor_workspace(slot)
		o.bind_expressions[action] = "focus_other_monitor_workspace(" .. slot .. ")"
		o.bind(mods .. " + code:" .. (slot + 9), "Switch other monitor to workspace " .. slot, action)
	end
end

return M
