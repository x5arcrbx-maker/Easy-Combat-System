--//:SERVICES
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService 		= game:GetService("TweenService")
local Players 			= game:GetService("Players")

--//:VARIABLES
local firedFor = {} --Prevent touched event rapid firing
local touchingParts = {} --Track which parts are touching each zone for each player
local lightingRemote = ReplicatedStorage.Remotes_Bindables.Remotes.GeneralPlayer.ZoneLighting

--Zone function (using "Zone" tag)
local zones = CollectionService:GetTagged("Zone")
for _, zone in pairs(zones) do
	--print("Found zone:", zone.Name) --Debug print
	zone.Touched:Connect(function(hit) --TOUCHED EVENT
		--print("Touched fired!") --Debug print
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end
		--print("Player found:", player.Name) --Debug print
		
		-- Initialize tracking for this player and zone
		if not touchingParts[player.UserId] then
			touchingParts[player.UserId] = {}
		end
		if not touchingParts[player.UserId][zone] then
			touchingParts[player.UserId][zone] = {}
		end
		
		-- Track this part as touching
		touchingParts[player.UserId][zone][hit] = true
		
		-- Only trigger zone enter if this is the first part touching
		if firedFor[player.UserId] then
			return
		else
			firedFor[player.UserId] = true
		end
		--//:VARIABLES
		local zoneGui = player.PlayerGui:FindFirstChild("Zone Text", true)
		--GUI Variables
		local mainText = zoneGui:WaitForChild("MainText")
		local descriptionText = zoneGui:WaitForChild("DescriptionText")
		--Set Text
		mainText.Text = zone.MainTextString.Value
		descriptionText.Text = zone.DescriptionTextString.Value
		--Tweening text
		local function tweenText(object: Instance, info: TweenInfo, properties: any)
			local tweenVisible = TweenService:Create(object, info, properties)
			tweenVisible:Play()
			tweenVisible.Completed:Once(function() --> After tween completed
				task.delay(3, function() --Wait 3 seconds before tweening out
					local tweenInvisible = TweenService:Create(object, info, { TextTransparency = 1 })
					tweenInvisible:Play()
				end)
			end)
		end

		tweenText(
			mainText, 
			TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
			{ TextTransparency = 0 }
		)
		tweenText(
			descriptionText,
			TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ TextTransparency = 0 }
		)

		--Changing lighting
		if zone:GetAttribute("ZoneLighting") then
			lightingRemote:FireClient(player, zone.Name)
		end
	end)

	zone.TouchEnded:Connect(function(hit) --TOUCH ENDED EVENT
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end
		
		-- Remove this part from tracking
		if touchingParts[player.UserId] and touchingParts[player.UserId][zone] then
			touchingParts[player.UserId][zone][hit] = nil
		end
		
		-- Only trigger zone leave if NO parts are still touching
		if touchingParts[player.UserId] and touchingParts[player.UserId][zone] then
			local hasTouchingParts = false
			for _ in pairs(touchingParts[player.UserId][zone]) do
				hasTouchingParts = true
				break
			end
			
			if not hasTouchingParts then
				--print("Player left zone:", player.Name) --Debug print
				if zone:GetAttribute("ZoneLighting") then
					lightingRemote:FireClient(player, "DEFAULT") --Reset lighting to default
				end
				firedFor[player.UserId] = nil --Reset firedFor for this player
				touchingParts[player.UserId][zone] = nil
			end
		end
	end)
end
