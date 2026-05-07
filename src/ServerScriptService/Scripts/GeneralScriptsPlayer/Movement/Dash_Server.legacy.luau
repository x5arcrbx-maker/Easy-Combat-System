--!strict

--//:SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

--//:REFERENCES
local FlashstepEvent: RemoteEvent = ReplicatedStorage.Remotes_Bindables.Remotes.GeneralPlayer.Flashstep :: RemoteEvent
local bindableFlashstepEvent: BindableEvent = ReplicatedStorage.Remotes_Bindables.Bindables.GeneralNPC.Movement.Flashstep :: BindableEvent

--//:VARIABLES
local COOLDOWN: number = ReplicatedStorage.Values.Movement.Dash.CooldownTime.Value
local SPEED: number = ReplicatedStorage.Values.Movement.Dash.Speed.Value
local DURATION: number = ReplicatedStorage.Values.Movement.Dash.Duration.Value

local PREVENTION_ATTRIBUTES: {string} = {
	"Gripped",
	"Carried",
	"Knocked",
	"Ragdolled",
	
	"TrueStunned",
	"Stunned",
	
	"Blocking",
	"Slowed",
	"UsingAttack",
	
	"DashOnCooldown",
}
local flashstepVFX: {Instance} = ReplicatedStorage.FX.VFX.Actions.Movement.Flashstep:GetChildren()
local SoundFX: Sound = ReplicatedStorage.FX.SFX.Combat.General.Dash

--//:FUNCTIONS

--Sets character transparency
local function setCharacterTransparency(char: Model, transparency: number)
	for _, descendant in char:GetDescendants() do
		if (descendant:IsA("BasePart") or descendant:IsA("Decal"))
			and not descendant:FindFirstAncestorOfClass("Tool")
		then
			if descendant.Name ~= "HumanoidRootPart" then
				descendant.Transparency = transparency
			end
		end
	end
end

--Plays particles
local function emitVFX(hrp: BasePart?)
	if not hrp then return end
	if not hrp.Parent then return end

	local attachment: Attachment = Instance.new("Attachment")
	attachment.Parent = hrp

	for _, v in pairs(flashstepVFX) do
		if not v:IsA("ParticleEmitter") then continue end

		local clone = v:Clone()
		clone.Parent = attachment
		clone.Enabled = false

		if clone.Name == "Dots" then
			clone:Emit(5)
		else
			clone:Emit(1)
		end

	end
	Debris:AddItem(attachment, 1)
end

local function playSFX(hrp: BasePart?)
	if not hrp or not hrp.Parent then 
		return 
	end
	
	local cloneSFX = SoundFX:Clone()
	cloneSFX.Parent = hrp
	cloneSFX:Play()
	Debris:AddItem(cloneSFX, cloneSFX.TimeLength)
end

--Immediately cancels dash
local function cancelDash(char: Model?, bodyVelocity: BodyVelocity?, RunConnection: RBXScriptConnection?)
	if not char or not char.Parent then return end
	if bodyVelocity and bodyVelocity.Parent then
		bodyVelocity:Destroy()
	end
	if RunConnection then
		RunConnection:Disconnect()
	end
	setCharacterTransparency(char, 0)
end

--Checks if the character is using an attack or not
local function cancelDashIfAttribute(char: Model?): boolean
	if not char or not char.Parent then 
		return false
	end
	
	for _, attribute in ipairs(PREVENTION_ATTRIBUTES) do
		if attribute == "DashOnCooldown" then continue end
		
		if char:GetAttribute(attribute) then 
			return false
		end
	end
	
	return true
end


--Begins the dash logic
local function beginDash(char: Model, hrp: BasePart, hum: Humanoid, direction_NPC: string?)
	--print("beginDash func started...") DEBUG
	
	if hrp:FindFirstChild("DashVelocity") then return end
	
	char:SetAttribute("DashOnCooldown", true)
	task.delay(COOLDOWN, function()
		char:SetAttribute("DashOnCooldown", false)
	end) --^ Attribute setting
	
	setCharacterTransparency(char, 1) -- Make character invisible

	--Creating variables
	local bodyVelocity: BodyVelocity
	local RunConnection: RBXScriptConnection
	
	-- Create velocity and change properties
	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Parent = hrp
	bodyVelocity.Name = "DashVelocity"
	bodyVelocity.MaxForce = Vector3.new(100000, 0, 100000)
	
	--Main logic--
	playSFX(hrp) --Handle SFX
	if CollectionService:HasTag(char, "AttackCharacter") then
		RunConnection = RunService.Heartbeat:Connect(function() --Heartbeat connection for dynamic movement and emitting particles
			--Exit early if prevention attributes are true
			if not cancelDashIfAttribute(char) then
				cancelDash(char, bodyVelocity, RunConnection)
				return
			end

			emitVFX(hrp) --Handle VFX

			--Handle velocity
			local direction: Vector3
			if direction_NPC then
				if direction_NPC == "Forwards" or direction_NPC == "Forward" then 
					direction = hrp.CFrame.LookVector
					bodyVelocity.Velocity = direction * SPEED
				elseif direction_NPC == "Backwards" or direction_NPC == "Backward" then
					direction = hrp.CFrame.LookVector * -1
					bodyVelocity.Velocity = direction * SPEED
				end
				if direction_NPC == "Right" then
					direction = hrp.CFrame.RightVector
					bodyVelocity.Velocity = direction * SPEED
				elseif direction_NPC == "Left" then
					direction = hrp.CFrame.RightVector * -1
					bodyVelocity.Velocity = direction * SPEED
				end
			else --fallback incase direction_NPC is nil
				direction = hrp.CFrame.LookVector
				bodyVelocity.Velocity = direction * SPEED
			end
		end)
	else
		RunConnection = RunService.Heartbeat:Connect(function() --Heartbeat connection for dynamic movement and emitting particles
			--Exit early if prevention attributes are true
			if not cancelDashIfAttribute(char) then
				cancelDash(char, bodyVelocity, RunConnection)
				return
			end

			emitVFX(hrp) --Handle VFX

			--Handle velocity
			local direction: Vector3 = hum.MoveDirection
			if direction.Magnitude <= 0 then
				bodyVelocity.Velocity = Vector3.new(0, 0, 0)
				return
			end
			bodyVelocity.Velocity = direction.Unit * SPEED
		end)
	end
	
	-- Remove velocity and restore transparency after dash
	task.delay(DURATION, function()
		cancelDash(char, bodyVelocity, RunConnection)
	end)
end

-- Player Dashing
FlashstepEvent.OnServerEvent:Connect(function(player)

	local char = player.Character
	if not char then return end
	for _, attribute in pairs(PREVENTION_ATTRIBUTES) do
		if char:GetAttribute(attribute) then return end
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid") :: Humanoid?
	if not hrp then return end
	if not hum then return end

	--Function to begin dash
	beginDash(char, hrp, hum)
end)

-- NPC dashing
bindableFlashstepEvent.Event:Connect(function(npc: Model?, direction: string)
	
	if not npc then return end
	for _, attribute in pairs(PREVENTION_ATTRIBUTES) do
		if npc:GetAttribute(attribute) then return end
	end
	local hrp = npc:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = npc:FindFirstChildOfClass("Humanoid") :: Humanoid?
	if not hrp then return end
	if not hum then return end

	--Function to begin dash
	beginDash(npc, hrp, hum, direction)
end)



