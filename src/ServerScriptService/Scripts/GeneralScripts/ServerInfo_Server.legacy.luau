--//:VARIABLES
local versionObj: StringValue = game:GetService("ReplicatedStorage").Values.ServerInfo.Version
local regionObj: StringValue = game:GetService("ReplicatedStorage").Values.ServerInfo.Region
local ageObj: StringValue = game:GetService("ReplicatedStorage").Values.ServerInfo.Age

--//:FUNCTIONS
local function getVersion(): string
	return tostring(game.PlaceVersion)
end

local function getRegion(player: Player): string
	if game:GetService("RunService"):IsStudio() then return "STUDIO" end
	return game:GetService("LocalizationService"):GetCountryRegionForPlayerAsync(player)
end

local function startAge()
	local minutes: number = 0
	local hours: number = 0
	local days: number = 0
	ageObj.Value = (
		"Server Age: (" ..tostring(days).. "d " ..tostring(hours).. "h " ..tostring(minutes).. "m )"
	) -- "Server Age (0d 0h 0m)"
	
	while true do
		task.wait(60)
		
		minutes += 1
		if minutes >= 60 then
			hours += 1
			minutes = 0
		end --adds to hour every 60 minutes
		if hours >= 24 then
			days += 1
			hours = 0
		end --adds to day every 24 hours
		
		ageObj.Value = (
			"Server Age (" ..tostring(days).. "d " ..tostring(hours).. "h " ..tostring(minutes).. "m )"
		)-- "Server Age (0d 0h 0m)"
	end
end

--//:MAIN
game:GetService("Players").PlayerAdded:Once(function(player)
	
	task.spawn(startAge)
	versionObj.Value = ("Version: (" ..getVersion().. ")")
	regionObj.Value = ("Server Region: (" ..getRegion(player).. ")")
end)
