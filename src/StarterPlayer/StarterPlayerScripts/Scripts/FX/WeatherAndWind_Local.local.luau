--Wind
local WindShake = require(game:GetService("ReplicatedStorage").Modules.Packages.WindShake)
WindShake:Init({MatchWorkspaceWind = false})


--Weather
local SimpleWeather_Script = game:GetService("ReplicatedStorage").Modules.Packages.SimpleWeather
local SimpleWeather = require(SimpleWeather_Script)
repeat
	task.wait()
until game:IsLoaded()
SimpleWeather:Start()

--[[
----local weathers = SimpleWeather_Script.Weathers.Lighting:GetChildren()
----local weatherToSetAs: string = weathers[math.random(1, #weathers)].Name
--local weathers = {
--	"Default",
--	"Cloudy",
--	"Rainy",
--	"Thunderstorm",
--	"Snowy",
--}
--local weatherToSetAs: string = weathers[math.random(1, #weathers)]
--game:GetService("ReplicatedStorage"):SetAttribute("CurrentWeather", weatherToSetAs)

SimpleWeather:Start()

--local waitTime = 1 * 10 --minutes
--while true do
--	task.wait(waitTime)
--	weatherToSetAs = weathers[math.random(1, #weathers)]
--	game:GetService("ReplicatedStorage"):SetAttribute("CurrentWeather", weatherToSetAs)
--end
]]
