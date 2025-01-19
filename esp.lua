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
	warn("Failed to load required dependencies for ESP module")
	return
end

local ESP = {
	Elements = {},
	Connections = {},
	LastUpdate = 0,
	Settings = {
		MaxRenderDistance = 1000,
		UpdateInterval = 0.03,
		BoxEnabled = true,
		TracerEnabled = true,
		NameEnabled = true,
		HealthEnabled = true,
		DistanceEnabled = true,
		TeamIndicatorEnabled = true
	}
}

-- Initialize ESP components
function ESP:InitComponents()
	self.Radar = require("modules/radar"):new()
	
	-- Initialize settings from config
	for key, value in pairs(Config.ESP) do
		if self.Settings[key] ~= nil then
			self.Settings[key] = value
		end
	end
end

-- ESP element creation
function ESP:CreateESPElements(player)
	if self.Elements[player] then return end
	
	local elements = {
		box = {},
		tracer = {
			line = Drawing.new("Line"),
			outline = Drawing.new("Line"),
			dot = Drawing.new("Circle"),
			dotOutline = Drawing.new("Circle")
		},
		name = Drawing.new("Text"),
		health = Drawing.new("Text"),
		distance = Drawing.new("Text"),
		lastTextUpdate = 0
	}
	
	-- Initialize box elements
	local boxParts = {"topFront", "topBack", "topLeft", "topRight",
					 "bottomFront", "bottomBack", "bottomLeft", "bottomRight",
					 "leftFront", "rightFront", "leftBack", "rightBack"}
					 
	for _, part in ipairs(boxParts) do
		elements.box[part] = Drawing.new("Line")
		elements.box[part].Thickness = 1
		elements.box[part].Transparency = 1
	end
	
	-- Initialize text elements
	for _, textElement in pairs({elements.name, elements.health, elements.distance}) do
		textElement.Center = true
		textElement.Outline = true
		textElement.Size = 14
	end
	
	self.Elements[player] = elements
	return elements
end

-- Update functions
function ESP:UpdateESP()
	if not self.Settings.Enabled then return end
	
	local currentTime = tick()
	if currentTime - self.LastUpdate < self.Settings.UpdateInterval then
		return
	end
	self.LastUpdate = currentTime
	
	local camera = workspace.CurrentCamera
	if not camera then return end
	
	local localPlayer = game.Players.LocalPlayer
	if not localPlayer or not localPlayer.Character then return end
	
	for player, elements in pairs(self.Elements) do
		if not player or not player.Parent then
			self:CleanupPlayerESP(player)
			continue
		end
		
		local character = player.Character
		if not character or not character:FindFirstChild("HumanoidRootPart") then
			self:HideElements(elements)
			continue
		end
		
		local hrp = character.HumanoidRootPart
		local distance = (hrp.Position - camera.CFrame.Position).Magnitude
		
		if distance > self.Settings.MaxRenderDistance then
			self:HideElements(elements)
			continue
		end
		
		local vector, onScreen = camera:WorldToViewportPoint(hrp.Position)
		
		if onScreen then
			if self.Settings.BoxEnabled then
				self:UpdateBoxESP(elements, character, camera, vector)
			end
			
			if self.Settings.TracerEnabled then
				self:UpdateTracerESP(elements, vector)
			end
			
			if currentTime - elements.lastTextUpdate > 0.1 then
				self:UpdateTextESP(elements, player, character, vector, distance)
				elements.lastTextUpdate = currentTime
			end
		else
			self:HideElements(elements)
		end
	end
end

function ESP:UpdateBoxESP(elements, character, camera, vector)
	local cframe = character:GetPivot()
	local size = character:GetExtentsSize()
	
	local corners = {
		topFrontLeft = cframe * CFrame.new(-size.X/2, size.Y/2, -size.Z/2),
		topFrontRight = cframe * CFrame.new(size.X/2, size.Y/2, -size.Z/2),
		bottomFrontLeft = cframe * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2),
		bottomFrontRight = cframe * CFrame.new(size.X/2, -size.Y/2, -size.Z/2)
	}
	
	for name, corner in pairs(corners) do
		local point = camera:WorldToViewportPoint(corner.Position)
		elements.box[name].Position = Vector2.new(point.X, point.Y)
		elements.box[name].Visible = true
	end
end

function ESP:UpdateTracerESP(elements, vector)
	local screenCenter = Vector2.new(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2)
	local targetPos = Vector2.new(vector.X, vector.Y)
	
	elements.tracer.line.From = screenCenter
	elements.tracer.line.To = targetPos
	elements.tracer.line.Visible = true
end

function ESP:UpdateTextESP(elements, player, character, vector, distance)
	if elements.name then
		elements.name.Position = Vector2.new(vector.X, vector.Y - 40)
		elements.name.Text = player.Name
		elements.name.Visible = true
	end
	
	if elements.distance then
		elements.distance.Position = Vector2.new(vector.X, vector.Y + 25)
		elements.distance.Text = string.format("%.0f", distance)
		elements.distance.Visible = true
	end
	
	if elements.health and character:FindFirstChild("Humanoid") then
		elements.health.Position = Vector2.new(vector.X, vector.Y - 25)
		elements.health.Text = string.format("%.0f%%", character.Humanoid.Health)
		elements.health.Visible = true
	end
end

function ESP:HideElements(elements)
	for _, boxLine in pairs(elements.box) do
		boxLine.Visible = false
	end
	
	for _, tracerElement in pairs(elements.tracer) do
		tracerElement.Visible = false
	end
	
	if elements.name then elements.name.Visible = false end
	if elements.health then elements.health.Visible = false end
	if elements.distance then elements.distance.Visible = false end
end

-- Cleanup functions
function ESP:CleanupPlayerESP(player)
	local elements = self.Elements[player]
	if not elements then return end
	
	for _, boxLine in pairs(elements.box) do
		boxLine:Remove()
	end
	
	for _, tracerElement in pairs(elements.tracer) do
		tracerElement:Remove()
	end
	
	if elements.name then elements.name:Remove() end
	if elements.health then elements.health:Remove() end
	if elements.distance then elements.distance:Remove() end
	
	self.Elements[player] = nil
end

function ESP:CleanupAll()
	for player, _ in pairs(self.Elements) do
		self:CleanupPlayerESP(player)
	end
	
	table.clear(self.Elements)
	table.clear(self.Connections)
	
	collectgarbage("collect")
end

-- Initialize ESP
function ESP:Init()
	self:InitComponents()
	
	game:GetService("RunService").RenderStepped:Connect(function()
		if not self.Settings.Enabled then return end
		self:UpdateESP()
	end)
	
	game:GetService("Players").PlayerAdded:Connect(function(player)
		if player ~= game.Players.LocalPlayer then
			self:CreateESPElements(player)
		end
	end)
	
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		self:CleanupPlayerESP(player)
	end)
end

return ESP
