--//:SERVICES
local UserInputService = game:GetService("UserInputService") :: UserInputService

--//:HELPER FUNCTIONS
local function createNotificationGui(player: Player, name: string): ScreenGui?
	if not player then
		warn("NotificationService:NotifyPlayer - Player is nil")
		return nil
	end
	if not name then
		warn("NotificationService:NotifyPlayer - Notification name is nil")
		return nil
	end

	local gui = script:WaitForChild("NotificationGui")
	if not gui then
		return nil
	end

	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
	local eventGuis = playerGui:WaitForChild("EventGUIs") :: Folder

	if eventGuis:FindFirstChild(name) then
		return nil
	end --^ if gui already exists, exit function
	local gui_clone = gui:Clone()
	gui_clone.Name = name
	gui_clone.Parent = eventGuis
	return gui_clone
end

--//:VARIABLES
local notificationFunctions = {
	["EquipWeapon"] = function(player: Player, character: Model)
		local equipGuiText: string = ""

		if not character:GetAttribute("WeaponIsEquipped") then
			local gui = createNotificationGui(player, "NotificationGui_EquipWeapon") :: ScreenGui?
			if not gui then
				warn("NotificationService:NotifyPlayer - Failed to create notification GUI")
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

		local gui = createNotificationGui(player, "NotificationGui_ChangeMovesetOnCooldown") :: ScreenGui?
		if not gui then
			--warn("NotificationService:NotifyPlayer - Failed to create notification GUI")
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

--//:MAIN
local NotificationService = {}

function NotificationService:NotifyPlayer(player: Player, character: Model, notificationType: string): boolean
	local success, err = pcall(function()
		if not player or not character then
			warn("NotificationService:NotifyPlayer - Player or Character is nil")
			return false
		end
		if not notificationType then
			warn("NotificationService:NotifyPlayer - Notification type is nil")
			return false
		end

		local notificationFunction = notificationFunctions[notificationType]
		if notificationFunction then
			notificationFunction(player, character)
			return true
		else
			warn("NotificationService:NotifyPlayer - Invalid notification type: " .. tostring(notificationType))
			return false
		end
	end)
	if not success then
		warn("NotificationService:NotifyPlayer - Error: " .. err)
		return false
	else
		return true
	end
end

return NotificationService
