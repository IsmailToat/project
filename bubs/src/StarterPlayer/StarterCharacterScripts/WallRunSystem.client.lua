local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Player = Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Char:WaitForChild("HumanoidRootPart")
local Humanoid = Char:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")
local Camera = workspace.CurrentCamera

--// CONFIGURATION
local Settings = {
	JumpForce = 90, 
	GravityDampening = 0,
	WallCheckDistance = 3.5,
	MinHeight = 3.5,
	AnimFade = 0.2, 

	MomentumDecay = 40,    
	BaseRunSpeed = 35,     
	JumpDuration = 0.15,   

	LeftAnimID = "rbxassetid://113417795087491",  
	RightAnimID = "rbxassetid://117876820506065", 
}

--// SETUP ANIMATIONS
local LeftAnim = Instance.new("Animation"); LeftAnim.AnimationId = Settings.LeftAnimID
local RightAnim = Instance.new("Animation"); RightAnim.AnimationId = Settings.RightAnimID
local TrackLeft = Animator:LoadAnimation(LeftAnim); TrackLeft.Priority = Enum.AnimationPriority.Action; TrackLeft.Looped = true
local TrackRight = Animator:LoadAnimation(RightAnim); TrackRight.Priority = Enum.AnimationPriority.Action; TrackRight.Looped = true

--// VARIABLES
local IsWallRunning = false
local IsW_Held = false
local WallNormal = Vector3.new(0,0,0)
local CurrentWallRunSpeed = 0 
local CurrentWallPart = nil 
local LastWallPart = nil    
local CurrentAnimTrack = nil 
local WallVelocity
local WallGyro
local Params = RaycastParams.new(); Params.FilterDescendantsInstances = {Char}; Params.FilterType = Enum.RaycastFilterType.Exclude

--// HELPER
local function GetCorrectedTangent(Normal, LookVector)
	local Tangent = Normal:Cross(Vector3.new(0,1,0))
	if Tangent:Dot(LookVector) < 0 then Tangent = -Tangent end
	return Tangent
end

local function StartWallRun(Normal, WallPart, Side)
	if IsWallRunning then return end

	-- Prevent climbing the same wall instantly
	if WallPart == LastWallPart then return end

	local FloorCheck = workspace:Raycast(RootPart.Position, Vector3.new(0, -Settings.MinHeight, 0), Params)
	if FloorCheck then return end 

	IsWallRunning = true
	Char:SetAttribute("IsWallRunning", true)

	WallNormal = Normal
	CurrentWallPart = WallPart 

	-- // FIX: AGGRESSIVE CLEANUP //
	-- Destroy ANY existing movement forces (Dash OR previous Jump Momentum)
	for _, child in pairs(RootPart:GetChildren()) do
		if child.Name == "DashVelocity" or child.Name == "WallJumpMomentum" then
			child:Destroy()
		end
	end

	-- Calculate Entry Speed
	local Velocity = RootPart.AssemblyLinearVelocity
	local HorizontalSpeed = Vector3.new(Velocity.X, 0, Velocity.Z).Magnitude

	CurrentWallRunSpeed = math.max(HorizontalSpeed, Settings.BaseRunSpeed)

	Humanoid.AutoRotate = false 
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false) 

	if Side == "Left" then
		CurrentAnimTrack = TrackLeft
	elseif Side == "Right" then
		CurrentAnimTrack = TrackRight
	end

	if CurrentAnimTrack then
		CurrentAnimTrack:Play(Settings.AnimFade)
	end

	WallVelocity = Instance.new("BodyVelocity")
	WallVelocity.Name = "WallVelocity"
	WallVelocity.MaxForce = Vector3.new(50000, 50000, 50000)
	WallVelocity.Parent = RootPart

	WallGyro = Instance.new("BodyGyro")
	WallGyro.MaxTorque = Vector3.new(50000, 50000, 50000)
	WallGyro.P = 20000

	local RunDirection = GetCorrectedTangent(Normal, RootPart.CFrame.LookVector)
	WallGyro.CFrame = CFrame.lookAt(RootPart.Position, RootPart.Position + RunDirection)
	WallGyro.Parent = RootPart
end

local function StopWallRun()
	if not IsWallRunning then return end
	IsWallRunning = false
	Char:SetAttribute("IsWallRunning", false)

	CurrentWallPart = nil 

	if WallVelocity then WallVelocity:Destroy() end
	if WallGyro then WallGyro:Destroy() end

	if CurrentAnimTrack then
		CurrentAnimTrack:Stop(Settings.AnimFade)
		CurrentAnimTrack = nil
	end

	Humanoid.AutoRotate = true
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
end

local function WallJump()
	local JumpNormal = WallNormal 
	LastWallPart = CurrentWallPart 
	StopWallRun()

	local ExitSpeed = math.max(Settings.JumpForce, CurrentWallRunSpeed)

	local JumpVel = Instance.new("BodyVelocity")
	JumpVel.Name = "WallJumpMomentum" 
	JumpVel.MaxForce = Vector3.new(50000, 50000, 50000)

	-- Push slightly AWAY from wall to prevent clipping
	local SafeDirection = (Camera.CFrame.LookVector + (JumpNormal * 1.5)).Unit

	JumpVel.Velocity = SafeDirection * ExitSpeed
	JumpVel.Parent = RootPart

	task.spawn(function()
		local startTime = os.clock()

		-- Phase 1: Initial Pop
		while os.clock() - startTime < Settings.JumpDuration do
			-- FIX: Stop loop if we started wallrunning again
			if Char:GetAttribute("IsWallRunning") == true then 
				if JumpVel then JumpVel:Destroy() end 
				return 
			end
			if RootPart:FindFirstChild("DashVelocity") then 
				if JumpVel then JumpVel:Destroy() end 
				return 
			end
			RunService.Heartbeat:Wait()
		end

		-- Phase 2: Glide (Remove Y support)
		if JumpVel and JumpVel.Parent then
			JumpVel.MaxForce = Vector3.new(50000, 0, 50000) 
		end

		local CurrentSpeed = ExitSpeed

		while JumpVel and JumpVel.Parent and CurrentSpeed > Settings.BaseRunSpeed do
			local dt = RunService.Heartbeat:Wait()

			if Humanoid.FloorMaterial ~= Enum.Material.Air then break end

			-- FIX: Stop loop if we started wallrunning again
			if Char:GetAttribute("IsWallRunning") == true then break end
			if RootPart:FindFirstChild("DashVelocity") then break end

			CurrentSpeed = CurrentSpeed - (Settings.MomentumDecay * dt)

			if CurrentSpeed < Settings.BaseRunSpeed then 
				CurrentSpeed = Settings.BaseRunSpeed 
			end

			local HorizontalLook = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z).Unit
			JumpVel.Velocity = HorizontalLook * CurrentSpeed
		end

		if JumpVel then JumpVel:Destroy() end
	end)
end

--// INPUT HANDLING
UserInputService.InputBegan:Connect(function(Input, Processed)
	if Processed then return end

	if Input.KeyCode == Enum.KeyCode.W then
		IsW_Held = true
	elseif Input.KeyCode == Enum.KeyCode.Space then
		if IsWallRunning then
			WallJump() 
		end
	end
end)

UserInputService.InputEnded:Connect(function(Input)
	if Input.KeyCode == Enum.KeyCode.W then
		IsW_Held = false
		if IsWallRunning then
			StopWallRun()
		end
	end
end)

--// MAIN LOOP
RunService.Heartbeat:Connect(function(DeltaTime)

	if Humanoid.FloorMaterial ~= Enum.Material.Air then
		LastWallPart = nil
	end

	if IsWallRunning then

		local RayDir = -WallNormal * (Settings.WallCheckDistance + 1)
		local WallCheck = workspace:Raycast(RootPart.Position, RayDir, Params)

		if WallCheck and IsW_Held then
			WallNormal = WallCheck.Normal
			CurrentWallPart = WallCheck.Instance

			local MoveDir = GetCorrectedTangent(WallNormal, RootPart.CFrame.LookVector)

			WallVelocity.Velocity = (MoveDir * CurrentWallRunSpeed) + Vector3.new(0, -Settings.GravityDampening, 0)
			WallGyro.CFrame = CFrame.lookAt(RootPart.Position, RootPart.Position + MoveDir)

		else
			StopWallRun()
		end

	elseif IsW_Held and not Humanoid.SeatPart then 

		local RightRay = workspace:Raycast(RootPart.Position, RootPart.CFrame.RightVector * Settings.WallCheckDistance, Params)
		local LeftRay = workspace:Raycast(RootPart.Position, -RootPart.CFrame.RightVector * Settings.WallCheckDistance, Params)

		if RightRay then
			StartWallRun(RightRay.Normal, RightRay.Instance, "Right")
		elseif LeftRay then
			StartWallRun(LeftRay.Normal, LeftRay.Instance, "Left")
		end
	end
end)