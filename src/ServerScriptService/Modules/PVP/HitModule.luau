local hitModule = {}

--//:SERVICES
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local TweenService		  = game:GetService("TweenService")
local ServerScriptService = game:GetService("ServerScriptService")
local Debris 			  = game:GetService("Debris")
local _RunService 		  = game:GetService("RunService")
local Players 			  = game:GetService("Players")

--//:MODULES
local Modules = ServerScriptService.Modules
local ClashModule = require(Modules.PVP.ClashModule)
local DataManager = require(Modules.Services.ProfileStore.Data.DataManager)

--//:VARIABLES
local PREVENTION_ATTRIBUTES_Ragdoll: {string}  = {
	"Gripped",
	"Carried",
	"Knocked",
}
local PREVENTION_ATTRIBUTES_Opponent: {string} = {
	"Gripped",
	"Carried",
	"Knocked",
	"Ragdolled",
}
local PREVENTION_ATTRIBUTES_Attacker: {string} = {
	"Gripped",
	"Carried",
	"Knocked",
	"Ragdolled",

	"TrueStunned",
	"Stunned",

	"Blocking",
}
local stunThreads = {}
-- Cleanup on player leave
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		stunThreads[character] = {}

		local conn
		conn = character.AncestryChanged:Connect(function(_, parent)
			if not parent then
				stunThreads[character] = nil
				conn:Disconnect()
			end
		end)
	end)
end)


--//:FUNCTIONS
--	Logic functions	--

local function attributeCheck(
	attackerCharacter: Model,
	opponentCharacter: Model
): boolean
	--| SAFEGUARDS |--
	for _, attribute in ipairs(PREVENTION_ATTRIBUTES_Opponent) do
		if opponentCharacter:GetAttribute(attribute) then 
			return false
		end
	end --Opponent guards

	for _, attribute in ipairs(PREVENTION_ATTRIBUTES_Attacker) do
		if attackerCharacter:GetAttribute(attribute) then
			return false
		end
	end --Attacker guards
	
	local attackerHum = attackerCharacter:FindFirstChildOfClass("Humanoid") :: Humanoid?
	local opponentHum = opponentCharacter:FindFirstChildOfClass("Humanoid") :: Humanoid?
	if 
		not attackerHum 
		or not opponentHum 
	then return false end
	if 
		(opponentHum.Health <= 0 or opponentHum:GetState() == Enum.HumanoidStateType.Dead) 
		or (attackerHum.Health <= 0 or attackerHum:GetState() == Enum.HumanoidStateType.Dead) 
	then return false end
	
	return true
end

--	Misc functions	--

-- Function to trigger all effects with their attributes.
local function triggerEffects(parentObject: Instance?)
	if not parentObject then
		warn("VFX trigger target not found!")
		return
	end

	-- Find all effect instances within the parent object.
	for _, instance in ipairs(parentObject:GetDescendants()) do
		if instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Sound") then

			task.spawn(function()
				if not instance.Parent then return end -- Safety check

				local delay = instance:GetAttribute("EmitDelay") or 0
				local duration = instance:GetAttribute("EmitDuration")

				if delay > 0 then
					task.wait(delay)
				end

				if not instance.Parent then return end -- Check again after delay

				if instance:IsA("Sound") then
					instance:Play()

				elseif instance:IsA("ParticleEmitter") then
					local count = instance:GetAttribute("EmitCount")
					if duration and duration > 0 then
						instance.Enabled = true
						task.wait(duration)
						if instance.Parent then instance.Enabled = false end
					elseif count and count > 0 then
						instance:Emit(count)
					else
						-- If no duration or count, emit 1 particle as a default one-shot.
						instance:Emit(1)
					end

				elseif instance:IsA("Beam") then
					local beamClone = instance:Clone()
					beamClone.Parent = instance.Parent
					beamClone.Enabled = true

					task.wait(if duration and duration > 0 then duration else 0.03)

					if beamClone and beamClone.Parent then beamClone:Destroy() end
				end
			end)
		end
	end
end


--//:MAIN
function hitModule.Hit(
	attackerHum: Humanoid,
	opponentHum: Humanoid,
	hitType: string?,
	DMG: number?,
	STUN_TIME: number?,
	PBable: boolean?,
	KB: boolean?,
	KBforce: number?,
	KB_TIME: number?,
	KB_Direction: string?,
	Direction_Divider: number?,
	Ragdoll: boolean?,
	Ragdoll_TIME: number?,
	Effect: boolean?,
	StatusEffect: string?
)
	if opponentHum:FindFirstChildOfClass("ForceField") then return end --Don't hit characters with a forcefield active
	
	local attackerChar = attackerHum:FindFirstAncestorOfClass("Model") :: Model? --opponent's Character
	local opponentChar = opponentHum:FindFirstAncestorOfClass("Model") :: Model? --opponent's Character
	if not attackerChar or not opponentChar then return end
	
	local ok = attributeCheck(attackerChar, opponentChar)
	if not ok then return end
	
	local attackerHRP = attackerChar:FindFirstChild("HumanoidRootPart") :: BasePart? --attacker's RootPart
	local opponentHRP = opponentChar:FindFirstChild("HumanoidRootPart") :: BasePart? --opponent's RootPart
	if not attackerHRP or not opponentHRP then return end
	
	-------------------

	local hitAnims = {
		[1] = ReplicatedStorage.Animations.General.HitAnims.Hit1,
		[2] = ReplicatedStorage.Animations.General.HitAnims.Hit2,
	}

	--Check HitType logic (local)
	--Mainly used for VFX, does nothing for actual logic besides cosmetics.
	local function checkhitType()
		--HitType SFX and VFX for M1 and M2
		if hitType == "FistM1" then
			local function playSFX()
				local SFX: Sound? = ReplicatedStorage.FX.SFX.Combat.Fists.M1Landed:Clone()
				if SFX then
					local pitch: number = math.random(75, 125) / 100
					local pitchShiftFx: PitchShiftSoundEffect? = SFX:FindFirstChildOfClass("PitchShiftSoundEffect")
					if pitchShiftFx then
						pitchShiftFx.Octave = pitch
						SFX.Parent = opponentHRP
						SFX:Play()
						Debris:AddItem(SFX, SFX.TimeLength)
					end
				end
			end
			playSFX()

			local function playVFX()
				local VFX: Folder? = ReplicatedStorage.FX.VFX.Actions.Combat.Hit.BluntHit
				if VFX then
					local attachment: Attachment = Instance.new("Attachment")
					attachment.Parent = opponentHRP
					for _, v in pairs(VFX:GetChildren()) do --Loops through VFX in folder
						if v:IsA("ParticleEmitter") then
							local v_Clone = v:Clone()
							v_Clone.Parent = attachment
							v_Clone:Emit(1)
						end
					end
					Debris:AddItem(attachment, 0.5)
				end
			end
			playVFX()
		end

		if hitType == "FistM2" then
			local function playSFX()
				local SFX: Sound? = ReplicatedStorage.FX.SFX.Combat.Fists.M2Landed:Clone()
				if SFX then
					SFX.Parent = opponentHRP
					SFX:Play()
					Debris:AddItem(SFX, SFX.TimeLength)
				end
			end
			playSFX()

			local function playVFX()
				local VFX: Folder? = ReplicatedStorage.FX.VFX.Actions.Combat.Hit.BluntHit
				if VFX then
					local attachment: Attachment = Instance.new("Attachment")
					attachment.Parent = opponentHRP
					for _, v in pairs(VFX:GetChildren()) do --Loops through VFX in folder
						if v:IsA("ParticleEmitter") then
							local v_Clone = v:Clone()
							v_Clone.Parent = attachment
							v_Clone:Emit(1)
						end
					end
					Debris:AddItem(attachment, 0.5)
				end
			end
			playVFX()
		end

		if hitType == "KatanaM1" then
			local function playSFX()
				local SFX: Sound? = ReplicatedStorage.FX.SFX.Combat.Katana.M1Landed:Clone()
				if SFX then
					local pitch: number = math.random(75, 125) / 100
					local pitchShiftFx: PitchShiftSoundEffect? = SFX:FindFirstChildOfClass("PitchShiftSoundEffect")
					if pitchShiftFx then
						pitchShiftFx.Octave = pitch
						SFX.Parent = opponentHRP
						SFX:Play()
						Debris:AddItem(SFX, SFX.TimeLength)
					end
				end
			end
			playSFX()

			local function playVFX()
				local VFX: Folder? = ReplicatedStorage.FX.VFX.Actions.Combat.Hit.SharpHit
				if VFX then
					local attachment: Attachment = Instance.new("Attachment")
					attachment.Parent = opponentHRP
					for _, v in pairs(VFX:GetChildren()) do --Loops through VFX in folder
						if v:IsA("ParticleEmitter") then
							local v_Clone = v:Clone()
							v_Clone.Parent = attachment
							v_Clone:Emit(1)
						end
					end
					Debris:AddItem(attachment, 0.5)
				end
			end
			playVFX()
		end

		if hitType == "KatanaM2" then
			local function playSFX()
				local SFX: Sound? = ReplicatedStorage.FX.SFX.Combat.Katana.M2Landed:Clone()
				if SFX then
					SFX.Parent = opponentHRP
					SFX:Play()
					Debris:AddItem(SFX, SFX.TimeLength)
				end
			end
			playSFX()

			local function playVFX()
				local VFX: Folder? = ReplicatedStorage.FX.VFX.Actions.Combat.Hit.SharpHit
				if VFX then
					local attachment: Attachment = Instance.new("Attachment")
					attachment.Parent = opponentHRP
					for _, v in pairs(VFX:GetChildren()) do --Loops through VFX in folder
						if v:IsA("ParticleEmitter") then
							local v_Clone = v:Clone()
							v_Clone.Parent = attachment
							v_Clone:Emit(1)
						end
					end
					Debris:AddItem(attachment, 0.5)
				end
			end
			playVFX()
		end

		--HitType SFX and VFX for 'Blunt' and 'Sharp'
		if hitType == "Blunt" then
			local function playSFX()
				local SFX: Sound? = ReplicatedStorage.FX.SFX.Combat.Fists.BluntLanded:Clone()
				if SFX then
					local pitch: number = math.random(85, 125) / 100
					local pitchShiftFx: PitchShiftSoundEffect? = SFX:FindFirstChildOfClass("PitchShiftSoundEffect")
					if pitchShiftFx then
						pitchShiftFx.Octave = pitch
						SFX.Parent = opponentHRP
						SFX:Play()
						Debris:AddItem(SFX, SFX.TimeLength)
					end
				end
			end
			playSFX()

			local function playVFX()
				local VFX: Folder? = ReplicatedStorage.FX.VFX.Actions.Combat.Hit.BluntHit
				if VFX then
					local attachment: Attachment = Instance.new("Attachment")
					attachment.Parent = opponentHRP
					for _, v in pairs(VFX:GetChildren()) do --Loops through VFX in folder
						if v:IsA("ParticleEmitter") then
							local v_Clone = v:Clone()
							v_Clone.Parent = attachment
							v_Clone:Emit(1)
						end
					end
					Debris:AddItem(attachment, 0.5)
				end
			end
			playVFX()
		end

		if hitType == "Sharp" then
			local function playSFX()
				local SFX: Sound? = ReplicatedStorage.FX.SFX.Combat.Katana.SharpLanded:Clone()
				if SFX then
					local pitch: number = math.random(85, 125) / 100
					local pitchShiftFx: PitchShiftSoundEffect? = SFX:FindFirstChildOfClass("PitchShiftSoundEffect")
					if pitchShiftFx then
						pitchShiftFx.Octave = pitch
						SFX.Parent = opponentHRP
						SFX:Play()
						Debris:AddItem(SFX, SFX.TimeLength)
					end
				end
			end
			playSFX()

			local function playVFX()
				local VFX: Folder? = ReplicatedStorage.FX.VFX.Actions.Combat.Hit.SharpHit
				if VFX then
					local attachment: Attachment = Instance.new("Attachment")
					attachment.Parent = opponentHRP
					for _, v in pairs(VFX:GetChildren()) do --Loops through VFX in folder
						if v:IsA("ParticleEmitter") then
							local v_Clone = v:Clone()
							v_Clone.Parent = attachment
							v_Clone:Emit(1)
						end
					end
					Debris:AddItem(attachment, 0.5)
				end
			end
			playVFX()
		end
	end

	--Stun logic (local)
	--Sets stun onto a character for a given amount of time, and can add either normal Stun (able to do actions with limitations) and TrueStun (no actions allowed).
	local function setStun(
		character: Model,
		TIME: number,
		TrueStun: boolean?
	)
		if not character then
			stunThreads[character] = nil
		end
		if not stunThreads[character] then
			stunThreads[character] = {}
		end
		
		if TrueStun then
			if stunThreads[character].TrueStunned then
				task.cancel(stunThreads[character].TrueStunned)
			end
			
			stunThreads[character].TrueStunned = task.spawn(function()
				character:SetAttribute("TrueStunned", true)
				task.wait(TIME)
				
				--Ensure this is still the active thread
				if stunThreads[character].TrueStunned ~= coroutine.running() then
					return
				end
				
				character:SetAttribute("TrueStunned", false)
				stunThreads[character].TrueStunned = nil
				
				--print("Un-TrueStunned: " .. character.Name) DEBUG
			end)
		else --Normal stun
			if stunThreads[character].Stunned then
				task.cancel(stunThreads[character].Stunned)
			end
			
			stunThreads[character].Stunned = task.spawn(function()
				character:SetAttribute("Stunned", true)
				task.wait(TIME)
				
				--Ensure this is still the active thread
				if stunThreads[character].Stunned ~= coroutine.running() then
					return
				end
				
				character:SetAttribute("Stunned", false)
				stunThreads[character].Stunned = nil
				
				--print("Un-Stunned: " .. character.Name) DEBUG
			end)
		end
	end

	--Knockback function (local)
	--<giverHRP> and <recievingHRP> are necessary to determine the direction of force since it uses CFrames.
	--<force> is a number (how strong the force is), 
	--<TIME> determines how long the force lasts, 
	--<direction> determines where the force will be (see the function for more details), 
	--and <divider> is the number the velocity is divided by (default is 2). 
	--^ However, do note that the divider only applies to certain directions, (see the function for more details).
	local function knockback(
		giverHRP: BasePart,
		recievingHRP: BasePart,
		force: number,
		TIME: number,
		direction: string,
		divider: number?
	)
		if not divider then divider = 2 end
		
		local existingVelocity = recievingHRP:FindFirstChildOfClass("BodyVelocity")
		if existingVelocity then existingVelocity:Destroy() end
		
		
		--Handle directions and velocities
		if direction == "Look" or direction == "LookVector" then
			local Knockback: BodyVelocity = Instance.new("BodyVelocity")
			Knockback.Parent   = recievingHRP
			Knockback.MaxForce = Vector3.new(100000, 100000, 100000)
			Knockback.Velocity = giverHRP.CFrame.LookVector * force
			Debris:AddItem(Knockback, TIME)
		end
	
		if direction == "Away" or direction == "Distance" then
			local Knockback: BodyVelocity = Instance.new("BodyVelocity")
			Knockback.Parent   = recievingHRP
			Knockback.MaxForce = Vector3.new(100000, 100000, 100000)
			Knockback.Velocity = (recievingHRP.CFrame.Position - giverHRP.CFrame.Position).Unit * force
			Debris:AddItem(Knockback, TIME)
		end
		
		if direction == "AwayUp" or direction == "DistanceUp" then
			local Knockback: BodyVelocity = Instance.new("BodyVelocity")
			Knockback.Parent   = recievingHRP
			Knockback.MaxForce = Vector3.new(100000, 100000, 100000)
			Knockback.Velocity = ((recievingHRP.CFrame.Position - giverHRP.CFrame.Position).Unit * force) + (giverHRP.CFrame.UpVector * KBforce)
			Debris:AddItem(Knockback, TIME)
		end

		if direction == "Up" or direction == "Upwards" then
			local Knockback: BodyVelocity = Instance.new("BodyVelocity")
			Knockback.Parent   = recievingHRP
			Knockback.MaxForce = Vector3.new(100000, 100000, 100000)
			Knockback.Velocity = giverHRP.CFrame.UpVector * KBforce
			Debris:AddItem(Knockback, TIME)
		end
		
		if direction == "UpLook" then
			local Knockback: BodyVelocity = Instance.new("BodyVelocity")
			Knockback.Parent   = recievingHRP
			Knockback.MaxForce = Vector3.new(100000, 100000, 100000)
			Knockback.Velocity = (giverHRP.CFrame.UpVector * KBforce) + (giverHRP.CFrame.LookVector * (KBforce / divider))
			Debris:AddItem(Knockback, TIME)
		end
		
		if direction == "LookUp" then
			local Knockback: BodyVelocity = Instance.new("BodyVelocity")
			Knockback.Parent   = recievingHRP
			Knockback.MaxForce = Vector3.new(100000, 100000, 100000)
			Knockback.Velocity = (giverHRP.CFrame.LookVector * KBforce) + (giverHRP.CFrame.UpVector * (KBforce / divider))
			Debris:AddItem(Knockback, TIME)
		end
	end

	--Ragdoll function (local)
	--Used to ragdoll a character for a set amount of time.
	local function ragdoll(
		character: Model,
		humanoid: Humanoid,
		TIME: number
	)
		local trigger: BoolValue? = character:FindFirstChild("RagdollTrigger")
		if trigger and trigger:IsA("BoolValue") then
			
			trigger.Value = true --Enable ragdoll
			character:SetAttribute("Ragdolled", true)
			task.delay(TIME, function()
				for _, attribute in pairs(PREVENTION_ATTRIBUTES_Ragdoll) do
					if character:GetAttribute(attribute) then return end
				end
				if humanoid:GetState() == Enum.HumanoidStateType.Dead then return end
				
				trigger.Value = false --Disable ragdoll
				character:SetAttribute("Ragdolled", false)
			end)
			
		end
	end

	--Status Effect function (local)
	--which adds the tag (status) to the character.
	local function addStatusEffect(
		character: Model,
		Status: string
	)
		character:AddTag(Status)
	end

	--(local) hit function, handles all aspects of hitting a player with an attack.
	--Utilizes all local functions above it.
	local function hit()
		if opponentChar:GetAttribute("IsAttacking") then
			ClashModule.Clash(attackerHRP, opponentHRP)
			return --Clashes if opponent is attacking, don't hit
		else
			--[[
			print("Blocking for opponent = " .. tostring(opponentChar:GetAttribute("Blocking")))
			print("BlockTime for opponent: " .. tostring(opponentChar:GetAttribute("BlockTime")))
			]]
			
			
			local animator = opponentHum:FindFirstChildOfClass("Animator") :: Animator
			if animator then
				local hitAnim = animator:LoadAnimation(hitAnims[math.random(1, #hitAnims)])
				hitAnim:Play() --Plays the hit animation
			end

			--Checking hitType
			checkhitType() --Checks for hitType and plays the appropriate sound and VFX

			--Stun
			if STUN_TIME then
				setStun(opponentChar, STUN_TIME, false) --Stun in seconds
			end

			--Damage
			if DMG then
				local dmgMultiplier = attackerChar:FindFirstChild("DamageMultiplier") :: NumberValue?
				local defenseMultiplier = opponentChar:FindFirstChild("DefenseMultiplier") :: NumberValue?
				
				if dmgMultiplier and defenseMultiplier then
					DMG = DMG * (dmgMultiplier.Value / defenseMultiplier.Value)
					
				elseif dmgMultiplier and not defenseMultiplier then
					DMG = DMG * dmgMultiplier.Value
					--warn("defenseMultiplier not found for " .. opponentChar.Name .. ", Readjusting hit formula")

				elseif not dmgMultiplier and defenseMultiplier then
					DMG = DMG * defenseMultiplier.Value
					--warn("dmgMultiplier not found for " .. attackerChar.Name .. ", Readjusting hit formula")
				end

				if opponentHum.Health - DMG <= 0 then
					attackerChar:SetAttribute("LastKilled", opponentChar.Name)
					local attachment = ReplicatedStorage.FX.VFX.General:FindFirstChild("Blood_Attachment") :: Attachment?
					if attachment then
						local clone_attachment = attachment:Clone()
						clone_attachment.Parent = opponentHRP
						triggerEffects(clone_attachment)
						Debris:AddItem(clone_attachment, 5)
					end

					local player = Players:GetPlayerFromCharacter(attackerChar)
					if player then
						
						local yen_FromOpponent = opponentChar:FindFirstChild("Yen") :: NumberValue
						if yen_FromOpponent then
							DataManager.UpdateYen(player, yen_FromOpponent.Value) --if Yen is from an NPC then give the player the Yen
						else
							local opponentPlayer = Players:GetPlayerFromCharacter(opponentChar)
							if opponentPlayer then --ensure opponentPlayer exists
								local leaderstats = opponentPlayer:FindFirstChild("leaderstats") :: Folder
								if leaderstats then
									yen_FromOpponent = leaderstats:FindFirstChild("Yen") :: NumberValue
									if yen_FromOpponent then --ensure yen exists in opponent's leaderstats
										local yenAmount = math.clamp(yen_FromOpponent.Value / 5,  0,math.huge)
										DataManager.UpdateYen(player, yenAmount)  --Give attacker yen
										DataManager.UpdateYen(opponentPlayer, -yenAmount) --subtract opponent yen
									end
								end
							end
						end
						
					end


					--Increase knockback drastically
					if KB then
						local existingVelocity = opponentHRP:FindFirstChildOfClass("BodyVelocity")
						if existingVelocity then existingVelocity:Destroy() end
						
						KBforce = KBforce * 2
						--if KB_Direction == "Look" or KB_Direction == "LookVector" or KB_Direction == "LookUp" then
						--	KBforce = KBforce * 1.5
						--	KB_Direction = "LookUp"
						--	Direction_Divider = 5
						--end

						--if KB_Direction == "Away" or KB_Direction == "Distance" then
						--	KB_Direction = "AwayUp"
						--	KBforce = KBforce * 3
						--end

						--if KB_Direction == "UpLook" then
						--	KBforce = KBforce * 2
						--end

						--if KB_Direction == "Up" or KB_Direction == "Upwards" then
						--	KBforce = KBforce * 2
						--end
					end
					
					if PBable and (hitType == "Sharp" or hitType == "KatanaM1" or hitType == "KatanaM2") then
						local opponentTorso = opponentChar:FindFirstChild("Torso") :: BasePart?
						if opponentTorso then
							local neckAttachment = opponentTorso:FindFirstChild("NeckAttachment") :: Attachment?
							if neckAttachment then neckAttachment:Destroy() end
						end
						
						setStun(opponentChar, 2.5, true) --TrueStun the opponent so they cannot move while dead
						opponentHum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
						task.delay(2, function()
							opponentHum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
							opponentHum:ChangeState(Enum.HumanoidStateType.Dead)
						end)
					end
				end
				opponentHum:TakeDamage(DMG)
				
				--local function highlightVFX()
				--	local highlight: Highlight = Instance.new("Highlight")
				--	highlight.Name = "DamageHighlight"
				--	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
				--	highlight.FillTransparency = 0.6
				--	highlight.FillColor = Color3.fromRGB(255, 0, 0)
				--	highlight.OutlineTransparency = 1
				--	highlight.Parent = opponentChar
					
				--	TweenService:Create( --Tween FillTransparency
				--		highlight,
				--		TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In, 0, false, 0),
				--		{FillTransparency = 1}
				--	):Play()
					
				--	Debris:AddItem(highlight, 0.25)
				--end
				--highlightVFX()
			end

			--Knockback
			if KB and KBforce and KB_TIME then
				knockback(attackerHRP, opponentHRP, KBforce, KB_TIME, KB_Direction, Direction_Divider)
			end --If KnockBack is true, knockback is applied

			--Ragdoll
			if Ragdoll and Ragdoll_TIME then
				ragdoll(opponentChar, opponentHum, Ragdoll_TIME)
			end --If Ragdoll is true, ragdoll is applied

			if Effect and StatusEffect then
				addStatusEffect(opponentChar, StatusEffect)
			end --If Effect is true, effect is applied
		end
	end

	--Blocking References
	local hitModule_blockingEvent = ReplicatedStorage.Remotes_Bindables.Remotes.PVP.Blocking.hitModule_BlockingEvent
	---------------------
	--Blocking Variables
	local blocking: boolean? = opponentChar:GetAttribute("Blocking")
	local blockHits: number = opponentChar:GetAttribute("BlockHits")
	local PBstun_Time: number = ReplicatedStorage.Values.Combat.Base.Block.PerfectBlockStunTime.Value
	local GBstun_Time: number = ReplicatedStorage.Values.Combat.Base.Block.GuardbreakStunTime.Value
	local GUARDBREAK_Amount: number = ReplicatedStorage.Values.Combat.Base.Block.GuardbreakAmount.Value
	local PB_Window: number = 0.25 --PB window in seconds

	if blocking then
		if PBable then
			local blockTime: number? = opponentChar:GetAttribute("BlockTime")
			if blockTime and blockTime <= PB_Window then --If opponent is blocking for <= PB_Window, attacker is PB'd
				print("Perfect Blocked!")
				
				--PB stun
				setStun(attackerChar, PBstun_Time, true) --PB stuntime in seconds

				--Knockback for PB
				knockback(opponentHRP, attackerHRP, 60, 0.1, "Away")

				--Reset opponent's blockHits
				opponentChar:SetAttribute("BlockHits", 0)

				--VFX--
				local function playParticles()
					local VFX_1: ParticleEmitter? = ReplicatedStorage.FX.VFX.Actions.Combat.PB.PB1:Clone()
					local VFX_2: ParticleEmitter? = ReplicatedStorage.FX.VFX.Actions.Combat.PB.PB2:Clone()

					if VFX_1 and VFX_2 then
						local attachment: Attachment = Instance.new("Attachment")
						attachment.Parent = attackerHRP
						attachment.CFrame = CFrame.new(0, 0, 1)
						VFX_1.Parent = attachment
						VFX_2.Parent = attachment

						VFX_1:Emit(1)
						VFX_2:Emit(1)
						Debris:AddItem(attachment, 0.5)
					end
				end
				playParticles()

				local function playHighlight()
					local Highlight: Highlight? = ReplicatedStorage.FX.VFX.Actions.Combat.PB.Highlight:Clone()
					if Highlight then
						Highlight.Parent = attackerChar
						Highlight.Adornee = attackerChar

						Debris:AddItem(Highlight, PBstun_Time)
					end
				end
				playHighlight()

				--SFX
				local function playSFX()
					local SFX: Sound? = ReplicatedStorage.FX.SFX.Combat.General.PerfectBlock:Clone()
					if SFX then
						SFX.Parent = opponentHRP
						SFX:Play()
						Debris:AddItem(SFX, SFX.TimeLength)
					end
				end
				playSFX()

				--Anim
				local function playAnimation()
					local animator: Animator? = attackerHum:FindFirstChildOfClass("Animator")
					if animator then
						local fadeTime_In: number = 0.1
						local fadeTime_Out: number = 0.4
						local track: AnimationTrack = animator:LoadAnimation(ReplicatedStorage.Animations.General.Blocking.PB:Clone())
						track:Play(fadeTime_In)
						task.delay(PBstun_Time - fadeTime_Out, function()
							track:Stop(fadeTime_Out)
						end)
						Debris:AddItem(track, PBstun_Time)
					end
				end
				playAnimation()
			else --If opponent is blocking for > PB_Window, AND attack is PBable, attacker's hit goes through
				hit()
			end
		else --If attack is not PBable, do normal block sequence
			if blockHits < (GUARDBREAK_Amount - 1) then
				opponentChar:SetAttribute("BlockHits", blockHits + 1)
				--hitModule_blockingEvent:Fire(blockHits, true)
				--	print("BlockHits = ", blockHits + 1)

				local tool = opponentChar:FindFirstChildOfClass("Tool")
				if tool and tool.Name == "Katana" then --If holding katana, play katana block SFX and VFX
					local function playSFX()
						--SFX
						local SFX: Sound? = ReplicatedStorage.FX.SFX.Combat.Katana.BlockedKatana:Clone()
						if SFX then
							local pitch: number = math.random(75, 125) / 100
							local pitchShiftFx: PitchShiftSoundEffect? =
								SFX:FindFirstChildOfClass("PitchShiftSoundEffect")
							if pitchShiftFx then
								pitchShiftFx.Octave = pitch
								SFX.Parent = opponentHRP
								SFX:Play()
								Debris:AddItem(SFX, SFX.TimeLength)
							end
						end
					end

					local function playVFX()
						local blockVFX: Folder? = ReplicatedStorage.FX.VFX.Actions.Combat.Blocked.Sharp
						if blockVFX then
							local attachment: Attachment = Instance.new("Attachment")
							attachment.Parent = opponentHRP

							for _, v in pairs(blockVFX:GetChildren()) do --Loops through VFX in folder
								if v:IsA("ParticleEmitter") then
									local v_Clone = v:Clone()
									v_Clone.Parent = attachment
									v_Clone:Emit(1)
								end
							end
							Debris:AddItem(attachment, 0.5)
						end
					end
					
					playSFX()
					playVFX()
				else --If not holding katana, play fists block SFX and VFX
					local function playSFX()
						local SFX: Sound? = ReplicatedStorage.FX.SFX.Combat.Fists.BlockedFists:Clone()
						if SFX then
							local pitch: number = math.random(75, 125) / 100
							local pitchShiftFx: PitchShiftSoundEffect? =
								SFX:FindFirstChildOfClass("PitchShiftSoundEffect")
							if pitchShiftFx then
								pitchShiftFx.Octave = pitch
								SFX.Parent = opponentHRP
								SFX:Play()
								Debris:AddItem(SFX, SFX.TimeLength)
							end
						end
					end

					local function playVFX()
						local blockVFX: Folder? = ReplicatedStorage.FX.VFX.Actions.Combat.Blocked.Blunt
						if blockVFX then
							local attachment: Attachment = Instance.new("Attachment")
							attachment.Parent = opponentHRP

							for _, v in pairs(blockVFX:GetChildren()) do --Loops through VFX in folder
								if v:IsA("ParticleEmitter") then
									local v_Clone = v:Clone()
									v_Clone.Parent = attachment
									v_Clone:Emit(1)
								end
							end
							Debris:AddItem(attachment, 0.5)
						end
					end
					
					playSFX()
					playVFX()
				end
				
				setStun(opponentChar, 0.25, false)
				knockback(attackerHRP, opponentHRP, 25, 0.1, "Away")
			else --Guardbreak
				hitModule_blockingEvent:Fire(blockHits, false)
				opponentChar:SetAttribute("Blocking", false)
				opponentChar:SetAttribute("BlockHits", 0)

				setStun(opponentChar, GBstun_Time, true) --Guardbreak time in seconds
				knockback(attackerHRP, opponentHRP, 75, 0.15, "Away") --Knockback for guardbreak

				--VFX
				local function playParticles()
					local VFX_1: ParticleEmitter? = ReplicatedStorage.FX.VFX.Actions.Combat.GB.GB1:Clone()
					local VFX_2: ParticleEmitter? = ReplicatedStorage.FX.VFX.Actions.Combat.GB.GB2:Clone()
					local VFX_3: ParticleEmitter? = ReplicatedStorage.FX.VFX.Actions.Combat.GB.GB3:Clone()

					if VFX_1 and VFX_2 and VFX_3 then
						local attachment: Attachment = Instance.new("Attachment")

						attachment.Parent = opponentHRP
						attachment.CFrame = CFrame.new(0, 0, -1)
						VFX_1.Parent = attachment
						VFX_2.Parent = attachment
						VFX_3.Parent = attachment

						VFX_1:Emit(1)
						VFX_2:Emit(1)
						VFX_3:Emit(1)
						Debris:AddItem(attachment, 1)
					end
				end
				local function playHighlight()
					local highlight: Highlight? = ReplicatedStorage.FX.VFX.Actions.Combat.GB.Highlight:Clone()
					if highlight then
						highlight.Parent = opponentChar
						highlight.Adornee = opponentChar
						highlight.Enabled = true

						Debris:AddItem(highlight, GBstun_Time)
					end
				end
				playParticles()
				playHighlight()

				--SFX
				local function playSFX()
					local SFX: Sound? = ReplicatedStorage.FX.SFX.Combat.General.GuardBreak:Clone()
					if SFX then
						SFX.Parent = opponentHRP
						SFX:Play()
						Debris:AddItem(SFX, SFX.TimeLength)
					end
				end
				playSFX()

				--Animation
				local function playAnimation()
					local animator: Animator? = opponentHum:FindFirstChildOfClass("Animator")
					if animator then
						local fadeTime_In: number = 0.1
						local fadeTime_Out: number = 0.4
						local track: AnimationTrack = animator:LoadAnimation(ReplicatedStorage.Animations.General.Blocking.Guardbroken)
						track:Play(fadeTime_In)
						task.delay(GBstun_Time - fadeTime_Out, function()
							track:Stop(fadeTime_Out)
						end)
						Debris:AddItem(track, GBstun_Time)
					end
				end
				playAnimation()
			end
		end
	else
		hit()
	end
end

return hitModule
