--//:SERVICES//
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting 			= game:GetService("Lighting")
local Players			= game:GetService("Players")
local TweenService 		= game:GetService("TweenService")


--//:REFERENCES
local Zone_Lighting = ReplicatedStorage.Zones.Lighting :: Folder
local Zone_SFX 		= ReplicatedStorage.Zones.Music :: Folder
local lightingRemote = ReplicatedStorage.Remotes_Bindables.Remotes.GeneralPlayer.ZoneLighting :: UnreliableRemoteEvent 

local player = Players.LocalPlayer





--//:FUNCTIONS


--Handle lighting
local function setLighting(zoneFolder_Lighting: Folder)
	for _, property in Lighting:GetChildren() do --Iterate through Lighting properties
		if zoneFolder_Lighting:FindFirstChild(property.Name) then
			property:Destroy()
			local newProperty = zoneFolder_Lighting:FindFirstChild(property.Name):Clone()
			newProperty.Parent = Lighting
		end
	end
	for _, property in workspace.Terrain:GetChildren() do --Iterate through Terrain properties
		if zoneFolder_Lighting:FindFirstChild(property.Name) then
			TweenService:Create(
				property, 
				TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), 
				{
					Cover = zoneFolder_Lighting.Clouds.Cover.Value,
					Density = zoneFolder_Lighting.Clouds.Density.Value,
				}
			):Play()
		end
	end
end

--Handle sounds
local function setSounds(zoneFolder_SFX: Folder)
	for _, sfx: Sound in pairs(player.PlayerGui:GetChildren()) do
		if sfx:IsA("Sound") then
			sfx:Destroy()
		end
	end --Remove all sounds

	if zoneFolder_SFX then
		local sound = zoneFolder_SFX:FindFirstChildOfClass("Sound")
		if sound then
			local cloneSound = sound:Clone()
			cloneSound.Parent = player.PlayerGui
			cloneSound.Looped = true
			cloneSound:Play()
		end
	end
end

--Resets lighting on character added to ensure lighting doesn't transfer when dying in another biome.
local function resetLighting_OnCharacterAdded()
	local zoneName: string = "DEFAULT"
	
	--Lighting
	local zoneFolder_Lighting = Zone_Lighting:FindFirstChild(zoneName) :: Folder
	if zoneFolder_Lighting then	
		setLighting(zoneFolder_Lighting)
	end

	--Sounds
	local zoneFolder_SFX = Zone_SFX:FindFirstChild(zoneName) :: Folder
	if zoneFolder_SFX then 
		setSounds(zoneFolder_SFX)
	end
end


--//:EVENTS
if player.Character then resetLighting_OnCharacterAdded() end
player.CharacterAdded:Connect(resetLighting_OnCharacterAdded)


--//:MAIN
lightingRemote.OnClientEvent:Connect(function(zoneName: string)
	
	--Lighting
	local zoneFolder_Lighting = Zone_Lighting:FindFirstChild(zoneName) :: Folder
	if not zoneFolder_Lighting then	return end
	setLighting(zoneFolder_Lighting)
	
	
	--Sounds
	local zoneFolder_SFX = Zone_SFX:FindFirstChild(zoneName) :: Folder
	if not zoneFolder_SFX then return end
	setSounds(zoneFolder_SFX)
	
end)

--Initialize
setLighting(Zone_Lighting.DEFAULT)
setSounds(Zone_SFX.DEFAULT)
print("Zones_Local initialized")