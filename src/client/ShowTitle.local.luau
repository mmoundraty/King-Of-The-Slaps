local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainMenu = playerGui:WaitForChild("MainMenu")

local blur = game.Lighting:WaitForChild("Blur")
blur.Enabled = true

local player = game.Players.LocalPlayer
local camera = game.Workspace.CurrentCamera
local camerapart = game.Workspace:WaitForChild("CameraPart")

if camerapart then
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = camerapart.CFrame
else
	warn("CameraPart not found")
end

mainMenu.Enabled = true