local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- Get the Event
local Event = ReplicatedStorage:WaitForChild("BlastPackEvent")

-- Configuration
local Settings = {
	BlastRadius = 30,    
	BlastForce = 165,    
	UpwardBias = 20,     
}

local ActiveSatchels = {} 

local function CreateSatchel(Player, OriginCFrame, Velocity)
	if ActiveSatchels[Player] then
		ActiveSatchels[Player]:Destroy()
		ActiveSatchels[Player] = nil
	end

	local Satchel = Instance.new("Part")
	Satchel.Name = "BlastPack_" .. Player.Name
	Satchel.Size = Vector3.new(1, 0.3, 1)
	Satchel.Color = Color3.fromRGB(255, 100, 0)
	Satchel.Material = Enum.Material.Neon
	Satchel.CanCollide = true
	Satchel.TopSurface = Enum.SurfaceType.Smooth
	Satchel.BottomSurface = Enum.SurfaceType.Smooth
	Satchel.Massless = true 
	Satchel.CFrame = OriginCFrame

	-- // FIX: REMOVE BOUNCINESS //
	-- Density=1, Friction=2(Max Stick), Elasticity=0(No Bounce)
	-- The "100" weights ensure this OVERRIDES the floor's material properties
	Satchel.CustomPhysicalProperties = PhysicalProperties.new(1, 2, 0, 100, 100)

	local Beep = Instance.new("Sound")
	Beep.SoundId = "rbxassetid://9119713997" 
	Beep.Volume = 0.5
	Beep.Parent = Satchel
	Beep.Looped = true
	Beep:Play()

	Satchel.Parent = workspace

	-- Give Player Physics Control (Anti-Lag)
	Satchel:SetNetworkOwner(Player)

	Satchel.AssemblyLinearVelocity = Velocity

	local HasStuck = false

	-- Delay slightly so it doesn't stick to the player throwing it immediately
	task.delay(0.05, function()
		if not Satchel or not Satchel.Parent then return end

		Satchel.Touched:Connect(function(Hit)
			if HasStuck then return end
			if Hit:IsDescendantOf(Player.Character) then return end 
			if Hit.CanCollide == false then return end 

			HasStuck = true

			-- Anchor immediately
			Satchel.Anchored = true
			Satchel.AssemblyLinearVelocity = Vector3.zero
			Satchel.CanCollide = false 

			Beep.PlaybackSpeed = 1.5 
		end)
	end)

	ActiveSatchels[Player] = Satchel
	Debris:AddItem(Satchel, 10)

	Satchel.Destroying:Connect(function()
		if ActiveSatchels[Player] == Satchel then
			ActiveSatchels[Player] = nil
		end
	end)
end

local function DetonateSatchel(Player)
	local Satchel = ActiveSatchels[Player]
	if not Satchel then return end

	local SatchelPos = Satchel.Position

	local Explosion = Instance.new("Explosion")
	Explosion.Position = SatchelPos
	Explosion.BlastPressure = 0
	Explosion.BlastRadius = 0 
	Explosion.DestroyJointRadiusPercent = 0
	Explosion.Visible = true
	Explosion.Parent = workspace

	Satchel:Destroy()
	ActiveSatchels[Player] = nil

	local HitHumanoids = {} 
	local Parts = workspace:GetPartBoundsInRadius(SatchelPos, Settings.BlastRadius)

	for _, Part in pairs(Parts) do
		local Char = Part.Parent
		local Hum = Char:FindFirstChild("Humanoid")
		local Root = Char:FindFirstChild("HumanoidRootPart")

		if Hum and Root and not HitHumanoids[Hum] then
			HitHumanoids[Hum] = true

			-- Cleanup Physics
			for _, child in pairs(Root:GetChildren()) do
				if child:IsA("BodyVelocity") then
					child:Destroy()
				end
			end

			-- Calculate Force
			local Dist = (Root.Position - SatchelPos).Magnitude
			local ProximityFactor = 1 - (Dist / Settings.BlastRadius)
			ProximityFactor = math.max(ProximityFactor, 0.4) 

			local Direction = (Root.Position - SatchelPos).Unit

			local ForceVector = Direction * (Settings.BlastForce * ProximityFactor)
			ForceVector = ForceVector + Vector3.new(0, Settings.UpwardBias, 0)

			-- Apply
			local BV = Instance.new("BodyVelocity")
			BV.Name = "BlastVelocity"
			BV.MaxForce = Vector3.new(50000, 50000, 50000)
			BV.Velocity = ForceVector
			BV.Parent = Root

			Debris:AddItem(BV, 0.25) 
		end
	end
end

Event.OnServerEvent:Connect(function(Player, Action, Arg1, Arg2)
	if Action == "Throw" then
		CreateSatchel(Player, Arg1, Arg2)
	elseif Action == "Detonate" then
		DetonateSatchel(Player)
	end
end)