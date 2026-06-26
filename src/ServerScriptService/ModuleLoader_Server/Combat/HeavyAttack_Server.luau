local module = {}

function module:Init()
	--//:SERVICES
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ServerScriptService = game:GetService("ServerScriptService")


	--//:MODULES
	local SkillsModule = require(ServerScriptService.FunctionModules.PVP.SkillsModule)


	--//:REFERENCES
	local M2RemoteEvent = ReplicatedStorage.Remotes_Bindables.Remotes.PVP.M1sAndM2s.M2RemoteEvent :: RemoteEvent
	local M2BindableEvent = ReplicatedStorage.Remotes_Bindables.Bindables.PVE.M1sAndM2s.M2BindableEvent :: BindableEvent


	--//:CONSTANTS
	local COOLDOWN: number = 5





	--//:FUNCTIONS
	local function GetHitType(character: Model): string
		local weapon = character:GetAttribute("Weapon") :: string

		if weapon == "Katana" then 
			return "Sharp"
		else 
			return "Blunt" 
		end
	end


	--//:MAIN
	--	Event (Player)
	M2RemoteEvent.OnServerEvent:Connect(function(player: Player)
		--character, hum, hrp variables
		local char = player.Character
		if not char or not char:GetAttribute("WeaponIsEquipped") then 
			return 
		end
		if char:FindFirstChildOfClass("Tool") then
			return
		end
		if char:GetAttribute("HeavyAttackOnCooldown") then return end

		local hum = char:FindFirstChildOfClass("Humanoid") :: Humanoid?
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hum or not hrp then return end

		--HitType variable, checks if it's a fist or katana M2
		local hitType = GetHitType(char)

		SkillsModule.HeavyAttack(char, hum, hrp, hitType) --Send to skills module for handling

		--Cooldown
		char:SetAttribute("HeavyAttackOnCooldown", true)
		task.delay(COOLDOWN, function()
			char:SetAttribute("HeavyAttackOnCooldown", false)
		end)
	end) --	Event (Player)

	--	Event (NPC)
	M2BindableEvent.Event:Connect(function(NPC: Model?)
		--if NpcCOOLDOWNs[NPC] and NpcCOOLDOWNs[NPC] - tick() < COOLDOWN then
		--	return -- Still on COOLDOWN
		--end

		--NpcCOOLDOWNs[NPC] = tick() --Marks moment NPC used M2

		--character, hum, hrp variables
		local char = NPC
		if not char then return end

		if char:GetAttribute("HeavyAttackOnCooldown") then return end

		local hum = char:FindFirstChildOfClass("Humanoid") :: Humanoid?
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hum or not hrp then return end

		--HitType variable, checks if it's a fist or katana M2
		local hitType = GetHitType(char)
		if not hitType then return end

		SkillsModule.HeavyAttack(char, hum, hrp, hitType) --Send to skills module for handling

		--Cooldown
		char:SetAttribute("HeavyAttackOnCooldown", true)
		task.delay(COOLDOWN, function()
			char:SetAttribute("HeavyAttackOnCooldown", false)
		end)
	end)

end

return module
