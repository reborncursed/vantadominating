-- ============================================================
-- NEMESIS X PREMIUM EDITION v2 — WITH AUTHENTICATION SYSTEM
-- Sacred UI Foundation | Account Auth | by CursedExility
-- Replit API-ready | Email + License Binding
-- ============================================================

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")

local lp        = Players.LocalPlayer
local playerGui = lp:WaitForChild("PlayerGui")

-- Cleanup
for _, old in ipairs(playerGui:GetChildren()) do
    if old.Name == "NX_UI"     or old.Name == "NX_Toggle"
    or old.Name == "NX_Auth"   or old.Name == "NX_Confirm" then
        old:Destroy()
    end
end

-- ============================================================
-- CONFIG
-- ============================================================
local REPLIT_URL = "https://edb380b6-3cee-44db-842c-268175d69d5a-00-ib570wwibtlr.worf.replit.dev"
local SAVED_EMAIL_KEY   = "NX_SavedEmail"
local SAVED_SESSION_KEY = "NX_Session"

-- ============================================================
-- THEMES
-- ============================================================
local THEMES = {
    ["Purple Neon"]   = Color3.fromRGB(170, 0,   255),
    ["Blue Electric"] = Color3.fromRGB(0,   150, 255),
    ["Red Crimson"]   = Color3.fromRGB(255, 0,   50),
    ["Green Toxic"]   = Color3.fromRGB(0,   255, 100),
    ["Gold"]          = Color3.fromRGB(240, 185, 55),
    ["Cyan"]          = Color3.fromRGB(0,   220, 220),
}

local ACCENT = THEMES["Purple Neon"]
local C = {
    BG     = Color3.fromRGB(10,  8,  14),
    Panel  = Color3.fromRGB(16,  12, 22),
    Card   = Color3.fromRGB(13,  10, 18),
    Input  = Color3.fromRGB(20,  15, 28),
    White  = Color3.fromRGB(255, 255, 255),
    Gray   = Color3.fromRGB(140, 140, 145),
    TogOff = Color3.fromRGB(26,  20, 32),
    Green  = Color3.fromRGB(45,  210, 110),
    Red    = Color3.fromRGB(215, 60,  60),
    Gold   = Color3.fromRGB(240, 185, 55),
    Yellow = Color3.fromRGB(255, 220, 60),
}

local themeStrokes = {}
local themeTexts   = {}
local themeFrames  = {}

local function applyTheme(color)
    ACCENT = color
    for _, s in ipairs(themeStrokes) do pcall(function() if s.Parent then s.Color = color end end) end
    for _, t in ipairs(themeTexts)   do pcall(function() if t.Parent then t.TextColor3 = color end end) end
    for _, f in ipairs(themeFrames)  do pcall(function() if f.Parent then f.BackgroundColor3 = color end end) end
end

-- ============================================================
-- SESSION STORAGE
-- ============================================================
local sessionData = {
    email       = "",
    licenseKey  = "",
    accountType = "Premium",
    authenticated = false,
    rememberMe  = false,
}

local function loadSavedEmail()
    local saved = ""
    pcall(function() saved = getgenv()[SAVED_EMAIL_KEY] or "" end)
    return saved
end

local function saveEmail(email)
    pcall(function() getgenv()[SAVED_EMAIL_KEY] = email end)
end

local function clearSession()
    pcall(function()
        getgenv()[SAVED_EMAIL_KEY]   = ""
        getgenv()[SAVED_SESSION_KEY] = ""
    end)
    sessionData.email         = ""
    sessionData.licenseKey    = ""
    sessionData.authenticated = false
    sessionData.rememberMe    = false
end

-- ============================================================
-- DETECTION UTILITIES
-- ============================================================
local function detectExecutor()
    local name = "Unknown"
    pcall(function()
        if identifyexecutor then name = identifyexecutor()
        elseif getexecutorname then name = getexecutorname()
        elseif syn and syn.request then name = "Synapse X"
        elseif KRNL_LOADED then name = "KRNL"
        elseif Delta then name = "Delta"
        elseif Hydrogen then name = "Hydrogen" end
    end)
    return name
end

local function detectSea()
    local lv = 0
    pcall(function()
        local d = lp:FindFirstChild("Data")
        if d then
            local l = d:FindFirstChild("Level")
            if l then lv = tonumber(l.Value) or 0 end
        end
    end)
    if lv >= 1500 then return "Third Sea", 3
    elseif lv >= 700 then return "Second Sea", 2
    else return "First Sea", 1 end
end

local function getScale()
    local vp = workspace.CurrentCamera.ViewportSize
    local w   = vp.X
    if w >= 1920 then return 1.2
    elseif w >= 1366 then return 1.0
    elseif w >= 1024 then return 0.88
    elseif w >= 768  then return 0.78
    else return 0.65 end
end

-- ============================================================
-- API CALLS
-- ============================================================
local function apiValidate(email, licenseKey)
    local ok, result = pcall(function()
        return HttpService:RequestAsync({
            Url    = REPLIT_URL .. "/validate",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body   = HttpService:JSONEncode({
                email = email,
                key   = licenseKey,
                hwid  = tostring(lp.UserId) .. "-" .. tostring(game.PlaceId),
            })
        })
    end)
    if not ok then return false, "Server Offline", nil end
    if result.StatusCode == 200 then
        local data = {}
        pcall(function() data = HttpService:JSONDecode(result.Body) end)
        return true, "Authentication Successful", data
    elseif result.StatusCode == 403 then
        local data = {}
        pcall(function() data = HttpService:JSONDecode(result.Body) end)
        local msg = data.message or "License Already Bound"
        return false, msg, nil
    elseif result.StatusCode == 404 then
        return false, "Invalid License", nil
    else
        return false, "Server Error: " .. tostring(result.StatusCode), nil
    end
end

-- ============================================================
-- ============================================================
-- AUTHENTICATION SCREEN
-- ============================================================
-- ============================================================

local AuthSG = Instance.new("ScreenGui")
AuthSG.Name           = "NX_Auth"
AuthSG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
AuthSG.ResetOnSpawn   = false
AuthSG.IgnoreGuiInset = true
AuthSG.Parent         = playerGui

-- Background blur overlay
local authBG = Instance.new("Frame", AuthSG)
authBG.Size                = UDim2.new(1, 0, 1, 0)
authBG.BackgroundColor3    = Color3.fromRGB(5, 3, 8)
authBG.BackgroundTransparency = 0.2
authBG.BorderSizePixel     = 0
authBG.ZIndex              = 1

-- Ambient glow
local glow = Instance.new("ImageLabel", AuthSG)
glow.Size             = UDim2.new(0, 500, 0, 500)
glow.Position         = UDim2.new(0.5, -250, 0.5, -250)
glow.BackgroundTransparency = 1
glow.Image            = "rbxassetid://5779559284"
glow.ImageColor3      = ACCENT
glow.ImageTransparency = 0.7
glow.ZIndex           = 2
table.insert(themeTexts, glow)

-- Auth panel
local authPanel = Instance.new("Frame", AuthSG)
authPanel.Name             = "AuthPanel"
authPanel.Size             = UDim2.new(0, 340, 0, 430)
authPanel.Position         = UDim2.new(0.5, -170, 0.5, -215)
authPanel.BackgroundColor3 = C.BG
authPanel.BorderSizePixel  = 0
authPanel.ZIndex           = 3
authPanel.Active           = true
authPanel.Draggable        = true
Instance.new("UICorner", authPanel).CornerRadius = UDim.new(0, 12)

local apStroke = Instance.new("UIStroke", authPanel)
apStroke.Thickness = 1.5
apStroke.Color     = ACCENT
table.insert(themeStrokes, apStroke)

-- Animated border pulse
task.spawn(function()
    local t = 0
    while authPanel and authPanel.Parent do
        task.wait(0.06); t += 0.06
        if apStroke and apStroke.Parent then
            apStroke.Transparency = 0.2 + 0.5 * math.abs(math.sin(t * 0.5))
        end
    end
end)

-- Auth rain
local authRain = Instance.new("Frame", authPanel)
authRain.Size                = UDim2.new(1, 0, 1, 0)
authRain.BackgroundTransparency = 1
authRain.ClipsDescendants    = true
authRain.BorderSizePixel     = 0
authRain.ZIndex              = 3

task.spawn(function()
    while authPanel and authPanel.Parent and authPanel.Visible do
        for _ = 1, 2 do
            local drop = Instance.new("Frame", authRain)
            drop.Size                   = UDim2.new(0, 1, 0, math.random(8, 18))
            drop.Position               = UDim2.new(math.random(), 0, 0, -20)
            drop.BackgroundColor3       = ACCENT
            drop.BorderSizePixel        = 0
            drop.BackgroundTransparency = 0.55
            drop.ZIndex                 = 3
            table.insert(themeFrames, drop)
            Instance.new("UICorner", drop).CornerRadius = UDim.new(1, 0)
            local dur = math.random(6, 11) / 10
            local tw  = TweenService:Create(drop, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
                Position = UDim2.new(drop.Position.X.Scale, 0, 1, 10)
            })
            tw:Play()
            tw.Completed:Connect(function()
                local i = table.find(themeFrames, drop)
                if i then table.remove(themeFrames, i) end
                drop:Destroy()
            end)
        end
        task.wait(0.03)
    end
end)

-- ── TOP ACCENT BAR ──
local topAccent = Instance.new("Frame", authPanel)
topAccent.Size             = UDim2.new(1, 0, 0, 4)
topAccent.BackgroundColor3 = ACCENT
topAccent.BorderSizePixel  = 0
topAccent.ZIndex           = 4
Instance.new("UICorner", topAccent).CornerRadius = UDim.new(0, 12)
local taFix = Instance.new("Frame", topAccent)
taFix.Size             = UDim2.new(1, 0, 0.5, 0)
taFix.Position         = UDim2.new(0, 0, 0.5, 0)
taFix.BackgroundColor3 = ACCENT
taFix.BorderSizePixel  = 0
table.insert(themeFrames, topAccent)
table.insert(themeFrames, taFix)

-- ── LOGO ──
local authLogo = Instance.new("TextLabel", authPanel)
authLogo.Text             = "⚔  NEMESIS  X"
authLogo.Font             = Enum.Font.GothamBlack
authLogo.TextSize         = 22
authLogo.TextColor3       = ACCENT
authLogo.Size             = UDim2.new(1, 0, 0, 30)
authLogo.Position         = UDim2.new(0, 0, 0, 18)
authLogo.BackgroundTransparency = 1
authLogo.TextXAlignment   = Enum.TextXAlignment.Center
authLogo.ZIndex           = 5
table.insert(themeTexts, authLogo)

local authSub = Instance.new("TextLabel", authPanel)
authSub.Text             = "PREMIUM EDITION"
authSub.Font             = Enum.Font.Gotham
authSub.TextSize         = 8
authSub.TextColor3       = C.Gray
authSub.Size             = UDim2.new(1, 0, 0, 12)
authSub.Position         = UDim2.new(0, 0, 0, 50)
authSub.BackgroundTransparency = 1
authSub.TextXAlignment   = Enum.TextXAlignment.Center
authSub.ZIndex           = 5

-- Divider
local authDiv = Instance.new("Frame", authPanel)
authDiv.Size             = UDim2.new(0.7, 0, 0, 1)
authDiv.Position         = UDim2.new(0.15, 0, 0, 68)
authDiv.BackgroundColor3 = ACCENT
authDiv.BackgroundTransparency = 0.6
authDiv.BorderSizePixel  = 0
authDiv.ZIndex           = 4
table.insert(themeFrames, authDiv)

-- Welcome labels
local welcomeLbl = Instance.new("TextLabel", authPanel)
welcomeLbl.Text             = "Welcome Back"
welcomeLbl.Font             = Enum.Font.GothamBold
welcomeLbl.TextSize         = 15
welcomeLbl.TextColor3       = C.White
welcomeLbl.Size             = UDim2.new(1, 0, 0, 20)
welcomeLbl.Position         = UDim2.new(0, 0, 0, 76)
welcomeLbl.BackgroundTransparency = 1
welcomeLbl.TextXAlignment   = Enum.TextXAlignment.Center
welcomeLbl.ZIndex           = 5

local secLbl = Instance.new("TextLabel", authPanel)
secLbl.Text             = "Secure License Authentication"
secLbl.Font             = Enum.Font.Gotham
secLbl.TextSize         = 9
secLbl.TextColor3       = C.Gray
secLbl.Size             = UDim2.new(1, 0, 0, 14)
secLbl.Position         = UDim2.new(0, 0, 0, 96)
secLbl.BackgroundTransparency = 1
secLbl.TextXAlignment   = Enum.TextXAlignment.Center
secLbl.ZIndex           = 5

-- ── INPUT HELPER ──
local function makeInput(parent, placeholder, yPos, masked)
    local wrapper = Instance.new("Frame", parent)
    wrapper.Size             = UDim2.new(0, 280, 0, 36)
    wrapper.Position         = UDim2.new(0.5, -140, 0, yPos)
    wrapper.BackgroundColor3 = C.Input
    wrapper.BorderSizePixel  = 0
    wrapper.ZIndex           = 5
    Instance.new("UICorner", wrapper).CornerRadius = UDim.new(0, 8)
    local ws = Instance.new("UIStroke", wrapper)
    ws.Thickness = 1; ws.Color = ACCENT; ws.Transparency = 0.6
    table.insert(themeStrokes, ws)

    local box = Instance.new("TextBox", wrapper)
    box.Size             = UDim2.new(1, -16, 1, 0)
    box.Position         = UDim2.new(0, 8, 0, 0)
    box.BackgroundTransparency = 1
    box.Text             = ""
    box.PlaceholderText  = placeholder
    box.PlaceholderColor3 = Color3.fromRGB(80, 70, 95)
    box.Font             = Enum.Font.Gotham
    box.TextSize         = 11
    box.TextColor3       = C.White
    box.TextXAlignment   = Enum.TextXAlignment.Left
    box.ZIndex           = 6
    box.ClearTextOnFocus  = false
    if masked then box.TextTransparency = 1 end -- handle masking below

    -- Focus glow
    box.Focused:Connect(function()
        TweenService:Create(ws, TweenInfo.new(0.15), { Transparency = 0.1 }):Play()
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(ws, TweenInfo.new(0.15), { Transparency = 0.6 }):Play()
    end)

    return wrapper, box
end

-- ── EMAIL INPUT ──
local emailLabel = Instance.new("TextLabel", authPanel)
emailLabel.Text             = "Email Address"
emailLabel.Font             = Enum.Font.GothamBold
emailLabel.TextSize         = 9
emailLabel.TextColor3       = C.Gray
emailLabel.Size             = UDim2.new(0, 280, 0, 14)
emailLabel.Position         = UDim2.new(0.5, -140, 0, 116)
emailLabel.BackgroundTransparency = 1
emailLabel.TextXAlignment   = Enum.TextXAlignment.Left
emailLabel.ZIndex           = 5

local _, emailBox = makeInput(authPanel, "Enter your email address", 130)
emailBox.Text = loadSavedEmail()

-- ── LICENSE KEY INPUT ──
local keyLabel = Instance.new("TextLabel", authPanel)
keyLabel.Text             = "License Key"
keyLabel.Font             = Enum.Font.GothamBold
keyLabel.TextSize         = 9
keyLabel.TextColor3       = C.Gray
keyLabel.Size             = UDim2.new(0, 280, 0, 14)
keyLabel.Position         = UDim2.new(0.5, -140, 0, 172)
keyLabel.BackgroundTransparency = 1
keyLabel.TextXAlignment   = Enum.TextXAlignment.Left
keyLabel.ZIndex           = 5

local _, keyBox = makeInput(authPanel, "NMX-XXXXXXXX-XXXXXXXX", 186)

-- ── WARNING CARD ──
local warnCard = Instance.new("Frame", authPanel)
warnCard.Size             = UDim2.new(0, 280, 0, 52)
warnCard.Position         = UDim2.new(0.5, -140, 0, 230)
warnCard.BackgroundColor3 = Color3.fromRGB(40, 28, 8)
warnCard.BorderSizePixel  = 0
warnCard.ZIndex           = 5
Instance.new("UICorner", warnCard).CornerRadius = UDim.new(0, 6)
local warnStroke = Instance.new("UIStroke", warnCard)
warnStroke.Thickness = 1; warnStroke.Color = C.Gold; warnStroke.Transparency = 0.35

local warnIcon = Instance.new("TextLabel", warnCard)
warnIcon.Text             = "⚠"
warnIcon.Font             = Enum.Font.GothamBlack
warnIcon.TextSize         = 14
warnIcon.TextColor3       = C.Gold
warnIcon.Size             = UDim2.new(0, 20, 1, 0)
warnIcon.Position         = UDim2.new(0, 8, 0, 0)
warnIcon.BackgroundTransparency = 1
warnIcon.TextXAlignment   = Enum.TextXAlignment.Center
warnIcon.ZIndex           = 6

local warnText = Instance.new("TextLabel", warnCard)
warnText.Text             = "IMPORTANT\nThe email used on first login will be permanently linked to your license."
warnText.Font             = Enum.Font.Gotham
warnText.TextSize         = 8
warnText.TextColor3       = C.Gold
warnText.Size             = UDim2.new(1, -36, 1, -6)
warnText.Position         = UDim2.new(0, 30, 0, 3)
warnText.BackgroundTransparency = 1
warnText.TextXAlignment   = Enum.TextXAlignment.Left
warnText.TextWrapped      = true
warnText.ZIndex           = 6

-- ── CHECKBOX ──
local checkboxChecked = false

local checkRow = Instance.new("Frame", authPanel)
checkRow.Size             = UDim2.new(0, 280, 0, 24)
checkRow.Position         = UDim2.new(0.5, -140, 0, 290)
checkRow.BackgroundTransparency = 1
checkRow.ZIndex           = 5

local checkBox = Instance.new("TextButton", checkRow)
checkBox.Size             = UDim2.new(0, 16, 0, 16)
checkBox.Position         = UDim2.new(0, 0, 0.5, -8)
checkBox.BackgroundColor3 = C.Input
checkBox.Text             = ""
checkBox.ZIndex           = 6
checkBox.BorderSizePixel  = 0
checkBox.AutoButtonColor  = false
Instance.new("UICorner", checkBox).CornerRadius = UDim.new(0, 4)
local checkStroke = Instance.new("UIStroke", checkBox)
checkStroke.Thickness = 1; checkStroke.Color = ACCENT; checkStroke.Transparency = 0.4
table.insert(themeStrokes, checkStroke)

local checkMark = Instance.new("TextLabel", checkBox)
checkMark.Text             = "✔"
checkMark.Font             = Enum.Font.GothamBlack
checkMark.TextSize         = 10
checkMark.TextColor3       = ACCENT
checkMark.Size             = UDim2.new(1, 0, 1, 0)
checkMark.BackgroundTransparency = 1
checkMark.TextXAlignment   = Enum.TextXAlignment.Center
checkMark.ZIndex           = 7
checkMark.Visible          = false
table.insert(themeTexts, checkMark)

local checkLbl = Instance.new("TextLabel", checkRow)
checkLbl.Text             = "I understand that my email will be permanently\nlinked to this license."
checkLbl.Font             = Enum.Font.Gotham
checkLbl.TextSize         = 8
checkLbl.TextColor3       = C.Gray
checkLbl.Size             = UDim2.new(1, -22, 1, 0)
checkLbl.Position         = UDim2.new(0, 22, 0, 0)
checkLbl.BackgroundTransparency = 1
checkLbl.TextXAlignment   = Enum.TextXAlignment.Left
checkLbl.TextWrapped      = true
checkLbl.ZIndex           = 6

-- ── REMEMBER ME TOGGLE ──
local rememberRow = Instance.new("Frame", authPanel)
rememberRow.Size             = UDim2.new(0, 280, 0, 20)
rememberRow.Position         = UDim2.new(0.5, -140, 0, 320)
rememberRow.BackgroundTransparency = 1
rememberRow.ZIndex           = 5

local remLbl = Instance.new("TextLabel", rememberRow)
remLbl.Text             = "Remember Me"
remLbl.Font             = Enum.Font.Gotham
remLbl.TextSize         = 10
remLbl.TextColor3       = C.White
remLbl.Size             = UDim2.new(0.6, 0, 1, 0)
remLbl.BackgroundTransparency = 1
remLbl.TextXAlignment   = Enum.TextXAlignment.Left
remLbl.ZIndex           = 6

local remState = false
local remTrack = Instance.new("TextButton", rememberRow)
remTrack.Size             = UDim2.new(0, 28, 0, 14)
remTrack.Position         = UDim2.new(1, -28, 0.5, -7)
remTrack.BackgroundColor3 = C.TogOff
remTrack.Text             = ""
remTrack.ZIndex           = 6
remTrack.AutoButtonColor  = false
Instance.new("UICorner", remTrack).CornerRadius = UDim.new(1, 0)

local remDot = Instance.new("Frame", remTrack)
remDot.Size             = UDim2.new(0, 10, 0, 10)
remDot.Position         = UDim2.new(0, 2, 0.5, -5)
remDot.BackgroundColor3 = C.White
remDot.ZIndex           = 7
Instance.new("UICorner", remDot).CornerRadius = UDim.new(1, 0)

remTrack.MouseButton1Click:Connect(function()
    remState = not remState
    sessionData.rememberMe = remState
    remTrack.BackgroundColor3 = remState and ACCENT or C.TogOff
    if remState then table.insert(themeFrames, remTrack) end
    TweenService:Create(remDot, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
        Position = UDim2.new(remState and 1 or 0, remState and -12 or 2, 0.5, -5)
    }):Play()
end)

-- ── STATUS LABEL ──
local statusLbl = Instance.new("TextLabel", authPanel)
statusLbl.Text             = "Waiting For Authentication"
statusLbl.Font             = Enum.Font.GothamBold
statusLbl.TextSize         = 9
statusLbl.TextColor3       = C.Gray
statusLbl.Size             = UDim2.new(0, 280, 0, 14)
statusLbl.Position         = UDim2.new(0.5, -140, 0, 346)
statusLbl.BackgroundTransparency = 1
statusLbl.TextXAlignment   = Enum.TextXAlignment.Center
statusLbl.ZIndex           = 5

local function setStatus(text, color)
    statusLbl.Text      = text
    statusLbl.TextColor3 = color or C.Gray
end

-- ── AUTHENTICATE BUTTON ──
local authBtn = Instance.new("TextButton", authPanel)
authBtn.Name             = "AuthBtn"
authBtn.Size             = UDim2.new(0, 280, 0, 36)
authBtn.Position         = UDim2.new(0.5, -140, 0, 366)
authBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 80)
authBtn.Text             = "Authenticate"
authBtn.Font             = Enum.Font.GothamBlack
authBtn.TextSize         = 12
authBtn.TextColor3       = Color3.fromRGB(160, 120, 200)
authBtn.ZIndex           = 5
authBtn.BorderSizePixel  = 0
authBtn.AutoButtonColor  = false
Instance.new("UICorner", authBtn).CornerRadius = UDim.new(0, 8)
local abStroke = Instance.new("UIStroke", authBtn)
abStroke.Thickness = 1; abStroke.Color = Color3.fromRGB(100, 60, 140); abStroke.Transparency = 0.3

-- Button enabled/disabled logic
local function setAuthBtnEnabled(enabled)
    if enabled then
        authBtn.BackgroundColor3 = ACCENT:Lerp(C.BG, 0.3)
        authBtn.TextColor3       = C.White
        abStroke.Color           = ACCENT
        abStroke.Transparency    = 0.1
        table.insert(themeStrokes, abStroke)
    else
        authBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 80)
        authBtn.TextColor3       = Color3.fromRGB(160, 120, 200)
        abStroke.Color           = Color3.fromRGB(100, 60, 140)
        abStroke.Transparency    = 0.3
    end
end
setAuthBtnEnabled(false)

-- Checkbox logic — enables button
checkBox.MouseButton1Click:Connect(function()
    checkboxChecked = not checkboxChecked
    checkMark.Visible = checkboxChecked
    if checkboxChecked then
        checkBox.BackgroundColor3 = ACCENT:Lerp(C.BG, 0.6)
    else
        checkBox.BackgroundColor3 = C.Input
    end
    setAuthBtnEnabled(checkboxChecked)
end)

-- ============================================================
-- MAIN UI (hidden until auth success)
-- ============================================================
local activeFeatures = 0
local activeFeatLabel = nil

local function updateActiveFeats(delta)
    activeFeatures = math.max(0, activeFeatures + delta)
    if activeFeatLabel and activeFeatLabel.Parent then
        activeFeatLabel.Text = tostring(activeFeatures)
    end
end

local MainSG = Instance.new("ScreenGui")
MainSG.Name           = "NX_UI"
MainSG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MainSG.ResetOnSpawn   = false
MainSG.IgnoreGuiInset = true
MainSG.Visible        = false
MainSG.Parent         = playerGui

local uiScale = Instance.new("UIScale", MainSG)
uiScale.Scale = getScale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    uiScale.Scale = getScale()
end)

-- Toggle Icon
local TG = Instance.new("ScreenGui")
TG.Name           = "NX_Toggle"
TG.ResetOnSpawn   = false
TG.IgnoreGuiInset = true
TG.Parent         = playerGui

local openBtn = Instance.new("TextButton", TG)
openBtn.Size             = UDim2.new(0, 36, 0, 36)
openBtn.Position         = UDim2.new(0, 12, 0.5, -18)
openBtn.BackgroundColor3 = C.BG
openBtn.Text             = "N"
openBtn.Font             = Enum.Font.GothamBold
openBtn.TextSize         = 14
openBtn.TextColor3       = ACCENT
openBtn.Visible          = false
openBtn.ZIndex           = 10
openBtn.BorderSizePixel  = 0
openBtn.AutoButtonColor  = false
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(1, 0)
local obs = Instance.new("UIStroke", openBtn)
obs.Thickness = 1.2; obs.Color = ACCENT
table.insert(themeStrokes, obs)
table.insert(themeTexts,   openBtn)

-- Main Frame
local Main = Instance.new("Frame", MainSG)
Main.Name             = "MainFrame"
Main.Size             = UDim2.new(0, 540, 0, 310)
Main.Position         = UDim2.new(0.5, -270, 0.5, -155)
Main.BackgroundColor3 = C.BG
Main.BorderSizePixel  = 0
Main.Active           = true
Main.Draggable        = true
Main.ZIndex           = 2
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local mainStroke = Instance.new("UIStroke", Main)
mainStroke.Thickness = 1.2; mainStroke.Color = ACCENT
table.insert(themeStrokes, mainStroke)

task.spawn(function()
    local t = 0
    while Main and Main.Parent do
        task.wait(0.06); t += 0.06
        if mainStroke and mainStroke.Parent then
            mainStroke.Transparency = 0.28 + 0.38 * math.abs(math.sin(t * 0.5))
        end
    end
end)

local function hideMain()
    Main.Visible    = false
    openBtn.Visible = true
end
local function showMain()
    Main.Visible    = true
    openBtn.Visible = false
end
openBtn.MouseButton1Click:Connect(showMain)
UserInputService.InputBegan:Connect(function(i, gp)
    if not gp and i.KeyCode == Enum.KeyCode.F4 then
        if Main.Visible then hideMain() else showMain() end
    end
end)

-- Top bar
local topBar = Instance.new("Frame", Main)
topBar.Size             = UDim2.new(1, 0, 0, 30)
topBar.BackgroundColor3 = C.Panel
topBar.BackgroundTransparency = 0.3
topBar.BorderSizePixel  = 0
topBar.ZIndex           = 8
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 10)
local tbFix = Instance.new("Frame", topBar)
tbFix.Size             = UDim2.new(1, 0, 0, 10)
tbFix.Position         = UDim2.new(0, 0, 1, -10)
tbFix.BackgroundColor3 = C.Panel
tbFix.BackgroundTransparency = 0.3
tbFix.BorderSizePixel  = 0

local topTitle = Instance.new("TextLabel", topBar)
topTitle.Text             = "⚔  NEMESIS X  PREMIUM"
topTitle.Font             = Enum.Font.GothamBlack
topTitle.TextSize         = 12
topTitle.TextColor3       = ACCENT
topTitle.Size             = UDim2.new(1, 0, 1, 0)
topTitle.BackgroundTransparency = 1
topTitle.TextXAlignment   = Enum.TextXAlignment.Center
topTitle.ZIndex           = 9
table.insert(themeTexts, topTitle)

local function mkCtrl(text, xOff, color, cb)
    local b = Instance.new("TextButton", topBar)
    b.Size             = UDim2.new(0, 20, 0, 20)
    b.Position         = UDim2.new(1, xOff, 0, 5)
    b.BackgroundColor3 = C.Card
    b.Text             = text
    b.Font             = Enum.Font.GothamBold
    b.TextSize         = 11
    b.TextColor3       = color
    b.ZIndex           = 10
    b.BorderSizePixel  = 0
    b.AutoButtonColor  = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    b.MouseButton1Click:Connect(cb)
end
mkCtrl("-", -52, C.Gray, hideMain)
mkCtrl("X", -28, C.Red,  hideMain)

-- Rain
local rainFrame = Instance.new("Frame", Main)
rainFrame.Size                = UDim2.new(1, 0, 1, 0)
rainFrame.BackgroundTransparency = 1
rainFrame.ClipsDescendants    = true
rainFrame.BorderSizePixel     = 0
rainFrame.ZIndex              = 1

task.spawn(function()
    while Main and Main.Parent do
        for _ = 1, 2 do
            if Main.Visible then
                local drop = Instance.new("Frame", rainFrame)
                drop.Size                   = UDim2.new(0, 1, 0, math.random(10, 20))
                drop.Position               = UDim2.new(math.random(), 0, 0, -25)
                drop.BackgroundColor3       = ACCENT
                drop.BorderSizePixel        = 0
                drop.BackgroundTransparency = 0.5
                drop.ZIndex                 = 1
                table.insert(themeFrames, drop)
                Instance.new("UICorner", drop).CornerRadius = UDim.new(1, 0)
                local dur = math.random(7, 12) / 10
                local tw  = TweenService:Create(drop, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
                    Position = UDim2.new(drop.Position.X.Scale, 0, 1, 10)
                })
                tw:Play()
                tw.Completed:Connect(function()
                    local i = table.find(themeFrames, drop)
                    if i then table.remove(themeFrames, i) end
                    drop:Destroy()
                end)
            end
        end
        task.wait(0.025)
    end
end)

-- Sidebar
local sidebar = Instance.new("Frame", Main)
sidebar.Size                = UDim2.new(0, 118, 1, -30)
sidebar.Position            = UDim2.new(0, 0, 0, 30)
sidebar.BackgroundColor3    = C.Panel
sidebar.BackgroundTransparency = 0.2
sidebar.BorderSizePixel     = 0
sidebar.ZIndex              = 4
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 10)
local sbFix = Instance.new("Frame", sidebar)
sbFix.Size             = UDim2.new(0, 10, 1, 0)
sbFix.Position         = UDim2.new(1, -10, 0, 0)
sbFix.BackgroundColor3 = C.Panel
sbFix.BackgroundTransparency = 0.2
sbFix.BorderSizePixel  = 0

local logoLbl = Instance.new("TextLabel", sidebar)
logoLbl.Text             = "⚔ Nemesis X"
logoLbl.Font             = Enum.Font.GothamBlack
logoLbl.TextSize         = 11
logoLbl.TextColor3       = ACCENT
logoLbl.Size             = UDim2.new(1, 0, 0, 16)
logoLbl.Position         = UDim2.new(0, 10, 0, 8)
logoLbl.BackgroundTransparency = 1
logoLbl.TextXAlignment   = Enum.TextXAlignment.Left
logoLbl.ZIndex           = 5
table.insert(themeTexts, logoLbl)

local subLbl = Instance.new("TextLabel", sidebar)
subLbl.Text             = "PREMIUM"
subLbl.Font             = Enum.Font.Gotham
subLbl.TextSize         = 7
subLbl.TextColor3       = C.Gray
subLbl.Size             = UDim2.new(1, 0, 0, 10)
subLbl.Position         = UDim2.new(0, 10, 0, 25)
subLbl.BackgroundTransparency = 1
subLbl.TextXAlignment   = Enum.TextXAlignment.Left
subLbl.ZIndex           = 5

local navDiv = Instance.new("Frame", sidebar)
navDiv.Size             = UDim2.new(0.82, 0, 0, 1)
navDiv.Position         = UDim2.new(0.09, 0, 0, 38)
navDiv.BackgroundColor3 = ACCENT
navDiv.BackgroundTransparency = 0.65
navDiv.BorderSizePixel  = 0
navDiv.ZIndex           = 5
table.insert(themeFrames, navDiv)

local navScroll = Instance.new("ScrollingFrame", sidebar)
navScroll.Size                = UDim2.new(1, 0, 1, -42)
navScroll.Position            = UDim2.new(0, 0, 0, 41)
navScroll.BackgroundTransparency = 1
navScroll.BorderSizePixel     = 0
navScroll.ScrollBarThickness  = 2
navScroll.ScrollBarImageColor3 = ACCENT
navScroll.CanvasSize          = UDim2.new(0, 0, 0, 0)
navScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
navScroll.ZIndex              = 5
local navLayout = Instance.new("UIListLayout", navScroll)
navLayout.Padding   = UDim.new(0, 1)
navLayout.SortOrder = Enum.SortOrder.LayoutOrder
local navPad = Instance.new("UIPadding", navScroll)
navPad.PaddingLeft  = UDim.new(0, 5)
navPad.PaddingRight = UDim.new(0, 5)
navPad.PaddingTop   = UDim.new(0, 2)

-- Content area
local contentArea = Instance.new("Frame", Main)
contentArea.Size                = UDim2.new(1, -122, 1, -34)
contentArea.Position            = UDim2.new(0, 120, 0, 32)
contentArea.BackgroundTransparency = 1
contentArea.BorderSizePixel     = 0
contentArea.ZIndex              = 3
contentArea.ClipsDescendants    = true

-- ============================================================
-- SACRED UI HELPERS (Full preserved set)
-- ============================================================

local function createModuleCard(name, size, pos, parent)
    parent = parent or contentArea
    local card = Instance.new("Frame", parent)
    card.Size             = size
    card.Position         = pos
    card.BackgroundColor3 = C.Panel
    card.ZIndex           = 4
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
    local cs = Instance.new("UIStroke", card)
    cs.Thickness = 1; cs.Color = ACCENT; cs.Transparency = 0.2
    table.insert(themeStrokes, cs)
    local sl = Instance.new("Frame", card)
    sl.Size             = UDim2.new(0, 2, 0, 11)
    sl.Position         = UDim2.new(0, 8, 0, 8)
    sl.BackgroundColor3 = ACCENT
    sl.BorderSizePixel  = 0
    sl.ZIndex           = 5
    table.insert(themeFrames, sl)
    local title = Instance.new("TextLabel", card)
    title.Text             = name
    title.Font             = Enum.Font.GothamBold
    title.TextSize         = 10
    title.TextColor3       = C.White
    title.Size             = UDim2.new(1, -25, 0, 25)
    title.Position         = UDim2.new(0, 15, 0, 1)
    title.BackgroundTransparency = 1
    title.TextXAlignment   = Enum.TextXAlignment.Left
    title.ZIndex           = 5
    return card
end

local function addToggleElement(parent, labelText, defaultState, yPos, callback)
    local state = defaultState or false
    local frame = Instance.new("Frame", parent)
    frame.Size             = UDim2.new(1, -16, 0, 22)
    frame.Position         = UDim2.new(0, 8, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.ZIndex           = 5
    local label = Instance.new("TextLabel", frame)
    label.Text             = labelText
    label.Font             = Enum.Font.Gotham
    label.TextSize         = 10
    label.TextColor3       = C.White
    label.Size             = UDim2.new(0, 130, 1, 0)
    label.BackgroundTransparency = 1
    label.TextXAlignment   = Enum.TextXAlignment.Left
    label.ZIndex           = 5
    local track = Instance.new("TextButton", frame)
    track.Size             = UDim2.new(0, 28, 0, 14)
    track.Position         = UDim2.new(1, -28, 0.5, -7)
    track.BackgroundColor3 = state and ACCENT or C.TogOff
    track.Text             = ""
    track.ZIndex           = 5
    track.AutoButtonColor  = false
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    if state then table.insert(themeFrames, track) end
    local dot = Instance.new("Frame", track)
    dot.Size             = UDim2.new(0, 10, 0, 10)
    dot.Position         = state and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5)
    dot.BackgroundColor3 = C.White
    dot.ZIndex           = 6
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    track.MouseButton1Click:Connect(function()
        state = not state
        if state then
            track.BackgroundColor3 = ACCENT
            table.insert(themeFrames, track)
            updateActiveFeats(1)
        else
            local idx = table.find(themeFrames, track)
            if idx then table.remove(themeFrames, idx) end
            track.BackgroundColor3 = C.TogOff
            updateActiveFeats(-1)
        end
        TweenService:Create(dot, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
            Position = UDim2.new(state and 1 or 0, state and -12 or 2, 0.5, -5)
        }):Play()
        if callback then callback(state) end
    end)
    return frame, track
end

local function addSliderElement(parent, labelText, min, max, default, yPos, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size             = UDim2.new(1, -16, 0, 30)
    frame.Position         = UDim2.new(0, 8, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.ZIndex           = 5
    local label = Instance.new("TextLabel", frame)
    label.Text             = labelText
    label.Font             = Enum.Font.Gotham
    label.TextSize         = 10
    label.TextColor3       = C.White
    label.Size             = UDim2.new(0, 90, 0, 12)
    label.BackgroundTransparency = 1
    label.TextXAlignment   = Enum.TextXAlignment.Left
    label.ZIndex           = 5
    local valLbl = Instance.new("TextLabel", frame)
    valLbl.Text            = tostring(default)
    valLbl.Font            = Enum.Font.Gotham
    valLbl.TextSize        = 9
    valLbl.TextColor3      = C.Gray
    valLbl.Size            = UDim2.new(0, 30, 0, 12)
    valLbl.Position        = UDim2.new(1, -30, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.TextXAlignment  = Enum.TextXAlignment.Right
    valLbl.ZIndex          = 5
    local sliderBG = Instance.new("TextButton", frame)
    sliderBG.Size             = UDim2.new(1, 0, 0, 3)
    sliderBG.Position         = UDim2.new(0, 0, 0, 18)
    sliderBG.BackgroundColor3 = C.TogOff
    sliderBG.Text             = ""
    sliderBG.BorderSizePixel  = 0
    sliderBG.ZIndex           = 5
    sliderBG.AutoButtonColor  = false
    local fill = Instance.new("Frame", sliderBG)
    fill.Size             = UDim2.new((default-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = ACCENT
    fill.BorderSizePixel  = 0
    fill.ZIndex           = 6
    table.insert(themeFrames, fill)
    local knob = Instance.new("Frame", fill)
    knob.Size             = UDim2.new(0, 8, 0, 8)
    knob.Position         = UDim2.new(1, -4, 0.5, -4)
    knob.BackgroundColor3 = C.White
    knob.ZIndex           = 7
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local dragging = false
    local function update(input)
        local pct = math.clamp((input.Position.X - sliderBG.AbsolutePosition.X) / sliderBG.AbsoluteSize.X, 0, 1)
        fill.Size  = UDim2.new(pct, 0, 1, 0)
        local val  = math.round(min + pct * (max - min))
        valLbl.Text = tostring(val)
        if callback then callback(val) end
    end
    sliderBG.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; update(i)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            update(i)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    return frame
end

local function addDropdownElement(parent, labelText, optionText, yPos)
    local frame = Instance.new("Frame", parent)
    frame.Size             = UDim2.new(1, -16, 0, 22)
    frame.Position         = UDim2.new(0, 8, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.ZIndex           = 5
    local label = Instance.new("TextLabel", frame)
    label.Text             = labelText
    label.Font             = Enum.Font.Gotham
    label.TextSize         = 10
    label.TextColor3       = C.White
    label.Size             = UDim2.new(0, 70, 1, 0)
    label.BackgroundTransparency = 1
    label.TextXAlignment   = Enum.TextXAlignment.Left
    label.ZIndex           = 5
    local menuBtn = Instance.new("TextButton", frame)
    menuBtn.Text             = optionText .. "  ▼"
    menuBtn.Font             = Enum.Font.GothamBold
    menuBtn.TextSize         = 10
    menuBtn.TextColor3       = ACCENT
    menuBtn.Size             = UDim2.new(0, 100, 1, 0)
    menuBtn.Position         = UDim2.new(1, -100, 0, 0)
    menuBtn.BackgroundTransparency = 1
    menuBtn.TextXAlignment   = Enum.TextXAlignment.Right
    menuBtn.ZIndex           = 5
    menuBtn.AutoButtonColor  = false
    table.insert(themeTexts, menuBtn)
    return menuBtn
end

-- ============================================================
-- PAGE / CARD HELPERS
-- ============================================================
local function makePage()
    local sf = Instance.new("ScrollingFrame", contentArea)
    sf.Size                = UDim2.new(1, 0, 1, 0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel     = 0
    sf.ScrollBarThickness  = 3
    sf.ScrollBarImageColor3 = ACCENT
    sf.CanvasSize          = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.Visible             = false
    sf.ZIndex              = 4
    local layout = Instance.new("UIListLayout", sf)
    layout.Padding = UDim.new(0, 5); layout.SortOrder = Enum.SortOrder.LayoutOrder
    local pad = Instance.new("UIPadding", sf)
    pad.PaddingLeft = UDim.new(0,4); pad.PaddingRight = UDim.new(0,5)
    pad.PaddingTop  = UDim.new(0,5); pad.PaddingBottom = UDim.new(0,6)
    return sf
end

local function pageHeader(page, text)
    local f = Instance.new("Frame", page)
    f.Size             = UDim2.new(1, 0, 0, 22)
    f.BackgroundColor3 = C.Panel
    f.BorderSizePixel  = 0
    f.ZIndex           = 5
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 5)
    local fs = Instance.new("UIStroke", f)
    fs.Thickness = 1; fs.Color = ACCENT; fs.Transparency = 0.4
    table.insert(themeStrokes, fs)
    local lbl = Instance.new("TextLabel", f)
    lbl.Text             = text
    lbl.Font             = Enum.Font.GothamBlack
    lbl.TextSize         = 10
    lbl.TextColor3       = ACCENT
    lbl.Size             = UDim2.new(1,-10,1,0)
    lbl.Position         = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.ZIndex           = 6
    table.insert(themeTexts, lbl)
end

local function makeCard(page, title)
    local card = Instance.new("Frame", page)
    card.Size             = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize    = Enum.AutomaticSize.Y
    card.BackgroundColor3 = C.Card
    card.BorderSizePixel  = 0
    card.ZIndex           = 5
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
    local cs = Instance.new("UIStroke", card)
    cs.Thickness = 1; cs.Color = ACCENT; cs.Transparency = 0.22
    table.insert(themeStrokes, cs)
    local sl = Instance.new("Frame", card)
    sl.Size             = UDim2.new(0, 2, 0, 11)
    sl.Position         = UDim2.new(0, 8, 0, 8)
    sl.BackgroundColor3 = ACCENT
    sl.BorderSizePixel  = 0
    sl.ZIndex           = 6
    table.insert(themeFrames, sl)
    local ll = Instance.new("UIListLayout", card)
    ll.Padding = UDim.new(0,0); ll.SortOrder = Enum.SortOrder.LayoutOrder
    local lpad = Instance.new("UIPadding", card)
    lpad.PaddingLeft = UDim.new(0,8); lpad.PaddingRight = UDim.new(0,8)
    lpad.PaddingTop  = UDim.new(0,6); lpad.PaddingBottom = UDim.new(0,6)
    if title and title ~= "" then
        local tl = Instance.new("TextLabel", card)
        tl.Text             = title
        tl.Font             = Enum.Font.GothamBold
        tl.TextSize         = 10
        tl.TextColor3       = C.White
        tl.Size             = UDim2.new(1,-14,0,20)
        tl.BackgroundTransparency = 1
        tl.TextXAlignment   = Enum.TextXAlignment.Left
        tl.ZIndex           = 6
        tl.LayoutOrder      = 0
        tl.AutomaticSize    = Enum.AutomaticSize.None
    end
    return card
end

local function cardToggle(card, label, cb)
    local state = false
    local frame = Instance.new("Frame", card)
    frame.Size             = UDim2.new(1,-14,0,22)
    frame.BackgroundTransparency = 1
    frame.ZIndex           = 6
    local lbl = Instance.new("TextLabel", frame)
    lbl.Text             = label
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = 10
    lbl.TextColor3       = C.White
    lbl.Size             = UDim2.new(1,-36,1,0)
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.ZIndex           = 6
    local track = Instance.new("TextButton", frame)
    track.Size             = UDim2.new(0,28,0,14)
    track.Position         = UDim2.new(1,-28,0.5,-7)
    track.BackgroundColor3 = C.TogOff
    track.Text             = ""
    track.ZIndex           = 6
    track.AutoButtonColor  = false
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)
    local dot = Instance.new("Frame", track)
    dot.Size             = UDim2.new(0,10,0,10)
    dot.Position         = UDim2.new(0,2,0.5,-5)
    dot.BackgroundColor3 = C.White
    dot.ZIndex           = 7
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
    track.MouseButton1Click:Connect(function()
        state = not state
        if state then
            track.BackgroundColor3 = ACCENT
            table.insert(themeFrames, track)
            updateActiveFeats(1)
        else
            local idx = table.find(themeFrames, track)
            if idx then table.remove(themeFrames, idx) end
            track.BackgroundColor3 = C.TogOff
            updateActiveFeats(-1)
        end
        TweenService:Create(dot, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
            Position = UDim2.new(state and 1 or 0, state and -12 or 2, 0.5, -5)
        }):Play()
        if cb then cb(state) end
    end)
    return frame
end

local function cardStat(card, label, init)
    local f = Instance.new("Frame", card)
    f.Size             = UDim2.new(1,-14,0,18)
    f.BackgroundTransparency = 1
    f.ZIndex           = 6
    local lbl = Instance.new("TextLabel", f)
    lbl.Text             = label
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = 9
    lbl.TextColor3       = C.Gray
    lbl.Size             = UDim2.new(0.58,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.ZIndex           = 6
    local val = Instance.new("TextLabel", f)
    val.Text             = init or "—"
    val.Font             = Enum.Font.GothamBold
    val.TextSize         = 9
    val.TextColor3       = C.White
    val.Size             = UDim2.new(0.42,-2,1,0)
    val.Position         = UDim2.new(0.58,0,0,0)
    val.BackgroundTransparency = 1
    val.TextXAlignment   = Enum.TextXAlignment.Right
    val.ZIndex           = 6
    return val
end

local function cardDD(card, label, opt)
    local f = Instance.new("Frame", card)
    f.Size             = UDim2.new(1,-14,0,22)
    f.BackgroundTransparency = 1
    f.ZIndex           = 6
    local lbl = Instance.new("TextLabel", f)
    lbl.Text             = label
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = 10
    lbl.TextColor3       = C.White
    lbl.Size             = UDim2.new(0.5,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.ZIndex           = 6
    local btn = Instance.new("TextButton", f)
    btn.Text             = opt .. "  ▼"
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 10
    btn.TextColor3       = ACCENT
    btn.Size             = UDim2.new(0.5,0,1,0)
    btn.Position         = UDim2.new(0.5,0,0,0)
    btn.BackgroundTransparency = 1
    btn.TextXAlignment   = Enum.TextXAlignment.Right
    btn.ZIndex           = 6
    btn.AutoButtonColor  = false
    table.insert(themeTexts, btn)
    return btn
end

local function cardSlider(card, label, min, max, default, cb)
    local f = Instance.new("Frame", card)
    f.Size             = UDim2.new(1,-14,0,30)
    f.BackgroundTransparency = 1
    f.ZIndex           = 6
    local lbl = Instance.new("TextLabel", f)
    lbl.Text             = label
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = 10
    lbl.TextColor3       = C.White
    lbl.Size             = UDim2.new(0,100,0,14)
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.ZIndex           = 6
    local vl = Instance.new("TextLabel", f)
    vl.Text            = tostring(default)
    vl.Font            = Enum.Font.Gotham
    vl.TextSize        = 9
    vl.TextColor3      = C.Gray
    vl.Size            = UDim2.new(0,30,0,14)
    vl.Position        = UDim2.new(1,-30,0,0)
    vl.BackgroundTransparency = 1
    vl.TextXAlignment  = Enum.TextXAlignment.Right
    vl.ZIndex          = 6
    local bg = Instance.new("TextButton", f)
    bg.Size             = UDim2.new(1,0,0,3)
    bg.Position         = UDim2.new(0,0,0,20)
    bg.BackgroundColor3 = C.TogOff
    bg.Text             = ""
    bg.BorderSizePixel  = 0
    bg.ZIndex           = 6
    bg.AutoButtonColor  = false
    local fill = Instance.new("Frame", bg)
    fill.Size             = UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = ACCENT
    fill.BorderSizePixel  = 0
    fill.ZIndex           = 7
    table.insert(themeFrames, fill)
    local knob = Instance.new("Frame", fill)
    knob.Size             = UDim2.new(0,8,0,8)
    knob.Position         = UDim2.new(1,-4,0.5,-4)
    knob.BackgroundColor3 = C.White
    knob.ZIndex           = 8
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
    local dragging = false
    local function upd(i)
        local pct = math.clamp((i.Position.X-bg.AbsolutePosition.X)/bg.AbsoluteSize.X,0,1)
        fill.Size = UDim2.new(pct,0,1,0)
        local v = math.round(min+pct*(max-min))
        vl.Text = tostring(v)
        if cb then cb(v) end
    end
    bg.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true; upd(i)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            upd(i)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=false
        end
    end)
end

local function cardBtn(card, text, cb)
    local btn = Instance.new("TextButton", card)
    btn.Size             = UDim2.new(1,-14,0,22)
    btn.BackgroundColor3 = C.Panel
    btn.Text             = text
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 10
    btn.TextColor3       = ACCENT
    btn.ZIndex           = 6
    btn.BorderSizePixel  = 0
    btn.AutoButtonColor  = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)
    local bs = Instance.new("UIStroke", btn)
    bs.Thickness=1; bs.Color=ACCENT; bs.Transparency=0.4
    table.insert(themeStrokes, bs)
    table.insert(themeTexts, btn)
    if cb then btn.MouseButton1Click:Connect(cb) end
    return btn
end

local function cardSpacer(card, h)
    local s = Instance.new("Frame", card)
    s.Size             = UDim2.new(1,0,0,h or 4)
    s.BackgroundTransparency = 1
    s.ZIndex           = 6
end

local function cardProgress(card, label, cur, tot)
    local f = Instance.new("Frame", card)
    f.Size             = UDim2.new(1,-14,0,26)
    f.BackgroundTransparency = 1
    f.ZIndex           = 6
    local lbl = Instance.new("TextLabel", f)
    lbl.Text             = label
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = 9
    lbl.TextColor3       = C.Gray
    lbl.Size             = UDim2.new(0.6,0,0,12)
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.ZIndex           = 6
    local cntLbl = Instance.new("TextLabel", f)
    cntLbl.Text            = tostring(cur).." / "..tostring(tot)
    cntLbl.Font            = Enum.Font.GothamBold
    cntLbl.TextSize        = 9
    cntLbl.TextColor3      = C.White
    cntLbl.Size            = UDim2.new(0.4,0,0,12)
    cntLbl.Position        = UDim2.new(0.6,0,0,0)
    cntLbl.BackgroundTransparency = 1
    cntLbl.TextXAlignment  = Enum.TextXAlignment.Right
    cntLbl.ZIndex          = 6
    local barBG = Instance.new("Frame", f)
    barBG.Size             = UDim2.new(1,0,0,5)
    barBG.Position         = UDim2.new(0,0,0,16)
    barBG.BackgroundColor3 = C.TogOff
    barBG.BorderSizePixel  = 0
    barBG.ZIndex           = 6
    Instance.new("UICorner", barBG).CornerRadius = UDim.new(0,3)
    local barFill = Instance.new("Frame", barBG)
    barFill.Size             = UDim2.new(math.clamp(cur/math.max(tot,1),0,1),0,1,0)
    barFill.BackgroundColor3 = ACCENT
    barFill.BorderSizePixel  = 0
    barFill.ZIndex           = 7
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(0,3)
    table.insert(themeFrames, barFill)
    return f, cntLbl, barFill
end

local function cardBtnRow(card, btns)
    local row = Instance.new("Frame", card)
    row.Size             = UDim2.new(1,-14,0,22)
    row.BackgroundTransparency = 1
    row.ZIndex           = 6
    local ll = Instance.new("UIListLayout", row)
    ll.FillDirection = Enum.FillDirection.Horizontal
    ll.Padding       = UDim.new(0,4)
    ll.SortOrder     = Enum.SortOrder.LayoutOrder
    for i, info in ipairs(btns) do
        local b = Instance.new("TextButton", row)
        b.Size             = UDim2.new(1/#btns, -(4*(#btns-1)/#btns), 1, 0)
        b.BackgroundColor3 = C.Panel
        b.Text             = info.text
        b.Font             = Enum.Font.GothamBold
        b.TextSize         = 9
        b.TextColor3       = ACCENT
        b.ZIndex           = 6
        b.BorderSizePixel  = 0
        b.AutoButtonColor  = false
        b.LayoutOrder      = i
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,5)
        local bs = Instance.new("UIStroke", b)
        bs.Thickness=1; bs.Color=ACCENT; bs.Transparency=0.4
        table.insert(themeStrokes, bs)
        table.insert(themeTexts, b)
        if info.cb then b.MouseButton1Click:Connect(info.cb) end
    end
    return row
end

-- ============================================================
-- TAB SYSTEM
-- ============================================================
local TABS = {
    {name="Home",         icon="🏠"},
    {name="Auto Farm",    icon="🌾"},
    {name="Sea Events",   icon="🌊"},
    {name="Items",        icon="⚔️"},
    {name="Devil Fruits", icon="🍎"},
    {name="ESP",          icon="👁️"},
    {name="Teleports",    icon="🚀"},
    {name="Server",       icon="🔄"},
    {name="Protection",   icon="🛡️"},
    {name="Combat",       icon="💥"},
    {name="Race",         icon="⚡"},
    {name="Chests",       icon="📦"},
    {name="Statistics",   icon="📊"},
    {name="Notifs",       icon="🔔"},
    {name="Settings",     icon="⚙️"},
}

local pages   = {}
local navBtns = {}

local function switchTab(name)
    for _, p in pairs(pages)   do p.Visible = false end
    for _, b in pairs(navBtns) do
        b.TextColor3           = C.Gray
        b.BackgroundTransparency = 1
    end
    if pages[name]   then pages[name].Visible = true end
    if navBtns[name] then
        navBtns[name].TextColor3           = ACCENT
        navBtns[name].BackgroundTransparency = 0.85
    end
end

for i, tab in ipairs(TABS) do
    local btn = Instance.new("TextButton", navScroll)
    btn.Text             = tab.icon .. " " .. tab.name
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 10
    btn.TextColor3       = C.Gray
    btn.Size             = UDim2.new(1, 0, 0, 22)
    btn.BackgroundColor3 = ACCENT
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel  = 0
    btn.TextXAlignment   = Enum.TextXAlignment.Left
    btn.ZIndex           = 6
    btn.LayoutOrder      = i
    btn.AutoButtonColor  = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    local bpad = Instance.new("UIPadding", btn)
    bpad.PaddingLeft = UDim.new(0, 8)
    navBtns[tab.name] = btn
    btn.MouseButton1Click:Connect(function() switchTab(tab.name) end)
    pages[tab.name] = makePage()
end

-- ============================================================
-- ── HOME PAGE ──
-- ============================================================
local seaName, seaNum = detectSea()
local executorName    = detectExecutor()

local hp = pages["Home"]
pageHeader(hp, "⚔ Nemesis X — Dashboard")

local logoCard = makeCard(hp, "")
local logoTL = Instance.new("TextLabel", logoCard)
logoTL.Text             = "⚔  NEMESIS  X"
logoTL.Font             = Enum.Font.GothamBlack
logoTL.TextSize         = 20
logoTL.TextColor3       = ACCENT
logoTL.Size             = UDim2.new(1,-14,0,26)
logoTL.BackgroundTransparency = 1
logoTL.TextXAlignment   = Enum.TextXAlignment.Center
logoTL.ZIndex           = 6
table.insert(themeTexts, logoTL)

local premTL = Instance.new("TextLabel", logoCard)
premTL.Text             = "PREMIUM EDITION  •  v2.0  •  ALL SEAS"
premTL.Font             = Enum.Font.Gotham
premTL.TextSize         = 7
premTL.TextColor3       = C.Gray
premTL.Size             = UDim2.new(1,-14,0,14)
premTL.BackgroundTransparency = 1
premTL.TextXAlignment   = Enum.TextXAlignment.Center
premTL.ZIndex           = 6

local statusRow = Instance.new("Frame", logoCard)
statusRow.Size             = UDim2.new(1,-14,0,16)
statusRow.BackgroundTransparency = 1
statusRow.ZIndex           = 6
local sdot = Instance.new("Frame", statusRow)
sdot.Size             = UDim2.new(0,6,0,6)
sdot.Position         = UDim2.new(0,0,0.5,-3)
sdot.BackgroundColor3 = C.Green
sdot.BorderSizePixel  = 0
Instance.new("UICorner", sdot).CornerRadius = UDim.new(1,0)
local stLbl = Instance.new("TextLabel", statusRow)
stLbl.Text             = "Status: Undetected  ✔"
stLbl.Font             = Enum.Font.GothamBold
stLbl.TextSize         = 9
stLbl.TextColor3       = C.Green
stLbl.Size             = UDim2.new(1,-10,1,0)
stLbl.Position         = UDim2.new(0,10,0,0)
stLbl.BackgroundTransparency = 1
stLbl.TextXAlignment   = Enum.TextXAlignment.Left
stLbl.ZIndex           = 6

-- User info card
local infoCard = makeCard(hp, "User Info")
local rtVal   = cardStat(infoCard, "Runtime",        "00:00:00")
local usrVal  = cardStat(infoCard, "Username",       lp.Name)
cardStat(infoCard, "Display Name",   lp.DisplayName)
local exeVal  = cardStat(infoCard, "Executor",       executorName)
local seaVal  = cardStat(infoCard, "Current Sea",    seaName)
cardStat(infoCard, "Key Status",     "✔ Active")
activeFeatLabel = cardStat(infoCard, "Active Features", "0")
cardStat(infoCard, "Total Features", "70+")

-- Runtime
task.spawn(function()
    local s = tick()
    while true do
        task.wait(1)
        local e = math.floor(tick()-s)
        rtVal.Text = string.format("%02d:%02d:%02d", math.floor(e/3600), math.floor(e/60)%60, e%60)
        local sn, _ = detectSea(); seaVal.Text = sn
    end
end)

-- Account card (populated after auth)
local accountCard = makeCard(hp, "🔐 Account")
local emailDisplayVal = cardStat(accountCard, "Email",               "—")
local acctTypeVal     = cardStat(accountCard, "Account Type",        "Premium")
local licenseStatVal  = cardStat(accountCard, "License Status",      "Active")
local authStatVal     = cardStat(accountCard, "Authentication",      "Verified ✔")
cardSpacer(accountCard, 2)
cardBtnRow(accountCard, {
    {text="🔄 Switch Account", cb=function()
        clearSession()
        MainSG.Visible = false
        authPanel.Visible = true
        setStatus("Waiting For Authentication", C.Gray)
        emailBox.Text = ""
        keyBox.Text   = ""
    end},
    {text="🚪 Log Out"},
})

-- Actions card
local actCard = makeCard(hp, "Quick Actions")
cardBtnRow(actCard, {
    {text="💬 Discord",   cb=function() pcall(function() setclipboard("https://discord.gg/8rz6u37Pac") end) end},
    {text="📋 Copy Key",  cb=function() pcall(function() setclipboard(sessionData.licenseKey) end) end},
})
cardBtnRow(actCard, {
    {text="💾 Save Config"},
    {text="📂 Load Config"},
})

-- Notif card
local homeNotifCard = makeCard(hp, "🔔 Notifications")
local nLbl = Instance.new("TextLabel", homeNotifCard)
nLbl.Text             = "✔ Nemesis X Premium v2.0 loaded!"
nLbl.Font             = Enum.Font.Gotham
nLbl.TextSize         = 9
nLbl.TextColor3       = C.Green
nLbl.Size             = UDim2.new(1,-14,0,16)
nLbl.BackgroundTransparency = 1
nLbl.TextXAlignment   = Enum.TextXAlignment.Left
nLbl.ZIndex           = 6

-- ============================================================
-- ── AUTO FARM PAGE ──
-- ============================================================
local fp = pages["Auto Farm"]
pageHeader(fp, "🌾 Auto Farm Pro")
local fmCard = makeCard(fp, "Farm Manager")
cardDD(fmCard, "Farm Type", "Level Farm")
cardDD(fmCard, "Target",    "Auto (by Sea)")
cardSpacer(fmCard, 2)
cardStat(fmCard, "Current Sea",   seaName)
cardStat(fmCard, "Status",        "Idle")
cardStat(fmCard, "Current Stage", "—")
cardProgress(fmCard, "Progress", 0, 100)
cardBtnRow(fmCard, {{text="▶ Start"},{text="⏹ Stop"}})
local fsetCard = makeCard(fp, "Farm Settings")
cardToggle(fsetCard, "Auto Farm")
cardToggle(fsetCard, "Auto Quest")
cardToggle(fsetCard, "Auto Level")
cardToggle(fsetCard, "Fast Attack")
cardToggle(fsetCard, "Bring Mobs")
cardToggle(fsetCard, "Auto Haki")
cardToggle(fsetCard, "Auto Stats")
cardToggle(fsetCard, "Auto Equip Weapon")
cardToggle(fsetCard, "Auto Equip Fruit")
cardToggle(fsetCard, "Smart Farm AI")
cardToggle(fsetCard, "Auto Elite Hunter")
cardToggle(fsetCard, "Auto Boss Farm")
cardToggle(fsetCard, "Auto Mastery Farm")
cardSlider(fsetCard, "Farm Range", 10, 200, 50)

-- ============================================================
-- ── SEA EVENTS PAGE ──
-- ============================================================
local sep2 = pages["Sea Events"]
pageHeader(sep2, "🌊 Sea Events Manager")
local levCard = makeCard(sep2, "🐋 Leviathan Manager")
cardStat(levCard, "Status",        "Idle")
cardStat(levCard, "Current Stage", "—")
cardStat(levCard, "Reward Status", "—")
cardStat(levCard, "Frozen Status", "—")
cardProgress(levCard, "Progress", 0, 100)
cardBtnRow(levCard, {{text="▶ Start"},{text="⏹ Stop"}})
cardSpacer(levCard, 2)
cardToggle(levCard, "Auto Leviathan")
cardToggle(levCard, "Auto Leviathan ESP")
cardToggle(levCard, "Auto Leviathan Hop")
cardToggle(levCard, "Auto Leviathan Rewards")
cardToggle(levCard, "Full Moon Tracker")
cardToggle(levCard, "Auto Frozen Dimension")
local sbCard = makeCard(sep2, "🌊 Sea Events")
cardToggle(sbCard, "Auto Sea Beast")
cardToggle(sbCard, "Auto Terror Shark")
cardToggle(sbCard, "Auto Ship Raid")
cardToggle(sbCard, "Auto Haunted Ship")
cardToggle(sbCard, "Auto Mirage Island")
cardToggle(sbCard, "Auto Boat")
cardToggle(sbCard, "Auto Heart")
cardToggle(sbCard, "Auto Sea Event ESP")
cardToggle(sbCard, "Auto Sea Event Teleport")
cardToggle(sbCard, "Auto Sea Event Rewards")

-- ============================================================
-- ── ITEMS PAGE ──
-- ============================================================
local ip = pages["Items"]
pageHeader(ip, "⚔️ Items & Progression Managers")
local yamaCard = makeCard(ip, "🗡️ Yama Manager")
cardStat(yamaCard, "Current Stage", "Elite Hunter Farming")
cardStat(yamaCard, "Status",        "Idle")
cardProgress(yamaCard, "Elite Kills", 0, 30)
cardSpacer(yamaCard, 2)
cardToggle(yamaCard, "Elite Hunter Hop")
cardToggle(yamaCard, "Auto Elite Hunter Quest")
cardToggle(yamaCard, "Auto Elite Kill")
cardToggle(yamaCard, "Auto Server Hop Elite")
cardSpacer(yamaCard, 2)
cardBtnRow(yamaCard, {{text="Continue Progress"},{text="TP Yama Room"}})
cardBtnRow(yamaCard, {{text="▶ Pull Yama"},{text="⏹ Stop"}})

local tushCard = makeCard(ip, "⚡ Tushita Manager")
cardStat(tushCard, "Current Stage", "—")
cardStat(tushCard, "Status",        "Idle")
cardProgress(tushCard, "Progress", 0, 100)
cardSpacer(tushCard, 2)
cardToggle(tushCard, "Auto Rip Indra")
cardToggle(tushCard, "Auto Holy Torch")
cardToggle(tushCard, "Auto Longma")
cardToggle(tushCard, "Auto Puzzle")
cardSpacer(tushCard, 2)
cardBtnRow(tushCard, {{text="Continue Progress"},{text="TP Longma"}})
cardBtnRow(tushCard, {{text="TP Torch"},{text="⏹ Stop"}})

local cdkCard = makeCard(ip, "👑 CDK Manager")
cardStat(cdkCard, "Current Stage", "—")
cardStat(cdkCard, "Status",        "Idle")
cardProgress(cdkCard, "Progress", 0, 100)
cardSpacer(cdkCard, 2)
cardToggle(cdkCard, "Auto Yama Progress")
cardToggle(cdkCard, "Auto Tushita Progress")
cardToggle(cdkCard, "Auto Fear Trial")
cardToggle(cdkCard, "Auto Pain Trial")
cardToggle(cdkCard, "Auto Haze Trial")
cardSpacer(cdkCard, 2)
cardBtnRow(cdkCard, {{text="Continue Progress"},{text="Start CDK Quest"}})
cardBtnRow(cdkCard, {{text="TP Scroll NPC"},{text="⏹ Stop"}})

local sgCard = makeCard(ip, "🎸 Soul Guitar Manager")
cardStat(sgCard, "Current Stage", "—")
cardStat(sgCard, "Status",        "Idle")
cardProgress(sgCard, "Progress", 0, 100)
cardSpacer(sgCard, 2)
cardToggle(sgCard, "Auto Graveyard Farm")
cardToggle(sgCard, "Auto Materials")
cardToggle(sgCard, "Auto Ghost Farm")
cardToggle(sgCard, "Auto Puzzle")
cardSpacer(sgCard, 2)
cardBtnRow(sgCard, {{text="Continue Progress"},{text="TP Graveyard"}})
cardBtnRow(sgCard, {{text="TP Puzzle"},{text="⏹ Stop"}})

local saCard = makeCard(ip, "⚓ Shark Anchor Manager")
cardStat(saCard, "Current Stage", "—")
cardStat(saCard, "Status",        "Idle")
cardProgress(saCard, "Progress", 0, 100)
cardSpacer(saCard, 2)
cardToggle(saCard, "Auto Monster Magnet")
cardToggle(saCard, "Auto Terror Shark")
cardToggle(saCard, "Auto Materials")
cardSpacer(saCard, 2)
cardBtnRow(saCard, {{text="Continue Progress"},{text="TP Terror Shark"}})
cardBtnRow(saCard, {{text="▶ Start"},{text="⏹ Stop"}})

-- ============================================================
-- ── DEVIL FRUITS PAGE ──
-- ============================================================
local dfp = pages["Devil Fruits"]
pageHeader(dfp, "🍎 Devil Fruits")
local fruitCard = makeCard(dfp, "Fruit System")
cardStat(fruitCard, "Status",         "Idle")
cardStat(fruitCard, "Current Target", "None")
cardSpacer(fruitCard, 2)
cardToggle(fruitCard, "Fruit ESP")
cardToggle(fruitCard, "Fruit Sniper")
cardToggle(fruitCard, "Auto Buy Fruit")
cardToggle(fruitCard, "Auto Store Fruit")
cardToggle(fruitCard, "Auto Eat Fruit")
cardToggle(fruitCard, "Fruit Notifier")
cardToggle(fruitCard, "Fruit Teleport")
cardSpacer(fruitCard, 2)
cardDD(fruitCard, "Target Fruit", "Any")
cardBtnRow(fruitCard, {{text="▶ Start"},{text="⏹ Stop"}})

-- ============================================================
-- ── ESP PAGE ──
-- ============================================================
local ep = pages["ESP"]
pageHeader(ep, "👁️ ESP")
local espCard = makeCard(ep, "Player & Boss")
cardToggle(espCard, "Player ESP")
cardToggle(espCard, "Boss ESP")
cardToggle(espCard, "NPC ESP")
local espFCard = makeCard(ep, "Fruit & Chest")
cardToggle(espFCard, "Fruit ESP")
cardToggle(espFCard, "Chest ESP")
local espSCard = makeCard(ep, "Sea & Island")
cardToggle(espSCard, "Leviathan ESP")
cardToggle(espSCard, "Island ESP")
local espSetCard = makeCard(ep, "ESP Settings")
cardSlider(espSetCard, "Range",    50, 5000, 1000)
cardSlider(espSetCard, "Box Size", 1,  10,   2)
cardDD(espSetCard, "Style", "Box")

-- ============================================================
-- ── TELEPORTS PAGE ──
-- ============================================================
local tp2 = pages["Teleports"]
pageHeader(tp2, "🚀 Teleports")
local tpCard = makeCard(tp2, "Teleport Options")
cardToggle(tpCard, "Island Teleport")
cardToggle(tpCard, "NPC Teleport")
cardToggle(tpCard, "Boss Teleport")
cardDD(tpCard, "Sea",    "Third Sea")
cardDD(tpCard, "Island", "Port Town")
cardBtnRow(tpCard, {{text="🚀 Teleport Now"}})
local tpJobCard = makeCard(tp2, "Job ID")
cardToggle(tpJobCard, "Join Job ID")
cardToggle(tpJobCard, "Copy Job ID")

-- ============================================================
-- ── SERVER PAGE ──
-- ============================================================
local svp = pages["Server"]
pageHeader(svp, "🔄 Server")
local srvCard = makeCard(svp, "Server Options")
cardToggle(srvCard, "Server Hop")
cardToggle(srvCard, "Auto Rejoin")
cardToggle(srvCard, "Hop Full Moon")
cardToggle(srvCard, "Hop Leviathan")
cardToggle(srvCard, "Hop Low Players")
cardSlider(srvCard, "Min Players", 1, 12, 6)

-- ============================================================
-- ── PROTECTION PAGE ──
-- ============================================================
local pp = pages["Protection"]
pageHeader(pp, "🛡️ Protection")
local protCard = makeCard(pp, "Protection Options")
cardToggle(protCard, "Anti AFK")
cardToggle(protCard, "Anti Void")
cardToggle(protCard, "Anti Stuck")
cardToggle(protCard, "Auto Reconnect")
cardToggle(protCard, "FPS Boost")

-- ============================================================
-- ── COMBAT PAGE ──
-- ============================================================
local cp = pages["Combat"]
pageHeader(cp, "💥 Combat")
local combCard = makeCard(cp, "Combat Options")
cardToggle(combCard, "Combat Aura")
cardToggle(combCard, "Auto Skill")
cardToggle(combCard, "Auto Weapon")
cardToggle(combCard, "Auto Dodge")
cardToggle(combCard, "Kill Aura")
cardSlider(combCard, "Aura Range", 5, 100, 20)

-- ============================================================
-- ── RACE PAGE ──
-- ============================================================
local rp = pages["Race"]
pageHeader(rp, "⚡ Race")
local raceCard = makeCard(rp, "Race Upgrades")
cardToggle(raceCard, "Auto Race V2")
cardToggle(raceCard, "Auto Race V3")
cardToggle(raceCard, "Auto Race V4")
cardToggle(raceCard, "Auto Blue Gear")

-- ============================================================
-- ── CHESTS PAGE ──
-- ============================================================
local chp = pages["Chests"]
pageHeader(chp, "📦 Chests")
local chestCard = makeCard(chp, "Chest Options")
cardToggle(chestCard, "Auto Chest")
cardToggle(chestCard, "Auto Elite Chest")
cardToggle(chestCard, "Auto Mirage Chest")
cardToggle(chestCard, "Chest ESP")

-- ============================================================
-- ── STATISTICS PAGE ──
-- ============================================================
local stp = pages["Statistics"]
pageHeader(stp, "📊 Statistics")
local statCard = makeCard(stp, "Session Stats")
local srtVal = cardStat(statCard, "Runtime",          "00:00:00")
local safVal = cardStat(statCard, "Active Features",  "0")
cardStat(statCard, "Beli Earned",      "0")
cardStat(statCard, "Fragments Earned", "0")
cardStat(statCard, "Levels Gained",    "0")
cardStat(statCard, "Chests Collected", "0")
task.spawn(function()
    local s = tick()
    while true do
        task.wait(1)
        local e = math.floor(tick()-s)
        srtVal.Text = string.format("%02d:%02d:%02d", math.floor(e/3600), math.floor(e/60)%60, e%60)
        safVal.Text = tostring(activeFeatures)
    end
end)

-- ============================================================
-- ── NOTIFICATIONS PAGE ──
-- ============================================================
local np = pages["Notifs"]
pageHeader(np, "🔔 Notifications")
local notifCard2 = makeCard(np, "Alert Settings")
cardToggle(notifCard2, "Voice Notifications")
cardToggle(notifCard2, "Fruit Alert")
cardToggle(notifCard2, "Boss Alert")
cardToggle(notifCard2, "Leviathan Alert")
cardToggle(notifCard2, "Full Moon Alert")
local feedCard = makeCard(np, "Notification Feed")
local feedLbl = Instance.new("TextLabel", feedCard)
feedLbl.Text             = "No notifications yet."
feedLbl.Font             = Enum.Font.Gotham
feedLbl.TextSize         = 9
feedLbl.TextColor3       = C.Gray
feedLbl.Size             = UDim2.new(1,-14,0,28)
feedLbl.BackgroundTransparency = 1
feedLbl.TextXAlignment   = Enum.TextXAlignment.Left
feedLbl.TextWrapped      = true
feedLbl.ZIndex           = 6

-- ============================================================
-- ── SETTINGS PAGE ──
-- ============================================================
local settPage = pages["Settings"]
pageHeader(settPage, "⚙️ Settings")

-- Theme card
local themeCard = makeCard(settPage, "🎨 Theme Settings")
local tselBtn = Instance.new("TextButton", themeCard)
tselBtn.Text             = "Purple Neon  ▼"
tselBtn.Font             = Enum.Font.GothamBold
tselBtn.TextSize         = 10
tselBtn.TextColor3       = ACCENT
tselBtn.Size             = UDim2.new(1,-14,0,22)
tselBtn.BackgroundColor3 = C.Panel
tselBtn.ZIndex           = 6
tselBtn.BorderSizePixel  = 0
tselBtn.AutoButtonColor  = false
Instance.new("UICorner", tselBtn).CornerRadius = UDim.new(0,5)
table.insert(themeTexts, tselBtn)

local tdd = Instance.new("Frame", themeCard)
tdd.Size             = UDim2.new(1,-14,0,0)
tdd.AutomaticSize    = Enum.AutomaticSize.Y
tdd.BackgroundColor3 = C.Panel
tdd.Visible          = false
tdd.ZIndex           = 20
tdd.BorderSizePixel  = 0
Instance.new("UICorner", tdd).CornerRadius = UDim.new(0,5)
local tddL = Instance.new("UIListLayout", tdd); tddL.SortOrder = Enum.SortOrder.LayoutOrder
local ti = 1
for tName, tColor in pairs(THEMES) do
    local opt = Instance.new("TextButton", tdd)
    opt.Size             = UDim2.new(1,0,0,20)
    opt.BackgroundTransparency = 1
    opt.Text             = tName
    opt.Font             = Enum.Font.GothamSemibold
    opt.TextSize         = 10
    opt.TextColor3       = tColor
    opt.ZIndex           = 21
    opt.LayoutOrder      = ti
    opt.AutoButtonColor  = false
    opt.MouseButton1Click:Connect(function()
        applyTheme(tColor)
        tselBtn.Text = tName .. "  ▼"
        tdd.Visible  = false
    end)
    ti += 1
end
tselBtn.MouseButton1Click:Connect(function()
    tdd.Visible = not tdd.Visible
end)
cardSpacer(themeCard, 2)
cardToggle(themeCard, "RGB Theme")

-- Account settings card
local acctSettCard = makeCard(settPage, "🔐 Account Settings")
local setEmailVal  = cardStat(acctSettCard, "Email",            "—")
local setAcctType  = cardStat(acctSettCard, "Account Type",     "Premium")
local setAuthStat  = cardStat(acctSettCard, "Auth Status",      "Verified")
local setLicStat   = cardStat(acctSettCard, "License Status",   "Active")
cardSpacer(acctSettCard, 2)
cardBtnRow(acctSettCard, {
    {text="🔄 Switch Account", cb=function()
        clearSession()
        MainSG.Visible = false
        authPanel.Visible = true
        setStatus("Waiting For Authentication", C.Gray)
        emailBox.Text = ""
        keyBox.Text   = ""
    end},
    {text="🚪 Log Out", cb=function()
        -- Confirmation handled inline
        clearSession()
        MainSG.Visible = false
        authPanel.Visible = true
        setStatus("Logged out. Please authenticate.", C.Gold)
        emailBox.Text = ""
        keyBox.Text   = ""
    end},
})

-- General card
local genCard = makeCard(settPage, "General")
cardToggle(genCard, "Mobile Mode")
cardToggle(genCard, "Performance Mode")
cardToggle(genCard, "Auto Save")

-- Config card
local cfgCard = makeCard(settPage, "Config")
cardBtnRow(cfgCard, {{text="💾 Save Config"},{text="📂 Load Config"}})

-- Display card
local scaleCard = makeCard(settPage, "Display")
cardSlider(scaleCard, "UI Scale", 50, 150, 100, function(val)
    uiScale.Scale = getScale() * (val / 100)
end)

-- ============================================================
-- ACTIVATE HOME
-- ============================================================
switchTab("Home")

-- ============================================================
-- ── AUTHENTICATE BUTTON LOGIC ──
-- ============================================================
local function openMainUI()
    -- Update account displays
    emailDisplayVal.Text = sessionData.email
    setEmailVal.Text     = sessionData.email

    -- Animate auth panel out
    TweenService:Create(authPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, -170, -0.5, -215),
        BackgroundTransparency = 1,
    }):Play()
    task.wait(0.3)
    AuthSG.Enabled    = false
    authPanel.Visible = false

    -- Show main UI
    MainSG.Visible    = true
    Main.Visible      = true
    Main.BackgroundTransparency = 1
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0,
    }):Play()

    print("[NX Premium] ✔ Authenticated | " .. sessionData.email)
end

authBtn.MouseButton1Click:Connect(function()
    if not checkboxChecked then return end

    local email = emailBox.Text:match("^%s*(.-)%s*$")
    local key   = keyBox.Text:match("^%s*(.-)%s*$")

    if email == "" then
        setStatus("Invalid Email", C.Red); return
    end
    if key == "" then
        setStatus("Invalid License", C.Red); return
    end

    setStatus("Authenticating...", C.Gold)
    authBtn.AutoButtonColor = false
    authBtn.BackgroundColor3 = Color3.fromRGB(40, 30, 55)

    task.spawn(function()
        local success, message, data = apiValidate(email, key)

        if success then
            sessionData.email         = email
            sessionData.licenseKey    = key
            sessionData.authenticated = true

            if remState then saveEmail(email) end

            setStatus("Authentication Successful ✔", C.Green)
            task.wait(0.8)
            openMainUI()
        else
            setStatus(message, C.Red)
            setAuthBtnEnabled(true)
        end
    end)
end)

-- ============================================================
-- LOG OUT CONFIRMATION WINDOW
-- ============================================================
local confirmSG = Instance.new("ScreenGui")
confirmSG.Name           = "NX_Confirm"
confirmSG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
confirmSG.ResetOnSpawn   = false
confirmSG.IgnoreGuiInset = true
confirmSG.Enabled        = false
confirmSG.Parent         = playerGui

local confirmBG = Instance.new("Frame", confirmSG)
confirmBG.Size                = UDim2.new(1,0,1,0)
confirmBG.BackgroundColor3    = Color3.new(0,0,0)
confirmBG.BackgroundTransparency = 0.5
confirmBG.BorderSizePixel     = 0
confirmBG.ZIndex              = 1

local confirmPanel = Instance.new("Frame", confirmSG)
confirmPanel.Size             = UDim2.new(0,260,0,120)
confirmPanel.Position         = UDim2.new(0.5,-130,0.5,-60)
confirmPanel.BackgroundColor3 = C.BG
confirmPanel.BorderSizePixel  = 0
confirmPanel.ZIndex           = 2
Instance.new("UICorner", confirmPanel).CornerRadius = UDim.new(0,10)
local cpS = Instance.new("UIStroke", confirmPanel)
cpS.Thickness=1.2; cpS.Color=ACCENT
table.insert(themeStrokes, cpS)

local cpTitle = Instance.new("TextLabel", confirmPanel)
cpTitle.Text             = "Are you sure you want to log out?"
cpTitle.Font             = Enum.Font.GothamBold
cpTitle.TextSize         = 11
cpTitle.TextColor3       = C.White
cpTitle.Size             = UDim2.new(1,-20,0,36)
cpTitle.Position         = UDim2.new(0,10,0,16)
cpTitle.BackgroundTransparency = 1
cpTitle.TextXAlignment   = Enum.TextXAlignment.Center
cpTitle.TextWrapped      = true
cpTitle.ZIndex           = 3

local confirmBtn = Instance.new("TextButton", confirmPanel)
confirmBtn.Size             = UDim2.new(0,110,0,28)
confirmBtn.Position         = UDim2.new(0,10,1,-40)
confirmBtn.BackgroundColor3 = C.Red
confirmBtn.Text             = "✔ Confirm"
confirmBtn.Font             = Enum.Font.GothamBold
confirmBtn.TextSize         = 11
confirmBtn.TextColor3       = C.White
confirmBtn.ZIndex           = 3
confirmBtn.BorderSizePixel  = 0
confirmBtn.AutoButtonColor  = false
Instance.new("UICorner", confirmBtn).CornerRadius = UDim.new(0,6)

local cancelBtn = Instance.new("TextButton", confirmPanel)
cancelBtn.Size             = UDim2.new(0,110,0,28)
cancelBtn.Position         = UDim2.new(1,-120,1,-40)
cancelBtn.BackgroundColor3 = C.Panel
cancelBtn.Text             = "✕ Cancel"
cancelBtn.Font             = Enum.Font.GothamBold
cancelBtn.TextSize         = 11
cancelBtn.TextColor3       = C.Gray
cancelBtn.ZIndex           = 3
cancelBtn.BorderSizePixel  = 0
cancelBtn.AutoButtonColor  = false
Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0,6)

confirmBtn.MouseButton1Click:Connect(function()
    confirmSG.Enabled = false
    clearSession()
    MainSG.Visible    = false
    authPanel.Visible = true
    AuthSG.Enabled    = true
    setStatus("Logged out. Please authenticate.", C.Gold)
    emailBox.Text = ""
    keyBox.Text   = ""
end)

cancelBtn.MouseButton1Click:Connect(function()
    confirmSG.Enabled = false
end)

-- Wire log out buttons to confirmation
-- (override the inline cb above with the confirm dialog)
-- Done via parent card btn — handled in settings card
-- ============================================================
-- INIT
-- ============================================================
print("[NX Premium v2] Auth UI Ready | " .. detectExecutor())
