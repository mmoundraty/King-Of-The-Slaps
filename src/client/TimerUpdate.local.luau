-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Remote events
local updateTimerEvent = ReplicatedStorage:WaitForChild("RemoteEvents").UpdateTimer

-- UI references
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local countdownGui = playerGui:WaitForChild("Countdown")
local timerLabel = countdownGui:WaitForChild("Frame").TextLabel
local doublePointsFrame = countdownGui:WaitForChild("DoublePoints")

updateTimerEvent.OnClientEvent:Connect(function(text, doublePoints)
	timerLabel.Text = text

	-- Show 2x points label in the last minute, hidden during intermission
	doublePointsFrame.Visible = doublePoints == true
end)
