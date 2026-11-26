
local powerupFolder = game.ReplicatedStorage.Powerups

--Returns true if player has a powerup
--For now, this is just determined by if the player has more than 1 tool (the slap hand)
local function plrHasPowerup(plr:Player)
	local toolCount = 0
	
	if plr.Character and plr.Character:FindFirstChildOfClass("Tool") then
		toolCount += 1
	end
	
	if toolCount + #plr.Backpack:GetChildren() > 1 then
		return true
	end
	return false
end

--Try giving powerup
--Returns true if actually given and false otherwise
local function givePowerup(plr:Player, tool, duration, powerup)
	--Checks before giving powerup
	--Player should exist, is alive, and have no powerups
	if plr and plr.Character then
		if plr.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
			return false
		end
		if plrHasPowerup(plr) then
			return false
		end
	else
		return false
	end

	local toolClone = tool:Clone()

	local equippedTool = plr.Character:FindFirstChildOfClass("Tool")
	if equippedTool then
		equippedTool.Parent = plr.Backpack
	end

	toolClone.Parent = plr.Character
	--game.Debris:AddItem(toolClone, duration)
	powerup:Destroy()
	
	task.wait(duration)
	
	toolClone.Parent = game.ReplicatedStorage
	task.wait()
	toolClone:Destroy()
	
	--Bro why doesn't speed coil reset aioukjokl;m;sadji
	--Character can be gone after the wait (left the game)
	local human = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
	if human then
		human.WalkSpeed = 16
	end
	
	return true
end

local functionTable = {
	[powerupFolder.BananaPowerup] = function(plr:Player, powerup)
		return givePowerup(plr, game.ServerStorage.BananaPeel, 20, powerup)
	end,
	[powerupFolder.BazookaPowerup] = function(plr:Player, powerup)
		return givePowerup(plr, game.ServerStorage.Bazooka, 20, powerup)
	end,
	[powerupFolder.SpeedPowerup] = function(plr:Player, powerup)
		return givePowerup(plr, game.ServerStorage.SpeedCoil, 20, powerup)
	end,
	[powerupFolder.GravityPowerup] = function(plr:Player, powerup)
		return givePowerup(plr, game.ServerStorage["Gravity Coil"], 20, powerup)
	end,
}

local powerupList = powerupFolder:GetChildren()

local allSpots = {}
for i, v in pairs(game.Workspace.Spleef:GetDescendants()) do
	if v:IsA("Part") then
		table.insert(allSpots, v)
	end
end

local PLRS_PER_POWERUP = 3

game.ReplicatedStorage.BindableEvents.SpawnPowerup.Event:Connect(function()
	if #game.Workspace.Powerups:GetChildren() >= #game.Players:GetChildren() / PLRS_PER_POWERUP then
		return
	end
	
	local powerupTemp:Part = powerupList[math.random(1, #powerupList)]
	local powerup = powerupTemp:Clone()
	powerup.Parent = game.Workspace.Powerups
	
	local targetSpot = allSpots[math.random(1, #allSpots)]
	powerup.CFrame = CFrame.new(targetSpot.Position + Vector3.new(0, 2, 0))
	
	task.spawn(function()
		local claimed = false
		
		powerup.Touched:Connect(function(part)
			if claimed then
				return
			end
			local plr = game.Players:GetPlayerFromCharacter(part.Parent)

			if plr then
				local result = functionTable[powerupTemp](plr, powerup)
				
				if result then
					claimed = true
				end
			end
		end)
	end)
end)

