local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Char:WaitForChild("Humanoid")
local RootPart = Char:WaitForChild("HumanoidRootPart")

--// CONFIGURATION
local Settings = {
	JumpForce = 38,  -- Default Roblox is 50. 38 is "a little less".
	Cooldown = 0.2,  -- Prevents accidental double inputs
}

--// DISABLE DEFAULT JUMPING
-- We set JumpPower to 0 so Roblox doesn't auto-jump when you hold space.
Humanoid.UseJumpPower = true
Humanoid.JumpPower = 0 

local CanJump = true

UserInputService.InputBegan:Connect(function(Input, Processed)
	if Processed then return end

	if Input.KeyCode == Enum.KeyCode.Space then
		-- Check if on ground and CanJump is ready
		if Humanoid.FloorMaterial ~= Enum.Material.Air and CanJump then

			CanJump = false

			-- Apply Jump Velocity Manually
			-- We preserve current X/Z momentum and just set Y
			local CurrentVel = RootPart.AssemblyLinearVelocity
			RootPart.AssemblyLinearVelocity = Vector3.new(CurrentVel.X, Settings.JumpForce, CurrentVel.Z)

			-- Cooldown to prevent spam
			task.delay(Settings.Cooldown, function()
				CanJump = true
			end)
		end
	end
end)

--// Safety Check: Ensure JumpPower stays 0
Humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
	if Humanoid.JumpPower ~= 0 then
		Humanoid.JumpPower = 0
	end
end)