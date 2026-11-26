-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Shared settings
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- Remote events
local sendRoundResultsEvent = ReplicatedStorage:WaitForChild("RemoteEvents").SendRoundResults

-- Assets
local runnerUpRankingSlot = ReplicatedStorage:WaitForChild("Assets").RunnerUpRankingSlot

-- UI references
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local resultsLeaderboardUi = playerGui:WaitForChild("ResultsLeaderboard")
local topThreeFrame = resultsLeaderboardUi.Frame.TopThree
local topThreeSlots = {
	topThreeFrame.First,
	topThreeFrame.Second,
	topThreeFrame.Third
}
local runnerUpsFrame = resultsLeaderboardUi.Frame.RunnerUps
local exitButton = resultsLeaderboardUi.Frame.ExitButton

-- Constants
local RANKING_ABBREVIATIONS = GameConfig.RANKING_ABBREVIATIONS
local EXIT_TIME = 10

-- Update round results UI
sendRoundResultsEvent.OnClientEvent:Connect(function(playerIds, playerDurations, playerNames)
	-- Clear top three slots
	for rank, slot in pairs(topThreeSlots) do
		slot.Character.Image = ""
		slot.Duration.Text = ""
		slot.PlayerName.Text = ""
		slot.Rank.Text = `{rank}{RANKING_ABBREVIATIONS[rank]}`
	end
	
	-- Clear runner up slots
	for _, slot in pairs(runnerUpsFrame:GetChildren()) do
		if slot:IsA("Frame") then
			slot:Destroy()
		end
	end
	
	-- Iterate through players and assign them their appropriate rank
	for rank, playerId in ipairs(playerIds) do
		-- Name comes from the server so players who already left still show
		local playerName = playerNames and playerNames[rank] or ""
		
		if rank <= 3 then
			local slot = topThreeSlots[rank]
			
			-- Update with player's avatar profile picture (thumbnail URL, no web call)
			slot.Character.Image = `rbxthumb://type=Avatar&id={playerId}&w=420&h=420`
			
			-- Update text labels
			slot.PlayerName.Text = playerName
			slot.Rank.Text = `{rank}{RANKING_ABBREVIATIONS[rank]}`
			slot.Duration.Text = `{playerDurations[rank]} points`
		else
			local slot = runnerUpRankingSlot:Clone()
			
			-- Update with player's avatar profile picture (thumbnail URL, no web call)
			slot.ProfilePicture.Image = `rbxthumb://type=AvatarHeadShot&id={playerId}&w=150&h=150`
			
			-- Update text labels
			slot.PlayerName.Text = playerName
			slot.Ranking.Text = `{rank}th`
			slot.Duration.Text = `{playerDurations[rank]} points`
			
			-- Move to runner ups frame
			slot.Parent = runnerUpsFrame
		end
	end
	
	-- Show leaderboard UI
	resultsLeaderboardUi.Enabled = true
	
	-- TODO: Add button to exit leaderboard UI
	-- and make UI close automatically after a few seconds
	task.spawn(function()
		for i = EXIT_TIME, 0, -1 do
			exitButton.Text = `Exit ({i})`
			task.wait(1)
		end
		
		resultsLeaderboardUi.Enabled = false
	end)
end)

exitButton.MouseButton1Click:Connect(function()
	resultsLeaderboardUi.Enabled = false
end)
