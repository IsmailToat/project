local PhysicsService = game:GetService("PhysicsService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService") -- Added TweenService

-- // CONFIGURATION //
local CLEAN_UP_TIME = 5 -- How long body stays before fading starts
local FADE_TIME = 2     -- How long the fade takes
local GROUP_RAGDOLLS = "Ragdolls"
local GROUP_PLAYERS = "Players"

-- // SETUP COLLISION GROUPS //
pcall(function()
	PhysicsService:RegisterCollisionGroup(GROUP_RAGDOLLS)
	PhysicsService:RegisterCollisionGroup(GROUP_PLAYERS)
	PhysicsService:CollisionGroupSetCollidable(GROUP_PLAYERS, GROUP_RAGDOLLS, false)
	PhysicsService:CollisionGroupSetCollidable(GROUP_RAGDOLLS, GROUP_RAGDOLLS, false)
end)

local char = script.Parent
local hum = char:WaitForChild("Humanoid")

-- Critical: Stop body from exploding on death
hum.BreakJointsOnDeath = false

local AttachmentData = {
	["RA"] = {"Right Arm", CFrame.new(0, 0.5, 0), CFrame.new(1.5, 0.5, 0)},
	["LA"] = {"Left Arm",  CFrame.new(0, 0.5, 0), CFrame.new(-1.5, 0.5, 0)},
	["RL"] = {"Right Leg", CFrame.new(0, 0.5, 0), CFrame.new(0.5, -1.5, 0)},
	["LL"] = {"Left Leg",  CFrame.new(0, 0.5, 0), CFrame.new(-0.5, -1.5, 0)},
}

local function CreateRagdoll()
	-- 1. CLONE CHARACTER
	char.Archivable = true
	local ragdoll = char:Clone()
	char.Archivable = false
	ragdoll.Name = char.Name .. "_Ragdoll"

	-- 2. SETUP RAGDOLL HUMANOID
	local rHum = ragdoll:FindFirstChild("Humanoid")
	if rHum then
		rHum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		rHum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		rHum.PlatformStand = true
		rHum.Health = 0
	end

	-- 3. CLEANUP & PHYSICS
	for _, obj in pairs(ragdoll:GetDescendants()) do
		if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ForceField") then
			obj:Destroy()
		elseif obj:IsA("BasePart") then
			obj.Velocity = Vector3.zero
			obj.RotVelocity = Vector3.zero
			obj.CollisionGroup = GROUP_RAGDOLLS
			
			if obj.Name == "HumanoidRootPart" then
				obj.Transparency = 1
				obj.CanCollide = false
			end
		elseif obj:IsA("Weld") or obj:IsA("Motor6D") then
			obj:Destroy()
		end
	end

	-- 4. JOINTS
	local Torso = ragdoll:FindFirstChild("Torso")
	if Torso then
		local Head = ragdoll:FindFirstChild("Head")
		if Head then
			local att1 = Instance.new("Attachment", Head)
			att1.Position = Vector3.new(0, -0.5, 0)
			local att2 = Instance.new("Attachment", Torso)
			att2.Position = Vector3.new(0, 1, 0)
			
			local socket = Instance.new("BallSocketConstraint", Torso)
			socket.Attachment0 = att2
			socket.Attachment1 = att1
			socket.LimitsEnabled = true
			socket.TwistLimitsEnabled = true 
			socket.UpperAngle = 45
		end

		for _, data in pairs(AttachmentData) do
			local limbName = data[1]
			local limb = ragdoll:FindFirstChild(limbName)
			if limb then
				local att1 = Instance.new("Attachment", limb)
				att1.CFrame = data[2]
				
				local att2 = Instance.new("Attachment", Torso)
				att2.CFrame = data[3]
				
				local socket = Instance.new("BallSocketConstraint", Torso)
				socket.Attachment0 = att2
				socket.Attachment1 = att1
				socket.LimitsEnabled = true
				socket.TwistLimitsEnabled = true
			end
		end
	end

	-- 5. SPAWN
	ragdoll.Parent = workspace
	
	-- 6. HIDE ORIGINAL (Instant)
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("Decal") then
			part.Transparency = 1
			if part:IsA("BasePart") then part.CanCollide = false end
		end
	end

	-- 7. FADE OUT LOGIC (The new part)
	task.delay(CLEAN_UP_TIME, function()
		if not ragdoll then return end
		
		-- Setup Tween info (Smooth linear fade)
		local tweenInfo = TweenInfo.new(FADE_TIME, Enum.EasingStyle.Linear)
		
		-- Fade every part and face
		for _, part in pairs(ragdoll:GetDescendants()) do
			if part:IsA("BasePart") or part:IsA("Decal") then
				local tween = TweenService:Create(part, tweenInfo, {Transparency = 1})
				tween:Play()
			end
		end
		
		-- Wait for fade to finish, then destroy
		task.wait(FADE_TIME)
		if ragdoll then ragdoll:Destroy() end
	end)
end

hum.Died:Connect(CreateRagdoll)