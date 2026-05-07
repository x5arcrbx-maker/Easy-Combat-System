--//:SERVICES://--
local Players 			= game:GetService("Players")
local StarterPlayer 	= game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//:VARIABLES://--
local defaultWalkSpeed = StarterPlayer.CharacterWalkSpeed --Default Speed
local defaultJumpPower = StarterPlayer.CharacterJumpPower --Default JumpPower
local sprintWalkSpeed  = ReplicatedStorage.Values.Attributes.Sprint.WalkSpeed.Value --Sprint Speed
local stunnedWalkSpeed = ReplicatedStorage.Values.Attributes.Stunned.WalkSpeed.Value --Stunned Speed
local stunnedJumpPower = ReplicatedStorage.Values.Attributes.Stunned.JumpPower.Value --Stunned JumpPower
local slowedWalkSpeed  = ReplicatedStorage.Values.Attributes.Slowed.WalkSpeed.Value --Slowed Speed

--local charactersJumping = {}

--//:REMOTE EVENTS://--
local movementChangeEvent = ReplicatedStorage.Remotes_Bindables.Remotes.GeneralPlayer:WaitForChild("RequestMovementChange")

--//:FUNCTIONS://--
local function applyMovement(character)
	local hum = character:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	
	--No movement whatsoever
	local gripping = character:GetAttribute("Gripping")
	local gripped = character:GetAttribute("Gripped")
	local carried = character:GetAttribute("Carried")
	local knocked = character:GetAttribute("Knocked")
	local ragdolled = character:GetAttribute("Ragdolled")
	------------------------
	--Stunned movement
	local trueStunned = character:GetAttribute("TrueStunned")
	local stunned = character:GetAttribute("Stunned")
	------------------------
	--Slowed movment
	local blocking = character:GetAttribute("Blocking")
	local slowed = character:GetAttribute("Slowed")
	local usingAttack = character:GetAttribute("UsingAttack")
	------------------------
	--No Climb or sprint
	local carrying = character:GetAttribute("Carrying")
	------------------------
	--Sprint
	local sprinting = character:GetAttribute("IsSprinting")
	------------------------
	
	--if statements
	
	if 
		gripping 
		or gripped 
		or carried 
		or knocked 
		or ragdolled 
	then
		character:SetAttribute("IsSprinting", false)
		character:SetAttribute("Blocking", false)
		character:SetAttribute("BlockHits", 0)
		character:SetAttribute("BlockTime", 0)
		character:SetAttribute("UsingAttack", false)
		character:SetAttribute("IsAttacking", false)
		character:SetAttribute("CanClimb", false)
		hum.WalkSpeed = 0
		hum.JumpPower = stunnedJumpPower
		return
	end
	
	if trueStunned then
		character:SetAttribute("IsSprinting", false)
		character:SetAttribute("Blocking", false)
		character:SetAttribute("BlockHits", 0)
		character:SetAttribute("BlockTime", 0)
		character:SetAttribute("UsingAttack", false)
		character:SetAttribute("IsAttacking", false)
		character:SetAttribute("CanClimb", false)
		hum.WalkSpeed = stunnedWalkSpeed
		hum.JumpPower = stunnedJumpPower
		return
	end

	if stunned or blocking then
		character:SetAttribute("IsSprinting", false)
		character:SetAttribute("CanClimb", false)
		hum.WalkSpeed = stunnedWalkSpeed
		hum.JumpPower = stunnedJumpPower
		return
	end

	if slowed then
		character:SetAttribute("IsSprinting", false)
		hum.WalkSpeed = slowedWalkSpeed
		hum.JumpPower = stunnedJumpPower
		return
	end

	if usingAttack then
		character:SetAttribute("IsSprinting", false)
		hum.WalkSpeed = slowedWalkSpeed
		hum.JumpPower = stunnedJumpPower
		return
	end
	
	if carrying then
		character:SetAttribute("CanClimb", false)
		character:SetAttribute("IsSprinting", false)
		hum.WalkSpeed = defaultWalkSpeed
		hum.JumpPower = defaultJumpPower --charactersJumping[character].jumpPower
		return
	end
	
	if sprinting then
		character:SetAttribute("CanClimb", true)
		hum.WalkSpeed = sprintWalkSpeed
		hum.JumpPower = defaultJumpPower --charactersJumping[character].jumpPower
		return
	end

	character:SetAttribute("CanClimb", true)
	hum.WalkSpeed = defaultWalkSpeed
	hum.JumpPower = defaultJumpPower --charactersJumping[character].jumpPower
end

local function setupCharacter(character: Model)
	--charactersJumping[character] = {
	--	lastJump = 0,
	--	jumpPower = defaultJumpPower,
	--} --Table to decrease jump power when spam jumping
	
	local attributes = {
		"Gripping", 
		"Gripped",
		"Carried",
		"Knocked",
		"Ragdolled",
		
		"TrueStunned",
		"Stunned",
		
		"Blocking",
		"Slowed",
		"UsingAttack",
		
		"Carrying",
		
		"IsSprinting",
	} --Attributes to listen to
	
	for _, attr in ipairs(attributes) do
		character:GetAttributeChangedSignal(attr):Connect(function()
			applyMovement(character)
		end)
	end
	applyMovement(character)
	
	
	--Subtracts now from lastJump.
	--If the time since last jump is less than 1 second, then it will subtract 5 from the jump power
	--If the time since last jump is greater than 1 second, then it will set the jump power to defaultJumpPower
	--[[
	local function getTime_and_setJump(now: number, humanoid: Humanoid)
		local data = charactersJumping[character]
		local timeSinceLastJump: number = now - data.lastJump
		
		if timeSinceLastJump < 0.75 then
			humanoid.JumpPower = math.max(humanoid.JumpPower - 2.5, 15)
			data.jumpPower = humanoid.JumpPower
			data.lastJump = now
		else
			humanoid.JumpPower = defaultJumpPower
			data.jumpPower = humanoid.JumpPower
			data.lastJump = now
		end
	end
	
	--Find Humanoid and connect Jumping event
	task.spawn(function()
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid?

		humanoid.Jumping:Connect(function()
			local now: number = tick()
			getTime_and_setJump(now, humanoid)
		end)
	end)
	]]
end

--//:EVENTS://--

-- Players
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(setupCharacter)
	--player.CharacterRemoving:Connect(function(character)
	--	if charactersJumping[character] then
	--		charactersJumping[character] = nil
	--	end
	--end)
end)

-- NPCs — works for ANY humanoid model that isn't a player
workspace.DescendantAdded:Connect(function(obj)
	if 
		obj:IsA("Model") 
		and obj:FindFirstChildOfClass("Humanoid") 
		and not Players:GetPlayerFromCharacter(obj) 
	then
		setupCharacter(obj)
	end
end)

-- Remote Event
movementChangeEvent.OnServerEvent:Connect(function(
	player, 
	changeType: string, 
	value: boolean
)
	local character = player.Character
	if not character then return end

	if changeType == "Sprint" then
		character:SetAttribute("IsSprinting", value)
		applyMovement(character)
	end
end)


---- For loops ----

-- Existing player characteracters
for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		setupCharacter(player.Character)
	end
end

-- Existing NPCs
for _, obj in ipairs(workspace:GetDescendants()) do
	if 
		obj:IsA("Model") 
		and obj:FindFirstChildOfClass("Humanoid") 
		and not Players:GetPlayerFromCharacter(obj) 
	then
		setupCharacter(obj)
	end
end


