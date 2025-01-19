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
	warn("Failed to load required dependencies for AimSilent module")
	return
end

local AimSilent = {
	ProcessingMethods = {},
	CurrentTarget = nil,
	LastProcessTime = 0
}

-- Initialize processing methods
function AimSilent:InitProcessingMethods()
	self.ProcessingMethods = {
		FindPartOnRay = function(origin, direction, target)
			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
			raycastParams.FilterDescendantsInstances = {game.Players.LocalPlayer.Character}
			
			local result = workspace:Raycast(origin, direction, raycastParams)
			if result and result.Instance:IsDescendantOf(target.Character) then
				return result.Instance, result.Position
			end
			return nil
		end,
		
		ModernRaycast = function(origin, direction, target)
			local raycastResult = workspace:Raycast(origin, direction * Config.AimSilent.AimbotRange, 
				RaycastParams.new())
			
			if raycastResult and raycastResult.Instance:IsDescendantOf(target.Character) then
				return raycastResult.Instance, raycastResult.Position
			end
			return nil
		end,
		
		PointToRay = function(origin, direction, target)
			local targetPart = target.Character:FindFirstChild(Config.AimLock.AimPart)
			if not targetPart then return nil end
			
			local directionToTarget = (targetPart.Position - origin).Unit
			local dotProduct = direction:Dot(directionToTarget)
			
			if dotProduct > 0.97 then -- About 15 degrees
				return targetPart, targetPart.Position
			end
			return nil
		end,
		
		RayHook = function(origin, direction, target)
			if not target or not target.Character then return nil end
			
			local targetPart = target.Character:FindFirstChild(Config.AimLock.AimPart)
			if not targetPart then return nil end
			
			local prediction = self:CalculatePrediction(target, targetPart)
			local targetPos = targetPart.Position + prediction
			
			if (targetPos - origin).Magnitude <= Config.AimSilent.AimbotRange then
				return targetPart, targetPos
			end
			return nil
		end
	}
end

-- Target selection and validation
function AimSilent:SelectBestTarget()
	local players = game:GetService("Players"):GetPlayers()
	local localPlayer = game:GetService("Players").LocalPlayer
	local camera = workspace.CurrentCamera
	
	local bestTarget = nil
	local bestScore = -math.huge
	
	for _, player in ipairs(players) do
		if player == localPlayer then continue end
		
		local character = player.Character
		if not self:ValidateTarget(player, character) then continue end
		
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then continue end
		
		local score = self:CalculateTargetScore(player, humanoidRootPart)
		if score > bestScore then
			bestScore = score
			bestTarget = player
		end
	end
	
	return bestTarget
end

function AimSilent:ValidateTarget(player, character)
	if not player or not character then return false end
	if not character:FindFirstChild("Humanoid") or character.Humanoid.Health <= 0 then return false end
	if Config.AimSilent.TeamCheck and player.Team == game.Players.LocalPlayer.Team then return false end
	
	if Config.AimSilent.VisibilityCheck then
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
		raycastParams.FilterDescendantsInstances = {game.Players.LocalPlayer.Character}
		
		local targetPart = character:FindFirstChild(Config.AimLock.AimPart)
		if not targetPart then return false end
		
		local origin = workspace.CurrentCamera.CFrame.Position
		local direction = (targetPart.Position - origin).Unit
		local result = workspace:Raycast(origin, direction * Config.AimSilent.MaxTargetDistance, raycastParams)
		
		if not result or not result.Instance:IsDescendantOf(character) then
			return false
		end
	end
	
	return true
end

function AimSilent:CalculateTargetScore(player, humanoidRootPart)
	local score = 0
	local camera = workspace.CurrentCamera
	local distance = (humanoidRootPart.Position - camera.CFrame.Position).Magnitude
	
	-- Distance scoring
	score = score + (1 - math.clamp(distance / Config.AimSilent.MaxTargetDistance, 0, 1)) * 50
	
	-- Health-based scoring
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if humanoid then
		score = score + (1 - (humanoid.Health / humanoid.MaxHealth)) * 30
	end
	
	return score
end

function AimSilent:CalculatePrediction(target, targetPart)
	if not Config.AimSilent.AutoPrediction then
		return targetPart.Velocity * Config.AimSilent.PredictionStrength
	end
	
	local distance = (targetPart.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
	local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
	
	return targetPart.Velocity * (ping + (distance / 10000))
end

-- Initialize AimSilent
function AimSilent:Init()
	self:InitProcessingMethods()
	
	if Config.AimSilent.SelectedSilentAimMethod == "Advanced" then
		local oldNamecall
		oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
			local args = {...}
			local method = getnamecallmethod()
			
			if method == "FindPartOnRayWithIgnoreList" and math.random() <= Config.AimSilent.HitChance then
				local target = AimSilent:SelectBestTarget()
				if target then
					local origin = args[1].Origin
					local direction = args[1].Direction
					
					local hitPart, hitPosition = AimSilent.ProcessingMethods[Config.AimSilent.SelectedTargetMethod](
						AimSilent, origin, direction, target)
						
					if hitPart then
						args[1] = Ray.new(origin, (hitPosition - origin))
					end
				end
			end
			
			return oldNamecall(self, unpack(args))
		end)
		
		-- Cleanup hooks
		game:GetService("Players").LocalPlayer.CharacterRemoving:Connect(function()
			if oldNamecall then
				hookmetamethod(game, "__namecall", oldNamecall)
				oldNamecall = nil
			end
		end)
	end
end

return AimSilent
