local FoodService = {}



--//:SERVICES//
local Players = game:GetService("Players")

--//:VARIABLES//
local playerOnCooldown = {}
Players.PlayerRemoving:Connect(function(player) --cleanup for playerOnCooldown on PlayerRemoving
	playerOnCooldown[player] = nil
end)

--//:FUNCTIONS//
function FoodService.Eat(COOLDOWN: number, HUNGER_toAdd: number, tool: Tool)

	local toolName: string = tool.Name --Keeps original name of tool

	--Local FUNCTIONS
	local function displayCooldown(COOLDOWN: number)
		for i = 1, COOLDOWN, -1 do
			tool.Name = i
			task.wait(1)
		end
		tool.Name = toolName
	end

	local function playSound(hrp: BasePart)
		local sound: Sound = tool:FindFirstChildOfClass("Sound")
		if sound then
			sound = sound:Clone()
			sound.Parent = hrp
			sound:Play()
			sound.Ended:Once(function()
				sound:Destroy()
			end)
		end
	end
	----------------
	
	--MAIN--
	tool.Activated:Connect(function()
		local player = Players:GetPlayerFromCharacter(tool.Parent)
		if player then
			
			-- Sanity checks --
			if playerOnCooldown[player] and tick() - playerOnCooldown[player] < COOLDOWN then
				return
			end
			playerOnCooldown[player] = tick()

			local char: Model? = player.Character
			if not char then return end
			local hum: Humanoid? = char:FindFirstChildOfClass("Humanoid")
			if not hum then return end
			if hum:GetState() == Enum.HumanoidStateType.Dead then return end
			
			local current_hunger: number? = char:GetAttribute("Hunger")
			if not current_hunger then return end
			--------------------
			
			--Update hunger--
			if current_hunger + HUNGER_toAdd < 100 then
				char:SetAttribute("Hunger", current_hunger + HUNGER_toAdd)
			elseif current_hunger + HUNGER_toAdd > 100 then
				char:SetAttribute("Hunger", 100)
			end
			-----------------
			
			--Play sound--
			local hrp: Instance? = char:FindFirstChild("HumanoidRootPart")
			if hrp and hrp:IsA("BasePart") then playSound(hrp) end
			--------------
			
			--Check amount of food player has--
			local amount: Instance? = tool:FindFirstChild("Amount") 
			if amount and amount:IsA("NumberValue") then
				if amount.Value <= 1 then
					tool:Destroy()
				else
					amount.Value -= 1
				end
			else 
				warn(
					"Tool does not have an 'Amount' NumberValue, or 'Amount' is not a NumberValue. "
					.. typeof(amount) .. " was found instead."
				)
			end
			
			--Display cooldown
			displayCooldown(COOLDOWN)
			-----------------------------------
		end
	end)
	--------
end



return FoodService
