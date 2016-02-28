-----------------------------------------------------------------------------------------------
-- Client Lua Script for IronCombatText
-- Based heavily on Carbine's FloatText addon.

-- Made by Iron Oxide, 2015
-----------------------------------------------------------------------------------------------

require "Window"
require "Spell"
require "CombatFloater"
require "GameLib"
require "Unit"

local IronCombatText = {}
local knTestingVulnerable = -1

---------------------------------------------------------------------------------------------------
function IronCombatText:new(o)
---------------------------------------------------------------------------------------------------
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	
	self.Utils = nil
	self.Options = nil
	self.Patterns = nil
	
	return o
end

---------------------------------------------------------------------------------------------------
function IronCombatText:Init()
---------------------------------------------------------------------------------------------------
	local bHasConfigureFunction = true
	local strConfigureButtonText = "Iron Combat Text"
	local tDependencies = {
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

-- Save settings, character level
---------------------------------------------------------------------------------------------------
function IronCombatText:OnSave(eType)
---------------------------------------------------------------------------------------------------
	if eType == GameLib.CodeEnumAddonSaveLevel.Character then
		return self.tSettings
	end

	return nil
end

---------------------------------------------------------------------------------------------------
function IronCombatText:OnConfigure()
---------------------------------------------------------------------------------------------------
	self.Options:OnInvokeOptions()
end


-- Setup the settings, character level
---------------------------------------------------------------------------------------------------
function IronCombatText:OnRestore(eType, tSaveData)
---------------------------------------------------------------------------------------------------
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then return end

	if tSaveData == nil then
		self.tSettings = self:GetDefaultSettings()
	else
		self.tSettings = self:CompareSettings(tSaveData)
	end
end

---------------------------------------------------------------------------------------------------
function IronCombatText:CompareSettings(tOther)
---------------------------------------------------------------------------------------------------
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
---------------------------------------------------------------------------------------------------
function IronCombatText:GetDefaultSettings()
---------------------------------------------------------------------------------------------------
	local tSettings = {}

	-- tSettings["DamageOut"] = 
	-- {
	-- 	cNormal 	 = 0xf4e443,
	-- 	cMulti  	 = 0x0088ff,
	-- 	cCrit   	 = 0xfffb93,
	-- 	cVuln   	 = 0xf5a2ff,
	-- 	cAbsorb      = 0xffffff,
	-- 	iBigCrit     = 10000,
	-- 	iThreshold   = 0,
	-- 	fNormalScale = 1.0,
	-- 	fCritScale   = 1.25,
	-- 	fDuration    = 1.25,
	-- 	strPattern   = "PatternPopup",
	-- 	strFont      = "CRB_FloaterMedium",
	-- 	bMergeShield = true,
	-- 	bShowAbsorb  = true,
	-- 	ePos         = CombatFloater.CodeEnumFloaterLocation.Chest,
	-- 	eCollision   = CombatFloater.CodeEnumFloaterCollisionMode.IgnoreCollision,		
	-- }

	-- tSettings["DamageIn"] = 
	-- {
	-- 	cNormal 	 = 0xff3333,
	-- 	cCrit 		 = 0xff0000,
	-- 	cAbsorb	     = 0xffffff,
	-- 	fCritScale 	 = 1.1,
	-- 	fNormalScale = 1.0,
	-- 	fDuration    = 1.0,
	-- 	nPattern     = "StreamDownLeft",
	-- 	nFont        = "CRB_HeaderLarge",
	-- 	eCollision   = CombatFloater.CodeEnumFloaterCollisionMode.IgnoreCollision,
	-- 	ePos         = CombatFloater.CodeEnumFloaterLocation.Chest
	-- }
	
	-- Damage Out
	tSettings.cDmgDefault 		  = 0xf4e443
	tSettings.cDmgMultiHit 		  = 0x0088ff
	tSettings.cDmgCrit 			  = 0xfffb93
	tSettings.cDmgVuln 			  = 0xf5a2ff
	tSettings.cDmgAbsorb          = 0xffffff
	tSettings.iDmgBigCritOutValue = 10000
	tSettings.iDmgOutThreshold    = 0
	tSettings.fDmgOutNormalScale  = 1.0
	tSettings.fDmgOutCritScale 	  = 1.25
	tSettings.fDmgOutDuration     = 1.25
	tSettings.nDmgOutPattern      = "PatternPopup"
	tSettings.fDmgOutAlpha        = 1.0
	tSettings.nDmgOutCollision    = CombatFloater.CodeEnumFloaterCollisionMode.IgnoreCollision
	tSettings.bDmgOutMergeShield  = true
	tSettings.bDmgOutShowAbsorb   = true

	-- Damage In
	tSettings.cDmgInDefault 	  = 0xff3333
	tSettings.cDmgInCrit 		  = 0xff0000
	tSettings.cDmgInAbsorb	      = 0xffffff
	tSettings.fDmgInCritScale 	  = 1.1
	tSettings.fDmgInNormalScale   = 1.0
	tSettings.fDmgInDuration      = 1.0
	tSettings.nDmgInPattern       = "PatternPopup"
	tSettings.nDmgInCollision     = CombatFloater.CodeEnumFloaterCollisionMode.IgnoreCollision
	
	-- Heal Out
	tSettings.cHealDefault 		  = 0x73E684
	tSettings.cHealCrit 		  = 0x4AE862
	tSettings.cHealMultiHit 	  = 0x469AE3
	tSettings.cHealShield 		  = 0x68DBE3
	tSettings.iHealBigCritValue   = 10000
	tSettings.iHealOutThreshold   = 0
	tSettings.fHealOutNormalScale = 1.0
	tSettings.fHealOutCritScale   = 1.1
	tSettings.nHealOutPattern     = "PatternPopup"
	tSettings.nHealOutCollision   = CombatFloater.CodeEnumFloaterCollisionMode.IgnoreCollision
	
	-- Heal In
	tSettings.cHealInDefault 	  = 0x73E684
	tSettings.cHealInCrit 		  = 0x4AE862
	tSettings.cHealInShield       = 0x68DBE3
	tSettings.iDmgBigCritInValue  = 30000
	tSettings.iHealInBigCritValue = 10000
	tSettings.iHealInThreshold    = 0
	tSettings.fHealInNormalScale  = 1.0
	tSettings.fHealInCritScale    = 1.1
	tSettings.fHealInDuration     = 1.0
	tSettings.nHealInPattern      = "PatternPopup"
	tSettings.nHealInCollision    = CombatFloater.CodeEnumFloaterCollisionMode.IgnoreCollision
	
	-- Default fonts
	tSettings.nDmgOutFont  = "CRB_FloaterMedium"
	tSettings.nDmgInFont   = "CRB_FloaterMedium"
	tSettings.nHealOutFont = "CRB_FloaterMedium"
	tSettings.nHealInFont  = "CRB_FloaterMedium"
	
	-- Default positions
	tSettings.nDmgOutPos   = CombatFloater.CodeEnumFloaterLocation.Chest
	tSettings.nDmgInPos    = CombatFloater.CodeEnumFloaterLocation.Chest
	tSettings.nHealOutPos  = CombatFloater.CodeEnumFloaterLocation.Chest
	tSettings.nHealInPos   = CombatFloater.CodeEnumFloaterLocation.Chest

	-- Deflects
	tSettings.cDeflect      = 0xdddddd

	-- General options
	tSettings.bShowRealmBroadcast = true
	tSettings.bShowZoneChange = true
	
	tSettings.currentCategory = "InitGeneral"
	
	return tSettings
end


---------------------------------------------------------------------------------------------------
function IronCombatText:OnLoad()
---------------------------------------------------------------------------------------------------
	-- Test to see if we have settings
	if self.tSettings == nil then
		self.tSettings = self:GetDefaultSettings()
	else
		self.tSettings = self:CompareSettings(self.tSettings)
	end
	
	self.Utils.Init(self)
	self.Patterns:Init(self)
	self.Options:Init(self)
	
	-- Register handlers for events, slash commands and timer, etc.
	-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)

	--                          CALLBACK NAME                           ALIASED NAME                           SELF
	Apollo.RegisterEventHandler("OptionsUpdated_Floaters", 		        "OnOptionsUpdated",                    self)
	Apollo.RegisterEventHandler("ChannelUpdate_Loot",					"OnChannelUpdate_Loot",                self)
	Apollo.RegisterEventHandler("SpellCastFailed", 						"OnSpellCastFailed",                   self)
	Apollo.RegisterEventHandler("DamageOrHealingDone",				 	"OnDamageOrHealing",                   self)
	Apollo.RegisterEventHandler("CombatMomentum", 						"OnCombatMomentum",                    self)
	Apollo.RegisterEventHandler("ExperienceGained", 					"OnExperienceGained",                  self)	-- UI_XPChanged ?
	Apollo.RegisterEventHandler("ElderPointsGained", 					"OnElderPointsGained",                 self)
	Apollo.RegisterEventHandler("UpdatePathXp", 						"OnPathExperienceGained",              self)
	Apollo.RegisterEventHandler("AttackMissed", 						"OnMiss",                              self)
	Apollo.RegisterEventHandler("SubZoneChanged", 						"OnSubZoneChanged",                    self)
	Apollo.RegisterEventHandler("RealmBroadcastTierMedium", 			"OnRealmBroadcastTierMedium",          self)
	Apollo.RegisterEventHandler("GenericError", 						"OnGenericError",                      self)
	Apollo.RegisterEventHandler("PrereqFailureMessage",					"OnPrereqFailed",                      self)
	Apollo.RegisterEventHandler("GenericFloater", 						"OnGenericFloater",                    self)
	Apollo.RegisterEventHandler("UnitEvaded", 							"OnUnitEvaded",                        self)
	Apollo.RegisterEventHandler("QuestShareFloater", 					"OnQuestShareFloater",                 self)
	Apollo.RegisterEventHandler("CountdownTick", 						"OnCountdownTick",                     self)
	Apollo.RegisterEventHandler("TradeSkillFloater",			 		"OnTradeSkillFloater",                 self)
	Apollo.RegisterEventHandler("FactionFloater", 						"OnFactionFloater",                    self) 
	Apollo.RegisterEventHandler("FloaterTransference", 					"OnFloaterTransference",               self)
	Apollo.RegisterEventHandler("CombatLogCCState", 					"OnCombatLogCCState",                  self)
	Apollo.RegisterEventHandler("CombatLogImmunity", 					"OnCombatLogImmunity",                 self)
	Apollo.RegisterEventHandler("FloaterMultiHit", 						"OnFloaterMultiHit",                   self)
	Apollo.RegisterEventHandler("FloaterMultiHeal", 					"OnFloaterMultiHeal",                  self)
	Apollo.RegisterEventHandler("ActionBarNonSpellShortcutAddFailed", 	"OnActionBarNonSpellShortcutAddFailed", self)
	Apollo.RegisterEventHandler("GenericEvent_GenericError",			"OnGenericError",                      self)

	-- set the max count of floater text
	CombatFloater.SetMaxFloaterCount(200)
	CombatFloater.SetMaxFloaterPerUnitCount(100)

	-- float text queue for delayed text
	self.tDelayedFloatTextQueue = Queue:new()
	self.iTimerIndex = 1
	self.tTimerFloatText = {}

	self:OnOptionsUpdated()
end

---------------------------------------------------------------------------------------------------
function IronCombatText:OnOptionsUpdated()
---------------------------------------------------------------------------------------------------
	if g_InterfaceOptions and g_InterfaceOptions.Carbine.bSpellErrorMessages ~= nil then
		self.bSpellErrorMessages = g_InterfaceOptions.Carbine.bSpellErrorMessages
	else
		self.bSpellErrorMessages = true
	end
end

---------------------------------------------------------------------------------------------------
function IronCombatText:GetDefaultTextOption()
---------------------------------------------------------------------------------------------------
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
---------------------------------------------------------------------------------------------------
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
---------------------------------------------------------------------------------------------------
	-- if you're in a taxi, don't show zone change
	if GameLib.GetPlayerTaxiUnit() or self.tSettings.bShowZoneChange == false then
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
---------------------------------------------------------------------------------------------------
	if self.tSettings.bShowRealmBroadcast == false then
		return
	end

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
---------------------------------------------------------------------------------------------------
	local strMessage = Apollo.GetString("FloatText_ActionBarAddFail")
	self:OnSpellCastFailed( LuaEnumMessageType.GenericPlayerInvokedError, nil, GameLib.GetControlledUnit(), GameLib.GetControlledUnit(), strMessage )
end

---------------------------------------------------------------------------------------------------
function IronCombatText:OnGenericError(eError, strMessage)
---------------------------------------------------------------------------------------------------
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
---------------------------------------------------------------------------------------------------
	self:OnGenericError(nil, strMessage)
end

---------------------------------------------------------------------------------------------------
function IronCombatText:OnGenericFloater(unitTarget, strMessage)
---------------------------------------------------------------------------------------------------
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

---------------------------------------------------------------------------------------------------
function IronCombatText:OnUnitEvaded(unitSource, unitTarget, eReason, strMessage)
---------------------------------------------------------------------------------------------------
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
---------------------------------------------------------------------------------------------------
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
---------------------------------------------------------------------------------------------------
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
---------------------------------------------------------------------------------------------------
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
---------------------------------------------------------------------------------------------------
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
---------------------------------------------------------------------------------------------------
	local bCritical = tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical
	self:OnDamageOrHealing( 
							tEventArgs.unitCaster, 
							tEventArgs.unitTarget, 
							tEventArgs.eDamageType, 
							math.abs(tEventArgs.nDamageAmount), 
							math.abs(tEventArgs.nShield),
							math.abs(tEventArgs.nAbsorption),
							bCritical,
							tEventArgs.splCallingSpell:GetName(),
							true 
						  )
end

---------------------------------------------------------------------------------------------------
function IronCombatText:OnFloaterMultiHeal(tEventArgs)
---------------------------------------------------------------------------------------------------
	local bCritical = tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical
	self:OnDamageOrHealing( tEventArgs.unitCaster, tEventArgs.unitTarget, GameLib.CodeEnumDamageType.Heal, 
							math.abs(tEventArgs.nHealAmount), 0, 0, bCritical, tEventArgs.splCallingSpell:GetName(), 
							true )
end

---------------------------------------------------------------------------------------------------
function IronCombatText:OnFloaterTransference(tEventArgs)
---------------------------------------------------------------------------------------------------
	local bCritical = tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical
		self:OnDamageOrHealing( tEventArgs.unitCaster, 
								tEventArgs.unitTarget, 
								tEventArgs.eDamageType, 
								math.abs(tEventArgs.nDamageAmount), 
								math.abs(tEventArgs.nShield), 
								math.abs(tEventArgs.nAbsorption),
								"FloaterTransference", 
								bCritical,
								false )

	-- healing data is stored in a table where each subtable contains a different vital that was healed
	-- units in caster's group can get healed
	for idx, tHeal in ipairs(tEventArgs.tHealData) do
		self:OnDamageOrHealing( tEventArgs.unitCaster, 
								tHeal.unitHealed, 
								tEventArgs.eDamageType, 
								math.abs(tHeal.nHealAmount), 
								0, 
								0, 
								bCritical, 
								"FloaterTransference", 
								false )
	end
end

---------------------------------------------------------------------------------------------------
function IronCombatText:OnCombatMomentum( eMomentumType, nCount, strText )
---------------------------------------------------------------------------------------------------
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

---------------------------------------------------------------------------------------------------
function IronCombatText:OnExperienceGained(eReason, unitTarget, strText, fDelay, nAmount)
---------------------------------------------------------------------------------------------------
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

---------------------------------------------------------------------------------------------------
function IronCombatText:OnElderPointsGained(nAmount, nRested)
---------------------------------------------------------------------------------------------------
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

---------------------------------------------------------------------------------------------------
function IronCombatText:OnPathExperienceGained( nAmount, strText )
---------------------------------------------------------------------------------------------------
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
---------------------------------------------------------------------------------------------------
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
---------------------------------------------------------------------------------------------------

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
---------------------------------------------------------------------------------------------------
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
---------------------------------------------------------------------------------------------------
	if unitTarget == nil or not Apollo.GetConsoleVariable("ui.showCombatFloater") then
		return
	end

	-- modify the text to be shown
	local tTextOption = self:GetDefaultTextOption()
	if GameLib.IsControlledUnit( unitTarget ) or unitTarget:GetType() == "Mount" then -- if the target unit is player's char
		tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Horizontal
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

		tTextOption.fScale 			= 1.0
		tTextOption.fDuration		= 2
		tTextOption.eCollisionMode 	= CombatFloater.CodeEnumFloaterCollisionMode.IgnoreCollision
		tTextOption.eLocation 		= CombatFloater.CodeEnumFloaterLocation.Chest
		tTextOption.fOffset 		= -0.8
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
function IronCombatText:OnDamageOrHealing( unitCaster, unitTarget, eDamageType, nDamage, nShieldDamaged, nAbsorptionAmount, bCritical, strName, bMultiHit)
------------------------------------------------------------------------------------------------------------------------------
	if unitTarget == nil or not Apollo.GetConsoleVariable("ui.showCombatFloater") or nDamage == nil then
		return
	end

	local bIsHealing = eDamageType == GameLib.CodeEnumDamageType.Heal or eDamageType == GameLib.CodeEnumDamageType.HealShields
	local bIsPlayer =    GameLib.IsControlledUnit(unitTarget) 
				      or unitTarget == GameLib.GetPlayerMountUnit()
				      or GameLib.IsControlledUnit(unitTarget:GetUnitOwner()) 
				      or unitTarget == GameLib.GetPlayerUnit()
					
	if  bIsPlayer then
		if bIsHealing then
			self:OnIncomingHealing(unitTarget, eDamageType, nDamage, nShieldDamaged, nAbsorptionAmount, bCritical)
		else
			self:OnIncomingDamage(unitTarget, eDamageType, nDamage, nShieldDamaged, nAbsorptionAmount, bCritical)
		end
	else
		if bIsHealing then
			self:OnOutgoingHealing(unitCaster, unitTarget, eDamageType, nDamage, nShieldDamaged, nAbsorptionAmount, bCritical, bMultiHit)
		else
			self:OnOutgoingDamage(unitCaster, unitTarget, nDamage, nShieldDamaged, nAbsorptionAmount, bCritical, bMultiHit)
		end
	end
end

------------------------------------------------------------------------------------------------------------------------------
-- Helper function for displaying healing
------------------------------------------------------------------------------------------------------------------------------
function IronCombatText:OnOutgoingHealing( unitCaster, unitTarget, eDamageType, nDamage, nShieldDamage, nAbsorp, bCritical, bMultiHit)
-----------------------------------------------------------------------------------------------------------------------------
	if (nDamage + nShieldDamage) <= self.tSettings.iHealOutThreshold then
		return
	end
	
	local tTextOption = self:GetDefaultTextOption()
	
	local nBaseColor     = self.tSettings.cHealDefault
	local fMaxSize       = self.tSettings.fHealOutNormalScale
	local fMaxDuration   = 1.25
	local fBigCritScale  = 1.0
	local nTotalDamage   = nDamage + nShieldDamage
	
	if bCritical == true then -- Crit not vuln
		nBaseColor = self.tSettings.cHealCrit
		fMaxSize = self.tSettings.fHealOutCritScale
		
		if nTotalDamage >= 10000 then
			fBigCritScale = 1.25
		end
	end
	
	if eDamageType == GameLib.CodeEnumDamageType.HealShields then -- healing shields params
		nBaseColor = self.tSettings.cHealShield
	end
	
	if bMultiHit ~= nil and bMultiHit == true then
	  nBaseColor = self.tSettings.cHealMultiHit
	end
	
	local tParams = 
	{
		strFontFace  	= self.tSettings.nHealOutFont,
		eLocation  	 	= self.tSettings.nHealOutPos,
		eCollisionMode	= self.tSettings.nHealOutCollision,
		fMaxSize 	 	= fMaxSize,
		fBigScale  	 	= fBigCritScale,
		fMaxDuration 	= fMaxDuration,
		nBaseColor   	= nBaseColor
	}
		
	tTextOption = self.Patterns:GeneratePattern(self.tSettings.nHealOutPattern, tParams)

	if type(nAbsorptionAmount) == "number" and nAbsorptionAmount > 0 then -- secondary "if" so we don't see absorption and "0"
		CombatFloater.ShowTextFloater( unitTarget, String_GetWeaselString(Apollo.GetString("FloatText_Absorbed"), nAbsorptionAmount), tTextOptionAbsorb )
	else
		CombatFloater.ShowTextFloater( unitTarget, String_GetWeaselString(Apollo.GetString("FloatText_PlusValue"), nDamage), tTextOption ) -- we show "0" when there's no absorption
	end
end

------------------------------------------------------------------------------------------------------------------------------
-- Helper function for displaying damage
------------------------------------------------------------------------------------------------------------------------------
function IronCombatText:OnOutgoingDamage( unitCaster, unitTarget, nDamage, nShieldDamage, nAbsorb, bCritical, bMultiHit)
-----------------------------------------------------------------------------------------------------------------------------	
	-- Don't do anything if under damage threshold
	if (nDamage + nShieldDamage) <= self.tSettings.iDmgOutThreshold then
		return
	end

	local tTextOption 	= self:GetDefaultTextOption()
	local nTotalDamage 	= nDamage + nShieldDamage
	local nBaseColor 	= self.tSettings.cDmgDefault
	local fMaxSize 		= self.tSettings.fDmgOutNormalScale
	local fCritScale 	= self.tSettings.fDmgOutCritScale
	local fMaxDuration 	= self.tSettings.fDmgOutDuration
	local fBigDmgScale 	= 1.0
	local bIsAbsorb     = false
	
	-- Change color and scale for crit
	if bCritical == true then 
		nBaseColor = self.tSettings.cDmgCrit
		fMaxSize = fMaxSize * fCritScale
		
		if nTotalDamage >= self.tSettings.iDmgBigCritOutValue then
			fBigDmgScale = 1.25
			fMaxDuration = fMaxDuration * 2
		end
	end
	
	-- Change color for vuln
	if unitTarget:IsInCCState( Unit.CodeEnumCCState.Vulnerability ) then 
		nBaseColor = self.tSettings.cDmgVuln
	end 
	
	-- Change color and position for multi-hit
	if bMultiHit and bMultiHit == true then
	  nBaseColor = self.tSettings.cDmgMultiHit
	end
	
	if type(nAbsorb) == "number" and nAbsorb > 0 then
		if self.tSettings.bDmgOutShowAbsorb == true then
			bIsAbsorb = true
			nBaseColor = self.tSettings.cDmgAbsorb
		end
		nTotalDamage = nTotalDamage + nAbsorb
	end

	
	local tParams = 
	{
		strFontFace     = self.tSettings.nDmgOutFont,
		eLocation  	    = self.tSettings.nDmgOutPos,
		eCollisionMode  = self.tSettings.nDmgOutCollision,
		fMaxSize 	    = fMaxSize,
		fBigScale  	    = fBigDmgScale,
		fMaxDuration    = fMaxDuration,
		nBaseColor      = nBaseColor
	}
	
	tTextOption = self.Patterns:GeneratePattern(self.tSettings.nDmgOutPattern, tParams)
	
	if bIsAbsorb == true then
		CombatFloater.ShowTextFloater( unitTarget, String_GetWeaselString(Apollo.GetString("FloatText_Absorbed"), nAbsorb), tTextOption )
	elseif self.tSettings.bDmgOutMergeShield == false then
		CombatFloater.ShowTextFloater( unitTarget, nDamage, nShieldDamage, tTextOption )
	else
		CombatFloater.ShowTextFloater( unitTarget, nTotalDamage, 0, tTextOption )
	end
	
end

------------------------------------------------------------------
function IronCombatText:OnIncomingDamage( unitPlayer, eDamageType, nDamage, nShieldDamage, nAbsorb, bCritical )
------------------------------------------------------------------	
	local tTextOption = self:GetDefaultTextOption()
	
	local nBaseColor 	= self.tSettings.cDmgInDefault
	local fMaxSize		= self.tSettings.fDmgInNormalScale
	local fCritScale 	= self.tSettings.fDmgInCritScale
	local fMaxDuration 	= self.tSettings.fDmgInDuration
	local fBigCritScale = 1.0
	local nTotalDamage 	= nDamage + nShieldDamage
	

	-- Change color and scale for crit
	if bCritical == true then 
		nBaseColor = self.tSettings.cDmgInCrit
		fMaxSize = fMaxSize * fCritScale
		if nTotalDamage >= self.tSettings.iDmgBigCritInValue then
			fBigCritScale = 1.25
		end
	end
	
	if type(nAbsorb) == "number" and nAbsorb > 0 then
		nBaseColor = self.tSettings.cDmgInAbsorb
	end
	
	local tParams = 
	{
		strFontFace  	= self.tSettings.nDmgInFont,
		eLocation  	 	= self.tSettings.nDmgInPos,
		eCollisionMode  = self.tSettings.nDmgInCollision,
		fMaxSize 		= fMaxSize,
		fBigScale  	 	= fBigCritScale,
		fMaxDuration 	= fMaxDuration,
		nBaseColor   	= nBaseColor
	}

	tTextOption = self.Patterns:GeneratePattern(self.tSettings.nDmgInPattern, tParams)

	--tTextOption = self.patternTable[self.tSettings.nDmgInPattern](self.tSettings.nDmgInFont, self.tSettings.nDmgInPos, fMaxSize, fBigCritScale, fMaxDuration, nBaseColor)

	if type(nAbsorb) == "number" and nAbsorb > 0 then
		CombatFloater.ShowTextFloater( unitPlayer, String_GetWeaselString(Apollo.GetString("FloatText_Absorbed"), nAbsorb), tTextOption )
	else
		CombatFloater.ShowTextFloater( unitPlayer, nDamage, nShieldDamage, tTextOption )
	end

end


------------------------------------------------------------------
function IronCombatText:OnIncomingHealing( unitPlayer, eDamageType, nDamage, nShieldDamage, nAbsorb, bCritical )
	if (nDamage + nShieldDamage) <= self.tSettings.iHealInThreshold then
		return
	end
	
	local tTextOption = self:GetDefaultTextOption()
	
	local nBaseColor 	= self.tSettings.cHealInDefault
	local fMaxSize 		= self.tSettings.fHealInNormalScale
	local fMaxDuration 	= self.tSettings.fHealInDuration
	local fBigCritScale = 1.0
	local nTotalDamage 	= nDamage + nShieldDamage
	
	if bCritical == true then
		nBaseColor = self.tSettings.cHealInCrit
		fMaxSize = self.tSettings.fHealInCritScale
		
		if nTotalDamage >= 10000 then
			fBigCritScale = 1.25
		end
	end
	
	if eDamageType == GameLib.CodeEnumDamageType.HealShields then -- healing shields params
		nBaseColor = self.tSettings.cHealInShield
	end
	
	local tParams =
	{
		strFontFace  	= self.tSettings.nHealInFont,
		eLocation  	 	= self.tSettings.nHealInPos,
		eCollisionMode	= self.tSettings.nHealInCollision,
		fMaxSize 	 	= fMaxSize,
		fBigScale  	 	= fBigCritScale,
		fMaxDuration 	= fMaxDuration,
		nBaseColor   	= nBaseColor
	}

	tTextOption = self.Patterns:GeneratePattern(self.tSettings.nHealInPattern, tParams)
	
	--tTextOption = self.patternTable[self.tSettings.nHealInPattern](self.tSettings.nHealInFont, self.tSettings.nHealInPos, fMaxSize, fBigCritScale, fMaxDuration, nBaseColor)

	if type(nAbsorptionAmount) == "number" and nAbsorptionAmount > 0 then -- secondary "if" so we don't see absorption and "0"
		CombatFloater.ShowTextFloater( unitPlayer, String_GetWeaselString(Apollo.GetString("FloatText_Absorbed"), nAbsorptionAmount), tTextOption )
	else
		CombatFloater.ShowTextFloater( unitPlayer, String_GetWeaselString(Apollo.GetString("FloatText_PlusValue"), nDamage), tTextOption ) -- we show "0" when there's no absorption
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
function IronCombatText:RequestShowTextFloater( eMessageType, unitTarget, strText, tTextOption, fDelay, tContent ) -- additional parameters for XP/rep
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


local IronCombatTextInst = IronCombatText:new()
IronCombatTextInst:Init()
