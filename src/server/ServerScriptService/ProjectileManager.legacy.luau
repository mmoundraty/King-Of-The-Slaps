

local virtualProjectileList = {}

local projectileTemplate = {
	position = nil,
	velocity = nil,
	acceleration = nil,
	shooter = nil,
	hitFunc = nil,
	currTime = 0,
}

local raycastParam = RaycastParams.new()
raycastParam.FilterType = Enum.RaycastFilterType.Exclude
raycastParam.FilterDescendantsInstances = {game.Workspace.Arena}

local MAX_TIME = 100

game["Run Service"].Heartbeat:Connect(function(dt)
	--Iterate backwards so table.remove doesn't skip the next projectile
	for i = #virtualProjectileList, 1, -1 do
		local v = virtualProjectileList[i]
		
		--v = projectileTemplate
		
		--print(i, v)
		
		raycastParam.FilterDescendantsInstances = {game.Workspace.Arena, v.shooter}
		
		local raycastResult = game.Workspace:Raycast(v.position, v.velocity * dt, raycastParam)
		
		if raycastResult then
			v.hitFunc(raycastResult)
			
			table.remove(virtualProjectileList, i)
		elseif v.currTime > MAX_TIME then
			table.remove(virtualProjectileList, i)
		end
		
		v.position = v.position + v.velocity * dt
		v.velocity = v.velocity + v.acceleration * dt


		v.currTime += dt
	end
end)

game.ReplicatedStorage.BindableFunctions.FireProjectile.OnInvoke = function(pos, vel, acc, char, hitFunc, projectile)
	local newProj = table.clone(projectileTemplate)
	
	newProj.position = pos
	newProj.velocity = vel
	newProj.acceleration = acc
	newProj.shooter = char
	newProj.hitFunc = hitFunc
	
	table.insert(virtualProjectileList, newProj)
	
	game.ReplicatedStorage.RemoteEvents.RenderProjectile:FireAllClients(pos, vel, acc, char, projectile)
end