local CooldownHandler = {}

local Players = game:GetService("Players")
local playerCooldowns = require(script.Parent.PlayerCooldowns)
local characterAdded_connections = {}

-- Reset cooldowns on respawn
function CooldownHandler:Init()
	local function resetCooldownsOnRespawn()
		Players.PlayerAdded:Connect(function(player)
			local conn: RBXScriptConnection
			conn = player.CharacterAdded:Connect(function()
				if playerCooldowns[player] then
					playerCooldowns[player] = nil
				end
				playerCooldowns[player] = {} -- reset on respawn
			end)

			characterAdded_connections[player] = {}
			table.insert(characterAdded_connections[player], conn)
		end)
	end

	local function removeKeyFromTableOnLeave()
		Players.PlayerRemoving:Connect(function(player)
			if playerCooldowns[player] then
				playerCooldowns[player] = nil
			end
			if characterAdded_connections[player] then
				for _, conn in pairs(characterAdded_connections[player]) do
					conn:Disconnect()
				end
				characterAdded_connections[player] = nil
			end
		end)
	end

	resetCooldownsOnRespawn()
	removeKeyFromTableOnLeave()
end

-- Get remaining cooldown for a skill (in seconds)
-- returns (number)
function CooldownHandler:GetRemainingCooldown(player: Player, skill: string): number
	local onCooldown = playerCooldowns[player]
	if not onCooldown then
		return 0
	end
	local expiresAt: number? = onCooldown[skill]
	if not expiresAt then
		return 0
	end
	local remaining = expiresAt - tick()
	return (remaining > 0) and remaining or 0
end

return CooldownHandler
