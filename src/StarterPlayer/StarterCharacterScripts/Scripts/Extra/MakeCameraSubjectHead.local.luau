local player = game:GetService("Players").LocalPlayer
local character: Model = player.Character or player.CharacterAdded:Wait()
local head: BasePart = character:WaitForChild("Head")

local camera: Camera? = workspace.CurrentCamera
camera.CameraSubject = head