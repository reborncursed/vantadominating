cat > /mnt/user-data/outputs/NemesisX_Premium_UI.lua << 'ENDOFSCRIPT'
-- ==========================================================
-- NEMESIS X PREMIUM EDITION — UI ONLY
-- Based on Sacred UI by CursedExility
-- 70+ Features | All Seas | Premium Design
-- ==========================================================

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Stats            = game:GetService("Stats")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── Cleanup ──
for _, oldUI in ipairs(playerGui:GetChildren()) do
    if oldUI.Name == "NemesisX_UI" or oldUI.Name == "NemesisX_ToggleIcon" then
        oldUI:Destroy()
    end
end

-- ==========================================================
-- THEME SYSTEM (Sacred exact structure)
-- ==========================================================
local THEMES = {
    ["Morado Neon"]    = Color3.fromRGB(170, 0,   255),
    ["Azul Electrico"] = Color3.fromRGB(0,   150, 255),
    ["Rojo Carmesi"]   = Color3.fromRGB(255, 0,   50),
    ["Verde Toxico"]   = Color3.fromRGB(0,   255, 100),
    ["Dorado"]         = Color3.fromRGB(240, 185, 55),
    ["Cyan"]           = Color3.fromRGB(0,   220, 220),
}

local currentThemeColor = THEMES["Morado Neon"]
local COLORS = {
    Background = Color3.fromRGB(10,  8,  14),
    PanelBG    = Color3.fromRGB(16,  12, 22),
    CardBG     = Color3.fromRGB(13,  10, 18),
    TextWhite  = Color3.fromRGB(255, 255, 255),
    TextGray   = Color3.fromRGB(140, 140, 145),
    ToggleOff  = Color3.fromRGB(26,  20, 32),
    Green      = Color3.fromRGB(45,  210, 110),
    Red        = Color3.fromRGB(215, 60,  60),
    Gold       = Color3.fromRGB(240, 185, 55),
}

local themeStrokes = {}
local themeTexts   = {}
local themeFrames  = {}

-- ==========================================================
-- SCREEN GUI
-- ==========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "NemesisX_UI"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.ResetOnSpawn   = false
screenGui.Parent         = playerGui

-- ==========================================================
-- MAIN FRAME (480x290 — Sacred proportion, slightly taller)
-- ==========================================================
local mainFrame = Instance.new("Frame")
mainFrame.Name             = "MainFrame"
mainFrame.Size             = UDim2.new(0, 520, 0, 300)
mainFrame.Position         = UDim2.new(0.5, -260, 0.5, -150)
mainFrame.BackgroundColor3 = COLORS.Background
mainFrame.BorderSizePixel  = 0
mainFrame.Active           = true
mainFrame.Draggable        = true
mainFrame.ZIndex           = 2
mainFrame.Parent           = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent       = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Thickness = 1.2
mainStroke.Color     = currentThemeColor
mainStroke.Parent    = mainFrame
table.insert(themeStrokes, mainStroke)

-- Animated stroke pulse
task.spawn(function()
    local t = 0
    while mainFrame and mainFrame.Parent do
        task.wait(0.06); t += 0.06
        if mainStroke and mainStroke.Parent then
            mainStroke.Transparency = 0.3 + 0.4 * math.abs(math.sin(t * 0.5))
        end
    end
end)

-- ==========================================================
-- TOGGLE ICON (Sacred exact — letter "N")
-- ==========================================================
local toggleIconGui = Instance.new("ScreenGui")
toggleIconGui.Name           = "NemesisX_ToggleIcon"
toggleIconGui.ResetOnSpawn   = false
toggleIconGui.Parent         = playerGui

local openButton = Instance.new("TextButton")
openButton.Name             = "OpenIcon"
openButton.Size             = UDim2.new(0, 38, 0, 38)
openButton.Position         = UDim2.new(0, 15, 0.5, -19)
openButton.BackgroundColor3 = COLORS.Background
openButton.Text             = "N"
openButton.Font             = Enum.Font.GothamBold
openButton.TextSize         = 14
openButton.TextColor3       = currentThemeColor
openButton.Visible          = false
openButton.Active           = true
openButton.Draggable        = true
openButton.ZIndex           = 10
openButton.Parent           = toggleIconGui
table.insert(themeTexts, openButton)

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(1, 0)
openCorner.Parent       = openButton

local openStroke = Instance.new("UIStroke")
openStroke.Thickness = 1.2
openStroke.Color     = currentThemeColor
openStroke.Parent    = openButton
table.insert(themeStrokes, openStroke)

local function hideMainUI()
    mainFrame.Visible  = false
    openButton.Visible = true
end

local function showMainUI()
    mainFrame.Visible  = true
    openButton.Visible = false
end

openButton.MouseButton1Click:Connect(showMainUI)

-- ==========================================================
-- TOP CONTROLS (Sacred exact: minimize + close)
-- ==========================================================
local controlsContainer = Instance.new("Frame")
controlsContainer.Size                = UDim2.new(0, 50, 0, 25)
controlsContainer.Position            = UDim2.new(1, -60, 0, 8)
controlsContainer.BackgroundTransparency = 1
controlsContainer.ZIndex              = 5
controlsContainer.Parent              = mainFrame

local function createTopControl(text, xOffset, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, 20, 0, 20)
    btn.Position         = UDim2.new(0, xOffset, 0, 2)
    btn.BackgroundColor3 = COLORS.PanelBG
    btn.Text             = text
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 11
    btn.TextColor3       = color
    btn.ZIndex           = 6
    btn.Parent           = controlsContainer
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = btn
    btn.MouseButton1Click:Connect(callback)
end

createTopControl("-", 0, COLORS.TextGray, hideMainUI)
createTopControl("X", 26, Color3.fromRGB(255, 75, 75), hideMainUI)

UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.F4 then
        if mainFrame.Visible then hideMainUI() else showMainUI() end
    end
end)

-- ==========================================================
-- RAIN EFFECT (Sacred exact)
-- ==========================================================
local rainContainer = Instance.new("Frame")
rainContainer.Name                = "RainContainer"
rainContainer.Size                = UDim2.new(1, 0, 1, 0)
rainContainer.BackgroundTransparency = 1
rainContainer.ClipsDescendants    = true
rainContainer.ZIndex              = 3
rainContainer.Parent              = mainFrame

local function spawnRainDrop()
    while mainFrame and mainFrame.Parent do
        if mainFrame.Visible then
            for i = 1, 2 do
                local drop = Instance.new("Frame")
                drop.Size                    = UDim2.new(0, 1, 0, math.random(10, 20))
                drop.Position                = UDim2.new(math.random(), 0, 0, -25)
                drop.BackgroundColor3        = currentThemeColor
                drop.BorderSizePixel         = 0
                drop.BackgroundTransparency  = 0.5
                drop.ZIndex                  = 3
                drop.Parent                  = rainContainer
                table.insert(themeFrames, drop)

                local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = drop

                local dur = math.random(7, 12) / 10
                local tw  = TweenService:Create(drop, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
                    Position = UDim2.new(drop.Position.X.Scale, 0, 1, 10)
                })
                tw:Play()
                tw.Completed:Connect(function()
                    local idx = table.find(themeFrames, drop)
                    if idx then table.remove(themeFrames, idx) end
                    drop:Destroy()
                end)
            end
        end
        task.wait(0.025)
    end
end
task.spawn(spawnRainDrop)

-- ==========================================================
-- SIDEBAR (Sacred structure, Nemesis X tabs)
-- ==========================================================
local sidebar = Instance.new("Frame")
sidebar.Size                = UDim2.new(0, 118, 1, 0)
sidebar.BackgroundColor3    = COLORS.PanelBG
sidebar.BackgroundTransparency = 0.2
sidebar.BorderSizePixel     = 0
sidebar.ZIndex              = 4
sidebar.Parent              = mainFrame

local sbCorner = Instance.new("UICorner"); sbCorner.CornerRadius = UDim.new(0, 10); sbCorner.Parent = sidebar
local sbFix = Instance.new("Frame")
sbFix.Size             = UDim2.new(0, 10, 1, 0)
sbFix.Position         = UDim2.new(1, -10, 0, 0)
sbFix.BackgroundColor3 = COLORS.PanelBG
sbFix.BackgroundTransparency = 0.2
sbFix.BorderSizePixel  = 0
sbFix.Parent           = sidebar

-- Logo
local mainTitle = Instance.new("TextLabel")
mainTitle.Text             = "⚔ Nemesis X"
mainTitle.Font             = Enum.Font.GothamBlack
mainTitle.TextSize         = 12
mainTitle.TextColor3       = currentThemeColor
mainTitle.Size             = UDim2.new(1, 0, 0, 16)
mainTitle.Position         = UDim2.new(0, 12, 0, 10)
mainTitle.BackgroundTransparency = 1
mainTitle.TextXAlignment   = Enum.TextXAlignment.Left
mainTitle.ZIndex           = 5
mainTitle.Parent           = sidebar
table.insert(themeTexts, mainTitle)

local subTitle = Instance.new("TextLabel")
subTitle.Text              = "PREMIUM EDITION"
subTitle.Font              = Enum.Font.Gotham
subTitle.TextSize          = 7
subTitle.TextColor3        = COLORS.TextGray
subTitle.Size              = UDim2.new(1, 0, 0, 10)
subTitle.Position          = UDim2.new(0, 12, 0, 27)
subTitle.BackgroundTransparency = 1
subTitle.TextXAlignment    = Enum.TextXAlignment.Left
subTitle.ZIndex            = 5
subTitle.Parent            = sidebar

local navDiv = Instance.new("Frame")
navDiv.Size             = UDim2.new(0.85, 0, 0, 1)
navDiv.Position         = UDim2.new(0.075, 0, 0, 40)
navDiv.BackgroundColor3 = currentThemeColor
navDiv.BackgroundTransparency = 0.7
navDiv.BorderSizePixel  = 0
navDiv.ZIndex           = 5
navDiv.Parent           = sidebar
table.insert(themeFrames, navDiv)

-- Nav scroll
local navScroll = Instance.new("ScrollingFrame")
navScroll.Size                = UDim2.new(1, 0, 1, -45)
navScroll.Position            = UDim2.new(0, 0, 0, 44)
navScroll.BackgroundTransparency = 1
navScroll.BorderSizePixel     = 0
navScroll.ScrollBarThickness  = 2
navScroll.ScrollBarImageColor3 = currentThemeColor
navScroll.CanvasSize          = UDim2.new(0, 0, 0, 0)
navScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
navScroll.ZIndex              = 5
navScroll.Parent              = sidebar
table.insert(themeStrokes, Instance.new("UIStroke")) -- placeholder keep list consistent

local navLayout = Instance.new("UIListLayout")
navLayout.Padding    = UDim.new(0, 1)
navLayout.SortOrder  = Enum.SortOrder.LayoutOrder
navLayout.Parent     = navScroll

local navPad = Instance.new("UIPadding")
navPad.PaddingLeft  = UDim.new(0, 6)
navPad.PaddingRight = UDim.new(0, 6)
navPad.PaddingTop   = UDim.new(0, 2)
navPad.Parent       = navScroll

-- ==========================================================
-- CONTENT AREA
-- ==========================================================
local contentFrame = Instance.new("Frame")
contentFrame.Size                = UDim2.new(1, -122, 1, -4)
contentFrame.Position            = UDim2.new(0, 120, 0, 2)
contentFrame.BackgroundTransparency = 1
contentFrame.ZIndex              = 4
contentFrame.Parent              = mainFrame

-- ==========================================================
-- THEME SELECTOR (Sacred exact, top-right of content)
-- ==========================================================
local themeSelector = Instance.new("TextButton")
themeSelector.Text             = "Morado Neon  ▼"
themeSelector.Font             = Enum.Font.GothamBold
themeSelector.TextSize         = 9
themeSelector.TextColor3       = currentThemeColor
themeSelector.Size             = UDim2.new(0, 108, 0, 18)
themeSelector.Position         = UDim2.new(1, -112, 0, 5)
themeSelector.BackgroundColor3 = COLORS.PanelBG
themeSelector.ZIndex           = 15
themeSelector.Parent           = contentFrame
table.insert(themeTexts, themeSelector)

local tsC = Instance.new("UICorner"); tsC.CornerRadius = UDim.new(0, 4); tsC.Parent = themeSelector
local tsS = Instance.new("UIStroke"); tsS.Thickness = 1; tsS.Color = Color3.fromRGB(55,50,65); tsS.Parent = themeSelector

local themeDropdownList = Instance.new("Frame")
themeDropdownList.Size             = UDim2.new(1, 0, 0, 108)
themeDropdownList.Position         = UDim2.new(0, 0, 1, 4)
themeDropdownList.BackgroundColor3 = COLORS.PanelBG
themeDropdownList.Visible          = false
themeDropdownList.ZIndex           = 20
themeDropdownList.Parent           = themeSelector

local tdlC = Instance.new("UICorner"); tdlC.CornerRadius = UDim.new(0, 5); tdlC.Parent = themeDropdownList
local tdlS = Instance.new("UIStroke"); tdlS.Thickness = 1; tdlS.Color = Color3.fromRGB(55,50,65); tdlS.Parent = themeDropdownList
local tdlL = Instance.new("UIListLayout"); tdlL.SortOrder = Enum.SortOrder.LayoutOrder; tdlL.Parent = themeDropdownList

local function applyNewTheme(themeName)
    currentThemeColor = THEMES[themeName]
    themeSelector.Text = themeName .. "  ▼"
    for _, s in ipairs(themeStrokes) do if s and s.Parent then s.Color = currentThemeColor end end
    for _, t in ipairs(themeTexts)   do if t and t.Parent then t.TextColor3 = currentThemeColor end end
    for _, f in ipairs(themeFrames)  do if f and f.Parent then f.BackgroundColor3 = currentThemeColor end end
    themeDropdownList.Visible = false
end

local tidx = 1
for name, color in pairs(THEMES) do
    local opt = Instance.new("TextButton")
    opt.Size             = UDim2.new(1, 0, 0, 18)
    opt.BackgroundTransparency = 1
    opt.Text             = name
    opt.Font             = Enum.Font.GothamSemibold
    opt.TextSize         = 9
    opt.TextColor3       = color
    opt.ZIndex           = 22
    opt.LayoutOrder      = tidx
    opt.Parent           = themeDropdownList
    opt.MouseButton1Click:Connect(function() applyNewTheme(name) end)
    tidx += 1
end
themeSelector.MouseButton1Click:Connect(function()
    themeDropdownList.Visible = not themeDropdownList.Visible
end)

-- ==========================================================
-- UI HELPERS (Sacred exact functions preserved + extended)
-- ==========================================================

-- createModuleCard — Sacred exact
local function createModuleCard(name, size, pos, parent)
    parent = parent or contentFrame
    local card = Instance.new("Frame")
    card.Size             = size
    card.Position         = pos
    card.BackgroundColor3 = COLORS.PanelBG
    card.ZIndex           = 4
    card.Parent           = parent

    local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 6); cc.Parent = card
    local cs = Instance.new("UIStroke"); cs.Thickness = 1; cs.Color = currentThemeColor; cs.Transparency = 0.2; cs.Parent = card
    table.insert(themeStrokes, cs)

    local sideLine = Instance.new("Frame")
    sideLine.Size             = UDim2.new(0, 2, 0, 11)
    sideLine.Position         = UDim2.new(0, 8, 0, 8)
    sideLine.BackgroundColor3 = currentThemeColor
    sideLine.BorderSizePixel  = 0
    sideLine.ZIndex           = 5
    sideLine.Parent           = card
    table.insert(themeFrames, sideLine)

    local title = Instance.new("TextLabel")
    title.Text             = name
    title.Font             = Enum.Font.GothamBold
    title.TextSize         = 10
    title.TextColor3       = COLORS.TextWhite
    title.Size             = UDim2.new(1, -25, 0, 25)
    title.Position         = UDim2.new(0, 15, 0, 1)
    title.BackgroundTransparency = 1
    title.TextXAlignment   = Enum.TextXAlignment.Left
    title.ZIndex           = 5
    title.Parent           = card

    return card
end

-- addToggleElement — Sacred exact
local function addToggleElement(parent, labelText, defaultState, yPos, callback)
    local state = defaultState

    local frame = Instance.new("Frame")
    frame.Size             = UDim2.new(1, -16, 0, 22)
    frame.Position         = UDim2.new(0, 8, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.ZIndex           = 5
    frame.Parent           = parent

    local label = Instance.new("TextLabel")
    label.Text             = labelText
    label.Font             = Enum.Font.Gotham
    label.TextSize         = 10
    label.TextColor3       = COLORS.TextWhite
    label.Size             = UDim2.new(0, 130, 1, 0)
    label.BackgroundTransparency = 1
    label.TextXAlignment   = Enum.TextXAlignment.Left
    label.ZIndex           = 5
    label.Parent           = frame

    local clickBtn = Instance.new("TextButton")
    clickBtn.Size             = UDim2.new(0, 28, 0, 14)
    clickBtn.Position         = UDim2.new(1, -28, 0.5, -7)
    clickBtn.BackgroundColor3 = state and currentThemeColor or COLORS.ToggleOff
    clickBtn.Text             = ""
    clickBtn.ZIndex           = 5
    clickBtn.Parent           = frame
    if state then table.insert(themeFrames, clickBtn) end

    local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(1, 0); tc.Parent = clickBtn

    local dot = Instance.new("Frame")
    dot.Size             = UDim2.new(0, 10, 0, 10)
    dot.Position         = UDim2.new(state and 1 or 0, state and -12 or 2, 0.5, -5)
    dot.BackgroundColor3 = COLORS.TextWhite
    dot.ZIndex           = 6
    dot.Parent           = clickBtn
    local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = dot

    clickBtn.MouseButton1Click:Connect(function()
        state = not state
        local tx = state and 1 or 0
        local to = state and -12 or 2
        if state then
            clickBtn.BackgroundColor3 = currentThemeColor
            table.insert(themeFrames, clickBtn)
        else
            local idx = table.find(themeFrames, clickBtn)
            if idx then table.remove(themeFrames, idx) end
            clickBtn.BackgroundColor3 = COLORS.ToggleOff
        end
        TweenService:Create(dot, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
            Position = UDim2.new(tx, to, 0.5, -5)
        }):Play()
        if callback then callback(state) end
    end)

    return frame, clickBtn
end

-- addSliderElement — Sacred exact
local function addSliderElement(parent, labelText, min, max, default, yPos, callback)
    local frame = Instance.new("Frame")
    frame.Size             = UDim2.new(1, -16, 0, 30)
    frame.Position         = UDim2.new(0, 8, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.ZIndex           = 5
    frame.Parent           = parent

    local label = Instance.new("TextLabel")
    label.Text             = labelText
    label.Font             = Enum.Font.Gotham
    label.TextSize         = 10
    label.TextColor3       = COLORS.TextWhite
    label.Size             = UDim2.new(0, 90, 0, 12)
    label.BackgroundTransparency = 1
    label.TextXAlignment   = Enum.TextXAlignment.Left
    label.ZIndex           = 5
    label.Parent           = frame

    local valDisplay = Instance.new("TextLabel")
    valDisplay.Text            = tostring(default)
    valDisplay.Font            = Enum.Font.Gotham
    valDisplay.TextSize        = 9
    valDisplay.TextColor3      = COLORS.TextGray
    valDisplay.Size            = UDim2.new(0, 30, 0, 12)
    valDisplay.Position        = UDim2.new(1, -30, 0, 0)
    valDisplay.BackgroundTransparency = 1
    valDisplay.TextXAlignment  = Enum.TextXAlignment.Right
    valDisplay.ZIndex          = 5
    valDisplay.Parent          = frame

    local sliderBG = Instance.new("TextButton")
    sliderBG.Size             = UDim2.new(1, 0, 0, 3)
    sliderBG.Position         = UDim2.new(0, 0, 0, 18)
    sliderBG.BackgroundColor3 = COLORS.ToggleOff
    sliderBG.Text             = ""
    sliderBG.BorderSizePixel  = 0
    sliderBG.ZIndex           = 5
    sliderBG.Parent           = frame

    local fill = Instance.new("Frame")
    fill.Size             = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = currentThemeColor
    fill.BorderSizePixel  = 0
    fill.ZIndex           = 6
    fill.Parent           = sliderBG
    table.insert(themeFrames, fill)

    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 8, 0, 8)
    knob.Position         = UDim2.new(1, -4, 0.5, -4)
    knob.BackgroundColor3 = COLORS.TextWhite
    knob.ZIndex           = 7
    knob.Parent           = fill
    local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1, 0); kc.Parent = knob

    local dragging = false
    local function updateSlider(input)
        local pct = math.clamp((input.Position.X - sliderBG.AbsolutePosition.X) / sliderBG.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        local val = math.round(min + pct * (max - min))
        valDisplay.Text = tostring(val)
        if callback then callback(val) end
    end
    sliderBG.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; updateSlider(i)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(i)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- addDropdownElement — Sacred exact
local function addDropdownElement(parent, labelText, optionText, yPos)
    local frame = Instance.new("Frame")
    frame.Size             = UDim2.new(1, -16, 0, 22)
    frame.Position         = UDim2.new(0, 8, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.ZIndex           = 5
    frame.Parent           = parent

    local label = Instance.new("TextLabel")
    label.Text             = labelText
    label.Font             = Enum.Font.Gotham
    label.TextSize         = 10
    label.TextColor3       = COLORS.TextWhite
    label.Size             = UDim2.new(0, 60, 1, 0)
    label.BackgroundTransparency = 1
    label.TextXAlignment   = Enum.TextXAlignment.Left
    label.ZIndex           = 5
    label.Parent           = frame

    local menuBtn = Instance.new("TextButton")
    menuBtn.Text             = optionText .. "  ▼"
    menuBtn.Font             = Enum.Font.GothamBold
    menuBtn.TextSize         = 10
    menuBtn.TextColor3       = currentThemeColor
    menuBtn.Size             = UDim2.new(0, 90, 1, 0)
    menuBtn.Position         = UDim2.new(1, -90, 0, 0)
    menuBtn.BackgroundTransparency = 1
    menuBtn.TextXAlignment   = Enum.TextXAlignment.Right
    menuBtn.ZIndex           = 5
    menuBtn.Parent           = frame
    table.insert(themeTexts, menuBtn)
    return menuBtn
end

-- ==========================================================
-- EXTENDED HELPERS
-- ==========================================================

-- Scrollable page for each tab
local function makePage()
    local sf = Instance.new("ScrollingFrame")
    sf.Size                = UDim2.new(1, 0, 1, -26)
    sf.Position            = UDim2.new(0, 0, 0, 26)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel     = 0
    sf.ScrollBarThickness  = 3
    sf.ScrollBarImageColor3 = currentThemeColor
    sf.CanvasSize          = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.Visible             = false
    sf.ZIndex              = 4
    sf.Parent              = contentFrame

    local layout = Instance.new("UIListLayout")
    layout.Padding   = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent    = sf

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft   = UDim.new(0, 4)
    pad.PaddingRight  = UDim.new(0, 6)
    pad.PaddingTop    = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 6)
    pad.Parent        = sf

    return sf
end

-- Section card in a page (rebranded createModuleCard for list pages)
local function makeCard(page, title, height)
    local card = Instance.new("Frame")
    card.Size             = UDim2.new(1, 0, 0, height)
    card.BackgroundColor3 = COLORS.CardBG
    card.BorderSizePixel  = 0
    card.ZIndex           = 5
    card.Parent           = page

    local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 6); cc.Parent = card
    local cs = Instance.new("UIStroke"); cs.Thickness = 1; cs.Color = currentThemeColor; cs.Transparency = 0.25; cs.Parent = card
    table.insert(themeStrokes, cs)

    local sl = Instance.new("Frame")
    sl.Size             = UDim2.new(0, 2, 0, 11)
    sl.Position         = UDim2.new(0, 8, 0, 8)
    sl.BackgroundColor3 = currentThemeColor
    sl.BorderSizePixel  = 0
    sl.ZIndex           = 6
    sl.Parent           = card
    table.insert(themeFrames, sl)

    if title ~= "" then
        local lbl = Instance.new("TextLabel")
        lbl.Text             = title
        lbl.Font             = Enum.Font.GothamBold
        lbl.TextSize         = 10
        lbl.TextColor3       = COLORS.TextWhite
        lbl.Size             = UDim2.new(1, -20, 0, 22)
        lbl.Position         = UDim2.new(0, 15, 0, 2)
        lbl.BackgroundTransparency = 1
        lbl.TextXAlignment   = Enum.TextXAlignment.Left
        lbl.ZIndex           = 6
        lbl.Parent           = card
    end

    return card
end

-- Toggle row inside a card (list-based)
local function makeToggleRow(card, labelText, yPos, callback)
    return addToggleElement(card, labelText, false, yPos, callback)
end

-- Stat row (label + value)
local function makeStatRow(card, labelText, yPos)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1, -16, 0, 20)
    f.Position         = UDim2.new(0, 8, 0, yPos)
    f.BackgroundTransparency = 1
    f.ZIndex           = 6
    f.Parent           = card

    local lbl = Instance.new("TextLabel")
    lbl.Text             = labelText
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = 10
    lbl.TextColor3       = COLORS.TextGray
    lbl.Size             = UDim2.new(0.55, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.ZIndex           = 6
    lbl.Parent           = f

    local val = Instance.new("TextLabel")
    val.Text             = "—"
    val.Font             = Enum.Font.GothamBold
    val.TextSize         = 10
    val.TextColor3       = COLORS.TextWhite
    val.Size             = UDim2.new(0.45, -4, 1, 0)
    val.Position         = UDim2.new(0.55, 0, 0, 0)
    val.BackgroundTransparency = 1
    val.TextXAlignment   = Enum.TextXAlignment.Right
    val.ZIndex           = 6
    val.Parent           = f

    return val
end

-- Action button
local function makeActionBtn(card, text, yPos, w, callback)
    w = w or 110
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, w, 0, 20)
    btn.Position         = UDim2.new(0, 8, 0, yPos)
    btn.BackgroundColor3 = COLORS.PanelBG
    btn.Text             = text
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 9
    btn.TextColor3       = currentThemeColor
    btn.ZIndex           = 6
    btn.Parent           = card
    btn.AutoButtonColor  = false
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 5); bc.Parent = btn
    local bs = Instance.new("UIStroke"); bs.Thickness = 1; bs.Color = currentThemeColor; bs.Transparency = 0.4; bs.Parent = btn
    table.insert(themeStrokes, bs)
    table.insert(themeTexts, btn)
    if callback then btn.MouseButton1Click:Connect(callback) end
    return btn
end

-- ==========================================================
-- TAB SYSTEM
-- ==========================================================
local pages    = {}
local navBtns  = {}
local activeTab = nil

local TABS = {
    { name="Home",         icon="🏠" },
    { name="Auto Farm",    icon="🌾" },
    { name="Sea Events",   icon="🌊" },
    { name="Items",        icon="⚔️" },
    { name="Devil Fruits", icon="🍎" },
    { name="ESP",          icon="👁️" },
    { name="Teleports",    icon="🚀" },
    { name="Server",       icon="🔄" },
    { name="Protection",   icon="🛡️" },
    { name="Combat",       icon="💥" },
    { name="Race",         icon="⚡" },
    { name="Chests",       icon="📦" },
    { name="Statistics",   icon="📊" },
    { name="Notifs",       icon="🔔" },
    { name="Settings",     icon="⚙️" },
}

local function switchTab(name)
    for tName, page in pairs(pages) do page.Visible = false end
    for tName, btn  in pairs(navBtns) do
        btn.TextColor3            = COLORS.TextGray
        btn.BackgroundTransparency = 1
    end
    if pages[name]   then pages[name].Visible = true end
    if navBtns[name] then
        navBtns[name].TextColor3            = currentThemeColor
        navBtns[name].BackgroundTransparency = 0.85
        table.insert(themeTexts, navBtns[name])
    end
    activeTab = name
end

-- Build nav buttons
for i, tab in ipairs(TABS) do
    local btn = Instance.new("TextButton")
    btn.Text             = tab.icon .. " " .. tab.name
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 10
    btn.TextColor3       = COLORS.TextGray
    btn.Size             = UDim2.new(1, 0, 0, 22)
    btn.BackgroundColor3 = currentThemeColor
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel  = 0
    btn.TextXAlignment   = Enum.TextXAlignment.Left
    btn.ZIndex           = 6
    btn.LayoutOrder      = i
    btn.Parent           = navScroll
    btn.AutoButtonColor  = false

    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 5); bc.Parent = btn
    local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 8); pad.Parent = btn

    navBtns[tab.name] = btn

    -- Make page
    local page = makePage()
    pages[tab.name] = page

    btn.MouseButton1Click:Connect(function() switchTab(tab.name) end)
end

-- Page header label
local function makePageHeader(page, text)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1, 0, 0, 22)
    f.BackgroundColor3 = COLORS.PanelBG
    f.BorderSizePixel  = 0
    f.ZIndex           = 5
    f.Parent           = page

    local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(0, 5); fc.Parent = f
    local fs = Instance.new("UIStroke"); fs.Thickness=1; fs.Color=currentThemeColor; fs.Transparency=0.5; fs.Parent=f
    table.insert(themeStrokes, fs)

    local lbl = Instance.new("TextLabel")
    lbl.Text             = text
    lbl.Font             = Enum.Font.GothamBlack
    lbl.TextSize         = 11
    lbl.TextColor3       = currentThemeColor
    lbl.Size             = UDim2.new(1, -10, 1, 0)
    lbl.Position         = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.ZIndex           = 6
    lbl.Parent           = f
    table.insert(themeTexts, lbl)
    return f
end

-- ==========================================================
-- ── HOME PAGE ──
-- ==========================================================
local homePage = pages["Home"]
makePageHeader(homePage, "⚔ Nemesis X  —  Dashboard")

-- Logo card
local logoCard = makeCard(homePage, "", 58)
local logoLbl = Instance.new("TextLabel")
logoLbl.Text             = "⚔ NEMESIS X"
logoLbl.Font             = Enum.Font.GothamBlack
logoLbl.TextSize         = 18
logoLbl.TextColor3       = currentThemeColor
logoLbl.Size             = UDim2.new(1, 0, 0, 26)
logoLbl.Position         = UDim2.new(0, 0, 0, 6)
logoLbl.BackgroundTransparency = 1
logoLbl.TextXAlignment   = Enum.TextXAlignment.Center
logoLbl.ZIndex           = 6
logoLbl.Parent           = logoCard
table.insert(themeTexts, logoLbl)

local premLbl = Instance.new("TextLabel")
premLbl.Text             = "PREMIUM EDITION  •  v1.0  •  Undetected ✔"
premLbl.Font             = Enum.Font.Gotham
premLbl.TextSize         = 8
premLbl.TextColor3       = COLORS.TextGray
premLbl.Size             = UDim2.new(1, 0, 0, 12)
premLbl.Position         = UDim2.new(0, 0, 0, 34)
premLbl.BackgroundTransparency = 1
premLbl.TextXAlignment   = Enum.TextXAlignment.Center
premLbl.ZIndex           = 6
premLbl.Parent           = logoCard

local statusDot = Instance.new("Frame")
statusDot.Size             = UDim2.new(0, 6, 0, 6)
statusDot.Position         = UDim2.new(0, 8, 0, 46)
statusDot.BackgroundColor3 = COLORS.Green
statusDot.BorderSizePixel  = 0
statusDot.ZIndex           = 6
statusDot.Parent           = logoCard
Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)

local statusLbl = Instance.new("TextLabel")
statusLbl.Text             = "Status: Undetected"
statusLbl.Font             = Enum.Font.GothamBold
statusLbl.TextSize         = 9
statusLbl.TextColor3       = COLORS.Green
statusLbl.Size             = UDim2.new(0, 120, 0, 12)
statusLbl.Position         = UDim2.new(0, 18, 0, 44)
statusLbl.BackgroundTransparency = 1
statusLbl.TextXAlignment   = Enum.TextXAlignment.Left
statusLbl.ZIndex           = 6
statusLbl.Parent           = logoCard

-- Info card
local infoCard = makeCard(homePage, "User Info", 80)
local runtimeVal  = makeStatRow(infoCard, "Runtime",         26)
local userVal     = makeStatRow(infoCard, "User",            44)
local executorVal = makeStatRow(infoCard, "Executor",        60)

pcall(function() userVal.Text = player.Name end)
pcall(function()
    if identifyexecutor then executorVal.Text = identifyexecutor()
    elseif getexecutorname then executorVal.Text = getexecutorname()
    else executorVal.Text = "Unknown" end
end)

-- Counter card
local counterCard = makeCard(homePage, "Session", 62)
local activeFeatsVal = makeStatRow(counterCard, "Active Features", 26)
local totalFeatsVal  = makeStatRow(counterCard, "Total Features",  44)
totalFeatsVal.Text   = "70+"

-- Action buttons card
local actionsCard = makeCard(homePage, "Quick Actions", 50)
makeActionBtn(actionsCard, "💬 Discord", 26, 90, function()
    pcall(function() setclipboard("https://discord.gg/8rz6u37Pac") end)
end)
makeActionBtn(actionsCard, "📋 Copy Key", 26, 90, function()
    pcall(function()
        local key = getgenv and getgenv().NX_Key or "—"
        setclipboard(tostring(key))
    end)
end):Position = UDim2.new(0, 104, 0, 26)

-- Notification panel
local notifCard = makeCard(homePage, "🔔 Notifications", 50)
local notifLbl = Instance.new("TextLabel")
notifLbl.Text             = "✔ Nemesis X loaded successfully!"
notifLbl.Font             = Enum.Font.Gotham
notifLbl.TextSize         = 9
notifLbl.TextColor3       = COLORS.Green
notifLbl.Size             = UDim2.new(1, -16, 0, 14)
notifLbl.Position         = UDim2.new(0, 8, 0, 26)
notifLbl.BackgroundTransparency = 1
notifLbl.TextXAlignment   = Enum.TextXAlignment.Left
notifLbl.ZIndex           = 6
notifLbl.Parent           = notifCard

local notifLbl2 = Instance.new("TextLabel")
notifLbl2.Text             = "ℹ All features are UI-only in this build."
notifLbl2.Font             = Enum.Font.Gotham
notifLbl2.TextSize         = 9
notifLbl2.TextColor3       = COLORS.TextGray
notifLbl2.Size             = UDim2.new(1, -16, 0, 14)
notifLbl2.Position         = UDim2.new(0, 8, 0, 40)  -- note: overlaps, card only 50h — resize at will
notifLbl2.BackgroundTransparency = 1
notifLbl2.TextXAlignment   = Enum.TextXAlignment.Left
notifLbl2.ZIndex           = 6
notifLbl2.Parent           = notifCard

-- Update runtime
task.spawn(function()
    local start = tick()
    while true do
        task.wait(1)
        local e = math.floor(tick() - start)
        runtimeVal.Text = string.format("%02d:%02d:%02d", math.floor(e/3600), math.floor(e/60)%60, e%60)
    end
end)

-- ==========================================================
-- ── AUTO FARM PAGE ──
-- ==========================================================
local farmPage = pages["Auto Farm"]
makePageHeader(farmPage, "🌾 Auto Farm Pro")

local farmCard = makeCard(farmPage, "Farm Core", 26*13+28)
addToggleElement(farmCard, "Auto Farm",         false, 26)
addToggleElement(farmCard, "Auto Quest",         false, 50)
addToggleElement(farmCard, "Auto Level",         false, 74)
addToggleElement(farmCard, "Fast Attack",        false, 98)
addToggleElement(farmCard, "Bring Mobs",         false, 122)
addToggleElement(farmCard, "Auto Haki",          false, 146)
addToggleElement(farmCard, "Auto Stats",         false, 170)
addToggleElement(farmCard, "Auto Equip Weapon",  false, 194)
addToggleElement(farmCard, "Auto Equip Fruit",   false, 218)
addToggleElement(farmCard, "Smart Farm AI",      false, 242)
addToggleElement(farmCard, "Auto Elite Hunter",  false, 266)
addToggleElement(farmCard, "Auto Boss Farm",     false, 290)
addToggleElement(farmCard, "Auto Mastery Farm",  false, 314)

local farmSettingsCard = makeCard(farmPage, "Farm Settings", 62)
addSliderElement(farmSettingsCard, "Farm Range",   10, 200, 50, 26)
addDropdownElement(farmSettingsCard, "Sea",    "Auto",  26)

-- ==========================================================
-- ── SEA EVENTS PAGE ──
-- ==========================================================
local seaPage = pages["Sea Events"]
makePageHeader(seaPage, "🌊 Sea Events")

local levCard = makeCard(seaPage, "Leviathan", 26*7+28)
addToggleElement(levCard, "Auto Leviathan",         false, 26)
addToggleElement(levCard, "Auto Leviathan ESP",     false, 50)
addToggleElement(levCard, "Auto Leviathan Hop",     false, 74)
addToggleElement(levCard, "Auto Leviathan Rewards", false, 98)
addToggleElement(levCard, "Full Moon Tracker",      false, 122)
addToggleElement(levCard, "Auto Frozen Dimension",  false, 146)
addToggleElement(levCard, "Auto Boat",              false, 170)

local seaEvCard = makeCard(seaPage, "Sea Events", 26*9+28)
addToggleElement(seaEvCard, "Auto Heart",             false, 26)
addToggleElement(seaEvCard, "Auto Sea Beast",         false, 50)
addToggleElement(seaEvCard, "Auto Terror Shark",      false, 74)
addToggleElement(seaEvCard, "Auto Ship Raid",         false, 98)
addToggleElement(seaEvCard, "Auto Haunted Ship",      false, 122)
addToggleElement(seaEvCard, "Auto Mirage Island",     false, 146)
addToggleElement(seaEvCard, "Auto Sea Event ESP",     false, 170)
addToggleElement(seaEvCard, "Auto Sea Event Teleport",false, 194)
addToggleElement(seaEvCard, "Auto Sea Event Rewards", false, 218)

-- ==========================================================
-- ── ITEMS & WEAPONS PAGE ──
-- ==========================================================
local itemsPage = pages["Items"]
makePageHeader(itemsPage, "⚔️ Items & Weapons")

local weapCard = makeCard(itemsPage, "Legendary Items", 26*9+28)
addToggleElement(weapCard, "Auto Legendary Sword", false, 26)
addToggleElement(weapCard, "Auto CDK",             false, 50)
addToggleElement(weapCard, "Auto TTK",             false, 74)
addToggleElement(weapCard, "Auto Soul Guitar",     false, 98)
addToggleElement(weapCard, "Auto Yama",            false, 122)
addToggleElement(weapCard, "Auto Tushita",         false, 146)
addToggleElement(weapCard, "Auto Shark Anchor",    false, 170)
addToggleElement(weapCard, "Auto Dark Blade Puzzle",false, 194)
addToggleElement(weapCard, "Auto Hallow Scythe",   false, 218)

-- ==========================================================
-- ── DEVIL FRUITS PAGE ──
-- ==========================================================
local fruitPage = pages["Devil Fruits"]
makePageHeader(fruitPage, "🍎 Devil Fruits")

local fruitCard = makeCard(fruitPage, "Fruit System", 26*7+28)
addToggleElement(fruitCard, "Fruit ESP",       false, 26)
addToggleElement(fruitCard, "Fruit Sniper",    false, 50)
addToggleElement(fruitCard, "Auto Buy Fruit",  false, 74)
addToggleElement(fruitCard, "Auto Store Fruit",false, 98)
addToggleElement(fruitCard, "Auto Eat Fruit",  false, 122)
addToggleElement(fruitCard, "Fruit Notifier",  false, 146)
addToggleElement(fruitCard, "Fruit Teleport",  false, 170)

-- ==========================================================
-- ── ESP PAGE ──
-- ==========================================================
local espPage = pages["ESP"]
makePageHeader(espPage, "👁️ ESP")

local espCard = makeCard(espPage, "ESP Options", 26*7+28)
addToggleElement(espCard, "Player ESP",    false, 26)
addToggleElement(espCard, "Boss ESP",      false, 50)
addToggleElement(espCard, "Fruit ESP",     false, 74)
addToggleElement(espCard, "Chest ESP",     false, 98)
addToggleElement(espCard, "Leviathan ESP", false, 122)
addToggleElement(espCard, "Island ESP",    false, 146)
addToggleElement(espCard, "NPC ESP",       false, 170)

local espSettCard = makeCard(espPage, "ESP Settings", 62)
addSliderElement(espSettCard, "Range",     50, 5000, 1000, 26)
addDropdownElement(espSettCard, "Style", "Box", 26)

-- ==========================================================
-- ── TELEPORTS PAGE ──
-- ==========================================================
local tpPage = pages["Teleports"]
makePageHeader(tpPage, "🚀 Teleports")

local tpCard = makeCard(tpPage, "Teleport Options", 26*5+28)
addToggleElement(tpCard, "Island Teleport", false, 26)
addToggleElement(tpCard, "NPC Teleport",    false, 50)
addToggleElement(tpCard, "Boss Teleport",   false, 74)
addToggleElement(tpCard, "Join Job ID",     false, 98)
addToggleElement(tpCard, "Copy Job ID",     false, 122)

local tpDropCard = makeCard(tpPage, "Select Island", 50)
addDropdownElement(tpDropCard, "Sea",    "Third Sea",    26)
addDropdownElement(tpDropCard, "Island", "Port Town",    26)

-- ==========================================================
-- ── SERVER PAGE ──
-- ==========================================================
local serverPage = pages["Server"]
makePageHeader(serverPage, "🔄 Server")

local serverCard = makeCard(serverPage, "Server Options", 26*5+28)
addToggleElement(serverCard, "Server Hop",      false, 26)
addToggleElement(serverCard, "Auto Rejoin",     false, 50)
addToggleElement(serverCard, "Hop Full Moon",   false, 74)
addToggleElement(serverCard, "Hop Leviathan",   false, 98)
addToggleElement(serverCard, "Hop Low Players", false, 122)

local serverSettCard = makeCard(serverPage, "Hop Settings", 50)
addSliderElement(serverSettCard, "Min Players",  1, 12, 6, 26)

-- ==========================================================
-- ── PROTECTION PAGE ──
-- ==========================================================
local protPage = pages["Protection"]
makePageHeader(protPage, "🛡️ Protection")

local protCard = makeCard(protPage, "Protection Options", 26*5+28)
addToggleElement(protCard, "Anti AFK",        false, 26)
addToggleElement(protCard, "Anti Void",       false, 50)
addToggleElement(protCard, "Anti Stuck",      false, 74)
addToggleElement(protCard, "Auto Reconnect",  false, 98)
addToggleElement(protCard, "FPS Boost",       false, 122)

-- ==========================================================
-- ── COMBAT PAGE ──
-- ==========================================================
local combatPage = pages["Combat"]
makePageHeader(combatPage, "💥 Combat")

local combatCard = makeCard(combatPage, "Combat Options", 26*5+28)
addToggleElement(combatCard, "Combat Aura",  false, 26)
addToggleElement(combatCard, "Auto Skill",   false, 50)
addToggleElement(combatCard, "Auto Weapon",  false, 74)
addToggleElement(combatCard, "Auto Dodge",   false, 98)
addToggleElement(combatCard, "Kill Aura",    false, 122)

local combatSettCard = makeCard(combatPage, "Combat Settings", 50)
addSliderElement(combatSettCard, "Aura Range", 5, 100, 20, 26)

-- ==========================================================
-- ── RACE PAGE ──
-- ==========================================================
local racePage = pages["Race"]
makePageHeader(racePage, "⚡ Race")

local raceCard = makeCard(racePage, "Race Upgrades", 26*4+28)
addToggleElement(raceCard, "Auto Race V2",    false, 26)
addToggleElement(raceCard, "Auto Race V3",    false, 50)
addToggleElement(raceCard, "Auto Race V4",    false, 74)
addToggleElement(raceCard, "Auto Blue Gear",  false, 98)

-- ==========================================================
-- ── CHESTS PAGE ──
-- ==========================================================
local chestsPage = pages["Chests"]
makePageHeader(chestsPage, "📦 Chests")

local chestCard = makeCard(chestsPage, "Chest Options", 26*4+28)
addToggleElement(chestCard, "Auto Chest",        false, 26)
addToggleElement(chestCard, "Auto Elite Chest",  false, 50)
addToggleElement(chestCard, "Auto Mirage Chest", false, 74)
addToggleElement(chestCard, "Chest ESP",         false, 98)

-- ==========================================================
-- ── STATISTICS PAGE ──
-- ==========================================================
local statsPage = pages["Statistics"]
makePageHeader(statsPage, "📊 Statistics")

local statsCard = makeCard(statsPage, "Session Stats", 26*6+28)
local rtVal     = makeStatRow(statsCard, "Runtime",           26)
local afVal     = makeStatRow(statsCard, "Active Features",   44)
local beliVal   = makeStatRow(statsCard, "Beli Earned",       62)
local fragVal   = makeStatRow(statsCard, "Fragments Earned",  80)
local lvlVal    = makeStatRow(statsCard, "Levels Gained",     98)
local chestVal  = makeStatRow(statsCard, "Chests Collected",  116)

-- initialize
beliVal.Text  = "0"
fragVal.Text  = "0"
lvlVal.Text   = "0"
chestVal.Text = "0"
afVal.Text    = "0"

-- Runtime mirror
task.spawn(function()
    local start = tick()
    while true do
        task.wait(1)
        local e = math.floor(tick() - start)
        rtVal.Text = string.format("%02d:%02d:%02d", math.floor(e/3600), math.floor(e/60)%60, e%60)
    end
end)

-- ==========================================================
-- ── NOTIFICATIONS PAGE ──
-- ==========================================================
local notifPage = pages["Notifs"]
makePageHeader(notifPage, "🔔 Notifications")

local notifCard2 = makeCard(notifPage, "Alert Settings", 26*5+28)
addToggleElement(notifCard2, "Voice Notifications", false, 26)
addToggleElement(notifCard2, "Fruit Alert",         false, 50)
addToggleElement(notifCard2, "Boss Alert",          false, 74)
addToggleElement(notifCard2, "Leviathan Alert",     false, 98)
addToggleElement(notifCard2, "Full Moon Alert",     false, 122)

-- ==========================================================
-- ── SETTINGS PAGE ──
-- ==========================================================
local settPage = pages["Settings"]
makePageHeader(settPage, "⚙️ Settings")

local settCard = makeCard(settPage, "General", 26*4+28)
addDropdownElement(settCard, "Theme",   "Morado Neon", 26)
addToggleElement(settCard, "RGB Theme",         false, 50)
addToggleElement(settCard, "Mobile Mode",        false, 74)
addToggleElement(settCard, "Performance Mode",   false, 98)

local saveCard = makeCard(settPage, "Config", 50)
makeActionBtn(saveCard, "💾 Save Config", 26, 100)
makeActionBtn(saveCard, "📂 Load Config", 26, 100):Position = UDim2.new(0, 108, 0, 26)

local perfCard = makeCard(settPage, "Display", 50)
addToggleElement(perfCard, "Auto Save", false, 26)
addSliderElement(perfCard, "UI Scale", 50, 150, 100, 0)

-- ==========================================================
-- ACTIVATE HOME TAB
-- ==========================================================
switchTab("Home")

print("[Nemesis X Premium] UI Loaded | 70+ Features | by CursedExility")
ENDOFSCRIPT
echo "Done! Lines: $(wc -l < /mnt/user-data/outputs/NemesisX_Premium_UI.lua)"
