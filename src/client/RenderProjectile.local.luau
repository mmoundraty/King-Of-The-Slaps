
local trackerTemplate = {
	position = nil,
	velocity = nil,
	acceleration = nil,
	object = nil,
	char = nil,
	currTime = 0
}
local trackerList = {}

game.ReplicatedStorage.RemoteEvents.RenderProjectile.OnClientEvent:Connect(function(pos, vel, acc, char, projectileTemplate)
	local object = projectileTemplate:Clone()
	object.Parent = game.Workspace.LocalProjectiles
	
	local tracker = table.clone(trackerTemplate)
	
	tracker.position = pos
	tracker.velocity = vel
	tracker.acceleration = acc
	tracker.char = char
	tracker.object = object
	
	table.insert(trackerList, tracker)
end)

local MAX_TIME = 100

local raycastParam = RaycastParams.new()
raycastParam.FilterType = Enum.RaycastFilterType.Exclude
raycastParam.FilterDescendantsInstances = {game.Workspace.Arena}

game["Run Service"].Heartbeat:Connect(function(dt)
	for i, v in pairs(trackerList) do

		--v = projectileTemplate

		--print(i, v)

		raycastParam.FilterDescendantsInstances = {game.Workspace.Arena, v.object, v.char}

		local raycastResult = game.Workspace:Raycast(v.position, v.velocity * dt, raycastParam)
		

		if raycastResult or v.currTime > MAX_TIME then
			v.object:Destroy()

			table.remove(trackerList, i)
		end

		v.object.CFrame = CFrame.new(v.position, v.position + v.velocity)
		
		v.position = v.position + v.velocity * dt
		v.velocity = v.velocity + v.acceleration * dt


		v.currTime += dt
	end
end)
