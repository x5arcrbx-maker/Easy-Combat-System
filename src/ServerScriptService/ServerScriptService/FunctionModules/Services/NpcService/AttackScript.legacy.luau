--!strict
---------------------------------------------------------------------
-- NPC ATTACK SCRIPT
---------------------------------------------------------------------

--//:SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

--//:REMOTES
local EventsPVE = ReplicatedStorage.Remotes_Bindables.Bindables.PVE.M1sAndM2s
local M1BindableEvent: BindableEvent = EventsPVE.M1BindableEvent
local M2BindableEvent: BindableEvent = EventsPVE.M2BindableEvent

--//:VARIABLES (For character)
local character = script:FindFirstAncestorOfClass("Model") :: Model
local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart
local hum = character:FindFirstChildOfClass("Humanoid") :: Humanoid
local animator = hum:FindFirstChildOfClass("Animator") :: Animator

--//:MODULES
local MovementAnimator = require(ServerScriptService.FunctionModules.Services.NpcService.MovementAnimator) :: any
MovementAnimator.Apply(character)

-- Folders for M1s
local FistFolder: Folder? = ReplicatedStorage.Animations.M1s.Fist
local KatanaFolder: Folder? = ReplicatedStorage.Animations.M1s.Katana

assert(FistFolder, "M1 Animations folders not found. Ensure 'Fist' and 'Katana' folders exist in ReplicatedStorage")
assert(KatanaFolder, "M1 Animations folders not found. Ensure 'Fist' and 'Katana' folders exist in ReplicatedStorage")

-- M2 folders (may or may not exist)
local M2Root = ReplicatedStorage.Animations.M2s

-- Constants
local ATTACK_RANGE: number = 12
local ATTACK_INTERVAL: number = 0.05
local CHASE_RANGE: number = 150

local MIN_DASH_DISTANCE: number = 25
local MAX_DASH_DISTANCE: number = 125

-- State
local isAttacking: boolean = false
local combo: number = 0
local M1cooldown: boolean = false
local PREVENTION_ATTRIBUTES: { string } = {
	"Gripped",
	"Carried",
	"Knocked",
	"Ragdolled",

	"TrueStunned",
	"Stunned",

	"Blocking",
	"UsingAttack",
}
--local M2cooldown = false

-- Tracks
local normalTracks = {} -- indexes 1..5
local heavyTracks = {}

---------------------------------------------------------------------
-- APPLY WEAPON / RETURN WEAPON NAME + M1 FOLDER
---------------------------------------------------------------------
local function normalizeWeaponAttr(attribute: any?): string
	if not attribute then
		warn(
			("NPC [%s] has invalid AttackNpcWeapon attribute value: %s, defaulting to Fists as weapon"):format(
				character.Name,
				tostring(attribute)
			)
		)
		return "Fist"
	end

	-- Normalize different possible values
	if attribute == true or type(attribute) == "string" and attribute:lower() == "katana" then
		return "Katana"
	end
	if type(attribute) == "string" and attribute:lower() == "katana" then
		return "Katana"
	end
	return "Fist"
end

local function applyWeapon(): (string, Folder)
	local weaponAttribute = character:GetAttribute("AttackNpcWeapon")
	local weapon = normalizeWeaponAttr(weaponAttribute)

	if weapon == "Katana" then
		-- Equip tool if present in ServerStorage (safe guarded)
		local success, tool = pcall(function()
			return ServerStorage.Tools:FindFirstChild("Skillsets(TOOLS)"):FindFirstChild("Katana", true):Clone()
		end)
		if success and tool then
			tool.Parent = character
			-- humanoid:EquipTool may error if tool already equipped or if no tool; protect with pcall
			pcall(function()
				hum:EquipTool(tool)
			end)
		else
			warn(("NPC [%s] could not equip Katana tool from ServerStorage"):format(character.Name))
		end
		return "Katana", KatanaFolder
	else
		return "Fist", FistFolder
	end
end

---------------------------------------------------------------------
-- LOAD / UNLOAD NORMAL (M1) TRACKS
---------------------------------------------------------------------
local function stopAndClearTracks(tracksTable: any)
	for i = #tracksTable, 1, -1 do
		local animation: AnimationTrack = tracksTable[i]
		if animation and animation.IsPlaying then
			pcall(function()
				animation:Stop()
			end)
		end
		tracksTable[i] = nil
	end
end

local function loadNormalTracks(folder: Folder?)
	if not folder then
		return
	end
	stopAndClearTracks(normalTracks)

	--print(("DEBUG: animator = %s, folder = %s"):format(tostring(animator), tostring(folder)))

	for i = 1, 5 do
		local child = folder and folder:FindFirstChild(tostring(i)) :: Animation?
		--[[ 
		print(
		 	("DEBUG: Slot %d - child = %s, isAnimation = %s"):format(
		 		i,
		 		tostring(child),
		 		tostring(child and child:IsA("Animation"))
		 	)
		 ) 
		]]

		if child and child:IsA("Animation") then
			local ok, track = pcall(function()
				return animator:LoadAnimation(child)
			end)
			if ok and track then
				normalTracks[i] = track
			else
				normalTracks[i] = nil
				warn(
					("NPC [%s] failed to load M1 animation %s (error: %s)"):format(
						character.Name,
						tostring(child and child.Name),
						tostring(track)
					)
				)
			end
		else
			normalTracks[i] = nil
			warn(("NPC [%s] missing M1 animation slot %d in folder"):format(character.Name, i))
		end
	end
end

---------------------------------------------------------------------
-- LOAD HEAVY (M2) TRACKS (weapon-aware, fallback IDs supported)
---------------------------------------------------------------------
local FALLBACK_M2_IDS = {
	Fist = {
		"rbxassetid://" .. M2Root.Fist["1"].AnimationId, -- 1st id
		"rbxassetid://" .. M2Root.Fist["2"].AnimationId, -- 2nd id
	},
	Katana = {
		"rbxassetid://" .. M2Root.Katana["1"].AnimationId, -- 1st id
		"rbxassetid://" .. M2Root.Katana["2"].AnimationId, -- 2nd id
	},
}

local function loadHeavyTracksForWeapon(weaponName: string)
	stopAndClearTracks(heavyTracks)

	-- Try to find folder: ReplicatedStorage.Animations.M2s.<weaponName>
	local folder = nil
	if M2Root then
		folder = M2Root:FindFirstChild(weaponName)
	end

	if folder and #folder:GetChildren() > 0 then
		for _, anim in ipairs(folder:GetChildren()) do
			if anim:IsA("Animation") then
				local ok, track = pcall(function()
					return animator:LoadAnimation(anim)
				end)
				if ok and track then
					table.insert(heavyTracks, track)
				end
			end
		end
	end

	-- Fallback to hardcoded IDs if none found
	if #heavyTracks == 0 then
		local ids = FALLBACK_M2_IDS[weaponName] or FALLBACK_M2_IDS.Fist
		for _, id in ipairs(ids) do
			local ok, track = pcall(function()
				local anim = Instance.new("Animation")
				anim.AnimationId = id
				return animator:LoadAnimation(anim)
			end)
			if ok and track then
				table.insert(heavyTracks, track)
			end
		end
	end

	if #heavyTracks == 0 then
		warn(("NPC [%s] has no heavy animations for weapon %s"):format(character.Name, tostring(weaponName)))
	end
end

---------------------------------------------------------------------
-- INITIALIZE ANIMATIONS (and set up attribute change listener)
---------------------------------------------------------------------
local currentWeaponName: string, currentM1Folder: Folder = applyWeapon()
loadNormalTracks(currentM1Folder)
loadHeavyTracksForWeapon(currentWeaponName)

character:GetAttributeChangedSignal("AttackNpcWeapon"):Connect(function()
	local newWeaponName, newM1Folder = applyWeapon()
	-- if weapon changed or M1 folder reference changed, reload trackers
	if newWeaponName ~= currentWeaponName or newM1Folder ~= currentM1Folder then
		currentWeaponName = newWeaponName
		currentM1Folder = newM1Folder
		loadNormalTracks(currentM1Folder)
		loadHeavyTracksForWeapon(currentWeaponName)
	end
end)

---------------------------------------------------------------------
-- NPC DASH
---------------------------------------------------------------------
local bindableFlashstepEvent: BindableEvent =
	ReplicatedStorage.Remotes_Bindables.Bindables.GeneralNPC.Movement.Flashstep
local DASH_DIRECTIONS: { string } = {
	"Forward",
	"Backwards",
	"Right",
	"Left",
}
local function dashTowardsTarget(direction: string)
	bindableFlashstepEvent:Fire(character, direction)
end

---------------------------------------------------------------------
-- NPC BLOCK
---------------------------------------------------------------------

--REMOTES
local blockingEvent: BindableEvent = ReplicatedStorage.Remotes_Bindables.Remotes.PVP.Blocking.BindBlockingEvent

--VARIABLES
local COOLDOWN: number = ReplicatedStorage.Values.NumberValues.Combat.Base.Block.CooldownTime.Value

local PREVENTION_ATTRIBUTES_Block: { string } = {
	"Ragdolled",
	"TrueStunned",
	"Carried",
	"Gripped",
	"Knocked",
}

local isBlocking: boolean = false
local canBlock: boolean = true

--Animations
local blockingAnimKatana: AnimationTrack = animator:LoadAnimation(ReplicatedStorage.Animations.General.Blocking.Katana)
local blockingAnimFist: AnimationTrack = animator:LoadAnimation(ReplicatedStorage.Animations.General.Blocking.Fist)
-------------

--FUNCTIONS
local function startBlocking()
	if character:GetAttribute("BlockOnCooldown") or isBlocking or not canBlock then
		return
	end

	isBlocking = true
	blockingEvent:Fire(character, true)

	local tool = character:FindFirstChildOfClass("Tool")
	if tool and tool:GetAttribute("Katana") then
		blockingAnimKatana:Play()
	else
		blockingAnimFist:Play()
	end
end

local function stopBlocking()
	if not isBlocking then
		return
	end

	canBlock = false
	task.delay(COOLDOWN, function()
		canBlock = true
	end)

	isBlocking = false
	blockingEvent:Fire(character, false)

	blockingAnimFist:Stop()
	blockingAnimKatana:Stop()
end

local function tryBlock(inputBegin: boolean)
	--Safe guards
	if not canBlock then
		return
	end
	if character:GetAttribute("BlockOnCooldown") then
		return
	end --not part of PREVENTION_ATTRIBUTES to avoid bugs
	if hum:GetState() == Enum.HumanoidStateType.Dead or hum.Health <= 0 then
		return
	end

	--Check input state
	if inputBegin then
		startBlocking()
	else
		stopBlocking()
	end
end

-- Listen for attribute changes (PREVENTION_ATTRIBUTES)
for _, attribute in ipairs(PREVENTION_ATTRIBUTES_Block) do
	character:GetAttributeChangedSignal(attribute):Connect(function()
		if character:GetAttribute(attribute) then
			stopBlocking()
			canBlock = false
		else
			canBlock = true
		end
	end)
end --End of for loop

---------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------
local function getNearestPlayer(): Player?
	local nearest, bestDist = nil, CHASE_RANGE
	local npcPos: Vector3 = hrp.Position

	for _, player in pairs(Players:GetPlayers()) do
		local playerCharacter = player.Character
		if playerCharacter then
			local playerHrp = playerCharacter:FindFirstChild("HumanoidRootPart") :: BasePart?
			if playerHrp then
				local distance = (playerHrp.Position - npcPos).Magnitude
				if distance <= bestDist then
					bestDist = distance
					nearest = player
				end
			end
		end
	end

	return nearest
end
local function chooseAttackType(player: Player): string
	local char = player.Character
	local blocking = char and char:GetAttribute("Blocking") == true
	if blocking then
		return (math.random(1, 20) == 1) and "Heavy" or "Normal"
	else
		return "Normal"
	end
end
local function hasPreventionAttributes(character_Var: Model): boolean
	for _, attribute in pairs(PREVENTION_ATTRIBUTES) do
		if character_Var:GetAttribute(attribute) then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
-- MAIN LOOP
---------------------------------------------------------------------
local targetUsingAttack_Conn: RBXScriptConnection
while true do
	task.wait(ATTACK_INTERVAL)

	if targetUsingAttack_Conn then
		targetUsingAttack_Conn:Disconnect()
	end --prevent memory leaks

	-- Create variables --
	local target = getNearestPlayer()
	if not target then
		continue
	end
	local targetChar = target.Character :: Model?
	if not targetChar then
		tryBlock(false) --unblock since there's no character
		continue
	else
		--Check if already attacking
		if targetChar:GetAttribute("UsingAttack") then
			if not isBlocking then
				local result = math.random(1, 3) --random chance to dash away or block
				if result == 1 then
					local direction: string = DASH_DIRECTIONS[math.random(1, 4)]
					dashTowardsTarget(direction)
				else
					local npc_BlockHits = character:GetAttribute("BlockHits") or 0 :: number
					if type(npc_BlockHits) == "number" and npc_BlockHits >= 3 then
						tryBlock(false) --about to be guardbroken so unblock
					else
						tryBlock(true) --not already blocking, so start block
					end
				end
			end
		else
			tryBlock(false) --not attacking so unblock
		end
		--Create usingAttack connection, when target uses an attack, block it if possible.
		targetUsingAttack_Conn = targetChar:GetAttributeChangedSignal("UsingAttack"):Connect(function()
			if targetChar:GetAttribute("UsingAttack") then
				if not isBlocking then
					tryBlock(true) --not already blocking, so start block
				else
					tryBlock(false) --already blocking so unblock
					local direction: string = DASH_DIRECTIONS[math.random(1, 4)]
					dashTowardsTarget(direction)
				end
			else
				tryBlock(false) --not attacking so unblock
			end
		end)
	end
	local targetHRP = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart
	if not targetHRP then
		continue
	end
	local targetHum = targetChar:FindFirstChildOfClass("Humanoid") :: Humanoid?
	if not targetHum then
		continue
	end

	--If dead then continue end
	if targetHum:GetState() == Enum.HumanoidStateType.Dead then
		continue
	end

	--Get distance and MoveTo position
	local dist = (targetHRP.Position - hrp.Position).Magnitude
	local moveToPos = targetHRP.Position

	-- CHASE --
	if dist > ATTACK_RANGE then
		tryBlock(false) --unblock since there's no character
		character:SetAttribute("IsSprinting", true)
		if dist > MIN_DASH_DISTANCE and dist < MAX_DASH_DISTANCE then
			dashTowardsTarget("Forwards")
			hum:MoveTo(moveToPos)
		else
			hum:MoveTo(moveToPos)
		end
		continue
	end
	hum:MoveTo(moveToPos)

	-- ATTACKING --
	if hum:GetState() == Enum.HumanoidStateType.Dead then
		continue
	end --ensure NPC isn't dead before attacking
	if hasPreventionAttributes(character) or isAttacking then
		continue
	end --ensure character doesn't have non-action attributes or isn't already attacking

	local attackType = chooseAttackType(target) --choose attack type ("Normal" or "Heavy")
	if attackType == "Normal" and M1cooldown then
		attackType = "Heavy"
	end --if attackType is "Normal" but M1 is on cooldown, change to heavy attack

	isAttacking = true

	if attackType == "Normal" then
		combo += 1
		if combo > 5 then
			combo = 5
		end

		M1cooldown = true

		local track = normalTracks[combo]
		if track then
			track:Play()
		else
			warn(("NPC [%s] missing normal track for combo %d"):format(character.Name, combo))
		end

		M1BindableEvent:Fire(character, combo)

		if combo < 5 then
			task.delay(0.6, function()
				isAttacking = false
				M1cooldown = false
			end)
		else
			if track then
				track.Stopped:Once(function()
					isAttacking = false
				end)
			else
				isAttacking = false
			end
			task.delay(1.5, function()
				M1cooldown = false
				combo = 0
			end)
		end

		continue
	end --Normal attack

	if attackType == "Heavy" then
		if #heavyTracks == 0 then
			warn(("NPC [%s] attempted heavy attack but has no heavyTracks"):format(character.Name))
			isAttacking = false
		else
			M2BindableEvent:Fire(character)

			local track = heavyTracks[math.random(1, #heavyTracks)] :: AnimationTrack
			track:Play()
			track.Stopped:Once(function()
				isAttacking = false
			end)
		end

		continue
	end --Heavy attack
end
