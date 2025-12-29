local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Remote = ReplicatedStorage.WeaponEvents.ShotgunEvent

-- SETTINGS
local PELLETS = 12
local SPEED = 300
local DMG = 6
local SLUG_DMG_AOE = 75
-- Math for perfect spread
local GOLDEN_ANGLE = math.pi * (3 - math.sqrt(5))

local function FireProjectile(Owner, Origin, Dir, IsSlug)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery = true, false, false
	p.Material = Enum.Material.Neon
	p.Color = IsSlug and Color3.fromRGB(255,50,50) or Color3.fromRGB(255,150,50)
	p.Size = IsSlug and Vector3.new(0.4,0.4,4) or Vector3.new(0.1,0.1,3)
	p.CFrame = CFrame.new(Origin, Origin + Dir)
	p.Parent = workspace
	
	local traveled = 0
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if not p.Parent then conn:Disconnect() return end
		local step = SPEED * dt
		local nextPos = p.Position + (Dir * step)
		
		local params = RaycastParams.new()
		if Owner.Character then params.FilterDescendantsInstances = {Owner.Character} end
		local result = workspace:Raycast(p.Position, (nextPos - p.Position), params)
		
		if result then
			conn:Disconnect()
			p:Destroy()
			
			-- Damage
			local h = result.Instance.Parent:FindFirstChild("Humanoid") or result.Instance.Parent.Parent:FindFirstChild("Humanoid")
			if h then h:TakeDamage(IsSlug and DMG*2 or DMG) end
			
			-- Slug Explosion
			if IsSlug then
				local exp = Instance.new("Explosion", workspace)
				exp.Position = result.Position
				exp.BlastRadius, exp.BlastPressure = 0, 200000
				
				local s = Instance.new("Sound", workspace)
				s.SoundId = "rbxassetid://142070127"; s.Volume=2; s.PlayOnRemove=true; s:Destroy()
				
				for _, v in pairs(workspace:GetChildren()) do
					if v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v ~= Owner.Character then
						if (v.HumanoidRootPart.Position - result.Position).Magnitude < 12 then
							v.Humanoid:TakeDamage(SLUG_DMG_AOE)
						end
					end
				end
			end
		else
			p.CFrame = CFrame.new(nextPos, nextPos + Dir)
			traveled += step
			if traveled > 500 then conn:Disconnect(); p:Destroy() end
		end
	end)
end

Remote.OnServerEvent:Connect(function(Player, Action, OriginPos, LookVector, Ratio)
	local Char = Player.Character
	if not Char then return end
	
	if Action == "Shoot" then
		-- Calc Spread
		local spread = 15 - (14.5 * Ratio)
		local isSlug = (Ratio > 0.9)
		
		-- Random rotation for the whole pattern so it doesn't look identical every time
		local patternRot = math.random() * math.pi * 2
		
		for i = 1, PELLETS do
			-- [[ FIBONACCI SPIRAL FORMULA ]]
			-- This guarantees pellets are evenly spaced apart
			local rNormalized = math.sqrt(i / PELLETS)
			local r = rNormalized * math.rad(spread)
			local theta = (i * GOLDEN_ANGLE) + patternRot -- Apply rotation
			
			local x = r * math.cos(theta)
			local y = r * math.sin(theta)
			
			local aimCF = CFrame.lookAt(OriginPos, OriginPos + LookVector)
			local spreadCF = aimCF * CFrame.Angles(x, y, 0)
			
			FireProjectile(Player, OriginPos, spreadCF.LookVector, isSlug)
		end
		
		local s = Instance.new("Sound", Char.Head)
		s.SoundId = isSlug and "rbxassetid://169446452" or "rbxassetid://142382109"
		s.Pitch = isSlug and 0.8 or 1
		s.PlayOnRemove = true; s:Destroy()
		
	elseif Action == "OverchargeExplode" then
		local exp = Instance.new("Explosion", workspace)
		exp.Position = Char.HumanoidRootPart.Position
		exp.BlastRadius, exp.BlastPressure = 30, 500000
		exp.DestroyJointRadiusPercent = 0
		
		for _, v in pairs(workspace:GetChildren()) do
			if v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") then
				if (v.HumanoidRootPart.Position - Char.HumanoidRootPart.Position).Magnitude < 30 then
					v.Humanoid.Health = 0
				end
			end
		end
	end
end)