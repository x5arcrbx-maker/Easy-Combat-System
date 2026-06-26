--!strict

--//:SERVICES
local MarketPlaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _Players = game:GetService("Players")

--//:VARIABLES
local _initGamePassFunctions = {}

--//:MAIN
local GamePassHandler = {}

function GamePassHandler:CheckIfPlayerHasGamePasses(player: Player)
	local playerUser = player.User
	local gamePassFolder = ReplicatedStorage.Values.NumberValues.GamePasses

	for _, gamePass: Instance in pairs(gamePassFolder:GetChildren()) do
		if not gamePass:IsA("NumberValue") or gamePass.Value == 0 then
			continue
		end

		local success, _ownsGamePass = pcall(function()
			return MarketPlaceService:UserOwnsGamePassAsync(playerUser, gamePass.Value)
		end)
		if not success then
			warn("Error while checking if player has gamepass: " .. gamePass.Name)
			continue
			-- elseif ownsGamePass then
		end
	end
end

return GamePassHandler
