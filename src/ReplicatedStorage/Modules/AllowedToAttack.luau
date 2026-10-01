local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tablesFolder = ReplicatedStorage:FindFirstChild("Tables")
local dictionariesFolder = tablesFolder:FindFirstChild("Dictionaries")
local attributesModule = dictionariesFolder:FindFirstChild("Attributes")
local attributes = require(attributesModule)

return function(character: Model): boolean
	for attr, _ in pairs(attributes.Combat.Stun) do
		if character:GetAttribute(attr) then
			return false
		end
	end
	return true
end
