local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Char:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")

--// CONFIGURATION
local Settings = {
	BaseRunSpeed = 35,      -- Normal Running Speed
	AnimationFade = 0.2,
}

--// Load Animation
local AnimObj = script:WaitForChild("RunAnim", 5)
if not AnimObj then
	warn("Run Script: Missing 'RunAnim' Animation Object!")
	script.Disabled = true
	return
end

local RunTrack = Animator:LoadAnimation(AnimObj)
RunTrack.Priority = Enum.AnimationPriority.Movement
RunTrack.Looped = true

--// Initialize Speed Multiplier Attribute
if not Char:GetAttribute("SpeedBoost") then
	Char:SetAttribute("SpeedBoost", 1) -- Default to 1x (Normal Speed)
end

--// MAIN LOOP
RunService.Heartbeat:Connect(function()

	-- 1. CALCULATE SPEED
	-- Speed = 35 * (Boost Multiplier)
	local CurrentBoost = Char:GetAttribute("SpeedBoost") or 1
	local TargetSpeed = Settings.BaseRunSpeed * CurrentBoost

	if Humanoid.WalkSpeed ~= TargetSpeed then
		Humanoid.WalkSpeed = TargetSpeed
	end

	-- 2. ANIMATION LOGIC
	local IsMoving = Humanoid.MoveDirection.Magnitude > 0
	local IsGrounded = Humanoid.FloorMaterial ~= Enum.Material.Air

	if IsMoving and IsGrounded then
		if not RunTrack.IsPlaying then
			RunTrack:Play(Settings.AnimationFade)
		end
	else
		if RunTrack.IsPlaying then
			RunTrack:Stop(Settings.AnimationFade)
		end
	end
end)