require "CombatFloater"

local Patterns = {}
local IronCombatText = Apollo.GetAddon("IronCombatText")

---------------------------------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------------------------------
local k_White = 0xffffff
local k_FrameCount = 8
local k_HalfFrameCount = 4

---------------------------------------------------------------------------------------------------
-- Local Functions
---------------------------------------------------------------------------------------------------
local function step(nCurrent, nStep, funcBefore, funcAfter)
	return (nCurrent < nStep) and funcBefore or funcAfter 
end

local function linearDown(nCurrentStep, nStep, nMax)
	return (nMax - (nCurrentStep - nStep)/k_FrameCount) * nMax
end

---------------------------------------------------------------------------------------------------
function Patterns:Init(parent)
---------------------------------------------------------------------------------------------------
	Apollo.LinkAddon(parent, self)
	self.parent = parent
	self.tick = 0
end

---------------------------------------------------------------------------------------------------
function Patterns:GeneratePattern(strPatternName, tParams)
---------------------------------------------------------------------------------------------------
	self.tick = (self.tick + 15) % 360

	-- Set all of the variables that are the same for each pattern
	local tGenerated = self.parent:GetDefaultTextOption()
	tGenerated.bShowOnTop 		= true
	tGenerated.eCollisionMode 	= tParams.eCollisionMode
	tGenerated.strFontFace 		= tParams.strFontFace
	tGenerated.eLocation 		= tParams.eLocation
	tGenerated.arFrames = {}


	local fBigSize = tParams.fMaxSize * tParams.fBigScale

	-- Prepopulate these pattern fields, as they do not change between patterns
	for i = 0, k_FrameCount do
		tGenerated.arFrames[i+1] = 
		{
			-- On even frames, larger text if crit
			fScale 	= step(i, 1, tParams.fMaxSize * 0.5, i % 2 == 0 and tParams.fMaxSize or fBigSize),
			-- Each frame is an equal fraction of max duration
			fTime 	= (i/k_FrameCount) * tParams.fMaxDuration,
			-- Decrease alpha to zero starting at frame 5
			fAlpha 	= linearDown(i, 5, 1),
			-- White for 1 frame, then base color
			nColor = step(i, 1, k_White, tParams.nBaseColor)
		}
	end
	
	return self[strPatternName](self, tParams, tGenerated)
end

---------------------------------------------------------------------------------------------------
--          123    123   
--      123             123
--               X
--      123             123
--          123     123
---------------------------------------------------------------------------------------------------
function Patterns:PatternSprinkler(tParams, tGenerated)
---------------------------------------------------------------------------------------------------
	tGenerated.fOffsetDirection = self.tick
	tGenerated.fOffset 		 	= 2

	for i = 0, k_FrameCount do
		tGenerated.arFrames[i+1].fVelocityDirection = tGenerated.fOffsetDirection
		tGenerated.arFrames[i+1].fVelocityMagnitude = step(i, 2, 6, step(i, 6, 1, 6))
	end

	return tGenerated
end

---------------------------------------------------------------------------------------------------
--       ^ 123  123  123 ^
--       |  123    123   |
--               X
---------------------------------------------------------------------------------------------------
function Patterns:PatternDefault(tParams, tGenerated)
---------------------------------------------------------------------------------------------------
	tGenerated.fOffsetDirection = math.random(0, 100) - 50
	tGenerated.fOffset 	     	= 0
	local speed = tParams.fBigScale > 1 and 10 or 6

	for i = 0, k_FrameCount do
		tGenerated.arFrames[i+1].fVelocityDirection = tGenerated.fOffsetDirection
		tGenerated.arFrames[i+1].fVelocityMagnitude = step(i, 2, speed, step(i, 5, 1, 6))
	end
	return tGenerated
end

---------------------------------------------------------------------------------------------------
function Patterns:PatternPopup(tParams, tGenerated)
---------------------------------------------------------------------------------------------------
	tGenerated.fOffsetDirection = 90
	tGenerated.fOffset 			= math.random(0,8) - 4
	local s1 = math.random(8, 10)

	for i = 0, k_FrameCount do
		tGenerated.arFrames[i+1].fVelocityDirection = step(i, 6, 0, 180)
		tGenerated.arFrames[i+1].fVelocityMagnitude = step(i, 2, s1, step(i, 6, 1, 6))
	end

	return tGenerated
end

---------------------------------------------------------------------------------------------------
--              123
--               123
--                123 
--           X     123  ^
--                123   |
--              123     |
---------------------------------------------------------------------------------------------------
function Patterns:PatternStreamUpRight(tParams, tGenerated)
---------------------------------------------------------------------------------------------------
	tGenerated.fOffsetDirection = math.random(200,210) -- 5 o'clock
	tGenerated.fOffset 		 	= 3
	local speed = tParams.fBigScale > 1.1 and 10 or 6

	for i = 0, k_FrameCount do
		tGenerated.arFrames[i+1].fVelocityDirection = step(i, k_HalfFrameCount, -20, 20)
		tGenerated.arFrames[i+1].fVelocityMagnitude = step(i, 2, speed, step(i, 5, 2, 6))
	end
	return tGenerated
end

---------------------------------------------------------------------------------------------------
--              123     |
--               123    |
--                123   v
--           X     123  
--                123   
--              123     
---------------------------------------------------------------------------------------------------
function Patterns:PatternStreamDownRight(tParams, tGenerated)
---------------------------------------------------------------------------------------------------
	tGenerated.fOffsetDirection = math.random(330,340) -- 5 o'clock
	tGenerated.fOffset 		 	= 2
	local speed = tParams.fBigScale > 1 and 10 or 6

	for i = 0, k_FrameCount do
		tGenerated.arFrames[i+1].fVelocityDirection = step(i, k_HalfFrameCount, 200, -200)
		tGenerated.arFrames[i+1].fVelocityMagnitude = step(i, 2, speed, step(i, 5, 1, 6))
	end
	return tGenerated
end

---------------------------------------------------------------------------------------------------
function Patterns:PatternStreamDownLeft(tParams, tGenerated)
---------------------------------------------------------------------------------------------------
	tGenerated.fOffsetDirection = math.random(20,30) -- 5 o'clock
	tGenerated.fOffset 		 	= 2
	local speed = tParams.fBigScale > 1 and 10 or 6

	for i = 0, k_FrameCount do
		tGenerated.arFrames[i+1].fVelocityDirection = step(i, k_HalfFrameCount, 160, -160)
		tGenerated.arFrames[i+1].fVelocityMagnitude = step(i, 2, speed, step(i, 5, 1, 6))
	end
	return tGenerated
end

---------------------------------------------------------------------------------------------------
function Patterns:PatternStreamUpLeft(tParams, tGenerated)
---------------------------------------------------------------------------------------------------
	tGenerated.fOffsetDirection = math.random(150,160) -- 5 o'clock
	tGenerated.fOffset 		 	= 2
	local speed = tParams.fBigScale > 1 and 10 or 6

	for i = 0, k_FrameCount do
		tGenerated.arFrames[i+1].fVelocityDirection = step(i, k_HalfFrameCount, 20, -20)
		tGenerated.arFrames[i+1].fVelocityMagnitude = step(i, 2, speed, step(i, 5, 1, 6))
	end
	return tGenerated
end


---------------------------------------------------------------------------------------------------
function Patterns:PatternStraightUp(tParams, tGenerated)
---------------------------------------------------------------------------------------------------
	tGenerated.fOffsetDirection = 90
	tGenerated.fOffset 			= math.random(0,6) - 3

	local speed = tParams.fBigScale > 1 and 10 or 6

	for i = 0, k_FrameCount do
		tGenerated.arFrames[i+1].fVelocityDirection = 0
		tGenerated.arFrames[i+1].fVelocityMagnitude = step(i, 2, speed, step(i, 6, 2, 6))
	end
	return tGenerated
end

---------------------------------------------------------------------------------------------------
function Patterns:PatternStraightDown(tParams, tGenerated)
---------------------------------------------------------------------------------------------------
	tGenerated.fOffsetDirection = 90
	tGenerated.fOffset 			= math.random(0,8) - 4

	local speed = tParams.fBigScale > 1 and 10 or 6

	for i = 0, k_FrameCount do
		tGenerated.arFrames[i+1].fVelocityDirection = 180
		tGenerated.arFrames[i+1].fVelocityMagnitude = step(i, 2, speed, step(i, 6, 2, 6))
	end
	return tGenerated
end

---------------------------------------------------------------------------------------------------
-- Set the Patterns for IronCombatText
---------------------------------------------------------------------------------------------------
IronCombatText.Patterns = Patterns
---------------------------------------------------------------------------------------------------
