local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local PROTECT_TIME = 5.0
local TRANSPARENCY_VAL = 0.5

local function OnCharacterAdded(character)
	-- 1. Create ForceField (God Mode)
	local ff = Instance.new("ForceField")
	ff.Visible = true -- Optional: Set false if you just want transparency
	ff.Parent = character
	Debris:AddItem(ff, PROTECT_TIME)

	-- 2. Make Transparent (Ghost Mode)
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Transparency = TRANSPARENCY_VAL
		end
	end

	-- 3. Wait and Restore
	task.delay(PROTECT_TIME, function()
		if character then
			for _, part in pairs(character:GetDescendants()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					-- Restore original transparency (usually 0)
					-- Check if it's the Handle of a tool or glass, otherwise 0
					if part.Transparency == TRANSPARENCY_VAL then
						part.Transparency = 0
					end
				end
			end
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(OnCharacterAdded)
end)