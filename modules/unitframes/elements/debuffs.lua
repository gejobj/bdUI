local bdUI, c, l = unpack(select(2, ...))
local mod = bdUI:get_module("Unitframes")

mod.additional_elements.debuffs = function(self, unit)
	if (self.Debuffs) then return end
	local config = mod.config

	-- Auras
	self.Debuffs = CreateFrame("Frame", nil, self)
	self.Debuffs:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 0, 4)
	self.Debuffs:SetPoint("BOTTOMRIGHT", self.Health, "TOPRIGHT", 0, 4)
	self.Debuffs:SetSize(config.playertargetwidth, 60)
	self.Debuffs.size = 18
	self.Debuffs.initialAnchor  = "BOTTOMRIGHT"
	self.Debuffs.spacing = bdUI.border
	self.Debuffs.num = 20
	self.Debuffs['growth-y'] = "UP"
	self.Debuffs['growth-x'] = "LEFT"

	self.Debuffs.PostCreateIcon = function(Debuffs, button)
		bdUI:set_backdrop_basic(button)
		button.cd:GetRegions():SetAlpha(0)
		button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	end
end