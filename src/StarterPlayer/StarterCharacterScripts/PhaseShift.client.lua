local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Char:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")

print("CLIENT: PhaseShift Script Loaded")

--// REMOTE
local RemoteName = "PhaseShiftEvent"
-- We wait up to 5 seconds to find the remote, to catch errors
local Remote = ReplicatedStorage:WaitForChild(RemoteName, 5)
if not Remote then
	warn("CLIENT ERROR: PhaseShiftEvent not found! Make sure the Server Script is in ServerScriptService.")
end

--// SETTINGS
local Settings = {
	Key = Enum.KeyCode.F,
	Duration = 4,           
	Cooldown = 10,
	Color = Color3.fromRGB(238, 162, 250),
}

--// UI SETUP
local PlayerGui = Player:WaitForChild("PlayerGui")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PhaseShiftUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local BarBG = Instance.new("Frame")
BarBG.Name = "CooldownBG"; BarBG.AnchorPoint = Vector2.new(0.5, 1)
BarBG.Position = UDim2.new(0.5, 0, 0.95, 0); BarBG.Size = UDim2.new(0, 200, 0, 8)
BarBG.BackgroundColor3 = Color3.fromRGB(40, 40, 40); BarBG.Visible = false
BarBG.Parent = ScreenGui; Instance.new("UICorner", BarBG).CornerRadius = UDim.new(1, 0)

local BarFill = Instance.new("Frame")
BarFill.Name = "Fill"; BarFill.Size = UDim2.new(1, 0, 1, 0)
BarFill.BackgroundColor3 = Settings.Color; BarFill.Parent = BarBG
Instance.new("UICorner", BarFill).CornerRadius = UDim.new(1, 0)

local StatusText = Instance.new("TextLabel")
StatusText.Name = "Status"; StatusText.Size = UDim2.new(1, 0, 0, 15)
StatusText.Position = UDim2.new(0, 0, -2.5, 0); StatusText.BackgroundTransparency = 1
StatusText.Text = "PHASE SHIFT"; StatusText.TextColor3 = Settings.Color
StatusText.Font = Enum.Font.GothamBold; StatusText.TextSize = 12; StatusText.Parent = BarBG

local IsActive = false

--// FUNCTIONS
local function StartUI()
	IsActive = true
	print("CLIENT: Phase Shift Activated (UI Start)")
	
	-- ACTIVE STATE
	BarBG.Visible = true
	BarFill.Size = UDim2.new(1, 0, 1, 0)
	StatusText.Text = "PHASE ACTIVE"
	StatusText.TextColor3 = Color3.new(1,1,1)
	
	TweenService:Create(BarFill, TweenInfo.new(Settings.Duration, Enum.EasingStyle.Linear), {
		Size = UDim2.new(0, 0, 1, 0)
	}):Play()
	
	-- ANIMATION STABILIZER
	local AnimConnection
	AnimConnection = RunService.RenderStepped:Connect(function()
		if not IsActive then 
			if AnimConnection then AnimConnection:Disconnect() end
			return 
		end
		for _, Track in pairs(Animator:GetPlayingAnimationTracks()) do
			if Track.Speed > 1.2 then Track:AdjustSpeed(1.0) end
		end
	end)

	-- FINISHED STATE
	task.delay(Settings.Duration, function()
		IsActive = false
		
		StatusText.Text = "RECHARGING..."
		StatusText.TextColor3 = Color3.fromRGB(150, 150, 150)
		BarFill.Size = UDim2.new(0, 0, 1, 0)
		
		TweenService:Create(BarFill, TweenInfo.new(Settings.Cooldown, Enum.EasingStyle.Linear), {
			Size = UDim2.new(1, 0, 1, 0)
		}):Play()

		task.delay(Settings.Cooldown, function()
			StatusText.Text = "READY [F]"
			StatusText.TextColor3 = Settings.Color
			BarFill.Size = UDim2.new(1, 0, 1, 0)
			
			task.delay(1, function()
				if not IsActive then BarBG.Visible = false end
			end)
		end)
	end)
end

--// INPUT
UserInputService.InputBegan:Connect(function(Input, Processed)
	if Processed then return end
	if Input.KeyCode == Settings.Key then
		if Remote then
			print("CLIENT: F Key Pressed - Requesting Server...")
			Remote:FireServer("Activate")
		end
	end
end)

--// SERVER CONFIRMATION
if Remote then
	Remote.OnClientEvent:Connect(function(Action)
		if Action == "Activated" then
			StartUI()
		end
	end)
end