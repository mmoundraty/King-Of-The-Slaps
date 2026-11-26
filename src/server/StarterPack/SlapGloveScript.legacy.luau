local tool = script.Parent
local handle = script.Parent:WaitForChild("Handle")

local plrChar = nil
local plrRootPart:Part = nil

local soundList = handle:WaitForChild("Sounds"):GetChildren()

--for debug
local showHitBox = false

--stats
local SlapRadius = 7
local SlapStrength = 450
local Cooldown = 1

local animation = tool:WaitForChild("Swing")
local swingAnim = nil

local meleeOverlapParam = OverlapParams.new()
meleeOverlapParam.FilterType = Enum.RaycastFilterType.Exclude
meleeOverlapParam.FilterDescendantsInstances = {}
meleeOverlapParam.RespectCanCollide = false

local debounce = false

local function sweep(hitCenter:Vector3, hitRadius, AttackerHumanoid)	
	local hitParts = game.Workspace:GetPartBoundsInRadius(hitCenter, hitRadius, meleeOverlapParam)
	
	--print(hitParts)

	if showHitBox then
		local hitBox = Instance.new("Part")
		hitBox.Size = Vector3.new(hitRadius, hitRadius, hitRadius)
		hitBox.Transparency = 0.5
		hitBox.Color = Color3.new(1, 0, 0)
		hitBox.Anchored = true
		hitBox.CanCollide = false
		hitBox.CanTouch = false
		hitBox.CanQuery = false
		hitBox.CFrame = CFrame.new(hitCenter)
		hitBox.Shape = Enum.PartType.Ball
		hitBox.Parent = game.Workspace
		game.Debris:AddItem(hitBox, 0.5)
	end

	local results = {}

	for i, v in pairs(hitParts) do
		local targetModel = v.Parent
		
		local human:Humanoid = targetModel:FindFirstChildOfClass("Humanoid")
		
		if human and human ~= AttackerHumanoid then
			if not table.find(results, targetModel) then
				table.insert(results, targetModel)
			end
		end
	end
	
	return results
end

local function knockback(character:Model)
	local rootPart:Part = character.PrimaryPart
	local plr = game.Players:GetPlayerFromCharacter(character)
	
	-- Ignore players held in the air after spawning
	if rootPart and rootPart.Anchored then
		return
	end

	if plr then
		local strengthRatio = 1--math.abs(1 - (rootPart.Position - plrRootPart.Position).Magnitude / SlapRadius)
		local flingVector = (rootPart.Position - plrRootPart.Position + Vector3.new(0, 5, 0)).Unit * SlapStrength * strengthRatio

		if rootPart then
			--
			
			game.ReplicatedStorage.BindableEvents.RagdollTarget:Fire(character, flingVector)
			
			game.ReplicatedStorage.RemoteEvents.FlingTarget:FireClient(plr, flingVector)
		end
	end
end

tool.Equipped:Connect(function()
	plrChar = tool.Parent
	plrRootPart = plrChar:WaitForChild("HumanoidRootPart")
	
	swingAnim = plrChar:WaitForChild("Humanoid"):LoadAnimation(animation)
end)

tool.Activated:Connect(function()
	if debounce then
		return
	end
	debounce = true
	
	if swingAnim then
		swingAnim:Play()
	end

	local hitResults = sweep(plrRootPart.Position + plrRootPart.CFrame.LookVector * SlapRadius, SlapRadius, plrChar:FindFirstChildOfClass("Humanoid"))

	if #hitResults > 0 then
		local randomSound = soundList[math.random(1, #soundList)]
		randomSound:Play()
		
		handle.hit:Emit(20)
	end

	for i, v in pairs(hitResults) do
		knockback(v)
	end
	
	task.wait(Cooldown)
	
	debounce = false
end)
