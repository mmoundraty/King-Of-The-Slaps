local tool = script.Parent
local origin = tool.Handle.Origin
local character

local shootEvent = tool:WaitForChild("Shoot")

local tweenService = game:GetService("TweenService")

local config = tool.Configuration
local speed = config.Speed.Value
local lifetime = config.Lifetime.Value
local radius = config.Radius.Value

tool.Equipped:Connect(function()
	character = tool.Parent
end)

tool.Unequipped:Connect(function()
	character = nil
end)

local overlapParam = OverlapParams.new()
overlapParam.FilterType = Enum.RaycastFilterType.Exclude
overlapParam.FilterDescendantsInstances = {game.Workspace.Arena}
overlapParam.RespectCanCollide = false

local function sweep(hitCenter:Vector3, hitRadius, AttackerHumanoid)	
	local hitParts = game.Workspace:GetPartBoundsInRadius(hitCenter, hitRadius, overlapParam)

	local results = {}

	for i, v in pairs(hitParts) do
		local targetModel = v.Parent
		if targetModel == character then
			continue
		end

		local human:Humanoid = targetModel:FindFirstChildOfClass("Humanoid")

		if human then --and human ~= AttackerHumanoid then
			if not table.find(results, targetModel) then
				table.insert(results, targetModel)
			end
		end
	end

	return results
end

shootEvent.OnServerEvent:Connect(function(plr, pos)
	if character:WaitForChild("Humanoid").Health > 0 then
		tool.Handle.Fire:Play()
		
		game.ReplicatedStorage.BindableFunctions.FireProjectile:Invoke(
			origin.WorldPosition, 
			(pos - origin.WorldPosition).Unit * 100,
			Vector3.new(0, 0, 0),
			character,
			function(raycastResult:RaycastResult)
				wait(0.025)
				local expolsionVisual = Instance.new("Part")
				expolsionVisual.Parent = workspace
				expolsionVisual.Name = "Explosion"
				expolsionVisual.Shape = Enum.PartType.Ball
				expolsionVisual.Material = Enum.Material.Neon
				expolsionVisual.Size = Vector3.new(radius,radius,radius)
				expolsionVisual.Position = raycastResult.Position
				expolsionVisual.Color = Color3.fromRGB(250, 164, 59)
				expolsionVisual.Massless = true
				expolsionVisual.Anchored = true
				expolsionVisual.CanCollide = false
				expolsionVisual.CanQuery = false
				expolsionVisual.CanTouch = false
				expolsionVisual.CastShadow = false
				game.Debris:AddItem(expolsionVisual,5)
				local explosion = Instance.new("Explosion")
				explosion.BlastRadius = radius/2
				explosion.BlastPressure = radius*4500
				explosion.DestroyJointRadiusPercent = 0
				explosion.ExplosionType = Enum.ExplosionType.NoCraters
				explosion.Visible = false
				explosion.Position = expolsionVisual.Position
				explosion.Parent = expolsionVisual

				local hitHumans = sweep(expolsionVisual.Position, radius, nil)

				for i, v in pairs(hitHumans) do
					-- Ignore players held in the air after spawning
					local rootPart = v:FindFirstChild("HumanoidRootPart")
					if game.Players:GetPlayerFromCharacter(v) and rootPart and rootPart.Anchored then
						continue
					end

					game.ReplicatedStorage.BindableEvents.RagdollTarget:Fire(v)
				end


				local sound = game.ReplicatedStorage.RocketStuff.Explode:Clone()
				sound.Parent = expolsionVisual
				sound.PlaybackSpeed = 30/radius
				sound.Volume = .7
				sound:Play()
				--explosion tween--
				local E_TI = TweenInfo.new(0.3,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,false)
				local E_TV = {
					Size = Vector3.new(0.001,0.001,0.001),
					Color = Color3.fromRGB(242, 105, 36),
				}
				local E_T = tweenService:Create(expolsionVisual, E_TI, E_TV)
				E_T:Play()
			end,
			game.ReplicatedStorage.Rocket
		)
		
		origin.Smoke.Enabled = true
		task.wait(0.25)
		origin.Smoke.Enabled = false
	end
end)