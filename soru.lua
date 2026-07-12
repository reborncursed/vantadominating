--// Blox Fruits Target Lock & Soru Dash (Mobile Optimized)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

--========================================================
-- TARGET SCANNER (Naghahanap ng pinakamalapit na Player)
--========================================================
local function getNearestPlayer()
    local nearestPlayer = nil
    local shortestDistance = 250 -- Max range ng Flash Step mo (sa studs)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            -- Siguraduhing buhay ang kalaban at wala siya sa Safe Zone (walang Highlight)
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
-- FLASH STEP EXECUTION (Anti-Cheat Safe Tween)
--========================================================
local function FlashStepToPlayer()
    local target = getNearestPlayer()
    if target and target.Character and LocalPlayer.Character then
        local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
        
        if myRoot and targetRoot then
            -- POSISYON: Saktong 3 studs sa harap ng mukha ng kalaban
            local targetCFrame = targetRoot.CFrame * CFrame.new(0, 0, -3)
            -- AUTO-AIM: Ppiikutin ang katawan mo para nakaharap ka agad sa kanya pagdating mo
            local finalCFrame = CFrame.lookAt(targetCFrame.Position, targetRoot.Position)
            
            -- TWEEN MATH: Kinakalkula ang bilis para hindi ma-detect ng anti-cheat
            local distance = (myRoot.Position - targetRoot.Position).Magnitude
            local tweenSpeed = 400 -- Bilis ng lipad (studs per second)
            local duration = distance / tweenSpeed
            
            local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(myRoot, tweenInfo, {CFrame = finalCFrame})
            
            -- I-reset ang velocity para hindi humampas sa sahig habang gumagalaw
            myRoot.Velocity = Vector3.new(0,0,0)
            
            -- Isagawa ang Flash Step
            tween:Play()
            tween.Completed:Wait() -- Hihintayin makarating bago pwedeng mag-click ng skills
        end
    end
end

--========================================================
-- EXECUTION TRIGGER
--========================================================
-- Patakbuhin ang function na ito kapag gusto mo nang mag-Flash Step sa player
FlashStepToPlayer()
