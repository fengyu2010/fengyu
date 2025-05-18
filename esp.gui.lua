local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 用于控制是否启用 ESP
_G.ESP_ENABLED = true

local function createESP(player)
    if player == LocalPlayer or not _G.ESP_ENABLED then return end
    local character = player.Character or player.CharacterAdded:Wait()
    local head = character:WaitForChild("Head", 5)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not head or not humanoid then return end

    if head:FindFirstChild("ESP") then return end

    local billboard = Instance.new("BillboardGui", head)
    billboard.Name = "ESP"
    billboard.Size = UDim2.new(0, 80, 0, 20) -- 更小
    billboard.StudsOffset = Vector3.new(0, 2.8, 0)
    billboard.AlwaysOnTop = true

    -- 名称
    local nameLabel = Instance.new("TextLabel", billboard)
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.Gotham

    -- 血量条背景
    local barBack = Instance.new("Frame", billboard)
    barBack.Position = UDim2.new(0, 0, 0.5, 0)
    barBack.Size = UDim2.new(1, 0, 0.3, 0)
    barBack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    barBack.BorderSizePixel = 0

    -- 血量条前景
    local barFront = Instance.new("Frame", barBack)
    barFront.Size = UDim2.new(1, 0, 1, 0)
    barFront.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    barFront.BorderSizePixel = 0

    coroutine.wrap(function()
        while billboard and humanoid and humanoid.Health > 0 do
            local healthRatio = humanoid.Health / humanoid.MaxHealth
            barFront.Size = UDim2.new(math.clamp(healthRatio, 0, 1), 0, 1, 0)
            wait(0.2)
        end
    end)()
end

-- 初始应用
for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(1)
        createESP(player)
    end)
end)

-- 控制按钮(屏幕上的小UI)
local screenGui = Instance.new("ScreenGui", game.CoreGui)
screenGui.Name = "ESP_Toggle_GUI"

local toggle = Instance.new("TextButton", screenGui)
toggle.Size = UDim2.new(0, 100, 0, 40)
toggle.Position = UDim2.new(0, 10, 0, 120)
toggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
toggle.Text = "ESP: ON"
toggle.TextScaled = true
toggle.Font = Enum.Font.GothamBold

toggle.MouseButton1Click:Connect(function()
    _G.ESP_ENABLED = not _G.ESP_ENABLED
    toggle.Text = "ESP: " .. (_G.ESP_ENABLED and "ON" or "OFF")

    -- 清除或重新添加
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            if head:FindFirstChild("ESP") then
                head.ESP:Destroy()
            end
        end
        if _G.ESP_ENABLED then
            createESP(player)
        end
    end
end)
