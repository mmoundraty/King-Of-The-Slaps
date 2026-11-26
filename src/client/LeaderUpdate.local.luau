-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Get the player
local player = Players.LocalPlayer

-- Remote events
local updateLeaderEvent = ReplicatedStorage:WaitForChild("RemoteEvents").UpdateLeader

-- UI References
local playerGui = player:WaitForChild("PlayerGui")
local leaderGui = playerGui:WaitForChild("Leader")
local leaderTextLabel = leaderGui:WaitForChild("Frame").TextLabel

-- Update
updateLeaderEvent.OnClientEvent:Connect(function(leadingPlayer, roundEnded)
	if roundEnded then
		if leadingPlayer then
			leaderTextLabel.Text = `Last Round's Winner: {leadingPlayer.Name}`
		else
			leaderTextLabel.Text = `Last Round's Winner: No one!`
		end
	elseif leadingPlayer then
		leaderTextLabel.Text = `Current Leader: {leadingPlayer.Name}`
	else
		leaderTextLabel.Text = "Current Leader: N/A"
	end
end)
