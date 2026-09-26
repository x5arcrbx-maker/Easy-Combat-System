-- SERVICES
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- MODULES
local controlsModule = script.Parent:WaitForChild("Controls")
local controls = require(controlsModule)

-- REMOTES
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local attackRemote = remotesFolder:WaitForChild("CharacterAttack")

-- VARIABLES
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Code --
local GameCharacter = {}
GameCharacter.__index = GameCharacter

type GameCharacter_obj = {
	Style: string,
	Kills: number,
	Player: Player,
	Character: Model,
	Humanoid: Humanoid,
}

function GameCharacter.new(): GameCharacter_obj
	local self = setmetatable({}, GameCharacter)
	self.Style = "Default"
	self.Kills = 0
	self.Player = player
	self.Character = character
	self.Humanoid = humanoid

	return self
end

function GameCharacter:TryAttack(attackType: string)
	attackRemote:FireServer(attackType)
	print("Attack attempted:", attackType)
end

function GameCharacter:Init()
	local ok, err = pcall(function()
		GameCharacter.new()

		local function init_AttackControls()
			local function tryLightAttack(
				actionName: string,
				inputState: Enum.UserInputState,
				inputObject: InputObject
			): Enum.ContextActionResult
				if inputState == Enum.UserInputState.Begin then
					self:TryAttack("Light")
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
					self:TryAttack("Heavy")
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

return GameCharacter
