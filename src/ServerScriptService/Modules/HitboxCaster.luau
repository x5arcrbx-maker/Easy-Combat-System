-- SERVICES
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- VARIABLES
local Trash = workspace:FindFirstChild("Trash") :: Folder
local RS_Modules = ReplicatedStorage:FindFirstChild("Modules") :: Folder
local RS_Functions = RS_Modules:FindFirstChild("Functions")
--
local shapes = {
	["Rectangle"] = function(cframe: CFrame, size: Vector3, params: OverlapParams): { BasePart }
		local partsInBox = workspace:GetPartBoundsInBox(cframe, size, params)
		return partsInBox
	end,
}
--
local Modules = script.Parent

-- MODULES
local HitManager = require(Modules:WaitForChild("HitManager"))
local StunHandler = require(Modules:FindFirstChild("StunHandler"))
local allowedToAttack = require(RS_Functions:FindFirstChild("AllowedToAttack"))

-- FUNCTIONS
function createShapeForDebug(cframe: CFrame, size: Vector3, castTime: number?)
	if not castTime then
		castTime = 0.25
	end

	local part = Instance.new("Part")
	part.Color = Color3.fromRGB(255, 0, 0)
	part.CastShadow = false
	part.Transparency = 0.65
	part.Material = Enum.Material.Neon
	part.Anchored = true
	part.CanTouch = false
	part.CanCollide = false
	part.CanQuery = false
	part.CFrame = cframe
	part.Size = size
	part.Parent = Trash

	Debris:AddItem(part, castTime)
end
--
local function setIsAttacking(character: Model, duration: number)
	character:SetAttribute("IsAttacking", true)
	task.delay(duration, function()
		character:SetAttribute("IsAttacking", false)
	end)
end

-- Code --
local HitboxCaster = {}

HitboxCaster.TryCast = function(
	Shape: string,
	attackDuration: number,
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
	direction: string,
	ragdollVal: boolean,
	ragdollTime: number
)
	-- Safety checks
	if not character or not allowedToAttack(character) then
		return
	end

	-- create variable for shape cast function and ensure it exists
	local shapeCastFunc = shapes[Shape]
	if not shapeCastFunc then
		warn(string.format("Shape cast function (%s) not found!", tostring(Shape)))
	end

	-- add stun to attacker before casting to prevent multiple castings
	StunHandler:Apply(character, stunTime_self, stunType_self)
	setIsAttacking(character, attackDuration)

	-- create parameters
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params:AddToFilter(character)
	-- place hitbox infront of character
	local new_cframe = cframe * CFrame.new(0, 0, -hitboxSize.Z / 2)

	-- call debug function if debug is enabled on character
	if character:GetAttribute("Debug") then
		createShapeForDebug(cframe, hitboxSize, 0.25)
	end
	-- get hitparts
	local hitParts = shapeCastFunc(new_cframe, hitboxSize, params)
	if hitParts then
		for _, part in pairs(hitParts) do
			if part.Name ~= "HumanoidRootPart" then
				continue
			end
			--ensure hitCharacter is a model and not the attacker
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
					direction,
					ragdollVal,
					ragdollTime
				)
			end
		end
	end
end

return HitboxCaster
