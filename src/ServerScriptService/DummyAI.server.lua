local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

--// CONFIGURATION
local RESPAWN_TIME = 3
-- R6 Animations (If you are using R15, change these back to your R15 IDs!)
local SWING_ANIM = "rbxassetid://100344585400886" 
local BLOCK_ANIM = "rbxassetid://132425649556300" 

local function LoadAnim(Humanoid, Id)
	local Anim = Instance.new("Animation")
	Anim.AnimationId = Id
	local Track = Humanoid:WaitForChild("Animator"):LoadAnimation(Anim)
	return Track
end

--// AI LOGIC

local function SetupAttacker(Dummy)
	local Hum = Dummy:WaitForChild("Humanoid")
	local Tool = Dummy:FindFirstChild("NeonBlade")
	if not Tool then return end

	local SwingTrack = LoadAnim(Hum, SWING_ANIM)

	task.spawn(function()
		while Dummy and Hum.Health > 0 do
			local NPCEvent = Tool:WaitForChild("NPCCombat", 5)
			if NPCEvent then
				SwingTrack:Play()
				NPCEvent:Fire("Attack") 
			end
			task.wait(1.5) -- Attacks every 1.5 seconds
		end
	end)
end

local function SetupBlocker(Dummy)
	local Hum = Dummy:WaitForChild("Humanoid")
	local Tool = Dummy:FindFirstChild("NeonBlade")
	if not Tool then return end

	local BlockTrack = LoadAnim(Hum, BLOCK_ANIM)
	BlockTrack.Looped = true

	task.spawn(function()
		local NPCEvent = Tool:WaitForChild("NPCCombat", 5)
		if NPCEvent and Hum.Health > 0 then
			-- Start blocking
			NPCEvent:Fire("BlockStart")
			BlockTrack:Play()

			while Dummy and Hum.Health > 0 do
				-- If guard broken (HP 0), wait for regen then re-block
				if Tool:GetAttribute("BlockHP") == 0 then
					BlockTrack:Stop()
					task.wait(6) -- Wait for full regen (5s delay + 1s regen)
					NPCEvent:Fire("BlockStart")
					BlockTrack:Play()
				end
				task.wait(1)
			end
		end
	end)
end

local function SetupParryBot(Dummy)
	local Hum = Dummy:WaitForChild("Humanoid")
	local Tool = Dummy:FindFirstChild("NeonBlade")
	if not Tool then return end

	local BlockTrack = LoadAnim(Hum, BLOCK_ANIM)

	task.spawn(function()
		local NPCEvent = Tool:WaitForChild("NPCCombat", 5)

		-- Wait a moment for everything to load
		task.wait(1)

		while Dummy and Hum.Health > 0 do
			if NPCEvent then
				-- 1. Start Block (Open Parry Window)
				NPCEvent:Fire("BlockStart")
				BlockTrack:Play()

				-- 2. Hold for 0.2s (Perfect Parry Timing)
				task.wait(0.2) 

				-- 3. Release Block
				NPCEvent:Fire("BlockEnd")
				BlockTrack:Stop()

				-- 4. COOLDOWN WAIT (CRITICAL FIX)
				-- Server requires 1.0s wait. We wait 1.2s to be safe.
				task.wait(1.2) 
			end
		end
	end)
end

--// RESPAWN SYSTEM

local function InitializeDummy(Dummy)
	local Hum = Dummy:WaitForChild("Humanoid")
	local Backup = Dummy:Clone()

	Hum.Died:Connect(function()
		task.wait(RESPAWN_TIME)
		if Dummy then Dummy:Destroy() end

		local NewDummy = Backup:Clone()
		NewDummy.Parent = workspace.TrainingDummies
		InitializeDummy(NewDummy)
	end)

	if Dummy.Name == "Dummy_Attacker" then
		SetupAttacker(Dummy)
	elseif Dummy.Name == "Dummy_Blocker" then
		SetupBlocker(Dummy)
	elseif Dummy.Name == "Dummy_Parry" then
		SetupParryBot(Dummy)
	end
end

--// STARTUP
local Folder = workspace:WaitForChild("TrainingDummies")
for _, Dummy in pairs(Folder:GetChildren()) do
	InitializeDummy(Dummy)
end