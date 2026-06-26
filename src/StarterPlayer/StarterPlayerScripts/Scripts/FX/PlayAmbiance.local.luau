local ambiance = script:WaitForChild("Ambiance")
ambiance.TimePosition = math.random(0, ambiance.TimeLength)
ambiance:Play()
