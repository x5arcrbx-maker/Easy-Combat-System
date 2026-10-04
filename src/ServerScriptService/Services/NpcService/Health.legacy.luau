local HealthService = require(game:GetService("ServerScriptService").Services.HealthService)
local character = script.Parent
HealthService:InitForCharacter(character)
