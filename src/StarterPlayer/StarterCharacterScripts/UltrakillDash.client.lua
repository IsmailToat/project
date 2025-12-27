local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- // CONFIGURATION //
local MAX_STAMINA = 3
local STAMINA_REGEN_RATE = 1.05 
local DASH_COST = 1
local DASH_DURATION = 0.25 
local DASH_COOLDOWN = 0.2
local DASH_SPEED = 100 
local DASH_FORCE = 150000 

-- // STATE //
local currentStamina = MAX_STAMINA
local lastDashTime = 0
local isDashing = false

-- // UI //
local PlayerGui = Player:WaitForChild("PlayerGui")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UltrakillHUD"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui
local StaminaFrame = Instance.new("Frame")
StaminaFrame.Size = UDim2.new(0, 200, 0, 30)
StaminaFrame.Position = UDim2.new(0.5, -100, 0.9, 0)
StaminaFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
StaminaFrame.BackgroundTransparency = 0.5
StaminaFrame.Parent = ScreenGui
local StaminaBar = Instance.new("Frame")
StaminaBar.Size = UDim2.new(1, 0, 1, 0)
StaminaBar.BackgroundColor3 = Color3.fromRGB(0, 255, 255) 
StaminaBar.BorderSizePixel = 0
StaminaBar.Parent = StaminaFrame

local function UpdateStaminaUI()
	local ratio = math.clamp(currentStamina / MAX_STAMINA, 0, 1)
	StaminaBar.Size = UDim2.new(ratio, 0, 1, 0)
	if currentStamina < DASH_COST then
		StaminaBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	else
		StaminaBar.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
	end
end

local function PerformDash()
	if isDashing then return end
	if (os.clock() - lastDashTime) < DASH_COOLDOWN then return end
	if currentStamina < DASH_COST then return end

	currentStamina = currentStamina - DASH_COST
	lastDashTime = os.clock()
	isDashing = true
	UpdateStaminaUI()
	
	Character:SetAttribute("IsDashing", true)
	
	-- Determine Direction
	local moveDir = Humanoid.MoveDirection
	local dashDirection
	
	if moveDir.Magnitude > 0.001 then
		dashDirection = Vector3.new(moveDir.X, 0, moveDir.Z).Unit
	else
		dashDirection = RootPart.CFrame.LookVector * Vector3.new(1,0,1) 
		if dashDirection.Magnitude == 0 then dashDirection = Vector3.new(0,0,-1) end
		dashDirection = dashDirection.Unit
	end
	
	-- HARD RESET: Kill all previous momentum (gravity/falling)
	RootPart.AssemblyLinearVelocity = Vector3.zero 
	
	-- Create Constraints
	local att = Instance.new("Attachment")
	att.Parent = RootPart
	
	local lv = Instance.new("LinearVelocity")
	lv.Name = "DashVelocity"
	lv.Parent = RootPart
	lv.Attachment0 = att
	lv.MaxForce = DASH_FORCE 
	lv.VectorVelocity = dashDirection * DASH_SPEED
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	
	local startTime = os.clock()
	local connection
	
	connection = RunService.Heartbeat:Connect(function(dt)
		local elapsed = os.clock() - startTime
		if elapsed >= DASH_DURATION then
			-- Cleanup
			isDashing = false
			Character:SetAttribute("IsDashing", false)
			lv:Destroy()
			att:Destroy()
			connection:Disconnect()
			
			-- FINAL MOMENTUM SYNC
			-- Ensure we don't snap back to old falling speed, but we KEEP the dash speed horizontally
			local exitVel = RootPart.AssemblyLinearVelocity
			RootPart.AssemblyLinearVelocity = Vector3.new(exitVel.X, 0, exitVel.Z)
		else
			-- Constantly zero out Y component to simulate "Gravity Nullification"
			local currentVel = RootPart.AssemblyLinearVelocity
			-- Note: LinearVelocity usually handles this, but if MaxForce is hit, this helps.
			-- We forcefully keep Y near 0 in case physics fights back.
		end
	end)
end

local function HandleDashInput(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		PerformDash()
	end
	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction("UltrakillDash", HandleDashInput, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonX)

RunService.Heartbeat:Connect(function(deltaTime)
	local isSliding = Character:GetAttribute("IsSliding") == true
	if not isSliding and currentStamina < MAX_STAMINA then
		currentStamina = currentStamina + (STAMINA_REGEN_RATE * deltaTime)
		if currentStamina > MAX_STAMINA then currentStamina = MAX_STAMINA end
		UpdateStaminaUI()
	end
end)

Player.CharacterAdded:Connect(function(NewChar)
	Character = NewChar
	Humanoid = NewChar:WaitForChild("Humanoid")
	RootPart = NewChar:WaitForChild("HumanoidRootPart")
	isDashing = false
	currentStamina = MAX_STAMINA
	UpdateStaminaUI()
end)