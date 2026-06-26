local SoundService = game:GetService("SoundService")

local music = SoundService:WaitForChild("Music") :: SoundGroup

for _, sound: Sound in music:GetChildren() do
	if not sound.IsLoaded then
		sound.Loaded:Wait()
	end
end

task.spawn(function()
	local songs = music:GetChildren()
	while true do
		local randomMusic: Sound = songs[math.random(#songs)]

		randomMusic.TimePosition = 0

		if not randomMusic.IsLoaded then
			randomMusic.Loaded:Wait()
		end

		randomMusic:Play()
		randomMusic.Ended:Wait()

		task.wait(2)
	end
end)

local player = game:GetService("Players").LocalPlayer
local function setupCharacter(char: Model)
	local hum = char:WaitForChild("Humanoid") :: Humanoid

	hum.Died:Once(function()
		for _, sound: Sound in music:GetChildren() do
			if sound.IsPlaying then
				sound:Stop()
				sound.TimePosition = 0
			end
		end
	end)
end

player.CharacterAdded:Connect(setupCharacter)
if player.Character then
	setupCharacter(player.Character)
end