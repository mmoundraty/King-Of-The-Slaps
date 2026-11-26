-- Client side of the spleef tiles: plays the fade/shrink when SpleefTiles sets "Falling".
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local spleef = workspace:WaitForChild("Spleef")
local tweenInfo = TweenInfo.new(GameConfig.SPLEEF_FADE_TIME)

-- Weak keys so tiles that stream out can be collected
local setUp = setmetatable({}, {__mode = "k"})

local function setupTile(tile)
	if not tile:IsA("Part") or setUp[tile] then
		return
	end
	setUp[tile] = true

	-- The server never changes Size, so this is always the original
	local originalSize = tile.Size

	local function update(instant)
		local goal = if tile:GetAttribute("Falling")
			then {Transparency = 1, Size = Vector3.zero}
			else {Transparency = 0, Size = originalSize}

		if instant then
			tile.Transparency = goal.Transparency
			tile.Size = goal.Size
		else
			-- A new tween on the same properties replaces the running one
			TweenService:Create(tile, tweenInfo, goal):Play()
		end
	end

	tile:GetAttributeChangedSignal("Falling"):Connect(function()
		update(false)
	end)

	-- Streamed in while already fallen
	if tile:GetAttribute("Falling") then
		update(true)
	end
end

-- Tiles stream in and out (StreamingEnabled), so catch late arrivals too
for _, tile in spleef:GetDescendants() do
	setupTile(tile)
end
spleef.DescendantAdded:Connect(setupTile)
