local VfxStudioEmitter = {}


local emitFunctions = {
	["ParticleEmitter"] = function(instance: Instance, emitDuration: number?)
		local count = instance:GetAttribute("EmitCount")
		if emitDuration and emitDuration > 0 then
			instance.Enabled = true
			task.wait(emitDuration)
			if instance.Parent then
				instance.Enabled = false
			end
		elseif count and count > 0 then
			instance:Emit(count)
		else
			-- If no duration or count, emit 1 particle as a default one-shot.
			instance:Emit(1)
		end
	end,
	["Beam"] = function(instance: Instance, emitDuration: number?)
		local beamClone = instance:Clone()
		beamClone.Parent = instance.Parent
		beamClone.Enabled = true

		task.wait(if emitDuration and emitDuration > 0 then emitDuration else 0.03)

		if beamClone and beamClone.Parent then
			beamClone:Destroy()
		end
	end,
	["Sound"] = function(instance: Instance, emitDuration: number?)
		instance:Play()
	end,
}

-- Function to trigger all effects with their attributes.
function VfxStudioEmitter:TriggerEffects(parentObject: Instance?)
	if not parentObject then
		warn("VFX trigger target not found!")
		return
	end

	-- Find all effect instances within the parent object.
	for _, instance in ipairs(parentObject:GetDescendants()) do
		local functionForEmitting = emitFunctions[instance.ClassName]
		if functionForEmitting then
			task.spawn(functionForEmitting, instance, instance:GetAttribute("EmitDuration"))
		end
		
		--[[
		if instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Sound") then
			task.spawn(function()
				if not instance.Parent then
					return
				end -- Safety check

				local emitDelay = instance:GetAttribute("EmitDelay") or 0
				local emitDuration = instance:GetAttribute("EmitDuration")

				if emitDelay > 0 then
					task.wait(emitDelay)
				end

				if not instance.Parent then
					return
				end -- Check again after delay

				if instance:IsA("Sound") then
					instance:Play()
				elseif instance:IsA("ParticleEmitter") then
					local count = instance:GetAttribute("EmitCount")
					if emitDuration and emitDuration > 0 then
						instance.Enabled = true
						task.wait(emitDuration)
						if instance.Parent then
							instance.Enabled = false
						end
					elseif count and count > 0 then
						instance:Emit(count)
					else
						-- If no duration or count, emit 1 particle as a default one-shot.
						instance:Emit(1)
					end
				elseif instance:IsA("Beam") then
					local beamClone = instance:Clone()
					beamClone.Parent = instance.Parent
					beamClone.Enabled = true

					task.wait(if emitDuration and emitDuration > 0 then emitDuration else 0.03)

					if beamClone and beamClone.Parent then
						beamClone:Destroy()
					end
				end
			end)
		end
		--]]
	end
end

return VfxStudioEmitter
