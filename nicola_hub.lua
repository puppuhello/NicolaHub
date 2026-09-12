--[[
    ╔══════════════════════════════════════════════╗
    ║           NICOLA HUB v5.0                    ║
    ║     Legends Re:Written — Full Autofarm       ║
    ║     Toggle: Right Shift                      ║
    ╚══════════════════════════════════════════════╝
    SLOT SYSTEM:
    1-3 = Magic (skill, activate e torna all'arma)
    4   = Weapon (M1 spam)
    5   = Blessing (M1)
    6   = Spec (opzionale)
]]

if game:GetService("CoreGui"):FindFirstChild("NicolaHub") then
    game:GetService("CoreGui"):FindFirstChild("NicolaHub"):Destroy()
end

local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local UIS=game:GetService("UserInputService")
local CoreGui=game:GetService("CoreGui")
local plr=Players.LocalPlayer
local remotes=RS:FindFirstChild("Remotes")

-- ═══ STATE ═══
local S = {
    afOn=false, fishOn=false, mineOn=false, flyOn=false, noclip=false,
    autoPickup=true, antiAFK=true,
    flySpeed=200, atkSpeed=0.25, atkRange=16, mobHeight=5,
    magicInterval=3, hitboxMult=15,
    vacuum=false, vacuumRange=80,
    kills=0, drops=0, fish=0, ores=0,
    status="Idle", startTime=0,
    selectedMobs={}, selectedOres={},
    primaryTool="",
    useWeapon=true, useBlessing=false,
    useMagic={},
}

-- ═══ CONFIG SAVE/LOAD ═══
local CONFIG_FILE = "NicolaHub_config.json"
local HttpService = game:GetService("HttpService")

local function saveConfig()
    pcall(function()
        local cfg = {
            flySpeed = S.flySpeed,
            atkSpeed = S.atkSpeed,
            atkRange = S.atkRange,
            mobHeight = S.mobHeight,
            magicInterval = S.magicInterval,
            hitboxMult = S.hitboxMult,
            vacuumRange = S.vacuumRange,
            vacuum = S.vacuum,
            autoPickup = S.autoPickup,
            antiAFK = S.antiAFK,
            noclip = S.noclip,
            primaryTool = S.primaryTool,
            selectedMobs = S.selectedMobs,
            selectedOres = S.selectedOres,
            useMagic = S.useMagic,
        }
        writefile(CONFIG_FILE, HttpService:JSONEncode(cfg))
        print("[NH] Config salvata!")
    end)
end

local function loadConfig()
    pcall(function()
        if not isfile(CONFIG_FILE) then return end
        local data = readfile(CONFIG_FILE)
        local cfg = HttpService:JSONDecode(data)
        if cfg.flySpeed then S.flySpeed = cfg.flySpeed end
        if cfg.atkSpeed then S.atkSpeed = cfg.atkSpeed end
        if cfg.atkRange then S.atkRange = cfg.atkRange end
        if cfg.mobHeight then S.mobHeight = cfg.mobHeight end
        if cfg.magicInterval then S.magicInterval = cfg.magicInterval end
        if cfg.hitboxMult then S.hitboxMult = cfg.hitboxMult end
        if cfg.vacuumRange then S.vacuumRange = cfg.vacuumRange end
        if cfg.vacuum ~= nil then S.vacuum = cfg.vacuum end
        if cfg.autoPickup ~= nil then S.autoPickup = cfg.autoPickup end
        if cfg.antiAFK ~= nil then S.antiAFK = cfg.antiAFK end
        if cfg.noclip ~= nil then S.noclip = cfg.noclip end
        if cfg.primaryTool then S.primaryTool = cfg.primaryTool end
        if cfg.selectedMobs then S.selectedMobs = cfg.selectedMobs end
        if cfg.selectedOres then S.selectedOres = cfg.selectedOres end
        if cfg.useMagic then S.useMagic = cfg.useMagic end
        print("[NH] Config caricata!")
    end)
end

-- carica config all'avvio
loadConfig()

local C = {
    bg=Color3.fromRGB(18,18,22), sidebar=Color3.fromRGB(25,25,32),
    content=Color3.fromRGB(32,32,40), header=Color3.fromRGB(20,20,26),
    card=Color3.fromRGB(38,38,48), dark=Color3.fromRGB(14,14,18),
    green=Color3.fromRGB(72,199,142), red=Color3.fromRGB(235,60,60),
    orange=Color3.fromRGB(255,170,40), cyan=Color3.fromRGB(40,200,220),
    text=Color3.fromRGB(230,230,235), dim=Color3.fromRGB(140,140,155),
    border=Color3.fromRGB(45,45,55), accent=Color3.fromRGB(72,199,142),
    toggleOff=Color3.fromRGB(55,55,65), check=Color3.fromRGB(72,199,142),
    uncheck=Color3.fromRGB(55,55,65), panel=Color3.fromRGB(38,38,48),
    divider=Color3.fromRGB(45,45,55), slider=Color3.fromRGB(45,45,55),
}

-- ═══ UTILS ═══
local function chr() return plr.Character end
local function hrpf() local c=chr() return c and c:FindFirstChild("HumanoidRootPart") end
local function humf() local c=chr() return c and c:FindFirstChildOfClass("Humanoid") end
local function alive()
    local c = plr.Character
    if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    local r = c:FindFirstChild("HumanoidRootPart")
    return h and r and h.Health > 0
end
local function mobHP(m) local h=m:FindFirstChild("Health") return h and h.Value or 0 end
local function mobMaxHP(m) local h=m:FindFirstChild("MaxHealth") return h and h.Value or 0 end
local function mobAlive(m) return m and m.Parent and mobHP(m)>0 end
local function mobPos(m)
    for _,d in pairs(m:GetDescendants()) do if d:IsA("BasePart") then return d.Position end end
    local ok,p=pcall(function() return m:GetPivot().Position end) return ok and p or nil
end
local function elapsed()
    if S.startTime==0 then return "00:00" end
    local e=tick()-S.startTime return string.format("%02d:%02d",math.floor(e/60),math.floor(e%60))
end
local function oreBase(n) return n:gsub("%d+$","") end
local function mobBase(n) return n:gsub("%d+$","") end

-- ═══ HITBOX EXPANSION ═══
local expandedMobs = {} -- track which mobs we expanded

local function expandHitbox(mob)
    if not mob or not mob.Parent then return end
    if expandedMobs[mob] then return end -- già espanso
    expandedMobs[mob] = true

    pcall(function()
        for _, part in pairs(mob:GetDescendants()) do
            if part:IsA("BasePart") then
                if not part:GetAttribute("NHorig") then
                    part:SetAttribute("NHorig", true)
                    part:SetAttribute("NHsx", part.Size.X)
                    part:SetAttribute("NHsy", part.Size.Y)
                    part:SetAttribute("NHsz", part.Size.Z)
                    part.Size = part.Size * S.hitboxMult
                    part.Transparency = 1
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function shrinkHitbox(mob)
    if not mob or not mob.Parent then return end
    expandedMobs[mob] = nil

    pcall(function()
        for _, part in pairs(mob:GetDescendants()) do
            if part:IsA("BasePart") and part:GetAttribute("NHorig") then
                local sx = part:GetAttribute("NHsx") or part.Size.X
                local sy = part:GetAttribute("NHsy") or part.Size.Y
                local sz = part:GetAttribute("NHsz") or part.Size.Z
                part.Size = Vector3.new(sx, sy, sz)
                part:SetAttribute("NHorig", nil)
            end
        end
    end)
end

-- espandi hitbox di TUTTI i mob selezionati nella mappa
local function expandAllMobs()
    local mf = workspace:FindFirstChild("Mobs")
    if not mf then return end
    for _, m in pairs(mf:GetChildren()) do
        if mobAlive(m) then
            local base = mobBase(m.Name)
            if S.selectedMobs[base] or S.selectedMobs[m.Name] then
                expandHitbox(m)
            end
        end
    end
end

-- ═══ MOB VACUUM ═══
local function vacuumMobs()
    if not S.vacuum then return end
    local r = hrpf()
    if not r then return end
    local myPos = r.Position
    local mf = workspace:FindFirstChild("Mobs")
    if not mf then return end

    -- punto davanti al player dove stackare i mob
    local stackPos = myPos + Vector3.new(0, -S.mobHeight + 2, 0)

    for _, m in pairs(mf:GetChildren()) do
        if not mobAlive(m) then continue end
        local base = mobBase(m.Name)
        if not S.selectedMobs[base] and not S.selectedMobs[m.Name] then continue end

        -- check distanza
        local mPos = mobPos(m)
        if not mPos then continue end
        local dist = (myPos - mPos).Magnitude
        if dist > S.vacuumRange or dist < 3 then continue end

        -- sposta tutte le parti del mob verso il player
        pcall(function()
            local offset = CFrame.new(stackPos) - m:GetPivot()
            for _, part in pairs(m:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CFrame = part.CFrame + offset.Position
                    part.Velocity = Vector3.zero
                    part.CanCollide = false
                    part.Anchored = false
                end
            end
        end)

        -- prova anche con PivotTo
        pcall(function()
            m:PivotTo(CFrame.new(stackPos))
        end)
    end
end

-- ═══ FLY SYSTEM ═══
local flyBV, flyBG

local function ensureFly()
    local c = plr.Character
    if not c then return false end
    local r = c:FindFirstChild("HumanoidRootPart")
    if not r then return false end

    local bv = r:FindFirstChild("NHfly")
    if not bv then
        bv = Instance.new("BodyVelocity")
        bv.Name="NHfly"
        bv.MaxForce=Vector3.new(math.huge,math.huge,math.huge)
        bv.Velocity=Vector3.zero
        bv.Parent=r
    end
    flyBV = bv

    local bg = r:FindFirstChild("NHgyro")
    if not bg then
        bg = Instance.new("BodyGyro")
        bg.Name="NHgyro"
        bg.MaxTorque=Vector3.new(math.huge,math.huge,math.huge)
        bg.D=100 bg.P=10000
        bg.Parent=r
    end
    flyBG = bg
    return true
end

local function stopFly()
    pcall(function()
        local c=plr.Character
        if c then
            local r=c:FindFirstChild("HumanoidRootPart")
            if r then
                if r:FindFirstChild("NHfly") then r:FindFirstChild("NHfly"):Destroy() end
                if r:FindFirstChild("NHgyro") then r:FindFirstChild("NHgyro"):Destroy() end
            end
        end
    end)
    flyBV=nil flyBG=nil
end

local function flyTo(target)
    if not ensureFly() then return false end
    local r=hrpf() if not r then return false end
    local dir=target-r.Position local dist=dir.Magnitude
    if dist<3 then flyBV.Velocity=Vector3.zero return true end
    flyBV.Velocity=dir.Unit*math.min(S.flySpeed,dist*3)
    if flyBG then flyBG.CFrame=CFrame.new(r.Position,target) end
    return false
end

local function flyStop()
    if flyBV then pcall(function() flyBV.Velocity=Vector3.zero end) end
end

-- ═══ WAIT FOR RESPAWN (ROBUSTO) ═══
local function waitForRespawn(maxWait)
    maxWait = maxWait or 15
    print("[NH] Aspetto respawn...")
    local t0 = tick()

    -- aspetta che il vecchio character muoia e il nuovo arrivi
    while (tick()-t0) < maxWait do
        if not gui or not gui.Parent then return false end
        task.wait(0.5)

        local c = plr.Character
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            local r = c:FindFirstChild("HumanoidRootPart")
            if h and r and h.Health > 0 then
                -- character è vivo! aspetta ancora un po' per stabilità
                task.wait(2)
                -- ri-verifica
                c = plr.Character
                if c then
                    h = c:FindFirstChildOfClass("Humanoid")
                    r = c:FindFirstChild("HumanoidRootPart")
                    if h and r and h.Health > 0 then
                        print("[NH] Respawn OK! HP:" .. h.Health)
                        return true
                    end
                end
            end
        end
    end
    print("[NH] Respawn timeout!")
    return false
end

-- ═══ EQUIP TOOL ═══
local function equipToolByName(toolName)
    local c = plr.Character
    if not c then return nil end
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h then return nil end

    -- già equipaggiato?
    local cur = c:FindFirstChildOfClass("Tool")
    if cur and cur.Name == toolName then return cur end

    -- cerca nel backpack
    local bp = plr:FindFirstChild("Backpack")
    if bp then
        local t = bp:FindFirstChild(toolName)
        if t and t:IsA("Tool") then
            h:EquipTool(t)
            task.wait(0.15)
            return c:FindFirstChildOfClass("Tool")
        end
    end
    return nil
end

local function equipPrimary()
    local c = plr.Character
    if not c then return nil end
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h then return nil end

    -- se c'è un primary tool selezionato, equippa quello
    if S.primaryTool and S.primaryTool ~= "" then
        local cur = c:FindFirstChildOfClass("Tool")
        if cur and cur.Name == S.primaryTool then return cur end -- già equipaggiato
        -- cerca nel backpack
        local bp = plr:FindFirstChild("Backpack")
        if bp then
            local t = bp:FindFirstChild(S.primaryTool)
            if t and t:IsA("Tool") then
                h:EquipTool(t)
                task.wait(0.15)
                return c:FindFirstChildOfClass("Tool")
            end
        end
        -- potrebbe essere nel character (non equipaggiato correttamente)
        local t2 = c:FindFirstChild(S.primaryTool)
        if t2 and t2:IsA("Tool") then return t2 end
    end

    -- fallback: equippa qualsiasi tool
    local cur = c:FindFirstChildOfClass("Tool")
    if cur then return cur end
    local bp = plr:FindFirstChild("Backpack")
    if bp then
        local t = bp:FindFirstChildOfClass("Tool")
        if t then h:EquipTool(t) task.wait(0.15) return c:FindFirstChildOfClass("Tool") end
    end
    return nil
end
-- alias
local equipAnyTool = equipPrimary

-- ═══ ANTI-CLIMB + ANTI-JUMP + NOCLIP (ULTRA) ═══
local stateConn = nil

local function hookStateChanged(hum)
    if stateConn then pcall(function() stateConn:Disconnect() end) end
    stateConn = hum.StateChanged:Connect(function(_, newState)
        if not (S.afOn or S.fishOn or S.mineOn) then return end
        if newState ~= Enum.HumanoidStateType.Physics
            and newState ~= Enum.HumanoidStateType.Running
            and newState ~= Enum.HumanoidStateType.Dead then
            pcall(function()
                hum:ChangeState(Enum.HumanoidStateType.Physics)
            end)
        end
    end)
end

-- hook iniziale
pcall(function()
    local c = plr.Character
    if c then
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then hookStateChanged(h) end
    end
end)

-- re-hook su ogni respawn
plr.CharacterAdded:Connect(function(newChar)
    local h = newChar:WaitForChild("Humanoid", 10)
    if h then hookStateChanged(h) end
end)

local function disableClimb()
    pcall(function()
        local c = plr.Character
        if not c then return end
        local h = c:FindFirstChildOfClass("Humanoid")
        if not h then return end
        h:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
        h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        h:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
        h:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        h:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
        h:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
        if S.afOn or S.fishOn or S.mineOn then
            h:ChangeState(Enum.HumanoidStateType.Physics)
            h.Jump = false
            -- anche WalkSpeed 0 per evitare che cammini sui muri
            if h.WalkSpeed > 0 then h.WalkSpeed = 0 end
        end
    end)
end

-- noclip anche parti vicine del mondo (muri)
local function noclipNearby()
    pcall(function()
        local r = hrpf()
        if not r then return end
        local pos = r.Position
        -- rendi noclip tutto nel raggio di 30 studs
        for _, part in pairs(workspace:GetPartBoundsInRadius(pos, 30, OverlapParams.new())) do
            if part.CanCollide and not part:IsDescendantOf(plr.Character) then
                part.CanCollide = false
                -- ripristina dopo 2 secondi
                task.delay(2, function()
                    pcall(function() part.CanCollide = true end)
                end)
            end
        end
    end)
end

-- RenderStepped: gira PRIMA della fisica, più prioritario
pcall(function()
    RunService.RenderStepped:Connect(function()
        if S.afOn or S.fishOn or S.mineOn then
            disableClimb()
        end
    end)
end)

RunService.Stepped:Connect(function()
    if S.noclip or S.afOn or S.fishOn or S.mineOn then
        pcall(function()
            local c=plr.Character if c then
                for _,p in pairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide=false end
                end
            end
        end)
        disableClimb()
        if S.afOn or S.fishOn or S.mineOn then noclipNearby() end
    end
end)

-- manual fly
RunService.Heartbeat:Connect(function()
    -- extra noclip
    if S.noclip or S.afOn or S.fishOn or S.mineOn then
        pcall(function()
            local c=plr.Character if c then
                for _,p in pairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide=false end
                end
            end
        end)
        disableClimb()
    end
    -- manual fly
    if S.flyOn and not S.afOn and not S.fishOn and not S.mineOn then
        if not ensureFly() then return end
        local cam=workspace.CurrentCamera local vel=Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then vel=vel+cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then vel=vel-cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then vel=vel-cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then vel=vel+cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then vel=vel+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then vel=vel-Vector3.new(0,1,0) end
        flyBV.Velocity=vel.Magnitude>0 and vel.Unit*S.flySpeed or Vector3.zero
    elseif not S.afOn and not S.fishOn and not S.mineOn then
        if flyBV then stopFly() end
    end
end)

-- ═══ GUI LAYOUT (Tekkit Hub style) ═══
local gui=Instance.new("ScreenGui")
gui.Name="NicolaHub" gui.ResetOnSpawn=false gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling gui.Parent=CoreGui

local main=Instance.new("Frame",gui) main.Name="Main"
main.Size=UDim2.new(0,560,0,420) main.Position=UDim2.new(0.5,-280,0.5,-210)
main.BackgroundColor3=C.bg main.BorderSizePixel=0 main.ClipsDescendants=true
Instance.new("UICorner",main).CornerRadius=UDim.new(0,8)
Instance.new("UIStroke",main).Color=C.border

-- ═══ HEADER ═══
local hdr=Instance.new("Frame",main) hdr.Name="Header" hdr.Size=UDim2.new(1,0,0,38) hdr.BackgroundColor3=C.header hdr.BorderSizePixel=0
local hdrBottom=Instance.new("Frame",hdr) hdrBottom.Size=UDim2.new(1,0,0,1) hdrBottom.Position=UDim2.new(0,0,1,-1) hdrBottom.BackgroundColor3=C.divider hdrBottom.BorderSizePixel=0

local icon=Instance.new("TextLabel",hdr) icon.Text="N" icon.Size=UDim2.new(0,26,0,26) icon.Position=UDim2.new(0,8,0,6)
icon.BackgroundColor3=C.green icon.TextColor3=Color3.new(1,1,1) icon.TextSize=16 icon.Font=Enum.Font.GothamBold
Instance.new("UICorner",icon).CornerRadius=UDim.new(1,0)

local titleLbl=Instance.new("TextLabel",hdr) titleLbl.Text="Nicola Hub" titleLbl.Size=UDim2.new(0,100,1,0) titleLbl.Position=UDim2.new(0,38,0,0)
titleLbl.BackgroundTransparency=1 titleLbl.TextColor3=C.text titleLbl.TextSize=14 titleLbl.Font=Enum.Font.GothamBold titleLbl.TextXAlignment=Enum.TextXAlignment.Left

local verLbl=Instance.new("TextLabel",hdr) verLbl.Text="v5.3" verLbl.Size=UDim2.new(0,40,1,0) verLbl.Position=UDim2.new(0,140,0,0)
verLbl.BackgroundTransparency=1 verLbl.TextColor3=C.dim verLbl.TextSize=11 verLbl.Font=Enum.Font.Gotham verLbl.TextXAlignment=Enum.TextXAlignment.Left

-- resize button
local resBtn=Instance.new("TextButton",hdr) resBtn.Text="⇲" resBtn.Size=UDim2.new(0,28,0,28) resBtn.Position=UDim2.new(1,-64,0,5)
resBtn.BackgroundColor3=C.card resBtn.TextColor3=C.dim resBtn.TextSize=14 resBtn.Font=Enum.Font.GothamBold resBtn.BorderSizePixel=0
Instance.new("UICorner",resBtn).CornerRadius=UDim.new(0,6)

-- close button
local xb=Instance.new("TextButton",hdr) xb.Text="✕" xb.Size=UDim2.new(0,28,0,28) xb.Position=UDim2.new(1,-34,0,5)
xb.BackgroundColor3=C.red xb.TextColor3=Color3.new(1,1,1) xb.TextSize=12 xb.Font=Enum.Font.GothamBold xb.BorderSizePixel=0
Instance.new("UICorner",xb).CornerRadius=UDim.new(0,6)
xb.MouseButton1Click:Connect(function() S.afOn=false S.fishOn=false S.mineOn=false gui:Destroy() end)

-- drag header
local dg,ds,dp=false,nil,nil
hdr.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dg=true ds=i.Position dp=main.Position end end)
hdr.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dg=false end end)
UIS.InputChanged:Connect(function(i) if dg and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-ds main.Position=UDim2.new(dp.X.Scale,dp.X.Offset+d.X,dp.Y.Scale,dp.Y.Offset+d.Y) end end)

-- resize handle (bottom-right corner)
local resHandle=Instance.new("TextButton",main) resHandle.Text="◢" resHandle.Size=UDim2.new(0,18,0,18)
resHandle.Position=UDim2.new(1,-18,1,-18) resHandle.BackgroundTransparency=1
resHandle.TextColor3=C.dim resHandle.TextSize=14 resHandle.Font=Enum.Font.GothamBold resHandle.ZIndex=10
local resizing,resStart,sizeStart=false,nil,nil
resHandle.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then resizing=true resStart=i.Position sizeStart=main.Size end end)
resHandle.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then resizing=false end end)
UIS.InputChanged:Connect(function(i) if resizing and i.UserInputType==Enum.UserInputType.MouseMovement then
    local d=i.Position-resStart
    local newW=math.max(400,sizeStart.X.Offset+d.X) local newH=math.max(300,sizeStart.Y.Offset+d.Y)
    main.Size=UDim2.new(0,newW,0,newH)
end end)

-- minimize/restore
local minimized=false local savedSize
resBtn.MouseButton1Click:Connect(function()
    if minimized then main.Size=savedSize minimized=false
    else savedSize=main.Size main.Size=UDim2.new(0,savedSize.X.Offset,0,38) minimized=true end
end)

-- Right Shift toggle
UIS.InputBegan:Connect(function(i,p) if not p and i.KeyCode==Enum.KeyCode.RightShift then main.Visible=not main.Visible end end)

-- ═══ SIDEBAR ═══
local sidebar=Instance.new("Frame",main) sidebar.Name="Sidebar" sidebar.Size=UDim2.new(0,150,1,-38) sidebar.Position=UDim2.new(0,0,0,38)
sidebar.BackgroundColor3=C.sidebar sidebar.BorderSizePixel=0
local sideDiv=Instance.new("Frame",sidebar) sideDiv.Size=UDim2.new(0,1,1,0) sideDiv.Position=UDim2.new(1,0,0,0) sideDiv.BackgroundColor3=C.divider sideDiv.BorderSizePixel=0
local sideScroll=Instance.new("ScrollingFrame",sidebar) sideScroll.Size=UDim2.new(1,0,1,0) sideScroll.BackgroundTransparency=1
sideScroll.BorderSizePixel=0 sideScroll.ScrollBarThickness=0 sideScroll.CanvasSize=UDim2.new(0,0,0,0) sideScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
local sLay=Instance.new("UIListLayout",sideScroll) sLay.Padding=UDim.new(0,0) sLay.SortOrder=Enum.SortOrder.LayoutOrder
local sPad=Instance.new("UIPadding",sideScroll) sPad.PaddingTop=UDim.new(0,8)

-- ═══ CONTENT AREA ═══
local contentArea=Instance.new("Frame",main) contentArea.Name="Content" contentArea.Size=UDim2.new(1,-151,1,-38) contentArea.Position=UDim2.new(0,151,0,38)
contentArea.BackgroundColor3=C.content contentArea.BorderSizePixel=0

-- sidebar tabs & content pages
local allPages={}
local allTabBtns={}
local activeTab=""
local layoutIdx=0

local function addCategory(catName)
    layoutIdx=layoutIdx+1
    local cl=Instance.new("TextLabel",sideScroll) cl.Text=catName cl.Size=UDim2.new(1,0,0,28)
    cl.BackgroundTransparency=1 cl.TextColor3=C.dim cl.TextSize=10 cl.Font=Enum.Font.GothamBold
    cl.TextXAlignment=Enum.TextXAlignment.Left cl.LayoutOrder=layoutIdx
    local clPad=Instance.new("UIPadding",cl) clPad.PaddingLeft=UDim.new(0,14) clPad.PaddingTop=UDim.new(0,6)
end

local function switchTab(tabName)
    for n,pg in pairs(allPages) do pg.Visible=(n==tabName) end
    for n,bt in pairs(allTabBtns) do
        bt.BackgroundColor3=(n==tabName) and C.card or C.sidebar
        bt.TextColor3=(n==tabName) and C.text or C.dim
        bt.Font=(n==tabName) and Enum.Font.GothamBold or Enum.Font.Gotham
        local ind=bt:FindFirstChild("Indicator")
        if ind then ind.Visible=(n==tabName) end
    end
    activeTab=tabName
end

local function addTab(tabName)
    layoutIdx=layoutIdx+1
    local tb=Instance.new("TextButton",sideScroll) tb.Text="  "..tabName tb.Size=UDim2.new(1,0,0,30)
    tb.BackgroundColor3=C.sidebar tb.TextColor3=C.dim tb.TextSize=12 tb.Font=Enum.Font.Gotham
    tb.TextXAlignment=Enum.TextXAlignment.Left tb.BorderSizePixel=0 tb.LayoutOrder=layoutIdx
    local tbPad=Instance.new("UIPadding",tb) tbPad.PaddingLeft=UDim.new(0,12)
    local indicator=Instance.new("Frame",tb) indicator.Name="Indicator" indicator.Size=UDim2.new(0,3,0.6,0) indicator.Position=UDim2.new(0,0,0.2,0)
    indicator.BackgroundColor3=C.green indicator.BorderSizePixel=0 indicator.Visible=false
    Instance.new("UICorner",indicator).CornerRadius=UDim.new(0,2)

    local page=Instance.new("ScrollingFrame",contentArea) page.Size=UDim2.new(1,0,1,0) page.BackgroundTransparency=1
    page.BorderSizePixel=0 page.ScrollBarThickness=3 page.ScrollBarImageColor3=C.green
    page.CanvasSize=UDim2.new(0,0,0,0) page.AutomaticCanvasSize=Enum.AutomaticSize.Y page.Visible=false
    local pLay=Instance.new("UIListLayout",page) pLay.Padding=UDim.new(0,4)
    local pPad=Instance.new("UIPadding",page) pPad.PaddingTop=UDim.new(0,10) pPad.PaddingBottom=UDim.new(0,10) pPad.PaddingLeft=UDim.new(0,14) pPad.PaddingRight=UDim.new(0,14)

    allPages[tabName]=page
    allTabBtns[tabName]=tb

    tb.MouseButton1Click:Connect(function() switchTab(tabName) end)

    return page
end

-- build sidebar — 5 tabs semplici
local fp=addTab("Farm")
local fishP=addTab("Fishing")
local mineP=addTab("Mining")
local playerP=addTab("Player")
local cfgP=addTab("Config")

-- activate first tab
switchTab("Farm")

-- ═══ UI HELPERS ═══
local function sec(p,t)
    local f=Instance.new("Frame",p) f.Size=UDim2.new(1,0,0,16) f.BackgroundTransparency=1
    local l=Instance.new("TextLabel",f) l.Text="─ "..t.." ─" l.Size=UDim2.new(1,0,1,0)
    l.BackgroundTransparency=1 l.TextColor3=C.accent l.TextSize=10 l.Font=Enum.Font.GothamBold
end

local function lbl(p,t)
    local l=Instance.new("TextLabel",p) l.Text=t l.Size=UDim2.new(1,0,0,16) l.BackgroundTransparency=1
    l.TextColor3=C.text l.TextSize=11 l.Font=Enum.Font.Gotham l.TextXAlignment=Enum.TextXAlignment.Left
    Instance.new("UIPadding",l).PaddingLeft=UDim.new(0,8) return l
end

local function btn(p,t,col,cb)
    local b=Instance.new("TextButton",p) b.Text=t b.Size=UDim2.new(1,0,0,26) b.BackgroundColor3=col
    b.TextColor3=Color3.new(1,1,1) b.TextSize=11 b.Font=Enum.Font.GothamBold b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    if cb then b.MouseButton1Click:Connect(cb) end return b
end

local function makeToggle(p,t,def,cb,desc)
    local f=Instance.new("Frame",p) f.Size=UDim2.new(1,0,0,desc and 48 or 32) f.BackgroundColor3=C.card f.BorderSizePixel=0
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,6)
    local fPad=Instance.new("UIPadding",f) fPad.PaddingLeft=UDim.new(0,12) fPad.PaddingRight=UDim.new(0,12)
    -- title
    local l=Instance.new("TextLabel",f) l.Text=t l.Size=UDim2.new(1,-56,0,18) l.Position=UDim2.new(0,0,0,desc and 6 or 7)
    l.BackgroundTransparency=1 l.TextColor3=C.text l.TextSize=13 l.Font=Enum.Font.GothamBold l.TextXAlignment=Enum.TextXAlignment.Left
    -- description
    if desc then
        local d=Instance.new("TextLabel",f) d.Text=desc d.Size=UDim2.new(1,-56,0,16) d.Position=UDim2.new(0,0,0,24)
        d.BackgroundTransparency=1 d.TextColor3=C.dim d.TextSize=10 d.Font=Enum.Font.Gotham d.TextXAlignment=Enum.TextXAlignment.Left
    end
    -- pill toggle
    local bg=Instance.new("Frame",f) bg.Size=UDim2.new(0,40,0,20) bg.Position=UDim2.new(1,-40,0.5,-10) bg.BorderSizePixel=0
    bg.BackgroundColor3=def and C.green or C.toggleOff
    Instance.new("UICorner",bg).CornerRadius=UDim.new(1,0)
    local dot=Instance.new("Frame",bg) dot.Size=UDim2.new(0,16,0,16) dot.BackgroundColor3=Color3.new(1,1,1) dot.BorderSizePixel=0
    dot.Position=def and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
    Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
    local on=def
    local obj={frame=f,label=l}
    function obj.isOn() return on end
    function obj.setOn(v) on=v
        TweenService:Create(bg,TweenInfo.new(0.15),{BackgroundColor3=on and C.green or C.toggleOff}):Play()
        TweenService:Create(dot,TweenInfo.new(0.15),{Position=on and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)}):Play()
    end
    local b2=Instance.new("TextButton",f) b2.Text="" b2.Size=UDim2.new(1,0,1,0) b2.BackgroundTransparency=1
    b2.MouseButton1Click:Connect(function() on=not on obj.setOn(on) if cb then cb(on) end end)
    return obj
end

local function makeSlider(p,t,mn,mx,df,cb)
    local f=Instance.new("Frame",p) f.Size=UDim2.new(1,0,0,38) f.BackgroundColor3=C.panel f.BorderSizePixel=0
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,6)
    local vl=Instance.new("TextLabel",f) vl.Size=UDim2.new(1,-10,0,16) vl.Position=UDim2.new(0,8,0,1)
    vl.BackgroundTransparency=1 vl.TextColor3=C.text vl.TextSize=10 vl.Font=Enum.Font.Gotham
    vl.TextXAlignment=Enum.TextXAlignment.Left vl.Text=t..": "..math.floor(df)
    local tr=Instance.new("Frame",f) tr.Size=UDim2.new(1,-20,0,6) tr.Position=UDim2.new(0,10,0,24)
    tr.BackgroundColor3=C.dark tr.BorderSizePixel=0 Instance.new("UICorner",tr).CornerRadius=UDim.new(1,0)
    local fr=math.clamp((df-mn)/(mx-mn),0,1)
    local fl=Instance.new("Frame",tr) fl.Size=UDim2.new(fr,0,1,0) fl.BackgroundColor3=C.accent fl.BorderSizePixel=0
    Instance.new("UICorner",fl).CornerRadius=UDim.new(1,0)
    local kn=Instance.new("Frame",fl) kn.Size=UDim2.new(0,10,0,10) kn.Position=UDim2.new(1,-5,0.5,-5)
    kn.BackgroundColor3=Color3.new(1,1,1) kn.BorderSizePixel=0 Instance.new("UICorner",kn).CornerRadius=UDim.new(1,0)
    local sb=Instance.new("TextButton",tr) sb.Text="" sb.Size=UDim2.new(1,0,1,12) sb.Position=UDim2.new(0,0,0,-6) sb.BackgroundTransparency=1
    local sd=false
    sb.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sd=true end end)
    sb.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sd=false end end)
    local function upd(x) local rel=math.clamp((x-tr.AbsolutePosition.X)/tr.AbsoluteSize.X,0,1)
        fl.Size=UDim2.new(rel,0,1,0) local val=math.floor(mn+rel*(mx-mn)) vl.Text=t..": "..val if cb then cb(val) end
    end
    UIS.InputChanged:Connect(function(i) if sd and i.UserInputType==Enum.UserInputType.MouseMovement then upd(i.Position.X) end end)
    sb.MouseButton1Click:Connect(function() upd(UIS:GetMouseLocation().X) end)
end

local function makeChecklist(parent, items, stateTable)
    local container=Instance.new("Frame",parent) container.Size=UDim2.new(1,0,0,0)
    container.BackgroundColor3=C.panel container.BorderSizePixel=0 container.AutomaticSize=Enum.AutomaticSize.Y
    Instance.new("UICorner",container).CornerRadius=UDim.new(0,6)
    local pad=Instance.new("UIPadding",container) pad.PaddingTop=UDim.new(0,4) pad.PaddingBottom=UDim.new(0,4) pad.PaddingLeft=UDim.new(0,6) pad.PaddingRight=UDim.new(0,6)
    Instance.new("UIListLayout",container).Padding=UDim.new(0,2)
    for _,item in ipairs(items) do
        local row=Instance.new("Frame",container) row.Size=UDim2.new(1,0,0,20) row.BackgroundTransparency=1
        local box=Instance.new("Frame",row) box.Size=UDim2.new(0,14,0,14) box.Position=UDim2.new(0,0,0.5,-7)
        box.BackgroundColor3=stateTable[item.name] and C.check or C.uncheck box.BorderSizePixel=0
        Instance.new("UICorner",box).CornerRadius=UDim.new(0,3)
        local tick=Instance.new("TextLabel",box) tick.Text="✓" tick.Size=UDim2.new(1,0,1,0)
        tick.BackgroundTransparency=1 tick.TextColor3=Color3.new(1,1,1) tick.TextSize=10 tick.Font=Enum.Font.GothamBold
        tick.Visible=stateTable[item.name]==true
        local txt=item.name if item.count then txt=txt.." ("..item.count..")" end
        if item.hp then txt=txt.." HP:"..item.hp end
        local label=Instance.new("TextLabel",row) label.Text=txt
        label.Size=UDim2.new(1,-20,1,0) label.Position=UDim2.new(0,20,0,0) label.BackgroundTransparency=1
        label.TextColor3=C.text label.TextSize=11 label.Font=Enum.Font.Gotham label.TextXAlignment=Enum.TextXAlignment.Left
        local cb2=Instance.new("TextButton",row) cb2.Text="" cb2.Size=UDim2.new(1,0,1,0) cb2.BackgroundTransparency=1
        cb2.MouseButton1Click:Connect(function()
            stateTable[item.name]=not stateTable[item.name]
            box.BackgroundColor3=stateTable[item.name] and C.check or C.uncheck
            tick.Visible=stateTable[item.name]
        end)
    end
    return container
end

-- ═══ COLLAPSIBLE DROPDOWN ═══
local function makeDropdown(parent, title, items, stateTable, refreshCb)
    local wrapper = Instance.new("Frame",parent) wrapper.Size=UDim2.new(1,0,0,0)
    wrapper.BackgroundTransparency=1 wrapper.AutomaticSize=Enum.AutomaticSize.Y
    Instance.new("UIListLayout",wrapper).Padding=UDim.new(0,0)

    -- count selected
    local function countSel()
        local n=0 for _,item in ipairs(items) do if stateTable[item.name] then n=n+1 end end return n
    end

    -- header button
    local header=Instance.new("TextButton",wrapper) header.Size=UDim2.new(1,0,0,28)
    header.BackgroundColor3=C.panel header.BorderSizePixel=0
    header.TextColor3=C.text header.TextSize=12 header.Font=Enum.Font.GothamBold
    header.TextXAlignment=Enum.TextXAlignment.Left
    Instance.new("UICorner",header).CornerRadius=UDim.new(0,6)
    local hPad=Instance.new("UIPadding",header) hPad.PaddingLeft=UDim.new(0,10)

    local arrow = "▶"
    local open = false

    local function updHeader()
        header.Text = (open and "▼ " or "▶ ") .. title .. " (" .. countSel() .. "/" .. #items .. ")"
    end
    updHeader()

    -- dropdown content (hidden by default)
    local content=Instance.new("Frame",wrapper) content.Size=UDim2.new(1,0,0,0)
    content.BackgroundColor3=C.dark content.BorderSizePixel=0 content.Visible=false
    content.AutomaticSize=Enum.AutomaticSize.Y
    Instance.new("UICorner",content).CornerRadius=UDim.new(0,6)
    local cPad=Instance.new("UIPadding",content) cPad.PaddingTop=UDim.new(0,4) cPad.PaddingBottom=UDim.new(0,4) cPad.PaddingLeft=UDim.new(0,6) cPad.PaddingRight=UDim.new(0,6)
    Instance.new("UIListLayout",content).Padding=UDim.new(0,2)

    -- populate items
    local function populate()
        for _,ch in pairs(content:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
        for _,item in ipairs(items) do
            local row=Instance.new("Frame",content) row.Size=UDim2.new(1,0,0,20) row.BackgroundTransparency=1
            local box=Instance.new("Frame",row) box.Size=UDim2.new(0,14,0,14) box.Position=UDim2.new(0,0,0.5,-7)
            box.BackgroundColor3=stateTable[item.name] and C.check or C.uncheck box.BorderSizePixel=0
            Instance.new("UICorner",box).CornerRadius=UDim.new(0,3)
            local tk=Instance.new("TextLabel",box) tk.Text="✓" tk.Size=UDim2.new(1,0,1,0)
            tk.BackgroundTransparency=1 tk.TextColor3=Color3.new(1,1,1) tk.TextSize=10 tk.Font=Enum.Font.GothamBold
            tk.Visible=stateTable[item.name]==true
            local txt=item.name
            if item.count then txt=txt.." ("..item.count..")" end
            if item.hp then txt=txt.." HP:"..item.hp end
            local lb=Instance.new("TextLabel",row) lb.Text=txt
            lb.Size=UDim2.new(1,-20,1,0) lb.Position=UDim2.new(0,20,0,0) lb.BackgroundTransparency=1
            lb.TextColor3=C.text lb.TextSize=11 lb.Font=Enum.Font.Gotham lb.TextXAlignment=Enum.TextXAlignment.Left
            local cb=Instance.new("TextButton",row) cb.Text="" cb.Size=UDim2.new(1,0,1,0) cb.BackgroundTransparency=1
            cb.MouseButton1Click:Connect(function()
                stateTable[item.name]=not stateTable[item.name]
                box.BackgroundColor3=stateTable[item.name] and C.check or C.uncheck
                tk.Visible=stateTable[item.name]
                updHeader()
            end)
        end
    end
    populate()

    header.MouseButton1Click:Connect(function()
        open = not open
        content.Visible = open
        updHeader()
    end)

    -- return wrapper + refresh function
    local obj = {wrapper=wrapper, header=header, content=content}
    function obj.refresh(newItems)
        items = newItems
        populate()
        updHeader()
    end
    return obj
end

-- ═══ FARM PAGE (Farming tab) ═══
local afToggle, fishToggle, mineToggle

afToggle=makeToggle(fp,"Auto Farm",false,function(on)
    S.afOn=on
    if on then
        if S.fishOn then S.fishOn=false fishToggle.setOn(false) end
        if S.mineOn then S.mineOn=false mineToggle.setOn(false) end
        task.spawn(function()
            while S.afOn and gui and gui.Parent do
                local ok, err = pcall(farmLoop)
                if not ok then
                    print("[NH] ⚠ FarmLoop crashato: " .. tostring(err))
                    print("[NH] Riavvio automatico in 3s...")
                    task.wait(3)
                else
                    break
                end
            end
        end)
    end
end,"Universal Auto Farm for Mobs and Bosses.")
local statusLbl=lbl(fp,"Status: Idle")
local statsLbl=lbl(fp,"Kills: 0 | Drops: 0 | 00:00")

-- ═══ ATTACK ═══
sec(fp,"ATTACK")
local primaryDropdown
local primaryLabel=lbl(fp,"Primary: nessuno")

local function scanAllTools()
    local bp=plr:FindFirstChild("Backpack")
    local c=plr.Character
    local allTools={}
    if bp then for _,t in pairs(bp:GetChildren()) do if t:IsA("Tool") then table.insert(allTools,t) end end end
    if c then for _,t in pairs(c:GetChildren()) do if t:IsA("Tool") then table.insert(allTools,t) end end end

    if primaryDropdown then primaryDropdown.wrapper:Destroy() primaryDropdown=nil end

    local pw = Instance.new("Frame",fp) pw.Size=UDim2.new(1,0,0,0)
    pw.BackgroundTransparency=1 pw.AutomaticSize=Enum.AutomaticSize.Y
    Instance.new("UIListLayout",pw).Padding=UDim.new(0,0)

    local ph=Instance.new("TextButton",pw) ph.Size=UDim2.new(1,0,0,32)
    ph.BackgroundColor3=C.card ph.BorderSizePixel=0 ph.TextColor3=C.text ph.TextSize=13
    ph.Font=Enum.Font.GothamBold ph.TextXAlignment=Enum.TextXAlignment.Left
    Instance.new("UICorner",ph).CornerRadius=UDim.new(0,6)
    Instance.new("UIPadding",ph).PaddingLeft=UDim.new(0,12)

    local primOpen = false
    local pc = Instance.new("Frame",pw) pc.Size=UDim2.new(1,0,0,0)
    pc.BackgroundColor3=C.dark pc.BorderSizePixel=0 pc.Visible=false
    pc.AutomaticSize=Enum.AutomaticSize.Y
    Instance.new("UICorner",pc).CornerRadius=UDim.new(0,6)
    local pp=Instance.new("UIPadding",pc) pp.PaddingTop=UDim.new(0,4) pp.PaddingBottom=UDim.new(0,4) pp.PaddingLeft=UDim.new(0,6) pp.PaddingRight=UDim.new(0,6)
    Instance.new("UIListLayout",pc).Padding=UDim.new(0,2)

    local function updPrimHeader()
        local sel = S.primaryTool ~= "" and S.primaryTool or "nessuno"
        ph.Text = (primOpen and "▼ " or "▶ ") .. "🗡 M1 Weapon: " .. sel
        primaryLabel.Text = "✓ Primary: " .. sel
    end

    local function buildPrimList()
        for _,ch in pairs(pc:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
        for _,t in ipairs(allTools) do
            local isSel = (S.primaryTool == t.Name)
            local b = Instance.new("TextButton",pc)
            b.Text = (isSel and "✓ " or "   ") .. t.Name
            b.Size=UDim2.new(1,0,0,24) b.BackgroundColor3=isSel and C.green or C.card
            b.TextColor3=C.text b.TextSize=11 b.Font=Enum.Font.GothamBold b.BorderSizePixel=0
            Instance.new("UICorner",b).CornerRadius=UDim.new(0,4)
            b.MouseButton1Click:Connect(function()
                S.primaryTool = t.Name
                equipPrimary()
                buildPrimList()
                updPrimHeader()
            end)
        end
    end

    buildPrimList()
    updPrimHeader()

    ph.MouseButton1Click:Connect(function()
        primOpen = not primOpen
        pc.Visible = primOpen
        updPrimHeader()
    end)

    primaryDropdown = {wrapper=pw}

    local magicItems = {}
    for _,t in ipairs(allTools) do
        if S.useMagic[t.Name]==nil then S.useMagic[t.Name]=false end
        table.insert(magicItems, {name=t.Name})
    end

    if _magicDropdown then _magicDropdown.wrapper:Destroy() end
    _magicDropdown = makeDropdown(fp, "✨ Magic Skills", magicItems, S.useMagic)
end

local _magicDropdown

btn(fp,"🔄 Refresh Tools & Skills",C.green,function() scanAllTools() end)
task.defer(scanAllTools)

makeSlider(fp,"Magic Interval (sec)",1,10,3,function(v) S.magicInterval=v end)

-- ═══ SETTINGS ═══
sec(fp,"SETTINGS")
makeSlider(fp,"Fly Speed",30,400,S.flySpeed,function(v) S.flySpeed=v saveConfig() end)
makeSlider(fp,"Altezza dal mob",0,30,S.mobHeight,function(v) S.mobHeight=v saveConfig() end)
makeSlider(fp,"Attack Range",5,60,S.atkRange,function(v) S.atkRange=v saveConfig() end)
makeSlider(fp,"Attack Speed (ms)",50,500,math.floor(S.atkSpeed*1000),function(v) S.atkSpeed=v/1000 saveConfig() end)
makeSlider(fp,"Hitbox Expand (x)",1,50,S.hitboxMult,function(v) S.hitboxMult=v saveConfig() end)

-- ═══ MOB & BOSS ═══
sec(fp,"MOB & BOSS")

local mobDropdown, bossDropdown

local function scanMobs()
    local mf=workspace:FindFirstChild("Mobs") if not mf then return end
    local knownBosses={Dragon=true,Hiei=true,Kaze=true,RougePaladin=true,Elsa=true,["Boar King"]=true,Regulus=true}
    local mobC,bossC,mobHP2,bossHP2={},{},{},{}
    for _,m in pairs(mf:GetChildren()) do
        if not mobAlive(m) then continue end
        local base=mobBase(m.Name) local mhp=mobMaxHP(m)
        if knownBosses[base] or knownBosses[m.Name] then
            local bn=knownBosses[base] and base or m.Name
            bossC[bn]=(bossC[bn] or 0)+1 bossHP2[bn]=mhp
        else
            mobC[base]=(mobC[base] or 0)+1 mobHP2[base]=mhp
        end
    end
    local mobItems,bossItems={},{}
    for n,c in pairs(mobC) do
        if S.selectedMobs[n]==nil then S.selectedMobs[n]=true end
        table.insert(mobItems,{name=n,count=c,hp=mobHP2[n]})
    end
    for n,c in pairs(bossC) do
        if S.selectedMobs[n]==nil then S.selectedMobs[n]=false end
        table.insert(bossItems,{name=n,count=c,hp=bossHP2[n]})
    end
    table.sort(mobItems,function(a,b) return a.name<b.name end)
    table.sort(bossItems,function(a,b) return a.name<b.name end)

    if mobDropdown then
        mobDropdown.refresh(mobItems)
    else
        mobDropdown = makeDropdown(fp, "🗡 Mob", mobItems, S.selectedMobs)
    end

    if bossDropdown then
        bossDropdown.refresh(bossItems)
    else
        bossDropdown = makeDropdown(fp, "👑 Boss", bossItems, S.selectedMobs)
    end

    print("[NH] Scan: "..#mobItems.." mob, "..#bossItems.." boss")
end

btn(fp,"🔍 Refresh Mob & Boss",C.green,function() scanMobs() end)
task.defer(scanMobs)

-- ═══ VACUUM ═══
sec(fp,"VACUUM")
makeToggle(fp,"Mob Vacuum",S.vacuum,function(v) S.vacuum=v saveConfig() end,"Risucchia tutti i mob nel raggio verso di te.")
makeSlider(fp,"Vacuum Range",20,200,S.vacuumRange,function(v) S.vacuumRange=v saveConfig() end)

-- ═══ FISH PAGE ═══
fishToggle=makeToggle(fishP,"Auto Fish",false,function(on)
    S.fishOn=on
    if on then
        if S.afOn then S.afOn=false afToggle.setOn(false) end
        if S.mineOn then S.mineOn=false mineToggle.setOn(false) end
        task.spawn(function()
            while S.fishOn and gui and gui.Parent do
                local ok, err = pcall(fishLoop)
                if not ok then print("[NH] FishLoop crash: "..tostring(err)) task.wait(3) else break end
            end
        end)
    end
end,"Pesca automatica nei Fishing Spots.")
local fishStatus=lbl(fishP,"Status: Idle")
local fishStats=lbl(fishP,"Fish: 0")
makeSlider(fishP,"Fly Speed",30,400,120,function(v) S.flySpeed=v end)

-- ═══ MINE PAGE ═══
mineToggle=makeToggle(mineP,"Auto Mine",false,function(on)
    S.mineOn=on
    if on then
        if S.afOn then S.afOn=false afToggle.setOn(false) end
        if S.fishOn then S.fishOn=false fishToggle.setOn(false) end
        task.spawn(function()
            while S.mineOn and gui and gui.Parent do
                local ok, err = pcall(mineLoop)
                if not ok then print("[NH] MineLoop crash: "..tostring(err)) task.wait(3) else break end
            end
        end)
    end
end,"Mina automaticamente i minerali selezionati.")
local mineStatus=lbl(mineP,"Status: Idle")
local mineStats=lbl(mineP,"Ores: 0")
makeSlider(mineP,"Fly Speed",30,400,120,function(v) S.flySpeed=v end)
local oreDropdown

local function scanOres()
    S.selectedOres={}
    local oresF=workspace:FindFirstChild("Ores") if not oresF then return end
    local types,seen,counts={},{},{}
    for _,ore in pairs(oresF:GetChildren()) do
        local base=oreBase(ore.Name) if base=="" then base=ore.Name end
        counts[base]=(counts[base] or 0)+1 if not seen[base] then seen[base]=true table.insert(types,base) end
    end
    table.sort(types)
    local items={} for _,ot in ipairs(types) do S.selectedOres[ot]=true table.insert(items,{name=ot,count=counts[ot]}) end

    if oreDropdown then
        oreDropdown.refresh(items)
    else
        oreDropdown = makeDropdown(mineP, "⛏ Minerali", items, S.selectedOres)
    end
end

btn(mineP,"🔍 Refresh Minerali",C.green,function() scanOres() end)
task.defer(scanOres)

-- ═══ PLAYER PAGE ═══
makeToggle(playerP,"Auto Pickup",S.autoPickup,function(v) S.autoPickup=v saveConfig() end,"Raccoglie automaticamente i drop.")
makeToggle(playerP,"Anti-AFK",S.antiAFK,function(v) S.antiAFK=v saveConfig() end,"Previene il kick per inattività.")
makeToggle(playerP,"Noclip",S.noclip,function(v) S.noclip=v saveConfig() end,"Attraversa muri e oggetti solidi.")
makeToggle(playerP,"Fly",false,function(v) S.flyOn=v end,"Vola liberamente con WASD + Space/Shift.")
makeSlider(playerP,"Fly Speed",30,400,S.flySpeed,function(v) S.flySpeed=v saveConfig() end)
sec(playerP,"TOOLS")
local function refreshTools()
    for _,ch in pairs(playerP:GetChildren()) do if ch:IsA("TextButton") and ch.Name and ch.Name:find("TL_") then ch:Destroy() end end
    local c=chr() local eq=c and c:FindFirstChildOfClass("Tool")
    if eq then local b=btn(playerP,"✓ "..eq.Name,C.green) b.Name="TL_"..eq.Name end
    local bp=plr:FindFirstChild("Backpack")
    if bp then for _,t in pairs(bp:GetChildren()) do if t:IsA("Tool") then
        local b=btn(playerP,t.Name,C.card,function() local h=humf() if h then h:EquipTool(t) end task.wait(0.3) refreshTools() end)
        b.Name="TL_"..t.Name
    end end end
end
btn(playerP,"🔄 Refresh Tools",C.green,function() refreshTools() end)
task.defer(refreshTools)

-- ═══ CONFIG PAGE ═══
local cfgStatus=lbl(cfgP,"Config: NicolaHub_config.json")
btn(cfgP,"💾 Salva Config",C.green,function()
    saveConfig()
    cfgStatus.Text="✓ Config salvata!"
    task.delay(2, function() cfgStatus.Text="Config: NicolaHub_config.json" end)
end)
btn(cfgP,"📂 Carica Config",C.card,function()
    loadConfig()
    cfgStatus.Text="✓ Config caricata! Riesegui lo script per applicare."
    task.delay(3, function() cfgStatus.Text="Config: NicolaHub_config.json" end)
end)
btn(cfgP,"🗑 Reset Config",C.red,function()
    pcall(function()
        if isfile(CONFIG_FILE) then delfile(CONFIG_FILE) end
    end)
    cfgStatus.Text="✓ Config resettata! Riesegui lo script."
    task.delay(3, function() cfgStatus.Text="Config: NicolaHub_config.json" end)
end)
lbl(cfgP,"")
lbl(cfgP,"Le impostazioni vengono salvate")
lbl(cfgP,"automaticamente ogni 30 secondi.")
lbl(cfgP,"Al prossimo avvio, tutto sarà già pronto!")

-- auto-save ogni 30 sec
task.spawn(function() while gui and gui.Parent do
    task.wait(30)
    saveConfig()
end end)

-- ═══ FIND MOB ═══
local function findMob()
    local mf=workspace:FindFirstChild("Mobs") if not mf then return nil,math.huge end
    local r=hrpf() if not r then return nil,math.huge end
    local my=r.Position local best,bestD=nil,math.huge
    for _,m in pairs(mf:GetChildren()) do
        local base=mobBase(m.Name)
        if not S.selectedMobs[base] and not S.selectedMobs[m.Name] then continue end
        if not mobAlive(m) then continue end
        local p=mobPos(m) if not p then continue end
        local d=(my-p).Magnitude if d>3000 then continue end
        if d<bestD then best,bestD=m,d end
    end
    return best,bestD
end

-- ═══ ATTACK (con slots) ═══
local lastMagicTime = 0
local currentTarget = nil -- mob attualmente sotto attacco

local VIM = pcall(function() return game:GetService("VirtualInputManager") end) and game:GetService("VirtualInputManager") or nil

-- firetouchinterest tra Handle del tool e parti del mob (100% hit)
local function touchMob(mob)
    pcall(function()
        local c = plr.Character
        if not c then return end
        local tool = c:FindFirstChildOfClass("Tool")
        if not tool then return end

        -- trova l'handle del tool
        local handle = tool:FindFirstChild("Handle")
        if not handle then
            for _, p in pairs(tool:GetDescendants()) do
                if p:IsA("BasePart") then handle = p break end
            end
        end
        if not handle then return end

        -- tocca TUTTE le parti del mob
        for _, part in pairs(mob:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function()
                    firetouchinterest(handle, part, 0)
                    task.wait()
                    firetouchinterest(handle, part, 1)
                end)
            end
        end
    end)
end

-- click VIM mirato alla posizione del mob sullo schermo
local function clickAtMob(mob)
    if not VIM then return end
    pcall(function()
        local cam = workspace.CurrentCamera
        local mp = mobPos(mob)
        if not mp then
            -- fallback: centro schermo
            local cx = cam.ViewportSize.X / 2
            local cy = cam.ViewportSize.Y / 2
            VIM:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
            task.wait(0.015)
            VIM:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
            return
        end
        -- proietta posizione mob sullo schermo
        local screenPos, onScreen = cam:WorldToViewportPoint(mp)
        local cx, cy
        if onScreen then
            cx = screenPos.X
            cy = screenPos.Y
        else
            cx = cam.ViewportSize.X / 2
            cy = cam.ViewportSize.Y / 2
        end
        VIM:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
        task.wait(0.015)
        VIM:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
    end)
end

local function doM1Attack()
    local c=plr.Character if not c then return end
    local tool=c:FindFirstChildOfClass("Tool")

    -- 1. tool:Activate()
    if tool then pcall(function() tool:Activate() end) end

    -- 2. click VIM mirato al mob
    if currentTarget and currentTarget.Parent then
        clickAtMob(currentTarget)
    elseif VIM then
        pcall(function()
            local cam = workspace.CurrentCamera
            local cx = cam.ViewportSize.X / 2
            local cy = cam.ViewportSize.Y / 2
            VIM:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
            task.wait(0.015)
            VIM:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
        end)
    end

    -- 3. firetouchinterest (garantisce il colpo)
    if currentTarget and currentTarget.Parent then
        touchMob(currentTarget)
    end
end

local function doMagicCycle()
    -- usa ogni magic skill selezionata, poi torna al weapon
    local c=plr.Character if not c then return end
    local h=c:FindFirstChildOfClass("Humanoid") if not h then return end

    for skillName, enabled in pairs(S.useMagic) do
        if not enabled then continue end
        if not S.afOn then return end
        if not alive() then return end

        -- cerca lo skill
        local bp=plr:FindFirstChild("Backpack")
        local tool = nil
        if bp then tool = bp:FindFirstChild(skillName) end
        -- potrebbe essere nel character (equipaggiato)
        if not tool then tool = c:FindFirstChild(skillName) end

        if tool and tool:IsA("Tool") then
            -- equip e attiva
            h:EquipTool(tool)
            task.wait(0.15)
            pcall(function() tool:Activate() end)
            task.wait(0.3)
        end
    end

    -- torna al primary tool
    task.wait(0.1)
    equipPrimary()
end

local function doAttack()
    -- assicura primary tool equipaggiato
    local c = plr.Character
    if not c then return end
    local curTool = c:FindFirstChildOfClass("Tool")
    if not curTool or (S.primaryTool ~= "" and curTool.Name ~= S.primaryTool) then
        equipPrimary()
        task.wait(0.1)
    end

    -- M1 attack
    doM1Attack()

    -- magic cycle periodico
    if tick()-lastMagicTime > S.magicInterval then
        local hasAnyMagic = false
        for _,v in pairs(S.useMagic) do if v then hasAnyMagic=true break end end
        if hasAnyMagic then
            doMagicCycle()
            lastMagicTime = tick()
        end
    end
end

-- ═══ DROPS ═══
local function pickDrops()
    if not S.autoPickup then return end
    local df=workspace:FindFirstChild("Drops") if not df then return end
    local pu=remotes and remotes:FindFirstChild("PickUp")
    local od=remotes and remotes:FindFirstChild("ObtainDrop")
    for _,drop in pairs(df:GetChildren()) do
        if not alive() then break end
        local act=drop:FindFirstChild("active") if act and not act.Value then continue end
        local dx,dy,dz=drop:FindFirstChild("x"),drop:FindFirstChild("y"),drop:FindFirstChild("z")
        if dx and dy and dz then
            local dpos=Vector3.new(dx.Value,dy.Value+3,dz.Value)
            local r=hrpf()
            if r and (r.Position-dpos).Magnitude<300 then
                local arr,t0=false,tick()
                while not arr and (tick()-t0)<3 and alive() and gui.Parent do
                    ensureFly() arr=flyTo(dpos) task.wait(0.05)
                end
                if pu then pcall(function() pu:FireServer(drop) end) end
                if od then pcall(function() od:FireServer(drop) end) end
                pcall(function() local td=drop:FindFirstChild("TheDrop")
                    if td then for _,p in pairs(td:GetDescendants()) do if p:IsA("BasePart") then
                        firetouchinterest(hrpf(),p,0) task.wait(0.05) firetouchinterest(hrpf(),p,1) break
                    end end end end)
                S.drops=S.drops+1 task.wait(0.1)
            end
        end
    end
end

-- ═══ FLY UP (evita terreno) ═══
local function flyUp(height)
    height = height or 50
    if not ensureFly() then return end
    local r = hrpf()
    if not r then return end
    local targetY = r.Position.Y + height
    S.status = "↑ Decollo..."
    print("[NH] Decollo +" .. height .. " studs")
    local t0 = tick()
    while (tick()-t0) < 4 and gui and gui.Parent do
        r = hrpf()
        if not r then break end
        if r.Position.Y >= targetY - 3 then break end
        ensureFly()
        if flyBV then flyBV.Velocity = Vector3.new(0, S.flySpeed, 0) end
        task.wait(0.05)
    end
    if flyBV then flyBV.Velocity = Vector3.zero end
    print("[NH] In quota! Y=" .. math.floor(hrpf() and hrpf().Position.Y or 0))
end

-- ═══ FARM LOOP (ULTRA ROBUSTO) ═══
function farmLoop()
    S.startTime=tick() S.kills=0 S.drops=0 lastMagicTime=0
    print("[NH] ⚡ Farm ON")

    -- DECOLLO INIZIALE
    S.noclip = true -- noclip auto ON
    flyUp(50)
    equipAnyTool()

    -- ANTI-STUCK failsafe
    local lastPos = Vector3.zero
    local stuckTime = 0

    while S.afOn and gui and gui.Parent do
        -- STEP 1: assicura di essere vivo
        local ok1, err1 = pcall(function()
            if not alive() then
                S.status="💀 Morto... respawn"
                print("[NH] Morto! Aspetto respawn...")
                local respawned = waitForRespawn(20)
                if not respawned then
                    print("[NH] Respawn fallito, riprovo...")
                    return -- riprova nel prossimo ciclo
                end
                -- RICREA FLY dopo respawn
                task.wait(1)
                ensureFly()
                flyUp(50)
                -- RIEQUIP tool
                equipAnyTool()
                S.status="✓ Ripreso!"
                print("[NH] Ripreso dopo morte!")
                task.wait(0.5)
            end
        end)

        if not ok1 then print("[NH] Errore step1: "..tostring(err1)) task.wait(1) continue end
        if not alive() then task.wait(0.5) continue end
        if not S.afOn then break end

        -- STEP 2: fly
        local ok2, err2 = pcall(function() ensureFly() end)
        if not ok2 then print("[NH] Errore fly: "..tostring(err2)) task.wait(1) continue end

        -- STEP 3: trova mob
        local mob, dist
        local ok3, err3 = pcall(function() mob, dist = findMob() end)
        if not ok3 then print("[NH] Errore find: "..tostring(err3)) task.wait(1) continue end

        if mob then
            local mhp = mobMaxHP(mob)
            currentTarget = mob -- imposta target per attacco mirato

            -- STEP 4: combatti
            while S.afOn and gui and gui.Parent do
                local ok4, err4 = pcall(function()
                    -- check morte durante fight
                    if not alive() then
                        S.status="💀 Morto in fight..."
                        error("DEAD") -- esce dal pcall, torna al loop principale
                    end

                    if not mobAlive(mob) then error("MOB_DEAD") end
                    ensureFly() -- SEMPRE ricrea fly se necessario
                    expandAllMobs() -- ingrandisci hitbox TUTTI i mob
                    vacuumMobs() -- risucchia mob vicini

                    -- ANTI-STUCK: detecta se fermo per 3 sec
                    local r=hrpf() if not r then error("NO_HRP") end
                    local curPos = r.Position
                    if (curPos - lastPos).Magnitude < 2 then
                        if stuckTime == 0 then
                            stuckTime = tick()
                        elseif tick() - stuckTime > 3 then
                            -- STUCK! tp in alto
                            print("[NH] ⚠ STUCK! TP up")
                            S.status = "⚠ Stuck → TP"
                            pcall(function()
                                r.CFrame = r.CFrame + Vector3.new(0, 50, 0)
                            end)
                            flyUp(30)
                            stuckTime = 0
                        end
                    else
                        stuckTime = 0
                    end
                    lastPos = curPos

                    local curMP=mobPos(mob) if not curMP then error("NO_POS") end
                    local d=(r.Position-curMP).Magnitude
                    local targetP=curMP+Vector3.new(0,S.mobHeight,0)

                    if d>S.atkRange then
                        flyTo(targetP)
                        S.status=mob.Name.." → "..math.floor(d).."m"
                    else
                        flyStop()
                        pcall(function() r.CFrame=CFrame.new(r.Position,curMP) end)
                        if flyBG then pcall(function() flyBG.CFrame=CFrame.new(r.Position,curMP) end) end
                        doAttack()
                        S.status="⚔ "..mob.Name.." ["..mobHP(mob).."/"..mhp.."]"
                    end
                end)

                if not ok4 then
                    if err4=="DEAD" then break end
                    if err4=="MOB_DEAD" or err4=="NO_POS" or err4=="NO_HRP" then break end
                    print("[NH] Fight err: "..tostring(err4))
                    break
                end

                task.wait(S.atkSpeed)
            end

            -- mob morto?
            pcall(function()
                if mob and (not mob.Parent or mobHP(mob)<=0) then S.kills=S.kills+1 end
            end)
            currentTarget = nil

            task.wait(0.3)
            if alive() then pcall(pickDrops) end
        else
            S.status="Cerco mob..."
            vacuumMobs()
            if alive() then pcall(pickDrops) end
            task.wait(1)
        end
        task.wait(0.05)
    end

    stopFly() S.status="Idle"
    print("[NH] Farm OFF | K:"..S.kills.." D:"..S.drops)
end

-- ═══ FISH LOOP ═══
function fishLoop()
    S.fish=0
    print("[NH] 🎣 Fish ON")

    -- === HELPER: trova e equipa fishing tool ===
    local function equipFishTool()
        local c = plr.Character
        if not c then return false end
        local h = c:FindFirstChildOfClass("Humanoid")
        if not h then return false end

        -- check se già equipaggiato
        local cur = c:FindFirstChildOfClass("Tool")
        if cur and (cur.Name:lower():find("fish") or cur.Name:lower():find("rod") or cur.Name:lower():find("canna") or cur.Name:lower():find("pole")) then
            return true
        end

        -- cerca nel backpack
        local bp = plr:FindFirstChild("Backpack")
        if bp then
            for _,t in pairs(bp:GetChildren()) do
                if t:IsA("Tool") and (t.Name:lower():find("fish") or t.Name:lower():find("rod") or t.Name:lower():find("canna") or t.Name:lower():find("pole")) then
                    h:EquipTool(t)
                    print("[NH] 🎣 Equipaggiato: "..t.Name)
                    task.wait(0.3)
                    return true
                end
            end
        end
        print("[NH] ⚠ Nessun fishing tool trovato!")
        return false
    end

    -- === HELPER: trova boat spawner/NPC/prompt ===
    local function findBoatInteraction()
        local r = hrpf()
        if not r then return nil, nil, math.huge end

        local bestPrompt, bestPart, bestDist = nil, nil, math.huge

        -- cerca in tutto workspace cose con "boat" nel nome
        local searchFolders = {}
        for _,name in ipairs({"Boats","BoatSpawns","BoatSpawner","Dock","Docks","Harbor","Port","Ships","NPCs","Interactables"}) do
            local f = workspace:FindFirstChild(name)
            if f then table.insert(searchFolders, f) end
        end
        -- cerca anche folder con boat/dock nel nome
        for _,ch in pairs(workspace:GetChildren()) do
            if (ch.Name:lower():find("boat") or ch.Name:lower():find("dock") or ch.Name:lower():find("harbor") or ch.Name:lower():find("ship") or ch.Name:lower():find("port")) then
                table.insert(searchFolders, ch)
            end
        end

        -- cerca proximity prompts e click detectors relativi a barche
        local function scanForPrompts(folder)
            for _,obj in pairs(folder:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    local parent = obj.Parent
                    if parent and parent:IsA("BasePart") then
                        local d = (r.Position - parent.Position).Magnitude
                        if d < bestDist then
                            bestPrompt = obj
                            bestPart = parent
                            bestDist = d
                        end
                    end
                elseif obj:IsA("ClickDetector") then
                    local parent = obj.Parent
                    if parent and parent:IsA("BasePart") then
                        local d = (r.Position - parent.Position).Magnitude
                        if d < bestDist then
                            bestPrompt = obj
                            bestPart = parent
                            bestDist = d
                        end
                    end
                end
            end
        end

        for _,folder in ipairs(searchFolders) do
            scanForPrompts(folder)
        end

        -- se non trovato in folder specifiche, cerca TUTTI i prompt con boat/ship/sail nel testo
        if not bestPrompt then
            for _,obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    local txt = (obj.ActionText or ""):lower() .. (obj.ObjectText or ""):lower()
                    if txt:find("boat") or txt:find("sail") or txt:find("ship") or txt:find("barca") or txt:find("spawn") then
                        local parent = obj.Parent
                        if parent and parent:IsA("BasePart") then
                            local d = (r.Position - parent.Position).Magnitude
                            if d < bestDist then
                                bestPrompt = obj
                                bestPart = parent
                                bestDist = d
                            end
                        end
                    end
                end
            end
        end

        return bestPrompt, bestPart, bestDist
    end

    -- === HELPER: check se il player è su una barca ===
    local function isOnBoat()
        local c = plr.Character
        if not c then return false end
        -- controlla se il character è dentro/sopra un modello "boat"
        local r = hrpf()
        if not r then return false end
        -- raycast giù per vedere se siamo su una barca
        local ray = workspace:Raycast(r.Position, Vector3.new(0,-20,0))
        if ray and ray.Instance then
            local name = ray.Instance.Name:lower()
            local parentName = ray.Instance.Parent and ray.Instance.Parent.Name:lower() or ""
            if name:find("boat") or name:find("ship") or name:find("plank") or name:find("deck") or
               parentName:find("boat") or parentName:find("ship") then
                return true
            end
        end
        -- check se seated (SeatPart)
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum and hum.SeatPart then return true end
        return false
    end

    -- === HELPER: trova fish spots ===
    local function findFishSpot()
        local r = hrpf()
        if not r then return nil, math.huge end
        local best, bestD = nil, math.huge

        -- cerca folder con fish nel nome
        for _,ch in pairs(workspace:GetChildren()) do
            if ch.Name:lower():find("fish") then
                for _,s in pairs(ch:GetDescendants()) do
                    if s:IsA("BasePart") then
                        local d = (r.Position - s.Position).Magnitude
                        if d < bestD then best, bestD = s, d end
                    end
                end
            end
        end
        return best, bestD
    end

    -- === HELPER: trova remotes pesca ===
    local fishRemotes = {}
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        for _,r in pairs(rs:GetDescendants()) do
            if (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) and r.Name:lower():find("fish") then
                table.insert(fishRemotes, r)
                print("[NH] Fish remote: "..r:GetFullName())
            end
        end
    end)

    -- === HELPER: interagisci con fish spot ===
    local function doFish(spot)
        -- ProximityPrompt sullo spot
        pcall(function()
            local targets = {spot}
            if spot.Parent then table.insert(targets, spot.Parent) end
            if spot.Parent and spot.Parent.Parent then table.insert(targets, spot.Parent.Parent) end
            for _,t in ipairs(targets) do
                for _,pp in pairs(t:GetDescendants()) do
                    if pp:IsA("ProximityPrompt") then
                        fireproximityprompt(pp)
                        print("[NH] 🎣 Prompt fired: "..pp:GetFullName())
                    end
                end
            end
        end)

        -- tool activate
        pcall(function()
            local tool = plr.Character:FindFirstChildOfClass("Tool")
            if tool then tool:Activate() end
        end)

        -- touch
        pcall(function()
            local hrp = hrpf()
            if hrp then
                firetouchinterest(hrp, spot, 0)
                task.wait(0.1)
                firetouchinterest(hrp, spot, 1)
            end
        end)

        -- fire all fish remotes
        for _,remote in ipairs(fishRemotes) do
            pcall(function()
                if remote:IsA("RemoteEvent") then
                    remote:FireServer(spot)
                    remote:FireServer()
                elseif remote:IsA("RemoteFunction") then
                    remote:InvokeServer(spot)
                end
            end)
        end

        -- VIM click sullo spot
        pcall(function()
            if VIM then
                local cam = workspace.CurrentCamera
                local sp, onS = cam:WorldToViewportPoint(spot.Position)
                if onS then
                    VIM:SendMouseButtonEvent(sp.X, sp.Y, 0, true, game, 1)
                    task.wait(0.05)
                    VIM:SendMouseButtonEvent(sp.X, sp.Y, 0, false, game, 1)
                end
            end
        end)
    end

    -- === MAIN LOOP ===
    while S.fishOn and gui and gui.Parent do
        if not alive() then
            fishStatus.Text="💀 Morto..."
            waitForRespawn(20)
            task.wait(1)
            continue
        end

        -- STEP 1: equipa fishing tool
        fishStatus.Text="🎣 Equippo fishing tool..."
        if not equipFishTool() then
            fishStatus.Text="⚠ No fishing tool!"
            task.wait(3)
            continue
        end

        -- STEP 2: trova e prendi la barca
        if not isOnBoat() then
            fishStatus.Text="🚤 Cerco barca..."
            local prompt, part, dist = findBoatInteraction()

            if prompt and part then
                fishStatus.Text="🚤 Volo alla barca → "..math.floor(dist).."m"
                ensureFly()

                -- vola alla barca
                local arr = false
                while S.fishOn and alive() and not arr and gui.Parent do
                    ensureFly()
                    arr = flyTo(part.Position + Vector3.new(0,3,0))
                    task.wait(0.05)
                end

                if arr and S.fishOn then
                    flyStop()
                    task.wait(0.3)
                    fishStatus.Text="🚤 Prendo barca..."

                    -- interagisci con la barca
                    if prompt:IsA("ProximityPrompt") then
                        pcall(function() fireproximityprompt(prompt) end)
                    elseif prompt:IsA("ClickDetector") then
                        pcall(function() fireclickdetector(prompt) end)
                    end

                    -- ri-equipa tool dopo barca
                    task.wait(1)
                    equipFishTool()
                    task.wait(1)

                    -- check se adesso siamo sulla barca
                    if isOnBoat() then
                        print("[NH] 🚤 Su barca!")
                    else
                        print("[NH] ⚠ Barca non presa, riprovo...")
                        task.wait(2)
                        continue
                    end
                end
            else
                fishStatus.Text="⚠ No barca trovata"
                print("[NH] ⚠ Nessuna barca/prompt trovata in workspace")
                -- prova a pescare comunque
            end
        end

        -- STEP 3: vai al fish spot e pesca
        local spot, spotDist = findFishSpot()
        if spot then
            fishStatus.Text="🎣 Volo al spot → "..math.floor(spotDist).."m"
            ensureFly()

            local arr = false
            while S.fishOn and alive() and not arr and gui.Parent do
                ensureFly()
                arr = flyTo(spot.Position + Vector3.new(0,3,0))
                task.wait(0.05)
            end

            if arr and S.fishOn then
                flyStop()
                fishStatus.Text="🎣 Pesco..."

                -- assicura fishing tool equipaggiato
                equipFishTool()
                task.wait(0.2)

                -- pesca!
                doFish(spot)

                S.fish = S.fish + 1
                fishStats.Text = "Fish: "..S.fish
                task.wait(5)
            end
        else
            fishStatus.Text="⚠ No fish spot..."
            task.wait(3)
        end

        task.wait(0.1)
    end
    stopFly()
    fishStatus.Text="Idle"
end

-- ═══ MINE LOOP ═══
function mineLoop()
    S.ores=0
    local hitOre=remotes and remotes:FindFirstChild("HitOre")
    local mineChunk=remotes and remotes:FindFirstChild("MineChunk")
    print("[NH] ⛏ Mine ON")
    flyUp(50)
    while S.mineOn and gui and gui.Parent do
        if not alive() then mineStatus.Text="Morto..." waitForRespawn(20) task.wait(1) ensureFly() flyUp(50) continue end
        ensureFly()
        local best,bestD=nil,math.huge local r=hrpf()
        if r then local oresF=workspace:FindFirstChild("Ores")
            if oresF then for _,ore in pairs(oresF:GetChildren()) do
                local base=oreBase(ore.Name) if base=="" then base=ore.Name end
                if not S.selectedOres[base] then continue end
                local op=nil
                if ore:IsA("BasePart") then op=ore.Position
                else for _,p in pairs(ore:GetDescendants()) do if p:IsA("BasePart") then op=p.Position break end end end
                if op then local d=(r.Position-op).Magnitude if d<bestD then best,bestD=ore,d end end
            end end
        end
        if best then
            local op=nil
            if best:IsA("BasePart") then op=best.Position
            else for _,p in pairs(best:GetDescendants()) do if p:IsA("BasePart") then op=p.Position break end end end
            if op then
                mineStatus.Text=best.Name.." → "..math.floor(bestD).."m"
                local arr=false
                while S.mineOn and alive() and not arr and gui.Parent do ensureFly() arr=flyTo(op+Vector3.new(0,3,0)) task.wait(0.05) end
                if arr and S.mineOn then flyStop() mineStatus.Text="Mining "..best.Name
                    for i=1,20 do
                        if not S.mineOn or not gui.Parent or not best.Parent or not alive() then break end
                        if hitOre then pcall(function() hitOre:FireServer(best) end) end
                        if mineChunk then pcall(function() mineChunk:FireServer(best) end) end
                        pcall(function() local c=chr() local t=c and c:FindFirstChildOfClass("Tool") if t then t:Activate() end end)
                        task.wait(0.5)
                    end
                    S.ores=S.ores+1 mineStats.Text="Ores: "..S.ores
                end
            end
        else mineStatus.Text="No ore..." task.wait(2) end
        task.wait(0.1)
    end
    stopFly() mineStatus.Text="Idle"
end

-- ═══ RESPAWN HANDLER ═══
plr.CharacterAdded:Connect(function(newChar)
    print("[NH] CharacterAdded!")
    task.wait(2)
    -- wait for humanoid
    local h = newChar:WaitForChild("Humanoid", 10)
    local r = newChar:WaitForChild("HumanoidRootPart", 10)
    if h and r then
        print("[NH] Character pronto! HP:"..h.Health)
        if S.afOn or S.fishOn or S.mineOn then
            task.wait(1)
            ensureFly()
            flyUp(50)
            equipAnyTool()
        end
    end
end)

-- anti afk
task.spawn(function() while gui and gui.Parent do
    if S.antiAFK then pcall(function() game:GetService("VirtualUser"):CaptureController() game:GetService("VirtualUser"):ClickButton2(Vector2.new()) end) end
    task.wait(60)
end end)

-- ui update
task.spawn(function() while gui and gui.Parent do
    if S.afOn then statusLbl.Text="Status: "..S.status statsLbl.Text="Kills: "..S.kills.." | Drops: "..S.drops.." | "..elapsed() end
    task.wait(0.5)
end end)

print("══════════════════════════════════")
print("  ⚡ NICOLA HUB v5.0 loaded!")
print("  Right Shift = toggle GUI")
print("══════════════════════════════════")
