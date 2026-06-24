--[[
    ✨ ENI's Premium Aura Per Click Hub v4.5 ✨
    Aesthetic Overhaul: XVC Hub Dark Matte Style, Sidebar Profile Badge, Dedicated Home Page, Friendly Dropdown Selectors.
    Features: Auto-Click (CPS slider), Auto-Rebirth, Auto-Hatch, Auto-Claim Gifts, Auto Buy Upgrades, Auto Spin Wheel, Stage Teleporter, Treadmill Teleporter, and Player Controls.
--]]

-- Increment Script Run ID for thread safety
_G.AuraScriptID = (_G.AuraScriptID or 0) + 1
local currentScriptID = _G.AuraScriptID

-- Clean up previous connections to prevent memory leaks and duplicate triggers
if _G.AuraCleanup then
    for _, conn in ipairs(_G.AuraCleanup) do
        pcall(function() conn:Disconnect() end)
    end
end
_G.AuraCleanup = {}

-- Cleanup previous GUI
if game:GetService("CoreGui"):FindFirstChild("AuraClickerHub") then
    game:GetService("CoreGui"):FindFirstChild("AuraClickerHub"):Destroy()
end
if game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("AuraClickerHub") then
    game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("AuraClickerHub"):Destroy()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- Helper function to track connections
local function safeConnect(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(_G.AuraCleanup, conn)
    return conn
end

-- ═══════════════════════════════════════════
-- EGG & STAGE FRIENDLY LISTS
-- ═══════════════════════════════════════════
local EGG_MAPPING = {
    ["Egg 1 (20 Trophies)"] = "1",
    ["Egg 2 (250 Trophies)"] = "2",
    ["Egg 3 (5K Trophies)"] = "3",
    ["Egg 4 (25K Trophies)"] = "4",
    ["Egg 5 (50K Trophies)"] = "5",
    ["Egg 6 (100K Trophies)"] = "6",
    ["Egg 7 (250K Trophies)"] = "7",
    ["Egg 8 (500K Trophies)"] = "8",
    ["Premium Egg 67"] = "67",
}

local EGG_OPTIONS = {
    "Egg 1 (20 Trophies)",
    "Egg 2 (250 Trophies)",
    "Egg 3 (5K Trophies)",
    "Egg 4 (25K Trophies)",
    "Egg 5 (50K Trophies)",
    "Egg 6 (100K Trophies)",
    "Egg 7 (250K Trophies)",
    "Egg 8 (500K Trophies)",
    "Premium Egg 67",
}

local HATCH_QTY_MAPPING = {
    ["Single Hatch (x1)"] = 1,
    ["Triple Hatch (x3)"] = 3,
}

local HATCH_QTY_OPTIONS = {
    "Single Hatch (x1)",
    "Triple Hatch (x3)",
}

local STAGE_OPTIONS = {}
for i = 1, 25 do
    table.insert(STAGE_OPTIONS, "Stage " .. i)
end

-- ═══════════════════════════════════════════
-- CONFIG & STATE
-- ═══════════════════════════════════════════
_G.AuraConfig = {
    AutoClick = false,
    ClickSpeed = 20, -- Clicks per second
    AutoWins = false,
    AutoRebirth = false,
    AutoHatch = false,
    AutoBuyUpgrades = false,
    AutoSpin = false,
    AutoClaimGifts = false,
    AutoClaimGroup = false,
    
    SelectedEgg = "Egg 1 (20 Trophies)",
    HatchAmount = "Single Hatch (x1)",
    
    TeleportStageValue = "Stage 1",
    SelectedTreadmill = "1x",
    
    -- Auto-delete config keys
    DeleteCommon = false,
    DeleteUncommon = false,
    DeleteRare = false,
    DeleteEpic = false,
    
    -- Player Cheats
    WalkSpeed = 40,
    JumpPower = 100,
    SpeedHack = false,
    Noclip = false,
    FlyHack = false,
    ClickTP = false,
    
    -- UI Settings
    UI_Transparency = 0.05,
    UI_Glow = false,
    UI_Keybind = Enum.KeyCode.LeftControl,
    AccentColor1 = Color3.fromRGB(255, 53, 94), -- Primary (Cyber Rose)
    AccentColor2 = Color3.fromRGB(157, 78, 221), -- Secondary (Neon Purple)
}

local Config = _G.AuraConfig

local SessionStats = {
    ClicksMined = 0,
    RebirthsDone = 0,
    Status = "Idle",
}

-- Gather current stats (Aura, Rebirths)
local function getAuraValue()
    local lead = LocalPlayer:FindFirstChild("leaderstats")
    local aura = lead and (lead:FindFirstChild("Aura") or lead:FindFirstChild("Clicks") or lead:FindFirstChild("Speed"))
    if not aura and LocalPlayer:FindFirstChild("PlayerData") then
        local rs = LocalPlayer.PlayerData:FindFirstChild("RealStats")
        aura = rs and (rs:FindFirstChild("Aura") or rs:FindFirstChild("Clicks") or rs:FindFirstChild("Speed"))
    end
    return aura and aura.Value or "0"
end

local function getRebirthsValue()
    local lead = LocalPlayer:FindFirstChild("leaderstats")
    local reb = lead and (lead:FindFirstChild("Rebirths") or lead:FindFirstChild("Rebirth"))
    if not reb and LocalPlayer:FindFirstChild("PlayerData") then
        local rs = LocalPlayer.PlayerData:FindFirstChild("RealStats")
        reb = rs and (rs:FindFirstChild("Rebirths") or rs:FindFirstChild("Rebirth"))
    end
    return reb and reb.Value or 0
end

-- ═══════════════════════════════════════════
-- WINS VALUE PARSER
-- ═══════════════════════════════════════════
local function parseSuffix(str)
    str = str:upper():gsub("%s+", ""):gsub("WINS", "")
    local numPart = str:match("^[0-9%.]+")
    if not numPart then return 0 end
    local val = tonumber(numPart) or 0
    local suffix = str:sub(#numPart + 1)
    if suffix == "K" then
        val = val * 1000
    elseif suffix == "M" then
        val = val * 1000000
    elseif suffix == "B" then
        val = val * 1000000000
    elseif suffix == "T" then
        val = val * 1000000000000
    end
    return val
end

local function getWinsValue()
    local text = "0"
    pcall(function()
        local ui = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("UI")
        local rebirth = ui and ui:FindFirstChild("Rebirth")
        local frame = rebirth and rebirth:FindFirstChild("Frame")
        local bar = frame and frame:FindFirstChild("ProgressBar")
        local level = bar and bar:FindFirstChild("CurrentLevel")
        if level then
            text = level.Text
        end
    end)
    local parts = string.split(text, "/")
    local currentPart = parts[1] or "0"
    return parseSuffix(currentPart)
end

-- ═══════════════════════════════════════════
-- UI STYLING & BASE (XVC SYSTEM Overhaul)
-- ═══════════════════════════════════════════
local COLORS = {
    bg = Color3.fromRGB(20, 20, 24),
    sidebar = Color3.fromRGB(24, 24, 28),
    bgLight = Color3.fromRGB(28, 28, 32),
    rowBg = Color3.fromRGB(33, 33, 38),     -- Premium row backdrop
    rowBgTrans = 0.3,                       -- Subtle semi-transparency for depth
    text = Color3.fromRGB(242, 240, 245),
    textDim = Color3.fromRGB(144, 138, 148),
    divider = Color3.fromRGB(35, 35, 40),
    toggleOn = Color3.fromRGB(46, 213, 115), -- Sleek green
    toggleOff = Color3.fromRGB(44, 42, 50),
    shadow = Color3.fromRGB(0, 0, 0),
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AuraClickerHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 99999999
ScreenGui.IgnoreGuiInset = true

-- Prefer CoreGui, fallback to PlayerGui
local success, _ = pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not success or not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local mainWidth, mainHeight = 550, 420
local minWidth, minHeight = 450, 300
local maxWidth, maxHeight = 900, 700
local Shadow = Instance.new("Frame")
Shadow.Name = "Shadow"
Shadow.Size = UDim2.new(0, mainWidth + 4, 0, mainHeight + 4)
Shadow.Position = UDim2.new(0, 12, 0, 12)
Shadow.BackgroundColor3 = COLORS.shadow
Shadow.BackgroundTransparency = 0.55
Shadow.BorderSizePixel = 0
Shadow.ZIndex = 1

local shadowCorner = Instance.new("UICorner")
shadowCorner.CornerRadius = UDim.new(0, 12)
shadowCorner.Parent = Shadow
Shadow.Parent = ScreenGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, mainWidth, 0, mainHeight)
Main.Position = UDim2.new(0, 10, 0, 10)
Main.BackgroundColor3 = COLORS.bg
Main.BackgroundTransparency = Config.UI_Transparency
Main.BorderSizePixel = 0
Main.Active = true
Main.ClipsDescendants = true
Main.ZIndex = 2

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = Main
Main.Parent = ScreenGui

Main:GetPropertyChangedSignal("Position"):Connect(function()
    Shadow.Position = Main.Position + UDim2.new(0, 2, 0, 2)
end)

local glowStroke = Instance.new("UIStroke")
glowStroke.Color = Color3.fromRGB(35, 35, 40) -- Flat thin boundary default
glowStroke.Thickness = 1
glowStroke.Transparency = 0
glowStroke.Enabled = true
glowStroke.Parent = Main

-- ═══════════════════════════════════════════
-- LAYOUT SPLIT: SIDEBAR vs CONTENT
-- ═══════════════════════════════════════════

-- Left Sidebar stretching full height
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 150, 1, 0)
Sidebar.BackgroundColor3 = COLORS.sidebar
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 4
Sidebar.Parent = Main

-- Divider line on the right of the Sidebar
local sidebarLine = Instance.new("Frame")
sidebarLine.Size = UDim2.new(0, 1, 1, 0)
sidebarLine.Position = UDim2.new(1, -1, 0, 0)
sidebarLine.BackgroundColor3 = COLORS.divider
sidebarLine.BorderSizePixel = 0
sidebarLine.ZIndex = 5
sidebarLine.Parent = Sidebar

-- Sidebar Header (Menu icon + Hub name)
local SidebarHeader = Instance.new("Frame")
SidebarHeader.Name = "SidebarHeader"
SidebarHeader.Size = UDim2.new(1, 0, 0, 45)
SidebarHeader.BackgroundTransparency = 1
SidebarHeader.ZIndex = 5
SidebarHeader.Parent = Sidebar

local MenuIcon = Instance.new("TextLabel")
MenuIcon.Name = "MenuIcon"
MenuIcon.Size = UDim2.new(0, 24, 1, 0)
MenuIcon.Position = UDim2.new(0, 12, 0, 0)
MenuIcon.BackgroundTransparency = 1
MenuIcon.Text = "≡"
MenuIcon.TextColor3 = COLORS.text
MenuIcon.TextSize = 16
MenuIcon.Font = Enum.Font.GothamBold
MenuIcon.ZIndex = 6
MenuIcon.Parent = SidebarHeader

local HubName = Instance.new("TextLabel")
HubName.Name = "HubName"
HubName.Size = UDim2.new(1, -44, 1, 0)
HubName.Position = UDim2.new(0, 36, 0, 0)
HubName.BackgroundTransparency = 1
HubName.Text = "Aura Clicker Hub"
HubName.TextColor3 = COLORS.text
HubName.TextSize = 11
HubName.Font = Enum.Font.GothamBlack
HubName.TextXAlignment = Enum.TextXAlignment.Left
HubName.ZIndex = 6
HubName.Parent = SidebarHeader

-- Tab buttons list container
local TabBtnContainer = Instance.new("Frame")
TabBtnContainer.Name = "TabBtnContainer"
TabBtnContainer.Size = UDim2.new(1, 0, 1, -95)
TabBtnContainer.Position = UDim2.new(0, 0, 0, 45)
TabBtnContainer.BackgroundTransparency = 1
TabBtnContainer.ZIndex = 4
TabBtnContainer.Parent = Sidebar

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.Padding = UDim.new(0, 3)
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Parent = TabBtnContainer

-- Sidebar player profile badge
local ProfileFrame = Instance.new("Frame")
ProfileFrame.Name = "ProfileFrame"
ProfileFrame.Size = UDim2.new(1, 0, 0, 50)
ProfileFrame.Position = UDim2.new(0, 0, 1, -50)
ProfileFrame.BackgroundColor3 = COLORS.sidebar
ProfileFrame.BorderSizePixel = 0
ProfileFrame.ZIndex = 4
ProfileFrame.Parent = Sidebar

local profileLine = Instance.new("Frame")
profileLine.Size = UDim2.new(1, 0, 0, 1)
profileLine.Position = UDim2.new(0, 0, 0, 0)
profileLine.BackgroundColor3 = COLORS.divider
profileLine.BorderSizePixel = 0
profileLine.ZIndex = 5
profileLine.Parent = ProfileFrame

local avatarImage = Instance.new("ImageLabel")
avatarImage.Name = "AvatarImage"
avatarImage.Size = UDim2.new(0, 32, 0, 32)
avatarImage.Position = UDim2.new(0, 10, 0.5, -16)
avatarImage.BackgroundColor3 = COLORS.bgLight
avatarImage.BorderSizePixel = 0
avatarImage.ZIndex = 5

local avatarCorner = Instance.new("UICorner")
avatarCorner.CornerRadius = UDim.new(1, 0)
avatarCorner.Parent = avatarImage
avatarImage.Parent = ProfileFrame

task.spawn(function()
    pcall(function()
        local userId = LocalPlayer.UserId
        local thumbType = Enum.ThumbnailType.HeadShot
        local thumbSize = Enum.ThumbnailSize.Size48x48
        local content, isReady = game.Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
        avatarImage.Image = content
    end)
end)

local userLabel = Instance.new("TextLabel")
userLabel.Name = "UserLabel"
userLabel.Size = UDim2.new(1, -52, 1, 0)
userLabel.Position = UDim2.new(0, 48, 0, 0)
userLabel.BackgroundTransparency = 1
userLabel.Text = LocalPlayer.Name
userLabel.TextColor3 = COLORS.text
userLabel.TextSize = 10
userLabel.Font = Enum.Font.GothamBold
userLabel.TextXAlignment = Enum.TextXAlignment.Left
userLabel.TextTruncate = Enum.TextTruncate.AtEnd
userLabel.ZIndex = 5
userLabel.Parent = ProfileFrame

-- Right Content Column
local ContentCol = Instance.new("Frame")
ContentCol.Name = "ContentCol"
ContentCol.Size = UDim2.new(1, -150, 1, 0)
ContentCol.Position = UDim2.new(0, 150, 0, 0)
ContentCol.BackgroundTransparency = 1
ContentCol.ZIndex = 4
ContentCol.Parent = Main

-- Content Top Header (Active Tab Name + Window Controls)
local ContentHeader = Instance.new("Frame")
ContentHeader.Name = "ContentHeader"
ContentHeader.Size = UDim2.new(1, 0, 0, 45)
ContentHeader.BackgroundTransparency = 1
ContentHeader.ZIndex = 5
ContentHeader.Parent = ContentCol

local ContentHeaderTitle = Instance.new("TextLabel")
ContentHeaderTitle.Name = "ContentHeaderTitle"
ContentHeaderTitle.Size = UDim2.new(1, -100, 1, 0)
ContentHeaderTitle.Position = UDim2.new(0, 12, 0, 0)
ContentHeaderTitle.BackgroundTransparency = 1
ContentHeaderTitle.Text = "Home"
ContentHeaderTitle.TextColor3 = COLORS.text
ContentHeaderTitle.TextSize = 14
ContentHeaderTitle.Font = Enum.Font.GothamBlack
ContentHeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
ContentHeaderTitle.ZIndex = 6
ContentHeaderTitle.Parent = ContentHeader

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -30, 0.5, -12)
CloseBtn.BackgroundColor3 = COLORS.bgLight
CloseBtn.BackgroundTransparency = 0.4
CloseBtn.Text = "×"
CloseBtn.TextColor3 = COLORS.text
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.ZIndex = 6
CloseBtn.Active = true

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = CloseBtn
CloseBtn.Parent = ContentHeader

local MinBtn = Instance.new("TextButton")
MinBtn.Name = "MinBtn"
MinBtn.Size = UDim2.new(0, 24, 0, 24)
MinBtn.Position = UDim2.new(1, -58, 0.5, -12)
MinBtn.BackgroundColor3 = COLORS.bgLight
MinBtn.BackgroundTransparency = 0.4
MinBtn.Text = "−"
MinBtn.TextColor3 = COLORS.text
MinBtn.TextSize = 14
MinBtn.Font = Enum.Font.GothamBold
MinBtn.BorderSizePixel = 0
MinBtn.ZIndex = 6
MinBtn.Active = true

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = MinBtn
MinBtn.Parent = ContentHeader

-- Dragging logic on both top headers
local dragging, dragInput, dragStart, startPos
local function updateDrag(input)
    local delta = input.Position - dragStart
    Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

local function makeDraggable(guiObject)
    safeConnect(guiObject.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    safeConnect(guiObject.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
end

makeDraggable(SidebarHeader)
makeDraggable(ContentHeader)

safeConnect(UserInputService.InputChanged, function(input)
    if input == dragInput and dragging then
        updateDrag(input)
    end
end)

-- Resize Grip and Resize Logic
local ResizeGrip = Instance.new("TextButton")
ResizeGrip.Name = "ResizeGrip"
ResizeGrip.Size = UDim2.new(0, 14, 0, 14)
ResizeGrip.Position = UDim2.new(1, -14, 1, -14)
ResizeGrip.BackgroundTransparency = 1
ResizeGrip.Text = "◢"
ResizeGrip.TextColor3 = COLORS.textDim
ResizeGrip.TextSize = 11
ResizeGrip.Font = Enum.Font.GothamBold
ResizeGrip.ZIndex = 15
ResizeGrip.Active = true
ResizeGrip.Parent = Main

local resizing = false
local resizeStartPos
local resizeStartSize

safeConnect(ResizeGrip.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeStartPos = input.Position
        resizeStartSize = Main.Size
        local releaseConn
        releaseConn = safeConnect(UserInputService.InputEnded, function(endedInput)
            if endedInput.UserInputType == Enum.UserInputType.MouseButton1 or endedInput.UserInputType == Enum.UserInputType.Touch then
                resizing = false
                if releaseConn then pcall(function() releaseConn:Disconnect() end) end
            end
        end)
    end
end)

safeConnect(UserInputService.InputChanged, function(input)
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - resizeStartPos
        local newWidth = math.clamp(resizeStartSize.X.Offset + delta.X, minWidth, maxWidth)
        local newHeight = math.clamp(resizeStartSize.Y.Offset + delta.Y, minHeight, maxHeight)
        
        mainWidth = newWidth
        mainHeight = newHeight
        
        Main.Size = UDim2.new(0, newWidth, 0, newHeight)
        Shadow.Size = UDim2.new(0, newWidth + 4, 0, newHeight + 4)
    end
end)

-- Main scrolling tab container
local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Size = UDim2.new(1, 0, 1, -61)
TabContainer.Position = UDim2.new(0, 0, 0, 45)
TabContainer.BackgroundTransparency = 1
TabContainer.ZIndex = 4
TabContainer.Parent = ContentCol

-- Bottom status bar in content area
local StatusBar = Instance.new("TextLabel")
StatusBar.Size = UDim2.new(1, 0, 0, 16)
StatusBar.Position = UDim2.new(0, 0, 1, -16)
StatusBar.BackgroundColor3 = COLORS.bg
StatusBar.BorderSizePixel = 0
StatusBar.Text = "  AURA Hub Operational • Status: Idle • Key: LeftControl"
StatusBar.TextColor3 = COLORS.textDim
StatusBar.TextSize = 9
StatusBar.Font = Enum.Font.Gotham
StatusBar.TextXAlignment = Enum.TextXAlignment.Left
StatusBar.ZIndex = 4
StatusBar.Parent = ContentCol

local Tabs = {}
local TabButtons = {}

local function showTab(tabName)
    for name, frame in pairs(Tabs) do
        frame.Visible = (name == tabName)
    end
    for name, item in pairs(TabButtons) do
        if name == tabName then
            item.btn.BackgroundColor3 = Color3.fromRGB(38, 38, 44)
            item.btn.BackgroundTransparency = 0
            item.lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            ContentHeaderTitle.Text = name
        else
            item.btn.BackgroundTransparency = 1
            item.lbl.TextColor3 = COLORS.textDim
        end
    end
end

local function createTabButton(name, text, icon, layoutOrder)
    local btn = Instance.new("TextButton")
    btn.Name = name .. "_TabBtn"
    btn.Size = UDim2.new(1, -16, 0, 32)
    btn.Position = UDim2.new(0, 8, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(38, 38, 44)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 5
    btn.LayoutOrder = layoutOrder or 0
    btn.Active = true
    btn.Selectable = true
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    btn.Parent = TabBtnContainer
    
    local lbl = Instance.new("TextLabel")
    lbl.Name = "Label"
    lbl.Size = UDim2.new(1, -12, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = icon .. "  " .. text
    lbl.TextColor3 = COLORS.textDim
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 9.5
    lbl.ZIndex = 6
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = btn

    safeConnect(btn.MouseEnter, function()
        if btn.BackgroundTransparency ~= 0 then
            TweenService:Create(lbl, TweenInfo.new(0.2), {TextColor3 = COLORS.text}):Play()
        end
    end)
    safeConnect(btn.MouseLeave, function()
        if btn.BackgroundTransparency ~= 0 then
            TweenService:Create(lbl, TweenInfo.new(0.2), {TextColor3 = COLORS.textDim}):Play()
        end
    end)

    safeConnect(btn.Activated, function()
        showTab(name)
    end)
    
    TabButtons[name] = {btn = btn, lbl = lbl}
    
    local tabFrame = Instance.new("ScrollingFrame")
    tabFrame.Name = name .. "Tab"
    tabFrame.Size = UDim2.new(1, 0, 1, 0)
    tabFrame.BackgroundTransparency = 1
    tabFrame.BorderSizePixel = 0
    tabFrame.ScrollBarThickness = 4
    tabFrame.ScrollBarImageColor3 = Config.AccentColor1
    tabFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabFrame.Visible = false
    tabFrame.ZIndex = 5
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 10)
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabFrame
    
    safeConnect(tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        tabFrame.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 24)
    end)
    
    local tabPadding = Instance.new("UIPadding")
    tabPadding.PaddingTop = UDim.new(0, 8)
    tabPadding.PaddingBottom = UDim.new(0, 8)
    tabPadding.PaddingLeft = UDim.new(0, 12)
    tabPadding.PaddingRight = UDim.new(0, 16) -- leaves room for scrollbar + 12px margin
    tabPadding.Parent = tabFrame
    
    tabFrame.Parent = TabContainer
    
    Tabs[name] = tabFrame
    return tabFrame
end

-- Component Card Generator
local function createCard(parent, title)
    local card = Instance.new("Frame")
    card.Name = title:gsub("%s+", "") .. "_Card"
    card.Size = UDim2.new(1, 0, 0, 0)
    card.BackgroundColor3 = COLORS.bgLight
    card.BackgroundTransparency = 0.5
    card.BorderSizePixel = 0
    card.ZIndex = 6
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card
    
    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = COLORS.divider
    cardStroke.Thickness = 1
    cardStroke.Parent = card
    
    local cardTitle = Instance.new("TextLabel")
    cardTitle.Name = "CardTitle"
    cardTitle.Size = UDim2.new(1, -16, 0, 24)
    cardTitle.Position = UDim2.new(0, 10, 0, 4)
    cardTitle.BackgroundTransparency = 1
    cardTitle.Text = title:upper()
    cardTitle.TextColor3 = Config.AccentColor1
    cardTitle.Font = Enum.Font.GothamBlack
    cardTitle.TextSize = 9.5
    cardTitle.TextXAlignment = Enum.TextXAlignment.Left
    cardTitle.ZIndex = 7
    cardTitle.Parent = card
    
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, -16, 0, 0)
    contentFrame.Position = UDim2.new(0, 8, 0, 24)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ZIndex = 7
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = contentFrame
    
    card.AutomaticSize = Enum.AutomaticSize.Y
    contentFrame.AutomaticSize = Enum.AutomaticSize.Y
    
    card.Parent = parent
    contentFrame.Parent = card
    
    return contentFrame
end

local function updateTheme()
    glowStroke.Color = Config.UI_Glow and Config.AccentColor1 or Color3.fromRGB(35, 35, 40)
    glowStroke.Thickness = Config.UI_Glow and 1.5 or 1
    glowStroke.Transparency = Config.UI_Glow and 0.25 or 0
    Main.BackgroundTransparency = Config.UI_Transparency
    for name, item in pairs(TabButtons) do
        if item.btn.BackgroundTransparency == 0 then
            item.lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
    for _, tabFrame in pairs(Tabs) do
        tabFrame.ScrollBarImageColor3 = Config.AccentColor1
    end
    -- Update all card titles and components
    for _, desc in ipairs(ScreenGui:GetDescendants()) do
        if desc.Name == "CardTitle" then
            desc.TextColor3 = Config.AccentColor1
        elseif desc.Name == "ValueBox" then
            desc.TextColor3 = Config.AccentColor1
        elseif desc.Name == "SwitchBG" and desc.BackgroundColor3 ~= COLORS.toggleOff then
            desc.BackgroundColor3 = Config.AccentColor1
        elseif desc.Name == "SelectorBtn" then
            desc.TextColor3 = Config.AccentColor1
        elseif desc.Name == "KeybindBtn" then
            desc.TextColor3 = Config.AccentColor1
        end
    end
end

local function createToggle(parent, label, configKey, callback)
    local row = Instance.new("Frame")
    row.Name = configKey .. "_ToggleRow"
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundColor3 = COLORS.rowBg
    row.BackgroundTransparency = COLORS.rowBgTrans
    row.BorderSizePixel = 0
    row.ZIndex = 7
    
    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 6)
    rowCorner.Parent = row

    local txt = Instance.new("TextLabel")
    txt.Name = "Label"
    txt.Size = UDim2.new(1, -60, 1, 0)
    txt.Position = UDim2.new(0, 10, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = label
    txt.TextColor3 = COLORS.text
    txt.TextSize = 10
    txt.Font = Enum.Font.GothamSemibold
    txt.ZIndex = 8
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Parent = row

    local switchBG = Instance.new("Frame")
    switchBG.Name = "SwitchBG"
    switchBG.Size = UDim2.new(0, 32, 0, 15)
    switchBG.Position = UDim2.new(1, -42, 0.5, -7)
    switchBG.BackgroundColor3 = Config[configKey] and Config.AccentColor1 or COLORS.toggleOff
    switchBG.BorderSizePixel = 0
    switchBG.ZIndex = 8
    
    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switchBG
    switchBG.Parent = row

    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.new(0, 11, 0, 11)
    knob.Position = Config[configKey] and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 9
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    knob.Parent = switchBG

    local btn = Instance.new("TextButton")
    btn.Name = configKey .. "_ToggleBtn"
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = 0.99
    btn.Text = ""
    btn.ZIndex = 10
    btn.Active = true
    btn.Selectable = true
    btn.Parent = row

    safeConnect(btn.Activated, function()
        Config[configKey] = not Config[configKey]
        local on = Config[configKey]

        TweenService:Create(switchBG, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
            BackgroundColor3 = on and Config.AccentColor1 or COLORS.toggleOff
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
            Position = on and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
        }):Play()

        if callback then callback(on) end
    end)
    
    row.Parent = parent
    return row
end

local function createSelectionSelector(parent, label, configKey, options, callback)
    local container = Instance.new("Frame")
    container.Name = configKey .. "_SelectorRow"
    container.Size = UDim2.new(1, 0, 0, 28)
    container.BackgroundColor3 = COLORS.rowBg
    container.BackgroundTransparency = COLORS.rowBgTrans
    container.BorderSizePixel = 0
    container.ZIndex = 7
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 6)
    containerCorner.Parent = container

    local lbl = Instance.new("TextLabel")
    lbl.Name = "Label"
    lbl.Size = UDim2.new(0.45, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = COLORS.text
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 10
    lbl.ZIndex = 8
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = container

    local activeIdx = 1
    for idx, val in ipairs(options) do
        if tostring(val) == tostring(Config[configKey]) then activeIdx = idx end
    end

    local btn = Instance.new("TextButton")
    btn.Name = "SelectorBtn"
    btn.Size = UDim2.new(0.55, -8, 0, 20)
    btn.Position = UDim2.new(0.45, 0, 0.5, -10)
    btn.BackgroundColor3 = COLORS.bgLight
    btn.Text = tostring(options[activeIdx])
    btn.TextColor3 = Config.AccentColor1
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9.5
    btn.BorderSizePixel = 0
    btn.ZIndex = 10
    btn.Active = true
    btn.Selectable = true
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 5)
    btnCorner.Parent = btn
    btn.Parent = container

    safeConnect(btn.Activated, function()
        activeIdx = (activeIdx % #options) + 1
        local choice = options[activeIdx]
        Config[configKey] = choice
        btn.Text = tostring(choice)
        if callback then callback(choice) end
    end)
    
    container.Parent = parent
    return container
end

local function createValueAdjuster(parent, label, configKey, minVal, maxVal, step, callback)
    local container = Instance.new("Frame")
    container.Name = configKey .. "_AdjusterRow"
    container.Size = UDim2.new(1, 0, 0, 28)
    container.BackgroundColor3 = COLORS.rowBg
    container.BackgroundTransparency = COLORS.rowBgTrans
    container.BorderSizePixel = 0
    container.ZIndex = 7
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 6)
    containerCorner.Parent = container

    local lbl = Instance.new("TextLabel")
    lbl.Name = "Label"
    lbl.Size = UDim2.new(0.45, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = COLORS.text
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 10
    lbl.ZIndex = 8
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = container

    local controls = Instance.new("Frame")
    controls.Name = "Controls"
    controls.Size = UDim2.new(0.55, -8, 1, 0)
    controls.Position = UDim2.new(0.45, 0, 0, 0)
    controls.BackgroundTransparency = 1
    controls.ZIndex = 8
    controls.Parent = container

    local minusBtn = Instance.new("TextButton")
    minusBtn.Name = "MinusBtn"
    minusBtn.Size = UDim2.new(0, 18, 0, 18)
    minusBtn.Position = UDim2.new(0, 0, 0.5, -9)
    minusBtn.BackgroundColor3 = COLORS.bgLight
    minusBtn.Text = "-"
    minusBtn.TextColor3 = COLORS.text
    minusBtn.Font = Enum.Font.GothamBold
    minusBtn.TextSize = 10.5
    minusBtn.BorderSizePixel = 0
    minusBtn.ZIndex = 10
    minusBtn.Active = true
    minusBtn.Selectable = true
    
    local minusCorner = Instance.new("UICorner")
    minusCorner.CornerRadius = UDim.new(0, 4)
    minusCorner.Parent = minusBtn
    minusBtn.Parent = controls

    local valueBox = Instance.new("TextBox")
    valueBox.Name = "ValueBox"
    valueBox.Size = UDim2.new(1, -44, 0, 18)
    valueBox.Position = UDim2.new(0, 22, 0.5, -9)
    valueBox.BackgroundColor3 = COLORS.bgLight
    valueBox.Text = tostring(Config[configKey])
    valueBox.TextColor3 = Config.AccentColor1
    valueBox.Font = Enum.Font.GothamBold
    valueBox.TextSize = 10
    valueBox.ZIndex = 9
    
    local valueCorner = Instance.new("UICorner")
    valueCorner.CornerRadius = UDim.new(0, 4)
    valueCorner.Parent = valueBox
    valueBox.Parent = controls

    local plusBtn = Instance.new("TextButton")
    plusBtn.Name = "PlusBtn"
    plusBtn.Size = UDim2.new(0, 18, 0, 18)
    plusBtn.Position = UDim2.new(1, -18, 0.5, -9)
    plusBtn.BackgroundColor3 = COLORS.bgLight
    plusBtn.Text = "+"
    plusBtn.TextColor3 = COLORS.text
    plusBtn.Font = Enum.Font.GothamBold
    plusBtn.TextSize = 10.5
    plusBtn.BorderSizePixel = 0
    plusBtn.ZIndex = 10
    plusBtn.Active = true
    plusBtn.Selectable = true
    
    local plusCorner = Instance.new("UICorner")
    plusCorner.CornerRadius = UDim.new(0, 4)
    plusCorner.Parent = plusBtn
    plusBtn.Parent = controls

    local function updateValue(newVal)
        newVal = math.clamp(newVal, minVal, maxVal)
        Config[configKey] = newVal
        valueBox.Text = tostring(newVal)
        if callback then callback(newVal) end
    end

    safeConnect(minusBtn.Activated, function()
        updateValue(Config[configKey] - step)
    end)

    safeConnect(plusBtn.Activated, function()
        updateValue(Config[configKey] + step)
    end)

    safeConnect(valueBox.FocusLost, function()
        local num = tonumber(valueBox.Text)
        if num then updateValue(num) else valueBox.Text = tostring(Config[configKey]) end
    end)
    
    container.Parent = parent
    return container
end

-- Close Button trigger cleanup
safeConnect(CloseBtn.Activated, function()
    ScreenGui:Destroy()
    if _G.AuraCleanup then
        for _, conn in ipairs(_G.AuraCleanup) do
            pcall(function() conn:Disconnect() end)
        end
    end
    _G.AuraCleanup = nil
    _G.AuraScriptID = _G.AuraScriptID + 1 -- stops all background loops
end)

-- ═══════════════════════════════════════════
-- BUILD PAGES
-- ═══════════════════════════════════════════

-- Tab 1: Home (Welcome Page)
local HomeTab = createTabButton("Home", "Home", "🏠", 1)

local function createInfoRow(parent, label, value)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 20)
    row.BackgroundTransparency = 1
    row.ZIndex = 8
    
    local left = Instance.new("TextLabel")
    left.Size = UDim2.new(0.4, 0, 1, 0)
    left.Position = UDim2.new(0, 10, 0, 0)
    left.BackgroundTransparency = 1
    left.Text = label
    left.TextColor3 = COLORS.textDim
    left.Font = Enum.Font.GothamSemibold
    left.TextSize = 10
    left.TextXAlignment = Enum.TextXAlignment.Left
    left.ZIndex = 9
    left.Parent = row
    
    local right = Instance.new("TextLabel")
    right.Size = UDim2.new(0.6, -10, 1, 0)
    right.Position = UDim2.new(0.4, 10, 0, 0)
    right.BackgroundTransparency = 1
    right.Text = value
    if label == "Current build" then
        right.TextColor3 = Config.AccentColor1
    else
        right.TextColor3 = COLORS.text
    end
    right.Font = Enum.Font.GothamBold
    right.TextSize = 10
    right.TextXAlignment = Enum.TextXAlignment.Left
    right.ZIndex = 9
    right.Parent = row
    
    row.Parent = parent
    return row
end

local WelcomeCard = createCard(HomeTab, "Welcome")
local WelcomeFrame = Instance.new("Frame")
WelcomeFrame.Name = "WelcomeFrame"
WelcomeFrame.Size = UDim2.new(1, 0, 0, 32)
WelcomeFrame.BackgroundColor3 = Color3.fromRGB(15, 32, 20)
WelcomeFrame.BackgroundTransparency = 0.5
WelcomeFrame.BorderSizePixel = 0
WelcomeFrame.ZIndex = 8

local welcomeCorner = Instance.new("UICorner")
welcomeCorner.CornerRadius = UDim.new(0, 6)
welcomeCorner.Parent = WelcomeFrame

local greenStroke = Instance.new("UIStroke")
greenStroke.Color = Color3.fromRGB(46, 213, 115)
greenStroke.Thickness = 0.8
greenStroke.Parent = WelcomeFrame

local WelcomeIcon = Instance.new("TextLabel")
WelcomeIcon.Name = "WelcomeIcon"
WelcomeIcon.Size = UDim2.new(0, 24, 1, 0)
WelcomeIcon.Position = UDim2.new(0, 8, 0, 0)
WelcomeIcon.BackgroundTransparency = 1
WelcomeIcon.Text = "ⓘ"
WelcomeIcon.TextColor3 = Color3.fromRGB(46, 213, 115)
WelcomeIcon.Font = Enum.Font.GothamBold
WelcomeIcon.TextSize = 12
WelcomeIcon.ZIndex = 9
WelcomeIcon.Parent = WelcomeFrame

local WelcomeLabel = Instance.new("TextLabel")
WelcomeLabel.Name = "WelcomeLabel"
WelcomeLabel.Size = UDim2.new(1, -36, 1, 0)
WelcomeLabel.Position = UDim2.new(0, 32, 0, 0)
WelcomeLabel.BackgroundTransparency = 1
WelcomeLabel.Text = "Welcome, " .. LocalPlayer.Name .. ". Session authorized."
WelcomeLabel.TextColor3 = Color3.fromRGB(46, 213, 115)
WelcomeLabel.Font = Enum.Font.GothamBold
WelcomeLabel.TextSize = 10
WelcomeLabel.TextXAlignment = Enum.TextXAlignment.Left
WelcomeLabel.ZIndex = 9
WelcomeLabel.Parent = WelcomeFrame

WelcomeFrame.Parent = WelcomeCard

local InfoCard = createCard(HomeTab, "System Information")
createInfoRow(InfoCard, "Hub version", "v4.5 (XVC Edition)")
createInfoRow(InfoCard, "Hub Status", "All Features Tested & Operational")
createInfoRow(InfoCard, "Active account", LocalPlayer.Name)
createInfoRow(InfoCard, "Selected Player", "Aura Per Click (World 2)")
createInfoRow(InfoCard, "Current build", "Lovingly crafted for LO ❤️")
-- Tab 2: Farming
local FarmTab = createTabButton("Farming", "Farming", "⚡", 2)

local FarmCard1 = createCard(FarmTab, "Auto Farming")
createToggle(FarmCard1, "Enable Auto-Click / Train", "AutoClick")
createValueAdjuster(FarmCard1, "Clicks Per Sec (CPS)", "ClickSpeed", 1, 50, 1)
createToggle(FarmCard1, "Enable Auto-Wins", "AutoWins")
createToggle(FarmCard1, "Enable Auto-Rebirth", "AutoRebirth")

local FarmCard2 = createCard(FarmTab, "Upgrades & Shopping")
createToggle(FarmCard2, "Auto Buy Click Upgrades", "AutoBuyUpgrades")

local FarmCard3 = createCard(FarmTab, "Daily, Chests & Spins")
createToggle(FarmCard3, "Auto-Claim Time Gifts (1-12)", "AutoClaimGifts")
createToggle(FarmCard3, "Auto-Claim Group Chest", "AutoClaimGroup")
createToggle(FarmCard3, "Auto-Spin Wheel", "AutoSpin")

local FarmCard4 = createCard(FarmTab, "Session Statistics")
local StatsFrame = Instance.new("Frame")
StatsFrame.Name = "StatsFrame"
StatsFrame.Size = UDim2.new(1, -10, 0, 55)
StatsFrame.BackgroundColor3 = COLORS.bgLight
StatsFrame.BackgroundTransparency = 0.5
StatsFrame.BorderSizePixel = 0
StatsFrame.ZIndex = 8
StatsFrame.Parent = FarmCard4
local statsFrameCorner = Instance.new("UICorner")
statsFrameCorner.CornerRadius = UDim.new(0, 6)
statsFrameCorner.Parent = StatsFrame

local StatsLabel = Instance.new("TextLabel")
StatsLabel.Name = "StatsLabel"
StatsLabel.Size = UDim2.new(1, -16, 1, -10)
StatsLabel.Position = UDim2.new(0, 8, 0, 5)
StatsLabel.BackgroundTransparency = 1
StatsLabel.Text = "Aura: 0\nRebirths: 0\nStatus: Idle"
StatsLabel.TextColor3 = COLORS.textDim
StatsLabel.Font = Enum.Font.GothamSemibold
StatsLabel.TextSize = 10
StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
StatsLabel.ZIndex = 9
StatsLabel.Parent = StatsFrame

task.spawn(function()
    while currentScriptID == _G.AuraScriptID do
        task.wait(0.5)
        pcall(function()
            StatsLabel.Text = "Aura: " .. getAuraValue() .. "\nRebirths: " .. getRebirthsValue() .. "\nStatus: " .. SessionStats.Status
        end)
    end
end)

local function getPetRarity(petName)
    local name = petName:lower()
    if name == "camel" or name == "silver camel" or name == "gold camel" or name == "diamond camel" or name == "void camel" or name == "void ice cream" or name == "bubble gum" then
        return "uncommon"
    elseif name == "fox" or name == "silver fox" or name == "gold fox" or name == "diamond fox" or name == "void fox" or name == "void cupcake" then
        return "rare"
    elseif name == "silver panda" or name == "gold panda" or name == "diamond panda" or name == "void panda" or name == "void bubble gum" then
        return "epic"
    elseif name == "silver yeti" or name == "gold yeti" or name == "diamond yeti" or name == "void yeti" or name == "void candy" then
        return "legendary"
    elseif name == "silver unicorn" or name == "gold unicorn" or name == "diamond unicorn" or name == "void unicorn" or name == "void candy dominus" or name == "void candy gun" or name == "67" or name == "void chocolate" then
        return "rainbow"
    end
    
    -- Generic fallback patterns
    if name:find("camel") or name:find("bubble gum") or name:find("ice cream") then
        return "uncommon"
    elseif name:find("fox") or name:find("cupcake") then
        return "rare"
    elseif name:find("panda") then
        return "epic"
    elseif name:find("yeti") or name:find("candy") then
        return "legendary"
    elseif name:find("unicorn") or name:find("dominus") or name:find("gun") or name == "67" or name:find("chocolate") then
        return "rainbow"
    end
    return "common"
end

local function deleteInventoryByRarity(targetRarity)
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local ui = playerGui and playerGui:FindFirstChild("UI")
        local pets = ui and ui:FindFirstChild("Pets")
        local frame = pets and pets:FindFirstChild("Frame")
        local petsFolder = frame and frame:FindFirstChild("Pets")
        if not petsFolder then return end
        
        for _, child in ipairs(petsFolder:GetChildren()) do
            if child.Name == "Pet" then
                local name = child:GetAttribute("AuraRunnerPetName")
                local copyIndex = child:GetAttribute("AuraRunnerPetCopyIndex")
                if name and copyIndex then
                    local rarity = getPetRarity(name)
                    if rarity == targetRarity then
                        game:GetService("ReplicatedStorage").Remotes.AuraRunnerUpdatePets:InvokeServer({
                            action = "delete",
                            petName = name,
                            copyIndex = copyIndex
                        })
                        task.wait(0.08)
                    end
                end
            end
        end
    end)
end

-- Background inventory watcher using GUI child additions
task.spawn(function()
    pcall(function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
        local ui = playerGui and playerGui:WaitForChild("UI", 10)
        local pets = ui and ui:WaitForChild("Pets", 10)
        local frame = pets and pets:WaitForChild("Frame", 10)
        local petsFolder = frame and frame:WaitForChild("Pets", 10)
        
        if petsFolder then
            safeConnect(petsFolder.ChildAdded, function(child)
                if child.Name == "Pet" then
                    task.wait(0.15)
                    local name = child:GetAttribute("AuraRunnerPetName")
                    local copyIndex = child:GetAttribute("AuraRunnerPetCopyIndex")
                    if name and copyIndex then
                        local rarity = getPetRarity(name)
                        local shouldDelete = false
                        if rarity == "common" and Config.DeleteCommon then
                            shouldDelete = true
                        elseif rarity == "uncommon" and Config.DeleteUncommon then
                            shouldDelete = true
                        elseif rarity == "rare" and Config.DeleteRare then
                            shouldDelete = true
                        elseif rarity == "epic" and Config.DeleteEpic then
                            shouldDelete = true
                        end
                        
                        if shouldDelete then
                            game:GetService("ReplicatedStorage").Remotes.AuraRunnerUpdatePets:InvokeServer({
                                action = "delete",
                                petName = name,
                                copyIndex = copyIndex
                            })
                        end
                    end
                end
            end)
        end
    end)
end)

-- Tab 3: Pets & Eggs
local PetTab = createTabButton("Pets/Eggs", "Pets/Eggs", "🥚", 3)

local EggCard = createCard(PetTab, "Egg Hatcher")
createToggle(EggCard, "Auto Hatch Selected Egg", "AutoHatch")
createSelectionSelector(EggCard, "Target Egg Name", "SelectedEgg", EGG_OPTIONS)
createSelectionSelector(EggCard, "Hatch Quantity Mode", "HatchAmount", HATCH_QTY_OPTIONS)

local PetDeleteCard = createCard(PetTab, "Pet Auto-Delete & Cleaner")
createToggle(PetDeleteCard, "Auto-Delete Common on Hatch", "DeleteCommon")
createToggle(PetDeleteCard, "Auto-Delete Uncommon on Hatch", "DeleteUncommon")
createToggle(PetDeleteCard, "Auto-Delete Rare on Hatch", "DeleteRare")
createToggle(PetDeleteCard, "Auto-Delete Epic on Hatch", "DeleteEpic")

local function makeDeleteBtn(card, text, rarity)
    local btn = Instance.new("TextButton")
    btn.Name = "DeleteBtn_" .. rarity
    btn.Size = UDim2.new(1, 0, 0, 24)
    btn.BackgroundColor3 = COLORS.rowBg
    btn.BackgroundTransparency = COLORS.rowBgTrans
    btn.Text = "🗑️ " .. text
    btn.TextColor3 = Color3.fromRGB(255, 75, 75)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.BorderSizePixel = 0
    btn.ZIndex = 10
    btn.Active = true
    btn.Selectable = true
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    safeConnect(btn.Activated, function()
        btn.Text = "Deleting..."
        deleteInventoryByRarity(rarity)
        btn.Text = "🗑️ " .. text
    end)
    
    btn.Parent = card
end

makeDeleteBtn(PetDeleteCard, "Clean Inventory: Delete Common", "common")
makeDeleteBtn(PetDeleteCard, "Clean Inventory: Delete Uncommon", "uncommon")
makeDeleteBtn(PetDeleteCard, "Clean Inventory: Delete Rare", "rare")
makeDeleteBtn(PetDeleteCard, "Clean Inventory: Delete Epic", "epic")

local PetUtilityCard = createCard(PetTab, "Pet Utility")
local AutoEquipPetsBtn = Instance.new("TextButton")
AutoEquipPetsBtn.Name = "AutoEquipPetsBtn"
AutoEquipPetsBtn.Size = UDim2.new(1, -10, 0, 28)
AutoEquipPetsBtn.BackgroundColor3 = COLORS.bgLight
AutoEquipPetsBtn.Text = "⚡ Auto-Equip Best Pets"
AutoEquipPetsBtn.TextColor3 = COLORS.text
AutoEquipPetsBtn.Font = Enum.Font.GothamBold
AutoEquipPetsBtn.TextSize = 11
AutoEquipPetsBtn.BorderSizePixel = 0
AutoEquipPetsBtn.ZIndex = 10
AutoEquipPetsBtn.Active = true
AutoEquipPetsBtn.Selectable = true
AutoEquipPetsBtn.Parent = PetUtilityCard
local autoEquipPetsBtnCorner = Instance.new("UICorner")
autoEquipPetsBtnCorner.CornerRadius = UDim.new(0, 6)
autoEquipPetsBtnCorner.Parent = AutoEquipPetsBtn

safeConnect(AutoEquipPetsBtn.Activated, function()
    AutoEquipPetsBtn.Text = "Equipping..."
    pcall(function()
        ReplicatedStorage.Remotes.AuraRunnerUpdatePets:InvokeServer({action = "equip_best"})
    end)
    task.wait(0.8)
    AutoEquipPetsBtn.Text = "⚡ Auto-Equip Best Pets"
end)

local AutoUnequipPetsBtn = Instance.new("TextButton")
AutoUnequipPetsBtn.Name = "AutoUnequipPetsBtn"
AutoUnequipPetsBtn.Size = UDim2.new(1, -10, 0, 28)
AutoUnequipPetsBtn.BackgroundColor3 = COLORS.bgLight
AutoUnequipPetsBtn.Text = "❌ Unequip All Pets"
AutoUnequipPetsBtn.TextColor3 = COLORS.text
AutoUnequipPetsBtn.Font = Enum.Font.GothamBold
AutoUnequipPetsBtn.TextSize = 11
AutoUnequipPetsBtn.BorderSizePixel = 0
AutoUnequipPetsBtn.ZIndex = 10
AutoUnequipPetsBtn.Active = true
AutoUnequipPetsBtn.Selectable = true
AutoUnequipPetsBtn.Parent = PetUtilityCard
local autoUnequipPetsBtnCorner = Instance.new("UICorner")
autoUnequipPetsBtnCorner.CornerRadius = UDim.new(0, 6)
autoUnequipPetsBtnCorner.Parent = AutoUnequipPetsBtn

safeConnect(AutoUnequipPetsBtn.Activated, function()
    AutoUnequipPetsBtn.Text = "Unequipping..."
    pcall(function()
        ReplicatedStorage.Remotes.AuraRunnerUpdatePets:InvokeServer({action = "unequip_all"})
    end)
    task.wait(0.8)
    AutoUnequipPetsBtn.Text = "❌ Unequip All Pets"
end)

-- Tab 4: Teleports & Stages
local TeleTab = createTabButton("Teleport", "Teleport", "📍", 4)

local StageCard = createCard(TeleTab, "Stage Teleporter")
createSelectionSelector(StageCard, "Chosen Stage Target", "TeleportStageValue", STAGE_OPTIONS)

local TeleportBtn = Instance.new("TextButton")
TeleportBtn.Name = "TeleportBtn"
TeleportBtn.Size = UDim2.new(1, -10, 0, 28)
TeleportBtn.BackgroundColor3 = COLORS.bgLight
TeleportBtn.Text = "⚡ Teleport to Chosen Stage"
TeleportBtn.TextColor3 = COLORS.text
TeleportBtn.Font = Enum.Font.GothamBold
TeleportBtn.TextSize = 11
TeleportBtn.BorderSizePixel = 0
TeleportBtn.ZIndex = 10
TeleportBtn.Active = true
TeleportBtn.Selectable = true
TeleportBtn.Parent = StageCard
local teleportBtnCorner = Instance.new("UICorner")
teleportBtnCorner.CornerRadius = UDim.new(0, 6)
teleportBtnCorner.Parent = TeleportBtn

safeConnect(TeleportBtn.Activated, function()
    TeleportBtn.Text = "Teleporting..."
    pcall(function()
        local stageNum = tonumber(Config.TeleportStageValue:match("%d+")) or 1
        ReplicatedStorage.Remotes.AuraRunnerTeleportStage:InvokeServer({
            stageOrder = stageNum
        })
    end)
    task.wait(0.5)
    TeleportBtn.Text = "⚡ Teleport to Chosen Stage"
end)

local TreadmillCard = createCard(TeleTab, "Treadmill Teleporter")
createSelectionSelector(TreadmillCard, "Selected Treadmill", "SelectedTreadmill", {"1x", "2x", "3x", "5x", "7x", "9x", "15x", "50x", "75x"})

local TreadmillTeleportBtn = Instance.new("TextButton")
TreadmillTeleportBtn.Name = "TreadmillTeleportBtn"
TreadmillTeleportBtn.Size = UDim2.new(1, -10, 0, 28)
TreadmillTeleportBtn.BackgroundColor3 = COLORS.bgLight
TreadmillTeleportBtn.Text = "🏃 Teleport to Treadmill"
TreadmillTeleportBtn.TextColor3 = COLORS.text
TreadmillTeleportBtn.Font = Enum.Font.GothamBold
TreadmillTeleportBtn.TextSize = 11
TreadmillTeleportBtn.BorderSizePixel = 0
TreadmillTeleportBtn.ZIndex = 10
TreadmillTeleportBtn.Active = true
TreadmillTeleportBtn.Selectable = true
TreadmillTeleportBtn.Parent = TreadmillCard
local treadmillTeleportBtnCorner = Instance.new("UICorner")
treadmillTeleportBtnCorner.CornerRadius = UDim.new(0, 6)
treadmillTeleportBtnCorner.Parent = TreadmillTeleportBtn

local function teleportToTreadmill(name)
    local utility = workspace:FindFirstChild("Map") 
        and workspace.Map:FindFirstChild("Lobby") 
        and workspace.Map.Lobby:FindFirstChild("Utility")
    local treadmills = utility and utility:FindFirstChild("Treadmills")
    if treadmills then
        local targetModel = nil
        for _, child in ipairs(treadmills:GetChildren()) do
            if child.Name:sub(1, #name) == name then
                targetModel = child
                break
            end
        end
        if targetModel then
            local targetPart = targetModel.PrimaryPart or targetModel:FindFirstChild("Platform") or targetModel:FindFirstChildOfClass("BasePart")
            if not targetPart then
                for _, part in ipairs(targetModel:GetDescendants()) do
                    if part:IsA("BasePart") then
                        targetPart = part
                        break
                    end
                end
            end
            if targetPart then
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3.5, 0)
                    return true
                end
            end
        end
    end
    return false
end

safeConnect(TreadmillTeleportBtn.Activated, function()
    TreadmillTeleportBtn.Text = "Teleporting..."
    local ok = teleportToTreadmill(Config.SelectedTreadmill)
    task.wait(0.5)
    if ok then
        TreadmillTeleportBtn.Text = "🏃 Teleported!"
    else
        TreadmillTeleportBtn.Text = "❌ Treadmill Not Found"
    end
    task.wait(1)
    TreadmillTeleportBtn.Text = "🏃 Teleport to Treadmill"
end)

-- Tab 5: Movement Cheats
local MoveTab = createTabButton("Movement", "Movement", "🏃", 5)

local MoveCard = createCard(MoveTab, "Character Modifications")
createToggle(MoveCard, "Enable Custom Speed/Jump", "SpeedHack")
createValueAdjuster(MoveCard, "WalkSpeed Limit", "WalkSpeed", 16, 250, 5)
createValueAdjuster(MoveCard, "JumpPower Limit", "JumpPower", 50, 250, 5)
createToggle(MoveCard, "Noclip Mode (Walls)", "Noclip")
createToggle(MoveCard, "Flight Mode", "FlyHack")
createToggle(MoveCard, "Click Teleport (Ctrl + Click)", "ClickTP")

-- Tab 6: Settings & Styling
local SettingsTab = createTabButton("Settings", "Settings", "⚙️", 6)

local KeybindCard = createCard(SettingsTab, "Hotkey Registry")
local KeybindContainer = Instance.new("Frame")
KeybindContainer.Name = "KeybindContainer"
KeybindContainer.Size = UDim2.new(1, -10, 0, 28)
KeybindContainer.BackgroundTransparency = 1
KeybindContainer.ZIndex = 8
KeybindContainer.Parent = KeybindCard

local keyLbl = Instance.new("TextLabel")
keyLbl.Name = "Label"
keyLbl.Size = UDim2.new(0.5, 0, 1, 0)
keyLbl.Position = UDim2.new(0, 8, 0, 0)
keyLbl.BackgroundTransparency = 1
keyLbl.Text = "Toggle Menu Keybind"
keyLbl.TextColor3 = COLORS.text
keyLbl.Font = Enum.Font.GothamSemibold
keyLbl.TextSize = 10
keyLbl.ZIndex = 9
keyLbl.TextXAlignment = Enum.TextXAlignment.Left
keyLbl.Parent = KeybindContainer

local KeybindBtn = Instance.new("TextButton")
KeybindBtn.Name = "KeybindBtn"
KeybindBtn.Size = UDim2.new(0.5, -10, 0, 22)
KeybindBtn.Position = UDim2.new(0.5, 10, 0.5, -11)
KeybindBtn.BackgroundColor3 = COLORS.bgLight
KeybindBtn.Text = Config.UI_Keybind.Name
KeybindBtn.TextColor3 = Config.AccentColor1
KeybindBtn.Font = Enum.Font.GothamBold
KeybindBtn.TextSize = 9.5
KeybindBtn.BorderSizePixel = 0
KeybindBtn.ZIndex = 10
KeybindBtn.Active = true
KeybindBtn.Selectable = true
KeybindBtn.Parent = KeybindContainer
local keybindBtnCorner = Instance.new("UICorner")
keybindBtnCorner.CornerRadius = UDim.new(0, 5)
keybindBtnCorner.Parent = KeybindBtn

local binding = false
safeConnect(KeybindBtn.Activated, function()
    binding = true
    KeybindBtn.Text = "... Press Key ..."
end)

safeConnect(UserInputService.InputBegan, function(input, gp)
    if gp then return end
    if binding then
        if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Enum.KeyCode.Backspace then
            Config.UI_Keybind = input.KeyCode
            KeybindBtn.Text = input.KeyCode.Name
            StatusBar.Text = "  AURA Hub Operational • Status: Idle • Key: " .. input.KeyCode.Name
            binding = false
        end
    else
        if input.KeyCode == Config.UI_Keybind then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end
end)

local ThemesCard = createCard(SettingsTab, "Theme Presets")
local PresetsFrame = Instance.new("Frame")
PresetsFrame.Name = "PresetsFrame"
PresetsFrame.Size = UDim2.new(1, -10, 0, 24)
PresetsFrame.BackgroundTransparency = 1
PresetsFrame.ZIndex = 8
PresetsFrame.Parent = ThemesCard

local pLayout = Instance.new("UIGridLayout")
pLayout.CellSize = UDim2.new(0.2, -4, 0, 22)
pLayout.CellPadding = UDim2.new(0, 4, 0, 4)
pLayout.Parent = PresetsFrame

local function makePresetBtn(colors)
    local b = Instance.new("TextButton")
    b.Name = "PresetBtn"
    b.BackgroundColor3 = colors[1]
    b.Text = ""
    b.ZIndex = 10
    b.Active = true
    b.Selectable = true
    b.Parent = PresetsFrame
    local bCorner = Instance.new("UICorner")
bCorner.CornerRadius = UDim.new(0, 4)
bCorner.Parent = b
    safeConnect(b.Activated, function()
        Config.AccentColor1 = colors[1]
        Config.AccentColor2 = colors[2]
        KeybindBtn.TextColor3 = colors[1]
        updateTheme()
    end)
    local stroke = Instance.new("UIStroke")
    stroke.Color = colors[2]
    stroke.Thickness = 1
    stroke.Parent = b
end

makePresetBtn({Color3.fromRGB(255, 53, 94), Color3.fromRGB(157, 78, 221)}) -- Cyber Rose
makePresetBtn({Color3.fromRGB(255, 140, 0), Color3.fromRGB(255, 50, 50)})   -- Sunset Gold
makePresetBtn({Color3.fromRGB(0, 212, 255), Color3.fromRGB(30, 80, 255)})  -- Ocean Breeze
makePresetBtn({Color3.fromRGB(46, 213, 115), Color3.fromRGB(10, 18, 12)})  -- Toxic Green
makePresetBtn({Color3.fromRGB(240, 240, 245), Color3.fromRGB(70, 75, 90)}) -- Midnight Ghost

local OptionsCard = createCard(SettingsTab, "UI Window Options")
createValueAdjuster(OptionsCard, "UI Opacity (x100)", "UI_Transparency", 0, 100, 5, function(val)
    Config.UI_Transparency = val / 100
    updateTheme()
end)
createToggle(OptionsCard, "Enable Border Glow", "UI_Glow", function(on)
    glowStroke.Enabled = on
    updateTheme()
end)

showTab("Home")

-- ═══════════════════════════════════════════
-- RUNTIME CHEATS ENGINE & TELEPORT MUTEX
-- ═══════════════════════════════════════════

local teleportMutex = false
local boughtUpgrades = {}
local lastRebirths = 0

-- Background loop to unlock mouse when GUI is open
task.spawn(function()
    while currentScriptID == _G.AuraScriptID do
        task.wait(0.1)
        if ScreenGui.Enabled and not binding then
            UserInputService.MouseIconEnabled = true
            if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            end
        end
    end
end)

-- 1. Auto Clicker
task.spawn(function()
    while currentScriptID == _G.AuraScriptID do
        local delay = 1 / math.max(Config.ClickSpeed, 1)
        task.wait(delay)
        if Config.AutoClick then
            SessionStats.Status = "Auto-Clicking..."
            pcall(function()
                ReplicatedStorage.Remotes.AuraRunnerTrainClick:FireServer({})
            end)
        end
    end
end)

-- 2. Auto Rebirth
task.spawn(function()
    while currentScriptID == _G.AuraScriptID do
        task.wait(1)
        if Config.AutoRebirth then
            SessionStats.Status = "Auto-Rebirthing..."
            pcall(function()
                ReplicatedStorage.Remotes.AuraRunnerRebirth:InvokeServer({})
            end)
        end
    end
end)

-- 3. Auto Egg Hatch (TRIPLE LOOP FIX)
task.spawn(function()
    while currentScriptID == _G.AuraScriptID do
        task.wait(1.2)
        if Config.AutoHatch then
            local eggId = EGG_MAPPING[Config.SelectedEgg] or "1"
            SessionStats.Status = "Hatching Egg " .. eggId .. "..."
            pcall(function()
                local amount = HATCH_QTY_MAPPING[Config.HatchAmount] or 1
                for i = 1, amount do
                    ReplicatedStorage.Remotes.AuraRunnerHatchEgg:InvokeServer({
                        eggModelName = eggId
                    })
                end
            end)
        end
    end
end)

-- 4. Auto Claim Free Gifts & Group Chest
task.spawn(function()
    while currentScriptID == _G.AuraScriptID do
        task.wait(20)
        if Config.AutoClaimGifts then
            for i = 1, 12 do
                pcall(function()
                    ReplicatedStorage.Remotes.ClaimFreeReward:FireServer(i)
                end)
            end
        end
        if Config.AutoClaimGroup then
            pcall(function()
                ReplicatedStorage.Remotes.AuraRunnerClaimGroupReward:InvokeServer()
            end)
        end
    end
end)

-- 5. Auto Buy Click Upgrades (PHYSICAL TELEPORT TOUCH)
task.spawn(function()
    while currentScriptID == _G.AuraScriptID do
        task.wait(1.5)
        if Config.AutoBuyUpgrades and not teleportMutex then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                
                local map = workspace:FindFirstChild("Map")
                local lobby = map and map:FindFirstChild("Lobby")
                local utility = lobby and lobby:FindFirstChild("Utility")
                local upgrades = utility and utility:FindFirstChild("Upgrades")
                if upgrades then
                    local currentWins = getWinsValue()
                    
                    -- Reset bought upgrades list on rebirth change
                    local currentRebirths = getRebirthsValue()
                    if currentRebirths ~= lastRebirths then
                        lastRebirths = currentRebirths
                        table.clear(boughtUpgrades)
                    end
                    
                    local affordable = {}
                    for _, u in ipairs(upgrades:GetChildren()) do
                        local price = tonumber(u.Name)
                        if price and currentWins >= price then
                            local touch = u:FindFirstChild("touch") or u:FindFirstChild("Touch")
                            if touch and not boughtUpgrades[u.Name] then
                                table.insert(affordable, {name = u.Name, price = price, touch = touch})
                            end
                        end
                    end
                    
                    -- Sort affordable upgrades descending by price so we grab the best ones first
                    table.sort(affordable, function(a, b) return a.price > b.price end)
                    
                    if #affordable > 0 then
                        teleportMutex = true
                        local oldCF = hrp.CFrame
                        
                        for _, item in ipairs(affordable) do
                            SessionStats.Status = "Buying Click Upgrades..."
                            hrp.CFrame = item.touch.CFrame + Vector3.new(0, 1, 0)
                            task.wait(0.12) -- wait for server touch registration
                            boughtUpgrades[item.name] = true
                        end
                        
                        hrp.CFrame = oldCF
                        SessionStats.Status = "Idle"
                        teleportMutex = false
                    end
                end
            end)
        end
    end
end)

-- 6. Auto Spin Wheel
task.spawn(function()
    while currentScriptID == _G.AuraScriptID do
        task.wait(1.5)
        if Config.AutoSpin then
            pcall(function()
                local spinWheelFolder = ReplicatedStorage:FindFirstChild("SpinWheel")
                
                local claimFree = spinWheelFolder and spinWheelFolder:FindFirstChild("ClaimFreeSpin")
                if claimFree then
                    claimFree:InvokeServer()
                end
                
                local stats = LocalPlayer:FindFirstChild("Stats")
                local spins = stats and stats:FindFirstChild("Spins")
                if spins and spins.Value > 0 then
                    local get = spinWheelFolder and spinWheelFolder:FindFirstChild("GetReward")
                    local claim = spinWheelFolder and spinWheelFolder:FindFirstChild("ClaimReward")
                    if get and claim then
                        SessionStats.Status = "Auto-Spinning..."
                        local reward = get:InvokeServer()
                        if reward then
                            task.wait(0.5)
                            claim:FireServer()
                            SessionStats.Status = "Claimed Spin: " .. tostring(reward)
                        end
                    end
                end
            end)
        end
    end
end)

-- 7. Auto Wins Loop (CRITICAL FIX: AVOID PREMIUM GAMEPASS WINPAD)
local function getHighestWinPart()
    local highestNum = -1
    local highestPart = nil
    local map = workspace:FindFirstChild("Map")
    if map then
        for _, child in ipairs(map:GetChildren()) do
            if child.Name:sub(1, 6) == "Stage_" then
                local num = tonumber(child.Name:sub(7))
                if num then
                    local win = child:FindFirstChild("Win", true) or child:FindFirstChild("win", true)
                    if win then
                        for _, part in ipairs(win:GetChildren()) do
                            -- Filter for WinParts that have the winAmount BillboardGui (the free ones!)
                            if part.Name == "WinPart" and (part:FindFirstChild("winAmount") or part:FindFirstChild("WinAmount")) then
                                if num > highestNum then
                                    highestNum = num
                                    highestPart = part
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return highestPart
end

task.spawn(function()
    while currentScriptID == _G.AuraScriptID do
        task.wait(0.6)
        if Config.AutoWins and not teleportMutex then
            pcall(function()
                local winPart = getHighestWinPart()
                if winPart then
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        teleportMutex = true
                        SessionStats.Status = "Auto-Winning..."
                        hrp.CFrame = winPart.CFrame
                        task.wait(0.12)
                        teleportMutex = false
                    end
                end
            end)
        end
    end
end)

-- 8. Character Cheats Loops

-- WalkSpeed / JumpPower loop
safeConnect(RunService.Heartbeat, function()
    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if Config.SpeedHack and humanoid then
        humanoid.WalkSpeed = Config.WalkSpeed
        humanoid.JumpPower = Config.JumpPower
    end
end)

-- Noclip loop
safeConnect(RunService.Stepped, function()
    if not Config.Noclip then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end)

-- Click Teleport (Ctrl + Click)
local mouse = LocalPlayer:GetMouse()
safeConnect(mouse.Button1Down, function()
    if Config.ClickTP and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and mouse.Hit then
            hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end
end)

-- Minimize Logic
local isMin = false
safeConnect(MinBtn.Activated, function()
    isMin = not isMin
    local targetSize = isMin and UDim2.new(0, mainWidth, 0, 45) or UDim2.new(0, mainWidth, 0, mainHeight)
    TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {Size = targetSize}):Play()
    TweenService:Create(Shadow, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
        Size = isMin and UDim2.new(0, mainWidth + 4, 0, 49) or UDim2.new(0, mainWidth + 4, 0, mainHeight + 4)
    }):Play()
    MinBtn.Text = isMin and "+" or "−"
    Sidebar.Visible = not isMin
    ContentCol.Size = isMin and UDim2.new(1, 0, 1, 0) or UDim2.new(1, -150, 1, 0)
    ContentCol.Position = isMin and UDim2.new(0, 0, 0, 0) or UDim2.new(0, 150, 0, 0)
    TabContainer.Visible = not isMin
    StatusBar.Visible = not isMin
    ResizeGrip.Visible = not isMin
end)

-- ═══════════════════════════════════════════
-- SPLASH SCREEN INTRO LOADER
-- ═══════════════════════════════════════════
local Splash = Instance.new("Frame")
Splash.Name = "Splash"
Splash.Size = UDim2.new(0, 300, 0, 160)
Splash.Position = UDim2.new(0.5, -150, 0.5, -80)
Splash.BackgroundColor3 = COLORS.bg
Splash.BorderSizePixel = 0
Splash.ZIndex = 100
Splash.Parent = ScreenGui
local splashCorner = Instance.new("UICorner")
splashCorner.CornerRadius = UDim.new(0, 12)
splashCorner.Parent = Splash

local splashStroke = Instance.new("UIStroke")
splashStroke.Color = Config.AccentColor1
splashStroke.Thickness = 1.5
splashStroke.Parent = Splash

local SplashGrad = Instance.new("UIGradient")
SplashGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Config.AccentColor1),
    ColorSequenceKeypoint.new(1, Config.AccentColor2),
})
SplashGrad.Parent = splashStroke

local SplashTitle = Instance.new("TextLabel")
SplashTitle.Size = UDim2.new(1, 0, 0, 40)
SplashTitle.Position = UDim2.new(0, 0, 0.2, 0)
SplashTitle.BackgroundTransparency = 1
SplashTitle.Text = "✨ AURA CLICKER HUB"
SplashTitle.TextColor3 = COLORS.text
SplashTitle.TextSize = 16
SplashTitle.Font = Enum.Font.GothamBlack
SplashTitle.ZIndex = 101
SplashTitle.Parent = Splash

local SplashStatus = Instance.new("TextLabel")
SplashStatus.Size = UDim2.new(1, 0, 0, 30)
SplashStatus.Position = UDim2.new(0, 0, 0.5, 0)
SplashStatus.BackgroundTransparency = 1
SplashStatus.Text = "Authenticating Session..."
SplashStatus.TextColor3 = COLORS.textDim
SplashStatus.TextSize = 10
SplashStatus.Font = Enum.Font.GothamSemibold
SplashStatus.ZIndex = 101
SplashStatus.Parent = Splash

local ProgressBarBG = Instance.new("Frame")
ProgressBarBG.Size = UDim2.new(0.8, 0, 0, 6)
ProgressBarBG.Position = UDim2.new(0.1, 0, 0.75, 0)
ProgressBarBG.BackgroundColor3 = COLORS.toggleOff
ProgressBarBG.BorderSizePixel = 0
ProgressBarBG.ZIndex = 101
ProgressBarBG.Parent = Splash
local progressBarBgCorner = Instance.new("UICorner")
progressBarBgCorner.CornerRadius = UDim.new(1, 0)
progressBarBgCorner.Parent = ProgressBarBG

local ProgressBar = Instance.new("Frame")
ProgressBar.Size = UDim2.new(0, 0, 1, 0)
ProgressBar.BackgroundColor3 = Config.AccentColor1
ProgressBar.BorderSizePixel = 0
ProgressBar.ZIndex = 102
ProgressBar.Parent = ProgressBarBG
local barCorner = Instance.new("UICorner")
barCorner.Parent = ProgressBar
barCorner.CornerRadius = UDim.new(1, 0)

local progressGrad = Instance.new("UIGradient")
progressGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Config.AccentColor1),
    ColorSequenceKeypoint.new(1, Config.AccentColor2),
})
progressGrad.Parent = ProgressBar

-- Hide main UI initially for intro reveal
Main.Visible = false
Shadow.Visible = false

task.spawn(function()
    TweenService:Create(ProgressBar, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.4, 0, 1, 0)}):Play()
    task.wait(0.6)
    if currentScriptID ~= _G.AuraScriptID then return end
    SplashStatus.Text = "Checking Game Version..."
    TweenService:Create(ProgressBar, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.7, 0, 1, 0)}):Play()
    task.wait(0.4)
    if currentScriptID ~= _G.AuraScriptID then return end
    SplashStatus.Text = "Loading XVC Profile Badges..."
    TweenService:Create(ProgressBar, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)}):Play()
    task.wait(0.5)
    if currentScriptID ~= _G.AuraScriptID then return end
    SplashStatus.Text = "Loaded successfully!"
    task.wait(0.3)
    
    -- Fade out splash intro
    TweenService:Create(Splash, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
    TweenService:Create(SplashTitle, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {TextTransparency = 1}):Play()
    TweenService:Create(SplashStatus, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {TextTransparency = 1}):Play()
    TweenService:Create(ProgressBarBG, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
    TweenService:Create(ProgressBar, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
    TweenService:Create(splashStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Transparency = 1}):Play()
    task.wait(0.35)
    if currentScriptID ~= _G.AuraScriptID then return end
    Splash:Destroy()
    
    -- Smooth slide-in main UI reveal
    Main.Visible = true
    Shadow.Visible = true
    Main.Size = UDim2.new(0, mainWidth, 0, 0)
    Main.BackgroundTransparency = 1
    Shadow.BackgroundTransparency = 1
    
    TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Back), {Size = UDim2.new(0, mainWidth, 0, mainHeight)}):Play()
    TweenService:Create(Main, TweenInfo.new(0.4), {BackgroundTransparency = Config.UI_Transparency}):Play()
    TweenService:Create(Shadow, TweenInfo.new(0.4), {BackgroundTransparency = 0.55}):Play()
    
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "✨ Aura Clicker Hub",
            Text = "Press " .. Config.UI_Keybind.Name .. " to open/close menu!",
            Duration = 5,
        })
    end)
end)

print("[ENI] Aura Per Click Hub v4.5 loaded successfully!")
updateTheme()
