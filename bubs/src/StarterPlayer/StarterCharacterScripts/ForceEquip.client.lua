local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Char:WaitForChild("Humanoid")

-- 1. Disable Backpack UI (So they can't unequip manually)
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

-- 2. Force Equip Loop
-- We check every frame to ensure the sword is in hand
RunService.Heartbeat:Connect(function()
	local Tool = Char:FindFirstChild("NeonBlade")

	-- If sword is not in hand, check if it's in the backpack
	if not Tool then
		local BackpackTool = Player.Backpack:FindFirstChild("NeonBlade")
		if BackpackTool then
			Humanoid:EquipTool(BackpackTool)
		end
	end
end)