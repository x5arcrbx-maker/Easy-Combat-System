--!strict

--//:SERVICES
local MarketPlaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--//:VARIABLES
local initGamePassFunctions = {
	["2x Yen"] = function(player: Player, ownsGamePass: boolean)
		if ownsGamePass then
			player:SetAttribute("YenMultiplier", 2)
		else
			player:SetAttribute("YenMultiplier", 1)
		end
	end,
	["Custom Flashstep Color"] = function(player: Player, ownsGamePass: boolean) end,
	["Early Access"] = function(player: Player, ownsGamePass: boolean)
		player:SetAttribute("EarlyAccess", ownsGamePass)
	end,
	["Radio"] = function(player: Player, ownsGamePass: boolean)
		local backpack = player.Backpack :: Backpack
		local character = player.Character
		if not character then
			warn("Character not found for player: " .. player.Name)
			return
		end

		local toolsFolder = ServerStorage:FindFirstChild("Tools") :: Folder
		if not toolsFolder then
			warn("Tools folder not found")
			return
		end
		local otherToolsFolder = toolsFolder:FindFirstChild("Other(TOOLS)") :: Folder
		if not otherToolsFolder then
			warn("Other(TOOLS) folder not found")
			return
		end
		local gamepassesFolder = otherToolsFolder:FindFirstChild("Gamepasses") :: Folder
		if not gamepassesFolder then
			warn("Gamepasses folder not found")
			return
		end

		local radio = gamepassesFolder:FindFirstChild("Radio")
		if not radio then
			warn("Radio gamepass tool not found")
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

	local valuesFolder = ReplicatedStorage:FindFirstChild("Values") :: Folder
	if not valuesFolder then
		return false
	end
	local NumberValuesFolder = valuesFolder:FindFirstChild("NumberValues") :: Folder
	if not NumberValuesFolder then
		return false
	end

	local gamePassFolder = NumberValuesFolder:FindFirstChild("GamePasses") :: Folder
	if not gamePassFolder then
		warn("GamePasses folder not found in NumberValues")
		return false
	end

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

	--Use pcall to avoid errors and check if the player owns the gamepass
	local success: boolean, ownsGamePass: boolean = pcall(function()
		return MarketPlaceService:UserOwnsGamePassAsync(playerUser, gamePass.Value)
	end)
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
