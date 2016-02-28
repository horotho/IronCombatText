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



---------------------------------------------------------------------------------------------------
-- Yes, I know this is basically a tree, but I don't know enough about Lua to make a tree
-- traversal and pass the object the right 'self'.
---------------------------------------------------------------------------------------------------
local CategoryBuilder = {}
CategoryBuilder.__index = CategoryBuilder

setmetatable(CategoryBuilder, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

---------------------------------------------------------------------------------------------------
function CategoryBuilder.new()
---------------------------------------------------------------------------------------------------
  local self = setmetatable({}, CategoryBuilder)
  self.count = 0
  self.categories = {}
  self.elements = {}
  return self
end

---------------------------------------------------------------------------------------------------
function CategoryBuilder:AddCategory(strName)
---------------------------------------------------------------------------------------------------
	self.count = self.count + 1
	self.categories[self.count] = {name = strName, category = CategoryBuilder()}
	return self.categories[self.count].category
end

---------------------------------------------------------------------------------------------------
function CategoryBuilder:AddElement(...)
---------------------------------------------------------------------------------------------------
	table.insert(self.elements, arg)
end

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
		{ "General", 		  "InitGeneral" },
		{ "Outgoing Damage",  "InitOutDmg"},
		{ "Incoming Damage",  "InitInDmg"},
		{ "Outgoing Healing", "InitOutHeal"},
		{ "Incoming Healing", "InitInHeal"},
	}

	self.parent = parent

	-- 
	self.patternList = {}
	for k,v in pairs(self.parent.Patterns) do
		_, _, name = string.find(k, "Pattern(%a+)")
		if name ~= nil and name ~= '' then
			table.insert(self.patternList, name)
		end
	end
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

		self.content = self.wndMain:FindChild("Content")
		self:SetupCategories()
    	self.wndMain:Invoke()
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
	if self.xmlDoc == nil then
		self.xmlDoc = XmlDoc.CreateFromFile("OptionsPanel.xml")
		self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	else
    	self:SetupCategories()
    	self.wndMain:Invoke()
		self:LoadCategory(self.parent.tSettings.currentCategory)
	end
end

-----------------------------------------------------------------------------------------------
-- Sets up all of the category buttons
-----------------------------------------------------------------------------------------------
function Options:SetupCategories()
-----------------------------------------------------------------------------------------------	
	self.settingsButtons = self.wndMain:FindChild("SettingsButtons")
	self.settingsButtons:DestroyChildren()

	for i,v in ipairs(self.initFunctions) do
		local widget = self:LoadWidget("CategoryButtonWidget", self.settingsButtons, {"Button"})
		widget.Button:SetText(v[1])
		widget.Button:AddEventHandler("ButtonCheck", "OnOptionSelected")
		widget.Button:SetData {
			func = v[2]
		}

		if self.parent.tSettings.currentCategory == v[2] then
			widget.Button:SetCheck(true)
		end
	end

	self.settingsButtons:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Top)
end

-----------------------------------------------------------------------------------------------
-- Loads a category when a radio button is pressed on the main options screen.
-----------------------------------------------------------------------------------------------
function Options:LoadCategory(categoryName)
-----------------------------------------------------------------------------------------------
	self.content:DestroyChildren()
	self.options = Apollo.LoadForm(self.xmlDoc, "BaseCategory", self.content, self)
	self.parent.tSettings.currentCategory = categoryName

	-- Global variables that are easy to re-init here and add later
	self.colorPreviews = {}
	self.textWidgets   = {}
	self.textParams    = {}
	self.totalSize 	   = 0

	if self.options then
		-- Populate the returned category from the Init functions
		local builder = CategoryBuilder()
		self:PopulateCategory(self[categoryName](self, builder))
	else
		Apollo.AddAddonErrorText(self, "Unable to load category ".. categoryName)
	end
end

-----------------------------------------------------------------------------------------------
function Options:PopulateCategory(category)
-----------------------------------------------------------------------------------------------
	local totalSize = 0
	local currentSize = 0

	for i,v in ipairs(category.categories) do
		currentSize = 65 -- Size of the header
		startSize = totalSize

		local category = self:LoadWidget("ContentCategory", self.options, { "Description", "Content" })
		category.Description:SetText(v.name)

		-- Use the first element of the table as the init function to call,
		-- and unpack the rest of the arguments for the actual function
		-- This is fairly similar to make_shared<iv[1]>(args...) (WHAT DO YOU KNOW, LUA IS LIKE C++??!?!)
		for i,iv in ipairs(v.category.elements) do
			local height = self[iv[1]](self, category.Content, unpack(iv, 2))
			currentSize = currentSize + height
		end

		-- Rearrange all of the sub elements appropriately
		local left, top, right, bottom = category.Widget:GetAnchorOffsets()
		category.Widget:SetAnchorOffsets(left, totalSize, right, totalSize + currentSize)
		category.Content:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Middle)

		-- Add combined widget size
		totalSize = totalSize + currentSize
	end

	self.options:ArrangeChildrenTiles(0)
end

-----------------------------------------------------------------------------------------------
function Options:InitInHeal(builder)
-----------------------------------------------------------------------------------------------
	local fontName = "nHealInFont"

	local color = builder:AddCategory("Color")
	color:AddElement(k_InitColor, "cHealInDefault",  "Normal",       fontName)
	color:AddElement(k_InitColor, "cHealInCrit",     "Critical",     fontName)
	color:AddElement(k_InitColor, "cHealInShield", 	 "Shield Heal",  fontName)

	local text = builder:AddCategory("Text")
	text:AddElement(k_InitFont, 	 fontName)
	text:AddElement(k_InitPosition,  "nHealInPos")
	text:AddElement(k_InitPattern,   "nHealInPattern")
	text:AddElement(k_InitCollision, "nHealInCollision")

	local scale = builder:AddCategory("Scale")
	scale:AddElement(k_InitSlider, "fHealInNormalScale", "Normal Scale")
	scale:AddElement(k_InitSlider, "fHealInCritScale", "Critical Scale")
	scale:AddElement(k_InitSlider, "fHealInDuration",  "Duration")

	local other = builder:AddCategory("Other")		
	other:AddElement(k_InitValue, "iHealInThreshold", "Don't show any healing under this threshold")

	return builder
end

-----------------------------------------------------------------------------------------------
function Options:InitOutHeal(builder)
-----------------------------------------------------------------------------------------------
	local fontName = "nHealOutFont"

	local color = builder:AddCategory("Color")
	color:AddElement(k_InitColor, "cHealDefault",  "Normal",       fontName) 
	color:AddElement(k_InitColor, "cHealCrit",     "Critical",     fontName)
	color:AddElement(k_InitColor, "cHealMultiHit", "Multi Hit",    fontName)
	color:AddElement(k_InitColor, "cHealShield",   "Shield Heal",  fontName) 

	local text = builder:AddCategory("Text")
	text:AddElement(k_InitFont, 	  fontName) 
	text:AddElement(k_InitPosition,  "nHealOutPos") 
	text:AddElement(k_InitPattern,   "nHealOutPattern")
	text:AddElement(k_InitCollision, "nHealOutCollision")

	local scale = builder:AddCategory("Scale")
	scale:AddElement(k_InitSlider, "fHealOutNormalScale", "Normal Scale") 
	scale:AddElement(k_InitSlider, "fHealOutCritScale",   "Critical Scale")

	local other = builder:AddCategory("Other")
	other:AddElement(k_InitValue,  "iHealOutThreshold",    "Don't show any healing under this threshold")

	return builder
end

-----------------------------------------------------------------------------------------------
function Options:InitOutDmg(builder)
-----------------------------------------------------------------------------------------------
	local fontName = "nDmgOutFont"

	local color = builder:AddCategory("Color")
	color:AddElement(k_InitColor, "cDmgDefault",   "Normal",        fontName) 
	color:AddElement(k_InitColor, "cDmgCrit",      "Critical",      fontName)
	color:AddElement(k_InitColor, "cDmgMultiHit",  "Multi Hit",     fontName)
	color:AddElement(k_InitColor, "cDmgVuln",      "Vulnerability", fontName) 
	color:AddElement(k_InitColor, "cDmgAbsorb",    "Absorb",        fontName)

	local text = builder:AddCategory("Text")
	text:AddElement(k_InitFont, 	  fontName) 
	text:AddElement(k_InitPosition,  "nDmgOutPos") 
	text:AddElement(k_InitPattern,   "nDmgOutPattern")
	text:AddElement(k_InitCollision, "nDmgOutCollision")

	local scale = builder:AddCategory("Scale")
	scale:AddElement(k_InitSlider, "fDmgOutNormalScale", "Normal Scale") 
	scale:AddElement(k_InitSlider, "fDmgOutCritScale",   "Critical Scale")
	scale:AddElement(k_InitSlider, "fDmgOutDuration",    "Duration", {0, 10.0, 0.05})

	local other = builder:AddCategory("Other")
	other:AddElement(k_InitValue,     "iDmgBigCritOutValue", "Emphasize crits above this value") 
	other:AddElement(k_InitValue,     "iDmgOutThreshold",    "Don't show any damage under this threshold")
	other:AddElement(k_InitOptionBox, "bDmgOutMergeShield",  "Merge shield and regular damage into one number") 
	other:AddElement(k_InitOptionBox, "bDmgOutShowAbsorb",   "Display absorbed damage differently than regular damage.")

	return builder
end

-----------------------------------------------------------------------------------------------
function Options:InitInDmg(builder)
-----------------------------------------------------------------------------------------------
	local fontName = "nDmgInFont"

	local color = builder:AddCategory("Color")
	color:AddElement(k_InitColor, "cDmgInDefault",  "Normal",    fontName) 
	color:AddElement(k_InitColor, "cDmgInCrit",     "Critical",  fontName) 
	color:AddElement(k_InitColor, "cDmgInAbsorb",   "Absorb",    fontName)

	local text = builder:AddCategory("Text")
	text:AddElement(k_InitFont, 	  fontName) 
	text:AddElement(k_InitPosition,  "nDmgInPos") 
	text:AddElement(k_InitPattern,   "nDmgInPattern")
	text:AddElement(k_InitCollision, "nDmgInCollision")

	local scale = builder:AddCategory("Scale")
	scale:AddElement(k_InitSlider, "fDmgInNormalScale", "Normal Scale") 
	scale:AddElement(k_InitSlider, "fDmgInCritScale",   "Critical Scale")
	scale:AddElement(k_InitSlider, "fDmgInDuration",    "Duration")

	return builder
end

-----------------------------------------------------------------------------------------------
function Options:InitGeneral(builder)
-----------------------------------------------------------------------------------------------
	local other = builder:AddCategory("Other")
	other:AddElement( k_InitOptionBox, "bShowZoneChange",     "Show zone changes.")
	other:AddElement( k_InitOptionBox, "bShowRealmBroadcast", "Show realm broadcasts.")

	return builder
end

-----------------------------------------------------------------------------------------------
-- Radio Group for options all have this as their callback
-----------------------------------------------------------------------------------------------
function Options:OnOptionSelected( wndHandler, wndControl, eMouseButton )
-----------------------------------------------------------------------------------------------
	self.parent.tSettings.currentCategory = wndHandler:GetData().func
	self:LoadCategory(self.parent.tSettings.currentCategory)
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
-- Helper function for loading an option box
-----------------------------------------------------------------------------------------------
function Options:LoadOptionBoxWidget(parentForm)
-----------------------------------------------------------------------------------------------
	return self:LoadWidget("OptionBoxWidget", parentForm, { "OptionBox", "Description" } )
end

-----------------------------------------------------------------------------------------------
-- Helper function for loading a value widget
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
function PrintTable(tbl)
---------------------------------------------------------------------------------------------------
	if type(tbl) ~= "table" then return end
	for k,v in pairs(tbl) do
		GoodPrint(k,"=",v)
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
	self.textParams[k_InitPattern].Max = table.getn(self.patternList)
	self.textParams[k_InitPattern].Idx = self:LookupIndex(self.patternList, self.parent.tSettings[setting])

	local tParams = {
		callback = function(nIdx)
			local pattern = self.patternList[nIdx]
			self.parent.tSettings[setting] = "Pattern"..pattern
			self.textParams[k_InitPattern].Widget.Current:SetText(pattern)
		end,
		name = k_InitPattern
	}

	local tWidget  = self:LoadListSelectionWidget(parentForm, tParams)
	local pattern  = self.parent.tSettings[setting]:gsub("Pattern", "")
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
	
	-- "ff" prepend because of alpha
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
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, 
									"Cannot open up color picker because you don't have the IronColorPicker addon!", 
									"IronCombatText")
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
