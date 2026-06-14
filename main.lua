--[[ 
    DANDY'S WORLD: POORLY SCRIPTED STUFF v8.9 (OPTIMIZED)
    macOS / iOS 25 Aesthetic Library + Smart ESP
    Updated: Pastel Easter Theme, Removed Webhooks/Links, Heavily Optimized
    Features: Auto Skillcheck, Smart Noclip, Real-time HP, Gen Rush, Auto Collect, Holiday Items
    Utility Build: Gen Speeder TP + Smart Safety Rules + Updated Infinite Yield
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

local Theme = {
    Background = Color3.fromRGB(255, 240, 245),
    Sidebar = Color3.fromRGB(255, 228, 230),
    Text = Color3.fromRGB(80, 50, 60),
    TextDim = Color3.fromRGB(150, 110, 130),
    Accent = Color3.fromRGB(255, 153, 204),
    Stroke = Color3.fromRGB(255, 200, 215),
    Success = Color3.fromRGB(119, 221, 119),
    Destructive = Color3.fromRGB(255, 105, 97),
    CornerRadius = UDim.new(0, 14),
    Gold = Color3.fromRGB(255, 215, 0)
}

local OriginalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
}

local SoundEnabled = true
local SoundAssets = {
    Hover = "rbxassetid://6895079853",
    Click = "rbxassetid://1412830636",
    Notify = "rbxassetid://87437544236708",
    Error = "rbxassetid://15933620967"
}
local LoadedSounds = {}

local function PreloadSounds()
    local SoundFolder = Instance.new("Folder")
    SoundFolder.Name = "DW_Script_Sounds"
    SoundFolder.Parent = SoundService

    for name, id in pairs(SoundAssets) do
        local s = Instance.new("Sound")
        s.Name = name
        s.SoundId = id
        s.Volume = 0.5
        s.Parent = SoundFolder
        LoadedSounds[name] = s
    end

    ContentProvider:PreloadAsync(SoundFolder:GetChildren())
end
task.spawn(PreloadSounds)

local function PlayAudio(name)
    if not SoundEnabled then return end
    local sound = LoadedSounds[name]
    if sound then
        sound:Play()
    end
end

local Library = {}
local NotificationHolder
local ScreenGui
local IsMenuOpen = true
local IsSettingKeybind = false
local ToggleKey = Enum.KeyCode.LeftControl
local DidAutoLoadConfig = false
local UIControls = {}

function Library:Notify(Title, Text, Duration)
    PlayAudio("Notify")
    if not NotificationHolder then return end

    local NotifyFrame = Instance.new("Frame")
    NotifyFrame.Size = UDim2.new(1, 0, 0, 0)
    NotifyFrame.BackgroundColor3 = Theme.Background
    NotifyFrame.BackgroundTransparency = 0.1
    NotifyFrame.BorderSizePixel = 0
    NotifyFrame.ClipsDescendants = true
    NotifyFrame.Parent = NotificationHolder

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Theme.Stroke
    Stroke.Thickness = 2
    Stroke.Parent = NotifyFrame

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = NotifyFrame

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Text = Title
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 14
    TitleLabel.TextColor3 = Theme.Accent
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Size = UDim2.new(1, -20, 0, 20)
    TitleLabel.Position = UDim2.new(0, 10, 0, 5)
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = NotifyFrame

    local DescLabel = Instance.new("TextLabel")
    DescLabel.Text = Text
    DescLabel.Font = Enum.Font.Gotham
    DescLabel.TextSize = 12
    DescLabel.TextColor3 = Theme.Text
    DescLabel.BackgroundTransparency = 1
    DescLabel.Size = UDim2.new(1, -20, 0, 30)
    DescLabel.Position = UDim2.new(0, 10, 0, 22)
    DescLabel.TextXAlignment = Enum.TextXAlignment.Left
    DescLabel.TextWrapped = true
    DescLabel.Parent = NotifyFrame

    NotifyFrame:TweenSize(UDim2.new(1, 0, 0, 60), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.3, true)
    task.delay(Duration or 3, function()
        NotifyFrame:TweenSize(UDim2.new(1, 0, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quart, 0.3, true, function()
            NotifyFrame:Destroy()
        end)
    end)
end

local FreecamEnabled = false
local FreecamSpeed = 1
local FreecamState = {
    Position = Vector3.new(),
    Angles = Vector2.new()
}
local InputState = {
    W = false, A = false, S = false, D = false, Q = false, E = false, Shift = false
}

local function UpdateFreecam(dt)
    if not FreecamEnabled then return end

    local delta = UserInputService:GetMouseDelta()
    if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or UserInputService.TouchEnabled then
        FreecamState.Angles = FreecamState.Angles - Vector2.new(delta.Y, delta.X) * 0.005
    end

    local pitch = math.clamp(FreecamState.Angles.X, -math.pi/2, math.pi/2)
    local yaw = FreecamState.Angles.Y
    local rotation = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)

    local moveVector = Vector3.new()
    if InputState.W then moveVector = moveVector + Vector3.new(0, 0, -1) end
    if InputState.S then moveVector = moveVector + Vector3.new(0, 0, 1) end
    if InputState.A then moveVector = moveVector + Vector3.new(-1, 0, 0) end
    if InputState.D then moveVector = moveVector + Vector3.new(1, 0, 0) end
    if InputState.Q then moveVector = moveVector + Vector3.new(0, -1, 0) end
    if InputState.E then moveVector = moveVector + Vector3.new(0, 1, 0) end

    local speedMultiplier = InputState.Shift and 3 or 1
    local adjustedSpeed = FreecamSpeed * speedMultiplier * (dt * 60)

    if moveVector.Magnitude > 0 then
        moveVector = moveVector.Unit * adjustedSpeed
        FreecamState.Position = FreecamState.Position + (rotation * moveVector)
    end

    Camera.CFrame = CFrame.new(FreecamState.Position) * rotation

    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.Anchored = true
        LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
    end
end

local function ToggleFreecamLogic(val)
    FreecamEnabled = val
    if val then
        Camera.CameraType = Enum.CameraType.Scriptable
        FreecamState.Position = Camera.CFrame.Position
        local x, y, z = Camera.CFrame:ToEulerAnglesYXZ()
        FreecamState.Angles = Vector2.new(x, y)
        RunService:BindToRenderStep("DW_Freecam", Enum.RenderPriority.Camera.Value + 1, UpdateFreecam)
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        Library:Notify("Freecam", "Enabled (Press H to toggle)", 2)
    else
        RunService:UnbindFromRenderStep("DW_Freecam")
        Camera.CameraType = Enum.CameraType.Custom
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.Anchored = false
        end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            Camera.CameraSubject = LocalPlayer.Character.Humanoid
        end
        Library:Notify("Freecam", "Disabled", 2)
    end
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.W then InputState.W = true end
    if input.KeyCode == Enum.KeyCode.A then InputState.A = true end
    if input.KeyCode == Enum.KeyCode.S then InputState.S = true end
    if input.KeyCode == Enum.KeyCode.D then InputState.D = true end
    if input.KeyCode == Enum.KeyCode.Q then InputState.Q = true end
    if input.KeyCode == Enum.KeyCode.E then InputState.E = true end
    if input.KeyCode == Enum.KeyCode.LeftShift then InputState.Shift = true end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
    if input.KeyCode == Enum.KeyCode.W then InputState.W = false end
    if input.KeyCode == Enum.KeyCode.A then InputState.A = false end
    if input.KeyCode == Enum.KeyCode.S then InputState.S = false end
    if input.KeyCode == Enum.KeyCode.D then InputState.D = false end
    if input.KeyCode == Enum.KeyCode.Q then InputState.Q = false end
    if input.KeyCode == Enum.KeyCode.E then InputState.E = false end
    if input.KeyCode == Enum.KeyCode.LeftShift then InputState.Shift = false end
end)

local ESP_Settings = {
    Players = {Enabled = false, Color = Theme.Accent},
    Twisteds = {Enabled = false, Color = Theme.Destructive},
    Generators = {Enabled = false, Color = Color3.fromRGB(255, 255, 255)},
    Items = {Enabled = false, Color = Color3.fromRGB(0, 200, 255)},
}

local WalkSpeedEnabled = false
local WalkSpeedValue = 24
local NoclipEnabled = false
local AutoSkillCheckEnabled = false
local AutoEscapeEnabled = false
local InfiniteStaminaEnabled = false
local GodModeEnabled = false
local TpSafeEnabled = false
local TpSafeKey = Enum.KeyCode.V
local TpSafeModeKey = Enum.KeyCode.B
local TpSafeMode = "Elevator" -- Elevator | Player | Sky
local TpSafeDangerDistance = 38
local TpSafeCheckInterval = 0.12
local TpSafeCooldown = 2.5
local TpSafeLastTrigger = 0
local TpSafeSkyHeight = 900
local TpSafeSkyPlate = nil
local TpSafeModeLabel = nil

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if input.KeyCode == TpSafeKey then
        TpSafeEnabled = not TpSafeEnabled

        if UIControls and UIControls.TpSafeToggle then
            UIControls.TpSafeToggle:SetValue(TpSafeEnabled, true)
        end

        if TpSafeModeLabel then
            TpSafeModeLabel:SetText(
                "TP Safe Mode: " .. TpSafeMode ..
                "\nState: " .. (TpSafeEnabled and "ON" or "OFF") ..
                "\nDanger Dist: " .. tostring(TpSafeDangerDistance)
            )
        end

        if Library and Library.Notify then
            Library:Notify("TP Safe", "State: " .. (TpSafeEnabled and "ON" or "OFF"), 2)
        end
    end

    if input.KeyCode == TpSafeModeKey then
        if TpSafeMode == "Elevator" then
            TpSafeMode = "Player"
        elseif TpSafeMode == "Player" then
            TpSafeMode = "Sky"
        else
            TpSafeMode = "Elevator"
        end

        if TpSafeModeLabel then
            TpSafeModeLabel:SetText(
                "TP Safe Mode: " .. TpSafeMode ..
                "\nState: " .. (TpSafeEnabled and "ON" or "OFF") ..
                "\nDanger Dist: " .. tostring(TpSafeDangerDistance)
            )
        end

        if Library and Library.Notify then
            Library:Notify("TP Safe", "Mode: " .. TpSafeMode, 2)
        end
    end
end)
local NoclipConnection = nil
local ESP_Storage = {}
local TwistedNotifyState = {
    Enabled = true,
    Room = nil,
    Known = {},
}
local ItemNotifyState = {
    Enabled = true,
    Room = nil,
    Known = {},
    AllowedRarities = {
        rare = true,
        veryrare = true,
        ["very rare"] = true,
    },
    FallbackTargets = {
        bandage = {
            display = "Bandage",
            rarity = "Rare",
        },
        ["health kit"] = {
            display = "Health Kit",
            rarity = "VeryRare",
        },
        healthkit = {
            display = "Health Kit",
            rarity = "VeryRare",
        },
    },
}

local AutoCollectSafeOnly = false
local AutoCollectSafeDistance = 45
local ConfigSaveFolder = "DandysWorld_PSS"
local ConfigSaveFile = ConfigSaveFolder .. "/config_v2.json"

local ROOM_ITEM_CATALOG = {
    AirHorn = {Event = false},
    Valve = {Event = false},
    Bandage = {Event = false},
    BonBon = {Event = false, Special = true},
    Chocolate = {Event = false},
    ChocolateBox = {Event = false},
    ChristmasCookie = {Event = true},
    DandyEasterEggs = {Event = true},
    EjectButton = {Event = false},
    ExtractionSpeedCandy = {Event = false},
    Gumball = {Event = false},
    HealthKit = {Event = false},
    Instructions = {Event = false},
    Jawbreaker = {Event = false},
    JumperCable = {Event = false},
    Ornament = {Event = true},
    Pop = {Event = false},
    PopBottle = {Event = false},
    ProteinBar = {Event = false},
    SkillCheckCandy = {Event = false},
    SmokeBomb = {Event = false},
    SpeedCandy = {Event = false},
    StaminaCandy = {Event = false},
    StealthCandy = {Event = false},
    Stopwatch = {Event = false},
    Tape = {Event = false},
}

local function EnsureConfigFolder()
    if makefolder and not (isfolder and isfolder(ConfigSaveFolder)) then
        pcall(function()
            makefolder(ConfigSaveFolder)
        end)
    end
end

local function BuildConfigTable()
    return {
        WalkSpeedEnabled = WalkSpeedEnabled,
        WalkSpeedValue = WalkSpeedValue,
        ESPPlayers = ESP_Settings.Players.Enabled,
        ESPTwisteds = ESP_Settings.Twisteds.Enabled,
        ESPGenerators = ESP_Settings.Generators.Enabled,
        ESPItems = ESP_Settings.Items.Enabled,
        AutoSkillCheckEnabled = AutoSkillCheckEnabled,
        AutoEscapeEnabled = AutoEscapeEnabled,
        InfiniteStaminaEnabled = InfiniteStaminaEnabled,
        TpSafeEnabled = TpSafeEnabled,
        TpSafeMode = TpSafeMode,
        TpSafeDangerDistance = TpSafeDangerDistance,
        SoundEnabled = SoundEnabled,
        ToggleKey = ToggleKey and ToggleKey.Name or "LeftControl",
        AutoCollectSafeOnly = AutoCollectSafeOnly,
        AutoCollectSafeDistance = AutoCollectSafeDistance,
    }
end

local function SaveCurrentConfig(silent)
    if not (writefile and HttpService) then
        if not silent then
            Library:Notify("Config", "Your executor does not support file save.", 3)
        end
        return false
    end

    EnsureConfigFolder()
    local ok, payload = pcall(function()
        return HttpService:JSONEncode(BuildConfigTable())
    end)
    if not ok or not payload then
        if not silent then
            Library:Notify("Config", "Failed to encode config.", 3)
        end
        return false
    end

    local wrote = pcall(function()
        writefile(ConfigSaveFile, payload)
    end)
    if wrote and not silent then
        Library:Notify("Config", "Config saved.", 2)
    elseif (not wrote) and (not silent) then
        Library:Notify("Config", "Failed to write config.", 3)
    end
    return wrote
end

local function ApplyLoadedConfig(data)
    if type(data) ~= "table" then return false end

    if type(data.WalkSpeedEnabled) == "boolean" then WalkSpeedEnabled = data.WalkSpeedEnabled end
    if tonumber(data.WalkSpeedValue) then WalkSpeedValue = math.clamp(math.floor(tonumber(data.WalkSpeedValue)), 16, 150) end
    if type(data.ESPPlayers) == "boolean" then ESP_Settings.Players.Enabled = data.ESPPlayers end
    if type(data.ESPTwisteds) == "boolean" then ESP_Settings.Twisteds.Enabled = data.ESPTwisteds end
    if type(data.ESPGenerators) == "boolean" then ESP_Settings.Generators.Enabled = data.ESPGenerators end
    if type(data.ESPItems) == "boolean" then ESP_Settings.Items.Enabled = data.ESPItems end
    if type(data.AutoSkillCheckEnabled) == "boolean" then AutoSkillCheckEnabled = data.AutoSkillCheckEnabled end
    if type(data.AutoEscapeEnabled) == "boolean" then AutoEscapeEnabled = data.AutoEscapeEnabled end
    if type(data.InfiniteStaminaEnabled) == "boolean" then InfiniteStaminaEnabled = data.InfiniteStaminaEnabled end
    if type(data.TpSafeEnabled) == "boolean" then TpSafeEnabled = data.TpSafeEnabled end
    if type(data.TpSafeMode) == "string" and (data.TpSafeMode == "Elevator" or data.TpSafeMode == "Player" or data.TpSafeMode == "Sky") then TpSafeMode = data.TpSafeMode end
    if tonumber(data.TpSafeDangerDistance) then TpSafeDangerDistance = math.clamp(math.floor(tonumber(data.TpSafeDangerDistance)), 15, 80) end
    if type(data.SoundEnabled) == "boolean" then SoundEnabled = data.SoundEnabled end
    if type(data.AutoCollectSafeOnly) == "boolean" then AutoCollectSafeOnly = data.AutoCollectSafeOnly end
    if tonumber(data.AutoCollectSafeDistance) then AutoCollectSafeDistance = math.clamp(math.floor(tonumber(data.AutoCollectSafeDistance)), 10, 200) end

    local savedKey = tostring(data.ToggleKey or "")
    if savedKey ~= "" and Enum.KeyCode[savedKey] then
        ToggleKey = Enum.KeyCode[savedKey]
    end

    return true
end

local function LoadSavedConfig(silent)
    if not (readfile and isfile and HttpService and isfile(ConfigSaveFile)) then
        if not silent then
            Library:Notify("Config", "No saved config found.", 2)
        end
        return false
    end

    local okRead, content = pcall(function()
        return readfile(ConfigSaveFile)
    end)
    if not okRead or not content or content == "" then
        if not silent then
            Library:Notify("Config", "Failed to read config.", 3)
        end
        return false
    end

    local okDecode, data = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    if not okDecode or type(data) ~= "table" then
        if not silent then
            Library:Notify("Config", "Saved config is invalid.", 3)
        end
        return false
    end

    local applied = ApplyLoadedConfig(data)
    if applied and not silent then
        Library:Notify("Config", "Config loaded.", 2)
    end
    return applied
end

DidAutoLoadConfig = LoadSavedConfig(true)

-- Cache para saber si un MainCharacter realmente usa corazones extra como parte del tracking.
-- Esto evita que un Heart3 extra oculto se cuente eternamente como daño falso.
local DW_HP_ModeCache = DW_HP_ModeCache or setmetatable({}, {__mode = "k"})

local function IsHeartGuiFilled(heart)
    if not heart then
        return false
    end

    local okVisible, visible = pcall(function()
        return heart.Visible
    end)

    if okVisible and visible == false then
        return false
    end

    -- Algunos juegos no ocultan el corazón con Visible,
    -- sino con transparencia. Roblox, siempre creativo para romper cosas simples.
    if heart:IsA("ImageLabel") or heart:IsA("ImageButton") then
        local okImageTransparency, imageTransparency = pcall(function()
            return heart.ImageTransparency
        end)

        if okImageTransparency and tonumber(imageTransparency) and imageTransparency >= 0.95 then
            return false
        end
    end

    return true
end

local function GetHeartsFromModel(playerModel)
    if not playerModel then return "..." end

    local stats = playerModel:FindFirstChild("Stats")

    local isMainCharacter = false
    local mainCharacter = stats and stats:FindFirstChild("MainCharacter")

    if mainCharacter and mainCharacter:IsA("BoolValue") then
        isMainCharacter = mainCharacter.Value == true
    end

    local maxHp = nil
    local healthValue = stats and stats:FindFirstChild("Health")

    if healthValue and (healthValue:IsA("NumberValue") or healthValue:IsA("IntValue")) then
        local value = tonumber(healthValue.Value)

        if value and value > 0 then
            maxHp = math.floor(value)
        end
    end

    if isMainCharacter then
        maxHp = 2
    end

    local loadout = playerModel:FindFirstChild("LoadoutFrame")
    local frame = loadout and loadout:FindFirstChild("Frame")
    local healthFrame = frame and frame:FindFirstChild("HealthFrame")
    local heartsFolder = healthFrame and healthFrame:FindFirstChild("Hearts")

    if not heartsFolder then
        return maxHp and ("?/" .. tostring(maxHp) .. " HP") or "..."
    end

    local hearts = {}

    for _, heart in ipairs(heartsFolder:GetChildren()) do
        local heartNumber = tostring(heart.Name):match("^Heart(%d+)$")

        if heartNumber then
            table.insert(hearts, {
                Number = tonumber(heartNumber),
                Object = heart,
            })
        end
    end

    table.sort(hearts, function(a, b)
        return a.Number < b.Number
    end)

    if not maxHp then
        maxHp = #hearts
    end

    maxHp = math.max(0, math.floor(tonumber(maxHp) or 0))

    if maxHp <= 0 then
        return "..."
    end

    local visibleAll = 0
    local hiddenAll = 0
    local visibleRelevant = 0
    local relevantFound = 0
    local extraVisibleNow = false

    for _, data in ipairs(hearts) do
        local heart = data.Object
        local filled = IsHeartGuiFilled(heart)

        if filled then
            visibleAll += 1
        else
            hiddenAll += 1
        end

        if data.Number <= maxHp then
            relevantFound += 1

            if filled then
                visibleRelevant += 1
            end
        elseif filled then
            extraVisibleNow = true
        end
    end

    if relevantFound <= 0 then
        visibleRelevant = visibleAll
    end

    local hp

    if isMainCharacter and #hearts > maxHp then
        local cache = DW_HP_ModeCache[playerModel]

        if not cache then
            cache = {
                ExtraWasVisible = false,
            }
            DW_HP_ModeCache[playerModel] = cache
        end

        -- Si alguna vez vimos corazones extra visibles,
        -- este Main usa esos HeartX extra para marcar daño.
        if extraVisibleNow or visibleAll > maxHp then
            cache.ExtraWasVisible = true
        end

        if cache.ExtraWasVisible then
            -- Caso donde full puede verse como 3 visibles, pero máximo real es 2.
            -- Ahí una vida perdida se detecta por corazones ocultos.
            hp = maxHp - hiddenAll
        else
            -- Caso donde Heart3 existe pero SIEMPRE está oculto por ser extra.
            -- Ahí NO debe contarse como daño.
            hp = visibleRelevant
        end
    else
        hp = visibleRelevant
    end

    hp = math.clamp(math.floor(tonumber(hp) or 0), 0, maxHp)

    if hp <= 0 then
        return "☠️ 0/" .. tostring(maxHp)
    end

    return string.rep("❤", hp) .. " " .. tostring(hp) .. "/" .. tostring(maxHp)
end


local function GetTwistedDisplayName(model)
    if not model then return "Twisted ?" end
    local cleanName = tostring(model.Name or ""):gsub("Monster", "")
    cleanName = cleanName:gsub("^%s+", ""):gsub("%s+$", "")
    if cleanName == "" then
        cleanName = tostring(model.Name or "Unknown")
    end
    return "Twisted " .. cleanName
end

local function NormalizeItemName(name)
    name = tostring(name or ""):lower()
    name = name:gsub("[%p_]", " ")
    name = name:gsub("%s+", " ")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    return name
end

local function GetDisplayItemName(item)
    if not item then return "Unknown Item" end

    local attrDisplay = item:GetAttribute("DisplayName")
    if typeof(attrDisplay) == "string" and attrDisplay ~= "" then
        return attrDisplay
    end

    local stringNames = {"DisplayName", "ItemName", "Name", "Title"}
    for _, valueName in ipairs(stringNames) do
        local direct = item:FindFirstChild(valueName)
        if direct and direct:IsA("StringValue") and tostring(direct.Value or "") ~= "" then
            return tostring(direct.Value)
        end

        local stats = item:FindFirstChild("Stats")
        local nested = stats and stats:FindFirstChild(valueName)
        if nested and nested:IsA("StringValue") and tostring(nested.Value or "") ~= "" then
            return tostring(nested.Value)
        end
    end

    return tostring(item.Name or "Unknown Item")
end

local function NormalizeRarityValue(value)
    value = tostring(value or ""):lower()
    value = value:gsub("[%p_]", " ")
    value = value:gsub("%s+", " ")
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    return value
end

local function ExtractItemRarity(item)
    if not item then return nil end

    local attrNames = {"Rarity", "ItemRarity", "LootRarity"}
    for _, attrName in ipairs(attrNames) do
        local attr = item:GetAttribute(attrName)
        if typeof(attr) == "string" and attr ~= "" then
            return tostring(attr)
        end
    end

    local directNames = {"Rarity", "ItemRarity", "LootRarity"}
    for _, valueName in ipairs(directNames) do
        local direct = item:FindFirstChild(valueName)
        if direct and direct:IsA("StringValue") and tostring(direct.Value or "") ~= "" then
            return tostring(direct.Value)
        end
    end

    local stats = item:FindFirstChild("Stats")
    if stats then
        for _, valueName in ipairs(directNames) do
            local nested = stats:FindFirstChild(valueName)
            if nested and nested:IsA("StringValue") and tostring(nested.Value or "") ~= "" then
                return tostring(nested.Value)
            end
        end
    end

    return nil
end

local function GetTrackedItemInfo(item)
    local rarity = ExtractItemRarity(item)
    local normalizedRarity = NormalizeRarityValue(rarity)

    if normalizedRarity ~= "" and ItemNotifyState.AllowedRarities[normalizedRarity] then
        return {
            display = GetDisplayItemName(item),
            rarity = rarity,
        }
    end

    local normalizedName = NormalizeItemName(item and item.Name)
    for key, info in pairs(ItemNotifyState.FallbackTargets) do
        if normalizedName:find(key, 1, true) then
            return {
                display = info.display,
                rarity = info.rarity,
            }
        end
    end

    return nil
end

local function GetCurrentRoomModel()
    local currentRoomFolder = Workspace:FindFirstChild("CurrentRoom")
    if not currentRoomFolder then return nil end
    return currentRoomFolder:GetChildren()[1]
end

local function GetCurrentMonsterFolder()
    local roomModel = GetCurrentRoomModel()
    return roomModel and roomModel:FindFirstChild("Monsters") or nil
end

local function GetGeneratorFolder()
    local roomModel = GetCurrentRoomModel()
    return roomModel and roomModel:FindFirstChild("Generators") or nil
end

local function GetMobRoot(model)
    if not model then return nil end
    if model:IsA("Model") then
        return model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart", true)
    end
    if model:IsA("BasePart") then
        return model
    end
    return model:FindFirstChildWhichIsA("BasePart", true)
end

local function GetGeneratorTeleportCFrame(gen)
    if not gen then return nil end

    local tpPosFolder = gen:FindFirstChild("TeleportPositions")
    if tpPosFolder then
        local firstPart = tpPosFolder:FindFirstChildWhichIsA("BasePart", true)
        if firstPart then
            return firstPart.CFrame
        end
    end

    if gen:IsA("Model") then
        return gen:GetPivot()
    end

    local part = gen:IsA("BasePart") and gen or gen:FindFirstChildWhichIsA("BasePart", true)
    return part and part.CFrame or nil
end

local function GetObjectWorldPosition(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then
        return obj.Position
    end
    if obj:IsA("Attachment") then
        return obj.WorldPosition
    end
    if obj:IsA("Model") then
        local pp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
        return pp and pp.Position or nil
    end
    local base = obj:FindFirstChildWhichIsA("BasePart", true)
    return base and base.Position or nil
end


local function GetMobCleanName(mob)
    local name = tostring(mob and mob.Name or "")
    name = name:gsub("Monster", "")
    name = name:gsub("Twisted", "")
    name = name:gsub("&", " ")
    name = name:gsub("[%p_]", " ")
    name = name:gsub("%s+", " ")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    return name:lower()
end

local function IsConnieMob(mob)
    return GetMobCleanName(mob) == "connie"
end

local function IsBlotMob(mob)
    local n = GetMobCleanName(mob)
    return n == "blot" or n == "blott"
end

local function IsGlistenMob(mob)
    return GetMobCleanName(mob) == "glisten"
end

local function IsRogerMob(mob)
    local n = GetMobCleanName(mob)
    return n == "rodger" or n == "roger"
end

local function IsDyleMob(mob)
    local n = GetMobCleanName(mob)
    return n == "dyle"
end

local function IsDandyMob(mob)
    local n = GetMobCleanName(mob)
    return n == "dandy"
end

local function IsRazzleDazzleMob(mob)
    local n = GetMobCleanName(mob)
    return n == "razzle dazzle"
        or n == "razzle"
        or n == "dazzle"
end

local DEFAULT_TWISTED_PROFILE = {
    vision = 60,
    instant = 26,
    kill = 3.33,
    lineOfSight = 0.4,
}

local TWISTED_PROFILES = {
    ["astro"] = {vision = 70, instant = 30, kill = 3, lineOfSight = 0.4},
    ["bassie"] = {vision = 70, instant = 30, kill = 4, lineOfSight = 0.4},
    ["bobette"] = {vision = 80, instant = 40, kill = 4, lineOfSight = 0.5},
    ["boxten"] = {vision = 60, instant = 26, kill = 3.33, lineOfSight = 0.4},
    ["brightney"] = {vision = 65, instant = 26, kill = 3.3, lineOfSight = 0.4},
    ["brusha"] = {vision = 100, instant = 26, kill = 3.333, lineOfSight = 0.4},
    ["coal"] = {
        vision = 70,
        instant = 35,
        kill = 3.33,
        lineOfSight = 0.6,
        blackout = {vision = 125, instant = 35, kill = 6.5, lineOfSight = 0.4},
    },
    ["connie"] = {vision = 60, instant = 25, kill = 3.3, lineOfSight = 0.4, machineOnly = true},
    ["cocoa"] = {vision = 50, instant = 25, kill = 3.33, lineOfSight = 0.4},
    ["cosmo"] = {vision = 60, instant = 26, kill = 3.333, lineOfSight = 0.4},
    ["dandy"] = {vision = 80, instant = 35, kill = 8.5, lineOfSight = 0.4, lethal = true},
    ["dyle"] = {vision = 70, instant = 35, kill = 8.5, lineOfSight = 0.4, lethal = true},
    ["eclipse"] = {vision = 60, instant = 30, kill = 3.33, lineOfSight = 0.4},
    ["eggson"] = {vision = 60, instant = 26, kill = 3.33, lineOfSight = 0.4},
    ["finn"] = {vision = 60, instant = 26, kill = 3.33, lineOfSight = 0.4},
    ["flutter"] = {vision = 65, instant = 30, kill = 3.5, lineOfSight = 0.4},
    ["flyte"] = {vision = 65, instant = 30, kill = 3.5, lineOfSight = 0.4},
    ["gigi"] = {vision = 60, instant = 26, kill = 3.33, lineOfSight = 0.4},
    ["ginger"] = {vision = 65, instant = 30, kill = 3.33, lineOfSight = 0.4},
    ["glisten"] = {vision = 60, instant = 25, kill = 3.33, lineOfSight = 0.4, activationBased = true},
    ["goob"] = {vision = 60, instant = 26, kill = 3.33, lineOfSight = 0.4},
    ["gourdy"] = {vision = 70, instant = 30, kill = 4, lineOfSight = 0.4},
    ["looey"] = {vision = 60, instant = 26, kill = 3.33, lineOfSight = 0.4},
    ["pebble"] = {vision = 85, instant = 32, kill = 4, lineOfSight = 0.4},
    ["poppy"] = {vision = 60, instant = 26, kill = 3.33, lineOfSight = 0.4},
    ["razzle dazzle"] = {vision = 60, instant = 25, kill = 3.33, lineOfSight = 0.4, zoneRunOnly = true},
    ["ribecca"] = {vision = 60, instant = 26, kill = 3.33, lineOfSight = 0.4},
    ["rodger"] = {vision = 60, instant = 25, kill = 3.33, lineOfSight = 0.4, ignoreGeneral = true},
    ["roger"] = {vision = 60, instant = 25, kill = 3.33, lineOfSight = 0.4, ignoreGeneral = true},
    ["rudie"] = {vision = 55, instant = 25, kill = 3.33, lineOfSight = 0.4},
    ["scraps"] = {vision = 65, instant = 28, kill = 3.5, lineOfSight = 0.4},
    ["shelly"] = {vision = 70, instant = 30, kill = 4, lineOfSight = 0.4},
    ["shrimpo"] = {vision = 70, instant = 28, kill = 3.33, lineOfSight = 0.4},
    ["soulvester"] = {vision = 70, instant = 28, kill = 3.5, lineOfSight = 0.4},
    ["sprout"] = {vision = 75, instant = 30, kill = 4, lineOfSight = 0.4},
    ["squirm"] = {vision = 0, instant = 0, kill = 4, lineOfSight = 0, zoneBased = true},
    ["teagan"] = {vision = 60, instant = 26, kill = 3.33, lineOfSight = 0.4},
    ["tisha"] = {vision = 60, instant = 26, kill = 3.33, lineOfSight = 0.4},
    ["toodles"] = {vision = 50, instant = 24, kill = 3.0, lineOfSight = 0.4},
    ["vee"] = {vision = 80, instant = 35, kill = 4, lineOfSight = 0.4},
    ["yatta"] = {vision = 55, instant = 24, kill = 3.0, lineOfSight = 0.4},
}

local function IsBlackoutActive()
    local info = Workspace:FindFirstChild("Info")
    if not info then return false end
    local blackout = info:FindFirstChild("Blackout")
    if blackout and blackout:IsA("BoolValue") then
        return blackout.Value == true
    end
    return false
end

local function GetMobThreatProfile(mob)
    local name = GetMobCleanName(mob)
    local profile = TWISTED_PROFILES[name] or DEFAULT_TWISTED_PROFILE

    if name == "coal" and profile.blackout and IsBlackoutActive() then
        local blackoutProfile = {}
        for k, v in pairs(profile) do
            blackoutProfile[k] = v
        end
        for k, v in pairs(profile.blackout) do
            blackoutProfile[k] = v
        end
        blackoutProfile.inBlackout = true
        return blackoutProfile
    end

    return profile
end

local function HasLineOfSight(fromPosition, toPosition, extraIgnore)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true

    local ignore = {}
    if LocalPlayer.Character then
        table.insert(ignore, LocalPlayer.Character)
    end
    local roomModel = GetCurrentRoomModel()
    if roomModel and roomModel:FindFirstChild("Items") then
        table.insert(ignore, roomModel.Items)
    end
    if type(extraIgnore) == "table" then
        for _, obj in ipairs(extraIgnore) do
            if obj then
                table.insert(ignore, obj)
            end
        end
    end
    params.FilterDescendantsInstances = ignore

    local direction = toPosition - fromPosition
    if direction.Magnitude <= 0.01 then
        return true
    end

    local result = Workspace:Raycast(fromPosition, direction, params)
    return result == nil
end

local function IsMobLookingAtPosition(mob, targetPosition, dotThreshold)
    local mobRoot = GetMobRoot(mob)
    if not mobRoot then return false end

    local dir = targetPosition - mobRoot.Position
    if dir.Magnitude <= 0.01 then
        return true
    end

    dir = dir.Unit
    local look = mobRoot.CFrame.LookVector
    local dot = look:Dot(dir)
    return dot >= (dotThreshold or 0.35)
end

local function AreAllGeneratorsCompleted()
    local genFolder = GetGeneratorFolder()
    if not genFolder then return false end

    local foundAny = false
    for _, gen in ipairs(genFolder:GetChildren()) do
        local stats = gen:FindFirstChild("Stats")
        local completedVal = stats and stats:FindFirstChild("Completed")
        if completedVal then
            foundAny = true
            if completedVal.Value == false then
                return false
            end
        end
    end

    return foundAny
end

local function IsConnieGenerator(gen)
    if not gen then return false end
    local stats = gen:FindFirstChild("Stats")
    local connie = stats and stats:FindFirstChild("Connie")
    return connie and connie:IsA("BoolValue") and connie.Value == true or false
end

local function IsConnieActiveInRoom()
    local monsterFolder = GetCurrentMonsterFolder()
    if not monsterFolder then return false end

    for _, mob in ipairs(monsterFolder:GetChildren()) do
        if IsConnieMob(mob) then
            return true
        end
    end

    return false
end

local function GetNearestConnieGeneratorDistance(position)
    local genFolder = GetGeneratorFolder()
    if not genFolder then
        return nil, math.huge
    end

    local nearestGen = nil
    local nearestDistance = math.huge

    for _, gen in ipairs(genFolder:GetChildren()) do
        if IsConnieGenerator(gen) then
            local genCF = GetGeneratorTeleportCFrame(gen)
            if genCF then
                local dist = (genCF.Position - position).Magnitude
                if dist < nearestDistance then
                    nearestDistance = dist
                    nearestGen = gen
                end
            end
        end
    end

    return nearestGen, nearestDistance
end

local function GetBlotHandCandidates()
    local found = {}
    local roomModel = GetCurrentRoomModel()
    if not roomModel then return found end

    local aliases = {
        "blothandzone",
        "blot hand zone",
        "blothand",
        "blot hand",
        "handzone",
        "hand zone",
    }

    for _, desc in ipairs(roomModel:GetDescendants()) do
        local n = NormalizeItemName(desc.Name)
        for _, alias in ipairs(aliases) do
            if n:find(alias, 1, true) then
                table.insert(found, desc)
                break
            end
        end
    end

    return found
end

local function GetNearestBlotHandDistance(position)
    local nearestObj = nil
    local nearestDistance = math.huge

    for _, obj in ipairs(GetBlotHandCandidates()) do
        local objPos = GetObjectWorldPosition(obj)
        if objPos then
            local dist = (objPos - position).Magnitude
            if dist < nearestDistance then
                nearestDistance = dist
                nearestObj = obj
            end
        end
    end

    return nearestObj, nearestDistance
end

local function GetNearestTwistedInfo(position, options)
    options = options or {}

    local roomModel = GetCurrentRoomModel()
    local monsterFolder = roomModel and roomModel:FindFirstChild("Monsters")
    if not monsterFolder then return nil, math.huge, false, false, nil end

    local nearestMob = nil
    local nearestDistance = math.huge
    local nearestHasLOS = false
    local nearestLooking = false
    local nearestProfile = nil

    for _, mob in pairs(monsterFolder:GetChildren()) do
        if mob and mob.Parent then
            local root = GetMobRoot(mob)
            if root then
                local profile = GetMobThreatProfile(mob)
                if not (options.IgnoreConnie and IsConnieMob(mob))
                    and not (options.IgnoreBlotBody and IsBlotMob(mob))
                    and not (options.IgnoreRoger and (IsRogerMob(mob) or profile.ignoreGeneral))
                    and not (options.IgnoreGlistenWhenInactive and IsGlistenMob(mob) and not AreAllGeneratorsCompleted()) then

                    local distance = (root.Position - position).Magnitude
                    local hasLOS = HasLineOfSight(root.Position, position, {mob})
                    local isLooking = hasLOS and IsMobLookingAtPosition(mob, position, profile.lineOfSight or 0.4)

                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearestMob = mob
                        nearestHasLOS = hasLOS
                        nearestLooking = isLooking
                        nearestProfile = profile
                    end
                end
            end
        end
    end

    return nearestMob, nearestDistance, nearestHasLOS, nearestLooking, nearestProfile
end

local function GetDangerBudget(profile, threshold)
    local killRadius = tonumber(profile.kill) or 3.33
    local instantRadius = tonumber(profile.instant) or 26
    local visionRadius = tonumber(profile.vision) or threshold

    local killBudget = killRadius + 1.5
    local instantBudget = math.min(instantRadius, threshold)
    local visionBudget = math.min(visionRadius, threshold)

    if profile.lethal then
        instantBudget = math.max(instantBudget, killBudget + 4)
        visionBudget = math.max(visionBudget, math.min((tonumber(profile.vision) or threshold), threshold))
    end

    return killBudget, instantBudget, visionBudget
end

local function IsSafeFromTwisteds(position, minDistance, context)
    context = context or {}
    local threshold = minDistance or 45

    if context.CheckConnieMachine ~= false and IsConnieActiveInRoom() then
        local connieGen, connieDist = GetNearestConnieGeneratorDistance(position)
        if connieGen and connieDist < math.max(14, math.floor(threshold * 0.45)) then
            return false, connieGen, connieDist, "ConnieGenerator"
        end
    end

    if context.CheckBlotHands ~= false then
        local handObj, handDist = GetNearestBlotHandDistance(position)
        if handObj and handDist < math.max(16, math.floor(threshold * 0.55)) then
            return false, handObj, handDist, "BlotHand"
        end
    end

    local roomModel = GetCurrentRoomModel()
    local monsterFolder = roomModel and roomModel:FindFirstChild("Monsters")
    if not monsterFolder then
        return true, nil, math.huge, "Safe"
    end

    local bestDangerMob = nil
    local bestDangerDistance = math.huge
    local bestDangerType = "Safe"

    for _, mob in ipairs(monsterFolder:GetChildren()) do
        local root = GetMobRoot(mob)
        if root then
            local profile = GetMobThreatProfile(mob)
            local distance = (root.Position - position).Magnitude

            if IsConnieMob(mob) then
                -- handled by generator connie check only
            elseif IsBlotMob(mob) then
                -- handled by blot hands only
            elseif IsRogerMob(mob) or profile.ignoreGeneral then
                -- ignored
            elseif IsGlistenMob(mob) and not AreAllGeneratorsCompleted() then
                -- not active yet
            else
                local hasLOS = HasLineOfSight(root.Position, position, {mob})
                if hasLOS then
                    local isLooking = IsMobLookingAtPosition(mob, position, profile.lineOfSight or 0.4)
                    local killBudget, instantBudget, visionBudget = GetDangerBudget(profile, threshold)

                    local dangerType = nil
                    local isDanger = false

                    if distance <= killBudget then
                        isDanger = true
                        dangerType = profile.lethal and "LethalKillRadius" or "KillRadius"
                    elseif IsRazzleDazzleMob(mob) then
                        if distance <= math.max(18, math.floor(instantBudget * 0.75)) then
                            isDanger = true
                            dangerType = "RazzleDazzleClose"
                        end
                    elseif distance <= instantBudget then
                        isDanger = true
                        dangerType = profile.lethal and "LethalInstant" or "InstantRadius"
                    elseif isLooking and distance <= visionBudget then
                        isDanger = true
                        dangerType = profile.lethal and "LethalVision" or "VisionRadius"
                    end

                    if isDanger and distance < bestDangerDistance then
                        bestDangerMob = mob
                        bestDangerDistance = distance
                        bestDangerType = dangerType or "NormalTwisted"
                    end
                end
            end
        end
    end

    if bestDangerMob then
        return false, bestDangerMob, bestDangerDistance, bestDangerType
    end

    return true, nil, math.huge, "Safe"
end


local function GetSafeElevatorCFrame()
    local elevatorFolder = Workspace:FindFirstChild("Elevators")
    if not elevatorFolder then return nil end

    local elevator = elevatorFolder:FindFirstChild("Elevator")
    if not elevator then return nil end

    local spawnZones = elevator:FindFirstChild("SpawnZones")
    if not spawnZones then return nil end

    local target = spawnZones:IsA("BasePart") and spawnZones or spawnZones:FindFirstChildOfClass("BasePart")
    return target and target.CFrame or nil
end

local function GetSafePlayerCFrame()
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end

    local inGamePlayers = Workspace:FindFirstChild("InGamePlayers")
    if not inGamePlayers then return nil end

    local bestCF = nil
    local bestScore = -math.huge

    for _, char in ipairs(inGamePlayers:GetChildren()) do
        if char.Name ~= LocalPlayer.Name then
            local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart", true)
            if root then
                local safe = IsSafeFromTwisteds(root.Position, TpSafeDangerDistance, {
                    CheckConnieMachine = true,
                    CheckBlotHands = true,
                })
                if safe then
                    local dist = (root.Position - myHRP.Position).Magnitude
                    local score = -dist
                    if score > bestScore then
                        bestScore = score
                        bestCF = root.CFrame
                    end
                end
            end
        end
    end

    return bestCF
end

local function EnsureTpSafeSkyPlate()
    if TpSafeSkyPlate and TpSafeSkyPlate.Parent then
        return TpSafeSkyPlate
    end

    local plate = Instance.new("Part")
    plate.Name = "DW_TpSafeSkyPlate"
    plate.Anchored = true
    plate.CanCollide = true
    plate.Transparency = 0.15
    plate.Color = Theme.Background
    plate.Material = Enum.Material.SmoothPlastic
    plate.Size = Vector3.new(120, 4, 120)
    plate.CFrame = CFrame.new(0, TpSafeSkyHeight, 0)
    plate.Parent = Workspace

    TpSafeSkyPlate = plate
    return plate
end

local function GetSafeSkyCFrame()
    local plate = EnsureTpSafeSkyPlate()
    return plate and plate.CFrame or nil
end

local function GetTpSafeTargetCFrame()
    if TpSafeMode == "Elevator" then
        return GetSafeElevatorCFrame()
    elseif TpSafeMode == "Player" then
        return GetSafePlayerCFrame()
    elseif TpSafeMode == "Sky" then
        return GetSafeSkyCFrame()
    end
    return nil
end

local function GetTpSafeThreatText(dangerObj, dangerDistance, dangerType)
    if dangerType == "ConnieGenerator" then
        return "Connie machine " .. tostring(math.floor(dangerDistance)) .. " studs"
    elseif dangerType == "BlotHand" then
        return "Blot hand " .. tostring(math.floor(dangerDistance)) .. " studs"
    elseif dangerObj and dangerObj:IsA("Model") then
        return GetTwistedDisplayName(dangerObj) .. " [" .. tostring(dangerType) .. "]"
    end
    return tostring(dangerType or "Danger")
end

local function PerformTpSafe(reasonText)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local targetCF = GetTpSafeTargetCFrame()
    if not targetCF then
        if Library and Library.Notify then
            Library:Notify("TP Safe", "No safe target for mode: " .. tostring(TpSafeMode), 3)
        end
        return false
    end

    hrp.CFrame = targetCF + Vector3.new(0, 3, 0)
    TpSafeLastTrigger = tick()

    if Library and Library.Notify then
        Library:Notify("TP Safe", "Triggered: " .. tostring(reasonText) .. " -> " .. tostring(TpSafeMode), 3)
    end
    return true
end

local function CountTrackedRareItems(roomModel)
    local count = 0
    local itemFolder = roomModel and roomModel:FindFirstChild("Items")
    if not itemFolder then return 0 end

    for _, item in pairs(itemFolder:GetChildren()) do
        if GetTrackedItemInfo(item) then
            count = count + 1
        end
    end
    return count
end

local function CreateHighlight(model, color, name, isPlayer, showBillboard)
    if not model then return end
    local existingBillboard = model:FindFirstChild("DW_ESP_Text")

    if existingBillboard and isPlayer then
        existingBillboard.TextLabel.Text = model.Name .. "\n" .. GetHeartsFromModel(model)
        return
    end

    if model:FindFirstChild("DW_ESP") then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "DW_ESP"
    highlight.Adornee = model
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = 0.6
    highlight.OutlineTransparency = 0.1
    highlight.Parent = model

    local billboard
    if showBillboard then
        billboard = Instance.new("BillboardGui")
        billboard.Name = "DW_ESP_Text"
        billboard.Adornee = model
        billboard.Size = UDim2.new(0, 150, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 5, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = model

        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, 0, 1, 0)
        text.BackgroundTransparency = 1
        if isPlayer then
            text.Text = model.Name .. "\n" .. GetHeartsFromModel(model)
        else
            text.Text = name
        end
        text.TextColor3 = color
        text.TextStrokeTransparency = 0
        text.Font = Enum.Font.GothamBold
        text.TextSize = 13
        text.Parent = billboard
    end

    table.insert(ESP_Storage, {Instance = highlight, Billboard = billboard, Parent = model, Type = name, IsPlayer = isPlayer})
end

local function RefreshESP()
    for i = #ESP_Storage, 1, -1 do
        local data = ESP_Storage[i]
        local shouldExist = false
        if data.Type == "Generator" and ESP_Settings.Generators.Enabled then
            shouldExist = true
        elseif data.IsPlayer and ESP_Settings.Players.Enabled then
            shouldExist = true
        elseif ESP_Settings.Twisteds.Enabled and data.Type == "Twisted" then
            shouldExist = true
        elseif ESP_Settings.Items.Enabled and data.Type == "Item" then
            shouldExist = true
        end

        if not shouldExist or not data.Parent or not data.Parent.Parent then
            if data.Instance then data.Instance:Destroy() end
            if data.Billboard then data.Billboard:Destroy() end
            table.remove(ESP_Storage, i)
        end
    end

    if ESP_Settings.Players.Enabled then
        local igPlayers = Workspace:FindFirstChild("InGamePlayers")
        if igPlayers then
            for _, char in pairs(igPlayers:GetChildren()) do
                if char.Name ~= LocalPlayer.Name then
                    CreateHighlight(char, ESP_Settings.Players.Color, char.Name, true, true)
                end
            end
        end
    end

    local currentRoomFolder = Workspace:FindFirstChild("CurrentRoom")
    if currentRoomFolder then
        local roomModel = currentRoomFolder:GetChildren()[1]
        if roomModel then
            local roomKey = roomModel:GetDebugId()
            if TwistedNotifyState.Room ~= roomKey then
                TwistedNotifyState.Room = roomKey
                TwistedNotifyState.Known = {}
            end
            if ItemNotifyState.Room ~= roomKey then
                ItemNotifyState.Room = roomKey
                ItemNotifyState.Known = {}
            end

            local monsterFolder = roomModel:FindFirstChild("Monsters")
            if monsterFolder then
                local currentTwisteds = {}
                local newTwisteds = {}
                local twistedNotifyEnabled = ESP_Settings.Twisteds.Enabled and TwistedNotifyState.Enabled

                if not twistedNotifyEnabled then
                    TwistedNotifyState.Known = {}
                end

                for _, mob in pairs(monsterFolder:GetChildren()) do
                    currentTwisteds[mob] = true
                    if twistedNotifyEnabled and not TwistedNotifyState.Known[mob] then
                        TwistedNotifyState.Known[mob] = true
                        table.insert(newTwisteds, GetTwistedDisplayName(mob))
                    end

                    if ESP_Settings.Twisteds.Enabled then
                        local twistedName = GetTwistedDisplayName(mob)
                        CreateHighlight(mob, ESP_Settings.Twisteds.Color, "Twisted", false, true)
                        if mob:FindFirstChild("DW_ESP_Text") then
                            mob.DW_ESP_Text.TextLabel.Text = twistedName
                        end
                    end
                end

                if twistedNotifyEnabled then
                    for mob in pairs(TwistedNotifyState.Known) do
                        if not currentTwisteds[mob] or not mob.Parent then
                            TwistedNotifyState.Known[mob] = nil
                        end
                    end

                    if #newTwisteds > 0 then
                        Library:Notify("New Twisted", table.concat(newTwisteds, ", "), 4)
                    end
                end
            end

            if ESP_Settings.Generators.Enabled then
                local genFolder = roomModel:FindFirstChild("Generators")
                if genFolder then
                    for _, gen in pairs(genFolder:GetChildren()) do
                        local isCompleted = false
                        if gen:FindFirstChild("Stats") and gen.Stats:FindFirstChild("Completed") then
                            isCompleted = gen.Stats.Completed.Value
                        end
                        local targetColor = isCompleted and Theme.Success or Color3.fromRGB(255, 255, 255)
                        local existing = gen:FindFirstChild("DW_ESP")
                        if existing then
                            if existing.FillColor ~= targetColor then
                                existing.FillColor = targetColor
                                existing.OutlineColor = targetColor
                            end
                        else
                            CreateHighlight(gen, targetColor, "Generator", false, false)
                        end
                    end
                end
            end

            local itemFolder = roomModel:FindFirstChild("Items")
            if itemFolder then
                local currentTrackedItems = {}
                local newTrackedItems = {}
                local itemNotifyEnabled = ESP_Settings.Items.Enabled and ItemNotifyState.Enabled

                if not itemNotifyEnabled then
                    ItemNotifyState.Known = {}
                end

                for _, item in pairs(itemFolder:GetChildren()) do
                    local trackedInfo = GetTrackedItemInfo(item)
                    if trackedInfo then
                        currentTrackedItems[item] = true
                        if itemNotifyEnabled and not ItemNotifyState.Known[item] then
                            ItemNotifyState.Known[item] = trackedInfo
                            table.insert(newTrackedItems, trackedInfo)
                        end
                    end

                    if ESP_Settings.Items.Enabled then
                        CreateHighlight(item, ESP_Settings.Items.Color, item.Name, false, true)
                    end
                end

                if itemNotifyEnabled then
                    for item in pairs(ItemNotifyState.Known) do
                        if not currentTrackedItems[item] or not item.Parent then
                            ItemNotifyState.Known[item] = nil
                        end
                    end

                    if #newTrackedItems > 0 then
                        local counts = {}
                        local order = {}
                        for _, info in ipairs(newTrackedItems) do
                            local key = tostring(info.display)
                            if not counts[key] then
                                counts[key] = {
                                    display = info.display,
                                    count = 0,
                                }
                                table.insert(order, key)
                            end
                            counts[key].count = counts[key].count + 1
                        end

                        local notifyNames = {}
                        for _, key in ipairs(order) do
                            local entry = counts[key]
                            if entry then
                                local label = tostring(entry.display)
                                if entry.count > 1 then
                                    label = label .. " x" .. tostring(entry.count)
                                end
                                table.insert(notifyNames, label)
                            end
                        end
                        Library:Notify("Useful Item", table.concat(notifyNames, ", "), 4)
                    end
                end
            end
        end
    end
end

task.spawn(function()
    while task.wait(0.5) do
        RefreshESP()
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if InfiniteStaminaEnabled then
            pcall(function()
                local igPlayers = Workspace:FindFirstChild("InGamePlayers")
                if igPlayers then
                    local myData = igPlayers:FindFirstChild(LocalPlayer.Name)
                    if myData and myData:FindFirstChild("Stats") then
                        local current = myData.Stats:FindFirstChild("CurrentStamina")
                        local original = myData.Stats:FindFirstChild("OriginalStamina")
                        if current and original then
                            current.Value = original.Value
                        end
                    end
                end
            end)
        end
    end
end)

local function ModifyPartCollision(part, noclipActive)
    if not part:IsA("BasePart") then return end
    local name = part.Name:lower()
    if name:find("floor") or name:find("ground") or name:find("base") then return end
    part.CanCollide = not noclipActive
end

local function ToggleNoclipSystem(enable)
    local cr = Workspace:FindFirstChild("CurrentRoom")
    if enable then
        if cr then
            task.spawn(function()
                for i, v in pairs(cr:GetDescendants()) do
                    ModifyPartCollision(v, true)
                    if i % 100 == 0 then task.wait() end
                end
            end)
        end
        if NoclipConnection then NoclipConnection:Disconnect() end
        NoclipConnection = Workspace.DescendantAdded:Connect(function(descendant)
            if NoclipEnabled and descendant:IsDescendantOf(Workspace:FindFirstChild("CurrentRoom")) then
                ModifyPartCollision(descendant, true)
            end
        end)
    else
        if NoclipConnection then
            NoclipConnection:Disconnect()
            NoclipConnection = nil
        end
        if cr then
            task.spawn(function()
                for i, v in pairs(cr:GetDescendants()) do
                    ModifyPartCollision(v, false)
                    if i % 100 == 0 then task.wait() end
                end
            end)
        end
    end
end

local function AttemptAutoSkillcheck()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not pGui then return end

    local screenGui = pGui:FindFirstChild("ScreenGui")
    if screenGui then
        local menu = screenGui:FindFirstChild("Menu")
        if menu then
            local skillFrame = menu:FindFirstChild("SkillCheckFrame")
            if skillFrame and skillFrame.Visible then
                local Marker = skillFrame:FindFirstChild("Marker")
                local GoldZone = skillFrame:FindFirstChild("GoldArea")
                if Marker and GoldZone and Marker.Visible and GoldZone.Visible then
                    local cursorX = Marker.AbsolutePosition.X
                    local goldX_Min = GoldZone.AbsolutePosition.X
                    local goldX_Max = GoldZone.AbsolutePosition.X + GoldZone.AbsoluteSize.X
                    if cursorX >= goldX_Min and cursorX <= goldX_Max then
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                        task.wait(1.5)
                    end
                end
            end
        end
    end

    local circleGui = pGui:FindFirstChild("CircleSkillCheckGui")
    if circleGui and circleGui.Enabled then
        local frame = circleGui:FindFirstChild("SkillCheckFrame")
        if frame then
            local container = frame:FindFirstChild("Container")
            if container then
                local shrinking = container:FindFirstChild("ShrinkingCircle")
                local yellow = container:FindFirstChild("YellowCircle")
                if shrinking and yellow and shrinking.Visible and yellow.Visible then
                    local sSize = shrinking.AbsoluteSize.X
                    local ySize = yellow.AbsoluteSize.X
                    if sSize <= ySize and sSize >= (ySize - 25) then
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                        task.wait(1)
                    end
                end
            end
        end
    end

    local treadmillGui = pGui:FindFirstChild("TreadmillTapSkillCheckGui")
    if treadmillGui and treadmillGui.Enabled then
        local viewportSize = workspace.CurrentCamera.ViewportSize
        VirtualInputManager:SendMouseButtonEvent(viewportSize.X / 2, viewportSize.Y / 2, 0, true, game, 1)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(viewportSize.X / 2, viewportSize.Y / 2, 0, false, game, 1)
        task.wait(math.random(5, 15) / 100)
    end
end

task.spawn(function()
    while task.wait(0.05) do
        if AutoSkillCheckEnabled then
            AttemptAutoSkillcheck()
        end
    end
end)

local PanicTeleported = false
task.spawn(function()
    while task.wait(0.5) do
        if AutoEscapeEnabled then
            pcall(function()
                local info = Workspace:FindFirstChild("Info")
                if info then
                    local panicVal = info:FindFirstChild("Panic")
                    if panicVal and panicVal.Value == true then
                        if not PanicTeleported then
                            local elevatorFolder = Workspace:FindFirstChild("Elevators")
                            if elevatorFolder then
                                local elevator = elevatorFolder:FindFirstChild("Elevator")
                                if elevator then
                                    local spawnZones = elevator:FindFirstChild("SpawnZones")
                                    if spawnZones and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                        local target = spawnZones:IsA("BasePart") and spawnZones or spawnZones:FindFirstChildOfClass("BasePart")
                                        if target then
                                            LocalPlayer.Character.HumanoidRootPart.CFrame = target.CFrame + Vector3.new(0, 3, 0)
                                            PanicTeleported = true
                                        end
                                    end
                                end
                            end
                        end
                    else
                        PanicTeleported = false
                    end
                end
            end)
        else
            PanicTeleported = false
        end
    end
end)

task.spawn(function()
    while task.wait(TpSafeCheckInterval) do
        if not TpSafeEnabled then
            continue
        end

        if tick() - TpSafeLastTrigger < TpSafeCooldown then
            continue
        end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            continue
        end

        local safe, dangerObj, dangerDistance, dangerType = IsSafeFromTwisteds(hrp.Position, TpSafeDangerDistance, {
            CheckConnieMachine = true,
            CheckBlotHands = true,
        })

        if not safe then
            PerformTpSafe(GetTpSafeThreatText(dangerObj, dangerDistance, dangerType))
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        if WalkSpeedEnabled then
            if hum.WalkSpeed < WalkSpeedValue then
                hum.WalkSpeed = WalkSpeedValue
            end
        end
    end
end)


--// FLOOR + RESEARCH WATCHERS
local FloorIntelState = {
    LastFloor = nil,
    LastMainTier = nil,
    CurrentText = "Floor intel: waiting...",
}

local ResearchWatchState = {
    Folder = nil,
    Connections = {},
    LastValues = {},
    LastChangedText = "Sin cambios",
}

local function ParseFloorNumber(text)
    text = tostring(text or "")
    local n = text:match("%d+")
    return tonumber(n)
end

local function Round2(n)
    return math.floor((tonumber(n) or 0) * 100 + 0.5) / 100
end

local function GetSpectatorFloorLabel()
    local spectatorGui = PlayerGui:FindFirstChild("SpectatorGui")
    local infoFrame = spectatorGui and spectatorGui:FindFirstChild("InfoFrame")
    return infoFrame and infoFrame:FindFirstChild("FloorNumber") or nil
end

local function GetTwistedRarityStatsForFloor(floor)
    floor = tonumber(floor) or 1

    local commonWeight = 75
    local uncommonWeight = 25
    local rareWeight = 10
    local mainWeight = 0

    if floor >= 5 then
        rareWeight = rareWeight + math.floor((floor - 5) / 2) + 1
        mainWeight = 4 * (math.floor((floor - 5) / 5) + 1)
    end

    local total = commonWeight + uncommonWeight + rareWeight + mainWeight

    return {
        Floor = floor,
        CommonChance = Round2((commonWeight / total) * 100),
        UncommonChance = Round2((uncommonWeight / total) * 100),
        RareChance = Round2((rareWeight / total) * 100),
        MainChance = Round2((mainWeight / total) * 100),
        MainWeight = mainWeight,
        MainTier = floor >= 5 and (math.floor((floor - 5) / 5) + 1) or 0,
        MainUnlocked = floor >= 5,
    }
end

local function BuildFloorIntelTextFromFloor(floor)
    if not floor then
        return "Floor intel: spectator floor not found"
    end

    local stats = GetTwistedRarityStatsForFloor(floor)
    if not stats.MainUnlocked then
        return string.format(
            "Floor %d | Main: 0%% | faltan %d pisos para Main",
            floor,
            math.max(0, 5 - floor)
        )
    end

    local nextTierFloor = ((stats.MainTier) * 5) + 5
    local floorsLeft = math.max(0, nextTierFloor - floor)
    return string.format(
        "Floor %d | Main ~%.2f%% | Rare ~%.2f%% | siguiente boost Main en %d piso(s)",
        floor,
        stats.MainChance,
        stats.RareChance,
        floorsLeft
    )
end

local function UpdateFloorIntelNotifier()
    local floorLabel = GetSpectatorFloorLabel()
    local floor = floorLabel and ParseFloorNumber(floorLabel.Text) or nil
    FloorIntelState.CurrentText = BuildFloorIntelTextFromFloor(floor)

    if not floor or floor == FloorIntelState.LastFloor then
        return
    end

    FloorIntelState.LastFloor = floor
    local stats = GetTwistedRarityStatsForFloor(floor)

    if Library and Library.Notify then
        Library:Notify("Floor Intel", FloorIntelState.CurrentText, 5)
    end

    if stats.MainTier ~= FloorIntelState.LastMainTier then
        FloorIntelState.LastMainTier = stats.MainTier
        if Library and Library.Notify then
            if stats.MainTier <= 0 then
                Library:Notify("Main Twisteds", "Todavía bloqueados. Empiezan desde floor 5.", 5)
            else
                Library:Notify(
                    "Main Twisteds UP",
                    string.format("Floor %d | tier %d | Main ~%.2f%%", floor, stats.MainTier, stats.MainChance),
                    6
                )
            end
        end
    end
end

local function DisconnectResearchWatcher()
    for _, conn in ipairs(ResearchWatchState.Connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    ResearchWatchState.Connections = {}
end

local function ClampResearchValue(v)
    return math.clamp(math.floor(tonumber(v) or 0), 0, 100)
end

local function FormatResearchMonsterName(name)
    name = tostring(name or "")
    name = name:gsub("Monster$", "")
    if name == "Blott" then
        return "Blot"
    elseif name == "RazzleDazzle" then
        return "Razzle & Dazzle"
    end
    return name
end

local function GetResearchFolder()
    local playerData = ReplicatedStorage:FindFirstChild("PlayerData")
    if not playerData then return nil end

    local myData = playerData:FindFirstChild(tostring(LocalPlayer.UserId))
    if not myData then return nil end

    return myData:FindFirstChild("Research")
end

local function SetResearchBaseline()
    ResearchWatchState.Folder = GetResearchFolder()
    ResearchWatchState.LastValues = {}

    if not ResearchWatchState.Folder then
        return
    end

    for _, child in ipairs(ResearchWatchState.Folder:GetChildren()) do
        if child:IsA("NumberValue") then
            ResearchWatchState.LastValues[child.Name] = ClampResearchValue(child.Value)
        end
    end
end

local function NotifyResearchIncrease(numberValue)
    if not numberValue or not numberValue:IsA("NumberValue") then
        return
    end

    local name = numberValue.Name
    local oldValue = ClampResearchValue(ResearchWatchState.LastValues[name] or 0)
    local newValue = ClampResearchValue(numberValue.Value)
    ResearchWatchState.LastValues[name] = newValue

    if newValue <= oldValue then
        return
    end

    local gained = newValue - oldValue
    local missing = math.max(0, 100 - newValue)
    local displayName = FormatResearchMonsterName(name)

    if newValue >= 100 then
        ResearchWatchState.LastChangedText = string.format("%s completado (%d/100, +%d)", displayName, newValue, gained)
        if Library and Library.Notify then
            Library:Notify("Research Complete", string.format("%s llegó a %d/100", displayName, newValue), 5)
        end
    else
        ResearchWatchState.LastChangedText = string.format("%s subió a %d/100 (+%d) | faltan %d", displayName, newValue, gained, missing)
        if Library and Library.Notify then
            Library:Notify("Research Up", string.format("%s: %d/100 (+%d) | faltan %d", displayName, newValue, gained, missing), 5)
        end
    end
end

local function ConnectResearchValue(numberValue)
    if not numberValue or not numberValue:IsA("NumberValue") then
        return
    end

    ResearchWatchState.LastValues[numberValue.Name] = ClampResearchValue(numberValue.Value)

    local conn = numberValue:GetPropertyChangedSignal("Value"):Connect(function()
        NotifyResearchIncrease(numberValue)
    end)
    table.insert(ResearchWatchState.Connections, conn)
end

local function StartResearchWatcher()
    DisconnectResearchWatcher()
    SetResearchBaseline()

    local folder = ResearchWatchState.Folder
    if not folder then
        ResearchWatchState.LastChangedText = "Research no encontrado"
        return
    end

    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("NumberValue") then
            ConnectResearchValue(child)
        end
    end

    local addedConn = folder.ChildAdded:Connect(function(child)
        if child:IsA("NumberValue") then
            ConnectResearchValue(child)
        end
    end)

    local removedConn = folder.ChildRemoved:Connect(function(child)
        if child and child:IsA("NumberValue") then
            ResearchWatchState.LastValues[child.Name] = nil
        end
    end)

    table.insert(ResearchWatchState.Connections, addedConn)
    table.insert(ResearchWatchState.Connections, removedConn)
end

local function BuildResearchOverviewText()
    local folder = GetResearchFolder()
    if not folder then
        return "Research: no encontrado\nÚltimo cambio: " .. tostring(ResearchWatchState.LastChangedText)
    end

    local total = 0
    local completed = 0
    local closestName = "Ninguno"
    local closestValue = 0
    local closestMissing = 100

    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("NumberValue") then
            total = total + 1
            local value = ClampResearchValue(child.Value)
            local missing = math.max(0, 100 - value)

            if value >= 100 then
                completed = completed + 1
            elseif missing < closestMissing then
                closestMissing = missing
                closestValue = value
                closestName = FormatResearchMonsterName(child.Name)
            end
        end
    end

    local pending = total - completed
    local nearestText
    if pending <= 0 then
        nearestText = "Todos completos"
    else
        nearestText = string.format("%s (%d/100, faltan %d)", closestName, closestValue, closestMissing)
    end

    return string.format(
        "Research completos: %d/%d\nMás cercano a 100: %s\nÚltimo cambio: %s",
        completed,
        total,
        nearestText,
        tostring(ResearchWatchState.LastChangedText)
    )
end

function Library:Init()
    if PlayerGui:FindFirstChild("DandysWorld_macOS") then
        PlayerGui.DandysWorld_macOS:Destroy()
    end

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "DandysWorld_macOS"
    ScreenGui.Parent = PlayerGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true

    local WelcomeBlur = Instance.new("Frame")
    WelcomeBlur.Size = UDim2.new(1, 0, 1, 0)
    WelcomeBlur.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    WelcomeBlur.BackgroundTransparency = 0.5
    WelcomeBlur.Parent = ScreenGui

    local WelcomeFrame = Instance.new("Frame")
    WelcomeFrame.Name = "WelcomeFrame"
    WelcomeFrame.Size = UDim2.new(0, 0, 0, 0)
    WelcomeFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    WelcomeFrame.BackgroundColor3 = Theme.Background
    WelcomeFrame.BorderSizePixel = 0
    WelcomeFrame.ClipsDescendants = true
    WelcomeFrame.Parent = ScreenGui

    local WelcomeCorner = Instance.new("UICorner", WelcomeFrame)
    WelcomeCorner.CornerRadius = Theme.CornerRadius

    local WelcomeStroke = Instance.new("UIStroke", WelcomeFrame)
    WelcomeStroke.Color = Theme.Accent
    WelcomeStroke.Thickness = 2

    local Avatar = Instance.new("ImageLabel")
    Avatar.Size = UDim2.new(0, 80, 0, 80)
    Avatar.Position = UDim2.new(0.5, -40, 0.2, 0)
    Avatar.BackgroundTransparency = 1
    Avatar.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
    Avatar.Parent = WelcomeFrame
    Instance.new("UICorner", Avatar).CornerRadius = UDim.new(1, 0)

    local WelcomeText = Instance.new("TextLabel")
    WelcomeText.Text = "Welcome Back, " .. LocalPlayer.DisplayName
    WelcomeText.Size = UDim2.new(1, 0, 0, 25)
    WelcomeText.Position = UDim2.new(0, 0, 0.6, 0)
    WelcomeText.BackgroundTransparency = 1
    WelcomeText.TextColor3 = Theme.Text
    WelcomeText.Font = Enum.Font.GothamBold
    WelcomeText.TextSize = 18
    WelcomeText.Parent = WelcomeFrame

    local LoadingText = Instance.new("TextLabel")
    LoadingText.Text = "Initializing..."
    LoadingText.Size = UDim2.new(1, 0, 0, 20)
    LoadingText.Position = UDim2.new(0, 0, 0.75, 0)
    LoadingText.BackgroundTransparency = 1
    LoadingText.TextColor3 = Theme.TextDim
    LoadingText.Font = Enum.Font.Gotham
    LoadingText.TextSize = 14
    LoadingText.Parent = WelcomeFrame

    TweenService:Create(WelcomeFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 320, 0, 200),
        Position = UDim2.new(0.5, -160, 0.5, -100)
    }):Play()

    task.wait(1)
    LoadingText.Text = "Loading Assets..."
    task.wait(0.8)
    LoadingText.Text = "Injecting..."
    task.wait(0.8)

    TweenService:Create(WelcomeFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }):Play()
    TweenService:Create(WelcomeBlur, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
    task.wait(0.4)
    WelcomeFrame:Destroy()
    WelcomeBlur:Destroy()

    NotificationHolder = Instance.new("Frame")
    NotificationHolder.Name = "Notifications"
    NotificationHolder.Size = UDim2.new(0, 250, 1, -20)
    NotificationHolder.Position = UDim2.new(1, -270, 0, 10)
    NotificationHolder.BackgroundTransparency = 1
    NotificationHolder.Parent = ScreenGui

    local UIList = Instance.new("UIListLayout")
    UIList.Padding = UDim.new(0, 5)
    UIList.VerticalAlignment = Enum.VerticalAlignment.Bottom
    UIList.Parent = NotificationHolder

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "Window"
    MainFrame.Size = UDim2.new(0, 80, 0, 45)
    MainFrame.Position = UDim2.new(0.5, -40, 0.5, -22)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BackgroundTransparency = 1
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Theme.Stroke
    MainStroke.Thickness = 1
    MainStroke.Parent = MainFrame

    TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 650, 0, 420),
        Position = UDim2.new(0.5, -325, 0.5, -210),
        BackgroundTransparency = 0.05
    }):Play()

    local MainCorner = Instance.new("UICorner", MainFrame)
    MainCorner.CornerRadius = Theme.CornerRadius

    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0, 180, 1, 0)
    Sidebar.BackgroundColor3 = Theme.Sidebar
    Sidebar.BackgroundTransparency = 0
    Sidebar.Parent = MainFrame
    Instance.new("UICorner", Sidebar).CornerRadius = Theme.CornerRadius

    local SidebarFix = Instance.new("Frame")
    SidebarFix.Size = UDim2.new(0, 10, 1, 0)
    SidebarFix.Position = UDim2.new(1, -10, 0, 0)
    SidebarFix.BackgroundColor3 = Theme.Sidebar
    SidebarFix.BorderSizePixel = 0
    SidebarFix.Parent = Sidebar

    local SidebarGradient = Instance.new("UIGradient")
    SidebarGradient.Rotation = 45
    SidebarGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Theme.Sidebar)
    }
    SidebarGradient.Parent = Sidebar

    local DragZone = Instance.new("Frame")
    DragZone.Size = UDim2.new(1, 0, 0, 40)
    DragZone.BackgroundTransparency = 1
    DragZone.Parent = MainFrame

    local Dragging, DragInput, DragStart, StartPos
    DragZone.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPos = MainFrame.Position
        end
    end)
    DragZone.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            DragInput = input
        end
    end)
    RunService.RenderStepped:Connect(function()
        if Dragging and DragInput then
            local Delta = DragInput.Position - DragStart
            MainFrame.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
        end
    end)

    local ContentPageHolder = Instance.new("Frame")
    ContentPageHolder.Size = UDim2.new(1, -180, 1, 0)
    ContentPageHolder.Position = UDim2.new(0, 180, 0, 0)
    ContentPageHolder.BackgroundTransparency = 1
    ContentPageHolder.Parent = MainFrame

    local ControlsHolder = Instance.new("Frame")
    ControlsHolder.Size = UDim2.new(0, 60, 0, 20)
    ControlsHolder.Position = UDim2.new(0, 18, 0, 18)
    ControlsHolder.BackgroundTransparency = 1
    ControlsHolder.Parent = MainFrame

    local function CreateDot(color, offset)
        local Dot = Instance.new("Frame")
        Dot.Size = UDim2.new(0, 12, 0, 12)
        Dot.Position = UDim2.new(0, offset, 0, 0)
        Dot.BackgroundColor3 = color
        Dot.Parent = ControlsHolder
        Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

        local Btn = Instance.new("TextButton", Dot)
        Btn.Size = UDim2.new(1, 0, 1, 0)
        Btn.BackgroundTransparency = 1
        Btn.Text = ""
        Btn.MouseEnter:Connect(function() PlayAudio("Hover") end)
        Btn.MouseButton1Click:Connect(function() PlayAudio("Click") end)
        return Btn
    end

    local CloseBtn = CreateDot(Theme.Destructive, 0)
    local HideBtn = CreateDot(Theme.Gold, 20)
    local OpenBtn = CreateDot(Theme.Success, 40)

    local function ShowCloseConfirmation()
        local ConfirmBlur = Instance.new("Frame")
        ConfirmBlur.Size = UDim2.new(1, 0, 1, 0)
        ConfirmBlur.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        ConfirmBlur.BackgroundTransparency = 1
        ConfirmBlur.ZIndex = 10
        ConfirmBlur.Parent = ScreenGui
        TweenService:Create(ConfirmBlur, TweenInfo.new(0.3), {BackgroundTransparency = 0.6}):Play()

        local AlertFrame = Instance.new("Frame")
        AlertFrame.Size = UDim2.new(0, 0, 0, 0)
        AlertFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        AlertFrame.BackgroundColor3 = Theme.Background
        AlertFrame.ClipsDescendants = true
        AlertFrame.ZIndex = 11
        AlertFrame.Parent = ConfirmBlur
        Instance.new("UICorner", AlertFrame).CornerRadius = Theme.CornerRadius
        Instance.new("UIStroke", AlertFrame).Color = Theme.Stroke

        local AlertTitle = Instance.new("TextLabel")
        AlertTitle.Text = "Exit Script?"
        AlertTitle.Size = UDim2.new(1, 0, 0, 30)
        AlertTitle.Position = UDim2.new(0, 0, 0, 15)
        AlertTitle.BackgroundTransparency = 1
        AlertTitle.TextColor3 = Theme.Text
        AlertTitle.Font = Enum.Font.GothamBold
        AlertTitle.TextSize = 18
        AlertTitle.ZIndex = 12
        AlertTitle.Parent = AlertFrame

        local AlertMsg = Instance.new("TextLabel")
        AlertMsg.Text = "Are you sure you want to close the menu?"
        AlertMsg.Size = UDim2.new(1, 0, 0, 20)
        AlertMsg.Position = UDim2.new(0, 0, 0, 45)
        AlertMsg.BackgroundTransparency = 1
        AlertMsg.TextColor3 = Theme.TextDim
        AlertMsg.Font = Enum.Font.Gotham
        AlertMsg.TextSize = 14
        AlertMsg.ZIndex = 12
        AlertMsg.Parent = AlertFrame

        local YesBtn = Instance.new("TextButton")
        YesBtn.Text = "Yes"
        YesBtn.Size = UDim2.new(0.4, 0, 0, 35)
        YesBtn.Position = UDim2.new(0.05, 0, 0.7, 0)
        YesBtn.BackgroundColor3 = Theme.Destructive
        YesBtn.TextColor3 = Color3.new(1, 1, 1)
        YesBtn.Font = Enum.Font.GothamBold
        YesBtn.TextSize = 14
        YesBtn.ZIndex = 12
        YesBtn.Parent = AlertFrame
        Instance.new("UICorner", YesBtn).CornerRadius = UDim.new(0, 8)
        YesBtn.MouseEnter:Connect(function() PlayAudio("Hover") end)

        local NoBtn = Instance.new("TextButton")
        NoBtn.Text = "No"
        NoBtn.Size = UDim2.new(0.4, 0, 0, 35)
        NoBtn.Position = UDim2.new(0.55, 0, 0.7, 0)
        NoBtn.BackgroundColor3 = Theme.Sidebar
        NoBtn.TextColor3 = Theme.Text
        NoBtn.Font = Enum.Font.GothamBold
        NoBtn.TextSize = 14
        NoBtn.ZIndex = 12
        NoBtn.Parent = AlertFrame
        Instance.new("UICorner", NoBtn).CornerRadius = UDim.new(0, 8)
        NoBtn.MouseEnter:Connect(function() PlayAudio("Hover") end)

        TweenService:Create(AlertFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
            Size = UDim2.new(0, 280, 0, 160),
            Position = UDim2.new(0.5, -140, 0.5, -80)
        }):Play()

        YesBtn.MouseButton1Click:Connect(function()
            PlayAudio("Click")
            TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}):Play()
            TweenService:Create(AlertFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}):Play()
            TweenService:Create(ConfirmBlur, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            task.wait(0.3)
            ScreenGui:Destroy()
        end)

        NoBtn.MouseButton1Click:Connect(function()
            PlayAudio("Click")
            TweenService:Create(AlertFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0)
            }):Play()
            TweenService:Create(ConfirmBlur, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            task.wait(0.3)
            ConfirmBlur:Destroy()
        end)
    end

    CloseBtn.MouseButton1Click:Connect(ShowCloseConfirmation)

    HideBtn.MouseButton1Click:Connect(function()
        IsMenuOpen = false
        TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 80, 0, 45)}):Play()
        Sidebar.Visible = false
        ContentPageHolder.Visible = false
    end)

    OpenBtn.MouseButton1Click:Connect(function()
        IsMenuOpen = true
        TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back), {Size = UDim2.new(0, 650, 0, 420)}):Play()
        task.wait(0.1)
        Sidebar.Visible = true
        ContentPageHolder.Visible = true
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if IsSettingKeybind then return end

        if input.KeyCode == ToggleKey then
            if IsMenuOpen then
                IsMenuOpen = false
                TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 80, 0, 45)}):Play()
                Sidebar.Visible = false
                ContentPageHolder.Visible = false
            else
                IsMenuOpen = true
                TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back), {Size = UDim2.new(0, 650, 0, 420)}):Play()
                task.wait(0.1)
                Sidebar.Visible = true
                ContentPageHolder.Visible = true
            end
        end
    end)

    local Title = Instance.new("TextLabel")
    Title.Text = "Dandy's World Utility"
    Title.TextColor3 = Theme.TextDim
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 13
    Title.Size = UDim2.new(1, -40, 0, 20)
    Title.Position = UDim2.new(0, 20, 0, 60)
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Sidebar

    local ProfileFrame = Instance.new("Frame")
    ProfileFrame.Name = "ProfileFrame"
    ProfileFrame.Size = UDim2.new(1, -24, 0, 50)
    ProfileFrame.Position = UDim2.new(0, 12, 1, -62)
    ProfileFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ProfileFrame.BackgroundTransparency = 0.5
    ProfileFrame.Parent = Sidebar
    Instance.new("UICorner", ProfileFrame).CornerRadius = UDim.new(0, 10)

    local ProfileStroke = Instance.new("UIStroke", ProfileFrame)
    ProfileStroke.Color = Theme.Stroke
    ProfileStroke.Transparency = 0.5

    local ProfileImage = Instance.new("ImageLabel")
    ProfileImage.Name = "Avatar"
    ProfileImage.Size = UDim2.new(0, 36, 0, 36)
    ProfileImage.Position = UDim2.new(0, 7, 0.5, -18)
    ProfileImage.BackgroundTransparency = 1
    ProfileImage.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
    ProfileImage.Parent = ProfileFrame
    Instance.new("UICorner", ProfileImage).CornerRadius = UDim.new(1, 0)

    local OnlineDot = Instance.new("Frame")
    OnlineDot.Size = UDim2.new(0, 10, 0, 10)
    OnlineDot.Position = UDim2.new(0, 34, 0, 26)
    OnlineDot.BackgroundColor3 = Theme.Success
    OnlineDot.BorderSizePixel = 0
    OnlineDot.Parent = ProfileFrame
    Instance.new("UICorner", OnlineDot).CornerRadius = UDim.new(1, 0)

    local DotStroke = Instance.new("UIStroke", OnlineDot)
    DotStroke.Color = Theme.Sidebar
    DotStroke.Thickness = 2

    local DisplayNameLabel = Instance.new("TextLabel")
    DisplayNameLabel.Name = "DName"
    DisplayNameLabel.Size = UDim2.new(1, -50, 0, 18)
    DisplayNameLabel.Position = UDim2.new(0, 50, 0, 8)
    DisplayNameLabel.BackgroundTransparency = 1
    DisplayNameLabel.Text = LocalPlayer.DisplayName
    DisplayNameLabel.TextColor3 = Theme.Text
    DisplayNameLabel.Font = Enum.Font.GothamBold
    DisplayNameLabel.TextSize = 12
    DisplayNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    DisplayNameLabel.Parent = ProfileFrame

    local UserNameLabel = Instance.new("TextLabel")
    UserNameLabel.Name = "UName"
    UserNameLabel.Size = UDim2.new(1, -50, 0, 14)
    UserNameLabel.Position = UDim2.new(0, 50, 0, 26)
    UserNameLabel.BackgroundTransparency = 1
    UserNameLabel.Text = "@" .. LocalPlayer.Name
    UserNameLabel.TextColor3 = Theme.TextDim
    UserNameLabel.Font = Enum.Font.Gotham
    UserNameLabel.TextSize = 11
    UserNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    UserNameLabel.Parent = ProfileFrame

    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Size = UDim2.new(1, -20, 1, -160)
    TabContainer.Position = UDim2.new(0, 10, 0, 90)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ScrollBarThickness = 0
    TabContainer.Parent = Sidebar
    Instance.new("UIListLayout", TabContainer).Padding = UDim.new(0, 5)

    local Tabs = {}
    local FirstTab = true

    function Tabs:CreateTab(Name, Icon)
        local TabData = {}

        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(1, 0, 0, 36)
        TabBtn.BackgroundTransparency = 1
        TabBtn.Text = "    " .. (Icon or "") .. "  " .. Name
        TabBtn.TextColor3 = Theme.TextDim
        TabBtn.Font = Enum.Font.GothamMedium
        TabBtn.TextSize = 14
        TabBtn.TextXAlignment = Enum.TextXAlignment.Left
        TabBtn.Parent = TabContainer
        Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 8)

        TabBtn.MouseEnter:Connect(function() PlayAudio("Hover") end)

        local Page = Instance.new("ScrollingFrame")
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.Visible = false
        Page.ScrollBarThickness = 0
        Page.Parent = ContentPageHolder
        Instance.new("UIListLayout", Page).Padding = UDim.new(0, 10)
        local Pad = Instance.new("UIPadding", Page)
        Pad.PaddingTop = UDim.new(0, 20)
        Pad.PaddingLeft = UDim.new(0, 20)
        Pad.PaddingRight = UDim.new(0, 20)

        local function Activate()
            PlayAudio("Click")
            for _, c in pairs(TabContainer:GetChildren()) do
                if c:IsA("TextButton") then
                    TweenService:Create(c, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextColor3 = Theme.TextDim}):Play()
                end
            end
            for _, c in pairs(ContentPageHolder:GetChildren()) do
                if c:IsA("ScrollingFrame") then
                    c.Visible = false
                end
            end
            Page.Visible = true
            TweenService:Create(TabBtn, TweenInfo.new(0.3), {BackgroundTransparency = 0.85, TextColor3 = Theme.Text}):Play()
            TabBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        end

        TabBtn.MouseButton1Click:Connect(function()
            Activate()
        end)

        if FirstTab then
            Activate()
            FirstTab = false
        end

        function TabData:CreateToggle(Text, Callback, Default)
            local ToggleFrame = Instance.new("Frame", Page)
            ToggleFrame.Size = UDim2.new(1, 0, 0, 44)
            ToggleFrame.BackgroundColor3 = Theme.Sidebar
            ToggleFrame.BackgroundTransparency = 0.5
            Instance.new("UICorner", ToggleFrame).CornerRadius = UDim.new(0, 10)

            local ToggleStroke = Instance.new("UIStroke", ToggleFrame)
            ToggleStroke.Color = Theme.Stroke
            ToggleStroke.Transparency = 0.5

            local Label = Instance.new("TextLabel", ToggleFrame)
            Label.Text = "  " .. Text
            Label.Size = UDim2.new(0.7, 0, 1, 0)
            Label.BackgroundTransparency = 1
            Label.TextColor3 = Theme.Text
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left

            local SwitchBg = Instance.new("Frame", ToggleFrame)
            SwitchBg.Size = UDim2.new(0, 44, 0, 24)
            SwitchBg.Position = UDim2.new(1, -55, 0.5, -12)
            SwitchBg.BackgroundColor3 = Default and Theme.Accent or Color3.fromRGB(230, 200, 210)
            Instance.new("UICorner", SwitchBg).CornerRadius = UDim.new(1, 0)

            local SwitchCircle = Instance.new("Frame", SwitchBg)
            SwitchCircle.Size = UDim2.new(0, 20, 0, 20)
            SwitchCircle.Position = Default and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
            SwitchCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Instance.new("UICorner", SwitchCircle).CornerRadius = UDim.new(1, 0)

            local Toggled = Default or false
            local Control = {}

            function Control:GetValue()
                return Toggled
            end

            function Control:SetValue(NewValue, SkipCallback)
                Toggled = NewValue and true or false
                SwitchBg.BackgroundColor3 = Toggled and Theme.Accent or Color3.fromRGB(230, 200, 210)
                SwitchCircle.Position = Toggled and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
                if not SkipCallback then
                    Callback(Toggled)
                end
            end

            local Trigger = Instance.new("TextButton", ToggleFrame)
            Trigger.Size = UDim2.new(1, 0, 1, 0)
            Trigger.BackgroundTransparency = 1
            Trigger.Text = ""
            Trigger.MouseEnter:Connect(function() PlayAudio("Hover") end)

            Trigger.MouseButton1Click:Connect(function()
                PlayAudio("Click")
                Toggled = not Toggled
                TweenService:Create(SwitchBg, TweenInfo.new(0.3), {BackgroundColor3 = Toggled and Theme.Accent or Color3.fromRGB(230, 200, 210)}):Play()
                TweenService:Create(SwitchCircle, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = Toggled and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)}):Play()
                Library:Notify("Toggle Update", Text .. " has been " .. (Toggled and "Enabled" or "Disabled"), 2)
                Callback(Toggled)
            end)

            return Control
        end

        function TabData:CreateSlider(Text, Min, Max, Default, Callback)
            local SliderFrame = Instance.new("Frame", Page)
            SliderFrame.Size = UDim2.new(1, 0, 0, 55)
            SliderFrame.BackgroundColor3 = Theme.Sidebar
            SliderFrame.BackgroundTransparency = 0.5
            Instance.new("UICorner", SliderFrame).CornerRadius = UDim.new(0, 10)

            local SliderStroke = Instance.new("UIStroke", SliderFrame)
            SliderStroke.Color = Theme.Stroke
            SliderStroke.Transparency = 0.5

            local Label = Instance.new("TextLabel", SliderFrame)
            Label.Text = "  " .. Text .. ": " .. Default
            Label.Size = UDim2.new(1, 0, 0, 25)
            Label.BackgroundTransparency = 1
            Label.TextColor3 = Theme.Text
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left

            local SliderBar = Instance.new("Frame", SliderFrame)
            SliderBar.Size = UDim2.new(1, -40, 0, 4)
            SliderBar.Position = UDim2.new(0, 20, 0, 38)
            SliderBar.BackgroundColor3 = Color3.fromRGB(230, 200, 210)
            Instance.new("UICorner", SliderBar)

            local SliderFill = Instance.new("Frame", SliderBar)
            SliderFill.Size = UDim2.new((Default - Min) / (Max - Min), 0, 1, 0)
            SliderFill.BackgroundColor3 = Theme.Accent
            Instance.new("UICorner", SliderFill)

            local SliderBtn = Instance.new("Frame", SliderFill)
            SliderBtn.Size = UDim2.new(0, 12, 0, 12)
            SliderBtn.Position = UDim2.new(1, -6, 0.5, -6)
            SliderBtn.BackgroundColor3 = Color3.new(1, 1, 1)
            Instance.new("UICorner", SliderBtn).CornerRadius = UDim.new(1, 0)

            local CurrentValue = Default
            local Control = {}

            function Control:GetValue()
                return CurrentValue
            end

            function Control:SetValue(NewValue, SkipCallback)
                CurrentValue = math.clamp(math.floor(tonumber(NewValue) or Default), Min, Max)
                local size = (CurrentValue - Min) / (Max - Min)
                SliderFill.Size = UDim2.new(size, 0, 1, 0)
                Label.Text = "  " .. Text .. ": " .. CurrentValue
                if not SkipCallback then
                    Callback(CurrentValue)
                end
            end

            local function UpdateSlider(Input)
                local Size = math.clamp((Input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                local Value = math.floor(Min + (Max - Min) * Size)
                Control:SetValue(Value)
            end

            SliderBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    UpdateSlider(input)
                    local Connection
                    Connection = UserInputService.InputChanged:Connect(function(input2)
                        if input2.UserInputType == Enum.UserInputType.MouseMovement or input2.UserInputType == Enum.UserInputType.Touch then
                            UpdateSlider(input2)
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(input2)
                        if input2.UserInputType == Enum.UserInputType.MouseButton1 or input2.UserInputType == Enum.UserInputType.Touch then
                            Connection:Disconnect()
                        end
                    end)
                end
            end)

            return Control
        end

        function TabData:CreateLabel(Text, Height)
            local LabelFrame = Instance.new("Frame", Page)
            LabelFrame.Size = UDim2.new(1, 0, 0, Height or 50)
            LabelFrame.BackgroundColor3 = Theme.Sidebar
            LabelFrame.BackgroundTransparency = 0.5
            Instance.new("UICorner", LabelFrame).CornerRadius = UDim.new(0, 10)

            local LabelStroke = Instance.new("UIStroke", LabelFrame)
            LabelStroke.Color = Theme.Stroke
            LabelStroke.Transparency = 0.5

            local Label = Instance.new("TextLabel", LabelFrame)
            Label.Size = UDim2.new(1, -20, 1, -12)
            Label.Position = UDim2.new(0, 10, 0, 6)
            Label.BackgroundTransparency = 1
            Label.Text = Text
            Label.TextWrapped = true
            Label.TextYAlignment = Enum.TextYAlignment.Top
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 13
            Label.TextColor3 = Theme.Text

            local Control = {}
            function Control:SetText(NewText)
                Label.Text = NewText
            end
            function Control:GetText()
                return Label.Text
            end
            return Control
        end

        function TabData:CreateButton(Text, Callback)
            local ButtonFrame = Instance.new("Frame", Page)
            ButtonFrame.Size = UDim2.new(1, 0, 0, 40)
            ButtonFrame.BackgroundColor3 = Theme.Accent
            ButtonFrame.BackgroundTransparency = 0.2
            Instance.new("UICorner", ButtonFrame).CornerRadius = UDim.new(0, 10)

            local Gradient = Instance.new("UIGradient")
            Gradient.Rotation = 90
            Gradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1, Theme.Accent)
            }
            Gradient.Transparency = NumberSequence.new{
                NumberSequenceKeypoint.new(0, 0.7),
                NumberSequenceKeypoint.new(1, 0.1)
            }
            Gradient.Parent = ButtonFrame

            local BtnStroke = Instance.new("UIStroke", ButtonFrame)
            BtnStroke.Color = Color3.fromRGB(255, 255, 255)
            BtnStroke.Transparency = 0.6
            BtnStroke.Thickness = 1

            local Btn = Instance.new("TextButton", ButtonFrame)
            Btn.Size = UDim2.new(1, 0, 1, 0)
            Btn.BackgroundTransparency = 1
            Btn.Text = Text
            Btn.TextColor3 = Theme.Text
            Btn.Font = Enum.Font.GothamBold
            Btn.TextSize = 14
            Btn.MouseEnter:Connect(function() PlayAudio("Hover") end)

            Btn.MouseButton1Click:Connect(function()
                PlayAudio("Click")
                Callback()
            end)
            return Btn
        end

        function TabData:CreatePlayerList()
            local DropdownFrame = Instance.new("Frame", Page)
            DropdownFrame.Size = UDim2.new(1, 0, 0, 40)
            DropdownFrame.BackgroundColor3 = Theme.Accent
            DropdownFrame.BackgroundTransparency = 0.2
            Instance.new("UICorner", DropdownFrame).CornerRadius = UDim.new(0, 10)

            local Gradient = Instance.new("UIGradient", DropdownFrame)
            Gradient.Rotation = 90
            Gradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1, Theme.Accent)
            }
            Gradient.Transparency = NumberSequence.new{
                NumberSequenceKeypoint.new(0, 0.7),
                NumberSequenceKeypoint.new(1, 0.1)
            }
            Gradient.Parent = DropdownFrame

            local BtnStroke = Instance.new("UIStroke", DropdownFrame)
            BtnStroke.Color = Color3.fromRGB(255, 255, 255)
            BtnStroke.Transparency = 0.6
            BtnStroke.Thickness = 1

            local ToggleBtn = Instance.new("TextButton", DropdownFrame)
            ToggleBtn.Size = UDim2.new(1, 0, 0, 40)
            ToggleBtn.BackgroundTransparency = 1
            ToggleBtn.Text = "Select Player to Teleport ▼"
            ToggleBtn.TextColor3 = Theme.Text
            ToggleBtn.Font = Enum.Font.GothamBold
            ToggleBtn.TextSize = 14

            local ListContainer = Instance.new("ScrollingFrame", DropdownFrame)
            ListContainer.Size = UDim2.new(1, 0, 1, -40)
            ListContainer.Position = UDim2.new(0, 0, 0, 40)
            ListContainer.BackgroundTransparency = 1
            ListContainer.Visible = false
            ListContainer.BorderSizePixel = 0
            ListContainer.ScrollBarThickness = 2

            local UIListInner = Instance.new("UIListLayout", ListContainer)
            UIListInner.Padding = UDim.new(0, 5)
            local PadInner = Instance.new("UIPadding", ListContainer)
            PadInner.PaddingTop = UDim.new(0, 10)
            PadInner.PaddingLeft = UDim.new(0, 10)
            PadInner.PaddingRight = UDim.new(0, 10)

            local IsOpen = false

            local function RefreshList()
                for _, v in pairs(ListContainer:GetChildren()) do
                    if v:IsA("TextButton") then
                        v:Destroy()
                    end
                end

                for _, v in pairs(Players:GetPlayers()) do
                    if v ~= LocalPlayer then
                        local PBtn = Instance.new("TextButton", ListContainer)
                        PBtn.Size = UDim2.new(1, 0, 0, 30)
                        PBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        PBtn.BackgroundTransparency = 0.3
                        PBtn.Text = "  " .. v.DisplayName .. " (@" .. v.Name .. ")"
                        PBtn.TextColor3 = Theme.Text
                        PBtn.Font = Enum.Font.GothamMedium
                        PBtn.TextSize = 12
                        PBtn.TextXAlignment = Enum.TextXAlignment.Left
                        Instance.new("UICorner", PBtn).CornerRadius = UDim.new(0, 6)

                        PBtn.MouseButton1Click:Connect(function()
                            PlayAudio("Click")
                            if v.Character and v.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                LocalPlayer.Character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame
                                Library:Notify("Teleport", "Teleported to " .. v.DisplayName, 2)
                            end
                        end)
                    end
                end
                ListContainer.CanvasSize = UDim2.new(0, 0, 0, UIListInner.AbsoluteContentSize.Y + 20)
            end

            ToggleBtn.MouseButton1Click:Connect(function()
                PlayAudio("Click")
                IsOpen = not IsOpen
                if IsOpen then
                    ToggleBtn.Text = "Close Player List ▲"
                    RefreshList()
                    ListContainer.Visible = true
                    TweenService:Create(DropdownFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(1, 0, 0, 200)}):Play()
                else
                    ToggleBtn.Text = "Select Player to Teleport ▼"
                    TweenService:Create(DropdownFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(1, 0, 0, 40)}):Play()
                    task.delay(0.2, function()
                        ListContainer.Visible = false
                    end)
                end
            end)
        end

        return TabData
    end

    return Tabs
end

local Window = Library:Init()
if DidAutoLoadConfig then
    task.defer(function()
        Library:Notify("Config", "Auto-loaded saved config.", 3)
    end)
end

local GeneralTab = Window:CreateTab("General", "ℹ️")
local GeneralStatusLabel = GeneralTab:CreateLabel("Status panel loading...", 90)
local GeneralConfigLabel = GeneralTab:CreateLabel("Config panel loading...", 64)
local GeneralSafetyLabel = GeneralTab:CreateLabel("Safety panel loading...", 82)
local GeneralFloorLabel = GeneralTab:CreateLabel("Floor intel loading...", 64)
local GeneralResearchLabel = GeneralTab:CreateLabel("Research panel loading...", 84)

StartResearchWatcher()

local MainTab = Window:CreateTab("Main", "🏠")
UIControls.WalkSpeedToggle = MainTab:CreateToggle("Enable WalkSpeed", function(val)
    WalkSpeedEnabled = val
    SaveCurrentConfig(true)
end, WalkSpeedEnabled)
UIControls.WalkSpeedSlider = MainTab:CreateSlider("WalkSpeed Value", 16, 150, WalkSpeedValue, function(val)
    WalkSpeedValue = val
    SaveCurrentConfig(true)
end)
MainTab:CreateButton("WalkSpeed Preset 20", function()
    WalkSpeedValue = 20
    if UIControls.WalkSpeedSlider then UIControls.WalkSpeedSlider:SetValue(20, true) end
    SaveCurrentConfig(true)
    Library:Notify("WalkSpeed", "Preset set to 20", 2)
end)
MainTab:CreateButton("WalkSpeed Preset 25", function()
    WalkSpeedValue = 25
    if UIControls.WalkSpeedSlider then UIControls.WalkSpeedSlider:SetValue(25, true) end
    SaveCurrentConfig(true)
    Library:Notify("WalkSpeed", "Preset set to 25", 2)
end)
MainTab:CreateButton("WalkSpeed Preset 30", function()
    WalkSpeedValue = 30
    if UIControls.WalkSpeedSlider then UIControls.WalkSpeedSlider:SetValue(30, true) end
    SaveCurrentConfig(true)
    Library:Notify("WalkSpeed", "Preset set to 30", 2)
end)
MainTab:CreateButton("WalkSpeed Preset 35", function()
    WalkSpeedValue = 35
    if UIControls.WalkSpeedSlider then UIControls.WalkSpeedSlider:SetValue(35, true) end
    SaveCurrentConfig(true)
    Library:Notify("WalkSpeed", "Preset set to 35", 2)
end)
MainTab:CreateButton("WalkSpeed Preset 40", function()
    WalkSpeedValue = 40
    if UIControls.WalkSpeedSlider then UIControls.WalkSpeedSlider:SetValue(40, true) end
    SaveCurrentConfig(true)
    Library:Notify("WalkSpeed", "Preset set to 40", 2)
end)
MainTab:CreateButton("WalkSpeed Preset 45", function()
    WalkSpeedValue = 45
    if UIControls.WalkSpeedSlider then UIControls.WalkSpeedSlider:SetValue(45, true) end
    SaveCurrentConfig(true)
    Library:Notify("WalkSpeed", "Preset set to 45", 2)
end)
MainTab:CreateToggle("Freecam", function(val)
    ToggleFreecamLogic(val)
end, false)
MainTab:CreateToggle("Noclip", function(val)
    NoclipEnabled = val
    ToggleNoclipSystem(val)
end, false)
UIControls.AutoSkillCheckToggle = MainTab:CreateToggle("Auto Skillcheck", function(val)
    AutoSkillCheckEnabled = val
    SaveCurrentConfig(true)
end, AutoSkillCheckEnabled)

local VisualsTab = Window:CreateTab("Visuals", "👁️")
UIControls.ESPTwistedsToggle = VisualsTab:CreateToggle("ESP Twisteds", function(val)
    ESP_Settings.Twisteds.Enabled = val
    SaveCurrentConfig(true)
end, ESP_Settings.Twisteds.Enabled)
UIControls.ESPGeneratorsToggle = VisualsTab:CreateToggle("ESP Generators", function(val)
    ESP_Settings.Generators.Enabled = val
    SaveCurrentConfig(true)
end, ESP_Settings.Generators.Enabled)
UIControls.ESPItemsToggle = VisualsTab:CreateToggle("ESP Items", function(val)
    ESP_Settings.Items.Enabled = val
    SaveCurrentConfig(true)
end, ESP_Settings.Items.Enabled)
UIControls.ESPPlayersToggle = VisualsTab:CreateToggle("ESP Players", function(val)
    ESP_Settings.Players.Enabled = val
    SaveCurrentConfig(true)
end, ESP_Settings.Players.Enabled)

local TeleportTab = Window:CreateTab("Teleports", "✈️")
TeleportTab:CreateButton("Teleport to Elevator", function()
    pcall(function()
        local elevatorFolder = Workspace:FindFirstChild("Elevators")
        if elevatorFolder then
            local elevator = elevatorFolder:FindFirstChild("Elevator")
            if elevator then
                local spawnZones = elevator:FindFirstChild("SpawnZones")
                if spawnZones and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local target = spawnZones:IsA("BasePart") and spawnZones or spawnZones:FindFirstChildOfClass("BasePart")
                    if target then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = target.CFrame + Vector3.new(0, 3, 0)
                    end
                end
            end
        end
    end)
    Library:Notify("Action", "Teleporting...", 2)
end)
UIControls.AutoEscapeToggle = TeleportTab:CreateToggle("Auto TP Elevator", function(val)
    AutoEscapeEnabled = val
    SaveCurrentConfig(true)
end, AutoEscapeEnabled)

local TpSafeModeLabel = TeleportTab:CreateLabel("TP Safe Mode: " .. TpSafeMode, 54)
UIControls.TpSafeToggle = TeleportTab:CreateToggle("TP Safe (Key V)", function(val)
    TpSafeEnabled = val
    SaveCurrentConfig(true)
end, TpSafeEnabled)
UIControls.TpSafeDangerSlider = TeleportTab:CreateSlider("TP Safe Danger Distance", 15, 80, TpSafeDangerDistance, function(val)
    TpSafeDangerDistance = val
    SaveCurrentConfig(true)
end)
TeleportTab:CreateButton("Cycle TP Safe Mode (Key B)", function()
    if TpSafeMode == "Elevator" then
        TpSafeMode = "Player"
    elseif TpSafeMode == "Player" then
        TpSafeMode = "Sky"
    else
        TpSafeMode = "Elevator"
    end

    if TpSafeModeLabel then
        TpSafeModeLabel:SetText("TP Safe Mode: " .. TpSafeMode .. "\nState: " .. (TpSafeEnabled and "ON" or "OFF") .. "\nDanger Dist: " .. tostring(TpSafeDangerDistance))
    end

    SaveCurrentConfig(true)
    Library:Notify("TP Safe", "Mode: " .. TpSafeMode, 2)
end)

local function IsGeneratorOccupiedByPlayer(gen, radius)
    local genCF = GetGeneratorTeleportCFrame(gen)
    if not genCF then return false end

    local inGamePlayers = Workspace:FindFirstChild("InGamePlayers")
    if not inGamePlayers then return false end

    radius = radius or 14
    for _, char in ipairs(inGamePlayers:GetChildren()) do
        if char.Name ~= LocalPlayer.Name then
            local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart", true)
            if root and (root.Position - genCF.Position).Magnitude <= radius then
                return true
            end
        end
    end

    return false
end

local function GetBestFreeGenerator()
    local roomModel = GetCurrentRoomModel()
    if not roomModel then return nil end

    local genFolder = roomModel:FindFirstChild("Generators")
    if not genFolder then return nil end

    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local bestGen = nil
    local bestDist = math.huge

    for _, gen in ipairs(genFolder:GetChildren()) do
        local stats = gen:FindFirstChild("Stats")
        local completedVal = stats and stats:FindFirstChild("Completed")
        if completedVal and completedVal.Value == false then
            if not IsGeneratorOccupiedByPlayer(gen, 14) and not IsConnieGenerator(gen) then
                local genCF = GetGeneratorTeleportCFrame(gen)
                if genCF and hrp then
                    local dist = (genCF.Position - hrp.Position).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        bestGen = gen
                    end
                elseif not bestGen then
                    bestGen = gen
                end
            end
        end
    end

    return bestGen
end

TeleportTab:CreateButton("TP to Uncompleted Machine", function()
    pcall(function()
        local targetGenerator = GetBestFreeGenerator()
        if targetGenerator and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetCFrame = GetGeneratorTeleportCFrame(targetGenerator)
            if targetCFrame then
                LocalPlayer.Character.HumanoidRootPart.CFrame = targetCFrame + Vector3.new(0, 3, 0)
            end
        end
    end)
    Library:Notify("Action", "Teleporting...", 2)
end)
TeleportTab:CreatePlayerList()

local FarmingTab = Window:CreateTab("Farming", "🎒")
UIControls.AutoCollectSafeToggle = FarmingTab:CreateToggle("Collect Only If Safe From Twisteds", function(val)
    AutoCollectSafeOnly = val
    SaveCurrentConfig(true)
end, AutoCollectSafeOnly)
UIControls.AutoCollectSafeSlider = FarmingTab:CreateSlider("Safe Distance From Twisted", 10, 200, AutoCollectSafeDistance, function(val)
    AutoCollectSafeDistance = val
    SaveCurrentConfig(true)
end)

local function AutoCollectItem(targetName)
    local room = Workspace:FindFirstChild("CurrentRoom")
    if not room then return end
    local items = {}

    for _, child in pairs(room:GetChildren()) do
        local itemFolder = child:FindFirstChild("Items")
        if itemFolder then
            for _, v in pairs(itemFolder:GetChildren()) do
                if v.Name == targetName or (targetName == "Research" and v.Name:match("Research")) then
                    table.insert(items, v)
                end
            end
        end
        if child.Name == targetName or (targetName == "Research" and child.Name:match("Research")) then
            table.insert(items, child)
        end
    end

    if #items == 0 then
        Library:Notify("Auto Collect", "No " .. targetName .. "s found nearby!", 3)
        return
    end

    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if AutoCollectSafeOnly and hrp then
        local safeNow, dangerObj, dangerDistance, dangerType = IsSafeFromTwisteds(hrp.Position, AutoCollectSafeDistance, {
            CheckConnieMachine = false,
            CheckBlotHands = true,
        })
        if not safeNow then
            local threatLabel = "Danger"
            if dangerType == "ConnieGenerator" then
                threatLabel = "Connie on machine"
            elseif dangerType == "BlotHand" then
                threatLabel = "Blot hand zone"
            elseif dangerObj and dangerObj:IsA("Model") then
                threatLabel = GetTwistedDisplayName(dangerObj)
            end
            Library:Notify("Auto Collect", "Unsafe: " .. threatLabel .. " at " .. tostring(math.floor(dangerDistance)) .. " studs.", 4)
            return
        end
    end

    Library:Notify("Auto Collect", "Collecting " .. #items .. " " .. targetName .. "s...", 3)

    local collectedCount = 0
    local skippedUnsafe = 0

    for _, item in pairs(items) do
        hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if item and item.Parent and hrp then
            local part = item:IsA("Model") and item.PrimaryPart or item:FindFirstChild("Handle") or item:FindFirstChildOfClass("BasePart")
            local prompt = item:FindFirstChild("ProximityPrompt", true)
            if part and prompt then
                local safeToCollect = true
                if AutoCollectSafeOnly then
                    local safePlayer = select(1, IsSafeFromTwisteds(hrp.Position, AutoCollectSafeDistance, {
                        CheckConnieMachine = false,
                        CheckBlotHands = true,
                    }))
                    local safeItem = select(1, IsSafeFromTwisteds(part.Position, AutoCollectSafeDistance, {
                        CheckConnieMachine = false,
                        CheckBlotHands = true,
                    }))
                    safeToCollect = safePlayer and safeItem
                end

                if safeToCollect then
                    hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                    task.wait(0.25)
                    local start = tick()
                    repeat
                        if item.Parent == nil then break end
                        hrp.CFrame = part.CFrame
                        if fireproximityprompt then
                            fireproximityprompt(prompt)
                        else
                            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                            task.wait()
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                        end
                        task.wait(0.1)
                    until tick() - start > 2 or item.Parent == nil

                    if item.Parent == nil then
                        collectedCount = collectedCount + 1
                    end
                else
                    skippedUnsafe = skippedUnsafe + 1
                end
            end
        end
    end

    local finishText = "Collected " .. tostring(collectedCount) .. "."
    if skippedUnsafe > 0 then
        finishText = finishText .. " Skipped unsafe: " .. tostring(skippedUnsafe) .. "."
    end
    Library:Notify("Auto Collect", finishText, 3)
end

local function GetFreeInventorySlots()
    local inGamePlayers = Workspace:FindFirstChild("InGamePlayers")
    if not inGamePlayers then
        return math.huge, 0
    end

    local myFolder = inGamePlayers:FindFirstChild(LocalPlayer.Name)
    if not myFolder then
        return math.huge, 0
    end

    local inventory = myFolder:FindFirstChild("Inventory")
    if not inventory then
        return math.huge, 0
    end

    local slots = {}
    for _, obj in ipairs(inventory:GetChildren()) do
        if obj:IsA("StringValue") then
            local n = tostring(obj.Name):gsub("%s+", ""):lower()
            if n:match("^slot%d+$") then
                table.insert(slots, obj)
            end
        end
    end

    table.sort(slots, function(a, b)
        local aNum = tonumber((a.Name:match("(%d+)"))) or 999
        local bNum = tonumber((b.Name:match("(%d+)"))) or 999
        return aNum < bNum
    end)

    local totalSlots = #slots
    if totalSlots <= 0 then
        return math.huge, 0
    end

    local usedSlots = 0
    for _, slot in ipairs(slots) do
        local value = tostring(slot.Value or "")
        local normalized = value:lower():gsub("%s+", "")

        local occupied = not (
            value == ""
            or normalized == "none"
            or normalized == "nil"
            or normalized == "empty"
        )

        if occupied then
            usedSlots += 1
        end
    end

    return math.max(totalSlots - usedSlots, 0), totalSlots
end

local GEN_SPEEDER_TARGETS = {
    {
        Display = "Valve",
        Tier = 4,
        Score = 600,
        Names = {"valve"},
    },
    {
        Display = "Instructions / JumperCable",
        Tier = 3,
        Score = 500,
        Names = {"instructions", "jumpercable", "jumper cable"},
    },
    {
        Display = "SkillCheckCandy",
        Tier = 2,
        Score = 400,
        Names = {"skillcheckcandy", "skill check candy"},
    },
    {
        Display = "ExtractionSpeedCandy / Stopwatch",
        Tier = 1,
        Score = 300,
        Names = {"extractionspeedcandy", "extraction speed candy", "stopwatch"},
    },
}

local function GetRequiredTierFromFreeSlots(freeSlots)
    if freeSlots == math.huge then
        return 1
    end
    if freeSlots <= 0 then
        return 999
    elseif freeSlots == 1 then
        return 4
    elseif freeSlots == 2 then
        return 3
    elseif freeSlots == 3 then
        return 2
    else
        return 1
    end
end

local function GetItemPart(item)
    if not item then return nil end
    if item:IsA("BasePart") then
        return item
    end
    if item:IsA("Model") then
        return item.PrimaryPart
            or item:FindFirstChild("Handle")
            or item:FindFirstChildWhichIsA("BasePart", true)
    end
    return item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart", true)
end

local function MatchGenSpeederTarget(item)
    if not item then return nil end

    local normalized = NormalizeItemName(
        tostring(item.Name or "") .. " " .. tostring(GetDisplayItemName(item) or "")
    )

    for _, entry in ipairs(GEN_SPEEDER_TARGETS) do
        for _, alias in ipairs(entry.Names) do
            if normalized:find(alias, 1, true) then
                return entry
            end
        end
    end

    return nil
end

local function IsTopTopGenSpeederItem(entry, item)
    if not entry or not item then return false end

    local normalized = NormalizeItemName(
        tostring(item.Name or "") .. " " .. tostring(GetDisplayItemName(item) or "")
    )

    if normalized:find("valve", 1, true) then
        return true
    end
    if normalized:find("instructions", 1, true) then
        return true
    end
    if normalized:find("jumpercable", 1, true) or normalized:find("jumper cable", 1, true) then
        return true
    end

    return false
end

local function IsBypassBlockedByDeadlyTwisteds()
    local monsterFolder = GetCurrentMonsterFolder()
    if not monsterFolder then
        return false, nil
    end

    for _, mob in ipairs(monsterFolder:GetChildren()) do
        if IsDyleMob(mob) then
            return true, "Twisted Dyle"
        end
        if IsDandyMob(mob) then
            return true, "Twisted Dandy"
        end
    end

    return false, nil
end

local function CollectSpecificWorldItem(item, bypassSafety)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not item or not item.Parent or not hrp then
        return false
    end

    local part = GetItemPart(item)
    local prompt = item:FindFirstChild("ProximityPrompt", true)
    if not part or not prompt then
        return false
    end

    if AutoCollectSafeOnly and not bypassSafety then
        local safePlayer = select(1, IsSafeFromTwisteds(hrp.Position, AutoCollectSafeDistance, {
            CheckConnieMachine = false,
            CheckBlotHands = true,
        }))
        local safeItem = select(1, IsSafeFromTwisteds(part.Position, AutoCollectSafeDistance, {
            CheckConnieMachine = false,
            CheckBlotHands = true,
        }))

        if not safePlayer or not safeItem then
            return false
        end
    end

    hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
    task.wait(0.18)

    local start = tick()
    repeat
        if not item.Parent then
            return true
        end

        if hrp.Parent then
            hrp.CFrame = part.CFrame + Vector3.new(0, 1.5, 0)
        end

        if fireproximityprompt then
            fireproximityprompt(prompt)
        else
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait()
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end

        task.wait(0.10)
    until tick() - start > 2 or not item.Parent

    return item.Parent == nil
end

local function ReturnFarAfterTopItemGrab(oldCFrame)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not oldCFrame then return end

    hrp.CFrame = oldCFrame + Vector3.new(0, 3, 0)
end

local function TeleportToBestGenSpeederTarget(allowGeneratorFallback, autoGrabItem)
    local roomModel = GetCurrentRoomModel()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    if not roomModel or not hrp then
        Library:Notify("Gen Speeder", "Room o character no disponible.", 3)
        return
    end

    local itemFolder = roomModel:FindFirstChild("Items")
    if not itemFolder then
        Library:Notify("Gen Speeder", "No encontré carpeta Items.", 3)
        return
    end

    local freeSlots, totalSlots = GetFreeInventorySlots()
    if freeSlots <= 0 and freeSlots ~= math.huge then
        Library:Notify("Gen Speeder", "No tienes slots libres.", 3)
        return
    end

    local requiredTier = GetRequiredTierFromFreeSlots(freeSlots)

    local bestItem = nil
    local bestPart = nil
    local bestEntry = nil
    local bestDistance = math.huge

    local bestFallbackItem = nil
    local bestFallbackPart = nil
    local bestFallbackEntry = nil
    local bestFallbackDistance = math.huge

    for _, item in ipairs(itemFolder:GetChildren()) do
        local entry = MatchGenSpeederTarget(item)
        local part = GetItemPart(item)

        if entry and part then
            local bypassSafety = IsTopTopGenSpeederItem(entry, item)
            if bypassSafety then
                local bypassBlocked = IsBypassBlockedByDeadlyTwisteds()
                if bypassBlocked then
                    bypassSafety = false
                end
            end
            local safeToTP = true

            if AutoCollectSafeOnly and not bypassSafety then
                safeToTP = select(1, IsSafeFromTwisteds(part.Position, AutoCollectSafeDistance, {
                    CheckConnieMachine = false,
                    CheckBlotHands = true,
                }))
            end

            if safeToTP then
                local dist = (part.Position - hrp.Position).Magnitude

                if entry.Tier >= requiredTier then
                    if (not bestEntry) or (entry.Score > bestEntry.Score) or (entry.Score == bestEntry.Score and dist < bestDistance) then
                        bestItem = item
                        bestPart = part
                        bestEntry = entry
                        bestDistance = dist
                    end
                end

                if (not bestFallbackEntry) or (entry.Score > bestFallbackEntry.Score) or (entry.Score == bestFallbackEntry.Score and dist < bestFallbackDistance) then
                    bestFallbackItem = item
                    bestFallbackPart = part
                    bestFallbackEntry = entry
                    bestFallbackDistance = dist
                end
            end
        end
    end

    local chosenItem = bestItem or bestFallbackItem
    local chosenPart = bestPart or bestFallbackPart
    local chosenEntry = bestEntry or bestFallbackEntry

    if chosenItem and chosenPart and chosenEntry then
        local oldCFrame = hrp.CFrame
        local bypassSafety = IsTopTopGenSpeederItem(chosenEntry, chosenItem)
        local bypassBlocked, bypassBlockedName = IsBypassBlockedByDeadlyTwisteds()
        if bypassSafety and bypassBlocked then
            bypassSafety = false
        end

        hrp.CFrame = chosenPart.CFrame + Vector3.new(0, 3, 0)

        local freeText = (freeSlots == math.huge) and "?" or tostring(freeSlots)
        local totalText = (totalSlots and totalSlots > 0) and tostring(totalSlots) or "?"

        if autoGrabItem then
            task.wait(0.18)
            local grabbed = CollectSpecificWorldItem(chosenItem, bypassSafety)

            if grabbed then
                if bypassSafety then
                    task.wait(0.08)
                    ReturnFarAfterTopItemGrab(oldCFrame)
                    Library:Notify("Gen Speeder", "TP + agarrado + salido -> " .. tostring(chosenItem.Name) .. " | Slots libres: " .. freeText .. "/" .. totalText, 3)
                else
                    local extraWarn = bypassBlockedName and (" | bypass off: " .. bypassBlockedName) or ""
                    Library:Notify("Gen Speeder", "TP + agarrado -> " .. tostring(chosenItem.Name) .. " | Slots libres: " .. freeText .. "/" .. totalText .. extraWarn, 3)
                end
            else
                Library:Notify("Gen Speeder", "TP -> " .. tostring(chosenItem.Name) .. " pero no se pudo agarrar.", 3)
            end
        else
            if bypassSafety then
                Library:Notify("Gen Speeder", "TP bypass -> " .. tostring(chosenItem.Name) .. " | Slots libres: " .. freeText .. "/" .. totalText, 3)
            else
                local extraWarn = bypassBlockedName and (" | bypass off: " .. bypassBlockedName) or ""
                Library:Notify("Gen Speeder", "TP -> " .. tostring(chosenItem.Name) .. " | Slots libres: " .. freeText .. "/" .. totalText .. extraWarn, 3)
            end
        end
        return
    end

    if allowGeneratorFallback then
        local gen = GetBestFreeGenerator()
        if gen then
            local genCF = GetGeneratorTeleportCFrame(gen)
            if genCF then
                local safeToTP = true
                if AutoCollectSafeOnly then
                    safeToTP = select(1, IsSafeFromTwisteds(genCF.Position, AutoCollectSafeDistance, {
                        CheckConnieMachine = true,
                        CheckBlotHands = true,
                    }))
                end

                if safeToTP then
                    hrp.CFrame = genCF + Vector3.new(0, 3, 0)
                    Library:Notify("Gen Speeder", "No había item útil. TP a máquina libre.", 3)
                    return
                end
            end
        end
    end

    Library:Notify("Gen Speeder", "No encontré item prioritario.", 3)
end

FarmingTab:CreateButton("Auto Collect Tapes", function() AutoCollectItem("Tape") end)
FarmingTab:CreateButton("Auto Collect Research", function() AutoCollectItem("Research") end)
FarmingTab:CreateButton("Auto Collect Holiday Items", function() AutoCollectItem("HolidayCollectibleItem") end)
FarmingTab:CreateButton("TP + Grab Best Gen Speeder Item", function()
    TeleportToBestGenSpeederTarget(false, true)
end)
FarmingTab:CreateButton("TP + Grab Best Item / Free Machine", function()
    TeleportToBestGenSpeederTarget(true, true)
end)

local PremiumTab = Window:CreateTab("Player", "⚡")
UIControls.InfiniteStaminaToggle = PremiumTab:CreateToggle("Infinite Stamina", function(val)
    InfiniteStaminaEnabled = val
    SaveCurrentConfig(true)
end, InfiniteStaminaEnabled)

local GodModeConn
PremiumTab:CreateToggle("God Mode", function(val)
    GodModeEnabled = val
    if val then
        local function ApplyGodMode(char)
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanTouch = false
                end
            end
        end
        if LocalPlayer.Character then
            ApplyGodMode(LocalPlayer.Character)
        end
        GodModeConn = LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            ApplyGodMode(char)
        end)
        Library:Notify("God Mode", "Hitbox Removed (CanTouch = false)", 3)
    else
        if GodModeConn then
            GodModeConn:Disconnect()
            GodModeConn = nil
        end
        Library:Notify("God Mode", "Disabled (Reset character to restore)", 2)
    end
end, false)

local StuffTab = Window:CreateTab("Stuff", "⚙️")
StuffTab:CreateButton("Force Reset", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.Health = 0
    end
    Library:Notify("Action", "Resetting...", 2)
end)
StuffTab:CreateButton("Infinite Yield", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end)
StuffTab:CreateToggle("Fullbright", function(val)
    if val then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    else
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.ClockTime = OriginalLighting.ClockTime
        Lighting.GlobalShadows = OriginalLighting.GlobalShadows
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
    end
end, false)

local SettingsTab = Window:CreateTab("Settings", "🛠️")
UIControls.SoundToggle = SettingsTab:CreateToggle("Enable UI Sounds", function(val)
    SoundEnabled = val
    SaveCurrentConfig(true)
end, SoundEnabled)

local KeybindButton = SettingsTab:CreateButton("Menu Keybind: " .. ToggleKey.Name, function()
    KeybindButton.Text = "Press any key..."
    IsSettingKeybind = true

    local InputConnection
    InputConnection = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            ToggleKey = input.KeyCode
            KeybindButton.Text = "Menu Keybind: " .. input.KeyCode.Name
            Library:Notify("Settings", "Keybind set to " .. input.KeyCode.Name, 2)
            SaveCurrentConfig(true)
            task.wait(0.2)
            IsSettingKeybind = false
            InputConnection:Disconnect()
        end
    end)
end)

SettingsTab:CreateButton("Save Config", function()
    SaveCurrentConfig(false)
end)

SettingsTab:CreateButton("Load Config", function()
    if LoadSavedConfig(false) then
        if UIControls.WalkSpeedToggle then UIControls.WalkSpeedToggle:SetValue(WalkSpeedEnabled, true) end
        if UIControls.WalkSpeedSlider then UIControls.WalkSpeedSlider:SetValue(WalkSpeedValue, true) end
        if UIControls.AutoSkillCheckToggle then UIControls.AutoSkillCheckToggle:SetValue(AutoSkillCheckEnabled, true) end
        if UIControls.ESPTwistedsToggle then UIControls.ESPTwistedsToggle:SetValue(ESP_Settings.Twisteds.Enabled, true) end
        if UIControls.ESPGeneratorsToggle then UIControls.ESPGeneratorsToggle:SetValue(ESP_Settings.Generators.Enabled, true) end
        if UIControls.ESPItemsToggle then UIControls.ESPItemsToggle:SetValue(ESP_Settings.Items.Enabled, true) end
        if UIControls.ESPPlayersToggle then UIControls.ESPPlayersToggle:SetValue(ESP_Settings.Players.Enabled, true) end
        if UIControls.AutoEscapeToggle then UIControls.AutoEscapeToggle:SetValue(AutoEscapeEnabled, true) end
        if UIControls.TpSafeToggle then UIControls.TpSafeToggle:SetValue(TpSafeEnabled, true) end
        if UIControls.TpSafeDangerSlider then UIControls.TpSafeDangerSlider:SetValue(TpSafeDangerDistance, true) end
        if TpSafeModeLabel then
            TpSafeModeLabel:SetText("TP Safe Mode: " .. TpSafeMode .. "\nState: " .. (TpSafeEnabled and "ON" or "OFF") .. "\nDanger Dist: " .. tostring(TpSafeDangerDistance))
        end
        if UIControls.InfiniteStaminaToggle then UIControls.InfiniteStaminaToggle:SetValue(InfiniteStaminaEnabled, true) end
        if UIControls.SoundToggle then UIControls.SoundToggle:SetValue(SoundEnabled, true) end
        if UIControls.AutoCollectSafeToggle then UIControls.AutoCollectSafeToggle:SetValue(AutoCollectSafeOnly, true) end
        if UIControls.AutoCollectSafeSlider then UIControls.AutoCollectSafeSlider:SetValue(AutoCollectSafeDistance, true) end
        KeybindButton.Text = "Menu Keybind: " .. ToggleKey.Name
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        UpdateFloorIntelNotifier()
        local roomModel = GetCurrentRoomModel()
        local roomName = roomModel and roomModel.Name or "No room"
        local twistedCount = 0
        local rareItemCount = 0
        local nearestText = "None"
        local specialThreatText = "Safe"

        if roomModel then
            local monsterFolder = roomModel:FindFirstChild("Monsters")
            if monsterFolder then
                twistedCount = #monsterFolder:GetChildren()
            end
            rareItemCount = CountTrackedRareItems(roomModel)
        end

        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local nearestMob, nearestDistance, hasLOS = GetNearestTwistedInfo(hrp.Position, {
                IgnoreConnie = false,
                IgnoreBlotBody = false,
                IgnoreRoger = false,
                IgnoreGlistenWhenInactive = false,
            })
            if nearestMob then
                local label = GetTwistedDisplayName(nearestMob)
                if hasLOS then
                    nearestText = label .. " (" .. tostring(math.floor(nearestDistance)) .. " studs, LOS)"
                else
                    nearestText = label .. " (" .. tostring(math.floor(nearestDistance)) .. " studs, blocked)"
                end
            end

            local safe, dangerObj, dangerDistance, dangerType = IsSafeFromTwisteds(hrp.Position, AutoCollectSafeDistance, {
                CheckConnieMachine = true,
                CheckBlotHands = true,
            })
            if not safe then
                if dangerType == "ConnieGenerator" then
                    specialThreatText = "Connie machine (" .. tostring(math.floor(dangerDistance)) .. " studs)"
                elseif dangerType == "BlotHand" then
                    specialThreatText = "Blot hand (" .. tostring(math.floor(dangerDistance)) .. " studs)"
                elseif dangerObj and dangerObj:IsA("Model") then
                    specialThreatText = GetTwistedDisplayName(dangerObj) .. " [" .. tostring(dangerType) .. "]"
                else
                    specialThreatText = tostring(dangerType)
                end
            end
        end

        if GeneralStatusLabel then
            GeneralStatusLabel:SetText(
                "Room: " .. roomName .. "\n" ..
                "Twisteds in room: " .. tostring(twistedCount) .. "\n" ..
                "Tracked rare items: " .. tostring(rareItemCount) .. "\n" ..
                "Nearest threat: " .. nearestText
            )
        end

        if GeneralConfigLabel then
            GeneralConfigLabel:SetText(
                "WalkSpeed: " .. tostring(WalkSpeedValue) .. (WalkSpeedEnabled and " [ON]" or " [OFF]") .. "\n" ..
                "Auto Skillcheck: " .. (AutoSkillCheckEnabled and "ON" or "OFF") .. "\n" ..
                "Auto TP Elevator: " .. (AutoEscapeEnabled and "ON" or "OFF") .. "\n" ..
                "TP Safe: " .. (TpSafeEnabled and "ON" or "OFF") .. " | " .. TpSafeMode .. " | " .. tostring(TpSafeDangerDistance) .. " studs\n" ..
                "Menu Keybind: " .. ToggleKey.Name
            )
        end

        if GeneralSafetyLabel then
            local freeSlots, totalSlots = GetFreeInventorySlots()
            local slotText = (freeSlots == math.huge) and "?" or tostring(freeSlots)
            local totalText = (totalSlots and totalSlots > 0) and tostring(totalSlots) or "?"
            GeneralSafetyLabel:SetText(
                "ESP Twisteds: " .. (ESP_Settings.Twisteds.Enabled and "ON" or "OFF") .. " | ESP Items: " .. (ESP_Settings.Items.Enabled and "ON" or "OFF") .. "\n" ..
                "Safe Auto Collect: " .. (AutoCollectSafeOnly and "ON" or "OFF") .. "\n" ..
                "Safe Distance: " .. tostring(AutoCollectSafeDistance) .. " studs\n" ..
                "Inventory free: " .. slotText .. "/" .. totalText .. " | Threat: " .. specialThreatText
            )
        end

        if TpSafeModeLabel then
            TpSafeModeLabel:SetText(
                "TP Safe Mode: " .. TpSafeMode ..
                "\nState: " .. (TpSafeEnabled and "ON" or "OFF") ..
                "\nDanger Dist: " .. tostring(TpSafeDangerDistance)
            )
        end

        if GeneralFloorLabel then
            GeneralFloorLabel:SetText(FloorIntelState.CurrentText)
        end

        if GeneralResearchLabel then
            GeneralResearchLabel:SetText(BuildResearchOverviewText())
        end
    end
end)

local MobileToggle = Instance.new("TextButton", ScreenGui)
MobileToggle.Name = "MobileToggle"
MobileToggle.Size = UDim2.new(0, 50, 0, 50)
MobileToggle.Position = UDim2.new(1, -70, 1, -70)
MobileToggle.BackgroundColor3 = Theme.Accent
MobileToggle.BackgroundTransparency = 0.3
MobileToggle.Text = "MENU"
MobileToggle.TextColor3 = Theme.Text
MobileToggle.Font = Enum.Font.GothamBold
MobileToggle.TextSize = 12
Instance.new("UICorner", MobileToggle).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", MobileToggle).Color = Theme.Stroke
if not UserInputService.TouchEnabled then
    MobileToggle.Visible = false
end

MobileToggle.MouseButton1Click:Connect(function()
    local WindowFrame = ScreenGui:FindFirstChild("Window")
    if WindowFrame then
        IsMenuOpen = not IsMenuOpen
        if IsMenuOpen then
            TweenService:Create(WindowFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back), {Size = UDim2.new(0, 650, 0, 420)}):Play()
        else
            TweenService:Create(WindowFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 80, 0, 45)}):Play()
        end
    end
end)

print("Dandy's World Utility v9.0 - Pastel Easter Theme Loaded")

]====]
}
