--//:SERVICES
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

--//:MODULES
local DataFolder = script.Parent
local DataManager = require(DataFolder.DataManager)
local GamePassHandler = require(DataFolder.GamePassHandler)
local ProfileStore = require(DataFolder.Parent)
local Template = require(DataFolder.Template)

--//:REFERENCES
local DataRemotes = ReplicatedStorage.Remotes_Bindables.Remotes.Data :: any
local updateDataRemote = DataRemotes.UpdateData :: UnreliableRemoteEvent
local readyRemote = DataRemotes.ReadyRemote :: RemoteEvent

--//:VARIABLES
local playerConnections = {}

--//:MAIN
--	Returns Run Context ("Test" or "Live")
local function GetStoreName()
	return RunService:IsStudio() and "Test" or "Live"
end

--	Access ProfileStore
local PlayerStore = ProfileStore.New(GetStoreName(), Template)

--	Add leaderstats and sync player data
local function Initialize(player: Player, profile: typeof(PlayerStore:StartSessionAsync()))
	print(("Initializing (Player: %s)"):format(player.Name))

	--Leaderstats (Folder)--
	local leaderstats: Folder = Instance.new("Folder")
	leaderstats.Parent = player
	leaderstats.Name = "leaderstats"

	--Parented to leaderstats
	local Yen: NumberValue = Instance.new("NumberValue")
	Yen.Parent = leaderstats
	Yen.Name = "Yen"
	Yen.Value = profile.Data.Yen

	GamePassHandler:InitGamePassForPlayer(player, "2x Yen")

	--[[
	local Rank: StringValue = Instance.new("StringValue")
	Rank.Parent = leaderstats
	Rank.Name = "Rank"
	Rank.Value = profile.Data.Rank
	]]

	local Kills: StringValue = Instance.new("NumberValue")
	Kills.Parent = leaderstats
	Kills.Name = "Kills"
	Kills.Value = profile.Data.Kills

	GamePassHandler:InitGamePassForPlayer(player, "Early Access")

	--[[
	--Parented to player
	local Level: NumberValue = Instance.new("NumberValue")
	Level.Parent = player
	Level.Name   = "Level"
	Level.Value  = profile.Data.Level
	
	local Experience: NumberValue = Instance.new("NumberValue")
	Experience.Parent = Level
	Experience.Name   = "Experience"
	Experience.Value  = profile.Data.Experience
	
	local Threshold: NumberValue = Instance.new("NumberValue")
	Threshold.Parent = Level
	Threshold.Name   = "Threshold"
	Threshold.Value  = DataManager:GetXPForNextLevel(Level.Value)
	
	local Race: StringValue = Instance.new("StringValue")
	Race.Parent = player
	Race.Name   = "Race"
	Race.Value  = profile.Data.Race
	]]

	local Quest: Folder = Instance.new("Folder")
	Quest.Parent = player
	Quest.Name = "Quest"

	--Parented to Quest
	local QuestName: StringValue = Instance.new("StringValue")
	QuestName.Parent = Quest
	QuestName.Name = "Name"
	QuestName.Value = profile.Data.Quests[1].Name

	local QuestRequirements: StringValue = Instance.new("StringValue")
	QuestRequirements.Parent = Quest
	QuestRequirements.Name = "Requirements"
	QuestRequirements.Value = profile.Data.Quests[1].Requirements

	local QuestProgress: NumberValue = Instance.new("NumberValue")
	QuestProgress.Parent = Quest
	QuestProgress.Name = "Progress"
	QuestProgress.Value = profile.Data.Quests[1].Progress

	local QuestCompleted: BoolValue = Instance.new("BoolValue")
	QuestCompleted.Parent = Quest
	QuestCompleted.Name = "Completed"
	QuestCompleted.Value = profile.Data.Quests[1].Completed

	local QuestRewards: StringValue = Instance.new("StringValue")
	QuestRewards.Parent = Quest
	QuestRewards.Name = "Rewards"
	QuestRewards.Value = profile.Data.Quests[1].Rewards

	--Connections
	playerConnections[player] = {} -- Store connections in a table
	local connections = playerConnections[player]

	local char_childAdded_conn: RBXScriptConnection
	local char_childRemoved_conn: RBXScriptConnection
	local plrBackpack_childAdded_conn: RBXScriptConnection
	local plrBackpack_childRemoved_conn: RBXScriptConnection
	local player_characterAdded_conn: RBXScriptConnection

	--	Handle inventory initialization & changes, and multipliers being added to character
	local function setupCharacter(character: Model)
		--Add Damage and Defense multipliers to character
		local function addMultipliers()
			if not character:FindFirstChild("DamageMultiplier") then
				local DamageMultiplier: NumberValue = Instance.new("NumberValue")
				DamageMultiplier.Parent = character
				DamageMultiplier.Name = "DamageMultiplier"
				DamageMultiplier.Value = 1 --DataManager:GetDamageMultiplier(profile.Data.Level)
			end

			if not character:FindFirstChild("DefenseMultiplier") then
				local DefenseMultiplier: NumberValue = Instance.new("NumberValue")
				DefenseMultiplier.Parent = character
				DefenseMultiplier.Name = "DefenseMultiplier"
				DefenseMultiplier.Value = 1 --DataManager:GetDefenseMultiplier(profile.Data.Level)
			end
		end
		addMultipliers()

		--Handle adding weapon to character
		local savedWeapon = profile.Data.Weapon
		if savedWeapon then
			character:SetAttribute("Weapon", savedWeapon)
			local addWeapon_bindable =
				ReplicatedStorage.Remotes_Bindables.Bindables.GeneralPlayer.WeaponChange :: BindableEvent
			addWeapon_bindable:Fire(character)
		end

		--Inventory Handling
		--Iterate through profile.Data.Inventory and clone tools to player.Backpack (if they exist)
		local function addInventory()
			for _, v: string in ipairs(profile.Data.Inventory) do
				local tool: Instance? = ServerStorage.Tools:FindFirstChild(v, true) --Find the tool
				if
					tool --was an instance found?
					and tool:IsA("Tool") --is the instance a tool?
					and not CollectionService:HasTag(tool, "StarterPack") --ensure tool is not a starter pack item
				then
					tool:Clone().Parent = player.Backpack
				end --^ if tool was found and is a tool and is not a StarterPack, clone and parent
			end
			print(
				"addInventory() was a success!"
					.. " Contents of inventory: "
					.. tostring(table.concat(profile.Data.Inventory, ", "))
			)

			GamePassHandler:InitGamePassForPlayer(player, "Radio")
		end
		addInventory()

		--Connect to child added/removed in character and player.Backpack to detect inventory changes
		local function okToUpdateInventory(): boolean
			if not character then
				return false
			end
			--[[
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid then
				return false
			end
			if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Dead then
				return false
			end
			]]

			return true
		end

		--	Set connection values and insert into connections table
		local function createInventoryChangeConnections()
			char_childAdded_conn = character.ChildAdded:Connect(function()
				if not okToUpdateInventory() then
					return
				end --Don't update data if dead
				DataManager.UpdateInventory(player)
			end)
			table.insert(connections, char_childAdded_conn)

			char_childRemoved_conn = character.ChildRemoved:Connect(function()
				if not okToUpdateInventory() then
					return
				end --Don't update data if dead
				DataManager.UpdateInventory(player)
			end)
			table.insert(connections, char_childRemoved_conn)

			plrBackpack_childAdded_conn = player.Backpack.ChildAdded:Connect(function()
				if not okToUpdateInventory() then
					return
				end --Don't update data if dead
				DataManager.UpdateInventory(player)
			end)
			table.insert(connections, plrBackpack_childAdded_conn)

			plrBackpack_childRemoved_conn = player.Backpack.ChildRemoved:Connect(function()
				if not okToUpdateInventory() then
					return
				end --Don't update data if dead
				DataManager.UpdateInventory(player)
			end)
			table.insert(connections, plrBackpack_childRemoved_conn)
		end
		createInventoryChangeConnections()
	end
	if player.Character then
		setupCharacter(player.Character)
	end
	player_characterAdded_conn = player.CharacterAdded:Connect(setupCharacter)
	table.insert(connections, player_characterAdded_conn) --Add characterAdded connection to connections table

	--[[
	--Updates info gui like (yen, rank, xp, level)
	local function updateDataClient()
		updateDataRemote:FireClient(player, "Yen", profile.Data.Yen)
		updateDataRemote:FireClient(player, "Experience", profile.Data.Experience)
		updateDataRemote:FireClient(player, "Level", profile.Data.Level)
		updateDataRemote:FireClient(player, "Rank", profile.Data.Rank)
	end
	
	--Connection to update data-GUIs on the client when player is ready
	local remoteConnection: RBXScriptConnection
	remoteConnection = readyRemote.OnServerEvent:Connect(function(playerWhoCalled)
		if playerWhoCalled ~= player then return end

		updateDataClient()
	end)
	table.insert(connections, remoteConnection)
	]]
end

--	Player Added function to initialize player data on join
local function PlayerAdded(player: Player)
	print("PlayerAdded succeeded! (Player: " .. player.Name .. ")")

	--Start new session
	local profile = PlayerStore:StartSessionAsync("Player_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	--Sanity check to ensure profile exists
	if profile ~= nil then
		profile:AddUserId(player.UserId) -- Cross-save prevention
		profile:Reconcile() -- Fill in missing data with values from Template

		--Session locking
		profile.OnSessionEnd:Connect(function()
			DataManager.Profiles[player] = nil
			player:Kick("Data error occured. Please rejoin")
		end)

		if player.Parent == Players then
			print("Player successfully loaded! (Player: " .. player.Name .. ")")

			DataManager.Profiles[player] = profile
			if DataManager.Profiles[player] then
				print("Profile loaded into DataManager! (Player: " .. player.Name .. ")")
			else
				warn("Profile not able to load into DataManager. (Player: " .. player.Name .. ")")
			end
			Initialize(player, profile)
		else
			profile:EndSession()
		end

		--[[
		while player do
			task.wait(3)
			DataManager.UpdateYen(player, 10)
			DataManager.UpdateExperience(player, 10)
		end
		]]
	else
		--Server shuts down while player is joining
		warn("Player couldn't be loaded. (Player: " .. player.Name .. ")")

		player:Kick("Data error occured. Please rejoin.")
	end
end
---------------------------
--|		DATA SAVING		|--
---------------------------
--	Player added and removed functions
for _, player in Players:GetPlayers() do -- Player added (incase PlayerAdded signal didn't fire)
	task.spawn(PlayerAdded, player)
end
Players.PlayerAdded:Connect(PlayerAdded) -- Player added
Players.PlayerRemoving:Connect(function(player) -- Player removed
	local profile = DataManager.Profiles[player]
	if not profile then
		warn("PlayerRemoving: Profile not found. (Player: " .. player.Name .. ")")
		return
	end
	profile:EndSession()
	DataManager.Profiles[player] = nil

	--Clear player connections to prevent memory leaks
	if playerConnections[player] then
		for _, conn: RBXScriptConnection in pairs(playerConnections[player]) do
			conn:Disconnect()
			conn = nil
		end
	end
end)
