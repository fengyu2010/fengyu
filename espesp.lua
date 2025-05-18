local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

_G.ESP_ENABLED = true
_G.SKELETON_ENABLED = true

local espData = {}

local function createLine(color)
    local line = Drawing.new("Line")
    line.Color = color
    line.Thickness = 2
    line.Transparency = 1
    line.Visible = true
    return line
end

local function getBonePairs(character)
    local parts = {
        Head = character:FindFirstChild("Head"),
        Root = character:FindFirstChild("HumanoidRootPart"),
        LeftArm = character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm"),
        RightArm = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm"),
        LeftLeg = character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg"),
        RightLeg = character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg")
    }

    local bones = {
        {parts.Head, parts.Root},
        {parts.Root, parts.LeftArm},
        {parts.Root, parts.RightArm},
        {parts.Root, parts.LeftLeg},
        {parts.Root, parts.RightLeg}
    }

    local valid = {}
    for _, pair in ipairs(bones) do
        if pair[1] and pair[2] then
            table.insert(valid, pair)
        end
    end
    return valid
end

local function removeESP(player)
    local record = espData[player]
    if record then
        if record.conn then record.conn:Disconnect() end
        if record.lines then
            for _, line in ipairs(record.lines) do
                if line then line:Remove() end
            end
        end
        if record.billboard and record.billboard.Parent then
            record.billboard:Destroy()
        end
        espData[player] = nil
    end
end

local function createESP(player)
    if player == LocalPlayer then return end
    removeESP(player)

    local lines = {}
    local billboard = nil

    local conn = RunService.RenderStepped:Connect(function()
        if not _G.ESP_ENABLED then
            removeESP(player)
            return
        end

        local character = player.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end
        local head = character:FindFirstChild("Head")
        if not head then return end

        -- Billboard 显示名称和血量
        if not billboard or not billboard.Parent then
            billboard = Instance.new("BillboardGui")
            billboard.Name = "ESP"
            billboard.Size = UDim2.new(0, 60, 0, 14)
            billboard.StudsOffset = Vector3.new(0, 3.2, 0)
            billboard.AlwaysOnTop = true
            billboard.Parent = head

            local nameLabel = Instance.new("TextLabel", billboard)
            nameLabel.Name = "Name"
            nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = player.Name
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextStrokeTransparency = 0.5
            nameLabel.TextScaled = true
            nameLabel.Font = Enum.Font.Gotham

            local barBack = Instance.new("Frame", billboard)
            barBack.Name = "BarBack"
            barBack.Position = UDim2.new(0, 0, 0.5, 0)
            barBack.Size = UDim2.new(1, 0, 0.5, 0)
            barBack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            barBack.BorderSizePixel = 0

            local barFront = Instance.new("Frame", barBack)
            barFront.Name = "BarFront"
            barFront.Size = UDim2.new(1, 0, 1, 0)
            barFront.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            barFront.BorderSizePixel = 0

            coroutine.wrap(function()
                while billboard and humanoid and humanoid.Health > 0 and _G.ESP_ENABLED do
                    local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                    barFront.Size = UDim2.new(ratio, 0, 1, 0)
                    wait(0.2)
                end
            end)()
        end

        -- 骨骼绘制
        local bonePairs = getBonePairs(character)
        while #lines < #bonePairs do
            table.insert(lines, createLine(Color3.fromRGB(0, 255, 0)))
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
    end)

    espData[player] = {
        conn = conn,
        lines = lines,
        billboard = billboard
    }
end

-- 玩家加入处理
local function setupPlayer(player)
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
        setupPlayer(player)
    end
end

Players.PlayerAdded:Connect(setupPlayer)

-- 控制按钮
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "ESP_Control"

local button = Instance.new("TextButton", gui)
button.Size = UDim2.new(0, 100, 0, 40)
button.Position = UDim2.new(0, 10, 0, 120)
button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.TextScaled = true
button.Font = Enum.Font.GothamBold
button.Text = "ESP: ON"

button.MouseButton1Click:Connect(function()
    _G.ESP_ENABLED = not _G.ESP_ENABLED
    button.Text = "ESP: " .. (_G.ESP_ENABLED and "ON" or "OFF")

    for _, player in ipairs(Players:GetPlayers()) do
        removeESP(player)
        if _G.ESP_ENABLED then
            createESP(player)
        end
    end
end)
