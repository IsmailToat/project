local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()

--// CONFIGURATION
local Settings = {
	PerfectThreshold = 50, -- Must match your RollSystem settings
	ValidThreshold = 200,  -- Must match your RollSystem settings

	-- Colors
	ColorPerfect = Color3.fromRGB(0, 255, 255), -- Cyan (Digital/Tech look)
	ColorGood = Color3.fromRGB(255, 170, 0),    -- Orange
	ColorBad = Color3.fromRGB(200, 50, 50),     -- Red
}

--// GUI SETUP
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RollFeedbackUI"
ScreenGui.Parent = Player:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local Label = Instance.new("TextLabel")
Label.Name = "TimingLabel"
Label.Size = UDim2.new(0, 100, 0, 30)
Label.Position = UDim2.new(0.5, 0, 0.75, 0) -- Positioned lower-middle
Label.AnchorPoint = Vector2.new(0.5, 0.5)
Label.BackgroundTransparency = 1
Label.Font = Enum.Font.Code -- The "Digital" look
Label.Text = ""
Label.TextSize = 22
Label.TextStrokeTransparency = 0.8
Label.TextTransparency = 1 -- Invisible start
Label.Parent = ScreenGui

--// FEEDBACK FUNCTION
local function ShowFeedback()
	local Timing = Char:GetAttribute("RollTiming")
	if not Timing then return end

	local Ms = math.floor(Timing)

	-- 1. Set Text
	Label.Text = Ms .. " ms"

	-- 2. Set Color based on timing
	if Ms <= Settings.PerfectThreshold then
		Label.TextColor3 = Settings.ColorPerfect
		Label.TextStrokeColor3 = Settings.ColorPerfect
	elseif Ms <= Settings.ValidThreshold then
		Label.TextColor3 = Settings.ColorGood
		Label.TextStrokeColor3 = Settings.ColorGood
	else
		Label.TextColor3 = Settings.ColorBad
		Label.TextStrokeColor3 = Settings.ColorBad
	end

	-- 3. Animation (Pop up and fade)
	-- Reset state
	Label.TextTransparency = 0
	Label.Position = UDim2.new(0.5, 0, 0.75, 0)
	Label.Rotation = math.random(-5, 5) -- Tiny tilt for style

	-- Tween: Move up slightly and fade out
	local TweenInfoIn = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local TweenInfoOut = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	-- Pop size
	local Pop = TweenService:Create(Label, TweenInfoIn, {
		TextSize = 26, 
		Rotation = 0
	})

	-- Fade out
	local Fade = TweenService:Create(Label, TweenInfoOut, {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.70, 0), -- Floats up
		TextSize = 15
	})

	Pop:Play()
	Pop.Completed:Connect(function()
		Fade:Play()
	end)
end

--// LISTENER
-- This waits for the "RollTiming" attribute to change (set by your RollSystem script)
Char:GetAttributeChangedSignal("RollTiming"):Connect(ShowFeedback)