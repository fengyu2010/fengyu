local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function createESP(player)
    if player == LocalPlayer then return end
    local character = player.Character or player.CharacterAdded:Wait()
    local head = character:WaitForChild("Head", 5)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not head or not humanoid then return end

    -- 防重复
    if head:FindFirstChild("ESP") then return end

    local billboard = Instance.new("BillboardGui", head)
    billboard.Name = "ESP"
    billboard.Size = UDim2.new(0, 100, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true

    -- 名称
    local nameLabel = Instance.new("TextLabel", billboard)
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamSemibold

    -- 血量
    local hpLabel = Instance.new("TextLabel", billboard)
    hpLabel.Size = UDim2.new(1, 0, 0.5, 0)
    hpLabel.Position = UDim2.new(0, 0, 0.5, 0)
    hpLabel.BackgroundTransparency = 1
    hpLabel.TextColor3 = Color3.fromRGB(255, 105, 105)
    hpLabel.TextScaled = true
    hpLabel.Font = Enum.Font.Gotham

    -- 实时更新血量
    coroutine.wrap(function()
        while billboard and humanoid and humanoid.Health > 0 do
            hpLabel.Text = "HP: " .. math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
            wait(0.2)
        end
    end)()
end

-- 对所有现有玩家应用
for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end

-- 监听新玩家
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(1)
        createESP(player)
    end)
end)
