--//:MODULES
local DataManager = require(game:GetService("ServerScriptService").Services.ProfileStore.Data.DataManager)

--//:REFERENCES
local remote: RemoteEvent = game:GetService("ReplicatedStorage").Remotes_Bindables.Remotes.GeneralPlayer.BuyFood

--//:VARIABLES
local prices: { [string]: number } = {
	Ramen = 150,
	Onigiri = 50,
}

--//:FUNCTIONS

--	Clone food into player's backpack
local function cloneFoodIntoBackpack(player: Player, food: string)
	local found_food: Instance? = game:GetService("ServerStorage").Tools["Other(TOOLS)"].Food:FindFirstChild(food)
	if found_food and found_food:IsA("Tool") then
		found_food:Clone().Parent = player.Backpack
	end
end

--	Search the player's inventory (backpack & character) for existing food
local function findFoodInInventory(player: Player, food: string): (boolean, Tool?)
	for _, v in pairs(player.Backpack:GetChildren()) do
		if v:IsA("Tool") and v.Name == food then
			return true and v
		end
	end --Search backpack (any tools not being held)
	for _, v in pairs(player.Character:GetChildren()) do
		if v:IsA("Tool") and v.Name == food then
			return true and v
		end
	end --Search character (to include any tool being held)

	return false and nil
end

--//:MAIN
remote.OnServerEvent:Connect(function(player: Player, food: string)
	if player.Character then
		--Sanity checks
		local leaderstats = player:FindFirstChild("leaderstats") :: Folder?
		if not leaderstats then
			return
		end
		local yen_Amount = leaderstats:FindFirstChild("Yen") :: NumberValue?
		if not yen_Amount then
			return
		end
		yen_Amount = yen_Amount.Value

		local price: number? = prices[food]
		if not price then
			return
		end --ensure price exists

		if yen_Amount < price then
			return
		end
		DataManager.UpdateYen(player, yen_Amount - price) --subtract price from player's yen

		--Give food
		local foundFoodInInventory: boolean, tool: Tool? = findFoodInInventory(player, food)
		if not foundFoodInInventory then
			cloneFoodIntoBackpack(player, food)
		else
			if tool then
				local amount = tool:FindFirstChild("Amount")
				if amount and amount:IsA("NumberValue") then
					amount.Value += 1
				end
			end
		end
	end
end)
