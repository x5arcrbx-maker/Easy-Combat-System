--!strict
--[[
	THIS SCRIPT WILL LOAD ALL GUIS FOR TOPBARPLUS, SET THEIR PROPERTIES, AND LOAD ANY ADDITIONAL GUIS.
	IT'S ALSO MEANT TO HANDLE ALL EVENTS FOR THE GUIS.
--]]
------------



--Getting player
local player = game:GetService("Players").LocalPlayer :: Player

--//:MODULES
local topbarPlus = require(game:GetService("ReplicatedStorage").Modules.Packages.topbarplus)

--//:VARIABLES
local icons = {
	Settings = topbarPlus.new(),
	Shiftlock = topbarPlus.new()
}
local connections: { [string]: {[string]: RBXScriptConnection?} } = {
	Sounds = {},
	VFX = {},
	Party = {},
	Keybinds = {},
}

local guiFolder: Folder? = script:WaitForChild("GUIs")
assert(guiFolder, "There is no GUIs folder in StarterPlayerScripts/" .. script.Name .. ".")

local clickSound: Sound? = script:WaitForChild("ClickSound")
assert(clickSound, "There is no ClickSound in StarterPlayerScripts/" .. script.Name .. ".")


--//:FUNCTIONS
local function checkExistenceAndTypes(
	instance: Instance?,
	path: Instance | string?,
	typeToCheck: string?
): boolean

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
			warn(
				"Instance type mismatch. Expected '" ..
					typeToCheck ..
					"', got '" ..
					instance.ClassName ..
					"'"
			)

			return false
		end
	end

	return true
end


--Settings icon
local function Init_SettingsIcon()
	
	icons.Settings:setImage("http://www.roblox.com/asset/?id=14134158045", "Viewing")
	icons.Settings:setImage("http://www.roblox.com/asset/?id=14134158045", "Selected")
	icons.Settings:setImage("http://www.roblox.com/asset/?id=14134158045", "Deselected")
	icons.Settings:setName("Settings")
	icons.Settings:setCaption("Settings")

	icons.Settings:bindEvent("selected", function()
		print("----------") --seperator for logs, easier reading
		print("Settings +SELECTED+")


		if not clickSound.IsPlaying then
			clickSound:Play()
		else
			clickSound:Stop()
			clickSound.TimePosition = 0
			clickSound:Play()
		end

		local player = game:GetService("Players").LocalPlayer
		if not player then return end
		local playerGui: StarterGui = player.PlayerGui

		local gui = guiFolder:FindFirstChild("SettingsGui")
		if not gui or not gui:IsA("ScreenGui") then return end
		
		local existingGui = playerGui:FindFirstChild(gui.Name)
		

		if existingGui and existingGui:IsA("ScreenGui") then
			gui = existingGui
			gui.Enabled = true
		else --If the gui was not already cloned and parented, clone and parent it to PlayerGui
			gui = gui:Clone()
			gui.Parent = playerGui
			gui.Enabled = true
			print("SettingsGui cloned and parented")
		end
		print("SettingsGui enabled")

		--Main frame
		local main_Frame = gui:FindFirstChild("MainFrame") :: Frame
		if not main_Frame then return end
		
		--Category frame
		local category_Frame = main_Frame:FindFirstChild("CategoryFrame") :: Frame
		if not category_Frame then return end

		--Category buttons
		local sounds_CategoryButton = category_Frame:FindFirstChild("Sounds") :: TextButton
		if not sounds_CategoryButton then return end
		
		local configure_Frame = sounds_CategoryButton:FindFirstChild("ConfigureFrame_" .. sounds_CategoryButton.Name) :: Frame?
		if not configure_Frame then
			configure_Frame = main_Frame:FindFirstChild("ConfigureFrame_" .. sounds_CategoryButton.Name) :: Frame?
		end
		if not configure_Frame then return end
		
		local musicVolume = configure_Frame:FindFirstChild("MusicVolume") :: Frame
		local footstepsVolume = configure_Frame:FindFirstChild("FootstepsVolume") :: Frame
		
		if not musicVolume then return end
		if not footstepsVolume then return end
		
		local musicVolume_textBox = musicVolume:FindFirstChild("TextBox") :: TextBox
		local footstepsVolume_textBox = footstepsVolume:FindFirstChild("TextBox") :: TextBox
		
		if not musicVolume
			or not footstepsVolume
			or not musicVolume_textBox
			or not footstepsVolume_textBox
		then return end


		--Connections
		local connection: RBXScriptConnection = sounds_CategoryButton.Activated:Connect(function()
			if not configure_Frame then return end
			if configure_Frame.Parent == main_Frame and configure_Frame.Visible then
				configure_Frame.Parent = sounds_CategoryButton
				configure_Frame.Visible = false
			else
				configure_Frame.Parent = main_Frame
				configure_Frame.Visible = true
			end
		end)
		connections.Sounds.Category = connection


		local musicVolumeConnection: RBXScriptConnection = musicVolume_textBox:GetPropertyChangedSignal("Text"):Connect(function()
			local number = tonumber(musicVolume_textBox.Text)
			if not number then return end

			number = math.clamp(number, 0, 10)
			musicVolume_textBox.Text = tostring(number)

			local music = game:GetService("SoundService"):FindFirstChild("Music") :: SoundGroup?
			if music then music.Volume = number end
		end)
		connections.Sounds.musicVolume_textBox = musicVolumeConnection

		local footstepsVolumeConnection: RBXScriptConnection = footstepsVolume_textBox:GetPropertyChangedSignal("Text"):Connect(function()
			local number = tonumber(musicVolume_textBox.Text)
			if not number then return end

			number = math.clamp(number, 0, 10)
			musicVolume_textBox.Text = tostring(number)

			local sounds = game:GetService("SoundService"):FindFirstChild("FootstepSounds") :: SoundGroup?
			if sounds then sounds.Volume = number end
		end)
		connections.Sounds.footstepsVolume_textBox = musicVolumeConnection
	end)
	icons.Settings:bindEvent("deselected", function()
		print("Settings -DESELECTED-")

		for _, connection in connections.Sounds do
			if connection then
				connection:Disconnect()
				connection = nil
			end
		end --Disconnect all connections


		if not clickSound.IsPlaying then
			clickSound:Play()
		else
			clickSound:Stop()
			clickSound.TimePosition = 0
			clickSound:Play()
		end --handle click sound

		--Player variables
		local player = game:GetService("Players").LocalPlayer
		if not player then return end
		local playerGui: StarterGui = player.PlayerGui

		local existing_ScreenGui = playerGui:FindFirstChild("SettingsGui")
		if not existing_ScreenGui or not existing_ScreenGui:IsA("ScreenGui") then
			warn("No SettingsGui found when deselecting.")
			return
		end --ensure existingGui exists
		existing_ScreenGui.Enabled = false

		--gui children variables
		local main_Frame = existing_ScreenGui:FindFirstChild("MainFrame")
		if not main_Frame or not main_Frame:IsA("Frame") then return end
		
		local category_Frame = main_Frame:FindFirstChild("CategoryFrame")
		if not category_Frame or not category_Frame:IsA("Frame") then return end
		
		local sounds_CategoryButton = category_Frame:FindFirstChild("Sounds")
		if not sounds_CategoryButton or not sounds_CategoryButton:IsA("TextButton") then return end
		
		local configure_Frame = main_Frame:FindFirstChild("ConfigureFrame_".. sounds_CategoryButton.Name)
		if not configure_Frame or not configure_Frame:IsA("Frame") then
			configure_Frame = sounds_CategoryButton:FindFirstChild("ConfigureFrame_".. sounds_CategoryButton.Name)
		end
		if not configure_Frame or not configure_Frame:IsA("Frame") then return end
		
		
		--handle configureFrame
		--if configure_Frame.Parent ~= main_Frame and not configure_Frame.Visible then
		--	configure_Frame.Parent = sounds_CategoryButton
		--	configure_Frame.Visible = false
		--end
		
		configure_Frame.Parent = sounds_CategoryButton
		configure_Frame.Visible = false

		print("SettingsGui disabled")
	end)
	
end
Init_SettingsIcon()


--Shiftlock icon
local function Init_ShiftlockIcon()
	
	--local smoothShiftlock = require(player.PlayerScripts.Extra["Customized ShiftLock"].SmoothShiftLock)

	icons.Shiftlock:setImage("http://www.roblox.com/asset/?id=105987953182009", "Viewing")
	icons.Shiftlock:setImage("http://www.roblox.com/asset/?id=105987953182009", "Selected")
	icons.Shiftlock:setImage("http://www.roblox.com/asset/?id=105987953182009", "Deselected")
	icons.Shiftlock:setName("Shiftlock")
	icons.Shiftlock:setCaption("Shiftlock")

	
	icons.Shiftlock:bindEvent("selected", function()
		local character = player.Character
		if not character then return end
		
		local shiftlockToggle = character:WaitForChild("ShiftLockEnabled") :: BoolValue
		shiftlockToggle.Value = true
	end)
	icons.Shiftlock:bindEvent("deselected", function()
		local character = player.Character
		if not character then return end

		local shiftlockToggle = character:WaitForChild("ShiftLockEnabled") :: BoolValue
		shiftlockToggle.Value = false
	end)
	
end
Init_ShiftlockIcon()

