local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- // CONFIGURATION //
local BLUR_SIZE = 15          -- How blurry the screen gets
local SATURATION = -1         -- -1 is Black & White, 0 is Normal
local FADE_TIME = 2.0         -- How long the fade takes

-- // SETUP EFFECTS //
-- We create these once and keep them disabled until death
local blur = Instance.new("BlurEffect")
blur.Name = "DeathBlur"
blur.Size = 0
blur.Enabled = false
blur.Parent = Lighting

local colorCorr = Instance.new("ColorCorrectionEffect")
colorCorr.Name = "DeathColor"
colorCorr.Saturation = 0
colorCorr.Enabled = false
colorCorr.Parent = Lighting

local function ResetEffects()
	blur.Enabled = false
	blur.Size = 0
	colorCorr.Enabled = false
	colorCorr.Saturation = 0
	
	-- Reset Camera
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		camera.CameraSubject = player.Character.Humanoid
		camera.CameraType = Enum.CameraType.Custom
	end
end

local function OnDied()
	-- 1. ENABLE EFFECTS
	blur.Enabled = true
	colorCorr.Enabled = true
	
	-- 2. TWEEN TO GRAY/BLURRY
	local info = TweenInfo.new(FADE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	TweenService:Create(blur, info, {Size = BLUR_SIZE}):Play()
	TweenService:Create(colorCorr, info, {Saturation = SATURATION}):Play()
	
	-- 3. LOCK CAMERA TO RAGDOLL
	-- The server creates a model named "PlayerName_Ragdoll"
	local ragdollName = player.Name .. "_Ragdoll"
	
	-- We wait a moment for the server script to spawn the ragdoll
	local ragdoll = Workspace:WaitForChild(ragdollName, 3)
	
	if ragdoll then
		local head = ragdoll:FindFirstChild("Head")
		if head then
			-- Smoothly pan camera to the dead body
			camera.CameraSubject = head
		end
	end
end

local function OnCharacterAdded(char)
	-- Reset everything when we spawn
	ResetEffects()
	
	local hum = char:WaitForChild("Humanoid")
	hum.Died:Connect(OnDied)
end

-- // INIT //
if player.Character then
	OnCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(OnCharacterAdded)