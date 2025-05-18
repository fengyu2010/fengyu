local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

_G.ESP_ENABLED = true
_G.SKELETON_ENABLED = true

local espConnections = {}

local function createLine(color)
    local line = Drawing.new("Line")
    line.Visible = true
    line.Color = color
    line.Thickness = 2
    line.Transparency = 1
    return line
end

local function getBonePairs(character)
    local parts = {
        ["Head"] = character:FindFirstChild("Head"),
        ["Torso"] = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"),
        ["Left Arm"] = character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm"),
        ["Right Arm"] = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm"),
        ["Left Leg"] = character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg"),
        ["Right Leg"] = character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg"),
    }

    local bones = {
        {parts["Head"], parts["Torso"]},
        {parts["Torso"], parts["Left Arm"]},
        {parts["Torso"], parts["Right Arm"]},
        {parts["Torso"], parts["Left Leg"]},
        {parts["Torso"], parts["Right Leg"]},
    }

    local validPairs = {}
    for _, pair in ipairs(bones) do
        if pair[1] and pair[2] then
            table.insert(validPairs, pair)
        end
    end
    return validPairs
end

local function cleanupESP(player)
    local record = espConnections[player]
    if record then
        if record.lines then
            for _, line in ipairs(record.lines) do
                if line then line:Remove() end
            end
        end
        if record.billboard and record.billboard.Parent then
            record.billboard:Destroy()
        end
        if record.conn then
            record.conn:Disconnect()
        end
        espConnections[player] = nil
    end
end

local function createESP(player)
    if player == LocalPlayer then return end
    cleanupESP(player)

    local lines = {}
    local billboard
    local function renderESP()
        if not _G.ESP_ENABLED then
            if billboard then
                billboard:Destroy()
                billboard = nil
            end
            for _, line in ipairs(lines) do
                line.Visible = false
            end
            return
        end

        local character = player.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end
        local head = character:FindFirstChild("Head")
        if not head then return end

        -- 创建或更新 Billboard GUI
        if not billboard then
            billboard = Instance.new("BillboardGui", head)
            billboard.Name = "ESP"
            billboard.Size = UDim2.new(0, 80, 0, 20)
            billboard.StudsOffset = Vector3.new(0, 2.8, 0)
            billboard.AlwaysOnTop = true

            local nameLabel = Instance.new("TextLabel", billboard)
            nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = player.Name
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextStrokeTransparency = 0.5
            nameLabel.TextScaled = true
            nameLabel.Font = Enum.Font.Gotham

            local barBack = Instance.new("Frame", billboard)
            barBack.Position = UDim2.new(0, 0, 0.5, 0)
            barBack.Size = UDim2.new(1, 0, 0.3, 0)
            barBack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            barBack.BorderSizePixel = 0

            local barFront = Instance.new("Frame", barBack)
            barFront.Name = "HealthBar"
            barFront.Size = UDim2.new(1, 0, 1, 0)
            barFront.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
            barFront.BorderSizePixel = 0

            coroutine.wrap(function()
                while humanoid and humanoid.Health > 0 and _G.ESP_ENABLED and billboard and billboard.Parent do
                    local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                    barFront.Size = UDim2.new(ratio, 0, 1, 0)
                    wait(0.2)
                end
            end)()
        end

        -- 骨骼绘制
        local bonePairs = getBonePairs(character)
        while #lines < #bonePairs do
            table.insert(lines, createLine(Color3.fromRGB(0, 255, 0))) -- 绿色
        end
        for i, pair in ipairs(bonePairs) do
            local p1, onScreen1 = Camera:WorldToViewportPoint(pair[1].Position)
            local p2, onScreen2 = Camera:WorldToViewportPoint(pair[2].Position)
            local line = lines[i]
            line.Visible = _G.SKELETON_ENABLED and onScreen1 and onScreen2
            if line.Visible then
                line.From = Vector2.new(p1.X, p1.Y)
                line.To = Vector2.new(p2.X, p2.Y)
            end
        end
        for i = #bonePairs + 1, #lines do
            lines[i].Visible = false
        end
    end

    local conn = RunService.RenderStepped:Connect(function()
        if not player or not player.Character then
            cleanupESP(player)
            return
        end
        renderESP()
    end)

    espConnections[player] = {
        conn = conn,
        lines = lines,
        billboard = billboard
    }
end

-- 玩家初始化
local function onPlayer(player)
    player.CharacterAdded:Connect(function()
        wait(0.5)
        if _G.ESP_ENABLED then
            createESP(player)
        end
    end)
    if player.Character then
        createESP(player)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        onPlayer(player)
    end
end

Players.PlayerAdded:Connect(onPlayer)

-- UI 控制按钮
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

    for _, player in ipairs(Players:GetPlayers()) do
        cleanupESP(player)
        if _G.ESP_ENABLED then
            createESP(player)
        end
    end
end)
