local tool = script.Parent
local character
local player
local mouse 

local shootEvent = tool:WaitForChild("Shoot")

local debounce = false
local cooldown = 1

tool.Equipped:Connect(function()
	character = tool.Parent
	player = game.Players.LocalPlayer
	mouse = player:GetMouse()
end)

tool.Unequipped:Connect(function()
	character = nil
end)

tool.Activated:Connect(function()
	if debounce then return end
	debounce = true
	mouse.TargetFilter = game.Workspace.Arena
	local mousePos = mouse.Hit.Position
	shootEvent:FireServer(mousePos)
	wait(cooldown)
	debounce = false
end)