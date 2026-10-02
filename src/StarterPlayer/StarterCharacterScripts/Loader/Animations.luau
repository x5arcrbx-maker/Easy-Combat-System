local function LoadAnim(
	folder: Folder,
	index: number,
	animator: Animator,
	priority: Enum.AnimationPriority
): AnimationTrack
	local animation = folder:FindFirstChild(tostring(index))
	if not animation then
		warn(string.format("Animation with index %d not found in folder %s", index, folder:GetFullName()))
		return nil
	end
	local animationTrack: AnimationTrack = animator:LoadAnimation(animation :: Animation)
	animationTrack.Priority = priority or Enum.AnimationPriority.Action
	return animationTrack
end

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

	for i = 1, #light_Basic_Animations do
		lightTracks[i] = LoadAnim(light_Basic_Animations_Folder, i, animator, Enum.AnimationPriority.Action)
	end

	for i = 1, #heavy_Basic_Animations do
		heavyTracks[i] = LoadAnim(heavy_Basic_Animations_Folder, i, animator, Enum.AnimationPriority.Action)
	end

	print("List of light animation tracks:")
	for i, track in ipairs(lightTracks) do
		print(string.format("  Track %d: %s", i, track.Animation.Name))
	end
	print("List of heavy animation tracks:")
	for i, track in ipairs(heavyTracks) do
		print(string.format("  Track %d: %s", i, track.Animation.Name))
	end

	return {
		Light = lightTracks,
		Heavy = heavyTracks,
	}
end
