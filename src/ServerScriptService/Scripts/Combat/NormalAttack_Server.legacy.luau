--!strict
--//:SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")


--//:MODULES
local SkillsModule = require(ServerScriptService.Modules.PVP.SkillsModule)


--//:REFERENCES
local M1RemoteEvent = ReplicatedStorage.Remotes_Bindables.Remotes.PVP.M1sAndM2s.M1RemoteEvent :: RemoteEvent
local M1BindableEvent = ReplicatedStorage.Remotes_Bindables.Bindables.PVE.M1sAndM2s.M1BindableEvent :: BindableEvent





--//:FUNCTIONS
local function GetHitType(character: Model): string
	local tool = character:FindFirstChildOfClass("Tool")

	if tool and tool.Name == "Katana" then return "Sharp"
	else return "Blunt" end
end


--//:MAIN
--	Event (Players)
M1RemoteEvent.OnServerEvent:Connect(function(player, combo)
	--character, hum, hrp variables
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid") :: Humanoid?
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hum or not hrp then return end

	local hitType = GetHitType(char)

	--Calling the function
	SkillsModule.NormalAttack(char, hum, hrp, combo, hitType)
end)

--	Event (NPCs)
M1BindableEvent.Event:Connect(function(NPC: Model?, combo)
	--character, hum, hrp variables
	local char = NPC
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid") :: Humanoid?
	local hrp = char:WaitForChild("HumanoidRootPart") :: BasePart?
	if not hum or not hrp then return end

	local hitType = GetHitType(char)

	--Calling the function
	SkillsModule.NormalAttack(char, hum, hrp, combo, hitType)
end)
