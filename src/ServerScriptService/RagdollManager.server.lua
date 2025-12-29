local PhysicsService = game:GetService("PhysicsService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- // CONFIGURATION //
local CLEAN_UP_TIME = 5  
local FADE_TIME = 2      
local GROUP_RAGDOLLS = "Ragdolls"
local GROUP_PLAYERS = "Players"

-- // PHYSICS PROPERTIES //
-- High Friction = Stop sliding
-- High Density = Heavy feel
local RAGDOLL_PHYSICS = PhysicalProperties.new(2.0, 1.5, 0.0, 1.0, 1.0)

-- // SETUP COLLISION GROUPS //
pcall(function()
	PhysicsService:RegisterCollisionGroup(GROUP_RAGDOLLS)
	PhysicsService:RegisterCollisionGroup(GROUP_PLAYERS)
	
	-- Players walk through ragdolls
	PhysicsService:CollisionGroupSetCollidable(GROUP_PLAYERS, GROUP_RAGDOLLS, false)
	
	-- Ragdolls collide with map (Default) explicitly true
	PhysicsService:CollisionGroupSetCollidable(GROUP_RAGDOLLS, "Default", true)
	
	-- Ragdolls collide with each other
	PhysicsService:CollisionGroupSetCollidable(GROUP_RAGDOLLS, GROUP_RAGDOLLS, true)
end)

-- // ATTACHMENT POSITIONS (R6) //
local AttachmentData = {
	["RA"] = {"Right Arm", CFrame.new(0, 0.5, 0), CFrame.new(1.5, 0.5, 0)},
	["LA"] = {"Left Arm",  CFrame.new(0, 0.5, 0), CFrame.new(-1.5, 0.5, 0)},
	["RL"] = {"Right Leg", CFrame.new(0, 0.5, 0), CFrame.new(0.5, -1.5, 0)},
	["LL"] = {"Left Leg",  CFrame.new(0, 0.5, 0), CFrame.new(-0.5, -1.5, 0)},
}

-- // HELPER: CREATE GHOST COLLIDER //
-- This creates an invisible part that the Humanoid won't disable collision on
local function CreateColliderPart(parentPart, ragdoll)
	local collider = Instance.new("Part")
	collider.Name = "Collider_" .. parentPart.Name
	collider.Size = parentPart.Size * 0.8 -- Slightly smaller to fit inside
	collider.Transparency = 1
	collider.CanCollide = true
	collider.Massless = true -- Let the main part handle weight
	collider.CollisionGroup = GROUP_RAGDOLLS
	collider.CustomPhysicalProperties = RAGDOLL_PHYSICS
	collider.Parent = ragdoll
	
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = parentPart
	weld.Part1 = collider
	weld.Parent = collider
	
	return collider
end

local function CreateRagdoll(char)
	local hum = char:FindFirstChild("Humanoid")
	if not hum then return end
	
	hum.BreakJointsOnDeath = false 
	
	char.Archivable = true
	local ragdoll = char:Clone()
	char.Archivable = false
	ragdoll.Name = char.Name .. "_Ragdoll"

	local rHum = ragdoll:FindFirstChild("Humanoid")
	if rHum then
		rHum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		rHum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		rHum.Health = 0
		-- Force Physics state stops the humanoid from messing with CanCollide
		rHum:ChangeState(Enum.HumanoidStateType.Physics) 
	end

	-- CLEANUP & PREP
	for _, obj in pairs(ragdoll:GetDescendants()) do
		if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ForceField") then
			obj:Destroy()
			
		elseif obj:IsA("BasePart") then
			obj.Velocity = Vector3.zero
			obj.RotVelocity = Vector3.zero
			obj.CollisionGroup = GROUP_RAGDOLLS
			obj.CustomPhysicalProperties = RAGDOLL_PHYSICS
			
			if obj.Name == "HumanoidRootPart" then
				obj.Transparency = 1
				obj.CanCollide = false
			else
				-- Main visual parts (Arms/Legs) often get their collision disabled by Roblox
				-- We turn it on here, but we RELY on the Collider Parts we make below
				obj.CanCollide = false 
			end
			
		elseif obj:IsA("Weld") or obj:IsA("Motor6D") then
			obj:Destroy()
		end
	end

	-- RIGGING
	local Torso = ragdoll:FindFirstChild("Torso")
	if Torso then
		-- Create Collider for Torso
		CreateColliderPart(Torso, ragdoll)

		-- Head
		local Head = ragdoll:FindFirstChild("Head")
		if Head then
			CreateColliderPart(Head, ragdoll) -- Collider for Head
			
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

		-- Limbs
		for _, data in pairs(AttachmentData) do
			local limbName = data[1]
			local limb = ragdoll:FindFirstChild(limbName)
			if limb then
				-- [[ FIX ]] Create a separate collider part for the limb
				-- This guarantees collision with the ground
				CreateColliderPart(limb, ragdoll)
				
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

	ragdoll.Parent = workspace
	
	-- HIDE ORIGINAL
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("Decal") then
			part.Transparency = 1
			if part:IsA("BasePart") then part.CanCollide = false end
		end
	end

	-- FADE OUT
	task.delay(CLEAN_UP_TIME, function()
		if not ragdoll then return end
		local tweenInfo = TweenInfo.new(FADE_TIME, Enum.EasingStyle.Linear)
		
		for _, part in pairs(ragdoll:GetDescendants()) do
			if part:IsA("BasePart") or part:IsA("Decal") then
				local tween = TweenService:Create(part, tweenInfo, {Transparency = 1})
				tween:Play()
			end
		end
		
		task.wait(FADE_TIME)
		if ragdoll then ragdoll:Destroy() end
	end)
end

local function OnCharacterAdded(char)
	local hum = char:WaitForChild("Humanoid")
	hum.Died:Connect(function()
		CreateRagdoll(char)
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(OnCharacterAdded)
end)