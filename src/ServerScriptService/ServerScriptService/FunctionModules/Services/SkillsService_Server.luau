local SkillsService_Server = {}

function SkillsService_Server:Init(tool: Tool)
	local skillEvent = tool:FindFirstChildOfClass("RemoteEvent") --RemoteEvent
	if not skillEvent then
		skillEvent = Instance.new("RemoteEvent")
		skillEvent.Name = "RemoteEvent"
		skillEvent.Parent = tool
	end

	--Modules
	local SkillsModule = require(game:GetService("ServerScriptService").FunctionModules.PVP.SkillsModule)

	local skillCategory = tool:FindFirstChild("Category") :: StringValue
	if not skillCategory then
		warn("Category StringValue not found in tool: ("..tool.Name..").")
		return
	end
	
	local existingCategory = SkillsModule[skillCategory.Value]
	if not existingCategory then
		warn("Category not found in SkillsModule: ("..skillCategory.Value..").")
		return
	end
	
	local skillName = tool.Name
	local existingSkill = existingCategory[skillName]
	if not existingSkill then
		warn("Skill not found in SkillsModule: ("..tool.Name..").")
		return
	end
	
	--RemoteEvent
	skillEvent.OnServerEvent:Connect(function(player)	
		local char = player.Character
		if not char then
			return
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then
			return
		end

		local weaponEquipped = char:GetAttribute("WeaponIsEquipped")
		if weaponEquipped and not char:GetAttribute("UsingAttack") then
			existingSkill(player, char, hum, skillName)
		end
		hum:UnequipTools()
	end)
end

return SkillsService_Server
