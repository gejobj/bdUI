local addonName, ns = ...
ns.bdConfig = {}
local mod = ns.bdConfig
-- Get bdCallbacks
LibStub("bdCallbacks-1.0"):New(mod)

-- Developer functions
function mod:noop() return end
function mod:debug(...) print("|cffA02C2FbdConfig|r:", ...) end
function mod:round(num, idp) local mult = 10^(idp or 0) return floor(num * mult + 0.5) / mult end

mod.dimensions = {
	left_column = 150,
	right_column = 600,
	height = 450,
	header = 30,
	padding = 10,
}

mod.media = {
	flat = "Interface\\Buttons\\WHITE8x8",
	arrow = "Interface\\Buttons\\Arrow-Down-Down.PNG",
	font = "fonts\\ARIALN.ttf",
	fontSize = 14,
	fontHeaderScale = 1.1,
	padding = 10,
	border_size = 2,
	background = {0.06, 0.07, 0.09},
	border = {0.03, 0.04, 0.06, 1},
	red = {0.62, 0.17, 0.18, 1},
	blue = {0.2, 0.4, 0.8, 1},
	green = {0.1, 0.7, 0.3, 1},
}
mod.media.primary = mod.media.blue

mod.arrow = UIParent:CreateTexture(nil, "OVERLAY")
mod.arrow:SetTexture(mod.media.arrow)
mod.arrow:SetTexCoord(0.9, 0.9, 0.9, 0.6)
mod.arrow:SetVertexColor(1, 1, 1, 0.5)

--===========================================
-- MEDIA FUNCTIONS
--===========================================
-- Use effective scale to create perfect border
function mod:get_border(frame)
	local screenheight = select(2, GetPhysicalScreenSize())
	local scale = 768 / screenheight
	local frame_scale = frame:GetEffectiveScale()
	local pixel = scale / frame_scale
	local border = pixel * mod.media.border_size

	return border
end

-- Create 2px background frame
function mod:create_backdrop(frame, alpha)
	local border = mod:get_border(frame)
	alpha = alpha or 0.98
	local r, g, b, a = unpack(mod.media.background)

	local bgcolor = {0, 0, 0, 0.08}
	local bordercolor = {0.05, 0.05, 0.05, 1}

	if (not frame.background) then
		frame.bd_background = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
		frame.bd_background:SetTexture(bdUI.media.flat)
		frame.bd_background:SetAllPoints()
		frame.bd_background:SetVertexColor(r, g, b, alpha)
		frame.bd_background.protected = true

		frame.t = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
		frame.t:SetTexture(bdUI.media.flat)
		frame.t:SetVertexColor(unpack(bordercolor))
		frame.t:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", -border, 0)
		frame.t:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", border, 0)

		frame.l = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
		frame.l:SetTexture(bdUI.media.flat)
		frame.l:SetVertexColor(unpack(bordercolor))
		frame.l:SetPoint("TOPRIGHT", frame, "TOPLEFT", 0, border)
		frame.l:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 0, -border)

		frame.r = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
		frame.r:SetTexture(bdUI.media.flat)
		frame.r:SetVertexColor(unpack(bordercolor))
		frame.r:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, border)
		frame.r:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 0, -border)

		frame.b = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
		frame.b:SetTexture(bdUI.media.flat)
		frame.b:SetVertexColor(unpack(bordercolor))
		frame.b:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", -border, 0)
		frame.b:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", border, 0)
	end

	frame.t:SetHeight(border)
	frame.b:SetHeight(border)
	frame.l:SetWidth(border)
	frame.r:SetWidth(border)
end

-- scrollframe
function mod:create_scrollframe(parent)
	local padding = mod.dimensions.padding

	local width = parent:GetWidth()
	local height = parent:GetHeight()

	-- scrollframe
	local scrollParent = CreateFrame("ScrollFrame", nil, parent) 
	scrollParent:SetPoint("TOPLEFT", parent) 
	scrollParent:SetSize(width - padding, height)

	--scrollbar 
	local scrollbar = CreateFrame("Slider", nil, scrollParent, "UIPanelScrollBarTemplate") 
	scrollbar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -2, -18) 
	scrollbar:SetPoint("BOTTOMLEFT", parent, "BOTTOMRIGHT", -18, 18) 
	scrollbar:SetMinMaxValues(1, 600)
	scrollbar:SetValueStep(1)
	scrollbar.scrollStep = 1
	scrollbar:SetValue(0)
	scrollbar:SetWidth(16)

	--content frame 
	local content = CreateFrame("Frame", nil, scrollParent) 
	content:SetPoint("TOPLEFT", parent, "TOPLEFT") 
	content:SetSize(scrollParent:GetWidth() - (padding * 2), scrollParent:GetHeight())
	scrollParent.content = content
	scrollParent:SetScrollChild(content)

	-- scripts
	scrollbar:SetScript("OnValueChanged", function (self, value) 
		self:GetParent():SetVerticalScroll(value) 
	end)

	-- scroller
	local function scroll(self, delta)
		scrollbar:SetValue(scrollbar:GetValue() - (delta*30))
	end
	scrollbar:SetScript("OnMouseWheel", scroll)
	scrollParent:SetScript("OnMouseWheel", scroll)
	content:SetScript("OnMouseWheel", scroll)

	content.scrollParent = scrollParent
	content.scrollbar = scrollbar
	content.parent = parent

	return content
end