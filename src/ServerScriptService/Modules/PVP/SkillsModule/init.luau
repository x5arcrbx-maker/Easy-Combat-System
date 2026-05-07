local SkillsModule = {}

--//:SERVICES//:--
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

--//:MODULES//:--
local AnimationService = require(ReplicatedStorage.Modules.Packages.AnimationService)
local Attributes = require(script.Attributes)
local BreathingHandler = require(script.BreathingHandler)
local CooldownHandler = require(script.CooldownHandler)
local HitModule = require(ServerScriptService.Modules.PVP.HitModule)
local HitTracker = require(script.HitTracker)
local SkillGuard = require(script.SkillGuard)

--//:REMOTES//:--
local vfxRemote: UnreliableRemoteEvent = ReplicatedStorage.Remotes_Bindables.Remotes.GeneralPlayer.SkillVFX
local animRemote: UnreliableRemoteEvent = ReplicatedStorage.Remotes_Bindables.Remotes.GeneralPlayer.SkillAnimations

--//:VARIABLES//:--
local Collection = workspace.Collection
local Trash = Collection.Trash
local SkillsetsVFX: Folder = ReplicatedStorage.FX.VFX.Actions.Combat.Skillsets

--//:FUNCTIONS//:-- (General)
CooldownHandler:Init()

-- Sets the "IsAttacking" attribute
local function setIsAttacking(char: Model, hitType: string, durationOfAttacking: number)
	durationOfAttacking = durationOfAttacking or 0.25

	char:SetAttribute("IsAttacking", true)
	char:SetAttribute("AttackType", hitType)
	task.delay(durationOfAttacking, function()
		char:SetAttribute("IsAttacking", false)
	end)
end

-- VisualizeHitbox function (for debugging)
local function _visualizeHitbox(hitboxCFrame: CFrame, hitboxSize: Vector3, TIME: number)
	TIME = TIME or 0.1
	local visualizer = Instance.new("Part")
	visualizer.Size = hitboxSize
	visualizer.CFrame = hitboxCFrame
	visualizer.Anchored = true
	visualizer.Transparency = 0.8
	visualizer.CanCollide = false
	visualizer.BrickColor = BrickColor.new("Really red")
	visualizer.Parent = workspace
	Debris:AddItem(visualizer, TIME)
end

--//:FUNCTIONS (Skills)
--[ BASE COMBAT ]--

--M1 / Normal Attack
function SkillsModule.NormalAttack(char: Model, hum: Humanoid, hrp: BasePart, combo: number, hitType: string)
	for _, v in Attributes.DOWNED_ATTRIBUTES do
		if char:GetAttribute(v) then
			return
		end
	end
	if hum:GetState() == Enum.HumanoidStateType.Dead then
		return
	end

	--STATS
	local DMG = 3.25 --Changes depending on combo value and hitType
	local STUN_TIME = 0.65 --Changes depending on combo value and hitType
	local PBable = false
	local KB = true
	local KBforce --Changes depending on combo value and hitType
	local KB_TIME = 0.1
	local KB_Direction = "Look"
	local Ragdoll --Changes depending on combo value and hitType
	local Ragdoll_TIME --Changes depending on combo value and hitType

	local STARTUP --Changes depending on combo value and hitType

	char:SetAttribute("UsingAttack", true)
	char:SetAttribute("Slowed", true)

	--	Handle UsingAttack
	if hitType == "Sharp" then
		STARTUP = 0.2
		task.delay(0.4, function() --Slowed and Endlag
			char:SetAttribute("UsingAttack", false)
			--print('Attributes set to false')
		end)
	else
		STARTUP = 0.15
		task.delay(0.35, function() --Slowed and Endlag
			char:SetAttribute("UsingAttack", false)
			--print('Attributes set to false')
		end)
	end

	--	Handle Slowed
	if combo >= 5 then --Is the attack the last one?
		if hitType == "Sharp" then
			task.delay(0.3, function() --Slowed
				char:SetAttribute("Slowed", false)
				--print('Attributes set to false')
			end)
		else
			task.delay(0.25, function() --Slowed
				char:SetAttribute("Slowed", false)
				--print('Attributes set to false')
			end)
		end
	else --The attack is not the last one
		if hitType == "Sharp" then
			task.delay(0.2, function() --Slowed
				char:SetAttribute("Slowed", false)
				--print('Attributes set to false')
			end)
		else
			task.delay(0.15, function() --Slowed
				char:SetAttribute("Slowed", false)
				--print('Attributes set to false')
			end)
		end
	end

	--[[ --forwardVelocity function
		local function forwardVelocity(char : Model, hum : Humanoid, hrp : BasePart)
		--preventing velocity if ragdolled, stunned, or blocking
		local ragdoll = char:GetAttribute("Ragdolled")
		local stunned = char:GetAttribute("Stunned")
		local trueStunned = char:GetAttribute("TrueStunned")
		local blocking = char:GetAttribute("Blocking")
		if ragdoll or stunned or trueStunned or blocking then return end

		local direction = hum.MoveDirection --Direction of movement

		if hum.MoveDirection.Magnitude == 0 then direction = hrp.CFrame.LookVector end --If not moving, lookvector is the direction

		--Actual velocity code
		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(100000, 100000, 100000)
		bv.Velocity = direction * 20
		bv.Parent = hrp
		game:GetService("Debris"):AddItem(bv, .15)
	end
	forwardVelocity(char, hum, hrp)
	]]

	vfxRemote:FireAllClients(hrp, "NormalAttack")
	local function handleAttack()
		--Hitbox size changes based on hitType
		local length: number, height: number, depth: number

		--Setting IsAttacking (for clashes and to prevent stacking attacks)
		if hitType == "Sharp" then
			setIsAttacking(char, hitType, 0.2)
			length = 5
			height = 5
			depth = 7.5
		else
			setIsAttacking(char, hitType, 0.15)
			length = 4.5
			height = 5
			depth = 7
		end

		--Setup
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { char }

		local hitboxSize: Vector3 = Vector3.new(length, height, depth)
		local hitboxCFrame: CFrame = hrp.CFrame * CFrame.new(0, 0, -depth / 2) --Position of hitbox

		--Getting parts in box
		local partsInBox = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, params)

		--Checking for HRP inside partsInBox
		if partsInBox then
			for _, v in pairs(partsInBox) do
				if v.Name == "HumanoidRootPart" then
					local opponentChar = v.Parent :: Model?
					if not opponentChar then
						return
					end
					local opponentHum = opponentChar:FindFirstChildOfClass("Humanoid") :: Humanoid?
					if not opponentHum then
						return
					end

					if combo < 5 then --Not final hit
						KBforce = 15
						Ragdoll = false
						if hitType == "Blunt" then
							STUN_TIME = STUN_TIME - 0.05
							DMG = DMG - 0.5
							hitType = "FistM1"
						elseif hitType == "Sharp" then
							STUN_TIME = STUN_TIME
							DMG = DMG
							hitType = "KatanaM1"
						end

						HitModule.Hit(
							hum,
							opponentHum,
							hitType,
							DMG,
							STUN_TIME,
							PBable,
							KB,
							KBforce,
							KB_TIME,
							KB_Direction,
							0,
							Ragdoll
						)
					else --Final hit
						KBforce = 60
						Ragdoll = true
						if hitType == "Blunt" then
							STUN_TIME = STUN_TIME + 0.05
							DMG = DMG - 0.5
							hitType = "FistM1"
						elseif hitType == "Sharp" then
							STUN_TIME = STUN_TIME
							DMG = DMG
							hitType = "KatanaM1"
						end
						Ragdoll_TIME = STUN_TIME

						HitModule.Hit(
							hum,
							opponentHum,
							hitType,
							DMG,
							STUN_TIME,
							PBable,
							KB,
							KBforce,
							KB_TIME,
							KB_Direction,
							0,
							Ragdoll,
							Ragdoll_TIME
						)
					end
				end
			end
		end
	end
	task.delay(STARTUP, handleAttack)

	--[[
	task.delay(STARTUP, function()
		--Hitbox size changes based on hitType
		local length: number, height: number, depth: number

		--Setting IsAttacking (for clashes and to prevent stacking attacks)
		if hitType == "Sharp" then
			setIsAttacking(char, hitType, 0.2)
			length = 5 height = 5 depth = 7.5
		else
			setIsAttacking(char, hitType, 0.15)
			length = 4.5 height = 5 depth = 7
		end

		--Setup
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { char }

		local hitboxSize: Vector3  = Vector3.new(length, height, depth)
		local hitboxCFrame: CFrame = hrp.CFrame * CFrame.new(0, 0, -depth / 2) --Position of hitbox

		--Getting parts in box
		local partsInBox = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, params)

		--Checking for HRP inside partsInBox
		if partsInBox then
			for _, v in pairs(partsInBox) do
				if v.Name == "HumanoidRootPart" then
					local opponentChar = v.Parent :: Model?
					if not opponentChar then return end
					local opponentHum  = opponentChar:FindFirstChildOfClass("Humanoid") :: Humanoid?
					if not opponentHum then return end

					if combo < 5 then --Not final hit
						KBforce = 15
						Ragdoll = false
						if hitType == "Blunt" then
							STUN_TIME = STUN_TIME - 0.05
							DMG = DMG - 0.5
							hitType = "FistM1"
						elseif hitType == "Sharp" then
							STUN_TIME = STUN_TIME
							DMG = DMG
							hitType = "KatanaM1"
						end

						HitModule.Hit(
							hum, 
							opponentHum, 
							hitType, 
							DMG, 
							STUN_TIME, 
							PBable, 
							KB, 
							KBforce,
							KB_TIME,
							KB_Direction,
							0,
							Ragdoll
						)
					else --Final hit
						KBforce = 60
						Ragdoll = true
						if hitType == "Blunt" then
							STUN_TIME = STUN_TIME + 0.05
							DMG = DMG - 0.5
							hitType = "FistM1"
						elseif hitType == "Sharp" then
							STUN_TIME = STUN_TIME
							DMG = DMG
							hitType = "KatanaM1"
						end
						Ragdoll_TIME = STUN_TIME

						HitModule.Hit(
							hum,
							opponentHum,
							hitType,
							DMG,
							STUN_TIME,
							PBable,
							KB,
							KBforce,
							KB_TIME,
							KB_Direction,
							0,
							Ragdoll,
							Ragdoll_TIME
						)
					end
				end
			end
		end
	end)
	]]
end

--M2 / Heavy Attack
function SkillsModule.HeavyAttack(char: Model, hum: Humanoid, hrp: BasePart, hitType: string)
	for _, v in Attributes.DOWNED_ATTRIBUTES do
		if char:GetAttribute(v) then
			return
		end
	end
	if hum:GetState() == Enum.HumanoidStateType.Dead then
		return
	end

	--STATS
	local DMG = 5
	local STUN_TIME = 2.5
	local PBable = true
	local KB = true
	local KBforce = 60
	local KB_TIME = 0.1
	local KB_Direction = "Look"
	local Ragdoll = true
	local Ragdoll_TIME = STUN_TIME
	local Effect
	local StatusEffect

	local STARTUP = 0.5

	--Heavy attack uses its own endlag system because cooldowns are handled elsewhere
	char:SetAttribute("Slowed", true)
	char:SetAttribute("UsingAttack", true)

	task.delay(1.15, function() --Slowed and Endlag
		char:SetAttribute("Slowed", false)
		char:SetAttribute("UsingAttack", false)
		--print('Attributes set to false')
	end)

	vfxRemote:FireAllClients(hrp, "HeavyAttack")

	--Velocity function
	local function forwardVelocity()
		--if hitType == "Blunt" then
		--	return
		--end

		--preventing velocity if ragdolled, stunned, or blocking
		for _, attribute in pairs(Attributes.PREVENTION_ATTRIBUTES) do
			if char:GetAttribute(attribute) then
				return
			end
		end

		--Actual velocity code
		local bv: BodyVelocity = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(100000, 100000, 100000)
		bv.Velocity = hrp.CFrame.LookVector * 50
		bv.Parent = hrp
		Debris:AddItem(bv, 0.15)
	end

	local function handleAttack()
		--Hitbox size changes based on hitType
		local length: number, height: number, depth: number

		--Setting IsAttacking (for clashes)
		if hitType == "Sharp" then
			setIsAttacking(char, hitType, 0.2)
			length = 5.5
			height = 7.5
			depth = 10.5
		else
			setIsAttacking(char, hitType, 0.15)
			length = 6.5
			height = 8.5
			depth = 9.5
		end

		--Setup
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { char }

		local hitboxSize: Vector3 = Vector3.new(length, height, depth)
		local hitboxCFrame: CFrame = hrp.CFrame * CFrame.new(0, 0, -depth / 2) --Position of hitbox

		--Getting parts in box
		local partsInBox = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, params)
		--visualizeHitbox(hitboxCFrame, hitboxSize, 0.5)

		if partsInBox then
			for _, v in pairs(partsInBox) do
				if v.Name == "HumanoidRootPart" then
					local opponentChar = v.Parent :: Model?
					if not opponentChar then
						return
					end
					local opponentHum = opponentChar:FindFirstChildOfClass("Humanoid") :: Humanoid?
					if not opponentHum then
						return
					end

					--Checking for fists or katana
					if hitType == "Blunt" then
						hitType = "FistM2"
						DMG = DMG - 0.5
						STUN_TIME = STUN_TIME + 0.1
						Effect = false
					elseif hitType == "Sharp" then
						hitType = "KatanaM2"
						DMG = DMG
						STUN_TIME = STUN_TIME
						Effect = true
						StatusEffect = "Bleed"
					end

					HitModule.Hit(
						hum,
						opponentHum,
						hitType,
						DMG,
						STUN_TIME,
						PBable,
						KB,
						KBforce,
						KB_TIME,
						KB_Direction,
						0,
						Ragdoll,
						Ragdoll_TIME,
						Effect,
						StatusEffect
					)
				end
			end
		end
	end

	task.delay(STARTUP, function()
		forwardVelocity()
		handleAttack()
	end)

	--[[
	task.delay(0.6, forwardVelocity)
	task.delay(0.6, function()
		--Hitbox size changes based on hitType
		local length: number, height: number, depth: number

		--Setting IsAttacking (for clashes)
		if hitType == "Sharp" then
			setIsAttacking(char, hitType, 0.2)
			length = 5.5 height = 7.5 depth = 10.5
		else
			setIsAttacking(char, hitType, 0.15)
			length = 6.5 height = 8.5 depth = 9.5
		end

		--Setup
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { char }

		local hitboxSize: Vector3  = Vector3.new(length, height, depth)
		local hitboxCFrame: CFrame = hrp.CFrame * CFrame.new(0, 0, -depth / 2) --Position of hitbox

		--Getting parts in box
		local partsInBox = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, params)
		--visualizeHitbox(hitboxCFrame, hitboxSize, 0.5)

		if partsInBox then
			for _, v in pairs(partsInBox) do
				if v.Name == "HumanoidRootPart" then
					local opponentChar = v.Parent :: Model?
					if not opponentChar then return end
					local opponentHum  = opponentChar:FindFirstChildOfClass("Humanoid") :: Humanoid?
					if not opponentHum then return end
					local opponentHrp = v

					--Checking for fists or katana
					if hitType == "Blunt" then
						hitType = "FistM2"
						DMG = DMG - 0.5
						STUN_TIME = STUN_TIME + 0.1
						Effect = false
					elseif hitType == "Sharp" then
						hitType = "KatanaM2"
						DMG = DMG
						STUN_TIME = STUN_TIME
						Effect = true
						StatusEffect = "Bleed"
					end

					HitModule.Hit(
						hum,
						opponentHum,
						hitType,
						DMG,
						STUN_TIME,
						PBable,
						KB,
						KBforce,
						KB_TIME,
						KB_Direction,
						0,
						Ragdoll,
						Ragdoll_TIME,
						Effect,
						StatusEffect
					)
				end
			end
		end
	end)
	]]
end
-------------------

--[ SUBSKILLS ]--
SkillsModule.Subskills = {
	["Hunter Step"] = function(player: Player, char: Model, hum: Humanoid, skill: string)
		for _, v in Attributes.DOWNED_ATTRIBUTES do
			if char:GetAttribute(v) then
				return
			end
		end
		if hum:GetState() == Enum.HumanoidStateType.Dead then
			return
		end

		--STATS
		local hitType = "Sharp"
		local DMG = 5
		local STUN_TIME = 0.6
		local PBable = true
		local KB = false
		local KBforce = nil
		local KB_TIME = nil
		local KB_Direction = "Look"
		local Ragdoll = false
		local Ragdoll_TIME = nil
		local Effect = true
		local StatusEffect = "Bleed"

		--COOLDOWN and STARTUP
		local COOLDOWN = 20 --real is (20s)
		local STARTUP = 0.25

		local ok = SkillGuard:CheckSkillAllowed(player, char, skill, COOLDOWN, true, STARTUP + 0.1)
		if not ok then
			return
		end

		--VFX
		local function playVFX_Highlight()
			--Create highlight (Indicator), set properties, and tween transparency
			local highlight: Highlight = Instance.new("Highlight")
			highlight.DepthMode = Enum.HighlightDepthMode.Occluded
			highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
			highlight.OutlineTransparency = 0.7
			highlight.FillColor = Color3.fromRGB(255, 255, 255)
			highlight.FillTransparency = 0.8
			highlight.Parent = char --Parent to char
			TweenService:Create( --Tween transparency for both fill and outline
				highlight,
				TweenInfo.new(STARTUP, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0),
				{ FillTransparency = 0.6, OutlineTransparency = 0.5 }
			):Play()
			Debris:AddItem(highlight, STARTUP)
		end
		local function playVFX_Whirlwinds(hrp: BasePart)
			--Find whirlWind (VFX), set position, tween transparency / rotation
			local whirlWind: MeshPart = SkillsetsVFX.Subskills.Slayer[skill].Whirlwind:Clone()
			whirlWind.Parent = Trash
			whirlWind.Position = hrp.Position + Vector3.new(0, -2, 0)
			TweenService:Create( --Tween transparency and rotation
				whirlWind,
				TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0),
				{
					Transparency = 1,
					Orientation = Vector3.new(0, -360, 0),
					Size = whirlWind.Size + Vector3.new(5, 3, 5),
				}
			):Play()
			Debris:AddItem(whirlWind, 0.25)

			--Find whirlWind2 (VFX), set position, tween transparency / rotation
			local whirlWind2: MeshPart = SkillsetsVFX.Subskills.Slayer[skill].Whirlwind2:Clone()
			whirlWind2.Parent = Trash
			whirlWind2.Position = hrp.Position
			TweenService:Create( --Tween transparency and rotation
				whirlWind2,
				TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0),
				{
					Transparency = 1,
					Orientation = Vector3.new(0, 360, 0),
					Size = whirlWind.Size + Vector3.new(5, 3, 5),
				}
			):Play()
			Debris:AddItem(whirlWind, 0.25)
		end
		local function playSFX(hrp: BasePart)
			local sound = ReplicatedStorage.FX.SFX.Combat.Skillsets.Subskills.Breaths[skill]
			if sound then
				sound = sound:Clone()
				sound.Parent = hrp
				sound:Play()
				Debris:AddItem(sound, sound.TimeLength)
			end
		end
		--Animation
		local function playAnimation(humanoid: Humanoid)
			local animator: Animator? = humanoid:FindFirstChildOfClass("Animator")
			if not animator then
				return
			end

			local animation = ReplicatedStorage.Animations.Skills.Subskills.Breaths[skill]
			AnimationService:Play(animation, animator, 0, 0, 1, 1, 1)
		end
		playAnimation(hum) --Play animation as soon as skill is validated

		--Play highlight VFX
		local hrp = char:FindFirstChild("HumanoidRootPart") :: Part
		playVFX_Highlight() --Highlight VFX indicates start of skill

		--Setup
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { char }
		local length = 7.5
		local height = 7.5
		local depth = 40
		local hitboxSize = Vector3.new(length, height, depth)

		task.delay(STARTUP, function()
			local hitboxCFrame = hrp.CFrame * CFrame.new(0, 0, -depth / 2) --Position of hitbox

			setIsAttacking(char, hitType, 0.15)

			local partsInBox = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, params)
			if partsInBox then
				for _, v in partsInBox do
					if v.Name == "HumanoidRootPart" then
						local opponentChar = v.Parent :: Model?
						if not opponentChar then
							return
						end
						local opponentHum = opponentChar:FindFirstChildOfClass("Humanoid") :: Humanoid?
						if not opponentHum then
							return
						end
						local opponentHrp = v
						local opponentHrp_Position = opponentHrp.Position

						playVFX_Whirlwinds(hrp)
						playSFX(hrp)
						hrp.Position = opponentHrp_Position

						--Preventing an attack when player isn't supposed to attack or opponent isn't supposed to be hit
						HitModule.Hit(
							hum,
							opponentHum,
							hitType,
							DMG,
							STUN_TIME,
							PBable,
							KB,
							KBforce,
							KB_TIME,
							KB_Direction,
							0,
							Ragdoll,
							Ragdoll_TIME,
							Effect,
							StatusEffect
						)
						break --Prevents from hitting multiple targets, making multiple teleports
					end
				end
			end
		end)
	end,

	["Sting & Send"] = function(player: Player, char: Model, hum: Humanoid, skill: string)
		for _, v in Attributes.DOWNED_ATTRIBUTES do
			if char:GetAttribute(v) then
				return
			end
		end
		if hum:GetState() == Enum.HumanoidStateType.Dead then
			return
		end
	end,
}
-----------------

--[ SKILLSETS ]--
-----| BDAs |-----
SkillsModule.Akaza = {
	["Annihilation Type: Punch"] = function(player: Player, char: Model, hum: Humanoid, skill: string)
		for _, v in Attributes.DOWNED_ATTRIBUTES do
			if char:GetAttribute(v) then
				return
			end
		end
		if hum:GetState() == Enum.HumanoidStateType.Dead then
			return
		end

		--STATS
		local hitType = "Blunt"
		local DMG = 10
		local STUN_TIME = 2.5
		local PBable = true
		local KB = true
		local KBforce = 90
		local KB_TIME = 0.2
		local KB_Direction = "Look"
		local Ragdoll = true
		local Ragdoll_TIME = STUN_TIME --(2.5)

		--COOLDOWN & STARTUP
		local COOLDOWN = 15 --(15s)
		local STARTUP = 0.7

		local ok = SkillGuard:CheckSkillAllowed(player, char, skill, COOLDOWN, true, 1.2)
		if not ok then
			return
		end

		animRemote:FireAllClients(hum, skill)
		task.delay(STARTUP, function()
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart
			vfxRemote:FireAllClients(hrp, skill)

			setIsAttacking(char, hitType, 0.15)

			--Setup
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { char }

			local length: number, height: number, depth: number = 11.5, 11.5, 21.5
			local hitboxSize: Vector3 = Vector3.new(length, height, depth)
			local hitboxCFrame: CFrame = hrp.CFrame * CFrame.new(0, 0, -depth / 2) --Position of hitbox

			local partsInBox = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, params)
			--visualizeHitbox(hitboxCFrame, hitboxSize, 0.5)

			if partsInBox then
				for _, v in partsInBox do
					if v.Name == "HumanoidRootPart" then
						local opponentChar = v.Parent :: Model?
						if not opponentChar then
							return
						end
						local opponentHum = opponentChar:FindFirstChildOfClass("Humanoid") :: Humanoid?
						if not opponentHum then
							return
						end

						HitModule.Hit(
							hum,
							opponentHum,
							hitType,
							DMG,
							STUN_TIME,
							PBable,
							KB,
							KBforce,
							KB_TIME,
							KB_Direction,
							0,
							Ragdoll,
							Ragdoll_TIME
						)
					end
				end
			end
		end)
	end,

	["Chaotic Blue Metal Afterglow"] = function(player: Player, char: Model, hum: Humanoid, skill: string)
		for _, v in Attributes.DOWNED_ATTRIBUTES do
			if char:GetAttribute(v) then
				return
			end
		end
		if hum:GetState() == Enum.HumanoidStateType.Dead then
			return
		end

		--STATS
		local hitCount = 8

		local hitType = "Blunt"
		local DMG = 6.5 / hitCount --Per hit (8 hits total)
		local STUN_TIME = 0.6
		local PBable = false
		local KB = true
		local KBforce = 7.5
		local KB_TIME = 0.1
		local KB_Direction = "Look"
		local Ragdoll = false
		local Ragdoll_TIME = STUN_TIME --(2.5)

		--COOLDOWN
		local COOLDOWN = 13 --(15s)
		local STARTUP = 0.4

		local ok = SkillGuard:CheckSkillAllowed(player, char, skill, COOLDOWN, true, 1.25)
		if not ok then
			return
		end

		animRemote:FireAllClients(hum, skill)
		task.delay(STARTUP, function()
			setIsAttacking(char, hitType, 0.15 * hitCount)

			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then
				return
			end

			--Setup
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { char }

			local length: number, height: number, depth: number = 17, 17, 18
			local hitboxSize = Vector3.new(length, height, depth)

			--Hit loop
			for _ = 1, hitCount do
				vfxRemote:FireAllClients(hrp, skill)

				--Getting RootPart info
				local hitboxCFrame = hrp.CFrame * CFrame.new(0, 0, -depth / 2) --Position of hitbox, inside loop to dynamically update hitbox position
				local partsInBox = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, params)

				if partsInBox then
					for _, v in pairs(partsInBox) do
						if v.Name == "HumanoidRootPart" then
							local opponentChar = v.Parent :: Model?
							if not opponentChar then
								return
							end
							local opponentHum = opponentChar:FindFirstChildOfClass("Humanoid") :: Humanoid?
							if not opponentHum then
								return
							end

							HitModule.Hit(
								hum,
								opponentHum,
								hitType,
								DMG,
								STUN_TIME,
								PBable,
								KB,
								KBforce,
								KB_TIME,
								KB_Direction,
								0,
								Ragdoll,
								Ragdoll_TIME
							)
						end
					end
				end
				task.wait(0.075)
			end
		end)
	end,

	["Flying Planet"] = function(player: Player, char: Model, hum: Humanoid, skill: string)
		for _, v in Attributes.DOWNED_ATTRIBUTES do
			if char:GetAttribute(v) then
				return
			end
		end
		if hum:GetState() == Enum.HumanoidStateType.Dead then
			return
		end

		--STATS
		local hitType = "Blunt"
		local DMG = 8.5 -- Damage dealt to the target
		local STUN_TIME = 2
		local PBable = true
		local KB = true
		local KBforce = 100
		local KB_TIME = 0.1
		local KB_Direction = "UpLook"
		local Direction_Divider = 4
		local RAGDOLL = true
		local RAGDOLL_TIME = STUN_TIME

		--COOLDOWN
		local COOLDOWN = 10 -- 13s
		local STARTUP = 0.2

		local ok = SkillGuard:CheckSkillAllowed(player, char, skill, COOLDOWN, true, 0.5)
		if not ok then
			return
		end

		animRemote:FireAllClients(hum, skill)

		task.delay(STARTUP, function()
			--Getting RootPart info
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then
				return
			end
			vfxRemote:FireAllClients(hrp, skill)

			setIsAttacking(char, hitType, 0.15)

			--Setup
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { char }

			local length: number, height: number, depth: number = 15, 17, 15
			local hitboxSize: Vector3 = Vector3.new(length, height, depth) -- width, height depth
			local hitboxCFrame: CFrame = hrp.CFrame * CFrame.new(0, height / 2, 0)

			local partsInBox = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, params)
			if partsInBox then
				for _, v in pairs(partsInBox) do
					if v.Name == "HumanoidRootPart" then
						local opponentChar = v.Parent :: Model?
						if not opponentChar then
							return
						end
						local opponentHum = opponentChar:FindFirstChildOfClass("Humanoid") :: Humanoid?
						if not opponentHum then
							return
						end

						HitModule.Hit(
							hum,
							opponentHum,
							hitType,
							DMG,
							STUN_TIME,
							PBable,
							KB,
							KBforce,
							KB_TIME,
							KB_Direction,
							Direction_Divider,
							RAGDOLL,
							RAGDOLL_TIME
						)

						--[[
						CUSTOM KNOCKBACK FOR THIS SKILL
						local function knockback()
							if not KB then
								return
							end
							local bv : BodyVelocity = Instance.new("BodyVelocity")
							bv.Velocity = hrp.CFrame.UpVector * KBforce + hrp.CFrame.LookVector * (KBforce / 4)
							bv.MaxForce = Vector3.new(100000, 100000, 100000)
							bv.Parent   = opponentHrp
							Debris:AddItem(bv, KB_TIME)
						end
						knockback()
						]]
					end
				end
			end
		end)
	end,

	["Crush Type"] = function(player: Player, char: Model, hum: Humanoid, skill: string)
		for _, v in Attributes.DOWNED_ATTRIBUTES do
			if char:GetAttribute(v) then
				return
			end
		end
		if hum:GetState() == Enum.HumanoidStateType.Dead then
			return
		end

		--STATS
		local hitType = "Blunt"
		local DMG = 6.5 -- Damage dealt to the target
		local STUN_TIME = 1.5
		local PBable = false
		local KB = true
		local KBforce = 40
		local KB_TIME = 0.1
		local KB_Direction = "Away"
		local RAGDOLL = true
		local RAGDOLL_TIME = STUN_TIME

		--COOLDOWN
		local COOLDOWN = 12 -- 13s
		local STARTUP = 0.35

		local ok = SkillGuard:CheckSkillAllowed(player, char, skill, COOLDOWN, false)
		if not ok then
			return
		end

		animRemote:FireAllClients(hum, skill)

		task.delay(STARTUP, function()
			--Getting RootPart
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then
				return
			end

			--Velocity
			local bv: BodyVelocity = Instance.new("BodyVelocity")
			bv.Name = "CrushType_BodyVelocity"
			bv.Velocity = hrp.CFrame.LookVector * 85 + hrp.CFrame.UpVector * 50
			bv.MaxForce = Vector3.new(100000, 100000, 100000)
			bv.Parent = hrp
			Debris:AddItem(bv, 0.1)

			--Delay so skill doesn't instantly set off
			task.delay(STARTUP, function()
				local landedConnection: RBXScriptConnection
				landedConnection = hum.StateChanged:Connect(function(_, newState)
					if newState ~= Enum.HumanoidStateType.Landed and newState ~= Enum.HumanoidStateType.Running then
						return
					end

					print("Landed reached (" .. script.Name .. ")")
					landedConnection:Disconnect()
					vfxRemote:FireAllClients(hrp, skill)

					char:SetAttribute("UsingAttack", false)
					char:SetAttribute("Slowed", false)

					--Setup
					local params = OverlapParams.new()
					params.FilterType = Enum.RaycastFilterType.Exclude
					params.FilterDescendantsInstances = { char }

					-- Centered hitbox around the player
					local length: number, height: number, depth: number = 35, 20, 35
					local hitboxSize: Vector3 = Vector3.new(length, height, depth)
					local hitboxCFrame: CFrame = hrp.CFrame --* CFrame.new(0, 0, -depth / 2) --Position of hitbox

					local partsInBox = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, params)
					if partsInBox then
						for _, v in pairs(partsInBox) do
							if v.Name == "HumanoidRootPart" then
								local opponentChar = v.Parent :: Model?
								if not opponentChar then
									return
								end
								local opponentHum = opponentChar:FindFirstChildOfClass("Humanoid") :: Humanoid?
								if not opponentHum then
									return
								end

								HitModule.Hit(
									hum,
									opponentHum,
									hitType,
									DMG,
									STUN_TIME,
									PBable,
									KB,
									KBforce,
									KB_TIME,
									KB_Direction,
									0,
									RAGDOLL,
									RAGDOLL_TIME
								)
							end
						end
					end
				end)

				task.delay(0.75, function()
					if landedConnection then
						landedConnection:Disconnect()
						char:SetAttribute("UsingAttack", false)
						char:SetAttribute("Slowed", false)
					end
				end)
			end)
		end)
	end,
}

SkillsModule.Doma = {
	["Freezing Clouds"] = function(player: Player, char: Model, hum: Humanoid, skill: string, _mousePos: Vector3?)
		for _, v in Attributes.DOWNED_ATTRIBUTES do
			if char:GetAttribute(v) then
				return
			end
		end
		if hum:GetState() == Enum.HumanoidStateType.Dead then
			return
		end

		--STATS
		local hitCount = 6
		local hitType = "Sharp"
		local DMG = 6.5 / hitCount -- Damage dealt to the target
		local STUN_TIME = 0.6
		local PBable = false
		local KB = true
		local KBforce = 5
		local KB_TIME = 0.1
		local KB_Direction = "Look"

		--COOLDOWN
		local COOLDOWN = 13 -- REAL CD IS 15s
		local STARTUP = 0.25

		local ok = SkillGuard:CheckSkillAllowed(player, char, skill, COOLDOWN, true, 1.15)
		if not ok then
			return
		end

		animRemote:FireAllClients(hum, skill)

		task.delay(STARTUP, function()
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then
				return
			end
			vfxRemote:FireAllClients(hrp, skill)

			--Setup
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { char }
			local length = 9.5
			local height = 9.5
			local depth = 17.5
			local hitboxSize = Vector3.new(length, height, depth) -- width, height depth

			--Multiple hits
			setIsAttacking(char, hitType, 0.5)
			for i = 1, hitCount do
				if i <= 1 then
					PBable = true
				else
					PBable = false
				end
				local hitboxCFrame = hrp.CFrame * CFrame.new(0, 0, -depth / 2) --Position of hitbox
				local partsInBox = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, params)

				if partsInBox then
					for _, v in pairs(partsInBox) do
						if v.Name == "HumanoidRootPart" then
							local opponentChar = v.Parent :: Model?
							if not opponentChar then
								return
							end
							local opponentHum = opponentChar:FindFirstChildOfClass("Humanoid") :: Humanoid?
							if not opponentHum then
								return
							end

							--print('HRP Found!')

							--Preventing an attack when player isn't supposed to attack or opponent isn't supposed to be hit
							HitModule.Hit(
								hum,
								opponentHum,
								hitType,
								DMG,
								STUN_TIME,
								PBable,
								KB,
								KBforce,
								KB_TIME,
								KB_Direction,
								0
							)
						end
					end
				end

				task.wait(0.125) -- Interval between hits
			end
		end)
	end,

	["Barren Hanging Garden"] = function(
		player: Player,
		char: Model,
		hum: Humanoid,
		skill: string,
		_mousePos: Vector3?
	)
		for _, v in Attributes.DOWNED_ATTRIBUTES do
			if char:GetAttribute(v) then
				return
			end
		end
		if hum:GetState() == Enum.HumanoidStateType.Dead then
			return
		end

		--STATS
		local hitCount = 8
		local hitType = "Sharp"
		local DMG = 8 / hitCount -- Damage dealt to the target
		local STUN_TIME = 0.6
		local PBable = false
		local KB = true
		local KBforce = 17.5
		local KB_TIME = 0.1
		local KB_Direction = "Look"

		--COOLDOWN
		local COOLDOWN = 13 -- REAL CD IS 15s
		local STARTUP = 0.3

		local ok = SkillGuard:CheckSkillAllowed(player, char, skill, COOLDOWN, true, 1.6)
		if not ok then
			return
		end

		animRemote:FireAllClients(hum, skill)

		local function forwardVelocity(hrp: BasePart)
			local BodyVelocity = Instance.new("BodyVelocity") :: BodyVelocity
			BodyVelocity.Parent = hrp
			BodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
			BodyVelocity.Velocity = hrp.CFrame.LookVector * 17.5
			BodyVelocity.Name = "ForwardVelocity_BarrenHangingGarden"
			Debris:AddItem(BodyVelocity, 0.1)
		end

		task.delay(STARTUP, function()
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then
				return
			end
			vfxRemote:FireAllClients(hrp, skill)

			--Setup
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { char }
			local length = 10
			local height = 14
			local depth = 13
			local hitboxSize = Vector3.new(length, height, depth) -- width, height depth

			--Multiple hits
			setIsAttacking(char, hitType, 1.2)
			for i = 1, hitCount do
				if i <= 2 then
					PBable = true
				else
					PBable = false
				end

				forwardVelocity(hrp)

				local hitboxCFrame = hrp.CFrame * CFrame.new(0, 0, -depth / 2) --Position of hitbox
				local partsInBox = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, params)

				if partsInBox then
					for _, v in pairs(partsInBox) do
						if v.Name == "HumanoidRootPart" then
							local opponentChar = v.Parent :: Model?
							if not opponentChar then
								return
							end
							local opponentHum = opponentChar:FindFirstChildOfClass("Humanoid") :: Humanoid?
							if not opponentHum then
								return
							end

							--print('HRP Found!')

							--Preventing an attack when player isn't supposed to attack or opponent isn't supposed to be hit
							HitModule.Hit(
								hum,
								opponentHum,
								hitType,
								DMG,
								STUN_TIME,
								PBable,
								KB,
								KBforce,
								KB_TIME,
								KB_Direction,
								0
							)
						end
					end
				end

				task.wait(0.15) -- Interval between hits
			end
		end)
	end,

	["Frozen Lotus"] = function(player: Player, char: Model, hum: Humanoid, skill: string, _mousePos: Vector3?)
		for _, v in Attributes.DOWNED_ATTRIBUTES do
			if char:GetAttribute(v) then
				return
			end
		end
		if hum:GetState() == Enum.HumanoidStateType.Dead then
			return
		end

		--STATS
		local hitCount = 1
		local hitType = "Sharp"
		local DMG = 6 / hitCount -- Damage dealt to the target
		local STUN_TIME = 0.6
		local PBable = false
		local Effect = true
		local StatusEffect = "Frost"

		--COOLDOWN
		local COOLDOWN = 12 --15s
		local STARTUP = 0.3
		local ENDLAG = 0.75
		local DURATION = 3

		local ok = SkillGuard:CheckSkillAllowed(player, char, skill, COOLDOWN, true, ENDLAG)
		if not ok then
			return
		end

		animRemote:FireAllClients(hum, skill)

		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then
			return
		end

		local function backwardVelocity()
			--preventing velocity if ragdolled, stunned, or blocking
			for _, attribute in pairs(Attributes.PREVENTION_ATTRIBUTES) do
				if char:GetAttribute(attribute) then
					return
				end
			end

			--Actual velocity code
			local bv: BodyVelocity = Instance.new("BodyVelocity")
			bv.MaxForce = Vector3.new(100000, 100000, 100000)
			bv.Velocity = (hrp.CFrame.LookVector * -50) + (hrp.CFrame.UpVector * 50)
			bv.Parent = hrp
			Debris:AddItem(bv, 0.1)
		end

		local function playVFX(): BasePart
			if not SkillGuard:CanPlayFX(char) then
				return
			end

			--//MAIN
			local part: BasePart = SkillsetsVFX.BDAs.Doma["Frozen Lotus"]
			part = part:Clone()
			--Particles
			for _, v: Instance in pairs(part:GetDescendants()) do
				if not v:IsA("ParticleEmitter") then
					continue
				end
				v.Enabled = false --Disable particles because they are played on the client
			end

			--Properties
			part.Parent = Trash
			part.CFrame = CFrame.lookAlong(
				hrp.Position
					+ ((hrp.CFrame.UpVector * (part.Size.Y / 3.75)) + (hrp.CFrame.LookVector * (part.Size.Z / 2))),
				hrp.CFrame.LookVector
			)
			task.delay(DURATION, function()
				part.CanTouch = false
			end)
			Debris:AddItem(part, DURATION + 2)

			return part
		end

		task.delay(STARTUP, function()
			hrp = char:FindFirstChild("HumanoidRootPart")
			if not hrp then
				return
			end
			vfxRemote:FireAllClients(hrp, skill)

			backwardVelocity()
			setIsAttacking(char, hitType, 0.15)

			local hitbox: BasePart = playVFX()
			--Setup
			HitTracker[char] = HitTracker[char] or {}
			local hitBySkill = HitTracker[char][skill] or {}
			HitTracker[char][skill] = hitBySkill

			local touchedConnection
			touchedConnection = hitbox.Touched:Connect(function(hit: BasePart)
				if hit.Parent ~= char then
					if not hit.Parent:IsA("Model") then
						return
					end
					local opponentChar = hit.Parent :: Model
					local opponentHum = opponentChar:FindFirstChildOfClass("Humanoid") :: Humanoid?
					if not opponentHum then
						return
					end

					for _, attribute in pairs(Attributes.DOWNED_ATTRIBUTES) do
						if opponentChar:GetAttribute(attribute) then
							return
						end
					end

					if not hitBySkill[opponentChar] then
						hitBySkill[opponentChar] = true

						--Preventing an attack when player isn't supposed to attack or opponent isn't supposed to be hit
						HitModule.Hit(
							hum,
							opponentHum,
							hitType,
							DMG,
							STUN_TIME,
							PBable,
							nil,
							nil,
							nil,
							nil,
							nil,
							nil,
							nil,
							Effect,
							StatusEffect
						)
					end
				end
			end)

			task.delay(DURATION, function()
				for _, v in pairs(hitBySkill) do
					v = nil
				end
				hitBySkill = nil
				HitTracker[char] = nil

				if touchedConnection then
					touchedConnection:Disconnect()
					touchedConnection = nil
				end
			end)
		end)
	end,

	["Wintry Icicles"] = function(player: Player, char: Model, hum: Humanoid, skill: string, _mousePos: Vector3?)
		for _, v in Attributes.DOWNED_ATTRIBUTES do
			if char:GetAttribute(v) then
				return
			end
		end
		if hum:GetState() == Enum.HumanoidStateType.Dead then
			return
		end

		--STATS
		local hitCount = 4
		local hitType = "Sharp"
		local DMG = 8 / hitCount -- Damage dealt to the target
		local STUN_TIME = 1
		local PBable = false
		local KB = true
		local KBforce = 5
		local KB_TIME = 0.1
		local KB_Direction = "Away"
		local Ragdoll = true
		local Ragdoll_TIME = STUN_TIME
		local Effect = true
		local StatusEffect = "Frost"

		--COOLDOWN
		local COOLDOWN = 15 -- REAL CD IS 15s
		local STARTUP = 0.15
		local DURATION = 0.4
		local MAX_DISTANCE = 50 -- Max distance the projectile can be spawned

		local ok = SkillGuard:CheckSkillAllowed(player, char, skill, COOLDOWN, true, DURATION)
		if not ok then
			return
		end

		local function playVFX(hrp: BasePart, opponentHrp: BasePart): BasePart
			--//MAIN
			local model: Model = SkillsetsVFX.BDAs.Doma["Wintry Icicles"]
			model = model:Clone()
			local hitbox: BasePart = model.Hitbox
			model.PrimaryPart = hitbox

			--Properties
			model.Parent = Trash
			model:PivotTo(CFrame.new(opponentHrp.Position + (hrp.CFrame.UpVector * 15)))
			for _, part: BasePart in pairs(model:GetChildren()) do
				if not part:IsA("BasePart") then
					continue
				end

				--part.Position = opponentHrp.Position + (hrp.CFrame.UpVector * 15)
				TweenService:Create(
					part,
					TweenInfo.new(DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0),
					{ Position = part.Position + (hrp.CFrame.UpVector * math.random(-18, -15)) }
				):Play()

				task.delay(DURATION, function()
					TweenService:Create(
						part,
						TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0),
						{ Transparency = 1 }
					):Play()

					--Particles
					for _, v: Instance in pairs(part:GetChildren()) do
						if not v:IsA("ParticleEmitter") then
							continue
						end
						v.Enabled = false --Disable particles because they are played on the client
					end
				end)
			end

			--hitbox.CanTouch = false

			--task.wait(0.1) --Pause before moving projectile

			--hitbox.CanTouch = true
			task.delay(DURATION, function()
				hitbox.CanTouch = false
			end)

			Debris:AddItem(model, DURATION + 3)

			return hitbox
		end

		animRemote:FireAllClients(hum, skill)

		task.delay(STARTUP, function()
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then
				return
			end
			--vfxRemote:FireAllClients(hrp, skill)

			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { char }

			local length: number, height: number, depth: number = 10, 10, MAX_DISTANCE -- Size of the box
			local hitboxSize: Vector3 = Vector3.new(length, height, depth)
			local hitboxCFrame = hrp.CFrame * CFrame.new(0, 0, -depth / 2) --Position of hitbox

			local partsInBox = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, params)
			if partsInBox then
				for _, v in ipairs(partsInBox) do
					if v.Name ~= "HumanoidRootPart" then
						continue
					end

					local opponentChar = v.Parent :: Model?
					if not opponentChar then
						return
					end
					local opponentHum = opponentChar:FindFirstChildOfClass("Humanoid") :: Humanoid?
					if not opponentHum then
						return
					end
					local opponentHrp = v

					--Multiple hits
					local hitbox: BasePart = playVFX(hrp, opponentHrp)

					--Setup
					HitTracker[char] = HitTracker[char] or {}
					local hitBySkill = HitTracker[char][skill] or {}
					HitTracker[char][skill] = hitBySkill

					local touchedConnection
					touchedConnection = hitbox.Touched:Connect(function(hit: BasePart)
						if hit.Parent ~= char then
							if not hit.Parent:IsA("Model") then
								return
							end
							local opponentChar_Touched = hit.Parent :: Model
							local opponentHum_Touched =
								opponentChar_Touched:FindFirstChildOfClass("Humanoid") :: Humanoid?
							if not opponentHum_Touched then
								return
							end

							for _, attribute in pairs(Attributes.DOWNED_ATTRIBUTES) do
								if opponentChar_Touched:GetAttribute(attribute) then
									return
								end
							end

							if not hitBySkill[opponentChar_Touched] then
								hitBySkill[opponentChar_Touched] = true

								--Preventing an attack when player isn't supposed to attack or opponent isn't supposed to be hit
								for _ = 1, hitCount do
									HitModule.Hit(
										hum,
										opponentHum_Touched,
										hitType,
										DMG,
										STUN_TIME,
										PBable,
										KB,
										KBforce,
										KB_TIME,
										KB_Direction,
										nil,
										Ragdoll,
										Ragdoll_TIME,
										Effect,
										StatusEffect
									)
								end
								pcall(function()
									local breakSound: Sound = hitbox:FindFirstChildOfClass("Sound")
									if breakSound then
										breakSound:Play()
									end
								end)
							end
						end
					end)

					task.delay(DURATION, function()
						for _, v in pairs(hitBySkill) do
							v = nil
						end
						hitBySkill = nil
						HitTracker[char] = nil

						if touchedConnection then
							touchedConnection:Disconnect()
							touchedConnection = nil
						end
					end)

					break
				end
			end
		end)
	end,
}

-----| Breaths |-----
SkillsModule.Moon = {
	["Loathsome Moon, Chains"] = function(player: Player, char: Model, hum: Humanoid, skill: string)
		for _, v in Attributes.DOWNED_ATTRIBUTES do
			if char:GetAttribute(v) then
				return
			end
		end
		if hum:GetState() == Enum.HumanoidStateType.Dead then
			return
		end

		local Breath_NEEDED = 15

		--STATS (Change as needed)
		local hitType = "Sharp"
		local DMG = 6 / 2 --Damage per hit / number of hits
		local STUN_TIME = 1
		local PBable = false
		local KB = true
		local KBforce = 50
		local KB_TIME = 0.1
		local KB_Direction = "Away"
		local Ragdoll = true
		local Ragdoll_TIME = STUN_TIME --(2.5)

		--COOLDOWN
		local COOLDOWN = 12 --15s
		local STARTUP = 0.3
		local ENDLAG = 0.75
		local _DURATION = ENDLAG - STARTUP

		local enoughBreath: boolean, breathAmount: number = BreathingHandler:CheckBreathingBar(Breath_NEEDED, char)
		if not enoughBreath then
			return
		end

		local ok: boolean = SkillGuard:CheckSkillAllowed(player, char, skill, COOLDOWN, true, ENDLAG)
		if not ok then
			return
		end

		BreathingHandler:SubtractBreathingBar(breathAmount, Breath_NEEDED, char)

		--VFX--
		--Creating variables
		local VFX: Folder = SkillsetsVFX.Breaths.Moon[skill]
		local Crescent1: MeshPart = VFX.Crescent1:Clone()
		local Crescent2: MeshPart = VFX.Crescent2:Clone()
		local hitbox: Part = VFX.Hitbox:Clone()

		local function playVFX(hrp: BasePart, hrpPosition: Vector3, hrpLookVector: Vector3)
			--If cannot play VFX, return
			if not SkillGuard:CanPlayFX(char) then
				return
			end

			--Enable Particles
			for _, child in Crescent1:GetChildren() do --Crescent1 VFX
				if child:IsA("ParticleEmitter") then
					child.Enabled = true
					task.delay(0.35, function() -- Disable particles after delay
						child.Enabled = false
					end)
				end
			end
			for _, child in Crescent2:GetChildren() do --Crescent2 VFX
				if child:IsA("ParticleEmitter") then
					child.Enabled = true
					task.delay(0.35, function() -- Disable particles after delay
						child.Enabled = false
					end)
				end
			end
			local rootAttachment = Instance.new("Attachment")
			rootAttachment.Parent = hrp
			for _, child in VFX.RootAttachment:GetChildren() do --Root attachment VFX
				if child:IsA("ParticleEmitter") then
					local clonedChild = child:Clone()
					clonedChild.Parent = rootAttachment
					if clonedChild.Name == "Swirl" or clonedChild.Name == "Swirl2" then
						clonedChild.Enabled = false
						clonedChild:Emit(1) --Force emit these
					else
						clonedChild.Enabled = true
						task.delay(0.35, function() -- Disable particles after delay
							clonedChild.Enabled = false
						end)
					end
				end
			end

			local GroundAttachment = VFX.GroundAttachment:Clone()
			GroundAttachment.Parent = hrp
			for _, child in GroundAttachment:GetChildren() do --Ground attachment VFX
				if child:IsA("ParticleEmitter") then
					child.Enabled = false
					child:Emit(1) --Force emit these
				end
			end

			--Parenting to workspace (Trash)
			Crescent1.Parent = Trash
			Crescent2.Parent = Trash
			hitbox.Parent = Trash

			--CFrames
			Crescent1.CFrame = CFrame.lookAt(hrpPosition, hrpPosition + hrpLookVector) --* CFrame.Angles(-45, 180, 45)
			Crescent2.CFrame = CFrame.lookAt(hrpPosition, hrpPosition + hrpLookVector) --* CFrame.Angles(0, 0, 45)
			hitbox.CFrame = CFrame.lookAt(hrpPosition, hrpPosition + hrpLookVector) --* CFrame.Angles(0, 0, 45)
			Crescent1.Orientation = Crescent1.Orientation --+ Vector3.new(0, 0, 0)
			Crescent2.Orientation = Crescent2.Orientation + Vector3.new(0, 180, -90)

			--Tween info
			local tweenInfo_Transparency =
				TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0)
			local tweenInfo_Position = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)
			local tweenInfo_Rotation = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0)

			--   TWEENS   --
			task.delay(0.35, function() --Wait to tween transparency
				--tween1_Trans
				TweenService:Create(Crescent1, tweenInfo_Transparency, { Transparency = 1 }):Play()
				--tween2_Trans
				TweenService:Create(Crescent2, tweenInfo_Transparency, { Transparency = 1 }):Play()
			end)

			--tween1_Pos
			TweenService:Create(Crescent1, tweenInfo_Position, { Position = Crescent1.Position + (hrpLookVector * 40) })
				:Play()
			--tween2_Pos
			TweenService:Create(Crescent2, tweenInfo_Position, { Position = Crescent2.Position + (hrpLookVector * 43) })
				:Play()
			--tweenHITBOX_Pos
			TweenService:Create(hitbox, tweenInfo_Position, { Position = Crescent2.Position + (hrpLookVector * 43) })
				:Play()

			--tween1_Rot
			TweenService
				:Create(
					Crescent1,
					tweenInfo_Rotation,
					{ Orientation = Crescent1.Orientation + Vector3.new(-500, 0, 0) }
				)
				:Play()
			--tween2_Rot
			TweenService
				:Create(
					Crescent2,
					tweenInfo_Rotation,
					{ Orientation = Crescent2.Orientation + Vector3.new(0, -500, 0) }
				)
				:Play()

			--Cleanup (Debris)
			Debris:AddItem(Crescent1, 2)
			Debris:AddItem(Crescent2, 2)
			Debris:AddItem(hitbox, 1)
			Debris:AddItem(rootAttachment, 1.5)
			Debris:AddItem(GroundAttachment, 1.5)
		end
		local function playSFX(hrp: BasePart)
			--If cannot play VFX, return
			if not SkillGuard:CanPlayFX(char) then
				return
			end

			local SFX = ReplicatedStorage.FX.SFX.Combat.Skillsets.Breaths.Moon.LoathsomeMoon:Clone()
			--^^^change to actual sound
			SFX.Parent = hrp
			SFX:Play()
			Debris:AddItem(SFX, SFX.TimeLength)
		end

		animRemote:FireAllClients(hum, skill)

		task.delay(STARTUP, function()
			setIsAttacking(char, hitType, 0.15)

			--Getting RootPart info
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then
				return
			end

			local hrpPosition = hrp.Position
			local hrpLookVector = hrp.CFrame.LookVector
			--Calling FX functions
			playVFX(hrp, hrpPosition, hrpLookVector) --change arguments/parameters as needed
			playSFX(hrp)

			--Setup
			HitTracker[char] = HitTracker[char] or {}
			local hitBySkill = HitTracker[char][skill] or {}
			HitTracker[char][skill] = hitBySkill

			local touchedConnection
			touchedConnection = hitbox.Touched:Connect(function(hit: BasePart)
				if hit.Parent ~= char then
					if not hit.Parent:IsA("Model") then
						return
					end
					local opponentChar = hit.Parent :: Model
					local opponentHum = opponentChar:FindFirstChildOfClass("Humanoid") :: Humanoid?
					if not opponentHum then
						return
					end

					for _, attribute in pairs(Attributes.DOWNED_ATTRIBUTES) do
						if opponentChar:GetAttribute(attribute) then
							return
						end
					end

					if not hitBySkill[opponentChar] then
						hitBySkill[opponentChar] = true

						for _ = 1, 2 do
							--Preventing an attack when player isn't supposed to attack or opponent isn't supposed to be hit
							HitModule.Hit(
								hum,
								opponentHum,
								hitType,
								DMG,
								STUN_TIME,
								PBable,
								KB,
								KBforce,
								KB_TIME,
								KB_Direction,
								0,
								Ragdoll,
								Ragdoll_TIME
							)
						end
					end
				end
			end)
			task.delay(0.5, function()
				for _, v in pairs(hitBySkill) do
					v = nil
				end
				hitBySkill = nil
				HitTracker[char] = nil

				if touchedConnection then
					touchedConnection:Disconnect()
					touchedConnection = nil
				end
			end)

			task.delay(0.5, function()
				hitbox.CanTouch = false
			end)
		end)
	end,

	["Moon Spirit Calamitous Eddy"] = function(player: Player, char: Model, hum: Humanoid, skill: string)
		for _, v in Attributes.DOWNED_ATTRIBUTES do
			if char:GetAttribute(v) then
				return
			end
		end
		if hum:GetState() == Enum.HumanoidStateType.Dead then
			return
		end

		local Breath_NEEDED = 20

		--STATS
		local hitCount = 3
		local hitType = "Sharp"
		local DMG = 7.5 / hitCount -- Damage dealt to the target
		local STUN_TIME = 0.6
		local PBable = false
		local KB = true
		local KBforce = 5
		local KB_TIME = 0.1
		local KB_Direction = "Look"

		--COOLDOWN
		local COOLDOWN = 14 -- REAL CD IS 12s
		local STARTUP = 0.3

		local enoughBreath: boolean, breathAmount: number = BreathingHandler:CheckBreathingBar(Breath_NEEDED, char)
		if not enoughBreath then
			return
		end

		local ok: boolean = SkillGuard:CheckSkillAllowed(player, char, skill, COOLDOWN, true, 1)
		if not ok then
			return
		end

		BreathingHandler:SubtractBreathingBar(breathAmount, Breath_NEEDED, char)

		animRemote:FireAllClients(hum, skill)

		task.delay(STARTUP, function()
			--Setup
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { char }
			local length = 20
			local height = 10
			local depth = 20
			local hitboxSize = Vector3.new(length, height, depth) -- width, height depth

			--Multiple hits
			for i = 1, hitCount do
				if i == 1 then
					PBable = true
				else
					PBable = false
				end

				--Getting RootPart info
				local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if not hrp then
					return
				end

				vfxRemote:FireAllClients(hrp, skill)

				setIsAttacking(char, hitType, 0.15)

				local hitboxCFrame = hrp.CFrame * CFrame.new(0, 0, -depth / 2) --Position of hitbox
				local partsInBox = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, params)

				if partsInBox then
					for _, v in pairs(partsInBox) do
						if v.Name == "HumanoidRootPart" then
							local opponentChar = v.Parent :: Model?
							if not opponentChar then
								return
							end
							local opponentHum = opponentChar:FindFirstChildOfClass("Humanoid") :: Humanoid?
							if not opponentHum then
								return
							end

							--print('HRP Found!')

							--Preventing an attack when player isn't supposed to attack or opponent isn't supposed to be hit
							HitModule.Hit(
								hum,
								opponentHum,
								hitType,
								DMG,
								STUN_TIME,
								PBable,
								KB,
								KBforce,
								KB_TIME,
								KB_Direction,
								0
							)
						end
					end
				end

				task.wait(0.2) -- Interval between hits
			end
		end)
	end,

	["Catastrophe, Tenman Crescent Moon"] = function(player: Player, char: Model, hum: Humanoid, skill: string)
		for _, v in Attributes.DOWNED_ATTRIBUTES do
			if char:GetAttribute(v) then
				return
			end
		end
		if hum:GetState() == Enum.HumanoidStateType.Dead then
			return
		end

		local Breath_NEEDED = 35

		--STATS
		local hitCount = 10
		local hitType = "Sharp"
		local DMG = 10 / hitCount -- Damage dealt to the target per hit
		local STUN_TIME = 0.6
		local PBable = false
		local KB = true
		local KBforce = 10
		local KB_TIME = 0.1
		local KB_Direction = "Away"

		--COOLDOWN
		local COOLDOWN = 20 -- REAL COOLDOWN IS 20s, SET TO 5 FOR TESTING
		local STARTUP = 0.6

		local enoughBreath: boolean, breathAmount: number = BreathingHandler:CheckBreathingBar(Breath_NEEDED, char)
		if not enoughBreath then
			return
		end

		local ok: boolean = SkillGuard:CheckSkillAllowed(player, char, skill, COOLDOWN, true, 1.8)
		if not ok then
			return
		end

		BreathingHandler:SubtractBreathingBar(breathAmount, Breath_NEEDED, char)

		animRemote:FireAllClients(hum, skill)

		task.delay(STARTUP, function()
			--Setting IsAttacking and AttackType onto attacker
			setIsAttacking(char, hitType, 0.15 * hitCount)

			--Setup
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { char }
			--Hitbox size (depth dynamically changes in hitloop below)
			local length = 22.5
			local height = 25
			--Hit loop
			for i = 1, hitCount do
				if i <= 2 then
					PBable = true
				else
					PBable = false
				end

				--Dynamic hitbox depth
				local depth = 5 + (i * 5) -- Depth increases with each hit
				local hitboxSize = Vector3.new(length, height, depth) -- width, height depth

				--Getting RootPart info
				local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if not hrp then
					return
				end

				vfxRemote:FireAllClients(hrp, skill)

				local hitboxCFrame = hrp.CFrame * CFrame.new(0, 0, -depth / 2) --Position of hitbox
				local partsInBox = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, params)
				if partsInBox then
					for _, v in pairs(partsInBox) do
						if v.Name == "HumanoidRootPart" then
							local opponentChar = v.Parent :: Model?
							if not opponentChar then
								return
							end
							local opponentHum = opponentChar:FindFirstChildOfClass("Humanoid") :: Humanoid?
							if not opponentHum then
								return
							end

							HitModule.Hit(
								hum,
								opponentHum,
								hitType,
								DMG,
								STUN_TIME,
								PBable,
								KB,
								KBforce,
								KB_TIME,
								KB_Direction,
								0
							)
						end
					end
				end

				task.wait(0.1) -- Interval between hits
			end
		end)
	end,

	["Moonbow, Half Moon"] = function(player: Player, char: Model, hum: Humanoid, skill: string)
		for _, v in Attributes.DOWNED_ATTRIBUTES do
			if char:GetAttribute(v) then
				return
			end
		end
		if hum:GetState() == Enum.HumanoidStateType.Dead then
			return
		end

		local Breath_NEEDED = 25

		--STATS
		local hitCount = 6
		local hitType = "Sharp"
		local DMG = 6 / hitCount -- Damage dealt to the target
		local STUN_TIME = 0.6
		local PBable = false
		local KB = true
		local KBforce = 7.5
		local KB_TIME = 0.1
		local KB_Direction = "Away"

		--COOLDOWN
		local COOLDOWN = 16 --20s
		local STARTUP = 0.4

		local enoughBreath: boolean, breathAmount: number = BreathingHandler:CheckBreathingBar(Breath_NEEDED, char)
		if not enoughBreath then
			return
		end

		local ok: boolean = SkillGuard:CheckSkillAllowed(player, char, skill, COOLDOWN, true, 1.25)
		if not ok then
			return
		end

		BreathingHandler:SubtractBreathingBar(breathAmount, Breath_NEEDED, char)

		animRemote:FireAllClients(hum, skill)

		--Setting IsAttacking and AttackType onto attacker
		task.delay(STARTUP, function()
			setIsAttacking(char, hitType, 0.15 * hitCount)

			--Setup
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { char }
			--Hitbox size
			local length = 20
			local height = 20
			local depth = 20
			local hitboxSize = Vector3.new(length, height, depth) -- width, height depth
			--Hit loop
			for _ = 1, hitCount do
				--Getting RootPart info
				local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if not hrp then
					return
				end

				vfxRemote:FireAllClients(hrp, skill)

				local hitboxCFrame = hrp.CFrame * CFrame.new(0, 0, -depth / 2) --Position of hitbox
				local partsInBox = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, params)

				if partsInBox then
					for _, v in pairs(partsInBox) do
						if v.Name == "HumanoidRootPart" then
							local opponentChar = v.Parent :: Model?
							if not opponentChar then
								return
							end
							local opponentHum = opponentChar:FindFirstChildOfClass("Humanoid") :: Humanoid?
							if not opponentHum then
								return
							end

							HitModule.Hit(
								hum,
								opponentHum,
								hitType,
								DMG,
								STUN_TIME,
								PBable,
								KB,
								KBforce,
								KB_TIME,
								KB_Direction,
								0
							)
						end
					end
				end

				task.wait(0.1) -- Interval between hits
			end
		end)
	end,
}

SkillsModule.Sun = {
	["Dance"] = function(player: Player, char: Model, hum: Humanoid, skill: string)
		for _, v in Attributes.DOWNED_ATTRIBUTES do
			if char:GetAttribute(v) then
				return
			end
		end
		if hum:GetState() == Enum.HumanoidStateType.Dead then
			return
		end

		local Breath_NEEDED = 15

		--STATS (Change as needed)
		local hitType = "Sharp"
		local DMG = 5
		local STUN_TIME = 2.5
		local PBable = true
		local KB = true
		local KB_FORCE = 50
		local KB_TIME = 0.1
		local KB_Direction = "Look"
		local Ragdoll = true
		local Ragdoll_TIME = STUN_TIME
		local Effect = true
		local StatusEffect = "Burn"

		--COOLDOWN
		local COOLDOWN = 12 --12s
		local STARTUP = 0.3

		local enoughBreath: boolean, breathAmount: number = BreathingHandler:CheckBreathingBar(Breath_NEEDED, char)
		if not enoughBreath then
			return
		end

		local ok: boolean = SkillGuard:CheckSkillAllowed(player, char, skill, COOLDOWN, true, 0.9)
		if not ok then
			return
		end

		BreathingHandler:SubtractBreathingBar(breathAmount, Breath_NEEDED, char)

		animRemote:FireAllClients(hum, skill)

		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then
			return
		end

		local function forwardVelocity()
			--preventing velocity if ragdolled, stunned, or blocking
			for _, attribute in pairs(Attributes.PREVENTION_ATTRIBUTES) do
				if char:GetAttribute(attribute) then
					return
				end
			end

			--Actual velocity code
			local bv: BodyVelocity = Instance.new("BodyVelocity")
			bv.MaxForce = Vector3.new(100000, 100000, 100000)
			bv.Velocity = hrp.CFrame.LookVector * 60
			bv.Parent = hrp
			Debris:AddItem(bv, 0.2)
		end

		task.delay(STARTUP - 0.1, forwardVelocity)
		task.delay(STARTUP, function()
			vfxRemote:FireAllClients(hrp, skill)

			setIsAttacking(char, hitType, 0.20)
			--Setup
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { char }
			local length = 10
			local height = 15
			local depth = 17.5
			local hitboxSize = Vector3.new(length, height, depth) -- width, height depth

			--Getting RootPart info
			hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then
				return
			end

			local hitboxCFrame = hrp.CFrame * CFrame.new(0, 0, -depth / 2) --Position of hitbox
			local partsInBox = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, params)
			--visualizeHitbox(hitboxCFrame, hitboxSize, 0.5)
			if partsInBox then
				for _, v in pairs(partsInBox) do
					if v.Name == "HumanoidRootPart" then
						local opponentChar = v.Parent :: Model?
						if not opponentChar then
							return
						end
						local opponentHum = opponentChar:FindFirstChildOfClass("Humanoid") :: Humanoid?
						if not opponentHum then
							return
						end

						--Preventing an attack when player isn't supposed to attack or opponent isn't supposed to be hit
						HitModule.Hit(
							hum,
							opponentHum,
							hitType,
							DMG,
							STUN_TIME,
							PBable,
							KB,
							KB_FORCE,
							KB_TIME,
							KB_Direction,
							0,
							Ragdoll,
							Ragdoll_TIME,
							Effect,
							StatusEffect
						)
					end
				end
			end
		end)
	end,

	["Raging Sun"] = function(player: Player, char: Model, hum: Humanoid, skill: string)
		for _, v in Attributes.DOWNED_ATTRIBUTES do
			if char:GetAttribute(v) then
				return
			end
		end
		if hum:GetState() == Enum.HumanoidStateType.Dead then
			return
		end

		local Breath_NEEDED = 15

		--STATS (Change as needed)
		local hitCount = 2

		local hitType = "Sharp"
		local DMG = 4 / hitCount --Damage / # of hits
		local STUN_TIME = 0.75
		local PBable = false
		local KB = true
		local KB_FORCE = 7.5
		local KB_TIME = 0.1
		local KB_Direction = "Away"
		local Ragdoll = false
		local Ragdoll_TIME = STUN_TIME
		local Effect = true
		local StatusEffect = "Burn"

		--COOLDOWN
		local COOLDOWN = 12 --12s
		local STARTUP = 0.3
		local TIME_BETWEEN_HITS = 0.3

		local enoughBreath: boolean, breathAmount: number = BreathingHandler:CheckBreathingBar(Breath_NEEDED, char)
		if not enoughBreath then
			return
		end

		local ok: boolean = SkillGuard:CheckSkillAllowed(player, char, skill, COOLDOWN, true, 0.9)
		if not ok then
			return
		end

		BreathingHandler:SubtractBreathingBar(breathAmount, Breath_NEEDED, char)

		animRemote:FireAllClients(hum, skill)

		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then
			return
		end

		task.delay(STARTUP, function()
			vfxRemote:FireAllClients(hrp, skill)

			for i = 1, hitCount do
				setIsAttacking(char, hitType, 0.20)

				--Setup
				local params = OverlapParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances = { char }
				local length = 15 --13
				local height = 13 --13
				local depth = 22.5 --17.5
				local hitboxSize = Vector3.new(length, height, depth) -- width, height depth

				--Getting RootPart info
				hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if not hrp then
					return
				end

				local hitboxCFrame = hrp.CFrame --Position of hitbox
				--local hitboxCFrame = hrp.CFrame * CFrame.new(0, 0, -depth / 2) --Position of hitbox
				local partsInBox = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, params)
				if partsInBox then
					for _, v in pairs(partsInBox) do
						if v.Name == "HumanoidRootPart" then
							local opponentChar = v.Parent :: Model?
							if not opponentChar then
								return
							end
							local opponentHum = opponentChar:FindFirstChildOfClass("Humanoid") :: Humanoid?
							if not opponentHum then
								return
							end

							--print('HRP Found!')

							--Preventing an attack when player isn't supposed to attack or opponent isn't supposed to be hit
							HitModule.Hit(
								hum,
								opponentHum,
								hitType,
								DMG,
								STUN_TIME,
								PBable,
								KB,
								KB_FORCE,
								KB_TIME,
								KB_Direction,
								0,
								Ragdoll,
								Ragdoll_TIME,
								Effect,
								StatusEffect
							)
						end
					end
				end
				task.wait(TIME_BETWEEN_HITS)
			end -- hit for loop
		end)
	end,

	["Burning Bones, Summer Sun"] = function(player: Player, char: Model, hum: Humanoid, skill: string)
		for _, v in Attributes.DOWNED_ATTRIBUTES do
			if char:GetAttribute(v) then
				return
			end
		end
		if hum:GetState() == Enum.HumanoidStateType.Dead then
			return
		end

		local Breath_NEEDED = 25

		--STATS (Change as needed)
		local hitCount = 6

		local hitType = "Sharp"
		local DMG = 5 / hitCount --Damage / # of hits
		local STUN_TIME = 0.6
		local PBable = false
		local KB = true
		local KB_FORCE = 5
		local KB_TIME = 0.1
		local KB_Direction = "Away"
		local Ragdoll = false
		local Ragdoll_TIME = STUN_TIME
		local Effect = true
		local StatusEffect = "Burn"

		--COOLDOWN
		local COOLDOWN = 14 --18s
		local STARTUP = 0.4
		local TIME_BETWEEN_HITS = 0.1

		local enoughBreath: boolean, breathAmount: number = BreathingHandler:CheckBreathingBar(Breath_NEEDED, char)
		if not enoughBreath then
			return
		end

		local ok: boolean = SkillGuard:CheckSkillAllowed(player, char, skill, COOLDOWN, true, 1)
		if not ok then
			return
		end

		BreathingHandler:SubtractBreathingBar(breathAmount, Breath_NEEDED, char)

		animRemote:FireAllClients(hum, skill)

		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then
			return
		end

		local function forwardVelocity()
			--preventing velocity if ragdolled, stunned, or blocking
			for _, attribute in pairs(Attributes.PREVENTION_ATTRIBUTES) do
				if char:GetAttribute(attribute) then
					return
				end
			end

			--Actual velocity code
			local bv: BodyVelocity = Instance.new("BodyVelocity")
			bv.MaxForce = Vector3.new(100000, 100000, 100000)
			bv.Velocity = hrp.CFrame.LookVector * 85
			bv.Parent = hrp
			Debris:AddItem(bv, 0.35)
		end

		task.delay(STARTUP, function()
			setIsAttacking(char, hitType, 0.65)
			forwardVelocity()
			vfxRemote:FireAllClients(hrp, skill)

			--Setup
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { char }
			local length: number, height: number, depth: number = 14, 14, 38
			local hitboxSize = Vector3.new(length, height, depth) -- width, height depth
			local hitboxCFrame = hrp.CFrame * CFrame.new(0, 0, -depth / 2) --Position of hitbox

			for _ = 1, hitCount do
				local partsInBox = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, params)
				--visualizeHitbox(hitboxCFrame, hitboxSize, 0.5)
				if partsInBox then
					for _, v in pairs(partsInBox) do
						if v.Name == "HumanoidRootPart" then
							local opponentChar = v.Parent :: Model?
							if not opponentChar then
								return
							end
							local opponentHum = opponentChar:FindFirstChildOfClass("Humanoid") :: Humanoid?
							if not opponentHum then
								return
							end

							--Preventing an attack when player isn't supposed to attack or opponent isn't supposed to be hit
							HitModule.Hit(
								hum,
								opponentHum,
								hitType,
								DMG,
								STUN_TIME,
								PBable,
								KB,
								KB_FORCE,
								KB_TIME,
								KB_Direction,
								0,
								Ragdoll,
								Ragdoll_TIME,
								Effect,
								StatusEffect
							)
						end
					end
				end
				task.wait(TIME_BETWEEN_HITS)
			end -- hit for loop
		end)
	end,

	["Setting Sun Transformation"] = function(player: Player, char: Model, hum: Humanoid, skill: string)
		for _, v in Attributes.DOWNED_ATTRIBUTES do
			if char:GetAttribute(v) then
				return
			end
		end
		if hum:GetState() == Enum.HumanoidStateType.Dead then
			return
		end

		local Breath_NEEDED = 20

		--STATS (Change as needed)
		local hitType = "Sharp"
		local DMG = 7 --Damage / # of hits
		local STUN_TIME = 1.5
		local PBable = true
		local KB = true
		local KB_FORCE = 30
		local KB_TIME = 0.1
		local KB_Direction = "Away"
		local Ragdoll = true
		local Ragdoll_TIME = STUN_TIME
		local Effect = true
		local StatusEffect = "Burn"

		--COOLDOWN
		local COOLDOWN = 10 --15s
		local STARTUP = 0.35

		local enoughBreath: boolean, breathAmount: number = BreathingHandler:CheckBreathingBar(Breath_NEEDED, char)
		if not enoughBreath then
			return
		end

		local ok: boolean = SkillGuard:CheckSkillAllowed(player, char, skill, COOLDOWN, true, 0.9)
		if not ok then
			return
		end

		BreathingHandler:SubtractBreathingBar(breathAmount, Breath_NEEDED, char)

		animRemote:FireAllClients(hum, skill)

		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then
			return
		end

		local function forwardVelocity()
			--preventing velocity if ragdolled, stunned, or blocking
			for _, attribute in pairs(Attributes.PREVENTION_ATTRIBUTES) do
				if char:GetAttribute(attribute) then
					return
				end
			end

			--Actual velocity code
			local bv: BodyVelocity = Instance.new("BodyVelocity")
			bv.MaxForce = Vector3.new(100000, 100000, 100000)
			bv.Velocity = hrp.CFrame.RightVector * 50
			bv.Parent = hrp
			Debris:AddItem(bv, 0.1)
		end

		task.delay(STARTUP - 0.1, forwardVelocity)
		task.delay(STARTUP, function()
			vfxRemote:FireAllClients(hrp, skill)

			setIsAttacking(char, hitType, 0.20)

			--Setup
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { char }
			local length: number, height: number, depth: number = 15, 13, 12
			local hitboxSize: Vector3 = Vector3.new(length, height, depth) -- width, height depth
			local hitboxCFrame: CFrame = hrp.CFrame * CFrame.new(0, 0, -depth / 2) --Position of hitbox

			local partsInBox = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, params)
			if partsInBox then
				for _, v in pairs(partsInBox) do
					if v.Name == "HumanoidRootPart" then
						local opponentChar = v.Parent :: Model?
						if not opponentChar then
							return
						end
						local opponentHum = opponentChar:FindFirstChildOfClass("Humanoid") :: Humanoid?
						if not opponentHum then
							return
						end

						--Preventing an attack when player isn't supposed to attack or opponent isn't supposed to be hit
						HitModule.Hit(
							hum,
							opponentHum,
							hitType,
							DMG,
							STUN_TIME,
							PBable,
							KB,
							KB_FORCE,
							KB_TIME,
							KB_Direction,
							0,
							Ragdoll,
							Ragdoll_TIME,
							Effect,
							StatusEffect
						)
					end
				end
			end
		end)
	end,
}

-- SkillsModule.Thunder = {

-- }

------------------

return SkillsModule
