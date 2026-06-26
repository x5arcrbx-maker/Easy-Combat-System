local module = {}

function module:Init()
	--//:SERVICES
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	local Debris = game:GetService("Debris")
	local ServerScriptService = game:GetService("ServerScriptService")

	--//:MODULES
	local _DataManager = require(ServerScriptService.FunctionModules.Services.ProfileStore.Data.DataManager)

	--//:VARIABLES
	local carryEvent = ReplicatedStorage.Remotes_Bindables.Remotes.PVP.GripAndCarry.CarryEvent :: RemoteEvent
	local gripEvent = ReplicatedStorage.Remotes_Bindables.Remotes.PVP.GripAndCarry.GripEvent :: RemoteEvent
	local reviveEvent = ReplicatedStorage.Remotes_Bindables.Remotes.PVP.GripAndCarry.ReviveEvent :: RemoteEvent

	local PREVENTION_ATTRIBUTES: { string } = {
		--"Gripping",
		"Gripped",
		"Carried",
		"Knocked",
		"Ragdolled",

		"TrueStunned",
		"Stunned",

		"Blocking",
		"Slowed",
		"UsingAttack",
	}
	local stateTracker = {}

	--//:FUNCTIONS
	local function AddDowned(character: Model)
		for _, v in pairs(ReplicatedStorage.Values.ObjectValues.Downed:GetChildren()) do
			if v:IsA("ObjectValue") then
				if v.Value == character then
					Debris:AddItem(v, 0)
				end
			end
		end
		local downed = Instance.new("ObjectValue")
		downed.Parent = ReplicatedStorage.Values.ObjectValues.Downed
		downed.Name = character.Name
		downed.Value = character

		character:SetAttribute("Knocked", true)
	end

	local function RemoveDowned(character: Model)
		for _, v in pairs(ReplicatedStorage.Values.ObjectValues.Downed:GetChildren()) do
			if v.Name == character.Name then
				v:Destroy()
				character:SetAttribute("Knocked", false)
			end
		end
	end

	--//:EVENTS
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
			if humanoid then
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
				humanoid.HealthChanged:Connect(function(health)
					if health > 0 then
						return
					end

					local trigger = character:FindFirstChild("RagdollTrigger") :: BoolValue?
					if not trigger then
						return
					end

					trigger.Value = true

					if not ReplicatedStorage.Values.ObjectValues.Downed:FindFirstChild(character.Name) then
						AddDowned(character)
					end
					print(character.Name .. " is downed")
				end)
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		if stateTracker[player] then
			stateTracker[player] = nil
		end
	end)

	carryEvent.OnServerEvent:Connect(function(player, victim: Model?)
		if victim and player.Character then
			local character = player.Character :: Model?
			if not character then
				return
			end
			local hrp = character:FindFirstChild("HumanoidRootPart") :: Part?
			local hum = character:FindFirstChildOfClass("Humanoid") :: Humanoid?
			if not hum or not hrp then
				return
			end
			local animator = hum:FindFirstChildOfClass("Animator") :: Animator?

			local victimHum = victim:FindFirstChildOfClass("Humanoid") :: Humanoid?
			local victimHrp = victim:FindFirstChild("HumanoidRootPart") :: Part?
			if not victimHrp or not victimHum then
				return
			end
			local victimAnimator = victimHum:FindFirstChildOfClass("Animator") :: Animator?
			if not animator or not victimAnimator then
				return
			end --^ Nil checks for above variables

			for _, attribute in pairs(PREVENTION_ATTRIBUTES) do
				if character:GetAttribute(attribute) then
					return
				end
			end --^ true checks for attributes in PREVENTION_ATTRIBUTES

			--Carry logic--
			if hrp:FindFirstChild("CarryWeld") then --End carry
				local carryWeld = hrp:FindFirstChild("CarryWeld") :: Weld
				if not stateTracker[player] then
					return
				end
				stateTracker[player] = nil

				print("Down you bastard " .. victim.Name)

				character:SetAttribute("Carrying", false)
				character:SetAttribute("CanClimb", true)
				victim:SetAttribute("Carried", false)

				for _, v in pairs(victim:GetChildren()) do
					if v:IsA("BasePart") then
						v.Massless = false
					end
				end --^ Loop through victim's children and set massless to false
				carryWeld:Destroy() --Destroy weld

				for _, v in pairs(animator:GetPlayingAnimationTracks()) do
					if v.Animation.AnimationId == script.Carrying.AnimationId then
						v:Stop()
					end
				end --^ Stop carrying animation

				for _, v in pairs(victimAnimator:GetPlayingAnimationTracks()) do
					if v.Animation.AnimationId == script.Carried.AnimationId then
						v:Stop()
					end
				end --^ Stop carried animation

				local trigger = victim:FindFirstChild("RagdollTrigger") :: BoolValue?
				if not trigger then
					return
				end
				trigger.Value = true --Trigger ragdoll for Victim
			else --Begin carry
				if stateTracker[player] then
					return
				end
				--^ Checks if player is already carrying or gripping someone

				stateTracker[player] = true

				print("Up you go " .. victim.Name)

				character:SetAttribute("Carrying", true)
				character:SetAttribute("CanClimb", false)
				victim:SetAttribute("Carried", true)

				for _, v in pairs(victim:GetChildren()) do
					if v:IsA("BasePart") then
						v.Massless = true
					end
				end --^ Loop through victim's children and set massless to true

				--Weld victim to player
				local Weld = Instance.new("Weld")
				Weld.Parent = hrp
				Weld.C1 = CFrame.new(-2, -1.5, 0)
				Weld.Part0 = hrp
				Weld.Part1 = victimHrp
				Weld.Name = "CarryWeld"

				local trigger = victim:FindFirstChild("RagdollTrigger") :: BoolValue?
				if not trigger then
					return
				end
				trigger.Value = false --Disable ragdoll for Victim

				--Play animations
				local carriedtrack = victimAnimator:LoadAnimation(script.Carried)
				local carryingtrack = animator:LoadAnimation(script.Carrying)
				carriedtrack:Play()
				carryingtrack:Play()
			end
		end
	end)

	gripEvent.OnServerEvent:Connect(function(player, victim: Model?)
		if victim and player.Character then
			local character = player.Character :: Model?
			if not character then
				return
			end
			local hrp = character:FindFirstChild("HumanoidRootPart") :: Part?
			local hum = character:FindFirstChildOfClass("Humanoid") :: Humanoid?
			if not hrp or not hum then
				return
			end --^ nil checks for above variables
			local animator = hum:FindFirstChildOfClass("Animator") :: Animator?

			local victimHrp = victim:FindFirstChild("HumanoidRootPart") :: Part?
			local victimHum = victim:FindFirstChildOfClass("Humanoid") :: Humanoid?
			if not victimHrp or not victimHum then
				return
			end --^ nil checks for above variables
			local victimAnimator = victimHum:FindFirstChildOfClass("Animator") :: Animator?

			if not animator or not victimAnimator then
				return
			end
			--^ nil checks for above variables

			for _, attribute in pairs(PREVENTION_ATTRIBUTES) do
				if character:GetAttribute(attribute) then
					return
				end
			end --^ true checks for attributes in PREVENTION_ATTRIBUTES

			if stateTracker[player] then
				return
			end
			stateTracker[player] = true

			victimHrp.Anchored = true --Anchor victim's hrp
			victimHrp.CFrame = CFrame.lookAt(victimHrp.Position, victimHrp.Position + Vector3.new(0, 100, 0)) --^ Reposition victim's hrp look

			--Weld player to victim
			local Weld: Weld = Instance.new("Weld")
			Weld.Parent = victimHrp
			Weld.C0 = CFrame.new(0, -1.5, -2.5)
			Weld.C1 = CFrame.new(0, 0, 0) * CFrame.fromEulerAngles(math.rad(-90), math.rad(-180), 0)
			Weld.Part0 = victimHrp
			Weld.Part1 = hrp
			Weld.Name = "GripWeld"

			--Setting attributes
			character:SetAttribute("Gripping", true)
			victim:SetAttribute("Gripped", true)

			--Play animation
			local griptrack: AnimationTrack
			local tool = character:FindFirstChildOfClass("Tool")

			if tool and (tool:GetAttribute("Katana") or tool.Name == "Katana") then
				griptrack = animator:LoadAnimation(script["Grip(Katana)"])
				griptrack:Play()
				griptrack:GetMarkerReachedSignal("Sound"):Once(function()
					local sound = script["Sound(Katana)"]:Clone()
					sound.Parent = character.PrimaryPart :: BasePart
					sound:Play()
					Debris:AddItem(sound, sound.TimeLength)
				end) --^ Play sound on punch marker
			else
				griptrack = animator:LoadAnimation(script["Grip(Fists)"])
				griptrack:Play()
				griptrack:GetMarkerReachedSignal("Sound"):Once(function()
					local sound = script["Sound(Fists)"]:Clone()
					sound.Parent = character.PrimaryPart :: BasePart
					sound:Play()
					Debris:AddItem(sound, sound.TimeLength)
				end) --^ Play sound on punch marker
			end

			griptrack.Stopped:Once(function()
				stateTracker[player] = nil -- Reset state

				--Setting attributes
				character:SetAttribute("Gripping", false)
				victim:SetAttribute("Gripped", false)

				--Kill victim
				local dead: Folder = Instance.new("Folder")
				dead.Parent = victim
				dead.Name = "Dead"
				victimHum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
				victimHum:ChangeState(Enum.HumanoidStateType.Dead)
				victimHum.Health = 0

				RemoveDowned(victim)
				task.delay(3, function()
					victim:Destroy()
				end)

				--if victim:FindFirstChild("Yen") and player then
				--	local yen = victim:FindFirstChild("Yen") :: NumberValue
				--	DataManager.UpdateYen(player, yen.Value)
				--end
				--if victim:FindFirstChild("Exp") and player then
				--	local exp = victim:FindFirstChild("Exp") :: NumberValue
				--	DataManager.UpdateExperience(player, exp.Value)
				--end

				victimHrp.Anchored = false --Unanchor victim's hrp
				Weld:Destroy()
			end) --^ Animation ended
		end
	end)

	reviveEvent.OnServerEvent:Connect(function(player)
		if not player.Character or not player.Character:FindFirstChildOfClass("Humanoid") then
			return
		end --^ nil check for character and humanoid

		local character = player.Character :: Model?
		if not character then
			return
		end
		local hum = character:FindFirstChildOfClass("Humanoid") :: Humanoid?
		if not hum then
			return
		end

		if character:GetAttribute("Knocked") then
			if (hum.Health / hum.MaxHealth) >= 0.15 then -- 15% health threshold
				local trigger = character:FindFirstChild("RagdollTrigger") :: BoolValue?
				if not trigger then
					return
				end

				if trigger.Value == true then
					trigger.Value = false
					RemoveDowned(character)
				end
			end
		end
	end)
end

return module
