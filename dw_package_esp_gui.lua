--// DW PACKAGE ESP GUI - FINAL ATTRIBUTE RARITYCLASS FIX
--// RarityClass = Attribute (package or Config) [1..5]
--// Type / Size / Color = StringValue inside Config
--// Value = Attribute on package
--// Billboard text uses RootPart ONLY

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PackagesFolder = Workspace:WaitForChild("Packages")

getgenv().DWPackageESPState = getgenv().DWPackageESPState or {}
local State = getgenv().DWPackageESPState

pcall(function()
	if State.Connection then
		State.Connection:Disconnect()
	end
end)

pcall(function()
	if CoreGui:FindFirstChild("DW_PackageESP_GUI") then
		CoreGui.DW_PackageESP_GUI:Destroy()
	end
	if CoreGui:FindFirstChild("DW_PackageESP_FOLDER") then
		CoreGui.DW_PackageESP_FOLDER:Destroy()
	end
end)

State.Cache = {}

local Theme = {
	Background = Color3.fromRGB(255, 240, 245),
	Sidebar = Color3.fromRGB(255, 228, 230),
	Text = Color3.fromRGB(80, 50, 60),
	TextDim = Color3.fromRGB(150, 110, 130),
	Accent = Color3.fromRGB(255, 153, 204),
	Stroke = Color3.fromRGB(255, 200, 215),
	Success = Color3.fromRGB(119, 221, 119),
	Destructive = Color3.fromRGB(255, 105, 97),
	Gold = Color3.fromRGB(255, 215, 0),
	CornerRadius = UDim.new(0, 14),
}

local TypeInfo = {
	[1] = {Name = "Common", Color = Color3.fromRGB(220, 220, 220)},
	[2] = {Name = "Rare", Color = Color3.fromRGB(90, 170, 255)},
	[3] = {Name = "Epic", Color = Color3.fromRGB(185, 110, 255)},
	[4] = {Name = "Legendary", Color = Color3.fromRGB(255, 180, 70)},
	[5] = {Name = "Mythic", Color = Color3.fromRGB(255, 90, 170)},
}

local ESP = {
	Enabled = true,
	ShowName = true,
	ShowRarity = true,
	ShowType = true,
	ShowSize = true,
	ShowValue = true,
	ShowColor = true,
	RefreshRate = 0.35,
	Filters = {
		[1] = true,
		[2] = true,
		[3] = true,
		[4] = true,
		[5] = true,
	},
	Folder = nil,
}

local UI = {
	StatusLabel = nil,
	ReasonLabel = nil,
	NotificationHolder = nil,
}

local function destroyIf(obj)
	if obj then
		pcall(function()
			obj:Destroy()
		end)
	end
end

local function getCharacter()
	return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
	local char = getCharacter()
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
	local char = getCharacter()
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function parseNumber(v)
	if v == nil then
		return nil
	end

	if typeof(v) == "number" then
		return v
	end

	local s = tostring(v)
	s = s:gsub("%$", "")
	s = s:gsub(",", "")
	s = s:gsub("%s+", "")
	local n = tonumber(s)
	if n then
		return n
	end

	local filtered = s:match("[-%d%.]+")
	if filtered then
		return tonumber(filtered)
	end

	return nil
end

local function notify(title, text, duration)
	if not UI.NotificationHolder then return end

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 0)
	frame.BackgroundColor3 = Theme.Background
	frame.BackgroundTransparency = 0.06
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = true
	frame.Parent = UI.NotificationHolder

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Stroke
	stroke.Thickness = 2
	stroke.Parent = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -20, 0, 18)
	titleLabel.Position = UDim2.new(0, 10, 0, 6)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 13
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextColor3 = Theme.Accent
	titleLabel.Text = title
	titleLabel.Parent = frame

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -20, 0, 30)
	descLabel.Position = UDim2.new(0, 10, 0, 22)
	descLabel.BackgroundTransparency = 1
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 12
	descLabel.TextWrapped = true
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.TextColor3 = Theme.Text
	descLabel.Text = text
	descLabel.Parent = frame

	frame:TweenSize(UDim2.new(1, 0, 0, 60), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true)

	task.delay(duration or 2.5, function()
		if frame and frame.Parent then
			frame:TweenSize(UDim2.new(1, 0, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quart, 0.2, true)
			task.wait(0.2)
			destroyIf(frame)
		end
	end)
end

local function getConfigFolder(packageObj)
	return packageObj:FindFirstChild("Config")
end

local function getStringValue(container, name)
	if not container then
		return nil
	end

	local child = container:FindFirstChild(name)
	if child and child:IsA("StringValue") then
		return child.Value
	end

	return nil
end

local function getRarityNumber(packageObj)
	local directAttr = packageObj:GetAttribute("RarityClass")
	if directAttr ~= nil then
		local n = parseNumber(directAttr)
		if n then
			return math.clamp(math.floor(n), 1, 5)
		end
	end

	local config = getConfigFolder(packageObj)
	if config then
		local configAttr = config:GetAttribute("RarityClass")
		if configAttr ~= nil then
			local n = parseNumber(configAttr)
			if n then
				return math.clamp(math.floor(n), 1, 5)
			end
		end

		local rarityString = getStringValue(config, "RarityClass")
		if rarityString ~= nil then
			local n = parseNumber(rarityString)
			if n then
				return math.clamp(math.floor(n), 1, 5)
			end
		end
	end

	return nil
end

local function getPackageTypeText(packageObj)
	local config = getConfigFolder(packageObj)
	return getStringValue(config, "Type")
end

local function getPackageSize(packageObj)
	local config = getConfigFolder(packageObj)
	return getStringValue(config, "Size")
end

local function getPackageColorText(packageObj)
	local config = getConfigFolder(packageObj)
	return getStringValue(config, "Color")
end

local function getPackageValue(packageObj)
	local direct = packageObj:GetAttribute("Value")
	if direct ~= nil then
		return direct
	end

	local config = getConfigFolder(packageObj)
	if config then
		local cfgAttr = config:GetAttribute("Value")
		if cfgAttr ~= nil then
			return cfgAttr
		end
	end

	return nil
end

local function getRootPartStrict(packageObj)
	if not packageObj then
		return nil
	end

	local rp = packageObj:FindFirstChild("RootPart", true)
	if rp and rp:IsA("BasePart") then
		return rp
	end

	return nil
end

local function getAdorneeStrict(packageObj)
	if packageObj:IsA("Model") then
		return packageObj
	end
	return getRootPartStrict(packageObj)
end

local function getESPColor(packageObj)
	local rarity = getRarityNumber(packageObj)
	if rarity and TypeInfo[rarity] then
		return TypeInfo[rarity].Color
	end
	return Color3.fromRGB(255, 255, 255)
end

local function shouldShowPackage(packageObj)
	if not ESP.Enabled then
		return false, "esp_disabled"
	end

	if packageObj:GetAttribute("OwnerUserId") ~= nil then
		return false, "owned_item"
	end

	local rarity = getRarityNumber(packageObj)
	if not rarity then
		return false, "missing_rarity"
	end

	if not ESP.Filters[rarity] then
		return false, "filtered_out"
	end

	return true, nil
end

local function buildESPText(packageObj)
	local lines = {}

	if ESP.ShowName then
		table.insert(lines, packageObj.Name)
	end

	local rarity = getRarityNumber(packageObj)
	if ESP.ShowRarity and rarity and TypeInfo[rarity] then
		table.insert(lines, TypeInfo[rarity].Name)
	end

	if ESP.ShowType then
		local typeText = getPackageTypeText(packageObj)
		if typeText ~= nil and typeText ~= "" then
			table.insert(lines, "Type: " .. tostring(typeText))
		end
	end

	if ESP.ShowSize then
		local sizeVal = getPackageSize(packageObj)
		if sizeVal ~= nil then
			table.insert(lines, "Size: " .. tostring(sizeVal))
		end
	end

	if ESP.ShowValue then
		local valueVal = getPackageValue(packageObj)
		if valueVal ~= nil then
			table.insert(lines, "Value: " .. tostring(valueVal))
		end
	end

	if ESP.ShowColor then
		local colorText = getPackageColorText(packageObj)
		if colorText ~= nil then
			table.insert(lines, "Color: " .. tostring(colorText))
		end
	end

	return table.concat(lines, "\n")
end

local function clearEntry(key)
	local entry = State.Cache[key]
	if not entry then
		return
	end

	destroyIf(entry.Highlight)
	destroyIf(entry.Billboard)
	State.Cache[key] = nil
end

local function ensurePackageESP(packageObj)
	local key = packageObj:GetDebugId()

	local ok, reason = shouldShowPackage(packageObj)
	if not ok then
		clearEntry(key)
		return false, reason
	end

	local rootPart = getRootPartStrict(packageObj)
	local adornee = getAdorneeStrict(packageObj)

	if not rootPart or not adornee then
		clearEntry(key)
		return false, "missing_rootpart"
	end

	local color = getESPColor(packageObj)
	local text = buildESPText(packageObj)

	local entry = State.Cache[key]
	if not entry then
		entry = {}
		State.Cache[key] = entry
	end

	if not entry.Highlight then
		local hl = Instance.new("Highlight")
		hl.Name = "DW_PackageESP"
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.FillTransparency = 0.6
		hl.OutlineTransparency = 0.1
		hl.Parent = ESP.Folder
		entry.Highlight = hl
	end

	entry.Highlight.Adornee = adornee
	entry.Highlight.FillColor = color
	entry.Highlight.OutlineColor = color
	entry.Highlight.Enabled = true

	if not entry.Billboard then
		local bb = Instance.new("BillboardGui")
		bb.Name = "DW_PackageESP_Text"
		bb.Size = UDim2.new(0, 190, 0, 70)
		bb.StudsOffset = Vector3.new(0, 4.5, 0)
		bb.AlwaysOnTop = true
		bb.Parent = ESP.Folder

		local label = Instance.new("TextLabel")
		label.Name = "TextLabel"
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextSize = 13
		label.TextWrapped = true
		label.TextStrokeTransparency = 0
		label.Parent = bb

		entry.Billboard = bb
		entry.Label = label
	end

	entry.Billboard.Adornee = rootPart
	entry.Billboard.Enabled = true
	entry.Label.Text = text
	entry.Label.TextColor3 = color

	return true, nil
end

local function cleanupESP()
	for key, entry in pairs(State.Cache) do
		local stillExists = false
		for _, obj in ipairs(PackagesFolder:GetChildren()) do
			if obj:GetDebugId() == key then
				stillExists = true
				break
			end
		end

		if not stillExists then
			destroyIf(entry.Highlight)
			destroyIf(entry.Billboard)
			State.Cache[key] = nil
		end
	end
end

local function clearAllESP()
	for key, entry in pairs(State.Cache) do
		destroyIf(entry.Highlight)
		destroyIf(entry.Billboard)
		State.Cache[key] = nil
	end
end

local function getVisiblePackages()
	local result = {}

	for _, packageObj in ipairs(PackagesFolder:GetChildren()) do
		local ok = shouldShowPackage(packageObj)
		if ok then
			local rootPart = getRootPartStrict(packageObj)
			local rarity = getRarityNumber(packageObj)
			local value = parseNumber(getPackageValue(packageObj)) or 0

			if rootPart and rarity then
				table.insert(result, {
					Object = packageObj,
					Part = rootPart,
					Rarity = rarity,
					Value = value,
				})
			end
		end
	end

	return result
end

local function findNearestVisiblePackage()
	local hrp = getHRP()
	if not hrp then return nil end

	local best, bestDist = nil, math.huge
	for _, entry in ipairs(getVisiblePackages()) do
		local dist = (hrp.Position - entry.Part.Position).Magnitude
		if dist < bestDist then
			bestDist = dist
			best = entry
		end
	end
	return best
end

local function findBestRarityVisiblePackage()
	local hrp = getHRP()
	if not hrp then return nil end

	local best = nil
	local bestRarity = -math.huge
	local bestDistance = math.huge

	for _, entry in ipairs(getVisiblePackages()) do
		local dist = (hrp.Position - entry.Part.Position).Magnitude

		if entry.Rarity > bestRarity then
			bestRarity = entry.Rarity
			bestDistance = dist
			best = entry
		elseif entry.Rarity == bestRarity and dist < bestDistance then
			bestDistance = dist
			best = entry
		end
	end

	return best
end

local function findMostExpensiveVisiblePackage()
	local hrp = getHRP()
	if not hrp then return nil end

	local best = nil
	local bestValue = -math.huge
	local bestDistance = math.huge

	for _, entry in ipairs(getVisiblePackages()) do
		local dist = (hrp.Position - entry.Part.Position).Magnitude

		if entry.Value > bestValue then
			bestValue = entry.Value
			bestDistance = dist
			best = entry
		elseif entry.Value == bestValue and dist < bestDistance then
			bestDistance = dist
			best = entry
		end
	end

	return best
end

local function teleportToPackage(entry)
	if not entry or not entry.Part then
		return false
	end

	local hrp = getHRP()
	local hum = getHumanoid()
	if not hrp or not hum then
		return false
	end

	local yOffset = (entry.Part.Size.Y / 2) + hum.HipHeight + 2
	hrp.CFrame = CFrame.new(entry.Part.Position + Vector3.new(0, yOffset, 0))
	return true
end

local function refreshESP()
	local total = 0
	local shown = 0
	local missingRarity = 0
	local missingRootPart = 0
	local filteredOut = 0
	local ownedItems = 0

	for _, packageObj in ipairs(PackagesFolder:GetChildren()) do
		total += 1
		local success, reason = ensurePackageESP(packageObj)
		if success then
			shown += 1
		else
			if reason == "missing_rarity" then
				missingRarity += 1
			elseif reason == "missing_rootpart" then
				missingRootPart += 1
			elseif reason == "filtered_out" then
				filteredOut += 1
			elseif reason == "owned_item" then
				ownedItems += 1
			end
		end
	end

	cleanupESP()

	if UI.StatusLabel then
		UI.StatusLabel.Text =
			"Packages total: " .. tostring(total) .. "\n" ..
			"Visible by filter: " .. tostring(shown) .. "\n" ..
			"ESP: " .. (ESP.Enabled and "ON" or "OFF")
	end

	if UI.ReasonLabel then
		local reasonText

		if not ESP.Enabled then
			reasonText = "No hay ESP porque esta apagado."
		elseif total <= 0 then
			reasonText = "No hay ESP porque workspace.Packages esta vacio."
		elseif shown > 0 then
			reasonText = "ESP activo. Si falta algo, revisa RarityClass atributo o RootPart."
		elseif ownedItems == total then
			reasonText = "No hay ESP porque todos los packages tienen OwnerUserId y se ignoran."
		elseif missingRarity == total then
			reasonText = "No hay ESP porque ningun package tiene RarityClass valido."
		elseif missingRootPart == total then
			reasonText = "No hay ESP porque ningun package tiene RootPart."
		elseif filteredOut > 0 and (filteredOut + missingRarity + missingRootPart + ownedItems) >= total then
			reasonText = "No hay ESP porque los filtros estan ocultando todo o los items tienen OwnerUserId."
		else
			reasonText =
				"Sin ESP visible.\n" ..
				"Missing RarityClass: " .. tostring(missingRarity) .. "\n" ..
				"Missing RootPart: " .. tostring(missingRootPart) .. "\n" ..
				"Owned Items: " .. tostring(ownedItems) .. "\n" ..
				"Filtered Out: " .. tostring(filteredOut)
		end

		UI.ReasonLabel.Text = reasonText
	end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DW_PackageESP_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = CoreGui

ESP.Folder = Instance.new("Folder")
ESP.Folder.Name = "DW_PackageESP_FOLDER"
ESP.Folder.Parent = CoreGui

UI.NotificationHolder = Instance.new("Frame")
UI.NotificationHolder.Name = "Notifications"
UI.NotificationHolder.Size = UDim2.new(0, 250, 1, -20)
UI.NotificationHolder.Position = UDim2.new(1, -260, 0, 10)
UI.NotificationHolder.BackgroundTransparency = 1
UI.NotificationHolder.Parent = ScreenGui

local notifLayout = Instance.new("UIListLayout")
notifLayout.Padding = UDim.new(0, 5)
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifLayout.Parent = UI.NotificationHolder

local MainFrame = Instance.new("Frame")
MainFrame.Name = "Window"
MainFrame.Size = UDim2.new(0, 670, 0, 560)
MainFrame.Position = UDim2.new(0.5, -335, 0.5, -280)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BackgroundTransparency = 0.05
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = Theme.CornerRadius

local mainStroke = Instance.new("UIStroke", MainFrame)
mainStroke.Color = Theme.Stroke
mainStroke.Thickness = 1

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 180, 1, 0)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.Parent = MainFrame
Instance.new("UICorner", Sidebar).CornerRadius = Theme.CornerRadius

local SidebarFix = Instance.new("Frame")
SidebarFix.Size = UDim2.new(0, 10, 1, 0)
SidebarFix.Position = UDim2.new(1, -10, 0, 0)
SidebarFix.BackgroundColor3 = Theme.Sidebar
SidebarFix.BorderSizePixel = 0
SidebarFix.Parent = Sidebar

local DragZone = Instance.new("Frame")
DragZone.Size = UDim2.new(1, 0, 0, 40)
DragZone.BackgroundTransparency = 1
DragZone.Parent = MainFrame

local dragging = false
local dragStart, startPos, dragInput

DragZone.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position
	end
end)

DragZone.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

RunService.RenderStepped:Connect(function()
	if dragging and dragInput then
		local delta = dragInput.Position - dragStart
		MainFrame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)

local ControlsHolder = Instance.new("Frame")
ControlsHolder.Size = UDim2.new(0, 60, 0, 20)
ControlsHolder.Position = UDim2.new(0, 18, 0, 18)
ControlsHolder.BackgroundTransparency = 1
ControlsHolder.Parent = MainFrame

local function createDot(color, offset)
	local Dot = Instance.new("Frame")
	Dot.Size = UDim2.new(0, 12, 0, 12)
	Dot.Position = UDim2.new(0, offset, 0, 0)
	Dot.BackgroundColor3 = color
	Dot.Parent = ControlsHolder
	Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

	local Btn = Instance.new("TextButton")
	Btn.Size = UDim2.new(1, 0, 1, 0)
	Btn.BackgroundTransparency = 1
	Btn.Text = ""
	Btn.Parent = Dot
	return Btn
end

local CloseBtn = createDot(Theme.Destructive, 0)
local HideBtn = createDot(Theme.Gold, 20)
local OpenBtn = createDot(Theme.Success, 40)

local ContentHolder = Instance.new("ScrollingFrame")
ContentHolder.Size = UDim2.new(1, -180, 1, 0)
ContentHolder.Position = UDim2.new(0, 180, 0, 0)
ContentHolder.BackgroundTransparency = 1
ContentHolder.ScrollBarThickness = 0
ContentHolder.Parent = MainFrame

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 10)
ContentLayout.Parent = ContentHolder

local ContentPadding = Instance.new("UIPadding")
ContentPadding.PaddingTop = UDim.new(0, 20)
ContentPadding.PaddingLeft = UDim.new(0, 20)
ContentPadding.PaddingRight = UDim.new(0, 20)
ContentPadding.Parent = ContentHolder

ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	ContentHolder.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 20)
end)

local Title = Instance.new("TextLabel")
Title.Text = "Package ESP"
Title.TextColor3 = Theme.TextDim
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.Size = UDim2.new(1, -40, 0, 20)
Title.Position = UDim2.new(0, 20, 0, 60)
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Sidebar

local SubTitle = Instance.new("TextLabel")
SubTitle.Text = "DW Style Utility"
SubTitle.TextColor3 = Theme.Text
SubTitle.Font = Enum.Font.GothamBold
SubTitle.TextSize = 20
SubTitle.Size = UDim2.new(1, -30, 0, 30)
SubTitle.Position = UDim2.new(0, 15, 0, 90)
SubTitle.BackgroundTransparency = 1
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.Parent = Sidebar

local SidebarInfo = Instance.new("TextLabel")
SidebarInfo.Text =
	"RarityClass atributo:\n" ..
	"1 = Common\n" ..
	"2 = Rare\n" ..
	"3 = Epic\n" ..
	"4 = Legendary\n" ..
	"5 = Mythic"
SidebarInfo.TextColor3 = Theme.TextDim
SidebarInfo.Font = Enum.Font.Gotham
SidebarInfo.TextSize = 12
SidebarInfo.TextYAlignment = Enum.TextYAlignment.Top
SidebarInfo.TextXAlignment = Enum.TextXAlignment.Left
SidebarInfo.Size = UDim2.new(1, -24, 0, 110)
SidebarInfo.Position = UDim2.new(0, 12, 0, 135)
SidebarInfo.BackgroundTransparency = 1
SidebarInfo.Parent = Sidebar

local function createSectionLabel(text, height)
	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(1, 0, 0, height or 55)
	Frame.BackgroundColor3 = Theme.Sidebar
	Frame.BackgroundTransparency = 0.5
	Frame.Parent = ContentHolder
	Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)

	local Stroke = Instance.new("UIStroke", Frame)
	Stroke.Color = Theme.Stroke
	Stroke.Transparency = 0.5

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -20, 1, -12)
	Label.Position = UDim2.new(0, 10, 0, 6)
	Label.BackgroundTransparency = 1
	Label.TextWrapped = true
	Label.TextYAlignment = Enum.TextYAlignment.Top
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Font = Enum.Font.Gotham
	Label.TextSize = 13
	Label.TextColor3 = Theme.Text
	Label.Text = text
	Label.Parent = Frame

	return Label
end

local function createToggle(text, default, callback)
	local ToggleFrame = Instance.new("Frame")
	ToggleFrame.Size = UDim2.new(1, 0, 0, 44)
	ToggleFrame.BackgroundColor3 = Theme.Sidebar
	ToggleFrame.BackgroundTransparency = 0.5
	ToggleFrame.Parent = ContentHolder
	Instance.new("UICorner", ToggleFrame).CornerRadius = UDim.new(0, 10)

	local ToggleStroke = Instance.new("UIStroke", ToggleFrame)
	ToggleStroke.Color = Theme.Stroke
	ToggleStroke.Transparency = 0.5

	local Label = Instance.new("TextLabel")
	Label.Text = "  " .. text
	Label.Size = UDim2.new(0.7, 0, 1, 0)
	Label.BackgroundTransparency = 1
	Label.TextColor3 = Theme.Text
	Label.Font = Enum.Font.Gotham
	Label.TextSize = 14
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = ToggleFrame

	local SwitchBg = Instance.new("Frame")
	SwitchBg.Size = UDim2.new(0, 44, 0, 24)
	SwitchBg.Position = UDim2.new(1, -55, 0.5, -12)
	SwitchBg.BackgroundColor3 = default and Theme.Accent or Color3.fromRGB(230, 200, 210)
	SwitchBg.Parent = ToggleFrame
	Instance.new("UICorner", SwitchBg).CornerRadius = UDim.new(1, 0)

	local SwitchCircle = Instance.new("Frame")
	SwitchCircle.Size = UDim2.new(0, 20, 0, 20)
	SwitchCircle.Position = default and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
	SwitchCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	SwitchCircle.Parent = SwitchBg
	Instance.new("UICorner", SwitchCircle).CornerRadius = UDim.new(1, 0)

	local Toggled = default and true or false
	local Control = {}

	function Control:SetValue(val, skip)
		Toggled = val and true or false
		TweenService:Create(SwitchBg, TweenInfo.new(0.2), {
			BackgroundColor3 = Toggled and Theme.Accent or Color3.fromRGB(230, 200, 210)
		}):Play()
		TweenService:Create(SwitchCircle, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
			Position = Toggled and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
		}):Play()
		if not skip then
			callback(Toggled)
		end
	end

	local Trigger = Instance.new("TextButton")
	Trigger.Size = UDim2.new(1, 0, 1, 0)
	Trigger.BackgroundTransparency = 1
	Trigger.Text = ""
	Trigger.Parent = ToggleFrame

	Trigger.MouseButton1Click:Connect(function()
		Control:SetValue(not Toggled)
	end)

	return Control
end

local function createButton(text, callback)
	local ButtonFrame = Instance.new("Frame")
	ButtonFrame.Size = UDim2.new(1, 0, 0, 40)
	ButtonFrame.BackgroundColor3 = Theme.Accent
	ButtonFrame.BackgroundTransparency = 0.2
	ButtonFrame.Parent = ContentHolder
	Instance.new("UICorner", ButtonFrame).CornerRadius = UDim.new(0, 10)

	local Gradient = Instance.new("UIGradient")
	Gradient.Rotation = 90
	Gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
		ColorSequenceKeypoint.new(1, Theme.Accent)
	}
	Gradient.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(1, 0.1)
	}
	Gradient.Parent = ButtonFrame

	local BtnStroke = Instance.new("UIStroke")
	BtnStroke.Color = Color3.fromRGB(255,255,255)
	BtnStroke.Transparency = 0.6
	BtnStroke.Thickness = 1
	BtnStroke.Parent = ButtonFrame

	local Btn = Instance.new("TextButton")
	Btn.Size = UDim2.new(1, 0, 1, 0)
	Btn.BackgroundTransparency = 1
	Btn.Text = text
	Btn.TextColor3 = Theme.Text
	Btn.Font = Enum.Font.GothamBold
	Btn.TextSize = 14
	Btn.Parent = ButtonFrame

	Btn.MouseButton1Click:Connect(callback)
	return Btn
end

UI.StatusLabel = createSectionLabel("Loading package info...", 72)
UI.ReasonLabel = createSectionLabel("Checking ESP reasons...", 92)

createToggle("Enable Package ESP", ESP.Enabled, function(val)
	ESP.Enabled = val
	if not val then
		clearAllESP()
	end
	refreshESP()
	notify("ESP", "Package ESP " .. (val and "enabled" or "disabled"), 2)
end)

createToggle("Show Package Name", ESP.ShowName, function(val)
	ESP.ShowName = val
	refreshESP()
end)

createToggle("Show Rarity", ESP.ShowRarity, function(val)
	ESP.ShowRarity = val
	refreshESP()
end)

createToggle("Show Type", ESP.ShowType, function(val)
	ESP.ShowType = val
	refreshESP()
end)

createToggle("Show Size", ESP.ShowSize, function(val)
	ESP.ShowSize = val
	refreshESP()
end)

createToggle("Show Value", ESP.ShowValue, function(val)
	ESP.ShowValue = val
	refreshESP()
end)

createToggle("Show Color", ESP.ShowColor, function(val)
	ESP.ShowColor = val
	refreshESP()
end)

createSectionLabel("Rarity Filters", 42)

local Type1Toggle = createToggle("1 - Common", ESP.Filters[1], function(val)
	ESP.Filters[1] = val
	refreshESP()
end)

local Type2Toggle = createToggle("2 - Rare", ESP.Filters[2], function(val)
	ESP.Filters[2] = val
	refreshESP()
end)

local Type3Toggle = createToggle("3 - Epic", ESP.Filters[3], function(val)
	ESP.Filters[3] = val
	refreshESP()
end)

local Type4Toggle = createToggle("4 - Legendary", ESP.Filters[4], function(val)
	ESP.Filters[4] = val
	refreshESP()
end)

local Type5Toggle = createToggle("5 - Mythic", ESP.Filters[5], function(val)
	ESP.Filters[5] = val
	refreshESP()
end)

createButton("Enable All Rarities", function()
	for i = 1, 5 do
		ESP.Filters[i] = true
	end
	Type1Toggle:SetValue(true, true)
	Type2Toggle:SetValue(true, true)
	Type3Toggle:SetValue(true, true)
	Type4Toggle:SetValue(true, true)
	Type5Toggle:SetValue(true, true)
	refreshESP()
	notify("Filters", "All rarities enabled", 2)
end)

createButton("Only Legendary + Mythic", function()
	for i = 1, 5 do
		ESP.Filters[i] = false
	end
	ESP.Filters[4] = true
	ESP.Filters[5] = true
	Type1Toggle:SetValue(false, true)
	Type2Toggle:SetValue(false, true)
	Type3Toggle:SetValue(false, true)
	Type4Toggle:SetValue(true, true)
	Type5Toggle:SetValue(true, true)
	refreshESP()
	notify("Filters", "Only Legendary and Mythic visible", 2)
end)

createButton("TP Nearest Visible", function()
	local entry = findNearestVisiblePackage()
	if not entry then
		notify("Teleport", "No visible package found", 2)
		return
	end

	if teleportToPackage(entry) then
		local rarity = TypeInfo[entry.Rarity] and TypeInfo[entry.Rarity].Name or tostring(entry.Rarity)
		notify("Teleport", "Nearest: " .. rarity .. " - " .. entry.Object.Name, 2.3)
	else
		notify("Teleport", "Could not teleport", 2)
	end
end)

createButton("TP Best Rarity", function()
	local entry = findBestRarityVisiblePackage()
	if not entry then
		notify("Teleport", "No visible package found", 2)
		return
	end

	if teleportToPackage(entry) then
		local rarity = TypeInfo[entry.Rarity] and TypeInfo[entry.Rarity].Name or tostring(entry.Rarity)
		notify("Teleport", "Best rarity: " .. rarity .. " - " .. entry.Object.Name, 2.3)
	else
		notify("Teleport", "Could not teleport", 2)
	end
end)

createButton("TP Most Expensive", function()
	local entry = findMostExpensiveVisiblePackage()
	if not entry then
		notify("Teleport", "No visible package con Value valido", 2.3)
		return
	end

	if teleportToPackage(entry) then
		local rarity = TypeInfo[entry.Rarity] and TypeInfo[entry.Rarity].Name or tostring(entry.Rarity)
		notify("Teleport", "Most expensive: " .. rarity .. " - " .. entry.Object.Name .. " | Value " .. tostring(entry.Value), 2.5)
	else
		notify("Teleport", "Could not teleport", 2)
	end
end)

createButton("Reset ESP", function()
	clearAllESP()
	refreshESP()
	notify("ESP", "ESP refreshed", 2)
end)

CloseBtn.MouseButton1Click:Connect(function()
	if State.Connection then
		State.Connection:Disconnect()
		State.Connection = nil
	end
	clearAllESP()
	destroyIf(ESP.Folder)
	destroyIf(ScreenGui)
end)

HideBtn.MouseButton1Click:Connect(function()
	TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quart), {
		Size = UDim2.new(0, 80, 0, 45)
	}):Play()
	task.wait(0.08)
	Sidebar.Visible = false
	ContentHolder.Visible = false
end)

OpenBtn.MouseButton1Click:Connect(function()
	Sidebar.Visible = true
	ContentHolder.Visible = true
	TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, 670, 0, 560)
	}):Play()
end)

refreshESP()
notify("Loaded", "Package ESP GUI ready", 2.4)

local acc = 0
State.Connection = RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc >= ESP.RefreshRate then
		acc = 0
		refreshESP()
	end
end)

print("DW Package ESP GUI loaded")
