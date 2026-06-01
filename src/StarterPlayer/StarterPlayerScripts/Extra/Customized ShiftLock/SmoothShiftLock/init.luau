local SmoothShiftLock = {}
SmoothShiftLock.__index = SmoothShiftLock

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local WorkspaceService = game:GetService("Workspace")
local _TweenService = game:GetService("TweenService")

local UtilsFolder = script:WaitForChild("Utils")

local Maid = require(UtilsFolder:WaitForChild("Maid"))
local Signal = require(UtilsFolder:WaitForChild("Signal"))
local Spring = require(UtilsFolder:WaitForChild("Spring"))

local LocalPlayer = Players.LocalPlayer

local ToggleEvent = script:WaitForChild("ToggleShiftLock")
local EditConfig = script:WaitForChild("EditConfig")

local config = { --SETTINGS
	["CHARACTER_SMOOTH_ROTATION"] = true, --true
	["MANUALLY_TOGGLEABLE"] = true, --true
	["CHARACTER_ROTATION_SPEED"] = 3, --1
	["TRANSITION_SPRING_DAMPER"] = 0.75, --0.4
	["CAMERA_TRANSITION_IN_SPEED"] = 12, --8
	["CAMERA_TRANSITION_OUT_SPEED"] = 12, --10
	["LOCKED_CAMERA_OFFSET"] = Vector3.new(1.75, 0.25, 0), --Vector3.new(1.75, 0.25, 0)
	["LOCKED_MOUSE_ICON"] = "http://www.roblox.com/asset/?id=6001676828", --"rbxasset://textures/MouseLockedCursor.png"
	["SHIFT_LOCK_KEYBINDS"] = {
		Enum.KeyCode.LeftAlt, --KEYBOARD KEYBIND
		Enum.KeyCode.DPadLeft, --CONSOLE KEYBIND
	},
}

local ENABLED = false

local maid = Maid.new()

function SmoothShiftLock:Init()
	print("SmoothShiftlock initiated")

	local _managerMaid = Maid.new()
	SmoothShiftLock.ShiftLockToggled = Signal.new()

	if LocalPlayer.Character then
		coroutine.wrap(function()
			self:CharacterAdded()
		end)()
	end

	_managerMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(function()
		coroutine.wrap(function()
			self:CharacterAdded()
		end)()
	end))
end

function SmoothShiftLock:CharacterAdded()
	local self = setmetatable({}, SmoothShiftLock)
	--// Instances
	self.Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() :: Model
	self.RootPart = self.Character:WaitForChild("HumanoidRootPart") :: BasePart
	self.Humanoid = self.Character:WaitForChild("Humanoid") :: Humanoid
	self.Head = self.Character:WaitForChild("Head") :: BasePart

	--	BoolValue for shiftlock state, will be used to toggling on/off outside this script
	self.EnabledBoolValue = Instance.new("BoolValue") :: BoolValue
	self.EnabledBoolValue.Name = "ShiftLockEnabled"
	self.EnabledBoolValue.Value = ENABLED
	self.EnabledBoolValue.Parent = self.Character

	self.EnabledBoolValue.Changed:Connect(function(value: boolean)
		if not config.MANUALLY_TOGGLEABLE then
			return
		end
		if self.Humanoid and self.Humanoid.Health ~= 0 then
			self:ToggleShiftLock(value)
		end
	end)

	self.Camera = WorkspaceService.CurrentCamera :: Camera

	self._connectionsMaid = Maid.new()
	self.camOffsetSpring = Spring.new(Vector3.new(0, 0, 0))
	self.camOffsetSpring.Damper = config.TRANSITION_SPRING_DAMPER

	self._connectionsMaid:GiveTask(UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe or not config.MANUALLY_TOGGLEABLE then
			return
		end

		for _, keyBind in pairs(config.SHIFT_LOCK_KEYBINDS) do
			if (input.KeyCode == keyBind) and (self.Humanoid and self.Humanoid.Health ~= 0) then
				self:ToggleShiftLock(not ENABLED)
			end
		end
	end))

	self._connectionsMaid:GiveTask(RunService.RenderStepped:Connect(function()
		if self.Head.LocalTransparencyModifier > 0.6 then
			return
		end

		local camCF = self.Camera.CFrame
		local distance = (self.Head.Position - camCF.Position).magnitude

		if distance > 1 then
			self.Camera.CFrame = (self.Camera.CFrame * CFrame.new(self.camOffsetSpring.Position))

			if ENABLED and (UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter) then
				self:SetMouseState(ENABLED)
			end
		end
	end))

	self._connectionsMaid:GiveTask(ToggleEvent.Event:Connect(function(toggle: boolean)
		if self.Humanoid and self.Humanoid.Health ~= 0 then
			self:ToggleShiftLock(toggle)
		end
	end))

	self._connectionsMaid:GiveTask(EditConfig.Event:Connect(function(toChange, value)
		if config[toChange] ~= nil then
			config[toChange] = value
		end
	end))

	self._connectionsMaid:GiveTask(self.Humanoid.Died:Connect(function()
		self:CharacterDiedOrRemoved()
		return
	end))

	self._connectionsMaid:GiveTask(LocalPlayer.CharacterRemoving:Connect(function()
		self:CharacterDiedOrRemoved()
		return
	end))

	return self
end

function SmoothShiftLock:CharacterDiedOrRemoved()
	self:ToggleShiftLock(false)

	if self._connectionsMaid ~= nil then
		self._connectionsMaid:Destroy()
	end

	maid:DoCleaning()
end

function SmoothShiftLock:IsEnabled(): boolean
	return ENABLED
end

function SmoothShiftLock:SetMouseState(enable: boolean)
	UserInputService.MouseBehavior = (enable and Enum.MouseBehavior.LockCenter) or Enum.MouseBehavior.Default
end

function SmoothShiftLock:SetMouseIcon(enable: boolean)
	UserInputService.MouseIcon = (enable and config.LOCKED_MOUSE_ICON :: string) or ""
end

function SmoothShiftLock:TransitionLockOffset(enable: boolean)
	if enable then
		self.camOffsetSpring.Speed = config.CAMERA_TRANSITION_IN_SPEED or 8
		self.camOffsetSpring.Target = config.LOCKED_CAMERA_OFFSET or Vector3.new(1.75, 0.25, 0)
	else
		self.camOffsetSpring.Speed = config.CAMERA_TRANSITION_OUT_SPEED or 10
		self.camOffsetSpring.Target = Vector3.new(0, 0, 0)
	end
end

function SmoothShiftLock:ToggleShiftLock(enable: boolean)
	assert(typeof(enable) == typeof(false), "Enable value is not a boolean.")
	ENABLED = enable

	if self.EnabledBoolValue then
		self.EnabledBoolValue.Value = ENABLED
	end
	self:SetMouseState(ENABLED)
	self:SetMouseIcon(ENABLED)
	self:TransitionLockOffset(ENABLED)

	if ENABLED then
		maid:GiveTask(RunService.RenderStepped:Connect(function(delta)
			if self.Humanoid and self.RootPart then
				self.Humanoid.AutoRotate = not ENABLED
			end

			if ENABLED then
				if not self.Humanoid.Sit and config.CHARACTER_SMOOTH_ROTATION then
					local _x, y, _z = self.Camera.CFrame:ToOrientation()
					self.RootPart.CFrame = self.RootPart.CFrame:Lerp(
						CFrame.new(self.RootPart.Position) * CFrame.Angles(0, y, 0),
						delta * 5 * config.CHARACTER_ROTATION_SPEED
					)
				elseif not self.Humanoid.Sit then
					local _x, y, _z = self.Camera.CFrame:ToOrientation()
					self.RootPart.CFrame = CFrame.new(self.RootPart.Position) * CFrame.Angles(0, y, 0)
				end
			end

			if not ENABLED then
				maid:Destroy()
			end
		end))
	end

	SmoothShiftLock.ShiftLockToggled:Fire(ENABLED)

	return self
end

return SmoothShiftLock
