local player = game.Players.LocalPlayer
local character = nil
local humanoid = nil
local rootPart:Part = nil

player.CharacterAdded:Connect(function(char)
	task.wait()
	character = char
	humanoid = character:FindFirstChildOfClass("Humanoid")
	--rootPart = character.PrimaryPart
end)

game.ReplicatedStorage.RemoteEvents.FlingTarget.OnClientEvent:Connect(function(force)
	
	rootPart = player.Character.PrimaryPart
	
	if rootPart then	
		task.wait()
		rootPart.AssemblyLinearVelocity = force --:ApplyImpulse(force)
	end
end)


