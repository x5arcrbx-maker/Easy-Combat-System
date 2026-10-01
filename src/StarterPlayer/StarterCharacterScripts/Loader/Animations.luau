return function(character: Model): { Light: { Animation }, Heavy: { Animation } }
	if not character then
		warn("Character is nil. Cannot load animations.")
		return { Light = {}, Heavy = {} }
	elseif not character:IsA("Model") then
		warn("Character is not a Model. Cannot load animations.")
		return { Light = {}, Heavy = {} }
	end
	local humanoid: Humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local animator: Animator = humanoid:WaitForChild("Animator") :: Animator

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local assets = ReplicatedStorage:WaitForChild("Assets") :: Folder
	local animations = assets:WaitForChild("Animations") :: Folder
	local combat_Animations = animations:WaitForChild("Combat") :: Folder
	local basic_Combat_Animations = combat_Animations:WaitForChild("Basic") :: Folder
	local light_Basic_Animations_Folder = basic_Combat_Animations:WaitForChild("Light") :: Folder
	local heavy_Basic_Animations_Folder = basic_Combat_Animations:WaitForChild("Heavy") :: Folder

	local light_Basic_Animations = light_Basic_Animations_Folder:GetChildren()
	local heavy_Basic_Animations = heavy_Basic_Animations_Folder:GetChildren()
	local lightTracks = {}
	local heavyTracks = {}

	for _, animation in ipairs(light_Basic_Animations) do
		local animationTrack: AnimationTrack = animator:LoadAnimation(animation :: Animation)
		animationTrack.Priority = Enum.AnimationPriority.Action
		table.insert(lightTracks, animationTrack)
	end

	for _, animation in ipairs(heavy_Basic_Animations) do
		local animationTrack: AnimationTrack = animator:LoadAnimation(animation :: Animation)
		animationTrack.Priority = Enum.AnimationPriority.Action
		table.insert(heavyTracks, animationTrack)
	end
	return {
		Light = lightTracks,
		Heavy = heavyTracks,
	}
end
