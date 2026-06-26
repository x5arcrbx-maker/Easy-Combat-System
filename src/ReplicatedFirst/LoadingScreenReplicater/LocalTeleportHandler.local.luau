local ReplicatedStorage = game:GetService("ReplicatedStorage")

local values = ReplicatedStorage:WaitForChild("Values") :: Folder
local boolValues = values:WaitForChild("BoolValues") :: Folder
local LoadingScreenMainMenu_Folder = boolValues:WaitForChild("LoadingScreen / MainMenu") :: Folder
local isReady = LoadingScreenMainMenu_Folder:WaitForChild("IsReady") :: BoolValue

repeat --Wait until player is loaded fully
	task.wait()
until isReady.Value == true

local remote = ReplicatedStorage.Remotes_Bindables.Remotes.GeneralPlayer.SpawnRemote :: RemoteEvent
remote:FireServer()
