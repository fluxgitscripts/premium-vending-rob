local Players             = game:GetService("Players")
local TweenService        = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui          = game:GetService("StarterGui")
local Workspace           = game:GetService("Workspace")

local plr = Players.LocalPlayer

local EJw = game:GetService("ReplicatedStorage"):WaitForChild("EJw")
local RemoteEvents = {
    RobEvent = EJw:WaitForChild("a3126821-130a-4135-80e1-1d28cece4007"),
    SellItem = EJw:WaitForChild("eb233e6a-acb9-4169-acb9-129fe8cb06bb"),
}

local VENDING_COLLECT_CODE   = "wRl"
local ProximityPromptTimeBet = 2.5

_G.vendingActive      = false
_G.flightSpeed        = 160
_G.vendingPoliceRange = 55

local vendingLoopThread    = nil
local instantCollectThread = nil

local DROP_Y             = -5
local SERVERHOP_POSITION = Vector3.new(-1292.9005126953125, DROP_Y, 3685.330810546875)

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

local function getChar()
    local char = plr.Character
    if not char then return nil, nil, nil end
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
        notify("HP Critical!", "Vending Rob paused!")
        return true
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= plr and p.Team and p.Team.Name == "Police" then
            local pChar = p.Character
            if pChar then
                local pRoot = pChar:FindFirstChild("HumanoidRootPart")
                if pRoot and (pRoot.Position - root.Position).Magnitude <= _G.vendingPoliceRange then
                    notify("Police Detected", "Vending Rob paused!")
                    return true
                end
            end
        end
    end

    return false
end

-- ============================================================
-- FLEE (Wegfliegen bei Polizei während Pickup)
-- ============================================================
local SAFE_POSITION = Vector3.new(-1292.9005126953125, DROP_Y, 3685.330810546875)

local function fleeFromPolice()
    local _, _, root = getChar()
    if not root then return end
    local safePos = SAFE_POSITION
    -- Find a direction away from nearest cop
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= plr and p.Team and p.Team.Name == "Police" then
            local pChar = p.Character
            if pChar then
                local pRoot = pChar:FindFirstChild("HumanoidRootPart")
                if pRoot then
                    local awayDir = (root.Position - pRoot.Position).Unit
                    safePos = root.Position + awayDir * 120
                    safePos = Vector3.new(safePos.X, DROP_Y, safePos.Z)
                    break
                end
            end
        end
    end

    local vehicle = Workspace.Vehicles:FindFirstChild(plr.Name)
    if vehicle then
        local driveSeat = vehicle:FindFirstChild("DriveSeat", true)
            or vehicle:FindFirstChildWhichIsA("VehicleSeat", true)
        if driveSeat then
            local _, hum, hrp = getChar()
            if hum and hrp then
                hrp.CFrame = driveSeat.CFrame
                task.wait(0.05)
                driveSeat:Sit(hum)
                task.wait(0.2)
            end
            vehicle.PrimaryPart = driveSeat
            local targetCF = CFrame.new(safePos)
            local dist = (vehicle:GetPivot().Position - safePos).Magnitude
            local duration = math.max(dist / _G.flightSpeed, 0.1)
            local val = Instance.new("CFrameValue")
            val.Value = vehicle:GetPivot()
            local conn = val.Changed:Connect(function(newCF)
                vehicle:PivotTo(newCF)
            end)
            local tw = TweenService:Create(val, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Value = targetCF})
            tw:Play()
            tw.Completed:Wait()
            conn:Disconnect()
            val:Destroy()
        end
    end
end

-- ============================================================
-- AUTO COLLECT (Fixed)
-- ============================================================
local function startAutoCollect()
    local Character        = plr.Character or plr.CharacterAdded:Wait()
    local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

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
            if isPoliceNearby() then
                Collected[obj] = nil
                fleeFromPolice()
                return
            end

            RemoteEvents.RobEvent:FireServer(obj, VENDING_COLLECT_CODE, true)

            if isPoliceNearby() then
                RemoteEvents.RobEvent:FireServer(obj, VENDING_COLLECT_CODE, false)
                Collected[obj] = nil
                fleeFromPolice()
                return
            end

            task.wait(ProximityPromptTimeBet)

            if isPoliceNearby() then
                RemoteEvents.RobEvent:FireServer(obj, VENDING_COLLECT_CODE, false)
                Collected[obj] = nil
                fleeFromPolice()
                return
            end

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

    -- Collect drops that are already there when we arrive
    loot()

    -- React instantly to new drops appearing
    local addConn = dropsFolder.ChildAdded:Connect(function(obj)
        if not _G.vendingActive then return end
        task.wait(0.05)
        if not (obj:IsA("MeshPart") and obj.Name == myName and obj.Transparency == 0) then return end
        local _, _, root = getChar()
        if root and (obj.Position - root.Position).Magnitude <= Range then
            collectDrop(obj)
        end
    end)

    -- Also poll in case ChildAdded fires before Transparency is set
    while _G.vendingActive do
        loot()
        task.wait(0.25)
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

-- ============================================================
-- TWEEN TO (_G.TeleportConfig)
-- ============================================================
_G.TeleportConfig.TweenTo = function(destination)
    if _G.TeleportConfig.TeleportActive then stopCurrentTween() end
    _G.TeleportConfig.TeleportActive = true

    local character = plr.Character or plr.CharacterAdded:Wait()
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

-- ============================================================
-- PLR TWEEN
-- ============================================================
local function plrTween(targetCFrame)
    local _, hum, root = getChar()
    if not root then return end
    if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end

    local dist     = (root.Position - targetCFrame.Position).Magnitude
    local duration = math.max(dist / 80, 0.03)
    local startCF  = root.CFrame

    root.CFrame = CFrame.new(root.Position, targetCFrame.Position)
    task.wait(0.05)

    local tVal = Instance.new("CFrameValue")
    tVal.Value = startCF
    local conn = tVal.Changed:Connect(function(newCF)
        if root and root.Parent then
            root.CFrame = CFrame.new(newCF.Position, newCF.Position + targetCFrame.LookVector)
        end
    end)

    local tw = TweenService:Create(tVal, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Value = targetCFrame})
    tw:Play()
    tw.Completed:Wait()
    conn:Disconnect()
    if root and root.Parent then root.CFrame = targetCFrame end
    tVal:Destroy()
end

-- ============================================================
-- VENDING CORE
-- ============================================================
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

    local glass = targetVending:FindFirstChild("Glass")
    if not glass then return false end

    local targetPos = glass.Position - glass.CFrame.LookVector * 12
    local lookDir   = glass.CFrame.RightVector
    tweenTo(CFrame.lookAt(targetPos, targetPos + lookDir))
    task.wait(0.6)

    if isPoliceNearby() then return false end

    local _, hum, _ = getChar()
    if hum then hum.Sit = false end
    task.wait(0.7)

    local offsetPos = glass.Position - glass.CFrame.LookVector * 1.6
    plrTween(CFrame.lookAt(offsetPos, glass.Position))
    task.wait(0.4)

    if isPoliceNearby() then return false end

    for i = 1, 10 do
        if isPoliceNearby() then return false end
        VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode.F, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        task.wait(0.3)
    end

    if isPoliceNearby() then return false end

    task.wait(0.6)
    return true
end

-- ============================================================
-- SERVERHOP
-- ============================================================
local function doServerHop()
    notify("Server Hop", "No Vending Machines – switching server!")
    task.wait(1)
    local TeleportService = game:GetService("TeleportService")
    TeleportService:Teleport(game.PlaceId, plr)
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
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

local function waitUntilReady()
    local char = plr.Character or plr.CharacterAdded:Wait()
    char:WaitForChild("HumanoidRootPart", 15)

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
end

local function vendingMainLoop()
    local count = 0

    waitUntilReady()
    task.wait(1)

    while _G.vendingActive do
        if isPoliceNearby() then
            task.wait(5)
            continue
        end

        local target = findNearestRobbableVending()
        if not target then
            tweenTo(CFrame.new(SERVERHOP_POSITION))
            task.wait(2)
            doServerHop()
            task.wait(10)
            continue
        end

        local result = VendingRob(target)
        if result then
            count = count + 1
        else
            task.wait(4)
        end

        task.wait(1.5)
    end
end

-- ============================================================
-- TOGGLE
-- ============================================================
local function setVendingActive(enabled)
    _G.vendingActive = enabled

    if enabled then
        launchInstantCollect()
        if vendingLoopThread then task.cancel(vendingLoopThread) end
        vendingLoopThread = task.spawn(vendingMainLoop)
        notify("Vending Rob", "Activated!")
    else
        stopInstantCollect()
        if vendingLoopThread then
            task.cancel(vendingLoopThread)
            vendingLoopThread = nil
        end
        stopCurrentTween()
        notify("Vending Rob", "Deactivated!")
    end
end

-- ============================================================
-- GUI
-- ============================================================
local OrionLib = loadstring(game:HttpGet("https://moon-hub.pages.dev/orion.lua"))()

local Window = OrionLib:MakeWindow({
    Name         = "Vending Rob",
    HidePremium  = false,
    Intro        = true,
    IntroText    = "Vending Rob",
    IntroIcon    = "rbxassetid://4483345998",
    SaveConfig   = true,
    ConfigFolder = "VendingRobConfig",
    Icon         = "rbxassetid://4483345998"
})

local MainTab = Window:MakeTab({
    Name        = "Main",
    Icon        = "rbxassetid://4483345998",
    PremiumOnly = false
})

MainTab:AddToggle({
    Name     = "Activate Vending Rob",
    Default  = true,
    Save     = false,
    Flag     = "vendingActive",
    Callback = function(Value)
        setVendingActive(Value)
    end
})

MainTab:AddSlider({
    Name      = "Flight Speed",
    Min       = 50,
    Max       = 250,
    Default   = 160,
    Color     = Color3.fromRGB(255, 255, 255),
    Increment = 10,
    ValueName = "speed",
    Save      = true,
    Flag      = "flightSpeed",
    Callback  = function(Value)
        _G.flightSpeed = Value
    end
})

MainTab:AddSlider({
    Name      = "Police Detection Range",
    Min       = 30,
    Max       = 100,
    Default   = 55,
    Color     = Color3.fromRGB(255, 255, 255),
    Increment = 5,
    ValueName = "studs",
    Save      = true,
    Flag      = "vendingPoliceRange",
    Callback  = function(Value)
        _G.vendingPoliceRange = Value
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
        OrionLib:ResetConfiguration()
        OrionLib:MakeNotification({
            Name    = "Success",
            Content = "Config reset.",
            Image   = "rbxassetid://4483345998",
            Time    = 4
        })
    end
})

OrionLib:Init()
