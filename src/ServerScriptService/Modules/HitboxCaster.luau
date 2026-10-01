local Modules = script.Parent
local HitManager = require(Modules:WaitForChild("HitManager"))

local HitboxCaster = {}

HitboxCaster.castRectangleHitbox = function(
	character,
	cframe: CFrame,
	hitboxSize: Vector3,
	damage: number,
	stunTime_self: number,
	stunTime_target: number,
	stunType_self: string,
	stunType_target: string,
	force: number,
	forceTime: number
)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params:AddToFilter(character)
	local new_cframe = cframe * CFrame.new(0, 0, -hitboxSize.Z / 2) --place hitbox infront of character
	local hitParts = workspace:GetPartBoundsInBox(new_cframe, hitboxSize, params)
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
					forceTime
				)
			end
		end
	end
end

return HitboxCaster
