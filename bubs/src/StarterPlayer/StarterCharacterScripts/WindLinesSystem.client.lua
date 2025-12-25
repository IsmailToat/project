local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera
local Char = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Char:WaitForChild("HumanoidRootPart")

--// SETTINGS
local Settings = {
	LineCount = 30,          -- Clean count (was 100)
	BaseSize = Vector2.new(80, 2), 

	MinSpeed = 10,           
	MaxSpeed = 100,          
	MaxOpacity = 0.5,        -- Subtle ghost look

	Smoothness = 0.1,        -- Lower = Smoother turns (0.1 is very smooth)
	StretchFactor = 3,       
}

--// UI SETUP
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WindLinesUI"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true 
ScreenGui.DisplayOrder = 0 

local Container = Instance.new("Frame")
Container.Name = "LineContainer"
Container.Size = UDim2.new(1, 0, 1, 0)
Container.BackgroundTransparency = 1
Container.ClipsDescendants = true 
Container.Parent = ScreenGui

--// HELPERS
local Center = Vector2.new(0.5, 0.5)

-- Smooth Dampening Variable
local SmoothedFlow = Vector2.new(0, 0)

-- Function to get spawn pos (donut shape - not too close to center)
local function GetRandomSpawnPos()
	local angle = math.random() * math.pi * 2
	local radius = math.random() * 0.3 + 0.1 -- 10% to 40% away from center
	return Center + Vector2.new(math.cos(angle), math.sin(angle)) * radius
end

--// INITIALIZE LINES WITH GRADIENTS
local Lines = {}

for i = 1, Settings.LineCount do
	local Frame = Instance.new("Frame")
	Frame.Name = "WindStreak"
	Frame.AnchorPoint = Vector2.new(0.5, 0.5) 
	Frame.BackgroundColor3 = Color3.new(1, 1, 1)
	Frame.BorderSizePixel = 0
	Frame.Parent = Container

	-- Add Gradient for "Streak" look
	local Gradient = Instance.new("UIGradient")
	Gradient.Rotation = 0
	-- Fade from Solid (0) to Transparent (1)
	Gradient.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0.0, 1.0), -- Tail (Invisible)
		NumberSequenceKeypoint.new(0.5, 0.5), 
		NumberSequenceKeypoint.new(1.0, 0.0)  -- Head (Visible)
	}
	Gradient.Parent = Frame

	Lines[i] = {
		Frame = Frame,
		Pos = GetRandomSpawnPos(),
		SpeedVariance = math.random() * 0.4 + 0.8 
	}
end

--// MAIN LOOP
RunService.RenderStepped:Connect(function(dt)
	if not RootPart then return end

	local Vel = RootPart.AssemblyLinearVelocity
	local Speed = Vel.Magnitude

	-- 1. Direction Logic
	local FwdSpeed  = Vel:Dot(Camera.CFrame.LookVector)
	local RightSpeed = Vel:Dot(Camera.CFrame.RightVector)
	local UpSpeed    = Vel:Dot(Camera.CFrame.UpVector)

	-- 2. Opacity Calc
	-- Hide if moving BACKWARDS or too slow
	local OpacityScale = math.clamp((Speed - Settings.MinSpeed) / (Settings.MaxSpeed - Settings.MinSpeed), 0, 1)

	if FwdSpeed < 5 then -- Only show when moving forward noticeably
		OpacityScale = 0 
	end

	local FinalOpacity = OpacityScale * Settings.MaxOpacity

	if FinalOpacity <= 0.01 then
		Container.Visible = false
		-- Reset smoothing so it doesn't "snap" when you start running again
		SmoothedFlow = Vector2.new(0,0) 
		return
	else
		Container.Visible = true
	end

	-- 3. Calculate Target Flow
	-- Planar Flow (Strafing)
	local targetPlanarX = -RightSpeed * 0.005
	local targetPlanarY = -UpSpeed * 0.005

	-- Apply Smoothing (Lerp)
	-- We lerp the planar flow so sudden strafes don't snap the lines instantly
	local currentPlanar = Vector2.new(targetPlanarX, targetPlanarY)
	SmoothedFlow = SmoothedFlow:Lerp(currentPlanar, Settings.Smoothness)

	-- 4. Update Each Line
	for _, data in ipairs(Lines) do

		-- Radial Flow (Tunnel Vision)
		local dirFromCenter = (data.Pos - Center)
		if dirFromCenter.Magnitude < 0.01 then dirFromCenter = Vector2.new(0.01, 0) end

		-- The closer to the edge, the faster it flies out
		local perspective = math.max(dirFromCenter.Magnitude * 3, 0.1)

		-- Combined Flow: Radial (Forward) + Smoothed Planar (Strafe)
		local radialVec = dirFromCenter.Unit * (FwdSpeed * 0.015 * perspective)
		local totalFlow = (radialVec + SmoothedFlow) * data.SpeedVariance * dt

		-- Update Position
		data.Pos = data.Pos + totalFlow

		-- Respawn Logic
		local dist = (data.Pos - Center).Magnitude
		if dist > 0.7 then -- If off screen
			data.Pos = GetRandomSpawnPos()
			-- Visual reset
			data.Frame.BackgroundTransparency = 1 
		end

		-- 5. Visual Update
		local frame = data.Frame
		frame.Position = UDim2.new(data.Pos.X, 0, data.Pos.Y, 0)

		-- Rotation
		if totalFlow.Magnitude > 0.0001 then
			local angle = math.atan2(totalFlow.Y, totalFlow.X)
			frame.Rotation = math.deg(angle)
		end

		-- Stretch
		local stretch = math.clamp(totalFlow.Magnitude * Settings.StretchFactor * 2000, 0, 300)
		frame.Size = UDim2.new(0, Settings.BaseSize.X + stretch, 0, Settings.BaseSize.Y)

		-- Fade (Soft edges)
		local centerFade = math.clamp(dist * 4, 0, 1) -- Fade in from center
		frame.BackgroundTransparency = 1 - (FinalOpacity * centerFade)
	end
end)