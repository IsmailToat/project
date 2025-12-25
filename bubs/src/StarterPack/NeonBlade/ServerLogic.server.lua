local Debris = game:GetService("Debris")
local Tool = script.Parent

local Remote = Tool:FindFirstChild("CombatEvent")
if not Remote then
	Remote = Instance.new("RemoteEvent"); Remote.Name = "CombatEvent"; Remote.Parent = Tool
end
local NPCEvent = Tool:FindFirstChild("NPCCombat")
if not NPCEvent then
	NPCEvent = Instance.new("BindableEvent"); NPCEvent.Name = "NPCCombat"; NPCEvent.Parent = Tool
end

--// SETTINGS
local Damage = 45
local BlockMaxHP = 200
local RegenDelay = 5
local ParryWindow = 0.25 
local BlockCooldown = 1.0 

local ColorParry = Color3.fromRGB(255, 255, 0)   
local ColorBlock = Color3.fromRGB(0, 200, 255)   

Tool:SetAttribute("BlockHP", BlockMaxHP)

--// STATE
local IsBlocking = false
local LastBlockEndTime = 0

--// VISUALS
local function SpawnHitboxVisual(CFrame, Size)
	local Box = Instance.new("Part")
	Box.Name = "HitboxVisual"
	Box.Anchored = true
	Box.CanCollide = false
	Box.Size = Size
	Box.CFrame = CFrame
	Box.Material = Enum.Material.ForceField
	Box.Color = Color3.fromRGB(255, 0, 0)
	Box.Transparency = 1 
	Box.Parent = workspace
	Debris:AddItem(Box, 0.2) 
end

local function StunPlayer(Char)
	local Hum = Char:FindFirstChild("Humanoid")
	if Hum then
		Hum.WalkSpeed = 0; Hum.JumpPower = 0
		task.delay(1.5, function()
			if Hum and Hum.Health > 0 then Hum.WalkSpeed = 16; Hum.JumpPower = 50 end
		end)
	end
end

local function CreateParryEffect(Position)
	local FXPart = Instance.new("Part")
	FXPart.Anchored = true; FXPart.CanCollide = false; FXPart.Transparency = 1
	FXPart.Position = Position
	FXPart.Parent = workspace
	Debris:AddItem(FXPart, 2)

	if Tool:FindFirstChild("Effects") then
		local S = Tool.Effects:FindFirstChild("ParrySound")
		if S then S:Clone().Parent = FXPart end
		local P = Tool.Effects:FindFirstChild("ParrySpark")
		if P then local C = P:Clone(); C.Parent = FXPart; C:Emit(50) end
	end
end

--// COMBAT
-- Updated to accept AimVector
local function PerformCombatAction(Char, Action, AimVector)
	local Root = Char:FindFirstChild("HumanoidRootPart")
	if not Root then return end

	if Action == "BlockStart" then
		if os.clock() - LastBlockEndTime < BlockCooldown then return end

		IsBlocking = true
		Tool:SetAttribute("BlockStartTimestamp", os.clock())

		local Shield = Instance.new("Highlight")
		Shield.Name = "BlockVisual"; Shield.FillColor = ColorParry; Shield.OutlineTransparency = 1
		Shield.FillTransparency = 0.6
		Shield.Parent = Char

		task.delay(ParryWindow, function()
			if IsBlocking and Shield and Shield.Parent then
				Shield.FillColor = ColorBlock
			end
		end)

	elseif Action == "BlockEnd" then
		IsBlocking = false
		LastBlockEndTime = os.clock()
		Tool:SetAttribute("BlockStartTimestamp", 0) 

		local Shield = Char:FindFirstChild("BlockVisual")
		if Shield then Shield:Destroy() end

	elseif Action == "Attack" then
		if IsBlocking then return end 

		-- // UPDATED RANGE & DIRECTION //
		-- Box Size: 6x6 wide, 12 long (Much longer reach)
		local BoxSize = Vector3.new(14, 5, 12)
		local StartPos = Root.Position

		-- Calculate Direction
		local Direction
		if typeof(AimVector) == "Vector3" then
			Direction = AimVector.Unit -- Player Camera Direction
		else
			Direction = Root.CFrame.LookVector -- NPC / Fallback
		end

		-- Create CFrame looking in that direction
		-- Offset forward by half the length (6 studs)
		local Origin = CFrame.lookAt(StartPos, StartPos + Direction)
		local BoxCFrame = Origin * CFrame.new(0, 0, -6)

		SpawnHitboxVisual(BoxCFrame, BoxSize)

		local Params = OverlapParams.new()
		Params.FilterDescendantsInstances = {Char}
		Params.FilterType = Enum.RaycastFilterType.Exclude

		local Parts = workspace:GetPartBoundsInBox(BoxCFrame, BoxSize, Params)
		local HitHumanoids = {}

		for _, Part in pairs(Parts) do
			local EnemyChar = Part.Parent
			local EnemyHum = EnemyChar:FindFirstChild("Humanoid")
			local EnemyRoot = EnemyChar:FindFirstChild("HumanoidRootPart")

			if EnemyHum and EnemyRoot and EnemyHum.Health > 0 and not HitHumanoids[EnemyHum] then
				HitHumanoids[EnemyHum] = true

				local EnemyIsBlocking = false
				if EnemyChar:FindFirstChild("BlockVisual") then EnemyIsBlocking = true end

				if EnemyIsBlocking then
					local Dist = (Root.Position - EnemyRoot.Position).Magnitude
					if Dist > 2 then 
						local VectorToAttacker = (Root.Position - EnemyRoot.Position).Unit
						local DefenderLook = EnemyRoot.CFrame.LookVector
						if VectorToAttacker:Dot(DefenderLook) < 0.2 then EnemyIsBlocking = false end
					end
				end

				if EnemyIsBlocking then
					local EnemyTool = EnemyChar:FindFirstChild("NeonBlade")
					local EnemyBlockTime = 0
					if EnemyTool then EnemyBlockTime = EnemyTool:GetAttribute("BlockStartTimestamp") or 0 end

					if (os.clock() - EnemyBlockTime) <= ParryWindow then
						CreateParryEffect(Root.Position)
						StunPlayer(Char) 
						return 
					end

					local CurrentBlockHP = EnemyTool and EnemyTool:GetAttribute("BlockHP") or BlockMaxHP
					local NewBlockHP = CurrentBlockHP - Damage

					if EnemyTool then 
						EnemyTool:SetAttribute("BlockHP", NewBlockHP)
						EnemyTool:SetAttribute("LastBlockHit", os.clock())
					end

					if NewBlockHP <= 0 then
						if EnemyChar:FindFirstChild("BlockVisual") then EnemyChar.BlockVisual:Destroy() end
						EnemyHum:TakeDamage(Damage)
						StunPlayer(EnemyChar) 
					else
						local BlockSound = Instance.new("Sound", EnemyRoot)
						BlockSound.SoundId = "rbxassetid://8514537845"
						BlockSound:Play(); Debris:AddItem(BlockSound, 1)
					end
					return 
				end

				EnemyHum:TakeDamage(Damage)
				local H = Instance.new("Highlight")
				H.FillColor = Color3.new(1,0,0); H.Parent = EnemyChar; Debris:AddItem(H, 0.2)
			end
		end
	end
end

--// EVENTS
Remote.OnServerEvent:Connect(function(Player, Action, Arg1)
	-- Arg1 is now AimVector (for Attacks) OR IsDebug (for Blocks)
	-- But PerformCombatAction handles AimVector.
	-- We pass Arg1 as AimVector.
	if Player.Character then PerformCombatAction(Player.Character, Action, Arg1) end
end)

NPCEvent.Event:Connect(function(Action)
	local Char = Tool.Parent
	if Char then PerformCombatAction(Char, Action, nil) end
end)

--// REGEN LOOP
task.spawn(function()
	while true do
		task.wait(0.5)
		local CurrentHP = Tool:GetAttribute("BlockHP") or BlockMaxHP
		local LastHit = Tool:GetAttribute("LastBlockHit") or 0
		if os.clock() - LastHit > RegenDelay and CurrentHP < BlockMaxHP then
			Tool:SetAttribute("BlockHP", math.min(CurrentHP + 20, BlockMaxHP))
		end
	end
end)
-- jip jip 
print("OWOWOWOWO")