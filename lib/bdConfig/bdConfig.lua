--[[












]]

local addonName, ns = ...
local mod = ns.bdConfig

--=================================================================
-- REGISTER ADDON
--=================================================================
function mod:register(name, saved_variables_string, lock_toggle, options)
	local instance = {}
	instance._ns = name
	instance._modules = {}
	options = options or {}

	-- create main window
	instance._window = mod:create_windows(name, lock_toggle)

	-- get profile save
	mod:initialize_saved_variables(saved_variables_string)
	instance.save = mod:get_save(saved_variable, nil)

	-- create profiles
	if (not options.hide_profiles) then
		mod:create_profiles(saved_variables_string, options.disable_spec_profiles)
	end

	-- show config window toggle
	function instance:toggle()
		if (self._window:IsShown()) then
			self._window:Hide()
		else
			self._window:Show()
			self._default:select()
		end
	end

	--========================================
	-- Called by individual modules/addons
	--========================================
	function instance:register_module(name, config, options, callback)
		options = options or {}
		local module
		if (options.hide_ui) then
			module = CreateFrame("frame", nil, UIParent)
		else
			module = mod:create_module(instance, name)
		end
		module._config = config
		module._containers = {}
		module._persistent = false

		if (options.persistent) then
			module._persistent = options.persistent
		end

		-- Caps/hide the scrollbar as necessary
		function module:update_scroll()
			local height = self.top:GetHeight()			

			local scrollHeight = math.max(mod.dimensions.height, height) - mod.dimensions.height + 1
			if (height > mod.dimensions.height) then
				height = mod.dimensions.height
			end
			module.scrollParent:SetHeight(height)
			module.scrollbar:SetMinMaxValues(1, scrollHeight)

			if (scrollHeight <= 1) then
				module.noScrollbar = true
				module.scrollbar:Hide()
			else
				module.noScrollbar = false
				module.scrollbar:Show()
			end
		end

		--========================================
		-- Recursively build config
		--========================================
		function module:build(config, name, parent)
			instance.save[name] = instance.save[name] or {}
			local sv = instance.save[name]

			-- loop through options
			for option, info in pairs(config) do
				mod:ensure_value(sv, info.key, info.value, self._persistent) -- initiate sv default

				-- frame build here
				info.save = sv
				info.module = name
				info._module = module
				info.callback = callback or noop

				if (not options.hide_ui and (mod.containers[info.type] or mod.elements[info.type])) then -- only if we've created this module
					local group = parent

					-- container group
					if (mod.containers[info.type]) then
						group = group:add(mod.containers[info.type](info, group))
					elseif (mod.elements[info.type]) then
						local element = group:add(mod.elements[info.type](info, group))
						-- hook into profile changes
						if (element.set and not module._persistent) then
							mod:add_action("profile_changed", function()
								element.save = mod:get_save(saved_variable, info.module)
								element.set()
							end)
						end
					end

					-- recursive call
					if (info.args and info.type ~= "repeater") then
						module:build(info.args, name, group)
					end

					parent.last_frame = group
				elseif (not options.hide_ui) then
					mod:debug("No module found for", info.type, "for", info.key)
				end
			end
		end

		-- call recursive build function
		local group = mod.containers["group"]({}, module, true)
		group.scroller = module
		module.top = group
		module:build(config, name, group)
		local height = group:update()

		-- return configuration reference
		return instance.save[name]
	end

	-- debug - show configuration window
	-- bdUI:add_action("post_loaded", function()
	-- 	instance:toggle()
	-- end)

	-- returns instance to be called
	return instance
end

--=================================================================
-- ELEMENTS & CONTAINERS
--=================================================================
mod.containers = {}
function mod:register_container(name, create)
	if (mod.containers[name]) then return end
	mod.containers[name] = function(options, parent, ...)
		local frame = create(options, parent, ...)
		frame._type = name
		frame._layout = "group"
		parent.last_frame = frame
		return frame
	end
end

mod.elements = {}
function mod:register_element(name, create)
	if (mod.elements[name]) then return end

	mod.elements[name] = function(options, parent, ...)
		local frame = create(options, parent, ...)
		frame._type = name
		frame._layout = "element"
		parent.last_frame = frame

		mod:add_action("profile_changed", frame.set)

		return frame
	end
end

--=================================================================
-- LAYOUT FRAMES
--=================================================================

function mod:create_container(options, parent, height)
	local padding = mod.dimensions.padding
	height = height or 30
	local sizes = {
		half = 0.5,
		third = 0.33,
		twothird = 0.66,
		full = 1
	}

	-- track row width
	size = sizes[options.size or "full"]
	parent._row = parent._row or 0
	parent._row = parent._row + size

	local container = CreateFrame("frame", nil, parent)
	container:SetSize((parent:GetWidth() * size) - (padding * 1.5), height)
	-- TESTING : shows a background around each container for debugging
	-- container:SetBackdrop({bgFile = mod.media.flat})
	-- container:SetBackdropColor(.1, .8, .2, 0.1)

	if (parent._row > 1 or not parent._lastel) then
		-- new or first row
		parent._row = size
		container._isrow = true

		if (not parent._rowel and parent.last_frame) then
			-- first, but next to group or element
			container:SetPoint("TOPLEFT", parent.last_frame, "BOTTOMLEFT", 0, -padding)
			parent._rowel = container
		elseif (not parent._rowel) then
			-- first element
			container:SetPoint("TOPLEFT", parent, "TOPLEFT", padding, -padding)
			parent._rowel = container
		else
			-- new row
			container:SetPoint("TOPLEFT", parent._rowel, "BOTTOMLEFT", 0, -padding)
			parent._rowel = container
		end
	else
		-- same row
		local height = container:GetHeight()
		local lastheight = parent._lastel:GetHeight()
		local idealheight = math.max(height, lastheight)
		container:SetHeight(idealheight)
		parent._lastel:SetHeight(idealheight)
		container:SetPoint("LEFT", parent._lastel, "RIGHT", padding, 0)
	end

	parent._lastel = container

	return container
end