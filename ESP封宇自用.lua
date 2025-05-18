local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

_G.ESP_ENABLED = true
_G.SKELETON_ENABLED = true

local espConnections = {}  -- 存储每个玩家的监听和线条

local function createLine(color)
    local line = Drawing.new("Line")
    line.Visible = true
    line.Color = color
    line.Thickness = 2
    line.Transparency = 1
    return line
end

local function getBonePairs(character)
    local bones = {
        { "Head", "Torso" },
        { "Torso", "Left Arm" },
        { "Torso", "Right Arm" },
        { "Torso", "Left Leg" },
        { "Torso", "Right Leg" }
    }

    local parts = {
        ["Head"] = character:FindFirstChild("Head"),
        ["Torso"] = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"),
        ["Left Arm"] = character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm"),
        ["Right Arm"] = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm"),
        ["Left Leg"] = character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg"),
        ["Right Leg"] = character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg"),
    }

    local out = {}
    for _, pair in ipairs(bones) do
        local p1 = parts[pair[1]]
        local p2 = parts[pair[2]]
        if p1 and p2 then
            table.insert(out, {p1, p2})
        end
    end
    return out
end

local function cleanupESP(player)
    if espConnections[player] then
        for _, obj in ipairs(espConnections[player].lines or {}) do
            if obj then obj:Remove() end
        end
        if espConnections[player].billboard and espConnections[player].billboard.Parent then
            espConnections[player].billboard:Destroy()
        end
        if espConnections[player].conn then
            espConnections[player].conn:Disconnect()
        end
        espConnections[player] = nil
    end
end

local function createESP(player)
    if player == LocalPlayer or not _G.ESP_ENABLED then return end
    cleanupESP(player)

    local lines = {}
    local billboard

    local function renderESP()
        local character = player.Character
        if not character then return end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local head = character:FindFirstChild("Head")
        if not humanoid or not head then return end

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
            barFront.Size = UDim2.new(1, 0, 1, 0)
            barFront.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
            barFront.BorderSizePixel = 0

            -- 更新血条
            coroutine.wrap(function()
                while humanoid and humanoid.Health > 0 and billboard.Parent do
                    local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                    barFront.Size = UDim2.new(ratio, 0, 1, 0)
                    wait(0.2)
                end
            end)()
        end

        if _G.SKELETON_ENABLED then
            local bones = getBonePairs(character)
            while #lines < #bones do
                table.insert(lines, createLine(Color3.fromRGB(255, 255, 0)))
            end
            for i, pair in ipairs(bones) do
                local pos1, vis1 = Camera:WorldToViewportPoint(pair[1].Position)
                local pos2, vis2 = Camera:WorldToViewportPoint(pair[2].Position)
                local line = lines[i]
                line.Visible = vis1 and vis2
                if vis1 and vis2 then
                    line.From = Vector2.new(pos1.X, pos1.Y)
                    line.To = Vector2.new(pos2.X, pos2.Y)
                end
            end
            for i = #bones + 1, #lines do
                lines[i].Visible = false
            end
        end
    end

    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not _G.ESP_ENABLED or not player.Character then
            cleanupESP(player)
            if conn then conn:Disconnect() end
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

-- 初始化所有玩家
for _, player in ipairs(Players:GetPlayers()) do
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

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(0.5)
        if _G.ESP_ENABLED then
            createESP(player)
        end
    end)
end)

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
