-- Configuration module for ZenithHUB
local Config = {
	UI = {
		Name = "ZenithHUB",
		LoadingTitle = "ZenithHUB | FPS",
		LoadingSubtitle = "by Devzinh",
		ConfigurationSaving = {
			Enabled = true,
			FolderName = nil,
			FileName = "ZenithHUB"
		},
		Discord = {
			Enabled = true,
			Invite = "discord.gg/J37PW97j6a",
			RememberJoins = true
		}
	},
	
	AimLock = {
		Enabled = false,
		Key = Enum.KeyCode.Q,
		Prediction = 0.135,
		AimPart = "HumanoidRootPart",
		AimRadius = 50,
		AimLockThickness = 3,
		TeamCheck = true,
		DisableOnDeath = true,
		DisableOutsideFOV = true,
		FOVSize = 100,
		Smoothness = 0.25,
		MinSmoothing = 0.1,
		MaxSmoothing = 0.4,
		PredictionMultiplier = 1.2,
		AutoAdjustPrediction = true,
		SmartPrediction = true,
		AdaptiveSmoothing = true,
		HealthBasedTargeting = true,
		MovementPrediction = true,
		VisibilityCheck = true,
		MaxTargetDistance = 1000,
		TargetPriority = "Distance"
	},
	
	AimSilent = {
		SelectedTargetMethod = "Dynamic",
		SelectedSilentAimMethod = "Advanced",
		AimbotRange = 1000,
		HitChance = 1,
		HeadshotChance = 0.5,
		Smoothness = 0.5,
		PredictionStrength = 1,
		TargetPriority = "Distance",
		MaxTargetDistance = 1000,
		VisibilityCheck = true,
		TeamCheck = true,
		WallCheck = true,
		HitboxExpansion = 0.1,
		AutoPrediction = true,
		AdaptiveTargeting = true
	},
	
	ESP = {
		Enabled = false,
		BoxEnabled = false,
		TracerEnabled = false,
		NameEnabled = true,
		HealthEnabled = true,
		DistanceEnabled = true,
		ChamsEnabled = false,
		OffScreenArrowsEnabled = false,
		TeamIndicatorEnabled = false,
		AutoScale = true,
		MinScale = 0.5,
		MaxScale = 1.5,
		ScaleDistance = 100,
		MaxRenderDistance = 1000,
		UpdateInterval = 0.03,
		
		Colors = {
			Box = Color3.fromRGB(255, 0, 0),
			Tracer = Color3.fromRGB(255, 255, 255),
			Text = Color3.fromRGB(255, 255, 255),
			Arrow = Color3.fromRGB(255, 255, 255)
		},
		
		Radar = {
			Enabled = true,
			Position = Vector2.new(200, 200),
			Size = 150,
			Zoom = 1,
			DotSize = 4,
			Transparency = 0.9,
			CenterColor = Color3.fromRGB(255, 255, 255),
			PlayerColor = Color3.fromRGB(255, 0, 0),
			TeamColor = Color3.fromRGB(0, 255, 0)
		}
	}
}

return Config
