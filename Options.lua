require "CombatFloater"

local Options = {}
local IronCombatText = Apollo.GetAddon("IronCombatText")

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
	"Horizontal",
	"Vertical",
	"Ignore"
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
  "StraightDown"
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
	
	self.initFunctions = {
		OutDmg  = function() self:InitOutDmg()  end,
		InDmg   = function() self:InitInDmg()   end,
		InHeal  = function() self:InitInHeal()  end,
		OutHeal = function() self:InitOutHeal() end,
		General = function() self:InitGeneral() end,
	}
	
	self.parent = parent
	self.currentCategory = "OutHeal"
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
	self:LoadCategory(self.currentCategory)
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
	
	-- Global variables that are easy to re-init here and add later
	self.colorPreviews = {}
	self.textWidgets   = {}
	
	if self.options then
		self.initFunctions[categoryName]()
	else
		Apollo.AddAddonErrorText(self, "Unable to load category ".. categoryName)
	end

end

-----------------------------------------------------------------------------------------------
function Options:InitInHeal()
-----------------------------------------------------------------------------------------------
	local totalHeight    = 0
	local fontName       = "nHealInFont"
	local positionName   = "nHealInPos"
	local patternName    = "nHealInPattern"
	local collisionName  = "nHealInCollision"
	
	-- Load Color Widgets
	local content = self:LoadCategoryWidget(self.options, "Color", { top = -2, itemHeight = 70, numItems = 3, padding = 30 })
	totalHeight = totalHeight + content.Size
	self:InitColorWidget(content.Widget, "cHealInDefault",  "Normal",    fontName)
	self:InitColorWidget(content.Widget, "cHealInCrit",     "Critical",  fontName)
	self:InitColorWidget(content.Widget, "cHealInShield",   "Shield Heal",    fontName)
	content.Widget:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Middle)

	-- Load Text Widgets
	content = self:LoadCategoryWidget(self.options, "Text", { top = totalHeight, itemHeight = 70, numItems = 4, padding = 30 })
	totalHeight = totalHeight + content.Size
	self:InitFontWidget    (content.Widget, fontName, colorPreviews)
	self:InitPositionWidget(content.Widget, positionName)
	self:InitPatternWidget (content.Widget, patternName)
	self:InitCollisionWidget(content.Widget, collisionName)
	content.Widget:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Middle)
	
	-- Load Scale Widgets
	content = self:LoadCategoryWidget(self.options, "Scale", { top = totalHeight, itemHeight = 70, numItems = 2, padding = 30 })
	totalHeight = totalHeight + content.Size
	self:InitSliderWidget(content.Widget, "fHealInNormalScale", "Normal Scale")
	self:InitSliderWidget(content.Widget, "fHealInCritScale",   "Critical Scale")
	content.Widget:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Middle)
	
	content = self:LoadCategoryWidget(self.options, "Other", { top = totalHeight, itemHeight = 65, numItems = 1, padding = 30})
	totalHeight = totalHeight + content.Size
	self:InitValueWidget(content.Widget, "iHealInThreshold", "Don't show any healing under this threshold")
	content.Widget:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Middle)
	
	self.options:ArrangeChildrenTiles(0)
end


-----------------------------------------------------------------------------------------------
function Options:InitOutHeal()
-----------------------------------------------------------------------------------------------
	local totalHeight = 0
	local fontName    = "nHealOutFont"
	
	local content = self:LoadCategoryWidget(self.options, "Color", { top = -2, itemHeight = 70, numItems = 4, padding = 30 })
	totalHeight = totalHeight + content.Size
	self:InitColorWidget(content.Widget, "cHealDefault",   "Normal",      fontName)
	self:InitColorWidget(content.Widget, "cHealCrit",      "Critical",    fontName)
	self:InitColorWidget(content.Widget, "cHealMultiHit",  "Multi Hit",   fontName)
	self:InitColorWidget(content.Widget, "cHealShield",    "Shield Heal", fontName)
	content.Widget:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Middle)
	
	-- Init text widgets
	content = self:LoadCategoryWidget(self.options, "Text", { top = totalHeight, itemHeight = 70, numItems = 4, padding = 30 })
	totalHeight = totalHeight + content.Size
	self:InitFontWidget    (content.Widget, fontName, colorPreviews)
	self:InitPositionWidget(content.Widget, "nHealOutPos")
	self:InitPatternWidget (content.Widget, "nHealOutPattern")
	self:InitCollisionWidget(content.Widget, "nHealOutCollision")
	content.Widget:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Middle)

	
	content = self:LoadCategoryWidget(self.options, "Scale", { top = totalHeight, itemHeight = 70, numItems = 2, padding = 30 })
	totalHeight = totalHeight + content.Size
	self:InitSliderWidget(content.Widget, "fHealOutNormalScale", "Normal Scale")
	self:InitSliderWidget(content.Widget, "fHealOutCritScale",   "Critical Scale")
	content.Widget:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Middle)
	
	content = self:LoadCategoryWidget(self.options, "Other", { top = totalHeight, itemHeight = 65, numItems = 1, padding = 30})
	totalHeight = totalHeight + content.Size
	self:InitValueWidget(content.Widget, "iHealOutThreshold", "Don't show any healing under this threshold")
	content.Widget:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Middle)


	self.options:ArrangeChildrenTiles(0)
	
	--[[
	self.bigCritValue    = self.options:FindChild("BigCrit")
	self.fontList        = self.options:FindChild("FontList")
	self.fontButton      = self.options:FindChild("FontButton")
	self.posButton       = self.options:FindChild("PosButton")
	self.posList         = self.options:FindChild("PosList")
	self.font            = self.parent.tSettings.nHealOutFont
	
	-- Scale
	self.normalScale 	 = self.options:FindChild("NormScale")
	self.normalScalePrev = self.options:FindChild("NormScalePrev")
	self.critScale 		 = self.options:FindChild("CritScale")
	self.critScalePrev   = self.options:FindChild("CritScalePrev")
	
	self:InitScaleWidget{
		slider  = self.critScale,
		preview = self.critScalePrev,
		value = self.parent.tSettings.fHealOutCritScale,
		callback = function(value, formattedValue)
			self.parent.tSettings.fHealOutCritScale = value
			self.critScalePrev:SetText(formattedValue)
		end
	}
	
	self:InitScaleWidget{
		slider = self.normalScale,
		preview = self.normalScalePrev,
		value = self.parent.tSettings.fHealOutNormalScale,
		callback = function(value, formattedValue)
			self.parent.tSettings.fHealOutNormalScale = value
			self.normalScalePrev:SetText(formattedValue)
		end
	
	}
	
	self:InitValueWidget{
		editBox = self.bigCritValue,
		value = ("%05d"):format(self.parent.tSettings.iHealBigCritValue),
		callback = function(value)
			self.parent.tSettings.iHealBigCritValue = tonumber(value)
		end
	}
	--]]

end

-----------------------------------------------------------------------------------------------
function Options:InitOutDmg()
-----------------------------------------------------------------------------------------------
	local totalHeight = 0
	local fontName       = "nDmgOutFont"
	local positionName   = "nDmgOutPos"
	local patternName    = "nDmgOutPattern"
	local collisionName  = "nDmgOutCollision"
	
	-- Load Color Widgets
	local content = self:LoadCategoryWidget(self.options, "Color", { top = -2, itemHeight = 65, numItems = 5, padding = 30 })
	totalHeight = totalHeight + content.Size
	self:InitColorWidget(content.Widget, "cDmgDefault",  "Normal",        fontName)
	self:InitColorWidget(content.Widget, "cDmgCrit",     "Critical",      fontName)
	self:InitColorWidget(content.Widget, "cDmgMultiHit", "Multi Hit",     fontName)
	self:InitColorWidget(content.Widget, "cDmgVuln",     "Vulnerability", fontName)
	self:InitColorWidget(content.Widget, "cDmgAbsorb",   "Absorb",        fontName)
	content.Widget:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Middle)

	-- Load Text Widgets
	content = self:LoadCategoryWidget(self.options, "Text", { top = totalHeight, itemHeight = 70, numItems = 4, padding = 30 })
	totalHeight = totalHeight + content.Size
	self:InitFontWidget    (content.Widget, fontName, colorPreviews)
	self:InitPositionWidget(content.Widget, positionName)
	self:InitPatternWidget (content.Widget, patternName)
	self:InitCollisionWidget(content.Widget, collisionName)
	content.Widget:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Middle)
	
	-- Load Scale Widgets
	content = self:LoadCategoryWidget(self.options, "Scale", { top = totalHeight, itemHeight = 70, numItems = 3, padding = 30 })
	totalHeight = totalHeight + content.Size
	self:InitSliderWidget(content.Widget, "fDmgOutNormalScale", "Normal Scale")
	self:InitSliderWidget(content.Widget, "fDmgOutCritScale",   "Critical Scale")
	self:InitSliderWidget(content.Widget, "fDmgOutDuration", "Duration", {0, 10.0, 0.05})
	content.Widget:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Middle)
	
	content = self:LoadCategoryWidget(self.options, "Other", { top = totalHeight, itemHeight = 70, numItems = 4, padding = 0 } )
	self:InitValueWidget(content.Widget, "iDmgBigCritOutValue", "Emphasize crits above this value")
	self:InitValueWidget(content.Widget, "iDmgOutThreshold", "Don't show any damage under this threshold")
	self:InitOptionBoxWidget(content.Widget, "bDmgOutMergeShield", "Merge shield and regular damage into one number")
	self:InitOptionBoxWidget(content.Widget, "bDmgOutShowAbsorb", "Display absorbed damage differently than regular damage.")
	--self:InitOptionBoxWidget(content.Widget, "b
	totalHeight = totalHeight + content.Size
	content.Widget:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Middle)
	
	--content.Widget:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Middle)
	
	self.options:ArrangeChildrenTiles(0)
end

-----------------------------------------------------------------------------------------------
function Options:InitInDmg()
-----------------------------------------------------------------------------------------------
	local totalHeight = 0
	local fontName       = "nDmgInFont"
	local positionName   = "nDmgInPos"
	local patternName    = "nDmgInPattern"
	local collisionName  = "nDmgInCollision"
	
	-- Load Color Widgets
	local content = self:LoadCategoryWidget(self.options, "Color", { top = -2, itemHeight = 70, numItems = 3, padding = 30 })
	totalHeight = totalHeight + content.Size
	self:InitColorWidget(content.Widget, "cDmgInDefault",  "Normal",    fontName)
	self:InitColorWidget(content.Widget, "cDmgInCrit",     "Critical",  fontName)
	self:InitColorWidget(content.Widget, "cDmgInAbsorb",   "Absorb",    fontName)
	content.Widget:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Middle)

	-- Load Text Widgets
	content = self:LoadCategoryWidget(self.options, "Text", { top = totalHeight, itemHeight = 70, numItems = 4, padding = 30 })
	totalHeight = totalHeight + content.Size
	self:InitFontWidget    (content.Widget, fontName, colorPreviews)
	self:InitPositionWidget(content.Widget, positionName)
	self:InitPatternWidget (content.Widget, patternName)
	self:InitCollisionWidget(content.Widget, collisionName)
	content.Widget:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Middle)
	
	-- Load Scale Widgets
	content = self:LoadCategoryWidget(self.options, "Scale", { top = totalHeight, itemHeight = 70, numItems = 2, padding = 30 })
	totalHeight = totalHeight + content.Size
	self:InitSliderWidget(content.Widget, "fDmgInNormalScale", "Normal Scale")
	self:InitSliderWidget(content.Widget, "fDmgInCritScale",   "Critical Scale")
	content.Widget:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Middle)
	
	self.options:ArrangeChildrenTiles(0)
end

-----------------------------------------------------------------------------------------------
function Options:InitGeneral()
-----------------------------------------------------------------------------------------------
	self.messages = self.options:FindChild("Messages")
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
	tForms["Widget"] = widget
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
	return self:LoadWidget("ColorPickerWidget", parentForm, { "Preview", "Description", "Color" } )
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
function Options:LoadListSelectionWidget(parentForm)
-----------------------------------------------------------------------------------------------
	local tWidget = self:LoadWidget("ListSelectionWidget", parentForm, { "Description", "Current", "Inc", "Dec" } )
	
	-- Set show/hide on button toggle
	tWidget.Current:AddEventHandler("ButtonCheck", "ListButtonChecked")
	tWidget.Current:AddEventHandler("ButtonUncheck", "ListButtonChecked")
	tWidget.Inc:AddEventHandler("ButtonSignal", "OnListPosChanged")
	tWidget.Dec:AddEventHandler("ButtonSignal", "OnListPosChanged")
	table.insert(self.textWidgets, tWidget)
	return tWidget
end

-----------------------------------------------------------------------------------------------
-- ListWidget increment and decrement
-----------------------------------------------------------------------------------------------
function Options:OnListPosChanged(wndHandler, wndControl)
-----------------------------------------------------------------------------------------------
	local name = wndHandler:GetName()
	-- Ternary operator in lua makes no sense (this is backwards because of the way the lists are)
	local inc = (name == "Inc") and -1 or 1
	wndHandler:GetData().callback(inc)
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
function Options:InitFontWidget(parentForm, setting, previews)
-----------------------------------------------------------------------------------------------
	local tWidget = self:LoadListSelectionWidget(parentForm)
	tWidget.Description:SetText("Font")
	tWidget.Current:SetText("1234567890")
	tWidget.Current:SetFont(self.parent.tSettings[setting])
	tWidget.Current:SetData(self:LookupIndex(fontList, self.parent.tSettings[setting]))
	
	local tCallback = {
		callback = function(nInc)
			local listSize = table.getn(fontList)
			local idx = Clamp(nInc + tWidget.Current:GetData(), listSize, 1)
			local font = fontList[idx]
			tWidget.Current:SetFont(font)
			tWidget.Current:SetData(idx)
			
			-- Update the previews
			for idx, prev in ipairs(self.colorPreviews) do
				prev:SetFont(font)
			end
			
			self.parent.tSettings[setting] = font
		end
	}
	
	tWidget.Inc:SetData(tCallback)
	tWidget.Dec:SetData(tCallback)
end

-----------------------------------------------------------------------------------------------
function Options:InitPositionWidget(parentForm, setting)
-----------------------------------------------------------------------------------------------
	local tWidget    = self:LoadListSelectionWidget(parentForm)
	local strDisplay = self:LookupKeyed(posLookup, self.parent.tSettings[setting], "Display")
	tWidget.Description:SetText("Position")
	tWidget.Current:SetText(strDisplay)
	tWidget.Current:SetData(self:LookupIndex(posList, self.parent.tSettings[setting]))
	
	local tCallback = {
		callback = function(nInc)
			local listSize = table.getn(posList)
			local idx = Clamp(nInc + tWidget.Current:GetData(), listSize, 1)
			local pos = posList[idx]
			tWidget.Current:SetData(idx)
			
			self.parent.tSettings[setting] = self:LookupKeyed(posLookup, pos, "Value")
			tWidget.Current:SetText(pos)
		end
	}

	tWidget.Inc:SetData(tCallback)
	tWidget.Dec:SetData(tCallback)
end

-----------------------------------------------------------------------------------------------
function Options:InitPatternWidget(parentForm, setting)
-----------------------------------------------------------------------------------------------
	local tWidget = self:LoadListSelectionWidget(parentForm)
	local pattern = self.parent.tSettings[setting]
	tWidget.Description:SetText("Pattern")
	tWidget.Current:SetText(pattern)
	tWidget.Current:SetData(self:LookupIndex(patternList, self.parent.tSettings[setting]))
	
	local tCallback = {
		callback = function(nInc)
			local listSize = table.getn(patternList)
			local idx = Clamp(nInc + tWidget.Current:GetData(), listSize, 1)
			local pattern = patternList[idx]
			tWidget.Current:SetData(idx)
			
			self.parent.tSettings[setting] = pattern
			tWidget.Current:SetText(pattern)
		end
	}

	tWidget.Inc:SetData(tCallback)
	tWidget.Dec:SetData(tCallback)
end


-----------------------------------------------------------------------------------------------
function Options:InitCollisionWidget(parentForm, setting)
-----------------------------------------------------------------------------------------------
	local tWidget = self:LoadListSelectionWidget(parentForm)
	local coll 	  = self:LookupKeyed(collisionLookup, self.parent.tSettings[setting], "Display")
	tWidget.Description:SetText("Collision")
	tWidget.Current:SetText(coll)
	tWidget.Current:SetData(self:LookupIndex(patternList, self.parent.tSettings[setting]))
	
	local tCallback = {
		callback = function(nInc)
			local listSize = table.getn(collisionList)
			local idx = Clamp(nInc + tWidget.Current:GetData(), listSize, 1)
			local coll = collisionList[idx]
			tWidget.Current:SetData(idx)
			
			self.parent.tSettings[setting] = self:LookupKeyed(collisionLookup, coll, "Value")
			tWidget.Current:SetText(coll)
		end
	}

	tWidget.Inc:SetData(tCallback)
	tWidget.Dec:SetData(tCallback)
end

-----------------------------------------------------------------------------------------------
function Options:InitSliderWidget(parentForm, setting, description, tLimits, strTooltip)
-----------------------------------------------------------------------------------------------
	local tWidget = self:LoadSliderWidget(parentForm)
	local value   = self.parent.tSettings[setting]	
	tWidget.Description:SetText(description)
	tWidget.Preview:SetText(("%1.2f"):format(value))
	tWidget.Slider:AddEventHandler("SliderBarChanged", "OnSliderWidgetChanged")
	tWidget.Slider:SetValue(value)
	tWidget.Slider:SetData{
		preview = tWidget.Preview,
		setting = setting
	}
	if tLimits then
		tWidget.Slider:SetMinMax(tLimits[1], tLimits[2], tLimits[3])
	else
		tWidget.Slider:SetMinMax(0, 4, 0.05) -- Really fucking descriptive function name carbino SetMinMaxAndTickAndOtherThingsButWeWontTellYouInTheName
	end
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
	tWidget.Value:SetMaxTextLength(5)
	tWidget.Value:SetData{
		setting = setting
	}
	tWidget.Value:AddEventHandler("EditBoxChanged", "OnValueWidgetChanged")
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
		setting = setting
	}
	
	tWidget.Color:SetText(value)
	tWidget.Color:SetMaxTextLength(6)
	tWidget.Color:SetTextColor("FFFFFFFF")
	tWidget.Color:AddEventHandler("EditBoxChanged", "OnColorPickerWidgetEditBoxChanged")

	tWidget.Preview:SetTextColor("FF"..value)
	tWidget.Preview:SetFont(font)
	
	tWidget.Description:SetText(description)
	table.insert(self.colorPreviews, tWidget.Preview)
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
	self.parent.tSettings[data.setting] = tonumber(value, 16)
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
