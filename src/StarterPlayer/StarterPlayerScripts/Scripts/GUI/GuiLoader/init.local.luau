--[[
	THIS SCRIPT WILL LOAD ALL GUIS FOR TOPBARPLUS,
	SET THEIR PROPERTIES,
	AND LOAD ANY ADDITIONAL GUIS.
	
	IT'S ALSO MEANT TO HANDLE ALL EVENTS FOR THE GUIS.
--]]
------------

--Getting player
local player = game:GetService("Players").LocalPlayer :: Player

--//:SERVICES
local MarketPlaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

--//:MODULES
local Icon = require(ReplicatedStorage.Modules.Packages.topbarplus)

--//:VARIABLES
local icons = {
	Settings = Icon.new():setName("Settings"):setCaption("Settings"):setImage(14134158045),
	Shop = Icon.new():setName("Shop"):setCaption("Shop"):setImage(13429538917),
	Skillsets = Icon.new():setName("Skillsets"):setCaption("Skillsets"):setImage(11833765861),
}
local connections = {
	Settings = {
		Sounds = {},
		VFX = {},
		Party = {},
		Keybinds = {},
	},
	Shop = {},
}

local guiFolder = script:WaitForChild("GUIs") :: Folder
local soundsFolder = script:WaitForChild("Sounds") :: Folder

local topbarClickSound = soundsFolder:WaitForChild("TopbarClick") :: Sound?
local guiClickSound = soundsFolder:WaitForChild("GuiClick") :: Sound?
local gamepassPromptClickSound = soundsFolder:WaitForChild("GamepassPromptClick") :: Sound?
local hoverSound = soundsFolder:WaitForChild("HoverSound") :: Sound?
local typingSound = soundsFolder:WaitForChild("TypingSound") :: Sound?

--//:FUNCTIONS
local function _checkExistenceAndTypes(instance: Instance?, path: Instance | string?, typeToCheck: string?): boolean
	--// EXISTENCE CHECK
	if not instance then
		-- check if path exists
		if not path then
			warn("Instance is nil and no path was provided.")
		else
			if typeof(path) == "Instance" then
				warn("Instance does not exist at path (" .. path.Name .. ")")
			else
				warn("Instance does not exist at path (" .. tostring(path) .. ")")
			end
		end

		return false
	end

	--// TYPE CHECK (optional)
	if typeToCheck then
		-- check Roblox class type
		if not instance:IsA(typeToCheck) then
			warn("Instance type mismatch. Expected '" .. typeToCheck .. ", got '" .. instance.ClassName)

			return false
		end
	end

	return true
end

local function playGuiSound(sound: Sound?, pitch: number?)
	if sound and sound:IsA("Sound") then
		if not sound.IsPlaying then
			if pitch then
				local pitchEffect = sound:FindFirstChildOfClass("PitchShiftSoundEffect") :: PitchShiftSoundEffect
				if pitchEffect then
					pitchEffect.Octave = pitch
				end
			end
			sound:Play()
		else
			if pitch then
				local pitchEffect = sound:FindFirstChildOfClass("PitchShiftSoundEffect") :: PitchShiftSoundEffect
				if pitchEffect then
					pitchEffect.Octave = pitch
				end
			end
			sound:Stop()
			sound.TimePosition = 0
			sound:Play()
		end
	end
end

local function promptGamePassPurchase(playerPurchasing: Player, gamepassId: number | string)
	if not gamepassId then
		return
	end
	if typeof(gamepassId) == "string" then
		gamepassId = tonumber(gamepassId)
		if not gamepassId then
			return
		end
	end
	MarketPlaceService:PromptGamePassPurchase(playerPurchasing, gamepassId)
end

--//Init
--Settings icon
local function Init_SettingsIcon()
	local success, err = pcall(function()
		--Bind events to the icon
		icons.Settings:bindEvent("selected", function()
			-- print("----------") --seperator for logs, easier reading
			-- print("Settings +SELECTED+")
			playGuiSound(topbarClickSound, 1)

			local playerGui: StarterGui = player.PlayerGui

			local gui = guiFolder:FindFirstChild("Settings")
			if not gui or not gui:IsA("ScreenGui") then
				return
			end

			local existing_gui = playerGui:FindFirstChild(gui.Name)
			if existing_gui and existing_gui:IsA("ScreenGui") then
				gui = existing_gui
				gui.Enabled = true
			else --If the gui was not already cloned and parented, clone and parent it to PlayerGui
				gui = gui:Clone()
				gui.Parent = playerGui
				gui.Enabled = true
				-- print("Settings cloned and parented")
			end
			-- print("Settings enabled")

			--Main frame
			local main_Frame = gui:FindFirstChild("MainFrame") :: Frame
			if not main_Frame then
				return
			end

			--Category frame
			local category_Frame = main_Frame:FindFirstChild("CategoryFrame") :: Frame
			if not category_Frame then
				return
			end

			--Category buttons
			local sounds_CategoryButton = category_Frame:FindFirstChild("Sounds") :: TextButton
			if not sounds_CategoryButton then
				return
			end

			local configure_Frame =
				sounds_CategoryButton:FindFirstChild("ConfigureFrame_" .. sounds_CategoryButton.Name) :: Frame?
			if not configure_Frame then
				configure_Frame = main_Frame:FindFirstChild("ConfigureFrame_" .. sounds_CategoryButton.Name) :: Frame?
			end
			if not configure_Frame then
				return
			end

			local musicVolume = configure_Frame:FindFirstChild("MusicVolume") :: Frame
			local footstepsVolume = configure_Frame:FindFirstChild("FootstepsVolume") :: Frame

			if not musicVolume then
				return
			end
			if not footstepsVolume then
				return
			end

			local musicVolume_textBox = musicVolume:FindFirstChild("TextBox") :: TextBox
			local footstepsVolume_textBox = footstepsVolume:FindFirstChild("TextBox") :: TextBox

			if not musicVolume or not footstepsVolume or not musicVolume_textBox or not footstepsVolume_textBox then
				return
			end

			--Connections
			for _, category in pairs(category_Frame:GetChildren()) do
				if category:IsA("ImageButton") or category:IsA("TextButton") and category.Visible then
					local categoryHoverBegan_Conn: RBXScriptConnection = sounds_CategoryButton.MouseEnter:Connect(
						function()
							playGuiSound(hoverSound, 1)
						end
					)
					table.insert(connections.Settings, categoryHoverBegan_Conn)

					local categoryHoverEnded_Conn: RBXScriptConnection = sounds_CategoryButton.MouseLeave:Connect(
						function()
							playGuiSound(hoverSound, 0.85)
						end
					)
					table.insert(connections.Settings, categoryHoverEnded_Conn)
				end
			end

			local sounds_categoryActivated_conn: RBXScriptConnection = sounds_CategoryButton.Activated:Connect(
				function()
					playGuiSound(guiClickSound, 1)

					if not configure_Frame then
						return
					end
					if configure_Frame.Parent == main_Frame and configure_Frame.Visible then
						configure_Frame.Parent = sounds_CategoryButton
						configure_Frame.Visible = false
					else
						configure_Frame.Parent = main_Frame
						configure_Frame.Visible = true
					end
				end
			)
			table.insert(connections.Settings.Sounds, sounds_categoryActivated_conn)

			local function updateTextBoxes(textbox): number?
				local number = tonumber(textbox.Text)
				if not number then
					textbox.Text = ""
					return nil
				end

				--[[
				if number < 0 then
					number = 0
				elseif number > 10 then
					number = 10
				end
				]]

				playGuiSound(typingSound, math.random(85, 115) / 100)
				number = math.clamp(number, 0, 10)
				textbox.Text = tostring(number)
				return number
			end

			local sounds_musicVolume_conn: RBXScriptConnection = musicVolume_textBox
				:GetPropertyChangedSignal("Text")
				:Connect(function()
					local number = updateTextBoxes(musicVolume_textBox)
					if not number then
						return
					end

					local soundGroup = SoundService:FindFirstChild("Music") :: SoundGroup?
					if soundGroup then
						soundGroup.Volume = number
					end
				end)
			table.insert(connections.Settings.Sounds, sounds_musicVolume_conn)

			local sounds_footstepsVolume_conn: RBXScriptConnection = footstepsVolume_textBox
				:GetPropertyChangedSignal("Text")
				:Connect(function()
					local number = updateTextBoxes(footstepsVolume_textBox)
					if not number then
						return
					end

					local soundGroup = SoundService:FindFirstChild("FootstepSounds") :: SoundGroup?
					if soundGroup then
						soundGroup.Volume = number
					end
				end)
			table.insert(connections.Settings.Sounds, sounds_footstepsVolume_conn)
		end)
		icons.Settings:bindEvent("deselected", function()
			-- print("Settings -DESELECTED-")

			for _, v in pairs(connections.Settings) do
				if typeof(v) == "RBXScriptConnection" then
					v:Disconnect()
					v = nil
				else
					for _, connection: RBXScriptConnection? in pairs(v) do
						if typeof(connection) == "RBXScriptConnection" then
							connection:Disconnect()
							connection = nil
						end
					end --Disconnect all connections
				end
			end

			playGuiSound(topbarClickSound, 0.85)

			--Player variables
			local playerGui: StarterGui = player.PlayerGui

			local existing_ScreenGui = playerGui:FindFirstChild("Settings")
			if not existing_ScreenGui or not existing_ScreenGui:IsA("ScreenGui") then
				warn("No Settings found when deselecting.")
				return
			end --ensure existingGui exists
			existing_ScreenGui.Enabled = false

			--gui children variables
			local main_Frame = existing_ScreenGui:FindFirstChild("MainFrame")
			if not main_Frame or not main_Frame:IsA("Frame") then
				return
			end

			local category_Frame = main_Frame:FindFirstChild("CategoryFrame")
			if not category_Frame or not category_Frame:IsA("Frame") then
				return
			end

			local sounds_CategoryButton = category_Frame:FindFirstChild("Sounds")
			if not sounds_CategoryButton or not sounds_CategoryButton:IsA("TextButton") then
				return
			end

			local configure_Frame = main_Frame:FindFirstChild("ConfigureFrame_" .. sounds_CategoryButton.Name)
			if not configure_Frame or not configure_Frame:IsA("Frame") then
				configure_Frame = sounds_CategoryButton:FindFirstChild("ConfigureFrame_" .. sounds_CategoryButton.Name)
			end
			if not configure_Frame or not configure_Frame:IsA("Frame") then
				return
			end

			--handle configureFrame
			--if configure_Frame.Parent ~= main_Frame and not configure_Frame.Visible then
			--	configure_Frame.Parent = sounds_CategoryButton
			--	configure_Frame.Visible = false
			--end

			configure_Frame.Parent = sounds_CategoryButton
			configure_Frame.Visible = false

			--print("Settings Gui disabled")
		end)
	end)
	if not success then
		warn("Error while initializing Settings icon: " .. err)
	end
end
Init_SettingsIcon()

--Shop icon
local function Init_ShopIcon()
	local success, err = pcall(function()
		--Bind events to the icon
		icons.Shop:bindEvent("selected", function()
			-- print("----------") --seperator for logs, easier reading
			-- print("Shop +SELECTED+")
			playGuiSound(topbarClickSound, 1)

			local playerGui: StarterGui = player.PlayerGui

			local gui = guiFolder:FindFirstChild("Shop")
			if not gui or not gui:IsA("ScreenGui") then
				return
			end

			local existing_gui = playerGui:FindFirstChild(gui.Name)
			if existing_gui and existing_gui:IsA("ScreenGui") then
				gui = existing_gui
				gui.Enabled = true
			else --If the gui was not already cloned and parented, clone and parent it to PlayerGui
				gui = gui:Clone()
				gui.Parent = playerGui
				gui.Enabled = true
				-- print("Shop cloned and parented")
			end
			-- print("Shop enabled")

			--Main frame
			local main_Frame = gui:FindFirstChild("MainFrame") :: Frame
			if not main_Frame then
				return
			end

			--Category frame
			local page_Frame = main_Frame:FindFirstChild("PageFrame") :: Frame
			if not page_Frame then
				return
			end

			--Connections
			for _, imageLabel in pairs(page_Frame:GetChildren()) do
				if imageLabel:IsA("ImageLabel") and imageLabel.Visible then
					local gamepass =
						ReplicatedStorage.Values.NumberValues.GamePasses:FindFirstChild(imageLabel.Name) :: NumberValue
					if not gamepass then
						continue
					end
					local gamepassID = gamepass.Value
					if not gamepassID or gamepassID == 0 then
						continue
					end

					local button = imageLabel:FindFirstChild("BuyButton") :: ImageButton
					if not button then
						continue
					end
					local buttonUIGradient = button:FindFirstChildOfClass("UIGradient") :: UIGradient
					if not buttonUIGradient then
						continue
					end
					local buttonUIStroke = button:FindFirstChildOfClass("UIStroke") :: UIStroke
					if not buttonUIStroke then
						continue
					end
					local buttonText = button:FindFirstChild("TextLabel") :: TextLabel
					if not buttonText then
						continue
					end
					local buttonTextUIGradient = buttonText:FindFirstChildOfClass("UIGradient") :: UIGradient
					if not buttonTextUIGradient then
						continue
					end

					--Check if player owns the GamePass or not
					if not MarketPlaceService:UserOwnsGamePassAsync(player.UserId, gamepassID) then --Not owned
						buttonText.Text = "Get"
						button.AutoButtonColor = true
						buttonUIGradient.Color = ColorSequence.new(Color3.fromRGB(105, 150, 108))
						buttonUIStroke.Color = Color3.fromRGB(103, 185, 103)
					else --Owned
						buttonText.Text = "Owned"
						button.AutoButtonColor = false
						buttonUIGradient.Color = ColorSequence.new(Color3.fromRGB(50, 50, 50))
						buttonUIStroke.Color = Color3.fromRGB(65, 65, 65)
						continue --Skip adding connections if the player already owns the gamepass
					end

					local hoverBegan_Conn: RBXScriptConnection = button.MouseEnter:Connect(function()
						playGuiSound(hoverSound, 1)
					end)
					table.insert(connections.Shop, hoverBegan_Conn)

					local hoverEnded_Conn: RBXScriptConnection = button.MouseLeave:Connect(function()
						playGuiSound(hoverSound, 0.85)
					end)
					table.insert(connections.Shop, hoverEnded_Conn)

					local activated_conn: RBXScriptConnection = button.Activated:Connect(function()
						playGuiSound(gamepassPromptClickSound, 1)

						-- print("Prompting gamepass: " .. gamepassID)
						local success, err = pcall(promptGamePassPurchase, player, gamepassID)
						if not success then
							warn("Error while trying to prompt gamepass purchase: " .. err)
						end
					end)
					table.insert(connections.Shop, activated_conn) --Add connection to table
				end
			end
		end)
		icons.Shop:bindEvent("deselected", function()
			-- print("Shop -DESELECTED-")

			for _, connection: RBXScriptConnection? in pairs(connections.Shop) do
				if connection and connection.Connected then
					connection:Disconnect()
					connection = nil
				end
			end --Disconnect all connections

			playGuiSound(topbarClickSound, 0.85)

			--Player variables
			local playerGui: StarterGui = player.PlayerGui

			local existing_ScreenGui = playerGui:FindFirstChild("Shop")
			if not existing_ScreenGui or not existing_ScreenGui:IsA("ScreenGui") then
				warn("No Settings found when deselecting.")
				return
			end --ensure existingGui exists
			existing_ScreenGui.Enabled = false

			--gui children variables
			--local main_Frame = existing_ScreenGui:FindFirstChild("MainFrame")
			--if not main_Frame or not main_Frame:IsA("Frame") then
			--	return
			--end

			--local page_Frame = main_Frame:FindFirstChild("PageFrame")
			--if not page_Frame or not page_Frame:IsA("Frame") then
			--	return
			--end

			--print("Shop Gui disabled")
		end)
	end)
	if not success then
		warn("Error while initializing Shop icon: " .. err)
	end
end
Init_ShopIcon()

local function Init_SkillsetsDropdownIcons()
	local success, err = pcall(function()
		local sun = Icon.new():setName("Sun"):setLabel("Sun"):setImage(2373819686)
		local moon = Icon.new():setName("Moon"):setLabel("Moon"):setImage(132049320741473)
		local ice = Icon.new():setName("Ice"):setLabel("Ice"):setImage(17771304663)
		local shockwave = Icon.new():setName("Shockwave"):setLabel("Shockwave"):setImage(137831468)

		icons.Skillsets:setDropdown({ sun, moon, ice, shockwave })

		--Bind events to the root icon
		icons.Skillsets:bindEvent("selected", function()
			playGuiSound(topbarClickSound, 1)
		end)
		icons.Skillsets:bindEvent("deselected", function()
			playGuiSound(topbarClickSound, 0.85)
		end)

		--Get necessary variables
		local remote = ReplicatedStorage.Remotes_Bindables.Remotes.GeneralPlayer.GiveMoveset :: RemoteEvent
		for _, icon in pairs(icons.Skillsets) do
			-- local icon = v.Value :: Instance?
			-- if not icon then
			-- 	if game:GetService("RunService"):IsStudio() then
			-- 		warn("Client - Icon instance is nil for icon: " .. icon.Name)
			-- 	end
			-- 	continue
			-- end

			icon:bindEvent("selected", function()
				playGuiSound(topbarClickSound, 1)
				local iconName = icon.Name
				if not iconName then
					if game:GetService("RunService"):IsStudio() then
						warn("Client - Icon name is nil")
					end
					return
				end
				remote:FireServer(icon.Name)
			end)
			icon:bindEvent("deselected", function()
				playGuiSound(topbarClickSound, 0.85)
			end)
		end
	end)
	if not success then
		warn("Error while initializing Skillsets dropdown icons: " .. err)
	end
end
Init_SkillsetsDropdownIcons()

--Shiftlock icon
local function Init_ShiftlockIcon()
	local success, err = pcall(function()
		if
			UserInputService.TouchEnabled
			and not UserInputService.KeyboardEnabled
			and not UserInputService.GamepadEnabled
		then
			icons.Shiftlock = Icon.new()
		else
			return
		end

		--Set properties of the icon
		icons.Shiftlock:setImage("rbxassetid://105987953182009"):setName("Shiftlock"):setCaption("Shiftlock")

		--Bind events to the icon
		icons.Shiftlock:bindEvent("selected", function()
			playGuiSound(topbarClickSound, 1)

			local character = player.Character
			if not character then
				return
			end

			local shiftlockToggle = character:WaitForChild("ShiftLockEnabled", 5) :: BoolValue
			if shiftlockToggle then
				shiftlockToggle.Value = true
			end
		end)
		icons.Shiftlock:bindEvent("deselected", function()
			playGuiSound(topbarClickSound, 0.85)

			local character = player.Character
			if not character then
				return
			end

			local shiftlockToggle = character:WaitForChild("ShiftLockEnabled", 5) :: BoolValue
			if shiftlockToggle then
				shiftlockToggle.Value = false
			end
		end)
	end)
	if not success then
		warn("Error while initializing Shiftlock icon: " .. err)
	end
end
Init_ShiftlockIcon()
