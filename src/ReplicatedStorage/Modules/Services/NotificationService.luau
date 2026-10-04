--//:SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage") :: ReplicatedStorage
local UserInputService = game:GetService("UserInputService") :: UserInputService

--//:VARIABLES
local UIfolder = ReplicatedStorage:WaitForChild("UI") :: Folder

--//:HELPER FUNCTIONS
local function createNotificationGui(player: Player, name: string): (ScreenGui?, string?)
	--Sanity checks for player and name parameters.
	if not player then
		warn("NotificationService:NotifyPlayer - Player is nil")
		return nil, "Player is nil"
	end
	if not name then
		warn("NotificationService:NotifyPlayer - Notification name is nil")
		return nil, "Notification name is nil"
	end

	local gui = UIfolder:FindFirstChild("NotificationGui") --Find the NotificationGui in UIfolder.
	if not gui then
		warn("NotificationService:NotifyPlayer - NotificationGui not found in ReplicatedStorage.UI")
		return nil, "NotificationGui not found"
	end
	--Get the player's PlayerGui to find a folder within it.
	local playerGui = player:FindFirstChild("PlayerGui") :: PlayerGui
	if not playerGui then
		warn("NotificationService:NotifyPlayer - PlayerGui not found for player")
		return nil, "PlayerGui not found"
	end
	--Folder to hold all event GUIs for the player.
	--	This is to organize Gui based on their category
	--	(e.g., event-based, startercharacter, etc.)
	local eventGuis = playerGui:FindFirstChild("EventGUIs") :: Folder
	if not eventGuis then
		eventGuis = Instance.new("Folder")
		eventGuis.Name = "EventGUIs"
		eventGuis.Parent = playerGui
	end

	if eventGuis:FindFirstChild(name) then --If gui already exists in eventGuis, exit function.
		return nil, "Notification GUI already exists"
	end
	local gui_clone = gui:Clone()
	gui_clone.Name = name
	gui_clone.Parent = eventGuis
	return gui_clone, nil
	--^	Return gui_clone so the calling function can manipulate it (e.g. change text, tween, etc.)
end

local function formatErrorMsg_createNotificationGui(errMessage: string): string
	return string.format(
		"NotificationService:NotifyPlayer - Failed to create notification GUI: %s",
		errMessage or "Unknown error"
	)
end

--//:TABLES
local notificationFunctions = {
	["EquipWeapon"] = function(player: Player, character: Model)
		local equipGuiText: string = ""

		if not character:GetAttribute("WeaponIsEquipped") then
			local gui: ScreenGui?, errMessage: string? = createNotificationGui(player, "NotificationGui_EquipWeapon")
			if not gui then
				warn(formatErrorMsg_createNotificationGui(errMessage))
				return
			end

			local tween_TIME = 0.2
			local gui_LIFETIME = 1 + (tween_TIME * 2)

			game:GetService("Debris"):AddItem(gui, gui_LIFETIME)

			local frame = gui:WaitForChild("MainFrame") :: Frame
			local textLabel = frame:WaitForChild("TextLabel") :: TextLabel
			local uiStroke = textLabel:WaitForChild("UIStroke") :: UIStroke

			textLabel.TextTransparency = 1
			uiStroke.Transparency = 1

			if UserInputService.KeyboardEnabled then
				equipGuiText = "Press [E] to equip weapon."
			elseif UserInputService.GamepadEnabled then
				equipGuiText = "Press [Button X] to equip weapon."
			elseif UserInputService.TouchEnabled then
				equipGuiText = "Tap the [Equip] button to equip weapon."
			end
			textLabel.Text = equipGuiText

			local TweenService = game:GetService("TweenService")
			local tweenInfo = TweenInfo.new(tween_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

			local tween = TweenService:Create(textLabel, tweenInfo, { TextTransparency = 0 })
			local strokeTween = TweenService:Create(uiStroke, tweenInfo, { Transparency = 0 })
			tween:Play()
			strokeTween:Play()

			task.delay(gui_LIFETIME - tween_TIME, function()
				local tweenOut = TweenService:Create(textLabel, tweenInfo, { TextTransparency = 1 })
				local strokeOut = TweenService:Create(uiStroke, tweenInfo, { Transparency = 1 })
				tweenOut:Play()
				strokeOut:Play()
			end)
		end
	end,

	["ChangeMovesetOnCooldown"] = function(player: Player, character: Model)
		if not character then
			warn("NotificationService:NotifyPlayer - Character is nil")
			return
		end

		local gui: ScreenGui?, errMessage: string? =
			createNotificationGui(player, "NotificationGui_ChangeMovesetOnCooldown")
		if not gui then
			warn(formatErrorMsg_createNotificationGui(errMessage))
			return
		end

		local tween_TIME = 0.2
		local gui_LIFETIME = 1 + (tween_TIME * 2)

		game:GetService("Debris"):AddItem(gui, gui_LIFETIME)

		local frame = gui:WaitForChild("MainFrame") :: Frame
		local textLabel = frame:WaitForChild("TextLabel") :: TextLabel
		local uiStroke = textLabel:WaitForChild("UIStroke") :: UIStroke

		textLabel.TextTransparency = 1
		uiStroke.Transparency = 1

		local movesetChangeCooldown = math.round(character:GetAttribute("MovesetChangeCooldown") or 0)
		textLabel.Text = ("Moveset change on cooldown (" .. tostring(movesetChangeCooldown) .. "s remaining)")

		local TweenService = game:GetService("TweenService")
		local tweenInfo = TweenInfo.new(tween_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		local tween = TweenService:Create(textLabel, tweenInfo, { TextTransparency = 0 })
		local strokeTween = TweenService:Create(uiStroke, tweenInfo, { Transparency = 0 })
		tween:Play()
		strokeTween:Play()

		task.delay(gui_LIFETIME - tween_TIME, function()
			local tweenOut = TweenService:Create(textLabel, tweenInfo, { TextTransparency = 1 })
			local strokeOut = TweenService:Create(uiStroke, tweenInfo, { Transparency = 1 })
			tweenOut:Play()
			strokeOut:Play()
		end)
	end,
}
--^ Holds all notification functions for each notification type.
--	  Each function takes a player and character as parameters.

--//:MAIN
local NotificationService = {} --module

function NotificationService:NotifyPlayer(player: Player, character: Model, notificationType: string): boolean
	--Use pcall to catch any errors that may occur during the notification process.
	local success, err = pcall(function()
		--Sanity checks for player, character, and notificationType parameters.
		if not player then
			warn("NotificationService:NotifyPlayer - (player: Player) is nil")
			return false
		elseif not character then
			warn("NotificationService:NotifyPlayer - (character: Model) is nil")
			return false
		elseif not notificationType then
			warn("NotificationService:NotifyPlayer - (notificationType: string) is nil")
			return false
		end

		--Find the appropriate notification function based on the notificationType parameter.
		local notificationFunction = notificationFunctions[notificationType]
		if notificationFunction then
			notificationFunction(player, character)
			return true
		else
			warn("NotificationService:NotifyPlayer - Invalid notification type: " .. tostring(notificationType))
			return false
		end
	end)

	if not success then --pcall failed, log the error and return false.
		warn("NotificationService:NotifyPlayer - Error: " .. err)
		return false
	else --pcall succeeded, return true.
		return true
	end
end

return NotificationService
