local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

_G.ESP_ENABLED = true
_G.SKELETON_ENABLED = true
_G.ANTENNA_ENABLED = true

-- 储存所有ESP对象
local espObjects = {}

-- 创建2D线段
local function createLine(color)
    local line = Drawing.new("Line")
    line.Visible = true
    line.Color = color
    line.Thickness = 2
    line.Transparency = 1
    return line
end

-- 获取角色骨骼连接点
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

    local pairsOut = {}
    for _, pair in ipairs(bones) do
        local p1 = parts[pair[1]]
        local p2 = parts[pair[2]]
        if p1 and p2 then
            table.insert(pairsOut, {p1, p2})
        end
    end
    return pairsOut
end

-- 创建ESP显示
local function createESP(player)
    if player == LocalPlayer or not _G.ESP_ENABLED then return end
    local character = player.Character or player.CharacterAdded:Wait()
    local head = character:WaitForChild("Head", 5)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not head or not humanoid then return end
    if head:FindFirstChild("ESP") then return end

    -- Billboard GUI
    local billboard = Instance.new("BillboardGui", head)
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

    local skeletonLines = {}
    local antennaLine = _G.ANTENNA_ENABLED and createLine(Color3.fromRGB(0, 255, 0)) or nil

    local function cleanup()
        if antennaLine then antennaLine:Remove() end
        for _, l in ipairs(skeletonLines) do
            l:Remove()
        end
    end

    coroutine.wrap(function()
        while _G.ESP_ENABLED and character and humanoid and humanoid.Health > 0 do
            -- 更新血量
            local healthRatio = humanoid.Health / humanoid.MaxHealth
            barFront.Size = UDim2.new(math.clamp(healthRatio, 0, 1), 0, 1, 0)

            if _G.SKELETON_ENABLED then
                local bonePairs = getBonePairs(character)
                while #skeletonLines < #bonePairs do
                    table.insert(skeletonLines, createLine(Color3.fromRGB(255, 255, 0)))
                end
                for i, pair in ipairs(bonePairs) do
                    local pos1, visible1 = Camera:WorldToViewportPoint(pair[1].Position)
                    local pos2, visible2 = Camera:WorldToViewportPoint(pair[2].Position)
                    local line = skeletonLines[i]
                    line.Visible = visible1 and visible2
                    if visible1 and visible2 then
                        line.From = Vector2.new(pos1.X, pos1.Y)
                        line.To = Vector2.new(pos2.X, pos2.Y)
                    end
                end
            end

            if _G.ANTENNA_ENABLED and antennaLine and head then
                local headPos, vis = Camera:WorldToViewportPoint(head.Position)
                antennaLine.Visible = vis
                if vis then
                    antennaLine.From = Vector2.new(headPos.X, headPos.Y)
                    antennaLine.To = Vector2.new(headPos.X, 0)
                end
            end

            RunService.RenderStepped:Wait()
        end
        cleanup()
    end)()
end

-- 处理所有玩家
for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(1)
        createESP(player)
    end)
end)

-- GUI切换按钮
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
