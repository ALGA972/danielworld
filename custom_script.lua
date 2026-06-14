--// UNIVERSAL TEAM ESP - POORLY SCRIPTED / DW STYLE
--// Solo ESP universal de jugadores
--// Colores por Team
--// Detecta tu Team
--// Opción para ocultar tu propio Team
--// GUI con intro tipo Poorly Scripted
--// GUI con scroll corregido para que no se pase hacia abajo
--// SMART RELOAD: recarga solo cuando detecta cambios/roturas
--// Inventory Threat Mode LOCAL: revisa Character y Backpack como backup
--// Knife = rojo | Gun = azul | Both = morado

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	return
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- GLOBAL CLEANUP
--==================================================

_G.UniversalTeamESP_DWStyle = _G.UniversalTeamESP_DWStyle or {}

if _G.UniversalTeamESP_DWStyle.Cleanup then
	pcall(_G.UniversalTeamESP_DWStyle.Cleanup)
end

--==================================================
-- THEME
--==================================================

local Theme = {
	Background = Color3.fromRGB(255, 240, 245),
	Sidebar = Color3.fromRGB(255, 228, 230),
	Panel = Color3.fromRGB(255, 248, 252),
	Text = Color3.fromRGB(80, 50, 60),
	TextDim = Color3.fromRGB(150, 110, 130),
	Accent = Color3.fromRGB(255, 153, 204),
	Stroke = Color3.fromRGB(255, 200, 215),
	Success = Color3.fromRGB(119, 221, 119),
	Destructive = Color3.fromRGB(255, 105, 97),
	Gold = Color3.fromRGB(255, 215, 0),
	Neutral = Color3.fromRGB(220, 220, 220),
	Black = Color3.fromRGB(0, 0, 0),

	Knife = Color3.fromRGB(255, 60, 60),
	Gun = Color3.fromRGB(80, 160, 255),
	ThreatBoth = Color3.fromRGB(190, 80, 255),

	CornerRadius = UDim.new(0, 14),
}

--==================================================
-- CONFIG
--==================================================

local Config = {
	Enabled = true,
	Players = true,

	UseTeamColor = true,
	HideOwnTeam = false,
	ShowNeutral = true,

	ShowLabels = true,
	ShowDistance = true,
	ShowTeamName = true,
	ShowDisplayName = true,

	InventoryThreatMode = true,
	ShowThreatName = true,

	KnifeColor = Color3.fromRGB(255, 60, 60),
	GunColor = Color3.fromRGB(80, 160, 255),
	BothThreatColor = Color3.fromRGB(190, 80, 255),

	Highlight = true,
	FillTransparency = 0.62,
	OutlineTransparency = 0.05,

	MaxDistance = 10000,
	RefreshDelay = 0.25,

	-- El modo inteligente no necesita borrar todo cada X segundos.
	AutoFullReload = false,
	FullReloadDelay = 3,

	ToggleKey = Enum.KeyCode.RightControl,

	DefaultEnemyColor = Color3.fromRGB(255, 153, 204),
	NeutralColor = Color3.fromRGB(220, 220, 220),
	OwnTeamFallbackColor = Color3.fromRGB(119, 221, 119),

	WindowOpenSize = UDim2.new(0, 650, 0, 420),
	WindowClosedSize = UDim2.new(0, 80, 0, 45),
}

--==================================================
-- RUNTIME
--==================================================

local Runtime = {
	Gui = nil,
	Main = nil,
	Sidebar = nil,
	Content = nil,
	NotifyHolder = nil,

	ESP = {},
	Connections = {},

	LoopToken = 0,
	GuiOpen = true,

	StatusLabel = nil,
	TeamLabel = nil,
	TeamDot = nil,
	CountLabel = nil,

	SetEnabledVisual = nil,
	SetPlayersVisual = nil,
	SetTeamColorVisual = nil,
	SetHideOwnTeamVisual = nil,
	SetNeutralVisual = nil,
	SetLabelsVisual = nil,
	SetDistanceVisual = nil,
	SetTeamNameVisual = nil,
	SetDisplayNameVisual = nil,
	SetHighlightVisual = nil,
	SetInventoryThreatVisual = nil,
	SetThreatNameVisual = nil,
}

--==================================================
-- BASIC UTILS
--==================================================

local function safeDestroy(obj)
	if obj then
		pcall(function()
			obj:Destroy()
		end)
	end
end

local function safeDisconnect(conn)
	if conn then
		pcall(function()
			conn:Disconnect()
		end)
	end
end

local function bind(conn)
	table.insert(Runtime.Connections, conn)
	return conn
end

local function getCharacter(player)
	return player and player.Character
end

local function getRoot(character)
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
		or character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChildWhichIsA("BasePart", true)
end

local function getHead(character)
	if not character then
		return nil
	end

	return character:FindFirstChild("Head")
		or character:FindFirstChild("HumanoidRootPart")
		or character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChildWhichIsA("BasePart", true)
end

local function getLocalRoot()
	local char = LocalPlayer.Character
	return getRoot(char)
end

local function isCharacterAlive(character)
	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if humanoid and humanoid.Health <= 0 then
		return false
	end

	return true
end

local function getBackpack(player)
	if not player then
		return nil
	end

	return player:FindFirstChildOfClass("Backpack") or player:FindFirstChild("Backpack")
end

local function getTeamName(player)
	if not player then
		return "No Team"
	end

	if player.Team then
		return player.Team.Name
	end

	if player.TeamColor and tostring(player.TeamColor.Name) ~= "" then
		return tostring(player.TeamColor.Name)
	end

	return "No Team"
end

local function getTeamColor(player)
	if not player then
		return Config.NeutralColor
	end

	if player.Team then
		local ok, color = pcall(function()
			return player.Team.TeamColor.Color
		end)

		if ok and typeof(color) == "Color3" then
			return color
		end
	end

	if player.TeamColor then
		local ok, color = pcall(function()
			return player.TeamColor.Color
		end)

		if ok and typeof(color) == "Color3" then
			return color
		end
	end

	return Config.NeutralColor
end

local function playerHasTeam(player)
	if not player then
		return false
	end

	if player.Team ~= nil then
		return true
	end

	if player.TeamColor and tostring(player.TeamColor.Name) ~= "White" then
		return true
	end

	return false
end

local function sameTeamAsLocal(player)
	if not player or player == LocalPlayer then
		return true
	end

	local localHasTeam = playerHasTeam(LocalPlayer)
	local otherHasTeam = playerHasTeam(player)

	if not localHasTeam or not otherHasTeam then
		return false
	end

	if LocalPlayer.Team ~= nil and player.Team ~= nil then
		return player.Team == LocalPlayer.Team
	end

	if LocalPlayer.TeamColor ~= nil and player.TeamColor ~= nil then
		return player.TeamColor == LocalPlayer.TeamColor
	end

	return false
end

--==================================================
-- LOCAL INVENTORY THREAT CHECK
--==================================================

local function findToolIn(container, toolName)
	if not container then
		return false
	end

	for _, obj in ipairs(container:GetChildren()) do
		if obj:IsA("Tool") and obj.Name == toolName then
			return true
		end
	end

	return false
end

local function getLocalThreatTool(player)
	if not player then
		return "None"
	end

	local character = player.Character

	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health <= 0 then
			return "None"
		end
	end

	local backpack = getBackpack(player)

	local hasKnife = false
	local hasGun = false

	-- Principal: herramienta equipada/visible en Character.
	if character then
		hasKnife = hasKnife or findToolIn(character, "Knife")
		hasGun = hasGun or findToolIn(character, "Gun")
	end

	-- Backup: Backpack, si el juego lo replica al cliente.
	if backpack then
		hasKnife = hasKnife or findToolIn(backpack, "Knife")
		hasGun = hasGun or findToolIn(backpack, "Gun")
	end

	if hasKnife and hasGun then
		return "Both"
	end

	if hasKnife then
		return "Knife"
	end

	if hasGun then
		return "Gun"
	end

	return "None"
end

local function getThreatColor(player)
	local threat = getLocalThreatTool(player)

	if threat == "Knife" then
		return Config.KnifeColor
	end

	if threat == "Gun" then
		return Config.GunColor
	end

	if threat == "Both" then
		return Config.BothThreatColor
	end

	return nil
end

local function getThreatLabel(player)
	local threat = getLocalThreatTool(player)

	if threat == "Knife" then
		return "Threat: Knife"
	end

	if threat == "Gun" then
		return "Threat: Gun"
	end

	if threat == "Both" then
		return "Threat: Knife + Gun"
	end

	return nil
end

local function getESPColor(player)
	if Config.InventoryThreatMode then
		local threatColor = getThreatColor(player)

		if threatColor then
			return threatColor
		end
	end

	if Config.UseTeamColor then
		if playerHasTeam(player) then
			return getTeamColor(player)
		end

		return Config.NeutralColor
	end

	if sameTeamAsLocal(player) then
		return Config.OwnTeamFallbackColor
	end

	return Config.DefaultEnemyColor
end

local function shouldShowPlayer(player)
	if not Config.Enabled then
		return false
	end

	if not Config.Players then
		return false
	end

	if not player or player == LocalPlayer then
		return false
	end

	local character = getCharacter(player)
	local root = getRoot(character)

	if not character or not root then
		return false
	end

	if not isCharacterAlive(character) then
		return false
	end

	if Config.HideOwnTeam and sameTeamAsLocal(player) then
		return false
	end

	if not Config.ShowNeutral and not playerHasTeam(player) then
		return false
	end

	local localRoot = getLocalRoot()
	if localRoot then
		local distance = (root.Position - localRoot.Position).Magnitude
		if distance > Config.MaxDistance then
			return false
		end
	end

	return true
end

local function buildLabelText(player)
	local character = getCharacter(player)
	local root = getRoot(character)
	local localRoot = getLocalRoot()

	local lines = {}

	if Config.ShowDisplayName and player.DisplayName and player.DisplayName ~= "" and player.DisplayName ~= player.Name then
		table.insert(lines, player.DisplayName .. " @" .. player.Name)
	else
		table.insert(lines, player.Name)
	end

	if Config.InventoryThreatMode and Config.ShowThreatName then
		local threatLabel = getThreatLabel(player)

		if threatLabel then
			table.insert(lines, threatLabel)
		end
	end

	if Config.ShowTeamName then
		table.insert(lines, "Team: " .. getTeamName(player))
	end

	if Config.ShowDistance and localRoot and root then
		local dist = math.floor((root.Position - localRoot.Position).Magnitude)
		table.insert(lines, tostring(dist) .. " studs")
	end

	return table.concat(lines, "\n")
end

--==================================================
-- NOTIFY
--==================================================

local function notify(titleText, descText, duration)
	if not Runtime.NotifyHolder then
		return
	end

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 0)
	frame.BackgroundColor3 = Theme.Background
	frame.BackgroundTransparency = 0.05
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = true
	frame.Parent = Runtime.NotifyHolder

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Stroke
	stroke.Thickness = 2
	stroke.Parent = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -20, 0, 20)
	title.Position = UDim2.new(0, 10, 0, 5)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.TextColor3 = Theme.Accent
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Text = tostring(titleText)
	title.Parent = frame

	local desc = Instance.new("TextLabel")
	desc.BackgroundTransparency = 1
	desc.Size = UDim2.new(1, -20, 0, 30)
	desc.Position = UDim2.new(0, 10, 0, 24)
	desc.Font = Enum.Font.Gotham
	desc.TextSize = 12
	desc.TextColor3 = Theme.Text
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextWrapped = true
	desc.Text = tostring(descText)
	desc.Parent = frame

	TweenService:Create(
		frame,
		TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{Size = UDim2.new(1, 0, 0, 62)}
	):Play()

	task.delay(duration or 2.5, function()
		if not frame or not frame.Parent then
			return
		end

		local tw = TweenService:Create(
			frame,
			TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
			{Size = UDim2.new(1, 0, 0, 0)}
		)

		tw:Play()
		tw.Completed:Wait()
		safeDestroy(frame)
	end)
end

--==================================================
-- ESP CORE
--==================================================

local function removeESP(player)
	local entry = Runtime.ESP[player]
	if not entry then
		return
	end

	safeDestroy(entry.Highlight)
	safeDestroy(entry.Billboard)

	Runtime.ESP[player] = nil
end

local function createOrUpdateESP(player)
	if not shouldShowPlayer(player) then
		removeESP(player)
		return
	end

	local character = getCharacter(player)
	local root = getRoot(character)
	local head = getHead(character)

	if not character or not root or not head then
		removeESP(player)
		return
	end

	local color = getESPColor(player)

	local entry = Runtime.ESP[player]
	if not entry then
		entry = {}
		Runtime.ESP[player] = entry
	end

	if Config.Highlight then
		if not entry.Highlight or not entry.Highlight.Parent then
			local highlight = Instance.new("Highlight")
			highlight.Name = "DW_Universal_ESP"
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Parent = character
			entry.Highlight = highlight
		end

		entry.Highlight.Adornee = character
		entry.Highlight.FillColor = color
		entry.Highlight.OutlineColor = color
		entry.Highlight.FillTransparency = Config.FillTransparency
		entry.Highlight.OutlineTransparency = Config.OutlineTransparency
		entry.Highlight.Enabled = true
	else
		safeDestroy(entry.Highlight)
		entry.Highlight = nil
	end

	if Config.ShowLabels then
		if not entry.Billboard or not entry.Billboard.Parent then
			local billboard = Instance.new("BillboardGui")
			billboard.Name = "DW_Universal_ESP_Text"
			billboard.Size = UDim2.new(0, 230, 0, 72)
			billboard.StudsOffset = Vector3.new(0, 3.6, 0)
			billboard.AlwaysOnTop = true
			billboard.LightInfluence = 0
			billboard.MaxDistance = Config.MaxDistance
			billboard.Parent = PlayerGui

			local text = Instance.new("TextLabel")
			text.Name = "TextLabel"
			text.Size = UDim2.new(1, 0, 1, 0)
			text.BackgroundTransparency = 1
			text.Font = Enum.Font.GothamBold
			text.TextSize = 13
			text.TextStrokeTransparency = 0
			text.TextStrokeColor3 = Theme.Black
			text.TextWrapped = true
			text.Parent = billboard

			entry.Billboard = billboard
			entry.Text = text
		end

		entry.Billboard.Adornee = head
		entry.Billboard.Enabled = true
		entry.Billboard.MaxDistance = Config.MaxDistance

		entry.Text.Text = buildLabelText(player)
		entry.Text.TextColor3 = color
	else
		safeDestroy(entry.Billboard)
		entry.Billboard = nil
		entry.Text = nil
	end
end

local function clearAllESP()
	for player in pairs(Runtime.ESP) do
		removeESP(player)
	end
end

local function getVisibleCount()
	local visibleCount = 0

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and shouldShowPlayer(player) then
			visibleCount += 1
		end
	end

	return visibleCount
end

local function updateCountLabel()
	if Runtime.CountLabel then
		Runtime.CountLabel.Text = "  Visible: " .. tostring(getVisibleCount())
	end
end

local function refreshESP()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			createOrUpdateESP(player)
		end
	end

	for player in pairs(Runtime.ESP) do
		if not player.Parent or not shouldShowPlayer(player) then
			removeESP(player)
		end
	end

	updateCountLabel()
end

--==================================================
-- SMART ESP REFRESH
--==================================================

local SmartRefresh = {
	Queued = {},
	Busy = false,
	DebounceTime = 0.08,
}

local function processSmartQueue()
	repeat
		task.wait(SmartRefresh.DebounceTime)

		local queued = SmartRefresh.Queued
		SmartRefresh.Queued = {}

		for targetPlayer, info in pairs(queued) do
			if info.ForceRemove then
				removeESP(targetPlayer)
			end

			if targetPlayer and targetPlayer.Parent then
				createOrUpdateESP(targetPlayer)
			else
				removeESP(targetPlayer)
			end
		end

		updateCountLabel()
	until next(SmartRefresh.Queued) == nil

	SmartRefresh.Busy = false
end

local function queueESPRefresh(player, forceRemove)
	if not player or player == LocalPlayer then
		return
	end

	local old = SmartRefresh.Queued[player]
	SmartRefresh.Queued[player] = {
		ForceRemove = (forceRemove and true or false) or (old and old.ForceRemove) or false,
		Time = os.clock(),
	}

	if SmartRefresh.Busy then
		return
	end

	SmartRefresh.Busy = true
	task.spawn(processSmartQueue)
end

local function queueAllESPRefresh(forceRemove)
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			queueESPRefresh(player, forceRemove)
		end
	end
end

local function isESPEntryBroken(player, entry)
	if not entry then
		return false
	end

	local character = getCharacter(player)
	local head = getHead(character)

	local highlightBroken = entry.Highlight and not entry.Highlight.Parent
	local billboardBroken = entry.Billboard and not entry.Billboard.Parent
	local adorneeBroken = entry.Billboard and Config.ShowLabels and entry.Billboard.Adornee ~= head
	local highlightAdorneeBroken = entry.Highlight and Config.Highlight and entry.Highlight.Adornee ~= character

	return highlightBroken or billboardBroken or adorneeBroken or highlightAdorneeBroken
end

--==================================================
-- STATUS
--==================================================

local function updateStatusText()
	if Runtime.StatusLabel then
		Runtime.StatusLabel.Text = "  Status: " .. (Config.Enabled and "ON" or "OFF")
	end

	if Runtime.TeamLabel then
		local teamText = getTeamName(LocalPlayer)
		Runtime.TeamLabel.Text = "       Your Team: " .. teamText
		Runtime.TeamLabel.TextColor3 = Theme.Text
	end

	if Runtime.TeamDot then
		Runtime.TeamDot.BackgroundColor3 = getTeamColor(LocalPlayer)
	end
end

--==================================================
-- INTRO
--==================================================

local function playIntro(gui)
	local welcomeBlur = Instance.new("Frame")
	welcomeBlur.Name = "WelcomeBlur"
	welcomeBlur.Size = UDim2.new(1, 0, 1, 0)
	welcomeBlur.Position = UDim2.new(0, 0, 0, 0)
	welcomeBlur.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	welcomeBlur.BackgroundTransparency = 0.45
	welcomeBlur.BorderSizePixel = 0
	welcomeBlur.ZIndex = 100
	welcomeBlur.Parent = gui

	local welcomeFrame = Instance.new("Frame")
	welcomeFrame.Name = "WelcomeFrame"
	welcomeFrame.Size = UDim2.new(0, 0, 0, 0)
	welcomeFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	welcomeFrame.BackgroundColor3 = Theme.Background
	welcomeFrame.BorderSizePixel = 0
	welcomeFrame.ClipsDescendants = true
	welcomeFrame.ZIndex = 101
	welcomeFrame.Parent = welcomeBlur

	local corner = Instance.new("UICorner")
	corner.CornerRadius = Theme.CornerRadius
	corner.Parent = welcomeFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Accent
	stroke.Thickness = 2
	stroke.Parent = welcomeFrame

	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.new(0, 80, 0, 80)
	avatar.Position = UDim2.new(0.5, -40, 0.15, 0)
	avatar.BackgroundTransparency = 1
	avatar.ZIndex = 102
	avatar.Parent = welcomeFrame

	local okThumb, thumb = pcall(function()
		return Players:GetUserThumbnailAsync(
			LocalPlayer.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size150x150
		)
	end)

	if okThumb and thumb then
		avatar.Image = thumb
	end

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(1, 0)
	avatarCorner.Parent = avatar

	local welcomeText = Instance.new("TextLabel")
	welcomeText.Text = "Welcome Back, " .. tostring(LocalPlayer.DisplayName)
	welcomeText.Size = UDim2.new(1, -20, 0, 25)
	welcomeText.Position = UDim2.new(0, 10, 0.58, 0)
	welcomeText.BackgroundTransparency = 1
	welcomeText.TextColor3 = Theme.Text
	welcomeText.Font = Enum.Font.GothamBold
	welcomeText.TextSize = 18
	welcomeText.TextTruncate = Enum.TextTruncate.AtEnd
	welcomeText.ZIndex = 102
	welcomeText.Parent = welcomeFrame

	local loadingText = Instance.new("TextLabel")
	loadingText.Text = "Initializing."
	loadingText.Size = UDim2.new(1, 0, 0, 20)
	loadingText.Position = UDim2.new(0, 0, 0.75, 0)
	loadingText.BackgroundTransparency = 1
	loadingText.TextColor3 = Theme.TextDim
	loadingText.Font = Enum.Font.Gotham
	loadingText.TextSize = 14
	loadingText.ZIndex = 102
	loadingText.Parent = welcomeFrame

	local loadingBack = Instance.new("Frame")
	loadingBack.Size = UDim2.new(0, 230, 0, 6)
	loadingBack.Position = UDim2.new(0.5, -115, 0.88, 0)
	loadingBack.BackgroundColor3 = Theme.Sidebar
	loadingBack.BorderSizePixel = 0
	loadingBack.ZIndex = 102
	loadingBack.Parent = welcomeFrame

	local loadingBackCorner = Instance.new("UICorner")
	loadingBackCorner.CornerRadius = UDim.new(1, 0)
	loadingBackCorner.Parent = loadingBack

	local loadingBar = Instance.new("Frame")
	loadingBar.Size = UDim2.new(0, 0, 1, 0)
	loadingBar.BackgroundColor3 = Theme.Accent
	loadingBar.BorderSizePixel = 0
	loadingBar.ZIndex = 103
	loadingBar.Parent = loadingBack

	local loadingBarCorner = Instance.new("UICorner")
	loadingBarCorner.CornerRadius = UDim.new(1, 0)
	loadingBarCorner.Parent = loadingBar

	TweenService:Create(
		welcomeFrame,
		TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			Size = UDim2.new(0, 320, 0, 210),
			Position = UDim2.new(0.5, -160, 0.5, -105),
		}
	):Play()

	TweenService:Create(
		loadingBar,
		TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.new(0.35, 0, 1, 0)}
	):Play()

	task.wait(0.85)

	loadingText.Text = "Loading Assets."
	TweenService:Create(
		loadingBar,
		TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.new(0.72, 0, 1, 0)}
	):Play()

	task.wait(0.75)

	loadingText.Text = "Injecting."
	TweenService:Create(
		loadingBar,
		TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.new(1, 0, 1, 0)}
	):Play()

	task.wait(0.6)

	TweenService:Create(
		welcomeFrame,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In),
		{
			Size = UDim2.new(0, 0, 0, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0),
		}
	):Play()

	TweenService:Create(
		welcomeBlur,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{BackgroundTransparency = 1}
	):Play()

	task.wait(0.4)

	safeDestroy(welcomeFrame)
	safeDestroy(welcomeBlur)
end

--==================================================
-- GUI
--==================================================

local function createGui()
	local gui = Instance.new("ScreenGui")
	gui.Name = "DandysWorld_macOS_UniversalESP"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = PlayerGui
	Runtime.Gui = gui

	playIntro(gui)

	local notifyHolder = Instance.new("Frame")
	notifyHolder.Name = "Notifications"
	notifyHolder.Size = UDim2.new(0, 300, 1, -20)
	notifyHolder.Position = UDim2.new(1, -315, 0, 10)
	notifyHolder.BackgroundTransparency = 1
	notifyHolder.Parent = gui
	Runtime.NotifyHolder = notifyHolder

	local nLayout = Instance.new("UIListLayout")
	nLayout.Padding = UDim.new(0, 8)
	nLayout.SortOrder = Enum.SortOrder.LayoutOrder
	nLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	nLayout.Parent = notifyHolder

	local main = Instance.new("Frame")
	main.Name = "Window"
	main.Size = Config.WindowClosedSize
	main.Position = UDim2.new(0.5, -40, 0.5, -22)
	main.BackgroundColor3 = Theme.Background
	main.BackgroundTransparency = 1
	main.BorderSizePixel = 0
	main.ClipsDescendants = true
	main.Parent = gui
	Runtime.Main = main

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = Theme.CornerRadius
	mainCorner.Parent = main

	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color = Theme.Stroke
	mainStroke.Thickness = 1
	mainStroke.Parent = main

	TweenService:Create(
		main,
		TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			Size = Config.WindowOpenSize,
			Position = UDim2.new(0.5, -325, 0.5, -210),
			BackgroundTransparency = 0.05,
		}
	):Play()

	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, 180, 1, 0)
	sidebar.BackgroundColor3 = Theme.Sidebar
	sidebar.BorderSizePixel = 0
	sidebar.Parent = main
	Runtime.Sidebar = sidebar

	local sideCorner = Instance.new("UICorner")
	sideCorner.CornerRadius = Theme.CornerRadius
	sideCorner.Parent = sidebar

	local sideFix = Instance.new("Frame")
	sideFix.Size = UDim2.new(0, 10, 1, 0)
	sideFix.Position = UDim2.new(1, -10, 0, 0)
	sideFix.BackgroundColor3 = Theme.Sidebar
	sideFix.BorderSizePixel = 0
	sideFix.Parent = sidebar

	local sidebarGradient = Instance.new("UIGradient")
	sidebarGradient.Rotation = 45
	sidebarGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Theme.Sidebar),
	})
	sidebarGradient.Parent = sidebar

	local controlsHolder = Instance.new("Frame")
	controlsHolder.Size = UDim2.new(0, 70, 0, 20)
	controlsHolder.Position = UDim2.new(0, 18, 0, 18)
	controlsHolder.BackgroundTransparency = 1
	controlsHolder.Parent = main

	local function createDot(color, offset)
		local dot = Instance.new("Frame")
		dot.Size = UDim2.new(0, 12, 0, 12)
		dot.Position = UDim2.new(0, offset, 0, 0)
		dot.BackgroundColor3 = color
		dot.BorderSizePixel = 0
		dot.Parent = controlsHolder

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = dot

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 1, 0)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.Parent = dot

		return btn
	end

	local closeBtn = createDot(Theme.Destructive, 0)
	local hideBtn = createDot(Theme.Gold, 20)
	local openBtn = createDot(Theme.Success, 40)

	local sideTitle = Instance.new("TextLabel")
	sideTitle.Text = "Poorly Scripted"
	sideTitle.TextColor3 = Theme.TextDim
	sideTitle.Font = Enum.Font.GothamBold
	sideTitle.TextSize = 13
	sideTitle.Size = UDim2.new(1, -40, 0, 20)
	sideTitle.Position = UDim2.new(0, 20, 0, 60)
	sideTitle.BackgroundTransparency = 1
	sideTitle.TextXAlignment = Enum.TextXAlignment.Left
	sideTitle.TextTruncate = Enum.TextTruncate.AtEnd
	sideTitle.Parent = sidebar

	local profileFrame = Instance.new("Frame")
	profileFrame.Size = UDim2.new(1, -24, 0, 82)
	profileFrame.Position = UDim2.new(0, 12, 0, 88)
	profileFrame.BackgroundColor3 = Theme.Panel
	profileFrame.BorderSizePixel = 0
	profileFrame.Parent = sidebar

	local profileCorner = Instance.new("UICorner")
	profileCorner.CornerRadius = UDim.new(0, 12)
	profileCorner.Parent = profileFrame

	local profileStroke = Instance.new("UIStroke")
	profileStroke.Color = Theme.Stroke
	profileStroke.Thickness = 1
	profileStroke.Parent = profileFrame

	local profileTitle = Instance.new("TextLabel")
	profileTitle.BackgroundTransparency = 1
	profileTitle.Size = UDim2.new(1, -16, 0, 20)
	profileTitle.Position = UDim2.new(0, 8, 0, 8)
	profileTitle.Font = Enum.Font.GothamBold
	profileTitle.TextSize = 12
	profileTitle.TextColor3 = Theme.Accent
	profileTitle.TextXAlignment = Enum.TextXAlignment.Left
	profileTitle.TextTruncate = Enum.TextTruncate.AtEnd
	profileTitle.Text = "Universal ESP"
	profileTitle.Parent = profileFrame

	local profileSub = Instance.new("TextLabel")
	profileSub.BackgroundTransparency = 1
	profileSub.Size = UDim2.new(1, -16, 0, 42)
	profileSub.Position = UDim2.new(0, 8, 0, 30)
	profileSub.Font = Enum.Font.Gotham
	profileSub.TextSize = 11
	profileSub.TextColor3 = Theme.TextDim
	profileSub.TextWrapped = true
	profileSub.TextXAlignment = Enum.TextXAlignment.Left
	profileSub.Text = "Team colors\nSmart refresh"
	profileSub.Parent = profileFrame

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -200, 1, -20)
	content.Position = UDim2.new(0, 190, 0, 10)
	content.BackgroundTransparency = 1
	content.Parent = main
	Runtime.Content = content

	local pageTitle = Instance.new("TextLabel")
	pageTitle.BackgroundTransparency = 1
	pageTitle.Size = UDim2.new(1, -20, 0, 34)
	pageTitle.Position = UDim2.new(0, 10, 0, 10)
	pageTitle.Font = Enum.Font.GothamBold
	pageTitle.TextSize = 22
	pageTitle.TextColor3 = Theme.Text
	pageTitle.TextXAlignment = Enum.TextXAlignment.Left
	pageTitle.Text = "Visuals"
	pageTitle.Parent = content

	local pageSub = Instance.new("TextLabel")
	pageSub.BackgroundTransparency = 1
	pageSub.Size = UDim2.new(1, -20, 0, 20)
	pageSub.Position = UDim2.new(0, 10, 0, 42)
	pageSub.Font = Enum.Font.Gotham
	pageSub.TextSize = 12
	pageSub.TextColor3 = Theme.TextDim
	pageSub.TextXAlignment = Enum.TextXAlignment.Left
	pageSub.Text = "Universal player ESP with smart reload"
	pageSub.TextTruncate = Enum.TextTruncate.AtEnd
	pageSub.Parent = content

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "ContentScroll"
	scroll.Size = UDim2.new(1, -20, 1, -76)
	scroll.Position = UDim2.new(0, 10, 0, 70)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = Theme.Accent
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ClipsDescendants = true
	scroll.Parent = content

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll

	local padding = Instance.new("UIPadding")
	padding.PaddingBottom = UDim.new(0, 12)
	padding.Parent = scroll

	local function makeInfoLabel(text)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -8, 0, 34)
		label.BackgroundColor3 = Theme.Panel
		label.BorderSizePixel = 0
		label.Font = Enum.Font.GothamBold
		label.TextSize = 12
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextColor3 = Theme.Text
		label.Text = "  " .. text
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.ClipsDescendants = true
		label.Parent = scroll

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 10)
		c.Parent = label

		local s = Instance.new("UIStroke")
		s.Color = Theme.Stroke
		s.Thickness = 1
		s.Parent = label

		return label
	end

	Runtime.StatusLabel = makeInfoLabel("Status: ON")
	Runtime.TeamLabel = makeInfoLabel("Your Team: ...")
	Runtime.CountLabel = makeInfoLabel("Visible: 0")

	local teamDot = Instance.new("Frame")
	teamDot.Name = "TeamColorDot"
	teamDot.Size = UDim2.new(0, 10, 0, 10)
	teamDot.Position = UDim2.new(0, 10, 0.5, -5)
	teamDot.BackgroundColor3 = Theme.Accent
	teamDot.BorderSizePixel = 0
	teamDot.Parent = Runtime.TeamLabel

	local teamDotCorner = Instance.new("UICorner")
	teamDotCorner.CornerRadius = UDim.new(1, 0)
	teamDotCorner.Parent = teamDot

	local teamDotStroke = Instance.new("UIStroke")
	teamDotStroke.Color = Theme.Stroke
	teamDotStroke.Thickness = 1
	teamDotStroke.Parent = teamDot

	Runtime.TeamDot = teamDot

	local function makeToggle(name, desc, default, callback)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -8, 0, 46)
		row.BackgroundColor3 = Theme.Panel
		row.BorderSizePixel = 0
		row.ClipsDescendants = true
		row.Parent = scroll

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 10)
		rowCorner.Parent = row

		local rowStroke = Instance.new("UIStroke")
		rowStroke.Color = Theme.Stroke
		rowStroke.Thickness = 1
		rowStroke.Parent = row

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, -82, 0, 20)
		label.Position = UDim2.new(0, 10, 0, 5)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 12
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextColor3 = Theme.Text
		label.Text = name
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.Parent = row

		local descLabel = Instance.new("TextLabel")
		descLabel.BackgroundTransparency = 1
		descLabel.Size = UDim2.new(1, -82, 0, 16)
		descLabel.Position = UDim2.new(0, 10, 0, 25)
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextSize = 10
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextColor3 = Theme.TextDim
		descLabel.Text = desc or ""
		descLabel.TextTruncate = Enum.TextTruncate.AtEnd
		descLabel.Parent = row

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 56, 0, 26)
		btn.Position = UDim2.new(1, -66, 0.5, -13)
		btn.BorderSizePixel = 0
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 11
		btn.Parent = row

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 9)
		btnCorner.Parent = btn

		local value = default and true or false

		local function setVisual(v)
			value = v and true or false
			btn.Text = value and "ON" or "OFF"
			btn.TextColor3 = value and Theme.Success or Theme.Destructive
			btn.BackgroundColor3 = value and Color3.fromRGB(235, 255, 235) or Color3.fromRGB(255, 235, 235)
		end

		setVisual(value)

		btn.MouseButton1Click:Connect(function()
			setVisual(not value)
			callback(value)
			queueAllESPRefresh(true)
		end)

		return setVisual
	end

	Runtime.SetEnabledVisual = makeToggle("ESP Enabled", "Interruptor maestro", Config.Enabled, function(v)
		Config.Enabled = v
		if not v then
			clearAllESP()
		else
			queueAllESPRefresh(true)
		end
		notify("ESP", "Enabled: " .. tostring(v), 2)
	end)

	Runtime.SetPlayersVisual = makeToggle("Player ESP", "Muestra jugadores", Config.Players, function(v)
		Config.Players = v
		if not v then
			clearAllESP()
		else
			queueAllESPRefresh(true)
		end
	end)

	Runtime.SetTeamColorVisual = makeToggle("Team Colors", "Usa el color del Team", Config.UseTeamColor, function(v)
		Config.UseTeamColor = v
	end)

	Runtime.SetHideOwnTeamVisual = makeToggle("Hide My Team", "Oculta jugadores de tu equipo", Config.HideOwnTeam, function(v)
		Config.HideOwnTeam = v
	end)

	Runtime.SetNeutralVisual = makeToggle("Show Neutral", "Muestra players sin team", Config.ShowNeutral, function(v)
		Config.ShowNeutral = v
	end)

	Runtime.SetLabelsVisual = makeToggle("Labels", "Nombre, team y distancia", Config.ShowLabels, function(v)
		Config.ShowLabels = v
	end)

	Runtime.SetDistanceVisual = makeToggle("Distance", "Muestra studs", Config.ShowDistance, function(v)
		Config.ShowDistance = v
	end)

	Runtime.SetTeamNameVisual = makeToggle("Team Name", "Muestra nombre de equipo", Config.ShowTeamName, function(v)
		Config.ShowTeamName = v
	end)

	Runtime.SetDisplayNameVisual = makeToggle("DisplayName", "Display + username", Config.ShowDisplayName, function(v)
		Config.ShowDisplayName = v
	end)

	Runtime.SetHighlightVisual = makeToggle("Highlight", "Contorno del personaje", Config.Highlight, function(v)
		Config.Highlight = v
	end)

	Runtime.SetInventoryThreatVisual = makeToggle("Inventory Threat", "Knife rojo | Gun azul", Config.InventoryThreatMode, function(v)
		Config.InventoryThreatMode = v
	end)

	Runtime.SetThreatNameVisual = makeToggle("Threat Name", "Muestra Knife/Gun en label", Config.ShowThreatName, function(v)
		Config.ShowThreatName = v
	end)

	closeBtn.MouseButton1Click:Connect(function()
		notify("GUI", "Closing ESP UI", 1.5)
		task.wait(0.15)
		if _G.UniversalTeamESP_DWStyle and _G.UniversalTeamESP_DWStyle.Cleanup then
			_G.UniversalTeamESP_DWStyle.Cleanup()
		end
	end)

	hideBtn.MouseButton1Click:Connect(function()
		Runtime.GuiOpen = false

		if Runtime.Sidebar then
			Runtime.Sidebar.Visible = false
		end

		if Runtime.Content then
			Runtime.Content.Visible = false
		end

		TweenService:Create(
			main,
			TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{
				Size = Config.WindowClosedSize,
				Position = UDim2.new(0.5, -40, 0.5, -22),
			}
		):Play()
	end)

	openBtn.MouseButton1Click:Connect(function()
		Runtime.GuiOpen = true

		TweenService:Create(
			main,
			TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{
				Size = Config.WindowOpenSize,
				Position = UDim2.new(0.5, -325, 0.5, -210),
			}
		):Play()

		task.delay(0.1, function()
			if Runtime.Sidebar then
				Runtime.Sidebar.Visible = true
			end

			if Runtime.Content then
				Runtime.Content.Visible = true
			end
		end)
	end)

	-- DRAG
	do
		local dragZone = Instance.new("Frame")
		dragZone.Name = "DragZone"
		dragZone.Size = UDim2.new(1, 0, 0, 44)
		dragZone.Position = UDim2.new(0, 0, 0, 0)
		dragZone.BackgroundTransparency = 1
		dragZone.Parent = main

		local dragging = false
		local dragStart = nil
		local startPos = nil

		dragZone.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = main.Position

				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)

		bind(UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				main.Position = UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset + delta.X,
					startPos.Y.Scale,
					startPos.Y.Offset + delta.Y
				)
			end
		end))
	end
end

--==================================================
-- LOOP
--==================================================

local function startLoop()
	Runtime.LoopToken += 1
	local token = Runtime.LoopToken

	task.spawn(function()
		local lastFullReload = os.clock()

		while token == Runtime.LoopToken do
			updateStatusText()

			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer then
					local entry = Runtime.ESP[player]

					if entry then
						if isESPEntryBroken(player, entry) then
							queueESPRefresh(player, true)
						else
							createOrUpdateESP(player)
						end
					else
						if shouldShowPlayer(player) then
							queueESPRefresh(player, false)
						end
					end
				end
			end

			if Config.AutoFullReload then
				if os.clock() - lastFullReload >= Config.FullReloadDelay then
					lastFullReload = os.clock()
					queueAllESPRefresh(true)
				end
			end

			updateCountLabel()
			task.wait(Config.RefreshDelay)
		end
	end)
end

--==================================================
-- PLAYER HOOKS
--==================================================

local function hookPlayer(player)
	if not player or player == LocalPlayer then
		return
	end

	local watchedContainers = {}

	local function refreshPlayerESP(forceRemove)
		queueESPRefresh(player, forceRemove)
	end

	local function watchContainer(container)
		if not container then
			return
		end

		if watchedContainers[container] then
			return
		end

		watchedContainers[container] = true

		bind(container.ChildAdded:Connect(function(child)
			if child:IsA("Tool")
				or child.Name == "Head"
				or child.Name == "HumanoidRootPart"
				or child.Name == "UpperTorso"
				or child.Name == "Torso"
			then
				task.wait(0.05)
				refreshPlayerESP(true)
			end
		end))

		bind(container.ChildRemoved:Connect(function(child)
			if child:IsA("Tool")
				or child.Name == "Head"
				or child.Name == "HumanoidRootPart"
				or child.Name == "UpperTorso"
				or child.Name == "Torso"
			then
				task.wait(0.05)
				refreshPlayerESP(true)
			end
		end))
	end

	local function watchBackpack()
		local backpack = getBackpack(player)
		if backpack then
			watchContainer(backpack)
		end
	end

	local function watchCharacter(character)
		if not character then
			return
		end

		removeESP(player)

		watchContainer(character)
		watchBackpack()

		bind(character.AncestryChanged:Connect(function(_, parent)
			if not parent then
				removeESP(player)
			else
				refreshPlayerESP(true)
			end
		end))

		task.spawn(function()
			for i = 1, 30 do
				if character and character.Parent and getRoot(character) and getHead(character) then
					break
				end

				task.wait(0.08)
			end

			refreshPlayerESP(true)
		end)

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			bind(humanoid.Died:Connect(function()
				removeESP(player)

				task.delay(0.15, function()
					refreshPlayerESP(true)
				end)
			end))

			bind(humanoid:GetPropertyChangedSignal("Health"):Connect(function()
				if humanoid.Health <= 0 then
					removeESP(player)
				end
			end))
		end
	end

	bind(player.CharacterAdded:Connect(function(character)
		task.wait(0.1)
		watchCharacter(character)
	end))

	bind(player.CharacterRemoving:Connect(function()
		removeESP(player)
	end))

	watchBackpack()

	bind(player.ChildAdded:Connect(function(child)
		if child:IsA("Backpack") or child.Name == "Backpack" then
			watchContainer(child)
			task.wait(0.05)
			refreshPlayerESP(true)
		end
	end))

	bind(player:GetPropertyChangedSignal("Team"):Connect(function()
		refreshPlayerESP(true)
	end))

	bind(player:GetPropertyChangedSignal("TeamColor"):Connect(function()
		refreshPlayerESP(true)
	end))

	if player.Character then
		watchCharacter(player.Character)
	end
end

--==================================================
-- INPUT / EVENTS
--==================================================

bind(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Config.ToggleKey then
		if Runtime.Main then
			Runtime.Main.Visible = not Runtime.Main.Visible
			notify("GUI", Runtime.Main.Visible and "Menu abierto" or "Menu cerrado", 1.5)
		end
	end
end))

bind(Players.PlayerAdded:Connect(function(player)
	hookPlayer(player)

	task.delay(0.4, function()
		queueESPRefresh(player, true)
	end)
end))

bind(Players.PlayerRemoving:Connect(function(player)
	removeESP(player)
end))

for _, player in ipairs(Players:GetPlayers()) do
	hookPlayer(player)
end

bind(LocalPlayer.CharacterAdded:Connect(function()
	task.wait(0.3)
	updateStatusText()
	queueAllESPRefresh(true)
end))

bind(LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
	updateStatusText()
	queueAllESPRefresh(true)
end))

bind(LocalPlayer:GetPropertyChangedSignal("TeamColor"):Connect(function()
	updateStatusText()
	queueAllESPRefresh(true)
end))

--==================================================
-- CLEANUP
--==================================================

local function cleanup()
	Runtime.LoopToken += 1

	for _, conn in ipairs(Runtime.Connections) do
		safeDisconnect(conn)
	end

	table.clear(Runtime.Connections)
	SmartRefresh.Queued = {}
	SmartRefresh.Busy = false

	clearAllESP()

	safeDestroy(Runtime.Gui)

	Runtime.Gui = nil
	Runtime.Main = nil
	Runtime.Sidebar = nil
	Runtime.Content = nil
	Runtime.NotifyHolder = nil
	Runtime.StatusLabel = nil
	Runtime.TeamLabel = nil
	Runtime.TeamDot = nil
	Runtime.CountLabel = nil
end

_G.UniversalTeamESP_DWStyle.Cleanup = cleanup

--==================================================
-- START
--==================================================

createGui()
updateStatusText()
refreshESP()
startLoop()

notify("Universal ESP", "Cargado. Smart reload ON | Knife rojo | Gun azul", 3)
