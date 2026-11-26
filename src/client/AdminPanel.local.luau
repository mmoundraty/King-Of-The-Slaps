local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Remote functions
local remoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local kickPlayerFunc = remoteFunctions.KickPlayer
local banPlayerFunc = remoteFunctions.BanPlayer

-- Find admin panel
task.wait(3)
local playerGui = player:FindFirstChild("PlayerGui")
local adminPanel = playerGui:FindFirstChild("AdminPanel")

if adminPanel then
	local panelOptions = adminPanel:FindFirstChild("PanelOptions")
	
	-- Kick functionality
	local kickPanel = adminPanel.KickPanel

	panelOptions.KickButton.MouseButton1Click:Connect(function()
		kickPanel.Visible = not kickPanel.Visible
	end)

	kickPanel.KickButton.MouseButton1Click:Connect(function()
		local playerName = kickPanel.TextBox.Text
		local success = kickPlayerFunc:InvokeServer(playerName)

		if success then
			kickPanel.TextBox.Text = `{playerName} was kicked!`
		else
			kickPanel.TextBox.Text = `{playerName} not found!`
		end
	end)

	-- Ban functionality
	local banPanel = adminPanel.BanPanel

	panelOptions.BanButton.MouseButton1Click:Connect(function()
		banPanel.Visible = not banPanel.Visible
	end)
	
	banPanel.BanButton.MouseButton1Click:Connect(function()
		local banInfo = banPanel.TextBox.Text:split(",")
		local playerName = banInfo[1]
		local banMinutes = tonumber(banInfo[2])
		local success, actualBanTime = banPlayerFunc:InvokeServer(playerName, banMinutes)

		if success then
			banPanel.TextBox.Text = `{playerName} was banned for {actualBanTime} minutes!`
		else
			banPanel.TextBox.Text = `{playerName} not found!`
		end
	end)
end
