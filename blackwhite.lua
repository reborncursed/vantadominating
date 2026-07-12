--// Black & White Noir Skill Visuals (Client-Side Only)
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

--// Settings
local FLASH_SPEED = 2 -- Bilis ng pagpapalit ng Itim at Puti. (Gawing 0 kung gusto mo static Black lang lahat)
local FIXED_BLACK = false -- Gawing 'true' kung ayaw mong mag-flash at gusto mo purong ITIM lang lahat.

--========================================================
-- BLACK & WHITE COLOR GENERATOR
--========================================================
local function getNoirColor()
    if FIXED_BLACK then
        return Color3.fromRGB(0, 0, 0) -- Purong Itim
    end
    
    -- Gumagamit ng Sine Wave para maging smooth ang pagpapalit mula Itim patungong Puti
    local wave = (math.sin(tick() * FLASH_SPEED) + 1) / 2 -- Nagbibigay ng value mula 0 hanggang 1
    
    if wave > 0.5 then
        return Color3.fromRGB(0, 0, 0) -- Itim / Shadow
    else
        return Color3.fromRGB(255, 255, 255) -- Puti / Light
    end
end

--========================================================
-- COLOR APPLIER
--========================================================
local function applyNoir(object)
    -- Kung ang skill ay isang normal na Part o MeshPart
    if object:IsA("BasePart") then
        RunService.RenderStepped:Connect(function()
            if object and object.Parent then
                object.Color = getNoirColor()
                -- Opsyonal: Gawing medyo neon o kumikinang ang puti
                if object.Color == Color3.fromRGB(255, 255, 255) then
                    object.Material = Enum.Material.Neon
                else
                    object.Material = Enum.Material.Glass
                end
            end
        end)
    
    -- Kung ang skill ay gumagamit ng Particle Emitters (Usok, kislap, aura)
    elseif object:IsA("ParticleEmitter") then
        RunService.RenderStepped:Connect(function()
            if object and object.Parent then
                local currentColor = getNoirColor()
                object.Color = ColorSequence.new(currentColor)
            end
        end)
        
    -- Kung ang skill ay Trail o Beam (yung mga guhit kapag humahampas ang sword)
    elseif object:IsA("Trail") or object:IsA("Beam") then
        RunService.RenderStepped:Connect(function()
            if object and object.Parent then
                local currentColor = getNoirColor()
                object.Color = ColorSequence.new(currentColor)
            end
        end)
    end
end

--========================================================
-- WORKSPACE WATCHER (Dito binabantayan ang mga skills)
--========================================================
Workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or descendant:IsA("Beam") then
        applyNoir(descendant)
    elseif descendant:IsA("BasePart") and (descendant.Name:lower():find("effect") or descendant.Name:lower():find("skill") or descendant.Name:lower():find("slash")) then
        applyNoir(descendant)
    end
end)

-- I-scan din ang mga kasalukuyang effects na nasa laro na pagka-execute mo
for _, descendant in pairs(Workspace:GetDescendants()) do
    if descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or descendant:IsA("Beam") then
        applyNoir(descendant)
    end
end
