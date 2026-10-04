--!strict
local UserInputService = game:GetService("UserInputService")


local DialogueModule = {}

function DialogueModule.Speak(
	player: Player,
	text: string,
	name: string,
	textColor3: Color3?,
	textStrokeColor3: Color3?,
	textScaled: boolean?,
	textSize: number?,
	fontFace: Font?,
	speed: number?,
	pitch: number?
)
	if not player
		or not text 
		or not name
	then
		warn("Invalid arguments passed to DialogueModule.Speak")
		warn("Player:", player, "... Text:", text, "... Name:", name)
		return 
	end

	if not player.Character then
		warn("Character not found for player:", player.Name)
		return 
	end

	--		Create variables		--
	local playerGui 	   = player:FindFirstChild("PlayerGui") :: PlayerGui
	local EventGUIs 	   = playerGui:FindFirstChild("EventGUIs") :: Folder
	local dialogueGui 	   = EventGUIs:FindFirstChild("Dialogue") :: ScreenGui
	
	local main_frame 	   = dialogueGui:FindFirstChild("MainFrame") :: Frame
	local choice_frame 	   = dialogueGui:FindFirstChild("ChoiceFrame") :: Frame
	local skipControlLabel = dialogueGui:FindFirstChild("SkipControlLabel") :: TextLabel
	local speakSound 	   = dialogueGui:FindFirstChild("SpeakSound") :: Sound
	
	local main_textBody    = main_frame:FindFirstChild("TextBody") :: TextLabel
	local main_nameBody    = main_frame:FindFirstChild("Name") :: TextLabel
	
	local choice_template  = choice_frame:FindFirstChild("Template") :: Frame
	local choice_list      = choice_frame:FindFirstChild("List") :: Frame
	
	local pitchEffect 	   = speakSound:FindFirstChildOfClass("PitchShiftSoundEffect") :: PitchShiftSoundEffect
	----------------------------------

	--		Set defaults		--
	--(numbers)
	speed = speed or 0.05
	pitch = pitch or 1
		
	--(properties)
	main_textBody.Text 			   = ""
	main_textBody.TextColor3 	   = textColor3 or Color3.new(1, 1, 1)
	main_textBody.TextStrokeColor3 = textStrokeColor3 or Color3.new(0, 0, 0)
	main_textBody.TextScaled 	   = textScaled or true
	main_textBody.TextSize 		   = textSize or 14
	main_textBody.FontFace 		   = fontFace or Font.new(
		"rbxasset://fonts/families/AccanthisADFStd.json",
		Enum.FontWeight.Regular,
		Enum.FontStyle.Normal
	)
	main_nameBody.Text 			   = name
	dialogueGui.Enabled 	  	   = true
	
	pitchEffect.Octave 		 	   = pitch
	------------------------------

	--Variables to track state
	local skipped  = false
	local finished = false

	--Update skipControlLabel.Text based on input type
	local function checkInputType()
		if finished then
			if UserInputService.KeyboardEnabled then
				skipControlLabel.Text = "Press [Left Control] to exit"
			end
			if UserInputService.GamepadEnabled then
				skipControlLabel.Text = "Press [X / Triangle] to exit"
			end
			if UserInputService.TouchEnabled then
				skipControlLabel.Text = "Tap anywhere to exit"
			end
		else
			if UserInputService.KeyboardEnabled then
				skipControlLabel.Text = "Press [Left Control] to continue"
			end
			if UserInputService.GamepadEnabled then
				skipControlLabel.Text = "Press [X / Triangle] to continue"
			end
			if UserInputService.TouchEnabled then
				skipControlLabel.Text = "Tap anywhere to continue"
			end
		end
	end

	--Keybinds for advancing dialogue
	local keybinds = {
		Keyboard = Enum.KeyCode.LeftControl,
		Console	 = Enum.KeyCode.ButtonX,
		Mobile 	 = Enum.UserInputType.Touch,
	} 
	--Check if input is a keybind for advancing dialogue
	local function isAdvanceInput(input: InputObject)
		return 
			input.KeyCode == keybinds.Keyboard
			or input.KeyCode == keybinds.Console
			or input.UserInputType == keybinds.Mobile
	end

	--Listen for input to advance dialogue
	local skip_inputConnection: RBXScriptConnection
	skip_inputConnection = UserInputService.InputBegan:Connect(function(input, GPE)
		checkInputType() --Update skipControlLabel.Text every time input occurs

		if GPE then return end
		if not isAdvanceInput(input) then return end
		
		if not finished then
			skipped = true
		else --If dialogue is finished, close dialogue and disconnect connection
			dialogueGui.Enabled = false
			skip_inputConnection:Disconnect()
		end
	end)

	-- Typewriter effect
	for i = 1, #text do
		if skipped then break end
		main_textBody.Text = string.sub(text, 1, i)
		if speakSound.Playing then
			speakSound:Stop()
			speakSound.TimePosition = 0
			speakSound:Play()
		else
			speakSound:Play()
		end
		
		task.wait(speed)
	end
	main_textBody.Text = text
	finished = true
	checkInputType() --Update skipControlLabel.Text when dialogue is finished
end


return DialogueModule
