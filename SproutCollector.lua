local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local SCAN_INTERVAL = 1
local HOVER_AT_TARGET = 0.3
local AUTO_CLEAR = true
local SPEED_MIN = 20
local SPEED_MAX = 800
local FlySpeed = 60
local SETTINGS_PANEL_HEIGHT = 76
local MAIN_BASE_HEIGHT = 340
local settingsOpen = false
local SETTINGS_TWEEN_INFO = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local MINIMIZE_TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FallbackItems = {
    ["Basic Egg"] = "1471846464", ["Silver Egg"] = "1471848094", ["Gold Egg"] = "1471849394",
    ["Royal Jelly"] = "1471882621", ["Mythic Egg"] = "4520739302", ["Diamond Egg"] = "1471850677",
    ["Gifted Diamond"] = "1987257040", ["Gifted Gold"] = "1987255318", ["Star Egg"] = "2007771339",
    ["Gifted Mythic"] = "6134473023", ["Gifted Silver"] = "1987253833", ["Treat"] = "1442700001",
    ["Sunflower Seed"] = "1952682401", ["Strawberry"] = "1952740625", ["Star Treat"] = "2028603146",
    ["Pineapple"] = "1952796032", ["Blueberry"] = "2028453802", ["Stinger"] = "2314214749",
    ["Star Jelly"] = "2319943273", ["Red Extract"] = "2495935291", ["Blue Extract"] = "2495936060",
    ["Oil"] = "2545746569", ["Magic Bean"] = "2529092020", ["Glue"] = "2504978518",
    ["Enzymes"] = "2584584968", ["Glitter"] = "2542899798", ["Coconut"] = "3012679515",
    ["Marshmallow Bee"] = "3027672238", ["Cloud Vial"] = "3030569073", ["Jelly Beans"] = "3080740120",
    ["Bitterberry"] = "4483236276", ["Atomic Treat"] = "4520736128", ["Neonberry"] = "4483267595",
    ["Purple Potion"] = "4935580111", ["Super Smoothie"] = "5144657109", ["SwirledWax"] = "8277783113",
    ["Soft Wax"] = "8277778300", ["Hard Wax"] = "8277780065", ["Debug Wax"] = "106257173347427",
    ["Caustic Wax"] = "8277781666", ["Snowflake"] = "6087969886", ["Turpentine"] = "8310376128",
    ["Pink Balloon"] = "8058046728", ["Red Balloon"] = "8058047989", ["White Balloon"] = "8058049243",
    ["Black Balloon"] = "8058051899", ["Robo Pass"] = "3036899811", ["Moon Charm"] = "2306224708",
    ["Present"] = "2659216738", ["Night Bell"] = "2676671613", ["Festive Bean"] = "2676715441",
    ["Micro-Converter"] = "2863122826", ["Smooth Dice"] = "8054996680", ["Ant Pass"] = "2060626811",
    ["Box-O-Frogs"] = "4528640710", ["Field Dice"] = "2863468407", ["Loaded Dice"] = "8055428094",
    ["Honey Bee Present"] = "2659216738", ["Comforting Vial"] = "11715984593", ["Invigorating Vial"] = "11715985633",
    ["Satisfying Vial"] = "11715986643", ["Motivating Vial"] = "11715987736", ["Refreshing Vial"] = "11715988800",
    ["Nectar Shower Vial"] = "131089799487446", ["White Drive"] = "11782092199", ["Red Drive"] = "11782094454",
    ["Blue Drive"] = "11782096305", ["Glitched Drive"] = "11782097887", ["Broken Drive"] = "13369738621"
}
local oldGui = PlayerGui:FindFirstChild("SproutCollectorGUI")
if oldGui then
    oldGui:Destroy()
end
local SAVE_FOLDER = "SproutCollector"
local SAVE_FILE = SAVE_FOLDER .. "/config.json"
local saveConfig
local loadedData
local refreshFieldsList
local purgeCollectibles
local refreshSpeedUI
local refreshItemsList
local ItemDatabase = {}
local IDToName = {}
local SortedItemNames = {}
for name, id in pairs(FallbackItems) do
    ItemDatabase[name] = id
    IDToName[id] = name
    table.insert(SortedItemNames, name)
end
table.sort(SortedItemNames)
local function isFinite(val)
    return val == val and val ~= math.huge and val ~= -math.huge
end
purgeCollectibles = function()
    local folder = Workspace:FindFirstChild("Collectibles")
    if not folder then return 0 end
    local count = 0
    for _, child in ipairs(folder:GetChildren()) do
        pcall(function() child:Destroy() end)
        count = count + 1
    end
    return count
end
if AUTO_CLEAR then
    task.spawn(function()
        local folder = Workspace:WaitForChild("Collectibles", 10)
        if folder then
            purgeCollectibles()
        end
    end)
end
local function create(class, properties, parent)
    local instance = Instance.new(class)
    for property, value in pairs(properties) do
        instance[property] = value
    end
    instance.Parent = parent
    return instance
end
local function round(object, radius)
    create("UICorner", { CornerRadius = UDim.new(0, radius) }, object)
end
local function stroke(object, color, transparency)
    create("UIStroke", { Color = color, Transparency = transparency or 0, Thickness = 1 }, object)
end
local ScreenGui = create("ScreenGui", {
    Name = "SproutCollectorGUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true
}, PlayerGui)
local Main = create("Frame", {
    Size = UDim2.fromOffset(280, MAIN_BASE_HEIGHT),
    Position = UDim2.new(0.5, -140, 0.5, -170),
    BackgroundColor3 = Color3.fromRGB(20, 23, 31),
    BorderSizePixel = 0,
    ClipsDescendants = true
}, ScreenGui)
round(Main, 10)
stroke(Main, Color3.fromRGB(65, 75, 95))
local Header = create("Frame", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = Color3.fromRGB(28, 33, 44),
    BorderSizePixel = 0
}, Main)
round(Header, 10)
create("Frame", {
    Size = UDim2.new(1, 0, 0, 10),
    Position = UDim2.new(0, 0, 1, -10),
    BackgroundColor3 = Header.BackgroundColor3,
    BorderSizePixel = 0
}, Header)
create("TextLabel", {
    Size = UDim2.new(1, -110, 1, 0),
    Position = UDim2.fromOffset(12, 0),
    BackgroundTransparency = 1,
    Text = "SPROUT COLLECTOR",
    TextColor3 = Color3.fromRGB(235, 240, 250),
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, Header)
local TriangleBtn = create("TextButton", {
    Size = UDim2.fromOffset(28, 28),
    Position = UDim2.new(1, -60, 0, 20),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    Text = "▼",
    TextColor3 = Color3.fromRGB(200, 210, 225),
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    Rotation = 90,
    ZIndex = 5
}, Header)
local Minimize = create("TextButton", {
    Size = UDim2.fromOffset(24, 24),
    Position = UDim2.new(1, -32, 0, 8),
    BackgroundColor3 = Color3.fromRGB(48, 57, 73),
    Text = "−",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 16,
    Font = Enum.Font.GothamBold
}, Header)
round(Minimize, 6)
local SettingsPanel = create("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    Position = UDim2.fromOffset(0, 40),
    BackgroundColor3 = Color3.fromRGB(24, 28, 37),
    BorderSizePixel = 0,
    ClipsDescendants = true
}, Main)
local Status = create("TextButton", {
    Size = UDim2.new(1, -16, 0, 30),
    Position = UDim2.fromOffset(8, 8),
    BackgroundColor3 = Color3.fromRGB(150, 45, 50),
    Text = "OFF",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 13,
    Font = Enum.Font.GothamBold
}, SettingsPanel)
round(Status, 7)
local SpeedControl = create("Frame", {
    Size = UDim2.new(1, -16, 0, 22),
    Position = UDim2.fromOffset(8, 46),
    BackgroundTransparency = 1
}, SettingsPanel)
local SpeedLabel = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 10),
    BackgroundTransparency = 1,
    Text = "Global speed: " .. FlySpeed .. " studs/s",
    TextColor3 = Color3.fromRGB(160, 175, 200),
    TextSize = 9,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left
}, SpeedControl)
local SpeedBar = create("Frame", {
    Size = UDim2.new(1, 0, 0, 8),
    Position = UDim2.fromOffset(0, 12),
    BackgroundColor3 = Color3.fromRGB(40, 48, 62),
    BorderSizePixel = 0
}, SpeedControl)
round(SpeedBar, 4)
local SpeedFill = create("Frame", {
    Size = UDim2.new((FlySpeed - SPEED_MIN) / (SPEED_MAX - SPEED_MIN), 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(65, 115, 210),
    BorderSizePixel = 0
}, SpeedBar)
round(SpeedFill, 4)
local SpeedHandle = create("Frame", {
    Size = UDim2.fromOffset(10, 14),
    Position = UDim2.new((FlySpeed - SPEED_MIN) / (SPEED_MAX - SPEED_MIN), -5, 0.5, -7),
    BackgroundColor3 = Color3.fromRGB(240, 240, 245),
    BorderSizePixel = 0,
    ZIndex = 2
}, SpeedBar)
round(SpeedHandle, 5)
local SpeedButton = create("TextButton", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "",
    ZIndex = 3
}, SpeedBar)
local TabBar = create("Frame", {
    Size = UDim2.new(1, 0, 0, 28),
    Position = UDim2.fromOffset(0, 40),
    BackgroundColor3 = Color3.fromRGB(24, 28, 37),
    BorderSizePixel = 0
}, Main)
local IDsTab = create("TextButton", {
    Size = UDim2.new(0.5, -3, 1, -6),
    Position = UDim2.fromOffset(3, 3),
    BackgroundColor3 = Color3.fromRGB(65, 115, 210),
    Text = "ITEMS",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 11,
    Font = Enum.Font.GothamBold
}, TabBar)
round(IDsTab, 5)
local FieldsTab = create("TextButton", {
    Size = UDim2.new(0.5, -3, 1, -6),
    Position = UDim2.new(0.5, 0, 0, 3),
    BackgroundColor3 = Color3.fromRGB(42, 50, 65),
    Text = "FIELDS",
    TextColor3 = Color3.fromRGB(200, 210, 225),
    TextSize = 11,
    Font = Enum.Font.GothamBold
}, TabBar)
round(FieldsTab, 5)
local Content = create("Frame", {
    Size = UDim2.new(1, -16, 0, 260),
    Position = UDim2.fromOffset(8, 72),
    BackgroundTransparency = 1
}, Main)
local IDPage = create("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    Position = UDim2.fromOffset(0, 0),
    BackgroundTransparency = 1,
    Visible = true
}, Content)
local SearchBar = create("TextBox", {
    Size = UDim2.new(1, -65, 0, 28),
    BackgroundColor3 = Color3.fromRGB(32, 38, 50),
    TextColor3 = Color3.fromRGB(240, 240, 240),
    PlaceholderColor3 = Color3.fromRGB(125, 135, 155),
    PlaceholderText = "Search...",
    Text = "",
    TextSize = 11,
    Font = Enum.Font.Gotham,
    ClearTextOnFocus = false
}, IDPage)
round(SearchBar, 6)
stroke(SearchBar, Color3.fromRGB(55, 65, 82))
local ClearBtn = create("TextButton", {
    Size = UDim2.new(0, 60, 0, 28),
    Position = UDim2.new(1, -60, 0, 0),
    BackgroundColor3 = Color3.fromRGB(160, 60, 40),
    Text = "CLEAR",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 10,
    Font = Enum.Font.GothamBold
}, IDPage)
round(ClearBtn, 6)
local List = create("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, -66),
    Position = UDim2.fromOffset(0, 36),
    BackgroundColor3 = Color3.fromRGB(27, 32, 42),
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y
}, IDPage)
round(List, 7)
create("UIListLayout", { Padding = UDim.new(0, 4) }, List)
create("UIPadding", { PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }, List)
local Footer = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.new(0, 0, 1, -30),
    BackgroundTransparency = 1,
    Text = "Ready.",
    TextColor3 = Color3.fromRGB(135, 150, 175),
    TextSize = 9,
    Font = Enum.Font.Gotham,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left
}, IDPage)
local FieldsPage = create("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    Position = UDim2.fromOffset(0, 0),
    BackgroundTransparency = 1,
    Visible = false
}, Content)
local FieldsList = create("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, -30),
    BackgroundColor3 = Color3.fromRGB(27, 32, 42),
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y
}, FieldsPage)
round(FieldsList, 7)
create("UIListLayout", { Padding = UDim.new(0, 4) }, FieldsList)
create("UIPadding", { PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }, FieldsList)
local FieldsFooter = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.new(0, 0, 1, -30),
    BackgroundTransparency = 1,
    Text = "",
    TextColor3 = Color3.fromRGB(135, 150, 175),
    TextSize = 9,
    Font = Enum.Font.Gotham,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left
}, FieldsPage)
local dragging = false
local dragInput
local dragStart
local startPosition
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                if saveConfig then saveConfig() end
            end
        end)
    end
end)
Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end
end)
local minimized = false
local savedMainHeight = MAIN_BASE_HEIGHT
Minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        savedMainHeight = Main.Size.Y.Offset
        Main.Size = UDim2.fromOffset(280, 40)
        Minimize.Text = "+"
    else
        Main.Size = UDim2.fromOffset(280, savedMainHeight)
        Minimize.Text = "−"
    end
    if saveConfig then saveConfig() end
end)
TriangleBtn.MouseButton1Click:Connect(function()
    if minimized then return end
    settingsOpen = not settingsOpen
    local panelH = settingsOpen and SETTINGS_PANEL_HEIGHT or 0
    local mainH = MAIN_BASE_HEIGHT + panelH
    local targetRotation = settingsOpen and 0 or 90
    TweenService:Create(Main, SETTINGS_TWEEN_INFO, { Size = UDim2.fromOffset(280, mainH) }):Play()
    TweenService:Create(SettingsPanel, SETTINGS_TWEEN_INFO, { Size = UDim2.new(1, 0, 0, panelH) }):Play()
    TweenService:Create(TabBar, SETTINGS_TWEEN_INFO, { Position = UDim2.fromOffset(0, 40 + panelH) }):Play()
    TweenService:Create(Content, SETTINGS_TWEEN_INFO, { Position = UDim2.fromOffset(8, 72 + panelH) }):Play()
    TweenService:Create(TriangleBtn, SETTINGS_TWEEN_INFO, { Rotation = targetRotation }):Play()
    saveConfig()
end)
local ItemConfigs = {}
local fieldSelection = {}
local FieldItemPermissions = {}
local openFields = {}
local function isFieldEnabled(name)
    local explicit = fieldSelection[name]
    if explicit ~= nil then return explicit end
    return true
end
local function ensureConfig(name)
    if not ItemConfigs[name] then
        ItemConfigs[name] = {
            enabled = false,
            ignoreZones = false,
            collectInField = false,
            holdTime = HOVER_AT_TARGET
        }
    end
    return ItemConfigs[name]
end
if type(isfile) == "function" and type(readfile) == "function" then
    if isfile(SAVE_FILE) then
        local ok, content = pcall(readfile, SAVE_FILE)
        if ok and content then
            local ok2, data = pcall(function() return HttpService:JSONDecode(content) end)
            if ok2 and type(data) == "table" then 
                loadedData = data 
            end
        end
    end
end
if loadedData then
    if type(loadedData.items) == "table" then
        for name, conf in pairs(loadedData.items) do
            if type(conf) == "table" and ItemDatabase[name] then
                ItemConfigs[name] = {
                    enabled = conf.enabled == true,
                    ignoreZones = conf.ignoreZones == true,
                    collectInField = conf.collectInField == true,
                    holdTime = type(conf.holdTime) == "number" and conf.holdTime or HOVER_AT_TARGET
                }
            end
        end
    end
    if type(loadedData.fields) == "table" then
        for name, enabled in pairs(loadedData.fields) do 
            if type(name) == "string" and type(enabled) == "boolean" then 
                fieldSelection[name] = enabled 
            end 
        end
    end
    if type(loadedData.fieldItems) == "table" then
        for fName, perms in pairs(loadedData.fieldItems) do
            if type(perms) == "table" then
                FieldItemPermissions[fName] = {}
                for iName, allowed in pairs(perms) do
                    FieldItemPermissions[fName][iName] = allowed
                end
            end
        end
    end
    if type(loadedData.speed) == "number" then 
        FlySpeed = math.clamp(math.floor(loadedData.speed), SPEED_MIN, SPEED_MAX) 
    end
    if loadedData.settingsOpen == true then
        settingsOpen = true
        local panelH = SETTINGS_PANEL_HEIGHT
        local mainH = MAIN_BASE_HEIGHT + panelH
        Main.Size = UDim2.fromOffset(280, mainH)
        SettingsPanel.Size = UDim2.new(1, 0, 0, panelH)
        TabBar.Position = UDim2.fromOffset(0, 40 + panelH)
        Content.Position = UDim2.fromOffset(8, 72 + panelH)
        TriangleBtn.Rotation = 0
    end
end
saveConfig = function()
    if type(writefile) ~= "function" then return end
    if type(makefolder) == "function" and type(isfolder) == "function" then 
        pcall(function() 
            if not isfolder(SAVE_FOLDER) then makefolder(SAVE_FOLDER) end 
        end) 
    end
    local data = {
        items = ItemConfigs, 
        fields = fieldSelection, 
        fieldItems = FieldItemPermissions,
        speed = FlySpeed,
        settingsOpen = settingsOpen,
        guiPosition = { 
            xScale = Main.Position.X.Scale, 
            xOffset = Main.Position.X.Offset, 
            yScale = Main.Position.Y.Scale, 
            yOffset = Main.Position.Y.Offset 
        },
        minimized = minimized
    }
    local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
    if ok then 
        pcall(writefile, SAVE_FILE, encoded) 
    end
end
local function getBounds(object)
    local cf, size
    if object:IsA("BasePart") then 
        cf = object.CFrame
        size = object.Size
    elseif object:IsA("Model") then 
        local success, boxCF, boxSize = pcall(function() return object:GetBoundingBox() end)
        if not success then return nil end
        cf = boxCF
        size = boxSize
    else 
        return nil 
    end
    local xExtent = math.abs(cf.RightVector.X) * size.X / 2 + math.abs(cf.UpVector.X) * size.Y / 2 + math.abs(cf.LookVector.X) * size.Z / 2
    local zExtent = math.abs(cf.RightVector.Z) * size.X / 2 + math.abs(cf.UpVector.Z) * size.Y / 2 + math.abs(cf.LookVector.Z) * size.Z / 2
    return { 
        minX = cf.Position.X - xExtent, 
        maxX = cf.Position.X + xExtent, 
        minZ = cf.Position.Z - zExtent, 
        maxZ = cf.Position.Z + zExtent 
    }
end
local function getFlowerZones()
    local folder = Workspace:FindFirstChild("FlowerZones")
    local zones = {}
    if not folder then return zones end
    for _, zone in ipairs(folder:GetChildren()) do 
        if isFieldEnabled(zone.Name) then 
            local bounds = getBounds(zone)
            if bounds then 
                table.insert(zones, {bounds = bounds, name = zone.Name}) 
            end
        end 
    end
    return zones
end
local function getCurrentFields(playerPos)
    local folder = Workspace:FindFirstChild("FlowerZones")
    local result = {}
    if not folder then return result end
    for _, zone in ipairs(folder:GetChildren()) do 
        if isFieldEnabled(zone.Name) then
            local bounds = getBounds(zone)
            if bounds then
                if playerPos.X >= bounds.minX and playerPos.X <= bounds.maxX and playerPos.Z >= bounds.minZ and playerPos.Z <= bounds.maxZ then
                    table.insert(result, {bounds = bounds, name = zone.Name})
                end
            end
        end
    end
    return result
end
local function isPointInAnyField(pos, fields)
    for _, field in ipairs(fields) do
        local b = field.bounds
        if pos.X >= b.minX and pos.X <= b.maxX and pos.Z >= b.minZ and pos.Z <= b.maxZ then
            return true, field.name
        end
    end
    return false, nil
end
local function intersectsFlowerZone(object, zones)
    local objectBounds = getBounds(object)
    if not objectBounds then return false end
    for _, zone in ipairs(zones) do
        local b = zone.bounds
        local overlapX = objectBounds.minX <= b.maxX and objectBounds.maxX >= b.minX
        local overlapZ = objectBounds.minZ <= b.maxZ and objectBounds.maxZ >= b.minZ
        if overlapX and overlapZ then 
            return true 
        end
    end
    return false
end
local function isItemForbiddenInAnyField(itemName, object)
    local objectBounds = getBounds(object)
    if not objectBounds then return false end
    local folder = Workspace:FindFirstChild("FlowerZones")
    if not folder then return false end
    for _, zone in ipairs(folder:GetChildren()) do
        local bounds = getBounds(zone)
        if bounds then
            local overlapX = objectBounds.minX <= bounds.maxX and objectBounds.maxX >= bounds.minX
            local overlapZ = objectBounds.minZ <= bounds.maxZ and objectBounds.maxZ >= bounds.minZ
            if overlapX and overlapZ then
                if FieldItemPermissions[zone.Name] and FieldItemPermissions[zone.Name][itemName] == false then
                    return true
                end
            end
        end
    end
    return false
end
local function getColorMapID(object)
    local backDecal = object:FindFirstChild("BackDecal", true)
    if not backDecal then return nil end
    local properties = {"ColorMap", "Texture", "SoundId", "MeshId", "Image"}
    for _, prop in ipairs(properties) do
        local ok, value = pcall(function() return backDecal[prop] end)
        if ok and value ~= nil then 
            local id = tostring(value):match("%d+")
            if id then return id end 
        end
    end
    return nil
end
local function getTargetCFrame(object)
    if object:IsA("BasePart") then 
        return object.CFrame 
    end
    local visualPart = nil
    for _, child in ipairs(object:GetDescendants()) do
        if child:IsA("BasePart") then
            if child:FindFirstChild("BackDecal") or child:FindFirstChild("FrontDecal") then
                visualPart = child
                break
            end
        end
    end
    if visualPart then 
        return visualPart.CFrame 
    end
    if object:IsA("Model") then 
        if object.PrimaryPart then 
            return object.PrimaryPart.CFrame 
        end
        local ok, pivot = pcall(function() return object:GetPivot() end)
        if ok and pivot then return pivot end 
    end
    for _, child in ipairs(object:GetDescendants()) do 
        if child:IsA("BasePart") then 
            return child.CFrame 
        end 
    end
    return nil
end
local function flyTo(character, root, targetCF, speed, cancelCheck)
    if not root or not root.Parent then return false end
    local startCF = root.CFrame
    local distance = (targetCF.Position - startCF.Position).Magnitude
    if not isFinite(distance) then return false end
    if distance < 1 then 
        pcall(function() root.CFrame = targetCF end)
        return true 
    end
    speed = math.max(speed, 1)
    local duration = distance / speed
    local startTime = os.clock()
    local collisionState = {}
    for _, part in ipairs(character:GetDescendants()) do 
        if part:IsA("BasePart") then 
            collisionState[part] = part.CanCollide
            part.CanCollide = false 
        end 
    end
    local success = true
    while true do
        if not root.Parent then success = false break end
        if Player.Character ~= character then success = false break end
        if cancelCheck and not cancelCheck() then success = false break end
        local elapsed = os.clock() - startTime
        local alpha = math.min(elapsed / duration, 1)
        local currentCF = startCF:Lerp(targetCF, alpha)
        pcall(function() root.CFrame = currentCF end)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        if alpha >= 1 then break end
        task.wait()
    end
    for part, val in pairs(collisionState) do 
        if part.Parent then 
            part.CanCollide = val 
        end 
    end
    return success
end
local Enabled = false
local RunToken = 0
local HomePosition = nil
local function isRunning(token) 
    return Enabled and RunToken == token 
end
local function teleportHome()
    if not HomePosition then return end
    local character = Player.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root or not root.Parent then return end
    local p = HomePosition.Position
    if isFinite(p.X) and isFinite(p.Y) and isFinite(p.Z) and p.Y > -500 then
        pcall(function() root.CFrame = HomePosition end)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
end
local function scanPass(token)
    local character = Player.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local zones = getFlowerZones()
    if not isRunning(token) then return end
    local playerFields = nil
    local collectiblesFolder = Workspace:FindFirstChild("Collectibles")
    local objects = {}
    if collectiblesFolder then 
        objects = collectiblesFolder:GetChildren() 
    end
    local targets = {}
    local scanned = 0
    local matchedID = 0
    for _, object in ipairs(objects) do
        if not isRunning(token) then break end
        scanned = scanned + 1
        if object.Name == "C" then
            local id = getColorMapID(object)
            if id then
                local itemName = IDToName[id]
                local conf = itemName and ensureConfig(itemName)
                if conf and conf.enabled then
                    matchedID = matchedID + 1
                    local cf = getTargetCFrame(object)
                    if cf then 
                        local targetPos = cf.Position
                        if isFinite(targetPos.X) and isFinite(targetPos.Y) and isFinite(targetPos.Z) and targetPos.Y > -50 and targetPos.Y < 500 then
                            local dist = (targetPos - root.Position).Magnitude
                            if isFinite(dist) and dist < 3000 then
                                local isForbidden = isItemForbiddenInAnyField(itemName, object)
                                if not isForbidden then
                                    local shouldCollect = false
                                    if conf.collectInField then
                                        if not playerFields then
                                            playerFields = getCurrentFields(root.Position)
                                        end
                                        if #playerFields > 0 and isPointInAnyField(targetPos, playerFields) then
                                            shouldCollect = true
                                        end
                                    elseif conf.ignoreZones or intersectsFlowerZone(object, zones) then
                                        shouldCollect = true
                                    end
                                    if shouldCollect then
                                        table.insert(targets, {object = object, cf = cf, holdTime = conf.holdTime}) 
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if #targets == 0 then 
        Footer.Text = string.format("None | scan %d, id %d", scanned, matchedID) 
        return 
    end
    HomePosition = root.CFrame
    Footer.Text = "Flying to " .. #targets .. " target(s)..."
    for index, entry in ipairs(targets) do
        if not isRunning(token) or Player.Character ~= character or not root.Parent then break end
        if not entry.object.Parent then continue end
        Footer.Text = "Flying " .. index .. " / " .. #targets
        flyTo(character, root, entry.cf, FlySpeed, function() return isRunning(token) end)
        local targetPart = nil
        for _, child in ipairs(entry.object:GetDescendants()) do
            if child:IsA("BasePart") then targetPart = child break end
        end
        if targetPart and firetouchinterest then
            pcall(function()
                firetouchinterest(root, targetPart, 0)
                task.wait()
                firetouchinterest(root, targetPart, 1)
            end)
        end
        local holdEndTime = os.clock() + entry.holdTime
        while os.clock() < holdEndTime do
            if not isRunning(token) or not root.Parent then break end
            if not entry.object.Parent then break end
            local currentCF = getTargetCFrame(entry.object)
            if currentCF then entry.cf = currentCF end
            pcall(function() root.CFrame = entry.cf end)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            task.wait()
        end
        pcall(function()
            if entry.object and entry.object.Parent then
                entry.object:Destroy()
            end
        end)
    end
    if isRunning(token) and HomePosition then 
        teleportHome() 
    end
    if isRunning(token) then 
        Footer.Text = "Returned home." 
    end
end
local function updateStatus()
    if Enabled then 
        Status.Text = "● ACTIVE"
        Status.BackgroundColor3 = Color3.fromRGB(35, 145, 85)
    else 
        Status.Text = "● OFF"
        Status.BackgroundColor3 = Color3.fromRGB(150, 45, 50) 
    end
end
Status.MouseButton1Click:Connect(function()
    Enabled = not Enabled
    RunToken += 1
    updateStatus()
    if Enabled then
        local token = RunToken
        Footer.Text = "Starting..."
        task.spawn(function()
            while isRunning(token) do
                local started = os.clock()
                local success, errorMessage = pcall(scanPass, token)
                if not success then 
                    warn("[Sprout Collector]", errorMessage)
                    Footer.Text = "Error. Check console." 
                end
                local remaining = SCAN_INTERVAL - (os.clock() - started)
                if remaining > 0 and isRunning(token) then 
                    task.wait(remaining) 
                end
            end
        end)
    else
        teleportHome()
        HomePosition = nil
        Footer.Text = "Stopped."
    end
end)
if loadedData then
    if type(loadedData.guiPosition) == "table" then
        local p = loadedData.guiPosition
        if type(p.xScale) == "number" and type(p.xOffset) == "number" and type(p.yScale) == "number" and type(p.yOffset) == "number" then
            Main.Position = UDim2.new(p.xScale, p.xOffset, p.yScale, p.yOffset)
        end
    end
    if loadedData.minimized == true then
        minimized = true
        Main.Size = UDim2.fromOffset(280, 40)
        Minimize.Text = "+"
    end
end
refreshSpeedUI = function()
    local ratio = (FlySpeed - SPEED_MIN) / (SPEED_MAX - SPEED_MIN)
    SpeedFill.Size = UDim2.new(ratio, 0, 1, 0)
    SpeedHandle.Position = UDim2.new(ratio, -5, 0.5, -7)
    SpeedLabel.Text = "Global speed: " .. FlySpeed .. " studs/s"
end
local draggingSpeed = false
SpeedButton.InputBegan:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
        draggingSpeed = true
        local ratio = math.clamp((input.Position.X - SpeedBar.AbsolutePosition.X) / SpeedBar.AbsoluteSize.X, 0, 1)
        FlySpeed = math.floor(SPEED_MIN + ratio * (SPEED_MAX - SPEED_MIN) + 0.5)
        refreshSpeedUI()
    end 
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingSpeed and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local ratio = math.clamp((input.Position.X - SpeedBar.AbsolutePosition.X) / SpeedBar.AbsoluteSize.X, 0, 1)
        FlySpeed = math.floor(SPEED_MIN + ratio * (SPEED_MAX - SPEED_MIN) + 0.5)
        refreshSpeedUI()
    end
end)
UserInputService.InputEnded:Connect(function(input) 
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and draggingSpeed then 
        draggingSpeed = false
        saveConfig() 
    end 
end)
local openMenus = {}
local ITEM_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function buildItemRow(name, index, parent)
    local conf = ensureConfig(name)
    local isOpen = openMenus[name] == true
    local baseHeight = 26
    local expandedHeight = 110
    local targetHeight = isOpen and expandedHeight or baseHeight
    local Container = create("Frame", {
        Size = UDim2.new(1, -2, 0, targetHeight),
        BackgroundColor3 = Color3.fromRGB(37, 44, 57),
        LayoutOrder = index,
        ClipsDescendants = true
    }, parent)
    round(Container, 5)
    local MainRow = create("Frame", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
        ZIndex = 1
    }, Container)
    create("TextLabel", {
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.fromOffset(8, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Color3.fromRGB(225, 232, 245),
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 1
    }, MainRow)
    local ItemTriangle = create("TextButton", {
        Size = UDim2.fromOffset(24, 24),
        Position = UDim2.new(1, -28, 0.5, -12),
        BackgroundTransparency = 1,
        Text = "▶",
        TextColor3 = Color3.fromRGB(200, 210, 225),
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        Rotation = isOpen and 90 or 0,
        ZIndex = 5
    }, MainRow)
    local Settings = create("Frame", {
        Size = UDim2.new(1, 0, 0, expandedHeight - baseHeight),
        Position = UDim2.fromOffset(0, baseHeight),
        BackgroundTransparency = 1,
        ZIndex = 1
    }, Container)
    local Toggle = create("TextButton", {
        Size = UDim2.new(0.5, -6, 0, 24),
        Position = UDim2.fromOffset(4, 4),
        BackgroundColor3 = conf.enabled and Color3.fromRGB(35, 145, 85) or Color3.fromRGB(120, 45, 50),
        Text = conf.enabled and "ENABLED" or "DISABLED",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 9,
        Font = Enum.Font.GothamBold
    }, Settings)
    round(Toggle, 4)
    local ZoneBtn = create("TextButton", {
        Size = UDim2.new(0.5, -6, 0, 24),
        Position = UDim2.new(0.5, 2, 0, 4),
        BackgroundColor3 = conf.ignoreZones and Color3.fromRGB(65, 115, 210) or Color3.fromRGB(80, 80, 90),
        Text = conf.ignoreZones and "IGNORE ZONE" or "USE ZONE",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 9,
        Font = Enum.Font.GothamBold
    }, Settings)
    round(ZoneBtn, 4)
    local FieldBtnItem = create("TextButton", {
        Size = UDim2.new(1, -8, 0, 22),
        Position = UDim2.fromOffset(4, 32),
        BackgroundColor3 = conf.collectInField and Color3.fromRGB(35, 145, 85) or Color3.fromRGB(80, 80, 90),
        Text = conf.collectInField and "COLLECT IN MY FIELD: ON" or "COLLECT IN MY FIELD: OFF",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 9,
        Font = Enum.Font.GothamBold
    }, Settings)
    round(FieldBtnItem, 4)
    local ItemHoldLabel = create("TextLabel", {
        Size = UDim2.new(1, -80, 0, 20),
        Position = UDim2.fromOffset(5, 58),
        BackgroundTransparency = 1,
        Text = "Hold: " .. string.format("%.1f", conf.holdTime) .. "s",
        TextColor3 = Color3.fromRGB(160, 175, 200),
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left
    }, Settings)
    local MinusBtn = create("TextButton", {
        Size = UDim2.fromOffset(30, 20),
        Position = UDim2.new(1, -70, 0, 58),
        BackgroundColor3 = Color3.fromRGB(48, 57, 73),
        Text = "-",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 12,
        Font = Enum.Font.GothamBold
    }, Settings)
    round(MinusBtn, 4)
    local PlusBtn = create("TextButton", {
        Size = UDim2.fromOffset(30, 20),
        Position = UDim2.new(1, -35, 0, 58),
        BackgroundColor3 = Color3.fromRGB(48, 57, 73),
        Text = "+",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 12,
        Font = Enum.Font.GothamBold
    }, Settings)
    round(PlusBtn, 4)
    ItemTriangle.MouseButton1Click:Connect(function()
        openMenus[name] = not openMenus[name]
        local nowOpen = openMenus[name]
        TweenService:Create(Container, ITEM_TWEEN_INFO, { Size = UDim2.new(1, -2, 0, nowOpen and expandedHeight or baseHeight) }):Play()
        TweenService:Create(ItemTriangle, ITEM_TWEEN_INFO, { Rotation = nowOpen and 90 or 0 }):Play()
    end)
    Toggle.MouseButton1Click:Connect(function()
        conf.enabled = not conf.enabled
        Toggle.BackgroundColor3 = conf.enabled and Color3.fromRGB(35, 145, 85) or Color3.fromRGB(120, 45, 50)
        Toggle.Text = conf.enabled and "ENABLED" or "DISABLED"
        saveConfig()
    end)
    ZoneBtn.MouseButton1Click:Connect(function()
        conf.ignoreZones = not conf.ignoreZones
        ZoneBtn.BackgroundColor3 = conf.ignoreZones and Color3.fromRGB(65, 115, 210) or Color3.fromRGB(80, 80, 90)
        ZoneBtn.Text = conf.ignoreZones and "IGNORE ZONE" or "USE ZONE"
        saveConfig()
    end)
    FieldBtnItem.MouseButton1Click:Connect(function()
        conf.collectInField = not conf.collectInField
        FieldBtnItem.BackgroundColor3 = conf.collectInField and Color3.fromRGB(35, 145, 85) or Color3.fromRGB(80, 80, 90)
        FieldBtnItem.Text = conf.collectInField and "COLLECT IN MY FIELD: ON" or "COLLECT IN MY FIELD: OFF"
        saveConfig()
    end)
    MinusBtn.MouseButton1Click:Connect(function()
        conf.holdTime = math.max(0.1, math.floor((conf.holdTime - 0.1) * 10 + 0.5) / 10)
        ItemHoldLabel.Text = "Hold: " .. string.format("%.1f", conf.holdTime) .. "s"
        saveConfig()
    end)
    PlusBtn.MouseButton1Click:Connect(function()
        conf.holdTime = math.min(2.0, math.floor((conf.holdTime + 0.1) * 10 + 0.5) / 10)
        ItemHoldLabel.Text = "Hold: " .. string.format("%.1f", conf.holdTime) .. "s"
        saveConfig()
    end)
end
local function buildFieldRow(fieldName, index, parent)
    local isOpen = openFields[fieldName] == true
    local baseHeight = 26
    local expandedHeight = 160
    local Container = create("Frame", {
        Size = UDim2.new(1, -2, 0, isOpen and expandedHeight or baseHeight),
        BackgroundColor3 = Color3.fromRGB(37, 44, 57),
        LayoutOrder = index,
        ClipsDescendants = true
    }, parent)
    round(Container, 5)
    local MainRow = create("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1 }, Container)
    create("TextLabel", { Size = UDim2.new(1, -80, 1, 0), Position = UDim2.fromOffset(8, 0), BackgroundTransparency = 1, Text = fieldName, TextColor3 = Color3.fromRGB(225, 232, 245), TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left }, MainRow)
    local ToggleBtn = create("TextButton", { Size = UDim2.fromOffset(48, 20), Position = UDim2.new(1, -76, 0.5, -10), BackgroundColor3 = isFieldEnabled(fieldName) and Color3.fromRGB(35, 145, 85) or Color3.fromRGB(120, 45, 50), Text = isFieldEnabled(fieldName) and "ON" or "OFF", TextColor3 = Color3.new(1, 1, 1), TextSize = 10, Font = Enum.Font.GothamBold }, MainRow)
    round(ToggleBtn, 4)
    ToggleBtn.MouseButton1Click:Connect(function()
        local nowEnabled = not isFieldEnabled(fieldName)
        fieldSelection[fieldName] = nowEnabled
        ToggleBtn.BackgroundColor3 = nowEnabled and Color3.fromRGB(35, 145, 85) or Color3.fromRGB(120, 45, 50)
        ToggleBtn.Text = nowEnabled and "ON" or "OFF"
        saveConfig()
    end)
    local ArrowBtn = create("TextButton", { Size = UDim2.fromOffset(24, 24), Position = UDim2.new(1, -26, 0.5, -12), BackgroundTransparency = 1, Text = "▶", TextColor3 = Color3.fromRGB(200, 210, 225), TextSize = 14, Font = Enum.Font.GothamBold, Rotation = isOpen and 90 or 0 }, MainRow)
    local InnerSettings = create("Frame", { Size = UDim2.new(1, -8, 0, expandedHeight - baseHeight), Position = UDim2.fromOffset(4, baseHeight), BackgroundTransparency = 1 }, Container)
    local InnerList = create("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 3, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y }, InnerSettings)
    create("UIListLayout", { Padding = UDim.new(0, 2) }, InnerList)
    for _, itemName in ipairs(SortedItemNames) do
        local isAllowed = true
        if FieldItemPermissions[fieldName] and FieldItemPermissions[fieldName][itemName] == false then
            isAllowed = false
        end
        local itemRow = create("Frame", { Size = UDim2.new(1, -2, 0, 20), BackgroundColor3 = Color3.fromRGB(45, 50, 65) }, InnerList)
        round(itemRow, 3)
        create("TextLabel", { Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(4, 0), BackgroundTransparency = 1, Text = itemName, TextColor3 = Color3.fromRGB(200, 210, 225), TextSize = 9, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left }, itemRow)
        local itemBtn = create("TextButton", { Size = UDim2.fromOffset(50, 16), Position = UDim2.new(1, -54, 0.5, -8), BackgroundColor3 = isAllowed and Color3.fromRGB(35, 145, 85) or Color3.fromRGB(120, 45, 50), Text = isAllowed and "ALLOW" or "FORBID", TextColor3 = Color3.new(1, 1, 1), TextSize = 8, Font = Enum.Font.GothamBold }, itemRow)
        round(itemBtn, 3)
        itemBtn.MouseButton1Click:Connect(function()
            if not FieldItemPermissions[fieldName] then FieldItemPermissions[fieldName] = {} end
            local current = FieldItemPermissions[fieldName][itemName]
            if current == nil then current = true end
            current = not current
            FieldItemPermissions[fieldName][itemName] = current
            itemBtn.BackgroundColor3 = current and Color3.fromRGB(35, 145, 85) or Color3.fromRGB(120, 45, 50)
            itemBtn.Text = current and "ALLOW" or "FORBID"
            saveConfig()
        end)
    end
    ArrowBtn.MouseButton1Click:Connect(function()
        openFields[fieldName] = not openFields[fieldName]
        local nowOpen = openFields[fieldName]
        TweenService:Create(Container, ITEM_TWEEN_INFO, { Size = UDim2.new(1, -2, 0, nowOpen and expandedHeight or baseHeight) }):Play()
        TweenService:Create(ArrowBtn, ITEM_TWEEN_INFO, { Rotation = nowOpen and 90 or 0 }):Play()
    end)
end
refreshItemsList = function()
    for _, child in ipairs(List:GetChildren()) do 
        if child:IsA("Frame") then child:Destroy() end 
    end
    local searchTxt = SearchBar.Text:lower()
    local filteredNames = {}
    for _, name in ipairs(SortedItemNames) do 
        if searchTxt == "" or name:lower():find(searchTxt) then
            table.insert(filteredNames, name) 
        end
    end
    for i, name in ipairs(filteredNames) do
        buildItemRow(name, i, List)
    end
end
refreshFieldsList = function()
    for _, child in ipairs(FieldsList:GetChildren()) do 
        if child:IsA("Frame") then child:Destroy() end 
    end
    local folder = Workspace:FindFirstChild("FlowerZones")
    if not folder then 
        FieldsFooter.Text = "FlowerZones not found." 
        return 
    end
    local names = {}
    for _, zone in ipairs(folder:GetChildren()) do 
        table.insert(names, zone.Name) 
    end
    table.sort(names)
    for index, name in ipairs(names) do
        buildFieldRow(name, index, FieldsList)
    end
end
SearchBar:GetPropertyChangedSignal("Text"):Connect(function() refreshItemsList() end)
ClearBtn.MouseButton1Click:Connect(function() 
    purgeCollectibles()
    Footer.Text = "Collectibles cleared." 
end)
IDsTab.MouseButton1Click:Connect(function()
    IDPage.Visible = true
    FieldsPage.Visible = false
    IDsTab.BackgroundColor3 = Color3.fromRGB(65, 115, 210)
    IDsTab.TextColor3 = Color3.new(1, 1, 1)
    FieldsTab.BackgroundColor3 = Color3.fromRGB(42, 50, 65)
    FieldsTab.TextColor3 = Color3.fromRGB(200, 210, 225)
end)
FieldsTab.MouseButton1Click:Connect(function()
    IDPage.Visible = false
    FieldsPage.Visible = true
    IDsTab.BackgroundColor3 = Color3.fromRGB(42, 50, 65)
    IDsTab.TextColor3 = Color3.fromRGB(200, 210, 225)
    FieldsTab.BackgroundColor3 = Color3.fromRGB(65, 115, 210)
    FieldsTab.TextColor3 = Color3.new(1, 1, 1)
    refreshFieldsList()
end)
refreshSpeedUI()
updateStatus()
refreshItemsList()
Footer.Text = "Ready."
print("[Sprout Collector] Loaded with Field-Item Permissions.")
