local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

--// LOOP EVERY FRAME
RunService.RenderStepped:Connect(function()
	local Char = Player.Character
	if not Char then return end

	for _, Part in pairs(Char:GetChildren()) do
		if Part:IsA("BasePart") then

			local Name = Part.Name

			-- Logic:
			-- 1. Hide HEAD (Face)
			-- 2. Hide TORSO (Prevents clipping when looking down)
			-- 3. Hide HumanoidRootPart (Invisible collider)
			-- 4. Show everything else (Arms, Legs)

			if Name == "Head" or Name == "Torso" or Name == "UpperTorso" or Name == "LowerTorso" or Name == "HumanoidRootPart" then
				Part.LocalTransparencyModifier = 1 -- Invisible
			else
				-- Arms and Legs will be visible
				Part.LocalTransparencyModifier = 0 -- Visible
			end
		end
	end
end)