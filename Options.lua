require "CombatFloater"
require "ChatSystemLib"

local Options = {}
local IronCombatText  = Apollo.GetAddon("IronCombatText")

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local k_InitColor 	  = "InitColorWidget"
local k_InitPattern   = "InitPatternWidget"
local k_InitFont      = "InitFontWidget"
local k_InitCollision = "InitCollisionWidget"
local k_InitPosition  = "InitPositionWidget"
local k_InitSlider	  = "InitSliderWidget"
local k_InitValue	  = "InitValueWidget"
local k_InitOptionBox = "InitOptionBoxWidget"


-- Testing
local k_InitComboBox = "InitComboBox"

-----------------------------------------------------------------------------------------------
-- Constant Tables
-----------------------------------------------------------------------------------------------
local fontList = 
{
  "CRB_FloaterLarge",
  "CRB_FloaterMedium",
  "CRB_FloaterSmall",
  "CRB_HeaderHuge",
  "CRB_HeaderLarge",
  "CRB_HeaderMedium",
  "CRB_HeaderSmall",
  "CRB_InterfaceLarge",
  "CRB_InterfaceLarge_B",
  "CRB_InterfaceLarge_BBO"
}

local posList = 
{
  "Head",
  "Chest",
  "Back",
  "Bottom",
  "Top"
}

local posLookup = 
{
	Head   = CombatFloater.CodeEnumFloaterLocation.Head,
	Chest  = CombatFloater.CodeEnumFloaterLocation.Chest,
	Back   = CombatFloater.CodeEnumFloaterLocation.Back,
	Top    = CombatFloater.CodeEnumFloaterLocation.Top,
	Bottom = CombatFloater.CodeEnumFloaterLocation.Bottom,
}

local collisionList = 
{
	"Ignore",
	"Horizontal",
	"Vertical"
}

local collisionLookup = 
{
	Horizontal = CombatFloater.CodeEnumFloaterCollisionMode.Horizontal,
	Vertical   = CombatFloater.CodeEnumFloaterCollisionMode.Vertical,
	Ignore     = CombatFloater.CodeEnumFloaterCollisionMode.IgnoreCollision
}

local patternList = 
{
  "Default",
  "Circular",
  "StreamUpRight",
  "StreamUpLeft",
  "StreamDownRight",
  "StreamDownLeft",
  "StraightUp",
  "StraightDown",
  "Test"
}

-----------------------------------------------------------------------------------------------
-- Init Function
-----------------------------------------------------------------------------------------------
function Options:Init(parent)
-----------------------------------------------------------------------------------------------
	Apollo.LinkAddon(parent, self)
	Apollo.RegisterSlashCommand("ict", "OnInvokeOptions", self)
	Apollo.RegisterSlashCommand("ironcombattext", "OnInvokeOptions", self)
	Apollo.RegisterSlashCommand("icbt", "OnInvokeOptions", self)

	-- Function table for category init
	self.initFunctions = 
	{
		OutDmg  = function() self:InitOutDmg()  end,
		InDmg   = function() self:InitInDmg()   end,
		InHeal  = function() self:InitInHeal()  end,
		OutHeal = function() self:InitOutHeal() end,
		General = function() self:InitGeneral() end,
	}

	-- Function table for widget init
	self.widgetFunctions = 
	{
		[k_InitColor]		= function(...) return self:InitColorWidget(...) 		end,
		[k_InitPattern] 	= function(...) return self:InitPatternWidget(...) 		end,
		[k_InitFont]		= function(...) return self:InitFontWidget(...) 		end,
		[k_InitCollision] 	= function(...) return self:InitCollisionWidget(...) 	end,
		[k_InitPosition] 	= function(...) return self:InitPositionWidget(...) 	end,
		[k_InitSlider] 		= function(...) return self:InitSliderWidget(...) 		end,
		[k_InitValue]		= function(...) return self:InitValueWidget(...) 		end,
		[k_InitOptionBox]	= function(...) return self:InitOptionBoxWidget(...) 	end,

	}
	
	self.parent = parent
	self.xmlDoc = XmlDoc.CreateFromFile("OptionsPanel.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- Options OnDocLoaded
-----------------------------------------------------------------------------------------------
function Options:OnDocLoaded()
-----------------------------------------------------------------------------------------------
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "AltSettings", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(false, true)
		self.content = self.wndMain:FindChild("Content")
		self:LoadCategory(self.parent.tSettings.currentCategory)
		 
	else
		Apollo.AddAddonErrorText(self, "Could not load the xml doc for some reason.")
	end
end

-----------------------------------------------------------------------------------------------
-- Loads the current category whenever the options screen is invoked.
-----------------------------------------------------------------------------------------------
function Options:OnInvokeOptions()
-----------------------------------------------------------------------------------------------
	self.wndMain:Invoke()
	self:LoadCategory(self.parent.tSettings.currentCategory)
end


-----------------------------------------------------------------------------------------------
-- Loads a category when a radio button is pressed on the main options screen.
-----------------------------------------------------------------------------------------------
function Options:LoadCategory(categoryName)
-----------------------------------------------------------------------------------------------
	self.currentButton = self.wndMain:FindChild(categoryName)
	self.currentButton:SetCheck(true)
	self.content:DestroyChildren()
	self.options = Apollo.LoadForm(self.xmlDoc, "BaseCategory", self.content, self)
	self.parent.tSettings.currentCategory = categoryName
	self.currentCategory = categoryName
	
	-- Global variables that are easy to re-init here and add later
	self.colorPreviews = {}
	self.textWidgets   = {}
	self.textParams    = {}
	self.totalSize 	   = 0
	
	if self.options then
		self.initFunctions[categoryName]()
	else
		Apollo.AddAddonErrorText(self, "Unable to load category ".. categoryName)
	end
end

-----------------------------------------------------------------------------------------------
function Options:InitInHeal()
-----------------------------------------------------------------------------------------------
	local fontName = "nHealInFont"

	self:LoadSubCategory(self.options, 
	{ 
		Color = 
			   { 
				{k_InitColor, "cHealInDefault",  "Normal",       fontName}, 
				{k_InitColor, "cHealInCrit",     "Critical",     fontName},
				{k_InitColor, "cHealInShield", 	 "Shield Heal",  fontName},
			   },  
		Text = 
			   { 
				{k_InitFont, 	  fontName}, 
				{k_InitPosition,  "nHealInPos"}, 
				{k_InitPattern,   "nHealInPattern"},
				{k_InitCollision, "nHealInCollision"}
			   }, 
  		Other = 
			   { 
				{k_InitValue,  "iHealInThreshold",    "Don't show any damage under this threshold"},
			   },
		Scale = 
			   { 
				{k_InitSlider, "fHealInNormalScale", "Normal Scale"}, 
				{k_InitSlider, "fHealInCritScale",   "Critical Scale"},
			   }, 
	})
end

-----------------------------------------------------------------------------------------------
function Options:InitOutHeal()
-----------------------------------------------------------------------------------------------
	local fontName = "nHealOutFont"
	
	self:LoadSubCategory(self.options, 
	{ 
		Color = 
			   { 
				{k_InitColor, "cHealDefault",  "Normal",       fontName}, 
				{k_InitColor, "cHealCrit",     "Critical",     fontName},
				{k_InitColor, "cHealMultiHit", "Multi Hit",    fontName},
				{k_InitColor, "cHealShield",   "Shield Heal",  fontName}, 
			   },  
		Text = 
			   { 
				{k_InitFont, 	  fontName}, 
				{k_InitPosition,  "nHealOutPos"}, 
				{k_InitPattern,   "nHealOutPattern"},
				{k_InitCollision, "nHealOutCollision"}
			   }, 
  		Other = 
			   { 
				{k_InitValue,  "iHealOutThreshold",    "Don't show any damage under this threshold"},
			   },
		Scale = 
			   { 
				{k_InitSlider, "fHealOutNormalScale", "Normal Scale"}, 
				{k_InitSlider, "fHealOutCritScale",   "Critical Scale"},
			   }, 
	})
end

-----------------------------------------------------------------------------------------------
function Options:InitOutDmg()
-----------------------------------------------------------------------------------------------
	local totalHeight = 0
	local fontName       = "nDmgOutFont"
	local positionName   = "nDmgOutPos"
	local patternName    = "nDmgOutPattern"
	local collisionName  = "nDmgOutCollision"

	self:LoadSubCategory(self.options, 
	{ 
		Color = 
			   { 
				{k_InitColor, "cDmgDefault",   "Normal",        fontName}, 
				{k_InitColor, "cDmgCrit",      "Critical",      fontName},
				{k_InitColor, "cDmgMultiHit",  "Multi Hit",     fontName},
				{k_InitColor, "cDmgVuln",      "Vulnerability", fontName}, 
				{k_InitColor, "cDmgAbsorb",    "Absorb",        fontName}
			   },  
		Text = 
			   { 
				{k_InitFont, 	  fontName}, 
				{k_InitPosition,  positionName}, 
				{k_InitPattern,   patternName},
				{k_InitCollision, collisionName}
			   }, 
  		Other = 
			   { 
				{k_InitValue,     "iDmgBigCritOutValue", "Emphasize crits above this value"}, 
				{k_InitValue,     "iDmgOutThreshold",    "Don't show any damage under this threshold"},
				{k_InitOptionBox, "bDmgOutMergeShield",  "Merge shield and regular damage into one number"}, 
				{k_InitOptionBox, "bDmgOutShowAbsorb",   "Display absorbed damage differently than regular damage."}
			   },
		Scale = 
			   { 
				{k_InitSlider, "fDmgOutNormalScale", "Normal Scale"}, 
				{k_InitSlider, "fDmgOutCritScale",   "Critical Scale"},
				{k_InitSlider, "fDmgOutDuration",    "Duration", {0, 10.0, 0.05}} 
			   }, 
	})

end

-----------------------------------------------------------------------------------------------
function Options:InitInDmg()
-----------------------------------------------------------------------------------------------
	local totalHeight = 0
	local fontName       = "nDmgInFont"
	local positionName   = "nDmgInPos"
	local patternName    = "nDmgInPattern"
	local collisionName  = "nDmgInCollision"


	self:LoadSubCategory(self.options, 
	{ 
		Color = 
			   { 
				{k_InitColor, "cDmgInDefault",  "Normal",    fontName}, 
				{k_InitColor, "cDmgInCrit",     "Critical",  fontName}, 
				{k_InitColor, "cDmgInAbsorb",   "Absorb",    fontName}
			   },  
		Text = 
			   { 
				{k_InitFont, 	  fontName}, 
				{k_InitPosition,  positionName}, 
				{k_InitPattern,   patternName},
				{k_InitCollision, collisionName}
			   }, 
		Scale = 
			   { 
				{k_InitSlider, "fDmgInNormalScale", "Normal Scale"}, 
				{k_InitSlider, "fDmgInCritScale",   "Critical Scale"}, 
			   } 
	})
	
end

-----------------------------------------------------------------------------------------------
function Options:InitGeneral()
-----------------------------------------------------------------------------------------------
	

	self:LoadSubCategory(self.options, 
	{
		Display = 
		{
			{ k_InitOptionBox, "bShowZoneChange", "Show zone changes."},
			{ k_InitOptionBox, "bShowRealmBroadCast", "Show realm broadcasts."},
		}

	})

end

-----------------------------------------------------------------------------------------------
function Options:LoadSubCategory(parentForm, tWidgets)
-----------------------------------------------------------------------------------------------
	local totalSize = 0
	local startSize = 0
	local currentSize = 0

	for k,v in pairs(tWidgets) do
		currentSize = 60 -- Size of the header
		startSize = totalSize

		local category = self:LoadWidget("ContentCategory", parentForm, { "Description", "Content" })
		category.Description:SetText(k)

		-- Use the first element of the table as the init function to call,
		-- and unpack the rest of the arguments for the actual function
		for i,iv in ipairs(v) do
			local height = self.widgetFunctions[iv[1]](category.Content, unpack(iv, 2))
			currentSize = currentSize + height
		end

		-- Rearrange all of the sub elements appropriately
		local left, top, right, bottom = category.Widget:GetAnchorOffsets()
		category.Widget:SetAnchorOffsets(left, startSize, right, startSize + currentSize)
		category.Content:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Middle)

		totalSize = totalSize + currentSize
	end

	parentForm:ArrangeChildrenTiles(0)
end

-----------------------------------------------------------------------------------------------
-- Radio Group for options all have this as their callback
-----------------------------------------------------------------------------------------------
function Options:OnOptionSelected( wndHandler, wndControl, eMouseButton )
-----------------------------------------------------------------------------------------------
	self.currentCategory = wndHandler:GetName():gsub("%s", "")
	self.parent.tSettings.currentCategory = self.currentCategory
	self:LoadCategory(self.currentCategory)
end

-----------------------------------------------------------------------------------------------
function Options:OnClose( wndHandler, wndControl, eMouseButton )
-----------------------------------------------------------------------------------------------
	self.wndMain:Close()
end

-----------------------------------------------------------------------------------------------
-- Widget Loading Utilities
--
-- < LoadWidget
-- < LoadColorWidget
-- < LoadSliderWidget
-- < LoadOptionBoxWidget
-- < LoadValueWidget
-- < LoadListSelectionWidget
-- < LoadListSelectionItemWidget
-----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-- Loads a widget and returns all of the requested forms in a table.
-----------------------------------------------------------------------------------------------
function Options:LoadWidget(strName, parentForm, tSub)
-----------------------------------------------------------------------------------------------
	local tForms = {}
	local widget = Apollo.LoadForm(self.xmlDoc, strName, parentForm, self)
	tForms.Widget = widget
	for i,n in ipairs(tSub) do
		tForms[n] = widget:FindChild(n)
	end
	return tForms
end

-----------------------------------------------------------------------------------------------
-- Helper function for loading a color widget
-----------------------------------------------------------------------------------------------
function Options:LoadColorWidget(parentForm)
-----------------------------------------------------------------------------------------------
	return self:LoadWidget("ColorPickerWidget", parentForm, { "Preview", "Description", "Color", "ColorImg" } )
end

-----------------------------------------------------------------------------------------------
-- Helper function for loading a slider
-----------------------------------------------------------------------------------------------
function Options:LoadSliderWidget(parentForm)
-----------------------------------------------------------------------------------------------
	return self:LoadWidget("SliderWidget", parentForm, { "Slider", "Description", "Preview" } )
end

-----------------------------------------------------------------------------------------------
-- Helper function for loading a slider
-----------------------------------------------------------------------------------------------
function Options:LoadOptionBoxWidget(parentForm)
-----------------------------------------------------------------------------------------------
	return self:LoadWidget("OptionBoxWidget", parentForm, { "OptionBox", "Description" } )
end

-----------------------------------------------------------------------------------------------
-- Helper function for loading a slider
-----------------------------------------------------------------------------------------------
function Options:LoadValueWidget(parentForm)
-----------------------------------------------------------------------------------------------
	return self:LoadWidget("ValueWidget", parentForm, { "Value", "Description" } )
end

-----------------------------------------------------------------------------------------------
-- Helper function for loading a list selection widget
-----------------------------------------------------------------------------------------------
function Options:LoadListSelectionWidget(parentForm, tParams)
-----------------------------------------------------------------------------------------------
	local tWidget = self:LoadWidget("ListSelectionWidget", parentForm, 
		{ "Description", "Current", "Inc", "Dec" } )

	local params = self.textParams[tParams.name]
 	
	tWidget.Inc:AddEventHandler("ButtonSignal", "OnListPosChanged")
	tWidget.Dec:AddEventHandler("ButtonSignal", "OnListPosChanged")
	tWidget.Inc:Enable(params.Idx ~= 1)
	tWidget.Dec:Enable(params.Idx ~= params.Max)
	tWidget.Inc:SetData(tParams)
	tWidget.Dec:SetData(tParams)
	return tWidget
end

-----------------------------------------------------------------------------------------------
-- ListWidget increment and decrement
-----------------------------------------------------------------------------------------------
function Options:OnListPosChanged(wndHandler, wndControl)
-----------------------------------------------------------------------------------------------
	local name = wndHandler:GetName()
	local data = wndHandler:GetData()
	local params = self.textParams[data.name]

	local inc = (name == "Inc") and -1 or 1
	params.Idx = Clamp(inc + params.Idx, params.Max, 1)

	params.Widget.Inc:Enable(params.Idx ~= 1)
	params.Widget.Dec:Enable(params.Idx ~= params.Max)
	
	data.callback(params.Idx)
end

-----------------------------------------------------------------------------------------------
-- Helper function for a category and resizing based on number of items requested
-----------------------------------------------------------------------------------------------
function Options:LoadCategoryWidget(parentForm, strName, params)
-----------------------------------------------------------------------------------------------
	local category = self:LoadWidget("ContentCategory", parentForm, { "Description", "Content" })
	local categoryPadding = 2
	local left, top, right, bottom = category.Widget:GetAnchorOffsets()
	local size = categoryPadding + params.top + params.itemHeight * params.numItems + params.padding
	category.Description:SetText(strName)
	category.Widget:SetAnchorOffsets(left, params.top + categoryPadding, right, size)
	
	local tRet = { Size = size, Widget = category.Content }
	return tRet
end

---------------------------------------------------------------------------------------------------
function PrintObject(o, filter)
---------------------------------------------------------------------------------------------------
	for key,value in pairs(getmetatable(o)) do
	    if filter ~= nil and type(filter) == "string" then
			if string.find(key, filter) then
				GoodPrint(key, "=", value)
			end
		else
			GoodPrint(key, "=", value)
		end
	end
end

---------------------------------------------------------------------------------------------------
function GoodPrint(...)
---------------------------------------------------------------------------------------------------
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

---------------------------------------------------------------------------------------------------
function Clamp(nValue, nMax, nMin)
---------------------------------------------------------------------------------------------------
	return (nValue > nMax) and nMax or (nValue < nMin) and nMin or nValue
end

-----------------------------------------------------------------------------------------------
-- Widget Initialization
--
-- < InitFontWidget
-- < InitPositionWidget
-- < InitPatternWidget
-- < InitColorWidget
-- < InitSliderWidget
-----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-- TODO: Rework the increment/decrement widgets to reduce copied code.
--       Currently, all of the widgets do basically the same thing.
-----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
function Options:InitFontWidget(parentForm, setting)
-----------------------------------------------------------------------------------------------
	self.textParams[k_InitFont]     = {}
	self.textParams[k_InitFont].Max = table.getn(fontList)
	self.textParams[k_InitFont].Idx = self:LookupIndex(fontList, self.parent.tSettings[setting])

	local tParams = {
		callback = function(nIdx)
			local font = fontList[nIdx]

			-- Update the preview for the setting
			self.textParams[k_InitFont].Widget.Current:SetFont(font)
			
			-- Update the color previews
			for idx, prev in ipairs(self.colorPreviews) do
				prev:SetFont(font)
			end
			
			-- Update the setting
			self.parent.tSettings[setting] = font
		end,
		name = k_InitFont 
	}

	local tWidget = self:LoadListSelectionWidget(parentForm, tParams)
	tWidget.Description:SetText("Font")
	tWidget.Current:SetText("1234567890")
	tWidget.Current:SetFont(self.parent.tSettings[setting])
	tWidget.Current:SetTooltip("The font displayed for floating text.")
	self.textParams[k_InitFont].Widget = tWidget

	return tWidget.Widget:GetHeight()
end

-----------------------------------------------------------------------------------------------
function Options:InitPositionWidget(parentForm, setting)
-----------------------------------------------------------------------------------------------
	local strDisplay = self:LookupKeyed(posLookup, self.parent.tSettings[setting], "Display")
	local idx        = self:LookupIndex(posList, strDisplay)

	self.textParams[k_InitPosition] = {}
	self.textParams[k_InitPosition].Max = table.getn(posList)
	self.textParams[k_InitPosition].Idx = idx

	local tParams = {
		callback = function(nIdx)
			local pos = posList[nIdx]
			self.parent.tSettings[setting] = self:LookupKeyed(posLookup, pos, "Value")
			self.textParams[k_InitPosition].Widget.Current:SetText(pos)
		end,
		name = k_InitPosition
	}

	local tWidget = self:LoadListSelectionWidget(parentForm, tParams)
	tWidget.Description:SetText("Position")
	tWidget.Current:SetText(strDisplay)
	tWidget.Current:SetTooltip("The position on the unit being targeted that the text will appear.")

	self.textParams[k_InitPosition].Widget = tWidget

	return tWidget.Widget:GetHeight()
end

-----------------------------------------------------------------------------------------------
function Options:InitPatternWidget(parentForm, setting)
-----------------------------------------------------------------------------------------------
	self.textParams[k_InitPattern] = {}
	self.textParams[k_InitPattern].Max = table.getn(patternList)
	self.textParams[k_InitPattern].Idx = self:LookupIndex(patternList, self.parent.tSettings[setting])

	local tParams = {
		callback = function(nIdx)
			local pattern = patternList[nIdx]
			self.parent.tSettings[setting] = pattern
			self.textParams[k_InitPattern].Widget.Current:SetText(pattern)
		end,
		name = k_InitPattern
	}

	local tWidget  = self:LoadListSelectionWidget(parentForm, tParams)
	local pattern  = self.parent.tSettings[setting]
	tWidget.Description:SetText("Pattern")
	tWidget.Current:SetText(pattern)
	tWidget.Current:SetTooltip("The pattern in which the text will move after it appears.")

	self.textParams[k_InitPattern].Widget = tWidget

	return tWidget.Widget:GetHeight()
end


-----------------------------------------------------------------------------------------------
function Options:InitCollisionWidget(parentForm, setting)
-----------------------------------------------------------------------------------------------
	local coll = self:LookupKeyed(collisionLookup, self.parent.tSettings[setting], "Display")
	local idx  = self:LookupIndex(collisionList,   coll)

	self.textParams[k_InitCollision] = {}
	self.textParams[k_InitCollision].Max = table.getn(collisionList)
	self.textParams[k_InitCollision].Idx = idx

	local tParams = {
		callback = function(nIdx)
			local coll = collisionList[nIdx]
			self.parent.tSettings[setting] = self:LookupKeyed(collisionLookup, coll, "Value")
			self.textParams[k_InitCollision].Widget.Current:SetText(coll)
		end,
		name = k_InitCollision
	}

	local tWidget  = self:LoadListSelectionWidget(parentForm, tParams)
	tWidget.Description:SetText("Collision")
	tWidget.Current:SetText(coll)
	tWidget.Current:SetTooltip("The way in which the text will re-position itself if text overlaps.")
	self.textParams[k_InitCollision].Widget = tWidget

	return tWidget.Widget:GetHeight()
end

-----------------------------------------------------------------------------------------------
function Options:InitSliderWidget(parentForm, setting, description, tLimits)
-----------------------------------------------------------------------------------------------
	local tWidget = self:LoadSliderWidget(parentForm)
	local value   = self.parent.tSettings[setting]	
	tWidget.Description:SetText(description)
	tWidget.Preview:SetText(("%1.2f"):format(value))
	tWidget.Slider:AddEventHandler("SliderBarChanged", "OnSliderWidgetChanged")
	tWidget.Slider:SetValue(value)
	tWidget.Slider:SetData {
		preview = tWidget.Preview,
		setting = setting
	}

	if tLimits then
		tWidget.Slider:SetMinMax(unpack(tLimits))
	else
		-- Really fucking descriptive function name carbino SetMinMaxAndTickAndOtherThingsButWeWontTellYouInTheName
		tWidget.Slider:SetMinMax(0, 4, 0.05) 
	end

	return tWidget.Widget:GetHeight()
end

-----------------------------------------------------------------------------------------------
function Options:OnSliderWidgetChanged(wndHandler, wndControl, nValue, nOldValue)
-----------------------------------------------------------------------------------------------
	local data = wndHandler:GetData()
	data.preview:SetText(("%1.2f"):format(nValue))
	self.parent.tSettings[data.setting] = nValue
end

-----------------------------------------------------------------------------------------------
-- Option Box Functions
--
-- < InitOptionBoxWidget
-- < OnOptionBoxWidgetChecked
-----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
function Options:InitOptionBoxWidget(parentForm, setting, description)
-----------------------------------------------------------------------------------------------
	local tWidget = self:LoadOptionBoxWidget(parentForm)
	local value = self.parent.tSettings[setting]
	tWidget.Description:SetText(description)
	tWidget.OptionBox:SetCheck(value)
	tWidget.OptionBox:SetData{
		setting = setting
	}
	tWidget.OptionBox:AddEventHandler("ButtonCheck",   "OnOptionBoxWidgetChecked")
	tWidget.OptionBox:AddEventHandler("ButtonUncheck", "OnOptionBoxWidgetChecked")

	return tWidget.Widget:GetHeight()
end

-----------------------------------------------------------------------------------------------
function Options:OnOptionBoxWidgetChecked(wndHandler, wndControl)
-----------------------------------------------------------------------------------------------
	local data = wndHandler:GetData()
	local check = wndHandler:IsChecked()
	self.parent.tSettings[data.setting] = check
end

-----------------------------------------------------------------------------------------------
-- Value Widget Functions
--
-- < InitColorWidget
-- < OnValueChanged
-----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
function Options:InitValueWidget(parentForm, setting, description)
-----------------------------------------------------------------------------------------------
	local tWidget = self:LoadValueWidget(parentForm)
	local value = self.parent.tSettings[setting]
	tWidget.Description:SetText(description)
	tWidget.Value:SetText(value)
	tWidget.Value:SetMaxTextLength(5) --limit from 0 to 99999
	tWidget.Value:SetData{
		setting = setting
	}
	tWidget.Value:AddEventHandler("EditBoxChanged", "OnValueWidgetChanged")

	return tWidget.Widget:GetHeight()
end

-----------------------------------------------------------------------------------------------
function Options:OnValueWidgetChanged(wndHandler, wndControl)
-----------------------------------------------------------------------------------------------
	local text = wndHandler:GetText()
	local value = tonumber(text, 10) and text:len() > 0 and text or 0
	local data = wndHandler:GetData()
	
	self.parent.tSettings[data.setting] = tonumber(value, 10)
end

-----------------------------------------------------------------------------------------------
-- Color Widget Functions
--
-- < InitColorWidget
-- < OnColorPickerWidgetEditBoxChanged
-----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
function Options:InitColorWidget(parentForm, setting, description, font)
-----------------------------------------------------------------------------------------------
	local tWidget = self:LoadColorWidget(parentForm)
	local value   = ("%06x"):format(self.parent.tSettings[setting])
	local font    = self.parent.tSettings[font]
	
	tWidget.Color:SetData {
		preview = tWidget.Preview,
		image   = tWidget.ColorImg,
		setting = setting
	}
	
	tWidget.Color:SetText(value)
	tWidget.Color:SetMaxTextLength(6)
	tWidget.Color:SetTextColor("FFFFFFFF")
	tWidget.Color:AddEventHandler("EditBoxChanged", "OnColorPickerWidgetEditBoxChanged")

	tWidget.Preview:SetTextColor("FF"..value)
	tWidget.ColorImg:SetBGColor("FF"..value)
	tWidget.ColorImg:AddEventHandler("MouseButtonDown", "OnColorPressed")
	tWidget.ColorImg:SetData {
		value = tostring(value),
		preview = tWidget.Preview,
		color   = tWidget.Color,
		setting = setting
	}
	tWidget.Preview:SetFont(font)
	
	tWidget.Description:SetText(description)
	table.insert(self.colorPreviews, tWidget.Preview)

	return tWidget.Widget:GetHeight()
end

-----------------------------------------------------------------------------------------------
-- Whenever a color widget reaches max length
-----------------------------------------------------------------------------------------------
function Options:OnColorPickerWidgetEditBoxChanged(wndHandler, wndControl)
-----------------------------------------------------------------------------------------------
	local text = wndHandler:GetText()
	local value = tonumber(text, 16) and text:len() == 6 and text or "ffffff"
	local data = wndHandler:GetData()
	
	data.preview:SetTextColor("ff"..value)
	data.image:GetData().value = value
	data.image:SetBGColor("ff"..value)
	self.parent.tSettings[data.setting] = tonumber(value, 16)
end

-----------------------------------------------------------------------------------------------
-- Whenever a color widget reaches max length
-----------------------------------------------------------------------------------------------
function Options:OnColorPressed(wndHandler, wndControl)
-----------------------------------------------------------------------------------------------
	local data = wndHandler:GetData()

	local callback = function(tRet)
		data.preview:SetTextColor("ff"..tRet.HEX)
		data.color:SetText(tRet.HEX)
		wndHandler:SetBGColor("ff"..tRet.HEX)
		data.value = tRet.HEX
		self.parent.tSettings[data.setting] = tonumber(tRet.HEX, 16)
	end
	
	if Apollo.GetAddon("IronColorPicker") ~= nil then
		Apollo.GetAddon("IronColorPicker"):ShowColor(data.value, callback)
	else
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, "Cannot open up color picker because you don't have the addon!", "IronCombatText")
	end
end

-----------------------------------------------------------------------------------------------
function Options:LookupIndex(list, value)
-----------------------------------------------------------------------------------------------
	for i,v in ipairs(list) do
		if v == value then
			return i
		end
	end
	
	return 0
end

-----------------------------------------------------------------------------------------------
function Options:LookupKeyed(tList, pos, kind)
-----------------------------------------------------------------------------------------------
	if kind == "Display" then
		for k,v in pairs(tList) do
			if v == pos then
				return k
			end
		end
	elseif kind == "Value" then
		for k,v in pairs(tList) do
			if k == pos then
				return v
			end
		end
	end
	return 0
end


IronCombatText.Options = Options
