--[[
    SHADE DUELS - CYBERPUNK UI v2
    Dark navy/cyan theme with direct input fields
    No more +/- button spam - just type your speed!
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================
-- CONFIG
-- ============================================================
local UI_CONFIG = {
    MAIN_COLOR = Color3.fromRGB(15, 30, 50),      -- Dark navy
    ACCENT_COLOR = Color3.fromRGB(0, 200, 255),  -- Cyan
    SECONDARY_COLOR = Color3.fromRGB(30, 50, 80), -- Lighter navy
    TEXT_COLOR = Color3.fromRGB(220, 220, 220),  -- Light gray
    ACCENT_TEXT = Color3.fromRGB(0, 200, 255),   -- Cyan text
    SUCCESS_COLOR = Color3.fromRGB(0, 255, 100),  -- Green
    DANGER_COLOR = Color3.fromRGB(255, 50, 50),   -- Red
}

-- ============================================================
-- MAIN UI CREATION
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShadeDuelsUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndex = 100
screenGui.Parent = playerGui

-- Main window frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainWindow"
mainFrame.Size = UDim2.new(0, 450, 0, 600)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -300)
mainFrame.BackgroundColor3 = UI_CONFIG.MAIN_COLOR
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = UI_CONFIG.ACCENT_COLOR
mainFrame.Parent = screenGui

-- Dragging
local dragging, dragStart, dragPos
mainFrame.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        dragPos = mainFrame.Position
    end
end)

mainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(dragPos.X.Scale, dragPos.X.Offset + delta.X, dragPos.Y.Scale, dragPos.Y.Offset + delta.Y)
    end
end)

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleText = Instance.new("TextLabel")
titleText.Name = "TitleText"
titleText.Size = UDim2.new(1, -50, 1, 0)
titleText.BackgroundTransparency = 1
titleText.TextColor3 = UI_CONFIG.ACCENT_TEXT
titleText.TextSize = 20
titleText.Font = Enum.Font.GothamBold
titleText.Text = "SHADE DUELS"
titleText.Parent = titleBar

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 40, 1, 0)
closeButton.Position = UDim2.new(1, -40, 0, 0)
closeButton.BackgroundColor3 = UI_CONFIG.DANGER_COLOR
closeButton.BorderSizePixel = 0
closeButton.TextColor3 = UI_CONFIG.TEXT_COLOR
closeButton.TextSize = 18
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "✕"
closeButton.Parent = titleBar
closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Tab buttons container
local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Size = UDim2.new(1, 0, 0, 45)
tabContainer.Position = UDim2.new(0, 0, 0, 50)
tabContainer.BackgroundColor3 = UI_CONFIG.MAIN_COLOR
tabContainer.BorderSizePixel = 1
tabContainer.BorderColor3 = UI_CONFIG.ACCENT_COLOR
tabContainer.Parent = mainFrame

local tabScroll = Instance.new("ScrollingFrame")
tabScroll.Name = "TabScroll"
tabScroll.Size = UDim2.new(1, 0, 1, 0)
tabScroll.BackgroundTransparency = 1
tabScroll.BorderSizePixel = 0
tabScroll.ScrollBarThickness = 0
tabScroll.CanvasSize = UDim2.new(5, 0, 0, 45)
tabScroll.Parent = tabContainer

local TAB_NAMES = {"SPEED", "COMBAT", "AUTO", "STEAL MODE", "VISUAL", "KEYBIND", "SETTINGS"}
local tabs = {}
local contentFrames = {}

for i, tabName in ipairs(TAB_NAMES) do
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = tabName .. "Tab"
    tabBtn.Size = UDim2.new(0, 90, 1, 0)
    tabBtn.Position = UDim2.new(0, (i-1) * 95, 0, 0)
    tabBtn.BackgroundColor3 = (i == 1) and UI_CONFIG.ACCENT_COLOR or UI_CONFIG.SECONDARY_COLOR
    tabBtn.TextColor3 = (i == 1) and UI_CONFIG.MAIN_COLOR or UI_CONFIG.TEXT_COLOR
    tabBtn.BorderSizePixel = 0
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.TextSize = 11
    tabBtn.Text = tabName
    tabBtn.Parent = tabScroll
    tabs[tabName] = tabBtn

    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = tabName .. "Content"
    contentFrame.Size = UDim2.new(1, 0, 1, -95)
    contentFrame.Position = UDim2.new(0, 0, 0, 95)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 6
    contentFrame.ScrollBarImageColor3 = UI_CONFIG.ACCENT_COLOR
    contentFrame.Visible = (i == 1)
    contentFrame.Parent = mainFrame
    contentFrames[tabName] = contentFrame

    tabBtn.MouseButton1Click:Connect(function()
        for _, btn in pairs(tabs) do
            btn.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
            btn.TextColor3 = UI_CONFIG.TEXT_COLOR
        end
        tabBtn.BackgroundColor3 = UI_CONFIG.ACCENT_COLOR
        tabBtn.TextColor3 = UI_CONFIG.MAIN_COLOR

        for _, frame in pairs(contentFrames) do
            frame.Visible = false
        end
        contentFrame.Visible = true
    end)
end

-- ============================================================
-- SPEED TAB CONTENT
-- ============================================================
local function createSpeedInput(parent, label, defaultValue, yPos)
    local container = Instance.new("Frame")
    container.Name = label .. "Container"
    container.Size = UDim2.new(1, -20, 0, 50)
    container.Position = UDim2.new(0, 10, 0, yPos)
    container.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
    container.BorderSizePixel = 1
    container.BorderColor3 = UI_CONFIG.ACCENT_COLOR
    container.Parent = parent

    local labelText = Instance.new("TextLabel")
    labelText.Name = "Label"
    labelText.Size = UDim2.new(0, 150, 0, 25)
    labelText.Position = UDim2.new(0, 10, 0, 5)
    labelText.BackgroundTransparency = 1
    labelText.TextColor3 = UI_CONFIG.TEXT_COLOR
    labelText.TextSize = 14
    labelText.Font = Enum.Font.Gotham
    labelText.Text = label
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Parent = container

    local inputBox = Instance.new("TextBox")
    inputBox.Name = "InputBox"
    inputBox.Size = UDim2.new(0, 100, 0, 30)
    inputBox.Position = UDim2.new(1, -120, 0, 8)
    inputBox.BackgroundColor3 = UI_CONFIG.MAIN_COLOR
    inputBox.BorderSizePixel = 1
    inputBox.BorderColor3 = UI_CONFIG.ACCENT_COLOR
    inputBox.TextColor3 = UI_CONFIG.ACCENT_TEXT
    inputBox.TextSize = 16
    inputBox.Font = Enum.Font.GothamBold
    inputBox.Text = tostring(defaultValue)
    inputBox.Parent = container

    inputBox.FocusLost:Connect(function()
        local val = tonumber(inputBox.Text) or defaultValue
        inputBox.Text = tostring(val)
        -- Here you would apply the speed value to your game
        print("Speed changed: " .. label .. " = " .. val)
    end)

    return inputBox
end

local speedContent = contentFrames["SPEED"]
speedContent.CanvasSize = UDim2.new(0, 0, 0, 300)

createSpeedInput(speedContent, "Normal Speed", 62, 10)
createSpeedInput(speedContent, "Carry Speed", 33, 70)
createSpeedInput(speedContent, "Lagger Speed", 15, 130)
createSpeedInput(speedContent, "Lagger Carry Speed", 24.5, 190)

-- Speed mode toggle
local speedModeContainer = Instance.new("Frame")
speedModeContainer.Name = "SpeedModeContainer"
speedModeContainer.Size = UDim2.new(1, -20, 0, 50)
speedModeContainer.Position = UDim2.new(0, 10, 0, 250)
speedModeContainer.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
speedModeContainer.BorderSizePixel = 1
speedModeContainer.BorderColor3 = UI_CONFIG.ACCENT_COLOR
speedModeContainer.Parent = speedContent

local speedModeLabel = Instance.new("TextLabel")
speedModeLabel.Name = "Label"
speedModeLabel.Size = UDim2.new(0, 150, 0, 25)
speedModeLabel.Position = UDim2.new(0, 10, 0, 5)
speedModeLabel.BackgroundTransparency = 1
speedModeLabel.TextColor3 = UI_CONFIG.TEXT_COLOR
speedModeLabel.TextSize = 14
speedModeLabel.Font = Enum.Font.Gotham
speedModeLabel.Text = "Carry Mode"
speedModeLabel.TextXAlignment = Enum.TextXAlignment.Left
speedModeLabel.Parent = speedModeContainer

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleBtn"
toggleBtn.Size = UDim2.new(0, 50, 0, 30)
toggleBtn.Position = UDim2.new(1, -70, 0, 8)
toggleBtn.BackgroundColor3 = UI_CONFIG.ACCENT_COLOR
toggleBtn.BorderSizePixel = 0
toggleBtn.TextColor3 = UI_CONFIG.MAIN_COLOR
toggleBtn.TextSize = 12
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Text = "ON"
toggleBtn.Parent = speedModeContainer

local isEnabled = true
toggleBtn.MouseButton1Click:Connect(function()
    isEnabled = not isEnabled
    toggleBtn.Text = isEnabled and "ON" or "OFF"
    toggleBtn.BackgroundColor3 = isEnabled and UI_CONFIG.SUCCESS_COLOR or UI_CONFIG.DANGER_COLOR
    print("Carry Mode: " .. (isEnabled and "ENABLED" or "DISABLED"))
end)

-- ============================================================
-- COMBAT TAB CONTENT
-- ============================================================
local combatContent = contentFrames["COMBAT"]
combatContent.CanvasSize = UDim2.new(0, 0, 0, 200)

local combatLabel = Instance.new("TextLabel")
combatLabel.Size = UDim2.new(1, -20, 0, 30)
combatLabel.Position = UDim2.new(0, 10, 0, 10)
combatLabel.BackgroundTransparency = 1
combatLabel.TextColor3 = UI_CONFIG.ACCENT_TEXT
combatLabel.TextSize = 16
combatLabel.Font = Enum.Font.GothamBold
combatLabel.Text = "COMBAT FEATURES"
combatLabel.TextXAlignment = Enum.TextXAlignment.Left
combatLabel.Parent = combatContent

-- Add combat options here
local combatOptions = {"Auto Attack", "Aim Assist", "Damage Boost", "Invincibility"}
for i, option in ipairs(combatOptions) do
    local btn = Instance.new("TextButton")
    btn.Name = option .. "Btn"
    btn.Size = UDim2.new(1, -20, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, 40 + (i-1) * 40)
    btn.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
    btn.BorderSizePixel = 1
    btn.BorderColor3 = UI_CONFIG.ACCENT_COLOR
    btn.TextColor3 = UI_CONFIG.TEXT_COLOR
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.Text = option
    btn.Parent = combatContent
    
    btn.MouseButton1Click:Connect(function()
        btn.BackgroundColor3 = UI_CONFIG.ACCENT_COLOR
        btn.TextColor3 = UI_CONFIG.MAIN_COLOR
        print(option .. " toggled!")
        task.wait(0.2)
        btn.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
        btn.TextColor3 = UI_CONFIG.TEXT_COLOR
    end)
end

-- ============================================================
-- AUTO TAB CONTENT
-- ============================================================
local autoContent = contentFrames["AUTO"]
autoContent.CanvasSize = UDim2.new(0, 0, 0, 200)

local autoLabel = Instance.new("TextLabel")
autoLabel.Size = UDim2.new(1, -20, 0, 30)
autoLabel.Position = UDim2.new(0, 10, 0, 10)
autoLabel.BackgroundTransparency = 1
autoLabel.TextColor3 = UI_CONFIG.ACCENT_TEXT
autoLabel.TextSize = 16
autoLabel.Font = Enum.Font.GothamBold
autoLabel.Text = "AUTO FARM"
autoLabel.TextXAlignment = Enum.TextXAlignment.Left
autoLabel.Parent = autoContent

local autoOptions = {"Auto Farm", "Auto Collect", "Auto Sell", "Auto Upgrade"}
for i, option in ipairs(autoOptions) do
    local btn = Instance.new("TextButton")
    btn.Name = option .. "Btn"
    btn.Size = UDim2.new(1, -20, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, 40 + (i-1) * 40)
    btn.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
    btn.BorderSizePixel = 1
    btn.BorderColor3 = UI_CONFIG.ACCENT_COLOR
    btn.TextColor3 = UI_CONFIG.TEXT_COLOR
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.Text = option
    btn.Parent = autoContent
    
    btn.MouseButton1Click:Connect(function()
        btn.BackgroundColor3 = UI_CONFIG.ACCENT_COLOR
        btn.TextColor3 = UI_CONFIG.MAIN_COLOR
        print(option .. " activated!")
        task.wait(0.2)
        btn.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
        btn.TextColor3 = UI_CONFIG.TEXT_COLOR
    end)
end

-- ============================================================
-- STEAL MODE TAB CONTENT
-- ============================================================
local stealContent = contentFrames["STEAL MODE"]
stealContent.CanvasSize = UDim2.new(0, 0, 0, 200)

local stealLabel = Instance.new("TextLabel")
stealLabel.Size = UDim2.new(1, -20, 0, 30)
stealLabel.Position = UDim2.new(0, 10, 0, 10)
stealLabel.BackgroundTransparency = 1
stealLabel.TextColor3 = UI_CONFIG.ACCENT_TEXT
stealLabel.TextSize = 16
stealLabel.Font = Enum.Font.GothamBold
stealLabel.Text = "STEAL MODES"
stealLabel.TextXAlignment = Enum.TextXAlignment.Left
stealLabel.Parent = stealContent

local stealModes = {"Normal", "Semi", "Smart", "Aggressive"}
for i, mode in ipairs(stealModes) do
    local btn = Instance.new("TextButton")
    btn.Name = mode .. "ModeBtn"
    btn.Size = UDim2.new(1, -20, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, 40 + (i-1) * 40)
    btn.BackgroundColor3 = (i == 1) and UI_CONFIG.ACCENT_COLOR or UI_CONFIG.SECONDARY_COLOR
    btn.BorderSizePixel = 1
    btn.BorderColor3 = UI_CONFIG.ACCENT_COLOR
    btn.TextColor3 = (i == 1) and UI_CONFIG.MAIN_COLOR or UI_CONFIG.TEXT_COLOR
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.Text = mode .. " Mode"
    btn.Parent = stealContent
    
    btn.MouseButton1Click:Connect(function()
        for _, child in pairs(stealContent:GetChildren()) do
            if child:IsA("TextButton") and child.Name ~= "Label" then
                child.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
                child.TextColor3 = UI_CONFIG.TEXT_COLOR
            end
        end
        btn.BackgroundColor3 = UI_CONFIG.ACCENT_COLOR
        btn.TextColor3 = UI_CONFIG.MAIN_COLOR
        print("Steal Mode: " .. mode)
    end)
end

-- ============================================================
-- VISUAL TAB CONTENT
-- ============================================================
local visualContent = contentFrames["VISUAL"]
visualContent.CanvasSize = UDim2.new(0, 0, 0, 600)

local visualLabel = Instance.new("TextLabel")
visualLabel.Size = UDim2.new(1, -20, 0, 30)
visualLabel.Position = UDim2.new(0, 10, 0, 10)
visualLabel.BackgroundTransparency = 1
visualLabel.TextColor3 = UI_CONFIG.ACCENT_TEXT
visualLabel.TextSize = 16
visualLabel.Font = Enum.Font.GothamBold
visualLabel.Text = "SKY THEMES"
visualLabel.TextXAlignment = Enum.TextXAlignment.Left
visualLabel.Parent = visualContent

local skyThemes = {"Night", "Aurora", "Sunset", "Galaxy", "Cyber", "Sakura", "Pink Night", "Blood Moon", "Deep Space", "Heaven"}
for i, theme in ipairs(skyThemes) do
    local btn = Instance.new("TextButton")
    btn.Name = theme .. "ThemeBtn"
    btn.Size = UDim2.new(1, -20, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, 40 + (i-1) * 40)
    btn.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
    btn.BorderSizePixel = 1
    btn.BorderColor3 = UI_CONFIG.ACCENT_COLOR
    btn.TextColor3 = UI_CONFIG.TEXT_COLOR
    btn.TextSize = 12
    btn.Font = Enum.Font.Gotham
    btn.Text = theme
    btn.Parent = visualContent
    
    btn.MouseButton1Click:Connect(function()
        btn.BackgroundColor3 = UI_CONFIG.ACCENT_COLOR
        btn.TextColor3 = UI_CONFIG.MAIN_COLOR
        print("Sky Theme: " .. theme)
        task.wait(0.2)
        btn.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
        btn.TextColor3 = UI_CONFIG.TEXT_COLOR
    end)
end

-- ============================================================
-- KEYBIND TAB CONTENT
-- ============================================================
local keybindContent = contentFrames["KEYBIND"]
keybindContent.CanvasSize = UDim2.new(0, 0, 0, 250)

local keybindLabel = Instance.new("TextLabel")
keybindLabel.Size = UDim2.new(1, -20, 0, 30)
keybindLabel.Position = UDim2.new(0, 10, 0, 10)
keybindLabel.BackgroundTransparency = 1
keybindLabel.TextColor3 = UI_CONFIG.ACCENT_TEXT
keybindLabel.TextSize = 16
keybindLabel.Font = Enum.Font.GothamBold
keybindLabel.Text = "KEYBINDS"
keybindLabel.TextXAlignment = Enum.TextXAlignment.Left
keybindLabel.Parent = keybindContent

local keybinds = {
    {label = "Toggle UI", key = "F"},
    {label = "Speed Boost", key = "E"},
    {label = "Auto Farm", key = "R"},
    {label = "Steal Mode", key = "T"}
}

for i, bind in ipairs(keybinds) do
    local container = Instance.new("Frame")
    container.Name = bind.label .. "Container"
    container.Size = UDim2.new(1, -20, 0, 40)
    container.Position = UDim2.new(0, 10, 0, 40 + (i-1) * 45)
    container.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
    container.BorderSizePixel = 1
    container.BorderColor3 = UI_CONFIG.ACCENT_COLOR
    container.Parent = keybindContent

    local bindLabel = Instance.new("TextLabel")
    bindLabel.Size = UDim2.new(0, 150, 1, 0)
    bindLabel.Position = UDim2.new(0, 10, 0, 0)
    bindLabel.BackgroundTransparency = 1
    bindLabel.TextColor3 = UI_CONFIG.TEXT_COLOR
    bindLabel.TextSize = 12
    bindLabel.Font = Enum.Font.Gotham
    bindLabel.Text = bind.label
    bindLabel.TextXAlignment = Enum.TextXAlignment.Left
    bindLabel.Parent = container

    local keyBtn = Instance.new("TextButton")
    keyBtn.Size = UDim2.new(0, 60, 0, 28)
    keyBtn.Position = UDim2.new(1, -70, 0, 6)
    keyBtn.BackgroundColor3 = UI_CONFIG.MAIN_COLOR
    keyBtn.BorderSizePixel = 1
    keyBtn.BorderColor3 = UI_CONFIG.ACCENT_COLOR
    keyBtn.TextColor3 = UI_CONFIG.ACCENT_TEXT
    keyBtn.TextSize = 12
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.Text = bind.key
    keyBtn.Parent = container
end

-- ============================================================
-- SETTINGS TAB CONTENT
-- ============================================================
local settingsContent = contentFrames["SETTINGS"]
settingsContent.CanvasSize = UDim2.new(0, 0, 0, 250)

local settingsLabel = Instance.new("TextLabel")
settingsLabel.Size = UDim2.new(1, -20, 0, 30)
settingsLabel.Position = UDim2.new(0, 10, 0, 10)
settingsLabel.BackgroundTransparency = 1
settingsLabel.TextColor3 = UI_CONFIG.ACCENT_TEXT
settingsLabel.TextSize = 16
settingsLabel.Font = Enum.Font.GothamBold
settingsLabel.Text = "SETTINGS"
settingsLabel.TextXAlignment = Enum.TextXAlignment.Left
settingsLabel.Parent = settingsContent

local settingsOptions = {
    {label = "Anti-Cheat Bypass", enabled = true},
    {label = "Smooth Movement", enabled = true},
    {label = "ESP Display", enabled = false},
    {label = "Auto-Save Config", enabled = true}
}

for i, setting in ipairs(settingsOptions) do
    local container = Instance.new("Frame")
    container.Name = setting.label .. "Container"
    container.Size = UDim2.new(1, -20, 0, 40)
    container.Position = UDim2.new(0, 10, 0, 40 + (i-1) * 45)
    container.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
    container.BorderSizePixel = 1
    container.BorderColor3 = UI_CONFIG.ACCENT_COLOR
    container.Parent = settingsContent

    local settingLabel = Instance.new("TextLabel")
    settingLabel.Size = UDim2.new(0, 200, 1, 0)
    settingLabel.Position = UDim2.new(0, 10, 0, 0)
    settingLabel.BackgroundTransparency = 1
    settingLabel.TextColor3 = UI_CONFIG.TEXT_COLOR
    settingLabel.TextSize = 12
    settingLabel.Font = Enum.Font.Gotham
    settingLabel.Text = setting.label
    settingLabel.TextXAlignment = Enum.TextXAlignment.Left
    settingLabel.Parent = container

    local toggleSwitch = Instance.new("TextButton")
    toggleSwitch.Size = UDim2.new(0, 50, 0, 28)
    toggleSwitch.Position = UDim2.new(1, -70, 0, 6)
    toggleSwitch.BackgroundColor3 = setting.enabled and UI_CONFIG.SUCCESS_COLOR or UI_CONFIG.DANGER_COLOR
    toggleSwitch.BorderSizePixel = 0
    toggleSwitch.TextColor3 = UI_CONFIG.MAIN_COLOR
    toggleSwitch.TextSize = 11
    toggleSwitch.Font = Enum.Font.GothamBold
    toggleSwitch.Text = setting.enabled and "ON" or "OFF"
    toggleSwitch.Parent = container

    toggleSwitch.MouseButton1Click:Connect(function()
        setting.enabled = not setting.enabled
        toggleSwitch.Text = setting.enabled and "ON" or "OFF"
        toggleSwitch.BackgroundColor3 = setting.enabled and UI_CONFIG.SUCCESS_COLOR or UI_CONFIG.DANGER_COLOR
        print(setting.label .. ": " .. (setting.enabled and "ENABLED" or "DISABLED"))
    end)
end

-- ============================================================
-- FOOTER
-- ============================================================
local footer = Instance.new("Frame")
footer.Name = "Footer"
footer.Size = UDim2.new(1, 0, 0, 30)
footer.Position = UDim2.new(0, 0, 1, -30)
footer.BackgroundColor3 = UI_CONFIG.SECONDARY_COLOR
footer.BorderSizePixel = 1
footer.BorderColor3 = UI_CONFIG.ACCENT_COLOR
footer.Parent = mainFrame

local footerText = Instance.new("TextLabel")
footerText.Size = UDim2.new(1, 0, 1, 0)
footerText.BackgroundTransparency = 1
footerText.TextColor3 = UI_CONFIG.ACCENT_TEXT
footerText.TextSize = 12
footerText.Font = Enum.Font.GothamBold
footerText.Text = "discord.gg/HgxWN2x2 | v2.0"
footerText.Parent = footer

print("✓ Shade Duels UI v2 loaded successfully!")
print("✓ Dark cyberpunk theme active")
print("✓ Direct speed input ready - no more button spam!")
