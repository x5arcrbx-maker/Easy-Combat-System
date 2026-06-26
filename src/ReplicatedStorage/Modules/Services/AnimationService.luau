local AnimationService = {}

--	For both functions, tracks are returned after function is complete for further usage such as:
-- 		KeyFrame events, stopping (without destroying), resetting TimePosition, etc.
--	[METHODS]
--		AnimationService:Play(animation, Animator, fadeTime_Play, fadeTime_End, weight, speed, repeatCount)
--      AnimationService:Stop(track, Animator, fadeTime)


-- Plays an animation track for a set amount of times, destroys it once ended. [Mainly used for playing animations, general usage]
function AnimationService:Play(
	animation: Animation,
	Animator: Animator,
	fadeTime_Play: number?,
	fadeTime_End: number?,
	weight: number?,
	speed: number?,
	repeatCount: number?,
	priority: Enum.AnimationPriority?
)
	
	--	Check for nil values
	if not animation then
		warn("AnimationService:Play | animation is nil. Did you forget to pass in an animation for first parameter?")
		return
	end
	if not Animator then
		warn("AnimationService:Play | Animator is nil. Did you forget to pass in an Animator for second parameter?")
		return
	end
	
	--	Default variables
	fadeTime_Play = fadeTime_Play or 0
	fadeTime_End  = fadeTime_End or 0
	weight 		  = weight or 1
	speed 		  = speed or 1
	repeatCount   = repeatCount or 1
	if repeatCount == 0 then repeatCount = 1 end
	
	--	Load Track and adjust weight & speed
	local track: AnimationTrack = Animator:LoadAnimation(animation)
	track:AdjustWeight(weight)
	track:AdjustSpeed(speed)
	if priority then
		track.Priority = priority
	end
	
	--	Check if the repeatCount is -1 (infinite/looped)
	if repeatCount == -1 then
		track.Looped = true
		track:Play(fadeTime_Play)
		return track
	end
	
	--	If not looped, play the animation and wait for it to end.
	task.spawn(function()
		for i = 1, repeatCount do -- Loop animation with repeatCount as the max iteration
			if i >= repeatCount then --	Animation is finished playing, stop and destroy it.
				track:Play(fadeTime_Play)
				track.Stopped:Wait()
				track:Destroy()
				track = nil
				break
			else --	Animation is still playing, continue.
				track:Play(fadeTime_Play)
				track.Stopped:Wait()
				track.TimePosition = 0
			end
		end
	end)
	
	return track
end

--Stops an animation track and destroys it. [Mainly used for canceling animations.]
function AnimationService:Stop(
	track: AnimationTrack,
	Animator: Animator,
	fadeTime: number?
)
	--	Check for nil values
	if not track then
		warn("AnimationService:Stop | track is nil. Did you forget to pass in a track for first parameter?")
		return
	end
	if not Animator then
		warn("AnimationService:Stop | Animator is nil. Did you forget to pass in an Animator for second parameter?")
		return
	end
	
	--	Default variables
	fadeTime = fadeTime or 0
	
	--	Stop and destroy track
	track:Stop(fadeTime)
	track:Destroy()
	track = nil
	
	return track
end

return AnimationService
