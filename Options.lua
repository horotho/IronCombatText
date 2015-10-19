local Options = {}
local IronCombatText = Apollo.GetAddon("IronCombatText")

-----------------------------------------------------------------------------------------------
-- Init Function
-----------------------------------------------------------------------------------------------
function Options:Init(parent)
-----------------------------------------------------------------------------------------------
	Apollo.LinkAddon(parent, self)
	Apollo.RegisterSlashCommand("ict", "OnInvokeOptions", self)
	
	self.parent = parent
		
	self.xmlDoc = XmlDoc.CreateFromFile("OptionsPanel.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	
	self.initFunctions = {
		OutDmg  = function() self:InitOutDmg()  end,
		InDmg   = function() self:InitInDmg()   end,
		InHeal  = function() self:InitInHeal()  end,
		OutHeal = function() self:InitOutHeal() end,
		General = function() self:InitGeneral() end,
	}

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
		self.currentCategory = "General"
		self:LoadCategory(self.currentCategory)
	
			
		-- Do additional Addon initialization here
	end	
end

-----------------------------------------------------------------------------------------------
-- Options OnInvokeOptions
-----------------------------------------------------------------------------------------------
function Options:OnInvokeOptions()
-----------------------------------------------------------------------------------------------
	self.wndMain:Invoke()
	self:LoadCategory(self.currentCategory)
end


-----------------------------------------------------------------------------------------------
-- InitFontWidget
-- Initializes the font widget.
-----------------------------------------------------------------------------------------------
function Options:InitFontWidget(data)
-----------------------------------------------------------------------------------------------
	data.fontList:SetData{
		callback = data.callback
	}
	data.fontButton:SetFont(data.value)
	local selected = data.fontList:FindChild(data.value)
	selected:SetCheck(true)
end

-----------------------------------------------------------------------------------------------
-- OnFontSelected
-- Forwards the button checked to the callback. The name of the button
-- corresponds to the string font.
-----------------------------------------------------------------------------------------------
function Options:OnFontSelected( wndHandler, wndControl, eMouseButton )
---------------------------------------------------------------------------------------------------
	local parent = wndHandler:GetParent()
	local font   = wndHandler:GetName()
	parent:GetData().callback(font)
end


---------------------------------------------------------------------------------------------------
-- OnFontPanelToggle
-- Callback that occurs when the font button is pressed.
-- Brings up the font list.
---------------------------------------------------------------------------------------------------
function Options:OnTextPanelToggle( wndHandler, wndControl, eMouseButton )
-----------------------------------------------------------------------------------------------
	local check = wndHandler:IsChecked()
	local name = wndHandler:GetName()
	self.fontList = self.wndMain:FindChild("FontList")
	self.posList  = self.wndMain:FindChild("PosList")
	
	if check == true then
		if name == "FontButton" then
			self.fontList:Show(true, true)
			self.posList:Close()
		elseif name == "PosButton" then
			self.posList:Show(true, true)
			self.fontList:Close()
		end
	else
		self.fontList:Close()
		self.posList:Close()
	end
	
end

-----------------------------------------------------------------------------------------------
-- InitPositionWidget
-- Initializes the font widget.
-----------------------------------------------------------------------------------------------
function Options:InitPositionWidget(data)
-----------------------------------------------------------------------------------------------
	data.posList:SetData{
		callback = data.callback
	}
	local selected = data.posList:FindChild(data.value)
	selected:SetCheck(true)
end

-----------------------------------------------------------------------------------------------
-- PositionSelected
-- Forwards the button checked to the callback. The name of the button
-- corresponds to the string font.
-----------------------------------------------------------------------------------------------
function Options:OnPositionSelected( wndHandler, wndControl, eMouseButton )
---------------------------------------------------------------------------------------------------
	local parent = wndHandler:GetParent()
	local pos    = wndHandler:GetName()
	parent:GetData().callback(pos)
end

-----------------------------------------------------------------------------------------------
-- Color selection with preview
-----------------------------------------------------------------------------------------------
function Options:InitColorWidget(data)
-----------------------------------------------------------------------------------------------
	data.editBox:SetData{
		callback = data.callback
	}
	data.editBox:SetText(data.value)
	data.editBox:SetMaxTextLength(6)
	data.editBox:SetTextColor("FFFFFFFF")
	data.preview:SetTextColor("ff"..data.value)
	data.preview:SetFont(data.font)
	data.editBox:AddEventHandler("EditBoxChanged", "OnColorWidgetEditBoxChanged")
end

-----------------------------------------------------------------------------------------------
-- Whenever a color widget reaches max length
-----------------------------------------------------------------------------------------------
function Options:OnColorWidgetEditBoxChanged(wndHandler, wndControl)
-----------------------------------------------------------------------------------------------
	local text = wndHandler:GetText()
	local value = tonumber(text, 16) and text:len() == 6 and text or "ffffff"
	wndHandler:GetData().callback(value)
end

-----------------------------------------------------------------------------------------------
-- Regular value selection without preview
-----------------------------------------------------------------------------------------------
function Options:InitValueWidget(data)
-----------------------------------------------------------------------------------------------
	data.editBox:SetData{
		callback = data.callback
	}
	data.editBox:SetText(data.value)
	data.editBox:SetMaxTextLength(5)
end

-----------------------------------------------------------------------------------------------
-- Regular floating point value selection without preview
-----------------------------------------------------------------------------------------------
function Options:InitFloatValueWidget(data)
-----------------------------------------------------------------------------------------------
	data.editBox:SetData{
		callback = data.callback
	}
	data.editBox:SetText(data.value)
	data.editBox:SetMaxTextLength(4)
	data.editBox:AddEventHandler("EditBoxChanged", "OnFloatWidgetEditBoxChanged")
end

-----------------------------------------------------------------------------------------------
function Options:OnFloatWidgetEditBoxChanged(wndHandler, wndControl)
-----------------------------------------------------------------------------------------------
	local text = wndHandler:GetText()
	local value = tonumber(text) and text:len() <= 5 and text or 10000
	wndHandler:GetData().callback(value)
end

-----------------------------------------------------------------------------------------------
-- Scale slider
-----------------------------------------------------------------------------------------------
function Options:InitScaleWidget(data)
-----------------------------------------------------------------------------------------------
	data.slider:SetData{
		callback = data.callback,
		preview = data.preview
	}
	
	data.preview:SetText(("%1.2f"):format(data.value))
	data.slider:AddEventHandler("SliderBarChanged", "OnSliderChanged")
	data.slider:SetValue(data.value)
end

-----------------------------------------------------------------------------------------------
function Options:OnSliderChanged(wndHandler, wndControl, nValue, nOldValue)
-----------------------------------------------------------------------------------------------
	formatted = ("%1.2f"):format(nValue)
	wndHandler:GetData().callback(nValue, formatted)
end

-----------------------------------------------------------------------------------------------
-- Radio Group for options all have this as their callback
-----------------------------------------------------------------------------------------------
function Options:OnOptionSelected( wndHandler, wndControl, eMouseButton )
-----------------------------------------------------------------------------------------------
	self:LoadCategory(wndHandler:GetName():gsub("%s", ""))
end

-----------------------------------------------------------------------------------------------
function Options:OnClose( wndHandler, wndControl, eMouseButton )
-----------------------------------------------------------------------------------------------
	self.wndMain:Close()
end

-----------------------------------------------------------------------------------------------
-- Loads a category when a radio button is pressed on the main options screen.
-----------------------------------------------------------------------------------------------
function Options:LoadCategory(categoryName)
-----------------------------------------------------------------------------------------------
	self.currentCategory = categoryName
	self.currentButton = self.wndMain:FindChild(self.currentCategory)
	self.currentButton:SetCheck(true)
	self.content:DestroyChildren()
	self.options = Apollo.LoadForm(self.xmlDoc, "Options" .. categoryName, self.content, self)
	
	if self.options then
		self.initFunctions[categoryName]()
		return true
	else
		return false
	end

end

-----------------------------------------------------------------------------------------------
function Options:InitInHeal()
-----------------------------------------------------------------------------------------------
	self.normalPreview	 = self.options:FindChild("NormPrev")
	self.normalColor 	 = self.options:FindChild("NormColor")
	self.critPreview 	 = self.options:FindChild("CritPrev")
	self.critColor 		 = self.options:FindChild("CritColor")
	self.normalScale 	 = self.options:FindChild("NormScale")
	self.critScale 		 = self.options:FindChild("CritScale")
	self.shieldHealPrev  = self.options:FindChild("ShieldHealPrev")
	self.shieldHealColor = self.options:FindChild("ShieldHealColor")
	self.bigCritValue    = self.options:FindChild("BigCrit")
	self.fontList        = self.options:FindChild("FontList")
	self.fontButton      = self.options:FindChild("FontButton")
	self.positionButton  = self.options:FindChild("PosButton")
	self.posList         = self.options:FindChild("PosList")
	self.previews        = { self.normalPreview, self.critPreview, self.shieldHealPrev }
	self.font            = self.parent.tSettings.nHealInFont
	
	-- Scale
	self.normalScale 	  = self.options:FindChild("NormScale")
	self.normalScalePrev  = self.options:FindChild("NormScalePrev")
	self.critScale 		  = self.options:FindChild("CritScale")
	self.critScalePrev    = self.options:FindChild("CritScalePrev")
	
	self:InitScaleWidget{
		slider  = self.critScale,
		preview = self.critScalePrev,
		value = self.parent.tSettings.fHealInCritScale,
		callback = function(value, formattedValue)
			self.parent.tSettings.fHealInCritScale = value
			self.critScalePrev:SetText(formattedValue)
		end
	}
	
	self:InitScaleWidget{
		slider = self.normalScale,
		preview = self.normalScalePrev,
		value = self.parent.tSettings.fHealInNormalScale,
		callback = function(value, formattedValue)
			self.parent.tSettings.fHealInNormalScale = value
			self.normalScalePrev:SetText(formattedValue)
		end
	}

	self:InitColorWidget{
		editBox = self.critColor,
		preview = self.critPreview,
		value = ("%06x"):format(self.parent.tSettings.cHealInCrit),
		font = self.font,
		callback = function (value)
			self.critPreview:SetTextColor("ff"..value)
			self.parent.tSettings.cHealInCrit = tonumber(value, 16)
		end
	}
	
	self:InitColorWidget{
		editBox = self.normalColor,
		preview = self.normalPreview,
		value = ("%06x"):format(self.parent.tSettings.cHealInDefault),
		font = self.font,
		callback = function (value)
			self.normalPreview:SetTextColor("ff"..value)
			self.parent.tSettings.cHealInDefault = tonumber(value, 16)
		end
	}
	
	self:InitColorWidget{
		editBox = self.shieldHealColor,
		preview = self.shieldHealPrev,
		value = ("%06x"):format(self.parent.tSettings.cHealInShield),
		font = self.font,
		callback = function (value)
			self.shieldHealPrev:SetTextColor("ff"..value)
			self.parent.tSettings.cHealInShield = tonumber(value, 16)
		end
	}
	
	self:InitValueWidget{
		editBox = self.bigCritValue,
		value = ("%05d"):format(self.parent.tSettings.iHealInBigCritValue),
		callback = function(value)
			self.parent.tSettings.iHealInBigCritValue = tonumber(value)
		end
	}	
	
	self:InitFontWidget{
		fontList = self.fontList,
		fontButton = self.fontButton,
		value = self.parent.tSettings.nHealInFont,
		callback = function(value)
			self.parent.tSettings.nHealInFont = value
			self.fontButton:SetFont(value)
			for i, preview in ipairs(self.previews) do
				preview:SetFont(value)
			end
		end
	}
	
	self:InitPositionWidget{
		posList = self.posList,
		posButton = self.posButton,
		value = "Head",
		callback = function(value)
			self.posButton:SetText(value)
		end
	}

end

-----------------------------------------------------------------------------------------------
function Options:InitGeneral()
-----------------------------------------------------------------------------------------------


end

-----------------------------------------------------------------------------------------------
function Options:InitOutHeal()
-----------------------------------------------------------------------------------------------
	self.normalPreview	 = self.options:FindChild("NormPrev")
	self.normalColor 	 = self.options:FindChild("NormColor")
	self.critPreview 	 = self.options:FindChild("CritPrev")
	self.critColor 		 = self.options:FindChild("CritColor")

	self.multiHitPrev    = self.options:FindChild("MultiHitPrev")
	self.multiHitColor   = self.options:FindChild("MultiHitColor")
	self.shieldHealPrev  = self.options:FindChild("ShieldHealPrev")
	self.shieldHealColor = self.options:FindChild("ShieldHealColor")
	self.bigCritValue    = self.options:FindChild("BigCrit")
	self.fontList        = self.options:FindChild("FontList")
	self.fontButton      = self.options:FindChild("FontButton")
	self.posButton       = self.options:FindChild("PosButton")
	self.posList         = self.options:FindChild("PosList")
	self.previews        = { self.normalPreview, self.critPreview, self.multiHitPrev, self.shieldHealPrev }
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

	self:InitColorWidget{
		editBox = self.multiHitColor,
		preview = self.multiHitPrev,
		value = ("%06x"):format(self.parent.tSettings.cHealMultiHit),
		font = self.font,
		callback = function (value)
			self.multiHitPrev:SetTextColor("ff"..value)
			self.parent.tSettings.cHealMultiHit = tonumber(value, 16)
		end
	}
	
	self:InitColorWidget{
		editBox = self.critColor,
		preview = self.critPreview,
		value = ("%06x"):format(self.parent.tSettings.cHealCrit),
		font = self.font,
		callback = function (value)
			self.critPreview:SetTextColor("ff"..value)
			self.parent.tSettings.cHealCrit = tonumber(value, 16)
		end
	}
	
	self:InitColorWidget{
		editBox = self.normalColor,
		preview = self.normalPreview,
		value = ("%06x"):format(self.parent.tSettings.cHealDefault),
		font = self.font,
		callback = function (value)
			self.normalPreview:SetTextColor("ff"..value)
			self.parent.tSettings.cHealDefault = tonumber(value, 16)
		end
	}
	
	self:InitColorWidget{
		editBox = self.shieldHealColor,
		preview = self.shieldHealPrev,
		value = ("%06x"):format(self.parent.tSettings.cHealShield),
		font = self.font,
		callback = function (value)
			self.shieldHealPrev:SetTextColor("ff"..value)
			self.parent.tSettings.cHealShield = tonumber(value, 16)
		end
	}
	
	self:InitValueWidget{
		editBox = self.bigCritValue,
		value = ("%05d"):format(self.parent.tSettings.iHealBigCritValue),
		callback = function(value)
			self.parent.tSettings.iHealBigCritValue = tonumber(value)
		end
	}
	
	self:InitFontWidget{
		fontList = self.fontList,
		fontButton = self.fontButton,
		value = self.parent.tSettings.nHealOutFont,
		callback = function(value)
			self.parent.tSettings.nHealOutFont = value
			for i, preview in ipairs(self.previews) do
				preview:SetFont(value)
			end
		end
	}
	
	self:InitPositionWidget{
		posList = self.posList,
		posButton = self.posButton,
		value = "Head",
		callback = function(value)
			self.posButton:SetText(value)
		end
	}

end

-----------------------------------------------------------------------------------------------
function Options:InitOutDmg()
-----------------------------------------------------------------------------------------------
	self.normalPreview	 = self.options:FindChild("NormPrev")
	self.normalColor 	 = self.options:FindChild("NormColor")
	self.vulnPreview     = self.options:FindChild("VulnPrev")
	self.vulnColor       = self.options:FindChild("VulnColor")
	self.critPreview 	 = self.options:FindChild("CritPrev")
	self.critColor 		 = self.options:FindChild("CritColor")
	self.normalScale 	 = self.options:FindChild("NormScale")
	self.critScale 		 = self.options:FindChild("CritScale")
	self.multiHitPreview = self.options:FindChild("MultiHitPrev")
	self.multiHitColor   = self.options:FindChild("MultiHitColor")
	self.bigCritValue    = self.options:FindChild("BigCrit")
	self.fontList        = self.options:FindChild("FontList")
	self.fontButton      = self.options:FindChild("FontButton")
	self.posList         = self.options:FindChild("PosList")
	self.posButton       = self.options:FindChild("PosButton")
	self.previews        = { self.normalPreview, self.critPreview, self.multiHitPreview, self.vulnPreview }
	self.font            = self.parent.tSettings.nDmgOutFont
	
	-- Scale
	self.normalScale 	 = self.options:FindChild("NormScale")
	self.normalScalePrev = self.options:FindChild("NormScalePrev")
	self.critScale 		 = self.options:FindChild("CritScale")
	self.critScalePrev   = self.options:FindChild("CritScalePrev")
	
	self:InitScaleWidget{
		slider  = self.critScale,
		preview = self.critScalePrev,
		value = self.parent.tSettings.fDmgOutCritScale,
		callback = function(value, formattedValue)
			self.parent.tSettings.fDmgOutCritScale = value
			self.critScalePrev:SetText(formattedValue)
		end
	}
	
	self:InitScaleWidget{
		slider = self.normalScale,
		preview = self.normalScalePrev,
		value = self.parent.tSettings.fDmgOutNormalScale,
		callback = function(value, formattedValue)
			self.parent.tSettings.fDmgOutNormalScale = value
			self.normalScalePrev:SetText(formattedValue)
		end	
	}	
	
	self:InitColorWidget{
		editBox = self.vulnColor,
		preview = self.vulnPreview,
		value = ("%06x"):format(self.parent.tSettings.cDmgVuln),
		font = self.font,
		callback = function (value)
			self.vulnPreview:SetTextColor("ff"..value)
			self.parent.tSettings.cDmgVuln = tonumber(value, 16)
		end
	}

	self:InitColorWidget{
		editBox = self.multiHitColor,
		preview = self.multiHitPreview,
		value = ("%06x"):format(self.parent.tSettings.cDmgMultiHit),
		font = self.font,
		callback = function (value)
			self.multiHitPreview:SetTextColor("ff"..value)
			self.parent.tSettings.cDmgMultiHit = tonumber(value, 16)
		end
	}
	
	self:InitColorWidget{
		editBox = self.critColor,
		preview = self.critPreview,
		value = ("%06x"):format(self.parent.tSettings.cDmgCrit),
		font = self.font,
		callback = function (value)
			self.critPreview:SetTextColor("ff"..value)
			self.parent.tSettings.cDmgCrit = tonumber(value, 16)
		end
	}
	
	self:InitColorWidget{
		editBox = self.normalColor,
		preview = self.normalPreview,
		value = ("%06x"):format(self.parent.tSettings.cDmgDefault),
		font = self.font,
		callback = function (value)
			self.normalPreview:SetTextColor("ff"..value)
			self.parent.tSettings.cDmgDefault = tonumber(value, 16)
		end
	}
	
	self:InitValueWidget{
		editBox = self.bigCritValue,
		value = ("%05d"):format(self.parent.tSettings.iDmgBigCritOutValue),
		callback = function(value)
			self.parent.tSettings.iDmgBigCritOutValue = tonumber(value)
		end
	}
	
		
	self:InitFontWidget{
		fontList = self.fontList,
		fontButton = self.fontButton,
		value = self.parent.tSettings.nDmgOutFont,
		callback = function(value)
			self.parent.tSettings.nDmgOutFont = value
			for i, preview in ipairs(self.previews) do
				preview:SetFont(value)
			end
		end
	}
	
	self:InitPositionWidget{
		posList = self.posList,
		posButton = self.posButton,
		value = "Head",
		callback = function(value)
			self.posButton:SetText(value)
		end
	}
	
end

-----------------------------------------------------------------------------------------------
function Options:InitInDmg()
-----------------------------------------------------------------------------------------------
	self.normalPreview	 = self.options:FindChild("NormPrev")
	self.normalColor 	 = self.options:FindChild("NormColor")
	self.critPreview 	 = self.options:FindChild("CritPrev")
	self.critColor 		 = self.options:FindChild("CritColor")
	self.absorbColor     = self.options:FindChild("AbsorbColor")
	self.absorbPreview   = self.options:FindChild("AbsorbPrev")
	self.bigCritValue    = self.options:FindChild("BigCrit")
	self.fontList        = self.options:FindChild("FontList")
	self.fontButton      = self.options:FindChild("FontButton")
	self.posList         = self.options:FindChild("PosList")
	self.posButton       = self.options:FindChild("PosButton")
	self.previews        = { self.normalPreview, self.critPreview, self.absorbPreview }
	self.font            = self.parent.tSettings.nDmgInFont
	
	-- Scale
	self.normalScale 	 = self.options:FindChild("NormScale")
	self.normalScalePrev = self.options:FindChild("NormScalePrev")
	self.critScale 		 = self.options:FindChild("CritScale")
	self.critScalePrev   = self.options:FindChild("CritScalePrev")

	self:InitColorWidget{
		editBox = self.critColor,
		preview = self.critPreview,
		value = ("%06x"):format(self.parent.tSettings.cDmgInCrit),
		font = self.font,
		callback = function (value)
			self.critPreview:SetTextColor("ff"..value)
			self.parent.tSettings.cDmgInCrit = tonumber(value, 16)
		end
	}
	
	self:InitColorWidget{
		editBox = self.normalColor,
		preview = self.normalPreview,
		value = ("%06x"):format(self.parent.tSettings.cDmgInDefault),
		font = self.font,
		callback = function (value)
			self.normalPreview:SetTextColor("ff"..value)
			self.parent.tSettings.cDmgInDefault = tonumber(value, 16)
		end
	}
	
	self:InitColorWidget{
		editBox = self.absorbColor,
		preview = self.absorbPreview,
		value = ("%06x"):format(self.parent.tSettings.cDmgInAbsorb),
		font = self.font,
		callback = function (value)
			self.absorbPreview:SetTextColor("ff"..value)
			self.parent.tSettings.cDmgInAbsorb = tonumber(value, 16)
		end
	}
	
	self:InitValueWidget{
		editBox = self.bigCritValue,
		value = ("%05d"):format(self.parent.tSettings.iDmgBigCritInValue),
		callback = function(value)
			self.parent.tSettings.iDmgBigCritInValue = tonumber(value)
		end
	}
	
	self:InitScaleWidget{
		slider  = self.critScale,
		preview = self.critScalePrev,
		value = self.parent.tSettings.fDmgInCritScale,
		callback = function(value, formattedValue)
			self.parent.tSettings.fDmgInCritScale = value
			self.critScalePrev:SetText(formattedValue)
		end
	}
	
	self:InitScaleWidget{
		slider = self.normalScale,
		preview = self.normalScalePrev,
		value = self.parent.tSettings.fDmgInNormalScale,
		callback = function(value, formattedValue)
			self.parent.tSettings.fDmgInNormalScale = value
			self.normalScalePrev:SetText(formattedValue)
		end
	
	}	
	
	self:InitFontWidget{
		fontList = self.fontList,
		fontButton = self.fontButton,
		value = self.parent.tSettings.nDmgInFont,
		previews = self.previews,
		callback = function(value)
			self.parent.tSettings.nDmgInFont = value
			for i, preview in ipairs(self.previews) do
				preview:SetFont(value)
			end
		end
	}
	
	self:InitPositionWidget{
		posList = self.posList,
		posButton = self.posButton,
		value = "Head",
		callback = function(value)
			self.posButton:SetText(value)
		end
	}

end

IronCombatText.Options = Options