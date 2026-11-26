local attachmentCFrames = {
	--HEAD
	["Neck"] = {CFrame.new(0, .75, 0, 0, -1, 0, 1, 0, -0, 0, 0, 1), CFrame.new(0, -0.5, 0, 0, -1, 0, 1, 0, -0, 0, 0, 1)},	
	--ARMS	
	["LeftShoulder"] = {CFrame.new(-.75, 0.75, 0), CFrame.new(0, 0.75, 0)},
	["RightShoulder"] = {CFrame.new(.75, 0.75, 0), CFrame.new(-0, 0.75, 0)},
	--
	["LeftElbow"] = {CFrame.new(-0, 0, 0), CFrame.new(0, 0.6, 0)},
	["RightElbow"] = {CFrame.new(0, 0, 0), CFrame.new(-0, 0.6, 0)},
	--
	["LeftWrist"] = {CFrame.new(-0, 0, 0), CFrame.new(0, .6, 0)},
	["RightWrist"] = {CFrame.new(0, 0, 0), CFrame.new(-0, .6, 0)},	
	--LEGS	
	["LeftHip"] = {CFrame.new(-0.5, -0, 0), CFrame.new(0, .75, 0)},
	["RightHip"] = {CFrame.new(0.5, -0, 0), CFrame.new(0, .75, 0)},	
	--
	["LeftKnee"] = {CFrame.new(-0, -0, 0), CFrame.new(0, .6, 0)},
	["RightKnee"] = {CFrame.new(0, -0, 0), CFrame.new(0, .6, 0)},
	--
	["LeftAnkle"] = {CFrame.new(-0, -0, 0), CFrame.new(0, .6, 0)},
	["RightAnkle"] = {CFrame.new(0, -0, 0), CFrame.new(0, .6, 0)},	
	--TORSO	
	["Root"] = {CFrame.new(0, 0, 0), CFrame.new(0, 0, 0)},
	--["Waist"] = {CFrame.new(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0), CFrame.new(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)},
}


--Built the first time a character is ragdolled, not on spawn, so mass respawns stay cheap
local function initChar(character)
	local hum = character:FindFirstChild("Humanoid")
	if not hum then return end
	if character:GetAttribute("RagdollRigged") then return end
	character:SetAttribute("RagdollRigged", true)

	for _, motor in character:GetDescendants() do
		if motor:IsA("Motor6D") and attachmentCFrames[motor.Name] then

			local a0 = Instance.new("Attachment")
			local a1 = Instance.new("Attachment")

			a0.CFrame = attachmentCFrames[motor.Name][1]
			a1.CFrame = attachmentCFrames[motor.Name][2]

			a0.Name = "RagdollAttachment"
			a1.Name = "RagdollAttachment"

			a0.Parent = motor.Part0
			a1.Parent = motor.Part1

			local rp = Instance.new("Part")
			rp.Name = "ColliderPart"
			rp.Size = motor.Part1.Size / 1.7
			rp.Massless = true
			rp.CFrame = motor.Part1.CFrame
			rp.Transparency = 1
			rp.CanCollide = false
			rp.Parent = motor.Part1

			local wc = Instance.new("WeldConstraint")
			wc.Part0 = rp
			wc.Part1 = motor.Part1
			wc.Parent = rp

			local b = Instance.new("BallSocketConstraint")
			b.Name = "RagdollConstraint"
			b.Attachment0 = a0
			b.Attachment1 = a1
			b.Enabled = false 
			b.Parent = motor.Parent

			motor.Enabled = true
		end
	end
end

local function replaceJoints(char, hum) 
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	hum.PlatformStand = true
	hum.AutoRotate = false
	hrp.Massless = true
	hrp.CanCollide = false

	for _, motor in char:GetDescendants() do
		if motor:IsA("Motor6D") and attachmentCFrames[motor.Name] then
			motor.Enabled = false
		end

		if motor:IsA("BallSocketConstraint") and motor.Name == "RagdollConstraint" then
			motor.Enabled = true
		end

		if motor:IsA("Part") and motor.Name == "ColliderPart" then
			motor.CanCollide = true
		end
	end
end

local function resetJoints(hum) 
	local char = hum.Parent
	local hrp = char.HumanoidRootPart

	char:SetAttribute("IsRagdoll", false)
	hum.PlatformStand = false
	hum.AutoRotate = true
	hrp.Massless = false
	hrp.CanCollide = true    

	if hum.Health <= 0 then return end --we don't want the player to stand up again if they are dead	

	for _, instance in char:GetDescendants() do
		if instance:IsA("Motor6D") then
			instance.Enabled = true
		end

		if instance:IsA("BallSocketConstraint") and instance.Name == "RagdollConstraint" then
			instance.Enabled = false
		end

		if instance:IsA("Part") and instance.Name == "ColliderPart" then
			instance.CanCollide = false
		end
	end

	hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
end

game.ReplicatedStorage.BindableEvents.RagdollTarget.Event:Connect(function(char:Model)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	
	initChar(char)
	
	local originalHeight = hum.JumpHeight
	local originalPower = hum.JumpPower
	
	hum.PlatformStand = true
	hum.JumpHeight = 0
	hum.JumpPower = 0
	replaceJoints(char, hum)
	
	task.wait(1.5)
		
	resetJoints(hum)
	hum.PlatformStand = false
	hum.JumpHeight = math.max(7.2, originalHeight)
	hum.JumpPower = math.max(50, originalPower)
end)