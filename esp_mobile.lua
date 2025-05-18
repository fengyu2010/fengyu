local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- 创建ESP函数
local function createESP(player)
    if player == LocalPlayer then return end
    local char = player.Character or player.CharacterAdded:Wait()
    local head = char:WaitForChild("Head", 5)
    if not head then return end

    -- 防止重复添加
    if head:FindFirstChild("ESP") then return end

    local billboard = Instance.new("BillboardGui", head)
    billboard.Name = "ESP"
    billboard.Size = UDim2.new(0, 100, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true

    local textLabel = Instance.new("TextLabel", billboard)
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "👀 ESP"
    textLabel.TextColor3 = Color3.fromRGB(255, 105, 180) -- 粉色
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
end

-- 为所有当前玩家添加
for _, player in pairs(Players:GetPlayers()) do
    createESP(player)
end

-- 监听新玩家加入
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(1)
        createESP(player)
    end)
end)
