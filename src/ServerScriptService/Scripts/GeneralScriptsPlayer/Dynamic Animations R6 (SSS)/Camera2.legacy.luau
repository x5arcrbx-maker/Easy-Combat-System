-- Camera2 (Server)
local Players 			= game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local serverRemote  = ReplicatedStorage.Remotes_Bindables.Remotes["Dynamic Animations R6"].OnServer
local clientRemote  = ReplicatedStorage.Remotes_Bindables.Remotes["Dynamic Animations R6"].OnClient

local function fireAllClientsExcept(exceptionPlayer, ...)
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= exceptionPlayer then
			clientRemote:FireClient(player, ...)
		end
	end
end

-- signature: (player, camCFrame, normalizedMoveDir, veryNormalizedMoveDir, cameraBasedFlag)
serverRemote.OnServerEvent:Connect(function(
	player: Player, 
	camCFrame: CFrame, 
	normalizedMoveDir: Vector3, 
	veryNormalizedMoveDir: Vector3, 
	cameraBasedFlag: boolean?
)
	-- forward the data to all other clients; include the original player as first argument for identification
	fireAllClientsExcept(
		player, 
		player, 
		camCFrame, 
		normalizedMoveDir, 
		veryNormalizedMoveDir, 
		cameraBasedFlag
	)
end)
