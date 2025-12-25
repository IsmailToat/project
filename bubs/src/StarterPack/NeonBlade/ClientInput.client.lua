local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Tool = script.Parent
local Handle = Tool:WaitForChild("Handle")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local IDLE_ANIM_ID = "rbxassetid://131831147664844" 
local SWING_ANIM_ID_1 = "rbxassetid://88825748279087"
local SWING_ANIM_ID_2 = "rbxassetid://100344585400886"
local BLOCK_ANIM_ID = "rbxassetid://132425649556300"

local BlockMaxHP = 200
local CrosshairOffset = Vector2.new(40, 0)
local SwingCooldown = 0.15 
local BlockCooldown = 1.0 

--// UI SETUP
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SwordUI"
ScreenGui.Parent = Player:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local BarBG = Instance.new("Frame")
BarBG.Name = "BlockBarBG"
BarBG.Position = UDim2.new(0.5, CrosshairOffset.X, 0.5, CrosshairOffset.Y)
BarBG.Size = UDim2.new(0, 6, 0, 50)
BarBG.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
BarBG.BackgroundTransparency = 0.5
BarBG.Visible = false
BarBG.Parent = ScreenGui
Instance.new("UICorner", BarBG).CornerRadius = UDim.new(1,0)

local BarFill = Instance.new("Frame")
BarFill.Name = "BlockFill"
BarFill.AnchorPoint = Vector2.new(0, 1); BarFill.Position = UDim2.new(0, 0, 1, 0); BarFill.Size = UDim2.new(1, 0, 1, 0)
BarFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
BarFill.Parent = BarBG
Instance.new("UICorner", BarFill).CornerRadius = UDim.new(1,0)

local Tracks = {}
local IsBlocking = false
local Debounce = false
local ComboStep = 1
local LastBlockRelease = 0 

--// PARRY SPARK
local ParrySpark = Handle:FindFirstChild("ParrySpark") or Instance.new("ParticleEmitter")
ParrySpark.Name = "ParrySpark"
ParrySpark.Texture = "rbxassetid://243058284" 
ParrySpark.Color = ColorSequence.new(Color3.fromRGB(255, 255, 100)) 
ParrySpark.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)})
ParrySpark.Lifetime = NumberRange.new(0.3, 0.5)
ParrySpark.Rate = 0 
ParrySpark.Speed = NumberRange.new(5, 10)
ParrySpark.SpreadAngle = Vector2.new(360, 360)
ParrySpark.Enabled = false
ParrySpark.Parent = Handle

local function LoadAnimations(Char)
	local Animator = Char:WaitForChild("Humanoid"):WaitForChild("Animator")
	Tracks = {} 
	local function Load(Id, Prio)
		local A = Instance.new("Animation"); A.AnimationId = Id
		local T = Animator:LoadAnimation(A); T.Priority = Prio
		return T
	end
	Tracks.Idle = Load(IDLE_ANIM_ID, Enum.AnimationPriority.Movement); Tracks.Idle.Looped = true
	Tracks.Block = Load(BLOCK_ANIM_ID, Enum.AnimationPriority.Action); Tracks.Block.Looped = true
	Tracks.Swing1 = Load(SWING_ANIM_ID_1, Enum.AnimationPriority.Action)
	Tracks.Swing2 = Load(SWING_ANIM_ID_2, Enum.AnimationPriority.Action)
end

local function UpdateBlockUI()
	local CurrentHP = Tool:GetAttribute("BlockHP") or BlockMaxHP
	local Percent = math.clamp(CurrentHP / BlockMaxHP, 0, 1)
	TweenService:Create(BarFill, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, Percent, 0)}):Play()

	local TimeSinceRelease = os.clock() - LastBlockRelease
	if TimeSinceRelease < BlockCooldown then
		BarFill.BackgroundColor3 = Color3.fromRGB(100, 100, 100) 
	elseif Percent < 0.3 then
		BarFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50) 
	else
		BarFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255) 
	end
end

Tool.Activated:Connect(function()
	if Debounce or IsBlocking then return end
	Debounce = true

	if Tracks.Swing1 and Tracks.Swing2 then
		if ComboStep == 1 then Tracks.Swing1:Play(); ComboStep = 2
		else Tracks.Swing2:Play(); ComboStep = 1 end
	end

	local Sound = Handle:FindFirstChild("SlashSound")
	if not Sound then
		Sound = Instance.new("Sound", Handle); Sound.Name = "SlashSound"
		Sound.SoundId = "rbxassetid://6000293026"; Sound.Volume = 0.5
	end
	Sound:Play()

	local Remote = Tool:WaitForChild("CombatEvent", 2)
	if Remote then 
		-- Send Attack Direction
		Remote:FireServer("Attack", Camera.CFrame.LookVector) 
	end

	task.wait(SwingCooldown)
	Debounce = false 
end)

UserInputService.InputBegan:Connect(function(Input, P)
	if P or Tool.Parent ~= Player.Character then return end

	if Input.UserInputType == Enum.UserInputType.MouseButton2 and not Debounce then
		if os.clock() - LastBlockRelease < BlockCooldown then return end

		IsBlocking = true
		if Tracks.Block then Tracks.Block:Play(0.1) end
		BarBG.Visible = true

		if ParrySpark then
			ParrySpark:Emit(15) 
			ParrySpark.Enabled = true 
			task.delay(0.25, function()
				if IsBlocking and ParrySpark then ParrySpark.Enabled = false end
			end)
		end

		local Remote = Tool:FindFirstChild("CombatEvent")
		if Remote then 
			-- // UPDATED: Send Block Direction //
			Remote:FireServer("BlockStart", Camera.CFrame.LookVector) 
		end
	end
end)

UserInputService.InputEnded:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton2 then
		if IsBlocking then 
			IsBlocking = false
			LastBlockRelease = os.clock() 
			if ParrySpark then ParrySpark.Enabled = false end
			if Tracks.Block then Tracks.Block:Stop(0.1) end

			BarBG.Visible = true 
			UpdateBlockUI() 
			task.delay(BlockCooldown, function()
				if not IsBlocking then BarBG.Visible = false end
			end)

			local Remote = Tool:FindFirstChild("CombatEvent")
			if Remote then Remote:FireServer("BlockEnd") end
		end
	end
end)

Tool.Equipped:Connect(function()
	local Char = Player.Character
	if Char then
		LoadAnimations(Char)
		if Tracks.Idle then Tracks.Idle:Play(0.2) end
	end
	BarBG.Visible = false
end)

Tool.Unequipped:Connect(function()
	for _, T in pairs(Tracks) do T:Stop() end
	BarBG.Visible = false
	IsBlocking = false
	ComboStep = 1
	if ParrySpark then ParrySpark.Enabled = false end
end)

Tool:GetAttributeChangedSignal("BlockHP"):Connect(UpdateBlockUI)

game:GetService("RunService").Heartbeat:Connect(function()
	if BarBG.Visible then UpdateBlockUI() end
end)

workspace.ChildAdded:Connect(function(Child)
	if Child.Name == "HitboxVisual" then
		local Char = Player.Character
		if Char and Char:GetAttribute("DebugHitboxes") == true then
			Child.Transparency = 0.3 
		end
	end
end)