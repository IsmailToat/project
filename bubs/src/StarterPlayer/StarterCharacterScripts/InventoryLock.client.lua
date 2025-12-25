local StarterGui = game:GetService("StarterGui")

-- Disable the Backpack (Hotbar) completely
-- This effectively locks the tool in your hand once equipped
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)