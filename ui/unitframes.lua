local D, S, E = unpack(select(2, ...))

local ADDON_NAME, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, D.Addon.name .. " was unable to locate oUF install.")

local frameWidth = 240
local frameWidthSmall = 132
local frameWidthRaid = 80
local healthHeight = 18
local castHeight = 16
local castOffset = -20
local powerHeight = 5
local buffHeight = 26


if S.unitframes.floatingcastbars then
	castOffset = 120
end

local function CheckInterrupt(self, unit)
	if unit == "vehicle" then unit = "player" end

	if self.interrupt and UnitCanAttack("player", unit) then
		self:SetStatusBarColor(1, 1, 1, 1)	
	else
		self:SetStatusBarColor(0.31, 0.45, 0.63, 1)		
	end
end

local function CheckCast(self, unit, name, rank, castid)
	CheckInterrupt(self, unit)
end

local function CheckChannel(self, unit, name, rank)
	CheckInterrupt(self, unit)
end

local function CustomCastTimeText(self, duration)
	self.Time:SetText(("%.1f / %.1f"):format(self.channeling and duration or self.max - duration, self.max))
end

oUF.Tags[D.Addon.name.. ':health'] = function(unit)

	if not UnitIsConnected(unit) then
		 return "Disconnected"
	end
	
	if UnitIsDead(unit) then
		return "Dead"
	end
	
	if UnitIsGhost(unit) then
		return "Ghost"
	end
	
	local min = UnitHealth(unit)
	local max = UnitHealthMax(unit)
	
	if min ~= max then
	
		if unit == "player" or unit == "target" or (unit and unit:find("boss%d")) then
			return D.ShortValue(min) .. " | " .. floor(min / max * 100) .. "%"
			
		elseif (unit and unit:find("arena%d")) or unit == "focus" or unit == "focustarget" then
			return D.ShortValue(min)
			
		else
			return D.ShortValueNegative(max-min)
			
		end
	else
		if  unit == "player" or unit == "target" or unit == "focus"  or unit == "focustarget" or (unit and unit:find("arena%d")) then
			return D.ShortValue(max)
			
		else
			return " "
		end
	end
	
end

local function PostCreateAura(element, button)
	
	button.remaining = D.CreateFontString(button, S.fonts.unitframe, 8, "THINOUTLINE")
	button.remaining:SetPoint("CENTER", 1, 0)
	
	button.icon:SetPoint("TOPLEFT", 2, -2)
	button.icon:SetPoint("BOTTOMRIGHT", -2, 2)
	button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	button.icon:SetDrawLayer('ARTWORK')
	
	button.count:SetPoint("BOTTOMRIGHT", 3, 3)
	button.count:SetJustifyH("RIGHT")
	button.count:SetFont(S.fonts.unitframe, 9, "THICKOUTLINE")
	button.count:SetTextColor(0.84, 0.75, 0.65)
	
	button.overlayFrame = CreateFrame("frame", nil, button, nil)
	
	button.overlay:SetParent(button.overlayFrame)
	button.count:SetParent(button.overlayFrame)
	button.remaining:SetParent(button.overlayFrame)
			
	button.Glow = CreateFrame("Frame", nil, button)
	button.Glow:SetPoint("TOPLEFT", button, "TOPLEFT", -1, 1)
	button.Glow:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -1)
	button.Glow:SetFrameStrata("BACKGROUND")	
	button.Glow:SetBackdrop{edgeFile =  S["textures"].shadow, edgeSize = 3, insets = {left = 0, right = 0, top = 0, bottom = 0}}
	button.Glow:SetBackdropColor(0, 0, 0, 0)
	button.Glow:SetBackdropBorderColor(0, 0, 0)
	
end

local function PostUpdateAura(icons, unit, icon, index, offset, filter, isDebuff, duration, timeLeft)
	local _, _, _, _, dtype, duration, expirationTime, unitCaster, _ = UnitAura(unit, index, icon.filter)

	if(icon.debuff) then
		if(not UnitIsFriend("player", unit) and icon.owner ~= "player" and icon.owner ~= "vehicle") then
			--icon:SetBackdropBorderColor(unpack(C["media"].bordercolor))
			icon.icon:SetDesaturated(true)
		else
			local color = DebuffTypeColor[dtype] or DebuffTypeColor.none
			--icon:SetBackdropBorderColor(color.r * 0.6, color.g * 0.6, color.b * 0.6)
			icon.icon:SetDesaturated(false)
		end
	end
	
end

local function CreateMenu(self)

	local unit = self.unit:gsub("(.)", string.upper, 1)
	if unit == "Targettarget" or unit == "focustarget" or unit == "pettarget" then return end

	if _G[unit.."FrameDropDown"] then
		ToggleDropDownMenu(1, nil, _G[unit.."FrameDropDown"], "cursor")
	elseif (self.unit:match("party")) then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor")
	else
		FriendsDropDown.unit = self.unit
		FriendsDropDown.id = self.id
		FriendsDropDown.initialize = RaidFrameDropDown_Initialize
		ToggleDropDownMenu(1, nil, FriendsDropDown, "cursor")
	end
	
end

local function CreateAltBar(self)

	local alt = CreateFrame("StatusBar", nil, self)
	alt:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT",0, -5)
	alt:SetPoint("TOPRIGHT", self.Health, "BOTTOMRIGHT",0, -5)
	alt:SetHeight(5)

	alt:SetStatusBarTexture(S["textures"].blank)
	
	return alt
	
end

local function CreateExperienceBar(self)

	local experience = CreateAltBar(self)
	experience:SetStatusBarColor(0, 0.4, 1, .8)
	
	experience:SetFrameLevel(10)
	experience:SetAlpha(0)
	
	experience:SetScript("OnEnter", function(x) x:SetAlpha(1) end)
	experience:SetScript("OnLeave", function(x) x:SetAlpha(0) end)
	
	self:SetScript("OnEnter", function(x) x.Experience:SetAlpha(1) end)
	self:SetScript("OnLeave", function(x) x.Experience:SetAlpha(0) end)
	
	experience.Tooltip = true
	
	experience.Rested = CreateFrame('StatusBar', nil, self)
	experience.Rested:SetParent(experience)
	experience.Rested:SetAllPoints(experience)
	experience.Rested:SetStatusBarTexture(S["textures"].blank)
	
	D.CreateShadow(experience.Rested)
	D.CreateBackground(experience.Rested)
		
	local resting = experience:CreateTexture(nil, "OVERLAY")
	resting:SetPoint("BOTTOMLEFT", -17 , 12)
	resting:SetSize(28, 28)
	
	resting:SetTexture([=[Interface\CharacterFrame\UI-StateIcon]=])
	resting:SetTexCoord(0, 0.5, 0, 0.421875)
	
	self.Resting = resting
	self.Experience = experience
			
end

local function CreateReputationBar(self)

	local reputation = CreateAltBar(self)
	reputation:SetStatusBarColor(0, 0.4, 1, .8)
	
	D.CreateShadow(reputation)
	D.CreateBackground(reputation)
	
	reputation:SetFrameLevel(10)
	reputation:SetAlpha(0)
	
	reputation:SetScript("OnEnter", function(x) x:SetAlpha(1) end)
	reputation:SetScript("OnLeave", function(x) x:SetAlpha(0) end)
	
	self:SetScript("OnEnter", function(x) x.Reputation:SetAlpha(1) end)
	self:SetScript("OnLeave", function(x) x.Reputation:SetAlpha(0) end)
	
	self.Reputation = reputation
end

local function CreateCombatIndicator(self)

	local combat = self.Health:CreateTexture(nil, "OVERLAY")
	combat:SetHeight(19)
	combat:SetWidth(19)
	combat:SetPoint("LEFT", self.Name, "Right", 0, 1)
	combat:SetVertexColor(0.69, 0.31, 0.31)
	self.Combat = combat
	
end

local function CreateLeaderAndMasterLooter(self)

	local leader = self.Health:CreateTexture(nil, "OVERLAY")
	leader:SetHeight(14)
	leader:SetWidth(14)
	leader:SetPoint("CENTER", self.Health, "CENTER", -15, 1)
	self.Leader = leader
	
	-- master looter
	local masterLooter = self.Health:CreateTexture(nil, "OVERLAY")
	masterLooter:SetHeight(14)
	masterLooter:SetWidth(14)
	masterLooter:SetPoint("CENTER", self.Health, "CENTER", 15, 1)
	self.MasterLooter = masterLooter
	
end

local function CreateRaidIcon(self)

	local raidIcon = self.Health:CreateTexture(nil, "OVERLAY")
	raidIcon:SetTexture(S["textures"].raidicons) -- thx hankthetank for texture
	raidIcon:SetHeight(20)
	raidIcon:SetWidth(20)
	raidIcon:SetPoint("TOP", 0, 11)
	
	self.RaidIcon = raidIcon
	
end

local function CreateComboPoints(self)
	
	local spacing = 4
	local numberOfPoints = 5
	local totalSpacing = (numberOfPoints - 1) * spacing 
	local pointWidth = (self:GetWidth()  - totalSpacing) / numberOfPoints
	
	
	local points = {}
	points.unit = PlayerFrame.unit
	
	for i = 1, numberOfPoints do
	
		points[i] = CreateFrame("Frame", nil, self)
		points[i]:SetHeight(8)
		points[i]:SetWidth(pointWidth)

		D.CreateBackground(points[i])
		D.CreateShadow(points[i], "Default")
	
		points[i].bg:SetBackdropColor(0.65, 0.63, 0.35, 0.6)
		if i == 1 then
			points[i]:SetPoint("TOPLEFT", self.Castbar, "BOTTOMLEFT", 0, -5)
		else
			points[i]:SetPoint("LEFT", points[i-1], "RIGHT", spacing, 0)
		end
		
	end
	
	self.CPoints = points
	
end

local function CreateBuffs(self)
	
	local buffs = CreateFrame("Frame", nil, self)
	buffs:SetPoint("BOTTOMLEFT", self.Power, "TOPLEFT", -1, 5)
	buffs:SetPoint("BOTTOMRIGHT", self.Power, "TOPRIGHT", -1, 5)
	buffs:SetHeight(buffHeight)
	buffs.size = buffHeight
	buffs.num = 9
	buffs.spacing = 1
	buffs.initialAnchor = 'BOTTOMLEFT'
	
	buffs.PostCreateIcon = PostCreateAura
	buffs.PostUpdateIcon = PostUpdateAura
	self.Buffs = buffs
	
end

local function CreateDebuffs(self)

	local anchor = self.Buffs or self.Power
	
	local debuffs = CreateFrame("Frame", nil, self)
	debuffs:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", -1, 5)
	debuffs:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", -1, 5)
	debuffs:SetHeight(buffHeight)
	debuffs.size = buffHeight
	debuffs.num = 9
	debuffs.spacing = 1
	debuffs.initialAnchor = 'BOTTOMLEFT'
	
	debuffs.PostCreateIcon = PostCreateAura
	debuffs.PostUpdateIcon = PostUpdateAura
	self.Debuffs = debuffs
	
end

local function CreateCastbar(self)
	
	local castbar = CreateFrame("StatusBar", nil, self)
	castbar:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 0, castOffset)
	castbar:SetPoint("TOPRIGHT", self.Health, "BOTTOMRIGHT", 0, castOffset)
	castbar:SetHeight(castHeight)
	
	castbar:SetStatusBarTexture(S["textures"].normal)
	D.CreateShadow(castbar)
	D.CreateBackground(castbar)
	
	castbar.PostCastStart = CheckCast
	castbar.PostChannelStart = CheckChannel
	
	castbar.Text = D.CreateFontString(castbar, S.fonts.unitframe, 12)
	castbar.Text:SetPoint("LEFT", castbar, "LEFT", 4, 0)
	castbar.Text:SetTextColor(1, 1, 1)
	
	castbar.Time = D.CreateFontString(castbar, S.fonts.unitframe, 12)
	castbar.Time:SetPoint("RIGHT", castbar, "RIGHT", -4, 0)
	castbar.Time:SetTextColor(0.8, 0.8, 0.8)
	castbar.Time:SetJustifyH("RIGHT")
	castbar.CustomTimeText = CustomCastTimeText
	
	castbar.button = CreateFrame("Frame", nil, castbar)
	castbar.button:SetHeight(20)
	castbar.button:SetWidth(20)
	castbar.button:SetPoint("RIGHT", castbar, "LEFT", -5, 0)
	
	castbar.Icon = castbar.button:CreateTexture(nil, "ARTWORK")
	castbar.Icon:SetPoint("TOPLEFT", castbar.button, 0, 0)
	castbar.Icon:SetPoint("BOTTOMRIGHT", castbar.button, 0, 0)
	castbar.Icon:SetTexCoord(0.08, 0.92, 0.08, .92)

	D.CreateShadow(castbar.button)

	self.Castbar = castbar
	
end

local function Shared(self, unit)

	self:RegisterForClicks("AnyUp")
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)
	
	self.colors = S["colors"]
	self.menu = CreateMenu
	
	self:SetWidth(frameWidth) --, )
	self:SetHeight(healthHeight + castHeight + powerHeight)
	
	
	
	local health = CreateFrame('StatusBar', nil, self)
	health:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
	health:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0)
	health:SetHeight(healthHeight)
	
	health:SetStatusBarTexture(S["textures"].normal)
	D.CreateShadow(health, "Default")
	
	health.frequentUpdates = true
	health.colorDisconnected = true
	health.colorTapping = true	
	health.colorClass = true
	health.colorReaction = true			
	
	local healthBG = health:CreateTexture(nil, 'BORDER')
	healthBG:SetAllPoints(health)
	healthBG:SetTexture(S["textures"].normal)
	healthBG.multiplier = 0.3
	health.bg = healthBG
	
	local healthValue = D.CreateFontString(health, S.fonts.unitframe, 12)
	healthValue:SetPoint("RIGHT", health, "RIGHT", -4, 0)
	healthValue.frequentUpdates = true
	
	self:Tag(healthValue, '[' .. D.Addon.name .. ':health]')
	
	self.Health = health
	self.HealthValue = healthValue
	
	local name =  D.CreateFontString(health, S.fonts.unitframe, 12, "OUTLINE")
	name:SetPoint("LEFT", health, "LEFT", 4, 0)
	name:SetTextColor(1, 1, 1)
	name:SetJustifyH("LEFT")
	
	self.Name = name
	self:Tag(name, '[name]')
	
	local power = CreateFrame('StatusBar', nil, self)
	power:SetPoint("BOTTOMLEFT", health, "TOPLEFT", 0, 5)
	power:SetPoint("BOTTOMRIGHT", health, "TOPRIGHT", 0, 5)
	power:SetHeight(powerHeight)
	
	power:SetStatusBarTexture(S["textures"].normal)
	D.CreateShadow(power, "Default")
	
	local bg = power:CreateTexture(nil, 'BORDER')
	bg:SetAllPoints(power)
	bg:SetTexture(S["textures"].normal)
	bg.multiplier = 0.3
	
	power.bg = bg 
	
	power.frequentUpdates = true
	power.Smooth = true
	
	power.colorDisconnected = true	
	power.colorTapping = true
	power.colorPower = true

	self.Power = power

	CreateRaidIcon(self)
	
end


local UnitSpecific = {

	player = function(self, ...)
		Shared(self, ...)
		
		CreateCastbar(self)
		CreateDebuffs(self)
		CreateComboPoints(self)
		CreateCombatIndicator(self)
		CreateLeaderAndMasterLooter(self)
		
		self.Castbar:ClearAllPoints()
		self.Castbar:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 0, 100)
		self.Castbar:SetPoint("BOTTOMRIGHT", self.Health, "TOPRIGHT", 0, 100)
		
		if D.Player.level ~= MAX_PLAYER_LEVEL then
			CreateExperienceBar(self)
		else
			CreateReputationBar(self)
		end
		
	end,
	
	target = function(self, ...)
		Shared(self, ...)
		
		CreateCastbar(self)
		CreateBuffs(self)
		CreateDebuffs(self)
		
	end,
	
	targettarget = function(self, ...)
		Shared(self, ...)
		
		self:SetWidth(frameWidthSmall)
		
	end,
	
	pet = function(self, ...)
		Shared(self, ...)
		
		self:SetWidth(frameWidthSmall)
		
		CreateCastbar(self)
		
		self.Castbar:ClearAllPoints()
		self.Castbar:SetPoint("BOTTOMLEFT", self.Power, "TOPLEFT", 0, 5)
		self.Castbar:SetPoint("BOTTOMRIGHT", self.Power, "TOPRIGHT", 0, 5)
		
		self:RegisterEvent("UNIT_PET", function(frame)
		
			for _, v in ipairs(frame.__elements) do
				v(frame, "UpdateElement", frame.unit)
			end
			
		end)
		
	end,
	
	boss = function(self, ...)
		Shared(self, ...)
		
		self:SetWidth(frameWidthSmall)
		
	end,
	
	raid = function(self, ...)
		Shared(self, ...)
		
		self:SetHeight(healthHeight)
		self:SetWidth(frameWidthRaid)
		
		D.Kill(self.Power)
		self.Power = nil
		
		self:Tag(self.HealthValue, '')
	end,
	
}
UnitSpecific.focustarget = UnitSpecific.targettarget
UnitSpecific.focus = UnitSpecific.target



oUF:RegisterStyle(D.Addon.name, Shared)
for unit,layout in next, UnitSpecific do
	-- Capitalize the unit name, so it looks better.
	oUF:RegisterStyle(D.Addon.name .. unit:gsub("^%l", string.upper), layout)
end


local spawnHelper = function(self, unit, ...)

	if UnitSpecific[unit]  then
		self:SetActiveStyle(D.Addon.name .. unit:gsub("^%l", string.upper))
	elseif UnitSpecific[unit:match('[^%d]+')] then -- boss1 -> boss
		self:SetActiveStyle(D.Addon.name .. unit:match('[^%d]+'):gsub("^%l", string.upper))
	else
		self:SetActiveStyle(D.Addon.name)
	end
	
	return self:Spawn(unit)
 
end

oUF:Factory(function(self)
	
	local xoffset = 250
	local yoffset = 100
	
	
	local player = spawnHelper(self, 'player')
	player:SetPoint("BOTTOM", DarkuiFrame, "BOTTOM", 0, 150)
	
	local pet = spawnHelper(self, 'pet')
	pet:SetPoint("RIGHT", player, "LEFT", -25, 0)
	
	local target = spawnHelper(self, 'target')
	target:SetPoint("LEFT", player, "CENTER", xoffset, yoffset)
	
	local targettarget	= spawnHelper(self, 'targettarget')
	targettarget:SetPoint("LEFT", target, "RIGHT", 25, 0)
	
	local focus = spawnHelper(self, 'focus')
	focus:SetPoint("RIGHT", player, "CENTER", -xoffset, yoffset)

	local focustarget = spawnHelper(self, 'focustarget')
	focustarget:SetPoint("RIGHT", focus, "LEFT", -25, 0)
	
	for i = 1,MAX_BOSS_FRAMES do
		local t_boss = _G["Boss"..i.."TargetFrame"]
		t_boss:UnregisterAllEvents()
		t_boss.Show = D.Dummy
		t_boss:Hide()
		_G["Boss"..i.."TargetFrame".."HealthBar"]:UnregisterAllEvents()
		_G["Boss"..i.."TargetFrame".."ManaBar"]:UnregisterAllEvents()
	end

	local boss = {}
	for i = 1, MAX_BOSS_FRAMES do
	
		boss[i] = spawnHelper(self, "boss"..i)
		
		if i == 1 then
			boss[i]:SetPoint("BOTTOMRIGHT", DarkuiBar5, "BOTTOMLEFT", -50, -15)
		else
			boss[i]:SetPoint('BOTTOM', boss[i-1], 'TOP', 0, 35)             
		end
		
	end
	
	
	self:SetActiveStyle(D.Addon.name .. "Raid")
	local raid = {}
	for i = 1, 8 do
		local group = oUF:SpawnHeader(D.Addon.name .. 'raid' ..i, nil, "raid,party",
			'oUF-initialConfigFunction', ([[
											self:SetWidth(71)
											self:SetHeight(%d)
										 ]]):format(healthHeight),
			'showPlayer', true,
			'showSolo', true,
			'showParty', true,
			'showRaid', true,
			'xoffset', -5,
			'yOffset', 0,
			'point', "RIGHT",
			'groupFilter', i)
		
		if i == 1 then
			group:SetPoint("BOTTOMRIGHT", DarkuiFrame, "BOTTOMRIGHT", 0, 0)
		else
			group:SetPoint("BOTTOMRIGHT", raid[i-1], "TOPRIGHT", 0, 5)
		end
		raid[i] = group
	end
	
end)
