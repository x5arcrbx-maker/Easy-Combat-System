--//:SERVICES
local GroupService = game:GetService("GroupService")
local Players = game:GetService("Players")

--//:VARIABLES
local group = GroupService:GetGroupInfoAsync(32976059)
local MINIMUM_RANK: number = 100

--//:MAIN
Players.PlayerAdded:Connect(function(player: Player)
	if player:GetRankInGroupAsync(32976059) < MINIMUM_RANK then
		player:Kick("You are not a tester or higher rank in the (" .. group.Name .. ") group.")
	end
end)
