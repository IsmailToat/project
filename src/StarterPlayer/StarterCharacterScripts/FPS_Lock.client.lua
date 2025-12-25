local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

--// SETTINGS
local DefaultFOV = 90
local MinFOV = 70
local MaxFOV = 120
local MenuKey = Enum.KeyCode.P

--// STATE
local IsMenuOpen = false
local CurrentFOV = DefaultFOV
local ShowHitboxes = false 

--// UI SETUP
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CrosshairUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Dot = Instance.new("Frame")
Dot.Name = "Dot"
Dot.AnchorPoint = Vector2.new(0.5, 0.5)
Dot.Position = UDim2.new(0.5, 0, 0.5, 0)
Dot.Size = UDim2.new(0, 4, 0, 4)
Dot.BackgroundColor3 = Color3.new(1, 1, 1)
Dot.BorderSizePixel = 0
Dot.Parent = ScreenGui
Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

local MenuFrame = Instance.new("Frame")
MenuFrame.Name = "SettingsMenu"
MenuFrame.Size = UDim2.new(0, 300, 0, 220)
MenuFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MenuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MenuFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MenuFrame.Visible = false
MenuFrame.Parent = ScreenGui
Instance.new("UICorner", MenuFrame).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Text = "SETTINGS"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.Parent = MenuFrame

local FOVLabel = Instance.new("TextLabel")
FOVLabel.Text = "FOV: " .. DefaultFOV
FOVLabel.Size = UDim2.new(1, 0, 0, 30)
FOVLabel.Position = UDim2.new(0, 0, 0.2, 0)
FOVLabel.BackgroundTransparency = 1
FOVLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
FOVLabel.Font = Enum.Font.Gotham
FOVLabel.TextSize = 16
FOVLabel.Parent = MenuFrame

local SliderBG = Instance.new("Frame")
SliderBG.Name = "SliderBG"
SliderBG.Size = UDim2.new(0.8, 0, 0, 6)
SliderBG.Position = UDim2.new(0.1, 0, 0.35, 0)
SliderBG.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
SliderBG.Parent = MenuFrame
Instance.new("UICorner", SliderBG).CornerRadius = UDim.new(1, 0)

local SliderFill = Instance.new("Frame")
SliderFill.Name = "Fill"
SliderFill.Size = UDim2.new(0.5, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
SliderFill.Parent = SliderBG
Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)

local SliderBtn = Instance.new("TextButton")
SliderBtn.Text = ""
SliderBtn.Size = UDim2.new(1, 0, 1, 0)
SliderBtn.BackgroundTransparency = 1
SliderBtn.Parent = SliderBG

local DebugBtn = Instance.new("TextButton")
DebugBtn.Text = "SHOW HITBOXES: OFF"
DebugBtn.Size = UDim2.new(0.8, 0, 0, 40)
DebugBtn.Position = UDim2.new(0.1, 0, 0.6, 0)
DebugBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
DebugBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
DebugBtn.Font = Enum.Font.GothamBold
DebugBtn.TextSize = 14
DebugBtn.Parent = MenuFrame
Instance.new("UICorner", DebugBtn).CornerRadius = UDim.new(0, 6)

--// FUNCTIONS

local function UpdateFOV(Alpha)
	local NewFOV = MinFOV + (Alpha * (MaxFOV - MinFOV))
	CurrentFOV = math.floor(NewFOV)
	FOVLabel.Text = "FOV: " .. CurrentFOV
	SliderFill.Size = UDim2.new(Alpha, 0, 1, 0)
	Camera.FieldOfView = CurrentFOV
end

local function ToggleHitboxes()
	ShowHitboxes = not ShowHitboxes

	if ShowHitboxes then
		DebugBtn.Text = "SHOW HITBOXES: ON"
		DebugBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
	else
		DebugBtn.Text = "SHOW HITBOXES: OFF"
		DebugBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
	end

	-- // CRITICAL FIX: ALWAYS GET LATEST CHARACTER //
	local Char = Player.Character
	if Char then
		-- This sets it on the CLIENT side. 
		-- We will read this in ClientInput and send it to the server.
		Char:SetAttribute("DebugHitboxes", ShowHitboxes)
	end
end

DebugBtn.MouseButton1Click:Connect(ToggleHitboxes)

local function ToggleMenu()
	IsMenuOpen = not IsMenuOpen
	MenuFrame.Visible = IsMenuOpen

	if IsMenuOpen then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		Player.CameraMode = Enum.CameraMode.Classic
		Player.CameraMinZoomDistance = 0.5
		Player.CameraMaxZoomDistance = 0.5
	else
		UserInputService.MouseIconEnabled = false
		Player.CameraMode = Enum.CameraMode.LockFirstPerson
	end
end

local IsDragging = false
SliderBtn.MouseButton1Down:Connect(function() IsDragging = true end)
UserInputService.InputEnded:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then IsDragging = false end
end)

UserInputService.InputChanged:Connect(function(Input)
	if IsDragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
		local MousePos = Input.Position.X
		local BarPos = SliderBG.AbsolutePosition.X
		local BarSize = SliderBG.AbsoluteSize.X
		local Alpha = math.clamp((MousePos - BarPos) / BarSize, 0, 1)
		UpdateFOV(Alpha)
	end
end)

UpdateFOV((DefaultFOV - MinFOV) / (MaxFOV - MinFOV))

UserInputService.InputBegan:Connect(function(Input, Processed)
	if not Processed and Input.KeyCode == MenuKey then ToggleMenu() end
end)

RunService.RenderStepped:Connect(function()
	if Camera.FieldOfView ~= CurrentFOV then Camera.FieldOfView = CurrentFOV end
	if IsMenuOpen then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	else
		if Player.CameraMode ~= Enum.CameraMode.LockFirstPerson then
			Player.CameraMode = Enum.CameraMode.LockFirstPerson
		end
		UserInputService.MouseIconEnabled = false
	end
end)