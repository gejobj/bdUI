--===============================================
-- FUNCTIONS
--===============================================
local bdUI, c, l = unpack(select(2, ...))
local mod = bdUI:get_module("Grid")
local lib_glow = bdButtonGlow
local config
local oUF = bdUI.oUF
mod.frames = {}

--===============================================
-- Core functionality
-- place core functionality here
--===============================================
-- upcoming features
-- fully custom sorting, custom player positions
-- bouqets / positioning
-- specific spell positioning
-- [buffs] [debuffs] [raid cooldowns] [my casts] [personals]
-- [name] [status] [raid target] [readycheck]

local index = 0;
local function layout(self, unit)
	self:RegisterForClicks('AnyDown')
	index = index + 1
	self.index = index

	-- Unit doesn't always include index
	if (unit == "raid" or unit == "party") then
		self.unit = "raid"..index
	else
		self.unit = unit
	end

	-- Disable tooltips
	self:SetScript("OnEnter", function()
		if (not config.hidetooltips) then
			UnitFrame_OnEnter(self)
		end
	end)
	
	--===============================================
	-- Health
	--===============================================
	self.Health = CreateFrame("StatusBar", nil, self)
	self.Health:SetStatusBarTexture(bdUI.media.flat)
	self.Health:SetAllPoints(self)
	self.Health:SetFrameLevel(0)
	self.Health.frequentUpdates = true
	self.Health.colorTapping = true
	self.Health.colorDisconnected = true
	self.Health.colorClass = true
	self.Health.colorReaction = true
	self.Health.colorHealth = true
	bdUI:set_backdrop(self.Health)
	function self.Health.PostUpdate(s, unit, min, max)
		local r, g, b = self.Health:GetStatusBarColor()
		
		if (config.invert) then
			self.Health:SetStatusBarColor(unpack(bdUI.media.backdrop))
			self.Health.border:SetVertexColor(r/2, g/2, b/2)
			self.Short:SetTextColor(r*1.1, g*1.1, b*1.1)
			--self.TotalAbsorb:SetStatusBarColor(1,1,1,.07)
		else
			self.Health:SetStatusBarColor(r/2, g/2, b/2)
			self.Health.border:SetVertexColor(unpack(bdUI.media.backdrop))
			self.Short:SetTextColor(1,1,1)
			--self.TotalAbsorb:SetStatusBarColor(.1,.1,.1,.5)
		end
	end
	
	--===============================================
	-- Tags
	--===============================================
	-- Status (offline/dead)
	self.Status = self.Health:CreateFontString(nil)
	self.Status:SetFont(bdUI.media.font, 12, "OUTLINE")
	self.Status:SetPoint('BOTTOMLEFT', self, "BOTTOMLEFT", 0, 0)
	oUF.Tags.Events["status"] = "UNIT_HEALTH UNIT_CONNECTION"
	oUF.Tags.Methods["status"] = function(unit)
		if not UnitIsConnected(unit) then
			return "offline"		
		elseif UnitIsDead(unit) then
			return "dead"		
		elseif UnitIsGhost(unit) then
			return "ghost"
		end
	end
	self:Tag(self.Status, '[status]')
	

	--===============================================
	-- Healing & Damage Absorbs
	--===============================================
	
	-- Heal predections
    local myHeals = CreateFrame('StatusBar', nil, self.Health)
    myHeals:SetPoint('TOP')
    myHeals:SetPoint('BOTTOM')
    myHeals:SetPoint('LEFT', self.Health:GetStatusBarTexture(), 'RIGHT')
	myHeals:SetStatusBarTexture(bdUI.media.flat)
	myHeals:SetStatusBarColor(0.6,1,0.6,.2)
    local otherHeals = CreateFrame('StatusBar', nil, self.Health)
    otherHeals:SetPoint('TOP')
    otherHeals:SetPoint('BOTTOM')
    otherHeals:SetPoint('LEFT', myHeals:GetStatusBarTexture(), 'RIGHT')
	local healAbsorbBar = CreateFrame('StatusBar', nil, self.Health)
    healAbsorbBar:SetAllPoints()
    healAbsorbBar:SetReverseFill(true)
	healAbsorbBar:SetStatusBarTexture(bdUI.media.flat)
	healAbsorbBar:SetStatusBarColor(.3, 0, 0,.5)
	local overHealAbsorbBar = CreateFrame('StatusBar', nil, self.Health)
    overHealAbsorbBar:SetAllPoints()
    overHealAbsorbBar:SetReverseFill(true)
	overHealAbsorbBar:SetStatusBarTexture(bdUI.media.flat)
	overHealAbsorbBar:SetStatusBarColor(.3, 0, 0,.5)

	-- Damage Absorbs
    local absorbBar = CreateFrame('StatusBar', nil, self.Health)
    absorbBar:SetAllPoints()
	absorbBar:SetStatusBarTexture(bdUI.media.flat)
	absorbBar:SetStatusBarColor(.1, .1, .2, .6)
	local overAbsorbBar = CreateFrame('StatusBar', nil, self.Health)
    overAbsorbBar:SetAllPoints()
	overAbsorbBar:SetStatusBarTexture(bdUI.media.flat)
	overAbsorbBar:SetStatusBarColor(.1, .1, .2, .6)

	-- Register and callback
    self.HealthPrediction = {
        myBar = myHeals,
        otherBar = otherHeals,

        absorbBar = absorbBar,
		overAbsorb = overAbsorbBar,

        healAbsorbBar = healAbsorbBar,
        overHealAbsorb = overHealAbsorbBar,

        maxOverflow = 1,
        frequentUpdates = true,
    }
	
	function self.HealthPrediction:PostUpdate(unit, myIncomingHeal, otherIncomingHeal, absorb, healAbsorb, hasOverAbsorb, hasOverHealAbsorb)
		if (config.hideabsorbs) then
			myHeals:Hide()
			otherHeals:Hide()
			absorbBar:Hide()
			overAbsorbBar:Hide()
			healAbsorbBar:Hide()
			overHealAbsorbBar:Hide()

			return
		else
			myHeals:Show()
			otherHeals:Show()
			absorbBar:Show()
			overAbsorbBar:Show()
			healAbsorbBar:Show()
			overHealAbsorbBar:Show()
		end

		local absorb = UnitGetTotalAbsorbs(unit) or 0
		local healAbsorb = UnitGetTotalHealAbsorbs(unit) or 0
		local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)

		local overA = 0
		local overH = 0

		-- 2nd dmg absorb shield
		if (absorb > maxHealth) then
			overA = absorb - maxHealth
			self.overAbsorb:Show()
		else
			self.overAbsorb:Hide()
		end
		
		-- 2nd heal absorb shield
		if (healAbsorb > maxHealth) then
			overH = healAbsorb - maxHealth
			self.overHealAbsorb:Show()
		else
			self.overHealAbsorb:Hide()
		end

		self.overHealAbsorb:SetMinMaxValues(0, UnitHealthMax(unit))
		self.overHealAbsorb:SetValue(overH)
		self.overAbsorb:SetMinMaxValues(0, UnitHealthMax(unit))
		self.overAbsorb:SetValue(overA)

		self.absorbBar:SetValue(absorb)
	end

	-- Resurrect
	self.ResurrectIndicator = self.Health:CreateTexture(nil, 'OVERLAY')
	self.ResurrectIndicator:SetSize(16, 16)
    self.ResurrectIndicator:SetPoint('TOPRIGHT', self)

	-- Summon
	self.SummonIndicator = self.Health:CreateTexture(nil, 'OVERLAY')
	self.SummonIndicator:SetSize(16, 16)
    self.SummonIndicator:SetPoint('TOPRIGHT', self)

	-- Phase
	self.PhaseIndicator = self.Health:CreateTexture(nil, 'OVERLAY')
	self.PhaseIndicator:SetSize(16, 16)
    self.PhaseIndicator:SetPoint('BOTTOMLEFT', self)

	-- Power
	self.Power = CreateFrame("StatusBar", nil, self.Health)
	self.Power:SetStatusBarTexture(bdUI.media.flat)
	self.Power:ClearAllPoints()
	self.Power:SetPoint("BOTTOMLEFT", self.Health, "BOTTOMLEFT", 0, 0)
	self.Power:SetPoint("TOPRIGHT", self.Health, "BOTTOMRIGHT",0, config.powerheight)
	self.Power:SetAlpha(0.8)
	self.Power.colorPower = true
	self.Power.border = self.Health:CreateTexture(nil)
	self.Power.border:SetPoint("TOPRIGHT", self.Power, "TOPRIGHT", 0, 2)
	self.Power.border:SetPoint("BOTTOMLEFT", self.Power, "TOPLEFT", 0, 0)
	
	-- shortname
	self.Short = self.Health:CreateFontString(nil, "OVERLAY")
	self.Short:SetFont(bdUI.media.font, 13)
	self.Short:SetShadowOffset(1,-1)
	self.Short:SetPoint("BOTTOMRIGHT", self.Health, "BOTTOMRIGHT", 0,0)
	self.Short:SetJustifyH("RIGHT")
	
	oUF.Tags.Events["self.Short"] = "UNIT_NAME_UPDATE"
	oUF.Tags.Methods["self.Short"] = function(unit)
		local name = UnitName(unit)
		if (not name) then return end
		if (bdUI.persistent.GridAliases[name]) then
			name = bdUI.persistent.GridAliases[name];
		end
		return string.utf8sub(name, 1, config.namewidth)
	end

	self:Tag(self.Short, '[self.Short]')
	self:Tag(self.Status, '[status]')

	self.Group = self.Health:CreateFontString(nil)
	self.Group:SetFont(bdUI.media.font, 12, "OUTLINE")
	self.Group:SetPoint('TOPRIGHT', self, "TOPRIGHT", -2, -2)
	oUF.Tags.Events["self.Group"] = "UNIT_NAME_UPDATE"
	oUF.Tags.Methods["self.Group"] = function(unit)
		local name, server = UnitName(unit)
		if(server and server ~= '') then
			name = string.format('%s-%s', name, server)
		end

		for i=1, GetNumGroupMembers() do
			local raidName, _, group = GetRaidRosterInfo(i)
			if( raidName == name ) then
				return "[" .. group .. "]"
			end
		end
	end
	self:Tag(self.Group, '[self.Group]')	
	
	-- Raid Icon
	self.RaidTargetIndicator = self.Health:CreateTexture(nil, "OVERLAY", nil, 1)
	self.RaidTargetIndicator:SetSize(12, 12)
	self.RaidTargetIndicator:SetPoint("TOP", self, "TOP", 0, -2)
	
	-- roll icon
	self.GroupRoleIndicator = self.Health:CreateTexture(nil, "OVERLAY")
	self.GroupRoleIndicator:SetSize(12, 12)
	self.GroupRoleIndicator:SetPoint("BOTTOMLEFT", self.Health, "BOTTOMLEFT",2,2)
	self.GroupRoleIndicator.Override = function(self,event)
		local role = UnitGroupRolesAssigned(self.unit)
		self.GroupRoleIndicator:Hide()
		if (config.roleicon) then
			if (role and (role == "HEALER" or role == "TANK")) then
				self.GroupRoleIndicator:SetTexCoord(GetTexCoordsForRoleSmallCircle(role))
				self.GroupRoleIndicator:Show()
			end
		end
		
		self.Power:Hide()
		if (config.powerdisplay == "None") then
			self.Power:Hide()
		elseif (config.powerdisplay == "Healers" and role == "HEALER") then
			self.Power:Show()
		elseif (config.powerdisplay == "All") then
			self.Power:Show()
		end
	end

	self.LeaderIndicator = self.Health:CreateTexture(nil, "OVERLAY")
	self.LeaderIndicator:SetSize(12, 12)
	self.LeaderIndicator:SetPoint("TOPLEFT", self.Health, "TOPLEFT",2,2)
	self.LeaderIndicator.PostUpdate = function(self, isLeader)
		if (not config.showpartyleadericon) then
			self:Hide()
		end
	end
	
	self.Range = {
		insideAlpha = config.inrangealpha,
		outsideAlpha = config.outofrangealpha,
	}
	
	-- Readycheck
	self.ReadyCheckIndicator = self.Health:CreateTexture(nil, 'OVERLAY', nil, 7)
	self.ReadyCheckIndicator:SetPoint('BOTTOM', self, 'BOTTOM', 0, 2)
	
	-- ResurrectIcon
	self.ResurrectIndicator = self.Health:CreateTexture(nil, 'OVERLAY')
	self.ResurrectIndicator:SetPoint('CENTER', self, "CENTER", 0,0)
	
	-- Threat
	self.ThreatLite = CreateFrame('frame', nil, self)
	self.ThreatLite:SetFrameLevel(95)
	self.ThreatLite:SetPoint('TOPRIGHT', self, "TOPRIGHT", 1, 1)
	self.ThreatLite:SetPoint('BOTTOMLEFT', self, "BOTTOMLEFT", -1, -1)
	self.ThreatLite:SetBackdrop({bgFile = bdUI.media.flat, edgeFile = bdUI.media.flat, edgeSize = 1})
	self.ThreatLite:SetBackdropBorderColor(1, 0, 0,1)
	self.ThreatLite:SetBackdropColor(0,0,0,0)
	self.ThreatLite:Hide()
	-- self.SimpleThreat.Callback = function(self)
	-- 	local status = UnitThreatSituation("player")
	-- 	if (status and status >= 2) then
	-- 		self.SimpleThreat:Show()
	-- 	else
	-- 		self.SimpleThreat:Hide()
	-- 	end
	-- end
	-- self:RegisterEvent("UNIT_HEALTH", self.SimpleThreat.Callback)
	-- self:RegisterEvent("PLAYER_ALIVE", self.SimpleThreat.Callback, true)
	-- self:RegisterEvent("PLAYER_UNGHOST", self.SimpleThreat.Callback, true)
	-- self:RegisterEvent("PLAYER_TARGET_CHANGED", self.SimpleThreat.Callback, true)
	-- self:RegisterEvent("PLAYER_REGEN_ENABLED", self.SimpleThreat.Callback, true)
	-- self:RegisterEvent("PLAYER_REGEN_DISABLED", self.SimpleThreat.Callback, true)
	-- self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", self.SimpleThreat.Callback)
	
	-- Buffs
	self.Buffs = CreateFrame("Frame", nil, self.Health)
	self.Buffs:SetPoint("TOPLEFT", self.Health, "TOPLEFT")
	self.Buffs:SetFrameLevel(21)
	self.Buffs:EnableMouse(false)
	self.Buffs.disableMouse = true
	self.Buffs.initialAnchor  = "TOPLEFT"
	self.Buffs.size = config.buffSize
	self.Buffs.spacing = 1
	self.Buffs.num = 6
	self.Buffs['growth-y'] = "DOWN"
	self.Buffs['growth-x'] = "RIGHT"

	self.Buffs.CustomFilter = function(self, unit, button, name, texture, count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID, canApply, isBossDebuff, casterIsPlayer, nameplateShowAll,timeMod, effect1, effect2, effect3)
		isBossDebuff = isBossDebuff or false
		nameplateShowAll = nameplateShowAll or false
		local castByPlayer = caster and UnitIsUnit(caster, "player") or false
		-- return bdUI:filterAura(name, castByPlayer, isBossDebuff, nameplateShowAll, false)
	end
	self.Buffs.PostCreateIcon = function(self, button) 
		local region = button.cd:GetRegions()
		button:SetAlpha(0.8)
		region:SetAlpha(1)
		region:Show()
		if (config.showBuffTimers) then
			region:SetTextHeight(config.buffSize)
			region:SetJustifyH("CENTER")
			region:SetJustifyV("MIDDLE")
			region:SetPoint("TOPLEFT", button.cd, "TOPLEFT", -config.buffSize, 0)
			region:SetPoint("BOTTOMRIGHT", button.cd, "BOTTOMRIGHT", config.buffSize, 0)
		else
			region:SetAlpha(0)
			region:Hide()
		end

		button.cd:SetReverse(true)
		button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	end
	
	-- special spell alerts
	self.Glow = CreateFrame("frame", "glow", self.Health)
	self.Glow:SetAllPoints()
	self.Glow:SetFrameLevel(3)

	-- Dispels
	self.Dispel = CreateFrame('frame', nil, self.Health)
	self.Dispel:SetFrameLevel(100)
	self.Dispel:SetPoint('TOPRIGHT', self, "TOPRIGHT", 1, 1)
	self.Dispel:SetPoint('BOTTOMLEFT', self, "BOTTOMLEFT", -1, -1)
	self.Dispel:SetBackdrop({bgFile = bdUI.media.flat, edgeFile = bdUI.media.flat, edgeSize = 2})
	self.Dispel:SetBackdropBorderColor(1, 0, 0,1)
	self.Dispel:SetBackdropColor(0,0,0,0)
	self.Dispel:Hide()
	
	-- look / color / show dispels and glows
	-- self:RegisterEvent("UNIT_AURA", dispelAndGlow);
	
	-- Debuffs
	self.Debuffs = CreateFrame("Frame", nil, self.Health)
	self.Debuffs:SetFrameLevel(21)
	self.Debuffs:SetPoint("CENTER", self.Health, "CENTER")
	
	self.Debuffs.initialAnchor = "CENTER"
	self.Debuffs.size = config.debuffSize
	self.Debuffs:EnableMouse(false)
	self.Debuffs.disableMouse = true
	self.Debuffs.spacing = 1
	self.Debuffs.num = 4
	self.Debuffs['growth-y'] = "DOWN"
	self.Debuffs['growth-x'] = "RIGHT"

	self.Debuffs.CustomFilter = function(self, unit, button, name, texture, count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID, canApply, isBossDebuff, casterIsPlayer, nameplateShowAll, timeMod)
		isBossDebuff = isBossDebuff or false
		nameplateShowAll = nameplateShowAll or false
		local castByPlayer = caster and UnitIsUnit(caster, "player") or false
		-- return bdUI:filterAura(name, castByPlayer, isBossDebuff, nameplateShowAll, false)
	end

	self.Debuffs.PostCreateIcon = function(self, button)
		local region = button.cd:GetRegions()
		button:SetAlpha(0.8)
		
		if (config.showDebuffTimers) then
			region:SetAlpha(1)
			region:SetTextHeight(config.debuffSize)
			region:SetJustifyH("CENTER")
			region:SetJustifyV("MIDDLE")
			region:SetPoint("TOPLEFT", button.cd, "TOPLEFT", -config.debuffSize, 0)
			region:SetPoint("BOTTOMRIGHT", button.cd, "BOTTOMRIGHT", config.debuffSize, 0)
		else
			region:SetAlpha(0)
		end
		button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	end
	
	table.insert(mod.frames, self)
end

--============================================================
-- Build positioning and attributes
--============================================================
function mod:get_attributes()
	local group_by, group_sort, sort_method, yOffset, xOffset, new_group_anchor, new_player_anchor, hgrowth, vgrowth, num_groups
	config.spacing = 2
	
	-- sorting options
	if (config.group_sort == "Group") then
		group_by = "GROUP"
		group_sort = "1, 2, 3, 4, 5, 6, 7, 8"
		sort_method = "INDEX"
	elseif (config.group_sort == "Role") then
		group_by = "ROLE"
		group_sort = "TANK,DAMAGE,NONE,HEAL"
		sort_method = "NAME"
	elseif (config.group_sort == "Name") then
		group_by = nil
		group_sort = "1, 2, 3, 4, 5, 6, 7, 8"
		sort_method = "NAME"
	elseif (config.group_sort == "Class") then
		group_by = "CLASS"
		group_sort = "WARRIOR,DEATHKNIGHT,PALADIN,DRUID,MONK,ROGUE,DEMONHUNTER,HUNTER,PRIEST,WARLOCK,MAGE,SHAMAN"
		sort_method = "NAME"
	end
	
	-- group growth/spacing
	if (config.group_growth == "Upwards") then
		new_group_anchor = "BOTTOM"
		yOffset = config.spacing
	elseif (config.group_growth == "Downwards") then
		new_group_anchor = "TOP"
		xOffset = config.spacing
	elseif (config.group_growth == "Left") then
		new_group_anchor = "RIGHT"
		xOffset = -config.spacing
	elseif (config.group_growth == "Right") then
		new_group_anchor = "LEFT"
		xOffset = config.spacing
	end
	
	-- player growth/spacing
	if (not config.new_player_reverse) then
		if (config.group_growth == "Upwards" or config.group_growth == "Downwards") then
			new_player_anchor = "LEFT"
			xOffset = config.spacing
		elseif (config.group_growth == "Left" or config.group_growth == "Right") then
			new_player_anchor = "TOP"
			yOffset = -config.spacing
		end
	elseif (config.new_player_reverse) then
		if (config.group_growth == "Upwards" or config.group_growth == "Downwards") then
			new_player_anchor = "RIGHT"
			xOffset = -config.spacing
		elseif (config.group_growth == "Left" or config.group_growth == "Right") then
			new_player_anchor = "BOTTOM"
			yOffset = config.spacing
		end
	end
	
	-- group limit
	local difficultySize = {[3] = 1, [4] = 25, [5] = 10, [6] = 25, [7] = 25, [9] = 40, [14] = 30, [15] = 30, [16] = 20, [17] = 30, [18] = 40, [20] = 25}
	num_groups = config.num_groups
	if (config.intel_groups) then
		local difficulty = select(3, GetInstanceInfo()) -- maybe use maxPlayers instead?
		if (difficultySize[difficulty]) then
			num_groups = (difficultySize[difficulty] / 5)
		end
	end
	
	return group_by, group_sort, sort_method, yOffset, xOffset, new_group_anchor, new_player_anchor, hgrowth, vgrowth, num_groups
end

--======================================================
-- Update the raidframe header with new configuration values
--======================================================
function mod:update_header()
	if (InCombatLockdown()) then return end
	
	local group_by, group_sort, sort_method, yOffset, xOffset, new_group_anchor, new_player_anchor, hgrowth, vgrowth, num_groups = mod:get_attributes()
	
	for k, frame in pairs(mod.frames) do
		frame:ClearAllPoints()
	end

	mod:resize_container()
	
	-- growth/spacing
	mod.frameHeader:SetAttribute("columnAnchorPoint", new_group_anchor)
	mod.frameHeader:SetAttribute("point", new_player_anchor)
	mod.frameHeader:SetAttribute("yOffset", yOffset)
	mod.frameHeader:SetAttribute("xOffset", xOffset)

	-- what to show
	mod.frameHeader:SetAttribute("showpartyleadericon", config.showpartyleadericon)
	
	-- when to show
	mod.frameHeader:SetAttribute("showSolo", config.showsolo)
	mod.frameHeader:SetAttribute("maxColumns", num_groups)
	
	-- width/height
	mod.frameHeader:SetAttribute("initial-width", config.width)
	mod.frameHeader:SetAttribute("initial-height", config.height)
	
	-- grouping/sorting
	mod.frameHeader:SetAttribute("groupBy", group_by)
	mod.frameHeader:SetAttribute("groupingOrder", group_sort)
	mod.frameHeader:SetAttribute("sortMethod", sort_method)
end

--======================================================
-- Initialize
--======================================================
function mod:initialize()
	config = mod._config
	bdUI.persistent.GridAliases = bdUI.persistent.GridAliases or {}
	
	local function enable(self)
		self:SetActiveStyle("bdGrid")

		-- Initial header spawning
		local group_by, group_sort, sort_method, yOffset, xOffset, new_group_anchor, new_player_anchor, hgrowth, vgrowth, num_groups = mod:get_attributes()
		mod.frameHeader = self:SpawnHeader(nil, nil, 'raid,party,solo',
			"showParty", true,
			"showPlayer", true,
			"showSolo", config.showsolo,
			"showRaid", true,
			"initial-scale", 1,
			"unitsPerColumn", 5,
			"columnSpacing", 2,
			"xOffset", xOffset,
			"maxColumns", config.num_groups,
			"groupingOrder", group_sort,
			"sortMethod", sort_method,
			"columnAnchorPoint", new_group_anchor,
			"initial-width", config.width,
			"initial-height", config.height,
			"point", new_player_anchor,
			"yOffset", yOffset,
			"groupBy", group_by
		);

		mod:config_callback()

		mod.raidpartyholder:RegisterEvent("PLAYER_REGEN_ENABLED")
		mod.raidpartyholder:RegisterEvent("PLAYER_ENTERING_WORLD")
		mod.raidpartyholder:SetScript("OnEvent", function(self, event, arg1)
			mod:update_header()
		end)
	end

	oUF:RegisterStyle("bdGrid", layout)
	oUF:Factory(enable)

	mod:create_container()
	mod:disable_blizzard()
end

--======================================================
-- Callback on creation and configuration change
--======================================================
function mod:config_callback()
	if (InCombatLockdown()) then return end
	
	for k, self in pairs(mod.frames) do
		self:SetSize(config.width, config.height)
		self.RaidTargetIndicator:SetSize(12, 12)
		self.ReadyCheckIndicator:SetSize(12, 12)
		self.ResurrectIndicator:SetSize(16, 16)
		self.ThreatLite:SetSize(60, 50)
		self.Dispel:SetSize(60, 50)
		
		self.Short:SetWidth(config.width)

		self.Buffs:SetPoint("TOPLEFT", self.Health, "TOPLEFT")
		self.Buffs:SetFrameLevel(27)
		self.Buffs:SetSize(64, 16)

		self.Debuffs:SetPoint("CENTER", self.Health, "CENTER")
		self.Debuffs:SetFrameLevel(27)
		self.Debuffs:SetSize(44, 22)

		self.Buffs.size = config.buffSize
		self.Debuffs.size = config.debuffSize
		
		if (config.powerdisplay == "None") then
			self.Power:Hide()
		elseif (config.powerdisplay == "Healers" and role == "HEALER") then
			self.Power:Show()
		elseif (config.powerdisplay == "All") then
			self.Power:Show()
		end

		self.Power:SetPoint("TOPRIGHT", self.Health, "BOTTOMRIGHT",0, config.powerheight)

		if (config.showGroupNumbers and IsInRaid()) then
			self.Group:Show()
		else
			self.Group:Hide()
		end

		self.Range = {
			insideAlpha = config.inrangealpha,
			outsideAlpha = config.outofrangealpha,
		}

		if (not config.roleicon) then
			self.GroupRoleIndicator:Hide()
		end
		
		local role = UnitGroupRolesAssigned(self.unit)
		self.Power:Hide()
		if (config.powerdisplay == "None") then
			self.Power:Hide()
		elseif (config.powerdisplay == "Healers" and role == "HEALER") then
			self.Power:Show()
		elseif (config.powerdisplay == "All") then
			self.Power:Show()
		end


		-- if (config.hideabsorbs) then
		-- 	self.TotalAbsorb:Hide()
		-- 	self.HealAbsorb:Hide()
		-- else
		-- 	self.TotalAbsorb:Show()
		-- 	self.HealAbsorb:Show()
		-- end
		
		if (config.showGroupNumbers and IsInRaid()) then
			self.Group:Show()
		else
			self.Group:Hide()
		end		
	end
end


--===============================================
-- Raid container, match layout of groups
--===============================================
function mod:create_container()
	mod.raidpartyholder = CreateFrame('frame', "bdGrid", UIParent)
	mod.raidpartyholder:SetSize(config['width']+2, config['height']*5+8)
	mod.raidpartyholder:SetPoint("TOPLEFT", UIParent, "CENTER", -250,200)
	bdMove:set_moveable(mod.raidpartyholder)
end

function mod:resize_container()
	mod.frameHeader:ClearAllPoints();
	if (config.group_growth == "Right") then
		mod.raidpartyholder:SetSize(config.width, config.height*5+8)
		hgrowth = "LEFT"
		vgrowth = "TOP"
		if (config.new_player_reverse) then vgrowth = "BOTTOM" end
		
	elseif (config.group_growth == "Left") then
		mod.raidpartyholder:SetSize(config.width, config.height*5+8)
		hgrowth = "RIGHT"
		vgrowth = "TOP"
		if (config.new_player_reverse) then vgrowth = "BOTTOM" end
		
	elseif (config.group_growth == "Upwards") then
		mod.raidpartyholder:SetSize(config.width*5+8, config.height)
		hgrowth = "LEFT"
		vgrowth = "BOTTOM"
		if (config.new_player_reverse) then hgrowth = "RIGHT" end
		
	elseif (config.group_growth == "Downwards") then
		mod.raidpartyholder:SetSize(config.width*5+8, config.height)
		hgrowth = "LEFT"
		vgrowth = "TOP"
		if (config.new_player_reverse) then hgrowth = "RIGHT" end
	end
	mod.frameHeader:SetPoint(vgrowth..hgrowth, mod.raidpartyholder, vgrowth..hgrowth, 0, 0)
end

--==============================================
-- Disable blizzard raid frames
--==============================================
function mod:disable_blizzard()
	local addonDisabler = CreateFrame("frame", nil)
	addonDisabler:RegisterEvent("ADDON_LOADED")
	addonDisabler:RegisterEvent("PLAYER_REGEN_ENABLED")
	addonDisabler:SetScript("OnEvent", function(self, event, addon)
		if (InCombatLockdown()) then return end
		if (IsAddOnLoaded("Blizzard_CompactRaidFrames")) then
			CompactRaidFrameManager:UnregisterAllEvents() 
			CompactRaidFrameManager:Hide() 
			CompactRaidFrameManager.Show = noop
			CompactRaidFrameContainer:UnregisterAllEvents() 
			CompactRaidFrameContainer:Hide()
			CompactRaidFrameContainer.Show = noop

			addonDisabler:UnregisterEvent("ADDON_LOADED")
			addonDisabler:UnregisterEvent("PLAYER_REGEN_ENABLED")
		end
	end)
end