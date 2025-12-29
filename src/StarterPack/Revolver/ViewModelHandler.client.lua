local Revolver = script.Parent.Name
local tool = script.Parent
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local Camera = workspace.CurrentCamera
local head = character:WaitForChild("Head")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Ensure these exist in ReplicatedStorage
local RevolverFolder = RS:WaitForChild(Revolver)
local ViewModelTP = RevolverFolder:WaitForChild("ViewTPModel")
local ViewModelFP = RevolverFolder:WaitForChild("ViewModel")

local ViewModelTPS
local equipped = false

local swayAmount = 0.6
local swayCF = CFrame.new()
local lastCameraCFrame = Camera.CFrame -- Initialize with current camera

local function isFirstPerson()
	if head.LocalTransparencyModifier == 1 or (head.CFrame.Position - Camera.CFrame.Position).Magnitude < 1 then
		return true
	else
		return false
	end
end

local function createFPVModel()
	-- Only create if it doesn't exist
	if not Camera:FindFirstChild("ViewModel" .. Revolver) then
		local viewModel = ViewModelFP:Clone()
		viewModel.Name = "ViewModel" .. Revolver
		viewModel.Parent = Camera
	end
end

local function CreateTPLocal()
	if not ViewModelTPS and equipped then
		ViewModelTPS = ViewModelTP:Clone()
		ViewModelTPS.Name = "ViewModelTPS(Local)" .. Revolver 
		ViewModelTPS.Parent = player.Character
	end
end

local function destroyFPViewModel_createTPSviewModel()
	local fpModel = Camera:FindFirstChild("ViewModel".. Revolver)
	if fpModel then
		fpModel:Destroy()
	end

	CreateTPLocal()
end

tool.Equipped:Connect(function()
	character = player.Character -- Update character in case of respawn
	head = character:WaitForChild("Head")
	lastCameraCFrame = Camera.CFrame -- Reset sway reference
	equipped = true
end)

tool.Unequipped:Connect(function()
	equipped = false

	local fpModel = Camera:FindFirstChild("ViewModel" .. Revolver)
	if fpModel then
		fpModel:Destroy()
	end

	local tpModel = player.Character:FindFirstChild("ViewModelTPS(Local)" .. Revolver)
	if tpModel then
		ViewModelTPS = nil
		tpModel:Destroy()
	end
end)

RunService.RenderStepped:Connect(function()
	-- Safety check
	if not player.Character or not player.Character:FindFirstChild("Humanoid") then return end

	if player.Character.Humanoid.Health <= 0 then
		equipped = false
		return
	end

	if not equipped then return end

	if isFirstPerson() then
		local FPViewModel = Camera:FindFirstChild("ViewModel" .. Revolver)
		local TPSViewModel = player.Character:FindFirstChild("ViewModelTPS(Local)" .. Revolver)

		-- Destroy TPV model if we are now in First Person
		if TPSViewModel then
			ViewModelTPS = nil
			TPSViewModel:Destroy()
		end

		if not FPViewModel then
			createFPVModel()
			FPViewModel = Camera:FindFirstChild("ViewModel" .. Revolver) -- Get reference immediately
		end

		if FPViewModel and FPViewModel.PrimaryPart then
			-- SWAY CALCULATION
			local rot = Camera.CFrame:ToObjectSpace(lastCameraCFrame)
			local X, Y, Z = rot:ToEulerAnglesXYZ()

			-- NOTE: Removed 'local' to update the global variable correctly
			swayCF = swayCF:Lerp(CFrame.Angles(math.sin(X) * swayAmount, math.sin(Y) * swayAmount, 0), 0.1)

			lastCameraCFrame = Camera.CFrame

			-- Using PivotTo is safer than SetPrimaryPartCFrame
			FPViewModel:PivotTo(Camera.CFrame * swayCF)
		end
	else 
		-- THIRD PERSON LOGIC
		destroyFPViewModel_createTPSviewModel()

		if player.Character and ViewModelTPS then
			-- NOTE: Currently pivots to Head. Change "Head" to "RightHand" if you want it in the hand.
			if player.Character:FindFirstChild("Head") then
				ViewModelTPS:PivotTo(player.Character.Head.CFrame)
			end
		end
	end
end)