-- SERVICES
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _UserInputService = game:GetService("UserInputService")

-- VARIABLES
local player = Players.LocalPlayer :: Player
local character = player.Character or player.CharacterAdded:Wait() :: Model
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local animator = humanoid:WaitForChild("Animator") :: Animator
--
local playingTrack_LightAttack: AnimationTrack?
local playingTrack_HeavyAttack: AnimationTrack?
--
local Loader = script.Parent :: Folder
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
local remoteEventsFolder = remotesFolder:FindFirstChild("Events")
local RS_Modules = ReplicatedStorage:FindFirstChild("Modules") :: Folder
local RS_Functions = RS_Modules:FindFirstChild("Functions")
local tablesFolder = RS_Modules:FindFirstChild("Tables") :: Folder
local dictionariesFolder = tablesFolder:FindFirstChild("Dictionaries") :: Folder
local attributesModule = dictionariesFolder:FindFirstChild("Attributes") :: Folder
--
local controlsModule = Loader:WaitForChild("Controls")
local animationsModule = Loader:WaitForChild("AttackAnimations")
local comboModule = Loader:WaitForChild("Combo")
--
local debounce: boolean = false

-- MODULES
local allowedToAttack = require(RS_Functions:FindFirstChild("AllowedToAttack"))
local animations = require(animationsModule)
local attributes = require(attributesModule)
local combo = require(comboModule)
local controls = require(controlsModule)

-- REMOTES
local attackRemote = remoteEventsFolder:WaitForChild("CharacterAttack")

-- FUNCTIONS
local function debounceIfStunned(attr: string)
	if character:GetAttribute(attr) then
		debounce = true
	else
		for otherAttr, _ in pairs(attributes.Combat.Stun) do
			if attr == otherAttr then
				continue
			end
			if character:GetAttribute(otherAttr) then
				debounce = true
				continue
			else
				debounce = false
			end
		end
	end
end

-- EVENTS
for attr, _ in pairs(attributes.Combat.Stun) do
	character:GetAttributeChangedSignal(attr):Connect(function()
		debounceIfStunned(attr)
	end)
end

-- Code --
local GameCharacterObj = {}
GameCharacterObj.__index = GameCharacterObj

type GameCharacter_Class = {
	Style: string,
	Kills: number,
	Player: Player,
	Character: Model,
	Humanoid: Humanoid,
	Animator: Animator,
	Combo: { Amount: number, ResetTime: number, LastHitTime: number },
}

function GameCharacterObj.new(): GameCharacter_Class
	local self = setmetatable({}, GameCharacterObj)
	self.Style = "Default"
	self.Kills = 0
	self.Player = player
	self.Character = character
	self.Humanoid = humanoid
	self.Animator = animator
	self.Combo = combo

	return self
end

function GameCharacterObj:TryAttack(attackType: string): boolean
	if not allowedToAttack(self.Character) then
		-- print("Cannot attack while stunned or incapacitated.")
		return false
	end
	attackRemote:FireServer(attackType)
	-- print("Attack attempted:", attackType)
	return true
end

function GameCharacterObj:Init()
	local ok, err = pcall(function()
		local self = GameCharacterObj.new()

		local anims: { Heavy: Animation, Light: Animation }
		local lightAnims: { Animation }
		local heavyAnims: { Animation }
		local function init_Animations()
			if self.Character then
				print("Character exists")
			else
				print("Character is nil")
			end
			anims = animations(self.Character)
			lightAnims = anims.Light
			heavyAnims = anims.Heavy
		end
		init_Animations()

		local function init_AttackControls()
			self.Combo.ResetTime = character:GetAttribute("ComboResetTime")
			self.Combo.LastHitTime = character:GetAttribute("ComboLastHit")

			local function tryLightAttack(
				actionName: string,
				inputState: Enum.UserInputState,
				inputObject: InputObject
			): Enum.ContextActionResult
				-- Safety checks
				if inputState ~= Enum.UserInputState.Begin then
					return Enum.ContextActionResult.Pass
				end
				local attackType: string = "Light"
				if debounce or not self:TryAttack(attackType) then
					return Enum.ContextActionResult.Pass
				end

				debounce = true
				local currentCombo: number = character:GetAttribute("Combo") or 0
				local comboToSet: number
				local lastHitTime: number = character:GetAttribute("ComboLastHit")
				local resetTime: number = character:GetAttribute("ComboResetTime")
				if ((tick() - lastHitTime) >= resetTime) or ((currentCombo + 1) > 5) then
					comboToSet = 1
					print("Reset combo")
				else
					comboToSet = math.min(currentCombo + 1, #lightAnims)
				end
				-- if ((tick() - self.Combo.LastHitTime) >= self.Combo.ResetTime) or ((self.Combo.Amount + 1) > 5) then
				-- 	self.Combo.Amount = 1
				-- 	print("Reset combo")
				-- else
				-- 	self.Combo.Amount = math.min(self.Combo.Amount + 1, #lightAnims)
				-- end
				lastHitTime = tick()

				local index: number = comboToSet
				local animTrack: AnimationTrack = lightAnims[index]
				if animTrack then
					if playingTrack_LightAttack and playingTrack_LightAttack ~= animTrack then
						playingTrack_LightAttack:Stop()
						playingTrack_LightAttack:Destroy()
						playingTrack_LightAttack = nil
					end
					playingTrack_LightAttack = animTrack
					animTrack:Play()
					animTrack:GetMarkerReachedSignal("Ended"):Once(function()
						debounce = false
					end)
					animTrack.Stopped:Connect(function()
						if playingTrack_LightAttack == animTrack then
							playingTrack_LightAttack = nil
						end
					end)
					print(string.format("Playing light attack animation (combo amount: %d)", index))
				else
					warn(string.format("No animation found for light attack (combo amount: %d)", index))
				end
				return Enum.ContextActionResult.Sink
			end

			local function tryHeavyAttack(
				actionName: string,
				inputState: Enum.UserInputState,
				inputObject: InputObject
			): Enum.ContextActionResult
				-- Safety checks
				if inputState ~= Enum.UserInputState.Begin then
					return Enum.ContextActionResult.Pass
				end
				local attackType: string = "Heavy"
				if debounce or not self:TryAttack(attackType) then
					return Enum.ContextActionResult.Pass
				end

				debounce = true
				local index = math.random(1, #heavyAnims)
				local animTrack = heavyAnims[index]
				if animTrack then
					if playingTrack_HeavyAttack and playingTrack_HeavyAttack ~= animTrack then
						playingTrack_HeavyAttack:Stop()
						playingTrack_HeavyAttack:Destroy()
						playingTrack_HeavyAttack = nil
					end
					playingTrack_HeavyAttack = animTrack
					animTrack:Play()
					animTrack.Stopped:Connect(function()
						if playingTrack_HeavyAttack == animTrack then
							playingTrack_HeavyAttack = nil
						end
						debounce = false
					end)
				else
					warn(string.format("No animation found for heavy attack (index: %d)", index))
				end
				return Enum.ContextActionResult.Sink
			end

			local createTouchButton_LightAtk = false
			local createTouchButton_HeavyAtk = false

			ContextActionService:BindAction(
				"LightAttack",
				tryLightAttack,
				createTouchButton_LightAtk,
				controls.LightAttack.Keyboard,
				controls.LightAttack.Gamepad
			)
			ContextActionService:BindAction(
				"HeavyAttack",
				tryHeavyAttack,
				createTouchButton_HeavyAtk,
				controls.HeavyAttack.Keyboard,
				controls.HeavyAttack.Gamepad
			)
		end
		init_AttackControls()
	end)
	if not ok then
		error(("Error initializing game character:" .. tostring(err)), 2)
	else
		print("Game character initialized successfully.")
	end
end

return GameCharacterObj
