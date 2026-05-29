game:GetService("ReplicatedFirst"):RemoveDefaultLoadingScreen()
--Disable default loading screen as soon as script runs

print("Loading Screen Loaded")

--//:SERVICES
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
-------------

--//:REFERENCES
local player: Player? = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui")

local completeSound: Sound = script:WaitForChild("CompleteSound")
---------------

--GUI Instance References
local loadingScreen: ScreenGui = script:WaitForChild("LoadingScreen"):Clone()
loadingScreen.Parent = playerGui
local frame: Frame = loadingScreen:WaitForChild("Frame")
local loadingText: TextLabel = frame:WaitForChild("LoadLabel")
local bar: TextLabel = frame:WaitForChild("LoadingBar"):WaitForChild("Bar")
--local title = frame:WaitForChild("Title") :: TextLabel
--title.Text = "Slayers Memory BG"
--	title.TextTransparency = 1
-------------------------

--//:VARIABLES
local tips: TextLabel = frame:WaitForChild("TipsLabel")
local tipsList: { string } = {
	"This tip is the first tip I typed.",
	"Use the environment to your advantage.",
	"You can stop your attacks from hitting by blocking, useful for feinting.",
	"Your light and heavy attacks will likely be your main source of damage.",
	"Don't rage at the death messages...",
	"How many tips do you think there are?",
	"Some attacks are perfect blockable, make sure to time your block.",
	"This is your story.",
	"If you can't fight, run.",
	"Clashes can save you from damage. Clash by attacking before being hit!",
	"Common sense is your best friend.",
	"A failure is a lesson learned.",
	"Use skills wisely, cooldowns exist...",
}
local assets: { Instance } = game:GetDescendants()
local COMPLETED: boolean = false
-------------

--//:FUNCTIONS
local function onCharacterAdded(_character: Model)
	repeat --Wait until loading is completed
		task.wait()
	until COMPLETED

	local class_TweenFunctions = {
		["TextLabel"] = function(v: Instance)
			TweenService:Create(
				v,
				TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0),
				{ TextTransparency = 1, BackgroundTransparency = 1 }
			):Play()
		end,

		["Frame"] = function(v: Instance)
			TweenService:Create(
				v,
				TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0),
				{ BackgroundTransparency = 1 }
			):Play()
		end,

		["UIStroke"] = function(v: Instance)
			TweenService:Create(
				v,
				TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0),
				{ Transparency = 1 }
			):Play()
		end,
	}

	local function fadeGui()
		for _, guiObj in pairs(frame:GetDescendants()) do
			local className = guiObj.ClassName
			local tweenFunction = class_TweenFunctions[className]
			pcall(tweenFunction, guiObj)
		end
	end
	fadeGui()
	task.wait(1)

	local values = game:GetService("ReplicatedStorage"):WaitForChild("Values")
	local LoadingScreenMainMenu_Folder = values:WaitForChild("LoadingScreen / MainMenu")
	local isReady = LoadingScreenMainMenu_Folder:WaitForChild("IsReady")
	isReady.Value = true
	--Fade out frame AFTER setting isReady.Value to true.
	--	This way the player doesn't see themselves in the spawn box between the transition
	--		from the loading screen to the main menu.
	TweenService:Create(
		frame,
		TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.In, 0, false, 0),
		{ BackgroundTransparency = 1 }
	):Play()
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Once(onCharacterAdded)
--^ Ensure player spawns at a random playerSpawn after spawning in the spawnBox

-- MAIN
task.spawn(function()
	local previousResult = nil --Previous result to avoid repeats

	repeat --Main loop
		local result = math.random(1, #tipsList)
		if #tipsList > 1 then --Checks > 1 to avoid infinite loop
			repeat
				result = math.random(1, #tipsList)
			until result ~= previousResult
		end --randomize tips
		previousResult = result --Store previous result to avoid repeats

		tips.Text = tipsList[result]
		if tips.TextTransparency == 1 then
			TweenService:Create(
				tips,
				TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0),
				{ TextTransparency = 0 }
			):Play()
		end

		task.wait(2) --wait 2 seconds
		TweenService:Create( --fade out tips.Text (1 seconds)
			tips,
			TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0),
			{ TextTransparency = 1 }
		):Play()
		task.wait(1.5) --While tips.Text fades out, wait 1.5 seconds
	--(.5 seconds of debounce before another tip)

	until COMPLETED
end) --^ End of task.spawn (tips)

for i, asset: Instance in pairs(assets) do
	local progress = i / #assets
	local progress_Text = math.round(progress * 100) .. "%"

	loadingText.Text = "Loading: " .. asset.ClassName .. "... (" .. progress_Text .. ")"
	--Example--
	--Loading: ReplicatedFirst... (15%)
	ContentProvider:PreloadAsync({ asset })

	TweenService:Create(
		bar,
		TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0),
		{ Size = UDim2.fromScale(progress, 1) }
	):Play()
	--task.wait(0.075)
end --^ End of for loop (assets)
--------------

--Loading Complete--
COMPLETED = true --Prevent tips from changing after loading is complete

loadingText.Text = "Loading Complete!" --Change loadingText to "Loading Complete!"
bar.Size = UDim2.fromScale(1, 1) --Set bar to 100% (Full)

completeSound:Play() --Play sound to notify player loading completed
--------------------

--Cleanup
task.wait(5) --Wait 5 seconds before destroying loading screen and script

loadingScreen:Destroy()
script:Destroy()
