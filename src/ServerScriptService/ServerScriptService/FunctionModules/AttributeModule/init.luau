-- Unified attribute handler for both players and NPCs
local CharacterAttributes = {}

--//:SERVICES
local Players = game:GetService("Players")

---------------------------------------------------------------------
-- ATTRIBUTE LIST
---------------------------------------------------------------------

CharacterAttributes.Defaults = {
	-- Combat
	InCombat = false, --Checks if character is in combat
	Stunned = false, --For regular attacks / stuns (can be unstunned manually)
	TrueStunned = false, --For Perfect Blocks / GuardBreaks mainly (to prevent character being unstunned during a punish)
	Blocking = false, --For blocking
	BlockHits = 0, --The number of hits blocked (guardbreaks at 4)
	BlockTime = 0, --Time spent blocking (used for Perfect block timing)
	MovesetChangeCooldown = 0, --Cooldown for changing movesets
	--BreathingBar		  = 0, --Breathing bar (max is 100)
	Slowed = false, --Slowed down movement
	IsAttacking = false, --For clashing
	UsingAttack = false, --For using attacks (prevents stacking)
	AttackType = "None", --To detect if hit is blunt or sharp
	IsSprinting = false, --Sprinting attribute
	HeavyAttackOnCooldown = false, --Prevent heavy attack spam
	BlockOnCooldown = false, --Block cooldown
	LastKilled = "", --Last thing killed by character
	Weapon = "None", --Current weapon
	WeaponIsEquipped = false, --Weapon is equipped

	-- Status / physics
	Ragdolled = false, --Character is ragdolled
	-- Knocked   = false, --Character was knocked down due to reaching 0 health, will stand up after a short time as long as they aren't being carried
	-- Carrying  = false, --Player is carrying a charater
	-- Carried   = false, --Character is being carried by another character
	-- Gripped   = false, --Character is in the process of being killed (whilst knocked, and only after knocked)
	-- Gripping  = false, --Character is in the process of gripping another character

	-- Combo System
	Combo = 0, --Current combo count (is displayed via cooldown bar GUI)
	ComboMax = 5, --Max of M1s a player can do before combo is reset

	-- Non-PvP / misc
	-- Hunger 		   = 100, --Hunger (if 0 then regen is cut in half)
	DashOnCooldown = false, --Dash cooldown (for cooldown display via cooldown bar GUI)
	CanClimb = true, --If player can climb)
	ClimbCount = 0, --Used for wall climbing (Max is 3, resets on landed)
}

local HumanoidStates = require(game:GetService("ReplicatedStorage").Values.Tables.HumanoidStateTypes)
---------------------------------------------------------------------
-- Apply attributes to a character
---------------------------------------------------------------------

--MISC function to add highlight to characters
local function addHighlight(character: Model)
	local highlight: Highlight = Instance.new("Highlight")
	highlight.Name = "CharacterHighlight"
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0.5
	highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = character
end

--Adds trail to character for finishers
local function addTrailForFinishers(character: Model)
	local torso = character:WaitForChild("Torso") :: BasePart

	local neckAttachment = torso:WaitForChild("NeckAttachment") :: Attachment
	local waistCenterAttachment = torso:WaitForChild("WaistCenterAttachment") :: Attachment

	local trail = script.FinisherTrail
	local cloneTrail = trail:Clone()
	cloneTrail.Attachment0 = neckAttachment
	cloneTrail.Attachment1 = waistCenterAttachment
	cloneTrail.Enabled = false
	cloneTrail.Parent = character
end

function CharacterAttributes.ApplyTo(character)
	if not character then
		return
	end

	addHighlight(character)
	task.spawn(addTrailForFinishers, character)

	for attrName: string, defaultValue: any in pairs(CharacterAttributes.Defaults) do
		if character:GetAttribute(attrName) == nil then
			character:SetAttribute(attrName, defaultValue)
		end
	end

	local hum = character:WaitForChild("Humanoid") :: Humanoid
	for state: Enum.HumanoidStateType, value: boolean in pairs(HumanoidStates) do
		hum:SetStateEnabled(state, value)
	end
end

---------------------------------------------------------------------
-- Hook into all characters
---------------------------------------------------------------------

function CharacterAttributes.Init()
	-----------------------------------------------------------
	-- Players
	-----------------------------------------------------------
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			CharacterAttributes.ApplyTo(character)
		end)
		-- If character already loaded
		if player.Character then
			CharacterAttributes.ApplyTo(player.Character)
		end
	end)

	-- For existing players
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			CharacterAttributes.ApplyTo(player.Character)
		end
		player.CharacterAdded:Connect(function(character)
			CharacterAttributes.ApplyTo(character)
		end)
	end

	-----------------------------------------------------------
	-- NPCs (any humanoid model without a Player owner)
	-----------------------------------------------------------
	local function tryApply(model)
		if
			model:IsA("Model")
			and model:FindFirstChildOfClass("Humanoid")
			and not Players:GetPlayerFromCharacter(model)
		then
			CharacterAttributes.ApplyTo(model)
		end
	end

	-- Existing NPCs on startup
	local NPCsFolder: Folder = workspace.Collection.Characters
	for _, obj in ipairs(NPCsFolder:GetDescendants()) do
		tryApply(obj)
	end

	-- New NPCs created later
	NPCsFolder.DescendantAdded:Connect(function(obj)
		tryApply(obj)
	end)
end

return CharacterAttributes
