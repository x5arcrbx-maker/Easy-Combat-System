local BreathingHandler = {}

--Breathing functions--
function BreathingHandler:SubtractBreathingBar(breathing_AMOUNT: number, breathing_NEEDED: number, character: Model)
	character:SetAttribute("BreathingBar", breathing_AMOUNT - breathing_NEEDED)
end

--Checks if player has enough breathing to use a skill
function BreathingHandler:CheckBreathingBar(breathing_NEEDED: number, character: Model): (boolean, number)
	local breathing_AMOUNT: number = character:GetAttribute("BreathingBar")
	if not breathing_AMOUNT then
		return false, 0
	end
	if breathing_AMOUNT < breathing_NEEDED then
		return false, 0
	end

	return true, breathing_AMOUNT
end

return BreathingHandler
