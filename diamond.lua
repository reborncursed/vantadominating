--// Services
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

--// Player
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

--// Patuloy na pag-update ng Character kapag namatay
Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
end)

--// Settings (Maaari mong baguhin ang lakas dito)
local DASH_SPEED = 800      -- Bilis ng lipad (Taasan kung bitin)
local DASH_DURATION = 1   -- Tagal ng lipad (sa segundo)

--// Variables
local Holding = false
local HoldStart = 0

--========================================================
-- PHYSICS ENGINE: DITO LILIPAD ANG CHARACTER
--========================================================
local function ApplyGlitchDash()
    if not HumanoidRootPart then return end

    -- Gumawa ng Attachment para sa LinearVelocity
    local attachment = HumanoidRootPart:FindFirstChild("DashAttachment")
    if not attachment then
        attachment = Instance.new("Attachment")
        attachment.Name = "DashAttachment"
        attachment.Parent = HumanoidRootPart
    end

    -- Gumawa ng LinearVelocity (Roblox Physics Force)
    local velocity = Instance.new("LinearVelocity")
    velocity.Attachment0 = attachment
    velocity.RelativeTo = Enum.ActuatorRelativeTo.World
    velocity.MaxForce = math.huge

    -- Itulak ang character paharap kung saan nakatingin ang camera/katawan
    velocity.VectorVelocity = HumanoidRootPart.CFrame.LookVector * DASH_SPEED
    velocity.Parent = HumanoidRootPart

    -- Oras ng paglipad bago tanggalin ang pwersa
    task.wait(DASH_DURATION)

    if velocity then velocity:Destroy() end
    if attachment then attachment:Destroy() end
end

--========================================================
-- MOBILE GUI CREATION (Para sa Cellphone)
--========================================================
-- Paggawa ng ScreenGui na hindi nakikita sa normal na Roblox Studio
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DiamondBoosterGui"
ScreenGui.ResetOnSpawn = false
-- Nilalagay sa CoreGui para hindi mawala kahit mamatay ang character
if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
ScreenGui.Parent = CoreGui:FindFirstChild("RobloxGui") or CoreGui

-- Ang Floating Button
local BoostButton = Instance.new("TextButton")
BoostButton.Size = UDim2.new(0, 70, 0, 70)
BoostButton.Position = UDim2.new(0.75, 0, 0.4, 0) -- Posisyon sa screen (Maaari mong i-drag)
BoostButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
BoostButton.Text = "DIAMOND\nBOOST"
BoostButton.TextColor3 = Color3.fromRGB(255, 255, 255)
BoostButton.Font = Enum.Font.SourceSansBold
BoostButton.TextSize = 14
BoostButton.ClipsDescendants = true
BoostButton.Parent = ScreenGui

-- Pabilugin ang edges ng button
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 15)
UICorner.Parent = BoostButton

-- Stroke/Border para maging maganda tingnan
local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 255, 255)
UIStroke.Thickness = 2
UIStroke.Parent = BoostButton

-- Gawing Draggable ang button para maiusog mo kung nakaharang sa UI ng Blox Fruits
local Dragging, DragInput, DragStart, StartPosition
BoostButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        Dragging = true
        DragStart = input.Position
        StartPosition = BoostButton.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then Dragging = false end
        end)
    end
end)
BoostButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        DragInput = input
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == DragInput and Dragging then
        local Delta = input.Position - DragStart
        BoostButton.Position = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
    end
end)

--========================================================
-- DETECT MOVEMENT INPUTS (TOUCH / CLICK)
--========================================================
-- Kapag sinimulan mong i-hold ang button sa screen
BoostButton.MouseButton1Down:Connect(function()
    Holding = true
    BoostButton.BackgroundColor3 = Color3.fromRGB(0, 100, 200) -- Magbabago ng kulay habang naka-hold
    
    -- Dito mo isasabay ang pag-click sa Diamond Z Skill mo sa screen habang naka-hold ito.
end)

-- Kapag binitawan mo na ang button sa screen
BoostButton.MouseButton1Up:Connect(function()
    if Holding then
        Holding = false
        BoostButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255) -- Babalik sa dating kulay
        
        -- Pagbitaw mo, sabay na tatakbo ang physics para lumipad ka pasulong!
        task.spawn(ApplyGlitchDash)
    end
end)
