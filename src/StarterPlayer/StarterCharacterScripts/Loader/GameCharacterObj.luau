-- SERVICES
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- VARIABLES
local player = Players.LocalPlayer :: Player
local character = player.Character or player.CharacterAdded:Wait() :: Model
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local animator = humanoid:WaitForChild("Animator") :: Animator
local Loader = script.Parent
--
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
--
local controlsModule = Loader:WaitForChild("Controls")
local animationsModule = Loader:WaitForChild("Animations")
local comboModule = Loader:WaitForChild("Combo")
local RS_Modules = ReplicatedStorage:FindFirstChild("Modules")

-- MODULES
local allowedToAttack = require(RS_Modules:FindFirstChild("AllowedToAttack"))
local animations = require(animationsModule)
local combo = require(comboModule)
local controls = require(controlsModule)

-- REMOTES
local attackRemote = remotesFolder:WaitForChild("CharacterAttack")

-- FUNCTIONS

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
		print("Cannot attack while stunned or incapacitated.")
		return false
	end
	attackRemote:FireServer(attackType)
	-- print("Attack attempted:", attackType)
	return true
end

function GameCharacterObj:Init()
	local ok, err = pcall(function()
		local gameCharacter = GameCharacterObj.new()

		local anims
		local lightAnims
		local heavyAnims
		local function init_Animations()
			if gameCharacter.Character then
				print("Character exists")
			else
				print("Character is nil")
			end
			anims = animations(gameCharacter.Character)
			lightAnims = anims.Light
			heavyAnims = anims.Heavy
		end
		init_Animations()

		local function init_AttackControls()
			local function tryLightAttack(
				actionName: string,
				inputState: Enum.UserInputState,
				inputObject: InputObject
			): Enum.ContextActionResult
				if inputState == Enum.UserInputState.Begin then
					local attackType: string = "Light"
					if not gameCharacter:TryAttack(attackType) then
						return Enum.ContextActionResult.Pass
					end
					if tick() - gameCharacter.Combo.LastHitTime > gameCharacter.Combo.ResetTime then
						gameCharacter.Combo.Amount = 0
					else
						gameCharacter.Combo.Amount = math.min(gameCharacter.Combo.Amount + 1, #lightAnims)
					end
					gameCharacter.Combo.LastHitTime = tick()

					local index: number
					if gameCharacter.Combo.Amount < 5 then
						index = gameCharacter.Combo.Amount + 1
					else
						gameCharacter.Combo.Amount = 1
						index = gameCharacter.Combo.Amount
					end
					local animToPlay = lightAnims[index]
					if animToPlay and not animToPlay.IsPlaying then
						animToPlay:Play()
					else
						warn(string.format("No animation found for light attack (combo amount: %d)", index))
					end
					return Enum.ContextActionResult.Sink
				end
				return Enum.ContextActionResult.Pass
			end

			local function tryHeavyAttack(
				actionName: string,
				inputState: Enum.UserInputState,
				inputObject: InputObject
			): Enum.ContextActionResult
				if inputState == Enum.UserInputState.Begin then
					local attackType: string = "Heavy"
					if not gameCharacter:TryAttack(attackType) then
						return Enum.ContextActionResult.Pass
					end
					local index = math.random(1, #heavyAnims)
					local animToPlay = heavyAnims[index]
					if animToPlay and not animToPlay.IsPlaying then
						animToPlay:Play()
					else
						warn(string.format("No animation found for heavy attack (index: %d)", index))
					end
					return Enum.ContextActionResult.Sink
				end
				return Enum.ContextActionResult.Pass
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

			-- local function onInputBegan(input: InputObject, GPE: boolean)
			-- 	if GPE then
			-- 		return
			-- 	end

			-- 	if (input.UserInputType == controls.LightAttack.Keyboard) or (input.KeyCode == controls.LightAttack.Console) then
			-- 		self:TryAttack("Light")
			-- 	elseif (input.KeyCode == controls.HeavyAttack.Keyboard) or (input.KeyCode == controls.HeavyAttack.Console) then
			-- 		self:TryAttack("Heavy")
			-- 	end
			-- end

			-- UserInputService.InputBegan:Connect(function(input: InputObject, GPE: boolean)
			-- 	if GPE then
			-- 		return
			-- 	end

			-- 	if (input.UserInputType == controls.LightAttack.Keyboard) or (input.KeyCode == controls.LightAttack.Console) then
			-- 		self:TryAttack("Light")
			-- 	end
			-- end)
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
