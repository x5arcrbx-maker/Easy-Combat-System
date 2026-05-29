--	Main function to teleport player on spawn
local function teleportOnCharacterAdded(character)
	local hrp = character:WaitForChild("HumanoidRootPart") :: BasePart

	local SpawnsFolder = game:GetService("ReplicatedStorage"):WaitForChild("PlayerSpawns") :: Folder
	local PlayerSpawns = SpawnsFolder:GetChildren() :: { BasePart }
	local spawnPart = PlayerSpawns[math.random(1, #PlayerSpawns)] :: BasePart

	hrp.Position = spawnPart.Position + Vector3.new(0, 100, 0)
end

local values = game:GetService("ReplicatedStorage"):WaitForChild("Values")
local LoadingScreenMainMenu_Folder = values:WaitForChild("LoadingScreen / MainMenu")
local isReady = LoadingScreenMainMenu_Folder:WaitForChild("IsReady")
repeat
	task.wait()
until isReady.Value == true

local player = game:GetService("Players").LocalPlayer :: Player
if player.Character then
	teleportOnCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(teleportOnCharacterAdded)
