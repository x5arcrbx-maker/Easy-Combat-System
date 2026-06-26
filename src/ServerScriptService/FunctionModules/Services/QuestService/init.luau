local QuestService = {}

local _DataManager =
	require(game:GetService("ServerScriptService").FunctionModules.Services.ProfileStore.Data.DataManager)

function QuestService:Give(_player: Player, _questName: string) end

return QuestService
