local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer

--// 1. CREATE UI
-- I HATE NIG
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MovementDashboard"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

-- Main Container
local MainFrame = Instance.new("Frame")
MainFrame.Name = "Container"
MainFrame.AnchorPoint = Vector2.new(0.5, 1)
MainFrame.Position = UDim2.new(0.5, 0, 0.95, 0)
MainFrame.Size = UDim2.new(0, 300, 0, 60)
MainFrame.BackgroundTransparency = 1
MainFrame.Parent = ScreenGui

--// SPEED & ALTITUDE (Existing)
local SpeedContainer = Instance.new("Frame")
SpeedContainer.Name = "SpeedSide"
SpeedContainer.Size = UDim2.new(0.5, -5, 1, 0)
SpeedContainer.BackgroundTransparency = 1
SpeedContainer.Parent = MainFrame

local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(1, 0, 0.6, 0)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "0"
SpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedLabel.TextStrokeTransparency = 0.5
SpeedLabel.Font = Enum.Font.GothamBlack
SpeedLabel.TextSize = 30
SpeedLabel.Parent = SpeedContainer

local SpeedUnit = Instance.new("TextLabel")
SpeedUnit.Position = UDim2.new(0, 0, 0.6, 0)
SpeedUnit.Size = UDim2.new(1, 0, 0.3, 0)
SpeedUnit.BackgroundTransparency = 1
SpeedUnit.Text = "SPD"
SpeedUnit.TextColor3 = Color3.fromRGB(200, 200, 200)
SpeedUnit.Font = Enum.Font.GothamMedium
SpeedUnit.TextSize = 12
SpeedUnit.Parent = SpeedContainer

local AltContainer = Instance.new("Frame")
AltContainer.Name = "AltSide"
AltContainer.Size = UDim2.new(0.5, -5, 1, 0)
AltContainer.Position = UDim2.new(0.5, 5, 0, 0)
AltContainer.BackgroundTransparency = 1
AltContainer.Parent = MainFrame

local AltLabel = Instance.new("TextLabel")
AltLabel.Size = UDim2.new(1, 0, 0.6, 0)
AltLabel.BackgroundTransparency = 1
AltLabel.Text = "0"
AltLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
AltLabel.TextStrokeTransparency = 0.5
AltLabel.Font = Enum.Font.GothamBlack
AltLabel.TextSize = 30
AltLabel.Parent = AltContainer

local AltUnit = Instance.new("TextLabel")
AltUnit.Position = UDim2.new(0, 0, 0.6, 0)
AltUnit.Size = UDim2.new(1, 0, 0.3, 0)
AltUnit.BackgroundTransparency = 1
AltUnit.Text = "ALT"
AltUnit.TextColor3 = Color3.fromRGB(200, 200, 200)
AltUnit.Font = Enum.Font.GothamMedium
AltUnit.TextSize = 12
AltUnit.Parent = AltContainer

local Divider = Instance.new("Frame")
Divider.AnchorPoint = Vector2.new(0.5, 0.5)
Divider.Position = UDim2.new(0.5, 0, 0.5, 0)
Divider.Size = UDim2.new(0, 2, 0.8, 0)
Divider.BackgroundTransparency = 0.8
Divider.Parent = MainFrame

--// NEW: TIMING POPUP
local TimingLabel = Instance.new("TextLabel")
TimingLabel.Name = "TimingPopup"
TimingLabel.AnchorPoint = Vector2.new(0.5, 1)
TimingLabel.Position = UDim2.new(0.5, 0, -0.5, 0) -- Above the dashboard
TimingLabel.Size = UDim2.new(1, 0, 0.5, 0)
TimingLabel.BackgroundTransparency = 1
TimingLabel.Text = ""
TimingLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
TimingLabel.TextStrokeTransparency = 0
TimingLabel.Font = Enum.Font.GothamBold
TimingLabel.TextSize = 24
TimingLabel.Parent = MainFrame

--// LOGIC
local MaxSpeedVisual = 80 
local CurrentChar = nil


-- Connect Attribute Listener
local function ConnectChar(Char)
	CurrentChar = Char
	Char:GetAttributeChangedSignal("RollTiming"):Connect(function()
		local MS = Char:GetAttribute("RollTiming")
		local IsPerfect = Char:GetAttribute("RollPerfect")
		ShowTimingFeedback(MS, IsPerfect)
	end)
end

if Player.Character then ConnectChar(Player.Character) end
Player.CharacterAdded:Connect(ConnectChar)

--// RENDER LOOP
RunService.RenderStepped:Connect(function(dt)
	if not CurrentChar then return end
	local RootPart = CurrentChar:FindFirstChild("HumanoidRootPart")
	if not RootPart then return end

	-- Update Speed/Alt
	local Velocity = RootPart.AssemblyLinearVelocity
	local HorizontalSpeed = Vector3.new(Velocity.X, 0, Velocity.Z).Magnitude
	local Altitude = RootPart.Position.Y

	SpeedLabel.Text = math.floor(HorizontalSpeed)
	AltLabel.Text = math.floor(Altitude)
end)