local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folderName = "WeaponEvents"
local folder = ReplicatedStorage:FindFirstChild(folderName)

if not folder then
	folder = Instance.new("Folder")
	folder.Name = folderName
	folder.Parent = ReplicatedStorage
	print("✅ Created WeaponEvents Folder")
else
	print("✔ WeaponEvents Folder exists")
end

local function EnsureEvent(name)
	if not folder:FindFirstChild(name) then
		local re = Instance.new("RemoteEvent")
		re.Name = name
		re.Parent = folder
		print("✅ Created RemoteEvent: " .. name)
	else
		print("✔ RemoteEvent exists: " .. name)
	end
end

EnsureEvent("RevolverEvent")
EnsureEvent("ShotgunEvent")