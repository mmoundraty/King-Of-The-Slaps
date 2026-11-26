game.Players.PlayerAdded:Connect(function(player)
	local leaderstats = Instance.new("Folder")	
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local duration = Instance.new("IntValue")
	duration.Name = "Duration"
	duration.Value = 0
	duration.Parent = leaderstats
	
	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Value = 0
	wins.Parent = leaderstats
	
	local spleefFolder = game.Workspace:WaitForChild("Spleef")
	--local partDetection = spleefFolder.detection
	
	local debounce = false
	
	local function incrementValue() 
		if debounce == false then
			duration.Value += 1
			debounce = true
		end
		task.wait(1)
		debounce = false
	end
end)
