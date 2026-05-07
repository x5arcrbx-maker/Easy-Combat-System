local NpcService = {}

--//:SERVICES
local ServerStorage 	  = game:GetService("ServerStorage")
local Debris			  = game:GetService("Debris")
local ServerScriptService = game:GetService("ServerScriptService")
local Players 			  = game:GetService("Players")
--//:MODULES
local DataManager = require(ServerScriptService.Modules.Services.ProfileStore.Data.DataManager) :: any

--//:REFERENCES
local spawners 		   = workspace:FindFirstChild("Spawners") :: Folder
if not spawners then --Checks if Spawners folder exists
	spawners = Instance.new("Folder")
	spawners.Name = "Spawners"
	spawners.Parent = workspace
	warn("(NpcService): 'Spawners' folder not found in workspace. A new folder has been created. Please add spawners to this folder.")
end
local collectionFolder = workspace:FindFirstChild("Collection") :: Folder
if not collectionFolder then --Checks if Collection folder exists
	collectionFolder = Instance.new("Folder")
	collectionFolder.Name = "Collection"
	collectionFolder.Parent = workspace
	warn("(NpcService): 'Collection' folder not found in workspace. A new folder has been created.")
end
local collection 	   = collectionFolder:FindFirstChild("Characters") :: Folder
if not collection then --Checks if Collection/Characters folder exists
	collection = Instance.new("Folder")
	collection.Name = "Characters"
	collection.Parent = collectionFolder
	warn("(NpcService): 'Collection/Characters' folder not found in workspace. A new folder has been created.")
end

local NpcFolder = ServerStorage:FindFirstChild("NPCs") :: Folder

--Scripts to clone to NPCs
local attackScript: Script 		 = script.AttackScript -- Attack script (disabled by default, cloned to NPCs)
local ragdollScript: Script 	 = script.R6NPCRagdoll -- Ragdoll script (disabled by default, cloned to NPCs)
--local gripAndCarryScript: Script = script["Handler (Grip and Carry) NPC"] -- Grip and Carry script (disabled by default, cloned to NPCs)
local healthScript: Script 		 = script.Health --Health script (disabled by default, cloned to NPCs)

--//:VARIABLES
local PREVENTION_ATTRIBUTES_Attacker: {string} = {
	"Gripped",
	"Carried",
	"Knocked",
	"Ragdolled",

	"TrueStunned",
	"Stunned",

	"Blocking",
}

--//:FUNCTIONS
local function setStunDebug(character: Model)
	local gui = script.StunBillboardGui:Clone()
	gui.Parent = character
	gui.Adornee = character
	gui.Enabled = true

	local frame = gui:FindFirstChildOfClass("Frame")
	if not frame then
		warn("No frame found inside StunBillboardGui")
		return
	end

	-- SINGLE update function
	local function updateColor()
		local isPrevented = false

		for _, attribute: string in pairs(PREVENTION_ATTRIBUTES_Attacker) do
			if character:GetAttribute(attribute) then
				isPrevented = true
				break
			end
			isPrevented = false
		end

		if isPrevented then
			frame.BackgroundColor3 = Color3.fromRGB(255,0,0)
		else
			frame.BackgroundColor3 = Color3.fromRGB(0,255,0)
		end
	end

	-- connect all attribute signals
	for _, attribute in pairs(PREVENTION_ATTRIBUTES_Attacker) do
		character:GetAttributeChangedSignal(attribute):Connect(updateColor)
	end
	-- VERY IMPORTANT — run once initially
	updateColor()
end

function NpcService:SpawnNpc(
	Type: string,
	Race: string,
	Name: string,
	spawnLocation: BasePart,
	AttackNpc: boolean,
	Weapon: boolean
) --Folder > Type > Race > Name
	local typeFolder = NpcFolder:FindFirstChild(Type)
	local raceFolder = typeFolder and typeFolder:FindFirstChild(Race) -- Check if typeFolder exists before accessing its children
	local nameModel  = raceFolder and raceFolder:FindFirstChild(Name) -- Check if raceFolder exists before accessing its children

	local Npc = nameModel :: Model --Gets NPC from given Folder (Type, Race, Name)
	if Npc then
		local newNpc: Model = Npc:Clone() --Clones NPC
		newNpc.Parent = collection --Add to collection to prevent workspace buildup
		newNpc:PivotTo(spawnLocation.CFrame + Vector3.new(0, 5, 0)) --Finds spawner starting with NPC Name, spawns 5 studs up prevent clipping
		
		-- Clone Scripts --
		healthScript = healthScript:Clone()
		healthScript.Name    = "Health_Clone"
		healthScript.Parent  = newNpc --Parents health script to new NPC
		healthScript.Enabled = true --Enables health script
		
		ragdollScript = ragdollScript:Clone()
		ragdollScript.Name    = "RagdollScriptNPC_Clone"
		ragdollScript.Parent  = newNpc --Parents ragdoll script to new NPC
		ragdollScript.Enabled = true --Enables ragdoll script
		
		--gripAndCarryScript = gripAndCarryScript:Clone()
		--gripAndCarryScript.Name    = "Handler (Grip and Carry) NPC_Clone"
		--gripAndCarryScript.Parent  = newNpc --Parents grip and carry script to new NPC
		--gripAndCarryScript.Enabled = true --Enables grip and carry script
		
		if Race == "Dummy" then
			setStunDebug(newNpc) --Sets NPC stun debug
		end
		
		-- Add Attack Script if AttackNpc is true
		if AttackNpc then
			attackScript = attackScript:Clone()
			attackScript.Name    = "AttackScript_Clone"
			attackScript.Parent  = newNpc --Parents attack script to new NPC
			attackScript.Enabled = true --Enables attack script
			if Weapon then
				newNpc:SetAttribute("AttackNpcWeapon", true)
			else
				newNpc:SetAttribute("AttackNpcWeapon", false)
			end
		end

		-- Connect the Died event to the new NPC's Humanoid
		local humanoid = newNpc:FindFirstChildOfClass("Humanoid") :: Humanoid
		if humanoid then
			humanoid.Died:Once(function()
				Debris:AddItem(newNpc, 3) -- Clean up the old model parts
				task.wait(5)
				NpcService:SpawnNpc(Type, Race, Name, spawnLocation, AttackNpc, Weapon) --Respawns NPC
			end)
		else
			-- If no humanoid is found, print a warning
			warn(
				"No humanoid found in NPC[" 
				.. Name ..
				"]"
			)
		end
	else
		if not NpcFolder then -- Check if NpcFolder is nil
			warn(
				"(NpcService): NpcFolder is nil. Is it parented to ServerStorage?"
			)
		elseif NpcFolder and not typeFolder then -- Check if typeFolder is nil
			warn(
				"(NpcService): Type folder [" 
				.. Type ..
				"] is nil. Does the folder exist?"
			)
		elseif NpcFolder and typeFolder and not raceFolder then -- Check if raceFolder is nil
			warn(
				"(NpcService): Race folder ["
				.. Race ..
				"] is nil. Does the folder exist?"
			)
		elseif NpcFolder and typeFolder and raceFolder and not nameModel then -- Check if nameModel is nil
			warn(
				"(NpcService): Model ["
				.. Name .. 
				"] is nil. Is it parented to the correct Race folder?"
			)
		end
	end
end

return NpcService
