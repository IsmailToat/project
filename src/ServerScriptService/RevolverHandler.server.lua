local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")

print("✅ Revolver Handler v5.4 (Tween Fix) LOADED") 

-- // SAFE EVENT GETTER //
local Events = ReplicatedStorage:WaitForChild("WeaponEvents", 10)
if not Events then error("FATAL: WeaponEvents folder missing!") end
local Remote = Events:WaitForChild("RevolverEvent", 10)
if not Remote then error("FATAL: RevolverEvent missing!") end

-- // CONFIGURATION //
local BASE_DAMAGE = 35
local COIN_ADD_MULT = 1.2
local RICOCHET_RANGE = 70
local DEAD_COIN_PHYSICS = PhysicalProperties.new(100, 100, 0, 100, 100)
local COIN_GROUP = "Coins"

-- // PHYSICS TUNING //
local THROW_FORWARD_FORCE = 50 
local THROW_UP_FORCE = 60      

-- // SETUP COLLISION GROUPS //
pcall(function()
	if not PhysicsService:IsCollisionGroupRegistered(COIN_GROUP) then
		PhysicsService:RegisterCollisionGroup(COIN_GROUP)
	end
	PhysicsService:CollisionGroupSetCollidable(COIN_GROUP, COIN_GROUP, false)
end)

-- // VISUALS: TAPERED BEAM //
local function CreateVisualBeam(origin, endPoint, color, thickness)
	if typeof(color) ~= "Color3" then color = Color3.new(1, 1, 1) end

	-- Create Holder
	local holder = Instance.new("Part")
	holder.Name = "BeamHolder"
	holder.Transparency = 1
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Anchored = true
	holder.Size = Vector3.new(0.1, 0.1, 0.1)
	holder.CFrame = CFrame.new(origin)
	holder.Parent = workspace

	-- Attachments
	local att0 = Instance.new("Attachment")
	att0.Position = Vector3.zero
	att0.Parent = holder

	local att1 = Instance.new("Attachment")
	att1.Position = holder.CFrame:PointToObjectSpace(endPoint)
	att1.Parent = holder

	-- Beam
	local beam = Instance.new("Beam")
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Color = ColorSequence.new(color)
	beam.FaceCamera = true
	beam.Width0 = thickness
	beam.Width1 = 0
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Parent = holder

	-- [[ FIX: ONLY TWEEN WIDTH ]]
	-- Tweening 'Transparency' on beams causes errors because it's a NumberSequence.
	-- Shrinking Width0 to 0 creates the same fade-out effect.
	local tween = TweenService:Create(beam, TweenInfo.new(0.3), {
		Width0 = 0 
	})
	
	tween:Play()
	Debris:AddItem(holder, 0.3) -- This will now run correctly
end

-- // WALL CHECK //
local function IsVisible(origin, targetPart, ignoreList)
	local dir = targetPart.Position - origin
	local dist = dir.Magnitude
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = ignoreList
	params.FilterType = Enum.RaycastFilterType.Exclude
	
	local result = workspace:Raycast(origin, dir.Unit * dist, params)
	if result then
		if result.Instance:IsDescendantOf(targetPart.Parent) or result.Instance == targetPart then return true end
		if result.Instance.Name == "CoinHitbox" and result.Instance == targetPart then return true end
		return false
	end
	return true
end

-- // NEXT TARGET //
local function GetNextTarget(origin, currentCoin, shooter)
	local potentialTargets = workspace:GetChildren()
	local ignoreList = {shooter.Character, currentCoin} 
	local bestTarget = nil
	local shortestDist = RICOCHET_RANGE
	
	-- 1. COINS
	for _, v in pairs(potentialTargets) do
		local coin = v:FindFirstChild("CoinHitbox") and v 
		if v.Name == "Coin" then coin = v end 
		
		if coin and coin ~= currentCoin and not coin:GetAttribute("Expired") then
			if coin:GetAttribute("OwnerId") == shooter.UserId then
				local hitbox = coin:FindFirstChild("CoinHitbox") or coin
				local dist = (hitbox.Position - origin).Magnitude
				if dist < shortestDist and IsVisible(origin, hitbox, ignoreList) then
					shortestDist = dist
					bestTarget = hitbox
				end
			end
		end
	end
	if bestTarget then return bestTarget end
	
	-- 2. HEADS
	shortestDist = RICOCHET_RANGE
	for _, v in pairs(potentialTargets) do
		local hum = v:FindFirstChild("Humanoid")
		local head = v:FindFirstChild("Head")
		if v ~= shooter.Character and hum and hum.Health > 0 and head then
			local dist = (head.Position - origin).Magnitude
			if dist < shortestDist and IsVisible(origin, head, ignoreList) then
				shortestDist = dist
				bestTarget = head
			end
		end
	end
	if bestTarget then return bestTarget end

	-- 3. BODY
	shortestDist = RICOCHET_RANGE
	for _, v in pairs(potentialTargets) do
		local hum = v:FindFirstChild("Humanoid")
		local root = v:FindFirstChild("HumanoidRootPart")
		if v ~= shooter.Character and hum and hum.Health > 0 and root then
			local dist = (root.Position - origin).Magnitude
			if dist < shortestDist and IsVisible(origin, root, ignoreList) then
				shortestDist = dist
				bestTarget = root
			end
		end
	end
	if bestTarget then return bestTarget end
	
	return nil
end

-- // SHOOT RECURSION //
local function ProcessShot(shooter, origin, direction, coinCount, ignoreList)
	if coinCount > 10 then return end
	
	local FinalBeamColor = Color3.fromRGB(255, 255, 200)
	local MaxDistance = (coinCount > 0) and 70 or 1000

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = ignoreList
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local result = workspace:Raycast(origin, direction * MaxDistance, rayParams)
	local endPos = origin + (direction * MaxDistance)
	
	if result then
		endPos = result.Position
		local hit = result.Instance
		
		-- [[ HIT COIN ]]
		if hit.Name == "Coin" or hit.Name == "CoinHitbox" then
			local coin = (hit.Name == "Coin") and hit or hit.Parent
			local isMyCoin = (coin:GetAttribute("OwnerId") == shooter.UserId)
			local isExpired = (coin:GetAttribute("Expired") == true)
			
			if isExpired or not isMyCoin then
				CreateVisualBeam(origin, endPos, FinalBeamColor, 0.2)
				return
			end
			
			local coinPos = coin.Position
			CreateVisualBeam(origin, coinPos, Color3.fromRGB(255, 200, 0), 0.3)
			
			local s = Instance.new("Sound", workspace)
			s.SoundId = "rbxassetid://9119713997"; s.Volume = 2; s.PlayOnRemove = true; s:Destroy()
			
			table.insert(ignoreList, coin)
			local nextTarget = GetNextTarget(coinPos, coin, shooter)
			local newDir = nextTarget and (nextTarget.Position - coinPos).Unit or Vector3.new(math.random()-0.5, math.random()-0.5, math.random()-0.5).Unit
			
			coin:Destroy()
			ProcessShot(shooter, coinPos, newDir, coinCount + 1, ignoreList)
			return
		end
		
		-- [[ HIT ENEMY ]]
		local hum = hit.Parent:FindFirstChild("Humanoid") or hit.Parent.Parent:FindFirstChild("Humanoid")
		if hum then
			local dmg = BASE_DAMAGE + (BASE_DAMAGE * COIN_ADD_MULT * coinCount)
			if hit.Name == "Head" then dmg = dmg * 2 end
			
			hum:TakeDamage(dmg)
			FinalBeamColor = Color3.fromRGB(255, 50, 50) 
			CreateVisualBeam(origin, endPos, FinalBeamColor, 0.4 + (0.1 * coinCount))
			return
		end
	end
	
	-- [[ HIT WALL OR SKY ]]
	CreateVisualBeam(origin, endPos, FinalBeamColor, 0.2)
end

-- // EVENT LISTENER //
Remote.OnServerEvent:Connect(function(Player, Action, OriginPos, LookVector)
	local Char = Player.Character
	if not Char then return end
	
	if Action == "Shoot" then
		local AdjustedOrigin = OriginPos + (LookVector * 0.5)
		ProcessShot(Player, AdjustedOrigin, LookVector, 0, {Char})
		
	elseif Action == "ThrowCoin" then
		local coin = Instance.new("Part")
		coin.Name = "Coin"
		coin.Shape = Enum.PartType.Cylinder
		coin.Size = Vector3.new(0.2, 1, 1)
		coin.Color = Color3.fromRGB(255, 200, 0)
		coin.Material = Enum.Material.Neon
		coin.CFrame = CFrame.new(OriginPos + (LookVector * 1)) * CFrame.Angles(0, math.pi/2, 0)
		pcall(function() coin.CollisionGroup = COIN_GROUP end)
		
		coin:SetAttribute("OwnerId", Player.UserId)
		
		local vel = (LookVector * THROW_FORWARD_FORCE) + Vector3.new(0, THROW_UP_FORCE, 0)
		if Char:FindFirstChild("HumanoidRootPart") then
			vel = vel + Char.HumanoidRootPart.AssemblyLinearVelocity
		end
		coin.AssemblyLinearVelocity = vel
		coin.AssemblyAngularVelocity = Vector3.new(10, 0, 0)
		
		local box = Instance.new("Part")
		box.Name = "CoinHitbox"
		box.Size = Vector3.new(11, 11, 11) 
		box.Transparency = 1
		box.CanCollide = false
		box.Massless = true
		pcall(function() box.CollisionGroup = COIN_GROUP end)
		box.CFrame = coin.CFrame
		box.Parent = coin
		local w = Instance.new("WeldConstraint", box)
		w.Part0, w.Part1 = coin, box; w.Parent = box
		
		local a0 = Instance.new("Attachment", coin); a0.Position = Vector3.new(0,0.5,0)
		local a1 = Instance.new("Attachment", coin); a1.Position = Vector3.new(0,-0.5,0)
		local t = Instance.new("Trail", coin)
		t.Attachment0 = a0; t.Attachment1 = a1
		t.Lifetime = 0.3
		t.Color = ColorSequence.new(Color3.fromRGB(255, 200, 0))
		
		local hasHit = false
		coin.Touched:Connect(function(hit)
			if hasHit then return end
			if hit:IsDescendantOf(Char) then return end
			if hit.Name == "CoinHitbox" or hit.Name == "Coin" or hit.Name == "Beam" or hit.Name == "BeamHolder" then return end
			
			hasHit = true
			coin:SetAttribute("Expired", true)
			
			pcall(function() coin:SetNetworkOwner(nil) end)
			
			coin.Color = Color3.fromRGB(100, 80, 0)
			coin.Material = Enum.Material.Metal
			t.Enabled = false
			
			coin.AssemblyLinearVelocity = Vector3.zero
			coin.AssemblyAngularVelocity = Vector3.zero
			coin.CustomPhysicalProperties = DEAD_COIN_PHYSICS
			
			Debris:AddItem(coin, 3)
		end)
		
		coin.Parent = workspace
		pcall(function() coin:SetNetworkOwner(Player) end)
		
		Debris:AddItem(coin, 8)
		
		local s = Instance.new("Sound", coin)
		s.SoundId = "rbxassetid://132596270805754"
		s.PlaybackSpeed = 0.9 + (math.random() * 0.2)
		s.Volume = 0.5
		s:Play()
	end
end)