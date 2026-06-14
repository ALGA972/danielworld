-- c00lSaken clean rebuild (complete v20 autogen safehook)
-- built from scratch with a lightweight native UI
-- keeps important game paths from the old script:
-- ReplicatedStorage.Assets.Survivors.Veeronica.Behavior
-- ReplicatedStorage.Systems.Character.Game.Sprinting
-- workspace.Players.Killers / Survivors
-- PlayerGui.MainUI.AbilityContainer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")

local lp = Players.LocalPlayer
local PlayerGui = lp:WaitForChild("PlayerGui")

-- executor compatibility helpers
local env = (getgenv and getgenv()) or _G
env.c00lSakenClean = env.c00lSakenClean or {}
local sharedState = env.c00lSakenClean

if sharedState._connections then
    for _, c in ipairs(sharedState._connections) do
        pcall(function() c:Disconnect() end)
    end
end
if sharedState._gui and sharedState._gui.Parent then
    pcall(function() sharedState._gui:Destroy() end)
end

sharedState._connections = {}
sharedState._esp = {}
sharedState._startedAt = tick()
sharedState._emoteLayoutCache = sharedState._emoteLayoutCache or {}

local function bind(conn)
    table.insert(sharedState._connections, conn)
    return conn
end

local function currentCharacter()
    return lp.Character
end

local function getRoot(model)
    return model and model:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(model)
    return model and model:FindFirstChildOfClass("Humanoid")
end


local function isCharacterReady()
    local char = currentCharacter()
    if not char or not char.Parent then return false end

    local hum = getHumanoid(char)
    local root = getRoot(char)
    if not hum or not root then return false end

    if hum.Health <= 0 then return false end

    return true
end

local function inGracePeriod()
    local last = sharedState._lastSpawn or sharedState._startedAt
    if (tick() - last) < 12 then
        return true
    end
    return not isCharacterReady()
end

sharedState._lastSpawn = tick()
bind(lp.CharacterAdded:Connect(function(char)
    sharedState._lastSpawn = tick()
    sharedState._emoteLayoutCache = {}

    task.defer(function()
        local hum = getHumanoid(char)
        if hum then
            hum.AutoRotate = true
        end
    end)
end))

local updateVoidrush
local updateAutoTrick

local Config = {
    Role = {
        VoidrushControl = false,
        AutoTrick = false,
    },
    Stamina = {
        Infinite = false,
        UseCustomMax = false,
        UseCustomGain = false,
        UseCustomLoss = false,
        UseCustomSpeed = false,
        Max = 100,
        Gain = 20,
        Loss = 5,
        Speed = 28,
    },
    AutoBlock = {
        Anim = false,
        Audio = false,
        Range = 12,
        Facing = true,
        FacingDot = -0.3,
        Delay = 0,
        AutoPunch = false,
        AimPunch = false,
        Prediction = 4,
    },
    Visuals = {
        Enabled = false,
        Killer = true,
        Survivor = true,
        Items = false,
        Generator = false,
        Labels = true,
        LabelSize = 32,
        Refresh = 0.7,
    },
    Anti = {
        Blindness = false,
        Subspace = false,
        Stun = false,
        Slow = false,
        HiddenStats = false,
        Popup1x = false,
        FakeNoli = false,
    },
    Other = {
        Jump = false,
        AlwaysShowChat = false,
        EmoteMenuHotkey = true,
        EmoteMenuUseForcedLayout = true,
        AutoGenHotkey = true,
        AutoGenSpeed = 0.08,
    }
}

local autoBlockTriggerSounds = {
    ["102228729296384"]=true,["140242176732868"]=true,["112809109188560"]=true,["136323728355613"]=true,
    ["115026634746636"]=true,["84116622032112"]=true,["108907358619313"]=true,["127793641088496"]=true,
    ["86174610237192"]=true,["95079963655241"]=true,["101199185291628"]=true,["119942598489800"]=true,
    ["84307400688050"]=true,["113037804008732"]=true,["105200830849301"]=true,["75330693422988"]=true,
    ["82221759983649"]=true,["81702359653578"]=true,["108610718831698"]=true,["112395455254818"]=true,
    ["109431876587852"]=true,["109348678063422"]=true,["85853080745515"]=true,["12222216"]=true,
    ["105840448036441"]=true,["114742322778642"]=true,["119583605486352"]=true,["79980897195554"]=true,
    ["71805956520207"]=true,["79391273191671"]=true,["89004992452376"]=true,["101553872555606"]=true,
    ["101698569375359"]=true,["106300477136129"]=true,["116581754553533"]=true,["117231507259853"]=true,
    ["119089145505438"]=true,["121954639447247"]=true,["125213046326879"]=true,["131406927389838"]=true
}

local autoBlockTriggerAnims = {
    ["126830014841198"]=true, ["126355327951215"]=true, ["121086746534252"]=true,
    ["18885909645"]=true, ["98456918873918"]=true, ["105458270463374"]=true,
    ["83829782357897"]=true, ["125403313786645"]=true, ["118298475669935"]=true,
    ["82113744478546"]=true, ["70371667919898"]=true, ["99135633258223"]=true,
    ["97167027849946"]=true, ["109230267448394"]=true, ["139835501033932"]=true,
    ["126896426760253"]=true, ["109667959938617"]=true, ["126681776859538"]=true,
    ["129976080405072"]=true, ["121293883585738"]=true, ["81639435858902"]=true,
    ["137314737492715"]=true, ["92173139187970"]=true, ["122709416391"]=true,
    ["879895330952"]=true, ["131430497821198"]=true, ["127172483138092"]=true,
    ["18885919947"]=true, ["87259391926321"]=true, ["106014898528300"]=true,
    ["86545133269813"]=true, ["89448354637442"]=true, ["90499469533503"]=true,
    ["116618003477002"]=true, ["106086955212611"]=true, ["107640065977686"]=true,
    ["77124578197357"]=true, ["101771617803133"]=true, ["134958187822107"]=true,
    ["111313169447787"]=true, ["71685573690338"]=true, ["129843313690921"]=true,
    ["97623143664485"]=true, ["136007065400978"]=true, ["86096387000557"]=true,
    ["108807732150251"]=true, ["138040001965654"]=true, ["73502073176819"]=true,
    ["86709774283672"]=true, ["140703210927645"]=true, ["96173857867228"]=true,
    ["121255898612475"]=true, ["98031287364865"]=true, ["119462383658044"]=true,
    ["77448521277146"]=true, ["103741352379819"]=true, ["131696603025265"]=true,
    ["122503338277352"]=true, ["97648548303678"]=true, ["94162446513587"]=true,
    ["84426150435898"]=true, ["93069721274110"]=true, ["114620047310688"]=true,
    ["97433060861952"]=true, ["82183356141401"]=true, ["100592913030351"]=true,
    ["70447634862911"]=true, ["106847695270773"]=true, ["120112897026015"]=true,
    ["74707328554358"]=true, ["133336594357903"]=true, ["86204001129974"]=true,
    ["124243639579224"]=true, ["131543461321709"]=true, ["136323728355613"]=true
}

local function notify(text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "c00lSaken Clean",
            Text = text,
            Duration = 3
        })
    end)
end

local function setChatVisibility(enabled)
    local chatWindow = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
    local chatInput = TextChatService:FindFirstChildOfClass("ChatInputBarConfiguration")

    if chatWindow then
        pcall(function()
            chatWindow.Enabled = enabled
        end)
    end

    if chatInput then
        pcall(function()
            chatInput.Enabled = enabled
        end)
    end

    local legacyChat = PlayerGui:FindFirstChild("Chat")
    if legacyChat then
        pcall(function()
            legacyChat.Enabled = enabled
        end)
    end
end

local function hide1xPopupFrames()
    local temp = PlayerGui:FindFirstChild("TemporaryUI")
    if not temp then
        return
    end

    for _, ui in ipairs(temp:GetDescendants()) do
        local lname = string.lower(ui.Name)
        local looksRelevant = lname:find("1x1x1x1", 1, true)
            or lname:find("popup", 1, true)
            or lname:find("scary", 1, true)
            or lname:find("jumpscare", 1, true)

        if ui:IsA("Frame") and looksRelevant then
            pcall(function()
                ui.Visible = false
            end)
        elseif ui:IsA("ImageLabel") and looksRelevant then
            pcall(function()
                ui.Visible = false
            end)
        elseif ui:IsA("TextLabel") and looksRelevant then
            pcall(function()
                ui.Visible = false
            end)
        end
    end

    for _, ui in ipairs(temp:GetChildren()) do
        if ui:IsA("Frame") then
            local hasRelevantDescendant = false
            for _, d in ipairs(ui:GetDescendants()) do
                local lname = string.lower(d.Name)
                if lname:find("1x1x1x1", 1, true)
                    or lname:find("popup", 1, true)
                    or lname:find("scary", 1, true)
                    or lname:find("jumpscare", 1, true) then
                    hasRelevantDescendant = true
                    break
                end
            end

            if hasRelevantDescendant then
                pcall(function()
                    ui.Visible = false
                end)
            end
        end
    end
end

local function toggleEmoteMenuHolder()
    local temp = PlayerGui:FindFirstChild("TemporaryUI")
    if not temp then
        return false
    end

    local holder = temp:FindFirstChild("EmoteMenuHolder", true)
    if not holder or not holder:IsA("GuiObject") then
        return false
    end

    local OPEN_POS = UDim2.fromOffset(690, 212)
    local OPEN_SIZE = UDim2.fromOffset(540, 540)

    local cache = sharedState._emoteLayoutCache
    cache.objects = cache.objects or {}
    cache.openedByScript = cache.openedByScript or false

    local function cacheObject(obj)
        if not obj or cache.objects[obj] then
            return
        end
        local info = {}
        if obj:IsA("GuiObject") then
            info.Visible = obj.Visible
            info.Active = obj.Active
            info.Position = obj.Position
            info.Size = obj.Size
            info.ZIndex = obj.ZIndex
        elseif obj:IsA("LayerCollector") then
            info.Enabled = obj.Enabled
        end
        cache.objects[obj] = info
    end

    local function restoreAllCached()
        for obj, info in pairs(cache.objects) do
            if obj and obj.Parent then
                pcall(function()
                    if obj:IsA("GuiObject") then
                        if info.Position ~= nil then obj.Position = info.Position end
                        if info.Size ~= nil then obj.Size = info.Size end
                        if info.Visible ~= nil then obj.Visible = info.Visible end
                        if info.Active ~= nil then obj.Active = info.Active end
                        if info.ZIndex ~= nil then obj.ZIndex = info.ZIndex end
                    elseif obj:IsA("LayerCollector") then
                        if info.Enabled ~= nil then obj.Enabled = info.Enabled end
                    end
                end)
            end
        end
        cache.objects = {}
        cache.openedByScript = false
    end

    local function collectAncestors(obj)
        local cur = obj
        while cur and cur ~= PlayerGui do
            if cur:IsA("GuiObject") or cur:IsA("LayerCollector") then
                cacheObject(cur)
            end
            cur = cur.Parent
        end
    end

    local radialMenus = {}
    for _, d in ipairs(holder:GetDescendants()) do
        if d:IsA("GuiObject") and string.lower(d.Name) == "radialmenu" then
            table.insert(radialMenus, d)
        end
    end

    local isOpen = holder.AbsoluteSize.X > 50 and holder.AbsoluteSize.Y > 50
    local newState = not isOpen

    if cache.openedByScript and not newState then
        restoreAllCached()
        return true
    end

    if not newState then
        return false
    end

    cacheObject(holder)
    collectAncestors(holder)

    local function prepareAttachSlots(rootGui)
        local attach = rootGui:FindFirstChild("Attach", true)
        if not attach or not attach:IsA("GuiObject") then
            return
        end

        cacheObject(attach)

        pcall(function()
            attach.Visible = true
            attach.Active = true
        end)

        for i = 1, 8 do
            local slot = attach:FindFirstChild(tostring(i))
            if slot and slot:IsA("GuiObject") then
                cacheObject(slot)
                pcall(function()
                    slot.Visible = true
                    slot.Active = true
                    slot.ZIndex = math.max(slot.ZIndex, 20)
                end)

                for _, d in ipairs(slot:GetDescendants()) do
                    if d:IsA("GuiObject") or d:IsA("LayerCollector") then
                        cacheObject(d)
                    end

                    if d:IsA("GuiObject") then
                        pcall(function()
                            d.Visible = true
                            d.Active = true
                            d.ZIndex = math.max(d.ZIndex, 20)
                        end)
                    end

                    if d:IsA("GuiButton") then
                        pcall(function()
                            d.Active = true
                            d.Selectable = true
                            d.AutoButtonColor = true
                        end)
                    end

                    if d:IsA("UIScale") then
                        pcall(function()
                            if d.Scale == 0 then
                                d.Scale = 1
                            end
                        end)
                    end
                end
            end
        end
    end

    local function prepareInteractiveTree(rootGui)
        collectAncestors(rootGui)
        cacheObject(rootGui)

        for _, d in ipairs(rootGui:GetDescendants()) do
            if d:IsA("GuiObject") or d:IsA("LayerCollector") then
                cacheObject(d)
            end

            if d:IsA("GuiObject") then
                pcall(function()
                    d.Visible = true
                    d.Active = true
                end)
            end

            if d:IsA("GuiButton") then
                pcall(function()
                    d.Active = true
                    d.Selectable = true
                    d.AutoButtonColor = true
                end)
            end

            if d:IsA("UIScale") then
                pcall(function()
                    if d.Scale == 0 then
                        d.Scale = 1
                    end
                end)
            end
        end

        prepareAttachSlots(rootGui)
    end

    local function openGui(guiObj)
        cacheObject(guiObj)
        pcall(function()
            guiObj.Visible = true
            guiObj.Active = true
            guiObj.Position = OPEN_POS
            guiObj.Size = OPEN_SIZE
            guiObj.ZIndex = math.max(guiObj.ZIndex, 10)
        end)
        prepareInteractiveTree(guiObj)
    end

    openGui(holder)
    for _, menu in ipairs(radialMenus) do
        openGui(menu)
    end
    cache.openedByScript = true

    return true
end

local function safeFind(root, path)
    local cur = root
    for _, name in ipairs(path) do
        if not cur then return nil end
        cur = cur:FindFirstChild(name)
    end
    return cur
end

local function getKillersFolder()
    return safeFind(workspace, {"Players", "Killers"})
end

local function isLikelyNoli(model)
    if not model or not model:IsA("Model") then
        return false
    end

    local actorName = model:GetAttribute("ActorDisplayName")
    local skinName = model:GetAttribute("SkinName")
    local skinDisplay = model:GetAttribute("SkinNameDisplay")
    local lname = string.lower(model.Name)

    return actorName == "Noli"
        or skinName == "ArtfulNoli"
        or skinDisplay == "Artful"
        or lname:find("noli", 1, true) ~= nil
end

local function hasUndetectableAttribute(model)
    return model and model:GetAttribute("Undetectable") ~= nil
end

local function purgeFakeNoli()
    local killers = getKillersFolder()
    if not killers then
        return
    end

    local nolis = {}
    for _, model in ipairs(killers:GetChildren()) do
        if isLikelyNoli(model) then
            table.insert(nolis, model)
        end
    end

    if #nolis < 2 then
        return
    end

    local withUndetectable = {}
    local withoutUndetectable = {}

    for _, model in ipairs(nolis) do
        if hasUndetectableAttribute(model) then
            table.insert(withUndetectable, model)
        else
            table.insert(withoutUndetectable, model)
        end
    end

    if #withUndetectable >= 1 and #withoutUndetectable >= 1 then
        for _, fake in ipairs(withoutUndetectable) do
            pcall(function()
                fake:Destroy()
            end)
        end
    end
end

local function getSurvivorsFolder()
    return safeFind(workspace, {"Players", "Survivors"})
end

local function getAbilityButton(name)
    local main = PlayerGui:FindFirstChild("MainUI")
    local container = main and main:FindFirstChild("AbilityContainer")
    local btn = container and container:FindFirstChild(name)
    if btn and btn.Visible then
        return btn
    end
    return nil
end

local function fireButton(btn)
    if not btn then return false end
    local ok = false
    pcall(function()
        for _, c in ipairs(getconnections(btn.MouseButton1Click)) do
            pcall(function() c:Fire() end)
            ok = true
        end
    end)
    pcall(function()
        if btn.Activate then
            btn:Activate()
            ok = true
        end
    end)
    return ok
end

local autoGenHooked = false
local FlowGameModule = nil
local oldFlowGameNew = nil
local currentFlowPuzzle = nil
local autoGenRunning = false
local lastAutoGenStart = 0
local lastAutoGenFinish = 0
local lastAutoGenKeyPress = 0

local AUTO_GEN_MIN_STEP = 0.05
local AUTO_GEN_MAX_STEP = 0.35
local AUTO_GEN_START_COOLDOWN = 1.25
local AUTO_GEN_FINISH_COOLDOWN = 2.0
local AUTO_GEN_KEY_DEBOUNCE = 0.35

local function clampAutoGenSpeed(v)
    v = tonumber(v) or 0.08
    if v < AUTO_GEN_MIN_STEP then
        v = AUTO_GEN_MIN_STEP
    end
    if v > AUTO_GEN_MAX_STEP then
        v = AUTO_GEN_MAX_STEP
    end
    return v
end

local function getSafeStepDelay()
    local base = clampAutoGenSpeed(Config.Other.AutoGenSpeed)
    local jitter = math.random(5, 20) / 1000
    return base + jitter
end

local function canStartAutoGen()
    local now = tick()

    if autoGenRunning then
        return false, "Auto gen already running"
    end

    if now - lastAutoGenStart < AUTO_GEN_START_COOLDOWN then
        return false, "Wait before starting again"
    end

    if now - lastAutoGenFinish < AUTO_GEN_FINISH_COOLDOWN then
        return false, "Puzzle just finished, wait a bit"
    end

    return true, nil
end

local function isNeighbour(r1, c1, r2, c2)
    return (r2 == r1 - 1 and c2 == c1)
        or (r2 == r1 + 1 and c2 == c1)
        or (r2 == r1 and c2 == c1 - 1)
        or (r2 == r1 and c2 == c1 + 1)
end

local function nodeKey(n)
    return tostring(n.row) .. "-" .. tostring(n.col)
end

local function orderPath(path, endpoints)
    if not path or #path == 0 then
        return path
    end

    local start = (endpoints and endpoints[1]) or path[1]
    local pool = {}

    for _, n in ipairs(path) do
        pool[nodeKey(n)] = {row = n.row, col = n.col}
    end

    local ordered = {}
    local cur = {row = start.row, col = start.col}
    table.insert(ordered, cur)
    pool[nodeKey(cur)] = nil

    while next(pool) do
        local found = false
        for k, n in pairs(pool) do
            if isNeighbour(cur.row, cur.col, n.row, n.col) then
                table.insert(ordered, n)
                pool[k] = nil
                cur = n
                found = true
                break
            end
        end
        if not found then
            break
        end
    end

    return ordered
end

local function solveFlowPuzzle(puzzle)
    local ok, reason = canStartAutoGen()
    if not ok then
        notify(reason)
        return
    end

    if not puzzle or not puzzle.Solution or not puzzle.targetPairs or not puzzle.paths then
        notify("No valid generator puzzle found")
        return
    end

    autoGenRunning = true
    lastAutoGenStart = tick()

    task.spawn(function()
        local success = false

        for i = 1, #puzzle.Solution do
            if not autoGenRunning then
                break
            end

            local path = puzzle.Solution[i]
            local ends = puzzle.targetPairs[i]
            local ordered = orderPath(path, ends)

            puzzle.paths[i] = {}

            for _, node in ipairs(ordered) do
                if not autoGenRunning then
                    break
                end

                table.insert(puzzle.paths[i], {
                    row = node.row,
                    col = node.col
                })

                pcall(function()
                    puzzle:updateGui()
                end)

                task.wait(getSafeStepDelay())
            end

            pcall(function()
                puzzle:checkForWin()
            end)

            task.wait(getSafeStepDelay())
        end

        if autoGenRunning then
            success = true
        end

        autoGenRunning = false
        lastAutoGenFinish = tick()

        if success then
            notify("Auto gen finished")
        else
            notify("Auto gen stopped")
        end
    end)
end

local function stopFlowPuzzle()
    autoGenRunning = false
    lastAutoGenFinish = tick()
end

local function hookAutoGen()
    if autoGenHooked then
        return
    end

    local target = safeFind(ReplicatedStorage, {"Modules", "Misc", "FlowGameManager", "FlowGame"})
    if not target then
        notify("FlowGame not found")
        return
    end

    local container = nil
    local constructor = nil

    if target:IsA("ModuleScript") then
        local ok, required = pcall(require, target)
        if ok and type(required) == "table" and type(required.new) == "function" then
            container = required
            constructor = required.new
        end
    elseif getsenv then
        local ok, envtbl = pcall(getsenv, target)
        if ok and type(envtbl) == "table" then
            if type(envtbl.new) == "function" then
                container = envtbl
                constructor = envtbl.new
            elseif type(envtbl.FlowGame) == "table" and type(envtbl.FlowGame.new) == "function" then
                container = envtbl.FlowGame
                constructor = envtbl.FlowGame.new
            elseif type(envtbl.FlowGameNew) == "function" then
                container = envtbl
                constructor = envtbl.FlowGameNew
            end
        end
    end

    if not container or type(constructor) ~= "function" then
        notify("Auto gen unavailable: FlowGame is not hookable here")
        return
    end

    FlowGameModule = container
    oldFlowGameNew = oldFlowGameNew or constructor

    if container.new then
        container.new = function(...)
            local puzzle = oldFlowGameNew(...)
            currentFlowPuzzle = puzzle
            return puzzle
        end
    else
        notify("Auto gen partial hook only")
        return
    end

    autoGenHooked = true
end

local cachedSprintController = nil
local lastSprintResolve = 0
local sprintWarned = false

local sprintFieldAliases = {
    Stamina = {"Stamina", "CurrentStamina", "SprintStamina", "Energy"},
    MaxStamina = {"MaxStamina", "StaminaMax", "MaxEnergy"},
    StaminaGain = {"StaminaGain", "RegenRate", "RecoveryRate"},
    StaminaLoss = {"StaminaLoss", "DrainRate", "ConsumeRate"},
    SprintSpeed = {"SprintSpeed", "RunSpeed", "SprintWalkSpeed"},
}

local sprintOriginals = {
    captured = false,
    Stamina = nil,
    MaxStamina = nil,
    StaminaGain = nil,
    StaminaLoss = nil,
    SprintSpeed = nil,
}

local function findFieldOwner(tbl, aliases)
    if type(tbl) ~= "table" then
        return nil, nil
    end

    for _, key in ipairs(aliases) do
        if rawget(tbl, key) ~= nil and type(tbl[key]) ~= "function" then
            return tbl, key
        end
    end

    for _, value in pairs(tbl) do
        if type(value) == "table" then
            for _, key in ipairs(aliases) do
                if rawget(value, key) ~= nil and type(value[key]) ~= "function" then
                    return value, key
                end
            end
        end
    end

    return nil, nil
end

local function getSprintController()
    if cachedSprintController then
        return cachedSprintController
    end
    if tick() - lastSprintResolve < 3 then
        return nil
    end
    lastSprintResolve = tick()

    local target = safeFind(ReplicatedStorage, {"Systems", "Character", "Game", "Sprinting"})
    if not target then
        if not sprintWarned then
            sprintWarned = true
            notify("Sprinting path not found. Using stamina fallback.")
        end
        return nil
    end

    if target:IsA("ModuleScript") then
        local ok, mod = pcall(require, target)
        if ok and type(mod) == "table" then
            cachedSprintController = mod
            return mod
        end
    end

    if (target:IsA("LocalScript") or target:IsA("Script")) and getsenv then
        local ok, envtbl = pcall(getsenv, target)
        if ok and type(envtbl) == "table" then
            cachedSprintController = envtbl
            return envtbl
        end
    end

    if not sprintWarned then
        sprintWarned = true
        notify("Couldn't hook Sprinting directly. Using stamina fallback.")
    end
    return nil
end

local function getSprintField(controller, fieldName)
    if type(controller) ~= "table" then
        return nil
    end
    local owner, key = findFieldOwner(controller, sprintFieldAliases[fieldName] or {fieldName})
    if owner and key then
        return owner[key]
    end
    return nil
end

local function setSprintField(controller, fieldName, value)
    if type(controller) ~= "table" then
        return false
    end
    local owner, key = findFieldOwner(controller, sprintFieldAliases[fieldName] or {fieldName})
    if owner and key then
        owner[key] = value
        return true
    end
    return false
end

local function captureSprintOriginals(controller)
    if not controller or sprintOriginals.captured then return end
    sprintOriginals.captured = true
    sprintOriginals.Stamina = getSprintField(controller, "Stamina")
    sprintOriginals.MaxStamina = getSprintField(controller, "MaxStamina")
    sprintOriginals.StaminaGain = getSprintField(controller, "StaminaGain")
    sprintOriginals.StaminaLoss = getSprintField(controller, "StaminaLoss")
    sprintOriginals.SprintSpeed = getSprintField(controller, "SprintSpeed")
end

local function applyStaminaValueFallbacks()
    local targets = {}

    local char = currentCharacter()
    if char then
        table.insert(targets, char)
    end
    table.insert(targets, PlayerGui)
    table.insert(targets, lp)

    for _, root in ipairs(targets) do
        if root then
            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("NumberValue") or obj:IsA("IntValue") then
                    local n = string.lower(obj.Name)
                    if Config.Stamina.Infinite and (n == "stamina" or n == "currentstamina" or n == "sprintstamina" or n == "energy") then
                        local maxGuess = Config.Stamina.UseCustomMax and Config.Stamina.Max or math.max(obj.Value, 100)
                        obj.Value = maxGuess
                    elseif Config.Stamina.UseCustomMax and (n == "maxstamina" or n == "staminamax" or n == "maxenergy") then
                        obj.Value = Config.Stamina.Max
                    elseif Config.Stamina.UseCustomGain and (n == "staminagain" or n == "regenrate" or n == "recoveryrate") then
                        obj.Value = Config.Stamina.Gain
                    elseif Config.Stamina.UseCustomLoss and (n == "staminaloss" or n == "drainrate" or n == "consumerate") then
                        obj.Value = Config.Stamina.Loss
                    elseif Config.Stamina.UseCustomSpeed and (n == "sprintspeed" or n == "runspeed" or n == "sprintwalkspeed") then
                        obj.Value = Config.Stamina.Speed
                    end
                end
            end
        end
    end
end

local function syncSprintSettings()
    local controller = getSprintController()
    if controller then
        captureSprintOriginals(controller)

        local currentMax = getSprintField(controller, "MaxStamina") or sprintOriginals.MaxStamina or Config.Stamina.Max

        if Config.Stamina.Infinite then
            setSprintField(controller, "Stamina", currentMax)
        elseif sprintOriginals.Stamina ~= nil then
            setSprintField(controller, "Stamina", sprintOriginals.Stamina)
        end

        if sprintOriginals.MaxStamina ~= nil then
            setSprintField(controller, "MaxStamina", Config.Stamina.UseCustomMax and Config.Stamina.Max or sprintOriginals.MaxStamina)
        end
        if sprintOriginals.StaminaGain ~= nil then
            setSprintField(controller, "StaminaGain", Config.Stamina.UseCustomGain and Config.Stamina.Gain or sprintOriginals.StaminaGain)
        end
        if sprintOriginals.StaminaLoss ~= nil then
            setSprintField(controller, "StaminaLoss", Config.Stamina.UseCustomLoss and Config.Stamina.Loss or sprintOriginals.StaminaLoss)
        end
        if sprintOriginals.SprintSpeed ~= nil then
            setSprintField(controller, "SprintSpeed", Config.Stamina.UseCustomSpeed and Config.Stamina.Speed or sprintOriginals.SprintSpeed)
        end
    end

    applyStaminaValueFallbacks()
end

local function isAnyStaminaFeatureActive()
    return Config.Stamina.Infinite
        or Config.Stamina.UseCustomMax
        or Config.Stamina.UseCustomGain
        or Config.Stamina.UseCustomLoss
        or Config.Stamina.UseCustomSpeed
end

local function extractNumericSoundId(sound)
    local sid = tostring(sound.SoundId or "")
    return sid:match("rbxassetid://(%d+)") or sid:match("://(%d+)") or sid:match("^(%d+)$")
end

local function isFacing(myRoot, targetRoot)
    if not Config.AutoBlock.Facing then
        return true
    end
    local dir = (myRoot.Position - targetRoot.Position).Unit
    local dot = targetRoot.CFrame.LookVector:Dot(dir)
    return dot > Config.AutoBlock.FacingDot
end

-- lightweight UI
local gui = Instance.new("ScreenGui")
gui.Name = "c00lSakenCleanUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local guiParent = (gethui and gethui()) or PlayerGui
gui.Parent = guiParent
sharedState._gui = gui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(760, 500)
main.Position = UDim2.new(0.5, -380, 0.5, -250)
main.BackgroundColor3 = Color3.fromRGB(13, 15, 21)
main.BorderSizePixel = 0
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(46, 52, 72)
mainStroke.Thickness = 1
mainStroke.Transparency = 0.2
mainStroke.Parent = main

local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 56)
top.BackgroundColor3 = Color3.fromRGB(18, 21, 30)
top.BorderSizePixel = 0
top.Parent = main

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 16)
topCorner.Parent = top

local fixTop = Instance.new("Frame")
fixTop.Size = UDim2.new(1, 0, 0, 14)
fixTop.Position = UDim2.new(0, 0, 1, -14)
fixTop.BackgroundColor3 = top.BackgroundColor3
fixTop.BorderSizePixel = 0
fixTop.Parent = top

local accent = Instance.new("Frame")
accent.Size = UDim2.new(1, 0, 0, 3)
accent.Position = UDim2.fromOffset(0, 53)
accent.BackgroundColor3 = Color3.fromRGB(165, 110, 255)
accent.BorderSizePixel = 0
accent.Parent = top
local accentCorner = Instance.new("UICorner")
accentCorner.CornerRadius = UDim.new(1, 0)
accentCorner.Parent = accent

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -200, 0, 22)
title.Position = UDim2.fromOffset(16, 9)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "c00lSaken Clean"
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(244, 246, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = top

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -200, 0, 16)
subtitle.Position = UDim2.fromOffset(16, 31)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.Gotham
subtitle.Text = "Clean panel style + transparent labels"
subtitle.TextSize = 11
subtitle.TextColor3 = Color3.fromRGB(144, 152, 176)
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = top

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(0, 120, 0, 16)
hint.Position = UDim2.new(1, -170, 0, 20)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.Gotham
hint.Text = "H = emote menu"
hint.TextSize = 11
hint.TextColor3 = Color3.fromRGB(144, 152, 176)
hint.TextXAlignment = Enum.TextXAlignment.Right
hint.Parent = top

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(32, 28)
close.Position = UDim2.new(1, -42, 0.5, -14)
close.BackgroundColor3 = Color3.fromRGB(34, 39, 54)
close.Text = "–"
close.Font = Enum.Font.GothamBold
close.TextSize = 14
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.Parent = top
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = close

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(0, 180, 1, -72)
tabBar.Position = UDim2.fromOffset(12, 62)
tabBar.BackgroundColor3 = Color3.fromRGB(16, 19, 27)
tabBar.BorderSizePixel = 0
tabBar.Parent = main
local tabBarCorner = Instance.new("UICorner")
tabBarCorner.CornerRadius = UDim.new(0, 14)
tabBarCorner.Parent = tabBar
local tabBarStroke = Instance.new("UIStroke")
tabBarStroke.Color = Color3.fromRGB(38, 43, 60)
tabBarStroke.Thickness = 1
tabBarStroke.Transparency = 0.2
tabBarStroke.Parent = tabBar

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -208, 1, -72)
content.Position = UDim2.fromOffset(196, 62)
content.BackgroundColor3 = Color3.fromRGB(16, 19, 27)
content.Parent = main
local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 14)
contentCorner.Parent = content
local contentStroke = Instance.new("UIStroke")
contentStroke.Color = Color3.fromRGB(38, 43, 60)
contentStroke.Thickness = 1
contentStroke.Transparency = 0.2
contentStroke.Parent = content

local tabLayout = Instance.new("UIListLayout")
tabLayout.Padding = UDim.new(0, 8)
tabLayout.FillDirection = Enum.FillDirection.Vertical
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabBar

local tabPad = Instance.new("UIPadding")
tabPad.PaddingTop = UDim.new(0, 12)
tabPad.PaddingLeft = UDim.new(0, 10)
tabPad.PaddingRight = UDim.new(0, 10)
tabPad.PaddingBottom = UDim.new(0, 12)
tabPad.Parent = tabBar

local dragging = false
local dragStart, startPos
bind(top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end))
bind(top.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end))
bind(UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end))

bind(close.MouseButton1Click:Connect(function()
    gui.Enabled = not gui.Enabled
end))

bind(UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        gui.Enabled = not gui.Enabled
    end
end))

bind(UserInputService.InputBegan:Connect(function(input, processed)
    if UserInputService:GetFocusedTextBox() then
        return
    end

    if input.KeyCode == Enum.KeyCode.H then
        if Config.Other.EmoteMenuHotkey then
            toggleEmoteMenuHolder()
        end
        return
    end

    if input.KeyCode == Enum.KeyCode.X then
        if processed then
            return
        end

        if not Config.Other.AutoGenHotkey then
            return
        end

        local now = tick()
        if now - lastAutoGenKeyPress < AUTO_GEN_KEY_DEBOUNCE then
            return
        end
        lastAutoGenKeyPress = now

        if autoGenRunning then
            stopFlowPuzzle()
        else
            solveFlowPuzzle(currentFlowPuzzle)
        end
    end
end))

local tabs = {}
local currentTab = nil

local function createPage(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 52)
    btn.BackgroundColor3 = Color3.fromRGB(27, 31, 43)
    btn.Text = name
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(240, 244, 255)
    btn.Parent = tabBar
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 12)
    btnCorner.Parent = btn
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(45, 50, 69)
    btnStroke.Thickness = 1
    btnStroke.Transparency = 0.3
    btnStroke.Parent = btn

    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Size = UDim2.new(1, 0, 1, 0)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ScrollBarThickness = 4
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = content

    local pagePad = Instance.new("UIPadding")
    pagePad.PaddingLeft = UDim.new(0, 12)
    pagePad.PaddingRight = UDim.new(0, 12)
    pagePad.PaddingTop = UDim.new(0, 12)
    pagePad.PaddingBottom = UDim.new(0, 12)
    pagePad.Parent = page

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent = page

    local function select()
        if currentTab then
            currentTab.page.Visible = false
            currentTab.button.BackgroundColor3 = Color3.fromRGB(27, 31, 43)
        end
        currentTab = tabs[name]
        currentTab.page.Visible = true
        currentTab.button.BackgroundColor3 = Color3.fromRGB(48, 61, 102)
    end

    bind(btn.MouseButton1Click:Connect(select))

    tabs[name] = {button = btn, page = page}
    if not currentTab then
        select()
    end
    return page
end

local function createSection(parent, titleText)
    local section = Instance.new("Frame")
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.Size = UDim2.new(1, 0, 0, 0)
    section.BackgroundColor3 = Color3.fromRGB(20, 23, 32)
    section.BorderSizePixel = 0
    section.Parent = parent
    local secCorner = Instance.new("UICorner")
    secCorner.CornerRadius = UDim.new(0, 12)
    secCorner.Parent = section
    local secStroke = Instance.new("UIStroke")
    secStroke.Color = Color3.fromRGB(43, 48, 66)
    secStroke.Thickness = 1
    secStroke.Transparency = 0.2
    secStroke.Parent = section

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -20, 0, 26)
    titleLbl.Position = UDim2.fromOffset(10, 8)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.Text = titleText
    titleLbl.TextSize = 16
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.TextColor3 = Color3.fromRGB(245, 247, 255)
    titleLbl.Parent = section

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 38)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.Parent = section

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = section

    return section
end

local function createToggle(parent, text, initial, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.Text = text
    lbl.TextSize = 14
    lbl.TextColor3 = Color3.fromRGB(228, 228, 235)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(58, 24)
    btn.Position = UDim2.new(1, -58, 0.5, -12)
    btn.BackgroundColor3 = initial and Color3.fromRGB(76, 140, 90) or Color3.fromRGB(60, 60, 70)
    btn.Text = initial and "ON" or "OFF"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Parent = row

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn

    local state = initial

    local function apply(v, fireCallback)
        state = v
        btn.BackgroundColor3 = state and Color3.fromRGB(76, 140, 90) or Color3.fromRGB(60, 60, 70)
        btn.Text = state and "ON" or "OFF"
        if fireCallback then
            callback(state)
        end
    end

    bind(btn.MouseButton1Click:Connect(function()
        apply(not state, true)
    end))

    apply(initial, false)

    return {
        Set = function(v)
            apply(v, true)
        end
    }
end

local function createBox(parent, text, initial, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.45, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.Text = text
    lbl.TextSize = 14
    lbl.TextColor3 = Color3.fromRGB(228, 228, 235)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.5, 0, 1, 0)
    box.Position = UDim2.new(0.5, 0, 0, 0)
    box.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    box.TextColor3 = Color3.fromRGB(250, 250, 250)
    box.Font = Enum.Font.Gotham
    box.TextSize = 14
    box.ClearTextOnFocus = false
    box.Text = tostring(initial)
    box.PlaceholderText = tostring(initial)
    box.Parent = row
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = box

    local function apply()
        callback(box.Text)
    end
    bind(box.FocusLost:Connect(apply))
    callback(tostring(initial))
    return box
end

local rolePage = createPage("Role")
local staminaPage = createPage("Stamina")
local autoBlockPage = createPage("Autoblock")
local visualsPage = createPage("Visuals")
local antiPage = createPage("Anti")
local otherPage = createPage("Other")

do
    local sec = createSection(rolePage, "Role")
    createToggle(sec, "Voidrush Controllable", false, function(v)
        Config.Role.VoidrushControl = v
        updateVoidrush()
    end)
    createToggle(sec, "Auto Trick", false, function(v)
        Config.Role.AutoTrick = v
        updateAutoTrick()
    end)
end

do
    local sec = createSection(staminaPage, "Stamina")
    createToggle(sec, "Infinite Stamina", false, function(v)
        Config.Stamina.Infinite = v
    end)
    createToggle(sec, "Custom Max", false, function(v)
        Config.Stamina.UseCustomMax = v
    end)
    createBox(sec, "Max Stamina", 100, function(t)
        Config.Stamina.Max = tonumber(t) or 100
    end)
    createToggle(sec, "Custom Gain", false, function(v)
        Config.Stamina.UseCustomGain = v
    end)
    createBox(sec, "Stamina Gain", 20, function(t)
        Config.Stamina.Gain = tonumber(t) or 20
    end)
    createToggle(sec, "Custom Loss", false, function(v)
        Config.Stamina.UseCustomLoss = v
    end)
    createBox(sec, "Stamina Loss", 5, function(t)
        Config.Stamina.Loss = tonumber(t) or 5
    end)
    createToggle(sec, "Custom Sprint Speed", false, function(v)
        Config.Stamina.UseCustomSpeed = v
    end)
    createBox(sec, "Sprint Speed", 28, function(t)
        Config.Stamina.Speed = tonumber(t) or 28
    end)
end

do
    local sec = createSection(autoBlockPage, "Block")
    createToggle(sec, "Auto Block (Animation)", false, function(v)
        Config.AutoBlock.Anim = v
    end)
    createToggle(sec, "Auto Block (Audio)", false, function(v)
        Config.AutoBlock.Audio = v
    end)
    createBox(sec, "Detection Range", 12, function(t)
        Config.AutoBlock.Range = tonumber(t) or 12
    end)
    createToggle(sec, "Enable Facing Check", true, function(v)
        Config.AutoBlock.Facing = v
    end)
    createBox(sec, "Facing Dot", -0.3, function(t)
        Config.AutoBlock.FacingDot = tonumber(t) or -0.3
    end)
    createBox(sec, "Block Delay", 0, function(t)
        Config.AutoBlock.Delay = tonumber(t) or 0
    end)
    createToggle(sec, "Autopunch", false, function(v)
        Config.AutoBlock.AutoPunch = v
    end)
    createToggle(sec, "Aimpunch", false, function(v)
        Config.AutoBlock.AimPunch = v
    end)
    createBox(sec, "Prediction", 4, function(t)
        Config.AutoBlock.Prediction = tonumber(t) or 4
    end)
end

do
    local sec = createSection(visualsPage, "ESP")
    createToggle(sec, "Enable Visuals", false, function(v)
        Config.Visuals.Enabled = v
    end)
    createToggle(sec, "Killer", true, function(v)
        Config.Visuals.Killer = v
    end)
    createToggle(sec, "Survivor", true, function(v)
        Config.Visuals.Survivor = v
    end)
    createToggle(sec, "Items", false, function(v)
        Config.Visuals.Items = v
    end)
    createToggle(sec, "Generator", false, function(v)
        Config.Visuals.Generator = v
    end)
    createToggle(sec, "Name Labels", true, function(v)
        Config.Visuals.Labels = v
    end)
    createBox(sec, "Label Size", 32, function(t)
        local n = tonumber(t) or 32
        if n < 16 then n = 16 end
        if n > 48 then n = 48 end
        Config.Visuals.LabelSize = n
    end)
    createBox(sec, "ESP Refresh", 0.7, function(t)
        local n = tonumber(t) or 0.7
        if n < 0.15 then n = 0.15 end
        if n > 5 then n = 5 end
        Config.Visuals.Refresh = n
    end)
end

do
    local sec = createSection(antiPage, "Anti")
    createToggle(sec, "Anti Blindness", false, function(v)
        Config.Anti.Blindness = v
    end)
    createToggle(sec, "Anti Subspace", false, function(v)
        Config.Anti.Subspace = v
    end)
    createToggle(sec, "Anti Stun", false, function(v)
        Config.Anti.Stun = v
    end)
    createToggle(sec, "Anti Slow", false, function(v)
        Config.Anti.Slow = v
    end)
    createToggle(sec, "Anti Hidden Stats", false, function(v)
        Config.Anti.HiddenStats = v
    end)
    createToggle(sec, "Anti 1x Popups", false, function(v)
        Config.Anti.Popup1x = v
    end)
    createToggle(sec, "Anti Fake Noli", false, function(v)
        Config.Anti.FakeNoli = v
    end)
end

do
    local sec = createSection(otherPage, "Other")
    createToggle(sec, "Jump", false, function(v)
        Config.Other.Jump = v
    end)
    createToggle(sec, "Always Show Chat", false, function(v)
        Config.Other.AlwaysShowChat = v
    end)
    createToggle(sec, "Enable Emote Menu (G)", true, function(v)
        Config.Other.EmoteMenuHotkey = v
    end)
    createToggle(sec, "Force Emote Menu Layout", true, function(v)
        Config.Other.EmoteMenuUseForcedLayout = v
    end)
end

notify("Clean UI loaded")

-- Visuals
local espCache = sharedState._esp

local function clearAdornment(entry)
    if entry and entry.Parent then
        pcall(function() entry:Destroy() end)
    end
end

local function removeESP(key)
    local obj = espCache[key]
    if not obj then return end
    clearAdornment(obj.highlight)
    clearAdornment(obj.billboard)
    espCache[key] = nil
end

local function getESPAnchorPart(model)
    return getRoot(model) or (model and model:FindFirstChildWhichIsA("BasePart", true))
end

local function isLocalOwnedModel(model)
    if not model then
        return false
    end

    local myChar = currentCharacter()
    if model == myChar then
        return true
    end

    local p = Players:GetPlayerFromCharacter(model)
    if p == lp then
        return true
    end

    local userIdAttr = model:GetAttribute("UserId")
    if tonumber(userIdAttr) == lp.UserId then
        return true
    end

    return false
end

local function getPlayerNameForModel(model)
    if not model then
        return nil
    end

    local p = Players:GetPlayerFromCharacter(model)
    if p then
        return p.Name
    end

    local userIdAttr = model:GetAttribute("UserId")
    if tonumber(userIdAttr) then
        local found = Players:GetPlayerByUserId(tonumber(userIdAttr))
        if found then
            return found.Name
        end
    end

    for _, attr in ipairs({"PlayerName", "Username", "UserName", "Player", "Owner", "OwnerName"}) do
        local v = model:GetAttribute(attr)
        if type(v) == "string" and v ~= "" then
            return v
        end
    end

    return nil
end

local function buildESPPlayerLabel(model, includeKillerTag)
    local characterName = tostring(model.Name or "Unknown")
    local playerName = getPlayerNameForModel(model)

    local base = characterName
    if playerName and playerName ~= "" and playerName ~= characterName then
        base = characterName .. " [" .. playerName .. "]"
    end

    if includeKillerTag then
        return "[KILLER] " .. base
    end

    return base
end

local function isGeneratorModel(model)
    local n = string.lower(model.Name)
    return n:find("generator") ~= nil or n == "gen"
end

local function isItemModel(model)
    local n = string.lower(model.Name)
    return n:find("medkit") ~= nil
        or n:find("bloxy") ~= nil
        or n:find("cola") ~= nil
        or n:find("item") ~= nil
end

local function hasMatchingAncestorModel(model, predicate)
    local parent = model and model.Parent
    while parent do
        if parent:IsA("Model") and predicate(parent) then
            return true
        end
        parent = parent.Parent
    end
    return false
end

local function isTopLevelGeneratorModel(model)
    return isGeneratorModel(model) and not hasMatchingAncestorModel(model, isGeneratorModel)
end

local function isTopLevelItemModel(model)
    return isItemModel(model) and not hasMatchingAncestorModel(model, isItemModel)
end

local function hasNearbyPosition(list, part, radius)
    if not part then
        return false
    end
    for _, pos in ipairs(list) do
        if (pos - part.Position).Magnitude <= radius then
            return true
        end
    end
    return false
end

local function ensureESP(key, model, labelText, fillColor, outlineColor)
    if not model or not model.Parent then
        removeESP(key)
        return
    end

    local root = getESPAnchorPart(model)
    if not root then
        removeESP(key)
        return
    end

    local entry = espCache[key]
    if not entry then
        entry = {}
        espCache[key] = entry
    end

    if not entry.highlight then
        local hl = Instance.new("Highlight")
        hl.Name = "DW_ESP"
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = model
        entry.highlight = hl
    elseif entry.highlight.Parent ~= model then
        entry.highlight.Parent = model
    end

    entry.highlight.Adornee = model
    entry.highlight.FillColor = fillColor
    entry.highlight.OutlineColor = outlineColor
    entry.highlight.FillTransparency = 0.6
    entry.highlight.OutlineTransparency = 0.1
    entry.highlight.Enabled = Config.Visuals.Enabled

    if Config.Visuals.Labels then
        if not entry.billboard then
            local bill = Instance.new("BillboardGui")
            bill.Name = "DW_ESP_Text"
            bill.Size = UDim2.new(0, 150, 0, 40)
            bill.AlwaysOnTop = true
            bill.Parent = model

            local lbl = Instance.new("TextLabel")
            lbl.Name = "TextLabel"
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.GothamBold
            lbl.TextStrokeTransparency = 0
            lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            lbl.TextScaled = false
            lbl.Parent = bill

            entry.billboard = bill
            entry.label = lbl
        elseif entry.billboard.Parent ~= model then
            entry.billboard.Parent = model
        end

        entry.billboard.Adornee = model
        entry.billboard.Enabled = Config.Visuals.Enabled
        entry.billboard.Size = UDim2.new(0, 150, 0, 40)
        entry.billboard.StudsOffset = Vector3.new(0, 5, 0)

        if entry.label then
            entry.label.Text = labelText
            entry.label.TextColor3 = fillColor
            entry.label.TextSize = 13
        end
    else
        clearAdornment(entry.billboard)
        entry.billboard = nil
        entry.label = nil
    end
end

updatePlayerESP = function()
    if not Config.Visuals.Enabled then
        for key, _ in pairs(espCache) do
            if key:sub(1, 7) == "killer_" or key:sub(1, 9) == "survivor_" then
                removeESP(key)
            end
        end
        return
    end

    local killers = getKillersFolder()
    if killers and Config.Visuals.Killer then
        for _, model in ipairs(killers:GetChildren()) do
            local hum = getHumanoid(model)
            if hum and hum.Health > 0 and not isLocalOwnedModel(model) then
                ensureESP(
                    "killer_" .. model:GetDebugId(),
                    model,
                    buildESPPlayerLabel(model, true),
                    Color3.fromRGB(210, 70, 70),
                    Color3.fromRGB(255, 170, 170)
                )
            end
        end
    end

    local surv = getSurvivorsFolder()
    if surv and Config.Visuals.Survivor then
        for _, model in ipairs(surv:GetChildren()) do
            if not isLocalOwnedModel(model) then
                local hum = getHumanoid(model)
                if hum and hum.Health > 0 then
                    ensureESP(
                        "survivor_" .. model:GetDebugId(),
                        model,
                        buildESPPlayerLabel(model, false),
                        Color3.fromRGB(70, 140, 220),
                        Color3.fromRGB(180, 220, 255)
                    )
                end
            end
        end
    end

    local live = {}

    local killersFolder = getKillersFolder()
    if killersFolder and Config.Visuals.Killer then
        for _, model in ipairs(killersFolder:GetChildren()) do
            if not isLocalOwnedModel(model) then
                live["killer_" .. model:GetDebugId()] = true
            end
        end
    end

    local survivorsFolder = getSurvivorsFolder()
    if survivorsFolder and Config.Visuals.Survivor then
        for _, model in ipairs(survivorsFolder:GetChildren()) do
            if not isLocalOwnedModel(model) then
                live["survivor_" .. model:GetDebugId()] = true
            end
        end
    end

    for key, _ in pairs(espCache) do
        if key:sub(1, 7) == "killer_" or key:sub(1, 9) == "survivor_" then
            if not live[key] then
                removeESP(key)
            end
        end
    end
end

updateWorldESP = function()
    if not Config.Visuals.Enabled then
        for key, _ in pairs(espCache) do
            if key:sub(1, 5) == "item_" or key:sub(1, 4) == "gen_" then
                removeESP(key)
            end
        end
        return
    end

    local found = {}
    local usedItemPositions = {}
    local usedGenPositions = {}
    local ITEM_DEDUPE_RADIUS = 4
    local GEN_DEDUPE_RADIUS = 10

    if Config.Visuals.Items or Config.Visuals.Generator then
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("Model") then
                if Config.Visuals.Items and isTopLevelItemModel(d) then
                    local anchorPart = getESPAnchorPart(d)

                    if anchorPart and not hasNearbyPosition(usedItemPositions, anchorPart, ITEM_DEDUPE_RADIUS) then
                        table.insert(usedItemPositions, anchorPart.Position)
                        local key = "item_" .. d:GetDebugId()
                        found[key] = true
                        ensureESP(
                            key,
                            d,
                            "[ITEM] " .. d.Name,
                            Color3.fromRGB(80, 220, 120),
                            Color3.fromRGB(180, 255, 200)
                        )
                    end
                elseif Config.Visuals.Generator and isTopLevelGeneratorModel(d) then
                    local anchorPart = getESPAnchorPart(d)

                    if anchorPart and not hasNearbyPosition(usedGenPositions, anchorPart, GEN_DEDUPE_RADIUS) then
                        table.insert(usedGenPositions, anchorPart.Position)
                        local key = "gen_" .. d:GetDebugId()
                        found[key] = true
                        ensureESP(
                            key,
                            d,
                            "[GEN] " .. d.Name,
                            Color3.fromRGB(220, 200, 80),
                            Color3.fromRGB(255, 235, 170)
                        )
                    end
                end
            end
        end
    end

    for key, _ in pairs(espCache) do
        if (key:sub(1, 5) == "item_" or key:sub(1, 4) == "gen_") and not found[key] then
            removeESP(key)
        end
    end
end

-- Role
local voidrushConn = nil
local originalVoidrushWalkSpeed = nil
updateVoidrush = function()
    if voidrushConn then
        voidrushConn:Disconnect()
        voidrushConn = nil
    end

    if not Config.Role.VoidrushControl then
        local char = currentCharacter()
        local hum = getHumanoid(char)
        if hum then
            hum.AutoRotate = true
            if originalVoidrushWalkSpeed then
                hum.WalkSpeed = originalVoidrushWalkSpeed
            end
        end
        return
    end

    voidrushConn = bind(RunService.RenderStepped:Connect(function()
        if inGracePeriod() then return end

        local char = currentCharacter()
        local hum = getHumanoid(char)
        local root = getRoot(char)
        if not hum or not root then return end

        if not originalVoidrushWalkSpeed then
            originalVoidrushWalkSpeed = hum.WalkSpeed
        end

        local state = char:GetAttribute("VoidRushState")
        if state == "Dashing" then
            hum.AutoRotate = false
            hum.WalkSpeed = 55

            local look = root.CFrame.LookVector
            local horizontal = Vector3.new(look.X, 0, look.Z)
            if horizontal.Magnitude > 0 then
                hum:Move(horizontal.Unit)
            end
        else
            hum.AutoRotate = true
            if originalVoidrushWalkSpeed then
                hum.WalkSpeed = originalVoidrushWalkSpeed
            end
        end
    end))
end

local autoTrickCleanup = nil
updateAutoTrick = function()
    if autoTrickCleanup then
        pcall(autoTrickCleanup)
        autoTrickCleanup = nil
    end

    if not Config.Role.AutoTrick then
        return
    end

    local behaviorFolder = safeFind(ReplicatedStorage, {"Assets", "Survivors", "Veeronica", "Behavior"})
    if not behaviorFolder then
        return
    end

    local active = {}
    local conns = {}

    local function getButton()
        local mainUI = PlayerGui:FindFirstChild("MainUI")
        return mainUI and mainUI:FindFirstChild("SprintingButton")
    end

    local function watchHighlight(h)
        if active[h] then return end
        active[h] = true

        local function check()
            if not Config.Role.AutoTrick or inGracePeriod() then return end

            local char = currentCharacter()
            local adornee = h.Adornee
            if char and adornee and (adornee == char or adornee:IsDescendantOf(char)) then
                local btn = getButton()
                if btn then
                    pcall(function()
                        for _, v in ipairs(getconnections(btn.MouseButton1Down)) do
                            pcall(function() v:Fire() end)
                        end
                    end)
                end
            end
        end

        table.insert(conns, h:GetPropertyChangedSignal("Adornee"):Connect(check))
        table.insert(conns, h.AncestryChanged:Connect(function(_, parent)
            if not parent then
                active[h] = nil
            else
                check()
            end
        end))

        check()
    end

    for _, d in ipairs(behaviorFolder:GetDescendants()) do
        if d:IsA("Highlight") then
            watchHighlight(d)
        end
    end

    table.insert(conns, behaviorFolder.DescendantAdded:Connect(function(d)
        if d:IsA("Highlight") then
            watchHighlight(d)
        end
    end))

    autoTrickCleanup = function()
        for _, c in ipairs(conns) do
            pcall(function() c:Disconnect() end)
        end
    end
end

-- Stamina / Anti / Other loops
bind(RunService.Heartbeat:Connect(function()
    if inGracePeriod() then
        return
    end

    if isAnyStaminaFeatureActive() then
        syncSprintSettings()
    end

    local char = currentCharacter()
    if char then
        if Config.Anti.Stun then
            local sm = char:FindFirstChild("SpeedMultipliers")
            local stunned = sm and sm:FindFirstChild("Stunned")
            if stunned then
                stunned.Value = 1.2
            end
        end
        if Config.Anti.Slow then
            local sm = char:FindFirstChild("SpeedMultipliers")
            if sm then
                for _, v in ipairs(sm:GetChildren()) do
                    if v:IsA("NumberValue") and v.Value < 1 then
                        v.Value = 1.2
                    end
                end
            end
        end
        if Config.Other.Jump then
            local hum = getHumanoid(char)
            if hum then
                hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                hum.JumpPower = math.max(hum.JumpPower, 50)
            end
        end
    end

    if Config.Anti.Blindness then
        local blur = Lighting:FindFirstChild("BlindnessBlur")
        if blur then blur:Destroy() end
    end
    if Config.Anti.Subspace then
        local a = Lighting:FindFirstChild("SubspaceVFXBlur")
        local b = Lighting:FindFirstChild("SubspaceVFXColorCorrection")
        if a then a:Destroy() end
        if b then b:Destroy() end
    end

    if Config.Other.AlwaysShowChat then
        setChatVisibility(true)
    end

    if Config.Anti.Popup1x then
        hide1xPopupFrames()
    end

    if Config.Anti.HiddenStats then
        for _, p in ipairs(Players:GetPlayers()) do
            local privacy = p:FindFirstChild("PlayerData")
            privacy = privacy and privacy:FindFirstChild("Settings")
            privacy = privacy and privacy:FindFirstChild("Privacy")
            if privacy then
                for _, n in ipairs({"HideKillerWins","HidePlaytime","HideSurvivorWins"}) do
                    local item = privacy:FindFirstChild(n)
                    if item then
                        item.Value = false
                    end
                end
            end
        end
    end
end))

-- Auto block and punch
local lastLocalBlockTime = 0
local soundHooks = {}

local function tryBlockFromRoot(hrp)
    if not (Config.AutoBlock.Anim or Config.AutoBlock.Audio) then return end
    local myRoot = getRoot(currentCharacter())
    if not myRoot or not hrp then return end
    if (hrp.Position - myRoot.Position).Magnitude > Config.AutoBlock.Range then return end
    if Config.AutoBlock.Facing and not isFacing(myRoot, hrp) then return end
    if tick() - lastLocalBlockTime < 0.35 then return end
    local btn = getAbilityButton("Block")
    if not btn then return end
    task.delay(Config.AutoBlock.Delay, function()
        if fireButton(btn) then
            lastLocalBlockTime = tick()
        end
    end)
end

local function hookSound(sound)
    if soundHooks[sound] then return end
    soundHooks[sound] = true
    local function attempt()
        if not Config.AutoBlock.Audio or inGracePeriod() then return end
        local id = extractNumericSoundId(sound)
        if not id or not autoBlockTriggerSounds[id] then return end
        local parent = sound.Parent
        while parent and not parent:FindFirstChild("HumanoidRootPart") do
            parent = parent.Parent
        end
        local hrp = parent and parent:FindFirstChild("HumanoidRootPart")
        if hrp then
            tryBlockFromRoot(hrp)
        end
    end
    bind(sound.Played:Connect(attempt))
    bind(sound:GetPropertyChangedSignal("IsPlaying"):Connect(function()
        if sound.IsPlaying then
            attempt()
        end
    end))
end

bind(RunService.RenderStepped:Connect(function()
    if inGracePeriod() then
        return
    end

    if Config.AutoBlock.Anim then
        local killers = getKillersFolder()
        local myRoot = getRoot(currentCharacter())
        if killers and myRoot then
            for _, killer in ipairs(killers:GetChildren()) do
                local hrp = getRoot(killer)
                local hum = getHumanoid(killer)
                local animator = hum and hum:FindFirstChildOfClass("Animator")
                if hrp and animator and (hrp.Position - myRoot.Position).Magnitude <= Config.AutoBlock.Range then
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                        local animObj = track.Animation
                        local animId = animObj and tostring(animObj.AnimationId):match("%d+")
                        if animId and autoBlockTriggerAnims[animId] then
                            tryBlockFromRoot(hrp)
                            break
                        end
                    end
                end
            end
        end
    end

    if Config.AutoBlock.AutoPunch then
        local killers = getKillersFolder()
        local myRoot = getRoot(currentCharacter())
        local btn = getAbilityButton("Punch")
        if killers and myRoot and btn then
            local nearest, nearestDist
            for _, killer in ipairs(killers:GetChildren()) do
                local hrp = getRoot(killer)
                if hrp then
                    local d = (hrp.Position - myRoot.Position).Magnitude
                    if d <= 12 and (not nearestDist or d < nearestDist) then
                        nearest = hrp
                        nearestDist = d
                    end
                end
            end
            if nearest then
                if Config.AutoBlock.AimPunch then
                    local char = currentCharacter()
                    if char then
                        local forward = nearest.Position + (nearest.AssemblyLinearVelocity or Vector3.zero) * Config.AutoBlock.Prediction
                        pcall(function()
                            char:PivotTo(CFrame.new(getRoot(char).Position, Vector3.new(forward.X, getRoot(char).Position.Y, forward.Z)))
                        end)
                    end
                end
                fireButton(btn)
            end
        end
    end
end))

task.spawn(function()
    while gui.Parent do
        if Config.AutoBlock.Audio then
            local killers = getKillersFolder()
            if killers then
                for _, d in ipairs(killers:GetDescendants()) do
                    if d:IsA("Sound") then
                        hookSound(d)
                    end
                end
            end
        end
        updatePlayerESP()
        task.wait(Config.Visuals.Refresh)
    end
end)

task.spawn(function()
    while gui.Parent do
        if Config.Visuals.Items or Config.Visuals.Generator then
            updateWorldESP()
            task.wait(math.max(2, Config.Visuals.Refresh * 4))
        else
            updateWorldESP()
            task.wait(3)
        end
    end
end)

task.spawn(function()
    while gui.Parent do
        if Config.Other.AlwaysShowChat then
            setChatVisibility(true)
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while gui.Parent do
        if Config.Anti.Popup1x then
            hide1xPopupFrames()
        end
        task.wait(0.15)
    end
end)

task.spawn(function()
    while gui.Parent do
        if Config.Anti.FakeNoli then
            purgeFakeNoli()
            task.wait(0.2)
        else
            task.wait(0.5)
        end
    end
end)

hookAutoGen()
updateVoidrush()
updateAutoTrick()

bind(gui.AncestryChanged:Connect(function(_, parent)
    if not parent then
        for key, _ in pairs(espCache) do
            removeESP(key)
        end
    end
end))
