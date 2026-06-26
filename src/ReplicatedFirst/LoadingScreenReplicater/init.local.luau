--Disable default loading screen as soon as script runs
game:GetService("ReplicatedFirst"):RemoveDefaultLoadingScreen()

--//:SERVICES
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
-------------

--Disable default core GUIs and re-enable only the ones we want to keep
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.AvatarSwitcher, true)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Captures, true)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.ExperienceShop, true)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.SelfView, true)

--Disable core GUIs

--//:REFERENCES
local player: Player? = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui")

local completeSound: Sound = script:WaitForChild("CompleteSound")

--	GUI Instance References
local loadingScreen: ScreenGui = script:WaitForChild("LoadingScreen")
loadingScreen = loadingScreen:Clone()
loadingScreen.Parent = playerGui
local frame = loadingScreen:WaitForChild("Frame") :: Frame
local loadingText = frame:WaitForChild("LoadLabel") :: TextLabel
local loadingBarFrame = frame:WaitForChild("LoadingBar") :: Frame
local bar = loadingBarFrame:WaitForChild("Bar") :: ImageLabel
bar.Size = UDim2.fromScale(0, 1)
----------------

--//:VARIABLES
local tips: TextLabel = frame:WaitForChild("TipsLabel")
local tipsList: { string } = {
	"This tip is the first tip I typed.",
	"Use the environment to your advantage.",
	"You can stop your attacks from hitting by blocking, useful for feinting.",
	"Your light and heavy attacks are useful for clashing to defend yourself.",
	"Don't rage at the death messages...",
	"How many tips do you think there are?",
	"Some attacks are perfect blockable, make sure to time your block.",
	"This is your story.",
	"If you can't fight, run.",
	"Clashes can save you from damage. Clash by attacking before being hit!",
	"Common sense is your best friend.",
	"A failure is a lesson learned.",
	"Use skills wisely, cooldowns exist you know...",
	"Learning to string different skills helps you damage your opponent, and even make them rage!",
	"Use your dash to get away from incoming attacks.",
	"Your dash can be used to bait attacks from your opponent.",
	"Remember, you can block while using a skill in case you find yourself in trouble.",
	"Heavy attacks are handy for both starting & continuing combos, and even clashing!",
	--"If you use breathing techniques, remember to breathe.",
	"Don't jump from a sky scraper. You are not Superman.",
	--"If you fall from somewhere high up, try to climb on something to prevent fall damage!",
	"Certain skills function much differently than others. Always important to ask questions when possible.",
	"It's usually better to be in shiftlock when in combat, unless you're just that guy...",
}
local assets: { Instance } = game:GetDescendants()
local COMPLETED: boolean = false
-------------

--//:FUNCTIONS
local function onCharacterAdded(_character: Model)
	print("onCharacterAdded reached!")
	local isReady = ReplicatedStorage.Values.BoolValues["LoadingScreen / MainMenu"].IsReady

	repeat --Wait until loading is completed
		task.wait()
	until COMPLETED
	print("Loading Completed: ", COMPLETED)

	local function fadeGui()
		local guiTweenFunctions = {
			["TextLabel"] = function(obj: TextLabel)
				TweenService
					:Create(obj, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0), {
						TextTransparency = 1,
						BackgroundTransparency = 1,
					})
					:Play()
			end,
			["ImageLabel"] = function(obj: TextLabel)
				TweenService
					:Create(obj, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0), {
						ImageTransparency = 1,
						BackgroundTransparency = 1,
					})
					:Play()
			end,
			["Frame"] = function(obj: Frame)
				TweenService
					:Create(obj, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0), {
						BackgroundTransparency = 1,
					})
					:Play()
			end,
			["UIStroke"] = function(obj: UIStroke)
				TweenService
					:Create(obj, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0), {
						Transparency = 1,
					})
					:Play()
			end,
		}

		for _, v in pairs(frame:GetDescendants()) do
			local vClassName = v.ClassName
			local tweenFunction_forV = guiTweenFunctions[vClassName]
			if tweenFunction_forV then
				tweenFunction_forV(v)
			end
		end
	end
	fadeGui()
	task.wait(1)
	print("Gui faded")

	isReady.Value = true
	--Fade out frame AFTER setting isReady.Value to true.
	--	This way the player doesn't see themselves in the spawn box between the transition
	--		from the loading screen to the main menu.
	TweenService:Create(frame, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.In, 0, false, 0), {
		BackgroundTransparency = 1,
	}):Play()
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Once(onCharacterAdded)
--^ Ensure player spawns at a random playerSpawn after spawning in the spawnBox
--------------

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
