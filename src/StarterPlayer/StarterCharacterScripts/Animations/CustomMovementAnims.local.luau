--!strict
--//:SERVICES
local Players = game:GetService("Players")

--//:REFERENCES
--	player & character variables
local player = Players.LocalPlayer :: Player
local char = player.Character or player.CharacterAdded:Wait() :: Model -- The player's character
local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid") :: Humanoid
local animator = hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator") :: Animator

--	animations
local idleAnim_Obj = script:FindFirstChild("DefaultIdle") :: Animation
local walkAnim_Obj = script:FindFirstChild("WalkAnim") :: Animation
local defaultRunAnim_Obj = script:FindFirstChild("DefaultRun") :: Animation
local katanaRunAnim_Obj = script:FindFirstChild("KatanaRun") :: Animation

--//:VARIABLES
--	Tracks
local idleTrack: AnimationTrack = animator:LoadAnimation(idleAnim_Obj)
idleTrack.Priority = Enum.AnimationPriority.Idle

local walkTrack: AnimationTrack = animator:LoadAnimation(walkAnim_Obj)
walkTrack.Priority = Enum.AnimationPriority.Movement

local runTrackDefault: AnimationTrack = animator:LoadAnimation(defaultRunAnim_Obj)
runTrackDefault.Priority = Enum.AnimationPriority.Movement

local runTrackKatana: AnimationTrack = animator:LoadAnimation(katanaRunAnim_Obj)
runTrackKatana.Priority = Enum.AnimationPriority.Movement

--	the run track that is currently playing, ensures the correct one is stopped when switching
local currentRunTrack = runTrackDefault

--//:CONSTANTS
--	numbers
local RUN_THRESHOLD: number = 16 -- Speed above which run animation plays
local animFade_Play: number = 0.3
local animFade_Stop: number = 0.25

--//:FUNCTIONS
local function stopAll()
	walkTrack:Stop(animFade_Stop)
	runTrackDefault:Stop(animFade_Stop)
	runTrackKatana:Stop(animFade_Stop)
	idleTrack:Stop(animFade_Stop)
end

local function playWalk()
	if walkTrack.IsPlaying then
		return
	end
	stopAll()
	walkTrack:Play(animFade_Play)
	--print("CustomWalkRunAnimate: Playing Walk Animation", walkAnimObj.AnimationId)
end

local function playRun()
	local tool = char:FindFirstChildOfClass("Tool")
	local selectedRunTrack = (tool and tool:GetAttribute("Katana")) and runTrackKatana or runTrackDefault

	if selectedRunTrack.IsPlaying then
		return
	end

	--if the selected runtrack is different from the current one, stop all animations to switch the track
	stopAll()
	currentRunTrack = selectedRunTrack
	currentRunTrack:Play(animFade_Play)
	--print("CustomWalkRunAnimate: Playing Run Animation")
end

local function onRunning(speed: number)
	if speed > RUN_THRESHOLD and hum.MoveDirection.Magnitude > 0 then
		playRun()
		if currentRunTrack then
			currentRunTrack:AdjustSpeed(speed / RUN_THRESHOLD)
		end
	elseif speed > 1 and hum.MoveDirection.Magnitude > 0 then
		playWalk()
		--if walkTrack then
		--	walkTrack:AdjustSpeed(speed / RUN_THRESHOLD)
		--end
	else
		stopAll()
		idleTrack:Play(animFade_Play)
		--print("CustomWalkRunAnimate: Playing Idle Animation", idleAnim.AnimationId)
	end
end

--//:EVENTS
hum.Running:Connect(onRunning) --onRunning function when humanoid runs
hum.Jumping:Connect(stopAll)
hum.Climbing:Connect(stopAll)
hum.Swimming:Connect(stopAll)
hum.Died:Connect(stopAll) --Stop animations on death
stopAll() --Stop animations on spawn

char.ChildAdded:Connect(function()
	if hum:GetState() == Enum.HumanoidStateType.Running and hum.WalkSpeed > RUN_THRESHOLD then
		onRunning(hum.WalkSpeed)
	end
end)
char.ChildRemoved:Connect(function()
	if hum:GetState() == Enum.HumanoidStateType.Running and hum.WalkSpeed > RUN_THRESHOLD then
		onRunning(hum.WalkSpeed)
	end
end)

char:GetAttributeChangedSignal("UsingAttack"):Connect(function()
	local Attacking = char:GetAttribute("UsingAttack")
	if not Attacking then
		onRunning(hum.WalkSpeed)
	end
end)
