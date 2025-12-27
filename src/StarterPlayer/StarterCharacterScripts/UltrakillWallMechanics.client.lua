local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- // CONFIGURATION //
local WALL_JUMP_FORCE = 50   
local WALL_JUMP_UP_FORCE = 45 
local MAX_WALL_JUMPS = 3
local WALL_SLIDE_ACCEL_TIME = 3.0 
local MIN_WALL_ANGLE = 66.5 
local WALL_CHECK_DISTANCE = 4.0 
local WALL_PUSH_THRESHOLD = -0.15
local WALL_STICK_FORCE = 2

-- // STATE //
local wallJumpCount = 0
local wallSlideTimer = 0 
local isWallSliding = false

-- // HELPER: Get Wall //
local function GetWallInfo()
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {Character}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local directions = {
		RootPart.CFrame.LookVector,
		-RootPart.CFrame.LookVector,
		RootPart.CFrame.RightVector,
		-RootPart.CFrame.RightVector
	}
	
	local closestResult = nil
	local closestDist = math.huge
	
	for _, dir in ipairs(directions) do
		local result = Workspace:Raycast(RootPart.Position, dir * WALL_CHECK_DISTANCE, rayParams)
		if result then
			local dist = (result.Position - RootPart.Position).Magnitude
			local angleFromUp = math.acos(math.clamp(result.Normal.Y, -1, 1))
			local angleDeg = math.deg(angleFromUp)
			
			if angleDeg > MIN_WALL_ANGLE and dist < closestDist then
				closestDist = dist
				closestResult = result
			end
		end
	end
	
	if closestResult then
		return closestResult.Normal, closestResult.Instance
	end
	return nil, nil
end

-- // INPUT: Wall Jump //
local function HandleWallJump(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		local state = Humanoid:GetState()
		local inAir = (state == Enum.HumanoidStateType.Freefall) or (state == Enum.HumanoidStateType.FallingDown) or (state == Enum.HumanoidStateType.Jumping)
		
		if inAir then
			local wallNormal, _ = GetWallInfo()
			if wallNormal and wallJumpCount < MAX_WALL_JUMPS then
				wallJumpCount = wallJumpCount + 1
				
				-- Stop Sliding
				isWallSliding = false
				Character:SetAttribute("IsWallSliding", false)
				
				-- Apply Velocity
				local jumpDir = (wallNormal + Vector3.new(0, 0.5, 0)).Unit 
				local jumpVel = (wallNormal * WALL_JUMP_FORCE) + Vector3.new(0, WALL_JUMP_UP_FORCE, 0)
				
				RootPart.AssemblyLinearVelocity = jumpVel
				
				-- Force Physics State so Movement script can pick it up
				Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				
				return Enum.ContextActionResult.Sink
			end
		end
	end
	return Enum.ContextActionResult.Pass
end

ContextActionService:BindActionAtPriority("UltrakillWallJump", HandleWallJump, false, Enum.ContextActionPriority.High.Value + 10, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)

-- // PHYSICS LOOP //
RunService.Heartbeat:Connect(function(deltaTime)
	local state = Humanoid:GetState()
	local isGrounded = (state == Enum.HumanoidStateType.Running) or (state == Enum.HumanoidStateType.Landed)
	
	if isGrounded then
		wallJumpCount = 0
		wallSlideTimer = 0
		if isWallSliding then
			isWallSliding = false
			Character:SetAttribute("IsWallSliding", false)
		end
		return
	end
	
	-- AIR LOGIC
	local wallNormal, _ = GetWallInfo()
	
	if wallNormal and not Character:GetAttribute("IsDashing") then
		local vel = RootPart.AssemblyLinearVelocity
		local velocityIntoWall = vel:Dot(wallNormal)
		
		-- 1. Anti-Bounce (Slide along wall)
		if velocityIntoWall < 0.1 then 
			local perp = velocityIntoWall * wallNormal
			local parallel = vel - perp
			vel = parallel - (wallNormal * WALL_STICK_FORCE)
			RootPart.AssemblyLinearVelocity = vel
		end
		
		-- 2. Wall Slide Logic
		if vel.Y < 0 then 
			local flatMove = Vector3.new(Humanoid.MoveDirection.X, 0, Humanoid.MoveDirection.Z)
			local flatNormal = Vector3.new(wallNormal.X, 0, wallNormal.Z)
			local isPushing = false
			
			if flatMove.Magnitude > 0.001 then
				flatMove = flatMove.Unit
				flatNormal = flatNormal.Unit
				if flatMove:Dot(flatNormal) < WALL_PUSH_THRESHOLD then isPushing = true end
			end
			
			if isPushing then
				isWallSliding = true
				Character:SetAttribute("IsWallSliding", true)
				wallSlideTimer = wallSlideTimer + deltaTime
				
				if wallSlideTimer < WALL_SLIDE_ACCEL_TIME then
					local ratio = wallSlideTimer / WALL_SLIDE_ACCEL_TIME
					local curve = ratio * ratio * ratio 
					
					local maxSlideSpeed = -100 
					local baseSlideSpeed = -10 -- FIXED: Base speed prevents getting stuck
					
					local allowedFallSpeed = baseSlideSpeed + (maxSlideSpeed * curve)
					
					if vel.Y < allowedFallSpeed then
						RootPart.AssemblyLinearVelocity = Vector3.new(vel.X, allowedFallSpeed, vel.Z)
					end
				end
			else
				isWallSliding = false
				Character:SetAttribute("IsWallSliding", false)
			end
		else
			isWallSliding = false
			Character:SetAttribute("IsWallSliding", false)
		end
	else
		isWallSliding = false
		Character:SetAttribute("IsWallSliding", false)
	end
end)

Player.CharacterAdded:Connect(function(NewChar)
	Character = NewChar
	Humanoid = NewChar:WaitForChild("Humanoid")
	RootPart = NewChar:WaitForChild("HumanoidRootPart")
	isWallSliding = false
	wallJumpCount = 0
end)