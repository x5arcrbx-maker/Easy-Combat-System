--!nolint DeprecatedApi
local module = {}

function module:Init()
	
	--//:SERVICES
	local GroupService = game:GetService("GroupService")
	local Players = game:GetService("Players")
	local BadgeService = game:GetService("BadgeService")


	--//:VARIABLES
	local groupId = 32976059
	local group = GroupService:GetGroupInfoAsync(groupId)
	local MINIMUM_RANK: number = 100

	local badgeId = 1084536795802534

	--//:FUNCTIONS
	
	--	Kicks player and provides reason
	local function kickPlayer(player: Player)
		player:Kick("You are not a tester or higher rank in the (" .. group.Name .. ") group.")
	end
	
	--	Checks rank of player in the group
	local function checkRank(player: Player)
		local rank = player:GetRankInGroupAsync(groupId)
		if rank < MINIMUM_RANK then
			kickPlayer()
		else
			BadgeService:AwardBadgeAsync(player.UserId, badgeId)
		end
		
		--[[ GroupService:GetRolesInGroupAsync is not enabled yet.
		local rolesInGroup = GroupService:GetRolesInGroupAsync(player.UserId, groupId)
		if not rolesInGroup.IsMember then
			kickPlayer(player)
		end

		for _, role in pairs(rolesInGroup.Roles) do
			if role.Rank < MINIMUM_RANK then
				kickPlayer(player)
			end
		end
		]]
	end


	--//:MAIN
	Players.PlayerAdded:Connect(checkRank)
	for _, player in ipairs(Players:GetPlayers()) do
		checkRank(player)
	end
end

return module
