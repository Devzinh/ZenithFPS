-- Load dependencies with proper error handling
local function loadModule(url)
	local success, content = pcall(function()
		return game:HttpGet(url)
	end)
	
	if not success then
		warn("Failed to fetch module from " .. url .. ": " .. tostring(content))
		return nil
	end
	
	local loadSuccess, module = pcall(function()
		return loadstring(content)()
	end)
	
	if not loadSuccess then
		warn("Failed to load module: " .. tostring(module))
		return nil
	end
	
	return module
end

local Config = loadModule('https://raw.githubusercontent.com/Devzinh/ZenithFPS/refs/heads/main/config.lua')
local Utilities = loadModule('https://raw.githubusercontent.com/Devzinh/ZenithFPS/refs/heads/main/utilities.lua')

if not Config or not Utilities then
	warn("Failed to load required dependencies for AimLock module")
	return
end

local AimLock = {
	IsTargeting = false,
	FOVCircle = Drawing.new("Circle")
}

-- Initialize FOV Circle
function AimLock:InitFOVCircle()
	self.FOVCircle.Thickness = Config.AimLock.AimLockThickness
	self.FOVCircle.NumSides = 50
	self.FOVCircle.Radius = Config.AimLock.FOVSize
	self.FOVCircle.Filled = false
	self.FOVCircle.Visible = false
	self.FOVCircle.ZIndex = 999
	self.FOVCircle.Transparency = 1
	self.FOVCircle.Color = Color3.fromRGB(255, 255, 255)
end

-- Core targeting functions
function AimLock:GetClosestTarget()
	local closestPlayer = nil
	local shortestDistance = math.huge
	local localPlayer = game.Players.LocalPlayer
	local camera = workspace.CurrentCamera
	local mousePos = Vector2.new(game.Players.LocalPlayer:GetMouse().X, game.Players.LocalPlayer:GetMouse().Y)

	for _, player in ipairs(game.Players:GetPlayers()) do
		if player ~= localPlayer then
			local character = player.Character
			if character and character:FindFirstChild("Humanoid") and character:FindFirstChild(Config.AimLock.AimPart) then
				-- Team check
				if Config.AimLock.TeamCheck and player.Team == localPlayer.Team then
					continue
				end

				-- Health check
				local humanoid = character:FindFirstChild("Humanoid")
				if humanoid.Health <= 0 then
					continue
				end

				local targetPart = character[Config.AimLock.AimPart]
				local pos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
				local magnitude = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude

				-- FOV check
				if Config.AimLock.DisableOutsideFOV and magnitude > Config.AimLock.FOVSize then
					continue
				end

				-- Distance check
				local distance = (targetPart.Position - camera.CFrame.Position).Magnitude
				if distance > Config.AimLock.MaxTargetDistance then
					continue
				end

				-- Visibility check
				if Config.AimLock.VisibilityCheck then
					local rayParams = RaycastParams.new()
					rayParams.FilterType = Enum.RaycastFilterType.Blacklist
					rayParams.FilterDescendantsInstances = {localPlayer.Character, character}
					
					local rayResult = workspace:Raycast(camera.CFrame.Position, 
						(targetPart.Position - camera.CFrame.Position).Unit * distance, 
						rayParams)
						
					if rayResult and not rayResult.Instance:IsDescendantOf(character) then
						continue
					end
				end

				if magnitude < shortestDistance then
					closestPlayer = player
					shortestDistance = magnitude
				end
			end
		end
	end

	return closestPlayer
end

function AimLock:CalculatePrediction(target)
	if not target or not target.Character then return Vector3.new() end
	
	local targetPart = target.Character[Config.AimLock.AimPart]
	local velocity = targetPart.Velocity
	local distance = (targetPart.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
	
	local baseTime = Config.AimLock.Prediction
	if Config.AimLock.AutoAdjustPrediction then
		-- Adjust prediction based on distance and velocity
		local distanceFactor = math.clamp(distance / 100, 0.5, 2)
		local velocityFactor = math.clamp(velocity.Magnitude / 50, 0.5, 2)
		baseTime = baseTime * distanceFactor * velocityFactor * Config.AimLock.PredictionMultiplier
	end
	
	local gravity = Vector3.new(0, -workspace.Gravity, 0)
	local prediction = velocity * baseTime
	
	if Config.AimLock.SmartPrediction then
		-- Add gravity compensation
		prediction = prediction + 0.5 * gravity * baseTime * baseTime
		
		-- Add movement pattern prediction
		local humanoid = target.Character:FindFirstChild("Humanoid")
		if humanoid then
			local moveDirection = humanoid.MoveDirection
			if moveDirection.Magnitude > 0.1 then
				prediction = prediction + moveDirection * baseTime * 5
			end
		end
	end
	
	return prediction
end

function AimLock:CalculateSmoothing(target)
	if not Config.AimLock.AdaptiveSmoothing then
		return Config.AimLock.Smoothness
	end
	
	local smoothing = Config.AimLock.Smoothness
	local targetPart = target.Character[Config.AimLock.AimPart]
	local velocity = targetPart.Velocity
	local distance = (targetPart.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
	
	-- Adjust smoothing based on distance
	local distanceFactor = math.clamp(distance / 100, 0.5, 2)
	smoothing = smoothing * distanceFactor
	
	-- Adjust smoothing based on target velocity
	local velocityFactor = math.clamp(2 - (velocity.Magnitude / 50), 0.5, 2)
	smoothing = smoothing * velocityFactor
	
	-- Clamp final smoothing value
	return math.clamp(smoothing, Config.AimLock.MinSmoothing, Config.AimLock.MaxSmoothing)
end

-- Main update loop
function AimLock:Update()
	if Config.AimLock.Enabled and self.IsTargeting then
		local target = self:GetClosestTarget()
		if target and target.Character and target.Character:FindFirstChild(Config.AimLock.AimPart) then
			-- ... (Keep existing implementation)
		end
	end
end

-- Initialize AimLock
function AimLock:Init()
	self:InitFOVCircle()
	
	-- Input handling
	game:GetService("UserInputService").InputBegan:Connect(function(input)
		if input.KeyCode == Config.AimLock.Key then
			self.IsTargeting = true
		end
	end)
	
	game:GetService("UserInputService").InputEnded:Connect(function(input)
		if input.KeyCode == Config.AimLock.Key then
			self.IsTargeting = false
		end
	end)
	
	-- Update FOV Circle
	game:GetService("RunService").RenderStepped:Connect(function()
		self.FOVCircle.Visible = Config.AimLock.Enabled
		if Config.AimLock.Enabled then
			self.FOVCircle.Position = Vector2.new(game.Players.LocalPlayer:GetMouse().X, game.Players.LocalPlayer:GetMouse().Y)
		end
	end)
	
	-- Main update loop
	game:GetService("RunService").RenderStepped:Connect(function()
		self:Update()
	end)
end

-- Cleanup
function AimLock:Cleanup()
	self.FOVCircle:Remove()
end

return AimLock
