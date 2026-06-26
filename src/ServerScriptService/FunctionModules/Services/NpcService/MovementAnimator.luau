-- MovementAnimator.lua
-- Makes NPCs use the same walk/run animation system as players

local MovementAnimator = {}
MovementAnimator.RUN_THRESHOLD = 16

-- Animation IDs (so you don’t need Animation objects)
local WALK_ANIM = "rbxassetid://127643079341749"
local RUN_ANIM = "rbxassetid://114679939428810" -- default run
local RUN_KATANA_ANIM = "rbxassetid://90978495556659"

function MovementAnimator.Apply(model)
	if not model then
		return
	end

	local hum = model:FindFirstChildWhichIsA("Humanoid")
	if not hum then
		return
	end

	-----------------------------------------------------------------
	-- Ensure animator exists once
	-----------------------------------------------------------------
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = hum
	else
		for _, obj in ipairs(hum:GetChildren()) do
			if obj:IsA("Animator") and obj ~= animator then
				obj:Destroy()
			end
		end
	end

	-----------------------------------------------------------------
	-- Create animation instances
	-----------------------------------------------------------------
	local walkAnimObj = Instance.new("Animation")
	walkAnimObj.AnimationId = WALK_ANIM

	local runAnimObj = Instance.new("Animation")
	runAnimObj.AnimationId = RUN_ANIM

	local walkTrack, runTrack

	-----------------------------------------------------------------
	local function stopAll()
		if walkTrack then
			walkTrack:Stop()
			walkTrack:Destroy()
			walkTrack = nil
		end
		if runTrack then
			runTrack:Stop()
			runTrack:Destroy()
			runTrack = nil
		end
	end

	local function playWalk()
		if walkTrack and walkTrack.IsPlaying then
			return
		end
		stopAll()
		walkTrack = animator:LoadAnimation(walkAnimObj)
		walkTrack.Priority = Enum.AnimationPriority.Movement
		walkTrack:Play()
	end

	local function playRun()
		if runTrack and runTrack.IsPlaying then
			return
		end
		stopAll()

		-- Switch run animation if NPC has a katana
		if model:FindFirstChild("Katana") then
			runAnimObj.AnimationId = RUN_KATANA_ANIM
		else
			runAnimObj.AnimationId = RUN_ANIM
		end

		runTrack = animator:LoadAnimation(runAnimObj)
		runTrack.Priority = Enum.AnimationPriority.Movement
		runTrack:Play()
	end

	-----------------------------------------------------------------
	-- Connect running signal
	-----------------------------------------------------------------
	local function onRunning(speed)
		if speed > MovementAnimator.RUN_THRESHOLD then
			playRun()
			if runTrack then
				runTrack:AdjustSpeed(speed / MovementAnimator.RUN_THRESHOLD)
			end
		elseif speed > 0.1 then
			playWalk()
			if walkTrack then
				walkTrack:AdjustSpeed(speed / MovementAnimator.RUN_THRESHOLD)
			end
		else
			stopAll()
		end
	end

	hum.Running:Connect(onRunning)

	hum.Died:Connect(stopAll)

	stopAll()
end

return MovementAnimator
