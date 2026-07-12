--// Rainbow Skill Visuals (Client-Side Only)
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

--// Settings
local RAINBOW_SPEED = 1 -- Taasan kung gusto mo mas mabilis magpalit ng kulay ang rainbow

--========================================================
-- RAINBOW COLOR GENERATOR
--========================================================
-- Nagbibigay ng pabago-bagong kulay base sa oras
local function getRainbowColor()
    local hue = (tick() * RAINBOW_SPEED) % 1
    return Color3.fromHSV(hue, 1, 1)
end

--========================================================
-- COLOR APPLIER
--========================================================
-- Tinitingnan kung anong klaseng object ang visual effect at binabago ang kulay nito
local function applyRainbow(object)
    -- Kung ang skill ay isang normal na Part o MeshPart
    if object:IsA("BasePart") then
        RunService.RenderStepped:Connect(function()
            if object and object.Parent then
                object.Color = getRainbowColor()
            end
        end)
    
    -- Kung ang skill ay gumagamit ng Particle Emitters (Usok, kislap, aura)
    elseif object:IsA("ParticleEmitter") then
        RunService.RenderStepped:Connect(function()
            if object and object.Parent then
                -- Ang ParticleEmitter ay gumagamit ng ColorSequence
                local currentColor = getRainbowColor()
                object.Color = ColorSequence.new(currentColor)
            end
        end)
        
    -- Kung ang skill ay Trail o Beam (yung mga guhit kapag humahampas)
    elseif object:IsA("Trail") or object:IsA("Beam") then
        RunService.RenderStepped:Connect(function()
            if object and object.Parent then
                local currentColor = getRainbowColor()
                object.Color = ColorSequence.new(currentColor)
            end
        end)
    end
end

--========================================================
-- WORKSPACE WATCHER (Dito binabantayan ang mga skills)
--========================================================
-- Kapag nag-skill ka o may lumabas na effect sa laro, automatic nitong kukunin
Workspace.DescendantAdded:Connect(function(descendant)
    -- Para masiguradong mga effects lang ang nagiging rainbow, pwede nating i-filter.
    -- Karamihan ng skills sa Blox Fruits ay gumagamit ng ParticleEmitters, Trails, o MeshParts.
    if descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or descendant:IsA("Beam") then
        applyRainbow(descendant)
    elseif descendant:IsA("BasePart") and (descendant.Name:lower():find("effect") or descendant.Name:lower():find("skill") or descendant.Name:lower():find("slash")) then
        -- Kung part siya at may pangalang "effect" o "skill", gagawin din itong rainbow
        applyRainbow(descendant)
    end
end)

-- I-scan din ang mga kasalukuyang effects na nasa laro na pagka-execute mo
for _, descendant in pairs(Workspace:GetDescendants()) do
    if descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or descendant:IsA("Beam") then
        applyRainbow(descendant)
    end
end
