local character = script.Parent
local torso =  character:WaitForChild("Torso")


-- Get the local player
-- Get the local player
local player = game.Players.LocalPlayer

-- Function to continuously get camera orientation
root = character:WaitForChild("HumanoidRootPart")
run = game:GetService("RunService")
cam = workspace.CurrentCamera
neck = torso:WaitForChild("Neck")

y = neck.C0.Y
run.RenderStepped:Connect(function()
	local camdirec = root.CFrame:ToObjectSpace(cam.CFrame).LookVector
	if neck then
		neck.C0 = CFrame.new(0,y,0) * CFrame.Angles(0,math.rad(180),0) * CFrame.Angles(0,-camdirec.X,0) * CFrame.Angles(-camdirec.Y,0,0)
		neck.C0 = neck.C0 * CFrame.Angles(math.rad(-90),0,0)
		
		game:GetService("ReplicatedStorage").RemoteHead:FireServer(neck.C0)
	end
end)