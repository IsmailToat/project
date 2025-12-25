local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

print("SERVER: PhaseShift Script Loaded")

--// SETUP REMOTE EVENT
local RemoteName = "PhaseShiftEvent"
local Remote = ReplicatedStorage:FindFirstChild(RemoteName)
if not Remote then
	Remote = Instance.new("RemoteEvent")
	Remote.Name = RemoteName
	Remote.Parent = ReplicatedStorage
end

--// SETTINGS
local Settings = {
	Duration = 4,
	Cooldown = 10,
	SpeedMultiplier = 2.2,
	Color = Color3.fromRGB(238, 162, 250), -- Light Purple
}

--// STATE
local PlayerCooldowns = {}

--// HELPER: CREATE TRAIL
local function CreateServerTrail(RootPart)
	local Att0 = Instance.new("Attachment")
	Att0.Name = "TrailAtt0"; Att0.Position = Vector3.new(0, 2.5, 0); Att0.Parent = RootPart

	local Att1 = Instance.new("Attachment")
	Att1.Name = "TrailAtt1"; Att1.Position = Vector3.new(0, -2.5, 0); Att1.Parent = RootPart

	local Trail = Instance.new("Trail")
	Trail.Name = "PhaseTrail"
	Trail.Attachment0 = Att0; Trail.Attachment1 = Att1
	Trail.Color = ColorSequence.new(Settings.Color)
	Trail.Texture = "rbxassetid://4541511300" 
	Trail.Transparency = NumberSequence.new(0.2, 1)
	Trail.Lifetime = 0.5 
	Trail.MinLength = 0.1
	Trail.LightEmission = 0.8 
	Trail.FaceCamera = true
	Trail.Parent = RootPart
	
	return Trail, Att0, Att1
end

--// ACTION LISTENER
Remote.OnServerEvent:Connect(function(Player, Action)
	if Action ~= "Activate" then return end
	
	local Char = Player.Character
	if not Char then return end
	
	-- Cooldown Check
	local LastUse = PlayerCooldowns[Player.UserId] or 0
	if os.clock() - LastUse < Settings.Cooldown then 
		print("SERVER: Phase Shift on Cooldown for", Player.Name)
		return 
	end
	PlayerCooldowns[Player.UserId] = os.clock()
	
	print("SERVER: Activating Phase Shift for", Player.Name)
	
	--// 1. ACTIVATE MECHANICS
	Char:SetAttribute("IsPhaseShifted", true)
	Char:SetAttribute("SpeedBoost", Settings.SpeedMultiplier)
	
	--// 2. SERVER-SIDE VISUALS & GHOST MODE
	local PartStates = {}
	
	for _, Part in pairs(Char:GetDescendants()) do
		if Part:IsA("BasePart") then
			-- Save State
			PartStates[Part] = {
				CanQuery = Part.CanQuery,
				CanTouch = Part.CanTouch,
				Transparency = Part.Transparency,
				Material = Part.Material,
				Color = Part.Color
			}
			
			-- PHYSICS: Disable Hitboxes
			Part.CanQuery = false 
			Part.CanTouch = false
			
			-- VISUALS: Purple & Translucent
			if Part.Name ~= "HumanoidRootPart" then
				Part.Transparency = 0.3
				Part.Material = Enum.Material.ForceField
				Part.Color = Settings.Color
			end
		end
	end
	
	-- Create Trail
	local Root = Char:FindFirstChild("HumanoidRootPart")
	local Trail, A0, A1
	if Root then
		Trail, A0, A1 = CreateServerTrail(Root)
	end
	
	-- Notify Client (Start UI)
	Remote:FireClient(Player, "Activated")
	
	--// 3. DEACTIVATE AFTER DURATION
	task.delay(Settings.Duration, function()
		if not Char or not Char.Parent then return end
		
		-- Restore Physics & Visuals
		for Part, State in pairs(PartStates) do
			if Part and Part.Parent then
				Part.CanQuery = State.CanQuery
				Part.CanTouch = State.CanTouch
				Part.Transparency = State.Transparency
				Part.Material = State.Material
				Part.Color = State.Color
			end
		end
		
		-- Reset Attributes
		Char:SetAttribute("IsPhaseShifted", false)
		Char:SetAttribute("SpeedBoost", 1)
		
		-- Cleanup Trail
		if Trail then Trail:Destroy() end
		if A0 then A0:Destroy() end
		if A1 then A1:Destroy() end
		
		print("SERVER: Phase Shift Ended for", Player.Name)
	end)
end)