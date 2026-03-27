local Players             = game:GetService("Players")
local TweenService        = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui          = game:GetService("StarterGui")
local Workspace           = game:GetService("Workspace")
local TeleportService     = game:GetService("TeleportService")
local HttpService         = game:GetService("HttpService")

local queue_on_teleport = syn and syn.queue_on_teleport or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
local plr = Players.LocalPlayer

local EJw = game:GetService("ReplicatedStorage"):WaitForChild("EJw")
local RemoteEvents = {
    RobEvent = EJw:WaitForChild("a3126821-130a-4135-80e1-1d28cece4007"),
    SellItem = EJw:WaitForChild("eb233e6a-acb9-4169-acb9-129fe8cb06bb"),
}

local VENDING_COLLECT_CODE   = "wRl"
local ProximityPromptTimeBet = 1.1 -- Maximale Geschwindigkeit für das Aufsammeln

_G.vendingActive      = false
_G.flightSpeed        = 240 
_G.vendingPoliceRange = 55

local vendingLoopThread    = nil
local instantCollectThread = nil
local teleportActive       = false
local currentTween         = nil
local currentTweenConn      = nil

local SERVERHOP_POSITION = Vector3.new(-1292.9005126953125, -2, 3685.330810546875)
local DROP_Y             = -2

-- Charakter-Hilfsfunktion
local function getChar()
    local char = plr.Character
    if not char then return nil, nil, nil end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    return char, hum, root
end

-- UI Benachrichtigung
local function notify(title, text)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text  = text,
        Time  = 3
    })
end

-- Stop Funktion für Tweens
local function stopCurrentTween()
    if currentTween then currentTween:Cancel(); currentTween = nil end
    if currentTweenConn then currentTweenConn:Disconnect(); currentTweenConn = nil end
    teleportActive = false
end

-- Polizei Check
local function isPoliceNearby()
    local _, _, root = getChar()
    if not root then return false end
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

-- SAMMLER LOGIK (Vollständig & Repariert)
local function startAutoCollect()
    local dropsFolder = Workspace:WaitForChild("Drops")
    local myName = plr.Name
    local collected = {}

    local function collect(obj)
        if collected[obj] or obj.Transparency ~= 0 then return end
        collected[obj] = true
        task.spawn(function()
            RemoteEvents.RobEvent:FireServer(obj, VENDING_COLLECT_CODE, true)
            task.wait(ProximityPromptTimeBet)
            RemoteEvents.RobEvent:FireServer(obj, VENDING_COLLECT_CODE, false)
            task.wait(1)
            collected[obj] = nil
        end)
    end

    -- Listener für neue Drops
    dropsFolder.ChildAdded:Connect(function(obj)
        if _G.vendingActive and obj.Name == myName then
            task.wait(0.1)
            collect(obj)
        end
    end)

    -- Permanenter Scan Loop
    while _G.vendingActive do
        for _, obj in ipairs(dropsFolder:GetChildren()) do
            if obj.Name == myName and obj:IsA("MeshPart") then
                collect(obj)
            end
        end
        task.wait(0.5)
    end
end

-- Fahrzeug Einsteigen
local function enterVehicle()
    local vehicle = Workspace.Vehicles:FindFirstChild(plr.Name)
    if not vehicle then return nil end
    local driveSeat = vehicle:FindFirstChild("DriveSeat", true) or vehicle:FindFirstChildWhichIsA("VehicleSeat", true)
    if driveSeat then
        local _, hum, hrp = getChar()
        if hum and hrp then
            hrp.CFrame = driveSeat.CFrame
            task.wait(0.1)
            driveSeat:Sit(hum)
        end
        return driveSeat
    end
    return nil
end

-- TWEENING (Mit Jitter gegen Kick)
local function tweenTo(destination)
    if teleportActive then stopCurrentTween() end
    teleportActive = true

    local driveSeat = enterVehicle()
    if not driveSeat then teleportActive = false; return false end
    local vehicle = driveSeat.Parent
    vehicle.PrimaryPart = driveSeat

    local targetCF = (typeof(destination) == "CFrame") and destination or CFrame.new(destination)
    local distance = (vehicle:GetPivot().Position - targetCF.Position).Magnitude

    if distance > 2 then
        local duration = distance / _G.flightSpeed
        local val = Instance.new("CFrameValue")
        val.Value = vehicle:GetPivot()

        currentTweenConn = val.Changed:Connect(function(newCF)
            vehicle:PivotTo(newCF)
            -- Jitter & Anti-Stuck
            driveSeat.AssemblyLinearVelocity = Vector3.new(0, 0.01, 0)
        end)

        currentTween = TweenService:Create(val, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Value = targetCF})
        currentTween:Play()
        currentTween.Completed:Wait()
        currentTweenConn:Disconnect()
        val:Destroy()
    end
    teleportActive = false
    return true
end

-- Vending Suche
local function findNearestVending()
    local folder = Workspace:FindFirstChild("Robberies") and Workspace.Robberies:FindFirstChild("VendingMachines")
    if not folder then return nil end
    local _, _, root = getChar()
    local nearest, minDist = nil, math.huge
    for _, model in ipairs(folder:GetChildren()) do
        local light = model:FindFirstChild("Light")
        if light and math.abs(light.Color.G - (147/255)) < 0.1 then
            local dist = (light.Position - root.Position).Magnitude
            if dist < minDist then
                minDist = dist
                nearest = model
            end
        end
    end
    return nearest
end

-- RAUB LOGIK (10 Schläge & Sammeln)
local function VendingRob(targetVending)
    local glass = targetVending:FindFirstChild("Glass")
    if not glass then return false end

    -- Flug zum Ziel
    local targetPos = glass.Position - glass.CFrame.LookVector * 12
    if not tweenTo(CFrame.lookAt(targetPos, glass.Position)) then return false end

    local _, hum, root = getChar()
    if hum then hum.Sit = false end
    task.wait(0.4)

    if isPoliceNearby() then return false end

    -- Zum Glas laufen
    root.CFrame = CFrame.lookAt(glass.Position - glass.CFrame.LookVector * 1.5, glass.Position)
    task.wait(0.2)

    -- EXAKT 10 MAL SCHLAGEN
    for i = 1, 10 do
        if isPoliceNearby() then 
            notify("Police!", "Fleeing to next Vending...")
            return false 
        end
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        task.wait(0.2) -- Schnelleres Schlagen
    end

    -- Kurz warten bis alle Items gedroppt sind
    task.wait(0.5)
    return true
end

-- SERVER HOP
local function flyUpAndHop()
    notify("Server Hop", "Next Server...")
    local driveSeat = enterVehicle()
    if driveSeat then
        tweenTo(CFrame.new(SERVERHOP_POSITION + Vector3.new(0, 500, 0)))
    end
    
    if queue_on_teleport then
        pcall(function() queue_on_teleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/fluxgitscripts/vending-rob/refs/heads/main/.lua'))()") end)
    end

    local success, servers = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")).data
    end)

    if success then
        for _, server in pairs(servers) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, plr)
                task.wait(5)
            end
        end
    end
    TeleportService:Teleport(game.PlaceId, plr)
end

-- MAIN LOOP
local function mainLoop()
    while _G.vendingActive do
        if isPoliceNearby() then
            enterVehicle()
            local nextTarget = findNearestVending()
            if nextTarget then VendingRob(nextTarget) else flyUpAndHop() end
        else
            local target = findNearestVending()
            if not target then
                flyUpAndHop()
                break
            end
            VendingRob(target)
        end
        task.wait(1)
    end
end

-- UI INITIALISIERUNG (ORION)
local OrionLib = loadstring(game:HttpGet("https://moon-hub.pages.dev/orion.lua"))()
local Window = OrionLib:MakeWindow({Name = "MoonHub - Vending Rob PRO", SaveConfig = true, ConfigFolder = "VendingRobConfig"})
local MainTab = Window:MakeTab({Name = "Main", Icon = "rbxassetid://4483345998"})

MainTab:AddToggle({
    Name = "Activate Vending Rob",
    Default = true,
    Callback = function(Value)
        _G.vendingActive = Value
        if Value then
            task.spawn(startAutoCollect)
            vendingLoopThread = task.spawn(mainLoop)
        else
            if vendingLoopThread then task.cancel(vendingLoopThread) end
            stopCurrentTween()
        end
    end
})

MainTab:AddSlider({
    Name = "Flight Speed",
    Min = 50, Max = 400, Default = 240,
    Callback = function(Value) _G.flightSpeed = Value end
})

MainTab:AddSlider({
    Name = "Police Range",
    Min = 30, Max = 150, Default = 55,
    Callback = function(Value) _G.vendingPoliceRange = Value end
})

OrionLib:Init()
