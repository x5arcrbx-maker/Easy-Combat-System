local module = {}

function module:Init()
	--//:SERVICES
	local Lighting = game:GetService("Lighting")
	local TweenService = game:GetService("TweenService")

	--//:VARIABLES
	local dayLength: number = 5 * 60 -- minutes
	local betweenLength: number = .25 * 60 -- minutes
	local nightLength: number = 5 * 60 -- minutes

	--//:MAIN
	while true do --DAY/NIGHT cycle that replaces the sky and clouds
		--DAY--
		TweenService:Create(Lighting, TweenInfo.new(dayLength, Enum.EasingStyle.Linear), { ClockTime = 16 }):Play()
		task.wait(dayLength) --Tween to 16:00

		--Transition to night
		TweenService:Create(
			Lighting, 
			TweenInfo.new(betweenLength, Enum.EasingStyle.Linear), 
			{ ClockTime = 20, ExposureCompensation = 1 }
		):Play()
		task.wait(betweenLength) --Quick tween to 19:30 and increase ExposureCompensation

		--NIGHT--
		TweenService:Create(Lighting, TweenInfo.new(nightLength, Enum.EasingStyle.Linear), { ClockTime = 24.001 }):Play()
		task.wait(nightLength) --Tween to 24:001 (To prevent pausing midsky due to tweening to clocktime larger than max) and wait half the night length to play another tween

		--TweenService:Create(Lighting, TweenInfo.new(nightLength, Enum.EasingStyle.Linear), { ClockTime = 6.0 }):Play()
		--task.wait(nightLength / 2) --Tween to 6:00 and wait half of night length because we had to wait half the night duration to prevent a pause in the sky

		--Transition to day
		TweenService:Create(
			Lighting, 
			TweenInfo.new(betweenLength, Enum.EasingStyle.Linear), 
			{ ClockTime = 8.5, ExposureCompensation = 0 }
		):Play() --Quick tween to 08:30 and decrease ExposureCompensation

		task.wait(betweenLength)
	end

--[[
--while true do --REGULAR DAY/NIGHT cycle
--	--DAY
--	TweenService:Create(
--		Lighting, 
--		TweenInfo.new(dayLength, Enum.EasingStyle.Linear), 
--		{ClockTime = 17}
--	):Play()
--	task.wait(dayLength)

--	TweenService:Create(
--		Lighting, 
--		TweenInfo.new(betweenLength, Enum.EasingStyle.Linear), 
--		{ClockTime = 24}
--	):Play()
--	task.wait(betweenLength)

--	--NIGHT
--	TweenService:Create(
--		Lighting, 
--		TweenInfo.new(nightLength, Enum.EasingStyle.Linear), 
--		{ClockTime = 0}
--	):Play()
--	task.wait(nightLength)

--	TweenService:Create(
--		Lighting, 
--		TweenInfo.new(betweenLength, Enum.EasingStyle.Linear), 
--		{ClockTime = 7}
--	):Play()

--	task.wait(betweenLength)
--end
--]]

end

return module
