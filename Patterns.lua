require "CombatFloater"

local Patterns = {}
local IronCombatText = Apollo.GetAddon("IronCombatText")

local tPatterns = 
{
	Circular        = function(...) return Patterns:PatternCircular        (...) end,
	Default         = function(...) return Patterns:PatternDefault         (...) end,
	StreamUpRight   = function(...) return Patterns:PatternStreamUpRight   (...) end,
	StreamDownRight = function(...) return Patterns:PatternStreamDownRight (...) end,
	StreamUpLeft    = function(...) return Patterns:PatternStreamUpLeft    (...) end,
	StreamDownLeft  = function(...) return Patterns:PatternStreamDownLeft  (...) end,
	StraightUp      = function(...) return Patterns:PatternStraightUp      (...) end,
	StraightDown    = function(...) return Patterns:PatternStraightDown    (...) end,
	Test            = function(...) return Patterns:PatternTest            (...) end,
}

---------------------------------------------------------------------------------------------------
function Patterns:Init(parent)
---------------------------------------------------------------------------------------------------
	Apollo.LinkAddon(parent, self)
	self.parent = parent
end

---------------------------------------------------------------------------------------------------
function Patterns:GeneratePattern(strPatternName, tParams)
---------------------------------------------------------------------------------------------------
	local tGenerated = self.parent:GetDefaultTextOption()
	tGenerated.bShowOnTop 		= true
	tGenerated.eCollisionMode 	= tParams.eCollisionMode
	tGenerated.strFontFace 		= tParams.strFontFace
	tGenerated.eLocation 		= tParams.eLocation
	return tPatterns[strPatternName](tParams, tGenerated)
end


local function GrowToMax(nTime, nMax)
	return (nTime < 4) and (nMax * math.log(nTime)) or nMax
end	



function Patterns:PatternTest(tParams, tGenerated)
	local fVelocityDirection = math.random(0, 50) - 25
	tGenerated.fOffsetDirection = 270
	tGenerated.fOffset = math.random(0,6) - 3
	tGenerated.arFrames = {}

	for i = 0, 10 do
		tGenerated.arFrames[i] = 
		{
			fScale 	= GrowToMax(i + 1, tParams.fMaxSize),
			fTime 	= i * 0.1 * tParams.fMaxDuration,
			fAlpha 	= 1,
			fVelocityDirection = fVelocityDirection,
			fVelocityMagnitude = -(i-4)^2+6,
			nColor = tParams.nBaseColor 
		}
	end

	return tGenerated
end

---------------------------------------------------------------------------------------------------
--          123    123   
--      123             123
--               X
--      123             123
--          123     123
---------------------------------------------------------------------------------------------------
function Patterns:PatternCircular(tParams, tGenerated)
---------------------------------------------------------------------------------------------------
	tGenerated.fOffsetDirection = math.random(0, 360)
	tGenerated.fOffset 		 	= math.random(10, 100)/100
	tGenerated.arFrames =
	{
		[1] = {fScale = (tParams.fMaxSize) * 0.8,	 		  fTime = 0,			        fVelocityDirection = tGenerated.fOffsetDirection, fVelocityMagnitude = 5, nColor = tParams.nBaseColor,	},
		[2] = {fScale = tParams.fMaxSize,			  		  fTime = .15,					fAlpha = 1.0,},   
		[3] = {fScale = tParams.fMaxSize * tParams.fBigScale, fTime = .3,		    		fAlpha = 0.95,},
		[4] = {fScale = tParams.fMaxSize,			  	      fTime = .5,					fAlpha = 0.9,},
		[5] = {fScale = tParams.fMaxSize * tParams.fBigScale, fTime = 0.75, 				fAlpha = 0.8 },
		[6] = {								  				  fTime = tParams.fMaxDuration,	fAlpha = 0.0,},
	}
	
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
	tGenerated.fOffset 	     	= math.random(10, 100)/100
	tGenerated.arFrames =
	{
		[1] = {fScale = (tParams.fMaxSize) * 0.8,	          fTime = 0,			        fVelocityDirection = tGenerated.fOffsetDirection, fVelocityMagnitude = 5, nColor = tParams.nBaseColor,	},
		[2] = {fScale = tParams.fMaxSize,			          fTime = .15,			        fAlpha = 1.0,},   
		[3] = {fScale = tParams.fMaxSize * tParams.fBigScale, fTime = .3,		            fAlpha = 0.95,},
		[4] = {fScale = tParams.fMaxSize,			          fTime = .5,			        fAlpha = 0.9,},
		[5] = {fScale = tParams.fMaxSize * tParams.fBigScale, fTime = 0.75, 		        fAlpha = 0.8 },
		[6] = {								                  fTime = tParams.fMaxDuration,	fAlpha = 0.0,},
	}
	
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
	tGenerated.fOffsetDirection = math.random(200,220) -- 5 o'clock
	tGenerated.fOffset 		 	= math.random(15,35)/10
	
	tGenerated.arFrames =
	{
		[1] = {fScale = tParams.fMaxSize * 0.8,	        		fTime = 0,			fVelocityDirection = -45, fVelocityMagnitude = 5,						nColor = tParams.nBaseColor,	},
		[2] = {fScale = tParams.fMaxSize,						fTime = .15,		fVelocityDirection = -30, fVelocityMagnitude = 5,	fAlpha = 1.0,							},
		[3] = {fScale = tParams.fMaxSize * tParams.fBigScale,	fTime = .30,		fVelocityDirection = -15, fVelocityMagnitude = 5,						nColor = tParams.nBaseColor,	},
		[4] = {fScale = tParams.fMaxSize,						fTime = .45,		fVelocityDirection = 15,  fVelocityMagnitude = 5,	fAlpha = 0.85,						},
		[5] = {fScale = tParams.fMaxSize * tParams.fBigScale,	fTime = .75,		fVelocityDirection = 30,  fVelocityMagnitude = 5,	fAlpha = 0.65,						},
		[6] = {													fTime = tParams.fMaxDuration,													fAlpha = 0.0,							},
	}
	
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
	tGenerated.fOffsetDirection = math.random(340,355) -- 5 o'clock
	tGenerated.fOffset			= math.random(30,50)/10
	
	tGenerated.arFrames =
	{
		[1] = {fScale = tParams.fMaxSize * 0.8,	       			fTime = 0,			fVelocityDirection = 230, 	fVelocityMagnitude = 5,						nColor = tParams.nBaseColor,	},
		[2] = {fScale = tParams.fMaxSize,						fTime = .15,		fVelocityDirection = 215, 	fVelocityMagnitude = 5,	fAlpha = 1.0,							},
		[3] = {fScale = tParams.fMaxSize * tParams.fBigScale,	fTime = .30,		fVelocityDirection = 200, 	fVelocityMagnitude = 5,						nColor = tParams.nBaseColor,	},
		[4] = {fScale = tParams.fMaxSize,						fTime = .45,		fVelocityDirection = -200,  fVelocityMagnitude = 5,	fAlpha = 0.85,						},
		[5] = {fScale = tParams.fMaxSize * tParams.fBigScale,	fTime = .75,		fVelocityDirection = -215,  fVelocityMagnitude = 5,	fAlpha = 0.65,						},
		[6] = {													fTime = tParams.fMaxDuration,													fAlpha = 0.0,							},
	}
	
	return tGenerated
end

---------------------------------------------------------------------------------------------------
function Patterns:PatternStreamDownLeft(tParams, tGenerated)
---------------------------------------------------------------------------------------------------
	tGenerated.fOffsetDirection = math.random(20,40) -- 5 o'clock
	tGenerated.fOffset 			= math.random(30,50)/10

	tGenerated.arFrames =
	{
		[1] = {fScale = tParams.fMaxSize * 0.8,	        		fTime = 0,			fVelocityDirection = 145, 	fVelocityMagnitude = 5,						nColor = tParams.nBaseColor,	},
		[2] = {fScale = tParams.fMaxSize,						fTime = .15,		fVelocityDirection = 160, 	fVelocityMagnitude = 5,	fAlpha = 1.0,							},
		[3] = {fScale = tParams.fMaxSize * tParams.fBigScale,	fTime = .30,		fVelocityDirection = 175, 	fVelocityMagnitude = 5,						nColor = tParams.nBaseColor,	},
		[4] = {fScale = tParams.fMaxSize,						fTime = .45,		fVelocityDirection = -175,  fVelocityMagnitude = 5,	fAlpha = 0.85,						},
		[5] = {fScale = tParams.fMaxSize * tParams.fBigScale,	fTime = .75,		fVelocityDirection = -160,  fVelocityMagnitude = 5,	fAlpha = 0.65,						},
		[6] = {													fTime = tParams.fMaxDuration,													fAlpha = 0.0,							},
	}
	
	return tGenerated
end

---------------------------------------------------------------------------------------------------
function Patterns:PatternStreamUpLeft(tParams, tGenerated)
---------------------------------------------------------------------------------------------------
	tGenerated.fOffsetDirection = math.random(130,160) -- 5 o'clock
	tGenerated.fOffset          = math.random(20,40)/10
	
	tGenerated.arFrames =
	{
		[1] = {fScale = tParams.fMaxSize * 0.8,	        		fTime = 0,			fVelocityDirection = 45, fVelocityMagnitude = 5,						nColor = tParams.nBaseColor,	},
		[2] = {fScale = tParams.fMaxSize,						fTime = .15,		fVelocityDirection = 30, fVelocityMagnitude = 5,	fAlpha = 1.0,							},
		[3] = {fScale = tParams.fMaxSize * tParams.fBigScale,	fTime = .30,		fVelocityDirection = 15, fVelocityMagnitude = 5,						nColor = tParams.nBaseColor,	},
		[4] = {fScale = tParams.fMaxSize,						fTime = .45,		fVelocityDirection = -15,  fVelocityMagnitude = 5,	fAlpha = 0.85,						},
		[5] = {fScale = tParams.fMaxSize * tParams.fBigScale,	fTime = .75,		fVelocityDirection = -30,  fVelocityMagnitude = 5,	fAlpha = 0.65,						},
		[6] = {													fTime = tParams.fMaxDuration,											fAlpha = 0.0,							},
	}
	
	return tGenerated
end

---------------------------------------------------------------------------------------------------
function Patterns:PatternStraightUp(tParams, tGenerated)
---------------------------------------------------------------------------------------------------
	tGenerated.fOffsetDirection = 0 
	tGenerated.fOffset 			= 0
	
	tGenerated.arFrames =
	{
		[1] = {fScale = tParams.fMaxSize * 0.8,	        		fTime = 0,			    fVelocityDirection = 0, fVelocityMagnitude = 5,						nColor = tParams.nBaseColor,	},
		[2] = {fScale = tParams.fMaxSize,						fTime = .15,			fAlpha = 1.0,							},
		[3] = {fScale = tParams.fMaxSize * tParams.fBigScale,	fTime = .30,							nColor = tParams.nBaseColor,	},
		[4] = {fScale = tParams.fMaxSize,						fTime = .45,			fAlpha = 0.85,						},
		[5] = {fScale = tParams.fMaxSize * tParams.fBigScale,	fTime = .75,			fAlpha = 0.65,						},
		[6] = {													fTime = tParams.fMaxDuration,													fAlpha = 0.0,							},
	}
	
	return tGenerated
end

---------------------------------------------------------------------------------------------------
function Patterns:PatternStraightDown(tParams, tGenerated)
---------------------------------------------------------------------------------------------------
	tGenerated.fOffsetDirection  = 0
	tGenerated.fOffset 			 = 0
	
	tGenerated.arFrames =
	{
		[1] = {fScale = tParams.fMaxSize * 0.8,	        		fTime = 0,			fVelocityDirection = 180, fVelocityMagnitude = 5, nColor = tParams.nBaseColor,	},
		[2] = {fScale = tParams.fMaxSize,						fTime = .15,					fAlpha = 1.0,												},
		[3] = {fScale = tParams.fMaxSize * tParams.fBigScale,	fTime = .30,					fAlpha = 0.95,						nColor = tParams.nBaseColor,	},
		[4] = {fScale = tParams.fMaxSize,						fTime = .45,					fAlpha = 0.80,												},
		[5] = {fScale = tParams.fMaxSize * tParams.fBigScale,	fTime = .75,					fAlpha = 0.65,												},
		[6] = {													fTime = tParams.fMaxDuration,   fAlpha = 0.0,												},
	}
	
	return tGenerated
end

IronCombatText.Patterns = Patterns
