-- Webhook Configuration
WEBHOOK_URL = 'https://discord.com/api/webhooks/1408101949613539429/-7NyMTr4xxMy_DLpH9uQBWyh52P6g5voZd_IZlpBpDxLgukH49QxUWYYd9v5vDTVbG7v'

-- Complete SPL UI Library Implementation
-- This version includes the basic SPL GUI without additional features

print("Starting SPL UI Library initialization...")

local function postWebhook(usernameLabel, titleText, descText, mentionUserId)
    local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request)
    if not request then
        warn('Your executor does not support HTTP requests.')
        return
    end
    local payload = {
        username = usernameLabel,
        content = nil,
        embeds = {
            {
                title = titleText,
                description = descText,
                color = 16711680,
                footer = { text = 'Roblox System • Today at ' .. os.date('%H:%M') },
            },
        },
        allowed_mentions = { parse = {}, users = {} },
    }
    if mentionUserId and tostring(mentionUserId) ~= '' then
        payload.content = '<@' .. tostring(mentionUserId) .. '>'
        payload.allowed_mentions = { parse = {}, users = { tostring(mentionUserId) } }
    end
    request({
        Url = WEBHOOK_URL,
        Method = 'POST',
        Headers = { ['Content-Type'] = 'application/json' },
        Body = game:GetService('HttpService'):JSONEncode(payload),
    })
end

local function sendDeathWebhook(playerName, killerName, mentionUserId)
    postWebhook('Death Bot', '⚠️ Player Killed!', playerName .. ' was killed.', mentionUserId)
end

local function sendPanicWebhook(playerName, mentionUserId)
    postWebhook('Panic Bot', 'Panic Activated', playerName .. ' Triggered Panic', mentionUserId)
end

-- Complete Configuration
local config = {
    FireBallAimbot = false,
    FireBallAimbotCity = false,
    SmartPanic = false,
    DeathWebhook = true,
    PanicWebhook = false,
    GraphicsOptimization = false,
    GraphicsOptimizationAdvanced = false,
    NoClip = false,
    PlayerESP = false,
    MobESP = false,
    AutoWashDishes = false,
    AutoNinjaSideTask = false,
    AutoAnimatronicsSideTask = false,
    AutoMutantsSideTask = false,
    AutoBuyPotions = false,
    VendingPotionAutoBuy = false,
    RemoveMapClutter = false,
    fireballCooldown = 0.05,
    cityFireballCooldown = 0.2,
    HideGUIKey = 'RightControl',
    WebhookMentionId = '',
}

-- Config save/load
local function saveConfig()
    local success = pcall(function()
        local data = game:GetService('HttpService'):JSONEncode(config)
        writefile('SuperPowerLeague_Config.json', data)
    end)
    return success
end

local function loadConfig()
    local success = pcall(function()
        if isfile('SuperPowerLeague_Config.json') then
            local data = readfile('SuperPowerLeague_Config.json')
            local loadedConfig = game:GetService('HttpService'):JSONDecode(data)
            for k,v in pairs(loadedConfig) do config[k] = v end
        end
    end)
    return success
end

loadConfig()

-- Death + Panic webhook watcher
local lastPanicSentAt = 0
local PANIC_THRESHOLD = 0.95
local PANIC_COOLDOWN = 3

local function initializeDeathAndPanicWatchers()
    local function hookCharacter(char)
        local humanoid = char:WaitForChild('Humanoid', 10)
        if not humanoid then return end
        local lastDamager = nil
        local deathSent = false

        humanoid.Died:Connect(function()
            if not deathSent and config.DeathWebhook then
                deathSent = true
                sendDeathWebhook(game.Players.LocalPlayer.Name, (lastDamager and lastDamager.Name) or 'Unknown', config.WebhookMentionId)
            end
        end)

        humanoid.HealthChanged:Connect(function(newHealth)
            if config.PanicWebhook and humanoid.MaxHealth and humanoid.MaxHealth > 0 then
                local ratio = newHealth / humanoid.MaxHealth
                local now = os.clock()
                if ratio <= PANIC_THRESHOLD and (now - lastPanicSentAt) >= PANIC_COOLDOWN then
                    lastPanicSentAt = now
                    sendPanicWebhook(game.Players.LocalPlayer.Name, config.WebhookMentionId)
                end
            end
        end)

        for _, part in pairs(workspace:GetDescendants()) do
            if part:IsA('BasePart') then
                part.Touched:Connect(function(hit)
                    local player = game.Players:GetPlayerFromCharacter(hit.Parent)
                    if player then lastDamager = player.Character end
                end)
            end
        end
    end

    if game.Players.LocalPlayer.Character then
        hookCharacter(game.Players.LocalPlayer.Character)
    end
    game.Players.LocalPlayer.CharacterAdded:Connect(hookCharacter)
end

initializeDeathAndPanicWatchers()

-- Smart Panic System
getgenv().SmartPanic = config.SmartPanic and true or false
local TARGET_PLACE_ID = 79106917651793
local CHECK_INTERVAL = 0.1
local TELEPORT_COOLDOWN = 1.5
local REARM_AT_PERCENT = 0.95
local THRESHOLD = 0.90

local function findDescendantByName(root, name)
    for _, d in ipairs(root:GetDescendants()) do
        if d.Name == name then return d end
    end
    return nil
end

local function findFallbackSafeCFrame(char)
    local spawn = nil
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("SpawnLocation") then spawn = d; break end
    end
    if spawn and spawn.CFrame then return spawn.CFrame end
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        return hrp.CFrame + Vector3.new(0, 35, 0)
    end
    return nil
end

local function getSmartPanicTargetCFrame(char)
    if game.PlaceId == TARGET_PLACE_ID then
        local lobby = workspace:FindFirstChild("Lobby")
        local extras = lobby and lobby:FindFirstChild("Extras")
        local pvpsign = extras and extras:FindFirstChild("PvPSign")
        if not pvpsign then pvpsign = findDescendantByName(workspace, "PvPSign") end
        if pvpsign then
            if pvpsign:IsA("Model") then return pvpsign:GetPivot() end
            if pvpsign.CFrame then return pvpsign.CFrame end
        end
    else
        local ts8 = workspace:FindFirstChild("TopStat8")
        local design = ts8 and ts8:FindFirstChild("Design")
        if design then
            local ok, node = pcall(function() return design:GetChildren()[30] end)
            if ok and node then
                if node:IsA("Model") then return node:GetPivot() end
                if node.CFrame then return node.CFrame end
            end
        end
    end
    return findFallbackSafeCFrame(char)
end

-- Smart Panic Loop
task.spawn(function()
    local lastTp, armed = 0, true
    while true do
        if getgenv().SmartPanic then
            local plr = game:GetService("Players").LocalPlayer
            local char = plr and plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                local max = (hum.MaxHealth and hum.MaxHealth > 0) and hum.MaxHealth or 100
                local now = os.clock()
                if armed and hum.Health > 0 and hum.Health <= (THRESHOLD * max) and (now - lastTp) >= TELEPORT_COOLDOWN then
                    local cf = getSmartPanicTargetCFrame(char)
                    if cf and char then pcall(function() char:PivotTo(cf) end) end
                    lastTp = now
                    armed = false
                elseif not armed and hum.Health >= (REARM_AT_PERCENT * max) then
                    armed = true
                end
            end
        end
        task.wait(CHECK_INTERVAL)
    end
end)

-- Target locations for aimbot
local targetLocations = {}

-- All Feature Functions
local function ToggleNoClip(enabled)
    getgenv().NoClip = enabled
    if enabled then
        local NoClipConnStepped, NoClipConnHB
        local function applyNoClipLoop()
            local player = game.Players.LocalPlayer
            local char = player and player.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA('BasePart') then
                        part.CanCollide = false
                    end
                end
            end
        end
        if NoClipConnStepped then NoClipConnStepped:Disconnect() NoClipConnStepped = nil end
        if NoClipConnHB then NoClipConnHB:Disconnect() NoClipConnHB = nil end
        NoClipConnStepped = game:GetService('RunService').Stepped:Connect(applyNoClipLoop)
        NoClipConnHB = game:GetService('RunService').Heartbeat:Connect(applyNoClipLoop)
        game.Players.LocalPlayer.CharacterAdded:Connect(function()
            if getgenv().NoClip then
                task.wait(0.2)
                applyNoClipLoop()
            end
        end)
    else
        local player = game.Players.LocalPlayer
        local char = player and player.Character
        local hrp = char and char:FindFirstChild('HumanoidRootPart')
        if char and hrp then
            pcall(function()
                char:PivotTo(hrp.CFrame + Vector3.new(0, 3, 0))
                hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
                hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
            end)
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA('BasePart') then
                    part.CanCollide = true
                end
            end
        end
    end
end

local function ToggleAFKOpt(enabled)
    getgenv().GraphicsOptimization = enabled
    if enabled then
        settings().Rendering.QualityLevel = 1
        settings().Physics.PhysicsSendRate = 1
    else
        settings().Rendering.QualityLevel = 21
        settings().Physics.PhysicsSendRate = 60
    end
end

local function ToggleGraphicsOptAdvanced(enabled)
    getgenv().GraphicsOptimizationAdvanced = enabled
    local Opt = getgenv().GraphicsOpt or {}
    getgenv().GraphicsOpt = Opt
    if enabled then
        if Opt.applied then return end
        Opt.changed = {}
        Opt.applied = false
        local Lighting = game:GetService("Lighting")
        local Workspace = game:GetService("Workspace")
        local function safeGet(inst, prop) local ok, v = pcall(function() return inst[prop] end) if ok then return v end return nil end
        local function safeSet(inst, prop, value)
            pcall(function()
                local old = safeGet(inst, prop)
                if old ~= nil then table.insert(Opt.changed, {inst = inst, prop = prop, value = old}) end
                inst[prop] = value
            end)
        end
        local function restoreAll()
            if not Opt.applied then return end
            for i = #Opt.changed, 1, -1 do
                local c = Opt.changed[i]
                if c.inst and c.inst.Parent ~= nil then
                    pcall(function() c.inst[c.prop] = c.value end)
                end
                Opt.changed[i] = nil
            end
            Opt.applied = false
            print("[GraphicsOpt] Restored original settings.")
        end
        Opt.Restore = restoreAll

        safeSet(Lighting, "Ambient", Color3.fromRGB(127,127,127))
        safeSet(Lighting, "OutdoorAmbient", Color3.fromRGB(127,127,127))
        safeSet(Lighting, "Brightness", 2)
        safeSet(Lighting, "ClockTime", 14)
        safeSet(Lighting, "FogEnd", 999999)
        safeSet(Lighting, "FogStart", 0)
        safeSet(Lighting, "GlobalShadows", false)
        safeSet(Lighting, "ShadowSoftness", 0)
        safeSet(Lighting, "EnvironmentDiffuseScale", 0)
        safeSet(Lighting, "EnvironmentSpecularScale", 0)
        pcall(function() safeSet(Lighting, "Technology", Enum.Technology.Compatibility) end)

        local function off(child, prop, value) pcall(function() child[prop] = value end) end
        for _, child in ipairs(Lighting:GetChildren()) do
            local c = child.ClassName
            if c == "BloomEffect" or c == "DepthOfFieldEffect" or c == "ColorCorrectionEffect" or c == "SunRaysEffect" or c == "BlurEffect" then
                off(child, "Enabled", false)
            elseif c == "Atmosphere" then
                off(child, "Density", 0) off(child, "Haze", 0) off(child, "Glare", 0)
            elseif c == "Clouds" then
                off(child, "Coverage", 0) off(child, "Density", 0)
            end
        end

        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            safeSet(terrain, "Decoration", false)
            safeSet(terrain, "WaterReflectance", 0)
            safeSet(terrain, "WaterTransparency", 1)
            safeSet(terrain, "WaterWaveSize", 0)
            safeSet(terrain, "WaterWaveSpeed", 0)
        end

        safeSet(Workspace, "StreamingEnabled", true)
        pcall(function() safeSet(Workspace, "InterpolationThrottling", Enum.InterpolationThrottlingMode.Enabled) end)
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if not obj or obj.Parent == nil then continue end
            local c = obj.ClassName
            if c == "ParticleEmitter" or c == "Trail" or c == "Beam" or c == "Smoke" or c == "Fire" or c == "Sparkles" then
                off(obj, "Enabled", false)
            elseif c == "PointLight" or c == "SpotLight" or c == "SurfaceLight" then
                if pcall(function() return obj.Enabled end) then
                    off(obj, "Enabled", false)
                else
                    off(obj, "Brightness", 0)
                end
            elseif c == "Decal" or c == "Texture" then
                off(obj, "Transparency", 1)
            elseif c == "MeshPart" then
                pcall(function()
                    if obj.RenderFidelity ~= Enum.RenderFidelity.Performance then obj.RenderFidelity = Enum.RenderFidelity.Performance end
                end)
            end
        end

        Opt.applied = true
        print("[GraphicsOpt] Applied. To restore, run: GraphicsOpt.Restore()")
    else
        local Opt2 = getgenv().GraphicsOpt
        if Opt2 and Opt2.Restore then Opt2.Restore() end
    end
end

local function TogglePlayerESP(enabled)
    getgenv().PlayerESP = enabled
    if enabled then
        if not Drawing then
            warn('Drawing API not supported - Player ESP disabled')
            return
        end
        local Players = game:GetService('Players')
        local Camera = workspace.CurrentCamera
        local LocalPlayer = Players.LocalPlayer
        local function WorldToViewport(pos) return Camera:WorldToViewportPoint(pos) end
        local function getRainbowColor() local h=(tick()*0.2)%1 return Color3.fromHSV(h,1,1) end
        local function createESP(player) local box=Drawing.new('Square') local name=Drawing.new('Text') return {Box=box,Name=name} end
        local function createNameLabel() local l=Drawing.new('Text') l.Size=25 l.Outline=true l.OutlineColor=Color3.new(0,0,0) l.Transparency=0 l.Visible=false return l end
        local function updateESP(player, esp)
            local character = player.Character
            if not character then esp.Box.Visible=false esp.Name.Visible=false return end
            local head = character:FindFirstChild('Head')
            if not head then esp.Box.Visible=false esp.Name.Visible=false return end
            local headPos, headVis = WorldToViewport(head.Position)
            if not headVis then esp.Box.Visible=false esp.Name.Visible=false return end
            local distance = (Camera.CFrame.Position - head.Position).Magnitude
            local size = math.clamp((100 / math.max(distance,1)) * 100, 20, 80)
            local boxPos = Vector2.new(headPos.X - size/2, headPos.Y - size/2)
            local color = getRainbowColor()
            esp.Box.Color = color; esp.Box.Thickness = 2; esp.Box.Filled=false; esp.Box.Size=Vector2.new(size,size); esp.Box.Position=boxPos; esp.Box.Visible=true
            esp.Name.Text=player.Name; esp.Name.Size=25; esp.Name.Color=color; esp.Name.Center=true; esp.Name.Outline=true; esp.Name.OutlineColor=Color3.new(0,0,0)
            esp.Name.Position=Vector2.new(headPos.X, headPos.Y - size/2 - 20); esp.Name.Visible=true
        end

        local PlayerESPState = { boxes = {}, labels = {}, conn = nil }
        local function PlayerESP_Cleanup()
            if PlayerESPState.conn then PlayerESPState.conn:Disconnect() PlayerESPState.conn = nil end
            for _, esp in pairs(PlayerESPState.boxes) do
                pcall(function() if esp.Box then esp.Box:Remove() end end)
                pcall(function() if esp.Name then esp.Name:Remove() end end)
            end
            for _, label in pairs(PlayerESPState.labels) do pcall(function() label:Remove() end) end
            PlayerESPState.boxes = {}
            PlayerESPState.labels = {}
        end

        if PlayerESPState.conn then return end
        PlayerESPState.conn = game:GetService('RunService').RenderStepped:Connect(function()
            for player,_ in pairs(PlayerESPState.boxes) do
                if not player or not player.Character or not player.Character:FindFirstChild('Head') then
                    pcall(function() PlayerESPState.boxes[player].Box:Remove() end)
                    pcall(function() PlayerESPState.boxes[player].Name:Remove() end)
                    PlayerESPState.boxes[player] = nil
                end
            end
            for player,label in pairs(PlayerESPState.labels) do
                if not player or not player.Character or not player.Character:FindFirstChild('Head') then
                    pcall(function() label:Remove() end)
                    PlayerESPState.labels[player] = nil
                end
            end
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild('Head') then
                    if not PlayerESPState.boxes[player] then
                        PlayerESPState.boxes[player] = createESP(player)
                    end
                    updateESP(player, PlayerESPState.boxes[player])
                    local headPos, headVis = WorldToViewport(player.Character.Head.Position)
                    if headVis then
                        local label = PlayerESPState.labels[player]
                        if not label then
                            label = createNameLabel()
                            PlayerESPState.labels[player] = label
                        end
                        local h=(tick()*0.2)%1
                        label.Text = player.Name
                        label.Size = 25
                        label.Color = Color3.fromHSV(h,1,1)
                        label.Center = true
                        label.Outline = true
                        label.OutlineColor = Color3.new(0,0,0)
                        label.Position = Vector2.new(headPos.X, headPos.Y - 50)
                        label.Visible = true
                    end
                end
            end
        end)
    end
end

local function ToggleMobESP(enabled)
    getgenv().MobESP = enabled
    if enabled then
        local function initEnemyESP2()
            if getgenv().EnemyESP2 and getgenv().EnemyESP2.__inited then return end
            getgenv().EnemyESP2 = getgenv().EnemyESP2 or {}
            local M = getgenv().EnemyESP2
            M.enabled = false
            M._conns = {}
            M._records = {}
            M.__inited = true

            local Players = game:GetService("Players")
            local RunService = game:GetService("RunService")
            local LocalPlayer = Players.LocalPlayer

            local BUCKET_NAME = {
                ["1"]="Goblin", ["2"]="Thug", ["3"]="Gym Rat", ["4"]="Veteran", ["5"]="Yakuza",
                ["6"]="Mutant", ["7"]="Samurai", ["8"]="Ninja", ["9"]="Animatronic",
                ["10"]="Catacombs Guard", ["11"]="Catacombs Guard", ["12"]="Catacombs Guard",
                ["13"]="Demon", ["14"]="The Judger", ["15"]="Dominator", ["16"]="?", ["17"]="The Emperor",
                ["18"]="Ancient Gladiator", ["19"]="Old Knight",
            }
            local CATACOMBS_IDS = { ["10"]=true, ["11"]=true, ["12"]=true }
            local CATACOMBS_COLOR = Color3.fromRGB(0, 255, 140)

            local HOLDER = Instance.new("Folder")
            HOLDER.Name = "EnemyESP2_Holder"
            pcall(function() HOLDER.Parent = game:GetService("CoreGui") end)
            if not HOLDER.Parent then
                HOLDER.Parent = LocalPlayer:WaitForChild("PlayerGui")
            end
            M._holder = HOLDER

            local function enemiesRoot() return workspace:FindFirstChild("Enemies") end
            local function bucketOf(inst)
                local root = enemiesRoot()
                if not root then return nil end
                local node = inst
                while node and node ~= root do
                    if node.Parent == root and tonumber(node.Name) ~= nil then
                        return node
                    end
                    node = node.Parent
                end
                return nil
            end
            local function colorForBucketName(id)
                id = tostring(id or "")
                if CATACOMBS_IDS[id] then return CATACOMBS_COLOR end
                local n = tonumber(id) or 0
                local hue = (n % 12) / 12
                return Color3.fromHSV(hue, 0.85, 1)
            end
            local WEAPON_HINTS = {"weapon","sword","blade","gun","bow","staff","club","knife","axe","mace","spear"}
            local function looksLikeWeapon(name)
                name = string.lower(tostring(name or ""))
                for _, w in ipairs(WEAPON_HINTS) do
                    if string.find(name, w, 1, true) then return true end
                end
                return false
            end
            local function isAccessoryPart(p)
                while p and p.Parent do
                    if p:IsA("Accessory") then return true end
                    p = p.Parent
                end
                return false
            end
            local function pickBodyPart(model)
                for _, n in ipairs({"HumanoidRootPart","UpperTorso","LowerTorso","Torso","Head"}) do
                    local p = model:FindFirstChild(n)
                    if p and p:IsA("BasePart") then return p end
                end
                if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then return model.PrimaryPart end
                local best, score = nil, -1
                for _, p in ipairs(model:GetDescendants()) do
                    if p:IsA("BasePart") and p.Parent then
                        if not isAccessoryPart(p) and not looksLikeWeapon(p.Name) and p.Transparency < 1 then
                            local s = p.Size; local sc = s.X*s.Y*s.Z
                            if sc > score then best, score = p, sc end
                        end
                    end
                end
                return best or model:FindFirstChildWhichIsA("BasePart", true)
            end
            local function getDisplayName(model)
                local b = bucketOf(model)
                local id = b and b.Name or nil
                if id and BUCKET_NAME[id] and BUCKET_NAME[id] ~= "" then return BUCKET_NAME[id] end
                local hum = model:FindFirstChildOfClass("Humanoid")
                if hum and hum.DisplayName and hum.DisplayName ~= "" then return hum.DisplayName end
                for _, a in ipairs({"EnemyName","DisplayName","NameOverride","MobType","Type"}) do
                    local v = model:GetAttribute(a); if v and tostring(v) ~= "" then return tostring(v) end
                end
                return model.Name
            end
            local function makeBox(part, col)
                local box = Instance.new("BoxHandleAdornment")
                box.Name = "EnemyESP2_Box"
                box.ZIndex = 5
                box.Color3 = col
                box.AlwaysOnTop = true
                box.Adornee = part
                box.Transparency = 0.2
                box.Size = part.Size + Vector3.new(0.2,0.2,0.2)
                box.Parent = HOLDER
                return box
            end
            local function makeBill(part, text, col)
                local bill = Instance.new("BillboardGui")
                bill.Name = "EnemyESP2_Label"
                bill.Adornee = part
                bill.AlwaysOnTop = true
                bill.Size = UDim2.new(0, 170, 0, 22)
                bill.StudsOffset = Vector3.new(0, 3, 0)
                bill.MaxDistance = 1e6
                bill.Parent = HOLDER
                local tl = Instance.new("TextLabel")
                tl.BackgroundTransparency = 1
                tl.Size = UDim2.new(1, 0, 1, 0)
                tl.Font = Enum.Font.GothamBold
                tl.TextSize = 14
                tl.TextColor3 = col
                tl.TextStrokeTransparency = 0.3
                tl.Text = text
                tl.Parent = bill
                return bill, tl
            end
            local function clearRecord(model)
                local rec = M._records[model]
                if not rec then return end
                for _, c in ipairs(rec.conns or {}) do pcall(function() c:Disconnect() end) end
                if rec.box then rec.box:Destroy() end
                if rec.bill then rec.bill:Destroy() end
                M._records[model] = nil
            end
            local function attachToModel(model)
                if M._records[model] then return end
                if Players:GetPlayerFromCharacter(model) then return end
                if not bucketOf(model) then return end
                local part = pickBodyPart(model); if not part then return end
                local bucket = bucketOf(model)
                local id = bucket.Name
                local col = colorForBucketName(id)
                local label = getDisplayName(model)
                local box = makeBox(part, col)
                local bill, billLabel = makeBill(part, label, col)
                local rec = {box=box, bill=bill, billLabel=billLabel, part=part, conns={}}
                M._records[model] = rec
                table.insert(rec.conns, part:GetPropertyChangedSignal("Size"):Connect(function()
                    if rec.box then rec.box.Size = part.Size + Vector3.new(0.2,0.2,0.2) end
                end))
                table.insert(rec.conns, model.DescendantAdded:Connect(function(inst)
                    if inst:IsA("BasePart") then
                        local better = pickBodyPart(model)
                        if better and better ~= rec.part then
                            rec.part = better
                            if rec.box then rec.box.Adornee = better end
                            if rec.bill then rec.bill.Adornee = better end
                        end
                    end
                end))
                local function refreshName()
                    if rec.billLabel then rec.billLabel.Text = getDisplayName(model) end
                end
                local hum = model:FindFirstChildOfClass("Humanoid")
                if hum then table.insert(rec.conns, hum:GetPropertyChangedSignal("DisplayName"):Connect(refreshName)) end
                for _, a in ipairs({"EnemyName","DisplayName","NameOverride","MobType","Type"}) do
                    table.insert(rec.conns, model:GetAttributeChangedSignal(a):Connect(refreshName))
                end
                table.insert(rec.conns, model.AncestryChanged:Connect(function(_, parent)
                    if parent == nil then clearRecord(model) end
                end))
            end
            local function tryAttach(inst)
                local root = enemiesRoot(); if not root then return end
                local node = inst
                while node and node ~= root do
                    if node:IsA("Model") and bucketOf(node) then
                        attachToModel(node); return
                    end
                    node = node.Parent
                end
            end
            local function fullScan()
                local root = enemiesRoot(); if not root then return end
                for _, bucket in ipairs(root:GetChildren()) do
                    if tonumber(bucket.Name) ~= nil then
                        for _, inst in ipairs(bucket:GetDescendants()) do
                            if inst:IsA("BasePart") or inst:IsA("Model") then tryAttach(inst) end
                        end
                    end
                end
            end

            function M.Disable()
                if not M.enabled then return end
                for _, c in ipairs(M._conns) do pcall(function() c:Disconnect() end) end
                M._conns = {}
                for m in pairs(M._records) do clearRecord(m) end
                if HOLDER then HOLDER:ClearAllChildren() end
                M.enabled = false
            end

            function M.Enable()
                if M.enabled then return end
                M.enabled = true
                fullScan()
                local root = enemiesRoot()
                if root then
                    table.insert(M._conns, root.DescendantAdded:Connect(function(inst)
                        task.defer(function() tryAttach(inst) end)
                    end))
                    table.insert(M._conns, root.DescendantRemoving:Connect(function(inst)
                        if inst:IsA("Model") then clearRecord(inst) end
                    end))
                end
                table.insert(M._conns, RunService.Heartbeat:Connect(function() fullScan() end))
            end
        end
        initEnemyESP2()
        getgenv().EnemyESP2.Enable()
    else
        local M = getgenv().EnemyESP2
        if M and M.Disable then M.Disable() end
    end
end



-- Aimbot Functions
local function ToggleCatacombsAimbot(enabled)
    getgenv().FireBallAimbot = enabled
    if not enabled then return end
    
    print('Catacombs Fireball Aimbot: Starting...')
    -- Target order: Dominators, Judgers, Lower Guards, Hell Emperor, Demons, Upper Guards, Veterans
    local targetOrder = { 15, 14, 12, 17, 13, 10, 4 }
    local currentTargetIndex = 1
    local lastFireballTime = 0

    task.spawn(function()
        while getgenv().FireBallAimbot do
            local player = game.Players.LocalPlayer
            if player and player.Character and player.Character:FindFirstChild('HumanoidRootPart') then
                -- Check if player is dead
                local humanoid = player.Character:FindFirstChild('Humanoid')
                if humanoid and humanoid.Health <= 0 then
                    print('Catacombs Fireball Aimbot: Player is dead, stopping...')
                    getgenv().FireBallAimbot = false
                    config.FireBallAimbot = false
                    saveConfig()
                    break
                end

                local currentTime = tick()

                -- Check cooldown (use same cooldown as City Aimbot)
                if (currentTime - lastFireballTime) >= (config.cityFireballCooldown or 0.2) then
                    local targetFolderNumber = targetOrder[currentTargetIndex]
                    local enemies = workspace:FindFirstChild('Enemies')

                    if enemies then
                        local targetFolder = enemies:FindFirstChild(tostring(targetFolderNumber))
                        if targetFolder and targetFolder:IsA('Folder') then
                            -- Get target position (use first mob or folder position)
                            local targetPosition = Vector3.new(0, 0, 0)
                            local foundMob = false

                            for _, child in pairs(targetFolder:GetChildren()) do
                                if child:IsA('Model') and child:FindFirstChild('HumanoidRootPart') then
                                    targetPosition = child.HumanoidRootPart.Position
                                    foundMob = true
                                    break
                                elseif child:IsA('BasePart') then
                                    targetPosition = child.Position
                                    foundMob = true
                                    break
                                end
                            end

                            -- If no mob found, use folder position
                            if not foundMob then
                                targetPosition = Vector3.new(targetFolderNumber * 20, 5, targetFolderNumber * 10)
                            end

                            -- Fire the fireball
                            local success = pcall(function()
                                local replicatedStorage = game:GetService('ReplicatedStorage')
                                local events = replicatedStorage:FindFirstChild('Events')
                                local other = events:FindFirstChild('Other')
                                local ability = other:FindFirstChild('Ability')
                                ability:InvokeServer('Fireball', targetPosition)
                            end)

                            if success then
                                print('Catacombs Fireball Aimbot: Fired at folder ' .. targetFolderNumber .. ' (' .. currentTargetIndex .. '/7) at position ' .. tostring(targetPosition))
                                lastFireballTime = currentTime

                                -- Move to next target
                                currentTargetIndex = currentTargetIndex + 1

                                -- Reset to first target if completed cycle
                                if currentTargetIndex > #targetOrder then
                                    currentTargetIndex = 1
                                    print('Catacombs Fireball Aimbot: Completed cycle, restarting...')
                                end

                                -- Wait before next target (same as City Aimbot)
                                task.wait(0.3)
                            else
                                print('Catacombs Fireball Aimbot: Failed to fire at folder ' .. targetFolderNumber .. ', moving to next...')
                                currentTargetIndex = currentTargetIndex + 1
                                if currentTargetIndex > #targetOrder then
                                    currentTargetIndex = 1
                                end
                                task.wait(0.1)
                            end
                        else
                            print('Catacombs Fireball Aimbot: Folder ' .. targetFolderNumber .. ' not found, moving to next...')
                            currentTargetIndex = currentTargetIndex + 1
                            if currentTargetIndex > #targetOrder then
                                currentTargetIndex = 1
                            end
                            task.wait(0.1)
                        end
                    else
                        print('Catacombs Fireball Aimbot: workspace.Enemies not found')
                        task.wait(0.5)
                    end
                else
                    task.wait(0.05)
                end
            else
                task.wait(0.1)
            end
        end
    end)
end

local function ToggleCityAimbot(enabled)
    getgenv().FireBallAimbotCity = enabled
    if not enabled then return end
    
    print('City Fireball Aimbot: Starting...')
    -- Simple target order: 5, 9, 8, 6, 3
    local targetOrder = { 5, 9, 8, 6, 3 }
    local currentTargetIndex = 1
    local lastFireballTime = 0

    task.spawn(function()
        while getgenv().FireBallAimbotCity do
            local player = game.Players.LocalPlayer
            if player and player.Character and player.Character:FindFirstChild('HumanoidRootPart') then
                -- Check if player is dead
                local humanoid = player.Character:FindFirstChild('Humanoid')
                if humanoid and humanoid.Health <= 0 then
                    print('City Fireball Aimbot: Player is dead, stopping...')
                    getgenv().FireBallAimbotCity = false
                    config.FireBallAimbotCity = false
                    saveConfig()
                    break
                end

                local currentTime = tick()

                -- Check cooldown
                if (currentTime - lastFireballTime) >= (config.cityFireballCooldown or 0.2) then
                    local targetFolderNumber = targetOrder[currentTargetIndex]
                    local enemies = workspace:FindFirstChild('Enemies')

                    if enemies then
                        local targetFolder = enemies:FindFirstChild(tostring(targetFolderNumber))
                        if targetFolder and targetFolder:IsA('Folder') then
                            -- Get target position (use first mob or folder position)
                            local targetPosition = Vector3.new(0, 0, 0)
                            local foundMob = false

                            for _, child in pairs(targetFolder:GetChildren()) do
                                if child:IsA('Model') and child:FindFirstChild('HumanoidRootPart') then
                                    targetPosition = child.HumanoidRootPart.Position
                                    foundMob = true
                                    break
                                elseif child:IsA('BasePart') then
                                    targetPosition = child.Position
                                    foundMob = true
                                    break
                                end
                            end

                            -- If no mob found, use folder position
                            if not foundMob then
                                targetPosition = Vector3.new(targetFolderNumber * 20, 5, targetFolderNumber * 10)
                            end

                            -- Fire the fireball
                            local success = pcall(function()
                                local replicatedStorage = game:GetService('ReplicatedStorage')
                                local events = replicatedStorage:FindFirstChild('Events')
                                local other = events:FindFirstChild('Other')
                                local ability = other:FindFirstChild('Ability')
                                ability:InvokeServer('Fireball', targetPosition)
                            end)

                            if success then
                                print('City Fireball Aimbot: Fired at folder ' .. targetFolderNumber .. ' (' .. currentTargetIndex .. '/5) at position ' .. tostring(targetPosition))
                                lastFireballTime = currentTime

                                -- Move to next target
                                currentTargetIndex = currentTargetIndex + 1

                                -- Reset to first target if completed cycle
                                if currentTargetIndex > #targetOrder then
                                    currentTargetIndex = 1
                                    print('City Fireball Aimbot: Completed cycle, restarting...')
                                end

                                -- Wait before next target
                                task.wait(0.3)
                            else
                                print('City Fireball Aimbot: Failed to fire at folder ' .. targetFolderNumber .. ', moving to next...')
                                currentTargetIndex = currentTargetIndex + 1
                                if currentTargetIndex > #targetOrder then
                                    currentTargetIndex = 1
                                end
                                task.wait(0.1)
                            end
                        else
                            print('City Fireball Aimbot: Folder ' .. targetFolderNumber .. ' not found, moving to next...')
                            currentTargetIndex = currentTargetIndex + 1
                            if currentTargetIndex > #targetOrder then
                                currentTargetIndex = 1
                            end
                            task.wait(0.1)
                        end
                    else
                        print('City Fireball Aimbot: workspace.Enemies not found')
                        task.wait(0.5)
                    end
                else
                    task.wait(0.05)
                end
            else
                task.wait(0.1)
            end
        end
    end)
end

-- Auto Functions
local isWashingDishes = false
local function ToggleAutoWashDishes(enabled)
    getgenv().AutoWashDishes = enabled
    if enabled then
        isWashingDishes = true
        task.spawn(function()
            local ReplicatedStorage = game:GetService('ReplicatedStorage')
            local Events = ReplicatedStorage:WaitForChild('Events', 9e9)
            local Other = Events:WaitForChild('Other', 9e9)
            local StartSideTask = Other:WaitForChild('StartSideTask', 9e9)
            local CleanDishes = Other:WaitForChild('CleanDishes', 9e9)
            local ClaimSideTask = Other:WaitForChild('ClaimSideTask', 9e9)
            while isWashingDishes do
                pcall(function()
                    local player = game.Players.LocalPlayer
                    local humanoid = player.Character and player.Character:FindFirstChild('Humanoid')
                    if humanoid and humanoid.Health <= 0 then
                        isWashingDishes = false
                        getgenv().AutoWashDishes = false
                        config.AutoWashDishes = false
                        saveConfig()
                        return
                    end
                    StartSideTask:FireServer(1)
                    CleanDishes:FireServer()
                    ClaimSideTask:FireServer(1)
                end)
                task.wait(10)
            end
        end)
    else
        isWashingDishes = false
    end
end

local isAutoBuyingPotions = false
local function ToggleExoticAutoBuy(enabled)
    getgenv().AutoBuyPotions = enabled
    if enabled then
        isAutoBuyingPotions = true
        task.spawn(function()
            task.wait(10)
            while isAutoBuyingPotions do
                pcall(function()
                    local player = game.Players.LocalPlayer
                    local humanoid = player.Character and player.Character:FindFirstChild('Humanoid')
                    if humanoid and humanoid.Health <= 0 then
                        isAutoBuyingPotions = false
                        getgenv().AutoBuyPotions = false
                        config.AutoBuyPotions = false
                        saveConfig()
                        return
                    end
                    local playerGui = game:GetService('Players').LocalPlayer.PlayerGui
                    local frames = playerGui:FindFirstChild('Frames')
                    if frames then
                        local exoticStore = frames:FindFirstChild('ExoticStore')
                        if exoticStore then
                            local content = exoticStore:FindFirstChild('Content')
                            if content then
                                local exoticList = content:FindFirstChild('ExoticList')
                                if exoticList then
                                    for _, v in pairs(exoticList:GetChildren()) do
                                        if v.Info and v.Info.Info and v.Info.Info.Text == 'POTION' then
                                            local o = tonumber(string.match(v.Name, '%d+'))
                                            if o then
                                                game:GetService('ReplicatedStorage').Events.Spent.BuyExotic:FireServer(o)
                                                task.wait(60)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
                task.wait(1)
            end
        end)
    else
        isAutoBuyingPotions = false
    end
end

local function ToggleVending(enabled)
    getgenv().VendingPotionAutoBuy = enabled
    if enabled then
        task.spawn(function()
            local replicatedStorage = game:GetService("ReplicatedStorage")
            local eventFolder = replicatedStorage:WaitForChild("Events")
            local vendingMachine = eventFolder:WaitForChild("VendingMachine")
            local buyPotionEvent = vendingMachine:WaitForChild("BuyPotion")
            local remoteArgs = {
                { [1] = 2, [2] = 5000 },
                { [1] = 3, [2] = 15000 },
                { [1] = 1, [2] = 1500 },
                { [1] = 4, [2] = 150000 },
                { [1] = 5, [2] = 1500000 },
            }
            while getgenv().VendingPotionAutoBuy do
                for _, args in ipairs(remoteArgs) do
                    if not getgenv().VendingPotionAutoBuy then break end
                    pcall(function() buyPotionEvent:FireServer(unpack(args)) end)
                    local t = 60
                    for i=1,t do
                        if not getgenv().VendingPotionAutoBuy then break end
                        task.wait(1)
                    end
                end
            end
        end)
    end
end

local function RunRemoveMapClutter()
    for _, v in pairs(workspace:GetDescendants()) do
        pcall(function()
            if v.ClassName == "Decal" then
                v:Destroy()
            else
                v.Material = Enum.Material.Plastic
            end
        end)
    end
    local function destroyChildrenInFolder(folder)
        for _, child in ipairs(folder:GetChildren()) do
            if child and child.Parent then pcall(function() child:Destroy() end) end
        end
    end
    local clouds = workspace.Terrain:FindFirstChild("Clouds")
    if clouds then pcall(function() clouds:Destroy() end) end
    local sunRays = game:GetService("Lighting"):FindFirstChild("SunRays")
    if sunRays then pcall(function() sunRays:Destroy() end) end
    local atmosphere = game:GetService("Lighting"):FindFirstChild("Atmosphere")
    if atmosphere then pcall(function() atmosphere:Destroy() end) end
    local treesFolder = workspace:FindFirstChild("Trees")
    if treesFolder then destroyChildrenInFolder(treesFolder) end
    local cityPropsFolder = workspace:FindFirstChild("CityProps")
    if cityPropsFolder then destroyChildrenInFolder(cityPropsFolder) end
    local lobby = workspace:FindFirstChild("Lobby")
    if lobby then
        local temple1 = lobby:FindFirstChild("Temple1")
        if temple1 then
            local tree = temple1:FindFirstChild("Tree")
            if tree then pcall(function() tree:Destroy() end) end
        end
    end
    local waterwalkFolder = workspace:FindFirstChild("Waterwalk")
    if waterwalkFolder then pcall(function() waterwalkFolder:Destroy() end) end
end

-- Teleport Functions
local function teleportTo(dest)
    local char = game.Players.LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild('HumanoidRootPart')
    if not hrp then return end
    char:PivotTo(dest)
end

local function getInstanceAtPath(pathParts)
    local current = workspace
    for _, part in ipairs(pathParts) do
        if current and current:FindFirstChild(part) then
            current = current[part]
        else
            return nil
        end
    end
    return current
end

local Compkiller = (function()
    --[[
        SPL Interface

    Author: 4lpaca (Modified for SPL)
    License: MIT
    Github: https://github.com/4lpaca-pin/CompKiller
    --]]

    -- Local Variables
    local cloneref = cloneref or function(f) return f end;
    local TweenService = cloneref(game:GetService('TweenService'));
    local UserInputService = cloneref(game:GetService('UserInputService'));
    local TextService = cloneref(game:GetService('TextService'));
    local RunService = cloneref(game:GetService('RunService'));
    local Players = cloneref(game:GetService('Players'));
    local HttpService = cloneref(game:GetService('HttpService'));
    local LocalPlayer = Players.LocalPlayer;
    local CoreGui = (gethui and gethui()) or cloneref(game:FindFirstChild('CoreGui')) or LocalPlayer.PlayerGui;
    local Mouse = LocalPlayer:GetMouse();
    local CurrentCamera = workspace.CurrentCamera;

    local Compkiller = {
        Version = '1.8',
        Logo = "rbxassetid://120245531583106",
        Windows = {},
        Scale = {
            Window = UDim2.new(0, 456,0, 499),
            Mobile = UDim2.new(0, 450,0, 375),
            TabOpen = 185,
            TabClose = 85,
        },
        ArcylicParent = CurrentCamera
    };

    Compkiller.Colors = {
        Highlight = Color3.fromRGB(17, 238, 253),
        Toggle = Color3.fromRGB(14, 203, 213),
        Risky = Color3.fromRGB(251, 255, 39),
        BGDBColor = Color3.fromRGB(22, 24, 29),
        BlockColor = Color3.fromRGB(28, 29, 34),
        StrokeColor = Color3.fromRGB(37, 38, 43),
        SwitchColor = Color3.fromRGB(255, 255, 255),
        DropColor = Color3.fromRGB(33, 35, 39),
        MouseEnter = Color3.fromRGB(55, 58, 65),
        BlockBackground = Color3.fromRGB(39, 40, 47),
        LineColor = Color3.fromRGB(65, 65, 65),
        HighStrokeColor = Color3.fromRGB(55, 56, 63),
    };

    Compkiller.Elements = {
        Highlight = {},
        DropHighlight = {},
        Risky = {},
        BGDBColor = {},
        BlockColor = {},
        StrokeColor = {},
        SwitchColor = {},
        DropColor = {},
        BlockBackground = {},
        LineColor = {},
        HighStrokeColor = {},
    };

    Compkiller.DragBlacklist = {};
    Compkiller.IaDrag = false;
    Compkiller.LastDrag = tick();
    Compkiller.Flags = {};

    -- Basic utility functions
    function Compkiller:_RandomString()
        return "CK="..string.char(math.random(64,102),math.random(64,102),math.random(64,102),math.random(64,102),math.random(64,102),math.random(64,102),math.random(64,102),math.random(64,102),math.random(64,102),math.random(64,102),math.random(64,102),math.random(64,102),math.random(64,102),math.random(64,102),math.random(64,102),math.random(64,102),math.random(64,102),math.random(64,102),math.random(64,102),math.random(64,102));    
    end;

    function Compkiller:_IsMouseOverFrame(Frame)
        if not Frame then
            return;
        end;

        local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;

        if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then
            return true;
        end;
    end;

    function Compkiller:_Animation(Self, Info, Property)
        local Tween = TweenService:Create(Self, Info or TweenInfo.new(0.25), Property);
        Tween:Play();
        return Tween;
    end;

    function Compkiller:_Input(Frame, Callback)
        local Button = Instance.new('TextButton', Frame);
        Button.ZIndex = Frame.ZIndex + 10;
        Button.Size = UDim2.fromScale(1,1);
        Button.BackgroundTransparency = 1;
        Button.TextTransparency = 1;

        if Callback then
            Button.MouseButton1Click:Connect(Callback);
        end;

        return Button;
    end;

    function Compkiller:_Hover(Frame, OnHover, Release)
        Frame.MouseEnter:Connect(OnHover);
        Frame.MouseLeave:Connect(Release);
    end;

    function Compkiller.__CONFIG(config, default)
        config = config or {};
        for i,v in next, default do
            if config[i] == nil then
                config[i] = v;
            end;
        end;
        return config;
    end;

    function Compkiller.__SIGNAL(default)
        local Bindable = Instance.new('BindableEvent');
        Bindable.Name = string.sub(tostring({}),7);
        Bindable:SetAttribute('Value',default);

        local Binds = {
            __signals = {}    
        };

        function Binds:Connect(event)
            event(Bindable:GetAttribute("Value"));
            local signal = Bindable.Event:Connect(event);
            table.insert(Binds.__signals,signal);
            return signal;
        end;

        function Binds:Fire(value)
            local IsSame = Bindable:GetAttribute("Value") == value;
            Bindable:SetAttribute('Value',value);
            if not IsSame then
                Bindable:Fire(value);
            end;
        end;

        function Binds:GetValue()
            return Bindable:GetAttribute("Value");
        end;

        return Binds;
    end;

    -- Drag function from original
    function Compkiller:Drag(InputFrame, MoveFrame, Speed)
        local dragToggle = false;
        local dragStart = nil;
        local startPos = nil;
        local Tween = TweenInfo.new(Speed or 0.1);

        local function updateInput(input)
            local delta = input.Position - dragStart;
            local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y);

            Compkiller:_Animation(MoveFrame,Tween,{
                Position = position
            });
        end;

        InputFrame.InputBegan:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and #Compkiller.DragBlacklist <= 0 then 
                dragToggle = true
                dragStart = input.Position
                startPos = MoveFrame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragToggle = false;
                        Compkiller.IS_DRAG_MOVE = false;
                    end
                end)
            end

            if not Compkiller.IsDrage and dragToggle then
                Compkiller.LastDrag = tick();
            end;

            Compkiller.IaDrag = dragToggle;
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch and #Compkiller.DragBlacklist <= 0 then
                if dragToggle then
                    Compkiller.IS_DRAG_MOVE = true;
                    updateInput(input)
                else
                    Compkiller.IS_DRAG_MOVE = false;
                end
            else
                if #Compkiller.DragBlacklist > 0 then
                    dragToggle = false
                    Compkiller.IS_DRAG_MOVE = false;
                end
            end

            Compkiller.IaDrag = dragToggle;
        end);
    end;

    -- Create the main window function with proper dragging
    function Compkiller:Window(config)
        config = Compkiller.__CONFIG(config, {
            Name = "Window",
            Logo = "rbxassetid://120245531583106",
            Scale = UDim2.new(0, 456, 0, 499),
            TextSize = 14
        });

        -- Create the main GUI
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = Compkiller:_RandomString()
        ScreenGui.Parent = CoreGui
        ScreenGui.ResetOnSpawn = false
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

        local MainFrame = Instance.new("Frame")
        MainFrame.Name = Compkiller:_RandomString()
        MainFrame.Parent = ScreenGui
        MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        MainFrame.BackgroundColor3 = Compkiller.Colors.BGDBColor
        MainFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        MainFrame.BorderSizePixel = 0
        MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        MainFrame.Size = config.Scale
        MainFrame.ZIndex = 1

        local UICorner = Instance.new("UICorner")
        UICorner.CornerRadius = UDim.new(0, 6)
        UICorner.Parent = MainFrame

        local UIStroke = Instance.new("UIStroke")
        UIStroke.Color = Compkiller.Colors.StrokeColor
        UIStroke.Parent = MainFrame

        -- Title bar for dragging
        local TitleBar = Instance.new("Frame")
        TitleBar.Name = Compkiller:_RandomString()
        TitleBar.Parent = MainFrame
        TitleBar.BackgroundColor3 = Compkiller.Colors.BlockColor
        TitleBar.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TitleBar.BorderSizePixel = 0
        TitleBar.Size = UDim2.new(1, 0, 0, 30)
        TitleBar.ZIndex = 2

        local UICorner2 = Instance.new("UICorner")
        UICorner2.CornerRadius = UDim.new(0, 6)
        UICorner2.Parent = TitleBar

        local TitleLabel = Instance.new("TextLabel")
        TitleLabel.Name = Compkiller:_RandomString()
        TitleLabel.Parent = TitleBar
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Position = UDim2.new(0, 10, 0, 0)
        TitleLabel.Size = UDim2.new(1, -20, 1, 0)
        TitleLabel.ZIndex = 3
        TitleLabel.Font = Enum.Font.GothamBold
        TitleLabel.Text = config.Name
        TitleLabel.TextColor3 = Compkiller.Colors.SwitchColor
        TitleLabel.TextSize = 16
        TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

        -- Main content area
        local MainContent = Instance.new("Frame")
        MainContent.Name = Compkiller:_RandomString()
        MainContent.Parent = MainFrame
        MainContent.BackgroundTransparency = 1
        MainContent.Position = UDim2.new(0, 0, 0, 30)
        MainContent.Size = UDim2.new(1, 0, 1, -30)
        MainContent.ZIndex = 2

        -- Left sidebar
        local Sidebar = Instance.new("Frame")
        Sidebar.Name = Compkiller:_RandomString()
        Sidebar.Parent = MainContent
        Sidebar.BackgroundColor3 = Compkiller.Colors.BlockColor
        Sidebar.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Sidebar.BorderSizePixel = 0
        Sidebar.Size = UDim2.new(0, 150, 1, 0)
        Sidebar.ZIndex = 3

        local UICorner3 = Instance.new("UICorner")
        UICorner3.CornerRadius = UDim.new(0, 4)
        UICorner3.Parent = Sidebar

        local UIStroke2 = Instance.new("UIStroke")
        UIStroke2.Color = Compkiller.Colors.StrokeColor
        UIStroke2.Parent = Sidebar

        -- Logo and title in sidebar
        local LogoFrame = Instance.new("Frame")
        LogoFrame.Name = Compkiller:_RandomString()
        LogoFrame.Parent = Sidebar
        LogoFrame.BackgroundTransparency = 1
        LogoFrame.Size = UDim2.new(1, 0, 0, 50)
        LogoFrame.ZIndex = 4

        local LogoLabel = Instance.new("TextLabel")
        LogoLabel.Name = Compkiller:_RandomString()
        LogoLabel.Parent = LogoFrame
        LogoLabel.BackgroundTransparency = 1
        LogoLabel.Position = UDim2.new(0, 10, 0, 0)
        LogoLabel.Size = UDim2.new(1, -20, 1, 0)
        LogoLabel.ZIndex = 5
        LogoLabel.Font = Enum.Font.GothamBold
        LogoLabel.Text = "SPL"
        LogoLabel.TextColor3 = Compkiller.Colors.Highlight
        LogoLabel.TextSize = 18
        LogoLabel.TextXAlignment = Enum.TextXAlignment.Left

        -- Tab container in sidebar
        local TabContainer = Instance.new("Frame")
        TabContainer.Name = Compkiller:_RandomString()
        TabContainer.Parent = Sidebar
        TabContainer.BackgroundTransparency = 1
        TabContainer.Position = UDim2.new(0, 0, 0, 50)
        TabContainer.Size = UDim2.new(1, 0, 1, -50)
        TabContainer.ZIndex = 4

        local UIListLayout = Instance.new("UIListLayout")
        UIListLayout.Parent = TabContainer
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Padding = UDim.new(0, 5)

        -- Main content area (right side)
        local ContentArea = Instance.new("Frame")
        ContentArea.Name = Compkiller:_RandomString()
        ContentArea.Parent = MainContent
        ContentArea.BackgroundTransparency = 1
        ContentArea.Position = UDim2.new(0, 155, 0, 0)
        ContentArea.Size = UDim2.new(1, -155, 1, 0)
        ContentArea.ZIndex = 3

        -- Window controls
        local WindowArgs = {
            Root = ScreenGui,
            MainFrame = MainFrame,
            Sidebar = Sidebar,
            TabContainer = TabContainer,
            ContentArea = ContentArea,
            IsOpen = true,
            Tabs = {},
            SelectedTab = nil,
            THREADS = {}
        };

        -- Add dragging functionality
        Compkiller:Drag(TitleBar, MainFrame, 0.1);

        -- Toggle function
        function WindowArgs:Toggle(Value)
            MainFrame.Visible = Value;
        end;

        -- Tab function
        function WindowArgs:Tab(config)
            config = Compkiller.__CONFIG(config, {
                Name = "Tab",
                Icon = "home",
                Type = "Tab",
                EnableScrolling = true
            });

            -- Create tab button in sidebar
            local TabButton = Instance.new("Frame")
            TabButton.Name = Compkiller:_RandomString()
            TabButton.Parent = TabContainer
            TabButton.BackgroundColor3 = Compkiller.Colors.DropColor
            TabButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
            TabButton.BorderSizePixel = 0
            TabButton.Size = UDim2.new(1, -10, 0, 35)
            TabButton.ZIndex = 5

            local UICorner4 = Instance.new("UICorner")
            UICorner4.CornerRadius = UDim.new(0, 4)
            UICorner4.Parent = TabButton

            local TabLabel = Instance.new("TextLabel")
            TabLabel.Name = Compkiller:_RandomString()
            TabLabel.Parent = TabButton
            TabLabel.BackgroundTransparency = 1
            TabLabel.Position = UDim2.new(0, 10, 0, 0)
            TabLabel.Size = UDim2.new(1, -20, 1, 0)
            TabLabel.ZIndex = 6
            TabLabel.Font = Enum.Font.GothamMedium
            TabLabel.Text = config.Name
            TabLabel.TextColor3 = Compkiller.Colors.SwitchColor
            TabLabel.TextSize = 14
            TabLabel.TextXAlignment = Enum.TextXAlignment.Left

            -- Create tab content
            local TabContent = Instance.new("Frame")
            TabContent.Name = Compkiller:_RandomString()
            TabContent.Parent = ContentArea
            TabContent.BackgroundTransparency = 1
            TabContent.Size = UDim2.new(1, 0, 1, 0)
            TabContent.ZIndex = 4
            TabContent.Visible = false

            local TabArgs = {
                Root = TabContent,
                Button = TabButton,
                Name = config.Name
            };

            -- Section function
            function TabArgs:Section(config)
                config = Compkiller.__CONFIG(config, {
                    Name = "Section",
                    Position = "Left"
                });

                local SectionFrame = Instance.new("Frame")
                SectionFrame.Name = Compkiller:_RandomString()
                SectionFrame.Parent = TabContent
                SectionFrame.BackgroundColor3 = Compkiller.Colors.BlockColor
                SectionFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
                SectionFrame.BorderSizePixel = 0
                SectionFrame.Position = UDim2.new(config.Position == "Left" and 0 or 0.5, 0, 0, 0)
                SectionFrame.Size = UDim2.new(0.48, -5, 1, 0)
                SectionFrame.ZIndex = 5

                local UICorner5 = Instance.new("UICorner")
                UICorner5.CornerRadius = UDim.new(0, 4)
                UICorner5.Parent = SectionFrame

                local UIStroke3 = Instance.new("UIStroke")
                UIStroke3.Color = Compkiller.Colors.StrokeColor
                UIStroke3.Parent = SectionFrame

                local SectionLabel = Instance.new("TextLabel")
                SectionLabel.Name = Compkiller:_RandomString()
                SectionLabel.Parent = SectionFrame
                SectionLabel.BackgroundTransparency = 1
                SectionLabel.Position = UDim2.new(0, 10, 0, 5)
                SectionLabel.Size = UDim2.new(1, -20, 0, 20)
                SectionLabel.ZIndex = 6
                SectionLabel.Font = Enum.Font.GothamMedium
                SectionLabel.Text = config.Name
                SectionLabel.TextColor3 = Compkiller.Colors.SwitchColor
                SectionLabel.TextSize = 14
                SectionLabel.TextXAlignment = Enum.TextXAlignment.Left

                local ContentArea2 = Instance.new("Frame")
                ContentArea2.Name = Compkiller:_RandomString()
                ContentArea2.Parent = SectionFrame
                ContentArea2.BackgroundTransparency = 1
                ContentArea2.Position = UDim2.new(0, 0, 0, 30)
                ContentArea2.Size = UDim2.new(1, 0, 1, -30)
                ContentArea2.ZIndex = 6

                local UIListLayout2 = Instance.new("UIListLayout")
                UIListLayout2.Parent = ContentArea2
                UIListLayout2.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout2.Padding = UDim.new(0, 5)

                local SectionArgs = {
                    Root = SectionFrame,
                    ContentArea = ContentArea2
                };

                -- AddToggle function
                function SectionArgs:AddToggle(config)
                    config = Compkiller.__CONFIG(config, {
                        Name = "Toggle",
                        Default = false,
                        Flag = nil,
                        Callback = function() end
                    });

                    local ToggleFrame = Instance.new("Frame")
                    ToggleFrame.Name = Compkiller:_RandomString()
                    ToggleFrame.Parent = ContentArea2
                    ToggleFrame.BackgroundTransparency = 1
                    ToggleFrame.Size = UDim2.new(1, 0, 0, 25)
                    ToggleFrame.ZIndex = 7

                    local ToggleLabel = Instance.new("TextLabel")
                    ToggleLabel.Name = Compkiller:_RandomString()
                    ToggleLabel.Parent = ToggleFrame
                    ToggleLabel.BackgroundTransparency = 1
                    ToggleLabel.Position = UDim2.new(0, 0, 0, 0)
                    ToggleLabel.Size = UDim2.new(1, -30, 1, 0)
                    ToggleLabel.ZIndex = 8
                    ToggleLabel.Font = Enum.Font.Gotham
                    ToggleLabel.Text = config.Name
                    ToggleLabel.TextColor3 = Compkiller.Colors.SwitchColor
                    ToggleLabel.TextSize = 12
                    ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left

                    local ToggleButton = Instance.new("Frame")
                    ToggleButton.Name = Compkiller:_RandomString()
                    ToggleButton.Parent = ToggleFrame
                    ToggleButton.AnchorPoint = Vector2.new(1, 0.5)
                    ToggleButton.BackgroundColor3 = config.Default and Compkiller.Colors.Toggle or Compkiller.Colors.DropColor
                    ToggleButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    ToggleButton.BorderSizePixel = 0
                    ToggleButton.Position = UDim2.new(1, 0, 0.5, 0)
                    ToggleButton.Size = UDim2.new(0, 25, 0, 15)
                    ToggleButton.ZIndex = 8

                    local UICorner6 = Instance.new("UICorner")
                    UICorner6.CornerRadius = UDim.new(1, 0)
                    UICorner6.Parent = ToggleButton

                    local ToggleDot = Instance.new("Frame")
                    ToggleDot.Name = Compkiller:_RandomString()
                    ToggleDot.Parent = ToggleButton
                    ToggleDot.AnchorPoint = Vector2.new(0.5, 0.5)
                    ToggleDot.BackgroundColor3 = Compkiller.Colors.SwitchColor
                    ToggleDot.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    ToggleDot.BorderSizePixel = 0
                    ToggleDot.Position = UDim2.new(config.Default and 0.75 or 0.25, 0, 0.5, 0)
                    ToggleDot.Size = UDim2.new(0.55, 0, 0.55, 0)
                    ToggleDot.ZIndex = 9

                    local UICorner7 = Instance.new("UICorner")
                    UICorner7.CornerRadius = UDim.new(1, 0)
                    UICorner7.Parent = ToggleDot

                    local ToggleInput = Compkiller:_Input(ToggleFrame, function()
                        config.Default = not config.Default;
                        
                        if config.Default then
                            Compkiller:_Animation(ToggleButton, TweenInfo.new(0.2), {
                                BackgroundColor3 = Compkiller.Colors.Toggle
                            });
                            Compkiller:_Animation(ToggleDot, TweenInfo.new(0.2), {
                                Position = UDim2.new(0.75, 0, 0.5, 0)
                            });
                        else
                            Compkiller:_Animation(ToggleButton, TweenInfo.new(0.2), {
                                BackgroundColor3 = Compkiller.Colors.DropColor
                            });
                            Compkiller:_Animation(ToggleDot, TweenInfo.new(0.2), {
                                Position = UDim2.new(0.25, 0, 0.5, 0)
                            });
                        end;
                        
                        config.Callback(config.Default);
                    end);

                    local ToggleArgs = {};

                    function ToggleArgs:SetValue(value)
                        config.Default = value;
                        
                        if config.Default then
                            Compkiller:_Animation(ToggleButton, TweenInfo.new(0.2), {
                                BackgroundColor3 = Compkiller.Colors.Toggle
                            });
                            Compkiller:_Animation(ToggleDot, TweenInfo.new(0.2), {
                                Position = UDim2.new(0.75, 0, 0.5, 0)
                            });
                        else
                            Compkiller:_Animation(ToggleButton, TweenInfo.new(0.2), {
                                BackgroundColor3 = Compkiller.Colors.DropColor
                            });
                            Compkiller:_Animation(ToggleDot, TweenInfo.new(0.2), {
                                Position = UDim2.new(0.25, 0, 0.5, 0)
                            });
                        end;
                        
                        config.Callback(config.Default);
                    end;

                    function ToggleArgs:GetValue()
                        return config.Default;
                    end;

                    if config.Flag then
                        Compkiller.Flags[config.Flag] = ToggleArgs;
                    end;

                    return ToggleArgs;
                end;

                -- AddButton function
                function SectionArgs:AddButton(config)
                    config = Compkiller.__CONFIG(config, {
                        Name = "Button",
                        Callback = function() end
                    });

                    local ButtonFrame = Instance.new("Frame")
                    ButtonFrame.Name = Compkiller:_RandomString()
                    ButtonFrame.Parent = ContentArea2
                    ButtonFrame.BackgroundColor3 = Compkiller.Colors.Highlight
                    ButtonFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    ButtonFrame.BorderSizePixel = 0
                    ButtonFrame.Size = UDim2.new(1, 0, 0, 25)
                    ButtonFrame.ZIndex = 7

                    local UICorner8 = Instance.new("UICorner")
                    UICorner8.CornerRadius = UDim.new(0, 3)
                    UICorner8.Parent = ButtonFrame

                    local UIStroke4 = Instance.new("UIStroke")
                    UIStroke4.Color = Compkiller.Colors.StrokeColor
                    UIStroke4.Parent = ButtonFrame

                    local ButtonLabel = Instance.new("TextLabel")
                    ButtonLabel.Name = Compkiller:_RandomString()
                    ButtonLabel.Parent = ButtonFrame
                    ButtonLabel.BackgroundTransparency = 1
                    ButtonLabel.Size = UDim2.new(1, 0, 1, 0)
                    ButtonLabel.ZIndex = 8
                    ButtonLabel.Font = Enum.Font.GothamMedium
                    ButtonLabel.Text = config.Name
                    ButtonLabel.TextColor3 = Compkiller.Colors.SwitchColor
                    ButtonLabel.TextSize = 12

                    Compkiller:_Input(ButtonFrame, config.Callback);

                    Compkiller:_Hover(ButtonFrame, function()
                        Compkiller:_Animation(ButtonFrame, TweenInfo.new(0.2), {
                            BackgroundTransparency = 0
                        });
                    end, function()
                        Compkiller:_Animation(ButtonFrame, TweenInfo.new(0.2), {
                            BackgroundTransparency = 0.1
                        });
                    end);

                    return {};
                end;

                -- AddSlider function
                function SectionArgs:AddSlider(config)
                    config = Compkiller.__CONFIG(config, {
                        Name = "Slider",
                        Min = 0,
                        Max = 100,
                        Default = 50,
                        Round = 0,
                        Callback = function() end
                    });

                    local SliderFrame = Instance.new("Frame")
                    SliderFrame.Name = Compkiller:_RandomString()
                    SliderFrame.Parent = ContentArea2
                    SliderFrame.BackgroundTransparency = 1
                    SliderFrame.Size = UDim2.new(1, 0, 0, 35)
                    SliderFrame.ZIndex = 7

                    local SliderLabel = Instance.new("TextLabel")
                    SliderLabel.Name = Compkiller:_RandomString()
                    SliderLabel.Parent = SliderFrame
                    SliderLabel.BackgroundTransparency = 1
                    SliderLabel.Position = UDim2.new(0, 0, 0, 0)
                    SliderLabel.Size = UDim2.new(1, 0, 0, 15)
                    SliderLabel.ZIndex = 8
                    SliderLabel.Font = Enum.Font.Gotham
                    SliderLabel.Text = config.Name .. ": " .. config.Default
                    SliderLabel.TextColor3 = Compkiller.Colors.SwitchColor
                    SliderLabel.TextSize = 12
                    SliderLabel.TextXAlignment = Enum.TextXAlignment.Left

                    local SliderBar = Instance.new("Frame")
                    SliderBar.Name = Compkiller:_RandomString()
                    SliderBar.Parent = SliderFrame
                    SliderBar.BackgroundColor3 = Compkiller.Colors.DropColor
                    SliderBar.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    SliderBar.BorderSizePixel = 0
                    SliderBar.Position = UDim2.new(0, 0, 0, 20)
                    SliderBar.Size = UDim2.new(1, 0, 0, 10)
                    SliderBar.ZIndex = 8

                    local UICorner9 = Instance.new("UICorner")
                    UICorner9.CornerRadius = UDim.new(0, 5)
                    UICorner9.Parent = SliderBar

                    local UIStroke5 = Instance.new("UIStroke")
                    UIStroke5.Color = Compkiller.Colors.StrokeColor
                    UIStroke5.Parent = SliderBar

                    local SliderFill = Instance.new("Frame")
                    SliderFill.Name = Compkiller:_RandomString()
                    SliderFill.Parent = SliderBar
                    SliderFill.BackgroundColor3 = Compkiller.Colors.Highlight
                    SliderFill.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    SliderFill.BorderSizePixel = 0
                    SliderFill.Size = UDim2.new((config.Default - config.Min) / (config.Max - config.Min), 0, 1, 0)
                    SliderFill.ZIndex = 9

                    local UICorner10 = Instance.new("UICorner")
                    UICorner10.CornerRadius = UDim.new(0, 5)
                    UICorner10.Parent = SliderFill

                    local SliderArgs = {};

                    function SliderArgs:SetValue(value)
                        config.Default = value;
                        SliderLabel.Text = config.Name .. ": " .. value;
                        Compkiller:_Animation(SliderFill, TweenInfo.new(0.2), {
                            Size = UDim2.new((value - config.Min) / (config.Max - config.Min), 0, 1, 0)
                        });
                        config.Callback(value);
                    end;

                    function SliderArgs:GetValue()
                        return config.Default;
                    end;

                    return SliderArgs;
                end;

                return SectionArgs;
            end;

            -- Tab selection logic
            Compkiller:_Input(TabButton, function()
                -- Hide all tab contents
                for _, tab in pairs(WindowArgs.Tabs) do
                    tab.Root.Visible = false;
                    Compkiller:_Animation(tab.Button, TweenInfo.new(0.2), {
                        BackgroundColor3 = Compkiller.Colors.DropColor
                    });
                end;
                
                -- Show selected tab
                TabContent.Visible = true;
                Compkiller:_Animation(TabButton, TweenInfo.new(0.2), {
                    BackgroundColor3 = Compkiller.Colors.Highlight
                });
                
                WindowArgs.SelectedTab = TabArgs;
            end);

            -- Add to tabs list
            table.insert(WindowArgs.Tabs, TabArgs);
            
            -- Select first tab by default
            if #WindowArgs.Tabs == 1 then
                TabContent.Visible = true;
                Compkiller:_Animation(TabButton, TweenInfo.new(0.2), {
                    BackgroundColor3 = Compkiller.Colors.Highlight
                });
                WindowArgs.SelectedTab = TabArgs;
            end;

            return TabArgs;
        end;

        return WindowArgs;
    end;

    return Compkiller;
end)();

-- Now create your window and UI elements
local Window
local success, err = pcall(function()
    Window = Compkiller:Window({
        Name = "SPL Hub",
        Logo = "rbxassetid://120245531583106",
        Scale = UDim2.new(0, 456, 0, 499),
        TextSize = 14
    });
end)

if not success then
    warn("Failed to create window:", err)
    return
end

-- Create all tabs
local CombatTab = Window:Tab({
    Name = "Combat",
    Icon = "⚔️",
    Type = "Tab",
    EnableScrolling = true
});

local MovementTab = Window:Tab({
    Name = "Movement",
    Icon = " ",
    Type = "Tab",
    EnableScrolling = true
});

local UtilityTab = Window:Tab({
    Name = "Utility",
    Icon = "🔧",
    Type = "Tab",
    EnableScrolling = true
});

local VisualTab = Window:Tab({
    Name = "Visual",
    Icon = " ",
    Type = "Tab",
    EnableScrolling = true
});

local QuestsTab = Window:Tab({
    Name = "Quests",
    Icon = " ",
    Type = "Tab",
    EnableScrolling = true
});

local ShopsTab = Window:Tab({
    Name = "Shops",
    Icon = "🛒",
    Type = "Tab",
    EnableScrolling = true
});

local TeleportTab = Window:Tab({
    Name = "Teleport",
    Icon = "🧭",
    Type = "Tab",
    EnableScrolling = true
});

local ConfigTab = Window:Tab({
    Name = "Config",
    Icon = "⚙️",
    Type = "Tab",
    EnableScrolling = true
});

-- Create sections for each tab
local CombatSection = CombatTab:Section({
    Name = "Catacombs Preset",
    Position = "Left"
});

local MovementSection = MovementTab:Section({
    Name = "Movement Features",
    Position = "Left"
});

local UtilitySection = UtilityTab:Section({
    Name = "Utility Features",
    Position = "Left"
});

local VisualSection = VisualTab:Section({
    Name = "Visual Features",
    Position = "Left"
});

local QuestsSection = QuestsTab:Section({
    Name = "Quest Automation",
    Position = "Left"
});

local ShopsSection = ShopsTab:Section({
    Name = "Shop Automation",
    Position = "Left"
});

local TeleportSection = TeleportTab:Section({
    Name = "Teleport Locations",
    Position = "Left"
});

local ConfigSection = ConfigTab:Section({
    Name = "Configuration",
    Position = "Left"
});

-- Combat Tab Content - First Section
CombatSection:AddToggle({
    Name = "Fireball Aimbot",
    Default = config.FireBallAimbot,
    Flag = "FireBallAimbot",
    Callback = function(enabled)
        config.FireBallAimbot = enabled
        ToggleCatacombsAimbot(enabled)
        saveConfig()
    end
});

CombatSection:AddSlider({
    Name = "Fireball Cooldown",
    Min = 0.05,
    Max = 1.0,
    Default = config.fireballCooldown,
    Callback = function(value)
        config.fireballCooldown = value
        saveConfig()
    end
});

-- Combat Tab Content - Second Section
local CombatSection2 = CombatTab:Section({
    Name = "City Preset",
    Position = "Right"
});

CombatSection2:AddToggle({
    Name = "Fireball Aimbot",
    Default = config.FireBallAimbotCity,
    Flag = "FireBallAimbotCity",
    Callback = function(enabled)
        config.FireBallAimbotCity = enabled
        ToggleCityAimbot(enabled)
        saveConfig()
    end
});

CombatSection2:AddSlider({
    Name = "City Fireball Cooldown",
    Min = 0.05,
    Max = 1.0,
    Default = config.cityFireballCooldown,
    Callback = function(value)
        config.cityFireballCooldown = value
        saveConfig()
    end
});

-- Movement Tab Content
MovementSection:AddToggle({
    Name = "No Clip",
    Default = config.NoClip,
    Flag = "NoClip",
    Callback = function(enabled)
        config.NoClip = enabled
        ToggleNoClip(enabled)
        saveConfig()
    end
});

-- Utility Tab Content
UtilitySection:AddToggle({
    Name = "AFK Optimization",
    Default = config.GraphicsOptimization,
    Flag = "GraphicsOptimization",
    Callback = function(enabled)
        config.GraphicsOptimization = enabled
        ToggleAFKOpt(enabled)
        saveConfig()
    end
});

UtilitySection:AddToggle({
    Name = "Graphics Optimization",
    Default = config.GraphicsOptimizationAdvanced,
    Flag = "GraphicsOptimizationAdvanced",
    Callback = function(enabled)
        config.GraphicsOptimizationAdvanced = enabled
        ToggleGraphicsOptAdvanced(enabled)
        saveConfig()
    end
});

UtilitySection:AddToggle({
    Name = "Remove Map Clutter",
    Default = config.RemoveMapClutter,
    Flag = "RemoveMapClutter",
    Callback = function(enabled)
        if enabled then RunRemoveMapClutter() end
        config.RemoveMapClutter = enabled
        saveConfig()
    end
});

UtilitySection:AddToggle({
    Name = "Death Webhook",
    Default = config.DeathWebhook,
    Flag = "DeathWebhook",
    Callback = function(enabled)
        config.DeathWebhook = enabled
        saveConfig()
    end
});

UtilitySection:AddToggle({
    Name = "Panic Webhook",
    Default = config.PanicWebhook,
    Flag = "PanicWebhook",
    Callback = function(enabled)
        config.PanicWebhook = enabled
        saveConfig()
    end
});

UtilitySection:AddToggle({
    Name = "Smart Panic",
    Default = config.SmartPanic,
    Flag = "SmartPanic",
    Callback = function(enabled)
        config.SmartPanic = enabled
        getgenv().SmartPanic = enabled
        saveConfig()
    end
});

-- Visual Tab Content
VisualSection:AddToggle({
    Name = "Player ESP",
    Default = config.PlayerESP,
    Flag = "PlayerESP",
    Callback = function(enabled)
        config.PlayerESP = enabled
        TogglePlayerESP(enabled)
        saveConfig()
    end
});

VisualSection:AddToggle({
    Name = "Mob ESP",
    Default = config.MobESP,
    Flag = "MobESP",
    Callback = function(enabled)
        config.MobESP = enabled
        ToggleMobESP(enabled)
        saveConfig()
    end
});

-- Quests Tab Content
QuestsSection:AddToggle({
    Name = "Dishes Side Task",
    Default = config.AutoWashDishes,
    Flag = "AutoWashDishes",
    Callback = function(enabled)
        config.AutoWashDishes = enabled
        ToggleAutoWashDishes(enabled)
        saveConfig()
    end
});

QuestsSection:AddToggle({
    Name = "Ninja Side Task",
    Default = config.AutoNinjaSideTask,
    Flag = "AutoNinjaSideTask",
    Callback = function(enabled)
        config.AutoNinjaSideTask = enabled
        getgenv().AutoNinjaSideTask = enabled
        if enabled then
            task.spawn(function()
                while getgenv().AutoNinjaSideTask do
                    pcall(function()
                        local player = game.Players.LocalPlayer
                        local humanoid = player.Character and player.Character:FindFirstChild('Humanoid')
                        if humanoid and humanoid.Health <= 0 then
                            getgenv().AutoNinjaSideTask = false
                            config.AutoNinjaSideTask = false
                            saveConfig()
                            return
                        end
                        
                        game:GetService("ReplicatedStorage"):WaitForChild("Events", 9e9)
                            :WaitForChild("Other", 9e9)
                            :WaitForChild("StartSideTask", 9e9)
                            :FireServer(9)
                            
                        game:GetService("ReplicatedStorage"):WaitForChild("Events", 9e9)
                            :WaitForChild("Other", 9e9)
                            :WaitForChild("ClaimSideTask", 9e9)
                            :FireServer(9)
                    end)
                    task.wait(60)
                end
            end)
        end
        saveConfig()
    end
});

QuestsSection:AddToggle({
    Name = "Animatronics Side Task",
    Default = config.AutoAnimatronicsSideTask,
    Flag = "AutoAnimatronicsSideTask",
    Callback = function(enabled)
        config.AutoAnimatronicsSideTask = enabled
        getgenv().AutoAnimatronicsSideTask = enabled
        if enabled then
            task.spawn(function()
                while getgenv().AutoAnimatronicsSideTask do
                    pcall(function()
                        local player = game.Players.LocalPlayer
                        local humanoid = player.Character and player.Character:FindFirstChild('Humanoid')
                        if humanoid and humanoid.Health <= 0 then
                            getgenv().AutoAnimatronicsSideTask = false
                            config.AutoAnimatronicsSideTask = false
                            saveConfig()
                            return
                        end
                        
                        game:GetService("ReplicatedStorage"):WaitForChild("Events", 9e9)
                            :WaitForChild("Other", 9e9)
                            :WaitForChild("StartSideTask", 9e9)
                            :FireServer(10)
                            
                        game:GetService("ReplicatedStorage"):WaitForChild("Events", 9e9)
                            :WaitForChild("Other", 9e9)
                            :WaitForChild("ClaimSideTask", 9e9)
                            :FireServer(10)
                    end)
                    task.wait(60)
                end
            end)
        end
        saveConfig()
    end
});

QuestsSection:AddToggle({
    Name = "Mutants Side Task",
    Default = config.AutoMutantsSideTask,
    Flag = "AutoMutantsSideTask",
    Callback = function(enabled)
        config.AutoMutantsSideTask = enabled
        getgenv().AutoMutantsSideTask = enabled
        if enabled then
            task.spawn(function()
                while getgenv().AutoMutantsSideTask do
                    pcall(function()
                        local player = game.Players.LocalPlayer
                        local humanoid = player.Character and player.Character:FindFirstChild('Humanoid')
                        if humanoid and humanoid.Health <= 0 then
                            getgenv().AutoMutantsSideTask = false
                            config.AutoMutantsSideTask = false
                            saveConfig()
                            return
                        end
                        
                        game:GetService("ReplicatedStorage"):WaitForChild("Events", 9e9)
                            :WaitForChild("Other", 9e9)
                            :WaitForChild("StartSideTask", 9e9)
                            :FireServer(7)
                            
                        game:GetService("ReplicatedStorage"):WaitForChild("Events", 9e9)
                            :WaitForChild("Other", 9e9)
                            :WaitForChild("ClaimSideTask", 9e9)
                            :FireServer(7)
                    end)
                    task.wait(60)
                end
            end)
        end
        saveConfig()
    end
});

-- Shops Tab Content
ShopsSection:AddToggle({
    Name = "Exotic Shop Potion Auto Buy",
    Default = config.AutoBuyPotions,
    Flag = "AutoBuyPotions",
    Callback = function(enabled)
        config.AutoBuyPotions = enabled
        ToggleExoticAutoBuy(enabled)
        saveConfig()
    end
});

ShopsSection:AddToggle({
    Name = "Vending Machine Potion Auto Buy",
    Default = config.VendingPotionAutoBuy,
    Flag = "VendingPotionAutoBuy",
    Callback = function(enabled)
        config.VendingPotionAutoBuy = enabled
        ToggleVending(enabled)
        saveConfig()
    end
});

-- Teleport Tab Content
TeleportSection:AddButton({
    Name = "Spawn",
    Callback = function()
        local spawn = workspace:FindFirstChild("Spawn")
        if spawn then
            teleportTo(spawn.CFrame)
        end
    end
});

TeleportSection:AddButton({
    Name = "City",
    Callback = function()
        local city = workspace:FindFirstChild("City")
        if city then
            teleportTo(city.CFrame)
        end
    end
});

TeleportSection:AddButton({
    Name = "Catacombs",
    Callback = function()
        local catacombs = workspace:FindFirstChild("Catacombs")
        if catacombs then
            teleportTo(catacombs.CFrame)
        end
    end
});

-- Config Tab Content
ConfigSection:AddButton({
    Name = "Save Config",
    Callback = function()
        if saveConfig() then
            print('Config saved successfully!')
        else
            warn('Failed to save config!')
        end
    end
});

ConfigSection:AddButton({
    Name = "Load Config",
    Callback = function()
        if loadConfig() then
            print('Config loaded successfully!')
            -- Apply loaded config to all toggles
            local function applyDiff(flag, getter, toggler)
                local current = getter()
                if current ~= flag then toggler(flag) end
            end

            applyDiff(config.NoClip, function() return getgenv().NoClip or false end, ToggleNoClip)
            applyDiff(config.GraphicsOptimization, function() return getgenv().GraphicsOptimization or false end, ToggleAFKOpt)
            applyDiff(config.GraphicsOptimizationAdvanced, function() return getgenv().GraphicsOptimizationAdvanced or false end, ToggleGraphicsOptAdvanced)
            applyDiff(config.PlayerESP, function() return getgenv().PlayerESP or false end, TogglePlayerESP)
                         applyDiff(config.MobESP, function()
                 local M = getgenv().EnemyESP2
                 return (M and M.enabled) or false
             end, ToggleMobESP)
             applyDiff(config.FireBallAimbot, function() return getgenv().FireBallAimbot or false end, ToggleCatacombsAimbot)
            applyDiff(config.FireBallAimbotCity, function() return getgenv().FireBallAimbotCity or false end, ToggleCityAimbot)
            applyDiff(config.AutoWashDishes, function() return getgenv().AutoWashDishes or false end, ToggleAutoWashDishes)
            applyDiff(config.AutoBuyPotions, function() return getgenv().AutoBuyPotions or false end, ToggleExoticAutoBuy)
            applyDiff(config.VendingPotionAutoBuy, function() return getgenv().VendingPotionAutoBuy or false end, ToggleVending)
        else
            warn('Failed to load config!')
        end
    end
});

-- Add keybind functionality
local awaitingHideKeyCapture = false
local SetHideKeyButtonRef

game:GetService('UserInputService').InputBegan:Connect(function(input, gp)
    if gp then return end
    if awaitingHideKeyCapture and input.UserInputType == Enum.UserInputType.Keyboard then
        config.HideGUIKey = input.KeyCode.Name
        saveConfig()
        awaitingHideKeyCapture = false
        if SetHideKeyButtonRef and SetHideKeyButtonRef:IsA('TextButton') then
            SetHideKeyButtonRef.Text = "Set Hide Key (" .. (config.HideGUIKey or "RightControl") .. ")"
        end
        return
    end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local keyName = input.KeyCode.Name
        local targetKey = config.HideGUIKey or 'RightControl'
        if keyName == targetKey then
            Window.MainFrame.Visible = not Window.MainFrame.Visible
        end
    end
end);

ConfigSection:AddButton({
    Name = "Set Hide Key (" .. (config.HideGUIKey or "RightControl") .. ")",
    Callback = function()
        awaitingHideKeyCapture = true
        print("Press any key to set as hide key...")
    end
});

print("Complete SPL UI Library loaded successfully!")
print("Click on tabs in the sidebar to navigate")
print("Drag the title bar to move the window")
print("All UI elements are functional and ready to use!")

-- Ensure GUI is visible
if Window and Window.MainFrame then
    Window.MainFrame.Visible = true
    print("GUI is now visible!")
else
    warn("Failed to make GUI visible - Window or MainFrame not found")
end
