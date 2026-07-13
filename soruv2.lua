--// Blox Fruits Instant Target Soru & Infinite Radius (Mobile Optimized)
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

--// Settings (Upgraded Config)
local SORU_RADIUS = 1000     -- NAPAKALAWAK NA RADIUS! (Halos buong isla/mapa)
local ATTACK_DURATION = 1.5 -- Gaano katagal mag-o-auto-click pagkadikit sa kalaban (sa segundo)

--========================================================
-- AUTO CLICK / WEAPON AUTO-EQUIP
--========================================================
local function StartAutoClick()
    local backpack = LocalPlayer:WaitForChild("Backpack")
    local character = LocalPlayer.Character
    
    if character then
        -- Awtomatikong isusuot ang iyong Fighting Style o Sword na nasa Slot 1
        local melee = backpack:FindFirstChildOfClass("Tool")
        if melee then
            melee.Parent = character
        end
    end

    -- Mabilis na pag-click ng M1 para pumasok ang damage sa server
    local endTime = tick() + ATTACK_DURATION
    task.spawn(function()
        while tick() < endTime do
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(0, 0))
            task.wait(0.03) -- Pinakamabilis na click rate para sa instant hits
        end
    end)
end

--========================================================
-- TARGET SCANNER (Nearest Player within 1,000 Studs)
--========================================================
local function getNearestPlayerInRadius()
    local nearestPlayer = nil
    local shortestDistance = SORU_RADIUS

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            -- Siguraduhing buhay ang player at wala sa Safe Zone (Walang Highlight)
            if humanoid and humanoid.Health > 0 and not player.Character:FindFirstChild("Highlight") then 
                local distance = (LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestPlayer = player
                end
            end
        end
    end
    return nearestPlayer
end

--========================================================
-- INSTANT FLASH STEP EXECUTION (Anti-Cheat Bypass)
--========================================================
local function ExecuteInstantSoru()
    local target = getNearestPlayerInRadius()
    
    if not target then
        print("Walang player sa loob ng 1000 studs radius.")
        return
    end

    if target.Character and LocalPlayer.Character then
        local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
        local myHumanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        
        if myRoot and targetRoot and myHumanoid then
            -- POSITION MATH: Saktong 2.5 studs sa harap ng target at auto-face aim lock
            local targetCFrame = targetRoot.CFrame * CFrame.new(0, 0, -2.5)
            local finalCFrame = CFrame.lookAt(targetCFrame.Position, targetRoot.Position)
            
            -- ANTI-CHEAT BYPASS: Sandaling i-disable ang humanoid states para hindi ma-detect ang instant teleport
            myHumanoid:ChangeState(Enum.HumanoidStateType.Physics)
            myRoot.Velocity = Vector3.new(0, 0, 0)
            myRoot.AssemblyVelocity = Vector3.new(0, 0, 0)
            
            -- INSTANT BLINK: Walang lipad, maglalaho ka at lilitaw agad sa mukha niya
            myRoot.CFrame = finalCFrame
            
            -- ISABAY AGAD ANG AUTO-ATTACK
            task.spawn(StartAutoClick)
            
            -- I-reset ang physics state pagkalipas ng micro-delay para makagalaw ka ulit nang normal
            task.wait(0.05)
            myHumanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
    end
end

--========================================================
-- MOBILE FLOATING GUI BUTTON (Draggable)
--========================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "InstantSoruGui"
ScreenGui.ResetOnSpawn = false
if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
ScreenGui.Parent = CoreGui:FindFirstChild("RobloxGui") or CoreGui

local SoruButton = Instance.new("TextButton")
SoruButton.Size = UDim2.new(0, 85, 0, 85)
SoruButton.Position = UDim2.new(0.8, 0, 0.3, 0)
SoruButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0) -- Kulay Orange para sa Instant Blink Mode
SoruButton.Text = "INSTANT\nSORU"
SoruButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SoruButton.Font = Enum.Font.SourceSansBold
SoruButton.TextSize = 14
SoruButton.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 20)
UICorner.Parent = SoruButton

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 255, 255)
UIStroke.Thickness = 2
UIStroke.Parent = SoruButton

-- DRAG SYSTEM FOR MOBILE SCREEN
local Dragging, DragInput, DragStart, StartPosition
SoruButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        Dragging = true
        DragStart = input.Position
        StartPosition = SoruButton.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then Dragging = false end
        end)
    end
end)
SoruButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        DragInput = input
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == DragInput and Dragging then
        local Delta = input.Position - DragStart
        SoruButton.Position = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
    end
end)

SoruButton.MouseButton1Click:Connect(function()
    ExecuteInstantSoru()
end)
