local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tool = script.Parent
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerGui = Player:WaitForChild("PlayerGui")

-- // DEBUG CHECK //
local EventsFolder = ReplicatedStorage:WaitForChild("WeaponEvents", 5)
if not EventsFolder then
	warn("CRITICAL ERROR: Could not find 'WeaponEvents' folder in ReplicatedStorage!")
	script.Disabled = true
end

local Remote = EventsFolder:WaitForChild("RevolverEvent", 5)
if not Remote then
	warn("CRITICAL ERROR: Could not find 'RevolverEvent'!")
end

-- // CONFIGURATION //
local MAX_COINS = 4
local RECHARGE_TIME = 0.5
local FIRE_RATE = 0.5

-- // STATE //
local coins = MAX_COINS
local rechargeTimer = 0
local canShoot = true

-- // UI SETUP //
local ScreenGui = Instance.new("ScreenGui", PlayerGui)
ScreenGui.Name = "RevolverHUD"
ScreenGui.ResetOnSpawn = false
ScreenGui.Enabled = false

local Container = Instance.new("Frame", ScreenGui)
Container.Size = UDim2.new(0, 200, 0, 50)
Container.Position = UDim2.new(0.5, -100, 0.85, 0)
Container.BackgroundTransparency = 1

local Icons = {}
for i = 1, MAX_COINS do
	local f = Instance.new("Frame", Container)
	f.Size = UDim2.new(0, 30, 0, 30)
	f.Position = UDim2.new(0, (i-1)*40, 0, 0)
	f.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
	f.BorderSizePixel = 0
	local c = Instance.new("UICorner", f)
	c.CornerRadius = UDim.new(1,0)
	table.insert(Icons, f)
end

local function UpdateUI()
	for i, frame in ipairs(Icons) do
		frame.BackgroundTransparency = (i <= coins) and 0 or 0.8
	end
end

-- // SAFE HANDLE FINDER //
local function GetTipPosition()
	-- Try to find Handle, otherwise fallback to Head, otherwise Camera
	local handle = Tool:FindFirstChild("Handle")
	if handle then
		return handle.Position
	elseif Player.Character and Player.Character:FindFirstChild("Head") then
		return Player.Character.Head.Position
	else
		return Camera.CFrame.Position
	end
end

-- // LOOPS //
RunService.Heartbeat:Connect(function(dt)
	if coins < MAX_COINS then
		rechargeTimer += dt
		if rechargeTimer >= RECHARGE_TIME then
			coins += 1
			rechargeTimer = 0
			UpdateUI()
		end
	end
end)

-- // INPUTS //
Tool.Activated:Connect(function()
	if not canShoot then return end
	if not Remote then return end -- Safety check
	
	canShoot = false
	Remote:FireServer("Shoot", GetTipPosition(), Camera.CFrame.LookVector)
	task.wait(FIRE_RATE)
	canShoot = true
end)

local inputConn
Tool.Equipped:Connect(function()
	ScreenGui.Enabled = true
	UpdateUI()
	inputConn = UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			if coins > 0 and Remote then
				coins -= 1
				UpdateUI()
				Remote:FireServer("ThrowCoin", GetTipPosition(), Camera.CFrame.LookVector)
			end
		end
	end)
end)

Tool.Unequipped:Connect(function()
	ScreenGui.Enabled = false
	if inputConn then inputConn:Disconnect() end
end)