--// Horizontal Stretched Screen Resolution (Client-Side Only)
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CurrentCamera = Workspace.CurrentCamera

--// Settings (Maaari mong baguhin ang stretch base sa panlasa mo)
local STRETCH_FACTOR = 1.35 -- Taasan mo ito kung gusto mo pang mas MALAPAD (e.g., 1.5 o 1.7)
local BASE_FOV = 70         -- Ang default FOV ng Roblox

--========================================================
-- STRETCH ENGINE
--========================================================
local function ApplyHorizontalStretch()
    if CurrentCamera then
        -- Binabago ang FOV nang dynamic para magmukhang compressed/stretched ang screen
        CurrentCamera.FieldOfView = BASE_FOV * STRETCH_FACTOR
        
        -- Pinipwersa ang Camera CFrame Matrix na mag-scale nang pa-horizontal
        -- Tandaan: Sa mobile executors, kailangan itong i-update bawat frame
        local currentCFrame = CurrentCamera.CFrame
        local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = currentCFrame:GetComponents()
        
        -- Nilalaparan ang X-axis matrix para sa horizontal stretch effect
        CurrentCamera.CFrame = CFrame.new(x, y, z, r00 * STRETCH_FACTOR, r01, r02, r10, r11, r12, r20, r21, r22)
    end
end

-- Patuloy na pinapatakbo bawat frame para hindi bumalik sa normal kapag ginalaw ang camera
local StretchConnection = RunService.RenderStepped:Connect(ApplyHorizontalStretch)

--========================================================
-- ANTICHAT / RESET BYPASS
--========================================================
-- Sinisigurado na kapag namatay ang character o nagpalit ng Sea, mananatili ang stretch screen
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    CurrentCamera = Workspace.CurrentCamera
end)
