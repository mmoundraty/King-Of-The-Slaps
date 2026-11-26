-- Server side of the spleef tiles: owns collision only.
-- The fade/shrink is played by SpleefTilesClient so tweens don't replicate every frame.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local spleef = workspace:WaitForChild("Spleef")

local HOLD_TIMES = {Platform1 = 3.5, Platform2 = 1.5, Platform3 = 1} -- seconds a tile stays gone
local TOUCH_DELAY = 0.5 -- seconds between touch and the tile starting to fall
local RESPAWN_TIME = 5 -- seconds from gone until the tile can fall again
local FADE_TIME = GameConfig.SPLEEF_FADE_TIME

local function setupTile(tile, holdTime)
	local falling = false -- skip touches while this tile is already going

	tile.Touched:Connect(function(otherPart)
		if falling or not otherPart.Parent:FindFirstChildOfClass("Humanoid") then
			return
		end
		falling = true

		task.wait(TOUCH_DELAY)
		tile:SetAttribute("Falling", true) -- clients fade and shrink it
		task.wait(FADE_TIME)

		tile.CanCollide = false
		task.wait(holdTime)
		tile.CanCollide = true

		tile:SetAttribute("Falling", false) -- clients grow it back
		task.wait(RESPAWN_TIME - holdTime)
		falling = false
	end)
end

for platformName, holdTime in HOLD_TIMES do
	for _, tile in spleef:WaitForChild(platformName):GetDescendants() do
		if tile:IsA("Part") then
			setupTile(tile, holdTime)
		end
	end
end
