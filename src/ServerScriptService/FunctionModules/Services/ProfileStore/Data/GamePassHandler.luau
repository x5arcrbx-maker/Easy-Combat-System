--!strict

--//:SERVICES
local MarketPlaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--//:VARIABLES
local initGamePassFunctions = {
	["2x Yen"] = function(player: Player, ownsGamePass: boolean)
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then
			warn("Leaderstats not found for player: " .. player.Name)
			return
		end
		local yenMultiplier = leaderstats:FindFirstChild("YenMultiplier") :: NumberValue
		if not yenMultiplier then
			warn("YenMultiplier not found for player: " .. player.Name)
			return
		end

		if ownsGamePass then
			yenMultiplier.Value = 2
		else
			yenMultiplier.Value = 1
		end
	end,
	["Custom Flashstep Color"] = function(player: Player, ownsGamePass: boolean) end,
	["Early Access"] = function(player: Player, ownsGamePass: boolean)
		local earlyAccessValue = player:FindFirstChild("EarlyAccess") :: BoolValue
		if not earlyAccessValue then
			warn("EarlyAccess BoolValue not found for player: " .. player.Name)
			return
		end
		earlyAccessValue.Value = ownsGamePass
	end,
	["Radio"] = function(player: Player, ownsGamePass: boolean)
		local backpack = player.Backpack :: Backpack
		if not ownsGamePass then
			local existingRadio = backpack:FindFirstChild("Radio")
			if existingRadio then
				existingRadio:Destroy()
			end
			return
		end

		local character = player.Character
		if not character then
			warn("Character not found for player: " .. player.Name)
			return
		end

		local radio = ServerStorage.Tools["Other(TOOLS)"].Gamepasses:FindFirstChild("Radio")
		if not radio then
			warn("Radio gamepass not found")
			return
		end

		local existingRadio_inBackpack = backpack:FindFirstChild("Radio")
		local existingRadio_inCharacter = character:FindFirstChild("Radio")

		if not existingRadio_inBackpack and not existingRadio_inCharacter then
			local radioClone = radio:Clone()
			radioClone.Parent = backpack
		end
	end,
}

--//:MAIN
local GamePassHandler = {}

function GamePassHandler:InitGamePassForPlayer(player: Player, gamePassName: string): boolean
	if not player then
		warn("Player argument is nil")
		return false
	end
	local playerUser: User = player.User
	local gamePassFolder = ReplicatedStorage.Values.NumberValues.GamePasses :: Folder
	local gamePass = gamePassFolder:FindFirstChild(gamePassName) :: NumberValue
	if not gamePass then
		warn("Gamepass not found: " .. gamePassName)
		return false
	end
	if not gamePass:IsA("NumberValue") then
		warn("Gamepass is not a NumberValue: " .. gamePassName)
		return false
	end --^ gamePass is a NumberValue so the value is the gamepass ID, so exit if gamePass is not a NumberValue
	if gamePass.Value == 0 then
		warn("Gamepass value is invalid: " .. gamePassName)
		return false
	end --^ If gamePass.Value is 0 then it means the gamepass is not set up yet.

	local success: boolean, ownsGamePass: boolean = pcall(function()
		return MarketPlaceService:UserOwnsGamePassAsync(playerUser, gamePass.Value)
	end) --^ use pcall to avoid errors and check if the player owns the gamepass
	if not success then
		warn("Error while checking if player has gamepass: " .. gamePassName)
		return false
	end

	local gamePassInitFunction = initGamePassFunctions[gamePassName]
	if gamePassInitFunction then
		gamePassInitFunction(player, ownsGamePass)
		return true
	else
		warn("No init function found for gamepass: " .. gamePassName)
		return false
	end
end

return GamePassHandler
