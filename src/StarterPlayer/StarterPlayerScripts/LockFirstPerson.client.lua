local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 1. Lock Camera
local function lockCamera()
	if player then
		player.CameraMode = Enum.CameraMode.LockFirstPerson
	end
end
lockCamera()

player:GetPropertyChangedSignal("CameraMode"):Connect(function()
	if player.CameraMode ~= Enum.CameraMode.LockFirstPerson then
		player.CameraMode = Enum.CameraMode.LockFirstPerson
	end
end)

-- 2. Hide Default Cursor
UserInputService.MouseIconEnabled = false

-- 3. Create Custom Crosshair
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CrosshairUI"
ScreenGui.Parent = playerGui
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true -- Ensures it's truly centered ignoring top bar

local Crosshair = Instance.new("Frame")
Crosshair.Name = "Dot"
Crosshair.Size = UDim2.new(0, 4, 0, 4) -- Small 4px dot
Crosshair.Position = UDim2.new(0.5, -2, 0.5, -2) -- Perfectly Centered
Crosshair.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Crosshair.BorderSizePixel = 0
Crosshair.Parent = ScreenGui

-- Optional: Make it round
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(1, 0)
Corner.Parent = Crosshair

-- Cleanup on exit (optional safe-guard)
game:GetService("Players").PlayerRemoving:Connect(function(p)
	if p == player then
		UserInputService.MouseIconEnabled = true
	end
end)