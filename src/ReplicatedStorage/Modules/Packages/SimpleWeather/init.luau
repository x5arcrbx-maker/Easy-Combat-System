--[[
Ｃｒｅｄｉｔｓ ａｒｅ ｎｏｔ ｒｅｑｕｉｒｅｄ, 　ｂｕｔ 　ｔｈｅｙ 　ａｒｅ 　ｇｒｅａｔｌｙ 　ａｐｐｒｅｃｉａｔｅｄ！ 　:)

    SimpleWeather Module by JordanGetMeBackmyAcc & sans_DAM

    Ｓｐｅｃｉａｌ 　ｔｈａｎｋｓ：
    	- buildthomas for the Rain System.
   		- sleitnick for the EZ Camera Shake Module.
]]

local SimpleWeather = {Weathers = {}}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")

local CurrentCamera = workspace.CurrentCamera
local Terrain = workspace.Terrain

local RainModule = require(script:WaitForChild("Rain"))
local CameraShaker = require(script:WaitForChild("CameraShaker")).new(Enum.RenderPriority.Camera.Value, function(shakeCF)
	CurrentCamera.CFrame = CurrentCamera.CFrame * shakeCF
end)

for _, weathers in pairs(script.Weathers.Lighting:GetChildren()) do
	local weatherName = weathers.Name
	local sky = script.Weathers.Skys:FindFirstChild(weatherName) or script.Weathers.Skys.Default
	
	SimpleWeather.Weathers[weatherName] = {
		Lighting = weathers,
		Sky = sky
	}
end

task.spawn(function()
	ContentProvider:PreloadAsync({script.Weathers.Skys})
end)

function ChangeWeather(weatherName)
	local data = SimpleWeather.Weathers[weatherName]
	if data then
		local LightingProperties : Folder = data.Lighting
		local Sky : Folder = data.Sky
		
		local tweenInfo = TweenInfo.new((script:GetAttribute("LightingTweenTime") or 0.4), Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
		local tweenInfo2 = TweenInfo.new((script:GetAttribute("TerrainTweenTime") or 1.5), Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
		
		if LightingProperties then
			if Lighting:FindFirstChildOfClass("Atmosphere") then
				if LightingProperties:FindFirstChild("AtmosphereDensity") then
					TweenService:Create(Lighting:FindFirstChildOfClass("Atmosphere"), tweenInfo, {Density = LightingProperties.AtmosphereDensity.Value}):Play()
				end
				if LightingProperties:FindFirstChild("AtmosphereOffset") then
					TweenService:Create(Lighting:FindFirstChildOfClass("Atmosphere"), tweenInfo, {Offset = LightingProperties.AtmosphereOffset.Value}):Play()
				end
				if LightingProperties:FindFirstChild("AtmosphereColor") then
					TweenService:Create(Lighting:FindFirstChildOfClass("Atmosphere"), tweenInfo, {Color = LightingProperties.AtmosphereColor.Value}):Play()
				else
					TweenService:Create(Lighting:FindFirstChildOfClass("Atmosphere"), tweenInfo, {Color = Color3.fromRGB(199, 170, 107)}):Play()
				end
				if LightingProperties:FindFirstChild("AtmosphereDecay") then
					TweenService:Create(Lighting:FindFirstChildOfClass("Atmosphere"), tweenInfo, {Decay = LightingProperties.AtmosphereDecay.Value}):Play()
				else
					TweenService:Create(Lighting:FindFirstChildOfClass("Atmosphere"), tweenInfo, {Decay =  Color3.fromRGB(92, 60, 13)}):Play()
				end
				if LightingProperties:FindFirstChild("AtmosphereGlare") then
					TweenService:Create(Lighting:FindFirstChildOfClass("Atmosphere"), tweenInfo, {Glare = LightingProperties.AtmosphereGlare.Value}):Play()
				else
					TweenService:Create(Lighting:FindFirstChildOfClass("Atmosphere"), tweenInfo, {Glare = 0}):Play()
				end
				if LightingProperties:FindFirstChild("AtmosphereHaze") then
					TweenService:Create(Lighting:FindFirstChildOfClass("Atmosphere"), tweenInfo, {Haze = LightingProperties.AtmosphereHaze.Value}):Play()
				else
					TweenService:Create(Lighting:FindFirstChildOfClass("Atmosphere"), tweenInfo, {Haze = 0}):Play()
				end
			end
			
			if Terrain:FindFirstChildOfClass("Clouds") then
				if LightingProperties:FindFirstChild("CloudsCover") then
					TweenService:Create(Terrain:FindFirstChildOfClass("Clouds"), tweenInfo2, {Cover = LightingProperties.CloudsCover.Value}):Play()
				end
				if LightingProperties:FindFirstChild("CloudsDensity") then
					TweenService:Create(Terrain:FindFirstChildOfClass("Clouds"), tweenInfo2, {Density = LightingProperties.CloudsDensity.Value}):Play()
				end
			end
			
			if LightingProperties:FindFirstChild("GrassDirection") then
				TweenService:Create(workspace, tweenInfo2, {GlobalWind = LightingProperties.GrassDirection.Value}):Play()
			end
			
			if LightingProperties:FindFirstChild("WaterWaveSize") then
				TweenService:Create(Terrain, tweenInfo2, {WaterWaveSize = LightingProperties.WaterWaveSize.Value}):Play()
			end

			if LightingProperties:FindFirstChild("WaterWaveSpeed") then
				TweenService:Create(Terrain, tweenInfo2, {WaterWaveSpeed = LightingProperties.WaterWaveSpeed.Value}):Play()
			end
			
			if LightingProperties:FindFirstChild("Rains") then
				ReplicatedStorage:SetAttribute("Rain", LightingProperties.Rains.Value)
			else
				ReplicatedStorage:SetAttribute("Rain", false)
			end
			
			if LightingProperties:FindFirstChild("Fog") then
				ReplicatedStorage:SetAttribute("Fog", LightingProperties.Fog.Value)
			else
				ReplicatedStorage:SetAttribute("Fog", false)
			end
			
			if LightingProperties:FindFirstChild("Snow") then
				ReplicatedStorage:SetAttribute("Snow", LightingProperties.Snow.Value)
			else
				ReplicatedStorage:SetAttribute("Snow", false)
			end
			
			if LightingProperties:FindFirstChild("Thunderstorm") then
				ReplicatedStorage:SetAttribute("Thunderstorm", LightingProperties.Thunderstorm.Value)
			end
			
			for _, properties in pairs(LightingProperties:GetChildren()) do
				pcall(function()
					local targetProperty = game.Lighting[properties.Name]
					local targetValue = properties

					if targetValue:IsA("Color3Value") then
						targetValue = Color3.fromRGB(targetValue.Value.R, targetValue.Value.G, targetValue.Value.B)
					elseif targetValue:IsA("NumberValue") then
						targetValue = tonumber(targetValue.Value)
					elseif targetValue:IsA("BoolValue") then
						targetValue = tostring(targetValue.Value) == "true"
					end

					local tween = TweenService:Create(Lighting, tweenInfo, { [properties.Name] = targetValue})
					tween:Play()
				end)
			end
		end
		
		if Sky then
			if Lighting:FindFirstChildOfClass("Sky") then
				Lighting:FindFirstChildOfClass("Sky"):Destroy()
			end
			Sky.Sky:Clone().Parent = Lighting
		end
	end
end

function SimpleWeather:Start()
	if not self.Started then
		self.Started = true
		
		self.Fog = script:WaitForChild("Assets").Fog:Clone()
		self.Snow = script:WaitForChild("Assets").Snow:Clone()
		
		self.Fog.Parent = CurrentCamera
		self.Snow.Parent = CurrentCamera
		
		self.State = {
			RainEnabled = false
		}
		
		CameraShaker:Start()
		RainModule:SetCollisionMode(RainModule.CollisionMode.Blacklist, self.Fog)
		RainModule:SetCollisionMode(RainModule.CollisionMode.Blacklist, self.Snow)
		
		RainModule:SetCollisionMode(
			RainModule.CollisionMode.Function,
			function(p)
				return p.Transparency <= 1 and p.CanCollide and not p:IsA("MeshPart")
			end
		)
		
		self.Signals = {}
		
		if not ReplicatedStorage:GetAttribute("CurrentWeather") then
			ReplicatedStorage:SetAttribute("CurrentWeather", "Default")
		end
		
		if not ReplicatedStorage:GetAttribute("OverrideWeather") then
			ChangeWeather(ReplicatedStorage:GetAttribute("CurrentWeather"))
		else
			ChangeWeather(ReplicatedStorage:GetAttribute("OverrideWeather"))
		end
				
		self.Signals.Signal1 = ReplicatedStorage:GetAttributeChangedSignal("CurrentWeather"):Connect(function()
			if not ReplicatedStorage:GetAttribute("OverrideWeather") then
				ChangeWeather(ReplicatedStorage:GetAttribute("CurrentWeather"))
			end
		end)

		self.Signals.Signal2 = ReplicatedStorage:GetAttributeChangedSignal("OverrideWeather"):Connect(function()
			if ReplicatedStorage:GetAttribute("OverrideWeather") then
				ChangeWeather(ReplicatedStorage:GetAttribute("OverrideWeather"))
			else
				ChangeWeather(ReplicatedStorage:GetAttribute("CurrentWeather"))
			end
		end)
		
		self.Signals.Signal3 = RunService.RenderStepped:Connect(function()
			self.Fog.CFrame = CurrentCamera.CFrame
			self.Snow.CFrame = CurrentCamera.CFrame
			
			if ReplicatedStorage:GetAttribute("Fog") then
				self.Fog.ParticleEmitter.Enabled = true
			else
				self.Fog.ParticleEmitter.Enabled = false
			end
			
			if ReplicatedStorage:GetAttribute("Snow") then
				self.Snow.ParticleEmitter.Enabled = true
			else
				self.Snow.ParticleEmitter.Enabled = false
			end
			
			if ReplicatedStorage:GetAttribute("Rain") then
				if not self.State.RainEnabled then
					self.State.RainEnabled = true
					RainModule:Enable(TweenInfo.new(script:GetAttribute("RainTweenTime") or 1))
				end
			else
				if self.State.RainEnabled then
					self.State.RainEnabled = false
					RainModule:Disable(TweenInfo.new(script:GetAttribute("RainTweenTime") or 1))
				end
			end
		end)
		
		self.Signals.Signal4 = task.spawn(function()
			while true do
				--task.wait(math.random(60, 90))
				task.wait(math.random(10, 70))
				if ReplicatedStorage:GetAttribute("Thunderstorm") then
					local player = game:GetService("Players").LocalPlayer
					local character = player.Character or player.CharacterAdded:Wait()
					local hrp = character:WaitForChild("HumanoidRootPart")

					local offset = Vector3.new(math.random(-90, 90), 0, math.random(-90, 90))
					local rayOrigin = hrp.Position + offset + Vector3.new(0, 100, 0)
					local rayDirection = Vector3.new(0, -200, 0)

					local rayResult = workspace:Raycast(rayOrigin, rayDirection)
					if rayResult then
						local lightning = script.Assets.Lightning:Clone()
						lightning.Parent = workspace

						local heightOffset = lightning.Size.Y / 2
						lightning.CFrame = CFrame.new(rayResult.Position + Vector3.new(0, heightOffset, 0))

						local debrisAttach = lightning:FindFirstChild("DebrisBlock", true)
						if debrisAttach and debrisAttach:IsA("Attachment") then
							local debrisParent = debrisAttach.Parent
							if debrisParent and debrisParent:IsA("BasePart") then
								debrisParent.Position = rayResult.Position + Vector3.new(0, 0.1, 0)
								debrisParent.Anchored = true

								local debrisEmitter = debrisAttach:FindFirstChildOfClass("ParticleEmitter")
								if debrisEmitter then
									debrisEmitter:Emit(50)
									if rayResult.Instance:IsA("BasePart") then
										debrisEmitter.Color = ColorSequence.new(rayResult.Instance.Color)
									elseif rayResult.Instance:IsA("Terrain") then
										debrisEmitter.Color = ColorSequence.new(Terrain:GetMaterialColor(rayResult.Material))
									end
								end
							end
						end

						CameraShaker:ShakeOnce(2, 0.6, 0.1, 0.3, Vector3.new(0, 0, 0), Vector3.new(0, 0, 0))
						
						--Randomize which sound will play, alongside a random speed, and play it.
						local soundsFolder = lightning:FindFirstChild("Sounds") :: Folder
						if soundsFolder then
							local sounds = soundsFolder:GetChildren()
							if #sounds > 0 then
								local randomSound = sounds[math.random(1, #sounds)]
								if randomSound:IsA("Sound") then
									local randomPlaybackSpeed = math.random(80, 120) / 100
									randomSound.PlaybackSpeed = randomPlaybackSpeed
									randomSound:Play()
									Debris:AddItem(randomSound, randomSound.TimeLength + 1)
								end
							end
						end
			
						for _, particleEmitter in pairs(lightning:GetChildren()) do
							if particleEmitter:IsA("ParticleEmitter") then
								particleEmitter.Enabled = true
								task.delay(.5, function()
									particleEmitter.Enabled = false
								end)
							end
						end
					end
				end

			end
		end)
	end
end

function SimpleWeather:Stop()
	if self.Started then
		CameraShaker:Stop()
		RainModule:Disable(TweenInfo.new(script:GetAttribute("RainTweenTime") or 1))
		for _, signals in pairs(self.Signals) do
			if typeof(signals) ~= "thread" then
				signals:Disconnect()
			else
				task.cancel(signals)
			end
		end
	end
end

return SimpleWeather