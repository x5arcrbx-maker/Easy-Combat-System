

--//:SERVICES//
local UserInputService     = game:GetService("UserInputService")
local Players 			   = game:GetService("Players")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local Debris 			   = game:GetService("Debris")
local ContextActionService = game:GetService("ContextActionService")
local RunService 		   = game:GetService("RunService")
local TweenService 		   = game:GetService("TweenService")
local CollectionService    = game:GetService("CollectionService")


--//:VARIABLES//
local player = Players.LocalPlayer :: Player
local char   = player.Character or player.CharacterAdded:Wait() :: Model 		 
local hrp = char:WaitForChild("HumanoidRootPart") :: BasePart 	 
local hum = char:WaitForChild("Humanoid") :: Humanoid		 
local animator = hum:WaitForChild("Animator") :: Animator 
local Camera = workspace.CurrentCamera :: Camera


--//:MODULES//
local actionsMap = require(script.ActionsMap)







--//:MAIN//
local module = {}

function module:Init()
	-- Non-PVP --
	local function Enable_NonPVP()
		local function sprint()

			--REMOTES
			local movementChangeEvent: RemoteEvent = ReplicatedStorage.Remotes_Bindables.Remotes.GeneralPlayer.RequestMovementChange


			--VARIABLES
			local PREVENTION_ATTRIBUTES: {string} = {
				"Ragdolled",
				"TrueStunned",
				"Stunned",
				"Blocking",
				"Slowed",
				"UsingAttack"
			}
			local keybinds = actionsMap.Sprint
			
			local connection: RBXScriptConnection
			
			local sprinting: boolean = false
			
			local pressTimeThreshold: number = 0.175
			local lastPressedTime: number = 0


			--FUNCTIONS
			
			--Begin character sprinting
			local function beginSprint()
				if not char:GetAttribute("IsSprinting") or not sprinting then
					movementChangeEvent:FireServer("Sprint", true)
					sprinting = true
				end
			end
			
			--Stop character sprinting
			local function endSprint()
				movementChangeEvent:FireServer("Sprint", false)
				sprinting = false
				--[[
				if char:GetAttribute("IsSprinting") or sprinting then
					movementChangeEvent:FireServer("Sprint", false)
					sprinting = false
				end
				]]
			end
			
			--Will decide whether to beginSprint or endSprint (depending on toggleSprint)
			local function trySprint(toggleSprint: boolean)
				--Attribute prevention
				for _, attribute in pairs(PREVENTION_ATTRIBUTES) do
					if char:GetAttribute(attribute) then 
						endSprint() 
						return
					end
				end
				
				if toggleSprint then beginSprint() else endSprint() end
			end

			--Prevents character from sprinting backwards or looking backwards while sprinting
			local function trackMoveDirectionChange()
				
				connection = RunService.Heartbeat:Connect(function()
					local moveDir: Vector3 = hum.MoveDirection
					local lookDir_Camera: Vector3 = Camera.CFrame.LookVector
					local lookDir_Hrp: Vector3 = hrp.CFrame.LookVector
					
					
					----Conditions to end sprint
					--local angleBetweenLookDirections: number = math.acos(lookDir_Camera:Dot(lookDir_Hrp) / (lookDir_Camera.Magnitude * lookDir_Hrp.Magnitude))
					--if angleBetweenLookDirections > math.rad(120) then 
					--	endSprint() 
					--end
					
					if moveDir.Magnitude > 0 then
						local dot: number = moveDir:Dot(lookDir_Hrp)
						if dot < 0 then  --moving backwards
							endSprint() 
						end --^ Checks move direction, and if not (to some extent) forward, then cancel sprint
					end
				end)
				
				--Disconnects the connection when the character dies
				char.Humanoid.Died:Once(function()
					connection:Disconnect()
				end) --End connection
				
			end
			player.CharacterAdded:Connect(trackMoveDirectionChange)
			if char then trackMoveDirectionChange() end
			
			
			--Track PREVENTION_ATTRIBUTES
			for _, attribute in pairs(PREVENTION_ATTRIBUTES) do
			
				char:GetAttributeChangedSignal(attribute):Connect(function()
					if char:GetAttribute(attribute) then
						movementChangeEvent:FireServer("Sprint", false)
						sprinting = false
					end
				end)
				
			end --End for


			--EVENTS
			UserInputService.InputBegan:Connect(function(input, GPE)
				if GPE then return end 
				if input.KeyCode ~= keybinds.Keyboard and input.KeyCode ~= keybinds.Console then return end
				
						
				if input.KeyCode == keybinds.Keyboard then
					if lastPressedTime > (tick() - pressTimeThreshold) then --Double pressed within threshold time

						--Keyboard and Console have different double-tap sprint systems.
						--When keyboard doubletaps, on InputBegan it simply tries to sprint.
						--When Console doubletaps, it checks if the player is already sprinting, and if so, will stop sprinting, otherwise begin sprinting.
						--This system is based off the Minecraft sprint system.

						if input.KeyCode == keybinds.Keyboard then
							trySprint(true)
					--[[
					elseif input.KeyCode == keybinds.Console then
					if char:GetAttribute("IsSprinting") and sprinting then
						trySprint(false)
					else
						trySprint(true)
					end
					]]
						end
					end
				elseif input.KeyCode == keybinds.Console then
					if not sprinting then
						trySprint(true) --Begin sprinting
					else
						trySprint(false) --End sprint
					end
				end
			
			end)
			
			UserInputService.InputEnded:Connect(function(input, GPE)
				if GPE then return end 
				if input.KeyCode ~= keybinds.Keyboard and input.KeyCode ~= keybinds.Console then return end
				
				
				lastPressedTime = tick() --Single press
				if input.KeyCode == keybinds.Keyboard then
					trySprint(false) --End sprint because input ended
				end
			end)


			--Binding and customizing action
			ContextActionService:BindAction("Sprint", trySprint, true)
			ContextActionService:SetTitle("Sprint", "Sprint")
			ContextActionService:SetPosition("Sprint", UDim2.new(0.273, 0,   0.515, 0))  

		end
		sprint()

		local function dash()

			--REMOTES
			local mainRemote: RemoteEvent 	 	   = ReplicatedStorage.Remotes_Bindables.Remotes.GeneralPlayer.Flashstep
			local VfxRemote: UnreliableRemoteEvent = mainRemote.FlashstepVFX

			--VARIABLES
			local PREVENTION_ATTRIBUTES = {
				"Gripped",
				"Carried",
				"Knocked",
				"Ragdolled",
				"TrueStunned",
				"Stunned",
				"Blocking",
				"Slowed",
				"UsingAttack",
				"DashOnCooldown",
			}
			local keybinds = actionsMap.Dash

			local DURATION: number = ReplicatedStorage.Values.Movement.Dash.Duration.Value
			local zoomedOutFOV: number = 90
			local defaultFOV: number   = 70

			local outFOV_Tween: Tween = TweenService:Create(
				Camera,
				TweenInfo.new(DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ FieldOfView = zoomedOutFOV }
			)
			local inFOV_Tween: Tween = TweenService:Create(
				Camera,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{ FieldOfView = defaultFOV }
			)

			--FUNCTIONS
			
			
			local function cancelDashIfAttribute(char: Model?): boolean
				if not char or not char.Parent then return true end

				for _, attribute in ipairs(PREVENTION_ATTRIBUTES) do
					if attribute == "DashOnCooldown" then continue end

					if char:GetAttribute(attribute) then return true end
				end

				return false
			end --Checks all prevention attributes BESIDES DashOnCooldown (meant to cancel a dash during use).

			local function tweenCamera()
				--Camera FX
				outFOV_Tween:Play()
				outFOV_Tween.Completed:Once(function()
					inFOV_Tween:Play()
				end)

				--Use RunService.Heartbeat to check for prevention attributes (meant to cancel camera tweens if dash is canceled).
				local RunConnection: RBXScriptConnection
				RunConnection = RunService.Heartbeat:Connect(function()
					if cancelDashIfAttribute(char) then
						if outFOV_Tween.PlaybackState == Enum.PlaybackState.Playing then outFOV_Tween:Cancel() end
						RunConnection:Disconnect()
						return
					end
				end)
				task.delay(DURATION, function() --If camera tweens aren't canceled during RunConnection, disconnect RunConnection
					if RunConnection then RunConnection:Disconnect() end
				end)
			end

			local function tryDash(
				action: string,
				inputState: Enum.UserInputState,
				inputObject: InputObject
			): Enum.ContextActionResult
				
				if inputState ~= Enum.UserInputState.Begin or inputState == Enum.UserInputState.Cancel then return Enum.ContextActionResult.Pass end
				for _, attribute in pairs(PREVENTION_ATTRIBUTES) do
					if char:GetAttribute(attribute) then return Enum.ContextActionResult.Pass end
				end --Checks all prevention attributes (meant to cancel a dash before happening).
				
				mainRemote:FireServer()
				tweenCamera()
				return Enum.ContextActionResult.Sink
			end

			--BIND & CUSTOMIZE ACTION
			ContextActionService:BindAction(
				"Dash", 
				tryDash, 
				true,
				keybinds.Keyboard, keybinds.Console
			)
			ContextActionService:SetTitle("Dash", "Dash")
			ContextActionService:SetPosition("Dash", UDim2.new(0.431, 0,   0.353, 0))  
		end
		dash()

		local function climb()

			--REMOTES
			local climbEvent = ReplicatedStorage.Remotes_Bindables.Remotes.GeneralPlayer.WallClimb :: RemoteEvent

			local keybinds = actionsMap.Climb
			local ACTION_NAME: string = "WallClimb"

			--FUNCTIONS
			local function beginClimb(
				actionName: string, 
				inputState: Enum.UserInputState, 
				inputObject: InputObject
			)
				if inputState ~= Enum.UserInputState.Begin then return end

				local state = hum:GetState()
				if state == Enum.HumanoidStateType.Jumping
					or state == Enum.HumanoidStateType.Freefall then

					climbEvent:FireServer(true)
				end
			end

			-- BIND INPUTS --
			hum.StateChanged:Connect(function(_, newState)
				--Allowing climb
				if newState == Enum.HumanoidStateType.Jumping 
					or newState == Enum.HumanoidStateType.Freefall then

					ContextActionService:BindAction(
						ACTION_NAME,
						beginClimb,
						true,
						keybinds.Keyboard, keybinds.Console
					)
					ContextActionService:SetTitle(ACTION_NAME, "Climb")
					ContextActionService:SetPosition(ACTION_NAME, UDim2.new(0.709, 0,   0.356, 0))  
				else
					ContextActionService:UnbindAction(ACTION_NAME)
				end

				--Reset climb count
				if newState == Enum.HumanoidStateType.Landed 
					or newState == Enum.HumanoidStateType.Running then

					climbEvent:FireServer(false)
				end
			end) --End of StateChanged

		end
		climb()
	end
	Enable_NonPVP()
	--print("Movement Game-Controls initialized")

	-- PVP --
	local function Enable_PVP()
		local function block()

			--REMOTES
			local blockingEvent: RemoteEvent = ReplicatedStorage.Remotes_Bindables.Remotes.PVP.Blocking.BlockingEvent

			--VARIABLES
			local COOLDOWN: number = ReplicatedStorage.Values.Combat.Base.Block.CooldownTime.Value

			local PREVENTION_ATTRIBUTES: {string} = {
				"Ragdolled",
				"TrueStunned",
				--"Carried",
				--"Gripped",
				--"Knocked",
			}
			local keybinds = actionsMap.Block

			local isBlocking: boolean = false
			local allowedToBlock: boolean = true
			local beganWhilePrevented: boolean = false --prevents cooldown being set if began input whilst prevented (e.g., ragdolled but began input)
			
			--Animations
			local blockingAnimKatana: AnimationTrack = animator:LoadAnimation(ReplicatedStorage.Animations.General.Blocking.Katana)
			local blockingAnimFist: AnimationTrack = animator:LoadAnimation(ReplicatedStorage.Animations.General.Blocking.Fist)
			-------------

			--FUNCTIONS
			local function startBlocking()
				if char:GetAttribute("BlockOnCooldown") or char:GetAttribute("Blocking") then
					beganWhilePrevented = true
					return 
				end
				for _, v in pairs(PREVENTION_ATTRIBUTES) do
					if char:GetAttribute(v) then 
						beganWhilePrevented = true
						return 
					end
				end
				if isBlocking then 
					beganWhilePrevented = true
					return 
				end --prevents remote spamming (if we are blocking)
				
				
				beganWhilePrevented = false
				
				blockingEvent:FireServer(true) --Tell server we are blocking
				isBlocking = true --Set debounce boolean to true

				local tool = char:FindFirstChildOfClass("Tool") :: Tool?
				if tool and (tool:GetAttribute("Katana") or tool.Name == "Katana") then
					blockingAnimKatana:Play()
				else
					blockingAnimFist:Play()
				end
			end

			local function stopBlocking()
				if beganWhilePrevented then return end
				
				
				blockingEvent:FireServer(false) --Tell server we are not blocking
				isBlocking = false --Set debounce boolean to false

				--If animTracks are playing, stop them
				if blockingAnimFist.IsPlaying then blockingAnimFist:Stop() end
				if blockingAnimKatana.IsPlaying then blockingAnimKatana:Stop() end
			end

			local function tryBlock(
				actionName: string, 
				inputState: Enum.UserInputState, 
				input: InputObject
			): Enum.ContextActionResult
				
				--Safe guards
				if not allowedToBlock then return Enum.ContextActionResult.Pass end
				if inputState == Enum.UserInputState.Cancel then return Enum.ContextActionResult.Pass end
				if hum:GetState() == Enum.HumanoidStateType.Dead or hum.Health <= 0 then return Enum.ContextActionResult.Pass end

				--Check input state
				if inputState == Enum.UserInputState.Begin then
					startBlocking()
				elseif inputState == Enum.UserInputState.End then
					stopBlocking()
				end
				return Enum.ContextActionResult.Sink
			end


			--Binding actions
			ContextActionService:BindAction("Block", tryBlock, true, keybinds.Keyboard, keybinds.Console)
			ContextActionService:SetTitle("Block", "Block")
			ContextActionService:SetPosition("Block", UDim2.new(0.435, 0,   0.032, 0))


			-- Listen for attribute changes (PREVENTION_ATTRIBUTES)
			for _, attribute: string in ipairs(PREVENTION_ATTRIBUTES) do
				char:GetAttributeChangedSignal(attribute):Connect(function()
					if char:GetAttribute(attribute) then 
						if char:GetAttribute("Blocking") or isBlocking then
							stopBlocking()
						end
						allowedToBlock = false
					else
						allowedToBlock = true
					end
				end)
			end --End of for loop

		end
		block()

		local function normalAndHeavy()

			--MODULES
			local AnimationService = require(ReplicatedStorage.Modules.Packages.AnimationService) :: ModuleScript


			--========================================================--
			--                    REMOTE EVENTS                       --
			--========================================================--
			local Remotes: Folder = ReplicatedStorage.Remotes_Bindables.Remotes.PVP.M1sAndM2s
			local M1Remote: RemoteEvent = Remotes.M1RemoteEvent
			local M2Remote: RemoteEvent = Remotes.M2RemoteEvent
			
			
			--========================================================--
			--                     ATTACK SETTINGS                     --
			--========================================================--
			local M1CooldownDuration: number = 2
			local M1OnCooldown: boolean = false

			local clicked: boolean = false --M1 debounce
			local PressTime: number = 0
			local NewPressTime: number = 0

			local ComboMax: number? = char:GetAttribute("ComboMax") or 5
			local Attacking: boolean = false --Overall debounce
			local playingM1Track -- Stores the currently playing M1 animation track


			--========================================================--
			--                  ANIMATION LOADING                      --
			--========================================================--

			local AnimFolder = ReplicatedStorage:FindFirstChild("Animations") :: Folder
			local M1Folder = AnimFolder:FindFirstChild("M1s") :: Folder
			local M2Folder = AnimFolder:FindFirstChild("M2s") :: Folder

			local M1_FistFolder = M1Folder:FindFirstChild("Fist") :: Folder
			local M1_KatanaFolder = M1Folder:FindFirstChild("Katana") :: Folder
			
			local M2_FistFolder = M2Folder:FindFirstChild("Fist") :: Folder
			local M2_KatanaFolder = M2Folder:FindFirstChild("Katana") :: Folder


			local function LoadAnim(folder: Folder, index: number)
				local animObj = folder:FindFirstChild(tostring(index))
				if not animObj then
					warn("Missing animation:", index)
					return nil
				end
				return animator:LoadAnimation(animObj)
			end

			local M1Fist = {}
			local M1Katana = {}

			for i = 1, 5 do
				M1Fist[i] = LoadAnim(M1_FistFolder, i)
				M1Katana[i] = LoadAnim(M1_KatanaFolder, i)
			end


			-- Heavy Attack animations (random choice)
			local M2Fist = {}
			local M2Katana = {}

			for i = 1, 2 do
				M2Fist[i] = LoadAnim(M2_FistFolder, i)
				M2Katana[i] = LoadAnim(M2_KatanaFolder, i)
			end


			--========================================================--
			--                      HELPERS                            --
			--========================================================--
			local function GetWeaponType(): string
				local tool = char:FindFirstChildOfClass("Tool")

				if tool and tool.Name == "Katana" then return "Katana"
				elseif tool and tool.Name ~= "Katana" then return "OtherTool"
				else return "Fist" end
			end

			local function PlayM1Anim(type: any, index: number): boolean | AnimationTrack
				local animTrack = (type == "Katana") and M1Katana[index] or M1Fist[index]
				if not animTrack then return false end

				local success, err = pcall(function()
					animTrack:Play()
					animTrack:Destroy()
				end)
				if not success then
					warn("Anim play failed:", err)
					return false
				end
				return animTrack
			end

			local function ResetM1()
				char:SetAttribute("Combo", 1)
				PressTime = tick()
				Attacking = true
				clicked = true

				local weapon = GetWeaponType()

				local animTrack = PlayM1Anim(weapon, 1)
				if animTrack then
					if playingM1Track and playingM1Track ~= animTrack then
						playingM1Track:Stop()
						playingM1Track:Destroy()
						playingM1Track = nil
					end
					playingM1Track = animTrack
					M1Remote:FireServer(1)

					--animTrack:GetMarkerReachedSignal("FireServer"):Once(function()
					--	M1Remote:FireServer(1)
					--end)
					animTrack:GetMarkerReachedSignal("Ended"):Once(function()
						Attacking = false
						clicked = false
					end)
					animTrack.Stopped:Once(function()
						if playingM1Track == animTrack then
							playingM1Track = nil
						end
					end)
				end
			end
			
			
			--========================================================--
			--                     INPUT SYSTEM                       --
			--========================================================--
			local PREVENT_ATTRIBUTES: {string} = {
				--"Gripped",
				--"Carried",
				--"Knocked",
				"Ragdolled",
				"TrueStunned",
				"Stunned",
				"Blocking",
				"UsingAttack" 
			}
			local RESET_ATTRIBUTES: {string} = {
				--"Gripped",
				--"Carried",
				--"Knocked",
				"TrueStunned",
				"Ragdolled",
			}

			local controlsEnabled: boolean = true

			local function HandleM1(
				actionName: string, 
				inputState: Enum.UserInputState, 
				inputObject: InputObject
			): Enum.ContextActionResult

				if not controlsEnabled then 
					return Enum.ContextActionResult.Pass 
				end
				if inputState == Enum.UserInputState.Cancel or inputState ~= Enum.UserInputState.Begin then 
					return Enum.ContextActionResult.Pass 
				end

				if hum:GetState() == Enum.HumanoidStateType.Dead or hum.Health <= 0 then 
					return Enum.ContextActionResult.Pass 
				end
				if Attacking or clicked or M1OnCooldown then 
					return Enum.ContextActionResult.Pass 
				end
				for _, v in pairs(PREVENT_ATTRIBUTES) do
					if char:GetAttribute(v) then return Enum.ContextActionResult.Pass end
				end
				local weapon: string = GetWeaponType()
				if weapon == "OtherTool" then return Enum.ContextActionResult.Pass end


				local combo: number? = char:GetAttribute("Combo") or 0
				Attacking = true
				clicked = true

				--local animsPlaying = animator:GetPlayingAnimationTracks()
				--print("Animations Playing: " .. #animsPlaying)

				combo += 1
				if combo > ComboMax then
					combo = 1
				end
				char:SetAttribute("Combo", combo)

				if combo == 1 then
					PressTime = tick()
					local animTrack: AnimationTrack  = PlayM1Anim(weapon, 1)
					if animTrack then
						if playingM1Track and playingM1Track ~= animTrack then
							playingM1Track:Stop()
							playingM1Track:Destroy()
							playingM1Track = nil
						end
						playingM1Track = animTrack
						M1Remote:FireServer(combo)

						--animTrack:GetMarkerReachedSignal("FireServer"):Once(function()
						--	M1Remote:FireServer(combo)
						--end)
						animTrack:GetMarkerReachedSignal("Ended"):Once(function()
							Attacking = false
							clicked = false
						end)
						animTrack.Stopped:Once(function()
							if playingM1Track == animTrack then
								playingM1Track = nil
							end
						end)
					end
				elseif combo > 1 and combo < 5 then
					NewPressTime = tick()
					if NewPressTime - PressTime < 3 then
						PressTime = tick()
						local animTrack: AnimationTrack  = PlayM1Anim(weapon, combo)
						if animTrack then
							if playingM1Track and playingM1Track ~= animTrack then
								playingM1Track:Stop()
								playingM1Track:Destroy()
								playingM1Track = nil
							end
							playingM1Track = animTrack
							M1Remote:FireServer(combo)

							--animTrack:GetMarkerReachedSignal("FireServer"):Once(function()
							--	M1Remote:FireServer(combo)
							--end)
							animTrack:GetMarkerReachedSignal("Ended"):Once(function()
								Attacking = false
								clicked = false
							end)
							animTrack.Stopped:Once(function()
								if playingM1Track == animTrack then
									playingM1Track = nil
								end
							end)
						end
					else
						char:SetAttribute("Combo", 0)
						ResetM1()
					end
				else -- combo == 5 (finisher)
					NewPressTime = tick()
					if NewPressTime - PressTime < 3 then
						M1OnCooldown = true

						local animTrack: AnimationTrack  = PlayM1Anim(weapon, 5)
						if animTrack then
							if playingM1Track and playingM1Track ~= animTrack then
								playingM1Track:Stop()
								playingM1Track:Destroy()
								playingM1Track = nil
							end
							playingM1Track = animTrack
							M1Remote:FireServer(combo)

							--animTrack:GetMarkerReachedSignal("FireServer"):Once(function()
							--	M1Remote:FireServer(combo)
							--end)
							animTrack:GetMarkerReachedSignal("Ended"):Once(function()
								Attacking = false
								clicked = false
							end)
							animTrack.Stopped:Once(function()
								if playingM1Track == animTrack then
									playingM1Track = nil
								end
							end)
						end

						task.delay(M1CooldownDuration, function()
							M1OnCooldown = false
							char:SetAttribute("Combo", 0)
							clicked = false
						end)
					else
						ResetM1()
					end
				end

				return Enum.ContextActionResult.Sink
			end

			local function HandleM2(
				actionName: string, 
				inputState: Enum.UserInputState, 
				inputObject: InputObject
			): Enum.ContextActionResult

				if not controlsEnabled then 
					return Enum.ContextActionResult.Pass 
				end
				if inputState == Enum.UserInputState.Cancel or inputState ~= Enum.UserInputState.Begin then 
					return Enum.ContextActionResult.Pass 
				end
				if hum:GetState() == Enum.HumanoidStateType.Dead or hum.Health <= 0 then 
					return Enum.ContextActionResult.Pass 
				end
				if Attacking then return Enum.ContextActionResult.Pass end
				if char:GetAttribute("HeavyAttackOnCooldown") then return Enum.ContextActionResult.Pass  end
				for _, v in pairs(PREVENT_ATTRIBUTES) do
					if char:GetAttribute(v) then return Enum.ContextActionResult.Pass end
				end
				local weapon: string = GetWeaponType()
				if weapon == "OtherTool" then return Enum.ContextActionResult.Pass end


				Attacking = true

				local animTrack: AnimationTrack
				if weapon == "Katana" then
					animTrack = M2Katana[math.random(1, #M2Katana)]
				else
					animTrack = M2Fist[math.random(1, #M2Fist)]
				end
				animTrack:Play()
				M2Remote:FireServer()

				--animTrack:GetMarkerReachedSignal("FireServer"):Once(function()
				--	M2Remote:FireServer()
				--end)
				
				animTrack.Stopped:Once(function()
					if playingM1Track == animTrack then
						playingM1Track = nil
					end
					Attacking = false
				end)

				return Enum.ContextActionResult.Sink
			end

			-- Recovery listeners to avoid stuck debounces when attributes change (e.g., TrueStunned/Ragdolled)
			for _, v in pairs(RESET_ATTRIBUTES) do
				Attacking = false
				clicked = false
			end

			--========================================================--
			--                     INPUT LISTENERS                     --
			--========================================================--
			local keybinds  = actionsMap.Attacking
			local keybinds_Light  = keybinds.LightAttack
			local keybinds_Heavy  = keybinds.HeavyAttack

			local shiftlockEnabled = char:WaitForChild("ShiftLockEnabled") :: BoolValue

			UserInputService.InputBegan:Connect(function(input, GPE)
				if GPE then return end
				
				--M1
				if 
					input.UserInputType == keybinds_Light.Keyboard or input.KeyCode == keybinds_Light.Console
				then HandleM1("LightAttack", input.UserInputState, input) end
				
				--M2
				if 
					input.KeyCode == keybinds_Heavy.Keyboard.NonShiftLock 
					or (input.UserInputType == keybinds_Heavy.Keyboard.ShiftLock and shiftlockEnabled.Value == true)
					or input.KeyCode == keybinds_Heavy.Console
				then HandleM2("HeavyAttack", input.UserInputState, input) end
			end)

			ContextActionService:BindAction( --Light BindAction
				"LightAttack", 
				HandleM1, 
				true
			)
			ContextActionService:SetTitle("LightAttack", "M1")
			ContextActionService:SetPosition("LightAttack", UDim2.new(0.552, 0,   -0.149, 0))

			ContextActionService:BindAction( --Heavy BindAction
				"HeavyAttack", 
				HandleM2, 
				true
			)
			ContextActionService:SetTitle("HeavyAttack", "M2")
			ContextActionService:SetPosition("HeavyAttack", UDim2.new(0.317, 0,   -0.15, 0))



			local function handleChildAdded(child: Instance)
				if not child:IsA("Tool") then return end

				if CollectionService:HasTag(child, "Skill") or CollectionService:HasTag(child, "Food") then
					controlsEnabled = false
				else
					controlsEnabled = true
				end
			end

			local function handleChildRemoved(child: Instance)
				if not child:IsA("Tool") then return end
				controlsEnabled = true
			end

			char.ChildAdded:Connect(handleChildAdded)
			char.ChildRemoved:Connect(handleChildRemoved)

		end
		normalAndHeavy()

		local function breathingBar()
			local Race: StringValue = player:WaitForChild("Race")
			repeat task.wait() until Race.Value ~= ("" and nil)
			if Race.Value ~= "Human" then return end --Ensure player is a human before proceeding with the function



			--VARIABLES
			local breathing_remote: RemoteEvent = ReplicatedStorage.Remotes_Bindables.Remotes.PVP.BreathingBar
			local keybinds  = actionsMap.Breathing
			local PREVENT_ATTRIBUTES: {string} = {
				"Gripped",
				"Carried",
				"Knocked",
				"TrueStunned",
				"Ragdolled",
				"Stunned",
				"Blocking",
				"UsingAttack" 
			}

			--FUNCTIONS
			local function beginBreathing(
				inputState: Enum.UserInputState 
			)
				--InputState check
				if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end

				for _, attribute in pairs(PREVENT_ATTRIBUTES) do
					if char:GetAttribute(attribute) then return end
				end --^ check if PREVENT attributes are true
				breathing_remote:FireServer(true)
			end

			local function endBreathing(
				inputState: Enum.UserInputState
			)
				--InputState check
				if inputState ~= Enum.UserInputState.End then return end

				breathing_remote:FireServer(false)
			end

			local function tryBreathing(
				actionName: string, 
				inputState: Enum.UserInputState, 
				inputObject: InputObject
			): Enum.ContextActionResult
				--InputState checks
				if inputState == Enum.UserInputState.Cancel then 
					return Enum.ContextActionResult.Pass 
				end
				if inputState ~= Enum.UserInputState.Begin and inputState ~= Enum.UserInputState.End then 
					return Enum.ContextActionResult.Pass 
				end

				if inputState == Enum.UserInputState.Begin then
					beginBreathing(inputState)
					return Enum.ContextActionResult.Sink

				elseif inputState == Enum.UserInputState.End then
					endBreathing(inputState)
					return Enum.ContextActionResult.Sink
				end
			end


			--BINDING--
			ContextActionService:BindAction(
				"Breathing",
				tryBreathing,
				true,
				keybinds.Keyboard, keybinds.Console
			)
			ContextActionService:SetTitle("Breathing", "Breathing")
			ContextActionService:SetPosition("Breathing", UDim2.new(0.75, 0, -0.15, 0))

			--DETECTING PREVENT ATTRIBUTES
			for _, attribute in pairs(PREVENT_ATTRIBUTES) do
				char:GetAttributeChangedSignal(attribute):Connect(function()
					endBreathing(Enum.UserInputState.End)
				end)
			end
		end
		breathingBar()

		local function gripAndCarry()

			--MODULES
			local ContextActionUtility = require(ReplicatedStorage.Modules.Packages.ContextActionUtility)

			--REMOTES
			local carryEvent  = ReplicatedStorage.Remotes_Bindables.Remotes.PVP.GripAndCarry.CarryEvent :: RemoteEvent
			local gripEvent   = ReplicatedStorage.Remotes_Bindables.Remotes.PVP.GripAndCarry.GripEvent :: RemoteEvent
			local reviveEvent = ReplicatedStorage.Remotes_Bindables.Remotes.PVP.GripAndCarry.ReviveEvent :: RemoteEvent

			--VARIABLES
			hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

			local carry_debounce 	  = false
			local carry_debounce_TIME = 1
			local grip_debounce		  = false
			local grip_debounce_TIME  = 1.5

			local keybinds  = actionsMap.GripAndCarry
			local keybinds_Carry  = keybinds.Carry
			local keybinds_Grip  = keybinds.Grip

			--//:FUNCTIONS
			local function GetClosestDowned(character_position: Vector3)
				local maxDistance = 8
				local nearestDowned, nearestDistance

				for _, v in pairs(ReplicatedStorage.Values.Downed:GetChildren()) do
					if v:IsA("ObjectValue") then
						if not v.Value then 
							print("No value for: "..v.Name) 
							continue
						end

						local v_character = v.Value
						if v_character:FindFirstChild("Dead") then
							print("Character is dead")
							continue 
						end

						local v_characterHead = v_character:FindFirstChild("Head") :: Part?
						if not v_characterHead then 
							warn("Head not found for: "..v_character.Name) 
							continue 
						end

						local distance = (v_characterHead.Position - character_position).Magnitude
						if  
							distance > maxDistance or
							(nearestDistance and distance >= nearestDistance)
						then
							print("Distance is too far")
							continue 
						end

						nearestDistance = distance
						nearestDowned = v_character
					end
				end

				print("Found nearestDowned")
				return nearestDowned
			end

			local function Carry(actionName: string, inputState: Enum.UserInputState, inputObject: any)
				if carry_debounce then return end
				if inputState ~= Enum.UserInputState.Begin then return end
				if inputObject.KeyCode ~= keybinds_Carry.Keyboard 
					and inputObject.KeyCode ~= keybinds_Carry.Console 
				then return end


				local characterHead = char:FindFirstChild("Head") :: BasePart?
				if not characterHead then return end

				local victim = GetClosestDowned(characterHead.Position)
				if victim then
					carryEvent:FireServer(victim)
					task.spawn(function()
						carry_debounce = true
						task.wait(carry_debounce_TIME)
						carry_debounce = false
					end)
				end

				print("Fired carry event")
			end

			local function Grip(actionName: string, inputState: Enum.UserInputState, inputObject)
				if grip_debounce == true then return end
				if inputState ~= Enum.UserInputState.Begin then return end

				local characterHead = char:FindFirstChild("Head") :: BasePart?
				if not characterHead then return end

				local victim = GetClosestDowned(characterHead.Position)
				if victim then
					gripEvent:FireServer(victim)
					task.spawn(function()
						grip_debounce = true
						task.wait(grip_debounce_TIME)
						grip_debounce = false
					end)
				end

				print("Fired grip event")
			end

			ContextActionService:BindAction("Carry", Carry, true)
			ContextActionService:SetImage("Carry", "rbxassetid://18362401517")
			ContextActionService:SetPosition("Carry", UDim2.new(0.826, 0,   0.213, 0))

			ContextActionService:BindAction("Grip", Grip, true)
			ContextActionService:SetImage("Grip", "rbxassetid://18362400331")
			ContextActionService:SetPosition("Grip", UDim2.new(0.83, 0,   0.025, 0))

			UserInputService.InputBegan:Connect(function(input, GPE)
				if GPE then return end

				if input.KeyCode == keybinds_Carry.Keyboard 
					or input.KeyCode == keybinds_Carry.Console then

					Carry("Carry", Enum.UserInputState.Begin, input)
				end

				if input.KeyCode == keybinds_Grip.Keyboard 
					or input.KeyCode == keybinds_Grip.Console then

					Grip("Grip", Enum.UserInputState.Begin, input)
				end
			end)


		--[[local buttonPositionTable = {	
			[1] = UDim2.new(0,123,0,70), 
			[2] = UDim2.new(0,30,0,60),
			[3] = UDim2.new(0,180,0,160),
			[4] = UDim2.new(0,85,0,0),
			[5] = UDim2.new(0,185,0,-25),
			[6] = UDim2.new(0,185,0,260),
			[7] = UDim2.new(0,216,0,65)
		}
		local maxButtons = #buttonPositionTable

		ContextActionService:BindAction("Carry", Carry, true, CarryButton)
		ContextActionService:SetTitle("Carry", "Carry")
		ContextActionService:SetPosition("Carry", buttonPositionTable[4])
		ContextActionService:SetImage("Carry", "rbxassetid://6256840888")

		ContextActionService:BindAction("Grip", Grip, true, GripButton)
		ContextActionService:SetTitle("Grip", "Grip")
		ContextActionService:SetPosition("Grip", buttonPositionTable[2])
		ContextActionService:SetImage("Grip", "rbxassetid://6256840888")
		ContextActionService:GetButton("Grip").Size = UDim2.new(0,90,0,90)]]

			hum.HealthChanged:Connect(function(health)
				local trigger = char:FindFirstChild("RagdollTrigger") :: BoolValue?
				if not trigger or not trigger.Value then return end

				if (health / hum.Health) >= 0.15 then
					reviveEvent:FireServer()
					print("Fired revive event")
				end
			end)
		end
		--gripAndCarry()
	end
	Enable_PVP()
	--print("PvP Game-Controls initialized")
	
	print("Game-Controls initialized!")
end

return module
