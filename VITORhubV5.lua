-- VITOR HUB - VERSÃO COMPLETA (CORRIGIDA 2026)
-- Compatível com: Delta, Arceus X, Ronix, Fluxus, Solara

repeat wait() until game:IsLoaded()
repeat wait() until game.Players.LocalPlayer

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")

-- ==================== SISTEMA DE ESTADO CENTRALIZADO ====================
local UIState = {
    currentSpeed = 16,
    currentJump = 50,
    currentSpin = 0,
    currentTPWalkSpeed = 16,
    infjumpEnabled = false,
    xrayEnabled = false,
    noclipEnabled = false,
    fullbrightEnabled = false,
    noFogEnabled = false,
    dayEnabled = false,
    nightEnabled = false,
    tpwalkEnabled = false,
    shiftLockEnabled = false,
    ghostEnabled = false,
    antiAfkEnabled = false,
    aimbotEnabled = false,
    espEnabled = false,
    telekillEnabled = false,
    bringAllEnabled = false,
    freeCamEnabled = false,
    rainbowActive = true,
    currentColor = Color3.fromRGB(0, 170, 255),
    rVal = 0,
    gVal = 170,
    bVal = 255,
    IgnoreList = {},
    TelekillIgnoreList = {},
    sessionStart = os.time(),
}

-- ==================== GERENCIADOR DE CONEXÕES ====================
local ActiveConnections = {}

local function AddConnection(conn)
    table.insert(ActiveConnections, conn)
    return conn
end

local function ClearConnections()
    for _, conn in pairs(ActiveConnections) do
        pcall(function() conn:Disconnect() end)
    end
    ActiveConnections = {}
end

-- ==================== SISTEMA DE CACHE DE PLAYERS ====================
local PlayerCache = { list = {}, thumbnails = {}, lastUpdate = 0 }

local function updatePlayerCache()
    PlayerCache.list = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            table.insert(PlayerCache.list, plr)
        end
    end
    table.sort(PlayerCache.list, function(a, b) return a.Name:lower() < b.Name:lower() end)
    PlayerCache.lastUpdate = tick()
end

local function getPlayerThumbnail(userId)
    if PlayerCache.thumbnails[userId] then
        return PlayerCache.thumbnails[userId]
    end
    
    local success, thumbnail = pcall(function()
        return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    end)
    
    local result = success and thumbnail or "rbxasset://textures/ui/GuiImagePlaceholder.png"
    PlayerCache.thumbnails[userId] = result
    return result
end

updatePlayerCache()

-- ==================== FUNÇÕES IGNORE ====================
local function AddIgnore(userId)
    if not userId then return end
    for _, id in pairs(UIState.IgnoreList) do
        if id == userId then return end
    end
    table.insert(UIState.IgnoreList, userId)
end

local function RemoveIgnore(userId)
    if not userId then return end
    for i, id in pairs(UIState.IgnoreList) do
        if id == userId then
            table.remove(UIState.IgnoreList, i)
            break
        end
    end
end

local function IsIgnored(userId)
    for _, id in pairs(UIState.IgnoreList) do
        if id == userId then return true end
    end
    return false
end

local function AddTelekillIgnore(userId)
    if not userId then return end
    for _, id in pairs(UIState.TelekillIgnoreList) do
        if id == userId then return end
    end
    table.insert(UIState.TelekillIgnoreList, userId)
end

local function RemoveTelekillIgnore(userId)
    for i, id in pairs(UIState.TelekillIgnoreList) do
        if id == userId then
            table.remove(UIState.TelekillIgnoreList, i)
            break
        end
    end
end

local function IsTelekillIgnored(userId)
    for _, id in pairs(UIState.TelekillIgnoreList) do
        if id == userId then return true end
    end
    return false
end

-- ==================== JUMP POWER ====================
local function setJumpPower(value)
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        local humanoid = char.Humanoid
        pcall(function() humanoid.JumpPower = value end)
        pcall(function() humanoid.JumpHeight = value * 0.144 end)
        pcall(function() humanoid.UseJumpPower = true end)
    end
end

-- ==================== VARIÁVEIS ====================
local infjump = UIState.infjumpEnabled
local xray = UIState.xrayEnabled
local noclipEnabled = UIState.noclipEnabled
local noclipConnection = nil
local spinSpeed = UIState.currentSpin
local spinConnection = nil
local fullbrightEnabled = UIState.fullbrightEnabled
local fullbrightConnection = nil
local noFogEnabled = UIState.noFogEnabled
local dayEnabled = UIState.dayEnabled
local nightEnabled = UIState.nightEnabled
local tpwalkEnabled = UIState.tpwalkEnabled
local tpwalkConnection = nil
local tpwalkSpeed = UIState.currentTPWalkSpeed
local shiftLockEnabled = UIState.shiftLockEnabled
local shiftLockUI = nil
local ghostEnabled = UIState.ghostEnabled
local antiAfkEnabled = UIState.antiAfkEnabled
local antiAfkConnection = nil

-- Valores originais
local originalBrightness = Lighting.Brightness
local originalAmbient = Lighting.Ambient
local originalOutdoorAmbient = Lighting.OutdoorAmbient
local originalFogEnd = Lighting.FogEnd
local originalGlobalShadows = Lighting.GlobalShadows
local originalClockTime = Lighting.ClockTime

-- ==================== ANTI-AFK ====================
local function setupAntiAfk()
    if antiAfkConnection then antiAfkConnection:Disconnect() end
    antiAfkConnection = RunService.Stepped:Connect(function()
        if antiAfkEnabled and player.Character and player.Character:FindFirstChild("Humanoid") then
            local humanoid = player.Character.Humanoid
            humanoid:Move(Vector3.new(0,0,0), false)
            humanoid:Move(Vector3.new(0,0,0), true)
        end
    end)
    StarterGui:SetCore("SendNotification", { Title = "Anti-Afk", Text = antiAfkEnabled and "Ativado" or "Desativado", Duration = 2 })
end

local function toggleAntiAfk(state)
    antiAfkEnabled = state
    UIState.antiAfkEnabled = state
    setupAntiAfk()
end

-- ==================== FUNÇÃO FLOAT ====================
local function executeFloat()
    --// SERVICES
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")

    local plr = Players.LocalPlayer

    --// VARIAVEIS
    local floatEnabled = false
    local upHold = false
    local downHold = false
    local floatSpeed = 35

    local character, root, humanoid
    local floors = {}
    local bodyVel = nil

    --// PEGAR CHAR
    local function setupChar()
        character = plr.Character or plr.CharacterAdded:Wait()
        root = character:WaitForChild("HumanoidRootPart")
        humanoid = character:WaitForChild("Humanoid")
    end

    setupChar()

    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        setupChar()
    end)

    --// GUI
    local gui = Instance.new("ScreenGui")
    gui.Name = "FloatGui"
    gui.ResetOnSpawn = false
    gui.Parent = game.CoreGui

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0,120,0,180)
    frame.Position = UDim2.new(0,20,0.4,0)
    frame.BackgroundColor3 = Color3.fromRGB(20,20,20)

    local exit = Instance.new("TextButton", frame)
    exit.Size = UDim2.new(1,0,0,30)
    exit.Text = "Exit"

    local toggle = Instance.new("TextButton", frame)
    toggle.Position = UDim2.new(0,0,0,35)
    toggle.Size = UDim2.new(1,0,0,40)
    toggle.Text = "OFF"

    local up = Instance.new("TextButton", frame)
    up.Position = UDim2.new(0,0,0,80)
    up.Size = UDim2.new(1,0,0,40)
    up.Text = "↑"

    local down = Instance.new("TextButton", frame)
    down.Position = UDim2.new(0,0,0,125)
    down.Size = UDim2.new(1,0,0,40)
    down.Text = "↓"

    -- BOTÕES
    up.MouseButton1Down:Connect(function() upHold = true end)
    up.MouseButton1Up:Connect(function() upHold = false end)

    down.MouseButton1Down:Connect(function() downHold = true end)
    down.MouseButton1Up:Connect(function() downHold = false end)

    -- CRIAR CHÃO
    local function createFloor()
        local p = Instance.new("Part")
        p.Size = Vector3.new(500,1,500)
        p.Position = root.Position - Vector3.new(0,3,0)
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.Parent = workspace

        table.insert(floors, p)
    end

    -- REMOVER TODOS
    local function removeAllFloors()
        for _,p in ipairs(floors) do
            if p then p:Destroy() end
        end
        floors = {}
    end

    -- NOCLIP ESTÁVEL
    RunService.Stepped:Connect(function()
        if floatEnabled and character then
            for _,v in ipairs(character:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
        end
    end)

    -- RESTORE COLLISION
    local function restoreCollision()
        if character then
            for _,v in ipairs(character:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = true
                end
            end
        end
    end

    -- EXIT (MATA TUDO)
    exit.MouseButton1Click:Connect(function()
        floatEnabled = false

        removeAllFloors()

        if bodyVel then
            bodyVel:Destroy()
            bodyVel = nil
        end

        restoreCollision()
        gui:Destroy()
    end)

    -- TOGGLE
    toggle.MouseButton1Click:Connect(function()
        floatEnabled = not floatEnabled
        toggle.Text = floatEnabled and "ON" or "OFF"

        if floatEnabled then
            humanoid.WalkSpeed = 35

            bodyVel = Instance.new("BodyVelocity")
            bodyVel.MaxForce = Vector3.new(0, math.huge, 0)
            bodyVel.Velocity = Vector3.new(0,0,0)
            bodyVel.Parent = root

        else
            -- DESATIVAR TOTAL
            removeAllFloors()

            if bodyVel then
                bodyVel:Destroy()
                bodyVel = nil
            end

            restoreCollision()

            humanoid.WalkSpeed = 16
        end
    end)

    -- LOOP
    RunService.RenderStepped:Connect(function()
        if not root or not humanoid then return end

        if floatEnabled and bodyVel then

            if upHold then
                bodyVel.Velocity = Vector3.new(0, floatSpeed, 0)

            elseif downHold then
                bodyVel.Velocity = Vector3.new(0, -floatSpeed, 0)

            else
                bodyVel.Velocity = Vector3.new(0, 0, 0)

                -- cria chão só quando parar
                if not floors[#floors] or (root.Position - floors[#floors].Position).Magnitude > 5 then
                    createFloor()
                end
            end

        end
    end)
end

-- ==================== FUNÇÃO NO CLIP CAMERA ====================
local function executeNoClipCamera()
    -- SERVICES
    local Players = game:GetService("Players")

    local player = Players.LocalPlayer

    -- GUI
    local gui = Instance.new("ScreenGui")
    gui.Parent = player.PlayerGui
    gui.ResetOnSpawn = false

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0,180,0,80)
    frame.Position = UDim2.new(0.05,0,0.3,0)
    frame.BackgroundColor3 = Color3.fromRGB(20,20,20)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1,0,0,30)
    title.Text = "No Clip Camera"
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.new(1,1,1)

    local exit = Instance.new("TextButton", frame)
    exit.Size = UDim2.new(1,-20,0,35)
    exit.Position = UDim2.new(0,10,0.45,0)
    exit.Text = "EXIT"
    exit.BackgroundColor3 = Color3.fromRGB(150,0,0)

    -- DESATIVA COLISÃO DA CAMERA
    player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam

    -- EXIT
    exit.MouseButton1Click:Connect(function()

        player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom

        gui:Destroy()

    end)
end

-- ==================== FREE CAM ====================
local freeCamEnabled = UIState.freeCamEnabled
local freeCamSpeed = 10
local freeCamGUI = nil
local freeCamPosition = Vector3.new()
local freeCamYaw = 0
local freeCamPitch = 0
local freeCamTouchStart = nil
local mainUIButtonRef = nil
local analogPos = Vector2.new(0, 0)
local analogTargetPos = Vector2.new(0, 0)
local analogActive = false
local analogTouchId = nil
local verticalMove = 0
local verticalTarget = 0

local function createFreeCamGUI()
    if freeCamGUI then return end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "ExitCamGUI"
    gui.Parent = player:WaitForChild("PlayerGui", 5) or player.PlayerGui
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = gui
    mainFrame.Size = UDim2.new(0, 200, 0, 200)
    mainFrame.Position = UDim2.new(0.5, -100, 0.5, -100)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Visible = false
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 15)
    local stroke = Instance.new("UIStroke")
    stroke.Parent = mainFrame
    stroke.Color = Color3.fromRGB(0, 200, 255)
    stroke.Thickness = 2
    
    local title = Instance.new("TextLabel")
    title.Parent = mainFrame
    title.Size = UDim2.new(1, 0, 0, 25)
    title.Position = UDim2.new(0, 0, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "Exit Cam"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    
    local speedText = Instance.new("TextLabel")
    speedText.Parent = mainFrame
    speedText.Size = UDim2.new(1, 0, 0, 20)
    speedText.Position = UDim2.new(0, 0, 0, 35)
    speedText.BackgroundTransparency = 1
    speedText.Text = "Speed"
    speedText.TextColor3 = Color3.fromRGB(180, 180, 180)
    speedText.TextSize = 12
    speedText.Font = Enum.Font.Gotham
    
    local speedValue = Instance.new("TextLabel")
    speedValue.Parent = mainFrame
    speedValue.Size = UDim2.new(1, 0, 0, 30)
    speedValue.Position = UDim2.new(0, 0, 0, 55)
    speedValue.BackgroundTransparency = 1
    speedValue.Text = tostring(freeCamSpeed)
    speedValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedValue.TextSize = 24
    speedValue.Font = Enum.Font.GothamBold
    
    local speedDown = Instance.new("TextButton")
    speedDown.Parent = mainFrame
    speedDown.Size = UDim2.new(0, 30, 0, 30)
    speedDown.Position = UDim2.new(0.2, -15, 0, 90)
    speedDown.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    speedDown.Text = "-"
    speedDown.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedDown.TextSize = 20
    speedDown.Font = Enum.Font.GothamBold
    Instance.new("UICorner", speedDown).CornerRadius = UDim.new(0, 8)
    
    local speedUp = Instance.new("TextButton")
    speedUp.Parent = mainFrame
    speedUp.Size = UDim2.new(0, 30, 0, 30)
    speedUp.Position = UDim2.new(0.8, -15, 0, 90)
    speedUp.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    speedUp.Text = "+"
    speedUp.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedUp.TextSize = 20
    speedUp.Font = Enum.Font.GothamBold
    Instance.new("UICorner", speedUp).CornerRadius = UDim.new(0, 8)
    
    local exitBtn = Instance.new("TextButton")
    exitBtn.Parent = mainFrame
    exitBtn.Size = UDim2.new(0.8, 0, 0, 30)
    exitBtn.Position = UDim2.new(0.1, 0, 0, 125)
    exitBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    exitBtn.Text = "Exit Cam"
    exitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    exitBtn.TextSize = 12
    exitBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", exitBtn).CornerRadius = UDim.new(0, 8)
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = mainFrame
    closeBtn.Size = UDim2.new(0.8, 0, 0, 30)
    closeBtn.Position = UDim2.new(0.1, 0, 0, 160)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
    closeBtn.Text = "Close Gui"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 12
    closeBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
    
    local upBtn = Instance.new("TextButton")
    upBtn.Parent = gui
    upBtn.Size = UDim2.new(0, 70, 0, 70)
    upBtn.Position = UDim2.new(0.92, -35, 0.4, -35)
    upBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    upBtn.Text = "↑"
    upBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    upBtn.TextSize = 40
    upBtn.Font = Enum.Font.GothamBold
    upBtn.Visible = false
    Instance.new("UICorner", upBtn).CornerRadius = UDim.new(0, 15)
    
    local downBtn = Instance.new("TextButton")
    downBtn.Parent = gui
    downBtn.Size = UDim2.new(0, 70, 0, 70)
    downBtn.Position = UDim2.new(0.92, -35, 0.55, -35)
    downBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    downBtn.Text = "↓"
    downBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    downBtn.TextSize = 40
    downBtn.Font = Enum.Font.GothamBold
    downBtn.Visible = false
    Instance.new("UICorner", downBtn).CornerRadius = UDim.new(0, 15)
    
    local analogFrame = Instance.new("Frame")
    analogFrame.Parent = gui
    analogFrame.Name = "AnalogicoFrame"
    analogFrame.Size = UDim2.new(0, 380, 0, 380)
    analogFrame.Position = UDim2.new(0.05, 0, 0.7, -190)
    analogFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    analogFrame.BackgroundTransparency = 0.2
    analogFrame.Visible = false
    analogFrame.ZIndex = 1000
    Instance.new("UICorner", analogFrame).CornerRadius = UDim.new(1, 0)
    
    local analogBall = Instance.new("Frame")
    analogBall.Parent = analogFrame
    analogBall.Size = UDim2.new(0, 120, 0, 120)
    analogBall.Position = UDim2.new(0.5, -60, 0.5, -60)
    analogBall.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    analogBall.AnchorPoint = Vector2.new(0.5, 0.5)
    analogBall.ZIndex = 1001
    Instance.new("UICorner", analogBall).CornerRadius = UDim.new(1, 0)
    
    speedDown.MouseButton1Click:Connect(function()
        freeCamSpeed = math.max(1, freeCamSpeed - 1)
        speedValue.Text = tostring(freeCamSpeed)
    end)
    
    speedUp.MouseButton1Click:Connect(function()
        freeCamSpeed = math.min(999, freeCamSpeed + 1)
        speedValue.Text = tostring(freeCamSpeed)
    end)
    
    AddConnection(analogFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and freeCamEnabled then
            analogActive = true
            analogTouchId = input.KeyCode
            local touchPos = input.Position
            local framePos = analogFrame.AbsolutePosition
            local frameSize = analogFrame.AbsoluteSize
            local relativeX = (touchPos.X - framePos.X) / frameSize.X * 2 - 1
            local relativeY = (touchPos.Y - framePos.Y) / frameSize.Y * 2 - 1
            analogTargetPos = Vector2.new(math.clamp(relativeX, -1, 1), math.clamp(relativeY, -1, 1))
            return Enum.ContextActionResult.Sink
        end
    end))
    
    AddConnection(analogFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and analogActive and input.KeyCode == analogTouchId and freeCamEnabled then
            local touchPos = input.Position
            local framePos = analogFrame.AbsolutePosition
            local frameSize = analogFrame.AbsoluteSize
            local relativeX = (touchPos.X - framePos.X) / frameSize.X * 2 - 1
            local relativeY = (touchPos.Y - framePos.Y) / frameSize.Y * 2 - 1
            analogTargetPos = Vector2.new(math.clamp(relativeX, -1, 1), math.clamp(relativeY, -1, 1))
            return Enum.ContextActionResult.Sink
        end
    end))
    
    AddConnection(analogFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and input.KeyCode == analogTouchId and freeCamEnabled then
            analogActive = false
            analogTouchId = nil
            analogTargetPos = Vector2.new(0, 0)
            return Enum.ContextActionResult.Sink
        end
    end))
    
    AddConnection(upBtn.MouseButton1Down:Connect(function() if freeCamEnabled then verticalTarget = 1 end end))
    AddConnection(upBtn.MouseButton1Up:Connect(function() if freeCamEnabled then verticalTarget = 0 end end))
    AddConnection(downBtn.MouseButton1Down:Connect(function() if freeCamEnabled then verticalTarget = -1 end end))
    AddConnection(downBtn.MouseButton1Up:Connect(function() if freeCamEnabled then verticalTarget = 0 end end))
    
    exitBtn.MouseButton1Click:Connect(function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = CFrame.new(freeCamPosition)
        end
        if player.Character then
            for _, part in pairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Anchored = false
                    part.CanCollide = true
                end
            end
        end
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        freeCamEnabled = false
        mainFrame.Visible = false
        upBtn.Visible = false
        downBtn.Visible = false
        analogFrame.Visible = false
        gui:Destroy()
        freeCamGUI = nil
        if player.Character then
            for _, part in pairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Anchored = false
                    part.CanCollide = true
                end
            end
        end
        Camera.CameraType = Enum.CameraType.Custom
        ContextActionService:UnbindCoreAction("FreeCamMove")
        analogTargetPos = Vector2.new(0, 0)
        analogPos = Vector2.new(0, 0)
        verticalTarget = 0
        verticalMove = 0
        if mainUIButtonRef then
            mainUIButtonRef.Text = "Activate Free Cam"
            mainUIButtonRef.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
        end
    end)
    
    freeCamGUI = { gui = gui, mainFrame = mainFrame, upBtn = upBtn, downBtn = downBtn, analogFrame = analogFrame, analogBall = analogBall, speedValue = speedValue }
end

local function activateFreeCam()
    if freeCamEnabled then return end
    ClearConnections()
    freeCamEnabled = true
    if not freeCamGUI then createFreeCamGUI() end
    freeCamGUI.mainFrame.Visible = true
    freeCamGUI.upBtn.Visible = true
    freeCamGUI.downBtn.Visible = true
    freeCamGUI.analogFrame.Visible = true
    
    ContextActionService:UnbindCoreAction("VirtualThumbstick")
    ContextActionService:UnbindCoreAction("Thumbstick1")
    ContextActionService:UnbindCoreAction("Thumbstick2")
    
    local camCF = Camera.CFrame
    freeCamPosition = camCF.Position
    local look = camCF.LookVector
    freeCamYaw = math.atan2(-look.X, -look.Z)
    freeCamPitch = math.asin(look.Y)
    
    if player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = true
                part.CanCollide = false
            end
        end
    end
    
    Camera.CameraType = Enum.CameraType.Scriptable
    
    AddConnection(UIS.TouchStarted:Connect(function(touch)
        if not freeCamEnabled then return end
        local touchPos = touch.Position
        local analogAbsPos = freeCamGUI.analogFrame.AbsolutePosition
        local analogSize = freeCamGUI.analogFrame.AbsoluteSize
        local upBtnPos = freeCamGUI.upBtn.AbsolutePosition
        local downBtnPos = freeCamGUI.downBtn.AbsolutePosition
        local btnSize = freeCamGUI.upBtn.AbsoluteSize
        
        local inAnalog = freeCamGUI.analogFrame.Visible and touchPos.X >= analogAbsPos.X and touchPos.X <= analogAbsPos.X + analogSize.X and touchPos.Y >= analogAbsPos.Y and touchPos.Y <= analogAbsPos.Y + analogSize.Y
        local inUpBtn = freeCamGUI.upBtn.Visible and touchPos.X >= upBtnPos.X and touchPos.X <= upBtnPos.X + btnSize.X and touchPos.Y >= upBtnPos.Y and touchPos.Y <= upBtnPos.Y + btnSize.Y
        local inDownBtn = freeCamGUI.downBtn.Visible and touchPos.X >= downBtnPos.X and touchPos.X <= downBtnPos.X + btnSize.X and touchPos.Y >= downBtnPos.Y and touchPos.Y <= downBtnPos.Y + btnSize.Y
        
        if not inAnalog and not inUpBtn and not inDownBtn then
            freeCamTouchStart = touch.Position
        end
    end))
    
    AddConnection(UIS.TouchMoved:Connect(function(touch)
        if not freeCamEnabled or not freeCamTouchStart then return end
        local touchPos = touch.Position
        local analogAbsPos = freeCamGUI.analogFrame.AbsolutePosition
        local analogSize = freeCamGUI.analogFrame.AbsoluteSize
        local inAnalog = freeCamGUI.analogFrame.Visible and touchPos.X >= analogAbsPos.X and touchPos.X <= analogAbsPos.X + analogSize.X and touchPos.Y >= analogAbsPos.Y and touchPos.Y <= analogAbsPos.Y + analogSize.Y
        if inAnalog then return end
        local delta = touch.Position - freeCamTouchStart
        freeCamYaw = freeCamYaw - delta.X * 0.005
        freeCamPitch = math.clamp(freeCamPitch - delta.Y * 0.005, math.rad(-80), math.rad(80))
        freeCamTouchStart = touch.Position
    end))
    
    AddConnection(UIS.TouchEnded:Connect(function() freeCamTouchStart = nil end))
    
    AddConnection(RunService.RenderStepped:Connect(function(dt)
        if not freeCamEnabled then return end
        analogPos = analogPos:Lerp(analogTargetPos, 0.3)
        local maxOffset = 130
        local xOffset = math.clamp(analogPos.X * maxOffset, -maxOffset, maxOffset)
        local yOffset = math.clamp(analogPos.Y * maxOffset, -maxOffset, maxOffset)
        if freeCamGUI and freeCamGUI.analogBall then
            freeCamGUI.analogBall.Position = UDim2.new(0.5, xOffset, 0.5, yOffset)
        end
        verticalMove = verticalMove * 0.7 + verticalTarget * 0.3
        local moveDirection = Vector3.new()
        if analogPos.Magnitude > 0.05 then
            local yawCF = CFrame.Angles(0, freeCamYaw, 0)
            local forward = yawCF.LookVector
            local right = yawCF.RightVector
            moveDirection = moveDirection + (forward * -analogPos.Y + right * analogPos.X)
        end
        if math.abs(verticalMove) > 0.01 then
            moveDirection = moveDirection + Vector3.new(0, verticalMove, 0)
        end
        if moveDirection.Magnitude > 0 then
            local moveDelta = moveDirection.Unit * freeCamSpeed * dt * 60
            freeCamPosition = freeCamPosition + moveDelta
        end
        Camera.CFrame = CFrame.new(freeCamPosition) * CFrame.Angles(0, freeCamYaw, 0) * CFrame.Angles(freeCamPitch, 0, 0)
    end))
end

local function deactivateFreeCam()
    if not freeCamEnabled then return end
    freeCamEnabled = false
    ClearConnections()
    if freeCamGUI then
        freeCamGUI.mainFrame.Visible = false
        freeCamGUI.upBtn.Visible = false
        freeCamGUI.downBtn.Visible = false
        freeCamGUI.analogFrame.Visible = false
    end
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(freeCamPosition)
    end
    if player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = false
                part.CanCollide = true
            end
        end
    end
    Camera.CameraType = Enum.CameraType.Custom
    ContextActionService:UnbindCoreAction("FreeCamMove")
    analogTargetPos = Vector2.new(0, 0)
    analogPos = Vector2.new(0, 0)
    verticalTarget = 0
    verticalMove = 0
end

local function toggleFreeCam(state, buttonRef)
    if state == freeCamEnabled then return end
    if buttonRef then mainUIButtonRef = buttonRef end
    if state then
        activateFreeCam()
        if mainUIButtonRef then
            mainUIButtonRef.Text = "Deactivate Free Cam"
            mainUIButtonRef.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
        end
    else
        deactivateFreeCam()
        if mainUIButtonRef then
            mainUIButtonRef.Text = "Activate Free Cam"
            mainUIButtonRef.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
        end
    end
end

-- ==================== BRING ALL ====================
local bringAllEnabled = UIState.bringAllEnabled
local bringAllConnection = nil

local function bringAllPlayers()
    if not bringAllEnabled then return end
    local myChar = player.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function() plr.Character.HumanoidRootPart.CFrame = myHRP.CFrame * CFrame.new(0, 5, 0) end)
        end
    end
end

local function toggleBringAll(state)
    if state == bringAllEnabled then return end
    bringAllEnabled = state
    UIState.bringAllEnabled = state
    if bringAllConnection then bringAllConnection:Disconnect() end
    if bringAllEnabled then
        bringAllConnection = RunService.RenderStepped:Connect(bringAllPlayers)
        StarterGui:SetCore("SendNotification", { Title = "Bring All", Text = "Players will be brought to you continuously", Duration = 2 })
    else
        StarterGui:SetCore("SendNotification", { Title = "Bring All", Text = "Disabled", Duration = 1 })
    end
end

-- ==================== VARIÁVEIS DA UI ====================
local currentColor = UIState.currentColor
local activeTab = "HOME"
local isMinimized = false
local dragOffset = Vector2.new()
local uiDragging = false
local rainbowActive = UIState.rainbowActive
local rainbowConnection = nil
local rVal, gVal, bVal = UIState.rVal, UIState.gVal, UIState.bVal

-- ==================== AIMBOT (CORRIGIDO) ====================
local aimbotEnabled = UIState.aimbotEnabled
local aimbotConnection = nil

local function getClosestVisiblePlayer()
    local char = player.Character
    if not char or not char:FindFirstChild("Head") then return nil end
    
    local camera = Camera
    local cameraPos = camera.CFrame.Position
    local cameraDir = camera.CFrame.LookVector
    
    local closestPlayer = nil
    local closestDistance = math.huge
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and not IsIgnored(plr.UserId) and plr.Character and plr.Character:FindFirstChild("Head") then
            local humanoid = plr.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local head = plr.Character.Head
                local targetPos = head.Position
                local targetDir = (targetPos - cameraPos).Unit
                local dot = cameraDir:Dot(targetDir)
                local angle = math.deg(math.acos(dot))
                
                if angle <= 90 then
                    local raycastParams = RaycastParams.new()
                    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                    raycastParams.FilterDescendantsInstances = {char}
                    
                    local rayResult = workspace:Raycast(cameraPos, (targetPos - cameraPos).Unit * 1000, raycastParams)
                    if rayResult and rayResult.Instance and rayResult.Instance:IsDescendantOf(plr.Character) then
                        local dist = (targetPos - cameraPos).Magnitude
                        if dist < closestDistance then
                            closestDistance = dist
                            closestPlayer = plr
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

local function toggleAimbot(state)
    aimbotEnabled = state
    UIState.aimbotEnabled = state
    if aimbotConnection then aimbotConnection:Disconnect() end
    if state then
        aimbotConnection = RunService.RenderStepped:Connect(function()
            if not aimbotEnabled or not player.Character then return end
            local target = getClosestVisiblePlayer()
            if target and target.Character and target.Character:FindFirstChild("Head") then
                local head = target.Character.Head
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            end
        end)
        StarterGui:SetCore("SendNotification", { Title = "Aimbot", Text = "Activated", Duration = 2 })
    end
end

-- ==================== ESP ====================
local espConnections = {}
local espHighlights = {}
local espNameTags = {}
local espEnabled = UIState.espEnabled

local function createESPForPlayer(plr)
    if plr == player then return end
    
    local function addHighlight(char)
        if not char then return end
        local highlight = Instance.new("Highlight")
        highlight.Name = "VitorESP"
        highlight.FillColor = currentColor
        highlight.OutlineColor = Color3.new(1,1,1)
        highlight.FillTransparency = 0.5
        highlight.Parent = char
        espHighlights[plr] = highlight
        
        local head = char:FindFirstChild("Head")
        if head then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "VitorNameTag"
            billboard.Size = UDim2.new(0, 100, 0, 30)
            billboard.StudsOffset = Vector3.new(0, 3, 0)
            billboard.AlwaysOnTop = true
            billboard.Parent = head
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Parent = billboard
            nameLabel.Size = UDim2.new(1, 0, 1, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = plr.Name
            nameLabel.TextColor3 = currentColor
            nameLabel.TextScaled = true
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextStrokeTransparency = 0.5
            espNameTags[plr] = billboard
        end
    end
    
    if plr.Character then addHighlight(plr.Character) end
    plr.CharacterAdded:Connect(function(char) task.wait(0.5); addHighlight(char) end)
end

local function toggleESP(state)
    espEnabled = state
    UIState.espEnabled = state
    if state then
        for _, plr in pairs(Players:GetPlayers()) do createESPForPlayer(plr) end
        local conn = Players.PlayerAdded:Connect(createESPForPlayer)
        table.insert(espConnections, conn)
    else
        for _, highlight in pairs(espHighlights) do pcall(function() highlight:Destroy() end) end
        espHighlights = {}
        for _, nametag in pairs(espNameTags) do pcall(function() nametag:Destroy() end) end
        espNameTags = {}
        for _, conn in pairs(espConnections) do pcall(function() conn:Disconnect() end) end
        espConnections = {}
    end
end

-- ==================== TELEKILL ====================
local telekillEnabled = UIState.telekillEnabled
local telekillCurrentTarget = nil
local telekillFollowConnection = nil

local function getRandomAliveTargetForTelekill()
    local alivePlayers = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("Humanoid") then
            local humanoid = plr.Character.Humanoid
            if humanoid.Health > 0 and not IsTelekillIgnored(plr.UserId) then
                table.insert(alivePlayers, plr)
            end
        end
    end
    if #alivePlayers > 0 then return alivePlayers[math.random(1, #alivePlayers)] end
    return nil
end

local function telekillFollowTarget()
    if not telekillCurrentTarget or not telekillCurrentTarget.Character then
        telekillCurrentTarget = getRandomAliveTargetForTelekill()
        if not telekillCurrentTarget then return end
    end
    local targetChar = telekillCurrentTarget.Character
    local targetHead = targetChar:FindFirstChild("Head") or targetChar:FindFirstChild("HumanoidRootPart")
    local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not targetHead or not myHRP then
        telekillCurrentTarget = getRandomAliveTargetForTelekill()
        return
    end
    local humanoid = targetChar:FindFirstChild("Humanoid")
    if humanoid and humanoid.Health <= 0 then
        telekillCurrentTarget = getRandomAliveTargetForTelekill()
        return
    end
    if IsTelekillIgnored(telekillCurrentTarget.UserId) then
        telekillCurrentTarget = getRandomAliveTargetForTelekill()
        return
    end
    local targetPos = targetHead.Position + Vector3.new(0, 2, 0)
    myHRP.CFrame = CFrame.new(targetPos)
end

local function toggleTelekill(state)
    telekillEnabled = state
    UIState.telekillEnabled = state
    if telekillFollowConnection then telekillFollowConnection:Disconnect() end
    if state then
        telekillCurrentTarget = getRandomAliveTargetForTelekill()
        if telekillCurrentTarget then
            StarterGui:SetCore("SendNotification", { Title = "Telekill", Text = "Following: " .. telekillCurrentTarget.Name, Duration = 2 })
        end
        telekillFollowConnection = RunService.Heartbeat:Connect(telekillFollowTarget)
    end
end

-- ==================== SHIFT LOCK ====================
local function setupShiftLock()
    local SHOW_CENTER_CURSOR = true
    local MOBILE_ENABLED = true
    local CONSOLE_ENABLED = true
    local CONSOLE_BUTTON = Enum.KeyCode.ButtonR2
    
    local IsMobile = UserInputService.TouchEnabled
    local IsConsole = GuiService:IsTenFootInterface()
    local UserGameSettings = UserSettings():GetService("UserGameSettings")
    
    local offset = CFrame.new(1.75, 0, 0)
    local Activated = false
    
    if (IsMobile and MOBILE_ENABLED) or (IsConsole and CONSOLE_ENABLED) then
        local SHIFT_LOCK_OFF = 'rbxasset://textures/ui/mouseLock_off.png'
        local SHIFT_LOCK_ON = 'rbxasset://textures/ui/mouseLock_on.png'
        local SHIFT_LOCK_CURSOR = 'rbxasset://textures/MouseLockedCursor.png'
        
        local shiftLockGui = Instance.new("ScreenGui")
        shiftLockGui.Name = "ShiftLockUI"
        shiftLockGui.Parent = player:WaitForChild("PlayerGui")
        shiftLockGui.ResetOnSpawn = false
        shiftLockGui.IgnoreGuiInset = true
        
        local middleFrame = Instance.new('Frame')
        middleFrame.Name = "MiddleIcon"
        middleFrame.Size = UDim2.new(.075, 0, .075, 0)
        middleFrame.Position = UDim2.new(.5, 0, .5, 0)
        middleFrame.AnchorPoint = Vector2.new(.5,.5)
        middleFrame.BackgroundTransparency = 1
        middleFrame.ZIndex = 10
        middleFrame.Visible = true
        middleFrame.Parent = shiftLockGui
        
        local MouseLockCursor = Instance.new('ImageLabel')
        MouseLockCursor.Name = "MouseLockLabel"
        MouseLockCursor.Size = UDim2.new(1, 0, 1, 0)
        MouseLockCursor.Position = UDim2.new(0, 0, 0, 0)
        MouseLockCursor.BackgroundTransparency = 1
        MouseLockCursor.Image = SHIFT_LOCK_CURSOR
        MouseLockCursor.Visible = false
        MouseLockCursor.Parent = middleFrame
        
        local arc = Instance.new("UIAspectRatioConstraint")
        arc.AspectRatio = 1
        arc.DominantAxis = "Height"
        arc.Parent = middleFrame
        
        if IsMobile and MOBILE_ENABLED then
            local frame = Instance.new('Frame')
            frame.Name = "BottomLeftControl"
            frame.Size = UDim2.new(.1, 0, .1, 0)
            frame.Position = UDim2.new(1, 0, 1, 0)
            frame.AnchorPoint = Vector2.new(1,1)
            frame.BackgroundTransparency = 1
            frame.ZIndex = 10
            frame.Parent = shiftLockGui
            
            local ShiftLockIcon = Instance.new('ImageButton')
            ShiftLockIcon.Name = "MouseLockLabel"
            ShiftLockIcon.Size = UDim2.new(1, 0, 1, 0)
            ShiftLockIcon.Position = UDim2.new(-2.775, 0, -1.975, 0)
            ShiftLockIcon.BackgroundTransparency = 1
            ShiftLockIcon.Image = SHIFT_LOCK_OFF
            ShiftLockIcon.Visible = true
            ShiftLockIcon.Parent = frame
            
            local arc2 = Instance.new("UIAspectRatioConstraint")
            arc2.AspectRatio = 1
            arc2.DominantAxis = "Height"
            arc2.Parent = frame
            
            ShiftLockIcon.Activated:Connect(function()
                Activated = not Activated
                ShiftLockIcon.Image = Activated and SHIFT_LOCK_ON or SHIFT_LOCK_OFF
                MouseLockCursor.Visible = Activated and SHOW_CENTER_CURSOR
                shiftLockEnabled = Activated
            end)
        end
        
        if IsConsole and CONSOLE_ENABLED then
            UserInputService.InputBegan:Connect(function(input)
                if input.KeyCode == CONSOLE_BUTTON then
                    Activated = not Activated
                    MouseLockCursor.Visible = Activated and SHOW_CENTER_CURSOR
                    shiftLockEnabled = Activated
                end
            end)
        end
        
        local function OnStep()
            if Activated then
                UserGameSettings.RotationType = Enum.RotationType.CameraRelative
                local Camera = workspace.CurrentCamera
                if Camera then
                    if (Camera.Focus.Position - Camera.CFrame.Position).Magnitude >= 0.99 then
                        Camera.CFrame = Camera.CFrame * offset
                        Camera.Focus = CFrame.fromMatrix(Camera.Focus.Position, Camera.CFrame.RightVector, Camera.CFrame.UpVector) * offset
                    end
                end
            end
        end
        RunService:BindToRenderStep("Mobile/ConsoleShiftLock", Enum.RenderPriority.Camera.Value + 1, OnStep)
        shiftLockUI = shiftLockGui
    end
end

local function toggleShiftLock(state)
    shiftLockEnabled = state
    UIState.shiftLockEnabled = state
    if state then
        if not shiftLockUI then setupShiftLock() end
    else
        if shiftLockUI then shiftLockUI:Destroy() end
        pcall(function()
            UserSettings():GetService("UserGameSettings").RotationType = Enum.RotationType.CameraRelative
        end)
    end
end

-- ==================== GHOST MODE ====================
local function toggleGhost(state)
    ghostEnabled = state
    UIState.ghostEnabled = state
    if state then
        pcall(function() loadstring(game:HttpGet('https://pastebin.com/raw/3Rnd9rHf'))() end)
    end
end

-- ==================== FUNÇÕES DOS HACKS ====================
local function toggleFullbright(state)
    fullbrightEnabled = state
    UIState.fullbrightEnabled = state
    if fullbrightConnection then fullbrightConnection:Disconnect() end
    if state then
        dayEnabled = false; nightEnabled = false
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        fullbrightConnection = RunService.RenderStepped:Connect(function()
            if fullbrightEnabled then
                Lighting.Brightness = 2
                Lighting.Ambient = Color3.new(1,1,1)
                Lighting.GlobalShadows = false
            end
        end)
    else
        Lighting.Brightness = originalBrightness
        Lighting.Ambient = originalAmbient
        Lighting.OutdoorAmbient = originalOutdoorAmbient
        Lighting.GlobalShadows = originalGlobalShadows
    end
end

local function toggleNoFog(state)
    noFogEnabled = state
    UIState.noFogEnabled = state
    if state then
        Lighting.FogEnd = 1e10
        Lighting.FogStart = 0
    else
        Lighting.FogEnd = originalFogEnd
    end
end

local function toggleDay(state)
    dayEnabled = state
    UIState.dayEnabled = state
    if state then
        fullbrightEnabled = false; nightEnabled = false
        if fullbrightConnection then fullbrightConnection:Disconnect() end
        Lighting.ClockTime = 12
        Lighting.Brightness = 1
        Lighting.Ambient = Color3.new(0.5,0.5,0.5)
        Lighting.OutdoorAmbient = Color3.new(0.5,0.5,0.5)
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 100000
    else
        Lighting.ClockTime = originalClockTime
    end
end

local function toggleNight(state)
    nightEnabled = state
    UIState.nightEnabled = state
    if state then
        fullbrightEnabled = false; dayEnabled = false
        if fullbrightConnection then fullbrightConnection:Disconnect() end
        Lighting.ClockTime = 0
        Lighting.Brightness = 0.5
        Lighting.Ambient = Color3.new(0.2,0.2,0.2)
        Lighting.OutdoorAmbient = Color3.new(0.2,0.2,0.2)
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 100000
    else
        Lighting.ClockTime = originalClockTime
    end
end

local function toggleXRay(state)
    xray = state
    UIState.xrayEnabled = state
    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Parent and not part.Parent:FindFirstChild("Humanoid") then
            pcall(function() part.LocalTransparencyModifier = state and 0.7 or 0 end)
        end
    end
end

local function toggleNoclip(state)
    noclipEnabled = state
    UIState.noclipEnabled = state
    if noclipConnection then noclipConnection:Disconnect() end
    if state then
        noclipConnection = RunService.Stepped:Connect(function()
            if noclipEnabled and player.Character then
                for _, part in pairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end

local function toggleSpin(speed)
    spinSpeed = speed
    UIState.currentSpin = speed
    if spinConnection then spinConnection:Disconnect() end
    if speed > 0 then
        spinConnection = RunService.RenderStepped:Connect(function()
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(speed), 0)
            end
        end)
    end
end

local function toggleTpwalk(state)
    tpwalkEnabled = state
    UIState.tpwalkEnabled = state
    if tpwalkConnection then tpwalkConnection:Disconnect() end
    if state then
        tpwalkConnection = RunService.RenderStepped:Connect(function()
            if tpwalkEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local root = player.Character.HumanoidRootPart
                local moveDir = player.Character.Humanoid.MoveDirection
                if moveDir.Magnitude > 0 then
                    root.CFrame = root.CFrame + moveDir * tpwalkSpeed * 0.1
                end
            end
        end)
    end
end

-- ==================== INFINITE JUMP ====================
UIS.JumpRequest:Connect(function()
    if infjump and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ==================== FUNÇÃO PARA CRIAR GUI SEGURA ====================
local function createSafeGui()
    local success, g = pcall(function()
        local newGui = Instance.new("ScreenGui")
        newGui.Name = "VitorHub"
        local playerGui = player:FindFirstChild("PlayerGui")
        if not playerGui then
            repeat task.wait() until player:FindFirstChild("PlayerGui")
            playerGui = player.PlayerGui
        end
        newGui.Parent = playerGui
        newGui.ResetOnSpawn = false
        newGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        newGui.DisplayOrder = 100
        newGui.IgnoreGuiInset = true
        return newGui
    end)
    
    if success and g then return g end
    
    local g = Instance.new("ScreenGui")
    g.Name = "VitorHub"
    pcall(function() g.Parent = game:GetService("CoreGui") end)
    if not g.Parent then
        pcall(function() g.Parent = player.PlayerGui end)
    end
    g.ResetOnSpawn = false
    g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    g.DisplayOrder = 100
    g.IgnoreGuiInset = true
    return g
end

local gui = createSafeGui()
if not gui or not gui.Parent then
    warn("Falha ao criar GUI")
    return
end

-- ==================== GUI PRINCIPAL ====================
local main = Instance.new("Frame")
main.Parent = gui
main.Size = UDim2.new(0, 630, 0, 430)
main.Position = UDim2.new(0.5, -315, 0.5, -215)
main.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
main.BackgroundTransparency = 0.1
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Active = true
main.Draggable = true
main.ZIndex = 10
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 20)
local mainStroke = Instance.new("UIStroke")
mainStroke.Parent = main
mainStroke.Thickness = 2.5
mainStroke.Color = currentColor
mainStroke.Transparency = 0.2

local topBar = Instance.new("Frame")
topBar.Parent = main
topBar.Size = UDim2.new(1, 0, 0, 55)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
topBar.BackgroundTransparency = 0.1
topBar.ZIndex = 11
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 20)

topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        uiDragging = true
        dragOffset = Vector2.new(input.Position.X - main.AbsolutePosition.X, input.Position.Y - main.AbsolutePosition.Y)
    end
end)
UIS.InputChanged:Connect(function(input)
    if uiDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        main.Position = UDim2.new(0, input.Position.X - dragOffset.X, 0, input.Position.Y - dragOffset.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        uiDragging = false
    end
end)

local titleLabel = Instance.new("TextLabel")
titleLabel.Parent = topBar
titleLabel.Size = UDim2.new(0, 250, 1, 0)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Vitor Hub"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 24
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 12

local minBtn = Instance.new("TextButton")
minBtn.Parent = topBar
minBtn.Size = UDim2.new(0, 40, 0, 40)
minBtn.Position = UDim2.new(1, -90, 0.5, -20)
minBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
minBtn.Text = "−"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.TextSize = 28
minBtn.Font = Enum.Font.GothamBold
minBtn.ZIndex = 12
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(1, 0)

local closeBtn = Instance.new("TextButton")
closeBtn.Parent = topBar
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -45, 0.5, -20)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 22
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 12
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)
closeBtn.MouseButton1Click:Connect(function() pcall(function() gui:Destroy() end) end)

-- ==================== TOP STATUS BAR ====================
local infoFrame = Instance.new("Frame")
infoFrame.Parent = main
infoFrame.Size = UDim2.new(0, 540, 0, 30)
infoFrame.Position = UDim2.new(0, 45, 0, 140)
infoFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
infoFrame.BackgroundTransparency = 0.3
infoFrame.ZIndex = 11
Instance.new("UICorner", infoFrame).CornerRadius = UDim.new(0, 8)

local statusLayout = Instance.new("UIListLayout")
statusLayout.Parent = infoFrame
statusLayout.FillDirection = Enum.FillDirection.Horizontal
statusLayout.Padding = UDim.new(0, 10)
statusLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
statusLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local brasiliaLabel = Instance.new("TextLabel")
brasiliaLabel.Parent = infoFrame
brasiliaLabel.Size = UDim2.new(0, 130, 1, 0)
brasiliaLabel.BackgroundTransparency = 1
brasiliaLabel.Text = "Brasilia: 00:00:00"
brasiliaLabel.TextColor3 = Color3.fromRGB(0, 170, 255)
brasiliaLabel.TextSize = 12
brasiliaLabel.Font = Enum.Font.GothamBold
brasiliaLabel.TextXAlignment = Enum.TextXAlignment.Center
brasiliaLabel.ZIndex = 12

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Parent = infoFrame
fpsLabel.Size = UDim2.new(0, 130, 1, 0)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "Fps: 60"
fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
fpsLabel.TextSize = 12
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.TextXAlignment = Enum.TextXAlignment.Center
fpsLabel.ZIndex = 12

local playersLabel = Instance.new("TextLabel")
playersLabel.Parent = infoFrame
playersLabel.Size = UDim2.new(0, 80, 1, 0)
playersLabel.BackgroundTransparency = 1
playersLabel.Text = "Players: 0"
playersLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
playersLabel.TextSize = 12
playersLabel.Font = Enum.Font.GothamBold
playersLabel.TextXAlignment = Enum.TextXAlignment.Center
playersLabel.ZIndex = 12

local servidorLabel = Instance.new("TextLabel")
servidorLabel.Parent = infoFrame
servidorLabel.Size = UDim2.new(0, 130, 1, 0)
servidorLabel.BackgroundTransparency = 1
servidorLabel.Text = "Servidor: 00:00:00"
servidorLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
servidorLabel.TextSize = 12
servidorLabel.Font = Enum.Font.GothamBold
servidorLabel.TextXAlignment = Enum.TextXAlignment.Center
servidorLabel.ZIndex = 12

coroutine.wrap(function()
    local lastTime = tick()
    local frameCount = 0
    while task.wait(0.1) do
        local horaBR = tonumber(os.date("!%H")) - 3
        if horaBR < 0 then horaBR = horaBR + 24 end
        brasiliaLabel.Text = "Brasilia: " .. string.format("%02d", horaBR) .. os.date(":%M:%S")
        frameCount = frameCount + 1
        local now = tick()
        if now - lastTime >= 1 then
            fpsLabel.Text = "Fps: " .. frameCount
            frameCount = 0
            lastTime = now
        end
        playersLabel.Text = "Players: " .. #Players:GetPlayers()
        local sessionSeconds = os.difftime(os.time(), UIState.sessionStart)
        servidorLabel.Text = string.format("Servidor: %02d:%02d:%02d", math.floor(sessionSeconds / 3600), math.floor((sessionSeconds % 3600) / 60), sessionSeconds % 60)
    end
end)()

-- ==================== AVATAR ====================
local avatarFrame = Instance.new("Frame")
avatarFrame.Parent = main
avatarFrame.Size = UDim2.new(0, 80, 0, 80)
avatarFrame.Position = UDim2.new(0, 20, 0, 75)
avatarFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
avatarFrame.BackgroundTransparency = 0.9
avatarFrame.BorderSizePixel = 0
avatarFrame.ZIndex = 11
Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(1, 0)
local avatarStroke = Instance.new("UIStroke")
avatarStroke.Parent = avatarFrame
avatarStroke.Thickness = 3
avatarStroke.Color = currentColor
avatarStroke.Transparency = 0.2

local avatarImg = Instance.new("ImageLabel")
avatarImg.Parent = avatarFrame
avatarImg.Size = UDim2.new(1, -6, 1, -6)
avatarImg.Position = UDim2.new(0, 3, 0, 3)
avatarImg.BackgroundTransparency = 1
local success, thumbnail = pcall(function()
    return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
end)
avatarImg.Image = success and thumbnail or "rbxasset://textures/ui/GuiImagePlaceholder.png"
avatarImg.ZIndex = 12
Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)

local nome = Instance.new("TextLabel")
nome.Parent = main
nome.Size = UDim2.new(0, 350, 0, 30)
nome.Position = UDim2.new(0, 115, 0, 85)
nome.BackgroundTransparency = 1
nome.Text = player.Name
nome.TextColor3 = Color3.fromRGB(255, 255, 255)
nome.TextSize = 24
nome.Font = Enum.Font.GothamBold
nome.TextXAlignment = Enum.TextXAlignment.Left
nome.ZIndex = 11
local nomeGlow = Instance.new("UIStroke")
nomeGlow.Parent = nome
nomeGlow.Thickness = 1.5
nomeGlow.Color = currentColor
nomeGlow.Transparency = 0.2

local admin = Instance.new("TextLabel")
admin.Parent = main
admin.Size = UDim2.new(0, 350, 0, 22)
admin.Position = UDim2.new(0, 115, 0, 115)
admin.BackgroundTransparency = 1
admin.Text = "Admin"
admin.TextColor3 = Color3.fromRGB(255, 50, 50)
admin.TextSize = 18
admin.Font = Enum.Font.GothamBold
admin.TextXAlignment = Enum.TextXAlignment.Left
admin.ZIndex = 11

-- ==================== TABS ====================
local tabContainer = Instance.new("Frame")
tabContainer.Parent = main
tabContainer.Size = UDim2.new(0, 590, 0, 45)
tabContainer.Position = UDim2.new(0, 20, 0, 180)
tabContainer.BackgroundTransparency = 1
tabContainer.ClipsDescendants = true
tabContainer.ZIndex = 11

local tabScrollingFrame = Instance.new("ScrollingFrame")
tabScrollingFrame.Parent = tabContainer
tabScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
tabScrollingFrame.BackgroundTransparency = 1
tabScrollingFrame.BorderSizePixel = 0
tabScrollingFrame.CanvasSize = UDim2.new(10, 0, 0, 0)
tabScrollingFrame.ScrollBarThickness = 0
tabScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.X
tabScrollingFrame.ZIndex = 11

local tabLayout = Instance.new("UIListLayout")
tabLayout.Parent = tabScrollingFrame
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 10)
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

local function createTabButton(text)
    local btn = Instance.new("TextButton")
    btn.Parent = tabScrollingFrame
    btn.Size = UDim2.new(0, 110, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(180, 180, 180)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.ZIndex = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    return btn
end

local homeBtn = createTabButton("Home")
local gamesBtn = createTabButton("Games")
local visualBtn = createTabButton("Visual")
local telekillIgnoreBtn = createTabButton("Tk Ignore")
local aimbotBtn = createTabButton("Aimbot")
local serverBtn = createTabButton("Server")
local teleportBtn = createTabButton("Teleport")
local bringBtn = createTabButton("Bring")
local bangBtn = createTabButton("Bang")
local calcBtn = createTabButton("Calc")
local colorBtn = createTabButton("Color")
local adminsBtn = createTabButton("Admins")

homeBtn.BackgroundColor3 = currentColor
homeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Parent = main
contentFrame.Size = UDim2.new(0, 590, 0, 170)
contentFrame.Position = UDim2.new(0, 20, 0, 235)
contentFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
contentFrame.BackgroundTransparency = 0.3
contentFrame.BorderSizePixel = 0
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
contentFrame.ScrollBarThickness = 6
contentFrame.ScrollBarImageColor3 = currentColor
contentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
contentFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
contentFrame.ZIndex = 11
Instance.new("UICorner", contentFrame).CornerRadius = UDim.new(0, 12)

local contentList = Instance.new("UIListLayout")
contentList.Parent = contentFrame
contentList.Padding = UDim.new(0, 8)
contentList.HorizontalAlignment = Enum.HorizontalAlignment.Center

contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, contentList.AbsoluteContentSize.Y + 15)
end)

local ball = Instance.new("TextButton")
ball.Parent = gui
ball.Size = UDim2.new(0, 60, 0, 60)
ball.Position = UDim2.new(0.5, -30, 0.5, -30)
ball.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
ball.Text = "V"
ball.TextColor3 = currentColor
ball.TextSize = 32
ball.Font = Enum.Font.GothamBold
ball.Visible = false
ball.Active = true
ball.Draggable = true
ball.ZIndex = 50
Instance.new("UICorner", ball).CornerRadius = UDim.new(1, 0)
local ballStroke = Instance.new("UIStroke")
ballStroke.Parent = ball
ballStroke.Thickness = 3
ballStroke.Color = currentColor
ballStroke.Transparency = 0.2

-- ==================== FUNÇÕES DE CRIAÇÃO ====================
local function clearContent()
    for _, v in pairs(contentFrame:GetChildren()) do
        if v ~= contentList then
            v:Destroy()
        end
    end
end

local function createButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = parent
    btn.Size = UDim2.new(0, 560, 0, 42)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 16
    btn.Font = Enum.Font.GothamSemibold
    btn.ZIndex = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function createSlider(parent, name, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(0, 560, 0, 60)
    frame.BackgroundTransparency = 1
    frame.ZIndex = 12
    
    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.Size = UDim2.new(0.5, 0, 0.4, 0)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 16
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 13
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Parent = frame
    valueLabel.Size = UDim2.new(0.3, 0, 0.4, 0)
    valueLabel.Position = UDim2.new(0.7, 0, 0, 5)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = currentColor
    valueLabel.TextSize = 16
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.ZIndex = 13
    
    local bg = Instance.new("Frame")
    bg.Parent = frame
    bg.Size = UDim2.new(0.9, 0, 0, 18)
    bg.Position = UDim2.new(0.05, 0, 0, 30)
    bg.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    bg.ZIndex = 13
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
    
    local fill = Instance.new("Frame")
    fill.Parent = bg
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = currentColor
    fill.ZIndex = 14
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    
    local dragBtn = Instance.new("TextButton")
    dragBtn.Parent = bg
    dragBtn.Size = UDim2.new(1, 0, 1, 0)
    dragBtn.BackgroundTransparency = 1
    dragBtn.Text = ""
    dragBtn.ZIndex = 15
    
    local val = default
    local dragging = false
    
    dragBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    RunService.RenderStepped:Connect(function()
        if dragging then
            local mouse = UIS:GetMouseLocation()
            local pos = bg.AbsolutePosition
            local size = bg.AbsoluteSize
            local perc = math.clamp((mouse.X - pos.X) / size.X, 0, 1)
            val = math.floor(min + (max - min) * perc)
            fill.Size = UDim2.new(perc, 0, 1, 0)
            valueLabel.Text = tostring(val)
            callback(val)
        end
    end)
end

local function createToggle(parent, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(0, 560, 0, 42)
    frame.BackgroundTransparency = 1
    frame.ZIndex = 12
    
    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 16
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 13
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Parent = frame
    toggleBtn.Size = UDim2.new(0, 60, 0, 30)
    toggleBtn.Position = UDim2.new(1, -70, 0.5, -15)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    toggleBtn.Text = ""
    toggleBtn.ZIndex = 13
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)
    
    local indicator = Instance.new("Frame")
    indicator.Parent = toggleBtn
    indicator.Size = UDim2.new(0, 24, 0, 24)
    indicator.Position = default and UDim2.new(1, -27, 0.5, -12) or UDim2.new(0, 3, 0.5, -12)
    indicator.BackgroundColor3 = default and currentColor or Color3.fromRGB(100, 100, 100)
    indicator.ZIndex = 14
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)
    
    local state = default
    
    local function updateToggle()
        indicator.Position = state and UDim2.new(1, -27, 0.5, -12) or UDim2.new(0, 3, 0.5, -12)
        indicator.BackgroundColor3 = state and currentColor or Color3.fromRGB(100, 100, 100)
    end
    
    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        updateToggle()
        callback(state)
    end)
end

-- ==================== FUNÇÃO DO WAYPOINT ====================
local function executeWaypoint()
    pcall(function()
        if game.Players.LocalPlayer.PlayerGui:FindFirstChild("VitorHub") then
            game.Players.LocalPlayer.PlayerGui:FindFirstChild("VitorHub"):Destroy()
        end

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TweenService = game:GetService("TweenService")
        local HttpService = game:GetService("HttpService")

        local player = Players.LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local root = char:WaitForChild("HumanoidRootPart")

        player.CharacterAdded:Connect(function(newChar)
            char = newChar
            root = char:WaitForChild("HumanoidRootPart")
        end)

        local FILE_NAME = "VitorHub_Global.json"
        local waypoints = {}

        local function save()
            pcall(function() writefile(FILE_NAME, HttpService:JSONEncode(waypoints)) end)
        end

        local function load()
            if isfile(FILE_NAME) then
                local ok, data = pcall(function() return HttpService:JSONDecode(readfile(FILE_NAME)) end)
                if ok and type(data) == "table" then waypoints = data end
            end
        end

        local gui = Instance.new("ScreenGui")
        gui.Name = "VitorHub"
        gui.ResetOnSpawn = false
        gui.Parent = player:WaitForChild("PlayerGui")

        local frame = Instance.new("Frame", gui)
        frame.Size = UDim2.new(0,480,0,520)
        frame.Position = UDim2.new(0.5,-240,0.5,-260)
        frame.BackgroundColor3 = Color3.fromRGB(20,20,30)
        frame.Active = true
        frame.Draggable = true
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0,18)

        local title = Instance.new("TextLabel", frame)
        title.Size = UDim2.new(1,0,0,50)
        title.BackgroundTransparency = 1
        title.Text = "🦈 Vitor Hub ⚡"
        title.TextColor3 = Color3.fromRGB(0,200,255)
        title.Font = Enum.Font.GothamBlack
        title.TextSize = 24
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Position = UDim2.new(0,12,0,0)

        local function makeBtn(txt,x)
            local b = Instance.new("TextButton", frame)
            b.Size = UDim2.new(0,40,0,40)
            b.Position = UDim2.new(1,x,0,5)
            b.Text = txt
            b.BackgroundColor3 = Color3.fromRGB(40,40,40)
            b.TextColor3 = Color3.fromRGB(255,255,255)
            b.AutoButtonColor = false
            Instance.new("UICorner", b)
            b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(0,170,255)}):Play() end)
            b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(40,40,40)}):Play() end)
            return b
        end

        local close = makeBtn("✕",-50)
        local minimize = makeBtn("—",-100)

        local add = Instance.new("TextButton", frame)
        add.Size = UDim2.new(1,-20,0,50)
        add.Position = UDim2.new(0,10,0,60)
        add.Text = "💾➕ Salvar Waypoint"
        add.BackgroundColor3 = Color3.fromRGB(0,170,255)
        add.TextColor3 = Color3.fromRGB(255,255,255)
        add.Font = Enum.Font.GothamBlack
        Instance.new("UICorner", add)

        local scroll = Instance.new("ScrollingFrame", frame)
        scroll.Size = UDim2.new(1,-20,1,-130)
        scroll.Position = UDim2.new(0,10,0,125)
        scroll.BackgroundTransparency = 1
        scroll.ScrollBarThickness = 16
        scroll.ScrollingEnabled = true

        local layout = Instance.new("UIListLayout", scroll)
        layout.Padding = UDim.new(0,12)
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+20)
        end)

        local function createWaypoint(data)
            local pos = Vector3.new(unpack(data.pos))
            local item = Instance.new("Frame", scroll)
            item.Size = UDim2.new(1,-5,0,120)
            item.BackgroundColor3 = Color3.fromRGB(35,35,35)
            Instance.new("UICorner", item)

            local label = Instance.new("TextBox", item)
            label.Size = UDim2.new(1,-20,0,40)
            label.Position = UDim2.new(0,10,0,5)
            label.Text = "📍 "..data.name
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.fromRGB(255,255,255)
            label.Font = Enum.Font.GothamBlack
            label.TextSize = 20
            label.FocusLost:Connect(function() data.name = label.Text:gsub("📍 ",""); save() end)

            local function makeBtn(txt,y,color)
                local b = Instance.new("TextButton", item)
                b.Size = UDim2.new(1,-20,0,30)
                b.Position = UDim2.new(0,10,0,y)
                b.Text = txt
                b.BackgroundColor3 = color
                b.TextColor3 = Color3.fromRGB(255,255,255)
                Instance.new("UICorner", b)
                b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(0,200,255)}):Play() end)
                b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.2),{BackgroundColor3=color}):Play() end)
                return b
            end

            local tp = makeBtn("⚡ Teleportar",50,Color3.fromRGB(0,170,255))
            local del = makeBtn("❌ Deletar Waypoint",85,Color3.fromRGB(170,0,0))

            tp.MouseButton1Click:Connect(function() if root and root.Parent then root.CFrame = CFrame.new(pos) end end)
            del.MouseButton1Click:Connect(function()
                for i,v in pairs(waypoints) do if v == data then table.remove(waypoints,i); break end end
                save()
                item:Destroy()
            end)
        end

        add.MouseButton1Click:Connect(function()
            local data = {name="Waypoint",pos={root.Position.X,root.Position.Y,root.Position.Z}}
            table.insert(waypoints,data)
            save()
            createWaypoint(data)
        end)

        load()
        for _,v in pairs(waypoints) do createWaypoint(v) end

        local ball = Instance.new("TextButton", gui)
        ball.Size = UDim2.new(0,60,0,60)
        ball.Position = UDim2.new(0.1,0,0.5,0)
        ball.Text = "V"
        ball.Visible = false
        ball.TextColor3 = Color3.new(1,1,1)
        Instance.new("UICorner", ball).CornerRadius = UDim.new(1,0)
        ball.Active = true
        ball.Selectable = true
        ball.Draggable = true

        RunService.RenderStepped:Connect(function() if ball.Visible then ball.BackgroundColor3 = Color3.fromHSV((tick()%5)/5,1,1) end end)

        minimize.MouseButton1Click:Connect(function() frame.Visible = false; ball.Visible = true end)
        ball.MouseButton1Click:Connect(function() frame.Visible = true; ball.Visible = false end)
        close.MouseButton1Click:Connect(function() save(); gui:Destroy() end)

        StarterGui:SetCore("SendNotification", { Title = "Waypoint", Text = "Executado com sucesso!", Duration = 2 })
    end)
end

-- ==================== FUNÇÕES DAS ABAS ====================
local function loadHome()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.ZIndex = 12
    
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Parent = mainFrame
    controlsFrame.Size = UDim2.new(1, -20, 1, -20)
    controlsFrame.Position = UDim2.new(0, 10, 0, 10)
    controlsFrame.BackgroundTransparency = 1
    controlsFrame.ZIndex = 13
    
    local controlsList = Instance.new("UIListLayout")
    controlsList.Parent = controlsFrame
    controlsList.Padding = UDim.new(0, 8)
    controlsList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    createSlider(controlsFrame, "Walk Speed", 16, 500, UIState.currentSpeed, function(v)
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.WalkSpeed = v
            UIState.currentSpeed = v
        end
    end)
    
    createSlider(controlsFrame, "Jump Power", 50, 500, UIState.currentJump, function(v)
        setJumpPower(v)
        UIState.currentJump = v
    end)
    
    createSlider(controlsFrame, "Spin Speed", 0, 999, UIState.currentSpin, function(v)
        toggleSpin(v)
    end)
    
    createSlider(controlsFrame, "Tp Walk Speed", 1, 500, UIState.currentTPWalkSpeed, function(v) 
        tpwalkSpeed = v
        UIState.currentTPWalkSpeed = v 
    end)
    
    createToggle(controlsFrame, "Tp Walk", UIState.tpwalkEnabled, function(v) toggleTpwalk(v) end)
    createToggle(controlsFrame, "Infinite Jump", UIState.infjumpEnabled, function(v) infjump = v; UIState.infjumpEnabled = v end)
    createToggle(controlsFrame, "Noclip", UIState.noclipEnabled, function(v) toggleNoclip(v) end)
    createToggle(controlsFrame, "Ghost Mode", UIState.ghostEnabled, function(v) toggleGhost(v) end)
    createToggle(controlsFrame, "Free Cam", UIState.freeCamEnabled, function(v)
        local toggleRef = nil
        for _, child in pairs(controlsFrame:GetChildren()) do
            if child:IsA("Frame") then
                for _, btn in pairs(child:GetChildren()) do
                    if btn:IsA("TextButton") and btn.Text == "" then
                        toggleRef = btn
                        break
                    end
                end
            end
        end
        toggleFreeCam(v, toggleRef)
    end)
    
    createButton(controlsFrame, "📍 Waypoint System", executeWaypoint)
    createButton(controlsFrame, "🌊 Float", executeFloat)
    
    createButton(controlsFrame, "Fly Gui V3", function()
        pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"))() end)
    end)
    
    createButton(controlsFrame, "Fly Vehicle V4", function()
        pcall(function() loadstring(game:HttpGet('https://raw.githubusercontent.com/ScpGuest666/Random-Roblox-script/refs/heads/main/Roblox%20Fe%20Vehicle%20Fly%20GUI%20script'))() end)
    end)
    
    createButton(controlsFrame, "All Animations / All Emotes", function()
        pcall(function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-7yd7-I-Emote-Script-48024"))() end)
    end)
    
    createButton(controlsFrame, "Delta Keyboard Mobile", function()
        pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Xxtan31/Ata/main/deltakeyboardcrack.txt"))() end)
    end)
    
    createButton(controlsFrame, "Teleport Tool Fe", function()
        pcall(function()
            local mouse = game.Players.LocalPlayer:GetMouse()
            local tool = Instance.new("Tool")
            tool.RequiresHandle = false
            tool.Name = "QQ Teleport"
            tool.Activated:Connect(function()
                local pos = mouse.Hit + Vector3.new(0,2.5,0)
                game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos.X,pos.Y,pos.Z)
            end)
            tool.Parent = game.Players.LocalPlayer.Backpack
        end)
    end)
    
    createButton(controlsFrame, "Youtube Music Player", function()
        pcall(function() loadstring(game:HttpGet(('https://raw.githubusercontent.com/Dan41/Roblox-Scripts/refs/heads/main/Youtube%20Music%20Player/YoutubeMusicPlayer.lua'),true))() end)
    end)
end

-- ==================== TELEKILL IGNORE TAB ====================
local TelekillIgnoreSearchText = ""
local TelekillIgnoreContainer = nil

local function updateTelekillIgnoreList(searchTerm)
    searchTerm = searchTerm or TelekillIgnoreSearchText
    searchTerm = searchTerm:lower()
    
    if TelekillIgnoreContainer then
        for _, v in pairs(TelekillIgnoreContainer:GetChildren()) do
            if v:IsA("Frame") then v:Destroy() end
        end
    end
    
    updatePlayerCache()
    local playerList = PlayerCache.list
    
    if searchTerm ~= "" then
        local filtered = {}
        for _, plr in pairs(playerList) do
            if plr.Name:lower():find(searchTerm) or (plr.DisplayName and plr.DisplayName:lower():find(searchTerm)) then
                table.insert(filtered, plr)
            end
        end
        playerList = filtered
    end
    
    for _, plr in pairs(playerList) do
        local isIgnored = IsTelekillIgnored(plr.UserId)
        
        local rowFrame = Instance.new("Frame")
        rowFrame.Parent = TelekillIgnoreContainer
        rowFrame.Size = UDim2.new(1, -10, 0, 60)
        rowFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
        rowFrame.BackgroundTransparency = 0.2
        Instance.new("UICorner", rowFrame).CornerRadius = UDim.new(0, 8)
        
        local avatarFrame = Instance.new("Frame")
        avatarFrame.Parent = rowFrame
        avatarFrame.Size = UDim2.new(0, 50, 0, 50)
        avatarFrame.Position = UDim2.new(0, 5, 0.5, -25)
        avatarFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        avatarFrame.BackgroundTransparency = 0.9
        Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(1, 0)
        
        local avatarImg = Instance.new("ImageLabel")
        avatarImg.Parent = avatarFrame
        avatarImg.Size = UDim2.new(1, -4, 1, -4)
        avatarImg.Position = UDim2.new(0, 2, 0, 2)
        avatarImg.BackgroundTransparency = 1
        avatarImg.Image = getPlayerThumbnail(plr.UserId)
        Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Parent = rowFrame
        nameLabel.Size = UDim2.new(0, 200, 0, 30)
        nameLabel.Position = UDim2.new(0, 60, 0.3, -15)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = plr.Name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 16
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local statusLabel = Instance.new("TextLabel")
        statusLabel.Parent = rowFrame
        statusLabel.Size = UDim2.new(0, 80, 0, 30)
        statusLabel.Position = UDim2.new(1, -190, 0.5, -15)
        statusLabel.BackgroundColor3 = isIgnored and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
        statusLabel.BackgroundTransparency = 0.2
        statusLabel.Text = isIgnored and "Ignored" or "Target"
        statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        statusLabel.TextSize = 12
        statusLabel.Font = Enum.Font.GothamBold
        Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 6)
        
        local actionBtn = Instance.new("TextButton")
        actionBtn.Parent = rowFrame
        actionBtn.Size = UDim2.new(0, 80, 0, 30)
        actionBtn.Position = UDim2.new(1, -100, 0.5, -15)
        actionBtn.BackgroundColor3 = isIgnored and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 100, 255)
        actionBtn.BackgroundTransparency = 0.2
        actionBtn.Text = isIgnored and "Unignore" or "Ignore"
        actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        actionBtn.TextSize = 12
        actionBtn.Font = Enum.Font.GothamBold
        Instance.new("UICorner", actionBtn).CornerRadius = UDim.new(0, 6)
        
        actionBtn.MouseButton1Click:Connect(function()
            if IsTelekillIgnored(plr.UserId) then
                RemoveTelekillIgnore(plr.UserId)
            else
                AddTelekillIgnore(plr.UserId)
            end
            updateTelekillIgnoreList(TelekillIgnoreSearchText)
            StarterGui:SetCore("SendNotification", { Title = "Telekill Ignore", Text = IsTelekillIgnored(plr.UserId) and "Player removed from ignore" or "Player added to ignore", Duration = 1 })
        end)
    end
    
    if TelekillIgnoreContainer then
        TelekillIgnoreContainer.CanvasSize = UDim2.new(0, 0, 0, math.max(170, #playerList * 65))
    end
end

local function loadTelekillIgnore()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Telekill Ignore List"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    
    local searchFrame = Instance.new("Frame")
    searchFrame.Parent = mainFrame
    searchFrame.Size = UDim2.new(1, -20, 0, 40)
    searchFrame.Position = UDim2.new(0, 10, 0, 35)
    searchFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    searchFrame.BackgroundTransparency = 0.2
    Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 8)
    
    local searchBox = Instance.new("TextBox")
    searchBox.Parent = searchFrame
    searchBox.Size = UDim2.new(1, -50, 1, -10)
    searchBox.Position = UDim2.new(0, 10, 0, 5)
    searchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    searchBox.BackgroundTransparency = 0.3
    searchBox.PlaceholderText = "Search players..."
    searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    searchBox.Text = TelekillIgnoreSearchText
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.TextSize = 14
    searchBox.Font = Enum.Font.Gotham
    searchBox.ClearTextOnFocus = false
    Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 6)
    
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        TelekillIgnoreSearchText = searchBox.Text
        updateTelekillIgnoreList(TelekillIgnoreSearchText)
    end)
    
    local clearBtn = Instance.new("TextButton")
    clearBtn.Parent = searchFrame
    clearBtn.Size = UDim2.new(0, 30, 0, 30)
    clearBtn.Position = UDim2.new(1, -35, 0.5, -15)
    clearBtn.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
    clearBtn.BackgroundTransparency = 0.2
    clearBtn.Text = "✕"
    clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearBtn.TextSize = 16
    clearBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(1, 0)
    clearBtn.MouseButton1Click:Connect(function() searchBox.Text = ""; TelekillIgnoreSearchText = ""; updateTelekillIgnoreList("") end)
    
    local listContainer = Instance.new("ScrollingFrame")
    listContainer.Parent = mainFrame
    listContainer.Size = UDim2.new(1, -20, 0, 250)
    listContainer.Position = UDim2.new(0, 10, 0, 85)
    listContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    listContainer.BackgroundTransparency = 0.3
    listContainer.BorderSizePixel = 0
    listContainer.ScrollBarThickness = 6
    listContainer.ScrollBarImageColor3 = currentColor
    listContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    Instance.new("UICorner", listContainer).CornerRadius = UDim.new(0, 8)
    
    TelekillIgnoreContainer = listContainer
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = listContainer
    listLayout.Padding = UDim.new(0, 5)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)
    
    local playerAddedConn = Players.PlayerAdded:Connect(function() updateTelekillIgnoreList(TelekillIgnoreSearchText) end)
    local playerRemovingConn = Players.PlayerRemoving:Connect(function() updateTelekillIgnoreList(TelekillIgnoreSearchText) end)
    table.insert(espConnections, playerAddedConn)
    table.insert(espConnections, playerRemovingConn)
    
    updateTelekillIgnoreList("")
end

-- ==================== VISUAL TAB ====================
local function loadVisual()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Visual Settings"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Parent = mainFrame
    controlsFrame.Size = UDim2.new(1, -20, 1, -20)
    controlsFrame.Position = UDim2.new(0, 10, 0, 40)
    controlsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    controlsFrame.BackgroundTransparency = 0.3
    Instance.new("UICorner", controlsFrame).CornerRadius = UDim.new(0, 8)
    
    local toggleList = Instance.new("UIListLayout")
    toggleList.Parent = controlsFrame
    toggleList.Padding = UDim.new(0, 8)
    toggleList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    createToggle(controlsFrame, "Day", UIState.dayEnabled, toggleDay)
    createToggle(controlsFrame, "Night", UIState.nightEnabled, toggleNight)
    createToggle(controlsFrame, "Fullbright", UIState.fullbrightEnabled, toggleFullbright)
    createToggle(controlsFrame, "No Fog", UIState.noFogEnabled, toggleNoFog)
    createToggle(controlsFrame, "X-Ray", UIState.xrayEnabled, toggleXRay)
    createToggle(controlsFrame, "Shift Lock", UIState.shiftLockEnabled, toggleShiftLock)
    
    createButton(controlsFrame, "📷 No Clip Camera", executeNoClipCamera)
end

-- ==================== GAMES TAB ====================
local GameCards = {
    { name = "Piggy", placeId = 4623386862, script = function() pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/totallynothimplayz/Jd/refs/heads/main/Veno%20Hub"))() end) end },
    { name = "The Rake Remastered", placeId = 5657896419, script = function() pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/main/the%20rake"))() end) end },
    { name = "Blox Fruits", placeId = 2753915549, script = function() pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/acsu123/Hoho-Hub/main/main.lua"))() end) end },
    { name = "Prison Life", placeId = 155615604, script = function() pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/TableTops/Neverlose/main/Lua/Main.lua"))() end) end },
    { name = "Murder Mystery 2", placeId = 142823291, script = function() pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/androidfan9/carnival/refs/heads/main/mainhub.txt"))() end) end },
    { name = "99 Nights in the Forest", placeId = 1902735202, script = function() pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/VapeVoidware/VW-Add/main/loader.lua"))() end) end }
}

local GameSearchText = ""
local GameCardsContainer = nil

local function getGameIcon(placeId)
    local fallback = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    pcall(function()
        local response = game:HttpGet("https://thumbnails.roblox.com/v1/games/icons?universeIds=" .. placeId .. "&size=128x128&format=Png")
        local data = HttpService:JSONDecode(response)
        if data and data.data and data.data[1] and data.data[1].imageUrl then
            return data.data[1].imageUrl
        end
    end)
    return fallback
end

local function createGameCard(gameData)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -10, 0, 140)
    card.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    card.BackgroundTransparency = 0.2
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
    
    local imageContainer = Instance.new("Frame")
    imageContainer.Parent = card
    imageContainer.Size = UDim2.new(0, 120, 0, 120)
    imageContainer.Position = UDim2.new(0, 10, 0.5, -60)
    imageContainer.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    imageContainer.BackgroundTransparency = 0.3
    Instance.new("UICorner", imageContainer).CornerRadius = UDim.new(0, 8)
    
    local gameImage = Instance.new("ImageLabel")
    gameImage.Parent = imageContainer
    gameImage.Size = UDim2.new(1, -4, 1, -4)
    gameImage.Position = UDim2.new(0, 2, 0, 2)
    gameImage.BackgroundTransparency = 1
    gameImage.Image = getGameIcon(gameData.placeId)
    gameImage.ScaleType = Enum.ScaleType.Crop
    Instance.new("UICorner", gameImage).CornerRadius = UDim.new(0, 6)
    
    local gameTitle = Instance.new("TextLabel")
    gameTitle.Parent = card
    gameTitle.Size = UDim2.new(0, 200, 0, 30)
    gameTitle.Position = UDim2.new(0, 140, 0.3, -15)
    gameTitle.BackgroundTransparency = 1
    gameTitle.Text = gameData.name
    gameTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    gameTitle.TextSize = 20
    gameTitle.Font = Enum.Font.GothamBold
    gameTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    local executeBtn = Instance.new("TextButton")
    executeBtn.Parent = card
    executeBtn.Size = UDim2.new(0, 100, 0, 40)
    executeBtn.Position = UDim2.new(1, -110, 0.7, -20)
    executeBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    executeBtn.BackgroundTransparency = 0.1
    executeBtn.Text = "▶ Execute"
    executeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    executeBtn.TextSize = 14
    executeBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", executeBtn).CornerRadius = UDim.new(0, 8)
    
    executeBtn.MouseButton1Click:Connect(function()
        gameData.script()
        StarterGui:SetCore("SendNotification", { Title = "Games", Text = "Executing " .. gameData.name .. "...", Duration = 2 })
    end)
    
    return card
end

local function updateGameList(searchTerm)
    searchTerm = searchTerm or GameSearchText
    searchTerm = searchTerm:lower()
    
    if GameCardsContainer then
        for _, v in pairs(GameCardsContainer:GetChildren()) do
            if v:IsA("Frame") then v:Destroy() end
        end
    end
    
    local filteredGames = {}
    for _, game in ipairs(GameCards) do
        if searchTerm == "" or game.name:lower():find(searchTerm) then
            table.insert(filteredGames, game)
        end
    end
    
    for _, game in ipairs(filteredGames) do
        local card = createGameCard(game)
        card.Parent = GameCardsContainer
    end
    
    if GameCardsContainer then
        GameCardsContainer.CanvasSize = UDim2.new(0, 0, 0, math.max(170, #filteredGames * 150))
    end
end

local function loadGames()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Games Library"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    
    local searchFrame = Instance.new("Frame")
    searchFrame.Parent = mainFrame
    searchFrame.Size = UDim2.new(1, -20, 0, 40)
    searchFrame.Position = UDim2.new(0, 10, 0, 35)
    searchFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    searchFrame.BackgroundTransparency = 0.2
    Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 8)
    
    local searchBox = Instance.new("TextBox")
    searchBox.Parent = searchFrame
    searchBox.Size = UDim2.new(1, -50, 1, -10)
    searchBox.Position = UDim2.new(0, 10, 0, 5)
    searchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    searchBox.BackgroundTransparency = 0.3
    searchBox.PlaceholderText = "Search games..."
    searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    searchBox.Text = GameSearchText
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.TextSize = 14
    searchBox.Font = Enum.Font.Gotham
    searchBox.ClearTextOnFocus = false
    Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 6)
    
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        GameSearchText = searchBox.Text
        updateGameList(GameSearchText)
    end)
    
    local clearBtn = Instance.new("TextButton")
    clearBtn.Parent = searchFrame
    clearBtn.Size = UDim2.new(0, 30, 0, 30)
    clearBtn.Position = UDim2.new(1, -35, 0.5, -15)
    clearBtn.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
    clearBtn.BackgroundTransparency = 0.2
    clearBtn.Text = "✕"
    clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearBtn.TextSize = 16
    clearBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(1, 0)
    clearBtn.MouseButton1Click:Connect(function() searchBox.Text = ""; GameSearchText = ""; updateGameList("") end)
    
    local cardsContainer = Instance.new("ScrollingFrame")
    cardsContainer.Parent = mainFrame
    cardsContainer.Size = UDim2.new(1, -20, 0, 270)
    cardsContainer.Position = UDim2.new(0, 10, 0, 85)
    cardsContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    cardsContainer.BackgroundTransparency = 0.3
    cardsContainer.BorderSizePixel = 0
    cardsContainer.ScrollBarThickness = 6
    cardsContainer.ScrollBarImageColor3 = currentColor
    cardsContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    Instance.new("UICorner", cardsContainer).CornerRadius = UDim.new(0, 8)
    
    GameCardsContainer = cardsContainer
    
    local cardsLayout = Instance.new("UIListLayout")
    cardsLayout.Parent = cardsContainer
    cardsLayout.Padding = UDim.new(0, 10)
    cardsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    cardsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        cardsContainer.CanvasSize = UDim2.new(0, 0, 0, cardsLayout.AbsoluteContentSize.Y + 10)
    end)
    
    updateGameList("")
end

-- ==================== SERVER TAB ====================
local function loadServer()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Server"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    
    local buttonsFrame = Instance.new("Frame")
    buttonsFrame.Parent = mainFrame
    buttonsFrame.Size = UDim2.new(1, -20, 0, 200)
    buttonsFrame.Position = UDim2.new(0, 10, 0, 40)
    buttonsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    buttonsFrame.BackgroundTransparency = 0.3
    Instance.new("UICorner", buttonsFrame).CornerRadius = UDim.new(0, 8)
    
    local buttonsLayout = Instance.new("UIListLayout")
    buttonsLayout.Parent = buttonsFrame
    buttonsLayout.Padding = UDim.new(0, 10)
    buttonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    createButton(buttonsFrame, "Rejoin", function() pcall(function() TeleportService:Teleport(game.PlaceId, player) end) end)
    createButton(buttonsFrame, "Reset Character", function()
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.Health = 0
        end
    end)
    createButton(buttonsFrame, "Server Pequeno", function()
        pcall(function()
            local placeId = game.PlaceId
            local response = game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?limit=100")
            local data = HttpService:JSONDecode(response)
            local smallestServer = nil
            local smallestPlayers = math.huge
            for _, server in ipairs(data.data) do
                if server.playing < smallestPlayers then
                    smallestPlayers = server.playing
                    smallestServer = server.id
                end
            end
            if smallestServer then
                TeleportService:TeleportToPlaceInstance(placeId, smallestServer, player)
                StarterGui:SetCore("SendNotification", { Title = "Server Pequeno", Text = "Teleportando para servidor com " .. smallestPlayers .. " jogadores", Duration = 3 })
            end
        end)
    end)
    createToggle(buttonsFrame, "Anti-Afk", UIState.antiAfkEnabled, toggleAntiAfk)
end

-- ==================== AIMBOT TAB ====================
local function loadAimbot()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Aimbot"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    
    local togglesFrame = Instance.new("Frame")
    togglesFrame.Parent = mainFrame
    togglesFrame.Size = UDim2.new(1, -20, 0, 150)
    togglesFrame.Position = UDim2.new(0, 10, 0, 40)
    togglesFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    togglesFrame.BackgroundTransparency = 0.3
    Instance.new("UICorner", togglesFrame).CornerRadius = UDim.new(0, 8)
    
    local togglesLayout = Instance.new("UIListLayout")
    togglesLayout.Parent = togglesFrame
    togglesLayout.Padding = UDim.new(0, 10)
    togglesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    createToggle(togglesFrame, "Aimbot (Head)", UIState.aimbotEnabled, toggleAimbot)
    createToggle(togglesFrame, "Esp", UIState.espEnabled, toggleESP)
    createToggle(togglesFrame, "Telekill", UIState.telekillEnabled, toggleTelekill)
end

-- ==================== TELEPORT TAB ====================
local TeleportSearchText = ""
local TeleportContainer = nil
local TeleportSelectedPlayer = nil

local function updateTeleportList(searchTerm)
    searchTerm = searchTerm or TeleportSearchText
    searchTerm = searchTerm:lower()
    
    if not TeleportContainer then return end
    
    for _, v in pairs(TeleportContainer:GetChildren()) do
        if v:IsA("Frame") then v:Destroy() end
    end
    
    updatePlayerCache()
    local playerList = PlayerCache.list
    
    if searchTerm ~= "" then
        local filtered = {}
        for _, plr in pairs(playerList) do
            if plr.Name:lower():find(searchTerm) or (plr.DisplayName and plr.DisplayName:lower():find(searchTerm)) then
                table.insert(filtered, plr)
            end
        end
        playerList = filtered
    end
    
    for _, plr in pairs(playerList) do
        local rowFrame = Instance.new("Frame")
        rowFrame.Parent = TeleportContainer
        rowFrame.Size = UDim2.new(1, -10, 0, 60)
        rowFrame.BackgroundColor3 = plr == TeleportSelectedPlayer and currentColor or Color3.fromRGB(35, 35, 48)
        rowFrame.BackgroundTransparency = plr == TeleportSelectedPlayer and 0.3 or 0.2
        Instance.new("UICorner", rowFrame).CornerRadius = UDim.new(0, 8)
        
        local avatarFrame = Instance.new("Frame")
        avatarFrame.Parent = rowFrame
        avatarFrame.Size = UDim2.new(0, 50, 0, 50)
        avatarFrame.Position = UDim2.new(0, 5, 0.5, -25)
        avatarFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        avatarFrame.BackgroundTransparency = 0.9
        Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(1, 0)
        
        local avatarImg = Instance.new("ImageLabel")
        avatarImg.Parent = avatarFrame
        avatarImg.Size = UDim2.new(1, -4, 1, -4)
        avatarImg.Position = UDim2.new(0, 2, 0, 2)
        avatarImg.BackgroundTransparency = 1
        avatarImg.Image = getPlayerThumbnail(plr.UserId)
        Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Parent = rowFrame
        nameLabel.Size = UDim2.new(0, 200, 0, 30)
        nameLabel.Position = UDim2.new(0, 60, 0.3, -15)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = plr.Name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 16
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local tpBtn = Instance.new("TextButton")
        tpBtn.Parent = rowFrame
        tpBtn.Size = UDim2.new(0, 100, 0, 35)
        tpBtn.Position = UDim2.new(1, -110, 0.5, -17)
        tpBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        tpBtn.BackgroundTransparency = 0.2
        tpBtn.Text = "Teleport"
        tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        tpBtn.TextSize = 12
        tpBtn.Font = Enum.Font.GothamBold
        Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 6)
        
        tpBtn.MouseButton1Click:Connect(function()
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0)
                TeleportSelectedPlayer = plr
                updateTeleportList(TeleportSearchText)
                StarterGui:SetCore("SendNotification", { Title = "Teleport", Text = "Teleported to: " .. plr.Name, Duration = 2 })
            end
        end)
        
        local bringBtn = Instance.new("TextButton")
        bringBtn.Parent = rowFrame
        bringBtn.Size = UDim2.new(0, 100, 0, 35)
        bringBtn.Position = UDim2.new(1, -220, 0.5, -17)
        bringBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
        bringBtn.BackgroundTransparency = 0.2
        bringBtn.Text = "Bring"
        bringBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        bringBtn.TextSize = 12
        bringBtn.Font = Enum.Font.GothamBold
        Instance.new("UICorner", bringBtn).CornerRadius = UDim.new(0, 6)
        
        bringBtn.MouseButton1Click:Connect(function()
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                plr.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0)
                StarterGui:SetCore("SendNotification", { Title = "Teleport", Text = "Brought: " .. plr.Name .. " to you", Duration = 2 })
            end
        end)
    end
    
    TeleportContainer.CanvasSize = UDim2.new(0, 0, 0, math.max(170, #playerList * 65))
end

local function loadTeleport()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Teleport & Bring"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    
    local searchFrame = Instance.new("Frame")
    searchFrame.Parent = mainFrame
    searchFrame.Size = UDim2.new(1, -20, 0, 40)
    searchFrame.Position = UDim2.new(0, 10, 0, 35)
    searchFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    searchFrame.BackgroundTransparency = 0.2
    Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 8)
    
    local searchBox = Instance.new("TextBox")
    searchBox.Parent = searchFrame
    searchBox.Size = UDim2.new(1, -50, 1, -10)
    searchBox.Position = UDim2.new(0, 10, 0, 5)
    searchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    searchBox.BackgroundTransparency = 0.3
    searchBox.PlaceholderText = "Search players..."
    searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    searchBox.Text = TeleportSearchText
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.TextSize = 14
    searchBox.Font = Enum.Font.Gotham
    searchBox.ClearTextOnFocus = false
    Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 6)
    
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        TeleportSearchText = searchBox.Text
        updateTeleportList(TeleportSearchText)
    end)
    
    local clearBtn = Instance.new("TextButton")
    clearBtn.Parent = searchFrame
    clearBtn.Size = UDim2.new(0, 30, 0, 30)
    clearBtn.Position = UDim2.new(1, -35, 0.5, -15)
    clearBtn.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
    clearBtn.BackgroundTransparency = 0.2
    clearBtn.Text = "✕"
    clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearBtn.TextSize = 16
    clearBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(1, 0)
    clearBtn.MouseButton1Click:Connect(function() searchBox.Text = ""; TeleportSearchText = ""; updateTeleportList("") end)
    
    local listContainer = Instance.new("ScrollingFrame")
    listContainer.Parent = mainFrame
    listContainer.Size = UDim2.new(1, -20, 0, 270)
    listContainer.Position = UDim2.new(0, 10, 0, 85)
    listContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    listContainer.BackgroundTransparency = 0.3
    listContainer.BorderSizePixel = 0
    listContainer.ScrollBarThickness = 6
    listContainer.ScrollBarImageColor3 = currentColor
    listContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    Instance.new("UICorner", listContainer).CornerRadius = UDim.new(0, 8)
    
    TeleportContainer = listContainer
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = listContainer
    listLayout.Padding = UDim.new(0, 5)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)
    
    local playerAddedConn = Players.PlayerAdded:Connect(function() updateTeleportList(TeleportSearchText) end)
    local playerRemovingConn = Players.PlayerRemoving:Connect(function() updateTeleportList(TeleportSearchText) end)
    table.insert(espConnections, playerAddedConn)
    table.insert(espConnections, playerRemovingConn)
    
    updateTeleportList("")
end

-- ==================== BRING TAB ====================
local BringSearchText = ""
local BringContainer = nil

local function updateBringList(searchTerm)
    searchTerm = searchTerm or BringSearchText
    searchTerm = searchTerm:lower()
    
    if not BringContainer then return end
    
    for _, v in pairs(BringContainer:GetChildren()) do
        if v:IsA("Frame") then v:Destroy() end
    end
    
    updatePlayerCache()
    local playerList = PlayerCache.list
    
    if searchTerm ~= "" then
        local filtered = {}
        for _, plr in pairs(playerList) do
            if plr.Name:lower():find(searchTerm) or (plr.DisplayName and plr.DisplayName:lower():find(searchTerm)) then
                table.insert(filtered, plr)
            end
        end
        playerList = filtered
    end
    
    for _, plr in pairs(playerList) do
        local rowFrame = Instance.new("Frame")
        rowFrame.Parent = BringContainer
        rowFrame.Size = UDim2.new(1, -10, 0, 60)
        rowFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
        rowFrame.BackgroundTransparency = 0.2
        Instance.new("UICorner", rowFrame).CornerRadius = UDim.new(0, 8)
        
        local avatarFrame = Instance.new("Frame")
        avatarFrame.Parent = rowFrame
        avatarFrame.Size = UDim2.new(0, 50, 0, 50)
        avatarFrame.Position = UDim2.new(0, 5, 0.5, -25)
        avatarFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        avatarFrame.BackgroundTransparency = 0.9
        Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(1, 0)
        
        local avatarImg = Instance.new("ImageLabel")
        avatarImg.Parent = avatarFrame
        avatarImg.Size = UDim2.new(1, -4, 1, -4)
        avatarImg.Position = UDim2.new(0, 2, 0, 2)
        avatarImg.BackgroundTransparency = 1
        avatarImg.Image = getPlayerThumbnail(plr.UserId)
        Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Parent = rowFrame
        nameLabel.Size = UDim2.new(0, 200, 0, 30)
        nameLabel.Position = UDim2.new(0, 60, 0.3, -15)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = plr.Name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 16
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local bringBtn = Instance.new("TextButton")
        bringBtn.Parent = rowFrame
        bringBtn.Size = UDim2.new(0, 100, 0, 35)
        bringBtn.Position = UDim2.new(1, -110, 0.5, -17)
        bringBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
        bringBtn.BackgroundTransparency = 0.2
        bringBtn.Text = "Bring"
        bringBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        bringBtn.TextSize = 12
        bringBtn.Font = Enum.Font.GothamBold
        Instance.new("UICorner", bringBtn).CornerRadius = UDim.new(0, 6)
        
        bringBtn.MouseButton1Click:Connect(function()
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                plr.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0)
                StarterGui:SetCore("SendNotification", { Title = "Bring", Text = "Brought: " .. plr.Name .. " to you", Duration = 2 })
            end
        end)
    end
    
    BringContainer.CanvasSize = UDim2.new(0, 0, 0, math.max(170, #playerList * 65))
end

local function loadBring()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Bring Players"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    
    local bringAllFrame = Instance.new("Frame")
    bringAllFrame.Parent = mainFrame
    bringAllFrame.Size = UDim2.new(1, -20, 0, 50)
    bringAllFrame.Position = UDim2.new(0, 10, 0, 35)
    bringAllFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    bringAllFrame.BackgroundTransparency = 0.3
    Instance.new("UICorner", bringAllFrame).CornerRadius = UDim.new(0, 8)
    
    createToggle(bringAllFrame, "Bring All Players", UIState.bringAllEnabled, toggleBringAll)
    
    local searchFrame = Instance.new("Frame")
    searchFrame.Parent = mainFrame
    searchFrame.Size = UDim2.new(1, -20, 0, 40)
    searchFrame.Position = UDim2.new(0, 10, 0, 95)
    searchFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    searchFrame.BackgroundTransparency = 0.2
    Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 8)
    
    local searchBox = Instance.new("TextBox")
    searchBox.Parent = searchFrame
    searchBox.Size = UDim2.new(1, -50, 1, -10)
    searchBox.Position = UDim2.new(0, 10, 0, 5)
    searchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    searchBox.BackgroundTransparency = 0.3
    searchBox.PlaceholderText = "Search players..."
    searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    searchBox.Text = BringSearchText
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.TextSize = 14
    searchBox.Font = Enum.Font.Gotham
    searchBox.ClearTextOnFocus = false
    Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 6)
    
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        BringSearchText = searchBox.Text
        updateBringList(BringSearchText)
    end)
    
    local clearBtn = Instance.new("TextButton")
    clearBtn.Parent = searchFrame
    clearBtn.Size = UDim2.new(0, 30, 0, 30)
    clearBtn.Position = UDim2.new(1, -35, 0.5, -15)
    clearBtn.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
    clearBtn.BackgroundTransparency = 0.2
    clearBtn.Text = "✕"
    clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearBtn.TextSize = 16
    clearBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(1, 0)
    clearBtn.MouseButton1Click:Connect(function() searchBox.Text = ""; BringSearchText = ""; updateBringList("") end)
    
    local listContainer = Instance.new("ScrollingFrame")
    listContainer.Parent = mainFrame
    listContainer.Size = UDim2.new(1, -20, 0, 210)
    listContainer.Position = UDim2.new(0, 10, 0, 145)
    listContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    listContainer.BackgroundTransparency = 0.3
    listContainer.BorderSizePixel = 0
    listContainer.ScrollBarThickness = 6
    listContainer.ScrollBarImageColor3 = currentColor
    listContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    Instance.new("UICorner", listContainer).CornerRadius = UDim.new(0, 8)
    
    BringContainer = listContainer
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = listContainer
    listLayout.Padding = UDim.new(0, 5)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)
    
    local playerAddedConn = Players.PlayerAdded:Connect(function() updateBringList(BringSearchText) end)
    local playerRemovingConn = Players.PlayerRemoving:Connect(function() updateBringList(BringSearchText) end)
    table.insert(espConnections, playerAddedConn)
    table.insert(espConnections, playerRemovingConn)
    
    updateBringList("")
end

-- ==================== BANG TAB ====================
local BangSearchText = ""
local BangContainer = nil
local bangActive = false
local bangConnection = nil
local bangSelectedPlayer = nil

local function toggleBang(state)
    bangActive = state
    if bangConnection then bangConnection:Disconnect() end
    if state and bangSelectedPlayer then
        local target = bangSelectedPlayer
        local time = 0
        bangConnection = RunService.RenderStepped:Connect(function()
            if not bangActive or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
            local targetHRP = target.Character.HumanoidRootPart
            local playerHRP = player.Character.HumanoidRootPart
            time = time + 0.1
            local offset = math.sin(time * 5) * 1.5
            local direction = targetHRP.CFrame.LookVector * -1
            local behindPos = targetHRP.Position + direction * (3 + offset)
            playerHRP.CFrame = CFrame.new(behindPos, targetHRP.Position)
        end)
        StarterGui:SetCore("SendNotification", { Title = "Bang", Text = "Bang activated on: " .. bangSelectedPlayer.Name, Duration = 2 })
    end
end

local function updateBangList(searchTerm)
    searchTerm = searchTerm or BangSearchText
    searchTerm = searchTerm:lower()
    
    if not BangContainer then return end
    
    for _, v in pairs(BangContainer:GetChildren()) do
        if v:IsA("Frame") then v:Destroy() end
    end
    
    updatePlayerCache()
    local playerList = PlayerCache.list
    
    if searchTerm ~= "" then
        local filtered = {}
        for _, plr in pairs(playerList) do
            if plr.Name:lower():find(searchTerm) or (plr.DisplayName and plr.DisplayName:lower():find(searchTerm)) then
                table.insert(filtered, plr)
            end
        end
        playerList = filtered
    end
    
    for _, plr in pairs(playerList) do
        local rowFrame = Instance.new("Frame")
        rowFrame.Parent = BangContainer
        rowFrame.Size = UDim2.new(1, -10, 0, 60)
        rowFrame.BackgroundColor3 = plr == bangSelectedPlayer and currentColor or Color3.fromRGB(35, 35, 48)
        rowFrame.BackgroundTransparency = plr == bangSelectedPlayer and 0.3 or 0.2
        Instance.new("UICorner", rowFrame).CornerRadius = UDim.new(0, 8)
        
        local avatarFrame = Instance.new("Frame")
        avatarFrame.Parent = rowFrame
        avatarFrame.Size = UDim2.new(0, 50, 0, 50)
        avatarFrame.Position = UDim2.new(0, 5, 0.5, -25)
        avatarFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        avatarFrame.BackgroundTransparency = 0.9
        Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(1, 0)
        
        local avatarImg = Instance.new("ImageLabel")
        avatarImg.Parent = avatarFrame
        avatarImg.Size = UDim2.new(1, -4, 1, -4)
        avatarImg.Position = UDim2.new(0, 2, 0, 2)
        avatarImg.BackgroundTransparency = 1
        avatarImg.Image = getPlayerThumbnail(plr.UserId)
        Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Parent = rowFrame
        nameLabel.Size = UDim2.new(0, 200, 0, 30)
        nameLabel.Position = UDim2.new(0, 60, 0.3, -15)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = plr.Name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 16
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local selectBtn = Instance.new("TextButton")
        selectBtn.Parent = rowFrame
        selectBtn.Size = UDim2.new(0, 100, 0, 35)
        selectBtn.Position = UDim2.new(1, -110, 0.5, -17)
        selectBtn.BackgroundColor3 = plr == bangSelectedPlayer and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(100, 100, 255)
        selectBtn.BackgroundTransparency = 0.2
        selectBtn.Text = plr == bangSelectedPlayer and "Selected" or "Select"
        selectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        selectBtn.TextSize = 12
        selectBtn.Font = Enum.Font.GothamBold
        Instance.new("UICorner", selectBtn).CornerRadius = UDim.new(0, 6)
        
        selectBtn.MouseButton1Click:Connect(function()
            bangSelectedPlayer = plr
            updateBangList(BangSearchText)
        end)
    end
    
    BangContainer.CanvasSize = UDim2.new(0, 0, 0, math.max(170, #playerList * 65))
end

local function loadBang()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Bang Player"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Parent = mainFrame
    toggleFrame.Size = UDim2.new(1, -20, 0, 50)
    toggleFrame.Position = UDim2.new(0, 10, 0, 35)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    toggleFrame.BackgroundTransparency = 0.3
    Instance.new("UICorner", toggleFrame).CornerRadius = UDim.new(0, 8)
    
    local toggleLabel = Instance.new("TextLabel")
    toggleLabel.Parent = toggleFrame
    toggleLabel.Size = UDim2.new(0.5, 0, 1, 0)
    toggleLabel.Position = UDim2.new(0, 10, 0, 0)
    toggleLabel.BackgroundTransparency = 1
    toggleLabel.Text = "Activate Bang"
    toggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleLabel.TextSize = 16
    toggleLabel.Font = Enum.Font.Gotham
    toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Parent = toggleFrame
    toggleBtn.Size = UDim2.new(0, 60, 0, 30)
    toggleBtn.Position = UDim2.new(1, -70, 0.5, -15)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    toggleBtn.Text = ""
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)
    
    local toggleIndicator = Instance.new("Frame")
    toggleIndicator.Parent = toggleBtn
    toggleIndicator.Size = UDim2.new(0, 24, 0, 24)
    toggleIndicator.Position = bangActive and UDim2.new(1, -27, 0.5, -12) or UDim2.new(0, 3, 0.5, -12)
    toggleIndicator.BackgroundColor3 = bangActive and currentColor or Color3.fromRGB(100, 100, 100)
    Instance.new("UICorner", toggleIndicator).CornerRadius = UDim.new(1, 0)
    
    toggleBtn.MouseButton1Click:Connect(function()
        bangActive = not bangActive
        toggleIndicator.Position = bangActive and UDim2.new(1, -27, 0.5, -12) or UDim2.new(0, 3, 0.5, -12)
        toggleIndicator.BackgroundColor3 = bangActive and currentColor or Color3.fromRGB(100, 100, 100)
        toggleBang(bangActive)
    end)
    
    local searchFrame = Instance.new("Frame")
    searchFrame.Parent = mainFrame
    searchFrame.Size = UDim2.new(1, -20, 0, 40)
    searchFrame.Position = UDim2.new(0, 10, 0, 95)
    searchFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    searchFrame.BackgroundTransparency = 0.2
    Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 8)
    
    local searchBox = Instance.new("TextBox")
    searchBox.Parent = searchFrame
    searchBox.Size = UDim2.new(1, -50, 1, -10)
    searchBox.Position = UDim2.new(0, 10, 0, 5)
    searchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    searchBox.BackgroundTransparency = 0.3
    searchBox.PlaceholderText = "Search players..."
    searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    searchBox.Text = BangSearchText
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.TextSize = 14
    searchBox.Font = Enum.Font.Gotham
    searchBox.ClearTextOnFocus = false
    Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 6)
    
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        BangSearchText = searchBox.Text
        updateBangList(BangSearchText)
    end)
    
    local clearBtn = Instance.new("TextButton")
    clearBtn.Parent = searchFrame
    clearBtn.Size = UDim2.new(0, 30, 0, 30)
    clearBtn.Position = UDim2.new(1, -35, 0.5, -15)
    clearBtn.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
    clearBtn.BackgroundTransparency = 0.2
    clearBtn.Text = "✕"
    clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearBtn.TextSize = 16
    clearBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(1, 0)
    clearBtn.MouseButton1Click:Connect(function() searchBox.Text = ""; BangSearchText = ""; updateBangList("") end)
    
    local listContainer = Instance.new("ScrollingFrame")
    listContainer.Parent = mainFrame
    listContainer.Size = UDim2.new(1, -20, 0, 210)
    listContainer.Position = UDim2.new(0, 10, 0, 145)
    listContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    listContainer.BackgroundTransparency = 0.3
    listContainer.BorderSizePixel = 0
    listContainer.ScrollBarThickness = 6
    listContainer.ScrollBarImageColor3 = currentColor
    listContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    Instance.new("UICorner", listContainer).CornerRadius = UDim.new(0, 8)
    
    BangContainer = listContainer
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = listContainer
    listLayout.Padding = UDim.new(0, 5)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)
    
    local playerAddedConn = Players.PlayerAdded:Connect(function() updateBangList(BangSearchText) end)
    local playerRemovingConn = Players.PlayerRemoving:Connect(function() updateBangList(BangSearchText) end)
    table.insert(espConnections, playerAddedConn)
    table.insert(espConnections, playerRemovingConn)
    
    updateBangList("")
end

-- ==================== CALCULATOR TAB ====================
local function loadCalculator()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Calculator"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    
    local calcFrame = Instance.new("Frame")
    calcFrame.Parent = mainFrame
    calcFrame.Size = UDim2.new(0, 560, 0, 300)
    calcFrame.Position = UDim2.new(0, 0, 0, 40)
    calcFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    calcFrame.BackgroundTransparency = 0.3
    Instance.new("UICorner", calcFrame).CornerRadius = UDim.new(0, 12)
    
    local display = Instance.new("TextBox")
    display.Parent = calcFrame
    display.Size = UDim2.new(0.9, 0, 0, 50)
    display.Position = UDim2.new(0.05, 0, 0, 20)
    display.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    display.BackgroundTransparency = 0.2
    display.PlaceholderText = "0"
    display.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    display.Text = "0"
    display.TextColor3 = Color3.fromRGB(255, 255, 255)
    display.TextSize = 24
    display.Font = Enum.Font.GothamBold
    display.TextXAlignment = Enum.TextXAlignment.Right
    display.ClearTextOnFocus = false
    Instance.new("UICorner", display).CornerRadius = UDim.new(0, 8)
    
    local buttonsFrame = Instance.new("Frame")
    buttonsFrame.Parent = calcFrame
    buttonsFrame.Size = UDim2.new(0.9, 0, 0, 180)
    buttonsFrame.Position = UDim2.new(0.05, 0, 0, 90)
    buttonsFrame.BackgroundTransparency = 1
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.Parent = buttonsFrame
    gridLayout.CellSize = UDim2.new(0, 120, 0, 40)
    gridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    
    local function evaluateExpression(expr)
        local clean = expr:gsub("[^%d%+%-%*%/%.%(%)]", "")
        if clean == "" then return "0" end
        local func, err = loadstring("return " .. clean)
        if not func then return "Erro" end
        local success, result = pcall(func)
        if success and type(result) == "number" then return tostring(result) else return "Erro" end
    end
    
    local numbers = { {"7", "8", "9", "/"}, {"4", "5", "6", "*"}, {"1", "2", "3", "-"}, {"0", ".", "=", "+"} }
    
    for row = 1, 4 do
        for col = 1, 4 do
            local btnText = numbers[row][col]
            local btn = Instance.new("TextButton")
            btn.Parent = buttonsFrame
            btn.Size = UDim2.new(0, 120, 0, 40)
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
            btn.BackgroundTransparency = 0.2
            btn.Text = btnText
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextSize = 18
            btn.Font = Enum.Font.GothamBold
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
            
            btn.MouseButton1Click:Connect(function()
                local currentText = display.Text
                if btnText == "=" then
                    display.Text = evaluateExpression(currentText)
                elseif btnText == "C" then
                    display.Text = "0"
                else
                    if currentText == "0" or currentText == "Erro" then
                        display.Text = btnText
                    else
                        display.Text = currentText .. btnText
                    end
                end
            end)
        end
    end
    
    local clearBtn = Instance.new("TextButton")
    clearBtn.Parent = calcFrame
    clearBtn.Size = UDim2.new(0.9, 0, 0, 40)
    clearBtn.Position = UDim2.new(0.05, 0, 0, 280)
    clearBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    clearBtn.BackgroundTransparency = 0.2
    clearBtn.Text = "Clear"
    clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearBtn.TextSize = 18
    clearBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 8)
    clearBtn.MouseButton1Click:Connect(function() display.Text = "0" end)
end

-- ==================== ADMINS TAB ====================
local function loadAdmins()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Admin Scripts"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    
    local buttonsFrame = Instance.new("Frame")
    buttonsFrame.Parent = mainFrame
    buttonsFrame.Size = UDim2.new(1, -20, 0, 300)
    buttonsFrame.Position = UDim2.new(0, 10, 0, 40)
    buttonsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    buttonsFrame.BackgroundTransparency = 0.3
    Instance.new("UICorner", buttonsFrame).CornerRadius = UDim.new(0, 8)
    
    local buttonsLayout = Instance.new("UIListLayout")
    buttonsLayout.Parent = buttonsFrame
    buttonsLayout.Padding = UDim.new(0, 10)
    buttonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    createButton(buttonsFrame, "Infinity Yield", function() pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end) end)
    createButton(buttonsFrame, "Dex Explorer Admin Fe", function() pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/DannyH3103/scripts/main/Hydrogen_DEXV4"))() end) end)
    createButton(buttonsFrame, "Paranoia Admin Fe", function() pcall(function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Paranoia-Admin-FE-72345"))() end) end)
    createButton(buttonsFrame, "Nameless Admin Fe", function() pcall(function() loadstring(game:HttpGet('https://raw.githubusercontent.com/FilteringEnabled/NamelessAdmin/main/Source'))() end) end)
end

-- ==================== COLOR TAB ====================
local function loadColor()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Color Settings"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Parent = mainFrame
    controlsFrame.Size = UDim2.new(1, -20, 0, 300)
    controlsFrame.Position = UDim2.new(0, 10, 0, 40)
    controlsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    controlsFrame.BackgroundTransparency = 0.3
    Instance.new("UICorner", controlsFrame).CornerRadius = UDim.new(0, 8)
    
    local toggleContainer = Instance.new("Frame")
    toggleContainer.Parent = controlsFrame
    toggleContainer.Size = UDim2.new(1, -20, 1, -20)
    toggleContainer.Position = UDim2.new(0, 10, 0, 10)
    toggleContainer.BackgroundTransparency = 1
    
    local toggleList = Instance.new("UIListLayout")
    toggleList.Parent = toggleContainer
    toggleList.Padding = UDim.new(0, 8)
    toggleList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    createToggle(toggleContainer, "Rainbow Mode", rainbowActive, function(v)
        rainbowActive = v
        UIState.rainbowActive = v
        if not rainbowActive then
            currentColor = Color3.fromRGB(rVal, gVal, bVal)
            mainStroke.Color = currentColor
            avatarStroke.Color = currentColor
            nomeGlow.Color = currentColor
            ball.TextColor3 = currentColor
            ballStroke.Color = currentColor
            contentFrame.ScrollBarImageColor3 = currentColor
            homeBtn.BackgroundColor3 = currentColor
            if espEnabled then
                for plr, highlight in pairs(espHighlights) do if highlight then highlight.FillColor = currentColor end end
                for plr, nametag in pairs(espNameTags) do if nametag and nametag:FindFirstChildOfClass("TextLabel") then nametag:FindFirstChildOfClass("TextLabel").TextColor3 = currentColor end end
            end
        end
    end)
    
    createSlider(toggleContainer, "Red", 0, 255, rVal, function(v)
        rVal = v; UIState.rVal = v
        if not rainbowActive then
            currentColor = Color3.fromRGB(rVal, gVal, bVal)
            mainStroke.Color = currentColor; avatarStroke.Color = currentColor; nomeGlow.Color = currentColor; ball.TextColor3 = currentColor; ballStroke.Color = currentColor; contentFrame.ScrollBarImageColor3 = currentColor; homeBtn.BackgroundColor3 = currentColor
            if espEnabled then
                for plr, highlight in pairs(espHighlights) do if highlight then highlight.FillColor = currentColor end end
                for plr, nametag in pairs(espNameTags) do if nametag and nametag:FindFirstChildOfClass("TextLabel") then nametag:FindFirstChildOfClass("TextLabel").TextColor3 = currentColor end end
            end
        end
    end)
    
    createSlider(toggleContainer, "Green", 0, 255, gVal, function(v)
        gVal = v; UIState.gVal = v
        if not rainbowActive then
            currentColor = Color3.fromRGB(rVal, gVal, bVal)
            mainStroke.Color = currentColor; avatarStroke.Color = currentColor; nomeGlow.Color = currentColor; ball.TextColor3 = currentColor; ballStroke.Color = currentColor; contentFrame.ScrollBarImageColor3 = currentColor; homeBtn.BackgroundColor3 = currentColor
            if espEnabled then
                for plr, highlight in pairs(espHighlights) do if highlight then highlight.FillColor = currentColor end end
                for plr, nametag in pairs(espNameTags) do if nametag and nametag:FindFirstChildOfClass("TextLabel") then nametag:FindFirstChildOfClass("TextLabel").TextColor3 = currentColor end end
            end
        end
    end)
    
    createSlider(toggleContainer, "Blue", 0, 255, bVal, function(v)
        bVal = v; UIState.bVal = v
        if not rainbowActive then
            currentColor = Color3.fromRGB(rVal, gVal, bVal)
            mainStroke.Color = currentColor; avatarStroke.Color = currentColor; nomeGlow.Color = currentColor; ball.TextColor3 = currentColor; ballStroke.Color = currentColor; contentFrame.ScrollBarImageColor3 = currentColor; homeBtn.BackgroundColor3 = currentColor
            if espEnabled then
                for plr, highlight in pairs(espHighlights) do if highlight then highlight.FillColor = currentColor end end
                for plr, nametag in pairs(espNameTags) do if nametag and nametag:FindFirstChildOfClass("TextLabel") then nametag:FindFirstChildOfClass("TextLabel").TextColor3 = currentColor end end
            end
        end
    end)
end

-- ==================== EVENTOS DAS ABAS ====================
homeBtn.MouseButton1Click:Connect(function() activeTab = "HOME"; loadHome() end)
gamesBtn.MouseButton1Click:Connect(function() activeTab = "GAMES"; loadGames() end)
visualBtn.MouseButton1Click:Connect(function() activeTab = "VISUAL"; loadVisual() end)
telekillIgnoreBtn.MouseButton1Click:Connect(function() activeTab = "TK IGNORE"; loadTelekillIgnore() end)
aimbotBtn.MouseButton1Click:Connect(function() activeTab = "AIMBOT"; loadAimbot() end)
serverBtn.MouseButton1Click:Connect(function() activeTab = "SERVER"; loadServer() end)
teleportBtn.MouseButton1Click:Connect(function() activeTab = "TELEPORT"; loadTeleport() end)
bringBtn.MouseButton1Click:Connect(function() activeTab = "BRING"; loadBring() end)
bangBtn.MouseButton1Click:Connect(function() activeTab = "BANG"; loadBang() end)
calcBtn.MouseButton1Click:Connect(function() activeTab = "CALC"; loadCalculator() end)
colorBtn.MouseButton1Click:Connect(function() activeTab = "COLOR"; loadColor() end)
adminsBtn.MouseButton1Click:Connect(function() activeTab = "ADMINS"; loadAdmins() end)

-- ==================== MINIMIZAR/RESTAURAR ====================
minBtn.MouseButton1Click:Connect(function()
    if isMinimized then return end
    isMinimized = true
    TweenService:Create(main, TweenInfo.new(0.4), { BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) }):Play()
    task.wait(0.3)
    main.Visible = false
    ball.Visible = true
    ball.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(ball, TweenInfo.new(0.4), { Size = UDim2.new(0, 60, 0, 60) }):Play()
end)

ball.MouseButton1Click:Connect(function()
    if not isMinimized then return end
    TweenService:Create(ball, TweenInfo.new(0.3), { Size = UDim2.new(0, 0, 0, 0) }):Play()
    task.wait(0.2)
    ball.Visible = false
    main.Visible = true
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.Size = UDim2.new(0, 0, 0, 0)
    main.BackgroundTransparency = 1
    TweenService:Create(main, TweenInfo.new(0.4), { Size = UDim2.new(0, 630, 0, 430), Position = UDim2.new(0.5, -315, 0.5, -215), BackgroundTransparency = 0.1 }):Play()
    task.wait(0.4)
    isMinimized = false
end)

-- ==================== RAINBOW EFFECT ====================
local hue = 0
rainbowConnection = RunService.RenderStepped:Connect(function()
    if rainbowActive then
        hue = (hue + 0.003) % 1
        currentColor = Color3.fromHSV(hue, 1, 1)
        UIState.currentColor = currentColor
        mainStroke.Color = currentColor
        avatarStroke.Color = currentColor
        nomeGlow.Color = currentColor
        ball.TextColor3 = currentColor
        ballStroke.Color = currentColor
        contentFrame.ScrollBarImageColor3 = currentColor
        if espEnabled then
            for plr, highlight in pairs(espHighlights) do if highlight then highlight.FillColor = currentColor end end
            for plr, nametag in pairs(espNameTags) do if nametag and nametag:FindFirstChildOfClass("TextLabel") then nametag:FindFirstChildOfClass("TextLabel").TextColor3 = currentColor end end
        end
        if activeTab == "HOME" then homeBtn.BackgroundColor3 = currentColor
        elseif activeTab == "GAMES" then gamesBtn.BackgroundColor3 = currentColor
        elseif activeTab == "VISUAL" then visualBtn.BackgroundColor3 = currentColor
        elseif activeTab == "TK IGNORE" then telekillIgnoreBtn.BackgroundColor3 = currentColor
        elseif activeTab == "AIMBOT" then aimbotBtn.BackgroundColor3 = currentColor
        elseif activeTab == "SERVER" then serverBtn.BackgroundColor3 = currentColor
        elseif activeTab == "TELEPORT" then teleportBtn.BackgroundColor3 = currentColor
        elseif activeTab == "BRING" then bringBtn.BackgroundColor3 = currentColor
        elseif activeTab == "BANG" then bangBtn.BackgroundColor3 = currentColor
        elseif activeTab == "CALC" then calcBtn.BackgroundColor3 = currentColor
        elseif activeTab == "COLOR" then colorBtn.BackgroundColor3 = currentColor
        elseif activeTab == "ADMINS" then adminsBtn.BackgroundColor3 = currentColor end
    end
end)

UIS.JumpRequest:Connect(function()
    if infjump and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ==================== INICIAR ====================
loadHome()

task.wait(1)
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "Vitor Hub",
        Text = "Complete Edition - Executed!",
        Duration = 2
    })
end)
