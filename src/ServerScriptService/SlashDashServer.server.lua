local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

--// SETUP REMOTE EVENT
local RemoteName = "SlashDashEvent"
local Remote = ReplicatedStorage:FindFirstChild(RemoteName)
if not Remote then
	Remote = Instance.new("RemoteEvent")
	Remote.Name = RemoteName
	Remote.Parent = ReplicatedStorage
end

--// SETTINGS
local DAMAGE = 30
local SLOW_DURATION = 2.5
local SLOW_SPEED = 6

--// FUNCTIONS
local function ApplySlow(Humanoid)
	if not Humanoid then return end
	
	-- We use an attribute to prevent overwriting existing speed boosts if possible
	-- But for a hard slow, we force WalkSpeed
	local OriginalSpeed = Humanoid.WalkSpeed
	
	-- Apply Slow
	Humanoid.WalkSpeed = SLOW_SPEED
	
	-- Visual Indicator (Optional Highlight)
	local Char = Humanoid.Parent
	local Highlight = Instance.new("Highlight")
	Highlight.FillColor = Color3.fromRGB(0, 255, 255) -- Cyan for "Frozen/Slow"
	Highlight.OutlineTransparency = 1
	Highlight.FillTransparency = 0.5
	Highlight.Parent = Char
	Debris:AddItem(Highlight, SLOW_DURATION)

	-- Reset after duration
	task.delay(SLOW_DURATION, function()
		if Humanoid and Humanoid.Health > 0 then
			-- Reset to 16 or their previous speed
			Humanoid.WalkSpeed = 16 
		end
	end)
end

Remote.OnServerEvent:Connect(function(Player, Action, TargetHumanoid)
	if Action == "Hit" and TargetHumanoid then
		-- Sanity check: Ensure target isn't the attacker
		if TargetHumanoid.Parent == Player.Character then return end

		TargetHumanoid:TakeDamage(DAMAGE)
		ApplySlow(TargetHumanoid)
		
		-- Play Hit Sound
		local Root = TargetHumanoid.Parent:FindFirstChild("HumanoidRootPart")
		if Root then
			local S = Instance.new("Sound")
			S.SoundId = "rbxassetid://3932505023" -- Sharp slash sound
			S.Volume = 0.5
			S.Parent = Root
			S:Play()
			Debris:AddItem(S, 1)
		end
	end
end)