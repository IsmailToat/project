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
	Strength = 60,         -- Vertical Power
	ForwardAssist = 60,     -- Horizontal Power (Low enough to not be a dash)
	Cooldown = 3,           

	-- UI Settings
	BarWidth = 200,
	BarHeight = 10,
	BarColor = Color3.fromRGB(0, 255, 100), 
	BgColor = Color3.fromRGB(50, 50, 50),
}

--// STATE
local CurrentCooldown = Settings.Cooldown 
local CanDoubleJump = true

--// UI SETUP
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DoubleJumpUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

local BarContainer = Instance.new("Frame")
BarContainer.Name = "Container"
BarContainer.AnchorPoint = Vector2.new(0.5, 1)
BarContainer.Position = UDim2.new(0.5, 0, 0.85, 0) 
BarContainer.Size = UDim2.new(0, Settings.BarWidth, 0, Settings.BarHeight)
BarContainer.BackgroundColor3 = Settings.BgColor
BarContainer.BorderSizePixel = 0
BarContainer.Parent = ScreenGui

local CornerBG = Instance.new("UICorner")
CornerBG.CornerRadius = UDim.new(1, 0)
CornerBG.Parent = BarContainer

local FillBar = Instance.new("Frame")
FillBar.Name = "Fill"
FillBar.Size = UDim2.new(1, 0, 1, 0) 
FillBar.BackgroundColor3 = Settings.BarColor
FillBar.BorderSizePixel = 0
FillBar.Parent = BarContainer

local CornerFill = Instance.new("UICorner")
CornerFill.CornerRadius = UDim.new(1, 0)
CornerFill.Parent = FillBar

--// FUNCTIONS

local function PerformDoubleJump()
	if not CanDoubleJump then return end

	local IsGrounded = (Humanoid.FloorMaterial ~= Enum.Material.Air)
	local IsWallRunning = Char:GetAttribute("IsWallRunning")

	if IsGrounded or IsWallRunning then return end

	-- Reset Cooldown
	CurrentCooldown = 0
	CanDoubleJump = false
	FillBar.BackgroundColor3 = Color3.fromRGB(100, 100, 100) 

	-- Clean up old physics 
	for _, child in pairs(RootPart:GetChildren()) do
		if child.Name == "WallJumpMomentum" or child.Name == "WallVelocity" then
			child:Destroy()
		end
	end

	-- Calculate Direction
	-- 1. Get Camera Direction (Horizontal only)
	local LookDir = Camera.CFrame.LookVector
	local HorizontalLook = Vector3.new(LookDir.X, 0, LookDir.Z).Unit

	-- 2. Combine Upward Strength + Slight Forward Assist
	local JumpVector = Vector3.new(0, Settings.Strength, 0) + (HorizontalLook * Settings.ForwardAssist)

	-- Apply Force
	local CurrentVel = RootPart.AssemblyLinearVelocity
	-- Reset Y velocity so the jump feels consistent, keep X/Z momentum
	RootPart.AssemblyLinearVelocity = Vector3.new(CurrentVel.X, 0, CurrentVel.Z) 

	local BV = Instance.new("BodyVelocity")
	BV.Name = "DoubleJumpForce"
	BV.MaxForce = Vector3.new(50000, 50000, 50000) -- Allow X/Z force now
	BV.Velocity = JumpVector
	BV.Parent = RootPart

	Debris:AddItem(BV, 0.15) 

	local Sound = Instance.new("Sound")
	Sound.SoundId = "rbxassetid://12222200" 
	Sound.Volume = 0.5
	Sound.Parent = RootPart
	Sound:Play()
	Debris:AddItem(Sound, 1)
end

--// LOOPS

RunService.Heartbeat:Connect(function(dt)
	-- Cooldown Logic
	if CurrentCooldown < Settings.Cooldown then
		CurrentCooldown = CurrentCooldown + dt
		if CurrentCooldown > Settings.Cooldown then
			CurrentCooldown = Settings.Cooldown
		end
	end

	-- Check Availability
	if CurrentCooldown >= Settings.Cooldown then
		if not CanDoubleJump then
			CanDoubleJump = true
			FillBar.BackgroundColor3 = Settings.BarColor 
		end
	end

	-- Update UI Size
	local Percent = CurrentCooldown / Settings.Cooldown
	FillBar.Size = UDim2.new(Percent, 0, 1, 0)
end)

--// INPUT

UserInputService.InputBegan:Connect(function(Input, Processed)
	if Processed then return end

	if Input.KeyCode == Enum.KeyCode.Space then
		PerformDoubleJump()
	end
end)