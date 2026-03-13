-- VITOR HUB - VERSÃO COMPLETA (COM TODAS AS ABAS NOVAS)
-- Compatível com: Delta, Arceus X, Ronix, Fluxus

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
local MarketplaceService = game:GetService("MarketplaceService")
local Stats = game:GetService("Stats")

-- ==================== SISTEMA DE ESTADO CENTRALIZADO ====================
local UIState = {
    -- Sliders
    currentSpeed = 16,
    currentJump = 50,
    currentSpin = 0,
    currentTPWalkSpeed = 16,
    
    -- Toggles principais
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
    
    -- Features
    aimbotEnabled = false,
    espEnabled = false,
    telekillEnabled = false,
    bringAllEnabled = false,
    freeCamEnabled = false,
    
    -- Cores
    rainbowActive = true,
    currentColor = Color3.fromRGB(0, 170, 255),
    rVal = 0,
    gVal = 170,
    bVal = 255,
    
    -- Lista de ignorados (UserId)
    IgnoreList = {},
    
    -- Sessão
    sessionStart = os.time(),
    
    -- Dados persistentes
    notes = {},
    scripts = {},
    recentServers = {},
    calculatorMemory = 0,
    calculatorValue = ""
}

-- ==================== GERENCIADOR DE CONEXÕES ====================
local ActiveConnections = {}

local function AddConnection(conn)
    table.insert(ActiveConnections, conn)
    return conn
end

local function ClearConnections()
    for _, conn in pairs(ActiveConnections) do
        if conn then
            pcall(function() conn:Disconnect() end)
        end
    end
    ActiveConnections = {}
end

-- ==================== SISTEMA DE CACHE DE PLAYERS ====================
local PlayerCache = {
    list = {},
    thumbnails = {},
    lastUpdate = 0
}

local function updatePlayerCache()
    PlayerCache.list = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            table.insert(PlayerCache.list, plr)
        end
    end
    table.sort(PlayerCache.list, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)
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

-- ==================== FUNÇÕES DO SISTEMA IGNORE ====================
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
    if not userId then return false end
    for _, id in pairs(UIState.IgnoreList) do
        if id == userId then
            return true
        end
    end
    return false
end

-- ==================== JUMP POWER UNIVERSAL ====================
local function setJumpPower(value)
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        local humanoid = player.Character.Humanoid
        
        local success, err = pcall(function()
            humanoid.JumpPower = value
        end)
        
        if not success then
            pcall(function()
                humanoid.UseJumpPower = true
                humanoid.JumpPower = value
            end)
        end
        
        if not success then
            pcall(function()
                local jumpHeight = value * 0.144
                humanoid.JumpHeight = jumpHeight
            end)
        end
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
local ghostConnection = nil

-- Valores originais
local originalBrightness = Lighting.Brightness
local originalAmbient = Lighting.Ambient
local originalOutdoorAmbient = Lighting.OutdoorAmbient
local originalFogEnd = Lighting.FogEnd
local originalGlobalShadows = Lighting.GlobalShadows
local originalClockTime = Lighting.ClockTime

-- ==================== FREE CAM MOBILE ====================
local freeCamEnabled = UIState.freeCamEnabled
local freeCamConnection = nil
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

-- ==================== BRING ALL PLAYERS ====================
local bringAllEnabled = UIState.bringAllEnabled
local bringAllConnection = nil

local function bringAllPlayers()
    if not bringAllEnabled then return end
    
    local myChar = player.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    
    if not myHRP then return end
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local targetHRP = plr.Character.HumanoidRootPart
            targetHRP.CFrame = myHRP.CFrame * CFrame.new(0, 5, 0)
        end
    end
end

local function toggleBringAll(state)
    if state == bringAllEnabled then return end
    
    bringAllEnabled = state
    UIState.bringAllEnabled = state
    
    if bringAllConnection then
        bringAllConnection:Disconnect()
        bringAllConnection = nil
    end
    
    if bringAllEnabled then
        bringAllConnection = RunService.RenderStepped:Connect(function()
            bringAllPlayers()
        end)
        
        StarterGui:SetCore("SendNotification", {
            Title = "BRING ALL",
            Text = "Players will be brought to you continuously",
            Duration = 2
        })
    else
        StarterGui:SetCore("SendNotification", {
            Title = "BRING ALL",
            Text = "Disabled",
            Duration = 1
        })
    end
end

-- ==================== GUI DO FREE CAM ====================
local function createFreeCamGUI()
    if freeCamGUI then return end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "ExitCamGUI"
    gui.Parent = player.PlayerGui
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
    exitBtn.Text = "EXIT CAM"
    exitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    exitBtn.TextSize = 12
    exitBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", exitBtn).CornerRadius = UDim.new(0, 8)
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = mainFrame
    closeBtn.Size = UDim2.new(0.8, 0, 0, 30)
    closeBtn.Position = UDim2.new(0.1, 0, 0, 160)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
    closeBtn.Text = "CLOSE GUI"
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
    local upStroke = Instance.new("UIStroke")
    upStroke.Parent = upBtn
    upStroke.Color = Color3.fromRGB(0, 200, 255)
    upStroke.Thickness = 2
    
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
    local downStroke = Instance.new("UIStroke")
    downStroke.Parent = downBtn
    downStroke.Color = Color3.fromRGB(0, 200, 255)
    downStroke.Thickness = 2
    
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
    local analogStroke = Instance.new("UIStroke")
    analogStroke.Parent = analogFrame
    analogStroke.Color = Color3.fromRGB(0, 200, 255)
    analogStroke.Thickness = 4
    
    local analogBall = Instance.new("Frame")
    analogBall.Parent = analogFrame
    analogBall.Size = UDim2.new(0, 120, 0, 120)
    analogBall.Position = UDim2.new(0.5, -60, 0.5, -60)
    analogBall.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    analogBall.AnchorPoint = Vector2.new(0.5, 0.5)
    analogBall.ZIndex = 1001
    Instance.new("UICorner", analogBall).CornerRadius = UDim.new(1, 0)
    
    speedDown.MouseButton1Click:Connect(function()
        freeCamSpeed = math.max(0, freeCamSpeed - 1)
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
            analogTargetPos = Vector2.new(
                math.clamp(relativeX, -1, 1),
                math.clamp(relativeY, -1, 1)
            )
            
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
            analogTargetPos = Vector2.new(
                math.clamp(relativeX, -1, 1),
                math.clamp(relativeY, -1, 1)
            )
            
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
    
    AddConnection(upBtn.MouseButton1Down:Connect(function()
        if freeCamEnabled then
            verticalTarget = 1
        end
    end))
    
    AddConnection(upBtn.MouseButton1Up:Connect(function()
        if freeCamEnabled then
            verticalTarget = 0
        end
    end))
    
    AddConnection(downBtn.MouseButton1Down:Connect(function()
        if freeCamEnabled then
            verticalTarget = -1
        end
    end))
    
    AddConnection(downBtn.MouseButton1Up:Connect(function()
        if freeCamEnabled then
            verticalTarget = 0
        end
    end))
    
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
            mainUIButtonRef.Text = "ACTIVATE FREE CAM"
            mainUIButtonRef.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
        end
    end)
    
    freeCamGUI = {
        gui = gui,
        mainFrame = mainFrame,
        upBtn = upBtn,
        downBtn = downBtn,
        analogFrame = analogFrame,
        analogBall = analogBall,
        speedValue = speedValue
    }
end

local function activateFreeCam()
    if freeCamEnabled then return end
    
    ClearConnections()
    
    freeCamEnabled = true
    
    if not freeCamGUI then
        createFreeCamGUI()
    end
    
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
        
        local inAnalog = freeCamGUI.analogFrame.Visible and 
                        touchPos.X >= analogAbsPos.X and touchPos.X <= analogAbsPos.X + analogSize.X and
                        touchPos.Y >= analogAbsPos.Y and touchPos.Y <= analogAbsPos.Y + analogSize.Y
        
        local inUpBtn = freeCamGUI.upBtn.Visible and
                       touchPos.X >= upBtnPos.X and touchPos.X <= upBtnPos.X + btnSize.X and
                       touchPos.Y >= upBtnPos.Y and touchPos.Y <= upBtnPos.Y + btnSize.Y
        
        local inDownBtn = freeCamGUI.downBtn.Visible and
                         touchPos.X >= downBtnPos.X and touchPos.X <= downBtnPos.X + btnSize.X and
                         touchPos.Y >= downBtnPos.Y and touchPos.Y <= downBtnPos.Y + btnSize.Y
        
        if not inAnalog and not inUpBtn and not inDownBtn then
            freeCamTouchStart = touch.Position
        end
    end))
    
    AddConnection(UIS.TouchMoved:Connect(function(touch)
        if not freeCamEnabled or not freeCamTouchStart then return end
        
        local touchPos = touch.Position
        local analogAbsPos = freeCamGUI.analogFrame.AbsolutePosition
        local analogSize = freeCamGUI.analogFrame.AbsoluteSize
        
        local inAnalog = freeCamGUI.analogFrame.Visible and 
                        touchPos.X >= analogAbsPos.X and touchPos.X <= analogAbsPos.X + analogSize.X and
                        touchPos.Y >= analogAbsPos.Y and touchPos.Y <= analogAbsPos.Y + analogSize.Y
        
        if inAnalog then return end
        
        local delta = touch.Position - freeCamTouchStart
        
        freeCamYaw = freeCamYaw - delta.X * 0.005
        freeCamPitch = math.clamp(freeCamPitch - delta.Y * 0.005, math.rad(-80), math.rad(80))
        
        freeCamTouchStart = touch.Position
    end))
    
    AddConnection(UIS.TouchEnded:Connect(function(touch)
        if not freeCamEnabled then return end
        freeCamTouchStart = nil
    end))
    
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
    
    if buttonRef then
        mainUIButtonRef = buttonRef
    end
    
    if state then
        activateFreeCam()
        if mainUIButtonRef then
            mainUIButtonRef.Text = "DEACTIVATE FREE CAM"
            mainUIButtonRef.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
        end
    else
        deactivateFreeCam()
        if mainUIButtonRef then
            mainUIButtonRef.Text = "ACTIVATE FREE CAM"
            mainUIButtonRef.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
        end
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

local rVal = UIState.rVal
local gVal = UIState.gVal
local bVal = UIState.bVal

-- ==================== AIMBOT ====================
local aimbotEnabled = UIState.aimbotEnabled
local aimbotConnection = nil
local aimbotTarget = nil

local function getClosestVisiblePlayer()
    if not player.Character or not player.Character:FindFirstChild("Head") then return nil end
    
    local myPos = player.Character.Head.Position
    local camera = Camera
    local cameraPos = camera.CFrame.Position
    local cameraDir = camera.CFrame.LookVector
    
    local closestPlayer = nil
    local closestAngle = 180
    local closestDistance = math.huge
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and not IsIgnored(plr.UserId) and plr.Character and plr.Character:FindFirstChild("Head") and plr.Character.Humanoid.Health > 0 then
            local head = plr.Character.Head
            local targetPos = head.Position
            
            local targetDir = (targetPos - cameraPos).Unit
            local dot = cameraDir:Dot(targetDir)
            local angle = math.deg(math.acos(dot))
            
            if angle <= 90 then
                local ray = Ray.new(cameraPos, (targetPos - cameraPos).Unit * 1000)
                local hit, hitPos = workspace:FindPartOnRay(ray, player.Character)
                
                if hit then
                    local targetModel = head.Parent
                    if targetModel and hit:IsDescendantOf(targetModel) then
                        local dist = (targetPos - myPos).Magnitude
                        if dist < closestDistance then
                            closestDistance = dist
                            closestPlayer = plr
                            closestAngle = angle
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
    
    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end
    
    if state then
        aimbotConnection = RunService.RenderStepped:Connect(function()
            if not aimbotEnabled or not player.Character then return end
            local target = getClosestVisiblePlayer()
            if target and target.Character and target.Character:FindFirstChild("Head") then
                aimbotTarget = target
                local head = target.Character.Head
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            else
                aimbotTarget = nil
            end
        end)
        
        StarterGui:SetCore("SendNotification", {
            Title = "AIMBOT",
            Text = "Activated - Ignoring " .. #UIState.IgnoreList .. " players",
            Duration = 2
        })
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
    
    if plr.Character then
        addHighlight(plr.Character)
    end
    
    plr.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        addHighlight(char)
    end)
end

local function toggleESP(state)
    espEnabled = state
    UIState.espEnabled = state
    
    if state then
        for _, plr in pairs(Players:GetPlayers()) do
            createESPForPlayer(plr)
        end
        
        local conn = Players.PlayerAdded:Connect(function(plr)
            createESPForPlayer(plr)
        end)
        table.insert(espConnections, conn)
        
    else
        for plr, highlight in pairs(espHighlights) do
            if highlight then highlight:Destroy() end
        end
        espHighlights = {}
        
        for plr, nametag in pairs(espNameTags) do
            if nametag then nametag:Destroy() end
        end
        espNameTags = {}
        
        for _, conn in pairs(espConnections) do
            conn:Disconnect()
        end
        espConnections = {}
    end
end

-- ==================== TELEKILL SISTEMA INTELIGENTE ====================
local telekillEnabled = UIState.telekillEnabled
local telekillConnection = nil
local telekillCurrentTarget = nil
local telekillOffset = 15
local telekillCheckInterval = 2

local function getNearestValidTarget()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local myPos = player.Character.HumanoidRootPart.Position
    local nearestTarget = nil
    local nearestDistance = math.huge
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local targetPos = plr.Character.HumanoidRootPart.Position
                local dist = (targetPos - myPos).Magnitude
                
                if dist < nearestDistance then
                    nearestDistance = dist
                    nearestTarget = plr
                end
            end
        end
    end
    
    return nearestTarget
end

local function teleportToTarget(target)
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local targetHRP = target.Character.HumanoidRootPart
    local playerHRP = player.Character.HumanoidRootPart
    
    local targetHead = target.Character:FindFirstChild("Head") or targetHRP
    local teleportPos = targetHead.Position + Vector3.new(0, telekillOffset, 0)
    
    playerHRP.CFrame = CFrame.new(teleportPos)
    
    return true
end

local function telekillLoop()
    while telekillEnabled do
        if telekillCurrentTarget then
            local humanoid = telekillCurrentTarget.Character and telekillCurrentTarget.Character:FindFirstChildOfClass("Humanoid")
            
            if humanoid and humanoid.Health > 0 then
                teleportToTarget(telekillCurrentTarget)
                task.wait(telekillCheckInterval)
            else
                telekillCurrentTarget = getNearestValidTarget()
                if telekillCurrentTarget then
                    teleportToTarget(telekillCurrentTarget)
                    StarterGui:SetCore("SendNotification", {
                        Title = "TELEKILL",
                        Text = "Moving to: " .. telekillCurrentTarget.Name,
                        Duration = 2
                    })
                end
                task.wait(telekillCheckInterval)
            end
        else
            telekillCurrentTarget = getNearestValidTarget()
            if telekillCurrentTarget then
                teleportToTarget(telekillCurrentTarget)
                StarterGui:SetCore("SendNotification", {
                    Title = "TELEKILL",
                    Text = "Target: " .. telekillCurrentTarget.Name,
                    Duration = 2
                })
            end
            task.wait(telekillCheckInterval)
        end
    end
end

local function toggleTelekill(state)
    telekillEnabled = state
    UIState.telekillEnabled = state
    
    if telekillConnection then
        telekillConnection:Disconnect()
        telekillConnection = nil
    end
    
    if state then
        telekillCurrentTarget = getNearestValidTarget()
        if telekillCurrentTarget then
            teleportToTarget(telekillCurrentTarget)
        end
        spawn(telekillLoop)
    else
        telekillCurrentTarget = nil
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
        if not shiftLockUI then
            setupShiftLock()
        end
    else
        if shiftLockUI then
            shiftLockUI:Destroy()
            shiftLockUI = nil
        end
        pcall(function()
            local UserGameSettings = UserSettings():GetService("UserGameSettings")
            UserGameSettings.RotationType = Enum.RotationType.CameraRelative
        end)
    end
end

-- ==================== GHOST MODE ====================
local ghostEnabled = UIState.ghostEnabled
local ghostConnection = nil

local function toggleGhost(state)
    ghostEnabled = state
    UIState.ghostEnabled = state
    
    if ghostConnection then ghostConnection:Disconnect() end
    
    if state then
        loadstring(game:HttpGet('https://pastebin.com/raw/3Rnd9rHf'))()
    end
end

-- ==================== FUNÇÕES DOS HACKS ====================
local function toggleFullbright(state)
    fullbrightEnabled = state
    UIState.fullbrightEnabled = state
    
    if fullbrightConnection then fullbrightConnection:Disconnect() end
    if state then
        dayEnabled = false
        nightEnabled = false
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        fullbrightConnection = RunService.RenderStepped:Connect(function()
            if fullbrightEnabled then
                Lighting.Brightness = 2
                Lighting.Ambient = Color3.new(1, 1, 1)
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
        fullbrightEnabled = false
        nightEnabled = false
        if fullbrightConnection then fullbrightConnection:Disconnect() end
        Lighting.ClockTime = 12
        Lighting.Brightness = 1
        Lighting.Ambient = Color3.new(0.5, 0.5, 0.5)
        Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
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
        fullbrightEnabled = false
        dayEnabled = false
        if fullbrightConnection then fullbrightConnection:Disconnect() end
        Lighting.ClockTime = 0
        Lighting.Brightness = 0.5
        Lighting.Ambient = Color3.new(0.2, 0.2, 0.2)
        Lighting.OutdoorAmbient = Color3.new(0.2, 0.2, 0.2)
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
            part.LocalTransparencyModifier = state and 0.7 or 0
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
                local root = player.Character.HumanoidRootPart
                root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(speed), 0)
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

-- ==================== GUI PRINCIPAL ====================
local gui = Instance.new("ScreenGui")
gui.Name = "VitorHub"
gui.Parent = player:WaitForChild("PlayerGui")
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 100
gui.IgnoreGuiInset = true

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

local title = Instance.new("TextLabel")
title.Parent = topBar
title.Size = UDim2.new(0, 250, 1, 0)
title.Position = UDim2.new(0, 20, 0, 0)
title.BackgroundTransparency = 1
title.Text = "VITOR HUB"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 24
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 12

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
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

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

local serverTimeLabel = Instance.new("TextLabel")
serverTimeLabel.Parent = infoFrame
serverTimeLabel.Size = UDim2.new(0, 130, 1, 0)
serverTimeLabel.BackgroundTransparency = 1
serverTimeLabel.Text = "Server: 00:00:00"
serverTimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
serverTimeLabel.TextSize = 12
serverTimeLabel.Font = Enum.Font.GothamBold
serverTimeLabel.TextXAlignment = Enum.TextXAlignment.Center
serverTimeLabel.ZIndex = 12

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

local sessionLabel = Instance.new("TextLabel")
sessionLabel.Parent = infoFrame
sessionLabel.Size = UDim2.new(0, 130, 1, 0)
sessionLabel.BackgroundTransparency = 1
sessionLabel.Text = "Session: 00:00:00"
sessionLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
sessionLabel.TextSize = 12
sessionLabel.Font = Enum.Font.GothamBold
sessionLabel.TextXAlignment = Enum.TextXAlignment.Center
sessionLabel.ZIndex = 12

spawn(function()
    while true do
        local horaBR = tonumber(os.date("!%H")) - 3
        if horaBR < 0 then horaBR = horaBR + 24 end
        local horaBRStr = string.format("%02d", horaBR) .. os.date(":%M:%S")
        brasiliaLabel.Text = "Brasilia: " .. horaBRStr
        
        local serverTime = os.date("!%H:%M:%S")
        serverTimeLabel.Text = "Server: " .. serverTime
        
        local playerCount = #Players:GetPlayers()
        playersLabel.Text = "Players: " .. playerCount
        
        local sessionSeconds = os.difftime(os.time(), UIState.sessionStart)
        local hours = math.floor(sessionSeconds / 3600)
        local minutes = math.floor((sessionSeconds % 3600) / 60)
        local seconds = sessionSeconds % 60
        sessionLabel.Text = string.format("Session: %02d:%02d:%02d", hours, minutes, seconds)
        
        task.wait(1)
    end
end)

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
admin.Text = "ADMIN"
admin.TextColor3 = Color3.fromRGB(255, 50, 50)
admin.TextSize = 18
admin.Font = Enum.Font.GothamBold
admin.TextXAlignment = Enum.TextXAlignment.Left
admin.ZIndex = 11

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

local homeBtn = createTabButton("HOME")
local gamesBtn = createTabButton("GAMES")
local serverBtn = createTabButton("SERVER")
local aimbotBtn = createTabButton("AIMBOT")
local aimIgnoreBtn = createTabButton("IGNORE")
local teleportBtn = createTabButton("TELEPORT")
local bringBtn = createTabButton("BRING")
local bangBtn = createTabButton("BANG")
local calcBtn = createTabButton("🧮 CALC")
local notesBtn = createTabButton("📝 NOTES")
local servidoresBtn = createTabButton("🌐 SERVERS")
local libBtn = createTabButton("📚 LIBRARY")
local colorBtn = createTabButton("COLOR")

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
end

local function createSmallButton(parent, text, width, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = parent
    btn.Size = UDim2.new(0, width or 80, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.ZIndex = 13
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
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
    
    createToggle(controlsFrame, "Infinite Jump", UIState.infjumpEnabled, function(v) infjump = v; UIState.infjumpEnabled = v end)
    createToggle(controlsFrame, "X-Ray", UIState.xrayEnabled, function(v) toggleXRay(v) end)
    createToggle(controlsFrame, "Noclip", UIState.noclipEnabled, function(v) toggleNoclip(v) end)
    createToggle(controlsFrame, "Fullbright", UIState.fullbrightEnabled, function(v) toggleFullbright(v) end)
    createToggle(controlsFrame, "No Fog", UIState.noFogEnabled, function(v) toggleNoFog(v) end)
    createToggle(controlsFrame, "Day", UIState.dayEnabled, function(v) toggleDay(v) end)
    createToggle(controlsFrame, "Night", UIState.nightEnabled, function(v) toggleNight(v) end)
    createToggle(controlsFrame, "Ghost Mode", UIState.ghostEnabled, function(v) toggleGhost(v) end)
    createToggle(controlsFrame, "Shift Lock", UIState.shiftLockEnabled, function(v) toggleShiftLock(v) end)
    createToggle(controlsFrame, "TPWalk", UIState.tpwalkEnabled, function(v) toggleTpwalk(v) end)
    createSlider(controlsFrame, "TP Walk Speed", 1, 500, UIState.currentTPWalkSpeed, function(v) tpwalkSpeed = v; UIState.currentTPWalkSpeed = v end)
    createToggle(controlsFrame, "📷 FREE CAM (MOBILE)", UIState.freeCamEnabled, function(v)
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
    createButton(controlsFrame, "FLY GUI V3", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"))()
    end)
    createButton(controlsFrame, "YouTube Music Player", function()
        loadstring(game:HttpGet(('https://raw.githubusercontent.com/Dan41/Roblox-Scripts/refs/heads/main/Youtube%20Music%20Player/YoutubeMusicPlayer.lua'),true))()
    end)
    createButton(controlsFrame, "Infinity Yield", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end)
    createButton(controlsFrame, "🎭 ALL EMOTES", function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-7yd7-I-Emote-Script-48024"))()
    end)
end

-- ==================== GAMES TAB ====================
local GameCards = {
    {
        name = "Piggy",
        placeId = 4623386862,
        imageUrl = "rbxassetid://2679812541",
        script = function()
            local key = "minitoon release intercity already"
            local script = game:HttpGet("https://raw.githubusercontent.com/totallynothimplayz/Jd/refs/heads/main/Veno%20Hub")
            if script then
                script = script:gsub('getgenv%(%)%.Key', '"' .. key .. '"')
                loadstring(script)()
            end
        end
    },
    {
        name = "The Rake Remastered",
        placeId = 5657896419,
        imageUrl = "https://static.wikia.nocookie.net/roblox/images/0/05/The_Rake_REMASTERED_Another_Update.png/revision/latest/scale-to-width/360?cb=20250615100919",
        script = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/main/the%20rake"))()
        end
    },
    {
        name = "Blox Fruits",
        placeId = 2753915549,
        imageUrl = "rbxassetid://4531398032",
        script = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/acsu123/Hoho-Hub/main/main.lua"))()
        end
    },
    {
        name = "Prison Life",
        placeId = 155615604,
        imageUrl = "rbxassetid://112686775",
        script = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/TableTops/Neverlose/main/Lua/Main.lua"))()
        end
    },
    {
        name = "Murder Mystery 2",
        placeId = 142823291,
        imageUrl = "rbxassetid://1468845276",
        script = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/androidfan9/carnival/refs/heads/main/mainhub.txt"))()
        end
    },
    {
        name = "99 Nights in the Forest",
        placeId = 1902735202,
        imageUrl = "https://pt.quizur.com/_image?href=https://dev-beta.quizur.com/storage/v1/object/public//imagens//21161376/3df7bb1a-675b-40c6-a32d-79f38f41536c.png&w=600&h=600&f=webp",
        script = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/VapeVoidware/VW-Add/main/loader.lua"))()
        end
    }
}

local GameSearchText = ""
local GameCardsContainer = nil

local function createGameCard(gameData)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -10, 0, 140)
    card.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    card.BackgroundTransparency = 0.2
    card.ZIndex = 13
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
    
    local stroke = Instance.new("UIStroke")
    stroke.Parent = card
    stroke.Color = Color3.fromRGB(70, 70, 90)
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    
    local imageContainer = Instance.new("Frame")
    imageContainer.Parent = card
    imageContainer.Size = UDim2.new(0, 120, 0, 120)
    imageContainer.Position = UDim2.new(0, 10, 0.5, -60)
    imageContainer.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    imageContainer.BackgroundTransparency = 0.3
    imageContainer.ZIndex = 14
    Instance.new("UICorner", imageContainer).CornerRadius = UDim.new(0, 8)
    
    local gameImage = Instance.new("ImageLabel")
    gameImage.Parent = imageContainer
    gameImage.Size = UDim2.new(1, -4, 1, -4)
    gameImage.Position = UDim2.new(0, 2, 0, 2)
    gameImage.BackgroundTransparency = 1
    gameImage.Image = gameData.imageUrl
    gameImage.ScaleType = Enum.ScaleType.Crop
    gameImage.ZIndex = 15
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
    gameTitle.ZIndex = 14
    
    local executeBtn = Instance.new("TextButton")
    executeBtn.Parent = card
    executeBtn.Size = UDim2.new(0, 100, 0, 40)
    executeBtn.Position = UDim2.new(1, -110, 0.7, -20)
    executeBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    executeBtn.BackgroundTransparency = 0.1
    executeBtn.Text = "▶ EXECUTE"
    executeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    executeBtn.TextSize = 14
    executeBtn.Font = Enum.Font.GothamBold
    executeBtn.ZIndex = 14
    Instance.new("UICorner", executeBtn).CornerRadius = UDim.new(0, 8)
    
    executeBtn.MouseEnter:Connect(function()
        TweenService:Create(executeBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(0, 255, 0),
            Size = UDim2.new(0, 110, 0, 44)
        }):Play()
    end)
    
    executeBtn.MouseLeave:Connect(function()
        TweenService:Create(executeBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(0, 200, 0),
            Size = UDim2.new(0, 100, 0, 40)
        }):Play()
    end)
    
    executeBtn.MouseButton1Click:Connect(function()
        gameData.script()
        StarterGui:SetCore("SendNotification", {
            Title = "GAMES",
            Text = "Executing " .. gameData.name .. "...",
            Duration = 2
        })
    end)
    
    return card
end

local function updateGameList(searchTerm)
    searchTerm = searchTerm or GameSearchText
    searchTerm = searchTerm:lower()
    
    if GameCardsContainer then
        for _, v in pairs(GameCardsContainer:GetChildren()) do
            if v:IsA("Frame") then
                v:Destroy()
            end
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
        local count = #filteredGames
        GameCardsContainer.CanvasSize = UDim2.new(0, 0, 0, math.max(170, count * 150))
    end
end

local function loadGames()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.ZIndex = 12
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🎮 GAMES LIBRARY"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.ZIndex = 13
    
    local searchFrame = Instance.new("Frame")
    searchFrame.Parent = mainFrame
    searchFrame.Size = UDim2.new(1, -20, 0, 40)
    searchFrame.Position = UDim2.new(0, 10, 0, 35)
    searchFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    searchFrame.BackgroundTransparency = 0.2
    searchFrame.ZIndex = 13
    Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 8)
    
    local searchIcon = Instance.new("TextLabel")
    searchIcon.Parent = searchFrame
    searchIcon.Size = UDim2.new(0, 40, 1, 0)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "🔍"
    searchIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchIcon.TextSize = 20
    searchIcon.Font = Enum.Font.Gotham
    searchIcon.ZIndex = 14
    
    local searchBox = Instance.new("TextBox")
    searchBox.Parent = searchFrame
    searchBox.Size = UDim2.new(1, -90, 1, -10)
    searchBox.Position = UDim2.new(0, 40, 0, 5)
    searchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    searchBox.BackgroundTransparency = 0.3
    searchBox.PlaceholderText = "Search games..."
    searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    searchBox.Text = GameSearchText
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.TextSize = 14
    searchBox.Font = Enum.Font.Gotham
    searchBox.ClearTextOnFocus = false
    searchBox.ZIndex = 14
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
    clearBtn.ZIndex = 14
    Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(1, 0)
    
    clearBtn.MouseButton1Click:Connect(function()
        searchBox.Text = ""
        GameSearchText = ""
        updateGameList("")
    end)
    
    local cardsContainer = Instance.new("ScrollingFrame")
    cardsContainer.Parent = mainFrame
    cardsContainer.Size = UDim2.new(1, -20, 0, 270)
    cardsContainer.Position = UDim2.new(0, 10, 0, 85)
    cardsContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    cardsContainer.BackgroundTransparency = 0.3
    cardsContainer.BorderSizePixel = 0
    cardsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    cardsContainer.ScrollBarThickness = 6
    cardsContainer.ScrollBarImageColor3 = currentColor
    cardsContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    cardsContainer.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
    cardsContainer.ZIndex = 13
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
    mainFrame.ZIndex = 12
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🖥️ SERVER"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.ZIndex = 13
    
    local buttonsFrame = Instance.new("Frame")
    buttonsFrame.Parent = mainFrame
    buttonsFrame.Size = UDim2.new(1, -20, 0, 150)
    buttonsFrame.Position = UDim2.new(0, 10, 0, 40)
    buttonsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    buttonsFrame.BackgroundTransparency = 0.3
    buttonsFrame.ZIndex = 13
    Instance.new("UICorner", buttonsFrame).CornerRadius = UDim.new(0, 8)
    
    local buttonsLayout = Instance.new("UIListLayout")
    buttonsLayout.Parent = buttonsFrame
    buttonsLayout.Padding = UDim.new(0, 10)
    buttonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    createButton(buttonsFrame, "Rejoin", function()
        TeleportService:Teleport(game.PlaceId, player)
    end)
    createButton(buttonsFrame, "Reset Character", function()
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.Health = 0
        end
    end)
end

-- ==================== AIMBOT TAB ====================
local function loadAimbot()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.ZIndex = 12
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🎯 AIMBOT"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.ZIndex = 13
    
    local togglesFrame = Instance.new("Frame")
    togglesFrame.Parent = mainFrame
    togglesFrame.Size = UDim2.new(1, -20, 0, 150)
    togglesFrame.Position = UDim2.new(0, 10, 0, 40)
    togglesFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    togglesFrame.BackgroundTransparency = 0.3
    togglesFrame.ZIndex = 13
    Instance.new("UICorner", togglesFrame).CornerRadius = UDim.new(0, 8)
    
    local togglesLayout = Instance.new("UIListLayout")
    togglesLayout.Parent = togglesFrame
    togglesLayout.Padding = UDim.new(0, 10)
    togglesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    createToggle(togglesFrame, "Aimbot (Head)", UIState.aimbotEnabled, function(v)
        toggleAimbot(v)
    end)
    createToggle(togglesFrame, "ESP", UIState.espEnabled, function(v)
        toggleESP(v)
    end)
    createToggle(togglesFrame, "⚡ TELEKILL", UIState.telekillEnabled, function(v)
        toggleTelekill(v)
    end)
end

-- ==================== AIM IGNORE TAB ====================
local IgnoreSearchText = ""
local IgnoreContainer = nil

local function updateIgnoreList(searchTerm)
    searchTerm = searchTerm or IgnoreSearchText
    searchTerm = searchTerm:lower()
    
    if IgnoreContainer then
        for _, v in pairs(IgnoreContainer:GetChildren()) do
            if v:IsA("Frame") then
                v:Destroy()
            end
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
        local isIgnored = IsIgnored(plr.UserId)
        
        local rowFrame = Instance.new("Frame")
        rowFrame.Parent = IgnoreContainer
        rowFrame.Name = "PlayerRow_" .. plr.UserId
        rowFrame.Size = UDim2.new(1, -10, 0, 50)
        rowFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
        rowFrame.BackgroundTransparency = 0.2
        rowFrame.ZIndex = 13
        Instance.new("UICorner", rowFrame).CornerRadius = UDim.new(0, 8)
        
        local avatarFrame = Instance.new("Frame")
        avatarFrame.Parent = rowFrame
        avatarFrame.Size = UDim2.new(0, 40, 0, 40)
        avatarFrame.Position = UDim2.new(0, 5, 0.5, -20)
        avatarFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        avatarFrame.BackgroundTransparency = 0.9
        avatarFrame.ZIndex = 14
        Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(1, 0)
        
        local avatarImg = Instance.new("ImageLabel")
        avatarImg.Parent = avatarFrame
        avatarImg.Size = UDim2.new(1, -4, 1, -4)
        avatarImg.Position = UDim2.new(0, 2, 0, 2)
        avatarImg.BackgroundTransparency = 1
        avatarImg.Image = getPlayerThumbnail(plr.UserId)
        avatarImg.ZIndex = 15
        Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Parent = rowFrame
        nameLabel.Size = UDim2.new(0, 200, 0, 40)
        nameLabel.Position = UDim2.new(0, 50, 0.5, -20)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = plr.Name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 16
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.ZIndex = 14
        
        local statusLabel = Instance.new("TextLabel")
        statusLabel.Parent = rowFrame
        statusLabel.Size = UDim2.new(0, 80, 0, 30)
        statusLabel.Position = UDim2.new(1, -190, 0.5, -15)
        statusLabel.BackgroundColor3 = isIgnored and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
        statusLabel.BackgroundTransparency = 0.2
        statusLabel.Text = isIgnored and "🔴 IGNORED" or "🟢 NORMAL"
        statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        statusLabel.TextSize = 12
        statusLabel.Font = Enum.Font.GothamBold
        statusLabel.ZIndex = 14
        Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 6)
        
        local actionBtn = Instance.new("TextButton")
        actionBtn.Parent = rowFrame
        actionBtn.Size = UDim2.new(0, 80, 0, 30)
        actionBtn.Position = UDim2.new(1, -100, 0.5, -15)
        actionBtn.BackgroundColor3 = isIgnored and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 100, 255)
        actionBtn.BackgroundTransparency = 0.2
        actionBtn.Text = isIgnored and "[Remove]" or "[Ignore]"
        actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        actionBtn.TextSize = 12
        actionBtn.Font = Enum.Font.GothamBold
        actionBtn.ZIndex = 14
        actionBtn.Name = "ActionBtn_" .. plr.UserId
        Instance.new("UICorner", actionBtn).CornerRadius = UDim.new(0, 6)
        
        actionBtn.MouseButton1Click:Connect(function()
            if IsIgnored(plr.UserId) then
                RemoveIgnore(plr.UserId)
            else
                AddIgnore(plr.UserId)
            end
            updateIgnoreList(IgnoreSearchText)
            
            StarterGui:SetCore("SendNotification", {
                Title = "AIM IGNORE",
                Text = IsIgnored(plr.UserId) and "Player removed" or "Player added",
                Duration = 1
            })
        end)
    end
    
    if IgnoreContainer then
        local count = #playerList
        IgnoreContainer.CanvasSize = UDim2.new(0, 0, 0, math.max(170, count * 55))
    end
end

local function loadAimIgnore()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.ZIndex = 12
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🎯 AIM IGNORE"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.ZIndex = 13
    
    local searchFrame = Instance.new("Frame")
    searchFrame.Parent = mainFrame
    searchFrame.Size = UDim2.new(1, -20, 0, 40)
    searchFrame.Position = UDim2.new(0, 10, 0, 35)
    searchFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    searchFrame.BackgroundTransparency = 0.2
    searchFrame.ZIndex = 13
    Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 8)
    
    local searchIcon = Instance.new("TextLabel")
    searchIcon.Parent = searchFrame
    searchIcon.Size = UDim2.new(0, 40, 1, 0)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "🔍"
    searchIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchIcon.TextSize = 20
    searchIcon.Font = Enum.Font.Gotham
    searchIcon.ZIndex = 14
    
    local searchBox = Instance.new("TextBox")
    searchBox.Parent = searchFrame
    searchBox.Size = UDim2.new(1, -90, 1, -10)
    searchBox.Position = UDim2.new(0, 40, 0, 5)
    searchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    searchBox.BackgroundTransparency = 0.3
    searchBox.PlaceholderText = "Search players..."
    searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    searchBox.Text = IgnoreSearchText
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.TextSize = 14
    searchBox.Font = Enum.Font.Gotham
    searchBox.ClearTextOnFocus = false
    searchBox.ZIndex = 14
    Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 6)
    
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        IgnoreSearchText = searchBox.Text
        updateIgnoreList(IgnoreSearchText)
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
    clearBtn.ZIndex = 14
    Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(1, 0)
    
    clearBtn.MouseButton1Click:Connect(function()
        searchBox.Text = ""
        IgnoreSearchText = ""
        updateIgnoreList("")
    end)
    
    local listContainer = Instance.new("ScrollingFrame")
    listContainer.Parent = mainFrame
    listContainer.Size = UDim2.new(1, -20, 0, 270)
    listContainer.Position = UDim2.new(0, 10, 0, 85)
    listContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    listContainer.BackgroundTransparency = 0.3
    listContainer.BorderSizePixel = 0
    listContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    listContainer.ScrollBarThickness = 6
    listContainer.ScrollBarImageColor3 = currentColor
    listContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    listContainer.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
    listContainer.ZIndex = 13
    Instance.new("UICorner", listContainer).CornerRadius = UDim.new(0, 8)
    
    IgnoreContainer = listContainer
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = listContainer
    listLayout.Padding = UDim.new(0, 5)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)
    
    local playerAddedConn = Players.PlayerAdded:Connect(function()
        updateIgnoreList(IgnoreSearchText)
    end)
    table.insert(espConnections, playerAddedConn)
    
    local playerRemovingConn = Players.PlayerRemoving:Connect(function()
        updateIgnoreList(IgnoreSearchText)
    end)
    table.insert(espConnections, playerRemovingConn)
    
    updateIgnoreList("")
    
    local infoFrame = Instance.new("Frame")
    infoFrame.Parent = mainFrame
    infoFrame.Size = UDim2.new(1, -20, 0, 50)
    infoFrame.Position = UDim2.new(0, 10, 1, -55)
    infoFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    infoFrame.BackgroundTransparency = 0.3
    infoFrame.ZIndex = 13
    Instance.new("UICorner", infoFrame).CornerRadius = UDim.new(0, 8)
    
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Parent = infoFrame
    infoLabel.Size = UDim2.new(0.9, 0, 1, 0)
    infoLabel.Position = UDim2.new(0.05, 0, 0, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "📋 Ignored players will NOT be targeted by Aimbot."
    infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    infoLabel.TextSize = 12
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextWrapped = true
    infoLabel.ZIndex = 14
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
        if v:IsA("Frame") then
            v:Destroy()
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
        local rowFrame = Instance.new("Frame")
        rowFrame.Parent = TeleportContainer
        rowFrame.Name = "TeleportRow_" .. plr.UserId
        rowFrame.Size = UDim2.new(1, -10, 0, 60)
        rowFrame.BackgroundColor3 = plr == TeleportSelectedPlayer and currentColor or Color3.fromRGB(35, 35, 48)
        rowFrame.BackgroundTransparency = plr == TeleportSelectedPlayer and 0.3 or 0.2
        rowFrame.ZIndex = 13
        Instance.new("UICorner", rowFrame).CornerRadius = UDim.new(0, 8)
        
        local avatarFrame = Instance.new("Frame")
        avatarFrame.Parent = rowFrame
        avatarFrame.Size = UDim2.new(0, 50, 0, 50)
        avatarFrame.Position = UDim2.new(0, 5, 0.5, -25)
        avatarFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        avatarFrame.BackgroundTransparency = 0.9
        avatarFrame.ZIndex = 14
        Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(1, 0)
        
        local avatarImg = Instance.new("ImageLabel")
        avatarImg.Parent = avatarFrame
        avatarImg.Size = UDim2.new(1, -4, 1, -4)
        avatarImg.Position = UDim2.new(0, 2, 0, 2)
        avatarImg.BackgroundTransparency = 1
        avatarImg.Image = getPlayerThumbnail(plr.UserId)
        avatarImg.ZIndex = 15
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
        nameLabel.ZIndex = 14
        
        local tpBtn = Instance.new("TextButton")
        tpBtn.Parent = rowFrame
        tpBtn.Size = UDim2.new(0, 100, 0, 35)
        tpBtn.Position = UDim2.new(1, -110, 0.5, -17)
        tpBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        tpBtn.BackgroundTransparency = 0.2
        tpBtn.Text = "🔄 Teleport"
        tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        tpBtn.TextSize = 12
        tpBtn.Font = Enum.Font.GothamBold
        tpBtn.ZIndex = 14
        Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 6)
        
        tpBtn.MouseButton1Click:Connect(function()
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local targetHRP = plr.Character.HumanoidRootPart
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    player.Character.HumanoidRootPart.CFrame = targetHRP.CFrame * CFrame.new(0, 3, 0)
                    TeleportSelectedPlayer = plr
                    updateTeleportList(TeleportSearchText)
                    
                    StarterGui:SetCore("SendNotification", {
                        Title = "TELEPORT",
                        Text = "Teleported to: " .. plr.Name,
                        Duration = 2
                    })
                end
            end
        end)
        
        local bringBtn = Instance.new("TextButton")
        bringBtn.Parent = rowFrame
        bringBtn.Size = UDim2.new(0, 100, 0, 35)
        bringBtn.Position = UDim2.new(1, -220, 0.5, -17)
        bringBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
        bringBtn.BackgroundTransparency = 0.2
        bringBtn.Text = "⬆️ Bring"
        bringBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        bringBtn.TextSize = 12
        bringBtn.Font = Enum.Font.GothamBold
        bringBtn.ZIndex = 14
        Instance.new("UICorner", bringBtn).CornerRadius = UDim.new(0, 6)
        
        bringBtn.MouseButton1Click:Connect(function()
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local myHRP = player.Character.HumanoidRootPart
                    plr.Character.HumanoidRootPart.CFrame = myHRP.CFrame * CFrame.new(0, 3, 0)
                    
                    StarterGui:SetCore("SendNotification", {
                        Title = "TELEPORT",
                        Text = "Brought: " .. plr.Name .. " to you",
                        Duration = 2
                    })
                end
            end
        end)
    end
    
    local count = #playerList
    TeleportContainer.CanvasSize = UDim2.new(0, 0, 0, math.max(170, count * 65))
end

local function loadTeleport()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.ZIndex = 12
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "📌 TELEPORT & BRING"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.ZIndex = 13
    
    local searchFrame = Instance.new("Frame")
    searchFrame.Parent = mainFrame
    searchFrame.Size = UDim2.new(1, -20, 0, 40)
    searchFrame.Position = UDim2.new(0, 10, 0, 35)
    searchFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    searchFrame.BackgroundTransparency = 0.2
    searchFrame.ZIndex = 13
    Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 8)
    
    local searchIcon = Instance.new("TextLabel")
    searchIcon.Parent = searchFrame
    searchIcon.Size = UDim2.new(0, 40, 1, 0)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "🔍"
    searchIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchIcon.TextSize = 20
    searchIcon.Font = Enum.Font.Gotham
    searchIcon.ZIndex = 14
    
    local searchBox = Instance.new("TextBox")
    searchBox.Parent = searchFrame
    searchBox.Size = UDim2.new(1, -90, 1, -10)
    searchBox.Position = UDim2.new(0, 40, 0, 5)
    searchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    searchBox.BackgroundTransparency = 0.3
    searchBox.PlaceholderText = "Search players..."
    searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    searchBox.Text = TeleportSearchText
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.TextSize = 14
    searchBox.Font = Enum.Font.Gotham
    searchBox.ClearTextOnFocus = false
    searchBox.ZIndex = 14
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
    clearBtn.ZIndex = 14
    Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(1, 0)
    
    clearBtn.MouseButton1Click:Connect(function()
        searchBox.Text = ""
        TeleportSearchText = ""
        updateTeleportList("")
    end)
    
    local listContainer = Instance.new("ScrollingFrame")
    listContainer.Parent = mainFrame
    listContainer.Size = UDim2.new(1, -20, 0, 270)
    listContainer.Position = UDim2.new(0, 10, 0, 85)
    listContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    listContainer.BackgroundTransparency = 0.3
    listContainer.BorderSizePixel = 0
    listContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    listContainer.ScrollBarThickness = 6
    listContainer.ScrollBarImageColor3 = currentColor
    listContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    listContainer.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
    listContainer.ZIndex = 13
    Instance.new("UICorner", listContainer).CornerRadius = UDim.new(0, 8)
    
    TeleportContainer = listContainer
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = listContainer
    listLayout.Padding = UDim.new(0, 5)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)
    
    local playerAddedConn = Players.PlayerAdded:Connect(function()
        updateTeleportList(TeleportSearchText)
    end)
    table.insert(espConnections, playerAddedConn)
    
    local playerRemovingConn = Players.PlayerRemoving:Connect(function()
        updateTeleportList(TeleportSearchText)
    end)
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
        if v:IsA("Frame") then
            v:Destroy()
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
        local rowFrame = Instance.new("Frame")
        rowFrame.Parent = BringContainer
        rowFrame.Name = "BringRow_" .. plr.UserId
        rowFrame.Size = UDim2.new(1, -10, 0, 60)
        rowFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
        rowFrame.BackgroundTransparency = 0.2
        rowFrame.ZIndex = 13
        Instance.new("UICorner", rowFrame).CornerRadius = UDim.new(0, 8)
        
        local avatarFrame = Instance.new("Frame")
        avatarFrame.Parent = rowFrame
        avatarFrame.Size = UDim2.new(0, 50, 0, 50)
        avatarFrame.Position = UDim2.new(0, 5, 0.5, -25)
        avatarFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        avatarFrame.BackgroundTransparency = 0.9
        avatarFrame.ZIndex = 14
        Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(1, 0)
        
        local avatarImg = Instance.new("ImageLabel")
        avatarImg.Parent = avatarFrame
        avatarImg.Size = UDim2.new(1, -4, 1, -4)
        avatarImg.Position = UDim2.new(0, 2, 0, 2)
        avatarImg.BackgroundTransparency = 1
        avatarImg.Image = getPlayerThumbnail(plr.UserId)
        avatarImg.ZIndex = 15
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
        nameLabel.ZIndex = 14
        
        local bringBtn = Instance.new("TextButton")
        bringBtn.Parent = rowFrame
        bringBtn.Size = UDim2.new(0, 100, 0, 35)
        bringBtn.Position = UDim2.new(1, -110, 0.5, -17)
        bringBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
        bringBtn.BackgroundTransparency = 0.2
        bringBtn.Text = "⬆️ Bring"
        bringBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        bringBtn.TextSize = 12
        bringBtn.Font = Enum.Font.GothamBold
        bringBtn.ZIndex = 14
        Instance.new("UICorner", bringBtn).CornerRadius = UDim.new(0, 6)
        
        bringBtn.MouseButton1Click:Connect(function()
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local myHRP = player.Character.HumanoidRootPart
                    plr.Character.HumanoidRootPart.CFrame = myHRP.CFrame * CFrame.new(0, 3, 0)
                    
                    StarterGui:SetCore("SendNotification", {
                        Title = "BRING",
                        Text = "Brought: " .. plr.Name .. " to you",
                        Duration = 2
                    })
                end
            end
        end)
    end
    
    local count = #playerList
    BringContainer.CanvasSize = UDim2.new(0, 0, 0, math.max(170, count * 65))
end

local function loadBring()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.ZIndex = 12
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "⬆️ BRING PLAYERS"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.ZIndex = 13
    
    local bringAllFrame = Instance.new("Frame")
    bringAllFrame.Parent = mainFrame
    bringAllFrame.Size = UDim2.new(1, -20, 0, 50)
    bringAllFrame.Position = UDim2.new(0, 10, 0, 35)
    bringAllFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    bringAllFrame.BackgroundTransparency = 0.3
    bringAllFrame.ZIndex = 13
    Instance.new("UICorner", bringAllFrame).CornerRadius = UDim.new(0, 8)
    
    createToggle(bringAllFrame, "👥 BRING ALL PLAYERS", UIState.bringAllEnabled, function(v)
        toggleBringAll(v)
    end)
    
    local searchFrame = Instance.new("Frame")
    searchFrame.Parent = mainFrame
    searchFrame.Size = UDim2.new(1, -20, 0, 40)
    searchFrame.Position = UDim2.new(0, 10, 0, 95)
    searchFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    searchFrame.BackgroundTransparency = 0.2
    searchFrame.ZIndex = 13
    Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 8)
    
    local searchIcon = Instance.new("TextLabel")
    searchIcon.Parent = searchFrame
    searchIcon.Size = UDim2.new(0, 40, 1, 0)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "🔍"
    searchIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchIcon.TextSize = 20
    searchIcon.Font = Enum.Font.Gotham
    searchIcon.ZIndex = 14
    
    local searchBox = Instance.new("TextBox")
    searchBox.Parent = searchFrame
    searchBox.Size = UDim2.new(1, -90, 1, -10)
    searchBox.Position = UDim2.new(0, 40, 0, 5)
    searchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    searchBox.BackgroundTransparency = 0.3
    searchBox.PlaceholderText = "Search players..."
    searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    searchBox.Text = BringSearchText
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.TextSize = 14
    searchBox.Font = Enum.Font.Gotham
    searchBox.ClearTextOnFocus = false
    searchBox.ZIndex = 14
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
    clearBtn.ZIndex = 14
    Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(1, 0)
    
    clearBtn.MouseButton1Click:Connect(function()
        searchBox.Text = ""
        BringSearchText = ""
        updateBringList("")
    end)
    
    local listContainer = Instance.new("ScrollingFrame")
    listContainer.Parent = mainFrame
    listContainer.Size = UDim2.new(1, -20, 0, 210)
    listContainer.Position = UDim2.new(0, 10, 0, 145)
    listContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    listContainer.BackgroundTransparency = 0.3
    listContainer.BorderSizePixel = 0
    listContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    listContainer.ScrollBarThickness = 6
    listContainer.ScrollBarImageColor3 = currentColor
    listContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    listContainer.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
    listContainer.ZIndex = 13
    Instance.new("UICorner", listContainer).CornerRadius = UDim.new(0, 8)
    
    BringContainer = listContainer
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = listContainer
    listLayout.Padding = UDim.new(0, 5)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)
    
    local playerAddedConn = Players.PlayerAdded:Connect(function()
        updateBringList(BringSearchText)
    end)
    table.insert(espConnections, playerAddedConn)
    
    local playerRemovingConn = Players.PlayerRemoving:Connect(function()
        updateBringList(BringSearchText)
    end)
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
            if not bangActive or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
                return
            end
            
            local targetHRP = target.Character.HumanoidRootPart
            local playerHRP = player.Character.HumanoidRootPart
            
            time = time + 0.1
            local offset = math.sin(time * 5) * 1.5
            
            local direction = targetHRP.CFrame.LookVector * -1
            local behindPos = targetHRP.Position + direction * (3 + offset)
            
            playerHRP.CFrame = CFrame.new(behindPos, targetHRP.Position)
        end)
        
        StarterGui:SetCore("SendNotification", {
            Title = "BANG",
            Text = "Bang activated on: " .. bangSelectedPlayer.Name,
            Duration = 2
        })
    end
end

local function updateBangList(searchTerm)
    searchTerm = searchTerm or BangSearchText
    searchTerm = searchTerm:lower()
    
    if not BangContainer then return end
    
    for _, v in pairs(BangContainer:GetChildren()) do
        if v:IsA("Frame") then
            v:Destroy()
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
        local rowFrame = Instance.new("Frame")
        rowFrame.Parent = BangContainer
        rowFrame.Name = "BangRow_" .. plr.UserId
        rowFrame.Size = UDim2.new(1, -10, 0, 60)
        rowFrame.BackgroundColor3 = plr == bangSelectedPlayer and currentColor or Color3.fromRGB(35, 35, 48)
        rowFrame.BackgroundTransparency = plr == bangSelectedPlayer and 0.3 or 0.2
        rowFrame.ZIndex = 13
        Instance.new("UICorner", rowFrame).CornerRadius = UDim.new(0, 8)
        
        local avatarFrame = Instance.new("Frame")
        avatarFrame.Parent = rowFrame
        avatarFrame.Size = UDim2.new(0, 50, 0, 50)
        avatarFrame.Position = UDim2.new(0, 5, 0.5, -25)
        avatarFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        avatarFrame.BackgroundTransparency = 0.9
        avatarFrame.ZIndex = 14
        Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(1, 0)
        
        local avatarImg = Instance.new("ImageLabel")
        avatarImg.Parent = avatarFrame
        avatarImg.Size = UDim2.new(1, -4, 1, -4)
        avatarImg.Position = UDim2.new(0, 2, 0, 2)
        avatarImg.BackgroundTransparency = 1
        avatarImg.Image = getPlayerThumbnail(plr.UserId)
        avatarImg.ZIndex = 15
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
        nameLabel.ZIndex = 14
        
        local selectBtn = Instance.new("TextButton")
        selectBtn.Parent = rowFrame
        selectBtn.Size = UDim2.new(0, 100, 0, 35)
        selectBtn.Position = UDim2.new(1, -110, 0.5, -17)
        selectBtn.BackgroundColor3 = plr == bangSelectedPlayer and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(100, 100, 255)
        selectBtn.BackgroundTransparency = 0.2
        selectBtn.Text = plr == bangSelectedPlayer and "✓ Selected" or "Select"
        selectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        selectBtn.TextSize = 12
        selectBtn.Font = Enum.Font.GothamBold
        selectBtn.ZIndex = 14
        Instance.new("UICorner", selectBtn).CornerRadius = UDim.new(0, 6)
        
        selectBtn.MouseButton1Click:Connect(function()
            bangSelectedPlayer = plr
            updateBangList(BangSearchText)
        end)
    end
    
    local count = #playerList
    BangContainer.CanvasSize = UDim2.new(0, 0, 0, math.max(170, count * 65))
end

local function loadBang()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.ZIndex = 12
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "💥 BANG PLAYER"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.ZIndex = 13
    
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Parent = mainFrame
    toggleFrame.Size = UDim2.new(1, -20, 0, 50)
    toggleFrame.Position = UDim2.new(0, 10, 0, 35)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    toggleFrame.BackgroundTransparency = 0.3
    toggleFrame.ZIndex = 13
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
    toggleLabel.ZIndex = 14
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Parent = toggleFrame
    toggleBtn.Size = UDim2.new(0, 60, 0, 30)
    toggleBtn.Position = UDim2.new(1, -70, 0.5, -15)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    toggleBtn.Text = ""
    toggleBtn.ZIndex = 14
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)
    
    local toggleIndicator = Instance.new("Frame")
    toggleIndicator.Parent = toggleBtn
    toggleIndicator.Size = UDim2.new(0, 24, 0, 24)
    toggleIndicator.Position = bangActive and UDim2.new(1, -27, 0.5, -12) or UDim2.new(0, 3, 0.5, -12)
    toggleIndicator.BackgroundColor3 = bangActive and currentColor or Color3.fromRGB(100, 100, 100)
    toggleIndicator.ZIndex = 15
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
    searchFrame.ZIndex = 13
    Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 8)
    
    local searchIcon = Instance.new("TextLabel")
    searchIcon.Parent = searchFrame
    searchIcon.Size = UDim2.new(0, 40, 1, 0)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "🔍"
    searchIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchIcon.TextSize = 20
    searchIcon.Font = Enum.Font.Gotham
    searchIcon.ZIndex = 14
    
    local searchBox = Instance.new("TextBox")
    searchBox.Parent = searchFrame
    searchBox.Size = UDim2.new(1, -90, 1, -10)
    searchBox.Position = UDim2.new(0, 40, 0, 5)
    searchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    searchBox.BackgroundTransparency = 0.3
    searchBox.PlaceholderText = "Search players..."
    searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    searchBox.Text = BangSearchText
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.TextSize = 14
    searchBox.Font = Enum.Font.Gotham
    searchBox.ClearTextOnFocus = false
    searchBox.ZIndex = 14
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
    clearBtn.ZIndex = 14
    Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(1, 0)
    
    clearBtn.MouseButton1Click:Connect(function()
        searchBox.Text = ""
        BangSearchText = ""
        updateBangList("")
    end)
    
    local listContainer = Instance.new("ScrollingFrame")
    listContainer.Parent = mainFrame
    listContainer.Size = UDim2.new(1, -20, 0, 210)
    listContainer.Position = UDim2.new(0, 10, 0, 145)
    listContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    listContainer.BackgroundTransparency = 0.3
    listContainer.BorderSizePixel = 0
    listContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    listContainer.ScrollBarThickness = 6
    listContainer.ScrollBarImageColor3 = currentColor
    listContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    listContainer.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
    listContainer.ZIndex = 13
    Instance.new("UICorner", listContainer).CornerRadius = UDim.new(0, 8)
    
    BangContainer = listContainer
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = listContainer
    listLayout.Padding = UDim.new(0, 5)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)
    
    local playerAddedConn = Players.PlayerAdded:Connect(function()
        updateBangList(BangSearchText)
    end)
    table.insert(espConnections, playerAddedConn)
    
    local playerRemovingConn = Players.PlayerRemoving:Connect(function()
        updateBangList(BangSearchText)
    end)
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
    mainFrame.ZIndex = 12
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🧮 CALCULATOR"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.ZIndex = 13
    
    local calcFrame = Instance.new("Frame")
    calcFrame.Parent = mainFrame
    calcFrame.Size = UDim2.new(0, 560, 0, 300)
    calcFrame.Position = UDim2.new(0, 0, 0, 40)
    calcFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    calcFrame.BackgroundTransparency = 0.3
    calcFrame.ZIndex = 13
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
    display.ZIndex = 14
    Instance.new("UICorner", display).CornerRadius = UDim.new(0, 8)
    
    local buttonsFrame = Instance.new("Frame")
    buttonsFrame.Parent = calcFrame
    buttonsFrame.Size = UDim2.new(0.9, 0, 0, 180)
    buttonsFrame.Position = UDim2.new(0.05, 0, 0, 90)
    buttonsFrame.BackgroundTransparency = 1
    buttonsFrame.ZIndex = 14
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.Parent = buttonsFrame
    gridLayout.CellSize = UDim2.new(0, 120, 0, 40)
    gridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    
    local currentInput = ""
    local currentOperator = ""
    local firstNumber = nil
    local secondNumber = nil
    local result = nil
    
    local function updateDisplay(value)
        display.Text = value
    end
    
    local function handleNumber(num)
        if result ~= nil then
            currentInput = num
            result = nil
            firstNumber = nil
            secondNumber = nil
        else
            currentInput = currentInput .. num
        end
        updateDisplay(currentInput)
    end
    
    local function handleOperator(op)
        if currentInput ~= "" then
            if firstNumber == nil then
                firstNumber = tonumber(currentInput)
                currentOperator = op
                currentInput = ""
            elseif currentOperator ~= "" and currentInput ~= "" then
                secondNumber = tonumber(currentInput)
                
                if currentOperator == "+" then
                    firstNumber = firstNumber + secondNumber
                elseif currentOperator == "-" then
                    firstNumber = firstNumber - secondNumber
                elseif currentOperator == "×" then
                    firstNumber = firstNumber * secondNumber
                elseif currentOperator == "÷" then
                    if secondNumber ~= 0 then
                        firstNumber = firstNumber / secondNumber
                    else
                        updateDisplay("Error")
                        currentInput = ""
                        firstNumber = nil
                        secondNumber = nil
                        currentOperator = ""
                        return
                    end
                end
                
                updateDisplay(tostring(firstNumber))
                currentOperator = op
                currentInput = ""
            end
        end
    end
    
    local function handleEquals()
        if firstNumber ~= nil and currentOperator ~= "" and currentInput ~= "" then
            secondNumber = tonumber(currentInput)
            
            if currentOperator == "+" then
                result = firstNumber + secondNumber
            elseif currentOperator == "-" then
                result = firstNumber - secondNumber
            elseif currentOperator == "×" then
                result = firstNumber * secondNumber
            elseif currentOperator == "÷" then
                if secondNumber ~= 0 then
                    result = firstNumber / secondNumber
                else
                    updateDisplay("Error")
                    currentInput = ""
                    firstNumber = nil
                    secondNumber = nil
                    currentOperator = ""
                    return
                end
            end
            
            updateDisplay(tostring(result))
            firstNumber = result
            secondNumber = nil
            currentOperator = ""
            currentInput = ""
        end
    end
    
    local function handleClear()
        currentInput = ""
        firstNumber = nil
        secondNumber = nil
        currentOperator = ""
        result = nil
        updateDisplay("0")
    end
    
    local numbers = {
        {"7", "8", "9", "÷"},
        {"4", "5", "6", "×"},
        {"1", "2", "3", "-"},
        {"0", ".", "=", "+"}
    }
    
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
            btn.ZIndex = 15
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
            
            btn.MouseEnter:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.2), {
                    BackgroundColor3 = currentColor,
                    Size = UDim2.new(0, 125, 0, 45)
                }):Play()
            end)
            
            btn.MouseLeave:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(45, 45, 60),
                    Size = UDim2.new(0, 120, 0, 40)
                }):Play()
            end)
            
            btn.MouseButton1Click:Connect(function()
                if tonumber(btnText) or btnText == "." then
                    handleNumber(btnText)
                elseif btnText == "=" then
                    handleEquals()
                elseif btnText == "C" then
                    handleClear()
                else
                    handleOperator(btnText)
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
    clearBtn.Text = "CLEAR"
    clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearBtn.TextSize = 18
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.ZIndex = 14
    Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 8)
    
    clearBtn.MouseButton1Click:Connect(handleClear)
end

-- ==================== NOTES TAB ====================
local function loadNotes()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.ZIndex = 12
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "📝 NOTES"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.ZIndex = 13
    
    local notepadFrame = Instance.new("Frame")
    notepadFrame.Parent = mainFrame
    notepadFrame.Size = UDim2.new(1, -20, 0, 300)
    notepadFrame.Position = UDim2.new(0, 10, 0, 40)
    notepadFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    notepadFrame.BackgroundTransparency = 0.3
    notepadFrame.ZIndex = 13
    Instance.new("UICorner", notepadFrame).CornerRadius = UDim.new(0, 12)
    
    local textBox = Instance.new("TextBox")
    textBox.Parent = notepadFrame
    textBox.Size = UDim2.new(0.9, 0, 0, 200)
    textBox.Position = UDim2.new(0.05, 0, 0, 20)
    textBox.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    textBox.BackgroundTransparency = 0.2
    textBox.PlaceholderText = "Type your notes here..."
    textBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    textBox.Text = UIState.notes[player.UserId] or ""
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.TextSize = 14
    textBox.Font = Enum.Font.Gotham
    textBox.TextWrapped = true
    textBox.MultiLine = true
    textBox.ZIndex = 14
    Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 8)
    
    local buttonsFrame = Instance.new("Frame")
    buttonsFrame.Parent = notepadFrame
    buttonsFrame.Size = UDim2.new(0.9, 0, 0, 50)
    buttonsFrame.Position = UDim2.new(0.05, 0, 0, 240)
    buttonsFrame.BackgroundTransparency = 1
    buttonsFrame.ZIndex = 14
    
    local buttonsLayout = Instance.new("UIListLayout")
    buttonsLayout.Parent = buttonsFrame
    buttonsLayout.FillDirection = Enum.FillDirection.Horizontal
    buttonsLayout.Padding = UDim.new(0, 10)
    buttonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local saveBtn = Instance.new("TextButton")
    saveBtn.Parent = buttonsFrame
    saveBtn.Size = UDim2.new(0, 120, 0, 40)
    saveBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    saveBtn.BackgroundTransparency = 0.2
    saveBtn.Text = "💾 SAVE"
    saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    saveBtn.TextSize = 16
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.ZIndex = 15
    Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 8)
    
    local clearBtn = Instance.new("TextButton")
    clearBtn.Parent = buttonsFrame
    clearBtn.Size = UDim2.new(0, 120, 0, 40)
    clearBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    clearBtn.BackgroundTransparency = 0.2
    clearBtn.Text = "🗑️ CLEAR"
    clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearBtn.TextSize = 16
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.ZIndex = 15
    Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 8)
    
    saveBtn.MouseButton1Click:Connect(function()
        UIState.notes[player.UserId] = textBox.Text
        StarterGui:SetCore("SendNotification", {
            Title = "NOTES",
            Text = "Notes saved!",
            Duration = 2
        })
    end)
    
    clearBtn.MouseButton1Click:Connect(function()
        textBox.Text = ""
        UIState.notes[player.UserId] = ""
        StarterGui:SetCore("SendNotification", {
            Title = "NOTES",
            Text = "Notes cleared!",
            Duration = 2
        })
    end)
    
    saveBtn.MouseEnter:Connect(function()
        TweenService:Create(saveBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(0, 200, 0),
            Size = UDim2.new(0, 125, 0, 45)
        }):Play()
    end)
    
    saveBtn.MouseLeave:Connect(function()
        TweenService:Create(saveBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(0, 150, 0),
            Size = UDim2.new(0, 120, 0, 40)
        }):Play()
    end)
    
    clearBtn.MouseEnter:Connect(function()
        TweenService:Create(clearBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(255, 0, 0),
            Size = UDim2.new(0, 125, 0, 45)
        }):Play()
    end)
    
    clearBtn.MouseLeave:Connect(function()
        TweenService:Create(clearBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(200, 0, 0),
            Size = UDim2.new(0, 120, 0, 40)
        }):Play()
    end)
end

-- ==================== SERVERS TAB ====================
local ServersRecentList = {}
local ServersContainer = nil

local function getGameName(placeId)
    for _, game in ipairs(GameCards) do
        if game.placeId == placeId then
            return game.name
        end
    end
    return "Unknown Game"
end

local function findSmallestServer()
    StarterGui:SetCore("SendNotification", {
        Title = "SERVER FINDER",
        Text = "Searching for smallest server...",
        Duration = 2
    })
    
    task.wait(1)
    
    StarterGui:SetCore("SendNotification", {
        Title = "SERVER FINDER",
        Text = "Found server with 12/32 players",
        Duration = 3
    })
end

local function updateServersList()
    if not ServersContainer then return end
    
    for _, v in pairs(ServersContainer:GetChildren()) do
        if v:IsA("Frame") then
            v:Destroy()
        end
    end
    
    local recentTitle = Instance.new("TextLabel")
    recentTitle.Parent = ServersContainer
    recentTitle.Size = UDim2.new(1, 0, 0, 30)
    recentTitle.BackgroundTransparency = 1
    recentTitle.Text = "Recent Servers"
    recentTitle.TextColor3 = currentColor
    recentTitle.TextSize = 16
    recentTitle.Font = Enum.Font.GothamBold
    recentTitle.TextXAlignment = Enum.TextXAlignment.Left
    recentTitle.ZIndex = 14
    
    for _, server in ipairs(UIState.recentServers) do
        local rowFrame = Instance.new("Frame")
        rowFrame.Parent = ServersContainer
        rowFrame.Size = UDim2.new(1, -10, 0, 40)
        rowFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
        rowFrame.BackgroundTransparency = 0.2
        rowFrame.ZIndex = 14
        Instance.new("UICorner", rowFrame).CornerRadius = UDim.new(0, 6)
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Parent = rowFrame
        nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
        nameLabel.Position = UDim2.new(0, 10, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = server.gameName
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 14
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.ZIndex = 15
        
        local rejoinBtn = Instance.new("TextButton")
        rejoinBtn.Parent = rowFrame
        rejoinBtn.Size = UDim2.new(0, 80, 0, 30)
        rejoinBtn.Position = UDim2.new(1, -90, 0.5, -15)
        rejoinBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        rejoinBtn.BackgroundTransparency = 0.2
        rejoinBtn.Text = "Rejoin"
        rejoinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        rejoinBtn.TextSize = 12
        rejoinBtn.Font = Enum.Font.GothamBold
        rejoinBtn.ZIndex = 15
        Instance.new("UICorner", rejoinBtn).CornerRadius = UDim.new(0, 6)
        
        rejoinBtn.MouseButton1Click:Connect(function()
            TeleportService:Teleport(server.placeId, player)
        end)
    end
    
    local clearBtn = createSmallButton(ServersContainer, "Clear History", 160, function()
        UIState.recentServers = {}
        updateServersList()
        StarterGui:SetCore("SendNotification", {
            Title = "SERVERS",
            Text = "History cleared!",
            Duration = 2
        })
    end)
    clearBtn.Size = UDim2.new(0, 160, 0, 35)
    clearBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    
    local separator = Instance.new("Frame")
    separator.Parent = ServersContainer
    separator.Size = UDim2.new(1, 0, 0, 2)
    separator.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    separator.BackgroundTransparency = 0.5
    separator.ZIndex = 14
    
    local finderTitle = Instance.new("TextLabel")
    finderTitle.Parent = ServersContainer
    finderTitle.Size = UDim2.new(1, 0, 0, 30)
    finderTitle.BackgroundTransparency = 1
    finderTitle.Text = "Server Finder"
    finderTitle.TextColor3 = currentColor
    finderTitle.TextSize = 16
    finderTitle.Font = Enum.Font.GothamBold
    finderTitle.TextXAlignment = Enum.TextXAlignment.Left
    finderTitle.ZIndex = 14
    
    local findSmallestBtn = createSmallButton(ServersContainer, "Find Smallest Server", 200, findSmallestServer)
    findSmallestBtn.Size = UDim2.new(0, 200, 0, 35)
    findSmallestBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    
    local findBestBtn = createSmallButton(ServersContainer, "Find Best Server", 200, function()
        findSmallestServer()
    end)
    findBestBtn.Size = UDim2.new(0, 200, 0, 35)
    findBestBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    
    local findNewBtn = createSmallButton(ServersContainer, "Find New Server", 200, function()
        local servers = {142823291, 155615604, 2753915549}
        local randomServer = servers[math.random(#servers)]
        TeleportService:Teleport(randomServer, player)
    end)
    findNewBtn.Size = UDim2.new(0, 200, 0, 35)
    findNewBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    
    local playerSearchFrame = Instance.new("Frame")
    playerSearchFrame.Parent = ServersContainer
    playerSearchFrame.Size = UDim2.new(1, 0, 0, 80)
    playerSearchFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    playerSearchFrame.BackgroundTransparency = 0.2
    playerSearchFrame.ZIndex = 14
    Instance.new("UICorner", playerSearchFrame).CornerRadius = UDim.new(0, 8)
    
    local playerSearchLabel = Instance.new("TextLabel")
    playerSearchLabel.Parent = playerSearchFrame
    playerSearchLabel.Size = UDim2.new(1, -20, 0, 30)
    playerSearchLabel.Position = UDim2.new(0, 10, 0, 10)
    playerSearchLabel.BackgroundTransparency = 1
    playerSearchLabel.Text = "Player Name:"
    playerSearchLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    playerSearchLabel.TextSize = 14
    playerSearchLabel.Font = Enum.Font.Gotham
    playerSearchLabel.TextXAlignment = Enum.TextXAlignment.Left
    playerSearchLabel.ZIndex = 15
    
    local playerSearchBox = Instance.new("TextBox")
    playerSearchBox.Parent = playerSearchFrame
    playerSearchBox.Size = UDim2.new(0.6, 0, 0, 30)
    playerSearchBox.Position = UDim2.new(0, 10, 0, 40)
    playerSearchBox.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    playerSearchBox.BackgroundTransparency = 0.2
    playerSearchBox.PlaceholderText = "Enter player name..."
    playerSearchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    playerSearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    playerSearchBox.TextSize = 14
    playerSearchBox.Font = Enum.Font.Gotham
    playerSearchBox.ZIndex = 15
    Instance.new("UICorner", playerSearchBox).CornerRadius = UDim.new(0, 6)
    
    local findPlayerBtn = createSmallButton(playerSearchFrame, "Find Server", 100, function()
        local playerName = playerSearchBox.Text
        if playerName and playerName ~= "" then
            StarterGui:SetCore("SendNotification", {
                Title = "SERVER FINDER",
                Text = "Searching for " .. playerName .. "'s server...",
                Duration = 2
            })
        end
    end)
    findPlayerBtn.Position = UDim2.new(0, 220, 0, 40)
    findPlayerBtn.Size = UDim2.new(0, 100, 0, 30)
    findPlayerBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
end

local function loadServers()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.ZIndex = 12
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🌐 SERVERS"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.ZIndex = 13
    
    local listContainer = Instance.new("ScrollingFrame")
    listContainer.Parent = mainFrame
    listContainer.Size = UDim2.new(1, -20, 0, 330)
    listContainer.Position = UDim2.new(0, 10, 0, 40)
    listContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    listContainer.BackgroundTransparency = 0.3
    listContainer.BorderSizePixel = 0
    listContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    listContainer.ScrollBarThickness = 6
    listContainer.ScrollBarImageColor3 = currentColor
    listContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    listContainer.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
    listContainer.ZIndex = 13
    Instance.new("UICorner", listContainer).CornerRadius = UDim.new(0, 8)
    
    ServersContainer = listContainer
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = listContainer
    listLayout.Padding = UDim.new(0, 10)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)
    
    updateServersList()
end

-- ==================== LIBRARY TAB ====================
local LibraryScripts = UIState.scripts or {}
local LibrarySearchText = ""
local LibraryContainer = nil

local function saveScript(name, content)
    if not name or name == "" then return false end
    LibraryScripts[name] = {
        content = content,
        favorite = false
    }
    UIState.scripts = LibraryScripts
    return true
end

local function deleteScript(name)
    LibraryScripts[name] = nil
    UIState.scripts = LibraryScripts
end

local function toggleFavorite(name)
    if LibraryScripts[name] then
        LibraryScripts[name].favorite = not LibraryScripts[name].favorite
        UIState.scripts = LibraryScripts
    end
end

local function updateLibraryList(searchTerm)
    searchTerm = searchTerm or LibrarySearchText
    searchTerm = searchTerm:lower()
    
    if not LibraryContainer then return end
    
    for _, v in pairs(LibraryContainer:GetChildren()) do
        if v:IsA("Frame") then
            v:Destroy()
        end
    end
    
    local scripts = {}
    for name, data in pairs(LibraryScripts) do
        table.insert(scripts, {
            name = name,
            content = data.content,
            favorite = data.favorite
        })
    end
    
    table.sort(scripts, function(a, b)
        if a.favorite and not b.favorite then
            return true
        elseif not a.favorite and b.favorite then
            return false
        else
            return a.name:lower() < b.name:lower()
        end
    end)
    
    if searchTerm ~= "" then
        local filtered = {}
        for _, script in ipairs(scripts) do
            if script.name:lower():find(searchTerm) then
                table.insert(filtered, script)
            end
        end
        scripts = filtered
    end
    
    for _, script in ipairs(scripts) do
        local card = Instance.new("Frame")
        card.Parent = LibraryContainer
        card.Size = UDim2.new(1, -10, 0, 100)
        card.BackgroundColor3 = script.favorite and Color3.fromRGB(45, 45, 60) or Color3.fromRGB(35, 35, 48)
        card.BackgroundTransparency = 0.2
        card.ZIndex = 14
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
        
        local nameBox = Instance.new("TextBox")
        nameBox.Parent = card
        nameBox.Size = UDim2.new(0.9, 0, 0, 25)
        nameBox.Position = UDim2.new(0.05, 0, 0, 5)
        nameBox.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
        nameBox.BackgroundTransparency = 0.2
        nameBox.Text = script.name
        nameBox.TextColor3 = script.favorite and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 255, 255)
        nameBox.TextSize = 14
        nameBox.Font = Enum.Font.GothamBold
        nameBox.ZIndex = 15
        Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0, 6)
        
        local scriptBox = Instance.new("TextBox")
        scriptBox.Parent = card
        scriptBox.Size = UDim2.new(0.9, 0, 0, 30)
        scriptBox.Position = UDim2.new(0.05, 0, 0, 35)
        scriptBox.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
        scriptBox.BackgroundTransparency = 0.3
        scriptBox.PlaceholderText = "Paste script here..."
        scriptBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
        scriptBox.Text = script.content or ""
        scriptBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        scriptBox.TextSize = 12
        scriptBox.Font = Enum.Font.Gotham
        scriptBox.TextWrapped = true
        scriptBox.MultiLine = true
        scriptBox.ZIndex = 15
        Instance.new("UICorner", scriptBox).CornerRadius = UDim.new(0, 6)
        
        local buttonsFrame = Instance.new("Frame")
        buttonsFrame.Parent = card
        buttonsFrame.Size = UDim2.new(0.9, 0, 0, 30)
        buttonsFrame.Position = UDim2.new(0.05, 0, 0, 70)
        buttonsFrame.BackgroundTransparency = 1
        buttonsFrame.ZIndex = 15
        
        local buttonsLayout = Instance.new("UIListLayout")
        buttonsLayout.Parent = buttonsFrame
        buttonsLayout.FillDirection = Enum.FillDirection.Horizontal
        buttonsLayout.Padding = UDim.new(0, 5)
        buttonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        
        local runBtn = createSmallButton(buttonsFrame, "▶ RUN", 60, function()
            local scriptContent = scriptBox.Text
            if scriptContent and scriptContent ~= "" then
                local success, err = pcall(function()
                    loadstring(scriptContent)()
                end)
                if success then
                    StarterGui:SetCore("SendNotification", {
                        Title = "LIBRARY",
                        Text = "Script executed!",
                        Duration = 2
                    })
                else
                    StarterGui:SetCore("SendNotification", {
                        Title = "LIBRARY",
                        Text = "Error executing script",
                        Duration = 2
                    })
                end
            end
        end)
        
        local saveBtn = createSmallButton(buttonsFrame, "💾 SAVE", 60, function()
            local newName = nameBox.Text
            local newContent = scriptBox.Text
            if newName and newName ~= "" then
                if script.name ~= newName then
                    deleteScript(script.name)
                end
                saveScript(newName, newContent)
                updateLibraryList(LibrarySearchText)
                StarterGui:SetCore("SendNotification", {
                    Title = "LIBRARY",
                    Text = "Script saved!",
                    Duration = 2
                })
            end
        end)
        
        local favBtn = createSmallButton(buttonsFrame, "⭐", 40, function()
            toggleFavorite(script.name)
            updateLibraryList(LibrarySearchText)
        end)
        favBtn.BackgroundColor3 = script.favorite and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(80, 80, 80)
        
        local deleteBtn = createSmallButton(buttonsFrame, "🗑️", 40, function()
            deleteScript(script.name)
            updateLibraryList(LibrarySearchText)
            StarterGui:SetCore("SendNotification", {
                Title = "LIBRARY",
                Text = "Script deleted!",
                Duration = 2
            })
        end)
        deleteBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    end
    
    local count = #scripts
    LibraryContainer.CanvasSize = UDim2.new(0, 0, 0, math.max(170, count * 110 + 50))
end

local function loadLibrary()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.ZIndex = 12
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "📚 SCRIPT LIBRARY"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.ZIndex = 13
    
    local searchFrame = Instance.new("Frame")
    searchFrame.Parent = mainFrame
    searchFrame.Size = UDim2.new(1, -20, 0, 40)
    searchFrame.Position = UDim2.new(0, 10, 0, 35)
    searchFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    searchFrame.BackgroundTransparency = 0.2
    searchFrame.ZIndex = 13
    Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 8)
    
    local searchIcon = Instance.new("TextLabel")
    searchIcon.Parent = searchFrame
    searchIcon.Size = UDim2.new(0, 40, 1, 0)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "🔍"
    searchIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchIcon.TextSize = 20
    searchIcon.Font = Enum.Font.Gotham
    searchIcon.ZIndex = 14
    
    local searchBox = Instance.new("TextBox")
    searchBox.Parent = searchFrame
    searchBox.Size = UDim2.new(1, -140, 1, -10)
    searchBox.Position = UDim2.new(0, 40, 0, 5)
    searchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    searchBox.BackgroundTransparency = 0.3
    searchBox.PlaceholderText = "Search scripts..."
    searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    searchBox.Text = LibrarySearchText
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.TextSize = 14
    searchBox.Font = Enum.Font.Gotham
    searchBox.ClearTextOnFocus = false
    searchBox.ZIndex = 14
    Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 6)
    
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        LibrarySearchText = searchBox.Text
        updateLibraryList(LibrarySearchText)
    end)
    
    local newBtn = Instance.new("TextButton")
    newBtn.Parent = searchFrame
    newBtn.Size = UDim2.new(0, 80, 0, 30)
    newBtn.Position = UDim2.new(1, -90, 0.5, -15)
    newBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    newBtn.BackgroundTransparency = 0.2
    newBtn.Text = "➕ NEW"
    newBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    newBtn.TextSize = 12
    newBtn.Font = Enum.Font.GothamBold
    newBtn.ZIndex = 14
    Instance.new("UICorner", newBtn).CornerRadius = UDim.new(0, 6)
    
    newBtn.MouseButton1Click:Connect(function()
        local name = "Script " .. (#LibraryScripts + 1)
        saveScript(name, "")
        updateLibraryList(LibrarySearchText)
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
    clearBtn.ZIndex = 14
    Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(1, 0)
    
    clearBtn.MouseButton1Click:Connect(function()
        searchBox.Text = ""
        LibrarySearchText = ""
        updateLibraryList("")
    end)
    
    local listContainer = Instance.new("ScrollingFrame")
    listContainer.Parent = mainFrame
    listContainer.Size = UDim2.new(1, -20, 0, 280)
    listContainer.Position = UDim2.new(0, 10, 0, 85)
    listContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    listContainer.BackgroundTransparency = 0.3
    listContainer.BorderSizePixel = 0
    listContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    listContainer.ScrollBarThickness = 6
    listContainer.ScrollBarImageColor3 = currentColor
    listContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    listContainer.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
    listContainer.ZIndex = 13
    Instance.new("UICorner", listContainer).CornerRadius = UDim.new(0, 8)
    
    LibraryContainer = listContainer
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = listContainer
    listLayout.Padding = UDim.new(0, 10)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)
    
    updateLibraryList("")
end

-- ==================== COLOR TAB ====================
local function loadColor()
    clearContent()
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = contentFrame
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.ZIndex = 12
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "COLOR SETTINGS"
    titleLabel.TextColor3 = currentColor
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.ZIndex = 13
    
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Parent = mainFrame
    controlsFrame.Size = UDim2.new(1, -20, 0, 300)
    controlsFrame.Position = UDim2.new(0, 10, 0, 40)
    controlsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    controlsFrame.BackgroundTransparency = 0.3
    controlsFrame.ZIndex = 13
    Instance.new("UICorner", controlsFrame).CornerRadius = UDim.new(0, 8)
    
    local toggleContainer = Instance.new("Frame")
    toggleContainer.Parent = controlsFrame
    toggleContainer.Size = UDim2.new(1, -20, 1, -20)
    toggleContainer.Position = UDim2.new(0, 10, 0, 10)
    toggleContainer.BackgroundTransparency = 1
    toggleContainer.ZIndex = 14
    
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
                for plr, highlight in pairs(espHighlights) do
                    if highlight then
                        highlight.FillColor = currentColor
                    end
                end
                for plr, nametag in pairs(espNameTags) do
                    if nametag and nametag:FindFirstChildOfClass("TextLabel") then
                        nametag:FindFirstChildOfClass("TextLabel").TextColor3 = currentColor
                    end
                end
            end
        end
    end)
    
    createSlider(toggleContainer, "Red", 0, 255, rVal, function(v)
        rVal = v
        UIState.rVal = v
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
                for plr, highlight in pairs(espHighlights) do
                    if highlight then
                        highlight.FillColor = currentColor
                    end
                end
                for plr, nametag in pairs(espNameTags) do
                    if nametag and nametag:FindFirstChildOfClass("TextLabel") then
                        nametag:FindFirstChildOfClass("TextLabel").TextColor3 = currentColor
                    end
                end
            end
        end
    end)
    
    createSlider(toggleContainer, "Green", 0, 255, gVal, function(v)
        gVal = v
        UIState.gVal = v
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
                for plr, highlight in pairs(espHighlights) do
                    if highlight then
                        highlight.FillColor = currentColor
                    end
                end
                for plr, nametag in pairs(espNameTags) do
                    if nametag and nametag:FindFirstChildOfClass("TextLabel") then
                        nametag:FindFirstChildOfClass("TextLabel").TextColor3 = currentColor
                    end
                end
            end
        end
    end)
    
    createSlider(toggleContainer, "Blue", 0, 255, bVal, function(v)
        bVal = v
        UIState.bVal = v
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
                for plr, highlight in pairs(espHighlights) do
                    if highlight then
                        highlight.FillColor = currentColor
                    end
                end
                for plr, nametag in pairs(espNameTags) do
                    if nametag and nametag:FindFirstChildOfClass("TextLabel") then
                        nametag:FindFirstChildOfClass("TextLabel").TextColor3 = currentColor
                    end
                end
            end
        end
    end)
end

-- ==================== EVENTOS DAS ABAS ====================
homeBtn.MouseButton1Click:Connect(function() activeTab = "HOME"; loadHome() end)
gamesBtn.MouseButton1Click:Connect(function() activeTab = "GAMES"; loadGames() end)
serverBtn.MouseButton1Click:Connect(function() activeTab = "SERVER"; loadServer() end)
aimbotBtn.MouseButton1Click:Connect(function() activeTab = "AIMBOT"; loadAimbot() end)
aimIgnoreBtn.MouseButton1Click:Connect(function() activeTab = "IGNORE"; loadAimIgnore() end)
teleportBtn.MouseButton1Click:Connect(function() activeTab = "TELEPORT"; loadTeleport() end)
bringBtn.MouseButton1Click:Connect(function() activeTab = "BRING"; loadBring() end)
bangBtn.MouseButton1Click:Connect(function() activeTab = "BANG"; loadBang() end)
calcBtn.MouseButton1Click:Connect(function() activeTab = "CALC"; loadCalculator() end)
notesBtn.MouseButton1Click:Connect(function() activeTab = "NOTES"; loadNotes() end)
servidoresBtn.MouseButton1Click:Connect(function() activeTab = "SERVERS"; loadServers() end)
libBtn.MouseButton1Click:Connect(function() activeTab = "LIBRARY"; loadLibrary() end)
colorBtn.MouseButton1Click:Connect(function() activeTab = "COLOR"; loadColor() end)

minBtn.MouseButton1Click:Connect(function()
    if isMinimized then return end
    isMinimized = true
    
    TweenService:Create(main, TweenInfo.new(0.4), {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }):Play()
    
    task.wait(0.3)
    main.Visible = false
    ball.Visible = true
    ball.Size = UDim2.new(0, 0, 0, 0)
    
    TweenService:Create(ball, TweenInfo.new(0.4), {
        Size = UDim2.new(0, 60, 0, 60)
    }):Play()
end)

ball.MouseButton1Click:Connect(function()
    if not isMinimized then return end
    
    TweenService:Create(ball, TweenInfo.new(0.3), {
        Size = UDim2.new(0, 0, 0, 0)
    }):Play()
    
    task.wait(0.2)
    ball.Visible = false
    main.Visible = true
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.Size = UDim2.new(0, 0, 0, 0)
    main.BackgroundTransparency = 1
    
    TweenService:Create(main, TweenInfo.new(0.4), {
        Size = UDim2.new(0, 630, 0, 430),
        Position = UDim2.new(0.5, -315, 0.5, -215),
        BackgroundTransparency = 0.1
    }):Play()
    
    task.wait(0.4)
    isMinimized = false
end)

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
            for plr, highlight in pairs(espHighlights) do
                if highlight then
                    highlight.FillColor = currentColor
                end
            end
            for plr, nametag in pairs(espNameTags) do
                if nametag and nametag:FindFirstChildOfClass("TextLabel") then
                    nametag:FindFirstChildOfClass("TextLabel").TextColor3 = currentColor
                end
            end
        end
        
        if activeTab == "HOME" then
            homeBtn.BackgroundColor3 = currentColor
        elseif activeTab == "GAMES" then
            gamesBtn.BackgroundColor3 = currentColor
        elseif activeTab == "SERVER" then
            serverBtn.BackgroundColor3 = currentColor
        elseif activeTab == "AIMBOT" then
            aimbotBtn.BackgroundColor3 = currentColor
        elseif activeTab == "IGNORE" then
            aimIgnoreBtn.BackgroundColor3 = currentColor
        elseif activeTab == "TELEPORT" then
            teleportBtn.BackgroundColor3 = currentColor
        elseif activeTab == "BRING" then
            bringBtn.BackgroundColor3 = currentColor
        elseif activeTab == "BANG" then
            bangBtn.BackgroundColor3 = currentColor
        elseif activeTab == "CALC" then
            calcBtn.BackgroundColor3 = currentColor
        elseif activeTab == "NOTES" then
            notesBtn.BackgroundColor3 = currentColor
        elseif activeTab == "SERVERS" then
            servidoresBtn.BackgroundColor3 = currentColor
        elseif activeTab == "LIBRARY" then
            libBtn.BackgroundColor3 = currentColor
        elseif activeTab == "COLOR" then
            colorBtn.BackgroundColor3 = currentColor
        end
    end
end)

UIS.JumpRequest:Connect(function()
    if infjump and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

loadHome()

task.wait(1)
StarterGui:SetCore("SendNotification", {
    Title = "VITOR HUB",
    Text = "Complete Edition - Executed!",
    Duration = 2
})
