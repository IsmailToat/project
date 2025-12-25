--// Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--// Players Stuff
local Plr = Players.LocalPlayer
local Char = Plr.Character or Plr.CharacterAdded:Wait()
local RootPart = Char:WaitForChild("HumanoidRootPart")
local Humanoid = Char:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")

print("Roll System Loaded") 

--// ANIMATION LOADING
local RollAnimID = "rbxassetid://70916359960990" -- PASTE YOUR ROLL ID

local RollAnim = Instance.new("Animation")
RollAnim.AnimationId = RollAnimID

local RollTrack = Animator:LoadAnimation(RollAnim)
RollTrack.Priority = Enum.AnimationPriority.Action
RollTrack.Looped = false 

--// Variables
local CanRoll = true
local HasAttemptedRoll = false

local Settings = {
	Cooldown = 0.5,

	-- // ROLL SETTINGS //
	MinFallSpeed = -45,        
	MaxRollDistance = 80,      
	FallGravity = 100,         

	-- // TIMING WINDOWS (ms)
	WindowValid = 200,       
	WindowPerfect = 50,      

	-- Rewards
	BoostNormal = 1.1,        
	BoostPerfect = 1.4,       
	TimeNormal = 2,           
	TimePerfect = 5,  
}

local Params = RaycastParams.new()
Params.FilterDescendantsInstances = {Char}
Params.FilterType = Enum.RaycastFilterType.Exclude

--// FUNCTIONS

function PerformRoll(IsPerfect)
	if not CanRoll then return end
	CanRoll = false

	-- Play Animation
	RollTrack:Play(0.1)

	-- Give Speed Boost
	local Boost = IsPerfect and Settings.BoostPerfect or Settings.BoostNormal
	local Duration = IsPerfect and Settings.TimePerfect or Settings.TimeNormal

	Char:SetAttribute("SpeedBoost", Boost)

	task.delay(Duration, function()
		Char:SetAttribute("SpeedBoost", 1) 
	end)

	task.delay(Settings.Cooldown, function()
		CanRoll = true
	end)
end

--// PHYSICS LOOP
RunService.Heartbeat:Connect(function(dt)
	local Velocity = RootPart.AssemblyLinearVelocity
	local IsGrounded = (Humanoid.FloorMaterial ~= Enum.Material.Air)

	if IsGrounded then
		HasAttemptedRoll = false
	end

	if not IsGrounded and Velocity.Y < -5 then
		RootPart.AssemblyLinearVelocity = Velocity - Vector3.new(0, Settings.FallGravity * dt, 0)
	end
end)

--// INPUT HANDLING
UserInputService.InputBegan:Connect(function(Input, istyping)
	if istyping then return end

	if Input.KeyCode == Enum.KeyCode.C then

		local CurrentYVel = RootPart.AssemblyLinearVelocity.Y
		local IsGrounded = (Humanoid.FloorMaterial ~= Enum.Material.Air)

		if not IsGrounded then

			if CurrentYVel > Settings.MinFallSpeed then return end

			if HasAttemptedRoll then return end
			HasAttemptedRoll = true

			local RayDirection = -RootPart.CFrame.UpVector * Settings.MaxRollDistance
			local GroundRay = workspace:Raycast(RootPart.Position, RayDirection, Params)

			if GroundRay then
				local Distance = GroundRay.Distance
				local FallSpeed = math.abs(CurrentYVel) 

				local TimeToImpact = Distance / FallSpeed
				local TimeMs = TimeToImpact * 1000

				-- Set Attributes (So your GUI can see them)
				Char:SetAttribute("RollTiming", TimeMs)
				Char:SetAttribute("RollPerfect", TimeMs <= Settings.WindowPerfect)

				-- Logic (Silent now)
				if TimeMs <= Settings.WindowPerfect then
					PerformRoll(true)
				elseif TimeMs <= Settings.WindowValid then
					PerformRoll(false)
				else
					-- Failed (Too Early)
				end
			end
		end
	end
end)