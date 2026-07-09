--[[
    ================================================================
    VisionOS.lua - VisionUI Framework (Merged Release Build - AUDITED)
    ================================================================
    Single-file build combining every completed module below.

    AUDIT NOTE (this build fixes a critical bug from the first merge):
    The original merge script stripped every line matching "return X"
    to keep each module's table in scope for later modules - but that
    regex incorrectly ALSO matched internal "return self" / "return inst"
    / "return id" statements inside constructor functions throughout the
    framework, not just each file's final module export. That silently
    made almost every constructor (Utilities.Create, GlassPanel.new,
    Window.new, Button.new, Toggle.new, etc.) return nil instead of the
    real object, which is why no UI could appear. This build's merge
    script only strips the LAST "return X" line in each file (guaranteed
    to be that module's own export), leaving every internal return
    statement fully intact.

    HONEST SCOPE NOTE:
    Dialog.lua, ContextMenu.lua, SearchBar.lua, Dock.lua, Icons.lua,
    Config.lua, and WindowManager.lua were never implemented, so
    Library:Dialog/SaveConfig/LoadConfig/ExportConfig/ImportConfig and
    Section:AddKeybind/AddColorPicker are NOT available. Everything else
    (19 modules) is included and fully wired.
    ================================================================
]]

local VisionOS = {}



-- ======================================================================
-- MODULE: Core/Theme.lua
-- ======================================================================

--[[
    VisionUI Framework - Theme.lua
    ================================
    VisionOS-inspired design tokens: warm neutral glass colors,
    typography hierarchy, spacing, and animation curves.
]]

local Theme = {}

-- ========== COLOR SYSTEM ==========
Theme.Colors = {
    -- Glass backgrounds (warm neutral, per spec)
    GlassBackground   = Color3.fromRGB(245, 245, 245),
    PanelWhite        = Color3.fromRGB(255, 255, 255),

    -- Text hierarchy
    TextPrimary       = Color3.fromRGB(255, 255, 255),
    TextSecondary     = Color3.fromRGB(210, 210, 210),
    TextDisabled      = Color3.fromRGB(170, 170, 170),

    -- Accent
    Accent            = Color3.fromRGB(120, 180, 255), -- soft blue
    Selection         = Color3.fromRGB(255, 255, 255), -- white glass

    -- Semantic
    Success           = Color3.fromRGB(140, 230, 180),
    Warning           = Color3.fromRGB(255, 210, 130),
    Danger            = Color3.fromRGB(255, 140, 140),

    -- Structural
    Border            = Color3.fromRGB(255, 255, 255),
    Shadow            = Color3.fromRGB(0, 0, 0),
}

-- ========== TRANSPARENCY ==========
Theme.Glass = {
    BackgroundTransparency = 0.35,   -- 0.25~0.45 per spec, mid value
    PanelTransparency       = 0.55,
    BorderTransparency      = 0.75,
    HighlightTransparency   = 0.85,
    ShadowTransparency      = 0.92,  -- very soft, never solid black
    ReflectionTransparency  = 0.9,
}

-- ========== TYPOGRAPHY ==========
Theme.Fonts = {
    Display   = Enum.Font.GothamBold,
    Title     = Enum.Font.GothamBold,
    Body      = Enum.Font.Gotham,
    Semibold  = Enum.Font.GothamSemibold,
    Caption   = Enum.Font.Gotham,
}

Theme.TextSizes = {
    Display   = 28,
    Title     = 20,
    Subtitle  = 14,
    Body      = 13,
    Caption   = 11,
    Micro     = 10,
}

-- ========== CORNER RADIUS ==========
Theme.Corner = {
    Window    = UDim.new(0, 28), -- 24-32px per spec
    Panel     = UDim.new(0, 22),
    Card      = UDim.new(0, 18),
    Control   = UDim.new(0, 12),
    Pill      = UDim.new(1, 0),
    Dock      = UDim.new(0, 26),
}

-- ========== SPACING ==========
Theme.Spacing = {
    XS = 4,
    S  = 8,
    M  = 14,
    L  = 20,
    XL = 28,
    XXL = 40,
}

Theme.Sizes = {
    WindowSize    = UDim2.fromOffset(960, 620),
    SidebarWidth  = 260,
    DockHeight    = 76,
    SearchHeight  = 44,
    RowHeight     = 46,
}

-- ========== ANIMATION CURVES ==========
Theme.Animation = {
    -- Spring-like easing via Back/Elastic for that "fluent" bounce
    Spring     = TweenInfo.new(0.45, Enum.EasingStyle.Back,     Enum.EasingDirection.Out),
    Smooth     = TweenInfo.new(0.28, Enum.EasingStyle.Quint,    Enum.EasingDirection.Out),
    Fast       = TweenInfo.new(0.15, Enum.EasingStyle.Quad,     Enum.EasingDirection.Out),
    Hover      = TweenInfo.new(0.18, Enum.EasingStyle.Quad,     Enum.EasingDirection.Out),
    Press      = TweenInfo.new(0.08, Enum.EasingStyle.Quad,     Enum.EasingDirection.Out),
    TabSwitch  = TweenInfo.new(0.32, Enum.EasingStyle.Quint,    Enum.EasingDirection.Out),
    WindowOpen = TweenInfo.new(0.5,  Enum.EasingStyle.Back,     Enum.EasingDirection.Out),
    Toast      = TweenInfo.new(0.4,  Enum.EasingStyle.Back,     Enum.EasingDirection.Out),
}





-- ======================================================================
-- MODULE: Core/Utilities.lua
-- ======================================================================

--[[
    VisionUI Framework - Utilities.lua
    ====================================
    Generic instance-creation helpers shared across the framework.
]]

local Utilities = {}

function Utilities.Create(className, properties, children)
    local inst = Instance.new(className)
    if properties then
        for prop, value in pairs(properties) do
            inst[prop] = value
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = inst
        end
    end
    return inst
end

function Utilities.Corner(radius)
    return Utilities.Create("UICorner", { CornerRadius = radius })
end

function Utilities.Stroke(color, transparency, thickness)
    return Utilities.Create("UIStroke", {
        Color = color,
        Transparency = transparency or 0.8,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

function Utilities.Gradient(colorSequence, rotation, transparencySequence)
    return Utilities.Create("UIGradient", {
        Color = colorSequence,
        Rotation = rotation or 0,
        Transparency = transparencySequence,
    })
end

function Utilities.Padding(top, right, bottom, left)
    return Utilities.Create("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or top or 0),
        PaddingBottom = UDim.new(0, bottom or top or 0),
        PaddingLeft = UDim.new(0, left or right or top or 0),
    })
end

function Utilities.ListLayout(direction, padding, sortOrder, hAlign, vAlign)
    return Utilities.Create("UIListLayout", {
        FillDirection = direction or Enum.FillDirection.Vertical,
        Padding = UDim.new(0, padding or 0),
        SortOrder = sortOrder or Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
        VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
    })
end

function Utilities.Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

function Utilities.Lerp(a, b, t)
    return a + (b - a) * t
end

-- Generates a unique incrementing id, useful for Signal/connection bookkeeping
local idCounter = 0
function Utilities.NextId()
    idCounter += 1
    return idCounter
end





-- ======================================================================
-- MODULE: Core/Signal.lua
-- ======================================================================

--[[
    VisionUI Framework - Core/Signal.lua
    =======================================
    Minimal custom signal implementation so components can expose
    :OnChanged(), :OnClick() etc. without depending on BindableEvents
    (cheaper, and keeps everything in pure Luau tables).
]]

local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({ _listeners = {} }, Signal)
end

function Signal:Connect(fn)
    local id = #self._listeners + 1
    self._listeners[id] = fn
    local connection = { Connected = true }
    function connection:Disconnect()
        self.Connected = false
        self._listeners[id] = nil
    end
    connection._listeners = self._listeners
    return connection
end

function Signal:Fire(...)
    for _, fn in pairs(self._listeners) do
        task.spawn(fn, ...)
    end
end

function Signal:DisconnectAll()
    self._listeners = {}
end





-- ======================================================================
-- MODULE: Core/GlassPanel.lua
-- ======================================================================

--[[
    VisionUI Framework - Core/GlassPanel.lua
    ===========================================
    Since Roblox cannot blur content behind a UI element, this module
    fakes the frosted "Liquid Glass" look using stacked, layered frames:

        Shadow Layer      (soft, far behind, never solid black)
        Outer Glow        (large soft accent bloom)
        Outer Border      (1px semi-transparent white ring)
        Glass Layer        (the actual translucent panel body)
        Highlight Layer    (subtle top-edge light catch)
        Reflection Layer   (soft diagonal sheen gradient)
        Content Layer       (where real content gets parented)

    GlassPanel.new() returns a table with:
        .Root        -> outermost Frame (use this to Position/Size/Parent)
        .Glass       -> the glass body Frame
        .Content     -> Frame where you should parent buttons/labels/etc
]]


local GlassPanel = {}
GlassPanel.__index = GlassPanel

-- config = {
--   Size, Position, CornerRadius, Parent,
--   AccentColor (glow tint), Elevation (shadow size multiplier 1-3),
--   NoContent (bool, skip creating a content layer)
-- }
function GlassPanel.new(config)
    config = config or {}
    local self = setmetatable({}, GlassPanel)

    local corner = config.CornerRadius or Theme.Corner.Panel
    local accent = config.AccentColor or Theme.Colors.Accent
    local elevation = config.Elevation or 1

    -- ===== ROOT (invisible positioning anchor) =====
    self.Root = Utilities.Create("Frame", {
        Name = "GlassPanelRoot",
        Size = config.Size or UDim2.fromOffset(300, 200),
        Position = config.Position or UDim2.fromOffset(0, 0),
        AnchorPoint = config.AnchorPoint or Vector2.new(0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = config.Parent,
    })

    -- ===== SHADOW LAYER (soft, multi-ring, never black) =====
    self.Shadow = Utilities.Create("Frame", {
        Name = "ShadowLayer",
        Size = UDim2.new(1, 20 * elevation, 1, 20 * elevation),
        Position = UDim2.new(0.5, 0, 0.5, 6 * elevation),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Colors.Shadow,
        BackgroundTransparency = Theme.Glass.ShadowTransparency,
        BorderSizePixel = 0,
        ZIndex = 1,
        Parent = self.Root,
    }, {
        Utilities.Corner(UDim.new(0, corner.Offset + 10)),
    })

    -- Second, tighter shadow ring for depth layering
    self.ShadowInner = Utilities.Create("Frame", {
        Name = "ShadowLayerInner",
        Size = UDim2.new(1, 8, 1, 8),
        Position = UDim2.new(0.5, 0, 0.5, 3),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Colors.Shadow,
        BackgroundTransparency = Theme.Glass.ShadowTransparency + 0.03,
        BorderSizePixel = 0,
        ZIndex = 1,
        Parent = self.Root,
    }, {
        Utilities.Corner(UDim.new(0, corner.Offset + 4)),
    })

    -- ===== OUTER GLOW (accent-tinted soft bloom) =====
    self.Glow = Utilities.Create("Frame", {
        Name = "OuterGlow",
        Size = UDim2.new(1, 16, 1, 16),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = accent,
        BackgroundTransparency = 0.94,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = self.Root,
    }, {
        Utilities.Corner(UDim.new(0, corner.Offset + 8)),
    })

    -- ===== GLASS LAYER (the visible panel body) =====
    self.Glass = Utilities.Create("Frame", {
        Name = "GlassLayer",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.Colors.GlassBackground,
        BackgroundTransparency = Theme.Glass.PanelTransparency,
        BorderSizePixel = 0,
        ZIndex = 3,
        ClipsDescendants = true,
        Parent = self.Root,
    }, {
        Utilities.Corner(corner),
    })

    -- ===== OUTER BORDER (1px semi-transparent white ring) =====
    Utilities.Stroke(Theme.Colors.Border, Theme.Glass.BorderTransparency, 1).Parent = self.Glass

    -- ===== HIGHLIGHT LAYER (top-edge light catch) =====
    self.Highlight = Utilities.Create("Frame", {
        Name = "HighlightLayer",
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Theme.Colors.PanelWhite,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = self.Glass,
    })

    -- ===== REFLECTION LAYER (soft diagonal sheen) =====
    self.Reflection = Utilities.Create("Frame", {
        Name = "ReflectionLayer",
        Size = UDim2.fromScale(1, 0.5),
        Position = UDim2.fromScale(0, 0),
        BackgroundColor3 = Theme.Colors.PanelWhite,
        BackgroundTransparency = 1, -- transparency driven entirely by gradient below
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = self.Glass,
    }, {
        Utilities.Gradient(
            ColorSequence.new(Theme.Colors.PanelWhite),
            75,
            NumberSequence.new({
                NumberSequenceKeypoint.new(0, Theme.Glass.ReflectionTransparency),
                NumberSequenceKeypoint.new(1, 1),
            })
        ),
    })

    -- ===== CONTENT LAYER =====
    if not config.NoContent then
        self.Content = Utilities.Create("Frame", {
            Name = "ContentLayer",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ZIndex = 5,
            Parent = self.Glass,
        })
    end

    return self
end

-- Updates the glow tint (used for hover/selection states)
function GlassPanel:SetAccent(color)
    self.Glow.BackgroundColor3 = color
end

function GlassPanel:Destroy()
    if self.Root then
        self.Root:Destroy()
    end
end





-- ======================================================================
-- MODULE: Core/Window.lua
-- ======================================================================

--[[
    VisionUI Framework - Core/Window.lua
    =======================================
    The main floating glass window. Handles:
    - Spring-in open animation
    - Smooth inertial dragging (mouse + touch)
    - Minimize / Restore / Close / BringToFront
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")


local Window = {}
Window.__index = Window

function Window.new(screenGui, config)
    config = config or {}
    local self = setmetatable({}, Window)

    self._connections = {}
    self.Minimized = false
    self.Title = config.Title or "VisionUI"
    -- AUDIT FIX: accept both `Subtitle` and `SubTitle` casings.
    self.Subtitle = config.Subtitle or config.SubTitle or ""

    local size = config.Size or Theme.Sizes.WindowSize

    -- ===== GLASS PANEL (root window body) =====
    self.Panel = GlassPanel.new({
        Size = size,
        Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        CornerRadius = Theme.Corner.Window,
        Parent = screenGui,
        Elevation = 2,
        NoContent = true,
    })

    self.Root = self.Panel.Root
    self.Glass = self.Panel.Glass

    -- ===== TITLE BAR =====
    self.TitleBar = Utilities.Create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundTransparency = 1,
        ZIndex = 5,
        Parent = self.Glass,
    }, {
        Utilities.Padding(0, 24, 0, 24),
        Utilities.ListLayout(Enum.FillDirection.Horizontal, 12, Enum.SortOrder.LayoutOrder, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center),
    })

    local titleBlock = Utilities.Create("Frame", {
        Size = UDim2.new(0.6, 0, 1, 0),
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        Parent = self.TitleBar,
    }, { Utilities.ListLayout(Enum.FillDirection.Vertical, 0, Enum.SortOrder.LayoutOrder, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center) })

    Utilities.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = self.Title,
        TextColor3 = Theme.Colors.TextPrimary,
        Font = Theme.Fonts.Title,
        TextSize = Theme.TextSizes.Title,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
        Parent = titleBlock,
    })

    if self.Subtitle ~= "" then
        Utilities.Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Text = self.Subtitle,
            TextColor3 = Theme.Colors.TextSecondary,
            Font = Theme.Fonts.Body,
            TextSize = Theme.TextSizes.Caption,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 2,
            Parent = titleBlock,
        })
    end

    -- ===== WINDOW CONTROLS (minimize / close), pill-glass style =====
    local controls = Utilities.Create("Frame", {
        Size = UDim2.fromOffset(76, 32),
        Position = UDim2.new(1, -76, 0.5, -16),
        BackgroundColor3 = Theme.Colors.PanelWhite,
        BackgroundTransparency = 0.85,
        ZIndex = 6,
        Parent = self.TitleBar,
    }, {
        Utilities.Corner(Theme.Corner.Pill),
        Utilities.Stroke(Theme.Colors.Border, 0.8),
        Utilities.ListLayout(Enum.FillDirection.Horizontal, 4, Enum.SortOrder.LayoutOrder, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center),
    })

    local function controlButton(symbol, order, onClick)
        local btn = Utilities.Create("TextButton", {
            Size = UDim2.fromOffset(28, 28),
            BackgroundTransparency = 1,
            Text = symbol,
            TextColor3 = Theme.Colors.TextPrimary,
            TextTransparency = 0.2,
            Font = Theme.Fonts.Semibold,
            TextSize = 14,
            AutoButtonColor = false,
            LayoutOrder = order,
            Parent = controls,
        }, { Utilities.Corner(Theme.Corner.Pill) })

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, Theme.Animation.Hover, { TextTransparency = 0 }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, Theme.Animation.Hover, { TextTransparency = 0.2 }):Play()
        end)
        if onClick then
            btn.MouseButton1Click:Connect(onClick)
        end
        return btn
    end

    controlButton("–", 1, function() self:ToggleMinimize() end)
    controlButton("×", 2, function() self:Hide() end)

    -- ===== BODY (below title bar, holds sidebar + content) =====
    self.Body = Utilities.Create("Frame", {
        Name = "Body",
        Size = UDim2.new(1, 0, 1, -56),
        Position = UDim2.new(0, 0, 0, 56),
        BackgroundTransparency = 1,
        ZIndex = 5,
        Parent = self.Glass,
    })

    self:_setupDragging()
    self:_playOpenAnimation()

    return self
end

-- ========== OPEN ANIMATION (fade + scale + slide, spring) ==========
function Window:_playOpenAnimation()
    local root = self.Root
    local targetPos = root.Position
    local targetSize = root.Size

    root.Position = targetPos + UDim2.fromOffset(0, 24)
    self.Glass.BackgroundTransparency = 1
    self.Panel.Glow.BackgroundTransparency = 1

    root.Size = UDim2.new(targetSize.X.Scale, targetSize.X.Offset * 0.92, targetSize.Y.Scale, targetSize.Y.Offset * 0.92)

    TweenService:Create(root, Theme.Animation.WindowOpen, {
        Position = targetPos,
        Size = targetSize,
    }):Play()

    TweenService:Create(self.Glass, Theme.Animation.Smooth, {
        BackgroundTransparency = Theme.Glass.PanelTransparency,
    }):Play()

    TweenService:Create(self.Panel.Glow, Theme.Animation.Smooth, {
        BackgroundTransparency = 0.94,
    }):Play()
end

-- ========== DRAGGING (smooth, inertial, mouse + touch) ==========
function Window:_setupDragging()
    local dragging = false
    local dragStart, startPos
    local velocity = Vector2.new(0, 0)
    local lastInputPos = Vector2.new(0, 0)
    local lastTime = 0

    local function beginDrag(pos)
        dragging = true
        dragStart = pos
        startPos = self.Root.Position
        lastInputPos = pos
        lastTime = os.clock()
        velocity = Vector2.new(0, 0)
        self:BringToFront()
    end

    table.insert(self._connections, self.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            beginDrag(input.Position)
        end
    end))

    table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local now = os.clock()
            local dt = math.max(now - lastTime, 1 / 144)
            local delta = input.Position - dragStart

            self.Root.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )

            velocity = (input.Position - lastInputPos) / dt
            lastInputPos = input.Position
            lastTime = now
        end
    end))

    table.insert(self._connections, UserInputService.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false

            -- brief inertial glide for a "smooth, no jitter" feel
            local glideConn
            local glideTime = 0
            glideConn = RunService.RenderStepped:Connect(function(dt)
                glideTime += dt
                velocity = velocity * 0.9
                if glideTime > 0.35 or velocity.Magnitude < 2 then
                    glideConn:Disconnect()
                    return
                end
                self.Root.Position = self.Root.Position + UDim2.fromOffset(velocity.X * dt, velocity.Y * dt)
            end)
        end
    end))
end

-- ========== WINDOW SYSTEM API ==========
function Window:BringToFront()
    -- Roblox renders siblings by DisplayOrder / insertion; simplest robust
    -- approach is to reparent to the end of the ScreenGui's children.
    local parent = self.Root.Parent
    if parent then
        self.Root.Parent = nil
        self.Root.Parent = parent
    end
end

function Window:ToggleMinimize()
    if self.Minimized then
        self:Restore()
    else
        self:Minimize()
    end
end

function Window:Minimize()
    self.Minimized = true
    TweenService:Create(self.Body, Theme.Animation.Smooth, {}):Play() -- placeholder for future body fade
    self.Body.Visible = false
end

function Window:Restore()
    self.Minimized = false
    self.Body.Visible = true
end

function Window:Hide()
    TweenService:Create(self.Root, Theme.Animation.Fast, {
        Size = UDim2.new(self.Root.Size.X.Scale, self.Root.Size.X.Offset * 0.95, self.Root.Size.Y.Scale, self.Root.Size.Y.Offset * 0.95),
    }):Play()
    local tween = TweenService:Create(self.Glass, Theme.Animation.Fast, { BackgroundTransparency = 1 })
    tween:Play()
    tween.Completed:Connect(function()
        self.Root.Visible = false
    end)
end

function Window:Show()
    self.Root.Visible = true
    self:_playOpenAnimation()
end

function Window:Destroy()
    for _, conn in ipairs(self._connections) do
        conn:Disconnect()
    end
    self._connections = {}
    self.Panel:Destroy()
end





-- ======================================================================
-- MODULE: Core/Sidebar.lua
-- ======================================================================

--[[
    VisionUI Framework - Core/Sidebar.lua
    ========================================
    VisionOS-style sidebar: icon + title rows, a smoothly sliding
    "selection pill" behind the active row, and hover states.
]]

local TweenService = game:GetService("TweenService")


local Sidebar = {}
Sidebar.__index = Sidebar

function Sidebar.new(parentBody)
    local self = setmetatable({}, Sidebar)
    self.Items = {}
    self.ActiveId = nil
    self.Changed = Signal.new()

    self.Root = Utilities.Create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, Theme.Sizes.SidebarWidth, 1, 0),
        BackgroundTransparency = 1,
        Parent = parentBody,
    }, {
        Utilities.Padding(Theme.Spacing.M, Theme.Spacing.M, Theme.Spacing.M, Theme.Spacing.M),
    })

    -- Selection pill sits behind the ScrollingFrame's rows, positioned in
    -- screen-space terms relative to Root so tweening is never contested
    -- by any layout object (same architectural lesson as prior audits).
    self.Pill = Utilities.Create("Frame", {
        Name = "SelectionPill",
        BackgroundColor3 = Theme.Colors.PanelWhite,
        BackgroundTransparency = 0.8,
        Size = UDim2.new(1, -28, 0, Theme.Sizes.RowHeight),
        ZIndex = 1,
        Visible = false,
        Parent = self.Root,
    }, {
        Utilities.Corner(Theme.Corner.Control),
        Utilities.Stroke(Theme.Colors.Border, 0.75),
    })

    self.List = Utilities.Create("ScrollingFrame", {
        Name = "SidebarList",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Colors.TextSecondary,
        ScrollBarImageTransparency = 0.5,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 2,
        Parent = self.Root,
    }, {
        Utilities.ListLayout(Enum.FillDirection.Vertical, 4),
    })

    return self
end

-- config = { Id = string, Title = string, Icon = string (unicode/text placeholder) }
function Sidebar:AddItem(config)
    local id = config.Id or config.Title
    local order = #self.Items + 1

    local row = Utilities.Create("TextButton", {
        Name = id .. "Row",
        Size = UDim2.new(1, 0, 0, Theme.Sizes.RowHeight),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = order,
        ZIndex = 3,
        Parent = self.List,
    }, {
        Utilities.Padding(0, 14, 0, 14),
        Utilities.ListLayout(Enum.FillDirection.Horizontal, 10, Enum.SortOrder.LayoutOrder, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center),
    })

    Utilities.Create("TextLabel", {
        Size = UDim2.fromOffset(20, 20),
        BackgroundTransparency = 1,
        Text = config.Icon or "•",
        TextColor3 = Theme.Colors.TextPrimary,
        TextTransparency = 0.25,
        Font = Theme.Fonts.Body,
        TextSize = 15,
        LayoutOrder = 1,
        Parent = row,
    })

    local label = Utilities.Create("TextLabel", {
        Size = UDim2.new(1, -34, 1, 0),
        BackgroundTransparency = 1,
        Text = config.Title,
        TextColor3 = Theme.Colors.TextPrimary,
        TextTransparency = 0.25,
        Font = Theme.Fonts.Semibold,
        TextSize = Theme.TextSizes.Body,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 2,
        Parent = row,
    })

    row.MouseEnter:Connect(function()
        if self.ActiveId ~= id then
            TweenService:Create(row, Theme.Animation.Hover, {}):Play()
            TweenService:Create(label, Theme.Animation.Hover, { TextTransparency = 0.05 }):Play()
        end
    end)
    row.MouseLeave:Connect(function()
        if self.ActiveId ~= id then
            TweenService:Create(label, Theme.Animation.Hover, { TextTransparency = 0.25 }):Play()
        end
    end)

    row.MouseButton1Click:Connect(function()
        self:SetActive(id)
    end)

    self.Items[id] = { Row = row, Label = label, Order = order }

    if not self.ActiveId then
        self:SetActive(id, true)
    end

    return id
end

function Sidebar:_movePillTo(row, instant)
    self.Pill.Visible = true
    local info = instant and TweenInfo.new(0) or Theme.Animation.Spring
    TweenService:Create(self.Pill, info, {
        Position = UDim2.new(0, 14, 0, row.Position.Y.Offset + Theme.Spacing.M),
        Size = UDim2.new(1, -28, 0, row.Size.Y.Offset),
    }):Play()
end

function Sidebar:SetActive(id, instant)
    if not self.Items[id] then return end
    if self.ActiveId == id then return end

    if self.ActiveId and self.Items[self.ActiveId] then
        TweenService:Create(self.Items[self.ActiveId].Label, Theme.Animation.Hover, { TextTransparency = 0.25 }):Play()
    end

    self.ActiveId = id
    local item = self.Items[id]
    TweenService:Create(item.Label, Theme.Animation.Hover, { TextTransparency = 0 }):Play()
    self:_movePillTo(item.Row, instant)

    self.Changed:Fire(id)
end





-- ======================================================================
-- MODULE: Core/Tabs.lua
-- ======================================================================

--[[
    VisionUI Framework - Core/Tabs.lua
    =====================================
    Horizontal glass tab bar (used inside a Window's content area).
    - Sliding selection pill (same architecture as Sidebar.lua)
    - Fade + slide transition between pages
    - Lazy page creation: a tab's page Frame is only built the first
      time it's selected, then cached for subsequent switches.
]]

local TweenService = game:GetService("TweenService")


local Tabs = {}
Tabs.__index = Tabs

-- parentBody: Frame to host the tab bar + page container
function Tabs.new(parentBody)
    local self = setmetatable({}, Tabs)
    self.Items = {}       -- id -> { Button, Label, Page, Factory, Built }
    self.ActiveId = nil
    self.Changed = Signal.new()
    self._isAnimating = false

    -- ===== TAB BAR =====
    self.Bar = Utilities.Create("Frame", {
        Name = "TabBar",
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        Parent = parentBody,
    })

    self.Pill = Utilities.Create("Frame", {
        Name = "TabSelectionPill",
        BackgroundColor3 = Theme.Colors.PanelWhite,
        BackgroundTransparency = 0.8,
        Size = UDim2.fromOffset(0, 34),
        ZIndex = 1,
        Visible = false,
        Parent = self.Bar,
    }, {
        Utilities.Corner(Theme.Corner.Pill),
        Utilities.Stroke(Theme.Colors.Border, 0.75),
    })

    self.List = Utilities.Create("Frame", {
        Name = "TabList",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 2,
        Parent = self.Bar,
    }, {
        Utilities.ListLayout(Enum.FillDirection.Horizontal, 6, Enum.SortOrder.LayoutOrder, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center),
    })

    -- ===== PAGE CONTAINER =====
    self.PageContainer = Utilities.Create("Frame", {
        Name = "PageContainer",
        Size = UDim2.new(1, 0, 1, -52),
        Position = UDim2.new(0, 0, 0, 52),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = parentBody,
    })

    return self
end

-- config = { Id, Title, Icon, PageFactory = function(pageFrame) ... end }
-- PageFactory is called ONCE, lazily, the first time this tab is opened.
function Tabs:AddTab(config)
    local id = config.Id or config.Title
    local order = #self.Items + 1

    local btn = Utilities.Create("TextButton", {
        Name = id .. "Tab",
        Size = UDim2.fromOffset(0, 34),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = order,
        ZIndex = 3,
        Parent = self.List,
    }, {
        Utilities.Padding(0, 16, 0, 16),
    })

    local label = Utilities.Create("TextLabel", {
        Size = UDim2.fromOffset(0, 34),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = config.Title,
        TextColor3 = Theme.Colors.TextPrimary,
        TextTransparency = 0.35,
        Font = Theme.Fonts.Semibold,
        TextSize = Theme.TextSizes.Body,
        Parent = btn,
    })

    btn.MouseEnter:Connect(function()
        if self.ActiveId ~= id then
            TweenService:Create(label, Theme.Animation.Hover, { TextTransparency = 0.1 }):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if self.ActiveId ~= id then
            TweenService:Create(label, Theme.Animation.Hover, { TextTransparency = 0.35 }):Play()
        end
    end)
    btn.MouseButton1Click:Connect(function()
        self:SetActive(id)
    end)

    local page = Utilities.Create("ScrollingFrame", {
        Name = id .. "Page",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Colors.TextSecondary,
        ScrollBarImageTransparency = 0.5,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = self.PageContainer,
    }, {
        Utilities.Padding(4, 4, 24, 4),
        Utilities.ListLayout(Enum.FillDirection.Vertical, 18),
    })

    self.Items[id] = {
        Button = btn, Label = label, Page = page,
        Factory = config.PageFactory, Built = false, Order = order,
    }

    if not self.ActiveId then
        self:SetActive(id, true)
    end

    return page -- returned so caller can also add content immediately if desired
end

function Tabs:_movePillTo(btn, instant)
    self.Pill.Visible = true
    local info = instant and TweenInfo.new(0) or Theme.Animation.Spring
    TweenService:Create(self.Pill, info, {
        Position = UDim2.new(0, btn.Position.X.Offset, 0.5, -17),
        Size = UDim2.fromOffset(btn.AbsoluteSize.X > 0 and btn.AbsoluteSize.X or 60, 34),
    }):Play()
end

-- Fade + slide transition between the old and new page
function Tabs:SetActive(id, instant)
    local item = self.Items[id]
    if not item or self.ActiveId == id or self._isAnimating then return end

    -- Lazily build the page content on first visit
    if not item.Built then
        if item.Factory then
            local ok, err = pcall(item.Factory, item.Page)
            if not ok then
                warn("VisionUI Tabs: page factory error for '" .. id .. "': " .. tostring(err))
            end
        end
        item.Built = true
    end

    local previousId = self.ActiveId
    self.ActiveId = id

    if previousId and self.Items[previousId] then
        TweenService:Create(self.Items[previousId].Label, Theme.Animation.Hover, { TextTransparency = 0.35 }):Play()
    end
    TweenService:Create(item.Label, Theme.Animation.Hover, { TextTransparency = 0 }):Play()
    self:_movePillTo(item.Button, instant)

    if instant or not previousId then
        item.Page.Visible = true
        for otherId, otherItem in pairs(self.Items) do
            if otherId ~= id then otherItem.Page.Visible = false end
        end
        self.Changed:Fire(id)
        return
    end

    self._isAnimating = true
    local oldPage = self.Items[previousId] and self.Items[previousId].Page

    -- New page starts slightly offset + transparent, slides + fades in
    item.Page.Visible = true
    item.Page.Position = UDim2.fromOffset(16, 0)
    item.Page.GroupTransparency = nil -- ScrollingFrame has no GroupTransparency; fade via a cover instead

    -- Simple, robust approach: tween Position for slide, and fade the old
    -- page out by toggling visibility after a short delay (Frames don't
    -- support a single transparency property, so we drive the slide only
    -- and swap visibility at the animation midpoint).
    TweenService:Create(item.Page, Theme.Animation.TabSwitch, {
        Position = UDim2.fromOffset(0, 0),
    }):Play()

    if oldPage then
        TweenService:Create(oldPage, Theme.Animation.TabSwitch, {
            Position = UDim2.fromOffset(-16, 0),
        }):Play()
    end

    task.delay(Theme.Animation.TabSwitch.Time * 0.5, function()
        if oldPage then
            oldPage.Visible = false
            oldPage.Position = UDim2.fromOffset(0, 0)
        end
    end)

    task.delay(Theme.Animation.TabSwitch.Time, function()
        self._isAnimating = false
    end)

    self.Changed:Fire(id)
end

function Tabs:GetPage(id)
    local item = self.Items[id]
    return item and item.Page
end





-- ======================================================================
-- MODULE: Core/Notifications.lua
-- ======================================================================

--[[
    VisionUI Framework - Core/Notifications.lua
    ==============================================
    Floating glass toast notification system.
    - Types: Success, Warning, Error, Info, Custom
    - Queue with stacked positioning (newest at top, others slide down)
    - Auto-dismiss with visible progress bar
    - Slide + fade + spring open animation
    - Click to dismiss early
]]

local TweenService = game:GetService("TweenService")


local Notifications = {}
Notifications.__index = Notifications

local TYPE_STYLE = {
    Success = { Color = Theme.Colors.Success, Icon = "✓" },
    Warning = { Color = Theme.Colors.Warning, Icon = "!" },
    Error   = { Color = Theme.Colors.Danger,  Icon = "✕" },
    Info    = { Color = Theme.Colors.Accent,  Icon = "i" },
    Custom  = { Color = Theme.Colors.Accent,  Icon = "•" },
}

-- One notification layer per game session (module-level singleton state)
local overlay = nil
local activeToasts = {} -- ordered list, index 1 = topmost/newest

local WIDTH = 320
local SPACING = 10
local TOP_MARGIN = 24

local function getOverlay()
    if overlay and overlay.Parent then return overlay end
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local screenGui = playerGui:FindFirstChild("VisionUI_Notifications")
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "VisionUI_Notifications"
        screenGui.ResetOnSpawn = false
        screenGui.DisplayOrder = 1000
        screenGui.Parent = playerGui
    end
    overlay = screenGui
    return screenGui
end

-- Recompute the Y position of every active toast (stack layout)
local function restack()
    local y = TOP_MARGIN
    for _, toast in ipairs(activeToasts) do
        TweenService:Create(toast.Panel.Root, Theme.Animation.Smooth, {
            Position = UDim2.new(1, -WIDTH - 20, 0, y),
        }):Play()
        y += toast.Panel.Root.AbsoluteSize.Y + SPACING
    end
end

local function removeToast(toast)
    for i, t in ipairs(activeToasts) do
        if t == toast then
            table.remove(activeToasts, i)
            break
        end
    end

    if toast._progressConn then
        toast._progressConn:Disconnect()
    end

    local tween = TweenService:Create(toast.Panel.Root, Theme.Animation.Fast, {
        Position = toast.Panel.Root.Position + UDim2.fromOffset(40, 0),
    })
    local fadeGlass = TweenService:Create(toast.Panel.Glass, Theme.Animation.Fast, { BackgroundTransparency = 1 })
    tween:Play()
    fadeGlass:Play()
    tween.Completed:Connect(function()
        toast.Panel:Destroy()
        restack()
    end)
end

-- config = { Title, Content, Duration (seconds, default 5), Type = "Success"|"Warning"|"Error"|"Info"|"Custom" }
function Notifications.Notify(config)
    config = config or {}
    local style = TYPE_STYLE[config.Type] or TYPE_STYLE.Info
    local duration = config.Duration or 5

    local panel = GlassPanel.new({
        Size = UDim2.fromOffset(WIDTH, 0), -- height computed via AutomaticSize below
        Position = UDim2.new(1, -WIDTH - 20, 0, TOP_MARGIN),
        CornerRadius = Theme.Corner.Card,
        Parent = getOverlay(),
        AccentColor = style.Color,
        Elevation = 2,
    })
    panel.Root.Size = UDim2.fromOffset(WIDTH, 0)
    panel.Glass.AutomaticSize = Enum.AutomaticSize.Y
    panel.Root.AutomaticSize = Enum.AutomaticSize.Y

    -- entrance: start off-screen right + transparent
    panel.Root.Position = UDim2.new(1, 40, 0, TOP_MARGIN)
    panel.Glass.BackgroundTransparency = 1
    panel.Glow.BackgroundTransparency = 1

    Utilities.Padding(14, 14, 14, 14).Parent = panel.Content

    local row = Utilities.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = panel.Content,
    }, { Utilities.ListLayout(Enum.FillDirection.Horizontal, 10, Enum.SortOrder.LayoutOrder, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top) })

    -- icon badge
    Utilities.Create("Frame", {
        Size = UDim2.fromOffset(26, 26),
        BackgroundColor3 = style.Color,
        BackgroundTransparency = 0.6,
        LayoutOrder = 1,
        Parent = row,
    }, {
        Utilities.Corner(Theme.Corner.Pill),
        Utilities.Create("TextLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = style.Icon,
            TextColor3 = Theme.Colors.TextPrimary,
            Font = Theme.Fonts.Semibold,
            TextSize = 13,
        }),
    })

    local textBlock = Utilities.Create("Frame", {
        Size = UDim2.new(1, -60, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 2,
        Parent = row,
    }, { Utilities.ListLayout(Enum.FillDirection.Vertical, 2) })

    Utilities.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = config.Title or "Notification",
        TextColor3 = Theme.Colors.TextPrimary,
        Font = Theme.Fonts.Semibold,
        TextSize = Theme.TextSizes.Body,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
        Parent = textBlock,
    })

    Utilities.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = config.Content or "",
        TextColor3 = Theme.Colors.TextSecondary,
        Font = Theme.Fonts.Body,
        TextSize = Theme.TextSizes.Caption,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        LayoutOrder = 2,
        Parent = textBlock,
    })

    -- close (click anywhere on toast to dismiss)
    local clickCatcher = Utilities.Create("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 10,
        Parent = panel.Glass,
    })

    -- progress bar (auto-dismiss timer)
    local progressTrack = Utilities.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 3),
        Position = UDim2.new(0, 0, 1, -3),
        BackgroundColor3 = style.Color,
        BackgroundTransparency = 0.85,
        ZIndex = 6,
        Parent = panel.Glass,
    })
    local progressFill = Utilities.Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = style.Color,
        BackgroundTransparency = 0.2,
        ZIndex = 7,
        Parent = progressTrack,
    })

    local toast = { Panel = panel }
    table.insert(activeToasts, 1, toast)
    restack()

    -- entrance animation
    TweenService:Create(panel.Root, Theme.Animation.Spring, { Position = panel.Root.Position }):Play()
    task.defer(function() restack() end) -- correct final Y after AutomaticSize resolves
    TweenService:Create(panel.Glass, Theme.Animation.Smooth, { BackgroundTransparency = Theme.Glass.PanelTransparency }):Play()
    TweenService:Create(panel.Glow, Theme.Animation.Smooth, { BackgroundTransparency = 0.9 }):Play()

    if duration > 0 then
        TweenService:Create(progressFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
            Size = UDim2.new(0, 0, 1, 0),
        }):Play()
        task.delay(duration, function()
            removeToast(toast)
        end)
    end

    clickCatcher.MouseButton1Click:Connect(function()
        removeToast(toast)
    end)

    return toast
end





-- ======================================================================
-- MODULE: Core/Tooltip.lua
-- ======================================================================

--[[
    VisionUI Framework - Core/Tooltip.lua
    ========================================
    Floating glass tooltip that follows the mouse near a target element,
    with automatic screen-edge detection (flips side if it would overflow).
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")


local Tooltip = {}
Tooltip.__index = Tooltip

local overlay = nil
local function getOverlay()
    if overlay and overlay.Parent then return overlay end
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local screenGui = playerGui:FindFirstChild("VisionUI_Tooltip")
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "VisionUI_Tooltip"
        screenGui.ResetOnSpawn = false
        screenGui.DisplayOrder = 1001
        screenGui.Parent = playerGui
    end
    overlay = screenGui
    return screenGui
end

-- Attaches a tooltip to `target` that shows `text` on hover.
function Tooltip.Attach(target, text)
    local self = setmetatable({}, Tooltip)
    self._connections = {}
    self.Visible = false

    self.Frame = Utilities.Create("Frame", {
        Name = "Tooltip",
        BackgroundColor3 = Theme.Colors.GlassBackground,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        Visible = false,
        ZIndex = 2000,
        Parent = getOverlay(),
    }, {
        Utilities.Corner(Theme.Corner.Subtle),
        Utilities.Stroke(Theme.Colors.Border, 0.7),
        Utilities.Padding(6, 10, 6, 10),
    })

    self.Label = Utilities.Create("TextLabel", {
        Size = UDim2.fromOffset(0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.Colors.TextPrimary,
        Font = Theme.Fonts.Body,
        TextSize = Theme.TextSizes.Caption,
        ZIndex = 2001,
        Parent = self.Frame,
    })

    local function show()
        self.Visible = true
        self.Frame.Visible = true
        self.Frame.BackgroundTransparency = 1
        TweenService:Create(self.Frame, Theme.Animation.Fast, { BackgroundTransparency = 0.15 }):Play()
    end

    local function hide()
        self.Visible = false
        local tween = TweenService:Create(self.Frame, Theme.Animation.Fast, { BackgroundTransparency = 1 })
        tween:Play()
        tween.Completed:Connect(function()
            if not self.Visible then self.Frame.Visible = false end
        end)
    end

    local function reposition(mousePos)
        local screenSize = getOverlay().AbsoluteSize
        local tipSize = self.Frame.AbsoluteSize
        local padding = 14

        local x = mousePos.X + padding
        local y = mousePos.Y + padding

        -- Smart flip: if it would overflow right edge, place to the left instead
        if x + tipSize.X > screenSize.X then
            x = mousePos.X - tipSize.X - padding
        end
        -- Flip vertically if it would overflow bottom edge
        if y + tipSize.Y > screenSize.Y then
            y = mousePos.Y - tipSize.Y - padding
        end

        self.Frame.Position = UDim2.fromOffset(x, y)
    end

    table.insert(self._connections, target.MouseEnter:Connect(function()
        show()
    end))

    table.insert(self._connections, target.MouseLeave:Connect(function()
        hide()
    end))

    table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
        if self.Visible and input.UserInputType == Enum.UserInputType.MouseMovement then
            reposition(input.Position)
        end
    end))

    return self
end

function Tooltip:SetText(text)
    self.Label.Text = text
end

function Tooltip:Destroy()
    for _, conn in ipairs(self._connections) do
        conn:Disconnect()
    end
    self._connections = {}
    self.Frame:Destroy()
end





-- ======================================================================
-- MODULE: Core/ThemeManager.lua
-- ======================================================================

--[[
    VisionUI Framework - Core/ThemeManager.lua
    =============================================
    Runtime theme management on top of Theme.lua's static tables.
    Since Theme.lua is required by value across many modules (they read
    Theme.Colors.X once at construction time), ThemeManager provides:
      1. A registry of "live" instances that opted in to auto-updating
         (via ThemeManager.Track(instance, property, themeKeyPath)).
      2. SetTheme()/SetAccent() that mutate Theme.Colors in place and
         push updates to every tracked instance.
    This avoids rewriting Theme.lua's structure (per Phase 3 rules) while
    still delivering real runtime theme switching.
]]

local TweenService = game:GetService("TweenService")


local ThemeManager = {}
ThemeManager._tracked = {}     -- { {instance, property, colorKey}, ... }
ThemeManager._current = "Dark"

local PRESETS = {
    Dark = {
        GlassBackground = Color3.fromRGB(30, 28, 34),
        TextPrimary     = Color3.fromRGB(255, 255, 255),
        TextSecondary   = Color3.fromRGB(210, 210, 210),
    },
    Light = {
        GlassBackground = Color3.fromRGB(245, 245, 245),
        TextPrimary     = Color3.fromRGB(30, 30, 30),
        TextSecondary   = Color3.fromRGB(90, 90, 90),
    },
}

-- Register an instance+property to be updated whenever the theme changes.
-- colorKey should match a key under Theme.Colors, e.g. "TextPrimary".
function ThemeManager.Track(instance, property, colorKey)
    table.insert(ThemeManager._tracked, { instance = instance, property = property, colorKey = colorKey })
    -- apply immediately
    if Theme.Colors[colorKey] then
        instance[property] = Theme.Colors[colorKey]
    end
end

-- Removes all tracked entries referencing a destroyed instance (call this
-- from a component's :Destroy() to prevent updating dead instances).
function ThemeManager.Untrack(instance)
    for i = #ThemeManager._tracked, 1, -1 do
        if ThemeManager._tracked[i].instance == instance then
            table.remove(ThemeManager._tracked, i)
        end
    end
end

local function applyToTracked(animate)
    for _, entry in ipairs(ThemeManager._tracked) do
        if entry.instance and entry.instance.Parent then
            local color = Theme.Colors[entry.colorKey]
            if color then
                if animate then
                    TweenService:Create(entry.instance, Theme.Animation.Smooth, { [entry.property] = color }):Play()
                else
                    entry.instance[entry.property] = color
                end
            end
        else
            -- prune dead instances lazily
            ThemeManager.Untrack(entry.instance)
        end
    end
end

-- SetTheme("Dark" | "Light")
function ThemeManager.SetTheme(name)
    local preset = PRESETS[name]
    if not preset then
        warn("ThemeManager: unknown theme '" .. tostring(name) .. "'")
        return
    end
    ThemeManager._current = name
    for key, color in pairs(preset) do
        Theme.Colors[key] = color
    end
    applyToTracked(true)
end

-- SetAccent(Color3) - updates the accent color used across all components
function ThemeManager.SetAccent(color3)
    Theme.Colors.Accent = color3
    applyToTracked(true)
end

-- Auto: follow a boolean (e.g. time-of-day or Studio setting) - simple
-- convenience wrapper; caller decides when to invoke this.
function ThemeManager.SetAutomatic(isDark)
    ThemeManager.SetTheme(isDark and "Dark" or "Light")
end

function ThemeManager.GetCurrent()
    return ThemeManager._current
end





-- ======================================================================
-- MODULE: Components/Button.lua
-- ======================================================================

--[[
    VisionUI Framework - Components/Button.lua
    =============================================
    Glass button: hover lift, press-down, release spring-back.
--]]

local TweenService = game:GetService("TweenService")


local Button = {}
Button.__index = Button

-- config = { Title = string, Parent = Instance, Primary = bool }
function Button.new(parent, config)
    config = config or {}
    local self = setmetatable({}, Button)
    self.Clicked = Signal.new()

    local isPrimary = config.Primary or false

    self.Root = Utilities.Create("TextButton", {
        Name = "GlassButton",
        Size = config.Size or UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = isPrimary and Theme.Colors.Accent or Theme.Colors.PanelWhite,
        BackgroundTransparency = isPrimary and 0.55 or 0.85,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = config.Order or 0,
        Parent = parent,
    }, {
        Utilities.Corner(Theme.Corner.Control),
        Utilities.Stroke(Theme.Colors.Border, isPrimary and 0.6 or 0.8),
    })

    self.Label = Utilities.Create("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = config.Title or "Button",
        TextColor3 = Theme.Colors.TextPrimary,
        Font = Theme.Fonts.Semibold,
        TextSize = Theme.TextSizes.Body,
        Parent = self.Root,
    })

    -- ===== Hover lift =====
    self.Root.MouseEnter:Connect(function()
        TweenService:Create(self.Root, Theme.Animation.Hover, {
            Position = self.Root.Position - UDim2.fromOffset(0, 2),
            BackgroundTransparency = (isPrimary and 0.4 or 0.75),
        }):Play()
    end)

    self.Root.MouseLeave:Connect(function()
        TweenService:Create(self.Root, Theme.Animation.Hover, {
            Position = self.Root.Position + UDim2.fromOffset(0, 0),
            BackgroundTransparency = isPrimary and 0.55 or 0.85,
        }):Play()
    end)

    -- ===== Press down / release spring-back =====
    self.Root.MouseButton1Down:Connect(function()
        TweenService:Create(self.Root, Theme.Animation.Press, {
            Size = UDim2.new(self.Root.Size.X.Scale, self.Root.Size.X.Offset - 4, self.Root.Size.Y.Scale, self.Root.Size.Y.Offset - 2),
        }):Play()
    end)

    self.Root.MouseButton1Up:Connect(function()
        TweenService:Create(self.Root, Theme.Animation.Spring, {
            Size = config.Size or UDim2.new(1, 0, 0, 42),
        }):Play()
    end)

    self.Root.MouseButton1Click:Connect(function()
        self.Clicked:Fire()
        -- AUDIT FIX: accept both `OnClick` and `Callback`.
        if config.OnClick then
            config.OnClick()
        end
        if config.Callback then
            config.Callback()
        end
    end)

    return self
end

function Button:SetTitle(text)
    self.Label.Text = text
end

function Button:Destroy()
    self.Clicked:DisconnectAll()
    self.Root:Destroy()
end





-- ======================================================================
-- MODULE: Components/Toggle.lua
-- ======================================================================

--[[
    VisionUI Framework - Components/Toggle.lua
    =============================================
    VisionOS-style toggle: rounded glass track, smoothly sliding knob,
    accent fill when on. Reports state via OnChanged - no game logic.
--]]

local TweenService = game:GetService("TweenService")


local Toggle = {}
Toggle.__index = Toggle

-- config = { Title, Description, Default, OnChanged }
function Toggle.new(parent, config)
    config = config or {}
    local self = setmetatable({}, Toggle)
    self.State = config.Default or false
    self.Changed = Signal.new()

    self.Root = Utilities.Create("Frame", {
        Name = "ToggleRow",
        Size = UDim2.new(1, 0, 0, config.Description and 54 or 40),
        BackgroundTransparency = 1,
        LayoutOrder = #parent:GetChildren(),
        Parent = parent,
    })

    local textBlock = Utilities.Create("Frame", {
        Size = UDim2.new(1, -60, 1, 0),
        BackgroundTransparency = 1,
        Parent = self.Root,
    }, { Utilities.ListLayout(Enum.FillDirection.Vertical, 2, Enum.SortOrder.LayoutOrder, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center) })

    Utilities.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = config.Title or "Toggle",
        TextColor3 = Theme.Colors.TextPrimary,
        TextTransparency = 0.1,
        Font = Theme.Fonts.Semibold,
        TextSize = Theme.TextSizes.Body,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
        Parent = textBlock,
    })

    if config.Description then
        Utilities.Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Text = config.Description,
            TextColor3 = Theme.Colors.TextSecondary,
            Font = Theme.Fonts.Body,
            TextSize = Theme.TextSizes.Caption,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            LayoutOrder = 2,
            Parent = textBlock,
        })
    end

    -- ===== TRACK =====
    self.Track = Utilities.Create("TextButton", {
        Size = UDim2.fromOffset(48, 28),
        Position = UDim2.new(1, -48, 0.5, -14),
        BackgroundColor3 = Theme.Colors.PanelWhite,
        BackgroundTransparency = 0.8,
        Text = "",
        AutoButtonColor = false,
        Parent = self.Root,
    }, {
        Utilities.Corner(Theme.Corner.Pill),
        Utilities.Stroke(Theme.Colors.Border, 0.75),
    })

    -- ===== KNOB =====
    self.Knob = Utilities.Create("Frame", {
        Size = UDim2.fromOffset(22, 22),
        Position = UDim2.fromOffset(3, 3),
        BackgroundColor3 = Theme.Colors.PanelWhite,
        BackgroundTransparency = 0,
        Parent = self.Track,
    }, { Utilities.Corner(Theme.Corner.Pill) })

    self.Track.MouseButton1Click:Connect(function()
        self:Set(not self.State)
    end)

    if self.State then
        self:Set(true, true)
    end

    if config.OnChanged then
        self.Changed:Connect(config.OnChanged)
    end
    -- AUDIT FIX: also accept `Callback` as an alias for `OnChanged`.
    if config.Callback then
        self.Changed:Connect(config.Callback)
    end

    return self
end

function Toggle:Set(value, skipCallback)
    self.State = value

    if value then
        TweenService:Create(self.Track, Theme.Animation.Hover, {
            BackgroundColor3 = Theme.Colors.Accent,
            BackgroundTransparency = 0.35,
        }):Play()
        TweenService:Create(self.Knob, Theme.Animation.Spring, {
            Position = UDim2.fromOffset(23, 3),
        }):Play()
    else
        TweenService:Create(self.Track, Theme.Animation.Hover, {
            BackgroundColor3 = Theme.Colors.PanelWhite,
            BackgroundTransparency = 0.8,
        }):Play()
        TweenService:Create(self.Knob, Theme.Animation.Spring, {
            Position = UDim2.fromOffset(3, 3),
        }):Play()
    end

    if not skipCallback then
        self.Changed:Fire(value)
    end
end

function Toggle:Get()
    return self.State
end

function Toggle:OnChanged(fn)
    return self.Changed:Connect(fn)
end





-- ======================================================================
-- MODULE: Components/Slider.lua
-- ======================================================================

--[[
    VisionUI Framework - Components/Slider.lua
    =============================================
    VisionOS-style slider: glass track, accent fill, spring-animated
    thumb, live value label, decimal precision support.
--]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")


local Slider = {}
Slider.__index = Slider

-- config = { Title, Min, Max, Default, Decimals (default 0), Suffix, OnChanged }
function Slider.new(parent, config)
    config = config or {}
    local self = setmetatable({}, Slider)
    self.Min = config.Min or 0
    self.Max = config.Max or 100
    self.Decimals = config.Decimals or 0
    self.Suffix = config.Suffix or ""
    self.Value = config.Default or self.Min
    self.Changed = Signal.new()
    self._connections = {}

    self.Root = Utilities.Create("Frame", {
        Name = "SliderRow",
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundTransparency = 1,
        LayoutOrder = #parent:GetChildren(),
        Parent = parent,
    })

    self.TitleLabel = Utilities.Create("TextLabel", {
        Size = UDim2.new(0.6, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = config.Title or "Slider",
        TextColor3 = Theme.Colors.TextPrimary,
        TextTransparency = 0.1,
        Font = Theme.Fonts.Semibold,
        TextSize = Theme.TextSizes.Body,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Root,
    })

    self.ValueLabel = Utilities.Create("TextLabel", {
        Size = UDim2.new(0.4, 0, 0, 18),
        Position = UDim2.new(0.6, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = self:_formatValue(self.Value),
        TextColor3 = Theme.Colors.TextSecondary,
        Font = Theme.Fonts.Body,
        TextSize = Theme.TextSizes.Caption,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = self.Root,
    })

    -- ===== TRACK =====
    self.Track = Utilities.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, 30),
        BackgroundColor3 = Theme.Colors.PanelWhite,
        BackgroundTransparency = 0.85,
        Parent = self.Root,
    }, { Utilities.Corner(Theme.Corner.Pill) })

    local pct = (self.Value - self.Min) / (self.Max - self.Min)

    self.Fill = Utilities.Create("Frame", {
        Size = UDim2.new(pct, 0, 1, 0),
        BackgroundColor3 = Theme.Colors.Accent,
        BackgroundTransparency = 0.2,
        Parent = self.Track,
    }, { Utilities.Corner(Theme.Corner.Pill) })

    -- ===== THUMB (glass with spring motion) =====
    self.Thumb = Utilities.Create("Frame", {
        Size = UDim2.fromOffset(18, 18),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(pct, 0, 0.5, 0),
        BackgroundColor3 = Theme.Colors.PanelWhite,
        Parent = self.Track,
    }, {
        Utilities.Corner(Theme.Corner.Pill),
        Utilities.Stroke(Theme.Colors.Border, 0.6, 1.5),
    })

    self:_setupDragging()

    if config.OnChanged then
        self.Changed:Connect(config.OnChanged)
    end
    -- AUDIT FIX: also accept `Callback` as an alias for `OnChanged`.
    if config.Callback then
        self.Changed:Connect(config.Callback)
    end

    return self
end

function Slider:_formatValue(value)
    local formatted
    if self.Decimals > 0 then
        formatted = string.format("%." .. self.Decimals .. "f", value)
    else
        formatted = tostring(math.floor(value + 0.5))
    end
    return formatted .. self.Suffix
end

function Slider:_setupDragging()
    local dragging = false

    local function updateFromX(xPos, animateThumb)
        local relative = math.clamp((xPos - self.Track.AbsolutePosition.X) / self.Track.AbsoluteSize.X, 0, 1)
        local raw = self.Min + relative * (self.Max - self.Min)
        local rounded = self.Decimals > 0
            and (math.floor(raw * (10 ^ self.Decimals) + 0.5) / (10 ^ self.Decimals))
            or math.floor(raw + 0.5)
        self:Set(rounded, false, animateThumb)
    end

    table.insert(self._connections, self.Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromX(input.Position.X, false)
        end
    end))

    table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(input.Position.X, false) -- live dragging, no spring lag
        end
    end))

    table.insert(self._connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                -- small spring "settle" on release for the Apple feel
                TweenService:Create(self.Thumb, Theme.Animation.Spring, {
                    Size = UDim2.fromOffset(18, 18),
                }):Play()
            end
        end
    end))

    self.Thumb.MouseEnter:Connect(function()
        TweenService:Create(self.Thumb, Theme.Animation.Hover, { Size = UDim2.fromOffset(20, 20) }):Play()
    end)
    self.Thumb.MouseLeave:Connect(function()
        if not dragging then
            TweenService:Create(self.Thumb, Theme.Animation.Hover, { Size = UDim2.fromOffset(18, 18) }):Play()
        end
    end)
end

function Slider:Set(value, skipCallback, animate)
    value = math.clamp(value, self.Min, self.Max)
    self.Value = value
    local pct = (value - self.Min) / (self.Max - self.Min)

    local info = (animate == false) and TweenInfo.new(0.05) or Theme.Animation.Fast
    TweenService:Create(self.Fill, info, { Size = UDim2.new(pct, 0, 1, 0) }):Play()
    TweenService:Create(self.Thumb, info, { Position = UDim2.new(pct, 0, 0.5, 0) }):Play()
    self.ValueLabel.Text = self:_formatValue(value)

    if not skipCallback then
        self.Changed:Fire(value)
    end
end

function Slider:Get()
    return self.Value
end

function Slider:OnChanged(fn)
    return self.Changed:Connect(fn)
end

function Slider:Destroy()
    for _, conn in ipairs(self._connections) do
        conn:Disconnect()
    end
    self._connections = {}
    self.Root:Destroy()
end





-- ======================================================================
-- MODULE: Components/Dropdown.lua
-- ======================================================================

--[[
    VisionUI Framework - Components/Dropdown.lua
    ===============================================
    Floating glass popup menu.
    - Single-select or Multi-select
    - Optional search/filter box
    - Keyboard navigation (Up/Down/Enter/Escape)
    - Animated open/close (scale + fade)
    - Automatic sizing based on option count
    - Reparents its popup to a top-level overlay so it is never clipped
      by a parent ScrollingFrame (same fix applied in the Lumexa audit).
--]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")


local Dropdown = {}
Dropdown.__index = Dropdown

-- Shared overlay + mutual-exclusion registry (module-level, one listener total)
local overlayLayer = nil
local openDropdowns = {}
local globalListenerBound = false

local function getOverlay()
    if overlayLayer and overlayLayer.Parent then return overlayLayer end
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local screenGui = playerGui:FindFirstChild("VisionUI_Overlay")
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "VisionUI_Overlay"
        screenGui.ResetOnSpawn = false
        screenGui.DisplayOrder = 999
        screenGui.Parent = playerGui
    end
    overlayLayer = screenGui
    return screenGui
end

local function closeAllExcept(except)
    for dd in pairs(openDropdowns) do
        if dd ~= except then dd:Close() end
    end
end

local function pointInside(absPos, absSize, point)
    return point.X >= absPos.X and point.X <= absPos.X + absSize.X
       and point.Y >= absPos.Y and point.Y <= absPos.Y + absSize.Y
end

local function ensureGlobalListener()
    if globalListenerBound then return end
    globalListenerBound = true
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        for dd in pairs(openDropdowns) do
            local insideButton = pointInside(dd.Root.AbsolutePosition, dd.Root.AbsoluteSize, input.Position)
            local insideMenu = dd.Open and pointInside(dd.Menu.AbsolutePosition, dd.Menu.AbsoluteSize, input.Position)
            if not insideButton and not insideMenu then
                dd:Close()
            end
        end
    end)
end

-- config = { Title, Options = {string,...}, Default, Multi = bool, Searchable = bool, OnChanged }
function Dropdown.new(parent, config)
    config = config or {}
    local self = setmetatable({}, Dropdown)
    self.Options = config.Options or {}
    self.Multi = config.Multi or false
    self.Searchable = config.Searchable or false
    self.Open = false
    self.Changed = Signal.new()
    self._optionButtons = {}
    self._highlightIndex = 0

    if self.Multi then
        self.Selected = {} -- set of selected option strings
        if config.Default then
            for _, v in ipairs(config.Default) do self.Selected[v] = true end
        end
    else
        self.Selected = config.Default or self.Options[1] or ""
    end

    self.Root = Utilities.Create("Frame", {
        Name = "DropdownRow",
        Size = UDim2.new(1, 0, 0, config.Title and 60 or 40),
        BackgroundTransparency = 1,
        LayoutOrder = #parent:GetChildren(),
        Parent = parent,
    })

    if config.Title then
        Utilities.Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            Text = config.Title,
            TextColor3 = Theme.Colors.TextPrimary,
            TextTransparency = 0.1,
            Font = Theme.Fonts.Semibold,
            TextSize = Theme.TextSizes.Body,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self.Root,
        })
    end

    -- ===== SELECTOR (the clickable field) =====
    self.Selector = Utilities.Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 38),
        Position = UDim2.new(0, 0, 0, config.Title and 20 or 0),
        BackgroundColor3 = Theme.Colors.PanelWhite,
        BackgroundTransparency = 0.85,
        Text = "",
        AutoButtonColor = false,
        Parent = self.Root,
    }, {
        Utilities.Corner(Theme.Corner.Control),
        Utilities.Stroke(Theme.Colors.Border, 0.75),
        Utilities.Padding(0, 14, 0, 14),
    })

    self.SelectedLabel = Utilities.Create("TextLabel", {
        Size = UDim2.new(1, -20, 1, 0),
        BackgroundTransparency = 1,
        Text = self:_selectedText(),
        TextColor3 = Theme.Colors.TextPrimary,
        TextTransparency = 0.15,
        Font = Theme.Fonts.Body,
        TextSize = Theme.TextSizes.Body,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = self.Selector,
    })

    self.Chevron = Utilities.Create("TextLabel", {
        Size = UDim2.fromOffset(16, 38),
        Position = UDim2.new(1, -16, 0, 0),
        BackgroundTransparency = 1,
        Text = "⌄",
        TextColor3 = Theme.Colors.TextSecondary,
        Font = Theme.Fonts.Body,
        TextSize = 14,
        Parent = self.Selector,
    })

    self.Selector.MouseEnter:Connect(function()
        TweenService:Create(self.Selector, Theme.Animation.Hover, { BackgroundTransparency = 0.75 }):Play()
    end)
    self.Selector.MouseLeave:Connect(function()
        TweenService:Create(self.Selector, Theme.Animation.Hover, { BackgroundTransparency = 0.85 }):Play()
    end)
    self.Selector.MouseButton1Click:Connect(function()
        if self.Open then self:Close() else self:_openMenu() end
    end)

    -- ===== MENU (built lazily inside the shared overlay) =====
    self.Menu = Utilities.Create("Frame", {
        Name = "DropdownMenu",
        BackgroundColor3 = Theme.Colors.GlassBackground,
        BackgroundTransparency = 0.15,
        Visible = false,
        ZIndex = 1000,
        Parent = getOverlay(),
    }, {
        Utilities.Corner(Theme.Corner.Control),
        Utilities.Stroke(Theme.Colors.Border, 0.7),
    })

    self.MenuList = Utilities.Create("ScrollingFrame", {
        Size = UDim2.new(1, -8, 1, -8),
        Position = UDim2.fromOffset(4, 4),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Colors.TextSecondary,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 1001,
        Parent = self.Menu,
    }, {
        Utilities.ListLayout(Enum.FillDirection.Vertical, 2),
    })

    if self.Searchable then
        self.SearchBox = Utilities.Create("TextBox", {
            Size = UDim2.new(1, -8, 0, 30),
            Position = UDim2.fromOffset(4, 4),
            BackgroundColor3 = Theme.Colors.PanelWhite,
            BackgroundTransparency = 0.88,
            PlaceholderText = "Search...",
            PlaceholderColor3 = Theme.Colors.TextDisabled,
            Text = "",
            TextColor3 = Theme.Colors.TextPrimary,
            Font = Theme.Fonts.Body,
            TextSize = Theme.TextSizes.Body,
            ClearTextOnFocus = false,
            ZIndex = 1001,
            Parent = self.Menu,
        }, { Utilities.Corner(Theme.Corner.Subtle), Utilities.Padding(0, 8, 0, 8) })

        self.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
            self:_filterOptions(self.SearchBox.Text)
        end)

        self.MenuList.Position = UDim2.fromOffset(4, 38)
        self.MenuList.Size = UDim2.new(1, -8, 1, -42)
    end

    self:_buildOptions()
    ensureGlobalListener()

    if config.OnChanged then
        self.Changed:Connect(config.OnChanged)
    end
    -- AUDIT FIX: also accept `Callback` as an alias for `OnChanged`.
    if config.Callback then
        self.Changed:Connect(config.Callback)
    end

    return self
end

function Dropdown:_selectedText()
    if self.Multi then
        local names = {}
        for name in pairs(self.Selected) do table.insert(names, name) end
        if #names == 0 then return "None selected" end
        table.sort(names)
        return table.concat(names, ", ")
    else
        return tostring(self.Selected)
    end
end

function Dropdown:_isSelected(option)
    if self.Multi then
        return self.Selected[option] == true
    else
        return self.Selected == option
    end
end

function Dropdown:_buildOptions()
    for _, btn in ipairs(self._optionButtons) do btn:Destroy() end
    self._optionButtons = {}

    for i, option in ipairs(self.Options) do
        local optBtn = Utilities.Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = i,
            ZIndex = 1001,
            Parent = self.MenuList,
        }, { Utilities.Corner(Theme.Corner.Subtle) })

        Utilities.Create("TextLabel", {
            Size = UDim2.new(1, -16, 1, 0),
            Position = UDim2.fromOffset(12, 0),
            BackgroundTransparency = 1,
            Text = (self.Multi and self:_isSelected(option) and "✓ " or "") .. option,
            TextColor3 = self:_isSelected(option) and Theme.Colors.Accent or Theme.Colors.TextPrimary,
            Font = Theme.Fonts.Body,
            TextSize = Theme.TextSizes.Body,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 1002,
            Parent = optBtn,
        })

        optBtn.MouseEnter:Connect(function()
            TweenService:Create(optBtn, Theme.Animation.Fast, { BackgroundTransparency = 0.85 }):Play()
        end)
        optBtn.MouseLeave:Connect(function()
            TweenService:Create(optBtn, Theme.Animation.Fast, { BackgroundTransparency = 1 }):Play()
        end)
        optBtn.MouseButton1Click:Connect(function()
            self:Select(option)
        end)

        table.insert(self._optionButtons, optBtn)
    end
end

function Dropdown:_filterOptions(query)
    query = query:lower()
    for i, btn in ipairs(self._optionButtons) do
        local option = self.Options[i]
        btn.Visible = query == "" or option:lower():find(query, 1, true) ~= nil
    end
end

function Dropdown:_openMenu()
    closeAllExcept(self)
    self.Open = true
    openDropdowns[self] = true

    local absPos = self.Selector.AbsolutePosition
    local absSize = self.Selector.AbsoluteSize
    local menuHeight = math.clamp(#self.Options * 34 + (self.Searchable and 38 or 0) + 8, 40, 260)

    self.Menu.Position = UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 6)
    self.Menu.Size = UDim2.fromOffset(absSize.X, 0)
    self.Menu.Visible = true

    TweenService:Create(self.Menu, Theme.Animation.Smooth, {
        Size = UDim2.fromOffset(absSize.X, menuHeight),
    }):Play()

    TweenService:Create(self.Chevron, Theme.Animation.Hover, { Rotation = 180 }):Play()
end

function Dropdown:Close()
    if not self.Open then return end
    self.Open = false
    openDropdowns[self] = nil

    local tween = TweenService:Create(self.Menu, Theme.Animation.Fast, {
        Size = UDim2.fromOffset(self.Menu.Size.X.Offset, 0),
    })
    tween:Play()
    tween.Completed:Connect(function()
        if not self.Open then self.Menu.Visible = false end
    end)

    TweenService:Create(self.Chevron, Theme.Animation.Hover, { Rotation = 0 }):Play()
end

function Dropdown:Select(option, skipCallback)
    if self.Multi then
        self.Selected[option] = not self.Selected[option] or nil
        self:_buildOptions()
        if self.Searchable then self:_filterOptions(self.SearchBox.Text) end
    else
        self.Selected = option
        self:Close()
    end

    self.SelectedLabel.Text = self:_selectedText()

    if not skipCallback then
        self.Changed:Fire(self.Selected)
    end
end

function Dropdown:Get()
    return self.Selected
end

function Dropdown:SetOptions(newOptions)
    self.Options = newOptions
    self:_buildOptions()
end

function Dropdown:OnChanged(fn)
    return self.Changed:Connect(fn)
end

function Dropdown:Destroy()
    self:Close()
    openDropdowns[self] = nil
    self.Root:Destroy()
    self.Menu:Destroy()
end





-- ======================================================================
-- MODULE: Components/Textbox.lua
-- ======================================================================

--[[
    VisionUI Framework - Components/Textbox.lua
    ==============================================
    Glass textbox: focus glow animation, placeholder, character limit,
    numeric-only mode, password (masked) mode.
--]]

local TweenService = game:GetService("TweenService")


local Textbox = {}
Textbox.__index = Textbox

-- config = { Title, Placeholder, Default, CharLimit, Numeric, Password, OnChanged, OnFocusLost }
function Textbox.new(parent, config)
    config = config or {}
    local self = setmetatable({}, Textbox)
    self.CharLimit = config.CharLimit
    self.Numeric = config.Numeric or false
    self.Password = config.Password or false
    self.RealText = config.Default or ""
    self.Changed = Signal.new()
    self.FocusLost = Signal.new()

    self.Root = Utilities.Create("Frame", {
        Name = "TextboxRow",
        Size = UDim2.new(1, 0, 0, config.Title and 60 or 40),
        BackgroundTransparency = 1,
        LayoutOrder = #parent:GetChildren(),
        Parent = parent,
    })

    if config.Title then
        Utilities.Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            Text = config.Title,
            TextColor3 = Theme.Colors.TextPrimary,
            TextTransparency = 0.1,
            Font = Theme.Fonts.Semibold,
            TextSize = Theme.TextSizes.Body,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self.Root,
        })
    end

    self.Field = Utilities.Create("TextBox", {
        Size = UDim2.new(1, 0, 0, 38),
        Position = UDim2.new(0, 0, 0, config.Title and 20 or 0),
        BackgroundColor3 = Theme.Colors.PanelWhite,
        BackgroundTransparency = 0.85,
        PlaceholderText = config.Placeholder or "",
        PlaceholderColor3 = Theme.Colors.TextDisabled,
        Text = self.Password and string.rep("•", #self.RealText) or self.RealText,
        TextColor3 = Theme.Colors.TextPrimary,
        Font = Theme.Fonts.Body,
        TextSize = Theme.TextSizes.Body,
        ClearTextOnFocus = false,
        Parent = self.Root,
    }, {
        Utilities.Corner(Theme.Corner.Control),
        Utilities.Stroke(Theme.Colors.Border, 0.75, 1),
        Utilities.Padding(0, 14, 0, 14),
    })

    self._stroke = self.Field:FindFirstChildOfClass("UIStroke")

    -- ===== Focus glow animation =====
    self.Field.Focused:Connect(function()
        TweenService:Create(self.Field, Theme.Animation.Hover, { BackgroundTransparency = 0.75 }):Play()
        TweenService:Create(self._stroke, Theme.Animation.Hover, {
            Color = Theme.Colors.Accent,
            Transparency = 0.3,
        }):Play()
    end)

    self.Field.FocusLost:Connect(function(enterPressed)
        TweenService:Create(self.Field, Theme.Animation.Hover, { BackgroundTransparency = 0.85 }):Play()
        TweenService:Create(self._stroke, Theme.Animation.Hover, {
            Color = Theme.Colors.Border,
            Transparency = 0.75,
        }):Play()
        self.FocusLost:Fire(self.RealText, enterPressed)
    end)

    -- ===== Input filtering (numeric / char limit / password masking) =====
    self.Field:GetPropertyChangedSignal("Text"):Connect(function()
        local text = self.Field.Text

        if self.Password then
            -- Track real characters separately, display masked
            if #text > #self.RealText then
                local newChar = text:sub(-1)
                self.RealText = self.RealText .. newChar
            elseif #text < #self.RealText then
                self.RealText = self.RealText:sub(1, #text)
            end
        else
            self.RealText = text
        end

        if self.Numeric then
            self.RealText = self.RealText:gsub("[^%d%.%-]", "")
        end

        if self.CharLimit and #self.RealText > self.CharLimit then
            self.RealText = self.RealText:sub(1, self.CharLimit)
        end

        local displayText = self.Password and string.rep("•", #self.RealText) or self.RealText
        if self.Field.Text ~= displayText then
            self.Field.Text = displayText
        end

        self.Changed:Fire(self.RealText)
    end)

    if config.OnChanged then
        self.Changed:Connect(config.OnChanged)
    end
    -- AUDIT FIX: also accept `Callback` as an alias for `OnChanged`.
    if config.Callback then
        self.Changed:Connect(config.Callback)
    end
    if config.OnFocusLost then
        self.FocusLost:Connect(config.OnFocusLost)
    end

    return self
end

function Textbox:Get()
    return self.RealText
end

function Textbox:Set(text)
    self.RealText = text
    self.Field.Text = self.Password and string.rep("•", #text) or text
end

function Textbox:OnChanged(fn)
    return self.Changed:Connect(fn)
end

function Textbox:Destroy()
    self.Root:Destroy()
end





-- ======================================================================
-- MODULE: Components/Section.lua
-- ======================================================================

--[[
    VisionUI Framework - Components/Section.lua
    ==============================================
    Large section header with optional description, automatic spacing
    between child controls, and a smooth collapse/expand animation.
--]]

local TweenService = game:GetService("TweenService")


local Section = {}
Section.__index = Section

-- config = { Title, Description, Collapsible = bool, DefaultCollapsed = bool }
function Section.new(parent, config)
    config = config or {}
    local self = setmetatable({}, Section)
    self.Collapsed = config.DefaultCollapsed or false
    self.Collapsible = config.Collapsible or false
    self.Changed = Signal.new()

    self.Root = Utilities.Create("Frame", {
        Name = "Section",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = #parent:GetChildren(),
        Parent = parent,
    }, {
        Utilities.ListLayout(Enum.FillDirection.Vertical, Theme.Spacing.M),
    })

    -- ===== HEADER =====
    -- AUDIT FIX: skip building a header entirely when no Title is given,
    -- instead of always reserving space and showing a fallback "Section"
    -- label. This is needed for the headerless default section used by
    -- Tab:AddButton()/etc (added in the Library.lua audit fix) and is a
    -- no-op for every existing caller that already supplies a Title.
    self.Header = nil
    self.Chevron = nil

    if config.Title then
        self.Header = Utilities.Create(self.Collapsible and "TextButton" or "Frame", {
            Name = "SectionHeader",
            Size = UDim2.new(1, 0, 0, config.Description and 40 or 24),
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = self.Collapsible and "" or nil,
            LayoutOrder = 1,
            Parent = self.Root,
        })

        local headerText = Utilities.Create("Frame", {
            Size = UDim2.new(1, -24, 1, 0),
            BackgroundTransparency = 1,
            Parent = self.Header,
        }, { Utilities.ListLayout(Enum.FillDirection.Vertical, 2) })

        Utilities.Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundTransparency = 1,
            Text = config.Title,
            TextColor3 = Theme.Colors.TextPrimary,
            Font = Theme.Fonts.Title,
            TextSize = Theme.TextSizes.Subtitle,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 1,
            Parent = headerText,
        })

        if config.Description then
            Utilities.Create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 16),
                BackgroundTransparency = 1,
                Text = config.Description,
                TextColor3 = Theme.Colors.TextSecondary,
                Font = Theme.Fonts.Body,
                TextSize = Theme.TextSizes.Caption,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = 2,
                Parent = headerText,
            })
        end
    end

    if self.Header and self.Collapsible then
        self.Chevron = Utilities.Create("TextLabel", {
            Size = UDim2.fromOffset(20, 20),
            Position = UDim2.new(1, -20, 0.5, -10),
            BackgroundTransparency = 1,
            Text = "⌄",
            TextColor3 = Theme.Colors.TextSecondary,
            Font = Theme.Fonts.Body,
            TextSize = 16,
            Rotation = self.Collapsed and -90 or 0,
            Parent = self.Header,
        })
        self.Header.MouseButton1Click:Connect(function()
            self:SetCollapsed(not self.Collapsed)
        end)
    end

    -- ===== BODY (holds child controls; caller parents things here) =====
    self.Body = Utilities.Create("Frame", {
        Name = "SectionBody",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Visible = not self.Collapsed,
        LayoutOrder = 2,
        Parent = self.Root,
    }, {
        Utilities.ListLayout(Enum.FillDirection.Vertical, Theme.Spacing.S),
    })

    self.Content = self.Body -- alias to match Card.Content convention used elsewhere

    return self
end

function Section:SetCollapsed(collapsed)
    if not self.Collapsible then return end
    self.Collapsed = collapsed

    if self.Chevron then
        TweenService:Create(self.Chevron, Theme.Animation.Smooth, {
            Rotation = collapsed and -90 or 0,
        }):Play()
    end

    if collapsed then
        -- Animate height to 0, then hide once fully collapsed
        local targetHeight = self.Body.AbsoluteSize.Y
        self.Body.Size = UDim2.new(1, 0, 0, targetHeight)
        self.Body.AutomaticSize = Enum.AutomaticSize.None
        local tween = TweenService:Create(self.Body, Theme.Animation.Smooth, { Size = UDim2.new(1, 0, 0, 0) })
        tween:Play()
        tween.Completed:Connect(function()
            self.Body.Visible = false
        end)
    else
        self.Body.Visible = true
        self.Body.AutomaticSize = Enum.AutomaticSize.Y
    end

    self.Changed:Fire(collapsed)
end





-- ======================================================================
-- MODULE: Components/Label.lua
-- ======================================================================

--[[
    VisionUI Framework - Components/Label.lua
    ============================================
    Simple single-line text label matching the VisionOS type scale.
--]]


local Label = {}
Label.__index = Label

-- config = { Text, Size ("Body"|"Caption"|"Title"|"Subtitle"), Color }
function Label.new(parent, config)
    config = config or {}
    local self = setmetatable({}, Label)

    local sizeKey = config.Size or "Body"
    local fontKey = (sizeKey == "Title") and "Title" or "Body"

    self.Root = Utilities.Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = config.Text or "",
        TextColor3 = config.Color or Theme.Colors.TextPrimary,
        Font = Theme.Fonts[fontKey] or Theme.Fonts.Body,
        TextSize = Theme.TextSizes[sizeKey] or Theme.TextSizes.Body,
        TextXAlignment = config.Align or Enum.TextXAlignment.Left,
        TextTransparency = config.Transparency or 0.1,
        LayoutOrder = #parent:GetChildren(),
        Parent = parent,
    })

    return self
end

function Label:SetText(text)
    self.Root.Text = text
end

function Label:Destroy()
    self.Root:Destroy()
end





-- ======================================================================
-- MODULE: Components/Paragraph.lua
-- ======================================================================

--[[
    VisionUI Framework - Components/Paragraph.lua
    ================================================
    Multi-line wrapped text block with a bold title above it.
--]]


local Paragraph = {}
Paragraph.__index = Paragraph

-- config = { Title, Content }
function Paragraph.new(parent, config)
    config = config or {}
    local self = setmetatable({}, Paragraph)

    self.Root = Utilities.Create("Frame", {
        Name = "Paragraph",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = #parent:GetChildren(),
        Parent = parent,
    }, {
        Utilities.ListLayout(Enum.FillDirection.Vertical, 4),
    })

    if config.Title then
        Utilities.Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            Text = config.Title,
            TextColor3 = Theme.Colors.TextPrimary,
            Font = Theme.Fonts.Semibold,
            TextSize = Theme.TextSizes.Body,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 1,
            Parent = self.Root,
        })
    end

    self.ContentLabel = Utilities.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = config.Content or "",
        TextColor3 = Theme.Colors.TextSecondary,
        Font = Theme.Fonts.Body,
        TextSize = Theme.TextSizes.Caption,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        LayoutOrder = 2,
        Parent = self.Root,
    })

    return self
end

function Paragraph:SetContent(text)
    self.ContentLabel.Text = text
end

function Paragraph:Destroy()
    self.Root:Destroy()
end





-- ======================================================================
-- MODULE: Components/Separator.lua
-- ======================================================================

--[[
    VisionUI Framework - Components/Separator.lua
    ================================================
    Thin translucent divider line, VisionOS glass-edge style.
--]]


local Separator = {}
Separator.__index = Separator

function Separator.new(parent)
    local self = setmetatable({}, Separator)

    self.Root = Utilities.Create("Frame", {
        Name = "Separator",
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Colors.Border,
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        LayoutOrder = #parent:GetChildren(),
        Parent = parent,
    })

    return self
end

function Separator:Destroy()
    self.Root:Destroy()
end





-- ======================================================================
-- MODULE: Library.lua
-- ======================================================================

--[[
    VisionUI Framework - Library.lua
    ===================================
    The top-level public API. This is the file you `require()`.

    Usage:
        local Window = Library:CreateWindow({ Title = "My App" })
        local Tab = Window:AddTab({ Title = "Home" })
        local Section = Tab:AddSection({ Title = "General" })
        Section:AddButton({ Title = "Click me", OnClick = function() end })
        Section:AddToggle({ Title = "Enabled", OnChanged = function(v) end })
        Library:Notify({ Title = "Saved", Content = "Done!", Type = "Success" })
]]



local Library = {}
Library._windows = {}
Library._screenGui = nil

-- ========== INTERNAL: shared ScreenGui for all windows ==========
local function getRootGui()
    if Library._screenGui and Library._screenGui.Parent then
        return Library._screenGui
    end
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "VisionUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    Library._screenGui = screenGui
    return screenGui
end

--[[
    ============================================================
    SECTION WRAPPER
    Wraps Components/Section.lua and adds every Add* control method,
    parenting each new control into the Section's Body.
    ============================================================
]]
local SectionWrapper = {}
SectionWrapper.__index = SectionWrapper

local function wrapSection(sectionInstance)
    return setmetatable({ _core = sectionInstance }, SectionWrapper)
end

-- Adds a button. config = { Title, OnClick }
-- Returns the Button component (has :SetTitle, :Destroy, .Clicked signal).
function SectionWrapper:AddButton(config)
    return Button.new(self._core.Body, config)
end

-- Adds a toggle. config = { Title, Description, Default, OnChanged }
-- Returns the Toggle component (has :Set, :Get, :OnChanged).
function SectionWrapper:AddToggle(config)
    return Toggle.new(self._core.Body, config)
end

-- Adds a slider. config = { Title, Min, Max, Default, Decimals, Suffix, OnChanged }
-- Returns the Slider component (has :Set, :Get, :OnChanged, :Destroy).
function SectionWrapper:AddSlider(config)
    return Slider.new(self._core.Body, config)
end

-- Adds a dropdown. config = { Title, Options, Default, Multi, Searchable, OnChanged }
-- Returns the Dropdown component (has :Select, :Get, :SetOptions, :OnChanged, :Destroy).
function SectionWrapper:AddDropdown(config)
    return Dropdown.new(self._core.Body, config)
end

-- Adds a textbox. config = { Title, Placeholder, Default, CharLimit, Numeric, Password, OnChanged, OnFocusLost }
-- Returns the Textbox component (has :Set, :Get, :OnChanged, :Destroy).
function SectionWrapper:AddTextbox(config)
    return Textbox.new(self._core.Body, config)
end

-- Adds a paragraph. config = { Title, Content }
-- Returns the Paragraph component (has :SetContent, :Destroy).
function SectionWrapper:AddParagraph(config)
    return Paragraph.new(self._core.Body, config)
end

-- Adds a plain label. config = { Text, Size, Color, Align }
-- Returns the Label component (has :SetText, :Destroy).
function SectionWrapper:AddLabel(config)
    return Label.new(self._core.Body, config)
end

-- Adds a thin divider line. No config needed.
function SectionWrapper:AddSeparator()
    return Separator.new(self._core.Body)
end

-- Collapses/expands this section (only works if it was created with Collapsible = true)
function SectionWrapper:SetCollapsed(collapsed)
    self._core:SetCollapsed(collapsed)
end

--[[
    ============================================================
    TAB WRAPPER
    Wraps a Tabs.lua page (a ScrollingFrame) and exposes :AddSection().
    ============================================================
]]
local TabWrapper = {}
TabWrapper.__index = TabWrapper

local function wrapTab(pageFrame)
    return setmetatable({ _page = pageFrame }, TabWrapper)
end

-- Adds a section to this tab. config = { Title, Description, Collapsible, DefaultCollapsed }
-- Returns a SectionWrapper - call :AddButton/:AddToggle/etc on it.
function TabWrapper:AddSection(config)
    local sectionCore = Section.new(self._page, config)
    return wrapSection(sectionCore)
end

-- ============================================================
-- AUDIT FIX: direct Tab:AddButton()/:AddToggle()/etc convenience API.
-- Lazily creates ONE headerless default section per tab on first use,
-- then forwards to it. Tab:AddSection() above is unchanged.
-- ============================================================
function TabWrapper:_getDefaultSection()
    if not self._defaultSection then
        local sectionCore = Section.new(self._page, { Title = nil })
        self._defaultSection = wrapSection(sectionCore)
    end
    return self._defaultSection
end

-- Adds a button directly to this tab. config = { Title, Callback (or OnClick) }
function TabWrapper:AddButton(config)
    return self:_getDefaultSection():AddButton(config)
end

-- Adds a toggle directly to this tab. config = { Title, Description, Default, OnChanged (or Callback) }
function TabWrapper:AddToggle(config)
    return self:_getDefaultSection():AddToggle(config)
end

-- Adds a slider directly to this tab. config = { Title, Min, Max, Default, Decimals, Suffix, OnChanged (or Callback) }
function TabWrapper:AddSlider(config)
    return self:_getDefaultSection():AddSlider(config)
end

-- Adds a dropdown directly to this tab. config = { Title, Options, Default, Multi, Searchable, OnChanged (or Callback) }
function TabWrapper:AddDropdown(config)
    return self:_getDefaultSection():AddDropdown(config)
end

-- Adds a textbox directly to this tab. config = { Title, Placeholder, Default, CharLimit, Numeric, Password, OnChanged (or Callback), OnFocusLost }
function TabWrapper:AddTextbox(config)
    return self:_getDefaultSection():AddTextbox(config)
end

-- Adds a paragraph directly to this tab. config = { Title, Content }
function TabWrapper:AddParagraph(config)
    return self:_getDefaultSection():AddParagraph(config)
end

-- Adds a plain label directly to this tab. config = { Text, Size, Color, Align }
function TabWrapper:AddLabel(config)
    return self:_getDefaultSection():AddLabel(config)
end

-- Adds a thin divider line directly to this tab. No config needed.
function TabWrapper:AddSeparator()
    return self:_getDefaultSection():AddSeparator()
end

--[[
    ============================================================
    WINDOW WRAPPER
    Wraps Core/Window.lua + Core/Tabs.lua and exposes :AddTab().
    ============================================================
]]
local WindowWrapper = {}
WindowWrapper.__index = WindowWrapper

-- config = { Title, Subtitle, Size }
function Library:CreateWindow(config)
    config = config or {}
    local gui = getRootGui()

    local coreWindow = Window.new(gui, config)
    local tabs = Tabs.new(coreWindow.Body)

    local self = setmetatable({
        _core = coreWindow,
        _tabs = tabs,
    }, WindowWrapper)

    table.insert(Library._windows, self)
    return self
end

-- Adds a tab. config = { Title, Icon, PageFactory (optional) }
-- Returns a TabWrapper - call :AddSection() on it, then Add* on that.
-- NOTE: unlike the raw Tabs.lua API, PageFactory is optional here since
-- most callers build content immediately using the returned TabWrapper.
function WindowWrapper:AddTab(config)
    config = config or {}
    local built = false
    local wrapper -- forward declare so the factory closure can capture it

    local pageFrame = self._tabs:AddTab({
        Id = config.Id,
        Title = config.Title,
        Icon = config.Icon,
        PageFactory = function(page)
            -- If the caller supplied their own PageFactory, defer to it.
            if config.PageFactory then
                config.PageFactory(page)
            end
            built = true
        end,
    })

    wrapper = wrapTab(pageFrame)
    return wrapper
end

function WindowWrapper:BringToFront()
    self._core:BringToFront()
end

function WindowWrapper:Hide()
    self._core:Hide()
end

function WindowWrapper:Show()
    self._core:Show()
end

function WindowWrapper:Destroy()
    self._core:Destroy()
    for i, w in ipairs(Library._windows) do
        if w == self then table.remove(Library._windows, i) break end
    end
end

--[[
    ============================================================
    LIBRARY-LEVEL API
    ============================================================
]]

-- Shows a floating glass toast notification.
-- config = { Title, Content, Duration (seconds), Type = "Success"|"Warning"|"Error"|"Info"|"Custom" }
function Library:Notify(config)
    return Notifications.Notify(config)
end

-- Switches the active theme at runtime. name = "Dark" | "Light"
-- Only instances registered via ThemeManager.Track (or built after this
-- call) reflect the new colors; see ThemeManager.lua for details.
function Library:SetTheme(name)
    ThemeManager.SetTheme(name)
end

-- Sets the accent color used across all components at runtime.
function Library:SetAccent(color3)
    ThemeManager.SetAccent(color3)
end

-- Attaches a floating tooltip with `text` to any GuiObject.
function Library:AddTooltip(target, text)
    return Tooltip.Attach(target, text)
end

-- Destroys every window and the root ScreenGui. Call this to fully
-- tear down the UI (e.g. on script cleanup).
function Library:DestroyAll()
    for _, w in ipairs(Library._windows) do
        w:Destroy()
    end
    Library._windows = {}
    if Library._screenGui then
        Library._screenGui:Destroy()
        Library._screenGui = nil
    end
end

return Library


