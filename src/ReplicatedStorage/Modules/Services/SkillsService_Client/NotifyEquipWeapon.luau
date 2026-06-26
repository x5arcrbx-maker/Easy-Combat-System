local NotifyEquipWeapon = {}


local UserInputService = game:GetService("UserInputService") :: UserInputService

function NotifyEquipWeapon:NotifyPlayer(player: Player, character: Model)
	local equipGuiText: string = ""
	
	if not character:GetAttribute("WeaponIsEquipped") then
		local NotifyToEquipWeapon_gui = script:WaitForChild("NotifyToEquipWeapon")
		if not NotifyToEquipWeapon_gui then
			return
		end

		local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
		local eventGuis = playerGui:WaitForChild("EventGUIs") :: Folder

		if eventGuis:FindFirstChild("NotifyToEquipWeapon") then
			return
		end--^ if gui already exists, exit function
		local gui_clone = NotifyToEquipWeapon_gui:Clone()
		gui_clone.Parent = eventGuis

		local tween_TIME = 0.2
		local gui_LIFETIME = 1 + (tween_TIME * 2)

		game:GetService("Debris"):AddItem(gui_clone, gui_LIFETIME)

		local frame = gui_clone:WaitForChild("MainFrame") :: Frame
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

		local tween = TweenService:Create(textLabel, tweenInfo, {TextTransparency = 0})
		local strokeTween = TweenService:Create(uiStroke, tweenInfo, {Transparency = 0})
		tween:Play()
		strokeTween:Play()

		task.delay(gui_LIFETIME - tween_TIME, function()
			local tweenOut = TweenService:Create(textLabel, tweenInfo, {TextTransparency = 1})
			local strokeOut = TweenService:Create(uiStroke, tweenInfo, {Transparency = 1})
			tweenOut:Play()
			strokeOut:Play()
		end)
	end
end

return NotifyEquipWeapon
