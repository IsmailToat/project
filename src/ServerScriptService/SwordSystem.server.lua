local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

--// CONFIGURATION
local SwordSettings = {
	Damage = 25,
	Cooldown = 0.4,
	BladeColor = Color3.fromRGB(0, 255, 255), -- Cyan Neon
	BladeSize = Vector3.new(0.3, 0.3, 3.5),
}

--// ANIMATION IDS (Standard R15 Animations)
local ANIM_IDLE = "rbxassetid://100720612999711" -- Generic hold
local ANIM_SWING = "rbxassetid://101375731776939" -- Generic slash

--// FUNCTIONS

local function CreateSword()
	local Tool = Instance.new("Tool")
	Tool.Name = "NeonBlade"
	Tool.CanBeDropped = false
	Tool.RequiresHandle = true

	-- 1. Create Handle
	local Handle = Instance.new("Part")
	Handle.Name = "Handle"
	Handle.Size = Vector3.new(0.4, 0.4, 1)
	Handle.Color = Color3.fromRGB(50, 50, 50)
	Handle.Material = Enum.Material.Metal
	Handle.Parent = Tool

	-- 2. Create Blade (Visual)
	local Blade = Instance.new("Part")
	Blade.Name = "Blade"
	Blade.Size = SwordSettings.BladeSize
	Blade.Color = SwordSettings.BladeColor
	Blade.Material = Enum.Material.Neon
	Blade.CanCollide = false
	Blade.Massless = true
	Blade.Parent = Tool

	-- Weld Blade to Handle
	local Weld = Instance.new("ManualWeld")
	Weld.Part0 = Handle
	Weld.Part1 = Blade
	Weld.C0 = CFrame.new(0, 0, -1.8) -- Position blade forward
	Weld.Parent = Handle

	-- 3. Add Audio
	local SoundSlash = Instance.new("Sound")
	SoundSlash.Name = "SlashSound"
	SoundSlash.SoundId = "rbxassetid://6000293026" -- Swoosh sound
	SoundSlash.Volume = 0.5
	SoundSlash.Parent = Handle

	local SoundHit = Instance.new("Sound")
	SoundHit.Name = "HitSound"
	SoundHit.SoundId = "rbxassetid://566593606" -- Hit sound
	SoundHit.Volume = 0.6
	SoundHit.Parent = Handle

	--// CLIENT SCRIPT (Input & Animation)
	local LocalScript = Instance.new("LocalScript")
	LocalScript.Name = "SwordClient"
	LocalScript.Source = [[
		local Players = game:GetService("Players")
		local Tool = script.Parent
		local Handle = Tool:WaitForChild("Handle")
		local Char = Players.LocalPlayer.Character
		local Animator = Char:WaitForChild("Humanoid"):WaitForChild("Animator")
		
		local SwingAnim = Instance.new("Animation")
		SwingAnim.AnimationId = "]]..ANIM_SWING..[["
		local TrackSwing = Animator:LoadAnimation(SwingAnim)
		
		local Debounce = false
		
		Tool.Activated:Connect(function()
			if Debounce then return end
			Debounce = true
			
			-- Play Animation
			TrackSwing:Play()
			Handle.SlashSound:Play()
			
			-- Tell Server to Hit
			Tool.HitEvent:FireServer()
			
			task.wait(]]..SwordSettings.Cooldown..[[)
			Debounce = false
		end)
	]]
	LocalScript.Parent = Tool

	--// SERVER LOGIC (Damage)
	local Remote = Instance.new("RemoteEvent")
	Remote.Name = "HitEvent"
	Remote.Parent = Tool

	Remote.OnServerEvent:Connect(function(Player)
		-- Hitbox Logic (Get parts in front of player)
		local Char = Player.Character
		if not Char then return end
		local Root = Char:FindFirstChild("HumanoidRootPart")

		-- Create a hitbox region in front of player
		local HitboxSize = Vector3.new(5, 5, 5)
		local HitboxCFrame = Root.CFrame * CFrame.new(0, 0, -3)

		local Params = OverlapParams.new()
		Params.FilterDescendantsInstances = {Char}
		Params.FilterType = Enum.RaycastFilterType.Exclude

		local Parts = workspace:GetPartBoundsInBox(HitboxCFrame, HitboxSize, Params)
		local HitHumanoids = {} -- Prevent hitting same guy twice

		for _, Part in pairs(Parts) do
			local EnemyChar = Part.Parent
			local Hum = EnemyChar:FindFirstChild("Humanoid")

			if Hum and Hum.Health > 0 and not HitHumanoids[Hum] then
				HitHumanoids[Hum] = true

				-- Deal Damage
				Hum:TakeDamage(]]..SwordSettings.Damage..[[)
				
				-- Play Hit Sound
				Handle.HitSound:Play()
				
				-- Optional: Add a visual hit effect here
			end
		end
	end)

	return Tool
end

--// SPAWN HANDLER

Players.PlayerAdded:Connect(function(Player)
	Player.CharacterAdded:Connect(function(Char)
		-- 1. Create the Sword
		local Sword = CreateSword()
		
		-- 2. Force Equip (Parent to Character, NOT Backpack)
		-- Using a small delay ensures the character is fully ready
		task.defer(function()
			Sword.Parent = Char
		end)
		
		-- 3. Prevent Unequipping
		-- If the game somehow unequips it (e.g. glitch), put it back instantly
		Sword.Unequipped:Connect(function()
			task.wait() -- Wait one frame
			if Char and Char:FindFirstChild("Humanoid") and Char.Humanoid.Health > 0 then
				Sword.Parent = Char
			end
		end)
	end)
end)