-- VARIABLES
local shapes = {
	["Rectangle"] = function(cframe: CFrame, size, params): { BasePart }
		local partsInBox = workspace:GetPartBoundsInBox(cframe, size, params)
		return partsInBox
	end,
}
local Modules = script.Parent

-- MODULES
local HitManager = require(Modules:WaitForChild("HitManager"))
local StunHandler = require(Modules:FindFirstChild("StunHandler"))

-- FUNCTIONS

-- Code --
local HitboxCaster = {}

HitboxCaster.TryCast = function(
	Shape: string,
	character: Model,
	cframe: CFrame,
	hitboxSize: Vector3,
	damage: number,
	stunTime_self: number,
	stunTime_target: number,
	stunType_self: string,
	stunType_target: string,
	force: number,
	forceTime: number,
	direction: string
)
	local shapeCastFunc = shapes[Shape]
	if not shapeCastFunc then
		warn(string.format("Shape cast function (%s) not found!", tostring(Shape)))
	end

	StunHandler:Apply(character, stunTime_self, stunType_self)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params:AddToFilter(character)
	local hitParts = shapeCastFunc(cframe, hitboxSize, params)
	if hitParts then
		for _, part in pairs(hitParts) do
			if part.Name ~= "HumanoidRootPart" then
				continue
			end
			local hitCharacter = part:FindFirstAncestorOfClass("Model")
			if hitCharacter and hitCharacter ~= character then
				HitManager.TryHit(
					character,
					hitCharacter,
					damage,
					stunTime_self,
					stunTime_target,
					stunType_self,
					stunType_target,
					force,
					forceTime,
					direction
				)
			end
		end
	end
end

-- HitboxCaster.castRectangleHitbox = function(
-- 	character: Model,
-- 	cframe: CFrame,
-- 	hitboxSize: Vector3,
-- 	damage: number,
-- 	stunTime_self: number,
-- 	stunTime_target: number,
-- 	stunType_self: string,
-- 	stunType_target: string,
-- 	force: number,
-- 	forceTime: number,
-- 	direction: string
-- )
-- 	StunHandler:Apply(character, stunTime_self, stunType_self)
-- 	local params = OverlapParams.new()
-- 	params.FilterType = Enum.RaycastFilterType.Exclude
-- 	params:AddToFilter(character)
-- 	local new_cframe = cframe * CFrame.new(0, 0, -hitboxSize.Z / 2) --place hitbox infront of character
-- 	local hitParts = workspace:GetPartBoundsInBox(new_cframe, hitboxSize, params)
-- 	if hitParts then
-- 		for _, part in pairs(hitParts) do
-- 			if part.Name ~= "HumanoidRootPart" then
-- 				continue
-- 			end
-- 			local hitCharacter = part:FindFirstAncestorOfClass("Model")
-- 			if hitCharacter and hitCharacter ~= character then
-- 				HitManager.TryHit(
-- 					character,
-- 					hitCharacter,
-- 					damage,
-- 					stunTime_self,
-- 					stunTime_target,
-- 					stunType_self,
-- 					stunType_target,
-- 					force,
-- 					forceTime,
-- 					direction
-- 				)
-- 			end
-- 		end
-- 	end
-- end

return HitboxCaster
