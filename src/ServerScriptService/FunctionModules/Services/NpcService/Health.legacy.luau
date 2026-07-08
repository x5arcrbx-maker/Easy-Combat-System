local HealthService = require(game:GetService("ServerScriptService").FunctionModules.Services.HealthService)
local character = script.Parent
HealthService:InitForCharacter(character)
