-----------------------------------------------------------------------------------------------
-- Client Lua Script for FloatTextPanel
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "Spell"
require "CombatFloater"
require "GameLib"
require "Unit"

local IronCombatText = {}

local knTestingVulnerable = -1

-- Helper function for taking unlimited arguments to a function.
local function GoodPrint(...)
    local args = { n = select("#", ...), ... }
    local toPrint = ""
    for i = 1, args.n do
        local arg
        if (args[i] ~= nil) then 
            arg = tostring(args[i])
        else
            arg = "nil"
        end
        toPrint = toPrint .. arg .. " "
    end
    Print(toPrint)
end

function IronCombatText:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function IronCombatText:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

-- Save settings, character level
function IronCombatText:OnSave(eType)
	if eType == GameLib.CodeEnumAddonSaveLevel.Character then
		return self.tSettings
	end

	return nil
end

-- Setup the settings, character level
function IronCombatText:OnRestore(eType, tSaveData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then return end

	if tSaveData == nil then
		self.tSettings = self:GetDefaultSettings()
	else
		self.tSettings = tSaveData
	end
end

function KeySet(tInput)
	local idx = 0
	local tKeySet = {}
	for key, value in pairs(tInput) do
		idx = idx + 1
		tKeySet[idx] = key
	end
	
	return tKeySet
end

function IronCombatText:CompareSettings(tOther)
	local tDefault = self:GetDefaultSettings()
	for kRhs, vRhs in pairs(tDefault) do
		for kLhs, vRhs in pairs(tOther) do
			if kRhs == kLhs then
				tDefault[kRhs] = vRhs
			end
		end
	end
	
	return tDefault
end

-- Default Settings that are loaded with the addon if there's no save data
function IronCombatText:GetDefaultSettings()
	local tSettings = {}
	tSettings.bShowMultiHit = true
	tSettings.cDmgDefault = 0xf4e443
	tSettings.cDmgMultiHit = 0x0088ff
	tSettings.cDmgCrit = 0xfffb93
	tSettings.cDmgVuln = 0xf5a2ff
	tSettings.cDmgInDefault = 0xff3333
	tSettings.cDmgInCrit = 0xff0000
	tSettings.cHealDefault = 0x73E684
	tSettings.cHealCrit = 0x4AE862
	tSettings.cHealMultiHit = 0x469AE3
	tSettings.cHealShield = 0x68DBE3
	tSettings.iBigCritValue = 10000
	tSettings.iBigCritInValue = 30000
	tSettings.fCritScale = 1.25
	tSettings.fNormalScale = 1.00
	tSettings.fCritInScale = 1.0
	tSettings.fNormalInScale = 0.75
	tSettings.tKeySet = KeySet(tSettings)
	return tSettings
end	

function IronCombatText:OnLoad()
	-- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("OptionsPanel.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- IronCombatText OnDocLoaded
-----------------------------------------------------------------------------------------------
function IronCombatText:OnDocLoaded()
-----------------------------------------------------------------------------------------------
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "AltSettings", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(false, true)
	
		-- Test to see if we have settings
		if self.tSettings == nil then
			self.tSettings = self:GetDefaultSettings()
		else
			self.tSettings = self:CompareSettings(self.tSettings)
		end
				
		self.content = self.wndMain:FindChild("Content")
		self.currentCategory = "General"
		self:LoadCategory(self.currentCategory)
		
		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("ict", "OnIronCombatOn", self)
		Apollo.RegisterEventHandler("OptionsUpdated_Floaters", 					"OnOptionsUpdated", self)

		Apollo.RegisterEventHandler("ChannelUpdate_Loot",						"OnChannelUpdate_Loot", self)
		Apollo.RegisterEventHandler("SpellCastFailed", 							"OnSpellCastFailed", self)
		Apollo.RegisterEventHandler("DamageOrHealingDone",				 		"OnDamageOrHealing", self)
		Apollo.RegisterEventHandler("CombatMomentum", 							"OnCombatMomentum", self)
		Apollo.RegisterEventHandler("ExperienceGained", 						"OnExperienceGained", self)	-- UI_XPChanged ?
		Apollo.RegisterEventHandler("ElderPointsGained", 						"OnElderPointsGained", self)
		Apollo.RegisterEventHandler("UpdatePathXp", 							"OnPathExperienceGained", self)
		Apollo.RegisterEventHandler("AttackMissed", 							"OnMiss", self)
		Apollo.RegisterEventHandler("SubZoneChanged", 							"OnSubZoneChanged", self)
		Apollo.RegisterEventHandler("RealmBroadcastTierMedium", 				"OnRealmBroadcastTierMedium", self)
		Apollo.RegisterEventHandler("GenericError", 							"OnGenericError", self)
		Apollo.RegisterEventHandler("PrereqFailureMessage",					 	"OnPrereqFailed", self)
		Apollo.RegisterEventHandler("GenericFloater", 							"OnGenericFloater", self)
		Apollo.RegisterEventHandler("UnitEvaded", 								"OnUnitEvaded", self)
		Apollo.RegisterEventHandler("QuestShareFloater", 						"OnQuestShareFloater", self)
		Apollo.RegisterEventHandler("CountdownTick", 							"OnCountdownTick", self)
		Apollo.RegisterEventHandler("TradeSkillFloater",				 		"OnTradeSkillFloater", self)
		Apollo.RegisterEventHandler("FactionFloater", 							"OnFactionFloater", self)
		Apollo.RegisterEventHandler("FloaterTransference", 						"OnFloaterTransference", self)
		Apollo.RegisterEventHandler("CombatLogCCState", 						"OnCombatLogCCState", self)
		Apollo.RegisterEventHandler("CombatLogImmunity", 						"OnCombatLogImmunity", self)
		Apollo.RegisterEventHandler("FloaterMultiHit", 							"OnFloaterMultiHit", self)
		Apollo.RegisterEventHandler("FloaterMultiHeal", 						"OnFloaterMultiHeal", self)
		Apollo.RegisterEventHandler("ActionBarNonSpellShortcutAddFailed", 		"OnActionBarNonSpellShortcutAddFailed", self)
		Apollo.RegisterEventHandler("GenericEvent_GenericError",				"OnGenericError", self)
	
		-- set the max count of floater text
		CombatFloater.SetMaxFloaterCount(500)
		CombatFloater.SetMaxFloaterPerUnitCount(500)
	
		-- float text queue for delayed text
		self.tDelayedFloatTextQueue = Queue:new()
		self.iTimerIndex = 1
		self.tTimerFloatText = {}
	
		self:OnOptionsUpdated()
	
		-- Do additional Addon initialization here
	end	
end

function IronCombatText:OnIronCombatOn()
	self.wndMain:Invoke()
	self:LoadCategory(self.currentCategory)
end

function IronCombatText:OnOptionsUpdated()
	if g_InterfaceOptions and g_InterfaceOptions.Carbine.bSpellErrorMessages ~= nil then
		self.bSpellErrorMessages = g_InterfaceOptions.Carbine.bSpellErrorMessages
	else
		self.bSpellErrorMessages = true
	end
end

function IronCombatText:GetDefaultTextOption()
	local tTextOption =
	{
		strFontFace 				= "CRB_FloaterLarge",
		fDuration 					= 2,
		fScale 						= 0.9,
		fExpand 					= 1,
		fVibrate 					= 0,
		fSpinAroundRadius 			= 0,
		fFadeInDuration 			= 0,
		fFadeOutDuration 			= 0,
		fVelocityDirection 			= 0,
		fVelocityMagnitude 			= 0,
		fAccelDirection 			= 0,
		fAccelMagnitude 			= 0,
		fEndHoldDuration 			= 0,
		eLocation 					= CombatFloater.CodeEnumFloaterLocation.Top,
		fOffsetDirection 			= 0,
		fOffset 					= -0.5,
		eCollisionMode 				= CombatFloater.CodeEnumFloaterCollisionMode.Horizontal,
		fExpandCollisionBoxWidth 	= 1,
		fExpandCollisionBoxHeight 	= 1,
		nColor 						= 0xFFFFFF,
		iUseDigitSpriteSet 			= nil,
		bUseScreenPos 				= false,
		bShowOnTop 					= false,
		fRotation 					= 0,
		fDelay 						= 0,
		nDigitSpriteSpacing 		= 0,
	}
	return tTextOption
end

---------------------------------------------------------------------------------------------------
function IronCombatText:OnSpellCastFailed( eMessageType, eCastResult, unitTarget, unitSource, strMessage )
	if unitTarget == nil or not Apollo.GetConsoleVariable("ui.showCombatFloater") then
		return
	end

	-- modify the text to be shown
	local tTextOption = self:GetDefaultTextOption()
	tTextOption.bUseScreenPos = true
	tTextOption.fOffset = -80
	tTextOption.nColor = 0xFFFFFF
	tTextOption.strFontFace = "CRB_Interface16_BO"
	tTextOption.bShowOnTop = true
	tTextOption.arFrames =
	{
		[1] = {fTime = 0,		fScale = 1.5,	fAlpha = 0.8,},
		[2] = {fTime = 0.1,		fScale = 1,	fAlpha = 0.8,},
		[3] = {fTime = 1.1,		fScale = 1,	fAlpha = 0.8,	fVelocityDirection = 0,},
		[4] = {fTime = 1.3,		fScale = 1,	fAlpha = 0.0,	fVelocityDirection = 0,},
	}

	if self.bSpellErrorMessages then -- This is set by interface options
		self:RequestShowTextFloater(LuaEnumMessageType.SpellCastError, unitSource, strMessage, tTextOption)
	end
end

---------------------------------------------------------------------------------------------------
function IronCombatText:OnSubZoneChanged(idZone, strZoneName)
	-- if you're in a taxi, don't show zone change
	if GameLib.GetPlayerTaxiUnit() then
		return
	end

	local tTextOption = self:GetDefaultTextOption()
	tTextOption.bUseScreenPos = true
	tTextOption.fOffset = -280
	tTextOption.nColor = 0x80ffff
	tTextOption.strFontFace = "CRB_HeaderGigantic_O"
	tTextOption.bShowOnTop = true
	tTextOption.arFrames=
	{
		[1] = {fTime = 0,	fAlpha = 0,		fScale = .8,},
		[2] = {fTime = 0.6, fAlpha = 1.0,},
		[3] = {fTime = 4.6,	fAlpha = 1.0,},
		[4] = {fTime = 5.2, fAlpha = 0,},
	}

	self:RequestShowTextFloater( LuaEnumMessageType.ZoneName, GameLib.GetControlledUnit(), strZoneName, tTextOption )
end

---------------------------------------------------------------------------------------------------
function IronCombatText:OnRealmBroadcastTierMedium(strMessage)
	local tTextOption = self:GetDefaultTextOption()
	tTextOption.bUseScreenPos = true
	tTextOption.fOffset = -180
	tTextOption.nColor = 0x80ffff
	tTextOption.strFontFace = "CRB_HeaderGigantic_O"
	tTextOption.bShowOnTop = true
	tTextOption.arFrames=
	{
		[1] = {fTime = 0,	fAlpha = 0,		fScale = .8,},
		[2] = {fTime = 0.6, fAlpha = 1.0,},
		[3] = {fTime = 4.6,	fAlpha = 1.0,},
		[4] = {fTime = 5.2, fAlpha = 0,},
	}

	self:RequestShowTextFloater( LuaEnumMessageType.RealmBroadcastTierMedium, GameLib.GetControlledUnit(), strMessage, tTextOption )
end

---------------------------------------------------------------------------------------------------
function IronCombatText:OnActionBarNonSpellShortcutAddFailed()
	local strMessage = Apollo.GetString("FloatText_ActionBarAddFail")
	self:OnSpellCastFailed( LuaEnumMessageType.GenericPlayerInvokedError, nil, GameLib.GetControlledUnit(), GameLib.GetControlledUnit(), strMessage )
end

---------------------------------------------------------------------------------------------------
function IronCombatText:OnGenericError(eError, strMessage)
	local arExciseListItem =  -- index is enums to respond to, value is optional (UNLOCALIZED) replacement string (otherwise the passed string is used)
	{
		[GameLib.CodeEnumGenericError.DbFailure] 						= "",
		[GameLib.CodeEnumGenericError.Item_BadId] 						= "",
		[GameLib.CodeEnumGenericError.Vendor_StackSize] 				= "",
		[GameLib.CodeEnumGenericError.Vendor_SoldOut] 					= "",
		[GameLib.CodeEnumGenericError.Vendor_UnknownItem] 				= "",
		[GameLib.CodeEnumGenericError.Vendor_FailedPreReq] 				= "",
		[GameLib.CodeEnumGenericError.Vendor_NotAVendor] 				= "",
		[GameLib.CodeEnumGenericError.Vendor_TooFar] 					= "",
		[GameLib.CodeEnumGenericError.Vendor_BadItemRec] 				= "",
		[GameLib.CodeEnumGenericError.Vendor_NotEnoughToFillQuantity] 	= "",
		[GameLib.CodeEnumGenericError.Vendor_NotEnoughCash] 			= "",
		[GameLib.CodeEnumGenericError.Vendor_UniqueConstraint] 			= "",
		[GameLib.CodeEnumGenericError.Vendor_ItemLocked] 				= "",
		[GameLib.CodeEnumGenericError.Vendor_IWontBuyThat] 				= "",
		[GameLib.CodeEnumGenericError.Vendor_NoQuantity] 				= "",
		[GameLib.CodeEnumGenericError.Vendor_BagIsNotEmpty] 			= "",
		[GameLib.CodeEnumGenericError.Vendor_CuratorOnlyBuysRelics] 	= "",
		[GameLib.CodeEnumGenericError.Vendor_CannotBuyRelics] 			= "",
		[GameLib.CodeEnumGenericError.Vendor_NoBuyer] 					= "",
		[GameLib.CodeEnumGenericError.Vendor_NoVendor] 					= "",
		[GameLib.CodeEnumGenericError.Vendor_Buyer_NoActionCC] 			= "",
		[GameLib.CodeEnumGenericError.Vendor_Vendor_NoActionCC] 		= "",
		[GameLib.CodeEnumGenericError.Vendor_Vendor_Disposition] 		= "",
	}

	if arExciseListItem[eError] then -- list of errors we don't want to show floaters for
		return
	end

	self:OnSpellCastFailed( LuaEnumMessageType.GenericPlayerInvokedError, nil, GameLib.GetControlledUnit(), GameLib.GetControlledUnit(), strMessage )
end

---------------------------------------------------------------------------------------------------
function IronCombatText:OnPrereqFailed(strMessage)
	self:OnGenericError(nil, strMessage)
end

---------------------------------------------------------------------------------------------------
function IronCombatText:OnGenericFloater(unitTarget, strMessage)
	-- modify the text to be shown
	local tTextOption = self:GetDefaultTextOption()
	tTextOption.fDuration = 2
	tTextOption.bUseScreenPos = true
	tTextOption.fOffset = 0
	tTextOption.nColor = 0x00FFFF
	tTextOption.strFontFace = "CRB_HeaderLarge_O"
	tTextOption.bShowOnTop = true

	CombatFloater.ShowTextFloater( unitTarget, strMessage, tTextOption )
end

function IronCombatText:OnUnitEvaded(unitSource, unitTarget, eReason, strMessage)
	local tTextOption = self:GetDefaultTextOption()
	tTextOption.fScale = 1.0
	tTextOption.fDuration = 2
	tTextOption.nColor = 0xbaeffb
	tTextOption.strFontFace = "CRB_FloaterSmall"
	tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.IgnoreCollision
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Chest
	tTextOption.fOffset = -0.8
	tTextOption.fOffsetDirection = 0

	tTextOption.arFrames =
	{
		[1] = {fTime = 0,		fScale = 2.0,	fAlpha = 1.0,	nColor = 0xFFFFFF,},
		[2] = {fTime = 0.15,	fScale = 0.9,	fAlpha = 1.0,},
		[3] = {fTime = 1.1,		fScale = 0.9,	fAlpha = 1.0,	fVelocityDirection = 0,	fVelocityMagnitude = 5,},
		[4] = {fTime = 1.3,						fAlpha = 0.0,	fVelocityDirection = 0,},
	}

	CombatFloater.ShowTextFloater( unitSource, strMessage, tTextOption )
end

---------------------------------------------------------------------------------------------------
function IronCombatText:OnAlertTitle(strMessage)
	local tTextOption = self:GetDefaultTextOption()
	tTextOption.fDuration = 2
	tTextOption.fFadeInDuration = 0.2
	tTextOption.fFadeOutDuration = 0.5
	tTextOption.fVelocityMagnitude = 0.2
	tTextOption.fOffset = 0.2
	tTextOption.nColor = 0xFFFF00
	tTextOption.strFontFace = "CRB_HeaderLarge_O"
	tTextOption.bShowOnTop = true
	tTextOption.fScale = 1
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Top

	CombatFloater.ShowTextFloater( GameLib.GetControlledUnit(), strMessage, tTextOption )
end

---------------------------------------------------------------------------------------------------
function IronCombatText:OnQuestShareFloater(unitTarget, strMessage)
	local tTextOption = self:GetDefaultTextOption()
	tTextOption.fDuration = 2
	tTextOption.fFadeInDuration = 0.2
	tTextOption.fFadeOutDuration = 0.5
	tTextOption.fVelocityMagnitude = 0.2
	tTextOption.fOffset = 0.2
	tTextOption.nColor = 0xFFFF00
	tTextOption.strFontFace = "CRB_HeaderLarge_O"
	tTextOption.bShowOnTop = true
	tTextOption.fScale = 1
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Top

	CombatFloater.ShowTextFloater( unitTarget, strMessage, tTextOption )
end

---------------------------------------------------------------------------------------------------
function IronCombatText:OnCountdownTick(strMessage)
	local tTextOption = self:GetDefaultTextOption()
	tTextOption.fDuration = 1
	tTextOption.fFadeInDuration = 0.2
	tTextOption.fFadeOutDuration = 0.2
	tTextOption.fVelocityMagnitude = 0.2
	tTextOption.fOffset = 0.2
	tTextOption.nColor = 0x00FF00
	tTextOption.strFontFace = "CRB_HeaderLarge_O"
	tTextOption.bShowOnTop = true
	tTextOption.fScale = 1
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Top

	CombatFloater.ShowTextFloater( GameLib.GetControlledUnit(), strMessage, tTextOption )
end

---------------------------------------------------------------------------------------------------
function IronCombatText:OnDeath()
	local tTextOption = self:GetDefaultTextOption()
	tTextOption.fDuration = 2
	tTextOption.fFadeOutDuration = 1.5
	tTextOption.fScale = 1.2
	tTextOption.nColor = 0xFFFFFF
	tTextOption.strFontFace = "CRB_HeaderLarge_O"
	tTextOption.bShowOnTop = true
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Top
	tTextOption.fOffset = 1

	CombatFloater.ShowTextFloater( GameLib.GetControlledUnit(), Apollo.GetString("Player_Incapacitated"), tTextOption )
end


---------------------------------------------------------------------------------------------------
function IronCombatText:OnFloaterMultiHit(tEventArgs)
	local bCritical = tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical
	if tEventArgs.unitCaster == GameLib.GetControlledUnit() then -- Target does the transference to the source
		self:OnDamageOrHealing( tEventArgs.unitCaster, tEventArgs.unitTarget, tEventArgs.eDamageType, math.abs(tEventArgs.nDamageAmount), math.abs(tEventArgs.nShield), math.abs(tEventArgs.nAbsorption), bCritical, true )
	else -- creature taking damage
		self:OnPlayerDamageOrHealing( tEventArgs.unitTarget, tEventArgs.eDamageType, math.abs(tEventArgs.nDamageAmount), math.abs(tEventArgs.nShield), math.abs(tEventArgs.nAbsorption), bCritical, true )
	end
end

---------------------------------------------------------------------------------------------------
function IronCombatText:OnFloaterMultiHeal(tEventArgs)
	local bCritical = tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical
	
	if tEventArgs.unitTarget == GameLib.GetPlayerUnit() then -- source recieves the transference from the taker
		self:OnPlayerDamageOrHealing(tEventArgs.unitCaster, GameLib.CodeEnumDamageType.Heal, math.abs(tEventArgs.nHealAmount), 0, 0, bCritical )
	else
		self:OnDamageOrHealing(tEventArgs.unitCaster, tEventArgs.unitTarget, GameLib.CodeEnumDamageType.Heal, math.abs(tEventArgs.nHealAmount), 0, 0, bCritical )
	end
end

---------------------------------------------------------------------------------------------------
function IronCombatText:OnFloaterTransference(tEventArgs)
	local bCritical = tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical
	if tEventArgs.unitCaster == GameLib.GetControlledUnit() then -- Target does the transference to the source
		self:OnDamageOrHealing( tEventArgs.unitCaster, tEventArgs.unitTarget, tEventArgs.eDamageType, math.abs(tEventArgs.nDamageAmount), math.abs(tEventArgs.nShield), math.abs(tEventArgs.nAbsorption), bCritical )
	else -- creature taking damage
		self:OnPlayerDamageOrHealing( tEventArgs.unitTarget, tEventArgs.eDamageType, math.abs(tEventArgs.nDamageAmount), math.abs(tEventArgs.nShield), math.abs(tEventArgs.nAbsorption), bCritical )
	end

	-- healing data is stored in a table where each subtable contains a different vital that was healed
	-- units in caster's group can get healed
	for idx, tHeal in ipairs(tEventArgs.tHealData) do
		if tHeal.unitHealed == GameLib.GetPlayerUnit() then -- source recieves the transference from the taker
			self:OnPlayerDamageOrHealing(tEventArgs.unitCaster, GameLib.CodeEnumDamageType.Heal, math.abs(tHeal.nHealAmount), 0, 0, bCritical )
		else
			self:OnDamageOrHealing(tEventArgs.unitCaster, tHeal.unitHealed, tEventArgs.eDamageType, math.abs(tHeal.nHealAmount), 0, 0, bCritical )
		end
	end
end

---------------------------------------------------------------------------------------------------
function IronCombatText:OnCombatMomentum( eMomentumType, nCount, strText )
	-- Passes: type enum, player's total count for that bonus type, string combines these things (ie. "3 Evade")
	local arMomentumStrings =
	{
		[CombatFloater.CodeEnumCombatMomentum.Impulse] 				= "FloatText_Impulse",
		[CombatFloater.CodeEnumCombatMomentum.KillingPerformance] 	= "FloatText_KillPerformance",
		[CombatFloater.CodeEnumCombatMomentum.KillChain] 			= "FloatText_KillChain",
		[CombatFloater.CodeEnumCombatMomentum.Evade] 				= "FloatText_Evade",
		[CombatFloater.CodeEnumCombatMomentum.Interrupt] 			= "FloatText_Interrupt",
		[CombatFloater.CodeEnumCombatMomentum.CCBreak] 				= "FloatText_StateBreak",
	}

	if not Apollo.GetConsoleVariable("ui.showCombatFloater") or arMomentumStrings[eMomentumType] == nil  then
		return
	end

	local nBaseColor = 0x7eff8f
	local tTextOption = self:GetDefaultTextOption()
	tTextOption.fScale = 0.8
	tTextOption.fDuration = 2
	tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Vertical
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Back
	tTextOption.fOffset = 2.0
	tTextOption.fOffsetDirection = 90
	tTextOption.strFontFace = "CRB_FloaterSmall"
	tTextOption.arFrames =
	{
		[1] = {fTime = 0,		nColor = 0xFFFFFF,		fAlpha = 0,		fVelocityDirection = 90,	fVelocityMagnitude = 5,		fScale = 0.8},
		[2] = {fTime = 0.15,							fAlpha = 1.0,	fVelocityDirection = 90,	fVelocityMagnitude = .2,},
		[3] = {fTime = 0.5,		nColor = nBaseColor,},
		[4] = {fTime = 1.0,		nColor = nBaseColor,},
		[5] = {fTime = 1.1,		nColor = 0xFFFFFF,		fAlpha = 1.0,	fVelocityDirection 	= 90,	fVelocityMagnitude 	= 5,},
		[6] = {fTime = 1.3,		nColor 	= nBaseColor,	fAlpha 	= 0.0,},
	}

	local unitToAttachTo = GameLib.GetControlledUnit()
	local strMessage = String_GetWeaselString(Apollo.GetString(arMomentumStrings[eMomentumType]), nCount)
	if eMomentumType == CombatFloater.CodeEnumCombatMomentum.KillChain and nCount == 2 then
		strMessage = Apollo.GetString("FloatText_DoubleKill")
		tTextOption.strFontFace = "CRB_FloaterMedium"
	elseif eMomentumType == CombatFloater.CodeEnumCombatMomentum.KillChain and nCount == 3 then
		strMessage = Apollo.GetString("FloatText_TripleKill")
		tTextOption.strFontFace = "CRB_FloaterMedium"
	elseif eMomentumType == CombatFloater.CodeEnumCombatMomentum.KillChain and nCount == 5 then
		strMessage = Apollo.GetString("FloatText_PentaKill")
		tTextOption.strFontFace = "CRB_FloaterHuge"
	elseif eMomentumType == CombatFloater.CodeEnumCombatMomentum.KillChain and nCount > 5 then
		tTextOption.strFontFace = "CRB_FloaterHuge"
	end

	CombatFloater.ShowTextFloater(unitToAttachTo, strMessage, tTextOption)
end

function IronCombatText:OnExperienceGained(eReason, unitTarget, strText, fDelay, nAmount)
	if not Apollo.GetConsoleVariable("ui.showCombatFloater") or nAmount < 0 then
		return
	end

	local strFormatted = ""
	local eMessageType = LuaEnumMessageType.XPAwarded
	local unitToAttachTo = GameLib.GetControlledUnit() -- unitTarget potentially nil

	local tContent = {}
	tContent.eType = LuaEnumMessageType.XPAwarded
	tContent.nNormal = 0
	tContent.nRested = 0

	local tTextOption = self:GetDefaultTextOption()
	tTextOption.fScale = 0.8
	tTextOption.fDuration = 2
	tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Vertical
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Back
	tTextOption.fOffset = 4.0 -- GOTCHA: Different
	tTextOption.fOffsetDirection = 90
	tTextOption.strFontFace = "CRB_FloaterSmall"
	tTextOption.arFrames =
	{
		[1] = {fTime = 0,			fAlpha = 0,		fVelocityDirection = 90,	fVelocityMagnitude = 5,		fScale = 0.8},
		[2] = {fTime = 0.15,		fAlpha = 1.0,	fVelocityDirection = 90,	fVelocityMagnitude = .2,},
		[3] = {fTime = 0.5,	},
		[4] = {fTime = 1.0,	},
		[5] = {fTime = 1.1,			fAlpha = 1.0,	fVelocityDirection 	= 90,	fVelocityMagnitude 	= 5,},
		[6] = {fTime = 1.3,			fAlpha 	= 0.0,},
	}

	-- GOTCHA: UpdateOrAddXpFloater will stomp on these text formats anyways (TODO REFACTOR)
	if eReason == CombatFloater.CodeEnumExpReason.KillPerformance or eReason == CombatFloater.CodeEnumExpReason.MultiKill or eReason == CombatFloater.CodeEnumExpReason.KillingSpree then
		return -- should not be delivered via the XP event
	elseif eReason == CombatFloater.CodeEnumExpReason.Rested then
		tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Vertical
		strFormatted = String_GetWeaselString(Apollo.GetString("FloatText_RestXPGained"), nAmount)
		tContent.nRested = nAmount
	else
		tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Vertical
		strFormatted = String_GetWeaselString(Apollo.GetString("FloatText_XPGained"), nAmount)
		tContent.nNormal = nAmount
	end

	self:RequestShowTextFloater(eMessageType, unitToAttachTo, strFormatted, tTextOption, fDelay, tContent)
end

function IronCombatText:OnElderPointsGained(nAmount, nRested)
	if not Apollo.GetConsoleVariable("ui.showCombatFloater") or nAmount < 0 then
		return
	end

	local tContent = {}
	tContent.eType = LuaEnumMessageType.XPAwarded
	tContent.nNormal = nAmount
	tContent.nRested = 0

	local tTextOption = self:GetDefaultTextOption()
	tTextOption.fScale = 0.8
	tTextOption.fDuration = 2
	tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Vertical
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Back
	tTextOption.fOffset = 4.0 -- GOTCHA: Different
	tTextOption.fOffsetDirection = 90
	tTextOption.strFontFace = "CRB_FloaterSmall"
	tTextOption.arFrames =
	{
		[1] = {fTime = 0,			fAlpha = 0,		fVelocityDirection = 90,	fVelocityMagnitude = 5,		fScale = 0.8},
		[2] = {fTime = 0.15,		fAlpha = 1.0,	fVelocityDirection = 90,	fVelocityMagnitude = .2,},
		[3] = {fTime = 0.5,	},
		[4] = {fTime = 1.0,	},
		[5] = {fTime = 1.1,			fAlpha = 1.0,	fVelocityDirection 	= 90,	fVelocityMagnitude 	= 5,},
		[6] = {fTime = 1.3,			fAlpha 	= 0.0,},
	}

	local eMessageType = LuaEnumMessageType.XPAwarded
	local unitToAttachTo = GameLib.GetControlledUnit()
	-- Base EP Floater
	local strFormatted = String_GetWeaselString(Apollo.GetString("FloatText_EPGained"), nAmount)
	self:RequestShowTextFloater(eMessageType, unitToAttachTo, strFormatted, tTextOption, 0, tContent)
	-- Rested EP Floater
	strFormatted = String_GetWeaselString(Apollo.GetString("FloatText_RestEPGained"), nRested)
	self:RequestShowTextFloater(eMessageType, unitToAttachTo, strFormatted, tTextOption, 0, tContent)
end

function IronCombatText:OnPathExperienceGained( nAmount, strText )
	if not Apollo.GetConsoleVariable("ui.showCombatFloater") then
		return
	end

	local eMessageType = LuaEnumMessageType.PathXp
	local unitToAttachTo = GameLib.GetControlledUnit()
	local strFormatted = String_GetWeaselString(Apollo.GetString("FloatText_PathXP"), nAmount)

	local tContent =
	{
		eType = LuaEnumMessageType.PathXp,
		nAmount = nAmount,
	}

	local tTextOption = self:GetDefaultTextOption()
	tTextOption.fScale = 0.8
	tTextOption.fDuration = 2
	tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Vertical
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Back
	tTextOption.fOffset = 4.0 -- GOTCHA: Different
	tTextOption.fOffsetDirection = 90
	tTextOption.strFontFace = "CRB_FloaterSmall"
	tTextOption.arFrames =
	{
		[1] = {fTime = 0,			fAlpha = 0,		fVelocityDirection = 90,	fVelocityMagnitude = 5,		fScale = 0.8},
		[2] = {fTime = 0.15,		fAlpha = 1.0,	fVelocityDirection = 90,	fVelocityMagnitude = .2,},
		[3] = {fTime = 0.5,	},
		[4] = {fTime = 1.0,	},
		[5] = {fTime = 1.1,			fAlpha = 1.0,	fVelocityDirection 	= 90,	fVelocityMagnitude 	= 5,},
		[6] = {fTime = 1.3,			fAlpha 	= 0.0,},
	}

	local unitToAttachTo = GameLib.GetControlledUnit() -- make unitToAttachTo to controlled unit because with the message system,
	self:RequestShowTextFloater( eMessageType, unitToAttachTo, strFormatted, tTextOption, 0, tContent )
end

---------------------------------------------------------------------------------------------------
function IronCombatText:OnFactionFloater(unitTarget, strMessage, nAmount, strFactionName, idFaction) -- Reputation Floater
	if not Apollo.GetConsoleVariable("ui.showCombatFloater") or strFactionName == nil or nAmount < 1 then
		return
	end

	local eMessageType = LuaEnumMessageType.ReputationIncrease
	local unitToAttachTo = unitTarget or GameLib.GetControlledUnit()
	local strFormatted = String_GetWeaselString(Apollo.GetString("FloatText_Rep"), nAmount, strFactionName)

	local tContent = {}
	tContent.eType = LuaEnumMessageType.ReputationIncrease
	tContent.nAmount = nAmount
	tContent.idFaction = idFaction
	tContent.strName = strFactionName

	local tTextOption = self:GetDefaultTextOption()
	tTextOption.fScale = 0.8
	tTextOption.fDuration = 2
	tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Vertical
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Back
	tTextOption.fOffset = 5.0 -- GOTCHA: Extra Different
	tTextOption.fOffsetDirection = 90
	tTextOption.strFontFace = "CRB_FloaterSmall"
	tTextOption.arFrames =
	{
		[1] = {fTime = 0,			fAlpha = 0,		fVelocityDirection = 90,	fVelocityMagnitude = 5,		fScale = 0.8},
		[2] = {fTime = 0.15,		fAlpha = 1.0,	fVelocityDirection = 90,	fVelocityMagnitude = .2,},
		[3] = {fTime = 0.5,	},
		[4] = {fTime = 1.0,	},
		[5] = {fTime = 1.1,			fAlpha = 1.0,	fVelocityDirection 	= 90,	fVelocityMagnitude 	= 5,},
		[6] = {fTime = 1.3,			fAlpha 	= 0.0,},
	}

	self:RequestShowTextFloater(eMessageType, GameLib.GetControlledUnit(), strFormatted, tTextOption, 0, tContent)
end

---------------------------------------------------------------------------------------------------
function IronCombatText:OnChannelUpdate_Loot(eType, tEventArgs)

	if eType ~= GameLib.ChannelUpdateLootType.Currency or not tEventArgs.monNew then
		return
	end

	if tEventArgs.monNew:GetMoneyType() == Money.CodeEnumCurrencyType.Credits then
		return
	end

	local eMessageType = LuaEnumMessageType.AlternateCurrency
	local strFormatted = String_GetWeaselString(Apollo.GetString("FloatText_AlternateMoney"), tEventArgs.monNew:GetAmount(), tEventArgs.monNew:GetTypeString())

	local tTextOption = self:GetDefaultTextOption()
	tTextOption.fScale = 1.0
	tTextOption.fDuration = 2
	tTextOption.strFontFace = "CRB_FloaterSmall"
	tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Vertical
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Bottom
	tTextOption.fOffset = -1
	tTextOption.fOffsetDirection = 0
	tTextOption.arFrames =
	{
		[1] = {fScale = 0.8,	fTime = 0,		fAlpha = 0.0,	fVelocityDirection = 0,		fVelocityMagnitude = 0,	},
		[2] = {fScale = 0.8,	fTime = 0.1,	fAlpha = 1.0,	fVelocityDirection = 0,		fVelocityMagnitude = 0,	},
		[3] = {fScale = 0.8,	fTime = 0.5,	fAlpha = 1.0,														},
		[4] = {					fTime = 1,		fAlpha = 1.0,	fVelocityDirection = 180,	fVelocityMagnitude = 3,	},
		[5] = {					fTime = 1.5,	fAlpha = 0.0,	fVelocityDirection = 180,							},
	}

	local tContent =
	{
		eType = LuaEnumMessageType.AlternateCurrency,
		eCurrencyType = tEventArgs.monNew:GetMoneyType(),
		nAmount = tEventArgs.monNew:GetAmount(),
	}

	self:RequestShowTextFloater(eMessageType, GameLib.GetControlledUnit(), strFormatted, tTextOption, 0, tContent)
end

---------------------------------------------------------------------------------------------------
function IronCombatText:OnTradeSkillFloater(unitTarget, strMessage)
	if not Apollo.GetConsoleVariable("ui.showCombatFloater") then
		return
	end

	local eMessageType = LuaEnumMessageType.TradeskillXp
	local tTextOption = self:GetDefaultTextOption()
	local unitToAttachTo = GameLib.GetControlledUnit()

	-- XP Defaults
	tTextOption.fScale = 1.0
	tTextOption.fDuration = 2
	tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Horizontal
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Top
	tTextOption.fOffset = -0.3
	tTextOption.fOffsetDirection = 0

	tTextOption.nColor = 0xffff80
	tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Vertical --Horizontal  --IgnoreCollision
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Top
	tTextOption.fOffset = -0.3
	tTextOption.fOffsetDirection = 0

	-- scale and movement
	tTextOption.arFrames =
	{
		[1] = {fTime = 0,	fScale = 1.0,	fAlpha = 0.0,},
		[2] = {fTime = 0.1,	fScale = 0.7,	fAlpha = 0.8,},
		[3] = {fTime = 0.9,	fScale = 0.7,	fAlpha = 0.8,	fVelocityDirection = 0,},
		[4] = {fTime = 1.0,	fScale = 1.0,	fAlpha = 0.0,	fVelocityDirection = 0,},
	}


	local unitToAttachTo = GameLib.GetControlledUnit()
	self:RequestShowTextFloater( eMessageType, unitToAttachTo, strMessage, tTextOption, 0 )
end

---------------------------------------------------------------------------------------------------
function IronCombatText:OnMiss( unitCaster, unitTarget, eMissType )
	if unitTarget == nil or not Apollo.GetConsoleVariable("ui.showCombatFloater") then
		return
	end

	-- modify the text to be shown
	local tTextOption = self:GetDefaultTextOption()
	if GameLib.IsControlledUnit( unitTarget ) or unitTarget:GetType() == "Mount" then -- if the target unit is player's char
		tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Horizontal --Vertical--Horizontal  --IgnoreCollision
		tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Chest
		tTextOption.nColor = 0xbaeffb
		tTextOption.fOffset = -0.6
		tTextOption.fOffsetDirection = 0
		tTextOption.arFrames =
		{
			[1] = {fScale = 1.0,	fTime = 0,						fVelocityDirection = 0,		fVelocityMagnitude = 0,},
			[2] = {fScale = 0.6,	fTime = 0.05,	fAlpha = 1.0,},
			[3] = {fScale = 0.6,	fTime = .2,		fAlpha = 1.0,	fVelocityDirection = 180,	fVelocityMagnitude = 3,},
			[4] = {fScale = 0.6,	fTime = .45,	fAlpha = 0.2,	fVelocityDirection = 180,},
		}
	else

		tTextOption.fScale = 1.0
		tTextOption.fDuration = 2
		tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.IgnoreCollision --Horizontal
		tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Chest
		tTextOption.fOffset = -0.8
		tTextOption.fOffsetDirection = 0
		tTextOption.arFrames =
		{
			[1] = {fScale = 1.1,	fTime = 0,		fAlpha = 1.0,	nColor = 0xb0b0b0,},
			[2] = {fScale = 0.7,	fTime = 0.1,	fAlpha = 1.0,},
			[3] = {					fTime = 0.3,	},
			[4] = {fScale = 0.7,	fTime = 0.8,	fAlpha = 1.0,},
			[5] = {					fTime = 0.9,	fAlpha = 0.0,},
		}
	end

	-- display the text
	local strText = (eMissType == GameLib.CodeEnumMissType.Dodge) and Apollo.GetString("CRB_Dodged") or Apollo.GetString("CRB_Blocked")
	CombatFloater.ShowTextFloater( unitTarget, strText, tTextOption )
end

------------------------------------------------------------------------------------------------------------------------------
-- Helper function for displaying healing
------------------------------------------------------------------------------------------------------------------------------
function IronCombatText:OnOutgoingHealing( unitCaster, unitTarget, eDamageType, nDamage, nShieldDamage, nAbsorp, bCritical, bMultiHit)
-----------------------------------------------------------------------------------------------------------------------------
	local tTextOption = self:GetDefaultTextOption()
	
	local nBaseColor = self.tSettings.cHealDefault
	local fMaxSize = 0.8
	local fMaxDuration = 1.25
	local fCritScale = 1.0
	local nTotalDamage = nDamage + nShieldDamage
	
	if bCritical == true then -- Crit not vuln
		nBaseColor = self.tSettings.cHealCrit
		
		if nTotalDamage >= 10000 then
			fMaxSize = 1.25
			fCritScale = 1.25
		end
	end
	
	if eDamageType == GameLib.CodeEnumDamageType.HealShields then -- healing shields params
		nBaseColor = self.tSettings.cHealShield
	end

	-- set offset
	tTextOption.fOffsetDirection = 220
	tTextOption.fOffset = 3
	tTextOption.bShowOnTop = true
	
	if bMultiHit and bMultiHit == true and self.tSettings.bShowMultiHit == true then
	  nBaseColor = self.tSettings.cHealMultiHit
	  tTextOption.fOffset = 5
	  tTextOption.fOffsetDirection = 250
	end
	
	-- scale and movement
	-- Default movement:
	-- t5             123
	-- t4              123
	-- t3               123
	-- t2              123
	-- t1              123
	-- t0            123
	tTextOption.arFrames =
	{
		[1] = {fScale = fMaxSize * 0.8,	        	fTime = 0,			fVelocityDirection = -45, fVelocityMagnitude = 5,										},
		[2] = {fScale = fMaxSize,				fTime = .15,		fVelocityDirection = -30, fVelocityMagnitude = 5,	fAlpha = 1.0, 		nColor = nBaseColor,},
		[3] = {fScale = fMaxSize * fCritScale,	fTime = .30,		fVelocityDirection = -15, fVelocityMagnitude = 5,						nColor = nBaseColor,},
		[4] = {fScale = fMaxSize,				fTime = .45,		fVelocityDirection = 15,  fVelocityMagnitude = 5,	fAlpha = 0.85,							},
		[5] = {fScale = fMaxSize * fCritScale,	fTime = .75,		fVelocityDirection = 30,  fVelocityMagnitude = 5,	fAlpha = 0.65,							},
		[6] = {									fTime = fMaxDuration,													fAlpha = 0.0,							},
	}

	if type(nAbsorptionAmount) == "number" and nAbsorptionAmount > 0 then -- secondary "if" so we don't see absorption and "0"
		CombatFloater.ShowTextFloater( unitTarget, String_GetWeaselString(Apollo.GetString("FloatText_Absorbed"), nAbsorptionAmount), tTextOptionAbsorb )
	else
		CombatFloater.ShowTextFloater( unitTarget, String_GetWeaselString(Apollo.GetString("FloatText_PlusValue"), nDamage), tTextOption ) -- we show "0" when there's no absorption
	end
end

------------------------------------------------------------------------------------------------------------------------------
-- Helper function for displaying damage
------------------------------------------------------------------------------------------------------------------------------
function IronCombatText:OnOutgoingDamage( unitCaster, unitTarget, nDamage, nShieldDamage, nAbsorp, bCritical, bMultiHit)
-----------------------------------------------------------------------------------------------------------------------------
	local tTextOption = self:GetDefaultTextOption()
	
	local nBaseColor = self.tSettings.cDmgDefault
	local fMaxSize = 1.0
	local fMaxDuration = 1.25
	local fCritScale = 1.0
	local nTotalDamage = nDamage + nShieldDamage
	
	tTextOption.strFontFace = "CRB_FloaterLarge"
	tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.IgnoreCollision
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Chest
	tTextOption.fOffsetDirection = 220 -- 5 o'clock
	tTextOption.fOffset = 3
	tTextOption.bShowOnTop = true

	-- Change color and scale for crit
	if bCritical == true then 
		nBaseColor = self.tSettings.cDmgCrit
		
		if nTotalDamage >= self.tSettings.iBigCritValue then
			fMaxSize = 1.25
			fCritScale = self.tSettings.fCritScale
		end
	else
		fMaxSize = self.tSettings.fNormalScale
	end
	
	-- Change color for vuln
	if unitTarget:IsInCCState( Unit.CodeEnumCCState.Vulnerability ) then 
		nBaseColor = self.tSettings.cDmgVuln
	end 
	
	-- Change color and position for multi-hit
	if bMultiHit ~= nil and bMultiHit == true and self.tSettings.bShowMultiHit == true then
	  --nBaseColor = 0x0088ff
	  nBaseColor = self.tSettings.cDmgMultiHit
	  tTextOption.fOffset = 5
	  tTextOption.fOffsetDirection = 250
	end
	
	-- scale and movement
	-- Default movement:
	-- t5             123
	-- t4              123
	-- t3               123
	-- t2              123
	-- t1              123
	-- t0            123
	tTextOption.arFrames =
	{
		[1] = {fScale = fMaxSize * 0.8,	        fTime = 0,			fVelocityDirection = -45, fVelocityMagnitude = 5,						},
		[2] = {fScale = fMaxSize,				fTime = .15,		fVelocityDirection = -30, fVelocityMagnitude = 5,	fAlpha = 1.0,},
		[3] = {fScale = fMaxSize * fCritScale,	fTime = .30,		fVelocityDirection = -15, fVelocityMagnitude = 5,						nColor = nBaseColor,},
		[4] = {fScale = fMaxSize,				fTime = .45,		fVelocityDirection = 15,  fVelocityMagnitude = 5,	fAlpha = 0.85,},
		[5] = {fScale = fMaxSize * fCritScale,	fTime = .75,		fVelocityDirection = 30,  fVelocityMagnitude = 5,	fAlpha = 0.65,},
		[6] = {									fTime = fMaxDuration,													fAlpha = 0.0,},
	}

	if type(nAbsorp) == "number" and nAbsorp > 0 then
		CombatFloater.ShowTextFloater( unitTarget, String_GetWeaselString(Apollo.GetString("FloatText_Absorbed"), nAbsorp), tTextOption )
	else
		CombatFloater.ShowTextFloater( unitTarget, nTotalDamage, 0, tTextOption )
	end
end

------------------------------------------------------------------------------------------------------------------------------
function IronCombatText:OnDamageOrHealing( unitCaster, unitTarget, eDamageType, nDamage, nShieldDamaged, nAbsorptionAmount, bCritical, bMultiHit)
------------------------------------------------------------------------------------------------------------------------------
	if unitTarget == nil or not Apollo.GetConsoleVariable("ui.showCombatFloater") or nDamage == nil then
		return
	end

	if GameLib.IsControlledUnit(unitTarget) or unitTarget == GameLib.GetPlayerMountUnit() or GameLib.IsControlledUnit(unitTarget:GetUnitOwner()) then
		self:OnPlayerDamageOrHealing( unitTarget, eDamageType, nDamage, nShieldDamaged, nAbsorptionAmount, bCritical )
		return
	end
	
	if eDamageType == GameLib.CodeEnumDamageType.Heal or eDamageType == GameLib.CodeEnumDamageType.HealShields then
		self:OnOutgoingHealing(unitCaster, unitTarget, eDamageType, nDamage, nShieldDamaged, nAbsorptionAmount, bCritical, bMultiHit)
		return
	else
		self:OnOutgoingDamage(unitCaster, unitTarget, nDamage, nShieldDamaged, nAbsorptionAmount, bCritical, bMultiHit)
		return
	end
	
end

------------------------------------------------------------------
function IronCombatText:OnIncomingDamage( unitPlayer, eDamageType, nDamage, nShieldDamage, nAbsorb, bCritical )
	local tTextOption = self:GetDefaultTextOption()
	
	local nBaseColor = self.tSettings.cDmgInDefault
	local fMaxSize = self.tSettings.fNormalInScale
	local fCritScale = self.tSettings.fCritInScale
	local fMaxDuration = 1.25
	local nTotalDamage = nDamage + nShieldDamage
	
	
	tTextOption.strFontFace = "CRB_FloaterLarge"
	tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.IgnoreCollision
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Chest
	tTextOption.fOffsetDirection = 60 -- 11 o'clock
	tTextOption.fOffset = 2

	-- Change color and scale for crit
	if bCritical == true then 
		nBaseColor = self.tSettings.cDmgInCrit
		
		if nTotalDamage >= self.tSettings.iBigCritInValue then
			fMaxSize = 1.25
			fCritScale = 1.25
		end
	end
	
	if type(nAbsorb) == "number" and nAbsorb > 0 then
		nBaseColor = 0xffffff
	end

	-- scale and movement
	-- Default movement:
	-- t5             123
	-- t4              123
	-- t3               123
	-- t2              123
	-- t1              123
	-- t0            123
	tTextOption.arFrames =
	{
		[1] = {fScale = fMaxSize * 0.8,	        fTime = 0,			fVelocityDirection = 125, fVelocityMagnitude = 5,	fAlpha = 1.0, nColor = nBaseColor,},
		[2] = {fScale = fMaxSize,				fTime = .15,		fVelocityDirection = 135, fVelocityMagnitude = 5,	fAlpha = 1.0,},
		[3] = {fScale = fMaxSize * fCritScale,	fTime = .30,		fVelocityDirection = 145, fVelocityMagnitude = 5,	nColor = nBaseColor,},
		[4] = {fScale = fMaxSize,				fTime = .45,		fVelocityDirection = -145,  fVelocityMagnitude = 5,	fAlpha = 0.85,},
		[5] = {fScale = fMaxSize * fCritScale,	fTime = .75,		fVelocityDirection = -135,  fVelocityMagnitude = 5,	fAlpha = 0.65,},
		[6] = {									fTime = fMaxDuration,													fAlpha = 0.0,},
	}

	if type(nAbsorb) == "number" and nAbsorb > 0 then
		CombatFloater.ShowTextFloater( unitPlayer, String_GetWeaselString(Apollo.GetString("FloatText_Absorbed"), nAbsorb), tTextOption )
	else
		CombatFloater.ShowTextFloater( unitPlayer, nDamage, nShieldDamage, tTextOption )
	end

end


------------------------------------------------------------------
function IronCombatText:OnIncomingHealing( unitPlayer, eDamageType, nDamage, nShieldDamage, nAbsorb, bCritical )


end

------------------------------------------------------------------
function IronCombatText:OnPlayerDamageOrHealing(unitPlayer, eDamageType, nDamage, nShieldDamaged, nAbsorptionAmount, bCritical)
	if unitPlayer == nil or not Apollo.GetConsoleVariable("ui.showCombatFloater") then
		return
	end

	-- If there is no damage, don't show a floater
	if nDamage == nil then
		return
	end
	
	if eDamageType == GameLib.CodeEnumDamageType.Heal or eDamageType == GameLib.CodeEnumDamageType.HealShields then
		self:OnIncomingHealing(unitPlayer, eDamageType, nDamage, nShieldDamaged, nAbsorptionAmount, bCritical)
		return
	else
		self:OnIncomingDamage(unitPlayer, eDamageType, nDamage, nShieldDamaged, nAbsorptionAmount, bCritical)
		return
	end

	local bShowFloater = true
	local tTextOption = self:GetDefaultTextOption()
	local tTextOptionAbsorb = self:GetDefaultTextOption()

	tTextOption.arFrames = {}
	tTextOptionAbsorb.arFrames = {}

	local nStallTime = .3

	if type(nAbsorptionAmount) == "number" and nAbsorptionAmount > 0 then --absorption is its own separate type
		tTextOptionAbsorb.nColor = 0xf8f3d7
		tTextOptionAbsorb.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Horizontal --Vertical--Horizontal  --IgnoreCollision
		tTextOptionAbsorb.eLocation = CombatFloater.CodeEnumFloaterLocation.Chest
		tTextOptionAbsorb.fOffset = -0.4
		tTextOptionAbsorb.fOffsetDirection = 0--125

		-- scale and movement
		tTextOptionAbsorb.arFrames =
		{
			[1] = {fScale = 1.1,	fTime = 0,									fVelocityDirection = 0,		fVelocityMagnitude = 0,},
			[2] = {fScale = 0.7,	fTime = 0.05,				fAlpha = 1.0,},
			[3] = {fScale = 0.7,	fTime = .2 + nStallTime,	fAlpha = 1.0,	fVelocityDirection = 180,	fVelocityMagnitude = 3,},
			[4] = {fScale = 0.7,	fTime = .45 + nStallTime,	fAlpha = 0.2,	fVelocityDirection = 180,},
		}
	end

	local bHeal = eDamageType == GameLib.CodeEnumDamageType.Heal or eDamageType == GameLib.CodeEnumDamageType.HealShields
	local nBaseColor = 0xff6d6d
	local nHighlightColor = 0xff6d6d
	local fMaxSize = 0.8
	local nOffsetDirection = 0
	local fOffsetAmount = -0.6
	local fMaxDuration = .55
	local eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Horizontal

	if eDamageType == GameLib.CodeEnumDamageType.Heal then -- healing params
		nBaseColor = 0xb0ff6a
		nHighlightColor = 0xb0ff6a
		fOffsetAmount = -0.5

		if bCritical then
			fMaxSize = 1.2
			nBaseColor = 0xc6ff94
			nHighlightColor = 0xc6ff94
			fMaxDuration = .75
		end

	elseif eDamageType == GameLib.CodeEnumDamageType.HealShields then -- healing shields params
		nBaseColor = 0x6afff3
		fOffsetAmount = -0.5
		nHighlightColor = 0x6afff3

		if bCritical then
			fMaxSize = 1.2
			nBaseColor = 0xa6fff8
			nHighlightColor = 0xFFFFFF
			fMaxDuration = .75
		end

	else -- regular old damage (player)
		fOffsetAmount = -0.5

		if bCritical then
			fMaxSize = 1.2
			nBaseColor = 0xffab3d
			nHighlightColor = 0xFFFFFF
			fMaxDuration = .75
		end
	end

	tTextOptionAbsorb.fOffset = fOffsetAmount
	tTextOption.eCollisionMode = eCollisionMode
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Chest

	-- scale and movement
	tTextOption.arFrames =
	{
		[1] = {fScale = fMaxSize * .75,	fTime = 0,									nColor = nHighlightColor,	fVelocityDirection = 0,		fVelocityMagnitude = 0,},
		[2] = {fScale = fMaxSize * 1.5,	fTime = 0.05,								nColor = nHighlightColor,	fVelocityDirection = 0,		fVelocityMagnitude = 0,},
		[3] = {fScale = fMaxSize,		fTime = 0.1,				fAlpha = 1.0,	nColor = nBaseColor,},
		[4] = {							fTime = 0.3 + nStallTime,	fAlpha = 1.0,								fVelocityDirection = 180,	fVelocityMagnitude = 3,},
		[5] = {							fTime = 0.65 + nStallTime,	fAlpha = 0.2,								fVelocityDirection = 180,},
	}

	if type(nAbsorptionAmount) == "number" and nAbsorptionAmount > 0 then -- secondary "if" so we don't see absorption and "0"
		CombatFloater.ShowTextFloater( unitPlayer, String_GetWeaselString(Apollo.GetString("FloatText_Absorbed"), nAbsorptionAmount), tTextOptionAbsorb )
	end

	if nDamage > 0 and bHeal then
		CombatFloater.ShowTextFloater( unitPlayer, String_GetWeaselString(Apollo.GetString("FloatText_PlusValue"), nDamage), tTextOption )
	elseif not bHeal then
		CombatFloater.ShowTextFloater( unitPlayer, nDamage, nShieldDamaged, tTextOption )
	end
end

------------------------------------------------------------------
function IronCombatText:GetDefaultCCStateTextOption()
	local tTextOption = self:GetDefaultTextOption()
	tTextOption.fScale = 1.0
	tTextOption.fDuration = 2
	tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Vertical --IgnoreCollision --Horizontal
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Chest
	tTextOption.fOffset = -0.8
	tTextOption.fOffsetDirection = 0
	tTextOption.arFrames={}
	tTextOption.nColor = 0xb0b0b0

	tTextOption.arFrames =
	{
		[1] = {fScale = 1.0,	fTime = 0,		fAlpha = 0.0},
		[2] = {fScale = 0.7,	fTime = 0.1,	fAlpha = 0.8},
		[3] = {fScale = 0.7,	fTime = 0.9,	fAlpha = 0.8,	fVelocityDirection = 0},
		[4] = {fScale = 1.0,	fTime = 1.0,	fAlpha = 0.0,	fVelocityDirection = 0},
	}
	return tTextOption
end

------------------------------------------------------------------
function IronCombatText:ShouldDisplayCCStateFloater( tEventArgs )
	if not Apollo.GetConsoleVariable("ui.showCombatFloater") then
		return false
	end

	-- removal of a CC state does not display floater text
	if tEventArgs.bRemoved or tEventArgs.bHideFloater then
		return false
	end

	return true

end
------------------------------------------------------------------
function IronCombatText:OnCombatLogCCState(tEventArgs)

	if not self:ShouldDisplayCCStateFloater( tEventArgs ) then
		return
	end
	
	if tEventArgs.eResult == nil then
		return false
	end -- totally invalid

	if GameLib.IsControlledUnit( tEventArgs.unitTarget ) then
		-- Route to the player function
		self:OnCombatLogCCStatePlayer(tEventArgs)
		return
	end
	
	local nOffsetState = tEventArgs.eState

	local arCCFormat =  --Removing an entry from this table means no floater is shown for that state.
	{
		[Unit.CodeEnumCCState.Stun] 			= 0xffe691, -- stun
		[Unit.CodeEnumCCState.Sleep] 			= 0xffe691, -- sleep
		[Unit.CodeEnumCCState.Root] 			= 0xffe691, -- root
		[Unit.CodeEnumCCState.Disarm] 			= 0xffe691, -- disarm
		[Unit.CodeEnumCCState.Silence] 			= 0xffe691, -- silence
		[Unit.CodeEnumCCState.Polymorph] 		= 0xffe691, -- polymorph
		[Unit.CodeEnumCCState.Fear] 			= 0xffe691, -- fear
		[Unit.CodeEnumCCState.Hold] 			= 0xffe691, -- hold
		[Unit.CodeEnumCCState.Knockdown] 		= 0xffe691, -- knockdown
		[Unit.CodeEnumCCState.Disorient] 		= 0xffe691,
		[Unit.CodeEnumCCState.Disable] 			= 0xffe691,
		[Unit.CodeEnumCCState.Taunt] 			= 0xffe691,
		[Unit.CodeEnumCCState.DeTaunt] 			= 0xffe691,
		[Unit.CodeEnumCCState.Blind] 			= 0xffe691,
		[Unit.CodeEnumCCState.Knockback] 		= 0xffe691,
		[Unit.CodeEnumCCState.Pushback ] 		= 0xffe691,
		[Unit.CodeEnumCCState.Pull] 			= 0xffe691,
		[Unit.CodeEnumCCState.PositionSwitch] 	= 0xffe691,
		[Unit.CodeEnumCCState.Tether] 			= 0xffe691,
		[Unit.CodeEnumCCState.Snare] 			= 0xffe691,
		[Unit.CodeEnumCCState.Interrupt] 		= 0xffe691,
		[Unit.CodeEnumCCState.Daze] 			= 0xffe691,
		[Unit.CodeEnumCCState.Subdue] 			= 0xffe691,
	}

	local tTextOption = self:GetDefaultCCStateTextOption()
	local strMessage = ""

	local bUseCCFormat = false -- use CC formatting vs. message formatting

	if tEventArgs.eResult == CombatFloater.CodeEnumCCStateApplyRulesResult.Ok then -- CC applied
		strMessage = tEventArgs.strState
		if arCCFormat[nOffsetState] ~= nil then -- make sure it's one we want to show
			bUseCCFormat = true
		else
			return
		end
	elseif tEventArgs.eResult == CombatFloater.CodeEnumCCStateApplyRulesResult.Target_Immune then
		strMessage = Apollo.GetString("FloatText_Immune")
	elseif tEventArgs.eResult == CombatFloater.CodeEnumCCStateApplyRulesResult.Target_InfiniteInterruptArmor then
		strMessage = Apollo.GetString("FloatText_InfInterruptArmor")
	elseif tEventArgs.eResult == CombatFloater.CodeEnumCCStateApplyRulesResult.Target_InterruptArmorReduced then -- use with interruptArmorHit
		strMessage = String_GetWeaselString(Apollo.GetString("FloatText_InterruptArmor"), tEventArgs.nInterruptArmorHit)
	elseif tEventArgs.eResult == CombatFloater.CodeEnumCCStateApplyRulesResult.DiminishingReturns_TriggerCap and tEventArgs.strTriggerCapCategory ~= nil then
		strMessage = Apollo.GetString("FloatText_CC_DiminishingReturns_TriggerCap").." "..tEventArgs.strTriggerCapCategory
	else -- all invalid messages
		return
	end

	if bUseCCFormat then -- CC applied
		tTextOption.arFrames =
		{
			[1] = {fScale = 2.0,	fTime = 0,		fAlpha = 1.0,	nColor = 0xFFFFFF,},
			[2] = {fScale = 0.7,	fTime = 0.15,	fAlpha = 1.0,},
			[3] = {					fTime = 0.5,					nColor = arCCFormat[nOffsetState],},
			[4] = {fScale = 0.7,	fTime = 1.1,	fAlpha = 1.0,										fVelocityDirection = 0,	fVelocityMagnitude = 5,},
			[5] = {					fTime = 1.3,	fAlpha = 0.0,										fVelocityDirection = 0,},
		}
	end

	CombatFloater.ShowTextFloater( tEventArgs.unitTarget, strMessage, tTextOption )
end
------------------------------------------------------------------
function IronCombatText:OnCombatLogImmunity(tEventArgs)

	if not self:ShouldDisplayCCStateFloater( tEventArgs ) then
		return
	end
	
	local tTextOption = self:GetDefaultCCStateTextOption()
	local strMessage = Apollo.GetString("FloatText_Immune")
	CombatFloater.ShowTextFloater( tEventArgs.unitTarget, strMessage, tTextOption )
	
end
------------------------------------------------------------------
function IronCombatText:OnCombatLogCCStatePlayer(tEventArgs)
	if not Apollo.GetConsoleVariable("ui.showCombatFloater") then
		return
	end

	-- removal of a CC state does not display floater text
	if tEventArgs.bRemoved or tEventArgs.bHideFloater then
		return
	end

	local arCCFormatPlayer =
    --Removing an entry from this table means no floater is shown for that state.
	{
		[Unit.CodeEnumCCState.Stun] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.Sleep] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.Root] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.Disarm] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.Silence] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.Polymorph] 		= 0xff2b2b,
		[Unit.CodeEnumCCState.Fear] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.Hold] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.Knockdown] 		= 0xff2b2b,
		[Unit.CodeEnumCCState.Disorient] 		= 0xff2b2b,
		[Unit.CodeEnumCCState.Disable] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.Taunt] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.DeTaunt] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.Blind] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.Knockback] 		= 0xff2b2b,
		[Unit.CodeEnumCCState.Pushback] 		= 0xff2b2b,
		[Unit.CodeEnumCCState.Pull] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.PositionSwitch] 	= 0xff2b2b,
		[Unit.CodeEnumCCState.Tether] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.Snare] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.Interrupt] 		= 0xff2b2b,
		[Unit.CodeEnumCCState.Daze] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.Subdue] 			= 0xff2b2b,
	}

	local nOffsetState = tEventArgs.eState

	local tTextOption = self:GetDefaultTextOption()
	local strMessage = ""

	tTextOption.fScale = 1.0
	tTextOption.fDuration = 2
	tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Horizontal
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Chest
	tTextOption.fOffset = -0.2
	tTextOption.fOffsetDirection = 0
	tTextOption.arFrames={}

	local bUseCCFormat = false -- use CC formatting vs. message formatting

	if tEventArgs.eResult == CombatFloater.CodeEnumCCStateApplyRulesResult.Ok then -- CC applied
		strMessage = tEventArgs.strState
		if arCCFormatPlayer[nOffsetState] ~= nil then -- make sure it's one we want to show
			bUseCCFormat = true
		else
			return
		end
	elseif tEventArgs.eResult == CombatFloater.CodeEnumCCStateApplyRulesResult.Target_Immune then
		strMessage = Apollo.GetString("FloatText_Immune")
	elseif tEventArgs.eResult == CombatFloater.CodeEnumCCStateApplyRulesResult.Target_InfiniteInterruptArmor then
		strMessage = Apollo.GetString("FloatText_InfInterruptArmor")
	elseif tEventArgs.eResult == CombatFloater.CodeEnumCCStateApplyRulesResult.Target_InterruptArmorReduced then -- use with interruptArmorHit
		strMessage = String_GetWeaselString(Apollo.GetString("FloatText_InterruptArmor"), tEventArgs.nInterruptArmorHit)
	else -- all invalid messages
		return
	end

	if not bUseCCFormat then -- CC didn't take
		tTextOption.nColor = 0xd8f8f8
		tTextOption.arFrames =
		{
			[1] = {fScale = 1.0,	fTime = 0,		fAlpha = 0.0,},
			[2] = {fScale = 0.7,	fTime = 0.1,	fAlpha = 0.8,},
			[3] = {fScale = 0.7,	fTime = 0.9,	fAlpha = 0.8,	fVelocityDirection = 180,	fVelocityMagnitude = 3,},
			[4] = {fScale = 0.7,	fTime = 1.0,	fAlpha = 0.0,	fVelocityDirection = 180,},
		}
	else -- CC applied
		tTextOption.nColor = arCCFormatPlayer[nOffsetState]
		tTextOption.arFrames =
		{
			[1] = {fScale = 1.1,	fTime = 0,		nColor = 0xFFFFFF,},
			[2] = {fScale = 0.7,	fTime = 0.05,	nColor = arCCFormatPlayer[nOffsetState],	fAlpha = 1.0,},
			[3]	= {					fTime = 0.35,	nColor = 0xFFFFFF,},
			[4] = {					fTime = 0.7,	nColor = arCCFormatPlayer[nOffsetState],},
			[5] = {					fTime = 1.05,	nColor = 0xFFFFFF,},
			[6] = {fScale = 0.7,	fTime = 1.4,	nColor = arCCFormatPlayer[nOffsetState],	fAlpha = 1.0,	fVelocityDirection = 180,	fVelocityMagnitude = 3,},
			[7] = {fScale = 0.7,	fTime = 1.55,												fAlpha = 0.2,	fVelocityDirection = 180,},
		}
	end

	CombatFloater.ShowTextFloater( tEventArgs.unitTarget, strMessage, tTextOption )
end

------------------------------------------------------------------
-- send show text request to message manager with a delay in milliseconds
function IronCombatText:RequestShowTextFloater( eMessageType, unitTarget, strText, tTextOption, fDelay, tContent ) -- addtn'l parameters for XP/rep
	local tParams =
	{
		unitTarget 	= unitTarget,
		strText 	= strText,
		tTextOption = TableUtil:Copy( tTextOption ),
		tContent 	= tContent,
	}

	if not fDelay or fDelay == 0 then -- just display if no delay
		Event_FireGenericEvent("Float_RequestShowTextFloater", eMessageType, tParams, tContent )
	else
		tParams.nTime = os.time() + fDelay
		tParams.eMessageType = eMessageType

		-- insert the text in the delayed queue in order of how fast they'll need to be shown
		local nInsert = 0
		for key, value in pairs(self.tDelayedFloatTextQueue:GetItems()) do
			if value.nTime > tParams.nTime then
				nInsert = key
				break
			end
		end
		if nInsert > 0 then
			self.tDelayedFloatTextQueue:InsertAbsolute( nInsert, tParams )
		else
			self.tDelayedFloatTextQueue:Push( tParams )
		end
		self.iTimerIndex = self.iTimerIndex + 1
		if self.iTimerIndex > 9999999 then
			self.iTimerIndex = 1
		end
		self.tTimerFloatText[self.iTimerIndex] = ApolloTimer.Create(fDelay, false, "OnDelayedFloatTextTimer", self)-- create the timer to show the text
	end
end

------------------------------------------------------------------
function IronCombatText:OnDelayedFloatTextTimer()
	local tParams = self.tDelayedFloatTextQueue:Pop()
	Event_FireGenericEvent("Float_RequestShowTextFloater", tParams.eMessageType, tParams, tParams.tContent) -- TODO: Event!!!!
end

function IronCombatText:InitOutDmg()
	self.normalPreview	 = self.options:FindChild("NormPrev")
	self.normalColor 	 = self.options:FindChild("NormColor")
	self.critPreview 	 = self.options:FindChild("CritPrev")
	self.critColor 		 = self.options:FindChild("CritColor")
	self.normalScale 	 = self.options:FindChild("NormScale")
	self.critScale 		 = self.options:FindChild("CritScale")
	self.multiHitPreview = self.options:FindChild("MultiHitPrev")
	self.multiHitColor   = self.options:FindChild("MultiHitColor")
	self.bigCritValue    = self.options:FindChild("BigCrit")

	self:InitColorWidget{
		editBox = self.multiHitColor,
		preview = self.multiHitPreview,
		value = ("%06x"):format(self.tSettings.cDmgMultiHit),
		callback = function (value)
			self.multiHitPreview:SetTextColor("ff"..value)
			self.tSettings.cDmgMultiHit = tonumber(value, 16)
		end
	}
	
	self:InitColorWidget{
		editBox = self.critColor,
		preview = self.critPreview,
		value = ("%06x"):format(self.tSettings.cDmgCrit),
		callback = function (value)
			self.critPreview:SetTextColor("ff"..value)
			self.tSettings.cDmgCrit = tonumber(value, 16)
		end
	}
	
	self:InitColorWidget{
		editBox = self.normalColor,
		preview = self.normalPreview,
		value = ("%06x"):format(self.tSettings.cDmgDefault),
		callback = function (value)
			self.normalPreview:SetTextColor("ff"..value)
			self.tSettings.cDmgDefault = tonumber(value, 16)
		end
	}
	
	self:InitValueWidget{
		editBox = self.bigCritValue,
		value = ("%05d"):format(self.tSettings.iBigCritValue),
		callback = function(value)
			self.tSettings.iBigCritValue = tonumber(value)
		end
	}
	
	-- Crit Scale
	self:InitFloatValueWidget{
		editBox = self.critScale,
		value = ("%1.2f"):format(self.tSettings.fCritScale),
		callback = function(value)
			self.tSettings.fCritScale = tonumber(value)
		end
	}
	
	-- Normal Scale
	self:InitFloatValueWidget{
		editBox = self.normalScale,
		value = ("%1.2f"):format(self.tSettings.fNormalScale),
		callback = function(value)
			self.tSettings.fNormalScale = tonumber(value)
		end
	}

end

function IronCombatText:InitInDmg()
	self.normalPreview	 = self.options:FindChild("NormPrev")
	self.normalColor 	 = self.options:FindChild("NormColor")
	self.critPreview 	 = self.options:FindChild("CritPrev")
	self.critColor 		 = self.options:FindChild("CritColor")
	self.normalScale 	 = self.options:FindChild("NormScale")
	self.critScale 		 = self.options:FindChild("CritScale")
	self.bigCritValue    = self.options:FindChild("BigCrit")
	
	self:InitColorWidget{
		editBox = self.critColor,
		preview = self.critPreview,
		value = ("%06x"):format(self.tSettings.cDmgInCrit),
		callback = function (value)
			self.critPreview:SetTextColor("ff"..value)
			self.tSettings.cDmgInCrit= tonumber(value, 16)
		end
	}
	
	self:InitColorWidget{
		editBox = self.normalColor,
		preview = self.normalPreview,
		value = ("%06x"):format(self.tSettings.cDmgInDefault),
		callback = function (value)
			self.normalPreview:SetTextColor("ff"..value)
			self.tSettings.cDmgInDefault = tonumber(value, 16)
		end
	}
	
	self:InitValueWidget{
		editBox = self.bigCritValue,
		value = ("%05d"):format(self.tSettings.iBigCritInValue),
		callback = function(value)
			self.tSettings.iBigCritValue = tonumber(value)
		end
	}
	
	-- Crit Scale
	self:InitFloatValueWidget{
		editBox = self.critScale,
		value = ("%1.2f"):format(self.tSettings.fCritInScale),
		callback = function(value)
			self.tSettings.fCritInScale = tonumber(value)
		end
	}
	
	-- Normal Scale
	self:InitFloatValueWidget{
		editBox = self.normalScale,
		value = ("%1.2f"):format(self.tSettings.fNormalInScale),
		callback = function(value)
			self.tSettings.fNormalInScale = tonumber(value)
		end
	}

end


---------------------------------------------------------------------------------------------------
-- Main Functions
---------------------------------------------------------------------------------------------------
function IronCombatText:LoadCategory(categoryName)
	self.currentCategory = categoryName
	self.currentButton = self.wndMain:FindChild(self.currentCategory)
	self.currentButton:SetCheck(true)
	self.content:DestroyChildren()
	self.options = Apollo.LoadForm(self.xmlDoc, "Options" .. categoryName, self.content, self)
	
	if self.options then
				
		Print(categoryName)
		if categoryName == "OutDmg" then
			self:InitOutDmg()
		elseif categoryName == "InDmg" then
			self:InitInDmg()
		end				
		
		return true
	else
		return false
	end

end

-- Color selection with preview
function IronCombatText:InitColorWidget(data)
	data.editBox:SetData{
		callback = data.callback
	}
	data.editBox:SetText(data.value)
	data.editBox:SetMaxTextLength(6)
	data.editBox:SetTextColor("FFFFFFFF")
	data.preview:SetTextColor("ff"..data.value)
	data.editBox:AddEventHandler("EditBoxChanged", "OnColorWidgetEditBoxChanged")
end

function IronCombatText:OnColorWidgetEditBoxChanged(wndHandler, wndControl)
	local text = wndHandler:GetText()
	local value = tonumber(text, 16) and text:len() == 6 and text or "ffffff"
	wndHandler:GetData().callback(value)
end

-- Regular value selection without preview
function IronCombatText:InitValueWidget(data)
	data.editBox:SetData{
		callback = data.callback
	}
	data.editBox:SetText(data.value)
	data.editBox:SetMaxTextLength(5)
end

-- Regular value selection without preview
function IronCombatText:InitFloatValueWidget(data)
	data.editBox:SetData{
		callback = data.callback
	}
	data.editBox:SetText(data.value)
	data.editBox:SetMaxTextLength(4)
	data.editBox:AddEventHandler("EditBoxChanged", "OnFloatWidgetEditBoxChanged")
end


function IronCombatText:OnFloatWidgetEditBoxChanged(wndHandler, wndControl)
	local text = wndHandler:GetText()
	local value = tonumber(text) and text:len() <= 5 and text or 10000
	wndHandler:GetData().callback(value)
end

function IronCombatText:OnOptionSelected( wndHandler, wndControl, eMouseButton )
	if self:LoadCategory(wndHandler:GetName():gsub("%s", "")) then
		Print("Loaded successfully")
	end	
	
end

function IronCombatText:OnClose( wndHandler, wndControl, eMouseButton )
	self.wndMain:Close()
end

function IronCombatText:OnApply( wndHandler, wndControl, eMouseButton )
	self.wndMain:Close()
	self.tSettings.bShowMultiHit = self.showMultiHit:IsChecked()
end


---------------------------------------------------------------------------------------------------
-- OptionsOutDmg Functions
---------------------------------------------------------------------------------------------------

function IronCombatText:OnFontSelect( wndHandler, wndControl, eMouseButton )
	local check = wndHandler:IsChecked()
	self.fontList = self.wndMain:FindChild("FontList")
	self.fontButton = self.wndMain:FindChild("FontSelect")
	
	if check == true then
		self.fontList:Show(true, true)
	else
		self.fontList:Close()
	end
	
end

local IronCombatTextInst = IronCombatText:new()
IronCombatTextInst:Init()