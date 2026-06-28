--//:SERVICES
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--//:REMOTE EVENTS
local vfxRemote = ReplicatedStorage.Remotes_Bindables.Remotes.GeneralPlayer:WaitForChild("SkillVFX")
local animRemote = ReplicatedStorage.Remotes_Bindables.Remotes.GeneralPlayer:WaitForChild("SkillAnimations")

--//:MODULES
local AnimationService = require(ReplicatedStorage.Modules.Services.AnimationService)
local RockModule = require(ReplicatedStorage.Modules.Packages.RockModule)
local VfxStudioEmitter = require(ReplicatedStorage.Modules.Services.VfxStudioEmitter)

--//VARIABLES
local _Camera = workspace.CurrentCamera
local player = Players.LocalPlayer
local _char = player.Character or player.CharacterAdded:Wait()

local Collection = workspace:FindFirstChild("Collection") :: Folder
local Trash = Collection:FindFirstChild("Trash") :: Folder
local SkillsetsVFX = ReplicatedStorage.FX.VFX.Actions.Combat.Skillsets
local SkillsetsSFX = ReplicatedStorage.FX.SFX.Combat.Skillsets

local attributesModule = require(ReplicatedStorage.Modules.Tables.Attributes)
local PREVENTION_ATTRIBUTES = attributesModule.PREVENTION_ATTRIBUTES

--//:FUNCTIONS
local function _canPlayFX(character: Model): boolean
	-- Check if char  can play FX (not stunned, ragdolled, etc.)
	for _, attribute in ipairs(PREVENTION_ATTRIBUTES) do
		if character:GetAttribute(attribute) then
			return false
		end
	end
	return true
end

local function SFX_Handler(hrp: BasePart, Sound: Sound, Pitch: number?)
	local success: boolean, err: string? = pcall(function()
		if not hrp then
			warn("No HumanoidRootPart given in SFX_Handler")
			return
		end

		if not Sound then
			warn("SFX not given in SFX_Handler.")
			return
		elseif not Sound:IsA("Sound") then
			warn("SFX is not a sound.")
			return
		end

		local cloneSound: Sound = Sound:Clone()
		-- Safely modify pitch if PitchShiftSoundEffect exists
		if Pitch then
			local pitchShift: PitchShiftSoundEffect? = cloneSound:FindFirstChildOfClass("PitchShiftSoundEffect")
			if pitchShift then
				pitchShift.Octave = Pitch
			end
		end

		-- Ensure hrp still exists before parenting
		if hrp.Parent then
			cloneSound.Parent = hrp
			cloneSound:Play()
			-- Add a small buffer to TimeLength to ensure sound plays completely
			Debris:AddItem(cloneSound, math.max(cloneSound.TimeLength, 0.5))
		else
			cloneSound:Destroy() -- Clean up if hrp is invalid
		end
	end)

	if not success then
		warn(err)
	end
end

local function createAfterImages(
	char: Model,
	TIME_BETWEEN: number?,
	AMOUNT: number?,
	TIME_CLONES_LAST: number?,
	EasingStyle: Enum.EasingStyle?,
	EasingDirection: Enum.EasingDirection?,
	playVfx: boolean?,
	VfxObject: Instance?,
	randomizeColor: boolean?,
	color: Color3?
)
	if not char then
		return
	end

	if not TIME_BETWEEN then
		TIME_BETWEEN = 0.1
	end
	if not AMOUNT then
		AMOUNT = 1
	end

	if not TIME_CLONES_LAST then
		TIME_CLONES_LAST = 0.4
	end
	if not EasingStyle then
		EasingStyle = Enum.EasingStyle.Sine
	end
	if not EasingDirection then
		EasingDirection = Enum.EasingDirection.In
	end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	task.spawn(function()
		--print("afterImage func ran")

		local cloneFolder = Instance.new("Folder")
		cloneFolder.Name = "AfterImage_TrashFolder"
		cloneFolder.Parent = Trash

		for _ = 1, AMOUNT do
			if playVfx and VfxObject then
				local vfxObjectClone = VfxObject:Clone()

				vfxObjectClone.Parent = hrp
				VfxStudioEmitter:TriggerEffects(vfxObjectClone)

				Debris:AddItem(vfxObjectClone, 3)
			end

			local characterChildren = char:GetChildren()

			for _, v: BasePart in pairs(characterChildren) do
				if v:IsA("BasePart") then
					local clone = v:Clone()
					for _, obj in pairs(clone:GetChildren()) do
						obj:Destroy()
					end
					clone.Anchored = true
					clone.CanCollide = false
					clone.CastShadow = false
					if randomizeColor then
						color = Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255))
					elseif not color then
						color = Color3.fromRGB(0, 0, 0)
					end
					clone.Color = color
					clone.Material = Enum.Material.Neon
					clone.Transparency = 0
					clone.Parent = cloneFolder

					--print("Created part for after image")

					TweenService
						:Create(
							clone,
							TweenInfo.new(TIME_CLONES_LAST, EasingStyle, EasingDirection),
							{ Transparency = 1 }
						)
						:Play()
				end
			end
			task.wait(TIME_BETWEEN)
		end
		Debris:AddItem(cloneFolder, TIME_CLONES_LAST)

		--print("afterImage func ended")
	end)
end
--------------

--//:MAIN

local vfxFunctions =
	{
		["Clash_Sharp"] = function(hrp: BasePart?)
			if hrp and hrp.Parent then
				local attachment: Attachment = Instance.new("Attachment")
				attachment.Parent = hrp
				--Play sound first
				local SFX: Sound = ReplicatedStorage.FX.SFX.Combat.General.Clash.Sharp:Clone()
				local pitch = math.random(75, 125) / 100
				SFX_Handler(hrp, SFX, pitch)

				local VFX = ReplicatedStorage.FX.VFX.Actions.Combat.Clash.Sharp
				for _, obj in pairs(VFX:GetChildren()) do
					if obj:IsA("ParticleEmitter") then
						local clone = obj:Clone()
						clone.Parent = attachment
						clone.Enabled = false
						clone:Emit(1)
					end
					if obj:IsA("PointLight") then
						local clone = obj:Clone()
						clone.Parent = attachment
						clone.Enabled = true
						TweenService:Create(
							clone,
							TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0),
							{ Brightness = 0 }
						):Play()
					end
				end
				Debris:AddItem(attachment, 0.5)
			end
		end,

		["Clash_Blunt"] = function(hrp: BasePart?)
			if hrp and hrp.Parent then
				local attachment: Attachment = Instance.new("Attachment")
				attachment.Parent = hrp
				--Play sound first
				local SFX: Sound = ReplicatedStorage.FX.SFX.Combat.General.Clash.Blunt:Clone()
				local pitch = math.random(75, 125) / 100
				SFX_Handler(hrp, SFX, pitch)

				local VFX: Folder = ReplicatedStorage.FX.VFX.Actions.Combat.Clash.Blunt
				for _, obj in pairs(VFX:GetChildren()) do
					if obj:IsA("ParticleEmitter") then
						local clone = obj:Clone()
						clone.Parent = attachment
						clone.Enabled = false
						clone:Emit(1)
					end
				end
				Debris:AddItem(attachment, 0.5)
			end
		end,

		["NormalAttack"] = function(hrp: BasePart?)
			if hrp and hrp.Parent then
				local _character = hrp.Parent

				local hitType: string
				local weapon = hrp.Parent:GetAttribute("Weapon")
				if weapon == "Katana" then
					hitType = "Sharp"
				else
					hitType = "Blunt"
				end

				local function playSFX() --SFX
					--SFX logic
					if hitType == "Sharp" then --Checking if player is using Katana
						local SFX: Sound = ReplicatedStorage.FX.SFX.Combat.Katana.SwingM1:Clone()
						local pitch = math.random(75, 125) / 100
						SFX_Handler(hrp, SFX, pitch)
					elseif hitType == "Blunt" then --Checking if player is using Fists
						local SFX: Sound = ReplicatedStorage.FX.SFX.Combat.Fists.SwingM1:Clone()
						local pitch = math.random(75, 125) / 100
						SFX_Handler(hrp, SFX, pitch)
					end
				end

				local function playVFX() --VFX
					--VFX logic
					if hitType == "Sharp" then
						local weaponHandle = hrp.Parent:FindFirstChild("Weapon") :: BasePart?
						if weaponHandle then
							local trail = weaponHandle:FindFirstChildOfClass("Trail")
							if trail then
								trail.Enabled = true
								task.delay(0.3, function()
									trail.Enabled = false
								end)
							end
						end
					end
				end

				playSFX()
				playVFX()
			end
		end,

		["HeavyAttack"] = function(hrp: BasePart?)
			if hrp and hrp.Parent then
				local character = hrp.Parent

				local hitType: string
				local weapon = hrp.Parent:GetAttribute("Weapon")
				if weapon == "Katana" then
					hitType = "Sharp"
				else
					hitType = "Blunt"
				end

				local function playVFX() --VFX logic
					--VFX logic
					if hitType == "Sharp" then
						local weaponHandle = hrp.Parent:FindFirstChild("Weapon") :: BasePart?
						if weaponHandle then
							local trail = weaponHandle:FindFirstChildOfClass("Trail")
							if trail then
								trail.Enabled = true
								task.delay(0.3, function()
									trail.Enabled = false
								end)
							end
						end
					end
				end

				local function playSFX() --SFX logic
					--SFX logic
					if hitType == "Sharp" then --Checking if player is using Katana
						local SFX: Sound = ReplicatedStorage.FX.SFX.Combat.Katana.SwingM2:Clone()
						local pitch = math.random(75, 125) / 100
						SFX_Handler(hrp, SFX, pitch)
					elseif hitType == "Blunt" then --Checking if player is using Fists
						local SFX: Sound = ReplicatedStorage.FX.SFX.Combat.Fists.SwingM2:Clone()
						local pitch = math.random(75, 125) / 100
						SFX_Handler(hrp, SFX, pitch)
					end
				end

				local function playIndicator() --Indicator / Highlight VFX
					-- local M2VFX1 = ReplicatedStorage.FX.VFX.Actions.Combat.M2Indicator.M2VFX1:Clone() :: ParticleEmitter
					-- local M2VFX = Instance.new("Attachment")
					-- M2VFX.Parent = hrp
					-- M2VFX.CFrame = CFrame.new(0, 0, -1)
					-- M2VFX1.Parent = M2VFX
					-- M2VFX1:Emit(1)
					-- Debris:AddItem(M2VFX, 0.6)

					local highlight: Highlight = Instance.new("Highlight")
					highlight.FillColor = Color3.fromRGB(255, 115, 0)
					highlight.FillTransparency = 0.75
					highlight.OutlineColor = Color3.fromRGB(0, 0, 0) --Color3.fromRGB(255, 115, 0)
					highlight.OutlineTransparency = 0.5
					highlight.DepthMode = Enum.HighlightDepthMode.Occluded
					highlight.Parent = character
					TweenService:Create(
						highlight,
						TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0),
						{
							FillTransparency = 1,
							--OutlineTransparency = 1
						}
					):Play()
					Debris:AddItem(highlight, 0.45)
					task.delay(0.45, function() --Delay playing SFX and VFX for when Heavy Attack hits
						playVFX()
						playSFX()
					end)
				end

				playIndicator() --Play indicator immediately compared to the SFX/VFX
			end
		end,
	}

--	Plays VFX on the client
vfxRemote.OnClientEvent:Connect(function(hrp: BasePart, vfxToPlay: string?)
	if not hrp then
		warn("Hrp is missing or invalid")
		return
	elseif not hrp.Parent then
		warn("Hrp parent is missing or invalid")
		return
	end
	if not vfxToPlay then
		warn("VFX name is missing")
		return
	end

	local character_instance = hrp.Parent
	local anim_hum = character_instance:FindFirstChildOfClass("Humanoid") :: Humanoid
	if not anim_hum then
		warn("Humanoid not found for character")
		return
	end

	--//:FUNCTIONS
	local vfxFunction = vfxFunctions[vfxToPlay]
	if vfxFunction then
		vfxFunction(hrp)
		return
	end

	------------------
	-- Nonskill VFX --
	------------------
	--[[
	--Clashes
	if vfxToPlay == "Clash_Sharp" then -- Sharp Clash VFX
		local attachment: Attachment = Instance.new("Attachment")
		attachment.Parent = hrp
		--Play sound first
		local SFX: Sound = ReplicatedStorage.FX.SFX.Combat.General.Clash.Sharp:Clone()
		local pitch = math.random(75, 125) / 100
		SFX_Handler(hrp, SFX, pitch)

		local VFX = ReplicatedStorage.FX.VFX.Actions.Combat.Clash.Sharp
		for _, obj in pairs(VFX:GetChildren()) do
			if obj:IsA("ParticleEmitter") then
				local clone = obj:Clone()
				clone.Parent = attachment
				clone.Enabled = false
				clone:Emit(1)
			end
			if obj:IsA("PointLight") then
				local clone = obj:Clone()
				clone.Parent = attachment
				clone.Enabled = true
				TweenService:Create(
					clone,
					TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0),
					{ Brightness = 0 }
				):Play()
			end
		end
		Debris:AddItem(attachment, 0.5)
	elseif vfxToPlay == "Clash_Blunt" then -- Blunt Clash VFX
		local attachment: Attachment = Instance.new("Attachment")
		attachment.Parent = hrp
		--Play sound first
		local SFX: Sound = ReplicatedStorage.FX.SFX.Combat.General.Clash.Blunt:Clone()
		local pitch = math.random(75, 125) / 100
		SFX_Handler(hrp, SFX, pitch)

		local VFX: Folder = ReplicatedStorage.FX.VFX.Actions.Combat.Clash.Blunt
		for _, obj in pairs(VFX:GetChildren()) do
			if obj:IsA("ParticleEmitter") then
				local clone = obj:Clone()
				clone.Parent = attachment
				clone.Enabled = false
				clone:Emit(1)
			end
		end
		Debris:AddItem(attachment, 0.5)
	end

	-----------------
	-- Base Combat --
	-----------------
	if vfxToPlay == "NormalAttack" then
		if hrp.Parent then
			local hitType: string
			local tool = hrp.Parent:FindFirstChildOfClass("Tool")
			if tool and (tool.Name == "Katana" or tool:GetAttribute("Katana")) then
				hitType = "Sharp"
			else
				hitType = "Blunt"
			end

			local function playSFX() --SFX
				--SFX logic
				if hitType == "Sharp" then --Checking if player is using Katana
					local SFX: Sound = ReplicatedStorage.FX.SFX.Combat.Katana.SwingM1:Clone()
					local pitch = math.random(75, 125) / 100
					SFX_Handler(hrp, SFX, pitch)
				elseif hitType == "Blunt" then --Checking if player is using Fists
					local SFX: Sound = ReplicatedStorage.FX.SFX.Combat.Fists.SwingM1:Clone()
					local pitch = math.random(75, 125) / 100
					SFX_Handler(hrp, SFX, pitch)
				end
			end

			local function playVFX() --VFX
				--VFX logic
				if hitType == "Sharp" then
					local handle = tool:FindFirstChild("Handle")
					if handle then
						local trail = handle:FindFirstChildOfClass("Trail")
						if trail then
							trail.Enabled = true
							task.delay(0.3, function()
								trail.Enabled = false
							end)
						end
					end
				end
			end

			playSFX()
			playVFX()
		end
	end

	if vfxToPlay == "HeavyAttack" then
		if hrp.Parent then
			local hitType: string
			local character = hrp.Parent
			local tool = character:FindFirstChildOfClass("Tool")
			if tool and (tool.Name == "Katana" or tool:GetAttribute("Katana")) then
				hitType = "Sharp"
			else
				hitType = "Blunt"
			end

			local function playVFX() --VFX logic
				--VFX logic
				if hitType == "Sharp" then
					local handle = tool:FindFirstChild("Handle")
					if handle then
						local trail = handle:FindFirstChildOfClass("Trail")
						if trail then
							trail.Enabled = true
							task.delay(0.3, function()
								trail.Enabled = false
							end)
						end
					end
				end
			end

			local function playSFX() --SFX logic
				--SFX logic
				if hitType == "Sharp" then --Checking if player is using Katana
					local SFX: Sound = ReplicatedStorage.FX.SFX.Combat.Katana.SwingM2:Clone()
					local pitch = math.random(75, 125) / 100
					SFX_Handler(hrp, SFX, pitch)
				elseif hitType == "Blunt" then --Checking if player is using Fists
					local SFX: Sound = ReplicatedStorage.FX.SFX.Combat.Fists.SwingM2:Clone()
					local pitch = math.random(75, 125) / 100
					SFX_Handler(hrp, SFX, pitch)
				end
			end

			local function playIndicator() --Indicator / Highlight VFX
				-- local M2VFX1 = ReplicatedStorage.FX.VFX.Actions.Combat.M2Indicator.M2VFX1:Clone() :: ParticleEmitter
				-- local M2VFX = Instance.new("Attachment")
				-- M2VFX.Parent = hrp
				-- M2VFX.CFrame = CFrame.new(0, 0, -1)
				-- M2VFX1.Parent = M2VFX
				-- M2VFX1:Emit(1)
				-- Debris:AddItem(M2VFX, 0.6)

				local highlight: Highlight = Instance.new("Highlight")
				highlight.FillColor = Color3.fromRGB(255, 115, 0)
				highlight.FillTransparency = 0.75
				highlight.OutlineColor = Color3.fromRGB(0,0,0)	--Color3.fromRGB(255, 115, 0)
				highlight.OutlineTransparency = 0.5
				highlight.DepthMode = Enum.HighlightDepthMode.Occluded
				highlight.Parent = character
				TweenService:Create(
					highlight,
					TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0),
					{ 
						FillTransparency = 1,
						--OutlineTransparency = 1 
					}
				):Play()
				Debris:AddItem(highlight, 0.45)
				task.delay(0.45, function() --Delay playing SFX and VFX for when Heavy Attack hits
					playVFX()
					playSFX()
				end)
			end

			playIndicator() --Play indicator immediately compared to the SFX/VFX
		end
	end
	]]

	-----------------
	-- Skill VFX --
	-----------------

	--	BDAs  --
	--Akaza
	--[[
	-- if vfxToPlay == "Annihilation Type: Punch" then
	-- 	local function playVFX(hrpPosition: Vector3, hrpLookVector: Vector3)
	-- 		--print('Played VFX!')

	-- 		--Creating variables
	-- 		local VFX: Folder = SkillsetsVFX.BDAs.Akaza.AnnihilationType --Folder of VFX

	-- 		local inwardShockwave: MeshPart = VFX.InwardShockwave:Clone()
	-- 		local outwardShockwave: MeshPart = VFX.OutwardShockwave:Clone()
	-- 		local ring: MeshPart = VFX.Ring:Clone()
	-- 		local Shockwave: MeshPart = VFX.Shockwave:Clone()

	-- 		local energyFX: ParticleEmitter = Shockwave.VFX_Attachment.Energy
	-- 		local ringFX: ParticleEmitter = Shockwave.VFX_Attachment2.Ring
	-- 		local burstFX: ParticleEmitter = Shockwave.VFX_Attachment2.Burst

	-- 		energyFX.Enabled = true
	-- 		ringFX.Enabled = false
	-- 		burstFX.Enabled = false

	-- 		--Initial Transparency
	-- 		inwardShockwave.Transparency = 0
	-- 		outwardShockwave.Transparency = 0
	-- 		ring.Transparency = 0
	-- 		Shockwave.Transparency = 0

	-- 		--Initial Size
	-- 		inwardShockwave.Size = Vector3.new(5, 7.5, 5) * 1.25
	-- 		outwardShockwave.Size = Vector3.new(4.75, 15, 4.75) * 1.25
	-- 		ring.Size = Vector3.new(0, 0, 0)
	-- 		Shockwave.Size = Vector3.new(7, 7, 12.5) * 1.5

	-- 		--Parenting to workspace
	-- 		inwardShockwave.Parent = Trash
	-- 		outwardShockwave.Parent = Trash
	-- 		ring.Parent = Trash
	-- 		Shockwave.Parent = Trash

	-- 		local lookAtPos = hrpPosition + hrpLookVector

	-- 		--CFrames
	-- 		inwardShockwave.CFrame = CFrame.lookAt(hrpPosition, lookAtPos) * CFrame.Angles(math.rad(90), 0, 0)
	-- 		outwardShockwave.CFrame = CFrame.lookAt(hrpPosition, lookAtPos) * CFrame.Angles(math.rad(90), 0, 0)
	-- 		outwardShockwave.Position = hrpPosition + (hrpLookVector * 3)
	-- 		ring.CFrame = CFrame.lookAt(hrpPosition, lookAtPos)
	-- 		Shockwave.CFrame = CFrame.lookAt(hrpPosition, lookAtPos)

	-- 		--Tween info
	-- 		local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 5, false, 0) -- Rotation tween info
	-- 		local tweenInfo2 = TweenInfo.new(0.5, Enum.EasingStyle.Circular, Enum.EasingDirection.Out, 0, false, 0) -- Size/Position tween
	-- 		local tweenInfo3 = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0) -- Transparency tween

	-- 		--   TWEENS   --

	-- 		--Size
	-- 		local inwardTween_Size = TweenService:Create(inwardShockwave, tweenInfo2, { Size = Vector3.new(0, 2.5, 0) })

	-- 		local outwardTween_Size = TweenService:Create(outwardShockwave, tweenInfo2, { Size = Vector3.new(0, 5, 0) })

	-- 		local ringTween_Size = TweenService:Create(ring, tweenInfo2, { Size = Vector3.new(5, 5, 0.04) * 1.75 })

	-- 		local ShockwaveTween_Size = TweenService:Create(Shockwave, tweenInfo2, { Size = Vector3.new(0, 0, 2.5) })

	-- 		--Position
	-- 		local inwardTween_Position = TweenService:Create(
	-- 			inwardShockwave,
	-- 			tweenInfo2,
	-- 			{ Position = inwardShockwave.Position + (hrpLookVector * 7) }
	-- 		)

	-- 		local outwardTween_Position = TweenService:Create(
	-- 			outwardShockwave,
	-- 			tweenInfo2,
	-- 			{ Position = outwardShockwave.Position + (hrpLookVector * 7) }
	-- 		)

	-- 		local ringTween_Position =
	-- 			TweenService:Create(ring, tweenInfo2, { Position = ring.Position + (hrpLookVector * 3) })

	-- 		local ShockwaveTween_Position =
	-- 			TweenService:Create(Shockwave, tweenInfo2, { Position = Shockwave.Position + (hrpLookVector * 15) })

	-- 		--Transparency
	-- 		local inwardTween_Transparency = TweenService:Create(inwardShockwave, tweenInfo3, { Transparency = 1 })

	-- 		local outwardTween_Transparency = TweenService:Create(outwardShockwave, tweenInfo3, { Transparency = 1 })

	-- 		local ringTween_Transparency = TweenService:Create(ring, tweenInfo3, { Transparency = 1 })

	-- 		local ShockwaveTween_Transparency = TweenService:Create(Shockwave, tweenInfo3, { Transparency = 1 })

	-- 		--Rotation
	-- 		local inwardTween_Rotation = TweenService:Create(
	-- 			inwardShockwave,
	-- 			tweenInfo,
	-- 			{ CFrame = inwardShockwave.CFrame * CFrame.Angles(0, math.rad(5000), 0) }
	-- 		)

	-- 		local outwardTween_Rotation = TweenService:Create(
	-- 			outwardShockwave,
	-- 			tweenInfo,
	-- 			{ CFrame = outwardShockwave.CFrame * CFrame.Angles(0, math.rad(5000), 0) }
	-- 		)

	-- 		--Playing Tweens
	-- 		--SIZE
	-- 		inwardTween_Size:Play()
	-- 		outwardTween_Size:Play()
	-- 		ringTween_Size:Play()
	-- 		ShockwaveTween_Size:Play()

	-- 		--POSITION
	-- 		inwardTween_Position:Play()
	-- 		outwardTween_Position:Play()
	-- 		ringTween_Position:Play()
	-- 		ShockwaveTween_Position:Play()

	-- 		--TRANSPARENCY
	-- 		inwardTween_Transparency:Play()
	-- 		outwardTween_Transparency:Play()

	-- 		--Emitting VFX
	-- 		task.delay(0.075, function()
	-- 			ringFX:Emit(1)
	-- 			burstFX:Emit(1)
	-- 		end)

	-- 		--TRANSPARENCY
	-- 		task.delay(0.25, function()
	-- 			ShockwaveTween_Transparency:Play()
	-- 			energyFX.Enabled = false
	-- 		end)
	-- 		ringTween_Transparency:Play()

	-- 		--ROTATION
	-- 		inwardTween_Rotation:Play()
	-- 		outwardTween_Rotation:Play()

	-- 		--Cleanup (Debris)
	-- 		Debris:AddItem(inwardShockwave, 1)
	-- 		Debris:AddItem(outwardShockwave, 1)
	-- 		Debris:AddItem(ring, 1)
	-- 		Debris:AddItem(Shockwave, 2)
	-- 		Debris:AddItem(energyFX, 1.5)
	-- 		Debris:AddItem(ringFX, 0.6)
	-- 		Debris:AddItem(burstFX, 0.6)
	-- 	end
	-- 	playVFX(hrp.Position, hrp.CFrame.LookVector)

	-- 	local SFX_Folder = SkillsetsSFX.BDAs.Akaza[vfxToPlay]
	-- 	for _, sound in pairs(SFX_Folder:GetChildren()) do
	-- 		SFX_Handler(hrp, sound, 1)
	-- 	end
	-- end

	-- if vfxToPlay == "Chaotic Blue Metal Afterglow" then

	-- end

	-- if vfxToPlay == "Flying Planet" then
	-- 	local function playVFX(hrpPosition: Vector3, hrpLookVector: Vector3)
	-- 		--Creating variables
	-- 		local VFX: Folder = SkillsetsVFX.BDAs.Akaza.FlyingPlanet

	-- 		local insideSpiral: MeshPart = VFX.InsideSpiral:Clone()
	-- 		local outsideSpiral: MeshPart = VFX.OutsideSpiral:Clone()
	-- 		local ring: MeshPart = VFX.Ring:Clone()
	-- 		local Shockwave: MeshPart = VFX.Shockwave:Clone()

	-- 		--Enable shockwave sub-effects
	-- 		local sparklesFX: ParticleEmitter = Shockwave.VFX_Attachment1.Sparkles
	-- 		local ringFX: ParticleEmitter = Shockwave.VFX_Attachment2.Ring
	-- 		local energyFX: ParticleEmitter = Shockwave.VFX_Attachment1.Energy

	-- 		sparklesFX.Enabled = true
	-- 		ringFX.Enabled = false
	-- 		energyFX.Enabled = true
	-- 		task.delay(0.1, function()
	-- 			ringFX:Emit(1)
	-- 		end)

	-- 		--Initial Transparency
	-- 		insideSpiral.Transparency = 0
	-- 		outsideSpiral.Transparency = 0.9
	-- 		ring.Transparency = 0
	-- 		Shockwave.Transparency = 0

	-- 		--Initial Sizes
	-- 		insideSpiral.Size = Vector3.new(25, 10, 20) * 1.25
	-- 		outsideSpiral.Size = Vector3.new(5, 0, 5) * 1.25
	-- 		ring.Size = Vector3.new(0, 0, 0)
	-- 		Shockwave.Size = Vector3.new(7, 7, 12.5) * 1.5

	-- 		--Parenting
	-- 		insideSpiral.Parent = Trash
	-- 		outsideSpiral.Parent = Trash
	-- 		ring.Parent = Trash
	-- 		Shockwave.Parent = Trash

	-- 		--UPWARD DIRECTION
	-- 		local up = Vector3.new(0, 1, 0)
	-- 		local lookAtPos = hrpPosition + hrpLookVector

	-- 		--CFrames (face upward)
	-- 		insideSpiral.CFrame = CFrame.lookAt(hrpPosition, hrpPosition)
	-- 		outsideSpiral.CFrame = CFrame.lookAt(hrpPosition, hrpPosition)
	-- 		ring.CFrame = CFrame.lookAt(hrpPosition, hrpPosition)
	-- 		Shockwave.CFrame = CFrame.lookAt(hrpPosition, lookAtPos) * CFrame.Angles(math.rad(90), 0, 0)

	-- 		--Initial Placement (Upward instead of forward)
	-- 		insideSpiral.Position = hrpPosition + up * 2.5
	-- 		outsideSpiral.Position = hrpPosition + up * 9

	-- 		--Tween info
	-- 		local tweenInfoRotate = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 5, false, 0)
	-- 		local tweenInfoSize = TweenInfo.new(0.5, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)
	-- 		local tweenInfoTrans = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	-- 		--Tweens
	-- 		local inward_Size = TweenService:Create(insideSpiral, tweenInfoSize, {
	-- 			Size = Vector3.new(0, 7.5, 0),
	-- 		})

	-- 		local outward_Size = TweenService:Create(outsideSpiral, tweenInfoSize, {
	-- 			Size = Vector3.new(7, 17, 7) * 1.25,
	-- 		})

	-- 		local ring_Size = TweenService:Create(ring, tweenInfoSize, {
	-- 			Size = Vector3.new(5, 0.05, 5) * 1.75,
	-- 		})

	-- 		local Shockwave_Size = TweenService:Create(Shockwave, tweenInfoSize, {
	-- 			Size = Vector3.new(0.5, 0.5, 2),
	-- 		})

	-- 		--Position tweens (UPWARD MOVEMENT)
	-- 		local inward_Pos = TweenService:Create(insideSpiral, tweenInfoSize, {
	-- 			Position = insideSpiral.Position + up * 6.5,
	-- 		})

	-- 		local ring_Pos = TweenService:Create(ring, tweenInfoSize, {
	-- 			Position = ring.Position + up * 3,
	-- 		})

	-- 		local Shockwave_Pos = TweenService:Create(Shockwave, tweenInfoSize, {
	-- 			Position = Shockwave.Position + up * 17,
	-- 		})

	-- 		--Transparency tweens
	-- 		local inward_Trans = TweenService:Create(insideSpiral, tweenInfoTrans, {
	-- 			Transparency = 1,
	-- 		})

	-- 		local outward_Trans = TweenService:Create(outsideSpiral, tweenInfoTrans, {
	-- 			Transparency = 1,
	-- 		})

	-- 		local ring_Trans = TweenService:Create(ring, tweenInfoTrans, {
	-- 			Transparency = 1,
	-- 		})

	-- 		local Shockwave_Trans = TweenService:Create(Shockwave, tweenInfoTrans, {
	-- 			Transparency = 1,
	-- 		})

	-- 		--Rotation tweens (spin around Y-axis)
	-- 		local inward_Rotation = TweenService:Create(
	-- 			insideSpiral,
	-- 			tweenInfoRotate,
	-- 			{ CFrame = insideSpiral.CFrame * CFrame.Angles(0, math.rad(360), 0) }
	-- 		)

	-- 		local outward_Rotation = TweenService:Create(
	-- 			outsideSpiral,
	-- 			tweenInfoRotate,
	-- 			{ CFrame = outsideSpiral.CFrame * CFrame.Angles(0, math.rad(360), 0) }
	-- 		)

	-- 		--Play tweens
	-- 		inward_Size:Play()
	-- 		outward_Size:Play()
	-- 		ring_Size:Play()
	-- 		Shockwave_Size:Play()

	-- 		inward_Pos:Play()
	-- 		ring_Pos:Play()
	-- 		Shockwave_Pos:Play()

	-- 		task.delay(0.2, function()
	-- 			inward_Trans:Play()
	-- 			Shockwave_Trans:Play()
	-- 			sparklesFX.Enabled = false
	-- 			energyFX.Enabled = false
	-- 		end)

	-- 		outward_Trans:Play()
	-- 		ring_Trans:Play()

	-- 		inward_Rotation:Play()
	-- 		outward_Rotation:Play()

	-- 		--Cleanup
	-- 		Debris:AddItem(insideSpiral, 1)
	-- 		Debris:AddItem(outsideSpiral, 1)
	-- 		Debris:AddItem(ring, 1)
	-- 		Debris:AddItem(energyFX, 1)
	-- 		Debris:AddItem(Shockwave, 2)
	-- 		Debris:AddItem(ringFX, 0.6)
	-- 		Debris:AddItem(sparklesFX, 2)
	-- 	end
	-- 	playVFX(hrp.Position, hrp.CFrame.LookVector)
	-- end

	-- if vfxToPlay == "Crush Type" then
	-- 	local function playVFX(hrpCFrame: CFrame)
	-- 		-- Create the attachment for VFX
	-- 		local attachment: Attachment = Instance.new("Attachment")
	-- 		attachment.Parent = hrp
	-- 		attachment.Position = Vector3.new(0, -2.5, 0) -- Move it down 2.5 studs
	-- 		Debris:AddItem(attachment, 1)

	-- 		-- Clone and apply all particle emitters
	-- 		local VFX: Folder = SkillsetsVFX.BDAs.Akaza.CrushType

	-- 		for _, obj in pairs(VFX:GetChildren()) do
	-- 			if obj:IsA("ParticleEmitter") then
	-- 				local clone = obj:Clone()
	-- 				clone.Parent = attachment
	-- 				clone.Enabled = false
	-- 				clone:Emit(1)
	-- 			end

	-- 			if obj:IsA("Attachment") then
	-- 				local clone = obj:Clone()
	-- 				clone.Parent = hrp
	-- 				clone.Position = Vector3.new(0, -2.5, 0) -- Move it down 2.5 studs
	-- 				Debris:AddItem(clone, 1)

	-- 				for _, obj2 in pairs(clone:GetChildren()) do
	-- 					if obj2:IsA("ParticleEmitter") then
	-- 						obj2.Enabled = false
	-- 						obj2:Emit(1)
	-- 					end
	-- 				end
	-- 			end
	-- 		end

	-- 		RockModule.Crater(hrpCFrame, 12.5, 20, 20, false)
	-- 		task.delay(0.3, function()
	-- 			RockModule.ClearDebris(true)
	-- 		end)
	-- 	end
	-- 	playVFX(hrp.CFrame)

	-- 	local SFX_Folder = SkillsetsSFX.BDAs.Akaza[vfxToPlay]
	-- 	for _, sound in pairs(SFX_Folder:GetChildren()) do
	-- 		SFX_Handler(hrp, sound, 1)
	-- 	end
	-- end
	]]

	--Doma
	if vfxToPlay == "Freezing Clouds" then
		local function playVFX(hrpPosition: Vector3, hrpLookVector: Vector3)
			--Creating variables
			local VFX: Part = SkillsetsVFX.BDAs.Doma["Freezing Clouds"]

			VFX = VFX:Clone()
			VFX.Parent = Trash
			VFX.CFrame = CFrame.lookAlong(hrpPosition + (hrpLookVector * 6), hrpLookVector)
			VFX.Orientation = VFX.Orientation + Vector3.new(0, -90, 0)

			local weld = Instance.new("WeldConstraint")
			weld.Part0 = VFX
			weld.Part1 = hrp
			weld.Parent = VFX

			local Vfx_descendants = VFX:GetDescendants()
			for _, v in pairs(Vfx_descendants) do
				if v:IsA("ParticleEmitter") then
					v.Enabled = false
					task.spawn(function()
						for _ = 1, 10 do
							v:Emit(10)
							task.wait(0.05)
						end
					end)
				end
			end

			Debris:AddItem(VFX, 4)
		end
		playVFX(hrp.Position, hrp.CFrame.LookVector)

		local function playSFX()
			local SFX: Sound = ReplicatedStorage.FX.SFX.Combat.Skillsets.BDAs.Doma[vfxToPlay]
			for _, sound in pairs(SFX:GetChildren()) do
				local sound_clone = sound:Clone()
				SFX_Handler(hrp, sound_clone)
			end
		end
		playSFX()
	end

	if vfxToPlay == "Barren Hanging Garden" then
		local function playSFX()
			local SFX: Sound = ReplicatedStorage.FX.SFX.Combat.Skillsets.BDAs.Doma[vfxToPlay]
			for _, sound in pairs(SFX:GetChildren()) do
				local sound_clone = sound:Clone()
				SFX_Handler(hrp, sound_clone, math.random(90, 110) / 100)
			end
		end

		local function playVFX()
			local mesh = SkillsetsVFX.BDAs.Doma.BarrenHangingGarden

			for _ = 1, 8 do
				if not hrp then
					break
				end
				playSFX()

				mesh = mesh:Clone()
				mesh.Parent = Trash
				mesh.CFrame = CFrame.lookAlong(hrp.Position + (hrp.CFrame.UpVector * 2), hrp.CFrame.LookVector)
				mesh.Orientation = mesh.Orientation
					+ Vector3.new(math.random(-45, 45), math.random(-100, -70), math.random(-150, -125))
				Debris:AddItem(mesh, 1)

				--Tweens
				TweenService:Create( --Orientation
					mesh,
					TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0),
					{ Orientation = mesh.Orientation + Vector3.new(0, 0, math.random(70, 100)) }
				):Play()
				TweenService:Create( --Transparency
					mesh,
					TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0),
					{ Transparency = 1 }
				):Play()
				TweenService:Create( --Size
					mesh,
					TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0),
					{ Size = mesh.Size + Vector3.new(1, 1, 0) }
				):Play()

				--Particles
				for _, v: Instance in pairs(mesh:GetDescendants()) do
					if v:IsA("ParticleEmitter") then
						v.Enabled = false
						task.spawn(function()
							if v.Name ~= "TransparentShock1" then
								if v.Name ~= "Effect_WhiteGlow" and v.Name ~= "PARTICLE Snowflake" then
									for _ = 1, 3 do --not a white glow or snowflake, emit less
										v:Emit(1)
										task.wait(0.15)
									end
								else --IS a white glow or snowflake, emit more
									for _ = 1, 10 do
										v:Emit(1)
										task.wait(0.05)
									end
								end
							else --Shockwave only emits once
								v:Emit(1)
							end
						end)
					end
				end
				task.wait(0.15)
			end
		end
		playVFX() --playSFX is called inside playVFX's forloop
	end

	if vfxToPlay == "Frozen Lotus" then
		local function playVFX()
			local part: BasePart = SkillsetsVFX.BDAs.Doma["Frozen Lotus"]

			--//MAIN
			part = part:Clone()
			part.Parent = Trash
			part.CFrame = CFrame.lookAlong(
				hrp.Position
					+ ((hrp.CFrame.UpVector * (part.Size.Y / 3.75)) + (hrp.CFrame.LookVector * (part.Size.Z / 2))),
				hrp.CFrame.LookVector
			)
			Debris:AddItem(part, 5)

			--Particles
			for _, v: Instance in pairs(part:GetDescendants()) do
				if v:IsA("ParticleEmitter") then
					v.Enabled = false

					task.spawn(function()
						if v.Name ~= "Effect_WhiteGlow" and v.Name ~= "PARTICLE Snowflake" then
							for _ = 1, 15 do --not a white glow or snowflake, emit less
								v:Emit(5)
								task.wait(0.02)
							end
						else --IS a white glow or snowflake, emit more
							for _ = 1, 20 do
								v:Emit(5)
								task.wait(0.02)
							end
						end
					end)
				end
			end
		end
		playVFX()

		local function playSFX()
			local SFX: Sound = ReplicatedStorage.FX.SFX.Combat.Skillsets.BDAs.Doma[vfxToPlay]
			for _, sound in pairs(SFX:GetChildren()) do
				local sound_clone = sound:Clone()
				SFX_Handler(hrp, sound_clone)
			end
		end
		playSFX()
	end
	--	Breaths	 --
	--Moon
	if vfxToPlay == "Moon Spirit Calamitous Eddy" then
		local function playVFX(hrpPosition: Vector3, hrpLookVector: Vector3)
			--Creating variables
			local VFX: Folder = SkillsetsVFX.Breaths.Moon[vfxToPlay]
			local Crescent: MeshPart = VFX:FindFirstChildOfClass("MeshPart"):Clone()
			local ShockWaveFX: Folder = VFX:FindFirstChild("ShockwaveFX"):Clone()

			--Parenting
			Crescent.Parent = Trash
			ShockWaveFX.Parent = hrp
			--CFrame
			Crescent.CFrame = CFrame.lookAt(hrpPosition, hrpPosition + hrpLookVector)
			Crescent.Position = Crescent.Position
				+ (hrp.CFrame.UpVector * math.random(0, 5))
				+ (hrp.CFrame.RightVector * math.random(-5, 5))

			--Orientation
			Crescent.Orientation = Crescent.Orientation + Vector3.new(0, 180, 90)

			--Enable Particles
			for _, obj in Crescent:GetChildren() do
				if obj:IsA("ParticleEmitter") then
					obj.Enabled = true
					task.delay(0.5, function() -- Disable particles after delay
						obj.Enabled = false
					end)
				end
			end

			for _, obj in ShockWaveFX:GetChildren() do
				if obj:IsA("Attachment") then
					for _, obj2 in pairs(obj:GetChildren()) do
						if obj2:IsA("ParticleEmitter") then
							obj2.Enabled = false
							obj2:Emit(1)
						end
					end
				end
			end

			--Tweens
			TweenService:Create( -- Position, Size
				Crescent,
				TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = Crescent.Position + (hrpLookVector * math.random(5, 15)),
					Size = Crescent.Size + Vector3.new(0, math.random(0, 5), math.random(5, 10)),
				}
			):Play()
			TweenService:Create( -- Rotation
				Crescent,
				TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
				{ Orientation = Crescent.Orientation + Vector3.new(0, math.random(-360, 360), 0) }
			):Play()
			task.delay(0.3, function()
				TweenService:Create( -- Transparency
					Crescent,
					TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
					{ Transparency = 1 }
				):Play()
			end)

			--Cleanup
			Debris:AddItem(Crescent, 2)
			Debris:AddItem(ShockWaveFX, 1)
		end
		playVFX(hrp.Position, hrp.CFrame.LookVector)

		local function playSFX()
			local SFX: Sound = ReplicatedStorage.FX.SFX.Combat.Skillsets.Breaths.Moon.CalamitousEddy:Clone()
			SFX.Parent = hrp
			SFX:Play()
			Debris:AddItem(SFX, SFX.TimeLength)
		end
		playSFX()
	end

	if vfxToPlay == "Catastrophe, Tenman Crescent Moon" then
		local function playVFX(hrpPosition: Vector3, hrpLookVector: Vector3)
			local VFX = SkillsetsVFX.Breaths.Moon[vfxToPlay]
			local Crescent = VFX.Crescent:Clone()

			--Parenting
			Crescent.Parent = Trash
			--CFrame
			Crescent.CFrame = CFrame.lookAt(hrpPosition, hrpPosition + hrpLookVector)
			--Orientation
			Crescent.Orientation = Crescent.Orientation + Vector3.new(90, 180, 90) --Set to (0, 180, 90) for correct forward facing slash (where player is looking)
			--Position
			Crescent.Position = hrp.CFrame * (hrp.CFrame.RightVector * math.random(-10, 10))

			local tweenInfo_rotation = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0)
			local tweenInfo_positionAndSize =
				TweenInfo.new(1.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)
			local tweenInfo_transparency =
				TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0)

			TweenService:Create(
				Crescent, --ROTATION
				tweenInfo_rotation,
				{ Orientation = Crescent.Orientation + Vector3.new(math.random(500, 1000), math.random(-45, 45), 0) }
			):Play()
			TweenService:Create(
				Crescent, --POSITION
				tweenInfo_positionAndSize,
				{ Position = Crescent.Position + (hrpLookVector * 50) + Vector3.new(0, 5, 0) }
			):Play()
			TweenService:Create(
				Crescent, --SIZE
				tweenInfo_positionAndSize,
				{ Size = Crescent.Size * Vector3.new(1, math.random(1, 2), 1) }
			):Play()
			task.delay(0.75, function() --TRANSPARENCY
				TweenService:Create(Crescent, tweenInfo_transparency, { Transparency = 1 }):Play()
			end)

			for _, obj in Crescent:GetChildren() do
				if obj:IsA("ParticleEmitter") then
					obj.Enabled = true
					task.delay(1, function() -- Disable particles after delay
						obj.Enabled = false
					end)
				end
			end

			Debris:AddItem(Crescent, 2)
		end
		playVFX(hrp.Position, hrp.CFrame.LookVector)

		local function playSFX()
			local SFX: Sound = ReplicatedStorage.FX.SFX.Combat.Skillsets.Breaths.Moon.CatastropheTenman:Clone()
			local pitch = math.random(75, 125) / 100
			SFX:FindFirstChildOfClass("PitchShiftSoundEffect").Octave = pitch

			--^^^change to actual sound
			SFX.Parent = hrp
			SFX:Play()
			Debris:AddItem(SFX, SFX.TimeLength)
		end
		playSFX()
	end

	if vfxToPlay == "Moonbow, Half Moon" then
		local function playVFX(hrpPosition: Vector3, hrpLookVector: Vector3, hrpRightVector: Vector3)
			--Creating variables
			local VFX: Folder = SkillsetsVFX.Breaths.Moon[vfxToPlay]
			local Crescent: MeshPart = VFX.Crescent:Clone()
			local GroundAttachment: Attachment = Crescent:FindFirstChild("GroundAttachment")
			local Shockwave: MeshPart = VFX.Shockwave:Clone()
			local GroundCircle: MeshPart = VFX.GroundCircle:Clone()

			--Parenting
			Crescent.Parent = Trash
			Shockwave.Parent = Trash
			GroundCircle.Parent = Trash
			--Position
			local PositionX = hrpRightVector * math.random(math.random(-10, -5), math.random(5, 10))
			local PositionZ = hrpLookVector * math.random(5, 15)
			local randomPosition = hrpPosition + PositionX + PositionZ
			Crescent.Position = randomPosition + Vector3.new(0, 17.5, 0)
			Shockwave.Position = randomPosition + Vector3.new(0, -2.5, 0)
			GroundCircle.Position = randomPosition + Vector3.new(0, -2.5, 0)
			--CFrame
			Crescent.CFrame = CFrame.lookAt(Crescent.Position, Crescent.Position + hrpLookVector)
			--Orientation
			Crescent.Orientation = Crescent.Orientation + Vector3.new(0, 180, 0)
			local randomOrientation = math.random(1, 2)
			if randomOrientation == 1 then
				randomOrientation = -360
			else
				randomOrientation = 360
			end
			--Tweens
			TweenService:Create( -- Shockwave
				Shockwave,
				TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Size = Shockwave.Size + Vector3.new(10, 5, 10),
					Orientation = Shockwave.Orientation + Vector3.new(0, randomOrientation, 0),
					Transparency = 1,
				}
			):Play()
			TweenService:Create( -- GroundCircle
				GroundCircle,
				TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Size = GroundCircle.Size + Vector3.new(10, 1, 10),
					Transparency = 1,
				}
			):Play()

			task.delay(0.5, function() --TRANSPARENCY (Crescent)
				TweenService:Create(
					Crescent,
					TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0),
					{ Transparency = 1 }
				):Play()
			end)

			for _, child in Crescent:GetChildren() do
				if child:IsA("ParticleEmitter") then
					child.Enabled = true
					task.delay(0.5, function() -- Disable particles after delay
						child.Enabled = false
					end)
				end
			end
			for _, child in GroundAttachment:GetChildren() do
				if child:IsA("ParticleEmitter") and child.Name ~= "Shockwave" then
					child.Enabled = true
					task.delay(0.1, function() -- Disable particles after delay
						child.Enabled = false
					end)
				end

				if child:IsA("ParticleEmitter") and child.Name == "Shockwave" then
					child.Enabled = true
					task.delay(0.1, function() -- Disable particles after delay
						child.Enabled = false
					end)
				end
			end

			Debris:AddItem(Crescent, 2)
			Debris:AddItem(Shockwave, 2)
			Debris:AddItem(GroundCircle, 2)
		end
		playVFX(hrp.Position, hrp.CFrame.LookVector, hrp.CFrame.RightVector) --VFX

		local function playSFX() --CHANGE THIS LATER
			local SFX: Sound = ReplicatedStorage.FX.SFX.Combat.Skillsets.Breaths.Moon.MoonbowHalfmoon:Clone()
			local playBackSpeed = math.random(100, 130) / 100
			SFX.PlaybackSpeed = playBackSpeed

			--^^^change to actual sound
			SFX.Parent = hrp
			SFX:Play()
			Debris:AddItem(SFX, SFX.TimeLength)
		end
		playSFX() --SFX
	end

	--Sun
end) -- End of OnClientEvent connection

local skillAnims = {

	--	Subskills	--
	["Sting & Send"] = function(
		_anim_char: Model,
		_anim_hrp: BasePart,
		_anim_hum: Humanoid,
		animator: Animator,
		animToPlay: string
	)
		local anim = ReplicatedStorage.Animations.Skills.Subskills.General[animToPlay]
		AnimationService:Play(anim, animator, 0, 0, 1, 1, 1, Enum.AnimationPriority.Action2)
	end,
	["Eye Drifting Kick"] = function(
		anim_char: Model,
		anim_hrp: BasePart,
		_anim_hum: Humanoid,
		animator: Animator,
		animToPlay: string
	)
		local anim: Animation = ReplicatedStorage.Animations.Skills.Subskills.General[animToPlay]
		local animTrack: AnimationTrack? =
			AnimationService:Play(anim, animator, 0, 0, 1, 1, 1, Enum.AnimationPriority.Action2)
		if not animTrack then
			return
		end

		local markerReached: RBXScriptConnection
		markerReached = animTrack:GetMarkerReachedSignal("Kick"):Once(function()
			local sfx = SkillsetsSFX.Subskills.General[animToPlay] :: Folder
			task.spawn(function()
				--Handle SFX
				local repeatSound = sfx:FindFirstChild("RepeatSound")
				for count = 1, 5 do
					local pitch: number
					local addedPitch: number? = tonumber(("0." .. count))
					if addedPitch then
						pitch = 1 + addedPitch
					else
						pitch = 1
					end
					SFX_Handler(anim_hrp, repeatSound, pitch)
					task.wait(0.036)
				end

				local endSound = sfx:FindFirstChild("EndSound")
				SFX_Handler(anim_hrp, endSound)

				--Emit end vfx
				local endAttachment = SkillsetsVFX.Subskills.General[animToPlay].EndAttachment
				local endAttachment_Clone = endAttachment:Clone()
				endAttachment_Clone.Parent = anim_hrp
				VfxStudioEmitter:TriggerEffects(endAttachment_Clone)
				Debris:AddItem(endAttachment_Clone, 1.5)
			end)

			local TIME_BETWEEN = 0.036
			local AMOUNT = 5
			local TIME_CLONES_LAST = 0.4
			local EasingStyle = Enum.EasingStyle.Quad
			local EasingDirection = Enum.EasingDirection.In
			local playVfx = true
			local vfx_attachment = SkillsetsVFX.Subskills.General[animToPlay].AfterimageAttachment
			local randomizeColor = true

			createAfterImages(
				anim_char,
				TIME_BETWEEN,
				AMOUNT,
				TIME_CLONES_LAST,
				EasingStyle,
				EasingDirection,
				playVfx,
				vfx_attachment,
				randomizeColor
			)
		end)

		task.delay(animTrack.Length, function()
			if markerReached then
				markerReached:Disconnect()
			end
		end)
	end,
	--	BDAs	--
	--Akaza
	["Annihilation Type: Punch"] = function(
		_anim_char: Model,
		anim_hrp: BasePart,
		_anim_hum: Humanoid,
		animator: Animator,
		animToPlay: string
	)
		local anim: Animation = ReplicatedStorage.Animations.Skills.BDAs.Akaza[animToPlay]
		local animTrack: AnimationTrack? =
			AnimationService:Play(anim, animator, 0, 0, 1, 1, 1, Enum.AnimationPriority.Action2)

		if not animTrack then --sanity check
			return
		end

		local function playVFX(hrpPosition: Vector3, hrpLookVector: Vector3)
			--print('Played VFX!')

			--Creating variables
			local VFX: Folder = SkillsetsVFX.BDAs.Akaza.AnnihilationType --Folder of VFX
			local VFX_Clone = VFX:Clone()

			local inwardShockwave: MeshPart = VFX_Clone.InwardShockwave
			local outwardShockwave: MeshPart = VFX_Clone.OutwardShockwave
			local ring: MeshPart = VFX_Clone.Ring
			local Shockwave: MeshPart = VFX_Clone.Shockwave

			--Initial Transparency
			for _, mesh: MeshPart in pairs(VFX_Clone:GetChildren()) do
				mesh.Transparency = 0
			end

			--Initial Size
			inwardShockwave.Size = Vector3.new(5, 7.5, 5) * 1.25
			outwardShockwave.Size = Vector3.new(4.75, 15, 4.75) * 1.25
			ring.Size = Vector3.new(0, 0, 0)
			Shockwave.Size = Vector3.new(7, 7, 12.5) * 1.5

			--Parenting to workspace
			VFX_Clone.Parent = workspace

			local lookAtPos = hrpPosition + hrpLookVector

			--CFrames
			inwardShockwave.CFrame = CFrame.lookAt(hrpPosition, lookAtPos) * CFrame.Angles(math.rad(90), 0, 0)
			outwardShockwave.CFrame = CFrame.lookAt(hrpPosition, lookAtPos) * CFrame.Angles(math.rad(90), 0, 0)
			outwardShockwave.Position = hrpPosition + (hrpLookVector * 3)
			ring.CFrame = CFrame.lookAt(hrpPosition, lookAtPos)
			Shockwave.CFrame = CFrame.lookAt(hrpPosition, lookAtPos)

			--Tween info
			local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 5, false, 0) -- Rotation tween info
			local tweenInfo2 = TweenInfo.new(0.5, Enum.EasingStyle.Circular, Enum.EasingDirection.Out, 0, false, 0) -- Size/Position tween
			local tweenInfo3 = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0) -- Transparency tween

			--   TWEENS   --
			local inwardTween_SizePos = TweenService:Create(inwardShockwave, tweenInfo2, {
				Size = Vector3.new(0, 2.5, 0),
				Position = inwardShockwave.Position + (hrpLookVector * 7),
			})
			local outwardTween_SizePos = TweenService:Create(outwardShockwave, tweenInfo2, {
				Size = Vector3.new(0, 5, 0),
				Position = outwardShockwave.Position + (hrpLookVector * 7),
			})
			local ringTween_SizePos = TweenService:Create(ring, tweenInfo2, {
				Size = Vector3.new(5, 5, 0.04) * 1.75,
				Position = ring.Position + (hrpLookVector * 3),
			})
			local ShockwaveTween_SizePos = TweenService:Create(Shockwave, tweenInfo2, {
				Size = Vector3.new(0, 0, 2.5),
				Position = Shockwave.Position + (hrpLookVector * 15),
			})

			--Transparency
			local inwardTween_Trans = TweenService:Create(inwardShockwave, tweenInfo3, { Transparency = 1 })
			local outwardTween_Trans = TweenService:Create(outwardShockwave, tweenInfo3, { Transparency = 1 })
			local ringTween_Trans = TweenService:Create(ring, tweenInfo3, { Transparency = 1 })
			local ShockwaveTween_Trans = TweenService:Create(Shockwave, tweenInfo3, { Transparency = 1 })

			--Rotation
			local inwardTween_Rot = TweenService:Create(
				inwardShockwave,
				tweenInfo,
				{ CFrame = inwardShockwave.CFrame * CFrame.Angles(0, math.rad(5000), 0) }
			)
			local outwardTween_Rot = TweenService:Create(
				outwardShockwave,
				tweenInfo,
				{ CFrame = outwardShockwave.CFrame * CFrame.Angles(0, math.rad(5000), 0) }
			)

			--Playing Tweens
			inwardTween_SizePos:Play()
			outwardTween_SizePos:Play()
			ringTween_SizePos:Play()
			ShockwaveTween_SizePos:Play()

			inwardTween_Trans:Play()
			outwardTween_Trans:Play()

			inwardTween_Rot:Play()
			outwardTween_Rot:Play()

			--Emitting VFX
			local endAttachment = Shockwave:FindFirstChild("EndAttachment")
			if endAttachment then
				VfxStudioEmitter:TriggerEffects(endAttachment)
			end

			--TRANSPARENCY
			task.delay(0.25, function()
				ShockwaveTween_Trans:Play()
			end)
			ringTween_Trans:Play()

			--Cleanup (Debris)
			Debris:AddItem(VFX_Clone, 5)
		end
		local SFX_Folder = SkillsetsSFX.BDAs.Akaza[animToPlay]

		local getMarkerConnection: RBXScriptConnection
		getMarkerConnection = animTrack:GetMarkerReachedSignal("Hit"):Connect(function()
			playVFX(anim_hrp.Position, anim_hrp.CFrame.LookVector)
			--^ VFX handling

			for _, sound in pairs(SFX_Folder:GetChildren()) do
				SFX_Handler(anim_hrp, sound, 1)
			end --SFX handling
		end)

		task.delay(animTrack.Length, function()
			if getMarkerConnection then
				getMarkerConnection:Disconnect()
			end
		end)
	end,
	["Chaotic Blue Metal Afterglow"] = function(
		_anim_char: Model,
		anim_hrp: BasePart,
		_anim_hum: Humanoid,
		animator: Animator,
		animToPlay: string
	)
		local anim: Animation = ReplicatedStorage.Animations.Skills.BDAs.Akaza[animToPlay]
		local animTrack: AnimationTrack? =
			AnimationService:Play(anim, animator, 0, 0, 1, 1, 1, Enum.AnimationPriority.Action2)

		if not animTrack then --sanity check
			return
		end

		local function playVFX(hrpPosition: Vector3, hrpLookVector: Vector3)
			-- Creating variables
			local VFX: Folder = SkillsetsVFX.BDAs.Akaza.Afterglow
			local VFX_Clone = VFX:Clone()

			local inwardShockwave: MeshPart = VFX_Clone.InwardShockwave
			local outwardShockwave: MeshPart = VFX_Clone.OutwardShockwave
			local ring: MeshPart = VFX_Clone.Ring
			local Shockwave: MeshPart = VFX_Clone.Shockwave

			-- Initial transparency
			for _, meshpart: MeshPart in pairs(VFX_Clone:GetChildren()) do
				meshpart.Transparency = 0
			end

			-- Initial size
			inwardShockwave.Size = Vector3.new(5, 7.5, 5) * 1.25
			outwardShockwave.Size = Vector3.new(4.75, 15, 4.75) * 1.25
			ring.Size = Vector3.new(0, 0, 0)
			Shockwave.Size = Vector3.new(7, 7, 12.5) * 1.5

			-- Parent to workspace
			VFX_Clone.Parent = workspace

			-- Calculate right and up vectors
			local upVector = Vector3.new(0, 1, 0)
			local rightVector = hrpLookVector:Cross(upVector).Unit
			local correctedUpVector = rightVector:Cross(hrpLookVector).Unit

			-- Randomized offsets
			local randomPosX = math.random(-7, 7)
			local randomPosY = math.random(2, 7)
			local offset = (rightVector * randomPosX) + (correctedUpVector * randomPosY)
			local spawnPosition = hrpPosition + offset

			-- CFrames
			inwardShockwave.CFrame = CFrame.lookAt(spawnPosition, spawnPosition + hrpLookVector)
				* CFrame.Angles(math.rad(90), 0, 0)
			outwardShockwave.CFrame = CFrame.lookAt(spawnPosition, spawnPosition + hrpLookVector)
				* CFrame.Angles(math.rad(90), 0, 0)
			outwardShockwave.Position = spawnPosition + (hrpLookVector * 3)
			ring.CFrame = CFrame.lookAt(spawnPosition, spawnPosition + hrpLookVector)
			Shockwave.CFrame = CFrame.lookAt(spawnPosition, spawnPosition + hrpLookVector)

			-- Tween info
			local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 5, false, 0)
			local tweenInfo2 = TweenInfo.new(0.5, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)
			local tweenInfo3 = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

			-- Size tweens
			local inwardTween_SizePos = TweenService:Create(inwardShockwave, tweenInfo2, {
				Size = Vector3.new(0, 2.5, 0),
				Position = inwardShockwave.Position + (hrpLookVector * 7),
			})
			local outwardTween_SizePos = TweenService:Create(outwardShockwave, tweenInfo2, {
				Size = Vector3.new(0, 5, 0),
				Position = outwardShockwave.Position + (hrpLookVector * 7),
			})
			local ringTween_SizePos = TweenService:Create(ring, tweenInfo2, {
				Size = Vector3.new(5, 5, 0.04) * 1.75,
				Position = ring.Position + (hrpLookVector * 3),
			})
			local ShockwaveTween_SizePos = TweenService:Create(Shockwave, tweenInfo2, {
				Size = Vector3.new(0, 0, 2.5),
				Position = Shockwave.Position + (hrpLookVector * 15),
			})
			-- Transparency tweens
			local inwardTween_Trans = TweenService:Create(inwardShockwave, tweenInfo3, { Transparency = 1 })
			local outwardTween_Trans = TweenService:Create(outwardShockwave, tweenInfo3, { Transparency = 1 })
			local ringTween_Trans = TweenService:Create(ring, tweenInfo3, { Transparency = 1 })
			local ShockwaveTween_Trans = TweenService:Create(Shockwave, tweenInfo3, { Transparency = 1 })

			-- Rotation tweens
			local inwardTween_Rot = TweenService:Create(
				inwardShockwave,
				tweenInfo,
				{ CFrame = inwardShockwave.CFrame * CFrame.Angles(0, math.rad(5000), 0) }
			)
			local outwardTween_Rot = TweenService:Create(
				outwardShockwave,
				tweenInfo,
				{ CFrame = outwardShockwave.CFrame * CFrame.Angles(0, math.rad(5000), 0) }
			)

			-- Play size tweens
			inwardTween_SizePos:Play()
			outwardTween_SizePos:Play()
			ringTween_SizePos:Play()
			ShockwaveTween_SizePos:Play()

			-- Begin fade-out
			inwardTween_Trans:Play()
			outwardTween_Trans:Play()

			-- Emit VFX
			local endAttachment = Shockwave:FindFirstChild("EndAttachment")
			if endAttachment then
				VfxStudioEmitter:TriggerEffects(endAttachment)
			end

			task.delay(0.25, function()
				ShockwaveTween_Trans:Play()
			end)
			ringTween_Trans:Play()

			-- Rotation tweens
			inwardTween_Rot:Play()
			outwardTween_Rot:Play()

			-- Cleanup
			Debris:AddItem(VFX_Clone, 5)
		end
		local SFX_Folder = SkillsetsSFX.BDAs.Akaza[animToPlay]

		local getMarkerConnection: RBXScriptConnection
		getMarkerConnection = animTrack:GetMarkerReachedSignal("Hit"):Connect(function()
			for _ = 1, 2 do
				playVFX(anim_hrp.Position, anim_hrp.CFrame.LookVector)
			end --VFX handling

			for _, sound in pairs(SFX_Folder:GetChildren()) do
				SFX_Handler(anim_hrp, sound, 1)
			end --SFX handling
		end)

		task.delay(animTrack.Length, function()
			if getMarkerConnection then
				getMarkerConnection:Disconnect()
			end
		end)
	end,
	["Flying Planet"] = function(
		_anim_char: Model,
		anim_hrp: BasePart,
		_anim_hum: Humanoid,
		animator: Animator,
		animToPlay: string
	)
		local anim: Animation = ReplicatedStorage.Animations.Skills.BDAs.Akaza[animToPlay]
		local animTrack: AnimationTrack? =
			AnimationService:Play(anim, animator, 0, 0, 1, 1, 1, Enum.AnimationPriority.Action2)

		if not animTrack then --sanity check
			return
		end

		local function playVFX(hrpPosition: Vector3, hrpLookVector: Vector3)
			--Creating variables
			local VFX: Folder = SkillsetsVFX.BDAs.Akaza.FlyingPlanet

			local insideSpiral: MeshPart = VFX.InsideSpiral:Clone()
			local outsideSpiral: MeshPart = VFX.OutsideSpiral:Clone()
			local ring: MeshPart = VFX.Ring:Clone()
			local Shockwave: MeshPart = VFX.Shockwave:Clone()

			--Enable shockwave sub-effects
			local sparklesFX: ParticleEmitter = Shockwave.VFX_Attachment1.Sparkles
			local ringFX: ParticleEmitter = Shockwave.VFX_Attachment2.Ring
			local energyFX: ParticleEmitter = Shockwave.VFX_Attachment1.Energy

			sparklesFX.Enabled = true
			ringFX.Enabled = false
			energyFX.Enabled = true
			task.delay(0.1, function()
				ringFX:Emit(1)
			end)

			--Initial Transparency
			insideSpiral.Transparency = 0
			outsideSpiral.Transparency = 0.9
			ring.Transparency = 0
			Shockwave.Transparency = 0

			--Initial Sizes
			insideSpiral.Size = Vector3.new(25, 10, 20) * 1.25
			outsideSpiral.Size = Vector3.new(5, 0, 5) * 1.25
			ring.Size = Vector3.new(0, 0, 0)
			Shockwave.Size = Vector3.new(7, 7, 12.5) * 1.5

			--Parenting
			insideSpiral.Parent = Trash
			outsideSpiral.Parent = Trash
			ring.Parent = Trash
			Shockwave.Parent = Trash

			--UPWARD DIRECTION
			local up = Vector3.new(0, 1, 0)
			local lookAtPos = hrpPosition + hrpLookVector

			--CFrames (face upward)
			insideSpiral.CFrame = CFrame.lookAt(hrpPosition, hrpPosition)
			outsideSpiral.CFrame = CFrame.lookAt(hrpPosition, hrpPosition)
			ring.CFrame = CFrame.lookAt(hrpPosition, hrpPosition)
			Shockwave.CFrame = CFrame.lookAt(hrpPosition, lookAtPos) * CFrame.Angles(math.rad(90), 0, 0)

			--Initial Placement (Upward instead of forward)
			insideSpiral.Position = hrpPosition + up * 2.5
			outsideSpiral.Position = hrpPosition + up * 9

			--Tween info
			local tweenInfoRotate = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 5, false, 0)
			local tweenInfoSize = TweenInfo.new(0.5, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)
			local tweenInfoTrans = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

			--Tweens
			local inward_Size = TweenService:Create(insideSpiral, tweenInfoSize, {
				Size = Vector3.new(0, 7.5, 0),
			})

			local outward_Size = TweenService:Create(outsideSpiral, tweenInfoSize, {
				Size = Vector3.new(7, 17, 7) * 1.25,
			})

			local ring_Size = TweenService:Create(ring, tweenInfoSize, {
				Size = Vector3.new(5, 0.05, 5) * 1.75,
			})

			local Shockwave_Size = TweenService:Create(Shockwave, tweenInfoSize, {
				Size = Vector3.new(0.5, 0.5, 2),
			})

			--Position tweens (UPWARD MOVEMENT)
			local inward_Pos = TweenService:Create(insideSpiral, tweenInfoSize, {
				Position = insideSpiral.Position + up * 6.5,
			})

			local ring_Pos = TweenService:Create(ring, tweenInfoSize, {
				Position = ring.Position + up * 3,
			})

			local Shockwave_Pos = TweenService:Create(Shockwave, tweenInfoSize, {
				Position = Shockwave.Position + up * 17,
			})

			--Transparency tweens
			local inward_Trans = TweenService:Create(insideSpiral, tweenInfoTrans, {
				Transparency = 1,
			})

			local outward_Trans = TweenService:Create(outsideSpiral, tweenInfoTrans, {
				Transparency = 1,
			})

			local ring_Trans = TweenService:Create(ring, tweenInfoTrans, {
				Transparency = 1,
			})

			local Shockwave_Trans = TweenService:Create(Shockwave, tweenInfoTrans, {
				Transparency = 1,
			})

			--Rotation tweens (spin around Y-axis)
			local inward_Rotation = TweenService:Create(
				insideSpiral,
				tweenInfoRotate,
				{ CFrame = insideSpiral.CFrame * CFrame.Angles(0, math.rad(360), 0) }
			)

			local outward_Rotation = TweenService:Create(
				outsideSpiral,
				tweenInfoRotate,
				{ CFrame = outsideSpiral.CFrame * CFrame.Angles(0, math.rad(360), 0) }
			)

			--Play tweens
			inward_Size:Play()
			outward_Size:Play()
			ring_Size:Play()
			Shockwave_Size:Play()

			inward_Pos:Play()
			ring_Pos:Play()
			Shockwave_Pos:Play()

			task.delay(0.2, function()
				inward_Trans:Play()
				Shockwave_Trans:Play()
				sparklesFX.Enabled = false
				energyFX.Enabled = false
			end)

			outward_Trans:Play()
			ring_Trans:Play()

			inward_Rotation:Play()
			outward_Rotation:Play()

			--Cleanup
			Debris:AddItem(insideSpiral, 1)
			Debris:AddItem(outsideSpiral, 1)
			Debris:AddItem(ring, 1)
			Debris:AddItem(energyFX, 1)
			Debris:AddItem(Shockwave, 2)
			Debris:AddItem(ringFX, 0.6)
			Debris:AddItem(sparklesFX, 2)
		end
		local SFX_Folder = SkillsetsSFX.BDAs.Akaza[animToPlay]

		local getMarkerConnection: RBXScriptConnection
		getMarkerConnection = animTrack:GetMarkerReachedSignal("Hit"):Connect(function()
			playVFX(anim_hrp.Position, anim_hrp.CFrame.LookVector)
			--^ VFX handling

			for _, sound in pairs(SFX_Folder:GetChildren()) do
				SFX_Handler(anim_hrp, sound, 1)
			end --SFX handling
		end)

		task.delay(animTrack.Length, function()
			if getMarkerConnection then
				getMarkerConnection:Disconnect()
			end
		end)
	end,
	["Crush Type"] = function(
		_anim_char: Model,
		anim_hrp: BasePart,
		anim_hum: Humanoid,
		animator: Animator,
		animToPlay: string
	)
		local anim: Animation = ReplicatedStorage.Animations.Skills.BDAs.Akaza[animToPlay]
		local animTrack: AnimationTrack =
			AnimationService:Play(anim, animator, 0, 0, 1, 1, 1, Enum.AnimationPriority.Action2)
		if not animTrack then
			return
		end

		local function playVFX(hrpCFrame: CFrame)
			-- Clone and apply all particle emitters
			local VFX: Folder = SkillsetsVFX.BDAs.Akaza.CrushType

			for _, v in pairs(VFX:GetChildren()) do
				if v:IsA("Attachment") then
					local attachment = v:Clone()
					attachment.Parent = anim_hrp
					Debris:AddItem(attachment, 3)

					VfxStudioEmitter:TriggerEffects(attachment)
				end
			end

			RockModule.Crater(hrpCFrame, 12.75, 20, 20, false)
			RockModule.Explosion(hrpCFrame, 10, 0.25, 0.5, false)
			task.delay(1, function()
				RockModule.ClearDebris(true)
			end)
		end
		local SFX_Folder = SkillsetsSFX.BDAs.Akaza[animToPlay]

		local landedConnection: RBXScriptConnection
		local getMarkerConnection: RBXScriptConnection
		getMarkerConnection = animTrack:GetMarkerReachedSignal("Pause"):Once(function()
			animTrack:AdjustSpeed(0)

			landedConnection = anim_hum.StateChanged:Connect(function(_, newState)
				if newState ~= Enum.HumanoidStateType.Landed and newState ~= Enum.HumanoidStateType.Running then
					return
				end
				landedConnection:Disconnect()

				animTrack:AdjustSpeed(1) --unpause animation
				playVFX(anim_hrp.CFrame) --VFX handling
				for _, sound in pairs(SFX_Folder:GetChildren()) do
					SFX_Handler(anim_hrp, sound, 1)
				end --SFX handling
			end)
		end)

		task.delay(animTrack.Length + 1, function()
			if animTrack then
				animTrack:Stop(0.5)
				animTrack:Destroy()
				animTrack = nil
			end

			if landedConnection then
				landedConnection:Disconnect()
			end

			if getMarkerConnection then
				getMarkerConnection:Disconnect()
			end
		end)

		--[[
		--local hit = false
		--local attributeConnection: RBXScriptConnection
		--attributeConnection = char:GetAttributeChangedSignal("Stunned"):Connect(function()
		--	if char:GetAttribute("Stunned") == true then
		--		attributeConnection:Disconnect()
		--		hit = true

		--		animTrack:AdjustSpeed(1.5)
		--		animTrack:Stop()
		--		animTrack:Destroy()

		--		char:SetAttribute("UsingAttack", false)
		--		char:SetAttribute("Slowed", false)
		--	end
		--end)
		--]]
	end,

	--Doma
	["Freezing Clouds"] = function(
		_anim_char: Model,
		_anim_hrp: BasePart,
		_anim_hum: Humanoid,
		animator: Animator,
		animToPlay: string
	)
		local anim = ReplicatedStorage.Animations.Skills.BDAs.Doma[animToPlay]
		AnimationService:Play(anim, animator, 0, 0, 1, 1, 1, Enum.AnimationPriority.Action2)
	end,
	["Barren Hanging Garden"] = function(
		_anim_char: Model,
		_anim_hrp: BasePart,
		_anim_hum: Humanoid,
		animator: Animator,
		animToPlay: string
	)
		local anim = ReplicatedStorage.Animations.Skills.BDAs.Doma[animToPlay]
		AnimationService:Play(anim, animator, 0, 0, 1, 1, 1, Enum.AnimationPriority.Action2)
	end,
	["Frozen Lotus"] = function(
		_anim_char: Model,
		_anim_hrp: BasePart,
		_anim_hum: Humanoid,
		animator: Animator,
		animToPlay: string
	)
		local anim = ReplicatedStorage.Animations.Skills.BDAs.Doma[animToPlay]
		AnimationService:Play(anim, animator, 0, 0, 1, 1, 1, Enum.AnimationPriority.Action2)
	end,
	["Wintry Icicles"] = function(
		_anim_char: Model,
		_anim_hrp: BasePart,
		_anim_hum: Humanoid,
		animator: Animator,
		animToPlay: string
	)
		local anim = ReplicatedStorage.Animations.Skills.BDAs.Doma[animToPlay]
		AnimationService:Play(anim, animator, 0, 0, 1, 1, 1, Enum.AnimationPriority.Action2)
	end,

	--	Breaths	--
	--Moon
	["Loathsome Moon, Chains"] = function(
		_anim_char: Model,
		_anim_hrp: BasePart,
		_anim_hum: Humanoid,
		animator: Animator,
		animToPlay: string
	)
		local anim = ReplicatedStorage.Animations.Skills.Breaths.Moon[animToPlay]
		AnimationService:Play(anim, animator, 0, 0, 1, 1, 1, Enum.AnimationPriority.Action2)
	end,
	["Moon Spirit Calamitous Eddy"] = function(
		_anim_char: Model,
		_anim_hrp: BasePart,
		_anim_hum: Humanoid,
		animator: Animator,
		animToPlay: string
	)
		local anim = ReplicatedStorage.Animations.Skills.Breaths.Moon[animToPlay]
		AnimationService:Play(anim, animator, 0, 0, 1, 1, 1, Enum.AnimationPriority.Action2)
	end,
	["Catastrophe, Tenman Crescent Moon"] = function(
		_anim_char: Model,
		_anim_hrp: BasePart,
		_anim_hum: Humanoid,
		animator: Animator,
		animToPlay: string
	)
		local anim = ReplicatedStorage.Animations.Skills.Breaths.Moon[animToPlay]
		AnimationService:Play(anim, animator, 0, 0, 1, 1, 1, Enum.AnimationPriority.Action2)
	end,
	["Moonbow, Half Moon"] = function(
		_anim_char: Model,
		_anim_hrp: BasePart,
		_anim_hum: Humanoid,
		animator: Animator,
		animToPlay: string
	)
		local anim = ReplicatedStorage.Animations.Skills.Breaths.Moon[animToPlay]
		AnimationService:Play(anim, animator, 0, 0, 1, 1, 1, Enum.AnimationPriority.Action2)
	end,

	--Sun
	["Dance"] = function(
		_anim_char: Model,
		anim_hrp: BasePart,
		anim_hum: Humanoid,
		animator: Animator,
		animToPlay: string
	)
		local anim: Animation = ReplicatedStorage.Animations.Skills.Breaths.Sun[animToPlay]
		local animTrack: AnimationTrack? =
			AnimationService:Play(anim, animator, 0, 0, 1, 1, 1, Enum.AnimationPriority.Action2)

		if not animTrack then
			return
		end

		local function emitVFX(slashToPlay: Folder)
			local character_instance = anim_hum.Parent :: Model?
			if not character_instance then
				return
			end
			local hrp = character_instance:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then
				return
			end

			for _, v: Attachment in pairs(slashToPlay:GetChildren()) do
				if v:IsA("Attachment") then
					local attachment = v:Clone()
					attachment.CFrame = v.CFrame
					attachment.Parent = hrp
					Debris:AddItem(attachment, 5)

					-- Run the function.
					VfxStudioEmitter:TriggerEffects(attachment)
				end
			end
		end
		local SFX_Folder = SkillsetsSFX.Breaths.Sun[animToPlay]

		local slash_conn: RBXScriptConnection
		slash_conn = animTrack:GetMarkerReachedSignal("Slash"):Connect(function()
			local model = SkillsetsVFX.Breaths.Sun.Dance :: Model
			local slashToPlay = model:FindFirstChild("Slash")
			if not slashToPlay then
				return
			end

			emitVFX(slashToPlay)
			for _, sound in pairs(SFX_Folder:GetChildren()) do
				SFX_Handler(anim_hrp, sound, 1)
			end --SFX handling
		end)

		task.delay(animTrack.Length, function()
			if slash_conn then
				slash_conn:Disconnect()
			end
		end)
	end,
	["Raging Sun"] = function(
		_anim_char: Model,
		anim_hrp: BasePart,
		anim_hum: Humanoid,
		animator: Animator,
		animToPlay: string
	)
		local anim: Animation = ReplicatedStorage.Animations.Skills.Breaths.Sun[animToPlay]
		local animTrack: AnimationTrack? =
			AnimationService:Play(anim, animator, 0, 0, 1, 1, 1, Enum.AnimationPriority.Action2)

		if not animTrack then
			return
		end

		local function emitVFX(slashToPlay: Folder)
			local character_instance = anim_hum.Parent :: Model?
			if not character_instance then
				return
			end
			local hrp = character_instance:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then
				return
			end

			for _, v: Attachment in pairs(slashToPlay:GetChildren()) do
				if v:IsA("Attachment") then
					local attachment = v:Clone()
					attachment.CFrame = v.CFrame
					attachment.Parent = hrp
					Debris:AddItem(attachment, 5)

					-- Run the function.
					VfxStudioEmitter:TriggerEffects(attachment)
				end
			end
		end
		local SFX_Folder = SkillsetsSFX.Breaths.Sun[animToPlay]

		local firstSlash_conn: RBXScriptConnection
		firstSlash_conn = animTrack:GetMarkerReachedSignal("First Slash"):Connect(function()
			local model = SkillsetsVFX.Breaths.Sun["Raging Sun"] :: Model
			local slashToPlay = model:FindFirstChild("Slash1") :: Folder?
			if not slashToPlay then
				return
			end

			emitVFX(slashToPlay)
			for _, sound in pairs(SFX_Folder:GetChildren()) do
				SFX_Handler(anim_hrp, sound, 1)
			end --SFX handling
		end)

		local secondSlash_conn: RBXScriptConnection
		secondSlash_conn = animTrack:GetMarkerReachedSignal("Second Slash"):Connect(function()
			local model = SkillsetsVFX.Breaths.Sun["Raging Sun"] :: Model
			local slashToPlay = model:FindFirstChild("Slash2") :: Folder?
			if not slashToPlay then
				return
			end

			emitVFX(slashToPlay)
			for _, sound in pairs(SFX_Folder:GetChildren()) do
				SFX_Handler(anim_hrp, sound, 1)
			end --SFX handling
		end)

		task.delay(animTrack.Length, function()
			if firstSlash_conn then
				firstSlash_conn:Disconnect()
			end
			if secondSlash_conn then
				secondSlash_conn:Disconnect()
			end
		end)
	end,
	["Burning Bones, Summer Sun"] = function(
		_anim_char: Model,
		anim_hrp: BasePart,
		_anim_hum: Humanoid,
		animator: Animator,
		animToPlay: string
	)
		local anim: Animation = ReplicatedStorage.Animations.Skills.Breaths.Sun[animToPlay]
		local animTrack: AnimationTrack =
			AnimationService:Play(anim, animator, 0, 0, 1, 1, 1, Enum.AnimationPriority.Action2)

		if not animTrack then
			return
		end

		local function playVFX()
			local mesh = SkillsetsVFX.Breaths.Sun[animToPlay] :: MeshPart
			if not mesh then
				warn("VFX for [" .. animToPlay .. "] not found!")
				return
			end

			--Properties
			mesh = mesh:Clone()
			mesh.Parent = Trash
			mesh.CFrame = CFrame.lookAlong(
				anim_hrp.Position + ((anim_hrp.CFrame.UpVector * 2) + (anim_hrp.CFrame.LookVector * 10)),
				anim_hrp.CFrame.LookVector
			)
			mesh.Orientation = mesh.Orientation + Vector3.new(0, 90, -90)
			mesh.Transparency = 1

			--Tweening
			TweenService:Create(
				mesh,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0),
				{ Transparency = 0 }
			):Play()
			TweenService
				:Create(mesh, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0), {
					Orientation = mesh.Orientation + Vector3.new(720, 0, 0),
					Size = mesh.Size + Vector3.new(2, 0, 2),
				})
				:Play()
			task.delay(0.5, function()
				TweenService:Create(
					mesh,
					TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0),
					{ Transparency = 1 }
				):Play()
			end)

			--Emit particles
			for _, v in pairs(mesh:GetDescendants()) do
				if v:IsA("ParticleEmitter") then
					--Emits particles
					task.spawn(function()
						for _ = 1, 3 do
							v:Emit(1)
							task.wait(0.1)
						end
					end)

					--Disables particles
					task.delay(0.4, function()
						v.Enabled = false
					end)
				end
			end

			Debris:AddItem(mesh, 3)
		end
		local SFX_Folder = SkillsetsSFX.Breaths.Sun[animToPlay]

		local getMarkerConnection: RBXScriptConnection
		getMarkerConnection = animTrack:GetMarkerReachedSignal("Hit"):Connect(function()
			playVFX()
			--^ VFX handling

			for _, sound in pairs(SFX_Folder:GetChildren()) do
				SFX_Handler(anim_hrp, sound, 1)
			end --SFX handling
		end)

		task.delay(animTrack.Length, function()
			if getMarkerConnection then
				getMarkerConnection:Disconnect()
			end
		end)
	end,
	["Setting Sun Transformation"] = function(
		_anim_char: Model,
		anim_hrp: BasePart,
		anim_hum: Humanoid,
		animator: Animator,
		animToPlay: string
	)
		local anim: Animation = ReplicatedStorage.Animations.Skills.Breaths.Sun[animToPlay]
		local animTrack: AnimationTrack =
			AnimationService:Play(anim, animator, 0, 0, 1, 1, 1, Enum.AnimationPriority.Action2)

		if not animTrack then
			return
		end

		local function emitVFX(slashToPlay: Folder)
			local character_instance = anim_hum.Parent :: Model?
			if not character_instance then
				return
			end
			local hrp = character_instance:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then
				return
			end

			for _, v: Attachment in pairs(slashToPlay:GetChildren()) do
				if v:IsA("Attachment") then
					local attachment = v:Clone()
					attachment.CFrame = v.CFrame
					attachment.Parent = hrp
					Debris:AddItem(attachment, 5)

					-- Run the function.
					VfxStudioEmitter:TriggerEffects(attachment)
				end
			end
		end
		local SFX_Folder = SkillsetsSFX.Breaths.Sun[animToPlay]

		local slash_conn: RBXScriptConnection
		slash_conn = animTrack:GetMarkerReachedSignal("Slash"):Connect(function()
			local slashToPlay = SkillsetsVFX.Breaths.Sun[animToPlay]:FindFirstChild("Slash") :: Folder?
			if not slashToPlay then
				return
			end

			emitVFX(slashToPlay)
			for _, sound in pairs(SFX_Folder:GetChildren()) do
				SFX_Handler(anim_hrp, sound, 1)
			end --SFX handling
		end)

		task.delay(animTrack.Length, function()
			if slash_conn then
				slash_conn:Disconnect()
			end
		end)
	end,
}
--	Plays animations on the client
animRemote.OnClientEvent:Connect(function(anim_hum: Humanoid, animToPlay: string)
	if not animToPlay then
		warn("No animation to play!")
		return
	end
	if not anim_hum then
		warn("No humanoid instance!")
		return
	end
	local anim_char
	if anim_hum.Parent then
		anim_char = anim_hum.Parent
	else
		return
	end
	local anim_hrp = anim_char:FindFirstChild("HumanoidRootPart")
	if not anim_hrp then
		return
	end
	local animator = anim_hum:FindFirstChildOfClass("Animator") :: Animator

	skillAnims[animToPlay](anim_char, anim_hrp, anim_hum, animator, animToPlay)
end)
