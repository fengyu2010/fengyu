-- 创建按钮（右上角）
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "ESPGui"

local toggleButton = Instance.new("TextButton", screenGui)
toggleButton.Size = UDim2.new(0, 100, 0, 40)
toggleButton.Position = UDim2.new(1, -110, 0, 10)
toggleButton.Text = "ESP: OFF"
toggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)

local espEnabled = false

-- 创建或删除ESP标签
local function updateESP()
	for _, otherPlayer in pairs(game.Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
			local head = otherPlayer.Character:FindFirstChild("Head")
			if head then
				local existingTag = head:FindFirstChild("ESPTag")
				if espEnabled and not existingTag then
					local billboard = Instance.new("BillboardGui", head)
					billboard.Name = "ESPTag"
					billboard.Size = UDim2.new(0, 100, 0, 20)
					billboard.Adornee = head
					billboard.AlwaysOnTop = true

					local label = Instance.new("TextLabel", billboard)
					label.Size = UDim2.new(1, 0, 1, 0)
					label.BackgroundTransparency = 1
					label.Text = "👀 ESP"
					label.TextColor3 = Color3.new(1, 0, 0)
					label.TextScaled = true
				elseif not espEnabled and existingTag then
					existingTag:Destroy()
				end
			end
		end
	end
end

-- 切换按钮
toggleButton.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	toggleButton.Text = espEnabled and "ESP: ON" or "ESP: OFF"
	updateESP()
end)

-- 实时更新 ESP 标签（新玩家加入或角色重生）
game.Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function()
		wait(1)
		updateESP()
	end)
end)

game.Players.PlayerRemoving:Connect(function()
	updateESP()
end)

-- 每隔几秒刷新一次防止掉帧
while true do
	wait(3)
	if espEnabled then
		updateESP()
	end
end