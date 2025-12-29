local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tool = script.Parent
local Handle = Tool:WaitForChild("Handle")
local Remote = ReplicatedStorage:WaitForChild("WeaponEvents"):WaitForChild("ShotgunEvent")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerGui = Player:WaitForChild("PlayerGui")

-- CONFIG
local MAX_CHARGE = 0.75
local EXPLODE_TIME = 5
local COOLDOWN = 1

-- STATE
local isCharging = false
local chargeStart = 0
local canShoot = true

-- UI
local ScreenGui = Instance.new("ScreenGui", PlayerGui)
ScreenGui.Name = "ShotgunHUD"
ScreenGui.ResetOnSpawn = false
ScreenGui.Enabled = false

local BarBg = Instance.new("Frame", ScreenGui)
BarBg.Size = UDim2.new(0, 200, 0, 8)
BarBg.Position = UDim2.new(0.5, -100, 0.75, 0)
BarBg.BackgroundColor3 = Color3.fromRGB(50,50,50)
BarBg.Visible = false
local BarFill = Instance.new("Frame", BarBg)
BarFill.Size = UDim2.fromScale(0, 1)
BarFill.BackgroundColor3 = Color3.fromRGB(255,100,0)

-- FUNCTIONS
local function Fire(duration)
	if not canShoot then return end
	canShoot = false
	
	local ratio = math.clamp(duration, 0, MAX_CHARGE) / MAX_CHARGE
	-- Send Handle Position + Aim
	Remote:FireServer("Shoot", Handle.Position, Camera.CFrame.LookVector, ratio)
	
	BarBg.Visible = false
	task.wait(COOLDOWN)
	canShoot = true
end

RunService.RenderStepped:Connect(function()
	if isCharging then
		local dur = os.clock() - chargeStart
		
		-- OVERCHARGE
		if dur >= EXPLODE_TIME then
			isCharging = false
			BarBg.Visible = false
			canShoot = false
			Remote:FireServer("OverchargeExplode")
			return
		end
		
		-- UI
		local ratio = math.min(dur, MAX_CHARGE) / MAX_CHARGE
		BarFill.Size = UDim2.fromScale(ratio, 1)
		
		if dur > MAX_CHARGE then
			local intensity = 0.1 + ((dur - MAX_CHARGE) * 0.1)
			local off = Vector3.new(math.random()-0.5, math.random()-0.5, 0) * intensity
			Camera.CFrame = Camera.CFrame * CFrame.new(off)
			BarFill.BackgroundColor3 = Color3.new(1,0,0)
		else
			BarFill.BackgroundColor3 = Color3.fromRGB(255,100,0)
		end
	end
end)

-- INPUTS
local inputConn
Tool.Equipped:Connect(function()
	ScreenGui.Enabled = true
	inputConn = UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 and canShoot then
			isCharging = true
			chargeStart = os.clock()
			BarBg.Visible = true
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and isCharging then
			isCharging = false
			Fire(os.clock() - chargeStart)
		end
	end)
end)

Tool.Unequipped:Connect(function()
	isCharging = false
	BarBg.Visible = false
	ScreenGui.Enabled = false
	if inputConn then inputConn:Disconnect() end
end)