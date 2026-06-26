local module = {}

function module:Init()
	local Players = game:GetService("Players")
	local BadgeService = game:GetService("BadgeService")
	local badgeId = 11149595451229
	
	local function awardBadge(player: Player)
		for _, user in pairs(Players:GetPlayers()) do
			if user.UserId == game.CreatorId then
				local success, hasBadge = pcall(function()
					return BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
				end)
				if success and not hasBadge then
					BadgeService:AwardBadgeAsync(player.UserId, badgeId)
				end
				
				break
			end
		end
	end
	
	Players.PlayerAdded:Connect(awardBadge)
	for _, player in ipairs(Players:GetPlayers()) do
		awardBadge(player)
	end
end

return module
