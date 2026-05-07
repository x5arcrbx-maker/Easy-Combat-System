return {
	-- PVP --
	Block = {
		Keyboard = Enum.KeyCode.F,
		Console = Enum.KeyCode.ButtonL2,
	},
	Attacking = {
		LightAttack = {
			Keyboard = Enum.UserInputType.MouseButton1,
			Console = Enum.KeyCode.ButtonR2,
		},
		HeavyAttack = {
			Keyboard = {
				NonShiftLock = Enum.KeyCode.R,
				ShiftLock = Enum.UserInputType.MouseButton2,
			},
			Console = Enum.KeyCode.ButtonY,
		},
	},
	
	Breathing = {
		Keyboard = Enum.KeyCode.G,
		Console = Enum.KeyCode.DPadDown,
	},
	
	GripAndCarry = {
		Grip = {
			Keyboard = Enum.KeyCode.B,
			Console = Enum.KeyCode.ButtonB,
		},
		Carry = {
			Keyboard = Enum.KeyCode.V,
			Console = Enum.KeyCode.DPadLeft,
		},
	},
	
	-- Non-PVP --
	Dash = {
		Keyboard = Enum.KeyCode.Q,
		Console = Enum.KeyCode.DPadUp,
	},
	Climb = {
		Keyboard = Enum.KeyCode.Space,
		Console = Enum.KeyCode.ButtonA,
	},
	Sprint = {
		Keyboard = Enum.KeyCode.W,
		Console = Enum.KeyCode.ButtonL3,
	},
}
