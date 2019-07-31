local parent, ns = ...
local lib = ns.bdConfig

--========================================
-- Methods Here
--========================================
local methods = {
	["add"] = function(self, frame)
		table.insert(self.children, frame)
		return frame
	end,
	["update"] = function(self, options, save)
		local height = self:calculate_height()
		self:SetHeight(height)
		return height
	end,
	["calculate_height"] = function(self)
		local height = lib.dimensions.padding

		for row, element in pairs(self.children) do
			if (element.children) then
				height = height + element:update() + lib.dimensions.padding
			elseif (element._isrow) then
				height = height + element:GetHeight() + lib.dimensions.padding
			end			
		end

		return height
	end
}

--========================================
-- Spawn Element
--========================================
local function create(options, parent, nobg)
	local padding = lib.dimensions.padding
	local yspace = padding

	-- Create Group Heading if it exists
	if (options.heading) then
		table.insert(parent.children, lib.elements['heading']({value = options.heading}, parent))
	end

	local group = lib:create_container(options, parent)
	group:SetSize(parent:GetWidth() - (padding * 2), 30)
	group.children = {}
	Mixin(group, methods)

	if (not nobg) then
		local border = lib:get_border(group)
		group:SetBackdrop({bgFile = lib.media.flat, edgeFile = lib.media.flat, edgeSize = border})
		group:SetBackdropColor(0, 0, 0, 0.08)
		group:SetBackdropBorderColor(0, 0, 0, 0.15)
	end

	if (parent.last_frame) then
		group:SetPoint("TOPLEFT", parent.last_frame, "BOTTOMLEFT", 0, -yspace)
	else
		group:SetPoint("TOPLEFT", parent, "TOPLEFT", padding, -yspace)
	end

	return group
end

lib:register_container("group", create)