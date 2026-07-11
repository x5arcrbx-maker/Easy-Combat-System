local module = {}

function module:Init()
	--// SETTINGS
	local MIN_FALL_HEIGHT: number = 35
	local DAMAGE_MULTIPLIER: number = 0.25
	local MAX_DAMAGE: number = 100

	--//:SERVICES
	local Players = game:GetService("Players")
	local Debris = game:GetService("Debris")

	--/:VARIABLES
	local data = setmetatable({}, { __mode = "k" }) :: { [Model]: { RBXScriptConnection } }
	local PREVENTION_ATTRIBUTES_Ragdoll: { string } = {
		"Gripped",
		"Carried",
		"Knocked",
	}

	--//:MODULES
	local RockModule = require(game:GetService("ReplicatedStorage").Modules.Packages.RockModule)

	--//:HELPERS
	local function randomizeSound(rootPart: BasePart)
		local soundsFolder = script:FindFirstChild("Sounds") :: Folder
		if not soundsFolder then
			return
		end

		local sounds = soundsFolder:GetChildren() :: { Sound }
		local randomSound: Sound = sounds[math.random(1, #sounds)]:Clone()

		randomSound.Parent = rootPart
		randomSound:Play()
		randomSound.Ended:Once(function()
			randomSound:Destroy()
		end)
	end

	local function onCharacterRemoving(character: Model)
		if data[character] then
			for _, v: RBXScriptConnection in pairs(data[character]) do
				v:Disconnect()
			end
			data[character] = nil
		end
	end

	--//:MAIN
	local function onCharacterAdded(character: Model)
		data[character] = {}

		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		local rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
		local fallStartY: number = 0

		local stateChangedConnection: RBXScriptConnection
		stateChangedConnection = humanoid.StateChanged:Connect(
			function(oldState: Enum.HumanoidStateType, newState: Enum.HumanoidStateType)
				if newState == Enum.HumanoidStateType.Freefall then
					fallStartY = rootPart.Position.Y
				end

				if
					oldState == Enum.HumanoidStateType.Freefall
					and newState ~= Enum.HumanoidStateType.Freefall
					and (newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running)
				then
					local fallEndY: number = rootPart.Position.Y
					local fallDistance: number = fallStartY - fallEndY
					--If fall distance is less than minimum height, then exit function
					if fallDistance >= MIN_FALL_HEIGHT then
						local damage: number = math.clamp(fallDistance * DAMAGE_MULTIPLIER, 0, MAX_DAMAGE) --math for damage
						humanoid:TakeDamage(damage)
						--tookFallDamage.Value = true --Prevent multiple fall damage

						--Ragdoll on damaged--
						local ragdollTrigger = character:FindFirstChild("RagdollTrigger") :: BoolValue?
						if not ragdollTrigger then
							return
						end

						if not ragdollTrigger.Value then --Ensure player isn't already ragdolled
							ragdollTrigger.Value = true

							randomizeSound(rootPart) --Play random bone-break sound
						end

						local TIME: number = damage / 10 --math that determines ragdoll time
						task.delay(TIME, function()
							for _, v: string in pairs(PREVENTION_ATTRIBUTES_Ragdoll) do
								if character:GetAttribute(v) then
									return
								end
							end --^if player is downed then don't unragdoll
							ragdollTrigger.Value = false
						end)

						--Play vfx when landed--
						local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
						if not hrp then
							return
						end --we'll clone the attachment to the rootpart

						--Clone attachment
						local attachment: Attachment = script:FindFirstChildOfClass("Attachment"):Clone()
						attachment.Parent = hrp
						attachment.Position = attachment.Position + Vector3.new(0, -hrp.Size.Y, 0) --Move it near the bottom of the ground
						Debris:AddItem(attachment, 2)
						local particleEmitters = attachment:GetChildren() :: { ParticleEmitter }

						--Emit particles
						for _, v: ParticleEmitter in pairs(particleEmitters) do
							if not v:IsA("ParticleEmitter") then
								continue
							end

							v.Enabled = false --Disable particles because we'll emit them.
							if v.Name ~= "Shockwave" then
								v:Emit(20)
							else
								v:Emit(1)
							end
						end

						RockModule.Explosion(hrp.CFrame, 10, 0.75, 1.5, false)
					end

					--print("fallDamage function completed")
				end
			end
		)
		table.insert(data[character], stateChangedConnection)

		local ancestryConnection
		ancestryConnection = character.AncestryChanged:Connect(function(_, parent: Instance)
			if not parent then
				onCharacterRemoving(character)
				if ancestryConnection then
					ancestryConnection:Disconnect()
				end
			end
		end)
		table.insert(data[character], ancestryConnection)
	end

	Players.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(onCharacterAdded)
		player.CharacterRemoving:Connect(onCharacterRemoving)
	end)
end

return module
