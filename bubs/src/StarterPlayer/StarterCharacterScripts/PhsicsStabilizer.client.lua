local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Char:WaitForChild("HumanoidRootPart")
local Humanoid = Char:WaitForChild("Humanoid")

print("Fixed Physics Stabilizer Active")

--// 1. DISABLE TRIPPING
-- This forces the Humanoid to ignore physics impacts that would normally make it fall.
Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)

--// 2. WATCH FOR RAGDOLL ATTEMPTS
-- If Roblox tries to force a fall state, we instantly force it back to Running.
Humanoid.StateChanged:Connect(function(old, new)
	if new == Enum.HumanoidStateType.FallingDown 
		or new == Enum.HumanoidStateType.Ragdoll 
		or new == Enum.HumanoidStateType.PlatformStanding then

		-- Instantly cancel the fall
		Humanoid:ChangeState(Enum.HumanoidStateType.Running)
	end
end)

--// 3. MAIN LOOP
RunService.Heartbeat:Connect(function()
	if not RootPart then return end

	-- ANTI-SPIN / ANTI-FLING
	-- If the character starts spinning uncontrollably (Angular Velocity), stop the spin.
	-- This prevents the "Tornado" effect when hitting walls.
	if RootPart.AssemblyAngularVelocity.Magnitude > 15 then
		RootPart.AssemblyAngularVelocity = Vector3.new(0,0,0)
	end

	-- UPRIGHT RECOVERY
	-- If you somehow get knocked flat on your face (and aren't WallRunning), snap back up.
	-- We check if the UpVector is pointing sideways or down.
	if not Char:GetAttribute("IsWallRunning") then
		if RootPart.CFrame.UpVector.Y < 0.2 then
			-- We are tipped over. Reset rotation to upright, keep position.
			local pos = RootPart.Position
			local look = RootPart.CFrame.LookVector
			-- Force upright CFrame
			RootPart.CFrame = CFrame.lookAt(pos, pos + Vector3.new(look.X, 0, look.Z))
			RootPart.AssemblyAngularVelocity = Vector3.zero
		end
	end
end)