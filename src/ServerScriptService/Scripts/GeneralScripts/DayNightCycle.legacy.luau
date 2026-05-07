--//:SERVICES
local Lighting 	   = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

--//:VARIABLES
local dayLength: number   	= 6 * 60 -- minutes
local betweenLength: number = 10 -- seconds
local nightLength: number	= 7.5 * 60 -- minutes
local totalCycleTime: number = dayLength + nightLength

local daySky: Sky = script.DaySky
local nightSky: Sky = script.NightSky

local dayClouds: Color3 = script.DayClouds.Value
local nightClouds: Color3 = script.NightClouds.Value
local clouds: Clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")

--//:MAIN
local function changeCloudColor(color: Color3)
	TweenService:Create(
		clouds, 
		TweenInfo.new(betweenLength, Enum.EasingStyle.Sine), 
		{Color = color}
	):Play()
end

local function changeBrightness(value: number)
	TweenService:Create(
		Lighting, 
		TweenInfo.new(betweenLength, Enum.EasingStyle.Sine), 
		{Brightness = value}
	):Play()
end

local function changeAmbient(color: Color3)
	TweenService:Create(
		Lighting, 
		TweenInfo.new(betweenLength, Enum.EasingStyle.Sine), 
		{Ambient = color}
	):Play()
end

while true do --DAY/NIGHT cycle that replaces the sky and clouds
	--DAY--
	TweenService:Create(
		Lighting, 
		TweenInfo.new(dayLength, Enum.EasingStyle.Linear), 
		{ClockTime = 17.5}
	):Play()
	task.wait(dayLength)
	
	--Transition to night
	--changeCloudColor(nightClouds)
	--changeAmbient(Color3.fromRGB(150,150,150))
	TweenService:Create(
		Lighting, 
		TweenInfo.new(betweenLength, Enum.EasingStyle.Linear), 
		{ClockTime = 22}
	):Play()
	task.wait(betweenLength)
	
	--NIGHT--
	TweenService:Create(
		Lighting, 
		TweenInfo.new(nightLength, Enum.EasingStyle.Linear), 
		{ClockTime = 2}
	):Play()
	task.wait(nightLength)
	
	--Transition to day
	--changeCloudColor(dayClouds)
	--changeAmbient(Color3.fromRGB(0,0,0))
	TweenService:Create(
		Lighting, 
		TweenInfo.new(betweenLength, Enum.EasingStyle.Linear), 
		{ClockTime = 8.5}
	):Play()
	
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

