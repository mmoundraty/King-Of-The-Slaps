local CollectionService = game:GetService("CollectionService")

-- Kill any character that touches a part tagged "Killbrick"
local function onTouch(otherPart)
	local model = otherPart:FindFirstAncestorWhichIsA("Model")
	local human = model and model:FindFirstChildWhichIsA("Humanoid")
	if human then
		human.Health = 0
	end
end

local function setup(part)
	if part:IsA("BasePart") then
		part.Touched:Connect(onTouch)
	end
end

for _, part in CollectionService:GetTagged("Killbrick") do
	setup(part)
end
CollectionService:GetInstanceAddedSignal("Killbrick"):Connect(setup)
