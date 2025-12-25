local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Char:WaitForChild("HumanoidRootPart")
local Humanoid = Char:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")
local Camera = workspace.CurrentCamera 

--// SETTINGS
local Settings = {
	Key = Enum.KeyCode.Q,       
	Cooldown = 5,
	DashTime = 0.7,            
	DashSpeed = 120,            
	Color = Color3.fromRGB(238, 162, 250), 
	HitboxSize = Vector3.new(6, 6, 6)
}

--// REMOTE
local Remote = ReplicatedStorage:WaitForChild("SlashDashEvent")

--// STATE
local OnCooldown = false
local IsDashing = false

--// UI SETUP
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SlashDashUI"
ScreenGui.Parent = Player:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local BarBG = Instance.new("Frame")
BarBG.Name = "BarBG"; BarBG.AnchorPoint = Vector2.new(0.5, 1); BarBG.Position = UDim2.new(0.65, 0, 0.95, 0)
BarBG.Size = UDim2.new(0, 150, 0, 6); BarBG.BackgroundColor3 = Color3.fromRGB(40,40,40); BarBG.Visible = false
BarBG.Parent = ScreenGui; Instance.new("UICorner", BarBG).CornerRadius = UDim.new(1,0)

local BarFill = Instance.new("Frame")
BarFill.Name = "Fill"; BarFill.Size = UDim2.new(1, 0, 1, 0); BarFill.BackgroundColor3 = Settings.Color
BarFill.Parent = BarBG; Instance.new("UICorner", BarFill).CornerRadius = UDim.new(1,0)

local Label = Instance.new("TextLabel")
Label.Text = "SLASH DASH [Q]"; Label.Font = Enum.Font.GothamBold; Label.TextSize = 10
Label.TextColor3 = Settings.Color; Label.BackgroundTransparency = 1; Label.Position = UDim2.new(0,0,-2.5,0)
Label.Size = UDim2.new(1,0,1,0); Label.Parent = BarBG

--// ANIMATION
local DashAnim = Instance.new("Animation")
DashAnim.AnimationId = "rbxassetid://88825748279087" 
local AnimTrack = Animator:LoadAnimation(DashAnim)

--// TRAIL SETUP
local Att0 = Instance.new("Attachment", RootPart); Att0.Position = Vector3.new(0, 1, 0)
local Att1 = Instance.new("Attachment", RootPart); Att1.Position = Vector3.new(0, -1, 0)
local Trail = Instance.new("Trail")
Trail.Color = ColorSequence.new(Settings.Color)
Trail.Transparency = NumberSequence.new(0.2, 1)
Trail.Lifetime = 0.4
Trail.Enabled = false
Trail.Parent = RootPart; Trail.Attachment0 = Att0; Trail.Attachment1 = Att1

--// FUNCTIONS
local function ActivateAbility()
	if OnCooldown or IsDashing then return end
	if Char:GetAttribute("IsPhaseShifted") then return end
	
	OnCooldown = true
	IsDashing = true
	
	-- 1. PHYSICS (Omni-Directional Movement)
	local DashDirection = Camera.CFrame.LookVector
	
	local Velocity = Instance.new("LinearVelocity")
	Velocity.MaxForce = 1000000
	Velocity.VectorVelocity = DashDirection * Settings.DashSpeed
	Velocity.Attachment0 = RootPart:FindFirstChild("RootAttachment") or Instance.new("Attachment", RootPart)
	Velocity.Parent = RootPart
	
	-- 2. ROTATION STABILIZER (Fixes Ragdoll Issue)
	-- Instead of looking at DashDirection, we look at a "Flattened" version of it.
	-- This keeps the character upright (Y axis preserved) but rotates them to face the dash compass direction.
	local FlatDir = Vector3.new(DashDirection.X, 0, DashDirection.Z)
	if FlatDir.Magnitude < 0.1 then 
		-- If looking straight up/down, keep current rotation
		FlatDir = RootPart.CFrame.LookVector 
	end

	local Align = Instance.new("AlignOrientation")
	Align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	Align.Attachment0 = Velocity.Attachment0
	Align.RigidityEnabled = true
	-- Look at the Flat Direction, but force UpVector to be (0,1,0)
	Align.CFrame = CFrame.lookAt(Vector3.zero, FlatDir) 
	Align.Parent = RootPart
	Debris:AddItem(Align, Settings.DashTime)

	-- 3. VISUALS
	Trail.Enabled = true
	AnimTrack:Play()
	
	local DashSound = Instance.new("Sound")
	DashSound.SoundId = "rbxassetid://4594396001" 
	DashSound.Parent = RootPart
	DashSound:Play()
	Debris:AddItem(DashSound, 1)
	
	-- 4. HIT DETECTION LOOP
	local HitHumanoids = {}
	local Connection
	Connection = RunService.RenderStepped:Connect(function()
		local Params = OverlapParams.new()
		Params.FilterDescendantsInstances = {Char}
		Params.FilterType = Enum.RaycastFilterType.Exclude
		
		-- Hitbox still follows the camera (so you can hit things above you)
		local CurrentDashDir = Camera.CFrame.LookVector
		local Origin = RootPart.Position
		local HitboxCFrame = CFrame.lookAt(Origin, Origin + CurrentDashDir) * CFrame.new(0, 0, -3)
		
		-- // DEBUG HITBOX VISUALIZATION //
		if Char:GetAttribute("DebugHitboxes") == true then
			local Viz = Instance.new("Part")
			Viz.Name = "DebugHitbox"
			Viz.Anchored = true; Viz.CanCollide = false
			Viz.Size = Settings.HitboxSize
			Viz.CFrame = HitboxCFrame
			Viz.Color = Color3.new(1, 0, 0)
			Viz.Transparency = 0.6
			Viz.Material = Enum.Material.ForceField
			Viz.Parent = workspace
			Debris:AddItem(Viz, 0.1) 
		end
		
		local Parts = workspace:GetPartBoundsInBox(HitboxCFrame, Settings.HitboxSize, Params)
		for _, P in pairs(Parts) do
			local EnemyChar = P.Parent
			local EnemyHum = EnemyChar:FindFirstChild("Humanoid")
			if EnemyHum and EnemyHum.Health > 0 and not HitHumanoids[EnemyHum] then
				HitHumanoids[EnemyHum] = true
				Remote:FireServer("Hit", EnemyHum)
				
				local Spark = Instance.new("Part")
				Spark.Size = Vector3.new(1,1,1); Spark.Anchored = true; Spark.CanCollide = false
				Spark.Material = Enum.Material.Neon; Spark.Color = Settings.Color
				Spark.CFrame = P.CFrame
				Spark.Parent = workspace
				Debris:AddItem(Spark, 0.1)
			end
		end
	end)
	
	-- 5. CLEANUP
	task.delay(Settings.DashTime, function()
		Velocity:Destroy() 
		Connection:Disconnect() 
		Trail.Enabled = false
		IsDashing = false
		
		-- Kill momentum softly
		RootPart.AssemblyLinearVelocity = Vector3.new(0, -5, 0) 
		
		-- 6. UI COOLDOWN
		BarBG.Visible = true
		Label.Text = "RECHARGING"
		Label.TextColor3 = Color3.fromRGB(150,150,150)
		BarFill.Size = UDim2.new(0,0,1,0)
		
		TweenService:Create(BarFill, TweenInfo.new(Settings.Cooldown, Enum.EasingStyle.Linear), {
			Size = UDim2.new(1,0,1,0)
		}):Play()
		
		task.delay(Settings.Cooldown, function()
			OnCooldown = false
			Label.Text = "SLASH DASH [Q]"
			Label.TextColor3 = Settings.Color
			task.delay(1, function() if not OnCooldown then BarBG.Visible = false end end)
		end)
	end)
end

UserInputService.InputBegan:Connect(function(Input, P)
	if P then return end
	if Input.KeyCode == Settings.Key then
		ActivateAbility()
	end
end)