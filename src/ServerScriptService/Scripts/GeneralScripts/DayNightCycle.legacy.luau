--//:SERVICES
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

--//:VARIABLES
local dayLength: number = 6 * 60 -- minutes
local betweenLength: number = 10 -- seconds
local nightLength: number = 7.5 * 60 -- minutes
local _totalCycleTime: number = dayLength + nightLength

local _daySky: Sky = script.DaySky
local _nightSky: Sky = script.NightSky

local _dayClouds: Color3 = script.DayClouds.Value
local _nightClouds: Color3 = script.NightClouds.Value
local clouds: Clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")

--//:MAIN
local function _changeCloudColor(color: Color3)
	TweenService:Create(clouds, TweenInfo.new(betweenLength, Enum.EasingStyle.Sine), { Color = color }):Play()
end

local function _changeBrightness(value: number)
	TweenService:Create(Lighting, TweenInfo.new(betweenLength, Enum.EasingStyle.Sine), { Brightness = value }):Play()
end

local function _changeAmbient(color: Color3)
	TweenService:Create(Lighting, TweenInfo.new(betweenLength, Enum.EasingStyle.Sine), { Ambient = color }):Play()
end

while true do --DAY/NIGHT cycle that replaces the sky and clouds
	--DAY--
	TweenService:Create(Lighting, TweenInfo.new(dayLength, Enum.EasingStyle.Linear), { ClockTime = 17.5 }):Play()
	task.wait(dayLength)

	--Transition to night
	--changeCloudColor(nightClouds)
	--changeAmbient(Color3.fromRGB(150,150,150))
	TweenService:Create(Lighting, TweenInfo.new(betweenLength, Enum.EasingStyle.Linear), { ClockTime = 22 }):Play()
	task.wait(betweenLength)

	--NIGHT--
	TweenService:Create(Lighting, TweenInfo.new(nightLength, Enum.EasingStyle.Linear), { ClockTime = 2 }):Play()
	task.wait(nightLength)

	--Transition to day
	--changeCloudColor(dayClouds)
	--changeAmbient(Color3.fromRGB(0,0,0))
	TweenService:Create(Lighting, TweenInfo.new(betweenLength, Enum.EasingStyle.Linear), { ClockTime = 8.5 }):Play()

	task.wait(betweenLength)
end

--[[
--while true do --REGULAR DAY/NIGHT cycle
--	--DAY
--	TweenService:Create(
--		Lighting, 
--		TweenInfo.new(dayLength, Enum.EasingStyle.Linear), 
--		{ClockTime = 17}
--	):Play()
--	task.wait(dayLength)

--	TweenService:Create(
--		Lighting, 
--		TweenInfo.new(betweenLength, Enum.EasingStyle.Linear), 
--		{ClockTime = 24}
--	):Play()
--	task.wait(betweenLength)

--	--NIGHT
--	TweenService:Create(
--		Lighting, 
--		TweenInfo.new(nightLength, Enum.EasingStyle.Linear), 
--		{ClockTime = 0}
--	):Play()
--	task.wait(nightLength)

--	TweenService:Create(
--		Lighting, 
--		TweenInfo.new(betweenLength, Enum.EasingStyle.Linear), 
--		{ClockTime = 7}
--	):Play()

--	task.wait(betweenLength)
--end
--]]
