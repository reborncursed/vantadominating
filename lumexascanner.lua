-- lumexa
-- Config Logger DetectionConfidence ObjectDatabase ChangeDetector InspectorSearch ObjectInspection HierarchyScanner InspectorScanner InspectorReport InspectorEngine SnapshotEngine LiveChangeDetector NPCIntelligence BossIntelligence IslandIntelligence EventIntelligence EnvironmentIntelligence StatisticsEngine HistoryEngine AlertEngine ExportEngine TimelineEngine RuntimeMonitor Utilities Status WorkspaceDetector SeaManager BossManager Cache WebhookConfig Webhook VerificationEngine BossDetector LightingDetector SeaEventDetector WorkspaceInspector ScannerCore ServerHop UI main

-- Config
local Config = (function()
-- config

local Config = {}

Config.Version = "1.0.0"

-- General
Config.General = {
    AutoStart = true,
    DebugMode = false,
}

-- Scanner
Config.Scanner = {
    Interval = 1, -- seconds between scans
    MaxDistance = 500,
    -- Maps PlaceId -> sea/world name, e.g. [111111] = "First Sea".
    -- Left empty on purpose: Lumexa does not assume any game's IDs.
    SeaMap = {},
    ContainerPath = nil,
}

Config.Detection = {
    -- Nothing dispatches to a webhook below this confidence score.
    -- See ARCHITECTURE.md §7 for the score table.
    MinConfidence = 90,

    -- Container Workspace.Enemies is confirmed from real Blox Fruits
    -- script source. Boss detection watches this folder's ChildAdded.
    EnemiesContainerPath = "Enemies",

    LocationsContainerPath = "_WorldOrigin.Locations",

    FallbackSweepEnabled = true,
    FallbackSweepIntervalSeconds = 30,

    VerboseDecisionLog = true,
}

-- [verify] = not confirmed against a live client, see ARCHITECTURE.md
Config.SeaEvents = {
    FactoryRaid = {
        Enabled = false, -- off by default until [verify] fields are filled in
        LocationName = "Factory", -- [verify]
        ActiveAttributeName = nil,
    },
    MirageIsland = {
        Enabled = false,
        LocationName = "Mirage Island", -- [verify]
    },
    Leviathan = {
        Enabled = false,
        -- Exact Model/identifier name — must NOT match the regular
        -- Sea Beast. [verify]
        ModelName = "Leviathan",
    },
    PrehistoricIsland = {
        Enabled = false,
        LocationName = "Prehistoric Island", -- [verify]
    },
    ElitePirates = {
        Enabled = false,
        ModelName = "Elite Pirates", -- [verify]
    },
    FullMoon = {
        Enabled = true, -- Lighting-based, no [verify] object names needed
        -- Only ever dispatches while SeaManager reports Third Sea —
        -- hard gate, see ARCHITECTURE.md §6, not a confidence penalty.
        RequiredSea = "Third Sea",
        StateAttributeName = nil,
        -- Fallback heuristic if no Attribute is found: ClockTime range
        -- treated as "night" for a lighting-only (70%) detection.
        ClockTimeRangeStart = 0,
        ClockTimeRangeEnd = 6,
    },

    CastleRaid = {
        Enabled = false,
        LocationName = "Castle", -- [verify]
        ActiveAttributeName = nil, -- [verify]
    },
    KitsuneShrine = {
        Enabled = false,
        LocationName = "Kitsune Shrine", -- [verify]
    },
    SeaBeast = {
        Enabled = false,
        ModelName = "Sea Beast", -- [verify]
    },
    TerrorShark = {
        Enabled = false,
        ModelName = "Terror Shark", -- [verify]
    },
    GhostShip = {
        Enabled = false,
        ModelName = "Ghost Ship", -- [verify]
    },
    PirateRaid = {
        Enabled = false,
        LocationName = "Pirate Raid", -- [verify]
        ActiveAttributeName = nil, -- [verify]
    },
}

-- BossManager
Config.BossManager = {
    Enabled = true,
    AutoFarm = false,
    TargetBosses = {
        -- First Sea
        "Saber", "Mob Leader", "Vice Admiral", "Warden", "Chief Warden",
        "Swan", "Magma Admiral", "Fishman Lord", "Wysper", "Thunder God", "Cyborg",
        -- Second Sea
        "Don Swan", "Darkbeard", "Cursed Captain", "Ice Admiral",
        "Awakened Ice Admiral", "Smoke Admiral", "Tide Keeper", "Factory",
        -- Third Sea
        "Rip Indra", "Dough King", "Cake Prince", "Soul Reaper", "Full Moon",
        "Mirage Island", "Leviathan", "Prehistoric Island",
    },
}

Config.Inspector = {
    -- How many levels deep to walk under each root container. Bounded
    -- on purpose — see INSPECTOR_ENGINE.md §2.
    MaxDepth = 4,
    MinReportConfidence = 50,
}

Config.Intelligence = {
    Enabled = true,
    BatchSize = 25,
    FullSweepIntervalSeconds = 60,
    -- How often the discovered-object database is persisted to file.
    SaveIntervalSeconds = 120,
    MaxLiveChangeEvents = 200,
    -- Stage 3: NPCIntelligence / BossIntelligence
    -- Instances refreshed per frame-spread tick for live position/health.
    NPCBatchSize = 20,
    -- Grace period before a disappeared NPC is pruned from tracking —
    -- avoids treating a temporary stream-out as permanent.
    NPCPruneAfterSeconds = 60,
    BossTickIntervalSeconds = 2,
    -- Stage 4: IslandIntelligence / EventIntelligence
    IslandTickIntervalSeconds = 5,
    IslandGoneGraceSeconds = 30,
    EventTickIntervalSeconds = 5,
    -- Stage 5: EnvironmentIntelligence
    EnvironmentTickIntervalSeconds = 10,
    -- Stage 6: StatisticsEngine / HistoryEngine
    StatisticsTickIntervalSeconds = 15,
    HistoryTickIntervalSeconds = 20,
    AlertTickIntervalSeconds = 5,
}

-- timeline engine. MaxEntries resolves "should only grow" vs "memory
-- leaks unacceptable" with a generous non-infinite cap, see
-- TIMELINE_ENGINE.md
Config.Timeline = {
    MaxEntries = 5000,
    PollIntervalSeconds = 2,
    SaveIntervalSeconds = 60,
    AutoExportIntervalSeconds = 300,
}

Config.Environment = {
    DayStartClockTime = 6,
    DayEndClockTime = 18,
    WeatherAttributeName = nil, -- [verify]
}

-- SeaManager
Config.SeaManager = {
    Enabled = false,
    PreferredSea = nil, -- set by user, no default assumption
}

-- ServerHop
Config.ServerHop = {
    Enabled = true,
    MinPlayers = 0,
    MaxPlayers = 100,
    HopDelay = 5,
    MaxTeleportRetries = 3,
    TeleportRetryDelaySeconds = 3,
    MaxPagesToScan = 25,
}

Config.Cache = {
    LifetimeSeconds = 3600, -- 1 hour
    SweepIntervalSeconds = 300, -- how often expiry sweeps run
}
-- IMPORTANT: never hardcode a webhook URL in source.
-- URLs must be supplied by the user at runtime and kept out of version control.
Config.Webhook = {
    URL = nil, -- legacy single-URL fallback, used if a keyed webhook isn't found
    Enabled = true,
    RateLimitSeconds = 3,
    MaxRetries = 3,
    RetryDelaySeconds = 5,
    QueueIntervalSeconds = 1, -- how often the sequential queue processor ticks
    TimeoutSeconds = 10, -- max time to wait for a single send before treating it as failed
}

Config.Webhooks = {
    -- First Sea
    ["Saber"] = "https://discord.com/api/webhooks/1526217983955964035/iCtcIdMQMz85ESM8LNDbTX7Fvc2Orz11WlZNXgHYA4dxak7HJnOHOdp1twSEODCnLL3R",
    ["Mob Leader"] = "https://discord.com/api/webhooks/1526218493802844224/yqwnzESm2R834siG5SV_i8wGtEt6r5X2SGTcPtz1PALhvjPvo70Zvv5-HKr67DxJI0i2",
    ["Vice Admiral"] = "https://discord.com/api/webhooks/1526218749613703178/cbdjBQrKDbBFR2TzwK8qZByXoi9_LJmMlsdUzYUVOTLPvIUXRH06RPsW5MQ8RDhDzF00",
    ["Warden"] = "https://discord.com/api/webhooks/1526218997165719725/7lc5DRWZvB-fDpPEUOchw1dJFI3Ljwf4jCA0VyUFHLzGGMcty_Akn9lIH6QaUhV-a8BO",
    ["Chief Warden"] = "https://discord.com/api/webhooks/1526219204225925141/crCpEZtjyeOp0Hk3XgXIx73l4kRRj8e0gdaFHRsjxBu4onNhtAbqBefunwKkdoZ3xsUT",
    ["Swan"] = "https://discord.com/api/webhooks/1526219414859415562/lB3cLg1GhIw2-4WGIaZ6mr1H4t-03rqG_2Sjrx2LpSabxiBPmZ6ama2E1olQIJnnGeNx",
    ["Magma Admiral"] = "https://discord.com/api/webhooks/1526219645806182441/it_io3UHDHx38cexAEVnY0R_kQ5vLhEmyb5N_LoLy3SQlDvic6G8fIUqYAXELfucfqdA",
    ["Fishman Lord"] = "https://discord.com/api/webhooks/1526220031472439388/fAZwSSjPmzYuwfPz8G9O8UMyyAVzJWQbSTtcnhfN5zWEIj_-LjEBJKY1yf1Va9-1tHuK",
    ["Wysper"] = "https://discord.com/api/webhooks/1526220632600084502/3e_stvc2VL0jaK596owVVolOE7nIR-l_M7Hyw84gdCen5bdigyzkXwmcnxQEKBeHShM5",
    ["Thunder God"] = "https://discord.com/api/webhooks/1526220257079853248/WWvNKim3R7i8qmRQhM5ecu5LbLGehRIky4LQCa602WDnZMOT3C0TPzgK2cLEyb_OX2Mp",
    ["Cyborg"] = "https://discord.com/api/webhooks/1526220360712847613/8Qqzs5AEVui-fccq5d0OH0P4RCvEpmcfWLHSfiLyu9TUzZfHELnHMmMC0zrBmUX4e0PJ",

    -- Second Sea
    ["Don Swan"] = "https://discord.com/api/webhooks/1526221514209234994/aIfy2RVBOK8HiJBQGPCohBC_x6cWtbCe0lKK8EYycvHIGbFWqty5r4YFj4aeYzlFQlFw",
    ["Darkbeard"] = "https://discord.com/api/webhooks/1526221663195103352/AU9KHkzpkB19VNkaATQFO6Ub_dk3pCyp7TIRluxAtHDEMEYuS4gpWMTGDT23wDKRs84E",
    ["Cursed Captain"] = "https://discord.com/api/webhooks/1526221849690640567/WrwXS6UHA_68HkP5a7sqUcKqvV3Xz18Bq1YvTP59wRc9agmTNXBzpfVXgzLS6P7rX3ml",
    ["Ice Admiral"] = "https://discord.com/api/webhooks/1526222037063045192/QU6ns0KHDpYJJqSgc75jcTGdGeUr2eBvrtI9s4Fv_SwrZHGhRlCf8XZDKf7RXqyobKXR",
    ["Awakened Ice Admiral"] = "https://discord.com/api/webhooks/1526222594636775524/eM2vFJ39aWq9PXZiX2gAGgVNCjnD_Bnps5y4HeVomYpmENtdTktdaALWEgKZr6DXMxy9",
    ["Smoke Admiral"] = "https://discord.com/api/webhooks/1526222770235641939/rCS5rULFm2-6anUC-yvP6pWYlf16s23euySTQkJMyJOpKEyRmFCq99Jou3M1PGxZk6x6",
    ["Tide Keeper"] = "https://discord.com/api/webhooks/1526222979657105518/CLt98Kc4_3uwz9cIJ9f0xU2vFEUthM7NHEz2hOjQgvJjXuxPhLMJ8IEFnWbwXNT8S1oQ",
    ["Factory"] = "https://discord.com/api/webhooks/1526223531933827203/HPgstrfSLP5c_QbtMdv7_Q3C4XJ2nyTOK4V_jNpVeSIg6lKOXfO9zdci6enL2MpLMXwZ",

    -- Third Sea
    ["Rip Indra"] = "https://discord.com/api/webhooks/1526224132373479434/B3nd-S8FMW0lxwz3QRK_4bfIO30ntsAXlsn8OqKcDC7hs--Ycr0OyBv48Jw16jGxWsO7",
    ["Dough King"] = "https://discord.com/api/webhooks/1526224346505547958/25SoFkdauUsCSjOCP3rXXdK8r7PgDaDKbif7lXm4HKB_36EWbifErvBgN0BrcH7dQF7p",
    ["Cake Prince"] = "https://discord.com/api/webhooks/1526224517066653871/v6RGeHU34HeXq2QrWjXlMu9PygmoJG-JfQZneuLO9MBcmyKnYCpX6Y7yfmx3MBmhizir",
    ["Soul Reaper"] = "https://discord.com/api/webhooks/1526224761653297365/PYFVpNJSC5n-ZwmBgo78gz2nKuhcZrYa4OE_6wxISgEwKQHeKybxOouI_41o3eX7v5XK",
    ["Full Moon"] = "https://discord.com/api/webhooks/1526224892549267466/bR4lkxxqqddWW09lps3cEqf1thrpTObG6AhIdJ1i7uJieL_PIznlHJwxeznBGzw4jAFh",
    ["Mirage Island"] = "https://discord.com/api/webhooks/1526225146812174498/s0f0JoNYtYfVHwpzk1SMPqoHR4b0mAKGOko5tkmyId3PpqAeUcSzIMawoNjgDeEN40Hq",
    ["Leviathan"] = "https://discord.com/api/webhooks/1526225449498312828/nxJpggN76Vup4BhI7MR7HpOOvPLcP7v3G9rmE7hnPPZ1mo_M8Aky-ohQ77yO-29Z0bvu",
    ["Prehistoric Island"] = "https://discord.com/api/webhooks/1526225700170760232/3zb-0jPBsMXFRCyS7nPLOSr37nd0elvXsyfIKPgmaxUPvDr6oSS5eoGa_5wR_oyCSvz2",
    ["Legendary Dealer"] = "https://discord.com/api/webhooks/1527615394637156353/Sd8j0We8LBdrmyxTZE_iZFAxqoIIUZl8UgKZZ8F2HhdJEJ2Ka_P9voMHpjPzPuh108k4",
}

-- Logger
Config.Logger = {
    Enabled = true,
    MaxLines = 200,
    PrintToConsole = true,
}

-- Internal state (not user-editable via UI)
Config._runtime = {
    Loaded = false,
    Started = false,
    StartTime = nil,
    AccumulatedUptime = 0,
}

function Config.SetRunning(isRunning)
    local now = os.clock()
    if isRunning and not Config._runtime.Started then
        Config._runtime.Started = true
        Config._runtime.StartTime = now
    elseif not isRunning and Config._runtime.Started then
        Config._runtime.AccumulatedUptime = Config._runtime.AccumulatedUptime
            + (now - (Config._runtime.StartTime or now))
        Config._runtime.Started = false
        Config._runtime.StartTime = nil
    end
end

--- Total seconds the framework has been running, across start/stop
--- cycles. Freezes while stopped rather than continuing to climb.
function Config.GetUptime()
    if Config._runtime.Started and Config._runtime.StartTime then
        return Config._runtime.AccumulatedUptime + (os.clock() - Config._runtime.StartTime)
    end
    return Config._runtime.AccumulatedUptime
end

function Config.GetStatus()
    return Config._runtime.Started and "Running" or "Stopped"
end

--- Safely set a nested config value using dot path, e.g. "Scanner.Interval"
function Config.Set(path, value)
    local keys = {}
    for key in string.gmatch(path, "[^%.]+") do
        table.insert(keys, key)
    end

    local node = Config
    for i = 1, #keys - 1 do
        node = node[keys[i]]
        if type(node) ~= "table" then
            return false, "Invalid config path: " .. path
        end
    end

    local lastKey = keys[#keys]
    if node[lastKey] == nil and node ~= Config then
        return false, "Unknown config key: " .. path
    end

    node[lastKey] = value
    return true
end

--- Safely get a nested config value using dot path
function Config.Get(path)
    local keys = {}
    for key in string.gmatch(path, "[^%.]+") do
        table.insert(keys, key)
    end

    local node = Config
    for _, key in ipairs(keys) do
        if type(node) ~= "table" then
            return nil
        end
        node = node[key]
    end

    return node
end

Config._runtime.Loaded = true

return Config
end)()

-- Logger
local Logger = (function()
-- logger


local Logger = {}

Logger._buffer = {} -- in-memory ring buffer of log lines
Logger._listeners = {} -- optional callbacks, e.g. to feed the UI

local LEVELS = {
    INFO = "INFO",
    WARN = "WARN",
    ERROR = "ERROR",
    SUCCESS = "SUCCESS",
    DEBUG = "DEBUG",
}
Logger.Levels = LEVELS

local function timestamp()
    local ok, result = pcall(function()
        return os.date("%H:%M:%S")
    end)
    return ok and result or "??:??:??"
end

local function pushToBuffer(line)
    table.insert(Logger._buffer, line)
    local maxLines = Config.Get("Logger.MaxLines") or 200
    if #Logger._buffer > maxLines then
        table.remove(Logger._buffer, 1)
    end
end

local function notifyListeners(entry)
    for _, listener in ipairs(Logger._listeners) do
        pcall(listener, entry)
    end
end

--- Core log function. Never throws.
function Logger.Log(level, module, message)
    if not Config.Get("Logger.Enabled") then
        return
    end

    level = level or LEVELS.INFO
    module = module or "Unknown"
    message = message or ""

    local line = string.format("[%s] [%s] [%s] %s", timestamp(), level, module, tostring(message))

    pcall(pushToBuffer, line)

    if Config.Get("Logger.PrintToConsole") then
        pcall(print, line)
    end

    pcall(notifyListeners, {
        level = level,
        module = module,
        message = message,
        line = line,
        time = timestamp(),
    })
end

function Logger.Info(module, message)
    Logger.Log(LEVELS.INFO, module, message)
end

function Logger.Warn(module, message)
    Logger.Log(LEVELS.WARN, module, message)
end

function Logger.Error(module, message)
    Logger.Log(LEVELS.ERROR, module, message)
end

function Logger.Success(module, message)
    Logger.Log(LEVELS.SUCCESS, module, message)
end

function Logger.Debug(module, message)
    if Config.Get("General.DebugMode") then
        Logger.Log(LEVELS.DEBUG, module, message)
    end
end

--- Subscribe to new log entries (e.g. UI module hooks in here)
function Logger.Subscribe(callback)
    if type(callback) ~= "function" then
        return false, "Listener must be a function"
    end
    table.insert(Logger._listeners, callback)
    return true
end

function Logger.Unsubscribe(callback)
    for i, existing in ipairs(Logger._listeners) do
        if existing == callback then
            table.remove(Logger._listeners, i)
            return true
        end
    end
    return false
end

--- Get a copy of the current log buffer
function Logger.GetBuffer()
    local copy = {}
    for i, line in ipairs(Logger._buffer) do
        copy[i] = line
    end
    return copy
end

function Logger.Clear()
    Logger._buffer = {}
end

return Logger
end)()

-- DetectionConfidence
local DetectionConfidence = (function()
-- confidence scoring


local DetectionConfidence = {}

local DEFAULT_WEIGHTS = {
    BOSS_MODEL = 40,        -- confirmed Model instance matching target name
    HUMANOID_ALIVE = 20,    -- Model has a live Humanoid (not just a name match)
    UNIQUE_OBJECT = 35,     -- confirmed unique event Instance (Leviathan, Mirage, etc.)
    MAP_OBJECT = 20,        -- required map/location object present
    ATTRIBUTE_MATCH = 15,   -- a specific Attribute value matched
    TAG_MATCH = 15,         -- CollectionService tag present
    REMOTE_FIRED = 25,      -- a client-facing RemoteEvent fired for this event
    LIGHTING_MATCH = 10,    -- Lighting property/Attribute matched
    PARTICLE_PRESENT = 5,   -- particle/sound effect present (weakest signal)
}

local weights = {}
for name, weight in pairs(DEFAULT_WEIGHTS) do
    weights[name] = weight
end

function DetectionConfidence.RegisterSignal(name, weight)
    if type(name) ~= "string" or type(weight) ~= "number" then
        return false, "RegisterSignal requires (string name, number weight)"
    end
    weights[name] = weight
    return true
end

function DetectionConfidence.GetWeight(name)
    return weights[name]
end

function DetectionConfidence.Calculate(signals)
    if type(signals) ~= "table" then
        return 0
    end

    local total = 0
    for _, signalName in ipairs(signals) do
        local weight = weights[signalName]
        if weight then
            total = total + weight
        else
            Logger.Debug("DetectionConfidence", "Unknown signal ignored: " .. tostring(signalName))
        end
    end

    if total > 100 then
        total = 100
    end

    return total
end

function DetectionConfidence.Explain(signals)
    if type(signals) ~= "table" then
        return 0, "(no signals provided)"
    end

    local total = 0
    local parts = {}

    for _, signalName in ipairs(signals) do
        local weight = weights[signalName]
        if weight then
            total = total + weight
            table.insert(parts, signalName .. "(+" .. weight .. ")")
        else
            table.insert(parts, signalName .. "(unknown, ignored)")
        end
    end

    local capped = math.min(total, 100)
    local breakdown = table.concat(parts, " + ") .. " = " .. total .. "%"
    if capped ~= total then
        breakdown = breakdown .. " (capped at 100%)"
    end

    return capped, breakdown
end

return DetectionConfidence
end)()

-- ObjectDatabase
local ObjectDatabase = (function()
-- object db


local ObjectDatabase = {}

ObjectDatabase._records = {} -- fullPath -> record
ObjectDatabase._scanVersion = 0

local DB_FILE = "Lumexa_InspectorDB.txt"

function ObjectDatabase.Get(fullPath)
    return ObjectDatabase._records[fullPath]
end

function ObjectDatabase.Set(fullPath, record)
    ObjectDatabase._records[fullPath] = record
end

function ObjectDatabase.Delete(fullPath)
    ObjectDatabase._records[fullPath] = nil
end

function ObjectDatabase.All()
    return ObjectDatabase._records
end

function ObjectDatabase.Count()
    local n = 0
    for _ in pairs(ObjectDatabase._records) do n = n + 1 end
    return n
end

function ObjectDatabase.Clear()
    ObjectDatabase._records = {}
end

function ObjectDatabase.GetScanVersion()
    return ObjectDatabase._scanVersion
end

function ObjectDatabase.Snapshot()
    local copy = {}
    for path, record in pairs(ObjectDatabase._records) do
        local recordCopy = {}
        for k, v in pairs(record) do
            if type(v) == "table" then
                local nested = {}
                for nk, nv in pairs(v) do nested[nk] = nv end
                recordCopy[k] = nested
            else
                recordCopy[k] = v
            end
        end
        copy[path] = recordCopy
    end
    return copy
end

--- Replaces the current records with a given snapshot (used when
--- loading a persisted database from file).
function ObjectDatabase.LoadSnapshot(snapshot, scanVersion)
    ObjectDatabase._records = snapshot or {}
    ObjectDatabase._scanVersion = scanVersion or 0
end

-- Persistence (survives script restarts / server hops, same pattern
-- used elsewhere in the project for counters — see Webhook.lua)

local function serializeRecord(record)
    local attrParts = {}
    for k, v in pairs(record.attributes or {}) do
        table.insert(attrParts, k .. "=" .. tostring(v))
    end
    table.sort(attrParts)

    local tagParts = {}
    for _, t in ipairs(record.tags or {}) do
        table.insert(tagParts, t)
    end
    table.sort(tagParts)

    return table.concat({
        record.name or "",
        record.className or "",
        record.fullPath or "",
        record.parentPath or "",
        tostring(record.childrenCount or 0),
        table.concat(attrParts, ","),
        table.concat(tagParts, ","),
        record.replicationSource or "",
        record.signature or "",
        tostring(record.firstSeen or 0),
        tostring(record.lastSeen or 0),
        tostring(record.version or 0),
    }, "\30") -- unit separator, unlikely to appear in real data
end

local function deserializeRecord(line)
    local fields = {}
    for part in string.gmatch(line, "([^\30]*)\30?") do
        table.insert(fields, part)
    end
    if #fields < 12 then return nil end

    local record = {
        name = fields[1],
        className = fields[2],
        fullPath = fields[3],
        parentPath = fields[4],
        childrenCount = tonumber(fields[5]) or 0,
        attributes = {},
        tags = {},
        replicationSource = fields[8],
        signature = fields[9],
        firstSeen = tonumber(fields[10]) or 0,
        lastSeen = tonumber(fields[11]) or 0,
        version = tonumber(fields[12]) or 0,
    }

    for pair in string.gmatch(fields[6] or "", "[^,]+") do
        local k, v = string.match(pair, "^(.-)=(.*)$")
        if k then record.attributes[k] = v end
    end
    for tag in string.gmatch(fields[7] or "", "[^,]+") do
        table.insert(record.tags, tag)
    end

    return record
end

function ObjectDatabase.Save()
    local ok, supported = pcall(function() return writefile ~= nil end)
    if not ok or not supported then
        Logger.Warn("ObjectDatabase", "writefile unavailable — database will not persist across restarts")
        return false
    end

    local lines = { "VERSION=" .. tostring(ObjectDatabase._scanVersion) }
    for _, record in pairs(ObjectDatabase._records) do
        table.insert(lines, serializeRecord(record))
    end

    pcall(writefile, DB_FILE, table.concat(lines, "\n"))
    return true
end

--- Loads a previously persisted database from file, if one exists.
--- Returns true if a database was loaded, false otherwise (fresh start).
function ObjectDatabase.Load()
    local ok, supported = pcall(function() return isfile ~= nil and readfile ~= nil end)
    if not ok or not supported then return false end

    local existsOk, exists = pcall(isfile, DB_FILE)
    if not existsOk or not exists then return false end

    local readOk, content = pcall(readfile, DB_FILE)
    if not readOk then return false end

    local lines = {}
    for line in string.gmatch(content, "[^\n]+") do
        table.insert(lines, line)
    end

    if #lines == 0 then return false end

    local scanVersion = tonumber(string.match(lines[1], "VERSION=(%d+)")) or 0
    local records = {}

    for i = 2, #lines do
        local record = deserializeRecord(lines[i])
        if record and record.fullPath then
            records[record.fullPath] = record
        end
    end

    ObjectDatabase.LoadSnapshot(records, scanVersion)
    Logger.Info("ObjectDatabase", string.format("Loaded %d record(s) from previous scan (version %d)", ObjectDatabase.Count(), scanVersion))
    return true
end

function ObjectDatabase.IncrementScanVersion()
    ObjectDatabase._scanVersion = ObjectDatabase._scanVersion + 1
    return ObjectDatabase._scanVersion
end

return ObjectDatabase
end)()

-- ChangeDetector
local ChangeDetector = (function()
-- diff two snapshots

local ChangeDetector = {}

function ChangeDetector.Compare(previous, current)
    previous = previous or {}
    current = current or {}

    local diff = {
        added = {},
        removed = {},
        renamed = {},
        moved = {},
        attributeChanged = {},
        classChanged = {},
    }

    local rawAdded = {}
    local rawRemoved = {}

    for path, record in pairs(current) do
        if not previous[path] then
            table.insert(rawAdded, record)
        end
    end

    for path, record in pairs(previous) do
        if not current[path] then
            table.insert(rawRemoved, record)
        end
    end

    -- In-place changes for paths present in both.
    for path, currentRecord in pairs(current) do
        local previousRecord = previous[path]
        if previousRecord then
            if previousRecord.className ~= currentRecord.className then
                table.insert(diff.classChanged, { previous = previousRecord, current = currentRecord })
            elseif previousRecord.signature ~= currentRecord.signature then
                local changedKeys = {}
                local allKeys = {}
                for k in pairs(previousRecord.attributes or {}) do allKeys[k] = true end
                for k in pairs(currentRecord.attributes or {}) do allKeys[k] = true end
                for k in pairs(allKeys) do
                    local prevVal = (previousRecord.attributes or {})[k]
                    local curVal = (currentRecord.attributes or {})[k]
                    if prevVal ~= curVal then
                        table.insert(changedKeys, k)
                    end
                end
                if #changedKeys > 0 then
                    table.insert(diff.attributeChanged, {
                        previous = previousRecord,
                        current = currentRecord,
                        changedKeys = changedKeys,
                    })
                end
            end
        end
    end

    local matchedAdded, matchedRemoved = {}, {}

    for ai, addedRecord in ipairs(rawAdded) do
        if not matchedAdded[ai] then
            for ri, removedRecord in ipairs(rawRemoved) do
                if not matchedRemoved[ri] then
                    local sameParent = addedRecord.parentPath == removedRecord.parentPath
                    local sameClass = addedRecord.className == removedRecord.className
                    local sameName = addedRecord.name == removedRecord.name
                    local similarChildren = math.abs((addedRecord.childrenCount or 0) - (removedRecord.childrenCount or 0)) <= 1

                    if sameParent and sameClass and similarChildren and not sameName then
                        table.insert(diff.renamed, { from = removedRecord, to = addedRecord })
                        matchedAdded[ai] = true
                        matchedRemoved[ri] = true
                        break
                    elseif sameName and sameClass and not sameParent then
                        table.insert(diff.moved, { from = removedRecord, to = addedRecord })
                        matchedAdded[ai] = true
                        matchedRemoved[ri] = true
                        break
                    end
                end
            end
        end
    end

    for ai, record in ipairs(rawAdded) do
        if not matchedAdded[ai] then
            table.insert(diff.added, record)
        end
    end
    for ri, record in ipairs(rawRemoved) do
        if not matchedRemoved[ri] then
            table.insert(diff.removed, record)
        end
    end

    return diff
end

--- Quick summary counts, useful for a one-line log without building
--- the full report.
function ChangeDetector.Summarize(diff)
    return {
        added = #diff.added,
        removed = #diff.removed,
        renamed = #diff.renamed,
        moved = #diff.moved,
        attributeChanged = #diff.attributeChanged,
        classChanged = #diff.classChanged,
    }
end

return ChangeDetector
end)()

-- InspectorSearch
local InspectorSearch = (function()
-- search


local InspectorSearch = {}

local function collect(predicate)
    local results = {}
    for _, record in pairs(ObjectDatabase.All()) do
        if predicate(record) then
            table.insert(results, record)
        end
    end
    return results
end

function InspectorSearch.ByName(name, exact)
    exact = exact ~= false
    local lowerName = string.lower(name)
    return collect(function(record)
        if exact then
            return record.name == name
        end
        return string.find(string.lower(record.name), lowerName, 1, true) ~= nil
    end)
end

function InspectorSearch.ByClass(className)
    return collect(function(record)
        return record.className == className
    end)
end

function InspectorSearch.ByAttribute(attributeName, value)
    return collect(function(record)
        local attrValue = (record.attributes or {})[attributeName]
        if attrValue == nil then return false end
        if value ~= nil then
            return attrValue == tostring(value)
        end
        return true
    end)
end

function InspectorSearch.ByTag(tagName)
    return collect(function(record)
        for _, tag in ipairs(record.tags or {}) do
            if tag == tagName then return true end
        end
        return false
    end)
end

function InspectorSearch.ByParent(parentPath)
    return collect(function(record)
        return record.parentPath == parentPath
    end)
end

function InspectorSearch.ByPartialPath(fragment)
    local lowerFragment = string.lower(fragment)
    return collect(function(record)
        return string.find(string.lower(record.fullPath), lowerFragment, 1, true) ~= nil
    end)
end

function InspectorSearch.BySource(source)
    return collect(function(record)
        return record.replicationSource == source
    end)
end

return InspectorSearch
end)()

-- ObjectInspection
local ObjectInspection = (function()
-- build a record from an instance

local ObjectInspection = {}

local CollectionService = nil
pcall(function() CollectionService = game:GetService("CollectionService") end)

function ObjectInspection.GetFullPath(instance)
    local ok, path = pcall(function() return instance:GetFullName() end)
    return ok and path or instance.Name
end

--- Fast fingerprint — cheap enough to compute for every Instance every
--- pass, used to decide whether the expensive read below is needed.
function ObjectInspection.CheapSignature(instance)
    local ok, childCount = pcall(function() return #instance:GetChildren() end)
    return instance.ClassName .. "|" .. tostring(ok and childCount or 0)
end

--- Rich signature — computed only when CheapSignature indicates a
--- possible change, used for the actual before/after comparison.
function ObjectInspection.RichSignature(name, className, childrenCount, attributes, tags)
    local attrParts = {}
    for k, v in pairs(attributes) do
        table.insert(attrParts, k .. "=" .. tostring(v))
    end
    table.sort(attrParts)

    local tagParts = {}
    for _, t in ipairs(tags) do table.insert(tagParts, t) end
    table.sort(tagParts)

    return table.concat({
        name, className, tostring(childrenCount),
        table.concat(attrParts, ","), table.concat(tagParts, ","),
    }, "|")
end

function ObjectInspection.BuildRecord(instance, source, existingRecord, now)
    local attributes = {}
    local attrOk, rawAttrs = pcall(function() return instance:GetAttributes() end)
    if attrOk then
        for k, v in pairs(rawAttrs) do
            attributes[k] = tostring(v)
        end
    end

    local tags = {}
    if CollectionService then
        local tagOk, rawTags = pcall(function() return CollectionService:GetTags(instance) end)
        if tagOk then
            for _, t in ipairs(rawTags) do table.insert(tags, t) end
        end
    end

    local childrenOk, childrenCount = pcall(function() return #instance:GetChildren() end)
    childrenCount = childrenOk and childrenCount or 0

    local parentOk, parentPath = pcall(function()
        return instance.Parent and instance.Parent:GetFullName() or ""
    end)

    local fullPath = ObjectInspection.GetFullPath(instance)

    return {
        name = instance.Name,
        className = instance.ClassName,
        fullPath = fullPath,
        parentPath = parentOk and parentPath or "",
        childrenCount = childrenCount,
        attributes = attributes,
        tags = tags,
        replicationSource = source,
        signature = ObjectInspection.RichSignature(instance.Name, instance.ClassName, childrenCount, attributes, tags),
        firstSeen = existingRecord and existingRecord.firstSeen or now,
        lastSeen = now,
        version = existingRecord and (existingRecord.version + 1) or 1,
    }
end

local INTERESTING_CLASSES = {
    Model = true, Folder = true, Tool = true,
    Humanoid = true, NPC = true,
    RemoteEvent = true, RemoteFunction = true, ModuleScript = true,
    ProximityPrompt = true, ClickDetector = true, SpawnLocation = true,
    ParticleEmitter = true, Attachment = true, Beam = true, Sound = true,
    MeshPart = true, Part = false, -- plain Parts only matter if tagged/attributed (checked separately)
}

function ObjectInspection.IsInteresting(instance)
    if INTERESTING_CLASSES[instance.ClassName] then
        return true
    end

    local attrOk, attrs = pcall(function() return instance:GetAttributes() end)
    if attrOk and next(attrs) ~= nil then
        return true
    end

    if CollectionService then
        local tagOk, tags = pcall(function() return CollectionService:GetTags(instance) end)
        if tagOk and #tags > 0 then
            return true
        end
    end

    return false
end

local CONTAINER_CLASSES = {
    Folder = true, Model = true, Tool = true, Workspace = true,
    Accessory = true, Backpack = true, Configuration = true,
}

function ObjectInspection.IsContainer(instance)
    return CONTAINER_CLASSES[instance.ClassName] == true
end

return ObjectInspection
end)()

-- HierarchyScanner
local HierarchyScanner = (function()
-- discovery queue


local HierarchyScanner = {}

-- { instance, source } entries. Priority queue drained first, always.
HierarchyScanner._priorityQueue = {}
HierarchyScanner._backgroundQueue = {}
HierarchyScanner._queuedPaths = {} -- fullPath -> true, dedupes queue membership
HierarchyScanner._processedCount = 0

local Players = nil
pcall(function() Players = game:GetService("Players") end)

local function enqueue(queue, instance, source)
    local path = ObjectInspection.GetFullPath(instance)
    if HierarchyScanner._queuedPaths[path] then
        return
    end
    HierarchyScanner._queuedPaths[path] = true
    table.insert(queue, { instance = instance, source = source })
end

local function enqueuePriority(instance, source)
    enqueue(HierarchyScanner._priorityQueue, instance, source)
end

local function enqueueBackground(instance, source)
    enqueue(HierarchyScanner._backgroundQueue, instance, source)
end

local function getRootContainers()
    local roots = {}
    local function tryAdd(instance, source)
        if instance then
            table.insert(roots, { instance = instance, source = source })
        end
    end

    local ok = pcall(function()
        tryAdd(game:GetService("Workspace"), "Workspace")
        tryAdd(game:GetService("ReplicatedStorage"), "ReplicatedStorage")
        tryAdd(game:GetService("Lighting"), "Lighting")
        tryAdd(game:GetService("Players"), "Players")
        tryAdd(game:GetService("Teams"), "Teams")
        tryAdd(game:GetService("Workspace").Terrain, "Terrain")
        tryAdd(game:GetService("SoundService"), "SoundService")
        tryAdd(game:GetService("StarterGui"), "StarterGui")
        tryAdd(game:GetService("StarterPlayer"), "StarterPlayer")

        local localPlayer = Players and Players.LocalPlayer
        if localPlayer then
            tryAdd(localPlayer:FindFirstChild("PlayerGui"), "PlayerGui")
            tryAdd(localPlayer.Character, "Character")
        end
    end)

    if not ok then
        Logger.Warn("HierarchyScanner", "Some root containers were unavailable when resolving roots")
    end

    return roots
end

function HierarchyScanner.EnqueueRoots()
    for _, root in ipairs(getRootContainers()) do
        enqueueBackground(root.instance, root.source)
    end

    if game and game:GetService("CollectionService") then
        local cs = game:GetService("CollectionService")
        local tagsOk, allTags = pcall(function() return cs:GetAllTags() end)
        if tagsOk then
            for _, tag in ipairs(allTags) do
                local taggedOk, tagged = pcall(function() return cs:GetTagged(tag) end)
                if taggedOk then
                    for _, instance in ipairs(tagged) do
                        enqueueBackground(instance, "CollectionService:" .. tag)
                    end
                end
            end
        end
    end
end

function HierarchyScanner.ProcessBatch(count)
    local now = os.time()
    local processed = 0

    while processed < count do
        local queue = (#HierarchyScanner._priorityQueue > 0) and HierarchyScanner._priorityQueue or HierarchyScanner._backgroundQueue
        if #queue == 0 then
            break
        end

        local item = table.remove(queue, 1)
        local instance = item.instance
        local path = ObjectInspection.GetFullPath(instance)
        HierarchyScanner._queuedPaths[path] = nil

        local existing = ObjectDatabase.Get(path)
        local cheapSig = ObjectInspection.CheapSignature(instance)
        local changed = not existing or existing._cheapSig ~= cheapSig

        if ObjectInspection.IsInteresting(instance) then
            if changed then
                local record = ObjectInspection.BuildRecord(instance, item.source, existing, now)
                record._cheapSig = cheapSig
                ObjectDatabase.Set(path, record)
            elseif existing then
                existing.lastSeen = now
            end
        end

        if ObjectInspection.IsContainer(instance) then
            local childrenOk, children = pcall(function() return instance:GetChildren() end)
            if childrenOk then
                for _, child in ipairs(children) do
                    if changed then
                        enqueuePriority(child, item.source)
                    else
                        enqueueBackground(child, item.source)
                    end
                end
            end
        end

        HierarchyScanner._processedCount = HierarchyScanner._processedCount + 1
        processed = processed + 1
    end

    return processed
end

function HierarchyScanner.GetQueueLength()
    return #HierarchyScanner._priorityQueue + #HierarchyScanner._backgroundQueue
end

function HierarchyScanner.GetProcessedCount()
    return HierarchyScanner._processedCount
end

return HierarchyScanner
end)()

-- InspectorScanner
local InspectorScanner = (function()
-- manual scan


local InspectorScanner = {}

local Workspace, ReplicatedStorage, Lighting, Terrain, CollectionService = nil, nil, nil, nil, nil
pcall(function()
    Workspace = game:GetService("Workspace")
    ReplicatedStorage = game:GetService("ReplicatedStorage")
    Lighting = game:GetService("Lighting")
    Terrain = Workspace and Workspace.Terrain
    CollectionService = game:GetService("CollectionService")
end)

local function getRootContainers()
    local roots = {}

    if Workspace then
        for _, name in ipairs({ "Enemies", "Characters", "Map", "Events" }) do
            local child = Workspace:FindFirstChild(name)
            if child then
                table.insert(roots, { instance = child, source = "Workspace" })
            else
                Logger.Debug("InspectorScanner", "Workspace." .. name .. " not found (may not exist in this game version)")
            end
        end
    end

    if ReplicatedStorage then
        table.insert(roots, { instance = ReplicatedStorage, source = "ReplicatedStorage" })
    end

    return roots
end

local function cheapSignature(instance)
    local ok, childCount = pcall(function() return #instance:GetChildren() end)
    return instance.ClassName .. "|" .. tostring(ok and childCount or 0)
end

local function richSignature(name, className, childrenCount, attributes, tags)
    local attrParts = {}
    for k, v in pairs(attributes) do
        table.insert(attrParts, k .. "=" .. tostring(v))
    end
    table.sort(attrParts)

    local tagParts = {}
    for _, t in ipairs(tags) do table.insert(tagParts, t) end
    table.sort(tagParts)

    return table.concat({
        name, className, tostring(childrenCount),
        table.concat(attrParts, ","), table.concat(tagParts, ","),
    }, "|")
end

local function buildFullPath(instance)
    local ok, path = pcall(function() return instance:GetFullName() end)
    return ok and path or instance.Name
end

local function inspectInstance(instance, source, now)
    local fullPath = buildFullPath(instance)
    local existing = ObjectDatabase.Get(fullPath)
    local cheapSig = cheapSignature(instance)

    if existing and existing.signature and existing._cheapSig == cheapSig then
        existing.lastSeen = now
        return existing
    end

    local attributes = {}
    local ok, rawAttrs = pcall(function() return instance:GetAttributes() end)
    if ok then
        for k, v in pairs(rawAttrs) do
            attributes[k] = tostring(v)
        end
    end

    local tags = {}
    if CollectionService then
        local tagOk, rawTags = pcall(function() return CollectionService:GetTags(instance) end)
        if tagOk then
            for _, t in ipairs(rawTags) do table.insert(tags, t) end
        end
    end

    local childrenOk, childrenCount = pcall(function() return #instance:GetChildren() end)
    childrenCount = childrenOk and childrenCount or 0

    local parentOk, parentPath = pcall(function() return instance.Parent and instance.Parent:GetFullName() or "" end)

    local record = {
        name = instance.Name,
        className = instance.ClassName,
        fullPath = fullPath,
        parentPath = parentOk and parentPath or "",
        childrenCount = childrenCount,
        attributes = attributes,
        tags = tags,
        replicationSource = source,
        signature = richSignature(instance.Name, instance.ClassName, childrenCount, attributes, tags),
        firstSeen = existing and existing.firstSeen or now,
        lastSeen = now,
        version = existing and (existing.version + 1) or 1,
        _cheapSig = cheapSig, -- not persisted (see ObjectDatabase serialize), scan-session only
    }

    ObjectDatabase.Set(fullPath, record)
    return record
end

local function walk(instance, source, depth, maxDepth, now, visited)
    if depth > maxDepth then return end

    inspectInstance(instance, source, now)

    local ok, children = pcall(function() return instance:GetChildren() end)
    if not ok then return end

    for _, child in ipairs(children) do
        walk(child, source, depth + 1, maxDepth, now, visited)
    end
end

function InspectorScanner.RunScan()
    local now = os.time()
    local maxDepth = Config.Get("Inspector.MaxDepth") or 4

    for _, root in ipairs(getRootContainers()) do
        walk(root.instance, root.source, 0, maxDepth, now, {})
    end

    if Lighting then
        inspectInstance(Lighting, "Lighting", now)
    end

    if Terrain then
        inspectInstance(Terrain, "Terrain", now)
    end

    if CollectionService then
        local tagsOk, allTags = pcall(function() return CollectionService:GetAllTags() end)
        if tagsOk then
            for _, tag in ipairs(allTags) do
                local taggedOk, tagged = pcall(function() return CollectionService:GetTagged(tag) end)
                if taggedOk then
                    for _, instance in ipairs(tagged) do
                        inspectInstance(instance, "CollectionService:" .. tag, now)
                    end
                end
            end
        end
    end

    if ReplicatedStorage then
        local descOk, descendants = pcall(function() return ReplicatedStorage:GetDescendants() end)
        if descOk then
            for _, instance in ipairs(descendants) do
                if instance:IsA("RemoteEvent") or instance:IsA("RemoteFunction") then
                    inspectInstance(instance, "RemoteEvent", now)
                end
            end
        end
    end

    Logger.Info("InspectorScanner", string.format("Scan complete — %d object(s) in database", ObjectDatabase.Count()))
end

return InspectorScanner
end)()

-- InspectorReport
local InspectorReport = (function()
-- report text


local InspectorReport = {}

local SIGNALS_REGISTERED = false
local function ensureSignalsRegistered()
    if SIGNALS_REGISTERED then return end
    DetectionConfidence.RegisterSignal("CONTAINS_NPCS", 35)
    DetectionConfidence.RegisterSignal("CONTAINS_EVENT_ATTRIBUTES", 30)
    DetectionConfidence.RegisterSignal("CONTAINS_EFFECTS", 20)
    DetectionConfidence.RegisterSignal("NEW_REMOTE", 25)
    DetectionConfidence.RegisterSignal("UNDER_KNOWN_EVENT_CONTAINER", 15)
    DetectionConfidence.RegisterSignal("HAS_HUMANOID_CHILD_ATTR", 40)
    SIGNALS_REGISTERED = true
end

local EVENT_ATTRIBUTE_HINTS = { "active", "state", "event", "spawn", "raid", "duration", "started" }
local EFFECT_CLASS_HINTS = { ParticleEmitter = true, Sound = true, Beam = true, Trail = true, Fire = true, Explosion = true }

local function classifyRecord(record)
    ensureSignalsRegistered()
    local signals = {}

    if record.className == "RemoteEvent" or record.className == "RemoteFunction" then
        table.insert(signals, "NEW_REMOTE")
    end

    if record.replicationSource == "Workspace" and (record.parentPath:find("Events") or record.parentPath:find("Map")) then
        table.insert(signals, "UNDER_KNOWN_EVENT_CONTAINER")
    end

    for attrName in pairs(record.attributes or {}) do
        local lowerAttr = string.lower(attrName)
        for _, hint in ipairs(EVENT_ATTRIBUTE_HINTS) do
            if string.find(lowerAttr, hint, 1, true) then
                table.insert(signals, "CONTAINS_EVENT_ATTRIBUTES")
                break
            end
        end
    end

    if EFFECT_CLASS_HINTS[record.className] then
        table.insert(signals, "CONTAINS_EFFECTS")
    end

    if record.className == "Model" and record.childrenCount and record.childrenCount > 0 then
        table.insert(signals, "HAS_HUMANOID_CHILD_ATTR")
    end

    if #signals == 0 then
        return nil
    end

    local score, explanation = DetectionConfidence.Explain(signals)
    return score, explanation, signals
end

local function formatRecordList(title, records, indent)
    indent = indent or "  "
    local lines = { title .. " (" .. #records .. ")" }
    for _, record in ipairs(records) do
        table.insert(lines, indent .. "- " .. record.fullPath .. " [" .. record.className .. "]")
    end
    return lines
end

--- Builds the full structured report as a single string.
function InspectorReport.Generate(diff, scanVersion)
    local lines = {}
    table.insert(lines, "========== INSPECTOR REPORT ==========")
    table.insert(lines, "Scan version: " .. tostring(scanVersion))
    table.insert(lines, os.date("!%Y-%m-%d %H:%M:%S UTC"))
    table.insert(lines, "")

    for _, line in ipairs(formatRecordList("New Objects", diff.added)) do table.insert(lines, line) end
    table.insert(lines, "")

    local modifiedLines = {}
    for _, entry in ipairs(diff.attributeChanged) do
        table.insert(modifiedLines, "  - " .. entry.current.fullPath .. " (changed: " .. table.concat(entry.changedKeys, ", ") .. ")")
    end
    for _, entry in ipairs(diff.classChanged) do
        table.insert(modifiedLines, "  - " .. entry.current.fullPath .. " (class: " .. entry.previous.className .. " -> " .. entry.current.className .. ")")
    end
    table.insert(lines, "Modified Objects (" .. #modifiedLines .. ")")
    for _, l in ipairs(modifiedLines) do table.insert(lines, l) end
    table.insert(lines, "")

    for _, line in ipairs(formatRecordList("Removed Objects", diff.removed)) do table.insert(lines, line) end
    table.insert(lines, "")

    local renameMoveLines = {}
    for _, entry in ipairs(diff.renamed) do
        table.insert(renameMoveLines, "  - possible rename: " .. entry.from.fullPath .. " -> " .. entry.to.fullPath)
    end
    for _, entry in ipairs(diff.moved) do
        table.insert(renameMoveLines, "  - possible move: " .. entry.from.fullPath .. " -> " .. entry.to.fullPath)
    end
    table.insert(lines, "Unknown Objects / Possible Renames-Moves (" .. #renameMoveLines .. ")")
    for _, l in ipairs(renameMoveLines) do table.insert(lines, l) end
    table.insert(lines, "")

    -- Heuristic classification over Added + Renamed/Moved targets.
    local classified = {}
    for _, record in ipairs(diff.added) do
        local score, explanation, signals = classifyRecord(record)
        if score then
            table.insert(classified, { record = record, score = score, explanation = explanation, signals = signals })
        end
    end
    for _, entry in ipairs(diff.renamed) do
        local score, explanation = classifyRecord(entry.to)
        if score then
            table.insert(classified, { record = entry.to, score = score, explanation = explanation })
        end
    end
    table.sort(classified, function(a, b) return a.score > b.score end)

    local potentialBosses, potentialEvents, potentialRemotes = {}, {}, {}
    for _, entry in ipairs(classified) do
        if entry.record.className == "RemoteEvent" or entry.record.className == "RemoteFunction" then
            table.insert(potentialRemotes, entry)
        elseif entry.record.className == "Model" then
            table.insert(potentialBosses, entry)
        else
            table.insert(potentialEvents, entry)
        end
    end

    local minConfidence = Config.Get("Inspector.MinReportConfidence") or 50

    local function formatClassified(title, entries)
        local out = { title .. " (" .. #entries .. ")" }
        for _, entry in ipairs(entries) do
            if entry.score >= minConfidence then
                table.insert(out, "  Unknown object detected:")
                table.insert(out, "    " .. entry.record.fullPath)
                table.insert(out, "  Confidence:")
                table.insert(out, "    " .. entry.score .. "%")
                table.insert(out, "  Reason:")
                table.insert(out, "    " .. entry.explanation)
            end
        end
        return out
    end

    for _, l in ipairs(formatClassified("Potential Boss Objects", potentialBosses)) do table.insert(lines, l) end
    table.insert(lines, "")
    for _, l in ipairs(formatClassified("Potential Event Objects", potentialEvents)) do table.insert(lines, l) end
    table.insert(lines, "")
    for _, l in ipairs(formatClassified("Potential RemoteEvents", potentialRemotes)) do table.insert(lines, l) end
    table.insert(lines, "")

    table.insert(lines, "Potential Replication Changes (" .. (#diff.moved) .. ")")
    for _, entry in ipairs(diff.moved) do
        table.insert(lines, "  - " .. entry.from.fullPath .. " -> " .. entry.to.fullPath ..
            " (source: " .. entry.from.replicationSource .. " -> " .. entry.to.replicationSource .. ")")
    end
    table.insert(lines, "")

    table.insert(lines, "======================================")

    return table.concat(lines, "\n")
end

return InspectorReport
end)()

-- InspectorEngine
local InspectorEngine = (function()
-- inspector


local InspectorEngine = {}

InspectorEngine.Search = InspectorSearch
InspectorEngine._lastReport = nil
InspectorEngine._loaded = false

local function ensureLoaded()
    if InspectorEngine._loaded then return end
    ObjectDatabase.Load()
    InspectorEngine._loaded = true
end

--- Runs a full scan and compares it against the last persisted scan.
--- Returns (diff, reportString).
function InspectorEngine.RunScan()
    ensureLoaded()

    local previous = ObjectDatabase.Snapshot()
    InspectorScanner.RunScan()
    local current = ObjectDatabase.All()

    local diff = ChangeDetector.Compare(previous, current)
    local scanVersion = ObjectDatabase.IncrementScanVersion()
    ObjectDatabase.Save()

    local report = InspectorReport.Generate(diff, scanVersion)
    InspectorEngine._lastReport = report

    local summary = ChangeDetector.Summarize(diff)
    Logger.Info("InspectorEngine", string.format(
        "Scan #%d complete — %d added, %d removed, %d renamed, %d moved, %d attribute change(s)",
        scanVersion, summary.added, summary.removed, summary.renamed, summary.moved, summary.attributeChanged
    ))

    local ok, supported = pcall(function() return writefile ~= nil end)
    if ok and supported then
        pcall(writefile, "Lumexa_InspectorReport.txt", report)
        Logger.Info("InspectorEngine", "Report written to Lumexa_InspectorReport.txt")
    end

    return diff, report
end

function InspectorEngine.GetLastReport()
    return InspectorEngine._lastReport
end

-- Developer Mode

function InspectorEngine.InspectObject(fullPath)
    ensureLoaded()
    local record = ObjectDatabase.Get(fullPath)
    if not record then
        Logger.Warn("InspectorEngine", "No record for " .. tostring(fullPath) .. " — run RunScan() first, or check the path")
        return nil
    end

    Logger.Info("InspectorEngine", "== " .. record.fullPath .. " ==")
    Logger.Info("InspectorEngine", "  Class: " .. record.className)
    Logger.Info("InspectorEngine", "  Parent: " .. record.parentPath)
    Logger.Info("InspectorEngine", "  Children: " .. tostring(record.childrenCount))
    Logger.Info("InspectorEngine", "  Replication source: " .. record.replicationSource)
    Logger.Info("InspectorEngine", "  First seen: " .. os.date("!%Y-%m-%d %H:%M:%S UTC", record.firstSeen))
    Logger.Info("InspectorEngine", "  Last seen: " .. os.date("!%Y-%m-%d %H:%M:%S UTC", record.lastSeen))
    Logger.Info("InspectorEngine", "  Version: " .. tostring(record.version))

    local attrLines = {}
    for k, v in pairs(record.attributes or {}) do
        table.insert(attrLines, k .. " = " .. v)
    end
    Logger.Info("InspectorEngine", "  Attributes: " .. (#attrLines > 0 and table.concat(attrLines, ", ") or "(none)"))
    Logger.Info("InspectorEngine", "  Tags: " .. (#record.tags > 0 and table.concat(record.tags, ", ") or "(none)"))

    return record
end

function InspectorEngine.ViewAttributes(fullPath)
    local record = ObjectDatabase.Get(fullPath)
    return record and record.attributes or {}
end

function InspectorEngine.ViewChildren(fullPath)
    return InspectorSearch.ByParent(fullPath)
end

function InspectorEngine.ViewParent(fullPath)
    local record = ObjectDatabase.Get(fullPath)
    return record and ObjectDatabase.Get(record.parentPath)
end

function InspectorEngine.ViewReplicationPath(fullPath)
    local record = ObjectDatabase.Get(fullPath)
    return record and record.replicationSource
end

function InspectorEngine.ViewCollectionTags(fullPath)
    local record = ObjectDatabase.Get(fullPath)
    return record and record.tags or {}
end

function InspectorEngine.ViewClass(fullPath)
    local record = ObjectDatabase.Get(fullPath)
    return record and record.className
end

function InspectorEngine.ViewCreationTime(fullPath)
    local record = ObjectDatabase.Get(fullPath)
    return record and record.firstSeen
end

function InspectorEngine.GetDatabaseSize()
    return ObjectDatabase.Count()
end

function InspectorEngine.ClearDatabase()
    ObjectDatabase.Clear()
    ObjectDatabase.Save()
    Logger.Info("InspectorEngine", "Database cleared")
end

pcall(function()
    if getgenv then
        getgenv().LumexaInspector = InspectorEngine
        Logger.Info("InspectorEngine", "Available as LumexaInspector in the executor console (e.g. LumexaInspector.RunScan())")
    end
end)

return InspectorEngine
end)()

-- SnapshotEngine
local SnapshotEngine = (function()
-- snapshots


local SnapshotEngine = {}

SnapshotEngine._index = {} -- array of { id, name, timestamp, objectCount }
SnapshotEngine._cache = {} -- id -> records table, in-memory cache for this session
SnapshotEngine._indexLoaded = false

local INDEX_FILE = "Lumexa_SnapshotIndex.txt"

local HttpService = nil
pcall(function() HttpService = game:GetService("HttpService") end)

local function snapshotFilePath(id)
    return "Lumexa_Snapshot_" .. tostring(id) .. ".txt"
end

local function loadIndex()
    if SnapshotEngine._indexLoaded then return end
    SnapshotEngine._indexLoaded = true

    local ok, supported = pcall(function() return isfile ~= nil and readfile ~= nil end)
    if not ok or not supported then return end

    local existsOk, exists = pcall(isfile, INDEX_FILE)
    if not existsOk or not exists then return end

    local readOk, content = pcall(readfile, INDEX_FILE)
    if not readOk or not HttpService then return end

    local decodeOk, decoded = pcall(function() return HttpService:JSONDecode(content) end)
    if decodeOk and type(decoded) == "table" then
        SnapshotEngine._index = decoded
        Logger.Info("SnapshotEngine", string.format("Loaded snapshot index (%d snapshot(s))", #SnapshotEngine._index))
    end
end

local function saveIndex()
    local ok, supported = pcall(function() return writefile ~= nil end)
    if not ok or not supported or not HttpService then return end

    local encodeOk, encoded = pcall(function() return HttpService:JSONEncode(SnapshotEngine._index) end)
    if encodeOk then
        pcall(writefile, INDEX_FILE, encoded)
    end
end

--- Captures the current live ObjectDatabase state as a new named
--- snapshot. Returns the snapshot id.
function SnapshotEngine.Capture(name)
    loadIndex()

    local id = tostring(os.time()) .. "_" .. tostring(#SnapshotEngine._index + 1)
    local records = ObjectDatabase.Snapshot() -- existing deep-copy helper, reused as-is

    local count = 0
    for _ in pairs(records) do count = count + 1 end

    SnapshotEngine._cache[id] = records

    table.insert(SnapshotEngine._index, {
        id = id,
        name = name or ("Snapshot " .. id),
        timestamp = os.time(),
        objectCount = count,
    })
    saveIndex()

    local ok, supported = pcall(function() return writefile ~= nil end)
    if ok and supported and HttpService then
        local encodeOk, encoded = pcall(function() return HttpService:JSONEncode(records) end)
        if encodeOk then
            pcall(writefile, snapshotFilePath(id), encoded)
        end
    else
        Logger.Warn("SnapshotEngine", "writefile unavailable — snapshot '" .. tostring(name) .. "' will not survive a restart")
    end

    Logger.Info("SnapshotEngine", string.format("Captured snapshot '%s' (%s) — %d object(s)", name or id, id, count))
    return id
end

function SnapshotEngine.List()
    loadIndex()
    return SnapshotEngine._index
end

--- Loads a snapshot's records (from the in-memory cache if already
--- loaded this session, otherwise from file).
function SnapshotEngine.Get(id)
    loadIndex()

    if SnapshotEngine._cache[id] then
        return SnapshotEngine._cache[id]
    end

    local ok, supported = pcall(function() return isfile ~= nil and readfile ~= nil end)
    if not ok or not supported then return nil end

    local existsOk, exists = pcall(isfile, snapshotFilePath(id))
    if not existsOk or not exists then return nil end

    local readOk, content = pcall(readfile, snapshotFilePath(id))
    if not readOk or not HttpService then return nil end

    local decodeOk, records = pcall(function() return HttpService:JSONDecode(content) end)
    if not decodeOk then return nil end

    SnapshotEngine._cache[id] = records
    return records
end

--- Compares two named snapshots by id. Returns the same diff shape
--- ChangeDetector.Compare always returns.
function SnapshotEngine.Compare(idA, idB)
    local recordsA = SnapshotEngine.Get(idA)
    local recordsB = SnapshotEngine.Get(idB)

    if not recordsA or not recordsB then
        return nil, "One or both snapshot ids not found"
    end

    return ChangeDetector.Compare(recordsA, recordsB), nil
end

function SnapshotEngine.CompareToLive(id)
    local records = SnapshotEngine.Get(id)
    if not records then
        return nil, "Snapshot id not found"
    end
    return ChangeDetector.Compare(records, ObjectDatabase.All()), nil
end

function SnapshotEngine.GenerateReport(idA, idB)
    local diff, err = SnapshotEngine.Compare(idA, idB)
    if not diff then
        return nil, err
    end
    return InspectorReport.Generate(diff, idA .. " -> " .. idB), nil
end

function SnapshotEngine.Delete(id)
    loadIndex()

    for i, entry in ipairs(SnapshotEngine._index) do
        if entry.id == id then
            table.remove(SnapshotEngine._index, i)
            saveIndex()
            SnapshotEngine._cache[id] = nil

            pcall(function()
                if delfile then delfile(snapshotFilePath(id)) end
            end)

            return true
        end
    end

    return false, "Snapshot id not found"
end

InspectorEngine.Snapshots = SnapshotEngine

return SnapshotEngine
end)()

-- LiveChangeDetector
local LiveChangeDetector = (function()
-- live change events


local LiveChangeDetector = {}

LiveChangeDetector._listeners = {}
LiveChangeDetector._recentEvents = {}

local function classifyChange(previousRecord, currentRecord)
    if not previousRecord then
        return "Added"
    end
    if previousRecord.className ~= currentRecord.className then
        return "ClassChanged"
    end
    if previousRecord.parentPath ~= currentRecord.parentPath then
        return "Moved"
    end
    if previousRecord.childrenCount ~= currentRecord.childrenCount then
        return "ChildrenCountChanged"
    end
    return "AttributeChanged"
end

local function recordEvent(event)
    table.insert(LiveChangeDetector._recentEvents, event)
    local maxEvents = Config.Get("Intelligence.MaxLiveChangeEvents") or 200
    if #LiveChangeDetector._recentEvents > maxEvents then
        table.remove(LiveChangeDetector._recentEvents, 1)
    end
end

local function notify(event)
    for _, listener in ipairs(LiveChangeDetector._listeners) do
        pcall(listener, event)
    end
end

local function handleSetMutation(fullPath, previousRecord, currentRecord)
    if previousRecord and previousRecord.signature == currentRecord.signature then
        return
    end

    local event = {
        changeType = classifyChange(previousRecord, currentRecord),
        fullPath = fullPath,
        previous = previousRecord,
        current = currentRecord,
        timestamp = os.time(),
    }

    recordEvent(event)
    notify(event)
end

local function handleDeleteMutation(fullPath, previousRecord)
    if not previousRecord then
        return -- nothing was actually there to remove
    end

    local event = {
        changeType = "Removed",
        fullPath = fullPath,
        previous = previousRecord,
        current = nil,
        timestamp = os.time(),
    }

    recordEvent(event)
    notify(event)
end

-- wraps Set/Delete at runtime instead of editing ObjectDatabase.lua directly
if not ObjectDatabase._liveChangeWrapped then
    local originalSet = ObjectDatabase.Set
    local originalDelete = ObjectDatabase.Delete

    ObjectDatabase.Set = function(fullPath, record)
        local previousRecord = ObjectDatabase.Get(fullPath)
        originalSet(fullPath, record)
        handleSetMutation(fullPath, previousRecord, record)
    end

    ObjectDatabase.Delete = function(fullPath)
        local previousRecord = ObjectDatabase.Get(fullPath)
        originalDelete(fullPath)
        handleDeleteMutation(fullPath, previousRecord)
    end

    ObjectDatabase._liveChangeWrapped = true
    Logger.Info("LiveChangeDetector", "Now observing ObjectDatabase mutations in real time")
end

function LiveChangeDetector.Subscribe(callback)
    if type(callback) ~= "function" then
        return false, "Listener must be a function"
    end
    table.insert(LiveChangeDetector._listeners, callback)
    return true
end

function LiveChangeDetector.Unsubscribe(callback)
    for i, existing in ipairs(LiveChangeDetector._listeners) do
        if existing == callback then
            table.remove(LiveChangeDetector._listeners, i)
            return true
        end
    end
    return false
end

--- Returns the most recent N events (default: all buffered, up to
--- MAX_EVENTS), newest last.
function LiveChangeDetector.GetRecentEvents(n)
    if not n or n >= #LiveChangeDetector._recentEvents then
        return LiveChangeDetector._recentEvents
    end

    local result = {}
    local startIndex = #LiveChangeDetector._recentEvents - n + 1
    for i = startIndex, #LiveChangeDetector._recentEvents do
        table.insert(result, LiveChangeDetector._recentEvents[i])
    end
    return result
end

function LiveChangeDetector.ClearEventHistory()
    LiveChangeDetector._recentEvents = {}
end

InspectorEngine.LiveChanges = LiveChangeDetector

return LiveChangeDetector
end)()

-- NPCIntelligence
local NPCIntelligence = (function()
-- npc tracking


local NPCIntelligence = {}

NPCIntelligence._tracked = {}      -- fullPath -> npc record
NPCIntelligence._trackedOrder = {} -- array of fullPath, for the round-robin cursor
NPCIntelligence._cursor = 1
NPCIntelligence._running = false

local function resolveInstance(fullPath)
    local parts = {}
    for part in string.gmatch(fullPath, "[^%.]+") do
        table.insert(parts, part)
    end
    if #parts == 0 then return nil end

    local ok, current = pcall(function() return game:GetService(parts[1]) end)
    if not ok or not current then
        ok, current = pcall(function() return game:FindFirstChild(parts[1]) end)
        if not ok then return nil end
    end

    for i = 2, #parts do
        if not current then return nil end
        local stepOk, next_ = pcall(function() return current:FindFirstChild(parts[i]) end)
        if not stepOk then return nil end
        current = next_
    end

    return current
end

local function isNPCModel(instance)
    if not instance or not instance:IsA("Model") then return false end
    local ok, humanoid = pcall(function() return instance:FindFirstChildOfClass("Humanoid") end)
    return ok and humanoid ~= nil
end

local function getLevel(instance)
    local attrOk, level = pcall(function() return instance:GetAttribute("Level") end)
    if attrOk and level ~= nil then return level end

    local child = instance:FindFirstChild("Level")
    if child and child:IsA("ValueBase") then
        local ok, value = pcall(function() return child.Value end)
        if ok then return value end
    end

    return nil
end

local function getTeam(instance)
    local attrOk, team = pcall(function() return instance:GetAttribute("Team") end)
    if attrOk and team ~= nil then return tostring(team) end

    local child = instance:FindFirstChild("Team")
    if child and child:IsA("ValueBase") then
        local ok, value = pcall(function() return tostring(child.Value) end)
        if ok then return value end
    end

    return nil
end

local function getPosition(instance)
    local root = instance:FindFirstChild("HumanoidRootPart") or instance.PrimaryPart
    if not root then return nil end
    local ok, position = pcall(function() return root.Position end)
    return ok and position or nil
end

local function buildRecord(instance, fullPath, now)
    local humanoid = instance:FindFirstChildOfClass("Humanoid")
    local position = getPosition(instance)

    local displayName = instance.Name
    if humanoid then
        local ok, dn = pcall(function() return humanoid.DisplayName end)
        if ok and dn and dn ~= "" then
            displayName = dn
        end
    end

    local health, maxHealth = 0, 0
    if humanoid then
        pcall(function() health = humanoid.Health end)
        pcall(function() maxHealth = humanoid.MaxHealth end)
    end

    return {
        instance = instance,
        humanoid = humanoid,
        displayName = displayName,
        internalName = instance.Name,
        path = fullPath,
        spawnPosition = position,
        currentPosition = position,
        alive = health > 0,
        health = health,
        maxHealth = maxHealth,
        team = getTeam(instance),
        level = getLevel(instance),
        firstDetected = now,
        lastUpdated = now,
        _goneSince = nil,
    }
end

local function onDiscoveryEvent(event)
    if event.changeType ~= "Added" then return end
    if not event.current or event.current.className ~= "Model" then return end
    if NPCIntelligence._tracked[event.fullPath] then return end -- already tracked

    local instance = resolveInstance(event.fullPath)
    if not isNPCModel(instance) then return end

    local record = buildRecord(instance, event.fullPath, os.time())
    NPCIntelligence._tracked[event.fullPath] = record
    table.insert(NPCIntelligence._trackedOrder, event.fullPath)
end

local function refreshOne(npc, now)
    local instanceGone = not npc.instance or not npc.instance.Parent

    if instanceGone then
        if not npc._goneSince then
            npc._goneSince = now
        end
        return
    end

    npc._goneSince = nil

    if npc.humanoid then
        local ok, health = pcall(function() return npc.humanoid.Health end)
        if ok then
            npc.health = health
            npc.alive = health > 0
        end
    end

    local position = getPosition(npc.instance)
    if position then
        npc.currentPosition = position
    end

    npc.lastUpdated = now
end

local function pruneStale(now)
    local graceSeconds = Config.Get("Intelligence.NPCPruneAfterSeconds") or 60
    local newOrder = {}

    for _, path in ipairs(NPCIntelligence._trackedOrder) do
        local npc = NPCIntelligence._tracked[path]
        if npc and npc._goneSince and (now - npc._goneSince) >= graceSeconds then
            NPCIntelligence._tracked[path] = nil
        else
            table.insert(newOrder, path)
        end
    end

    NPCIntelligence._trackedOrder = newOrder
    if NPCIntelligence._cursor > #NPCIntelligence._trackedOrder then
        NPCIntelligence._cursor = 1
    end
end

function NPCIntelligence.Start()
    if NPCIntelligence._running then
        Logger.Warn("NPCIntelligence", "Start called but already running")
        return false
    end

    LiveChangeDetector.Subscribe(onDiscoveryEvent)
    NPCIntelligence._running = true

    local lastPrune = os.clock()

    task.spawn(function()
        while NPCIntelligence._running do
            local now = os.time()
            local batchSize = Config.Get("Intelligence.NPCBatchSize") or 20
            local total = #NPCIntelligence._trackedOrder

            for i = 1, math.min(batchSize, total) do
                local index = ((NPCIntelligence._cursor - 1 + i - 1) % total) + 1
                local path = NPCIntelligence._trackedOrder[index]
                local npc = NPCIntelligence._tracked[path]
                if npc then
                    refreshOne(npc, now)
                end
            end

            if total > 0 then
                NPCIntelligence._cursor = ((NPCIntelligence._cursor - 1 + math.min(batchSize, total)) % total) + 1
            end

            local pruneInterval = Config.Get("Intelligence.NPCPruneAfterSeconds") or 60
            if (os.clock() - lastPrune) >= pruneInterval then
                pruneStale(now)
                lastPrune = os.clock()
            end

            task.wait()
        end
    end)

    Logger.Info("NPCIntelligence", "Started")
    return true
end

function NPCIntelligence.Stop()
    NPCIntelligence._running = false
    LiveChangeDetector.Unsubscribe(onDiscoveryEvent)
    Logger.Info("NPCIntelligence", "Stopped")
end

function NPCIntelligence.GetNPC(fullPath)
    return NPCIntelligence._tracked[fullPath]
end

function NPCIntelligence.GetAllNPCs()
    return NPCIntelligence._tracked
end

function NPCIntelligence.GetAliveNPCs()
    local result = {}
    for path, npc in pairs(NPCIntelligence._tracked) do
        if npc.alive then result[path] = npc end
    end
    return result
end

function NPCIntelligence.GetDeadNPCs()
    local result = {}
    for path, npc in pairs(NPCIntelligence._tracked) do
        if not npc.alive then result[path] = npc end
    end
    return result
end

function NPCIntelligence.Count()
    return #NPCIntelligence._trackedOrder
end

InspectorEngine.NPCs = NPCIntelligence

return NPCIntelligence
end)()

-- BossIntelligence
local BossIntelligence = (function()
-- boss lifecycle


local BossIntelligence = {}

BossIntelligence._tracked = {}
BossIntelligence._running = false

local TRAIL_MAX = 10
local HISTORY_MAX = 20

local function isTargetBoss(name)
    local targets = Config.Get("BossManager.TargetBosses") or {}
    for _, targetName in ipairs(targets) do
        if targetName == name then return true end
    end
    return false
end

local function ensureTracked(bossName)
    if not BossIntelligence._tracked[bossName] then
        BossIntelligence._tracked[bossName] = {
            state = "Untracked",
            currentPath = nil,
            spawnTime = nil,
            deathTime = nil,
            health = 0,
            maxHealth = 0,
            currentPosition = nil,
            trail = {},
            history = {},
        }
    end
    return BossIntelligence._tracked[bossName]
end

local function pushTrail(entry, position, now)
    table.insert(entry.trail, { position = position, timestamp = now })
    if #entry.trail > TRAIL_MAX then
        table.remove(entry.trail, 1)
    end
end

local function pushHistory(entry, record)
    table.insert(entry.history, record)
    if #entry.history > HISTORY_MAX then
        table.remove(entry.history, 1)
    end
end

local function tick()
    local now = os.time()
    local npcs = NPCIntelligence.GetAllNPCs()

    -- Track which boss names were actually seen alive this tick, so a
    -- boss with no currently-alive Instance can be distinguished below.
    local seenAlive = {}

    for path, npc in pairs(npcs) do
        if isTargetBoss(npc.internalName) then
            local entry = ensureTracked(npc.internalName)

            if npc.alive then
                seenAlive[npc.internalName] = true

                if entry.state ~= "Alive" or entry.currentPath ~= path then
                    -- New spawn (either first sighting, or a fresh
                    -- Instance after a prior death/untrack).
                    local respawnSeconds = nil
                    if entry.deathTime then
                        respawnSeconds = now - entry.deathTime
                    end

                    entry.state = "Alive"
                    entry.currentPath = path
                    entry.spawnTime = now
                    entry.deathTime = nil
                    entry.trail = {}

                    Logger.Info("BossIntelligence", string.format(
                        "%s spawned%s", npc.internalName,
                        respawnSeconds and string.format(" (respawned after %ds)", respawnSeconds) or ""
                    ))
                end

                entry.health = npc.health
                entry.maxHealth = npc.maxHealth
                entry.currentPosition = npc.currentPosition
                if npc.currentPosition then
                    pushTrail(entry, npc.currentPosition, now)
                end
            elseif entry.state == "Alive" and entry.currentPath == path then
                -- health hit 0 while tracked, not just despawned
                entry.state = "Dead"
                entry.deathTime = now
                entry.health = 0

                pushHistory(entry, {
                    path = entry.currentPath,
                    spawnTime = entry.spawnTime,
                    deathTime = entry.deathTime,
                })

                Logger.Info("BossIntelligence", npc.internalName .. " died")
            end
        end
    end

    for bossName, entry in pairs(BossIntelligence._tracked) do
        -- disappeared without a recorded death is ambiguous, not dead
        if entry.state == "Alive" and not seenAlive[bossName] then
            entry.state = "Untracked"
        end
    end
end

function BossIntelligence.Start()
    if BossIntelligence._running then
        Logger.Warn("BossIntelligence", "Start called but already running")
        return false
    end

    BossIntelligence._running = true

    task.spawn(function()
        while BossIntelligence._running do
            pcall(tick)
            task.wait(Config.Get("Intelligence.BossTickIntervalSeconds") or 2)
        end
    end)

    Logger.Info("BossIntelligence", "Started")
    return true
end

function BossIntelligence.Stop()
    BossIntelligence._running = false
    Logger.Info("BossIntelligence", "Stopped")
end

function BossIntelligence.GetState(bossName)
    return BossIntelligence._tracked[bossName]
end

function BossIntelligence.GetAllTracked()
    return BossIntelligence._tracked
end

function BossIntelligence.GetHistory(bossName)
    local entry = BossIntelligence._tracked[bossName]
    return entry and entry.history or {}
end

--- Average respawn time across recorded history for a boss, or nil if
--- fewer than 2 death->spawn cycles have been observed this session.
function BossIntelligence.GetAverageRespawnSeconds(bossName)
    local entry = BossIntelligence._tracked[bossName]
    if not entry or #entry.history < 2 then return nil end

    local total, count = 0, 0
    for i = 2, #entry.history do
        local gap = entry.history[i].spawnTime - entry.history[i - 1].deathTime
        if gap and gap >= 0 then
            total = total + gap
            count = count + 1
        end
    end

    return count > 0 and (total / count) or nil
end

InspectorEngine.Bosses = BossIntelligence

return BossIntelligence
end)()

-- IslandIntelligence
local IslandIntelligence = (function()
-- island tracking


local IslandIntelligence = {}

IslandIntelligence._tracked = {}
IslandIntelligence._trackedOrder = {}
IslandIntelligence._running = false

local APPEARANCES_MAX = 20

local function resolveInstance(fullPath)
    local parts = {}
    for part in string.gmatch(fullPath, "[^%.]+") do
        table.insert(parts, part)
    end
    if #parts == 0 then return nil end

    local ok, current = pcall(function() return game:GetService(parts[1]) end)
    if not ok or not current then
        ok, current = pcall(function() return game:FindFirstChild(parts[1]) end)
        if not ok then return nil end
    end

    for i = 2, #parts do
        if not current then return nil end
        local stepOk, next_ = pcall(function() return current:FindFirstChild(parts[i]) end)
        if not stepOk then return nil end
        current = next_
    end

    return current
end

local function tryGetPosition(instance)
    if not instance then return nil end

    if instance:IsA("BasePart") then
        local ok, pos = pcall(function() return instance.Position end)
        return ok and pos or nil
    end

    if instance:IsA("Model") then
        local ok, primary = pcall(function() return instance.PrimaryPart end)
        if ok and primary then
            local posOk, pos = pcall(function() return primary.Position end)
            if posOk then return pos end
        end
        local partOk, part = pcall(function() return instance:FindFirstChildWhichIsA("BasePart", true) end)
        if partOk and part then
            local posOk2, pos2 = pcall(function() return part.Position end)
            if posOk2 then return pos2 end
        end
    end

    return nil
end

local function isUnderLocationsContainer(parentPath)
    local containerPath = Config.Get("Detection.LocationsContainerPath") or "_WorldOrigin.Locations"
    return parentPath == ("Workspace." .. containerPath)
end

local function pushAppearance(entry, appearance)
    table.insert(entry.appearances, appearance)
    if #entry.appearances > APPEARANCES_MAX then
        table.remove(entry.appearances, 1)
    end
end

local function onDiscoveryEvent(event)
    if event.changeType ~= "Added" then return end
    if not event.current then return end
    if not isUnderLocationsContainer(event.current.parentPath) then return end
    if IslandIntelligence._tracked[event.fullPath] then return end

    local now = os.time()
    local instance = resolveInstance(event.fullPath)

    local entry = {
        name = event.current.name,
        displayName = event.current.name,
        instance = instance,
        firstSeen = now,
        lastSeen = now,
        currentlyPresent = true,
        position = tryGetPosition(instance),
        _goneSince = nil,
    }
    entry.appearances = { { start = now, ended = nil, durationSeconds = nil } }

    IslandIntelligence._tracked[event.fullPath] = entry
    table.insert(IslandIntelligence._trackedOrder, event.fullPath)

    Logger.Info("IslandIntelligence", entry.displayName .. " appeared")
end

local function refreshOne(entry, now)
    local instanceGone = not entry.instance or not entry.instance.Parent

    if instanceGone then
        if not entry._goneSince then
            entry._goneSince = now
        end
        return
    end

    entry._goneSince = nil
    entry.lastSeen = now

    local position = tryGetPosition(entry.instance)
    if position then
        entry.position = position
    end
end

local function finalizeDisappearance(entry, now)
    entry.currentlyPresent = false

    local lastAppearance = entry.appearances[#entry.appearances]
    if lastAppearance and not lastAppearance.ended then
        lastAppearance.ended = now
        lastAppearance.durationSeconds = now - lastAppearance.start
    end
end

function IslandIntelligence.Start()
    if IslandIntelligence._running then
        Logger.Warn("IslandIntelligence", "Start called but already running")
        return false
    end

    LiveChangeDetector.Subscribe(onDiscoveryEvent)
    IslandIntelligence._running = true

    task.spawn(function()
        while IslandIntelligence._running do
            local now = os.time()
            local graceSeconds = Config.Get("Intelligence.IslandGoneGraceSeconds") or 30

            for _, path in ipairs(IslandIntelligence._trackedOrder) do
                local entry = IslandIntelligence._tracked[path]
                if entry then
                    if entry.currentlyPresent then
                        refreshOne(entry, now)
                        if entry._goneSince and (now - entry._goneSince) >= graceSeconds then
                            finalizeDisappearance(entry, now)
                        end
                    end
                end
            end

            task.wait(Config.Get("Intelligence.IslandTickIntervalSeconds") or 5)
        end
    end)

    Logger.Info("IslandIntelligence", "Started")
    return true
end

function IslandIntelligence.Stop()
    IslandIntelligence._running = false
    LiveChangeDetector.Unsubscribe(onDiscoveryEvent)
    Logger.Info("IslandIntelligence", "Stopped")
end

function IslandIntelligence.GetIsland(fullPath)
    return IslandIntelligence._tracked[fullPath]
end

function IslandIntelligence.GetAllIslands()
    return IslandIntelligence._tracked
end

function IslandIntelligence.GetCurrentlyPresent()
    local result = {}
    for path, entry in pairs(IslandIntelligence._tracked) do
        if entry.currentlyPresent then result[path] = entry end
    end
    return result
end

function IslandIntelligence.GetAverageDurationSeconds(name)
    local total, count = 0, 0
    for _, entry in pairs(IslandIntelligence._tracked) do
        if entry.name == name then
            for _, appearance in ipairs(entry.appearances) do
                if appearance.durationSeconds then
                    total = total + appearance.durationSeconds
                    count = count + 1
                end
            end
        end
    end
    return count > 0 and (total / count) or nil
end

InspectorEngine.Islands = IslandIntelligence

return IslandIntelligence
end)()

-- EventIntelligence
local EventIntelligence = (function()
-- event tracking


local EventIntelligence = {}

local EVENT_KEYS = {
    "FactoryRaid", "MirageIsland", "Leviathan", "PrehistoricIsland",
    "ElitePirates", "FullMoon", "CastleRaid", "KitsuneShrine",
    "SeaBeast", "TerrorShark", "GhostShip", "PirateRaid",
}

-- eventKey -> { active, startTime, lastActiveTime, history = {...} (bounded) }
EventIntelligence._tracked = {}
EventIntelligence._running = false

local HISTORY_MAX = 20

local Workspace, Lighting = nil, nil
pcall(function()
    Workspace = game:GetService("Workspace")
    Lighting = game:GetService("Lighting")
end)

local function ensureTracked(eventKey)
    if not EventIntelligence._tracked[eventKey] then
        EventIntelligence._tracked[eventKey] = {
            active = false,
            startTime = nil,
            lastActiveTime = nil,
            history = {},
        }
    end
    return EventIntelligence._tracked[eventKey]
end

local function resolveContainer(pathString)
    if not Workspace or not pathString then return nil end
    local node = Workspace
    for key in string.gmatch(pathString, "[^%.]+") do
        if not node then return nil end
        node = node:FindFirstChild(key)
    end
    return node
end

local function checkAttribute(eventConfig)
    local locationsPath = Config.Get("Detection.LocationsContainerPath") or "_WorldOrigin.Locations"
    local container = resolveContainer(locationsPath)
    if not container or not eventConfig.LocationName then return false end

    local instance = container:FindFirstChild(eventConfig.LocationName)
    if not instance then return false end

    local ok, value = pcall(function() return instance:GetAttribute(eventConfig.ActiveAttributeName) end)
    return ok and value == true
end

local function checkModelPresence(eventConfig)
    local enemiesPath = Config.Get("Detection.EnemiesContainerPath") or "Enemies"
    local container = resolveContainer(enemiesPath)
    if not container or not eventConfig.ModelName then return false end

    local instance = container:FindFirstChild(eventConfig.ModelName)
    return instance ~= nil and instance:IsA("Model")
end

local function checkLocationPresence(eventConfig)
    local locationsPath = Config.Get("Detection.LocationsContainerPath") or "_WorldOrigin.Locations"
    local container = resolveContainer(locationsPath)
    if not container or not eventConfig.LocationName then return false end

    return container:FindFirstChild(eventConfig.LocationName) ~= nil
end

local function checkFullMoon(eventConfig)
    if not Lighting then return false end

    if eventConfig.StateAttributeName then
        local ok, value = pcall(function() return Lighting:GetAttribute(eventConfig.StateAttributeName) end)
        if ok and value ~= nil then return value == true end
    end

    local ok, clockTime = pcall(function() return Lighting.ClockTime end)
    if not ok then return false end

    local rangeStart = eventConfig.ClockTimeRangeStart or 0
    local rangeEnd = eventConfig.ClockTimeRangeEnd or 6
    return clockTime >= rangeStart and clockTime <= rangeEnd
end

--- Generic dispatcher: picks the right check based on which Config
--- fields the event actually has, per the module header's reasoning.
local function isEventActive(eventKey, eventConfig)
    if eventKey == "FullMoon" then
        return checkFullMoon(eventConfig)
    end
    if eventConfig.ActiveAttributeName then
        return checkAttribute(eventConfig)
    end
    if eventConfig.ModelName then
        return checkModelPresence(eventConfig)
    end
    if eventConfig.LocationName then
        return checkLocationPresence(eventConfig)
    end
    return false
end

local function pushHistory(entry, record)
    table.insert(entry.history, record)
    if #entry.history > HISTORY_MAX then
        table.remove(entry.history, 1)
    end
end

local function tick()
    local now = os.time()
    local seaEvents = Config.Get("SeaEvents") or {}

    for _, eventKey in ipairs(EVENT_KEYS) do
        local eventConfig = seaEvents[eventKey]
        if eventConfig and eventConfig.Enabled then
            local entry = ensureTracked(eventKey)
            local ok, active = pcall(isEventActive, eventKey, eventConfig)
            active = ok and active or false

            if active and not entry.active then
                entry.active = true
                entry.startTime = now
                Logger.Info("EventIntelligence", eventKey .. " became active")
            elseif not active and entry.active then
                entry.active = false
                local duration = entry.startTime and (now - entry.startTime) or nil
                pushHistory(entry, {
                    startTime = entry.startTime,
                    endTime = now,
                    durationSeconds = duration,
                })
                Logger.Info("EventIntelligence", string.format(
                    "%s ended%s", eventKey,
                    duration and string.format(" (lasted %ds)", duration) or ""
                ))
            end

            if active then
                entry.lastActiveTime = now
            end
        end
    end
end

function EventIntelligence.Start()
    if EventIntelligence._running then
        Logger.Warn("EventIntelligence", "Start called but already running")
        return false
    end

    EventIntelligence._running = true

    task.spawn(function()
        while EventIntelligence._running do
            pcall(tick)
            task.wait(Config.Get("Intelligence.EventTickIntervalSeconds") or 5)
        end
    end)

    Logger.Info("EventIntelligence", "Started")
    return true
end

function EventIntelligence.Stop()
    EventIntelligence._running = false
    Logger.Info("EventIntelligence", "Stopped")
end

function EventIntelligence.GetState(eventKey)
    return EventIntelligence._tracked[eventKey]
end

function EventIntelligence.GetAllTracked()
    return EventIntelligence._tracked
end

function EventIntelligence.GetHistory(eventKey)
    local entry = EventIntelligence._tracked[eventKey]
    return entry and entry.history or {}
end

function EventIntelligence.GetAverageDurationSeconds(eventKey)
    local entry = EventIntelligence._tracked[eventKey]
    if not entry or #entry.history == 0 then return nil end

    local total, count = 0, 0
    for _, record in ipairs(entry.history) do
        if record.durationSeconds then
            total = total + record.durationSeconds
            count = count + 1
        end
    end
    return count > 0 and (total / count) or nil
end

InspectorEngine.Events = EventIntelligence

return EventIntelligence
end)()

-- EnvironmentIntelligence
local EnvironmentIntelligence = (function()
-- environment tracking


local EnvironmentIntelligence = {}

EnvironmentIntelligence._state = {}
EnvironmentIntelligence._dayNightHistory = {}
EnvironmentIntelligence._seaHistory = {}
EnvironmentIntelligence._running = false

local HISTORY_MAX = 20

local Lighting = nil
pcall(function() Lighting = game:GetService("Lighting") end)

local function isDaytime(clockTime)
    local dayStart = Config.Get("Environment.DayStartClockTime") or 6
    local dayEnd = Config.Get("Environment.DayEndClockTime") or 18
    return clockTime >= dayStart and clockTime < dayEnd
end

--- [verify]: only reads something if the Inspector has confirmed a
--- real Attribute name for it. Returns nil (unknown), never a guess.
local function readWeather()
    local attrName = Config.Get("Environment.WeatherAttributeName")
    if not attrName or not Lighting then return nil end
    local ok, value = pcall(function() return Lighting:GetAttribute(attrName) end)
    return ok and value or nil
end

local function readAtmosphere()
    if not Lighting then return nil end
    local ok, atmosphere = pcall(function() return Lighting:FindFirstChildOfClass("Atmosphere") end)
    if not ok or not atmosphere then return nil end

    local result = {}
    pcall(function() result.density = atmosphere.Density end)
    pcall(function() result.haze = atmosphere.Haze end)
    pcall(function() result.glare = atmosphere.Glare end)
    return result
end

local function readSky()
    if not Lighting then return nil end
    local ok, sky = pcall(function() return Lighting:FindFirstChildOfClass("Sky") end)
    if not ok or not sky then return nil end
    return { name = sky.Name }
end

local function pushHistory(historyTable, record)
    table.insert(historyTable, record)
    if #historyTable > HISTORY_MAX then
        table.remove(historyTable, 1)
    end
end

local function tick()
    if not Lighting then return end
    local now = os.time()

    local clockOk, clockTime = pcall(function() return Lighting.ClockTime end)
    if not clockOk then return end

    local nowDaytime = isDaytime(clockTime)
    local wasDaytime = EnvironmentIntelligence._state.isDaytime

    if wasDaytime ~= nil and wasDaytime ~= nowDaytime then
        pushHistory(EnvironmentIntelligence._dayNightHistory, {
            from = wasDaytime and "Day" or "Night",
            to = nowDaytime and "Day" or "Night",
            timestamp = now,
        })
        Logger.Info("EnvironmentIntelligence", (nowDaytime and "Day" or "Night") .. " began")
    end

    local currentSea = SeaManager.GetCurrentSea()
    local previousSea = EnvironmentIntelligence._state.sea
    if previousSea and currentSea and previousSea ~= currentSea then
        pushHistory(EnvironmentIntelligence._seaHistory, {
            from = previousSea, to = currentSea, timestamp = now,
        })
        Logger.Info("EnvironmentIntelligence", "Sea changed: " .. previousSea .. " -> " .. currentSea)
    end

    local timeOfDayOk, timeOfDay = pcall(function() return Lighting.TimeOfDay end)
    local fogStartOk, fogStart = pcall(function() return Lighting.FogStart end)
    local fogEndOk, fogEnd = pcall(function() return Lighting.FogEnd end)
    local fogColorOk, fogColor = pcall(function() return Lighting.FogColor end)
    local brightnessOk, brightness = pcall(function() return Lighting.Brightness end)

    EnvironmentIntelligence._state = {
        clockTime = clockTime,
        timeOfDay = timeOfDayOk and timeOfDay or nil,
        isDaytime = nowDaytime,
        fogStart = fogStartOk and fogStart or nil,
        fogEnd = fogEndOk and fogEnd or nil,
        fogColor = fogColorOk and fogColor or nil,
        brightness = brightnessOk and brightness or nil,
        atmosphere = readAtmosphere(),
        sky = readSky(),
        weather = readWeather(), -- [verify], nil unless configured
        sea = currentSea,
        lastUpdated = now,
    }
end

function EnvironmentIntelligence.Start()
    if EnvironmentIntelligence._running then
        Logger.Warn("EnvironmentIntelligence", "Start called but already running")
        return false
    end

    EnvironmentIntelligence._running = true

    task.spawn(function()
        while EnvironmentIntelligence._running do
            pcall(tick)
            task.wait(Config.Get("Intelligence.EnvironmentTickIntervalSeconds") or 10)
        end
    end)

    Logger.Info("EnvironmentIntelligence", "Started")
    return true
end

function EnvironmentIntelligence.Stop()
    EnvironmentIntelligence._running = false
    Logger.Info("EnvironmentIntelligence", "Stopped")
end

function EnvironmentIntelligence.GetState()
    return EnvironmentIntelligence._state
end

function EnvironmentIntelligence.GetDayNightHistory()
    return EnvironmentIntelligence._dayNightHistory
end

function EnvironmentIntelligence.GetSeaHistory()
    return EnvironmentIntelligence._seaHistory
end

InspectorEngine.Environment = EnvironmentIntelligence

return EnvironmentIntelligence
end)()

-- StatisticsEngine
local StatisticsEngine = (function()
-- stats


local StatisticsEngine = {}

StatisticsEngine._snapshot = {}
StatisticsEngine._running = false

local function computeClassCounts()
    local counts = {}
    for _, record in pairs(ObjectDatabase.All()) do
        counts[record.className] = (counts[record.className] or 0) + 1
    end
    return counts
end

local function computeAverageBossLifetime()
    local total, count = 0, 0
    for _, entry in pairs(BossIntelligence.GetAllTracked()) do
        for _, cycle in ipairs(entry.history) do
            if cycle.spawnTime and cycle.deathTime then
                total = total + (cycle.deathTime - cycle.spawnTime)
                count = count + 1
            end
        end
    end
    return count > 0 and (total / count) or nil
end

local function computeAverageEventDuration()
    local total, count = 0, 0
    for eventKey, entry in pairs(EventIntelligence.GetAllTracked()) do
        for _, record in ipairs(entry.history) do
            if record.durationSeconds then
                total = total + record.durationSeconds
                count = count + 1
            end
        end
    end
    return count > 0 and (total / count) or nil
end

local function computeBossSpawnCount()
    local total = 0
    for _, entry in pairs(BossIntelligence.GetAllTracked()) do
        total = total + #entry.history
        if entry.state == "Alive" then
            total = total + 1 -- current spawn hasn't completed a cycle yet, still counts
        end
    end
    return total
end

local function computeEventOccurrenceCount()
    local total = 0
    for _, entry in pairs(EventIntelligence.GetAllTracked()) do
        total = total + #entry.history
        if entry.active then
            total = total + 1
        end
    end
    return total
end

local function recompute()
    local classCounts = computeClassCounts()

    StatisticsEngine._snapshot = {
        timestamp = os.time(),

        -- Boss statistics
        bossSpawnCount = computeBossSpawnCount(),
        averageBossLifetimeSeconds = computeAverageBossLifetime(),
        bossesFound = VerificationEngine.GetTotalFound(), -- existing, reused

        -- NPC statistics
        npcCount = NPCIntelligence.Count(),

        -- Structural counts, from ObjectDatabase's class breakdown
        modelCount = classCounts.Model or 0,
        folderCount = classCounts.Folder or 0,
        moduleCount = classCounts.ModuleScript or 0,
        remoteCount = (classCounts.RemoteEvent or 0) + (classCounts.RemoteFunction or 0),
        totalObjectCount = ObjectDatabase.Count(),
        classCounts = classCounts,

        -- Event statistics
        eventCount = computeEventOccurrenceCount(),
        averageEventDurationSeconds = computeAverageEventDuration(),

        -- Island statistics
        islandsTracked = (function()
            local n = 0
            for _ in pairs(IslandIntelligence.GetAllIslands()) do n = n + 1 end
            return n
        end)(),

        -- Webhook statistics (existing, reused)
        webhooksSent = Webhook.GetTotalSent(),
        webhookQueueLength = Webhook.GetQueueLength(),
    }
end

function StatisticsEngine.Start()
    if StatisticsEngine._running then
        Logger.Warn("StatisticsEngine", "Start called but already running")
        return false
    end

    StatisticsEngine._running = true
    recompute() -- populate immediately rather than waiting for the first tick

    task.spawn(function()
        while StatisticsEngine._running do
            task.wait(Config.Get("Intelligence.StatisticsTickIntervalSeconds") or 15)
            pcall(recompute)
        end
    end)

    Logger.Info("StatisticsEngine", "Started")
    return true
end

function StatisticsEngine.Stop()
    StatisticsEngine._running = false
    Logger.Info("StatisticsEngine", "Stopped")
end

--- Returns the cached snapshot (see module header for why this isn't
--- computed fresh on every call).
function StatisticsEngine.GetSnapshot()
    return StatisticsEngine._snapshot
end

function StatisticsEngine.Refresh()
    recompute()
    return StatisticsEngine._snapshot
end

InspectorEngine.Statistics = StatisticsEngine

return StatisticsEngine
end)()

-- HistoryEngine
local HistoryEngine = (function()
-- timeline


local HistoryEngine = {}

HistoryEngine._timeline = {}
HistoryEngine._running = false

local TIMELINE_MAX = 150

local function collectBossEntries(out)
    for bossName, entry in pairs(BossIntelligence.GetAllTracked()) do
        for _, cycle in ipairs(entry.history) do
            if cycle.spawnTime then
                table.insert(out, {
                    type = "BossSpawn",
                    label = bossName .. " spawned",
                    timestamp = cycle.spawnTime,
                    detail = cycle,
                })
            end
            if cycle.deathTime then
                table.insert(out, {
                    type = "BossDeath",
                    label = bossName .. " died",
                    timestamp = cycle.deathTime,
                    detail = cycle,
                })
            end
        end
    end
end

local function collectEventEntries(out)
    for eventKey, entry in pairs(EventIntelligence.GetAllTracked()) do
        for _, record in ipairs(entry.history) do
            if record.startTime then
                table.insert(out, {
                    type = "EventStart",
                    label = eventKey .. " began",
                    timestamp = record.startTime,
                    detail = record,
                })
            end
            if record.endTime then
                table.insert(out, {
                    type = "EventEnd",
                    label = eventKey .. " ended",
                    timestamp = record.endTime,
                    detail = record,
                })
            end
        end
    end
end

local function collectIslandEntries(out)
    for path, entry in pairs(IslandIntelligence.GetAllIslands()) do
        for _, appearance in ipairs(entry.appearances) do
            if appearance.start then
                table.insert(out, {
                    type = "IslandAppeared",
                    label = entry.displayName .. " appeared",
                    timestamp = appearance.start,
                    detail = appearance,
                })
            end
            if appearance.ended then
                table.insert(out, {
                    type = "IslandDisappeared",
                    label = entry.displayName .. " disappeared",
                    timestamp = appearance.ended,
                    detail = appearance,
                })
            end
        end
    end
end

local function collectStructuralEntries(out)
    for _, event in ipairs(LiveChangeDetector.GetRecentEvents()) do
        table.insert(out, {
            type = "StructuralChange",
            label = event.changeType .. ": " .. event.fullPath,
            timestamp = event.timestamp,
            detail = event,
        })
    end
end

local function rebuild()
    local merged = {}
    collectBossEntries(merged)
    collectEventEntries(merged)
    collectIslandEntries(merged)
    collectStructuralEntries(merged)

    table.sort(merged, function(a, b) return a.timestamp < b.timestamp end)

    if #merged > TIMELINE_MAX then
        local trimmed = {}
        local startIndex = #merged - TIMELINE_MAX + 1
        for i = startIndex, #merged do
            table.insert(trimmed, merged[i])
        end
        merged = trimmed
    end

    HistoryEngine._timeline = merged
end

function HistoryEngine.Start()
    if HistoryEngine._running then
        Logger.Warn("HistoryEngine", "Start called but already running")
        return false
    end

    HistoryEngine._running = true
    rebuild()

    task.spawn(function()
        while HistoryEngine._running do
            task.wait(Config.Get("Intelligence.HistoryTickIntervalSeconds") or 20)
            pcall(rebuild)
        end
    end)

    Logger.Info("HistoryEngine", "Started")
    return true
end

function HistoryEngine.Stop()
    HistoryEngine._running = false
    Logger.Info("HistoryEngine", "Stopped")
end

--- Returns the most recent `limit` timeline entries (default: all
--- cached, up to TIMELINE_MAX), oldest first.
function HistoryEngine.GetTimeline(limit)
    if not limit or limit >= #HistoryEngine._timeline then
        return HistoryEngine._timeline
    end

    local result = {}
    local startIndex = #HistoryEngine._timeline - limit + 1
    for i = startIndex, #HistoryEngine._timeline do
        table.insert(result, HistoryEngine._timeline[i])
    end
    return result
end

function HistoryEngine.GetByType(entryType)
    local result = {}
    for _, entry in ipairs(HistoryEngine._timeline) do
        if entry.type == entryType then
            table.insert(result, entry)
        end
    end
    return result
end

--- Forces an immediate rebuild, bypassing the tick interval.
function HistoryEngine.Refresh()
    rebuild()
    return HistoryEngine._timeline
end

InspectorEngine.History = HistoryEngine

return HistoryEngine
end)()

-- AlertEngine
local AlertEngine = (function()
-- alert engine


local AlertEngine = {}

AlertEngine._alerts = {}
AlertEngine._listeners = {}
AlertEngine._running = false
AlertEngine._lastProcessedCount = 0

local ALERTS_MAX = 100

local function isTargetBoss(name)
    local targets = Config.Get("BossManager.TargetBosses") or {}
    for _, targetName in ipairs(targets) do
        if targetName == name then return true end
    end
    return false
end

local function pushAlert(alertType, message, severity)
    local alert = {
        type = alertType,
        message = message,
        severity = severity or "info",
        timestamp = os.time(),
    }

    table.insert(AlertEngine._alerts, alert)
    if #AlertEngine._alerts > ALERTS_MAX then
        table.remove(AlertEngine._alerts, 1)
    end

    Logger.Info("AlertEngine", alertType .. ": " .. message)

    for _, listener in ipairs(AlertEngine._listeners) do
        pcall(listener, alert)
    end
end

-- converts one already-aggregated HistoryEngine entry into 0 or 1 alerts
local function classifyEntry(entry)
    if entry.type == "BossSpawn" then
        pushAlert("New Boss Detected", entry.label, "high")
        return
    end

    if entry.type == "EventStart" then
        pushAlert("New Event", entry.label, "medium")
        return
    end

    if entry.type == "IslandAppeared" then
        pushAlert("New Island", entry.label, "medium")
        return
    end

    if entry.type == "StructuralChange" then
        local event = entry.detail
        if event.changeType == "Added" and event.current then
            local className = event.current.className
            local name = event.current.name

            if className == "Folder" then
                pushAlert("New Folder", event.fullPath, "low")
            elseif className == "ModuleScript" then
                pushAlert("New Module", event.fullPath, "low")
            elseif className == "Model" and not isTargetBoss(name) then
                pushAlert("Unknown Model", event.fullPath, "low")
            end
        elseif event.changeType == "Removed" then
            pushAlert("Object Removed", event.fullPath, "low")
        end
        -- object renaming can only be detected by comparing two
        -- snapshots (SnapshotEngine/ChangeDetector), not from a live
        -- per-mutation stream — no "Object Renamed" alert fires here
    end
end

local function tick()
    local timeline = HistoryEngine.GetTimeline()
    for i = AlertEngine._lastProcessedCount + 1, #timeline do
        classifyEntry(timeline[i])
    end
    AlertEngine._lastProcessedCount = #timeline
end

function AlertEngine.Start()
    if AlertEngine._running then
        Logger.Warn("AlertEngine", "Start called but already running")
        return false
    end

    AlertEngine._running = true

    task.spawn(function()
        while AlertEngine._running do
            task.wait(Config.Get("Intelligence.AlertTickIntervalSeconds") or 5)
            pcall(tick)
        end
    end)

    Logger.Info("AlertEngine", "Started")
    return true
end

function AlertEngine.Stop()
    AlertEngine._running = false
    Logger.Info("AlertEngine", "Stopped")
end

function AlertEngine.Subscribe(callback)
    if type(callback) ~= "function" then
        return false, "Listener must be a function"
    end
    table.insert(AlertEngine._listeners, callback)
    return true
end

function AlertEngine.Unsubscribe(callback)
    for i, existing in ipairs(AlertEngine._listeners) do
        if existing == callback then
            table.remove(AlertEngine._listeners, i)
            return true
        end
    end
    return false
end

function AlertEngine.GetRecent(limit)
    if not limit or limit >= #AlertEngine._alerts then
        return AlertEngine._alerts
    end
    local result = {}
    local startIndex = #AlertEngine._alerts - limit + 1
    for i = startIndex, #AlertEngine._alerts do
        table.insert(result, AlertEngine._alerts[i])
    end
    return result
end

function AlertEngine.GetByType(alertType)
    local result = {}
    for _, alert in ipairs(AlertEngine._alerts) do
        if alert.type == alertType then
            table.insert(result, alert)
        end
    end
    return result
end

InspectorEngine.Alerts = AlertEngine

return AlertEngine
end)()

-- ExportEngine
local ExportEngine = (function()
-- export engine


local ExportEngine = {}

local HttpService = nil
pcall(function() HttpService = game:GetService("HttpService") end)

-- strips live Instance/Vector3 values down to plain, serializable data
local function sanitize(value)
    local t = typeof(value)

    if t == "Instance" then
        local ok, path = pcall(function() return value:GetFullName() end)
        return ok and path or tostring(value)
    end

    if t == "Vector3" then
        return { x = value.X, y = value.Y, z = value.Z }
    end

    if t == "table" then
        local result = {}
        local isArray = true
        local count = 0
        for k in pairs(value) do
            count = count + 1
            if type(k) ~= "number" then isArray = false end
        end

        if isArray and count == #value then
            for i, v in ipairs(value) do
                result[i] = sanitize(v)
            end
        else
            for k, v in pairs(value) do
                result[tostring(k)] = sanitize(v)
            end
        end
        return result
    end

    if t == "number" or t == "string" or t == "boolean" or value == nil then
        return value
    end

    return tostring(value)
end

function ExportEngine.ToJSON(data)
    if not HttpService then
        return nil, "HttpService unavailable"
    end
    local ok, result = pcall(function()
        return HttpService:JSONEncode(sanitize(data))
    end)
    if not ok then
        return nil, tostring(result)
    end
    return result, nil
end

-- flat key/value table -> a markdown bullet list; array of uniform
-- records -> a markdown table
function ExportEngine.ToMarkdown(data, title)
    local lines = {}
    if title then
        table.insert(lines, "# " .. title)
        table.insert(lines, "")
    end

    if type(data) ~= "table" then
        table.insert(lines, tostring(data))
        return table.concat(lines, "\n")
    end

    local isArray = #data > 0
    if isArray and type(data[1]) == "table" then
        local headers = {}
        for k in pairs(data[1]) do
            table.insert(headers, k)
        end
        table.sort(headers)

        table.insert(lines, "| " .. table.concat(headers, " | ") .. " |")
        table.insert(lines, "|" .. string.rep(" --- |", #headers))

        for _, row in ipairs(data) do
            local cells = {}
            for _, h in ipairs(headers) do
                table.insert(cells, tostring(row[h] or ""))
            end
            table.insert(lines, "| " .. table.concat(cells, " | ") .. " |")
        end
    else
        local keys = {}
        for k in pairs(data) do
            table.insert(keys, k)
        end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)

        for _, k in ipairs(keys) do
            local v = data[k]
            if type(v) == "table" then
                table.insert(lines, "- **" .. tostring(k) .. "**: " .. (ExportEngine.ToJSON(v) or "?"))
            else
                table.insert(lines, "- **" .. tostring(k) .. "**: " .. tostring(v))
            end
        end
    end

    return table.concat(lines, "\n")
end

-- array of uniform records -> CSV, using the first record's keys as headers
function ExportEngine.ToCSV(rows)
    if type(rows) ~= "table" or #rows == 0 then
        return ""
    end

    local headers = {}
    for k in pairs(rows[1]) do
        table.insert(headers, k)
    end
    table.sort(headers)

    local function escape(value)
        local s = tostring(value)
        if s:find('[,"\n]') then
            s = '"' .. s:gsub('"', '""') .. '"'
        end
        return s
    end

    local lines = { table.concat(headers, ",") }
    for _, row in ipairs(rows) do
        local cells = {}
        for _, h in ipairs(headers) do
            table.insert(cells, escape(row[h] or ""))
        end
        table.insert(lines, table.concat(cells, ","))
    end

    return table.concat(lines, "\n")
end

local function writeToFile(filename, content)
    local ok, supported = pcall(function() return writefile ~= nil end)
    if not ok or not supported then
        Logger.Warn("ExportEngine", "writefile unavailable, cannot save " .. filename)
        return false
    end
    pcall(writefile, filename, content)
    Logger.Info("ExportEngine", "Exported " .. filename)
    return true
end

function ExportEngine.ExportStatistics(format)
    local data = StatisticsEngine.GetSnapshot()
    format = format or "json"

    if format == "json" then
        local content = ExportEngine.ToJSON(data)
        if content then writeToFile("Lumexa_Statistics.json", content) end
        return content
    elseif format == "markdown" then
        local content = ExportEngine.ToMarkdown(data, "Lumexa Statistics")
        writeToFile("Lumexa_Statistics.md", content)
        return content
    elseif format == "csv" then
        local content = ExportEngine.ToCSV({ data })
        writeToFile("Lumexa_Statistics.csv", content)
        return content
    end

    return nil, "Unknown format: " .. tostring(format)
end

function ExportEngine.ExportHistory(format)
    local data = HistoryEngine.GetTimeline()
    format = format or "json"

    if format == "json" then
        local content = ExportEngine.ToJSON(data)
        if content then writeToFile("Lumexa_History.json", content) end
        return content
    elseif format == "markdown" then
        local content = ExportEngine.ToMarkdown(data, "Lumexa History")
        writeToFile("Lumexa_History.md", content)
        return content
    elseif format == "csv" then
        local content = ExportEngine.ToCSV(data)
        writeToFile("Lumexa_History.csv", content)
        return content
    end

    return nil, "Unknown format: " .. tostring(format)
end

function ExportEngine.ExportAlerts(format)
    local data = AlertEngine.GetRecent()
    format = format or "json"

    if format == "json" then
        local content = ExportEngine.ToJSON(data)
        if content then writeToFile("Lumexa_Alerts.json", content) end
        return content
    elseif format == "markdown" then
        local content = ExportEngine.ToMarkdown(data, "Lumexa Alerts")
        writeToFile("Lumexa_Alerts.md", content)
        return content
    elseif format == "csv" then
        local content = ExportEngine.ToCSV(data)
        writeToFile("Lumexa_Alerts.csv", content)
        return content
    end

    return nil, "Unknown format: " .. tostring(format)
end

-- InspectorEngine already writes its own report as plain text on scan;
-- this exposes it under the shared export naming for convenience
function ExportEngine.ExportInspectorReport()
    local report = InspectorEngine.GetLastReport()
    if not report then
        return nil, "No report available yet, run LumexaInspector.RunScan() first"
    end
    writeToFile("Lumexa_InspectorReport_Export.txt", report)
    return report
end

InspectorEngine.Export = ExportEngine

return ExportEngine
end)()

-- TimelineEngine
local TimelineEngine = (function()
-- timeline engine
--
-- hybrid capture: LiveChangeDetector is genuinely event-driven (true
-- subscribe, zero poll gap) and covers folders/modules/remotes/unknown
-- objects/removed/moved. BossIntelligence/EventIntelligence/
-- IslandIntelligence/NPCIntelligence expose no subscribe hook, and the
-- function that actually pushes their history (pushHistory) is a
-- private, unexported local inside each file, not reachable from
-- outside at all — the runtime-wrap trick LiveChangeDetector used on
-- ObjectDatabase.Set doesn't apply here. So lifecycle events (boss
-- spawn/death, event start/end, island appear/disappear, npc found)
-- are captured via a fast poll-and-diff instead, tuned well below
-- those modules' own internal caps so nothing is realistically evicted
-- before this catches it. Not a true event hook — documented honestly
-- rather than claimed as one.
--
-- "history should only grow" vs "memory leaks are unacceptable" (both
-- explicit project requirements) is resolved with a generous but
-- non-infinite soft cap (Config.Timeline.MaxEntries, default 5000) —
-- see TIMELINE_ENGINE.md.


local TimelineEngine = {}

TimelineEngine._entries = {}
TimelineEngine._nextId = 1
TimelineEngine._seenKeys = {}
TimelineEngine._running = false
TimelineEngine._loaded = false

local TIMELINE_FILE = "Lumexa_Timeline.txt"

local function isTargetBoss(name)
    local targets = Config.Get("BossManager.TargetBosses") or {}
    for _, targetName in ipairs(targets) do
        if targetName == name then return true end
    end
    return false
end

local function buildTimestamp()
    local now = os.time()
    local t = os.date("*t", now)
    local gameTime = nil
    local ok, env = pcall(function() return EnvironmentIntelligence.GetState() end)
    if ok and env then gameTime = env.clockTime end

    return {
        hour = t.hour,
        minute = t.min,
        second = t.sec,
        unix = now,
        gameTime = gameTime,
        serverUptime = Config.GetUptime(),
    }
end

-- see module header: memory-leak protection vs "should only grow"
local function enforceCap()
    local maxEntries = Config.Get("Timeline.MaxEntries") or 5000
    while #TimelineEngine._entries > maxEntries do
        table.remove(TimelineEngine._entries, 1)
    end
end

function TimelineEngine.Add(fields)
    local jobId = "unknown"
    pcall(function() jobId = game.JobId end)

    local entry = {
        id = TimelineEngine._nextId,
        type = fields.type,
        category = fields.category,
        title = fields.title,
        description = fields.description or fields.title,
        priority = fields.priority or "Information",
        objectName = fields.objectName,
        objectPath = fields.objectPath,
        sea = SeaManager.GetCurrentSea(),
        island = fields.island,
        jobId = jobId,
        timestamp = buildTimestamp(),
    }

    TimelineEngine._nextId = TimelineEngine._nextId + 1
    table.insert(TimelineEngine._entries, entry)
    enforceCap()

    Logger.Info("TimelineEngine", entry.title .. (entry.objectName and (": " .. entry.objectName) or ""))
    return entry
end

function TimelineEngine.Clear()
    TimelineEngine._entries = {}
    TimelineEngine._nextId = 1
    Logger.Warn("TimelineEngine", "Timeline cleared (manual override)")
end

-- event-driven: LiveChangeDetector
local function onLiveChange(event)
    local record = event.current or event.previous
    if not record then return end
    local className = record.className
    local name = record.name

    if event.changeType == "Added" then
        if className == "Folder" then
            TimelineEngine.Add({
                type = "FolderCreated", category = "Objects", title = "New Folder Created",
                objectName = name, objectPath = event.fullPath, priority = "Low",
            })
        elseif className == "ModuleScript" then
            TimelineEngine.Add({
                type = "ModuleAdded", category = "Modules", title = "Module Added",
                objectName = name, objectPath = event.fullPath, priority = "Low",
            })
        elseif className == "RemoteEvent" or className == "RemoteFunction" then
            TimelineEngine.Add({
                type = "RemoteAdded", category = "Remotes", title = "Remote Added",
                objectName = name, objectPath = event.fullPath, priority = "Low",
            })
        elseif className == "Model" and not isTargetBoss(name) then
            TimelineEngine.Add({
                type = "UnknownObjectFound", category = "Unknown", title = "Unknown Object Found",
                objectName = name, objectPath = event.fullPath, priority = "Medium",
            })
        end
    elseif event.changeType == "Removed" then
        TimelineEngine.Add({
            type = "ObjectRemoved", category = "Objects", title = "Object Removed",
            objectName = name, objectPath = event.fullPath, priority = "Information",
        })
    elseif event.changeType == "Moved" then
        TimelineEngine.Add({
            type = "ObjectMoved", category = "Objects", title = "Object Moved",
            objectName = name, objectPath = event.fullPath, priority = "Information",
        })
    end
    -- renamed isn't derivable from a live per-mutation stream, same
    -- honest limitation already documented in AlertEngine
end

-- poll-and-diff: boss lifecycle
local function pollBosses()
    for bossName, entry in pairs(BossIntelligence.GetAllTracked()) do
        for _, cycle in ipairs(entry.history) do
            if cycle.spawnTime then
                local key = "boss_spawn_" .. bossName .. "_" .. cycle.spawnTime
                if not TimelineEngine._seenKeys[key] then
                    TimelineEngine._seenKeys[key] = true
                    TimelineEngine.Add({
                        type = "BossSpawned", category = "Boss", title = "Boss Spawned",
                        objectName = bossName, objectPath = cycle.path, priority = "High",
                    })
                end
            end
            if cycle.deathTime then
                local key = "boss_death_" .. bossName .. "_" .. cycle.deathTime
                if not TimelineEngine._seenKeys[key] then
                    TimelineEngine._seenKeys[key] = true
                    TimelineEngine.Add({
                        type = "BossDied", category = "Boss", title = "Boss Died",
                        objectName = bossName, objectPath = cycle.path, priority = "High",
                    })
                end
            end
        end

        if entry.state == "Alive" and entry.spawnTime then
            local key = "boss_spawn_" .. bossName .. "_" .. entry.spawnTime
            if not TimelineEngine._seenKeys[key] then
                TimelineEngine._seenKeys[key] = true
                TimelineEngine.Add({
                    type = "BossSpawned", category = "Boss", title = "Boss Spawned",
                    objectName = bossName, objectPath = entry.currentPath, priority = "High",
                })
            end
        elseif entry.state == "Untracked" and entry.spawnTime then
            local key = "boss_despawn_" .. bossName .. "_" .. entry.spawnTime
            if not TimelineEngine._seenKeys[key] then
                TimelineEngine._seenKeys[key] = true
                TimelineEngine.Add({
                    type = "BossDespawned", category = "Boss", title = "Boss Despawned",
                    objectName = bossName, objectPath = entry.currentPath, priority = "Medium",
                })
            end
        end
    end
end

-- poll-and-diff: sea event lifecycle
local function pollEvents()
    for eventKey, entry in pairs(EventIntelligence.GetAllTracked()) do
        for _, record in ipairs(entry.history) do
            if record.startTime then
                local key = "event_start_" .. eventKey .. "_" .. record.startTime
                if not TimelineEngine._seenKeys[key] then
                    TimelineEngine._seenKeys[key] = true
                    local category = (eventKey == "FullMoon") and "Lighting"
                        or (eventKey == "MirageIsland" or eventKey == "PrehistoricIsland") and "Island"
                        or "World"
                    TimelineEngine.Add({
                        type = eventKey .. "Started", category = category, title = eventKey .. " Started",
                        objectName = eventKey, priority = "Medium",
                    })
                end
            end
            if record.endTime then
                local key = "event_end_" .. eventKey .. "_" .. record.endTime
                if not TimelineEngine._seenKeys[key] then
                    TimelineEngine._seenKeys[key] = true
                    local category = (eventKey == "FullMoon") and "Lighting"
                        or (eventKey == "MirageIsland" or eventKey == "PrehistoricIsland") and "Island"
                        or "World"
                    TimelineEngine.Add({
                        type = eventKey .. "Ended", category = category, title = eventKey .. " Ended",
                        objectName = eventKey, priority = "Medium",
                    })
                end
            end
        end
    end
end

-- poll-and-diff: island appearance lifecycle
local function pollIslands()
    for path, entry in pairs(IslandIntelligence.GetAllIslands()) do
        for _, appearance in ipairs(entry.appearances) do
            if appearance.start then
                local key = "island_appear_" .. path .. "_" .. appearance.start
                if not TimelineEngine._seenKeys[key] then
                    TimelineEngine._seenKeys[key] = true
                    TimelineEngine.Add({
                        type = "IslandAppeared", category = "Island", title = "New Island Found",
                        objectName = entry.displayName, objectPath = path, island = entry.displayName,
                        priority = "Medium",
                    })
                end
            end
            if appearance.ended then
                local key = "island_gone_" .. path .. "_" .. appearance.ended
                if not TimelineEngine._seenKeys[key] then
                    TimelineEngine._seenKeys[key] = true
                    TimelineEngine.Add({
                        type = "IslandDisappeared", category = "Island", title = "Island Disappeared",
                        objectName = entry.displayName, objectPath = path, island = entry.displayName,
                        priority = "Medium",
                    })
                end
            end
        end
    end
end

-- poll-and-diff: new NPC found
local function pollNPCs()
    for path, npc in pairs(NPCIntelligence.GetAllNPCs()) do
        local key = "npc_found_" .. path
        if not TimelineEngine._seenKeys[key] then
            TimelineEngine._seenKeys[key] = true
            TimelineEngine.Add({
                type = "NewNPCFound", category = "NPC", title = "New NPC Found",
                objectName = npc.displayName, objectPath = path, priority = "Low",
            })
        end
    end
end

local function serialize()
    local ok, json = pcall(function() return ExportEngine.ToJSON(TimelineEngine._entries) end)
    return ok and json or nil
end

function TimelineEngine.Save()
    local ok, supported = pcall(function() return writefile ~= nil end)
    if not ok or not supported then return false end
    local content = serialize()
    if content then
        pcall(writefile, TIMELINE_FILE, content)
    end
    return true
end

function TimelineEngine.Load()
    if TimelineEngine._loaded then return end
    TimelineEngine._loaded = true

    local ok, supported = pcall(function() return isfile ~= nil and readfile ~= nil end)
    if not ok or not supported then return end

    local existsOk, exists = pcall(isfile, TIMELINE_FILE)
    if not existsOk or not exists then return end

    local readOk, content = pcall(readfile, TIMELINE_FILE)
    if not readOk then return end

    local HttpService = nil
    pcall(function() HttpService = game:GetService("HttpService") end)
    if not HttpService then return end

    local decodeOk, entries = pcall(function() return HttpService:JSONDecode(content) end)
    if decodeOk and type(entries) == "table" then
        TimelineEngine._entries = entries
        local maxId = 0
        for _, e in ipairs(entries) do
            if e.id and e.id > maxId then maxId = e.id end
            local key
            if e.type == "BossSpawned" then key = "boss_spawn_" .. tostring(e.objectName) .. "_" .. tostring(e.timestamp and e.timestamp.unix)
            end
            -- seenKeys aren't reconstructed exactly on load (they're a
            -- dedupe aid for this session, not part of the persisted
            -- record) — a fresh session re-diffs from the current live
            -- state, which only ever adds NEW entries going forward,
            -- consistent with "history should only grow"
        end
        TimelineEngine._nextId = maxId + 1
        Logger.Info("TimelineEngine", string.format("Loaded %d timeline entr%s from disk", #entries, #entries == 1 and "y" or "ies"))
    end
end

function TimelineEngine.Search(query)
    query = query or {}
    local results = {}
    for _, entry in ipairs(TimelineEngine._entries) do
        local match = true
        if query.name and entry.objectName ~= query.name then match = false end
        if query.path and not (entry.objectPath and entry.objectPath:find(query.path, 1, true)) then match = false end
        if query.category and entry.category ~= query.category then match = false end
        if query.sea and entry.sea ~= query.sea then match = false end
        if query.island and entry.island ~= query.island then match = false end
        if query.bossName and entry.objectName ~= query.bossName then match = false end
        if query.date then
            local entryDate = os.date("*t", entry.timestamp.unix)
            if entryDate.year ~= query.date.year or entryDate.month ~= query.date.month or entryDate.day ~= query.date.day then
                match = false
            end
        end
        if match then table.insert(results, entry) end
    end
    return results
end

function TimelineEngine.Filter(criteria)
    criteria = criteria or {}
    local results = {}
    local now = os.date("*t")
    local currentJobId = "unknown"
    pcall(function() currentJobId = game.JobId end)

    for _, entry in ipairs(TimelineEngine._entries) do
        local match = true

        if criteria.onlyCategory and entry.category ~= criteria.onlyCategory then match = false end
        if criteria.onlyPriority and entry.priority ~= criteria.onlyPriority then match = false end
        if criteria.onlyCritical and entry.priority ~= "Critical" then match = false end
        if criteria.onlyBosses and entry.category ~= "Boss" then match = false end
        if criteria.onlyEvents and entry.category ~= "World" and entry.category ~= "Lighting" then match = false end
        if criteria.onlyNPCs and entry.category ~= "NPC" then match = false end
        if criteria.onlyEnvironment and entry.category ~= "Lighting" and entry.category ~= "Sea" then match = false end
        if criteria.onlyUnknown and entry.category ~= "Unknown" then match = false end
        if criteria.onlyCurrentServer and entry.jobId ~= currentJobId then match = false end
        if criteria.onlyToday then
            local d = os.date("*t", entry.timestamp.unix)
            if d.year ~= now.year or d.month ~= now.month or d.day ~= now.day then match = false end
        end

        if match then table.insert(results, entry) end
    end
    return results
end

function TimelineEngine.GetHistory(limit)
    if not limit or limit >= #TimelineEngine._entries then
        return TimelineEngine._entries
    end
    local result = {}
    local startIndex = #TimelineEngine._entries - limit + 1
    for i = startIndex, #TimelineEngine._entries do
        table.insert(result, TimelineEngine._entries[i])
    end
    return result
end

function TimelineEngine.GetStatistics()
    local todayEntries = TimelineEngine.Filter({ onlyToday = true })
    local bossesToday, eventsToday, added, removed = 0, 0, 0, 0

    for _, entry in ipairs(todayEntries) do
        if entry.type == "BossSpawned" then bossesToday = bossesToday + 1 end
        if entry.category == "World" or entry.category == "Lighting" then
            if entry.title:find("Started") then eventsToday = eventsToday + 1 end
        end
        if entry.type == "FolderCreated" or entry.type == "ModuleAdded" or entry.type == "RemoteAdded"
            or entry.type == "UnknownObjectFound" then
            added = added + 1
        end
        if entry.type == "ObjectRemoved" then removed = removed + 1 end
    end

    local bossLifetimeTotal, bossLifetimeCount = 0, 0
    for _, entry in pairs(BossIntelligence.GetAllTracked()) do
        for _, cycle in ipairs(entry.history) do
            if cycle.spawnTime and cycle.deathTime then
                bossLifetimeTotal = bossLifetimeTotal + (cycle.deathTime - cycle.spawnTime)
                bossLifetimeCount = bossLifetimeCount + 1
            end
        end
    end

    local eventDurationTotal, eventDurationCount = 0, 0
    for _, entry in pairs(EventIntelligence.GetAllTracked()) do
        for _, record in ipairs(entry.history) do
            if record.durationSeconds then
                eventDurationTotal = eventDurationTotal + record.durationSeconds
                eventDurationCount = eventDurationCount + 1
            end
        end
    end

    return {
        bossesSpawnedToday = bossesToday,
        eventsToday = eventsToday,
        objectsAdded = added,
        objectsRemoved = removed,
        averageEventDurationSeconds = eventDurationCount > 0 and (eventDurationTotal / eventDurationCount) or nil,
        averageBossLifetimeSeconds = bossLifetimeCount > 0 and (bossLifetimeTotal / bossLifetimeCount) or nil,
        totalDiscoveries = #TimelineEngine._entries,
    }
end

function TimelineEngine.Export(format)
    format = format or "json"
    local data = TimelineEngine._entries

    if format == "json" then
        local content = ExportEngine.ToJSON(data)
        if content then
            local ok, supported = pcall(function() return writefile ~= nil end)
            if ok and supported then pcall(writefile, "Timeline.json", content) end
        end
        return content
    elseif format == "markdown" then
        local content = ExportEngine.ToMarkdown(data, "Lumexa Timeline")
        local ok, supported = pcall(function() return writefile ~= nil end)
        if ok and supported then pcall(writefile, "Timeline.md", content) end
        return content
    elseif format == "csv" then
        local flat = {}
        for _, e in ipairs(data) do
            table.insert(flat, {
                id = e.id, type = e.type, category = e.category, title = e.title,
                priority = e.priority, objectName = e.objectName, objectPath = e.objectPath,
                sea = e.sea, island = e.island, unix = e.timestamp.unix,
            })
        end
        local content = ExportEngine.ToCSV(flat)
        local ok, supported = pcall(function() return writefile ~= nil end)
        if ok and supported then pcall(writefile, "Timeline.csv", content) end
        return content
    end

    return nil, "Unknown format: " .. tostring(format)
end

function TimelineEngine.Start()
    if TimelineEngine._running then
        Logger.Warn("TimelineEngine", "Start called but already running")
        return false
    end

    TimelineEngine.Load()
    LiveChangeDetector.Subscribe(onLiveChange)
    TimelineEngine._running = true

    local lastSave = os.clock()
    local lastExport = os.clock()

    task.spawn(function()
        while TimelineEngine._running do
            pcall(pollBosses)
            pcall(pollEvents)
            pcall(pollIslands)
            pcall(pollNPCs)

            local saveInterval = Config.Get("Timeline.SaveIntervalSeconds") or 60
            if (os.clock() - lastSave) >= saveInterval then
                pcall(TimelineEngine.Save)
                lastSave = os.clock()
            end

            local exportInterval = Config.Get("Timeline.AutoExportIntervalSeconds") or 300
            if (os.clock() - lastExport) >= exportInterval then
                pcall(TimelineEngine.Export, "json")
                pcall(TimelineEngine.Export, "markdown")
                pcall(TimelineEngine.Export, "csv")
                lastExport = os.clock()
            end

            task.wait(Config.Get("Timeline.PollIntervalSeconds") or 2)
        end
    end)

    Logger.Info("TimelineEngine", "Started")
    return true
end

function TimelineEngine.Stop()
    TimelineEngine._running = false
    LiveChangeDetector.Unsubscribe(onLiveChange)
    pcall(TimelineEngine.Save)
    Logger.Info("TimelineEngine", "Stopped")
end

InspectorEngine.Timeline = TimelineEngine

return TimelineEngine
end)()

-- RuntimeMonitor
local RuntimeMonitor = (function()
-- discovery loop


local RuntimeMonitor = {}

RuntimeMonitor._running = false

function RuntimeMonitor.Start()
    if RuntimeMonitor._running then
        Logger.Warn("RuntimeMonitor", "Start called but already running")
        return false
    end

    ObjectDatabase.Load()
    HierarchyScanner.EnqueueRoots()

    RuntimeMonitor._running = true
    Logger.Info("RuntimeMonitor", "Intelligence Engine discovery started")

    local lastRootSweep = os.clock()
    local lastSave = os.clock()

    task.spawn(function()
        while RuntimeMonitor._running do
            local batchSize = Config.Get("Intelligence.BatchSize") or 25
            HierarchyScanner.ProcessBatch(batchSize)

            local sweepInterval = Config.Get("Intelligence.FullSweepIntervalSeconds") or 60
            if (os.clock() - lastRootSweep) >= sweepInterval then
                HierarchyScanner.EnqueueRoots()
                lastRootSweep = os.clock()
            end

            local saveInterval = Config.Get("Intelligence.SaveIntervalSeconds") or 120
            if (os.clock() - lastSave) >= saveInterval then
                pcall(ObjectDatabase.Save)
                lastSave = os.clock()
            end

            task.wait()
        end
    end)

    return true
end

function RuntimeMonitor.Stop()
    if not RuntimeMonitor._running then
        return false
    end

    RuntimeMonitor._running = false
    pcall(ObjectDatabase.Save)
    Logger.Info("RuntimeMonitor", "Intelligence Engine discovery stopped")
    return true
end

function RuntimeMonitor.GetProgress()
    return {
        running = RuntimeMonitor._running,
        queueLength = HierarchyScanner.GetQueueLength(),
        processedCount = HierarchyScanner.GetProcessedCount(),
        databaseSize = ObjectDatabase.Count(),
    }
end

return RuntimeMonitor
end)()

-- Utilities
local Utilities = (function()
-- helpers


local Utilities = {}

--- Wraps a function call in pcall and logs on failure.
--- Returns success (bool), result (any)
function Utilities.SafeCall(fn, moduleName, ...)
    if type(fn) ~= "function" then
        Logger.Error(moduleName or "Utilities", "SafeCall received a non-function")
        return false, nil
    end

    local ok, result = pcall(fn, ...)
    if not ok then
        Logger.Error(moduleName or "Utilities", "SafeCall failed: " .. tostring(result))
        return false, nil
    end

    return true, result
end

--- Deep copy a table (no metatables, plain data only)
function Utilities.DeepCopy(original)
    if type(original) ~= "table" then
        return original
    end

    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = Utilities.DeepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

--- Merge table b into table a (a is not mutated; returns new table)
function Utilities.MergeTables(a, b)
    local result = Utilities.DeepCopy(a) or {}
    if type(b) == "table" then
        for key, value in pairs(b) do
            result[key] = value
        end
    end
    return result
end

--- Clamp a number between min and max
function Utilities.Clamp(value, min, max)
    if type(value) ~= "number" then
        return min
    end
    if value < min then return min end
    if value > max then return max end
    return value
end

--- Round a number to N decimal places
function Utilities.Round(value, decimals)
    decimals = decimals or 0
    local mult = 10 ^ decimals
    return math.floor(value * mult + 0.5) / mult
end

--- Distance between two Vector3-like tables {x,y,z} without requiring roblox types,
--- but also supports real Vector3 if Magnitude is available.
function Utilities.Distance(a, b)
    if not a or not b then
        return math.huge
    end

    -- Prefer native Vector3 math if present
    if type((a - b)) == "userdata" then
        local ok, mag = pcall(function() return (a - b).Magnitude end)
        if ok then return mag end
    end

    local dx = (a.x or a.X or 0) - (b.x or b.X or 0)
    local dy = (a.y or a.Y or 0) - (b.y or b.Y or 0)
    local dz = (a.z or a.Z or 0) - (b.z or b.Z or 0)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

--- Simple debounce helper. Returns a function that only allows
--- execution once per `interval` seconds.
function Utilities.Debounce(fn, interval)
    local lastRun = 0
    return function(...)
        local now = os.clock()
        if now - lastRun >= interval then
            lastRun = now
            return fn(...)
        end
    end
end

--- Generate a short random ID (not cryptographically secure, just for tagging)
function Utilities.ShortId(length)
    length = length or 6
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = {}
    for i = 1, length do
        local idx = math.random(1, #chars)
        id[i] = chars:sub(idx, idx)
    end
    return table.concat(id)
end

--- Trim whitespace from a string
function Utilities.Trim(s)
    if type(s) ~= "string" then return s end
    return s:match("^%s*(.-)%s*$")
end

--- Check if a table is empty
function Utilities.IsEmpty(t)
    if type(t) ~= "table" then return true end
    return next(t) == nil
end

return Utilities
end)()

-- Status
local Status = (function()
-- activity status


local Status = {}

Status.States = {
    IDLE = "Idle",
    SEARCHING = "Searching...",
    BOSS_FOUND = "Boss Found",
    NO_BOSS_FOUND = "No Boss Found",
    SENDING_WEBHOOK = "Sending Webhook...",
    WEBHOOK_SENT = "Webhook Sent",
    WAITING = "Waiting...",
    SERVER_HOPPING = "Server Hopping...",
    TELEPORT_FAILED = "Teleport Failed",
    RETRYING = "Retrying...",
    CONNECTED = "Connected",
}

Status._current = Status.States.IDLE
Status._changedAt = os.clock()
Status._listeners = {}

function Status.Set(state)
    if state == Status._current then
        return
    end
    Status._current = state
    Status._changedAt = os.clock()

    for _, listener in ipairs(Status._listeners) do
        pcall(listener, state)
    end
end

function Status.Get()
    return Status._current
end

--- Seconds since the status last changed (useful for "stuck" detection)
function Status.TimeInState()
    return os.clock() - Status._changedAt
end

function Status.Subscribe(callback)
    if type(callback) ~= "function" then
        return false, "Listener must be a function"
    end
    table.insert(Status._listeners, callback)
    return true
end

function Status.Unsubscribe(callback)
    for i, existing in ipairs(Status._listeners) do
        if existing == callback then
            table.remove(Status._listeners, i)
            return true
        end
    end
    return false
end

return Status
end)()

-- WorkspaceDetector
local WorkspaceDetector = (function()
-- generic watchers


local WorkspaceDetector = {}

local Workspace = nil
local CollectionService = nil
pcall(function()
    Workspace = game:GetService("Workspace")
    CollectionService = game:GetService("CollectionService")
end)

--- Resolves a dot-path under Workspace to an Instance, or nil.
function WorkspaceDetector.ResolveContainer(pathString)
    if not Workspace then return nil end
    if not pathString or pathString == "" then return Workspace end

    local node = Workspace
    for key in string.gmatch(pathString, "[^%.]+") do
        if not node then return nil end
        node = node:FindFirstChild(key)
    end
    return node
end

function WorkspaceDetector.WatchContainer(pathString, callback)
    local container = WorkspaceDetector.ResolveContainer(pathString)
    if not container then
        Logger.Warn("WorkspaceDetector", "Container not found: " .. tostring(pathString))
        return nil, nil
    end

    for _, existing in ipairs(container:GetChildren()) do
        pcall(callback, existing)
    end

    local connection = container.ChildAdded:Connect(function(child)
        pcall(callback, child)
    end)

    Logger.Info("WorkspaceDetector", "Watching " .. pathString .. " (" .. #container:GetChildren() .. " existing child(ren))")
    return container, connection
end

--- Watches for Instances carrying a given CollectionService tag,
--- covering both already-tagged Instances and future ones.
function WorkspaceDetector.WatchTag(tagName, callback)
    if not CollectionService then
        Logger.Warn("WorkspaceDetector", "CollectionService unavailable")
        return nil
    end

    for _, existing in ipairs(CollectionService:GetTagged(tagName)) do
        pcall(callback, existing)
    end

    local connection = CollectionService:GetInstanceAddedSignal(tagName):Connect(function(instance)
        pcall(callback, instance)
    end)

    Logger.Info("WorkspaceDetector", "Watching tag: " .. tagName)
    return connection
end

--- Watches a specific Attribute on an Instance, calling callback(newValue)
--- immediately with the current value and on every future change.
function WorkspaceDetector.WatchAttribute(instance, attributeName, callback)
    if not instance then return nil end

    pcall(callback, instance:GetAttribute(attributeName))

    local connection = instance:GetAttributeChangedSignal(attributeName):Connect(function()
        pcall(callback, instance:GetAttribute(attributeName))
    end)

    return connection
end

--- Watches a specific property via .Changed, filtered to one property
--- name (Instance.Changed fires for every property, so this filters).
function WorkspaceDetector.WatchProperty(instance, propertyName, callback)
    if not instance then return nil end

    local ok, initial = pcall(function() return instance[propertyName] end)
    if ok then
        pcall(callback, initial)
    end

    local connection = instance.Changed:Connect(function(changedProperty)
        if changedProperty == propertyName then
            local readOk, value = pcall(function() return instance[propertyName] end)
            if readOk then
                pcall(callback, value)
            end
        end
    end)

    return connection
end

return WorkspaceDetector
end)()

-- SeaManager
local SeaManager = (function()
-- current sea


local SeaManager = {}

SeaManager._currentSea = nil
SeaManager._listeners = {}

local Players = nil
pcall(function()
    Players = game:GetService("Players")
end)

--- Subscribe to sea-change events. Callback receives (newSea, oldSea).
function SeaManager.Subscribe(callback)
    if type(callback) ~= "function" then
        return false, "Listener must be a function"
    end
    table.insert(SeaManager._listeners, callback)
    return true
end

local function notify(newSea, oldSea)
    for _, listener in ipairs(SeaManager._listeners) do
        pcall(listener, newSea, oldSea)
    end
end

function SeaManager.DetectCurrentSea()
    local ok, placeId = pcall(function()
        return game.PlaceId
    end)

    if not ok then
        Logger.Error("SeaManager", "Failed to read PlaceId")
        return nil
    end

    local seaMap = Config.Get("Scanner.SeaMap") or {}
    local detected = seaMap[placeId] or seaMap[tostring(placeId)]
    if not detected then
        Logger.Warn("SeaManager", "Unknown PlaceId " .. tostring(placeId) .. " — sea not mapped")
        return nil
    end

    SeaManager.SetCurrentSea(detected)
    return detected
end

--- Manually set the current sea (e.g. after detection or user override)
function SeaManager.SetCurrentSea(seaName)
    if type(seaName) ~= "string" or seaName == "" then
        return false, "Invalid sea name"
    end

    local old = SeaManager._currentSea
    if old == seaName then
        return true -- no change
    end

    SeaManager._currentSea = seaName
    Logger.Info("SeaManager", "Sea changed: " .. tostring(old) .. " -> " .. seaName)
    notify(seaName, old)
    return true
end

function SeaManager.GetCurrentSea()
    return SeaManager._currentSea
end

--- Checks if the current sea matches the user's configured preference
function SeaManager.IsPreferredSea()
    local preferred = Config.Get("SeaManager.PreferredSea")
    if not preferred then
        return false, "No preferred sea configured"
    end
    return SeaManager._currentSea == preferred
end

return SeaManager
end)()

-- BossManager
local BossManager = (function()
-- target list


local BossManager = {}

--- Add a boss name to the target list
function BossManager.AddTarget(name)
    if type(name) ~= "string" then
        return false, "Invalid boss name"
    end
    name = name:match("^%s*(.-)%s*$") -- trim whitespace from UI text input
    if name == "" then
        return false, "Invalid boss name"
    end

    local targets = Config.Get("BossManager.TargetBosses") or {}
    for _, existing in ipairs(targets) do
        if existing == name then
            return false, "Already tracking " .. name
        end
    end

    table.insert(targets, name)
    Config.Set("BossManager.TargetBosses", targets)
    Logger.Info("BossManager", "Now tracking: " .. name)
    return true
end

--- Remove a boss name from the target list
function BossManager.RemoveTarget(name)
    if type(name) == "string" then
        name = name:match("^%s*(.-)%s*$")
    end
    local targets = Config.Get("BossManager.TargetBosses") or {}
    for i, existing in ipairs(targets) do
        if existing == name then
            table.remove(targets, i)
            Config.Set("BossManager.TargetBosses", targets)
            Logger.Info("BossManager", "Stopped tracking: " .. name)
            return true
        end
    end
    return false, "Not currently tracking " .. tostring(name)
end

function BossManager.GetTargets()
    return Config.Get("BossManager.TargetBosses") or {}
end

return BossManager
end)()

-- Cache
local Cache = (function()
-- dedupe cache


local Cache = {}

Cache._entries = {} -- "eventKey|JobId" -> { confidence = n, timestamp = os.clock() }

local function makeKey(eventKey, jobId)
    return tostring(eventKey) .. "|" .. tostring(jobId or "unknown")
end

--- True if this (eventKey, JobId) pair has already been recorded and
--- hasn't expired yet.
function Cache.HasSeen(eventKey, jobId)
    local entry = Cache._entries[makeKey(eventKey, jobId)]
    return entry ~= nil
end

function Cache.Record(eventKey, jobId, confidence)
    Cache._entries[makeKey(eventKey, jobId)] = {
        confidence = confidence,
        timestamp = os.clock(),
    }
end

function Cache.ExpireOld()
    local lifetime = Config.Get("Cache.LifetimeSeconds") or 3600
    local now = os.clock()
    local expired = {}

    for key, entry in pairs(Cache._entries) do
        if (now - entry.timestamp) > lifetime then
            table.insert(expired, key)
        end
    end

    for _, key in ipairs(expired) do
        Cache._entries[key] = nil
    end

    if #expired > 0 then
        Logger.Debug("Cache", string.format("Expired %d old entr%s", #expired, #expired == 1 and "y" or "ies"))
    end
end

function Cache.Count()
    local n = 0
    for _ in pairs(Cache._entries) do
        n = n + 1
    end
    return n
end

function Cache.Clear()
    Cache._entries = {}
end

return Cache
end)()

-- WebhookConfig
local WebhookConfig = (function()
-- webhook config aliases


local WebhookConfig = {}

local webhooks = Config.Get("Webhooks") or {}
local aliasCount = 0

-- snapshot first, mutating webhooks mid-pairs() is undefined behavior
local originalPairs = {}
for spaceKey, url in pairs(webhooks) do
    table.insert(originalPairs, { key = spaceKey, url = url })
end

for _, entry in ipairs(originalPairs) do
    local spaceKey, url = entry.key, entry.url
    local underscoreKey = spaceKey:gsub(" ", "_")
    if underscoreKey ~= spaceKey then
        WebhookConfig[underscoreKey] = url
        webhooks[underscoreKey] = url
        aliasCount = aliasCount + 1
    else
        WebhookConfig[spaceKey] = url
    end
end

local legendaryDealerRouted = WebhookConfig.Legendary_Dealer ~= nil

Logger.Info("WebhookConfig", string.format(
    "Centralized webhook config ready — %d underscore_case alias(es) generated%s",
    aliasCount,
    legendaryDealerRouted and " (Legendary Dealer configured, but still has no detector — see MIGRATION_REPORT.md)" or ""
))

--- Looks up a webhook URL by either naming convention.
function WebhookConfig.Get(name)
    return WebhookConfig[name] or webhooks[name]
end

return WebhookConfig
end)()

-- Webhook
local Webhook = (function()
-- webhook sender


local Webhook = {}

Webhook._lastSent = 0
Webhook._queue = {}
Webhook._sentDedupeKeys = {} -- dedupeKey -> timestamp (os.clock()) of when it was sent
Webhook._processing = false
Webhook._running = false

local SENT_STATS_FILE = "Lumexa_WebhooksSent.txt"

local function loadTotalSent()
    local ok, supported = pcall(function() return isfile ~= nil and readfile ~= nil end)
    if not ok or not supported then return 0 end

    local existsOk, exists = pcall(isfile, SENT_STATS_FILE)
    if not existsOk or not exists then return 0 end

    local readOk, content = pcall(readfile, SENT_STATS_FILE)
    if not readOk then return 0 end

    return tonumber(content) or 0
end

local function saveTotalSent()
    local ok, supported = pcall(function() return writefile ~= nil end)
    if not ok or not supported then return end
    pcall(writefile, SENT_STATS_FILE, tostring(Webhook._totalSent))
end

Webhook._totalSent = loadTotalSent()

local HttpService = nil
pcall(function()
    HttpService = game:GetService("HttpService")
end)

-- Executor HTTP backend detection

local httpRequest = nil
local httpRequestName = nil

local function detectRequestFunction()
    local candidates = {
        { "syn.request", function() return syn and syn.request end },
        { "http_request", function() return http_request end },
        { "request", function() return request end },
        { "fluxus.request", function() return fluxus and fluxus.request end },
        { "http.request", function() return http and http.request end },
    }

    for _, candidate in ipairs(candidates) do
        local name, getter = candidate[1], candidate[2]
        -- pcall guards against environments where even *referencing*
        -- one of these globals could error (e.g. a restrictive genv).
        local ok, fn = pcall(getter)
        if ok and type(fn) == "function" then
            return fn, name
        end
    end

    return nil, nil
end

httpRequest, httpRequestName = detectRequestFunction()

if httpRequest then
    Logger.Info("Webhook", "HTTP backend detected: " .. httpRequestName)
else
    Logger.Error("Webhook", "No compatible HTTP function found (tried syn.request, http_request, request, fluxus.request, http.request). Webhooks will not send on this executor.")
end

--- Re-runs detection. Useful if the executor injects its request
--- function slightly after this module first loads.
function Webhook.RedetectBackend()
    httpRequest, httpRequestName = detectRequestFunction()
    if httpRequest then
        Logger.Info("Webhook", "HTTP backend detected: " .. httpRequestName)
    else
        Logger.Warn("Webhook", "Still no compatible HTTP function found")
    end
    return httpRequest ~= nil, httpRequestName
end

function Webhook.GetBackendName()
    return httpRequestName
end

-- URL resolution / validation

local function isValidWebhookUrl(url)
    if type(url) ~= "string" then return false end
    return url:match("^https://discord%.com/api/webhooks/") ~= nil
        or url:match("^https://discordapp%.com/api/webhooks/") ~= nil
end

--- Resolves a URL for a given webhook key. Falls back to the legacy
--- single Config.Webhook.URL if no keyed entry exists.
local function resolveUrl(webhookKey)
    local webhooks = Config.Get("Webhooks") or {}
    local url = webhookKey and webhooks[webhookKey]

    if not isValidWebhookUrl(url) then
        url = Config.Get("Webhook.URL")
    end

    return url
end

local function canSendNow()
    local rateLimit = Config.Get("Webhook.RateLimitSeconds") or 3
    return (os.clock() - Webhook._lastSent) >= rateLimit
end

-- Embed builder

function Webhook.BuildEmbed(options)
    options = options or {}

    local fields = {}
    for _, field in ipairs(options.fields or {}) do
        table.insert(fields, {
            name = tostring(field.name or "Field"),
            value = tostring(field.value or ""),
            inline = field.inline ~= false,
        })
    end

    local embed = {
        title = options.title,
        description = options.description,
        color = options.color or 0x8B5CF6, -- purple accent, matches Lumexa's UI theme
        fields = fields,
    }

    if options.footer then
        embed.footer = (type(options.footer) == "table") and options.footer or { text = tostring(options.footer) }
    end

    if options.author then
        embed.author = (type(options.author) == "table") and options.author or { name = tostring(options.author) }
    end

    if options.thumbnail then
        embed.thumbnail = { url = tostring(options.thumbnail) }
    end

    if options.image then
        embed.image = { url = tostring(options.image) }
    end

    if options.timestamp ~= false then
        local ok, isoTime = pcall(function() return DateTime.now():ToIsoDate() end)
        embed.timestamp = ok and isoTime or os.date("!%Y-%m-%dT%H:%M:%SZ")
    end

    return embed
end

function Webhook.BuildBossEmbed(bossName, extraFields)
    local jobId = "unknown"
    pcall(function() jobId = game.JobId end)

    local fields = { { name = "Server", value = jobId, inline = true } }
    for _, f in ipairs(extraFields or {}) do
        table.insert(fields, f)
    end

    local embed = Webhook.BuildEmbed({
        title = "Boss Detected: " .. tostring(bossName),
        color = 0xE74C3C,
        fields = fields,
    })
    local dedupeKey = jobId .. "_" .. tostring(bossName)
    return embed, dedupeKey
end

-- Transport

local function sendRequest(url, payload)
    if not httpRequest then
        return false, "No compatible HTTP backend available on this executor"
    end

    local encodeOk, encoded = pcall(function()
        return HttpService:JSONEncode(payload)
    end)
    if not encodeOk then
        return false, "Encoding failed: " .. tostring(encoded)
    end

    -- pcall only, never task.spawn/coroutine.wrap around this call
    -- (mobile executors block http from a spawned thread)
    local callOk, response = pcall(httpRequest, {
        Url = url,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
        },
        Body = encoded,
    })

    if not callOk then
        return false, "Request threw an error: " .. tostring(response)
    end

    if type(response) ~= "table" then
        -- Some backends return nothing useful on success; treat a
        -- non-error, non-table result as an unknown-but-not-failed case.
        return true, nil
    end

    local statusCode = response.StatusCode or response.status or response.Status
    local success = response.Success
    if success == nil and statusCode ~= nil then
        success = (statusCode >= 200 and statusCode < 300)
    end

    if success == false then
        return false, "HTTP " .. tostring(statusCode or "unknown")
    end

    return true, nil
end

-- Queue

--- Enqueue an embed for sending. Skips silently (returns false, reason)
--- if a dedupeKey was already sent successfully or is already queued.
function Webhook.Enqueue(webhookKey, embed, dedupeKey)
    if not Config.Get("Webhook.Enabled") then
        return false, "Webhook is disabled in config"
    end

    if dedupeKey then
        if Webhook._sentDedupeKeys[dedupeKey] then
            Logger.Debug("Webhook", "Skipped duplicate (already sent): " .. dedupeKey)
            return false, "Duplicate: already sent"
        end
        for _, item in ipairs(Webhook._queue) do
            if item.dedupeKey == dedupeKey then
                Logger.Debug("Webhook", "Skipped duplicate (already queued): " .. dedupeKey)
                return false, "Duplicate: already queued"
            end
        end
    end

    table.insert(Webhook._queue, {
        webhookKey = webhookKey,
        embed = embed,
        dedupeKey = dedupeKey,
        attempts = 0,
    })

    Logger.Debug("Webhook", "Queued embed" .. (dedupeKey and (" [" .. dedupeKey .. "]") or ""))
    return true, nil
end

-- Clean alias — same behavior as Enqueue, just the name requested
-- for the new API surface.
Webhook.Queue = Webhook.Enqueue

function Webhook.EnqueueBossAlert(bossName, extraFields, webhookKey)
    local embed, dedupeKey = Webhook.BuildBossEmbed(bossName, extraFields)
    return Webhook.Enqueue(webhookKey or bossName, embed, dedupeKey)
end

--- Attempts to send one queue item, respecting retry config.
--- Returns true if the item is done (sent or permanently failed/dropped).
local function processItem(item)
    local url = resolveUrl(item.webhookKey)
    if not isValidWebhookUrl(url) then
        Logger.Warn("Webhook", "Dropping queued item: no valid webhook URL for key " .. tostring(item.webhookKey))
        return true -- drop, nothing more we can do
    end

    if not httpRequest then
        Logger.Error("Webhook", "No HTTP backend available, dropping queue item")
        return true
    end

    if not canSendNow() then
        return false -- not done, retry on a later tick once rate limit clears
    end

    Status.Set(Status.States.SENDING_WEBHOOK)
    Logger.Info("Webhook", "Sending...")

    local ok, err = sendRequest(url, { embeds = { item.embed } })
    Webhook._lastSent = os.clock()

    if ok then
        if item.dedupeKey then
            Webhook._sentDedupeKeys[item.dedupeKey] = os.clock()
        end
        Webhook._totalSent = Webhook._totalSent + 1
        saveTotalSent()
        Status.Set(Status.States.WEBHOOK_SENT)
        Logger.Success("Webhook", "Success" .. (item.dedupeKey and (" [" .. item.dedupeKey .. "]") or ""))
        return true
    end

    item.attempts = item.attempts + 1
    local maxRetries = Config.Get("Webhook.MaxRetries") or 3

    if item.attempts >= maxRetries then
        Logger.Error("Webhook", string.format("Failed after %d attempt(s): %s", item.attempts, tostring(err)))
        return true -- permanently failed, drop it
    end

    Logger.Warn("Webhook", string.format("Retry %d/%d: %s", item.attempts, maxRetries, tostring(err)))
    Status.Set(Status.States.RETRYING)
    return false -- keep in queue, will be retried
end

local function expireOldEntries()
    local lifetime = Config.Get("Cache.LifetimeSeconds") or 3600
    local now = os.clock()
    local expired = {}

    for key, sentAt in pairs(Webhook._sentDedupeKeys) do
        if (now - sentAt) > lifetime then
            table.insert(expired, key)
        end
    end

    for _, key in ipairs(expired) do
        Webhook._sentDedupeKeys[key] = nil
    end

    if #expired > 0 then
        Logger.Debug("Webhook", string.format("Expired %d old dedupe entr%s", #expired, #expired == 1 and "y" or "ies"))
    end
end

function Webhook.Process()
    if #Webhook._queue == 0 or Webhook._processing then
        return false
    end

    Webhook._processing = true
    local item = Webhook._queue[1]

    local ok, done = pcall(processItem, item)
    if not ok then
        Logger.Error("Webhook", "processItem crashed: " .. tostring(done))
        table.remove(Webhook._queue, 1)
    elseif done then
        table.remove(Webhook._queue, 1)
    end

    Webhook._processing = false
    return true
end

function Webhook.StartQueueProcessor()
    if Webhook._running then
        return false, "Queue processor already running"
    end

    Webhook._running = true
    Logger.Info("Webhook", "Queue processor started")
    local lastSweep = os.clock()

    task.spawn(function()
        while Webhook._running do
            local sweepInterval = Config.Get("Cache.SweepIntervalSeconds") or 300
            if (os.clock() - lastSweep) >= sweepInterval then
                pcall(expireOldEntries)
                lastSweep = os.clock()
            end

            if #Webhook._queue > 0 and not Webhook._processing then
                Webhook._processing = true

                local item = Webhook._queue[1]
                local retryDelay = Config.Get("Webhook.RetryDelaySeconds") or 5

                local ok, done = pcall(processItem, item)
                if not ok then
                    Logger.Error("Webhook", "processItem crashed: " .. tostring(done))
                    table.remove(Webhook._queue, 1)
                elseif done then
                    table.remove(Webhook._queue, 1)
                else
                    task.wait(retryDelay)
                end

                Webhook._processing = false
            end

            local interval = Config.Get("Webhook.QueueIntervalSeconds") or 1
            task.wait(interval)
        end
    end)

    return true
end

function Webhook.StopQueueProcessor()
    Webhook._running = false
    Logger.Info("Webhook", "Queue processor stopped")
end

function Webhook.GetQueueLength()
    return #Webhook._queue
end

function Webhook.GetTotalSent()
    return Webhook._totalSent
end

--- Empties the queue without sending anything still pending.
function Webhook.Clear()
    local dropped = #Webhook._queue
    Webhook._queue = {}
    Logger.Info("Webhook", string.format("Queue cleared (%d item(s) dropped)", dropped))
end

function Webhook.FlushQueue(maxSeconds)
    maxSeconds = maxSeconds or 8
    local deadline = os.clock() + maxSeconds

    Logger.Info("Webhook", string.format("Flushing %d queued webhook(s) before shutdown", #Webhook._queue))

    while #Webhook._queue > 0 and os.clock() < deadline do
        local item = Webhook._queue[1]
        local ok, done = pcall(processItem, item)

        if not ok then
            Logger.Error("Webhook", "processItem crashed during flush: " .. tostring(done))
            table.remove(Webhook._queue, 1)
        elseif done then
            table.remove(Webhook._queue, 1)
        else
            task.wait(0.2)
        end
    end

    if #Webhook._queue > 0 then
        Logger.Warn("Webhook", string.format("Shutdown flush timed out with %d item(s) still queued", #Webhook._queue))
    else
        Logger.Info("Webhook", "Queue fully flushed before shutdown")
    end
end

-- Immediate (non-queued) sends

--- Send a plain text message immediately (bypasses the queue).
function Webhook.Send(message, webhookKey)
    if not Config.Get("Webhook.Enabled") then
        return false, "Webhook is disabled in config"
    end

    local url = resolveUrl(webhookKey)
    if not isValidWebhookUrl(url) then
        Logger.Warn("Webhook", "Send blocked: no valid webhook URL configured")
        return false, "No valid webhook URL configured"
    end

    if not canSendNow() then
        Logger.Debug("Webhook", "Send skipped due to rate limit")
        return false, "Rate limited"
    end

    local ok, err = sendRequest(url, { content = tostring(message) })
    if ok then
        Webhook._lastSent = os.clock()
        Webhook._totalSent = Webhook._totalSent + 1
        saveTotalSent()
        Logger.Success("Webhook", "Message sent successfully")
        return true, nil
    end

    Logger.Error("Webhook", tostring(err))
    return false, err
end

function Webhook.SendEmbed(options, webhookKey)
    if not Config.Get("Webhook.Enabled") then
        return false, "Webhook is disabled in config"
    end

    local url = resolveUrl(webhookKey)
    if not isValidWebhookUrl(url) then
        Logger.Warn("Webhook", "SendEmbed blocked: no valid webhook URL configured")
        return false, "No valid webhook URL configured"
    end

    if not canSendNow() then
        return false, "Rate limited"
    end

    local embed = Webhook.BuildEmbed(options)
    local ok, err = sendRequest(url, { embeds = { embed } })
    if ok then
        Webhook._lastSent = os.clock()
        Webhook._totalSent = Webhook._totalSent + 1
        saveTotalSent()
        Logger.Success("Webhook", "Embed sent successfully")
        return true, nil
    end

    Logger.Error("Webhook", tostring(err))
    return false, err
end

--- Sends an immediate test embed, bypassing the queue and rate limit,
--- to verify a webhook URL + HTTP backend actually work end-to-end.
function Webhook.Test(webhookKey)
    if not Config.Get("Webhook.Enabled") then
        return false, "Webhook is disabled in config"
    end

    local url = resolveUrl(webhookKey)
    if not isValidWebhookUrl(url) then
        return false, "No valid webhook URL configured"
    end

    if not httpRequest then
        return false, "No compatible HTTP backend available on this executor"
    end

    local embed = Webhook.BuildEmbed({
        title = "Lumexa Webhook Test",
        description = "If you can see this, your webhook configuration is working correctly.",
        color = 0x2ECC71,
        fields = {
            { name = "Backend", value = httpRequestName or "unknown", inline = true },
        },
    })

    local ok, err = sendRequest(url, { embeds = { embed } })
    if ok then
        Webhook._lastSent = os.clock()
        Webhook._totalSent = Webhook._totalSent + 1
        saveTotalSent()
        Logger.Success("Webhook", "Test message sent successfully")
    else
        Logger.Error("Webhook", "Test failed: " .. tostring(err))
    end

    return ok, err
end

return Webhook
end)()

-- VerificationEngine
local VerificationEngine = (function()
-- confidence gate + dispatch


local VerificationEngine = {}

local STATS_FILE = "Lumexa_BossesFound.txt"

local function loadTotalFound()
    local ok, supported = pcall(function() return isfile ~= nil and readfile ~= nil end)
    if not ok or not supported then return 0 end

    local existsOk, exists = pcall(isfile, STATS_FILE)
    if not existsOk or not exists then return 0 end

    local readOk, content = pcall(readfile, STATS_FILE)
    if not readOk then return 0 end

    return tonumber(content) or 0
end

local function saveTotalFound()
    local ok, supported = pcall(function() return writefile ~= nil end)
    if not ok or not supported then return end
    pcall(writefile, STATS_FILE, tostring(VerificationEngine._totalFound))
end

VerificationEngine._totalFound = loadTotalFound()

function VerificationEngine.GetTotalFound()
    return VerificationEngine._totalFound
end

VerificationEngine.Confidence = {
    BOSS_MODEL = 100,
    UNIQUE_EVENT_OBJECT = 95,
    MAP_OBJECT = 90,
    ATTRIBUTE = 80,
    LIGHTING = 70,
    PARTICLE = 60,
}

local function logDecision(candidate, accepted, reason, confirmationMs)
    if not Config.Get("Detection.VerboseDecisionLog") then
        return
    end

    local jobId = "unknown"
    pcall(function() jobId = game.JobId end)

    Logger.Debug("VerificationEngine", string.format(
        "%s | source=%s | confidence=%d%% | layer=%s | sea=%s | job=%s | confirmMs=%s | status=%s%s",
        candidate.displayName or candidate.eventKey,
        tostring(candidate.source),
        candidate.confidence or 0,
        tostring(candidate.layer),
        tostring(SeaManager.GetCurrentSea() or "Unknown"),
        jobId,
        tostring(confirmationMs),
        accepted and "ACCEPTED" or "REJECTED",
        reason and (" | reason=" .. reason) or ""
    ))
end

local function verify(candidate)
    -- hard reject, not a confidence penalty (e.g. full moon outside third sea)
    if candidate.requiresSea then
        local currentSea = SeaManager.GetCurrentSea()
        if currentSea ~= candidate.requiresSea then
            return false, "Sea gate failed (needs " .. candidate.requiresSea .. ", currently " .. tostring(currentSea or "Unknown") .. ")"
        end
    end

    if not candidate.eventKey or candidate.eventKey == "" then
        return false, "Missing eventKey"
    end

    if type(candidate.confidence) ~= "number" then
        return false, "Missing confidence score"
    end

    return true, nil
end

--- Layer 3: Confirmation. Threshold + dedupe check.
local function confirm(candidate)
    local minConfidence = Config.Get("Detection.MinConfidence") or 90
    if candidate.confidence < minConfidence then
        return false, string.format("Below confidence threshold (%d%% < %d%%)", candidate.confidence, minConfidence)
    end

    local jobId = "unknown"
    pcall(function() jobId = game.JobId end)

    if Cache.HasSeen(candidate.eventKey, jobId) then
        return false, "Already alerted this server"
    end

    return true, nil
end

--- Layer 4: Dispatch. Only reached if Layers 2 and 3 both passed.
local function dispatch(candidate)
    local jobId = "unknown"
    pcall(function() jobId = game.JobId end)

    Cache.Record(candidate.eventKey, jobId, candidate.confidence)

    local fields = { { name = "Confidence", value = candidate.confidence .. "%", inline = true } }
    for _, f in ipairs(candidate.extraFields or {}) do
        table.insert(fields, f)
    end

    Status.Set(Status.States.BOSS_FOUND)
    local ok, err = Webhook.EnqueueBossAlert(candidate.displayName or candidate.eventKey, fields, candidate.webhookKey)

    if ok then
        VerificationEngine._totalFound = VerificationEngine._totalFound + 1
        saveTotalFound()
    end

    return ok, err
end

--- Main entry point for every detector. Runs Layers 2-4 and returns
--- (accepted: bool, reason: string|nil).
function VerificationEngine.Submit(candidate)
    local startClock = os.clock()

    local verifyOk, verifyReason = verify(candidate)
    if not verifyOk then
        logDecision(candidate, false, verifyReason, nil)
        return false, verifyReason
    end

    local confirmOk, confirmReason = confirm(candidate)
    if not confirmOk then
        logDecision(candidate, false, confirmReason, nil)
        return false, confirmReason
    end

    local dispatchOk, dispatchErr = dispatch(candidate)
    local confirmationMs = math.floor((os.clock() - startClock) * 1000)

    logDecision(candidate, true, dispatchOk and nil or ("Webhook: " .. tostring(dispatchErr)), confirmationMs)

    return true, nil
end

return VerificationEngine
end)()

-- BossDetector
local BossDetector = (function()
-- boss detection


local BossDetector = {}

BossDetector._activeSightings = {} -- boss name -> Instance, for hop-timing purposes only (see ARCHITECTURE §7)
BossDetector._connection = nil
BossDetector._container = nil

local function isTargetBoss(name)
    local targets = Config.Get("BossManager.TargetBosses") or {}
    for _, targetName in ipairs(targets) do
        if targetName == name then
            return true
        end
    end
    return false
end

local function onEnemyAdded(instance)
    if not instance:IsA("Model") then
        return
    end

    if not isTargetBoss(instance.Name) then
        return
    end

    local humanoid = instance:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        Logger.Debug("BossDetector", instance.Name .. " matched target name but has no Humanoid yet — waiting")
        -- The Humanoid can stream in slightly after the Model itself;
        -- watch for it rather than dropping the candidate.
        local conn
        conn = instance.ChildAdded:Connect(function(child)
            if child:IsA("Humanoid") then
                if conn then conn:Disconnect() end
                onEnemyAdded(instance)
            end
        end)
        return
    end

    BossDetector._activeSightings[instance.Name] = instance

    VerificationEngine.Submit({
        eventKey = instance.Name,
        displayName = instance.Name,
        confidence = VerificationEngine.Confidence.BOSS_MODEL,
        source = "Workspace.Enemies ChildAdded",
        layer = "Layer 1: Fast Detection (event-driven)",
    })

    -- Track despawn for hop-timing only — NOT as a confidence signal,
    -- since it can mean "died" or just "streamed out". See ARCHITECTURE §7.
    instance.AncestryChanged:Connect(function(_, parent)
        if parent == nil and BossDetector._activeSightings[instance.Name] == instance then
            BossDetector._activeSightings[instance.Name] = nil
        end
    end)
end

--- Starts watching Workspace.Enemies. Idempotent — safe to call more
--- than once, only connects once.
function BossDetector.Start()
    if BossDetector._connection then
        return true
    end

    if not Config.Get("BossManager.Enabled") then
        Logger.Info("BossDetector", "BossManager.Enabled is false, not starting")
        return false
    end

    local path = Config.Get("Detection.EnemiesContainerPath") or "Enemies"
    local container, connection = WorkspaceDetector.WatchContainer(path, onEnemyAdded)

    if not container then
        Logger.Error("BossDetector", "Could not find Workspace." .. path .. " — run WorkspaceInspector.RunFull() to locate the real container name")
        return false
    end

    BossDetector._container = container
    BossDetector._connection = connection
    Logger.Info("BossDetector", "Watching Workspace." .. path .. " for target bosses")
    return true
end

function BossDetector.Stop()
    if BossDetector._connection then
        BossDetector._connection:Disconnect()
        BossDetector._connection = nil
    end
end

function BossDetector.GetActiveSightings()
    return BossDetector._activeSightings
end

function BossDetector.FallbackSweep()
    if not BossDetector._container then
        return
    end

    for _, child in ipairs(BossDetector._container:GetChildren()) do
        if child:IsA("Model") and isTargetBoss(child.Name) and not BossDetector._activeSightings[child.Name] then
            onEnemyAdded(child)
        end
    end
end

return BossDetector
end)()

-- LightingDetector
local LightingDetector = (function()
-- full moon


local LightingDetector = {}

LightingDetector._connection = nil
LightingDetector._lastState = false

local Lighting = nil
pcall(function() Lighting = game:GetService("Lighting") end)

local function isFullMoonActive()
    local eventConfig = Config.Get("SeaEvents.FullMoon") or {}

    if eventConfig.StateAttributeName and Lighting then
        local ok, value = pcall(function()
            return Lighting:GetAttribute(eventConfig.StateAttributeName)
        end)
        if ok and value ~= nil then
            return value == true, VerificationEngine.Confidence.ATTRIBUTE
        end
    end

    if Lighting then
        local ok, clockTime = pcall(function() return Lighting.ClockTime end)
        if ok then
            local rangeStart = eventConfig.ClockTimeRangeStart or 0
            local rangeEnd = eventConfig.ClockTimeRangeEnd or 6
            local inRange = clockTime >= rangeStart and clockTime <= rangeEnd
            return inRange, VerificationEngine.Confidence.LIGHTING
        end
    end

    return false, 0
end

local function checkAndSubmit()
    local eventConfig = Config.Get("SeaEvents.FullMoon") or {}
    if not eventConfig.Enabled then
        return
    end

    local active, confidence = isFullMoonActive()

    if active and not LightingDetector._lastState then
        VerificationEngine.Submit({
            eventKey = "FullMoon",
            displayName = "Full Moon",
            confidence = confidence,
            source = "Lighting",
            layer = "Layer 1: Fast Detection (Lighting)",
            requiresSea = eventConfig.RequiredSea or "Third Sea",
        })
    end

    LightingDetector._lastState = active
end

function LightingDetector.Start()
    if LightingDetector._connection then
        return true
    end

    if not Lighting then
        Logger.Error("LightingDetector", "Lighting service unavailable")
        return false
    end

    local eventConfig = Config.Get("SeaEvents.FullMoon") or {}
    if eventConfig.StateAttributeName then
        LightingDetector._connection = WorkspaceDetector.WatchAttribute(
            Lighting, eventConfig.StateAttributeName, function() checkAndSubmit() end
        )
    else
        LightingDetector._connection = WorkspaceDetector.WatchProperty(
            Lighting, "ClockTime", function() checkAndSubmit() end
        )
    end

    Logger.Info("LightingDetector", "Watching Lighting for Full Moon")
    return true
end

function LightingDetector.Stop()
    if LightingDetector._connection then
        LightingDetector._connection:Disconnect()
        LightingDetector._connection = nil
    end
end

--- Fallback sweep entry point (see ARCHITECTURE.md §9).
function LightingDetector.FallbackSweep()
    checkAndSubmit()
end

return LightingDetector
end)()

-- SeaEventDetector
local SeaEventDetector = (function()
-- sea events


local SeaEventDetector = {}

SeaEventDetector._connections = {}

-- Mirage Island / Prehistoric Island — both are Location-folder events

local function watchLocationEvent(eventKeyConfigPath, eventKey, displayName)
    local eventConfig = Config.Get(eventKeyConfigPath) or {}
    if not eventConfig.Enabled then
        return
    end

    local locationName = eventConfig.LocationName
    if not locationName then
        Logger.Warn("SeaEventDetector", eventKey .. " enabled but LocationName not set")
        return
    end

    local path = Config.Get("Detection.LocationsContainerPath") or "_WorldOrigin.Locations"
    local container, connection = WorkspaceDetector.WatchContainer(path, function(child)
        if child.Name ~= locationName then
            return
        end

        VerificationEngine.Submit({
            eventKey = eventKey,
            displayName = displayName,
            confidence = VerificationEngine.Confidence.UNIQUE_EVENT_OBJECT,
            source = path .. " ChildAdded (matched '" .. locationName .. "')",
            layer = "Layer 1: Fast Detection (event-driven)",
        })
    end)

    if connection then
        table.insert(SeaEventDetector._connections, connection)
    end
end

-- Leviathan / Elite Pirates — Model-type events in Workspace.Enemies

local function watchModelEvent(eventKeyConfigPath, eventKey, displayName)
    local eventConfig = Config.Get(eventKeyConfigPath) or {}
    if not eventConfig.Enabled then
        return
    end

    local modelName = eventConfig.ModelName
    if not modelName then
        Logger.Warn("SeaEventDetector", eventKey .. " enabled but ModelName not set")
        return
    end

    local path = Config.Get("Detection.EnemiesContainerPath") or "Enemies"
    local container, connection = WorkspaceDetector.WatchContainer(path, function(child)
        if not child:IsA("Model") then
            return
        end
        if child.Name ~= modelName then
            return
        end

        VerificationEngine.Submit({
            eventKey = eventKey,
            displayName = displayName,
            confidence = VerificationEngine.Confidence.UNIQUE_EVENT_OBJECT,
            source = path .. " ChildAdded (matched '" .. modelName .. "')",
            layer = "Layer 1: Fast Detection (event-driven)",
        })
    end)

    if connection then
        table.insert(SeaEventDetector._connections, connection)
    end
end

-- Factory Raid — requires confirming the raid is ACTIVE, not just that
-- the Factory location exists. See ARCHITECTURE.md §6.

local function watchFactoryRaid()
    local eventConfig = Config.Get("SeaEvents.FactoryRaid") or {}
    if not eventConfig.Enabled then
        return
    end

    if not eventConfig.ActiveAttributeName then
        Logger.Warn("SeaEventDetector", "FactoryRaid enabled but ActiveAttributeName not set — cannot confirm raid is active vs island merely existing, refusing to guess (see ARCHITECTURE.md §6)")
        return
    end

    local path = Config.Get("Detection.LocationsContainerPath") or "_WorldOrigin.Locations"
    local locationName = eventConfig.LocationName or "Factory"

    local container = WorkspaceDetector.ResolveContainer(path)
    if not container then
        Logger.Error("SeaEventDetector", "Could not find " .. path)
        return
    end

    local function watchFactoryInstance(instance)
        local connection = WorkspaceDetector.WatchAttribute(instance, eventConfig.ActiveAttributeName, function(value)
            if value ~= true then
                return
            end

            VerificationEngine.Submit({
                eventKey = "FactoryRaid",
                displayName = "Factory Raid",
                confidence = VerificationEngine.Confidence.ATTRIBUTE,
                source = path .. "." .. locationName .. ":GetAttribute('" .. eventConfig.ActiveAttributeName .. "')",
                layer = "Layer 1: Fast Detection (AttributeChanged)",
            })
        end)
        if connection then
            table.insert(SeaEventDetector._connections, connection)
        end
    end

    local existing = container:FindFirstChild(locationName)
    if existing then
        watchFactoryInstance(existing)
    end

    local addedConn = container.ChildAdded:Connect(function(child)
        if child.Name == locationName then
            watchFactoryInstance(child)
        end
    end)
    table.insert(SeaEventDetector._connections, addedConn)
end

function SeaEventDetector.Start()
    watchLocationEvent("SeaEvents.MirageIsland", "MirageIsland", "Mirage Island")
    watchLocationEvent("SeaEvents.PrehistoricIsland", "PrehistoricIsland", "Prehistoric Island")
    watchModelEvent("SeaEvents.Leviathan", "Leviathan", "Leviathan")
    watchModelEvent("SeaEvents.ElitePirates", "ElitePirates", "Elite Pirates")
    watchFactoryRaid()

    Logger.Info("SeaEventDetector", "Started (" .. #SeaEventDetector._connections .. " active watcher(s) — events without confirmed [verify] fields are skipped)")
end

function SeaEventDetector.Stop()
    for _, connection in ipairs(SeaEventDetector._connections) do
        pcall(function() connection:Disconnect() end)
    end
    SeaEventDetector._connections = {}
end

function SeaEventDetector.FallbackSweep()
    -- Intentionally a no-op beyond what the persistent watchers already
    -- cover — see doc comment above.
end

return SeaEventDetector
end)()

-- WorkspaceInspector
local WorkspaceInspector = (function()
-- dev dump tool


local WorkspaceInspector = {}

local Workspace = nil
local CollectionService = nil
pcall(function()
    Workspace = game:GetService("Workspace")
    CollectionService = game:GetService("CollectionService")
end)

local function writeLine(buffer, line)
    table.insert(buffer, line)
    Logger.Info("Inspector", line)
end

--- Dumps Workspace.Enemies contents — confirms the boss container and
--- shows exactly what names/classes are actually inside it right now.
function WorkspaceInspector.DumpEnemies(buffer)
    buffer = buffer or {}
    writeLine(buffer, "== Workspace.Enemies ==")

    local container = Workspace and Workspace:FindFirstChild("Enemies")
    if not container then
        writeLine(buffer, "  NOT FOUND at this path. Try WorkspaceInspector.FindContainers() to search for the real name.")
        return buffer
    end

    local children = container:GetChildren()
    writeLine(buffer, "  " .. #children .. " child(ren) currently present:")
    for _, child in ipairs(children) do
        local hasHumanoid = child:FindFirstChildOfClass("Humanoid") ~= nil
        local attrs = {}
        for attrName, attrValue in pairs(child:GetAttributes()) do
            table.insert(attrs, attrName .. "=" .. tostring(attrValue))
        end
        writeLine(buffer, string.format("    - %s (%s)%s%s",
            child.Name, child.ClassName,
            hasHumanoid and " [has Humanoid]" or "",
            (#attrs > 0) and (" attrs: " .. table.concat(attrs, ", ")) or ""))
    end

    return buffer
end

--- Dumps Workspace._WorldOrigin.Locations contents — this is where
--- island-type events (Mirage, Prehistoric) should be looked for.
function WorkspaceInspector.DumpLocations(buffer)
    buffer = buffer or {}
    writeLine(buffer, "== Workspace._WorldOrigin.Locations ==")

    local origin = Workspace and Workspace:FindFirstChild("_WorldOrigin")
    local container = origin and origin:FindFirstChild("Locations")
    if not container then
        writeLine(buffer, "  NOT FOUND at this path. Try WorkspaceInspector.FindContainers() to search for the real name.")
        return buffer
    end

    local children = container:GetChildren()
    writeLine(buffer, "  " .. #children .. " child(ren) currently present:")
    for _, child in ipairs(children) do
        writeLine(buffer, string.format("    - %s (%s)", child.Name, child.ClassName))
    end

    return buffer
end

function WorkspaceInspector.DumpTags(buffer)
    buffer = buffer or {}
    writeLine(buffer, "== CollectionService Tags ==")

    if not CollectionService then
        writeLine(buffer, "  CollectionService unavailable")
        return buffer
    end

    local ok, tags = pcall(function() return CollectionService:GetAllTags() end)
    if not ok or not tags or #tags == 0 then
        writeLine(buffer, "  No tags found (or GetAllTags unsupported on this executor)")
        return buffer
    end

    for _, tag in ipairs(tags) do
        local countOk, tagged = pcall(function() return CollectionService:GetTagged(tag) end)
        writeLine(buffer, "  " .. tag .. ": " .. (countOk and #tagged or "?") .. " instance(s)")
    end

    return buffer
end

--- Dumps current Lighting properties relevant to Full Moon detection.
function WorkspaceInspector.DumpLighting(buffer)
    buffer = buffer or {}
    writeLine(buffer, "== Lighting ==")

    local ok, lighting = pcall(function() return game:GetService("Lighting") end)
    if not ok then
        writeLine(buffer, "  Lighting service unavailable")
        return buffer
    end

    pcall(function() writeLine(buffer, "  ClockTime: " .. tostring(lighting.ClockTime)) end)
    pcall(function() writeLine(buffer, "  Brightness: " .. tostring(lighting.Brightness)) end)

    local attrs = {}
    for attrName, attrValue in pairs(lighting:GetAttributes()) do
        table.insert(attrs, attrName .. "=" .. tostring(attrValue))
    end
    writeLine(buffer, "  Attributes: " .. (#attrs > 0 and table.concat(attrs, ", ") or "(none)"))

    return buffer
end

function WorkspaceInspector.DumpSea(buffer)
    buffer = buffer or {}
    writeLine(buffer, "== Sea / PlaceId ==")

    local ok, placeId = pcall(function() return game.PlaceId end)
    writeLine(buffer, "  game.PlaceId: " .. (ok and tostring(placeId) or "unavailable"))
    writeLine(buffer, "  SeaManager.GetCurrentSea(): " .. tostring(SeaManager.GetCurrentSea() or "Unknown (add this PlaceId to Config.Scanner.SeaMap)"))

    return buffer
end

function WorkspaceInspector.FindContainers(searchTerms)
    searchTerms = searchTerms or { "enem", "boss", "event", "location", "island", "raid", "factory", "mirage", "leviathan" }
    local buffer = {}
    writeLine(buffer, "== Searching Workspace for likely containers ==")

    if not Workspace then
        writeLine(buffer, "  Workspace unavailable")
        return buffer
    end

    for _, child in ipairs(Workspace:GetChildren()) do
        local lowerName = string.lower(child.Name)
        for _, term in ipairs(searchTerms) do
            if string.find(lowerName, term) then
                writeLine(buffer, string.format("  %s (%s) — matched '%s'", child.Name, child.ClassName, term))
                break
            end
        end
    end

    return buffer
end

--- Runs every dump above and writes the combined output to a file
--- (Lumexa_Inspector.txt) if the executor supports writefile.
function WorkspaceInspector.RunFull()
    local buffer = {}
    WorkspaceInspector.DumpSea(buffer)
    WorkspaceInspector.DumpEnemies(buffer)
    WorkspaceInspector.DumpLocations(buffer)
    WorkspaceInspector.DumpTags(buffer)
    WorkspaceInspector.DumpLighting(buffer)
    WorkspaceInspector.FindContainers()

    local ok, supported = pcall(function() return writefile ~= nil end)
    if ok and supported then
        pcall(writefile, "Lumexa_Inspector.txt", table.concat(buffer, "\n"))
        Logger.Info("Inspector", "Full report written to Lumexa_Inspector.txt")
    end

    return buffer
end

return WorkspaceInspector
end)()

-- ScannerCore
local ScannerCore = (function()
-- detection orchestrator


local ScannerCore = {}

ScannerCore._running = false
ScannerCore._allClearListeners = {}
-- starts false, not true, or a boss-less server never fires the clear signal
ScannerCore._wasClear = false

function ScannerCore.SubscribeAllClear(callback)
    if type(callback) ~= "function" then
        return false, "Listener must be a function"
    end
    table.insert(ScannerCore._allClearListeners, callback)
    return true
end

local function notifyAllClear()
    for _, listener in ipairs(ScannerCore._allClearListeners) do
        pcall(listener)
    end
end

local DEBOUNCE_SECONDS = 3
local emptySince = nil

local function checkClearToHop()
    local sightings = BossDetector.GetActiveSightings()
    local count = 0
    for _ in pairs(sightings) do count = count + 1 end

    if count > 0 then
        emptySince = nil
        ScannerCore._wasClear = false
        return
    end

    if not emptySince then
        emptySince = os.clock()
        return
    end

    if (os.clock() - emptySince) >= DEBOUNCE_SECONDS and not ScannerCore._wasClear then
        ScannerCore._wasClear = true
        Logger.Info("ScannerCore", "No active bosses for " .. DEBOUNCE_SECONDS .. "s — clear to hop")
        notifyAllClear()
    end
end

function ScannerCore.Start()
    if ScannerCore._running then
        Logger.Warn("ScannerCore", "Start called but already running")
        return false
    end

    BossDetector.Start()
    LightingDetector.Start()
    SeaEventDetector.Start()

    ScannerCore._running = true

    local lastFallbackSweep = os.clock()
    local lastCacheSweep = os.clock()

    task.spawn(function()
        while ScannerCore._running do
            pcall(checkClearToHop)

            if Config.Get("Detection.FallbackSweepEnabled") then
                local sweepInterval = Config.Get("Detection.FallbackSweepIntervalSeconds") or 30
                if (os.clock() - lastFallbackSweep) >= sweepInterval then
                    pcall(BossDetector.FallbackSweep)
                    pcall(LightingDetector.FallbackSweep)
                    pcall(SeaEventDetector.FallbackSweep)
                    lastFallbackSweep = os.clock()
                end
            end

            local cacheSweepInterval = Config.Get("Cache.SweepIntervalSeconds") or 300
            if (os.clock() - lastCacheSweep) >= cacheSweepInterval then
                pcall(Cache.ExpireOld)
                lastCacheSweep = os.clock()
            end

            task.wait(1)
        end
    end)

    Logger.Info("ScannerCore", "Detection engine started")
    return true
end

function ScannerCore.Stop()
    if not ScannerCore._running then
        return false
    end

    ScannerCore._running = false
    BossDetector.Stop()
    LightingDetector.Stop()
    SeaEventDetector.Stop()

    Logger.Info("ScannerCore", "Detection engine stopped")
    return true
end

--- For the Dashboard / debug use: active boss sightings right now.
function ScannerCore.GetActiveSightings()
    return BossDetector.GetActiveSightings()
end

return ScannerCore
end)()

-- ServerHop
local ServerHop = (function()
-- server hopping


local ServerHop = {}

ServerHop._hopping = false
ServerHop._visitedJobIds = {} -- JobId -> timestamp (os.clock()) of when it was visited/tried

local TeleportService = nil
local HttpService = nil
local Players = nil

pcall(function()
    TeleportService = game:GetService("TeleportService")
    HttpService = game:GetService("HttpService")
    Players = game:GetService("Players")
end)

-- Mark our own starting server as visited so we never "hop" to ourselves.
pcall(function()
    ServerHop._visitedJobIds[game.JobId] = os.clock()
end)

--- Fetches a single page of public server instances for the current place.
--- Returns (servers, nextCursor) or (nil, nil) on failure.
local function fetchServerPage(cursor)
    if not HttpService then
        Logger.Error("ServerHop", "HttpService unavailable")
        return nil, nil
    end

    local placeId = game.PlaceId
    local url = string.format(
        "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100",
        placeId
    )
    if cursor and cursor ~= "" then
        url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
    end

    local ok, response = pcall(function()
        return HttpService:GetAsync(url)
    end)

    if not ok then
        Logger.Error("ServerHop", "Failed to fetch server list: " .. tostring(response))
        return nil, nil
    end

    local decodeOk, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)

    if not decodeOk or not data or not data.data then
        Logger.Error("ServerHop", "Failed to decode server list")
        return nil, nil
    end

    return data.data, data.nextPageCursor
end

--- Returns true if a server is a valid hop candidate: not visited,
--- has room, and falls within the configured player-count thresholds.
local function isCandidate(server)
    local minPlayers = Config.Get("ServerHop.MinPlayers") or 0
    local maxPlayers = Config.Get("ServerHop.MaxPlayers") or 100

    if ServerHop._visitedJobIds[server.id] then
        return false
    end
    if server.playing >= server.maxPlayers then
        return false -- full
    end
    if server.playing < minPlayers or server.playing > maxPlayers then
        return false
    end
    return true
end

local function findBestServer()
    local cursor = nil
    local bestServer = nil
    local bestAvailable = -1
    local maxPages = Config.Get("ServerHop.MaxPagesToScan") or 25
    local pagesScanned = 0

    repeat
        local servers, nextCursor = fetchServerPage(cursor)
        pagesScanned = pagesScanned + 1

        if not servers then
            break -- fetch failed, stop scanning this attempt
        end

        for _, server in ipairs(servers) do
            if isCandidate(server) then
                local available = server.maxPlayers - server.playing
                if available > bestAvailable then
                    bestAvailable = available
                    bestServer = server
                end
            end
        end

        cursor = nextCursor
    until not cursor or cursor == "" or pagesScanned >= maxPages

    if cursor and cursor ~= "" and pagesScanned >= maxPages then
        Logger.Warn("ServerHop", string.format("Stopped scanning after safety cap of %d pages", maxPages))
    end

    return bestServer, pagesScanned
end

--- Attempts the actual teleport call, retrying on failure per config.
local function teleportWithRetry(target)
    local maxRetries = Config.Get("ServerHop.MaxTeleportRetries") or 3
    local retryDelay = Config.Get("ServerHop.TeleportRetryDelaySeconds") or 3

    for attempt = 1, maxRetries do
        local ok, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, target.id, Players.LocalPlayer)
        end)

        if ok then
            return true, nil
        end

        Logger.Warn("ServerHop", string.format("Teleport attempt %d/%d failed: %s", attempt, maxRetries, tostring(err)))
        Status.Set(Status.States.TELEPORT_FAILED)

        if attempt < maxRetries then
            Status.Set(Status.States.RETRYING)
            task.wait(retryDelay)
        end
    end

    return false, "Teleport failed after " .. tostring(maxRetries) .. " attempts"
end

--- Attempts a single server hop. Returns success (bool), reason (string)
function ServerHop.HopOnce()
    if not Config.Get("ServerHop.Enabled") then
        return false, "ServerHop is disabled in config"
    end

    if ServerHop._hopping then
        return false, "Already hopping"
    end

    if not TeleportService then
        return false, "TeleportService unavailable"
    end

    ServerHop._hopping = true
    Status.Set(Status.States.SERVER_HOPPING)

    -- everything below runs inside pcall so _hopping always resets, even on crash
    local crashed, ok, err = pcall(function()
        local target, pagesScanned = findBestServer()
        if not target then
            Logger.Warn("ServerHop", string.format("No suitable server found after scanning %d page(s)", pagesScanned or 0))
            return false, "No suitable server found"
        end

        Logger.Info("ServerHop", string.format(
            "Selected server %s (%d/%d players, %d slot(s) free) after scanning %d page(s)",
            tostring(target.id), target.playing, target.maxPlayers, target.maxPlayers - target.playing, pagesScanned or 0
        ))

        local teleportOk, teleportErr = teleportWithRetry(target)
        if teleportOk then
            ServerHop.MarkVisited(target.id)
            Logger.Info("ServerHop", "Hopping to server " .. tostring(target.id))
        end
        return teleportOk, teleportErr
    end)

    ServerHop._hopping = false

    if not crashed then
        Logger.Error("ServerHop", "HopOnce crashed: " .. tostring(ok))
        return false, "Internal error: " .. tostring(ok)
    end

    if not ok then
        Logger.Error("ServerHop", tostring(err))
        return false, err
    end

    return true, nil
end

--- Convenience wrapper with the configured delay applied before hopping.
function ServerHop.HopWithDelay()
    local delay = Config.Get("ServerHop.HopDelay") or 5
    Status.Set(Status.States.WAITING)
    task.spawn(function()
        task.wait(delay)
        Utilities.SafeCall(ServerHop.HopOnce, "ServerHop")
    end)
end

--- Manually mark a JobId as visited (e.g. if learned from elsewhere)
function ServerHop.MarkVisited(jobId)
    if not jobId then return end

    local maxVisited = 5000
    if ServerHop.GetVisitedCount() >= maxVisited then
        Logger.Warn("ServerHop", "Visited-JobId cache exceeded " .. maxVisited .. ", clearing")
        ServerHop._visitedJobIds = {}
        pcall(function() ServerHop._visitedJobIds[game.JobId] = os.clock() end)
    end

    ServerHop._visitedJobIds[jobId] = os.clock()
end

function ServerHop.GetVisitedCount()
    local count = 0
    for _ in pairs(ServerHop._visitedJobIds) do
        count = count + 1
    end
    return count
end

--- Purges visited-JobId entries older than Config.Cache.LifetimeSeconds.
--- Called from ServerHop's own lightweight maintenance loop below.
local function expireVisited()
    local lifetime = Config.Get("Cache.LifetimeSeconds") or 3600
    local now = os.clock()
    local expired = {}

    for jobId, visitedAt in pairs(ServerHop._visitedJobIds) do
        if (now - visitedAt) > lifetime then
            table.insert(expired, jobId)
        end
    end

    for _, jobId in ipairs(expired) do
        ServerHop._visitedJobIds[jobId] = nil
    end

    if #expired > 0 then
        Logger.Debug("ServerHop", string.format("Expired %d old visited-JobId entr%s", #expired, #expired == 1 and "y" or "ies"))
    end
end

task.spawn(function()
    while true do
        local sweepInterval = Config.Get("Cache.SweepIntervalSeconds") or 300
        task.wait(sweepInterval)
        pcall(expireVisited)
    end
end)

return ServerHop
end)()

-- UI
local UI = (function()
-- rayfield ui


local UI = {}

UI._window = nil
UI._tabs = {}
UI._initialized = false
UI._dashboardRunning = false
UI._Rayfield = nil -- stored so the Credits button can call Rayfield:Notify

local function safeRequireRayfield()
    local ok, Rayfield = pcall(function()
        return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    end)

    if not ok then
        Logger.Error("UI", "Failed to load Rayfield: " .. tostring(Rayfield))
        return nil
    end

    return Rayfield
end

local function detectExecutorName()
    local ok, name = pcall(function()
        if identifyexecutor then
            return (identifyexecutor())
        end
        return nil
    end)

    if ok and type(name) == "string" and name ~= "" then
        return name
    end

    -- Fallback heuristics if identifyexecutor isn't available
    local checks = {
        { "Delta", function() return Delta ~= nil end },
        { "Codex", function() return Codex ~= nil end },
        { "Synapse X", function() return syn ~= nil end },
        { "Fluxus", function() return fluxus ~= nil end },
        { "Krnl", function() return KRNL_LOADED ~= nil end },
    }
    for _, check in ipairs(checks) do
        local checkName, fn = check[1], check[2]
        local checkOk, matched = pcall(fn)
        if checkOk and matched then
            return checkName
        end
    end

    return "Unknown"
end

function UI.Init()
    if UI._initialized then
        Logger.Warn("UI", "UI.Init called again but UI is already built — skipping to avoid duplicate windows/listeners")
        return true
    end

    local Rayfield = safeRequireRayfield()
    if not Rayfield then
        return false, "Rayfield failed to load"
    end
    UI._Rayfield = Rayfield

    local ok, err = pcall(function()
        UI._window = Rayfield:CreateWindow({
            Name = "Lumexa",
            LoadingTitle = "Lumexa",
            LoadingSubtitle = "Scanner",
            Theme = "Default",
            ConfigurationSaving = {
                Enabled = true,
                FolderName = "Lumexa",
                FileName = "Config",
            },
        })

        UI._tabs.Dashboard = UI._window:CreateTab("Dashboard")
        UI._buildDashboardTab()
    end)

    if not ok then
        Logger.Error("UI", "UI construction failed: " .. tostring(err))
        return false, tostring(err)
    end

    Logger.Info("UI", "Interface initialized")
    UI._initialized = true
    return true
end

function UI._buildDashboardTab()
    local tab = UI._tabs.Dashboard

    tab:CreateSection("Lumexa Scanner")

    local executorName = detectExecutorName()
    tab:CreateLabel("Executor: " .. executorName)

    tab:CreateButton({
        Name = "Credits",
        Callback = function()
            local shown = false
            if UI._Rayfield and UI._Rayfield.Notify then
                local notifyOk = pcall(function()
                    UI._Rayfield:Notify({
                        Title = "Credits",
                        Content = "@vantaorbureu",
                        Duration = 5,
                    })
                end)
                shown = notifyOk
            end
            if not shown then
                Logger.Info("UI", "Credits: @vantaorbureu")
            end
        end,
    })

    local fields = {
        BossesFound = tab:CreateLabel("Boss Found: " .. tostring(VerificationEngine.GetTotalFound())),
        WebhooksSent = tab:CreateLabel("Webhook Sent: " .. tostring(Webhook.GetTotalSent())),
    }

    local function refresh()
        pcall(function() fields.BossesFound:Set("Boss Found: " .. tostring(VerificationEngine.GetTotalFound())) end)
        pcall(function() fields.WebhooksSent:Set("Webhook Sent: " .. tostring(Webhook.GetTotalSent())) end)
    end

    refresh()

    UI._dashboardRunning = true
    task.spawn(function()
        while UI._dashboardRunning do
            pcall(refresh)
            task.wait(1)
        end
    end)
end

function UI.SetShutdownHandler(handler)
    UI._shutdownHandler = handler
end

function UI.Shutdown()
    UI._dashboardRunning = false

    if UI._window and UI._window.Destroy then
        pcall(function() UI._window:Destroy() end)
    end

    UI._window = nil
    UI._tabs = {}
    UI._initialized = false
    Logger.Info("UI", "UI shut down")
end

return UI
end)()

-- main
(function()
-- entry point


local Main = {}

Main._started = false

ScannerCore.SubscribeAllClear(function()
    if Main._started and Config.Get("ServerHop.Enabled") then
        Logger.Info("Main", "No active bosses, considering server hop")

        task.spawn(function()
            local deadline = os.clock() + 15
            while Webhook.GetQueueLength() > 0 and os.clock() < deadline do
                task.wait(0.5)
            end

            Utilities.SafeCall(ServerHop.HopWithDelay, "Main")
        end)
    end
end)

UI.SetShutdownHandler(function()
    Main.Shutdown()
end)

--[[
    Startup sequence:
        Config  -> already loaded — every module requires it first
        Logger  -> already loaded — active from the moment Config is ready
        UI      -> built so the user has visibility into everything below
        Scanner -> ScannerCore starts BossDetector, LightingDetector,
                   SeaEventDetector — all event-driven (see
                   ARCHITECTURE.md), continuous for the life of the script
        Queue   -> Webhook queue processor, always running so nothing
                   dispatched by VerificationEngine gets dropped
        Hopper  -> ServerHop itself is event-driven (wired to
                   ScannerCore's all-clear signal above), so its
                   "startup" step here is just announcing readiness
]]
function Main.Start()
    if Main._started then
        Logger.Warn("Main", "Start called but Lumexa is already running")
        return false
    end

    Logger.Info("Main", "Lumexa v" .. Config.Version .. " starting...")

    -- Stage: UI
    local uiOk, uiErr = Utilities.SafeCall(UI.Init, "Main")
    if not uiOk then
        Logger.Error("Main", "UI failed to initialize: " .. tostring(uiErr))
        -- continue anyway — framework can run headless
    end

    -- Stage: Scanner (detection engine)
    Utilities.SafeCall(SeaManager.DetectCurrentSea, "Main")
    if Config.Get("General.AutoStart") then
        Utilities.SafeCall(ScannerCore.Start, "Main")
    else
        Logger.Info("Main", "AutoStart disabled — detection engine is ready but waiting for manual start")
    end

    -- Stage: Queue
    Utilities.SafeCall(Webhook.StartQueueProcessor, "Main")

    -- Stage: Hopper
    if Config.Get("ServerHop.Enabled") then
        Logger.Info("Main", "ServerHop is enabled and listening for boss-cleared events")
    else
        Logger.Info("Main", "ServerHop is disabled in config")
    end

    if Config.Get("Intelligence.Enabled") then
        Utilities.SafeCall(RuntimeMonitor.Start, "Main")
        -- Stage 3: NPC/Boss Intelligence — live per-entity tracking
        -- built on top of what RuntimeMonitor discovers.
        Utilities.SafeCall(NPCIntelligence.Start, "Main")
        Utilities.SafeCall(BossIntelligence.Start, "Main")
        Utilities.SafeCall(IslandIntelligence.Start, "Main")
        Utilities.SafeCall(EventIntelligence.Start, "Main")
        -- Stage 5: Environment Intelligence — Lighting/Fog/Sky/Weather/
        -- Sea state tracking, also statistics-only.
        Utilities.SafeCall(EnvironmentIntelligence.Start, "Main")
        -- Stage 6: Statistics/History Engine — pure aggregation over
        -- everything above, no independent tracking state of its own.
        Utilities.SafeCall(StatisticsEngine.Start, "Main")
        Utilities.SafeCall(HistoryEngine.Start, "Main")
        -- Stage 7: Alert Engine — consumes HistoryEngine's timeline,
        -- generates local alerts only, never dispatches a webhook.
        Utilities.SafeCall(AlertEngine.Start, "Main")
        -- Timeline Engine — hybrid event-driven + poll capture, see
        -- TIMELINE_ENGINE.md for why it's not purely event-driven.
        Utilities.SafeCall(TimelineEngine.Start, "Main")
    end

    Main._started = true
    Config.SetRunning(true)
    Status.Set(Status.States.CONNECTED)
    Logger.Info("Main", "Lumexa started successfully")
    return true
end

function Main.GetUptime()
    return Config.GetUptime()
end

function Main.GetStatus()
    return Config.GetStatus()
end

function Main.Stop()
    if not Main._started then
        return false
    end

    Utilities.SafeCall(ScannerCore.Stop, "Main")
    Utilities.SafeCall(RuntimeMonitor.Stop, "Main")
    Utilities.SafeCall(NPCIntelligence.Stop, "Main")
    Utilities.SafeCall(BossIntelligence.Stop, "Main")
    Utilities.SafeCall(IslandIntelligence.Stop, "Main")
    Utilities.SafeCall(EventIntelligence.Stop, "Main")
    Utilities.SafeCall(EnvironmentIntelligence.Stop, "Main")
    Utilities.SafeCall(StatisticsEngine.Stop, "Main")
    Utilities.SafeCall(HistoryEngine.Stop, "Main")
    Utilities.SafeCall(AlertEngine.Stop, "Main")
    Utilities.SafeCall(TimelineEngine.Stop, "Main")
    Utilities.SafeCall(Webhook.StopQueueProcessor, "Main")

    Main._started = false
    Config.SetRunning(false)
    Logger.Info("Main", "Lumexa stopped")
    return true
end

function Main.Shutdown()
    Main.Stop()
    Utilities.SafeCall(UI.Shutdown, "Main")
    Logger.Info("Main", "Lumexa fully shut down")
    return true
end

Main.Start()

pcall(function()
    game:BindToClose(function()
        Logger.Info("Main", "Server shutting down — flushing webhook queue")
        Utilities.SafeCall(Webhook.FlushQueue, "Main", 8)
        Logger.Info("Main", "Shutdown flush complete, exiting")
    end)
end)

end)()
