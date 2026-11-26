-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- Remote events
local updateRoundStatusEvent = ReplicatedStorage:WaitForChild("BindableEvents").
	UpdateRoundStatus

-- Remote functions
local remoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local kickPlayerFunc = remoteFunctions.KickPlayer
local banPlayerFunc = remoteFunctions.BanPlayer

-- Group variables
local GROUP_ID = 7386191
local MIN_ADMIN_RANK = 254

Players.PlayerAdded:Connect(function(player)
	-- Check player rank first
	local playerRank = player:GetRankInGroupAsync(GROUP_ID)
	
	if playerRank >= MIN_ADMIN_RANK then
		-- Add admin panel to the player's UI
		local adminPanel = ServerStorage:WaitForChild("Admin").AdminPanel:Clone()
		local playerGui = player:WaitForChild("PlayerGui")
		adminPanel.Parent = playerGui
		
		-- Set up admin panel functionality
		local panelOptions = adminPanel.PanelOptions
		
		adminPanel.ViewPanel.Button.MouseButton1Click:Connect(function()
			panelOptions.Visible = not panelOptions.Visible
		end)
		
		panelOptions.StartButton.MouseButton1Click:Connect(function()
			updateRoundStatusEvent:Fire("Start")
		end)
		
		panelOptions.EndButton.MouseButton1Click:Connect(function()
			updateRoundStatusEvent:Fire("End")
		end)
		
		panelOptions.CarpetBombanaButton.MouseButton1Click:Connect(function()
			local carpetBombana = ServerStorage:FindFirstChild("CarpetBombana"):Clone()
			carpetBombana.Parent = player.Backpack
		end)
	end
end)

-- Kick functionality
kickPlayerFunc.OnServerInvoke = function(admin, playerName)
	if admin:GetRankInGroupAsync(GROUP_ID) < MIN_ADMIN_RANK then return false end
	
	local playerToKick = Players:FindFirstChild(playerName)
	
	if playerToKick then
		playerToKick:Kick("You have been kicked.")
		return true
	else
		return false
	end
end

-- Ban functionality
banPlayerFunc.OnServerInvoke = function(admin, playerName, banMinutes)
	if admin:GetRankInGroupAsync(GROUP_ID) < MIN_ADMIN_RANK then return false end
	
	local playerToBan = Players:FindFirstChild(playerName)
	
	if playerToBan then
		local banMinutes = banMinutes or 5
		local banConfig = {
			UserIds = {playerToBan.UserId},
			Duration = 60 * banMinutes,
			DisplayReason = `Get banned noob!11!1 You are banned for {banMinutes} minutes.`,
			PrivateReason = "Exploiting",
			ApplyToUniverse = true,
			ExcludeAltAccounts = false
		}
		
		local success, result = pcall(function()
			return Players:BanAsync(banConfig)
		end)
		
		return true, banMinutes
	else
		return false
	end
end
