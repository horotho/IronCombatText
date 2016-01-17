local Utils = {}
local IronCombatText = Apollo.GetAddon("IronCombatText")

---------------------------------------------------------------------------------------------------
function Utils:Init(parent)
---------------------------------------------------------------------------------------------------
	Apollo.LinkAddon(parent, self)
end

---------------------------------------------------------------------------------------------------
function Utils:GoodPrint(...)
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
function Utils:PrintAnchors(anchors)
---------------------------------------------------------------------------------------------------
	--local left, top, right, bottom = anchors.Left, anchors.Top, anchors.Right, anchors.Bottom
	--self:GoodPrint(": [ left=", left, ", top=", top, ", right=", right, ", bot=", bottom, " ]")
end


---------------------------------------------------------------------------------------------------
function Utils:PrintObject(o, filter)
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
function Utils:PrintTable(tb)
---------------------------------------------------------------------------------------------------
	for key,value in pairs(tb) do
		GoodPrint(type(value), ", ", key, "=", value)

		if type(value) == "userdata" and key == "splCallingSpell" then
			GoodPrint(value:GetName())
		end
	end
end

IronCombatText.Utils = Utils