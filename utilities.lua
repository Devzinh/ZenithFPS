local Utilities = {}

-- Team checking utilities
function Utilities.AreTeamsAllied(team1, team2)
	if not team1 or not team2 then return false end
	
	-- Check if teams are the same
	if team1 == team2 then return true end
	
	-- Check team alliance status if available
	local teamService = game:GetService("Teams")
	if teamService then
		-- Check team colors (some games use similar colors for allied teams)
		if team1.TeamColor and team2.TeamColor then
			local colorDifference = (team1.TeamColor.Color - team2.TeamColor.Color).Magnitude
			if colorDifference < 0.1 then
				return true
			end
		end
		
		-- Check for neutral teams
		local function isNeutralTeam(team)
			local name = team.Name:lower()
			return name:find("neutral") or name:find("spectator") or name:find("none")
		end
		
		if isNeutralTeam(team1) or isNeutralTeam(team2) then
			return true
		end
		
		-- Check for team properties that indicate alliance
		local function checkTeamProperties(t1, t2)
			-- Some games use custom team properties
			if t1:FindFirstChild("Alliance") and t2:FindFirstChild("Alliance") then
				return t1.Alliance.Value == t2.Alliance.Value
			end
			
			-- Check for team groups
			if t1:FindFirstChild("GroupId") and t2:FindFirstChild("GroupId") then
				return t1.GroupId.Value == t2.GroupId.Value
			end
			
			return false
		end
		
		if checkTeamProperties(team1, team2) then
			return true
		end
		
		-- Check for explicit alliance configurations
		local function checkExplicitAlliances()
			local alliances = teamService:FindFirstChild("TeamAlliances")
			if alliances then
				local team1Allies = alliances:FindFirstChild(team1.Name)
				if team1Allies and team1Allies:FindFirstChild(team2.Name) then
					return team1Allies[team2.Name].Value
				end
			end
			return false
		end
		
		if checkExplicitAlliances() then
			return true
		end
	end
	
	return false
end

function Utilities.ShouldShowESP(player)
	local localPlayer = game.Players.LocalPlayer
	if not localPlayer then return false end
	
	-- Don't show ESP for local player
	if player == localPlayer then return false end
	
	-- Check if player is on the same team
	if not Utilities.AreTeamsAllied(player.Team, localPlayer.Team) then
		return true
	end
	
	return false
end

-- Math utilities
function Utilities.CalculateDistance(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

function Utilities.ClampValue(value, min, max)
	return math.min(math.max(value, min), max)
end

-- Ray casting utilities
function Utilities.PerformRaycast(origin, direction, distance, whitelist)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = whitelist or {}
	
	local raycastResult = workspace:Raycast(origin, direction * distance, raycastParams)
	return raycastResult
end

-- Drawing utilities
function Utilities.CreateDrawingObject(type, properties)
	local object = Drawing.new(type)
	
	if properties then
		for property, value in pairs(properties) do
			object[property] = value
		end
	end
	
	return object
end

return Utilities
