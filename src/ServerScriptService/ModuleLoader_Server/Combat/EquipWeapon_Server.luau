local module = {}

function module:Init()
	--//:SERVICES
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ServerStorage = game:GetService("ServerStorage")
	local ServerScriptService = game:GetService("ServerScriptService")
	local Debris = game:GetService("Debris")
	local Players = game:GetService("Players")

	--//:MODULES
	local DataManager = require(ServerScriptService.FunctionModules.Services.ProfileStore.Data.DataManager)

	--//:VARIABLES
	local ANIMATION_TIME = ReplicatedStorage.Values.NumberValues.Combat.Base.EquipAnimationTime.Value

	local remote = ReplicatedStorage.Remotes_Bindables.Remotes.PVP.EquipWeapon :: RemoteEvent
	local bindable = ReplicatedStorage.Remotes_Bindables.Bindables.GeneralPlayer.WeaponChange :: BindableEvent

	local attributesModule = require(ReplicatedStorage.Modules.Tables.Attributes)

	local PREVENTION_ATTRIBUTES = attributesModule.PREVENTION_ATTRIBUTES
	local attributesWithKatanaAnimations = {
		"Blocking",
		"UsingAttack",
		"WeaponIsEquipped",
	}
	local playerConnections = {}

	--//:MODULES
	local HitModule = require(ServerScriptService.FunctionModules.PVP.HitModule)

	--//:FUNCTIONS
	local function playSfx(character: Model, equip: boolean, currentWeapon: string)
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return
		end

		if equip then
			local equipSfx = ReplicatedStorage.FX.SFX.Combat.Weapons.Equip:FindFirstChild(currentWeapon) :: Sound?
			if equipSfx then
				local sfxClone = equipSfx:Clone()

				local timePositionToSet = sfxClone:GetAttribute("TimePosition")
				if
					timePositionToSet
					and type(timePositionToSet) == "number"
					and timePositionToSet < sfxClone.TimeLength
				then
					sfxClone.TimePosition = timePositionToSet
				end
				sfxClone.Parent = hrp
				sfxClone:Play()
				Debris:AddItem(sfxClone, sfxClone.TimeLength)
			end
		else
			local unequipSfx = ReplicatedStorage.FX.SFX.Combat.Weapons.Unequip:FindFirstChild(currentWeapon) :: Sound?
			if unequipSfx then
				local sfxClone = unequipSfx:Clone()

				local timePositionToSet = sfxClone:GetAttribute("TimePosition")
				if timePositionToSet then
					sfxClone.TimePosition = timePositionToSet
				end
				sfxClone.Parent = hrp
				sfxClone:Play()
				Debris:AddItem(sfxClone, sfxClone.TimeLength)
			end
		end
	end

	local function fireAllClients(character: Model, equip: boolean, currentWeapon: string)
		local hum = character:FindFirstChildOfClass("Humanoid")
		if not hum then
			return
		end

		local animator = hum:FindFirstChildOfClass("Animator")
		if not animator then
			return
		end

		local animToPlay = currentWeapon
		local animation: Animation?
		if equip then
			animation = ReplicatedStorage.Animations.Weapons.Equip:FindFirstChild(animToPlay) :: Animation?
		else
			animation = ReplicatedStorage.Animations.Weapons.Unequip:FindFirstChild(animToPlay) :: Animation?
		end
		if not animation then
			return
		end

		HitModule.setStun(character, ANIMATION_TIME, true)
		remote:FireAllClients(animator, animation)
	end

	local function addWeaponModel(character: Model, currentWeapon: string)
		--local existingWeaponModel = character:FindFirstChild("Weapon") :: BasePart?
		--if existingWeaponModel and existingWeaponModel:GetAttribute("Katana") then
		--	return
		--end

		local weapon_fromStorage = ServerStorage.Tools["Other(TOOLS)"].Weapons:FindFirstChild(currentWeapon) :: Tool?
		if weapon_fromStorage then
			local rightArm = character:FindFirstChild("Right Arm") :: BasePart?
			if not rightArm then -- No right arm, exit function.
				return
			end

			local cloneWeapon = weapon_fromStorage:Clone()
			cloneWeapon.Parent = character --Parent weapon (tool) to character so we can copy RightGrip properties to Motor6D later.

			local rightGrip = rightArm:FindFirstChild("RightGrip") :: Weld
			if not rightGrip then -- No right grip, destroy clone weapon and exit function.
				cloneWeapon:Destroy()
				return
			end

			local existing_RightGripMotor = rightArm:FindFirstChild("RightGripMotor") :: Motor6D?
			if existing_RightGripMotor then -- Destroy old Motor6D if it exists.
				existing_RightGripMotor:Destroy()
			end

			local rightGripMotor = Instance.new("Motor6D")
			rightGripMotor.Name = "RightGripMotor"
			rightGripMotor.C0 = rightGrip.C0
			rightGripMotor.C1 = rightGrip.C1

			local handle = weapon_fromStorage:FindFirstChild("Handle") :: BasePart?
			if not handle then
				return
			end
			local cloneHandle = handle:Clone()

			rightGripMotor.Part0 = rightArm
			rightGripMotor.Part1 = cloneHandle
			rightGripMotor.Parent = rightArm

			local existingWeapon = character:FindFirstChild("Weapon")
			if existingWeapon then
				existingWeapon:Destroy()
			end

			cloneHandle.Name = "Weapon"
			cloneHandle.Anchored = false
			cloneHandle.Parent = character

			cloneWeapon:Destroy()
		end

		if currentWeapon == "Katana" then
			local existingSheathe = character:FindFirstChild("Sheathe")
			if existingSheathe then
				existingSheathe:Destroy()
			end

			local sheathe = ServerStorage.Assets.Models.Sheathe

			local sheathe_clone = sheathe:Clone()
			local motor6D = sheathe_clone:FindFirstChildOfClass("Motor6D")
			local torso = character:FindFirstChild("Torso")
			if not torso then
				return
			end
			motor6D.Part0 = torso
			sheathe_clone.Parent = character

			local katanaWeld = sheathe_clone:FindFirstChildOfClass("Weld")
			if not katanaWeld then
				return
			end
			local existingWeapon = character:FindFirstChild("Weapon") :: BasePart?
			if not existingWeapon then
				return
			end
			katanaWeld.Part1 = existingWeapon
		end
	end

	local function _removeWeaponModel(character: Model, _currentWeapon: string)
		local equippedWeapon = character:FindFirstChild("Weapon")
		if equippedWeapon then
			equippedWeapon:Destroy()
		end
	end

	--//:EVENTS
	remote.OnServerEvent:Connect(function(player)
		local character = player.Character
		if not character then
			return
		end
		for _, attr in pairs(PREVENTION_ATTRIBUTES) do
			if character:GetAttribute(attr) then
				return
			end
		end
		if character:GetAttribute("UsingAttack") then
			return
		end
		--^ Safety checks ^--

		local function handleTables()
			if not playerConnections[player] then
				playerConnections[player] = {}
			else
				if not playerConnections[player][character] then
					playerConnections[player][character] = {}

					for _, attr in pairs(attributesWithKatanaAnimations) do
						local attributeChanged_conn: RBXScriptConnection
						attributeChanged_conn = character:GetAttributeChangedSignal(attr):Connect(function()
							local sheathe = character:FindFirstChild("Sheathe")
							if not sheathe then
								return
							end
							local katanaWeld = sheathe:FindFirstChildOfClass("Weld")
							if not katanaWeld then
								return
							end

							if character:GetAttribute(attr) then
								if attr == "Blocking" then
									local currentWeapon = character:GetAttribute("Weapon")
									if currentWeapon == "Katana" and not character:GetAttribute("WeaponIsEquipped") then
										katanaWeld.Enabled = true
										return
									end
								end
								katanaWeld.Enabled = false
							else
								if character:GetAttribute("WeaponIsEquipped") then
									katanaWeld.Enabled = false
									return
								end

								if attr == "WeaponIsEquipped" then --Weapon is being unequipped
									task.delay(ANIMATION_TIME, function()
										katanaWeld.Enabled = true
									end)
								else
									katanaWeld.Enabled = true
								end
							end
						end)
						table.insert(playerConnections[player][character], attributeChanged_conn)
					end
				end
			end
			if not playerConnections[player].CharacterRemoving then
				local characterRemoving_conn: RBXScriptConnection
				characterRemoving_conn = player.CharacterRemoving:Once(function()
					pcall(function()
						for _, conn in pairs(playerConnections[player][character]) do
							conn:Disconnect()
						end
						playerConnections[player][character] = nil
					end)
				end)
				playerConnections[player].CharacterRemoving = characterRemoving_conn
			end
		end
		handleTables()

		local currentWeapon: string = character:GetAttribute("Weapon")
		local weaponIsEquipped: boolean = character:GetAttribute("WeaponIsEquipped")

		if not weaponIsEquipped then -- Equip
			character:SetAttribute("WeaponIsEquipped", true)
			local equip = true

			addWeaponModel(character, currentWeapon)
			playSfx(character, equip, currentWeapon)
			fireAllClients(character, equip, currentWeapon)
		else -- Unequip
			character:SetAttribute("WeaponIsEquipped", false)
			local equip = false

			--task.delay(ANIMATION_TIME, removeWeaponModel, character, currentWeapon)
			playSfx(character, equip, currentWeapon)
			fireAllClients(character, equip, currentWeapon)
		end
	end)

	bindable.Event:Connect(function(character: Model)
		local currentWeapon: string = character:GetAttribute("Weapon")
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			DataManager.UpdateWeapon(player, currentWeapon)
		end

		if currentWeapon ~= "Katana" then --Destroy remaining katana models
			local sheathe = character:FindFirstChild("Sheathe")
			if sheathe then
				sheathe:Destroy()
			end

			local weapon = character:FindFirstChild("Weapon")
			if weapon and weapon:GetAttribute("Katana") then
				weapon:Destroy()
			end
		else
			addWeaponModel(character, currentWeapon)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		if playerConnections[player] then
			for _, conn in pairs(playerConnections[player]) do
				if typeof(conn) == "table" then
					for _, subConn in pairs(conn) do
						subConn:Disconnect()
					end
					conn = nil
				else
					conn:Disconnect()
					conn = nil
				end
			end
			playerConnections[player] = nil
		end
	end)
end

return module
