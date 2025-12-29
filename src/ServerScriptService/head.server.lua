game:GetService("ReplicatedStorage").RemoteHead.OnServerEvent:Connect(function(plr, txt)
	char = plr.Character or plr.CharacterAdded:Wait()
	hum = char:WaitForChild("Humanoid")
	torso = char:FindFirstChild("Torso")
	if torso and torso:FindFirstChild("Neck") then
		torso:WaitForChild("Neck").C0 = txt
	end
	
	
end)