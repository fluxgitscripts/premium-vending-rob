local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- FIX: LocalPlayer sofort holen, aber sicher mit WaitForChild-Fallback
local plr = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MoonHubWatermark"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Name = "Watermark"
frame.Size = UDim2.new(0, 285, 0, 50)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(10, 8, 20)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = frame

local accent = Instance.new("Frame")
accent.Size = UDim2.new(0, 3, 1, 0)
accent.Position = UDim2.new(0, 0, 0, 0)
accent.BackgroundColor3 = Color3.fromRGB(138, 95, 255)
accent.BorderSizePixel = 0
accent.Parent = frame

local accentCorner = Instance.new("UICorner")
accentCorner.CornerRadius = UDim.new(0, 6)
accentCorner.Parent = accent

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(138, 95, 255)
stroke.Transparency = 0.55
stroke.Thickness = 1
stroke.Parent = frame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 130, 0, 20)
titleLabel.Position = UDim2.new(0, 14, 0, 5)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "MoonHub Vending Rob"
titleLabel.TextColor3 = Color3.fromRGB(233, 213, 255)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = frame

local linkLabel = Instance.new("TextLabel")
linkLabel.Size = UDim2.new(0, 130, 0, 16)
linkLabel.Position = UDim2.new(0, 14, 0, 26)
linkLabel.BackgroundTransparency = 1
linkLabel.Text = ".gg/moon-hub"
linkLabel.TextColor3 = Color3.fromRGB(220, 210, 255)
linkLabel.TextTransparency = 0.1
linkLabel.TextSize = 11
linkLabel.Font = Enum.Font.GothamMedium
linkLabel.TextXAlignment = Enum.TextXAlignment.Left
linkLabel.Parent = frame

local divider1 = Instance.new("Frame")
divider1.Size = UDim2.new(0, 1, 0, 28)
divider1.Position = UDim2.new(0, 155, 0, 11)
divider1.BackgroundColor3 = Color3.fromRGB(138, 95, 255)
divider1.BackgroundTransparency = 0.6
divider1.BorderSizePixel = 0
divider1.Parent = frame

local fpsTitle = Instance.new("TextLabel")
fpsTitle.Size = UDim2.new(0, 55, 0, 14)
fpsTitle.Position = UDim2.new(0, 160, 0, 7)
fpsTitle.BackgroundTransparency = 1
fpsTitle.Text = "FPS"
fpsTitle.TextColor3 = Color3.fromRGB(196, 181, 253)
fpsTitle.TextTransparency = 0.3
fpsTitle.TextSize = 9
fpsTitle.Font = Enum.Font.GothamBold
fpsTitle.TextXAlignment = Enum.TextXAlignment.Center
fpsTitle.Parent = frame

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0, 55, 0, 22)
fpsLabel.Position = UDim2.new(0, 160, 0, 20)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "0"
fpsLabel.TextColor3 = Color3.fromRGB(167, 139, 250)
fpsLabel.TextSize = 18
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.TextXAlignment = Enum.TextXAlignment.Center
fpsLabel.Parent = frame

local divider2 = Instance.new("Frame")
divider2.Size = UDim2.new(0, 1, 0, 28)
divider2.Position = UDim2.new(0, 220, 0, 11)
divider2.BackgroundColor3 = Color3.fromRGB(138, 95, 255)
divider2.BackgroundTransparency = 0.6
divider2.BorderSizePixel = 0
divider2.Parent = frame

local pingTitle = Instance.new("TextLabel")
pingTitle.Size = UDim2.new(0, 55, 0, 14)
pingTitle.Position = UDim2.new(0, 225, 0, 7)
pingTitle.BackgroundTransparency = 1
pingTitle.Text = "PING"
pingTitle.TextColor3 = Color3.fromRGB(196, 181, 253)
pingTitle.TextTransparency = 0.3
pingTitle.TextSize = 9
pingTitle.Font = Enum.Font.GothamBold
pingTitle.TextXAlignment = Enum.TextXAlignment.Center
pingTitle.Parent = frame

local pingLabel = Instance.new("TextLabel")
pingLabel.Size = UDim2.new(0, 55, 0, 22)
pingLabel.Position = UDim2.new(0, 225, 0, 20)
pingLabel.BackgroundTransparency = 1
pingLabel.Text = "0"
pingLabel.TextColor3 = Color3.fromRGB(167, 139, 250)
pingLabel.TextSize = 18
pingLabel.Font = Enum.Font.GothamBold
pingLabel.TextXAlignment = Enum.TextXAlignment.Center
pingLabel.Parent = frame

local lastTime = tick()
local frameCount = 0

RunService.RenderStepped:Connect(function()
    frameCount += 1
    local now = tick()
    local delta = now - lastTime

    if delta >= 0.5 then
        local fps = math.round(frameCount / delta)
        frameCount = 0
        lastTime = now

        fpsLabel.Text = tostring(fps)

        if fps >= 100 then
            fpsLabel.TextColor3 = Color3.fromRGB(167, 139, 250)
        elseif fps >= 60 then
            fpsLabel.TextColor3 = Color3.fromRGB(134, 239, 172)
        else
            fpsLabel.TextColor3 = Color3.fromRGB(252, 165, 165)
        end
    end
end)

-- FIX: GetNetworkPing mit nil-Guard und pcall (verhindert "attempt to index nil with GetNetworkPing")
RunService.Heartbeat:Connect(function()
    local localPlr = Players.LocalPlayer
    if not localPlr then return end
    local ok, ping = pcall(function()
        return math.round(localPlr:GetNetworkPing() * 1000)
    end)
    if not ok then return end

    pingLabel.Text = tostring(ping)

    if ping <= 80 then
        pingLabel.TextColor3 = Color3.fromRGB(134, 239, 172)
    elseif ping <= 150 then
        pingLabel.TextColor3 = Color3.fromRGB(253, 224, 71)
    else
        pingLabel.TextColor3 = Color3.fromRGB(252, 165, 165)
    end
end)

local TweenService        = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui          = game:GetService("StarterGui")
local Workspace           = game:GetService("Workspace")
local HttpService         = game:GetService("HttpService")
local TeleportService     = game:GetService("TeleportService")

if not plr then plr = Players.LocalPlayer end

local EJw = game:GetService("ReplicatedStorage"):WaitForChild("EJw")
local RemoteEvents = {
    RobEvent = EJw:WaitForChild("a3126821-130a-4135-80e1-1d28cece4007"),
    SellItem = EJw:WaitForChild("eb233e6a-acb9-4169-acb9-129fe8cb06bb"),
}

local VENDING_COLLECT_CODE   = "wRl"
local ProximityPromptTimeBet = 2.3

_G.vendingActive      = false
_G.flightSpeed        = 160
_G.vendingPoliceRange = 30
_G.lowHpActive        = false
_G.lowHpThreshold     = 30

local vendingLoopThread    = nil
local instantCollectThread = nil
local prisonCheckThread    = nil
local lowHpCheckThread     = nil

local DROP_Y = -5

local CONFIG_FILE = "vending-rob-moon-hub-config.json"

local defaultConfig = {
    flightSpeed        = 160,
    vendingPoliceRange = 55,
    vendingActive      = false,
    lowHpActive        = false,
    lowHpThreshold     = 30,
}

local function loadConfig()
    if isfile and isfile(CONFIG_FILE) then
        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(CONFIG_FILE))
        end)
        if ok and type(decoded) == "table" then
            _G.flightSpeed        = decoded.flightSpeed        or defaultConfig.flightSpeed
            _G.vendingPoliceRange = decoded.vendingPoliceRange or defaultConfig.vendingPoliceRange
            _G.vendingActive      = decoded.vendingActive      ~= nil and decoded.vendingActive or defaultConfig.vendingActive
            _G.lowHpActive        = decoded.lowHpActive        ~= nil and decoded.lowHpActive or defaultConfig.lowHpActive
            _G.lowHpThreshold     = decoded.lowHpThreshold     or defaultConfig.lowHpThreshold
        end
    end
end

local function saveConfig()
    if writefile then
        local data = {
            flightSpeed        = _G.flightSpeed,
            vendingPoliceRange = _G.vendingPoliceRange,
            vendingActive      = _G.vendingActive,
            lowHpActive        = _G.lowHpActive,
            lowHpThreshold     = _G.lowHpThreshold,
        }
        pcall(function()
            writefile(CONFIG_FILE, HttpService:JSONEncode(data))
        end)
    end
end

loadConfig()

_G.TeleportConfig = {
    TeleportActive    = false,
    CurrentTween      = nil,
    CurrentConnection = nil,
}

local function stopCurrentTween()
    if _G.TeleportConfig.CurrentTween then
        _G.TeleportConfig.CurrentTween:Cancel()
        _G.TeleportConfig.CurrentTween = nil
    end
    if _G.TeleportConfig.CurrentConnection then
        _G.TeleportConfig.CurrentConnection:Disconnect()
        _G.TeleportConfig.CurrentConnection = nil
    end
    _G.TeleportConfig.TeleportActive = false
end

-- FIX: getChar komplett mit pcall gesichert (verhindert "attempt to index nil with Character")
local function getChar()
    if not plr then return nil, nil, nil end
    local ok, char = pcall(function() return plr.Character end)
    if not ok or not char then return nil, nil, nil end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    return char, hum, root
end

local function clickAtCoordinates(rx, ry)
    local vp = Workspace.CurrentCamera.ViewportSize
    VirtualInputManager:SendMouseButtonEvent(vp.X * rx, vp.Y * ry, 0, true,  game, 0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(vp.X * rx, vp.Y * ry, 0, false, game, 0)
end

local function notify(title, text)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text  = text,
        Time  = 4
    })
end

local function isPoliceNearby()
    local _, _, root = getChar()
    if not root then return false end

    local hum = root.Parent:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 25 then
        return true
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= plr and p.Team and p.Team.Name == "Police" then
            local pChar = p.Character
            if pChar then
                local pRoot = pChar:FindFirstChild("HumanoidRootPart")
                if pRoot and (pRoot.Position - root.Position).Magnitude <= _G.vendingPoliceRange then
                    return true
                end
            end
        end
    end

    return false
end

-- FIX: isPlayerInPrison mit pcall — plr.Team wirft Fehler wenn noch nicht geladen (Line 307)
local function isPlayerInPrison()
    if not plr then return false end
    local ok, team = pcall(function() return plr.Team end)
    if not ok or not team then return false end
    return team.Name == "Prisoner"
end

local function doServerHop(reason)
    local vehicle = Workspace.Vehicles:FindFirstChild(plr.Name)
    if vehicle then
        local driveSeat = vehicle:FindFirstChild("DriveSeat", true)
            or vehicle:FindFirstChildWhichIsA("VehicleSeat", true)

        if driveSeat then
            local _, humanoid, hrp = getChar()
            if hrp then hrp.CFrame = driveSeat.CFrame end
            task.wait(0.1)
            if humanoid then driveSeat:Sit(humanoid) end
            task.wait(0.3)

            vehicle.PrimaryPart = driveSeat
            local currentPos = vehicle:GetPivot().Position
            vehicle:PivotTo(CFrame.new(Vector3.new(currentPos.X, currentPos.Y + 800, currentPos.Z)))
            driveSeat.AssemblyLinearVelocity = Vector3.zero
            driveSeat.AssemblyAngularVelocity = Vector3.zero
            task.wait(0.2)
        end
    end

    plr:Kick(reason or "Serverhopping")

    task.wait(1)

    if queue_on_teleport then
        local payload = [[
            loadstring(game:HttpGet("https://raw.githubusercontent.com/fluxgitscripts/premium-vending-rob/refs/heads/main/.lua"))()
        ]]
        pcall(function() queue_on_teleport(payload) end)
    end

    local success, servers = pcall(function()
        return HttpService:JSONDecode(
            game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        ).data
    end)

    if success and servers then
        for _, server in pairs(servers) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, plr)
                return
            end
        end
    end

    TeleportService:Teleport(game.PlaceId, plr)
end

local function startAutoCollect()
    if not plr then return end
    -- FIX: Character sicher mit pcall holen
    local ok, Character = pcall(function()
        return plr.Character or plr.CharacterAdded:Wait()
    end)
    if not ok or not Character then return end

    local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 15)
    if not HumanoidRootPart then return end

    local Collected = {}
    local Range     = 30
    local myName    = plr.Name

    local dropsFolder = Workspace:WaitForChild("Drops")

    local function collectDrop(obj)
        if Collected[obj] then return end
        if not obj or not obj.Parent then return end
        if obj.Transparency ~= 0 then return end

        Collected[obj] = true

        task.spawn(function()
            RemoteEvents.RobEvent:FireServer(obj, VENDING_COLLECT_CODE, true)
            task.wait(ProximityPromptTimeBet)
            RemoteEvents.RobEvent:FireServer(obj, VENDING_COLLECT_CODE, false)
            task.wait(0.3)

            if obj and obj.Parent and obj.Transparency == 0 then
                Collected[obj] = nil
            end
        end)
    end

    local function loot()
        local _, _, root = getChar()
        if root then HumanoidRootPart = root end
        if not HumanoidRootPart then return end

        for _, obj in ipairs(dropsFolder:GetChildren()) do
            if obj:IsA("MeshPart")
                and obj.Name == myName
                and obj.Transparency == 0
                and not Collected[obj]
                and (obj.Position - HumanoidRootPart.Position).Magnitude <= Range
            then
                collectDrop(obj)
            end
        end
    end

    loot()

    local addConn = dropsFolder.ChildAdded:Connect(function(obj)
        if not _G.vendingActive then return end
        if isPlayerInPrison() then return end
        task.wait(0.05)
        if not (obj:IsA("MeshPart") and obj.Name == myName and obj.Transparency == 0) then return end
        local _, _, root = getChar()
        if root and (obj.Position - root.Position).Magnitude <= Range then
            collectDrop(obj)
        end
    end)

    while _G.vendingActive do
        if isPlayerInPrison() then
            task.wait(1)
        else
            loot()
            task.wait(0.25)
        end
    end

    addConn:Disconnect()
end

local function stopInstantCollect()
    if instantCollectThread then
        task.cancel(instantCollectThread)
        instantCollectThread = nil
    end
end

local function launchInstantCollect()
    if instantCollectThread then return end
    instantCollectThread = task.spawn(startAutoCollect)
end

_G.TeleportConfig.TweenTo = function(destination)
    clickAtCoordinates(0.5, 0.9)
    if _G.TeleportConfig.TeleportActive then stopCurrentTween() end
    _G.TeleportConfig.TeleportActive = true

    -- FIX: Character sicher mit pcall holen
    if not plr then _G.TeleportConfig.TeleportActive = false; return false end
    local okC, character = pcall(function()
        return plr.Character or plr.CharacterAdded:Wait()
    end)
    if not okC or not character then _G.TeleportConfig.TeleportActive = false; return false end

    local humanoid  = character:FindFirstChildOfClass("Humanoid")
    local hrp       = character:FindFirstChild("HumanoidRootPart")

    local vehicle = Workspace.Vehicles:FindFirstChild(plr.Name)
    if not vehicle then
        _G.TeleportConfig.TeleportActive = false
        notify("Error", "No vehicle found!")
        return false
    end

    local driveSeat = vehicle:FindFirstChild("DriveSeat", true)
        or vehicle:FindFirstChildWhichIsA("VehicleSeat", true)
    if not driveSeat then _G.TeleportConfig.TeleportActive = false; return false end
    vehicle.PrimaryPart = driveSeat

    if humanoid and humanoid.SeatPart ~= driveSeat then
        if hrp then hrp.CFrame = driveSeat.CFrame end
        task.wait(0.1)
        driveSeat:Sit(humanoid)
        local t = 0
        while humanoid.SeatPart ~= driveSeat and t < 15 do
            if not _G.TeleportConfig.TeleportActive then return false end
            task.wait(0.1)
            t = t + 1
        end
    end

    local targetCF  = (typeof(destination) == "CFrame") and destination or CFrame.new(destination)
    local targetPos = targetCF.Position

    local pivotNow = vehicle:GetPivot()
    vehicle:PivotTo(CFrame.new(Vector3.new(pivotNow.X, DROP_Y, pivotNow.Z)))
    driveSeat.AssemblyLinearVelocity  = Vector3.zero
    driveSeat.AssemblyAngularVelocity = Vector3.zero
    task.wait(0.05)

    if not _G.TeleportConfig.TeleportActive then return false end

    local startPos = Vector3.new(pivotNow.X, DROP_Y, pivotNow.Z)
    local distance = (startPos - targetPos).Magnitude

    if distance > 0.5 then
        local speedVariance = _G.flightSpeed * (0.92 + math.random() * 0.16)
        local duration      = distance / speedVariance

        local val = Instance.new("CFrameValue")
        val.Value = vehicle:GetPivot()

        _G.TeleportConfig.CurrentConnection = val.Changed:Connect(function(newCF)
            vehicle:PivotTo(newCF)
            driveSeat.AssemblyLinearVelocity  = Vector3.new(
                (math.random() - 0.5) * 0.08, 0, (math.random() - 0.5) * 0.08)
            driveSeat.AssemblyAngularVelocity = Vector3.zero
        end)

        _G.TeleportConfig.CurrentTween = TweenService:Create(val,
            TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
            {Value = targetCF})
        _G.TeleportConfig.CurrentTween:Play()
        _G.TeleportConfig.CurrentTween.Completed:Wait()

        if _G.TeleportConfig.CurrentConnection then
            _G.TeleportConfig.CurrentConnection:Disconnect()
            _G.TeleportConfig.CurrentConnection = nil
        end
        val:Destroy()
    end

    _G.TeleportConfig.TeleportActive = false
    _G.TeleportConfig.CurrentTween   = nil
    driveSeat:Sit(humanoid)
    clickAtCoordinates(0.5, 0.9)
    return true
end

local function tweenTo(destination)
    return _G.TeleportConfig.TweenTo(destination)
end

local function plrTween(targetCFrame)
    local _, hum, root = getChar()
    if not root then return end
    if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
    root.CFrame = targetCFrame
end

local function findNearestRobbableVending()
    local folder = Workspace:FindFirstChild("Robberies")
        and Workspace.Robberies:FindFirstChild("VendingMachines")
    if not folder then return nil end

    local _, _, root = getChar()
    if not root then return nil end

    local nearest, minDist = nil, math.huge
    local targetColor = Color3.fromRGB(73, 147, 0)

    for _, model in ipairs(folder:GetChildren()) do
        local light = model:FindFirstChild("Light")
        local glass = model:FindFirstChild("Glass")
        if light and glass and light:IsA("BasePart") and light.Color == targetColor then
            local dist = (glass.Position - root.Position).Magnitude
            if dist < minDist then
                minDist = dist
                nearest = model
            end
        end
    end

    return nearest
end

local function VendingRob(targetVending)
    if not targetVending then return false end

    if isPlayerInPrison() then
        print("Prison Check - You are in Prison. Cannot rob vending machine.")
        return false
    end

    local glass = targetVending:FindFirstChild("Glass")
    if not glass then return false end

    local targetPos = glass.Position - glass.CFrame.LookVector * 12
    local lookDir   = glass.CFrame.RightVector
    tweenTo(CFrame.lookAt(targetPos, targetPos + lookDir))
    task.wait(0.3)

    if isPoliceNearby() then
        doServerHop("Police Nearby")
        return false
    end

    if isPlayerInPrison() then
        print("Prison Check - You are in Prison. Aborting robbery.")
        return false
    end

    local _, hum, _ = getChar()
    if hum then hum.Sit = false end
    task.wait(0.3)

    local offsetPos = glass.Position - glass.CFrame.LookVector * 1.6
    plrTween(CFrame.lookAt(offsetPos, glass.Position))
    task.wait(0.2)

    if isPoliceNearby() then
        doServerHop("Police Nearby")
        return false
    end

    if isPlayerInPrison() then
        print("Prison Check - You are in Prison. Aborting robbery.")
        return false
    end

    for i = 1, 14 do
        if isPlayerInPrison() then
            print("Prison Check - You are in Prison. Stopping robbery.")
            return false
        end
        if isPoliceNearby() then
            doServerHop("Police Nearby")
            return false
        end
        VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode.F, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        task.wait(0.3)
    end

    if isPoliceNearby() then
        doServerHop("Police Nearby")
        return false
    end

    if isPlayerInPrison() then
        print("Prison Check - You are in Prison. Robbery aborted.")
        return false
    end

    task.wait(0.6)
    return true
end

local function hasRobbableVending()
    local folder = Workspace:FindFirstChild("Robberies")
        and Workspace.Robberies:FindFirstChild("VendingMachines")
    if not folder then return false end
    local targetColor = Color3.fromRGB(73, 147, 0)
    for _, model in ipairs(folder:GetChildren()) do
        local light = model:FindFirstChild("Light")
        local glass = model:FindFirstChild("Glass")
        if light and glass and light:IsA("BasePart") and light.Color == targetColor then
            return true
        end
    end
    return false
end

-- FIX: waitUntilReady — Character nie direkt indexen, immer pcall + HRP-nil-Check (Line 655)
local function waitUntilReady()
    if not plr then return false end

    local char
    local okC = pcall(function()
        char = plr.Character or plr.CharacterAdded:Wait()
    end)
    if not okC or not char then return false end

    local hrp = char:WaitForChild("HumanoidRootPart", 15)
    if not hrp then return false end

    local t = 0
    repeat
        if not Workspace.Vehicles:FindFirstChild(plr.Name) then task.wait(0.5) end
        t = t + 0.5
    until Workspace.Vehicles:FindFirstChild(plr.Name) or t >= 15

    t = 0
    repeat
        task.wait(0.5)
        t = t + 0.5
    until hasRobbableVending() or t >= 30

    if not hasRobbableVending() then
        doServerHop("No Vending Machines")
        return false
    end

    return true
end

local lowHpTriggered = false

local function startLowHpCheck()
    if lowHpCheckThread then return end
    lowHpCheckThread = task.spawn(function()
        while true do
            task.wait(0.5)
            if not _G.lowHpActive or not _G.vendingActive then
                lowHpTriggered = false
                continue
            end

            local _, hum, _ = getChar()
            if not hum then continue end

            local hp = hum.Health
            if hp <= 0 then
                lowHpTriggered = false
                continue
            end

            if hp <= _G.lowHpThreshold and not lowHpTriggered then
                lowHpTriggered = true
                notify("Low HP", "HP kritisch (" .. math.floor(hp) .. ")! Weiche aus...")

                local nextTarget = findNearestRobbableVending()
                if nextTarget then
                    local glass = nextTarget:FindFirstChild("Glass")
                    if glass then
                        local targetPos = glass.Position - glass.CFrame.LookVector * 12
                        local lookDir   = glass.CFrame.RightVector
                        tweenTo(CFrame.lookAt(targetPos, targetPos + lookDir))
                        task.wait(1)
                        local _, hum2, _ = getChar()
                        if hum2 and hum2.Health <= _G.lowHpThreshold then
                            doServerHop("Low HP")
                        end
                    else
                        doServerHop("Low HP")
                    end
                else
                    doServerHop("Low HP")
                end

                lowHpTriggered = false
            elseif hp > _G.lowHpThreshold then
                lowHpTriggered = false
            end
        end
    end)
end

local function stopLowHpCheck()
    if lowHpCheckThread then
        task.cancel(lowHpCheckThread)
        lowHpCheckThread = nil
    end
    lowHpTriggered = false
end

local function vendingMainLoop()
    if not waitUntilReady() then return end
    task.wait(1)

    while _G.vendingActive do
        if isPlayerInPrison() then
            print("Prison Check - You are in Prison. Waiting to be released...")
            while _G.vendingActive and isPlayerInPrison() do
                task.wait(2)
            end
            if not _G.vendingActive then break end
            print("Prison Check - You are free! Resuming vending robbery.")
            if not waitUntilReady() then return end
            task.wait(1)
        end

        local target = findNearestRobbableVending()
        if not target then
            doServerHop("No Vending Machines")
            break
        else
            local success = VendingRob(target)
            if not success then
                if isPlayerInPrison() then
                    task.wait(1)
                else
                    task.wait(1.5)
                end
            else
                task.wait(1.5)
            end
        end
    end
end

local function setVendingActive(enabled)
    _G.vendingActive = enabled

    if enabled then
        if vendingLoopThread then task.cancel(vendingLoopThread) end
        vendingLoopThread = task.spawn(vendingMainLoop)
        task.delay(3, function()
            if _G.vendingActive and not isPlayerInPrison() then
                launchInstantCollect()
            end
        end)
        if _G.lowHpActive then
            startLowHpCheck()
        end
        notify("Vending Rob", "Activated!")
    else
        stopInstantCollect()
        stopLowHpCheck()
        if vendingLoopThread then
            task.cancel(vendingLoopThread)
            vendingLoopThread = nil
        end
        stopCurrentTween()
        notify("Vending Rob", "Deactivated!")
    end
end

local function startPrisonCheck()
    if prisonCheckThread then return end
    prisonCheckThread = task.spawn(function()
        while true do
            if isPlayerInPrison() then
                print("Prison Check - You are in Prison.")
            end
            task.wait(2)
        end
    end)
end

startPrisonCheck()

local OrionLib = loadstring(game:HttpGet("https://moon-hub.pages.dev/orion.lua"))()

local Window = OrionLib:MakeWindow({
    Name         = "MoonHub・ discord.gg/moon-hub",
    HidePremium  = false,
    IntroEnabled = false,
    IntroText    = "Loading MoonHub...",
    IntroIcon    = "rbxassetid://79390235538362",
    SaveConfig   = false,
    ConfigFolder = "VendingRobConfig",
    Icon         = "rbxassetid://4483345998"
})

local MainTab = Window:MakeTab({
    Name        = "Main",
    Icon        = "rbxassetid://4483345998",
    PremiumOnly = false
})

MainTab:AddSection({ Name = "Robbery" })

local savedToggle = _G.vendingActive

MainTab:AddToggle({
    Name     = "Activate Vending Rob",
    Default  = savedToggle,
    Save     = false,
    Flag     = "vendingActive",
    Callback = function(Value)
        setVendingActive(Value)
        saveConfig()
    end
})

MainTab:AddToggle({
    Name     = "Low HP Escape",
    Default  = _G.lowHpActive,
    Save     = false,
    Flag     = "lowHpActive",
    Callback = function(Value)
        _G.lowHpActive = Value
        if Value and _G.vendingActive then
            startLowHpCheck()
        elseif not Value then
            stopLowHpCheck()
        end
        saveConfig()
        if Value then
            notify("Low HP Escape", "Aktiviert! Flieht bei " .. _G.lowHpThreshold .. " HP.")
        else
            notify("Low HP Escape", "Deaktiviert.")
        end
    end
})

if savedToggle then
    task.defer(function() setVendingActive(true) end)
end

MainTab:AddSection({ Name = "Settings" })

MainTab:AddSlider({
    Name      = "Flight Speed",
    Min       = 50,
    Max       = 250,
    Default   = _G.flightSpeed,
    Color     = Color3.fromRGB(255, 255, 255),
    Increment = 10,
    ValueName = "speed",
    Save      = false,
    Flag      = "flightSpeed",
    Callback  = function(Value)
        _G.flightSpeed = Value
        saveConfig()
    end
})

MainTab:AddSlider({
    Name      = "Police Detection Range",
    Min       = 30,
    Max       = 100,
    Default   = _G.vendingPoliceRange,
    Color     = Color3.fromRGB(255, 255, 255),
    Increment = 5,
    ValueName = "studs",
    Save      = false,
    Flag      = "vendingPoliceRange",
    Callback  = function(Value)
        _G.vendingPoliceRange = Value
        saveConfig()
    end
})

MainTab:AddSlider({
    Name      = "Low HP Threshold",
    Min       = 5,
    Max       = 90,
    Default   = _G.lowHpThreshold,
    Color     = Color3.fromRGB(255, 255, 255),
    Increment = 5,
    ValueName = "HP",
    Save      = false,
    Flag      = "lowHpThreshold",
    Callback  = function(Value)
        _G.lowHpThreshold = Value
        saveConfig()
    end
})

local ConfigTab = Window:MakeTab({
    Name        = "Config",
    Icon        = "rbxassetid://4483345998",
    PremiumOnly = false
})

ConfigTab:AddButton({
    Name = "Reset Config",
    Callback = function()
        _G.flightSpeed        = defaultConfig.flightSpeed
        _G.vendingPoliceRange = defaultConfig.vendingPoliceRange
        _G.lowHpThreshold     = defaultConfig.lowHpThreshold
        saveConfig()
        OrionLib:MakeNotification({
            Name    = "Success",
            Content = "Config reset & saved.",
            Image   = "rbxassetid://4483345998",
            Time    = 4
        })
    end
})

ConfigTab:AddButton({
    Name = "Save Config now",
    Callback = function()
        saveConfig()
        OrionLib:MakeNotification({
            Name    = "Saved",
            Content = "Config saved to " .. CONFIG_FILE,
            Image   = "rbxassetid://4483345998",
            Time    = 4
        })
    end
})

OrionLib:Init()
