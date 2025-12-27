local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- // CONFIGURATION //
local TARGET_GRAVITY = 60 
local MOVEMENT_SPEED = 35
local JUMP_HEIGHT = 10 
local AIR_DRAG = 0.5 -- Low drag for that "floaty" feel
local AIR_ACCELERATION = 150 
local COYOTE_TIME_WINDOW = 0.2 
local BHOP_WINDOW = 0.15 

Workspace.Gravity = TARGET_GRAVITY

local CALCULATED_JUMP_POWER = math.sqrt(2 * TARGET_GRAVITY * JUMP_HEIGHT)

-- // STATE //
local lastGroundedTime = 0
local isJumping = false
local wasGrounded = true
local lastJumpPressTime = 0 
local currentAirMomentum = Vector3.zero 

-- Track previous frame states to handle momentum handovers
local wasWallSliding = false 
local wasDashing = false

-- // FRICTION CONTROL //
local defaultPhysicalProperties = RootPart.CustomPhysicalProperties
local frictionlessProperties = PhysicalProperties.new(0.7, 0, 0, 1, 1)

local function SetFrictionMode(mode)
	if mode == "Frictionless" then
		RootPart.CustomPhysicalProperties = frictionlessProperties
	else
		RootPart.CustomPhysicalProperties = defaultPhysicalProperties
	end
end

-- // JUMP FUNCTION //
local function PerformJump(preserveMomentum)
	Humanoid.JumpPower = CALCULATED_JUMP_POWER
	Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	isJumping = true
	SetFrictionMode("Normal") 
	
	if preserveMomentum then
		local vel = RootPart.AssemblyLinearVelocity
		-- Keep current horizontal momentum, only change Y
		currentAirMomentum = Vector3.new(vel.X, 0, vel.Z)
	end
	
	task.delay(0.05, function() Humanoid.JumpPower = 0 end)
end

-- // INPUT //
local function HandleJumpInput(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		lastJumpPressTime = os.clock()
		
		local now = os.clock()
		local timeSinceGrounded = now - lastGroundedTime
		local state = Humanoid:GetState()
		local inAir = (state == Enum.HumanoidStateType.Freefall) or (state == Enum.HumanoidStateType.FallingDown) or (state == Enum.HumanoidStateType.Jumping)
		
		-- Coyote Jump
		if inAir and not isJumping and timeSinceGrounded < COYOTE_TIME_WINDOW then
			PerformJump(false)
		-- Ground Jump
		elseif (state == Enum.HumanoidStateType.Running) or (state == Enum.HumanoidStateType.Landed) then
			PerformJump(false)
		end
	end
	return Enum.ContextActionResult.Pass -- Pass input so Wall Mechanics can see it too
end

ContextActionService:BindActionAtPriority("UltrakillJumpBase", HandleJumpInput, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)

-- // PHYSICS LOOP //
RunService.Heartbeat:Connect(function(deltaTime)
	if Humanoid.WalkSpeed ~= MOVEMENT_SPEED then Humanoid.WalkSpeed = MOVEMENT_SPEED end
	if Workspace.Gravity ~= TARGET_GRAVITY then Workspace.Gravity = TARGET_GRAVITY end

	local isDashing = Character:GetAttribute("IsDashing") == true
	local isWallSliding = Character:GetAttribute("IsWallSliding") == true

	-- // MOMENTUM HANDOVER //
	-- If we were dashing/sliding last frame, but STOPPED this frame,
	-- we must capture the high velocity immediately so air physics doesn't reset it to 0.
	if (wasDashing and not isDashing) or (wasWallSliding and not isWallSliding) then
		local exitVel = RootPart.AssemblyLinearVelocity
		currentAirMomentum = Vector3.new(exitVel.X, 0, exitVel.Z)
	end

	wasDashing = isDashing
	wasWallSliding = isWallSliding

	-- If external mechanics are active, stop this script from interfering
	if isDashing or isWallSliding then 
		local vel = RootPart.AssemblyLinearVelocity
		currentAirMomentum = Vector3.new(vel.X, 0, vel.Z)
		return 
	end

	local state = Humanoid:GetState()
	local isGrounded = (state == Enum.HumanoidStateType.Running) or (state == Enum.HumanoidStateType.Landed)
	local isFalling = (state == Enum.HumanoidStateType.Freefall)

	if isGrounded then
		lastGroundedTime = os.clock()
		isJumping = false
		wasGrounded = true
		SetFrictionMode("Normal") 
		local vel = RootPart.AssemblyLinearVelocity
		currentAirMomentum = Vector3.new(vel.X, 0, vel.Z)
	elseif wasGrounded and isFalling then
		wasGrounded = false
	end

	-- // AIR PHYSICS (LOW DRAG) //
	if not isGrounded then
		local currentVel = RootPart.AssemblyLinearVelocity
		
		-- Sync tracker if we just jumped manually
		if isJumping then
			currentAirMomentum = Vector3.new(currentVel.X, 0, currentVel.Z)
		end
		
		-- 1. Apply Natural Decay (Very slow drag)
		local decay = math.clamp(1 - (deltaTime * AIR_DRAG), 0.9, 1)
		currentAirMomentum = currentAirMomentum * decay
		
		-- 2. Apply Air Strafing (Only adds velocity, doesn't limit it)
		-- This allows you to steer without losing your "Wall Jump" speed.
		if Humanoid.MoveDirection.Magnitude > 0.001 then
			local wishDir = Humanoid.MoveDirection
			
			-- Project velocity: How fast are we going in the desired direction?
			local currentSpeedInWishDir = currentAirMomentum:Dot(wishDir)
			local addSpeed = MOVEMENT_SPEED - currentSpeedInWishDir
			
			if addSpeed > 0 then
				local accelSpeed = math.min(AIR_ACCELERATION * deltaTime, addSpeed)
				currentAirMomentum = currentAirMomentum + (wishDir * accelSpeed)
			end
		end
		
		-- 3. Apply Velocity
		RootPart.AssemblyLinearVelocity = Vector3.new(
			currentAirMomentum.X,
			currentVel.Y, -- Preserve Gravity
			currentAirMomentum.Z
		)
	end
end)

Humanoid.StateChanged:Connect(function(oldState, newState)
	if newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running then
		if oldState == Enum.HumanoidStateType.Freefall then
			SetFrictionMode("Normal") 
			local timeSinceInput = os.clock() - lastJumpPressTime
			if timeSinceInput < BHOP_WINDOW then
				PerformJump(true)
			end
		end
	end
end)

Player.CharacterAdded:Connect(function(NewChar)
	Character = NewChar
	Humanoid = NewChar:WaitForChild("Humanoid")
	RootPart = NewChar:WaitForChild("HumanoidRootPart")
	Humanoid.WalkSpeed = MOVEMENT_SPEED
	Humanoid.JumpPower = 0
	Workspace.Gravity = TARGET_GRAVITY
end)