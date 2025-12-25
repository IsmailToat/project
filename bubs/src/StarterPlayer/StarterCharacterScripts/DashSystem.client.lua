local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Char:WaitForChild("HumanoidRootPart")
local Humanoid = Char:WaitForChild("Humanoid")
local Camera = workspace.CurrentCamera

--// CONFIGURATION
local Settings = {
	DashKey = Enum.KeyCode.LeftShift,
	MaxCharges = 2,
	CooldownPerCharge = 5, 
	DashSpeed = 100,      
	DashDuration = 0.2,   
	UI_Y_Position = 0.6,  
	BarColor = Color3.fromRGB(0, 255, 255), 
}

local CurrentCharges = Settings.MaxCharges
local ChargeProgress = 0 
local IsDashing = false

-- Raycast for Wall Safety
local Params = RaycastParams.new()
Params.FilterDescendantsInstances = {Char}
Params.FilterType = Enum.RaycastFilterType.Exclude

-- UI Setup (Compressed)
local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "DashUI"; ScreenGui.ResetOnSpawn = false; ScreenGui.Parent = Player:WaitForChild("PlayerGui")
local MainFrame = Instance.new("Frame"); MainFrame.Name = "DashContainer"; MainFrame.AnchorPoint = Vector2.new(0.5, 0.5); MainFrame.Position = UDim2.new(0.5, 0, Settings.UI_Y_Position, 0); MainFrame.Size = UDim2.new(0, 100, 0, 10); MainFrame.BackgroundTransparency = 1; MainFrame.Parent = ScreenGui
local Layout = Instance.new("UIListLayout"); Layout.Padding = UDim.new(0, 5); Layout.FillDirection = Enum.FillDirection.Horizontal; Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center; Layout.VerticalAlignment = Enum.VerticalAlignment.Center; Layout.Parent = MainFrame
local Bars = {}; for i = 1, Settings.MaxCharges do local BarBG = Instance.new("Frame"); BarBG.Size = UDim2.new(0, 40, 0, 6); BarBG.BackgroundColor3 = Color3.fromRGB(50, 50, 50); BarBG.Parent = MainFrame; local BarFill = Instance.new("Frame"); BarFill.Size = UDim2.new(1, 0, 1, 0); BarFill.BackgroundColor3 = Settings.BarColor; BarFill.BorderSizePixel = 0; BarFill.Parent = BarBG; table.insert(Bars, BarFill) end

local function GetDashDirection()
	local LookVector = Camera.CFrame.LookVector
	local RightVector = Camera.CFrame.RightVector
	local ForwardVal = 0; local RightVal = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then ForwardVal = 1 end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then ForwardVal = -1 end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then RightVal = -1 end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then RightVal = 1 end
	local WishDir = (LookVector * ForwardVal) + (RightVector * RightVal)
	if WishDir.Magnitude < 0.1 then return LookVector else return WishDir.Unit end
end

local function Dash()
	if CurrentCharges < 1 or IsDashing then return end
	if Char:GetAttribute("IsWallRunning") == true then return end

	-- Cleanup Physics
	for _, child in pairs(RootPart:GetChildren()) do
		if child.Name == "WallJumpMomentum" or child.Name == "WallVelocity" then child:Destroy() end
	end

	CurrentCharges = CurrentCharges - 1
	IsDashing = true

	local DashDir = GetDashDirection()

	-- Wall Safety Check
	local WallCheck = workspace:Raycast(RootPart.Position, DashDir * 8, Params)
	if WallCheck then
		IsDashing = false
		return 
	end

	local Velocity = Instance.new("BodyVelocity")
	Velocity.Name = "DashVelocity" 
	-- FIX: Changed math.huge to 50000 to prevent physics explosion
	Velocity.MaxForce = Vector3.new(50000, 50000, 50000)
	Velocity.Velocity = DashDir * Settings.DashSpeed
	Velocity.Parent = RootPart

	Debris:AddItem(Velocity, Settings.DashDuration)

	task.delay(Settings.DashDuration, function()
		IsDashing = false
	end)
end

RunService.Heartbeat:Connect(function(dt)
	if CurrentCharges < Settings.MaxCharges then ChargeProgress = ChargeProgress + (dt / Settings.CooldownPerCharge); if ChargeProgress >= 1 then CurrentCharges = CurrentCharges + 1; ChargeProgress = 0 end else ChargeProgress = 0 end
	for i = 1, Settings.MaxCharges do local Bar = Bars[i]; if i <= CurrentCharges then Bar.Size = UDim2.new(1, 0, 1, 0); Bar.Transparency = 0 elseif i == CurrentCharges + 1 then Bar.Size = UDim2.new(ChargeProgress, 0, 1, 0); Bar.Transparency = 0.5 else Bar.Size = UDim2.new(0, 0, 1, 0) end end
end)

UserInputService.InputBegan:Connect(function(Input, Processed)
	if Processed then return end
	if Input.KeyCode == Settings.DashKey then Dash() end
end)