-- ============================================
-- LUMEXA FPS BOOSTER
-- Optimized for low-end/mobile devices
-- ============================================

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

print("[Lumexa FPS Booster] Starting optimization...")

-- ============================================
-- 1. LIGHTING OPTIMIZATION
-- ============================================
local function optimizeLighting()
    -- Voxel is the lightest lighting engine (vs Future/ShadowMap which are heavy)
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000 -- push fog far away so it doesn't render close
        Lighting.Brightness = 1
    end)

    -- Remove post-processing effects (Blur, Bloom, ColorCorrection, SunRays, DepthOfField)
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("BlurEffect") 
            or effect:IsA("BloomEffect") 
            or effect:IsA("ColorCorrectionEffect") 
            or effect:IsA("SunRaysEffect") 
            or effect:IsA("DepthOfFieldEffect") then
            effect.Enabled = false
        end
    end
end

-- ============================================
-- 2. WORKSPACE / RENDERING OPTIMIZATION
-- ============================================
local function optimizeWorkspace()
    pcall(function()
        Workspace.StreamingEnabled = true -- only load nearby parts (huge FPS help)
    end)

    -- Reduce render distance for meshes/parts far away
    pcall(function()
        settings().Rendering.MeshPartHeadsAndAccessories = false
    end)
end

-- ============================================
-- 3. REMOVE DECORATIVE / UNNECESSARY PARTS
-- ============================================
local function removeDecorations()
    local removedCount = 0
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            -- Remove particle emitters (grass, dust, water splash effects, etc.)
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") then
                obj.Enabled = false
                removedCount = removedCount + 1
            end
            -- Reduce decal/texture quality
            if obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 1
            end
        end)
    end
    print("[Lumexa FPS Booster] Disabled " .. removedCount .. " particle effects")
end

-- ============================================
-- 4. CHARACTER / PLAYER OPTIMIZATION
-- ============================================
local function optimizeCharacters()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            for _, part in pairs(player.Character:GetDescendants()) do
                pcall(function()
                    if part:IsA("ParticleEmitter") or part:IsA("Trail") then
                        part.Enabled = false
                    end
                end)
            end
        end
    end
end

-- ============================================
-- 5. DISABLE UNNECESSARY UI ANIMATIONS
-- ============================================
local function optimizeUI()
    pcall(function()
        StarterGui:SetCore("TopbarEnabled", true) -- keep topbar functional
    end)
end

-- ============================================
-- 6. CONTINUOUS OPTIMIZATION (for newly spawned effects)
-- ============================================
local function startContinuousOptimizer()
    Workspace.DescendantAdded:Connect(function(obj)
        pcall(function()
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") then
                task.wait(0.1) -- let it initialize first
                obj.Enabled = false
            end
        end)
    end)
end

-- ============================================
-- 7. TERRAIN / WATER OPTIMIZATION
-- ============================================
local function optimizeTerrain()
    pcall(function()
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 0.5
            terrain.Decoration = false -- removes grass/rock detail meshes
        end
    end)
end

-- ============================================
-- 8. MESH / TEXTURE SIMPLIFICATION
-- ============================================
local function simplifyMeshesAndTextures()
    local count = 0
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("MeshPart") then
                obj.RenderFidelity = Enum.RenderFidelity.Performance
            end
            if obj:IsA("SurfaceAppearance") then
                obj.Parent = nil -- removes high-detail material textures
                count = count + 1
            end
        end)
    end
    print("[Lumexa FPS Booster] Simplified " .. count .. " surface textures")
end

-- ============================================
-- 9. VIEW DISTANCE / CAMERA OPTIMIZATION
-- ============================================
local function optimizeCamera()
    pcall(function()
        -- Reduce streaming target radius so fewer distant parts load
        Workspace.StreamingTargetRadius = 128
        Workspace.StreamingMinRadius = 64
    end)
end

-- ============================================
-- 10. MEMORY CLEANUP LOOP
-- ============================================
local function startMemoryCleanup()
    task.spawn(function()
        while true do
            task.wait(30) -- every 30 seconds
            collectgarbage("collect")
        end
    end)
end

-- ============================================
-- 11. SKILL / ABILITY EFFECT REMOVAL (maximum aggressive - instant destroy)
-- ============================================
local function removeSkillEffects()
    local count = 0

    local effectClasses = {
        ["ParticleEmitter"] = true,
        ["Trail"] = true,
        ["Smoke"] = true,
        ["Fire"] = true,
        ["Sparkles"] = true,
        ["Beam"] = true,
        ["Explosion"] = true,
        ["Highlight"] = true,
    }

    local function stripEffects(obj)
        pcall(function()
            if effectClasses[obj.ClassName] then
                obj.Enabled = false
                obj:Destroy() -- fully remove, not just disable, so it can't flash on screen
                count = count + 1
            end
        end)
    end

    -- Strip existing effects immediately
    for _, obj in pairs(Workspace:GetDescendants()) do
        stripEffects(obj)
    end

    -- Instant removal on new effects (no wait at all - catches it before first render)
    Workspace.DescendantAdded:Connect(function(obj)
        stripEffects(obj)
    end)

    local Camera = Workspace.CurrentCamera
    if Camera then
        Camera.DescendantAdded:Connect(function(obj)
            stripEffects(obj)
        end)
    end

    -- Some skill VFX spawn as standalone Models directly in Workspace 
    -- (common pattern: "HitEffect", "SkillVFX", "SlashEffect" etc.) with no Humanoid
    Workspace.ChildAdded:Connect(function(obj)
        pcall(function()
            if obj:IsA("Model") and not obj:FindFirstChildOfClass("Humanoid") then
                -- Likely a pure visual effect model (not a player/mob) - strip its effects instantly
                for _, desc in pairs(obj:GetDescendants()) do
                    stripEffects(desc)
                end
            end
        end)
    end)

    print("[Lumexa FPS Booster] Destroyed " .. count .. " skill/ability effects")
end

-- ============================================
-- 12. SOUND / SCREEN SHAKE REDUCTION (skills often trigger these too)
-- ============================================
local function reduceScreenEffects()
    pcall(function()
        for _, obj in pairs(Lighting:GetDescendants()) do
            if obj:IsA("PostEffect") then
                obj.Enabled = false
            end
        end
    end)
end

-- ============================================
-- RUN ALL OPTIMIZATIONS
-- ============================================
optimizeLighting()
optimizeWorkspace()
removeDecorations()
optimizeCharacters()
optimizeUI()
optimizeTerrain()
simplifyMeshesAndTextures()
optimizeCamera()
removeSkillEffects()
reduceScreenEffects()
startMemoryCleanup()
startContinuousOptimizer()
