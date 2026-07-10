-- ========================================
-- ESP ДЛЯ ПОИСКА МАЛЕНЬКИХ ИГРОКОВ
-- ========================================

local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ========================================
-- СОЗДАЕМ GUI
-- ========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player.PlayerGui
screenGui.ResetOnSpawn = false

-- ========================================
-- КНОПКА ВКЛ/ВЫКЛ
-- ========================================
local espBtn = Instance.new("TextButton")
espBtn.Size = UDim2.new(0, 60, 0, 60)
espBtn.Position = UDim2.new(1, -75, 0, 10)
espBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
espBtn.Text = "POISK\nВКЛ"
espBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
espBtn.TextScaled = true
espBtn.Font = Enum.Font.GothamBold
espBtn.Parent = screenGui

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(1, 0)
btnCorner.Parent = espBtn

-- ========================================
-- НАСТРОЙКИ
-- ========================================
local espEnabled = true
local MAX_NORMAL_HEIGHT = 5.0  -- Максимальный рост "нормального" игрока
local espData = {}

-- ========================================
-- ПРОВЕРКА РОСТА
-- ========================================
local function getPlayerHeight(plr)
    if not plr or not plr.Character then return 0 end
    
    local root = plr.Character:FindFirstChild("HumanoidRootPart")
    local head = plr.Character:FindFirstChild("Head")
    if not root or not head then return 0 end
    
    -- Вычисляем рост (расстояние от ног до головы)
    local rootPos = root.Position
    local headPos = head.Position
    local height = math.abs(headPos.Y - rootPos.Y)
    
    return height
end

-- ========================================
-- СОЗДАНИЕ ОБВОДКИ
-- ========================================
local function createOutline()
    local lines = {}
    
    for i = 1, 4 do
        local line = Instance.new("Frame")
        line.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        line.BackgroundTransparency = 0.1
        line.BorderSizePixel = 1
        line.BorderColor3 = Color3.fromRGB(255, 255, 255)
        line.Parent = screenGui
        line.ZIndex = 999
        line.Visible = false
        table.insert(lines, line)
    end
    
    -- Имя и рост
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(0, 200, 0, 40)
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    infoLabel.TextScaled = true
    infoLabel.Font = Enum.Font.GothamBold
    infoLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    infoLabel.TextStrokeTransparency = 0.3
    infoLabel.Parent = screenGui
    infoLabel.ZIndex = 999
    infoLabel.Visible = false
    
    return lines, infoLabel
end

-- ========================================
-- ОБНОВЛЕНИЕ ESP
-- ========================================
local function updateESP()
    for plr, data in pairs(espData) do
        if not plr or not plr.Character then
            for _, line in pairs(data.lines) do
                line.Visible = false
            end
            data.info.Visible = false
            continue
        end
        
        local root = plr.Character:FindFirstChild("HumanoidRootPart")
        local head = plr.Character:FindFirstChild("Head")
        if not root or not head then
            for _, line in pairs(data.lines) do
                line.Visible = false
            end
            data.info.Visible = false
            continue
        end
        
        local hum = plr.Character:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then
            for _, line in pairs(data.lines) do
                line.Visible = false
            end
            data.info.Visible = false
            continue
        end
        
        -- Проверяем рост
        local height = getPlayerHeight(plr)
        local isSmall = height < MAX_NORMAL_HEIGHT
        
        -- Если игрок нормального роста - пропускаем
        if not isSmall then
            for _, line in pairs(data.lines) do
                line.Visible = false
            end
            data.info.Visible = false
            continue
        end
        
        -- Получаем позиции на экране
        local rootPos, onScreen = camera:WorldToViewportPoint(root.Position)
        local headPos = camera:WorldToViewportPoint(head.Position)
        
        if not onScreen then
            for _, line in pairs(data.lines) do
                line.Visible = false
            end
            data.info.Visible = false
            continue
        end
        
        -- Размер контура
        local boxHeight = math.abs(headPos.Y - rootPos.Y) + 30
        local boxWidth = boxHeight * 0.55
        
        if boxHeight < 25 then boxHeight = 25 end
        if boxWidth < 15 then boxWidth = 15 end
        if boxHeight > 150 then boxHeight = 150 end
        if boxWidth > 90 then boxWidth = 90 end
        
        local centerX = rootPos.X
        local centerY = (headPos.Y + rootPos.Y) / 2
        
        -- Рисуем контур (красный - маленький)
        local color = Color3.fromRGB(255, 0, 0)
        
        data.lines[1].Size = UDim2.new(0, boxWidth, 0, 3)
        data.lines[1].Position = UDim2.new(0, centerX - boxWidth/2, 0, centerY - boxHeight/2)
        data.lines[1].BackgroundColor3 = color
        data.lines[1].Visible = true
        
        data.lines[2].Size = UDim2.new(0, boxWidth, 0, 3)
        data.lines[2].Position = UDim2.new(0, centerX - boxWidth/2, 0, centerY + boxHeight/2)
        data.lines[2].BackgroundColor3 = color
        data.lines[2].Visible = true
        
        data.lines[3].Size = UDim2.new(0, 3, 0, boxHeight)
        data.lines[3].Position = UDim2.new(0, centerX - boxWidth/2, 0, centerY - boxHeight/2)
        data.lines[3].BackgroundColor3 = color
        data.lines[3].Visible = true
        
        data.lines[4].Size = UDim2.new(0, 3, 0, boxHeight)
        data.lines[4].Position = UDim2.new(0, centerX + boxWidth/2, 0, centerY - boxHeight/2)
        data.lines[4].BackgroundColor3 = color
        data.lines[4].Visible = true
        
        -- Информация (имя + рост)
        data.info.Position = UDim2.new(0, centerX - 100, 0, headPos.Y - 45)
        data.info.Text = plr.Name .. " | Рост: " .. string.format("%.2f", height) .. " 🟢"
        data.info.TextColor3 = Color3.fromRGB(0, 255, 0)
        data.info.Visible = true
    end
end

-- ========================================
-- СОЗДАНИЕ ESP ДЛЯ ИГРОКА
-- ========================================
local function createESPForPlayer(plr)
    if plr == player then return end
    if espData[plr] then return end
    
    local lines, info = createOutline()
    espData[plr] = {
        lines = lines,
        info = info,
    }
end

-- ========================================
-- УДАЛЕНИЕ ESP
-- ========================================
local function removeESPForPlayer(plr)
    if espData[plr] then
        for _, line in pairs(espData[plr].lines) do
            pcall(function() line:Destroy() end)
        end
        pcall(function() espData[plr].info:Destroy() end)
        espData[plr] = nil
    end
end

-- ========================================
-- ОБНОВЛЕНИЕ ВСЕХ
-- ========================================
local function updateAllESP()
    for plr in pairs(espData) do
        removeESPForPlayer(plr)
    end
    espData = {}
    
    if not espEnabled then return end
    
    for _, plr in pairs(game.Players:GetPlayers()) do
        createESPForPlayer(plr)
    end
end

-- ========================================
-- ВКЛ/ВЫКЛ
-- ========================================
local function toggleESP()
    espEnabled = not espEnabled
    
    if espEnabled then
        espBtn.Text = "POISK\nВКЛ"
        espBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        updateAllESP()
        print("[ESP] ВКЛЮЧЕН - поиск маленьких игроков")
    else
        espBtn.Text = "POISK\nВЫКЛ"
        espBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        for plr in pairs(espData) do
            removeESPForPlayer(plr)
        end
        espData = {}
        print("[ESP] ВЫКЛЮЧЕН")
    end
end

espBtn.MouseButton1Click:Connect(toggleESP)

-- ========================================
-- ОСНОВНОЙ ЦИКЛ
-- ========================================
game:GetService("RunService").RenderStepped:Connect(function()
    if espEnabled then
        updateESP()
    end
end)

-- ========================================
-- ПОДПИСКА НА ИГРОКОВ
-- ========================================
updateAllESP()

game.Players.PlayerAdded:Connect(function(plr)
    task.wait(0.5)
    if espEnabled then
        createESPForPlayer(plr)
    end
    
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        if espEnabled then
            createESPForPlayer(plr)
        end
    end)
end)

for _, plr in pairs(game.Players:GetPlayers()) do
    if plr ~= player then
        plr.CharacterAdded:Connect(function()
            task.wait(0.5)
            if espEnabled then
                createESPForPlayer(plr)
            end
        end)
    end
end

-- Удаление при смерти
game:GetService("RunService").Heartbeat:Connect(function()
    if not espEnabled then return end
    
    for plr in pairs(espData) do
        if plr and plr.Character then
            local hum = plr.Character:FindFirstChild("Humanoid")
            if not hum or hum.Health <= 0 then
                removeESPForPlayer(plr)
            end
        else
            removeESPForPlayer(plr)
        end
    end
end)

-- ========================================
-- ПОМОЩЬ
-- ========================================
print("========================================")
print("   ✅ ESP ПОИСК МАЛЕНЬКИХ ИГРОКОВ")
print("   Кнопка в правом верхнем углу")
print("   Выделяет игроков с ростом меньше " .. MAX_NORMAL_HEIGHT)
print("   Красный контур + зеленая надпись")
print("========================================")
-- ========================================
-- AIMBOT ДЛЯ МАЛЕНЬКИХ ИГРОКОВ (рост < 1.20)
-- ========================================

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

-- ========================================
-- НАСТРОЙКИ
-- ========================================
local MAX_HEIGHT = 1.20  -- Максимальный рост
local FOV_SIZE = 350     -- Радиус круга

-- ========================================
-- КРУГ FOV
-- ========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player.PlayerGui
screenGui.ResetOnSpawn = false

local circle = Instance.new("Frame")
circle.Size = UDim2.new(0, FOV_SIZE * 2, 0, FOV_SIZE * 2)
circle.Position = UDim2.new(0.5, -FOV_SIZE, 0.5, -FOV_SIZE)
circle.BackgroundTransparency = 1
circle.BorderSizePixel = 2
circle.BorderColor3 = Color3.fromRGB(0, 255, 0)
circle.Parent = screenGui
circle.Visible = false

-- Крестик
local cross1 = Instance.new("Frame")
cross1.Size = UDim2.new(0, 20, 0, 2)
cross1.Position = UDim2.new(0.5, -10, 0.5, -1)
cross1.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
cross1.Parent = circle

local cross2 = Instance.new("Frame")
cross2.Size = UDim2.new(0, 2, 0, 20)
cross2.Position = UDim2.new(0.5, -1, 0.5, -10)
cross2.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
cross2.Parent = circle

-- ========================================
-- КНОПКА ВКЛ/ВЫКЛ (СДВИНУТА ЛЕВЕЕ)
-- ========================================
local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 60, 0, 60)
btn.Position = UDim2.new(1, -145, 0, 10)  -- Сдвинута левее на 70 пикселей
btn.BackgroundColor3 = Color3.fromRGB(0, 0, 200)
btn.Text = "AIM\nВЫКЛ"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.TextScaled = true
btn.Font = Enum.Font.GothamBold
btn.Parent = screenGui

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(1, 0)
btnCorner.Parent = btn

-- ========================================
-- ПРОВЕРКА РОСТА
-- ========================================
local function isSmall(plr)
    if not plr or not plr.Character then return false end
    
    local root = plr.Character:FindFirstChild("HumanoidRootPart")
    local head = plr.Character:FindFirstChild("Head")
    if not root or not head then return false end
    
    local height = math.abs(head.Position.Y - root.Position.Y)
    return height < MAX_HEIGHT and height > 0
end

-- ========================================
-- ПОИСК ЦЕЛИ
-- ========================================
local function findTarget()
    local closest = nil
    local closestDist = FOV_SIZE
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr == player then continue end
        if not isSmall(plr) then continue end
        
        local char = plr.Character
        if not char then continue end
        
        local hum = char:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        
        local head = char:FindFirstChild("Head")
        if not head then continue end
        
        local pos, onScreen = camera:WorldToViewportPoint(head.Position)
        if not onScreen then continue end
        
        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
        
        if dist < closestDist then
            closestDist = dist
            closest = plr
        end
    end
    
    return closest
end

-- ========================================
-- AIMBOT
-- ========================================
local function aimAt(target)
    if not target then return end
    
    local head = target.Character and target.Character:FindFirstChild("Head")
    if not head then return end
    
    camera.CFrame = CFrame.new(camera.CFrame.Position, head.Position)
end

-- ========================================
-- ВКЛ/ВЫКЛ
-- ========================================
local aimbotOn = false

btn.MouseButton1Click:Connect(function()
    aimbotOn = not aimbotOn
    
    if aimbotOn then
        btn.Text = "AIM\nВКЛ"
        btn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        circle.Visible = true
        print("[AIMBOT] ВКЛЮЧЕН - рост < " .. MAX_HEIGHT)
    else
        btn.Text = "AIM\nВЫКЛ"
        btn.BackgroundColor3 = Color3.fromRGB(0, 0, 200)
        circle.Visible = false
        print("[AIMBOT] ВЫКЛЮЧЕН")
    end
end)

-- ========================================
-- ОСНОВНОЙ ЦИКЛ
-- ========================================
game:GetService("RunService").RenderStepped:Connect(function()
    if not aimbotOn then return end
    
    if mouse.Button2Down or game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftControl) then
        local target = findTarget()
        if target then
            aimAt(target)
        end
    end
end)

-- ========================================
print("========================================")
print("   ✅ AIMBOT ДЛЯ МАЛЕНЬКИХ")
print("   Рост < " .. MAX_HEIGHT)
print("   Синяя кнопка слева от других")
print("   ПКМ или CTRL - прицел")
print("========================================")