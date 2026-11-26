-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- Shared settings
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- Remote events
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local updateLeaderEvent = remoteEvents.UpdateLeader
local updateTimerEvent = remoteEvents.UpdateTimer
local sendRoundResultsEvent = remoteEvents.SendRoundResults

-- Bindable events
local updateRoundStatusEvent = ReplicatedStorage:WaitForChild("BindableEvents").UpdateRoundStatus

-- Assets
local leaderHighlight = ReplicatedStorage:WaitForChild("Assets").LeaderHighlight
local rankingSlotTemplate = ReplicatedStorage:WaitForChild("Assets").RankingSlot

-- References
local arena = workspace:WaitForChild("Arena")
local spawnLocations = workspace:WaitForChild("SpawnLocations")
local rankingsBoards = workspace:WaitForChild("RankingsBoards")
local spleefFolder = workspace:WaitForChild("Spleef")
local mapCenter = workspace:WaitForChild("Map"):WaitForChild("MapCenter")

-- Music 
local music = workspace:WaitForChild("Music")
local roundMusic = music.Round
local intermissionMusic = music.Intermission

-- Round & Point settings
local INTERMISSION_TIME = 20
local ROUND_TIME = 120
local INTERVAL = 1
local TOP_PLAYERS_AMOUNT = 10
local RANKING_ABBREVIATIONS = GameConfig.RANKING_ABBREVIATIONS
local RANKING_COLORS = {
	Color3.fromRGB(255, 215, 0),
	Color3.fromRGB(192, 192, 192),
	Color3.fromRGB(205, 127, 50)
}
local REQUIRED_PLAYERS = 2
local DOUBLE_POINTS_TIME = 60 -- seconds left when points double

-- Spawn settings
local SPAWN_RING_RADIUS = 110 -- studs from MapCenter; clear of green tier (~70), inside arena (~168)
local SPAWN_ANCHOR_TIME = GameConfig.SPAWN_ANCHOR_TIME -- seconds held in the air

-- Platform hitboxes
local platformHitboxes = {
	[arena:WaitForChild("PurpleHitbox")] = 1,
	[arena:WaitForChild("GreenHitbox")] = 2,
	[arena:WaitForChild("RedHitbox")] = 3
}

-- State variables
local roundOngoing = false
local endRound = false
local startRound = false
local leadingPlayer = nil
local leadingPlayerDuration = 0
local leadingPlayerHighlightConnection = nil
local lastSentLeader = nil -- leader last sent to clients, to skip unchanged updates
local playersOnPlatform = {}
local intermissionComplete = false
local doublePoints = false
local ringAngles = {} -- round start slots on the spawn ring
local characterAddedConnections = {}

-- Helper functions --
-- Platform detection, only checks character parts (filter set each tick)
local hitboxOverlapParams = OverlapParams.new()
hitboxOverlapParams.FilterType = Enum.RaycastFilterType.Include

local function getHitboxPlayers(hitbox)
	local hitParts = workspace:GetPartBoundsInBox(hitbox.CFrame, hitbox.Size, hitboxOverlapParams)
	local playersInHitbox = {}

	for _, part in ipairs(hitParts) do
		local character = part:FindFirstAncestorOfClass("Model")

		if character then
			local player = Players:GetPlayerFromCharacter(character)

			if player then
				playersInHitbox[player] = true
			end
		end
	end

	return playersInHitbox
end

-- Check if a player is held in the air after spawning
local function isSpawnAnchored(player)
	local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return rootPart ~= nil and rootPart.Anchored
end

--[[
Places a character on the spawn ring facing MapCenter and holds it in the air

Params:
	character: The spawned character
	angle: Position on the ring in radians
]]
local function spawnInRing(character, angle)
	-- Wait for the character to be in the workspace
	if not character.Parent then
		character.AncestryChanged:Wait()
	end

	local rootPart = character:WaitForChild("HumanoidRootPart", 5)
	if not rootPart then
		warn("[RoundManager] No HumanoidRootPart on spawned character")
		return
	end

	-- Get ring position at MapCenter height, facing the center
	local center = mapCenter.Position
	local position = center + Vector3.new(math.cos(angle), 0, math.sin(angle)) * SPAWN_RING_RADIUS
	local lookAt = Vector3.new(center.X, position.Y, center.Z)

	rootPart.Anchored = true
	character:PivotTo(CFrame.lookAt(position, lookAt))

	-- Release after the hold
	task.delay(SPAWN_ANCHOR_TIME, function()
		if rootPart.Parent then
			rootPart.Anchored = false
		end
	end)
end

-- Spawn in the ring while a round is ongoing
local function onCharacterAdded(player, character)
	if not ReplicatedStorage:GetAttribute("GameOngoing") then
		ringAngles[player] = nil
		return
	end

	-- Use the round start slot if there is one, otherwise a random point
	local angle = ringAngles[player] or math.random() * 2 * math.pi
	ringAngles[player] = nil

	spawnInRing(character, angle)
end

-- Change round status (Walls, teleportation, UI)
local function changeRoundStatus(status)
	roundOngoing = status
	doublePoints = false
	game.ReplicatedStorage:SetAttribute("GameOngoing", status)

	-- Activate or deactivate walls
	for _, wall in pairs(CollectionService:GetTagged("ArenaWall")) do
		wall.CanCollide = not status
		
		if status then
			wall.Transparency = 1
		else
			wall.Transparency = 0.5
		end
	end

	-- Teleport players out of arena if round ends
	if status then
		-- Update leader UI
		updateLeaderEvent:FireAllClients(nil, false)
		lastSentLeader = nil
		
		-- Reset players on platform
		playersOnPlatform = {}

		-- Respawn players evenly around the ring
		local ringPlayers = {}
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character then
				table.insert(ringPlayers, player)
			end
		end

		local angleOffset = math.random() * 2 * math.pi
		for index, player in ipairs(ringPlayers) do
			ringAngles[player] = angleOffset + (index - 1) / #ringPlayers * 2 * math.pi
			task.spawn(player.LoadCharacter, player)
		end
	else
		for _, player:Player in pairs(Players:GetChildren()) do
			if player.Character then
				--[[local spawns = spawnLocations:GetChildren()
				local location = spawns[math.random(1, #spawns)]

				player.Character:PivotTo(location.CFrame + Vector3.new(0, 2, 0))]]
				
				--Respawn players instead of teleporting to remove tools
				--Spawned so the round end doesn't wait on every respawn
				task.spawn(player.LoadCharacter, player)
			end
		end
	end	
	
	--Clear powerups
	for _, powerups in game.Workspace.Powerups:GetChildren() do
		powerups:Destroy()
	end
end

-- Reset round stats and get leading players
local function resetRound()
	local leadingPlayers = {leadingPlayer}

	for _, player in pairs(Players:GetPlayers()) do
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then continue end

		local duration = leaderstats:FindFirstChild("Duration")
		if not duration then continue end

		local currentDuration = duration.Value -- Store value before resetting for tie checks

		-- Pass over any leading players already in the table
		if not table.find(leadingPlayers, player) then
			-- Add to table if duration matches leading player's duration
			if currentDuration >= leadingPlayerDuration and leadingPlayerDuration > 0 then
				table.insert(leadingPlayers, player)
			end
		end
		
		-- Reset highlight for all applicable players
		local highlight = player.Character and player.Character:FindFirstChildOfClass("Highlight")
		
		if highlight then
			highlight:Destroy()
		end

		-- Reset duration of all players
		duration.Value = 0
	end

	-- Remove leader's highlight
	--if leadingPlayer then
	--	if leadingPlayer.Character then
	--		local highlight = leadingPlayer.Character:FindFirstChildOfClass("Highlight")
	--		if highlight then
	--			highlight:Destroy()
	--		end
	--	end
	--end

	-- Stop re-adding the leader's highlight on respawn
	if leadingPlayerHighlightConnection then
		leadingPlayerHighlightConnection:Disconnect()
		leadingPlayerHighlightConnection = nil
	end

	-- Update leader text
	updateLeaderEvent:FireAllClients(leadingPlayer, true)

	-- Reset round variables
	leadingPlayer = nil
	leadingPlayerDuration = 0

	return leadingPlayers
end

-- Events --
-- Admin intervention detection
updateRoundStatusEvent.Event:Connect(function(roundStatus)
	if roundStatus == "Start" and not roundOngoing then
		startRound = true
	elseif roundStatus == "End" and roundOngoing then
		endRound = true
	end
end)

-- Ring spawning
local function onPlayerAdded(player)
	characterAddedConnections[player] = player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)

	-- Leader UI only updates on change, so send the current leader to late joiners
	if roundOngoing then
		updateLeaderEvent:FireClient(player, leadingPlayer, false)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Player disconnect cleanup
Players.PlayerRemoving:Connect(function(player)
	-- Remove ring spawning state
	if characterAddedConnections[player] then
		characterAddedConnections[player]:Disconnect()
		characterAddedConnections[player] = nil
	end
	ringAngles[player] = nil

	-- Remove from platform tracking
	if playersOnPlatform[player] then
		playersOnPlatform[player] = nil
	end

	-- Clear leader data if the leader leaves
	if player == leadingPlayer then
		leadingPlayer = nil
		leadingPlayerDuration = 0
		updateLeaderEvent:FireAllClients(nil, false)
		lastSentLeader = nil

		-- Disconnect the highlight connection to prevent memory leaks
		if leadingPlayerHighlightConnection then
			leadingPlayerHighlightConnection:Disconnect()
			leadingPlayerHighlightConnection = nil
		end
	end
end)

-- Game loops --
-- Point awarding & leader loop
task.spawn(function()
	while task.wait(INTERVAL) do
		-- Make sure there is a round happening
		if not roundOngoing then continue end

		-- Only query character parts, not the spleef tiles
		local characters = {}
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character then
				table.insert(characters, player.Character)
			end
		end
		hitboxOverlapParams.FilterDescendantsInstances = characters

		-- Rebuild players in hitboxes, highest platform wins
		playersOnPlatform = {}
		for hitbox, pointsValue in pairs(platformHitboxes) do
			for player in pairs(getHitboxPlayers(hitbox)) do
				if (playersOnPlatform[player] or 0) < pointsValue then
					playersOnPlatform[player] = pointsValue
				end
			end
		end

		-- Award points, none while held after spawning
		for player, pointValue in pairs(playersOnPlatform) do
			if isSpawnAnchored(player) then continue end

			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats then
				local duration = leaderstats:FindFirstChild("Duration")
				if duration then
					duration.Value += if doublePoints then pointValue * 2 else pointValue
				end
			end
		end

		-- Get current leader and update UI
		for _, player in pairs(Players:GetPlayers()) do
			local leaderstats = player:FindFirstChild("leaderstats")
			if not leaderstats then continue end

			local duration = leaderstats:FindFirstChild("Duration")

			if duration and duration.Value > leadingPlayerDuration then
				-- Remove highlight from previous leading player
				if leadingPlayer and leadingPlayer.Character then
					local previousHighlight = leadingPlayer.Character:FindFirstChildOfClass("Highlight")
					if previousHighlight then
						previousHighlight:Destroy()
					end
				end

				-- Remove highlight function connection
				if leadingPlayerHighlightConnection then
					leadingPlayerHighlightConnection:Disconnect()
				end

				-- Update variables
				leadingPlayer = player
				leadingPlayerDuration = duration.Value

				-- Make leading player glow
				if leadingPlayer.Character then
					local highlight = leaderHighlight:Clone()
					highlight.Parent = leadingPlayer.Character

					-- Add highlight back if leader dies
					leadingPlayerHighlightConnection = leadingPlayer.CharacterAdded:Connect(function(character)
						if leadingPlayer then
							local newHighlight = leaderHighlight:Clone()
							newHighlight.Parent = character
						else
							leadingPlayerHighlightConnection:Disconnect()
						end
					end)
				end
			end
		end

		-- Make sure there is a round ongoing and the leader changed before updating leader
		if roundOngoing and leadingPlayer ~= lastSentLeader then
			lastSentLeader = leadingPlayer
			updateLeaderEvent:FireAllClients(leadingPlayer, false)
		end
	end
end)

-- Counter to store power up spawn cooldown
-- When this reaches 0, a request to make a random powerup will be sent
local powerupSpawnCounter = 10


-- Main Timer Loop
local function timer()
	-- End round
	changeRoundStatus(false)

	-- Update rankings leaderboard BEFORE resetting scores
	local playerDurations = {}
	local top = {}
	local topPlayerIds = {}
	local topDurations = {}
	local topNames = {}

	-- Get players and their durations
	for _, player in pairs(Players:GetPlayers()) do
		local leaderstats = player:FindFirstChild("leaderstats")

		if leaderstats then
			if leaderstats.Duration.Value > 0 then
				table.insert(playerDurations, {
					player = player,
					duration = leaderstats.Duration.Value
				})
			end
		end
	end

	-- Sort scores in descending order
	table.sort(playerDurations, function(a, b)
		return a.duration > b.duration
	end)

	-- Get top ten entries
	for i = 1, math.min(TOP_PLAYERS_AMOUNT, #playerDurations) do
		top[i] = playerDurations[i].player
		topPlayerIds[i] = playerDurations[i].player.UserId
		topDurations[i] = playerDurations[i].duration
		topNames[i] = playerDurations[i].player.Name
	end

	-- Testing results leaderboard
	sendRoundResultsEvent:FireAllClients(topPlayerIds, topDurations, topNames)

	-- Build ranking slots once, then copy them onto every board
	local rankingSlots = {}
	for rank, player in ipairs(top) do
		local rankingSlot = rankingSlotTemplate:Clone()

		-- Update with player's avatar profile picture (thumbnail URL, no web call)
		rankingSlot.ProfilePicture.Image = `rbxthumb://type=AvatarHeadShot&id={player.UserId}&w=150&h=150`

		-- Update with username and rank
		rankingSlot.LayoutOrder = rank
		rankingSlot.PlayerName.Text = player.Name

		if RANKING_ABBREVIATIONS[rank] then
			rankingSlot.Ranking.Text = `{rank}{RANKING_ABBREVIATIONS[rank]}`
			rankingSlot.BackgroundColor3 = RANKING_COLORS[rank]
		else
			rankingSlot.Ranking.Text = `{rank}th`
		end

		rankingSlots[rank] = rankingSlot
	end

	-- Update rankings boards
	for _, board in pairs(rankingsBoards:GetChildren()) do
		local rankingsFrame = board.Screen.RankingsGui.Frame

		-- Reset board first
		for _, element in pairs(rankingsFrame:GetChildren()) do
			if element:IsA("Frame") then
				element:Destroy()
			end
		end

		-- Put ranking slots onto board
		for _, rankingSlot in ipairs(rankingSlots) do
			rankingSlot:Clone().Parent = rankingsFrame
		end
	end

	-- Reset scores and get player(s) with most duration
	local leadingPlayers = resetRound()
	if leadingPlayers then
		for _, player in pairs(leadingPlayers) do
			-- Add win
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats then
				leaderstats.Wins.Value += 1
			end
		end
	end

	-- Play intermission music
	roundMusic:Stop()
	intermissionMusic:Play()

	-- Run intermission
	repeat
		local playerDropped = false

		for i = INTERMISSION_TIME, 0, -1 do
			if #Players:GetPlayers() >= REQUIRED_PLAYERS or startRound then
				-- Check if admin started round
				if startRound then
					startRound = false
					intermissionComplete = true
					break
				end
				updateTimerEvent:FireAllClients(`Intermission: {tostring(i)}`)
				task.wait(1)
			else
				-- If less than required players, wait until enough join
				while #Players:GetPlayers() < REQUIRED_PLAYERS and not startRound do
					updateTimerEvent:FireAllClients(
						`{REQUIRED_PLAYERS} players required to start!`)
					task.wait(1)
				end

				-- Mark that we need to restart the countdown and break the for loop
				playerDropped = true
				break
			end
		end

		if not playerDropped then
			intermissionComplete = true
		end

	until intermissionComplete

	-- Start the round
	changeRoundStatus(true)

	-- Play round music
	intermissionMusic:Stop()
	roundMusic:Play()
	
	powerupSpawnCounter = 1

	-- Run round
	for i = ROUND_TIME, 0, -1 do
		-- Check if admin ended round
		if endRound then 
			endRound = false
			break 
		end
		
		powerupSpawnCounter -= 1
		
		if powerupSpawnCounter <= 0 then
			-- The other term would make powerups spawn faster as the round nears its end
			--powerupSpawnCounter = math.random(5, 10) + (i / ROUND_TIME * 20)
			
			powerupSpawnCounter = math.clamp(10 * (1 - (#game.Players:GetChildren())/100), 3, 10)
			game.ReplicatedStorage.BindableEvents.SpawnPowerup:Fire()
		end

		-- Double points for the last minute
		doublePoints = i <= DOUBLE_POINTS_TIME

		updateTimerEvent:FireAllClients(`Round in Progress: {tostring(i)}`, doublePoints)
		task.wait(1)
	end
end

-- Start the system, looping instead of recursing so the stack doesn't grow each round
while true do
	timer()
end
