local DataManager = require(game:GetService("ServerScriptService").Modules.Services.ProfileStore.Data.DataManager)

local remote = game:GetService("ReplicatedStorage").Remotes_Bindables.Remotes.GeneralPlayer.GiveQuest



remote.OnServerEvent:Connect(function(player, questName: string?)
	if not questName then return end
	DataManager.UpdateQuest(player, questName)
end)
