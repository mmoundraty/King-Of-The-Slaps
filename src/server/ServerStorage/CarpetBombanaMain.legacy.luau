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
		
		for i=1, 15, 1 do
			game.ReplicatedStorage.BindableFunctions.FireProjectile:Invoke(
				origin.WorldPosition, 
				(pos - origin.WorldPosition + Vector3.new(math.random(-15, 15), math.random(-15, 15), math.random(-15, 15))).Unit * 250,
				Vector3.new(0, -workspace.Gravity, 0),
				character,
				function(raycastResult:RaycastResult)
					local peel = game.ReplicatedStorage["Banana Peel"]:Clone()
					peel.Parent = game.Workspace
					peel.CFrame = CFrame.new(raycastResult.Position + Vector3.new(0, 2, 0))
					
					task.spawn(function()

						local debounce = true
						local sounds = {peel.Slip1, peel.Slip2, peel.Slip3}

						local function playrandom()
							sounds[math.random(1,3)]:Play()
							return
						end

						peel.Touched:Connect(function(hit)
							if debounce then
								-- Ignore players held in the air after spawning
								local rootPart = hit.Parent:FindFirstChild("HumanoidRootPart")
								if game.Players:GetPlayerFromCharacter(hit.Parent) and rootPart and rootPart.Anchored then
									return
								end

								if hit.Parent:FindFirstChildOfClass("Humanoid") then
									debounce = false
									hit.Parent:FindFirstChildOfClass("Humanoid").PlatformStand = true
									hit.CFrame = CFrame.new(hit.Position + Vector3.new(0,math.random(3,8),0), peel.Position)
									playrandom()
									wait(2)

									hit.Parent:FindFirstChildOfClass("Humanoid").PlatformStand = false
									wait(1)
									debounce = true
								end


							end
						end)
					end)

					game.Debris:AddItem(peel, 5)
				end,
				game.ReplicatedStorage.BananaProjectile
			)
			
			task.wait()
		end
		
		origin.Smoke.Enabled = true
		task.wait(0.25)
		origin.Smoke.Enabled = false
	end
end)