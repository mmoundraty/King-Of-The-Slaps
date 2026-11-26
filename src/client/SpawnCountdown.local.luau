-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared settings
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- UI references
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local spawnCountdownGui = playerGui:WaitForChild("SpawnCountdown")
local countdownFrame = spawnCountdownGui:WaitForChild("Frame")
local countdownLabel = countdownFrame:WaitForChild("TextLabel")

-- Settings
local ANCHOR_TIME = GameConfig.SPAWN_ANCHOR_TIME -- seconds held in the air after spawning
local GO_TIME = 1     -- seconds "GO!" stays up

-- State
local countdownId = 0 -- bumped to cancel a running countdown
local characterConnections = {}

-- Hide the countdown and cancel any running one
local function hideCountdown()
	countdownId += 1
	countdownFrame.Visible = false
end

-- Count down while held in the air after spawning
local function startCountdown()
	countdownId += 1
	local id = countdownId

	countdownFrame.Visible = true
	for i = ANCHOR_TIME, 1, -1 do
		if id ~= countdownId then return end

		countdownLabel.Text = tostring(i)
		task.wait(1)
	end
end

-- Show "GO!" on release
local function showGo()
	countdownId += 1
	local id = countdownId

	countdownLabel.Text = "GO!"
	countdownFrame.Visible = true
	task.wait(GO_TIME)

	if id == countdownId then
		countdownFrame.Visible = false
	end
end

-- Stop following the current character
local function clearCharacter()
	for _, connection in ipairs(characterConnections) do
		connection:Disconnect()
	end
	table.clear(characterConnections)
	hideCountdown()
end

-- Follow the spawn hold on each new character
local function onCharacterAdded(character)
	clearCharacter()

	local humanoid = character:WaitForChild("Humanoid", 5)
	local rootPart = character:WaitForChild("HumanoidRootPart", 5)
	if not humanoid or not rootPart or character ~= player.Character then return end

	-- Start or end the countdown with the hold (RoundManager anchors the root part)
	table.insert(characterConnections, rootPart:GetPropertyChangedSignal("Anchored"):Connect(function()
		if rootPart.Anchored then
			startCountdown()
		else
			showGo()
		end
	end))

	-- Stop if killed mid hold, the server still unanchors the body
	table.insert(characterConnections, humanoid.Died:Connect(clearCharacter))

	-- Already anchored before the connection
	if rootPart.Anchored then
		startCountdown()
	end
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end
