local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local SCAN_INTERVAL = 1
local HOLD_MIN = 0.1
local HOLD_MAX = 2.0
local HOVER_AT_TARGET = 0.3
local AUTO_CLEAR = true
local SPEED_MIN = 20
local SPEED_MAX = 800
local FlySpeed = 60
local CurrentFieldOnly = false
local SETTINGS_PANEL_HEIGHT = 110
local MAIN_BASE_HEIGHT = 340
local settingsOpen = false
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
local refreshHoldUI
local refreshItemsList
local ItemDatabase = {}
local IDToName = {}
for name, id in pairs(FallbackItems) do
    ItemDatabase[name] = id
    IDToName[id] = name
end
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
    Rotation = 90
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
    Size = UDim2.new(0.5, -6, 0, 30),
    Position = UDim2.fromOffset(8, 8),
    BackgroundColor3 = Color3.fromRGB(150, 45, 50),
    Text = "OFF",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 13,
    Font = Enum.Font.GothamBold
}, SettingsPanel)
round(Status, 7)
local FieldBtn = create("TextButton", {
    Size = UDim2.new(0.5, -6, 0, 30),
    Position = UDim2.new(0.5, -2, 0, 8),
    BackgroundColor3 = Color3.fromRGB(60, 60, 70),
    Text = "FIELD: OFF",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 10,
    Font = Enum.Font.GothamBold
}, SettingsPanel)
round(FieldBtn, 7)
local SpeedControl = create("Frame", {
    Size = UDim2.new(1, -16, 0, 22),
    Position = UDim2.fromOffset(8, 46),
    BackgroundTransparency = 1
}, SettingsPanel)
local SpeedLabel = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 10),
    BackgroundTransparency = 1,
    Text = "Fly speed: " .. FlySpeed .. " studs/s",
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
local HoldControl = create("Frame", {
    Size = UDim2.new(1, -16, 0, 22),
    Position = UDim2.fromOffset(8, 76),
    BackgroundTransparency = 1
}, SettingsPanel)
local HoldLabel = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 10),
    BackgroundTransparency = 1,
    Text = "Hold time: " .. HOVER_AT_TARGET .. "s",
    TextColor3 = Color3.fromRGB(160, 175, 200),
    TextSize = 9,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left
}, HoldControl)
local HoldBar = create("Frame", {
    Size = UDim2.new(1, 0, 0, 8),
    Position = UDim2.fromOffset(0, 12),
    BackgroundColor3 = Color3.fromRGB(40, 48, 62),
    BorderSizePixel = 0
}, HoldControl)
round(HoldBar, 4)
local HoldFill = create("Frame", {
    Size = UDim2.new((HOVER_AT_TARGET - HOLD_MIN) / (HOLD_MAX - HOLD_MIN), 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(65, 115, 210),
    BorderSizePixel = 0
}, HoldBar)
round(HoldFill, 4)
local HoldHandle = create("Frame", {
    Size = UDim2.fromOffset(10, 14),
    Position = UDim2.new((HOVER_AT_TARGET - HOLD_MIN) / (HOLD_MAX - HOLD_MIN), -5, 0.5, -7),
    BackgroundColor3 = Color3.fromRGB(240, 240, 245),
    BorderSizePixel = 0,
    ZIndex = 2
}, HoldBar)
round(HoldHandle, 5)
local HoldButton = create("TextButton", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "",
    ZIndex = 3
}, HoldBar)
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
        Content.Visible = false
        TabBar.Visible = false
        SettingsPanel.Visible = false
        Main.Size = UDim2.fromOffset(280, 40)
        Minimize.Text = "+"
    else
        Content.Visible = true
        TabBar.Visible = true
        SettingsPanel.Visible = true
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
    local ti = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(Main, ti, { Size = UDim2.fromOffset(280, mainH) }):Play()
    TweenService:Create(SettingsPanel, ti, { Size = UDim2.new(1, 0, 0, panelH) }):Play()
    TweenService:Create(TabBar, ti, { Position = UDim2.fromOffset(0, 40 + panelH) }):Play()
    TweenService:Create(Content, ti, { Position = UDim2.fromOffset(8, 72 + panelH) }):Play()
    TweenService:Create(TriangleBtn, ti, { Rotation = targetRotation }):Play()
    saveConfig()
end)
FieldBtn.MouseButton1Click:Connect(function()
    CurrentFieldOnly = not CurrentFieldOnly
    if CurrentFieldOnly then
        FieldBtn.Text = "FIELD: ON"
        FieldBtn.BackgroundColor3 = Color3.fromRGB(35, 145, 85)
    else
        FieldBtn.Text = "FIELD: OFF"
        FieldBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    end
    saveConfig()
end)
local SelectedNames = {}
local SelectedIDs = {}
local ItemIgnoreZones = {}
local fieldSelection = {}
local function isFieldEnabled(name)
    local explicit = fieldSelection[name]
    if explicit ~= nil then return explicit end
    return true
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
        for _, name in ipairs(loadedData.items) do
            if ItemDatabase[name] then 
                SelectedNames[name] = true
                SelectedIDs[ItemDatabase[name]] = true 
            end
        end
    end
    if type(loadedData.ignoreZones) == "table" then
        for _, name in ipairs(loadedData.ignoreZones) do
            if ItemDatabase[name] then
                ItemIgnoreZones[name] = true
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
    if type(loadedData.speed) == "number" then 
        FlySpeed = math.clamp(math.floor(loadedData.speed), SPEED_MIN, SPEED_MAX) 
    end
    if type(loadedData.hoverDelay) == "number" then
        HOVER_AT_TARGET = math.clamp(loadedData.hoverDelay, HOLD_MIN, HOLD_MAX)
    end
    if loadedData.currentFieldOnly == true then
        CurrentFieldOnly = true
        FieldBtn.Text = "FIELD: ON"
        FieldBtn.BackgroundColor3 = Color3.fromRGB(35, 145, 85)
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
    local itemsList = {}
    for name, _ in pairs(SelectedNames) do 
        table.insert(itemsList, name) 
    end
    local ignoreList = {}
    for name, val in pairs(ItemIgnoreZones) do
        if val then table.insert(ignoreList, name) end
    end
    local data = {
        items = itemsList, 
        ignoreZones = ignoreList,
        fields = fieldSelection, 
        speed = FlySpeed,
        hoverDelay = HOVER_AT_TARGET,
        currentFieldOnly = CurrentFieldOnly,
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
refreshSpeedUI = function()
    local ratio = (FlySpeed - SPEED_MIN) / (SPEED_MAX - SPEED_MIN)
    SpeedFill.Size = UDim2.new(ratio, 0, 1, 0)
    SpeedHandle.Position = UDim2.new(ratio, -5, 0.5, -7)
    SpeedLabel.Text = "Fly speed: " .. FlySpeed .. " studs/s"
end
refreshHoldUI = function()
    local ratio = (HOVER_AT_TARGET - HOLD_MIN) / (HOLD_MAX - HOLD_MIN)
    HoldFill.Size = UDim2.new(ratio, 0, 1, 0)
    HoldHandle.Position = UDim2.new(ratio, -5, 0.5, -7)
    HoldLabel.Text = "Hold time: " .. string.format("%.1f", HOVER_AT_TARGET) .. "s"
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
local draggingHold = false
HoldButton.InputBegan:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
        draggingHold = true
        local ratio = math.clamp((input.Position.X - HoldBar.AbsolutePosition.X) / HoldBar.AbsoluteSize.X, 0, 1)
        HOVER_AT_TARGET = math.floor((HOLD_MIN + ratio * (HOLD_MAX - HOLD_MIN)) * 10 + 0.5) / 10
        refreshHoldUI()
    end 
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingHold and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local ratio = math.clamp((input.Position.X - HoldBar.AbsolutePosition.X) / HoldBar.AbsoluteSize.X, 0, 1)
        HOVER_AT_TARGET = math.floor((HOLD_MIN + ratio * (HOLD_MAX - HOLD_MIN)) * 10 + 0.5) / 10
        refreshHoldUI()
    end
end)
UserInputService.InputEnded:Connect(function(input) 
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and draggingHold then 
        draggingHold = false
        saveConfig() 
    end 
end)
refreshItemsList = function()
    for _, child in ipairs(List:GetChildren()) do 
        if child:IsA("Frame") then 
            child:Destroy() 
        end 
    end
    local searchTxt = SearchBar.Text:lower()
    local sortedNames = {}
    for name, _ in pairs(ItemDatabase) do 
        if searchTxt == "" or name:lower():find(searchTxt) then
            table.insert(sortedNames, name) 
        end
    end
    table.sort(sortedNames)
    for i, name in ipairs(sortedNames) do
        local id = ItemDatabase[name]
        local isSelected = SelectedNames[name] == true
        local isIgnoring = ItemIgnoreZones[name] == true
        local Row = create("Frame", {
            Size = UDim2.new(1, -2, 0, 26),
            BackgroundColor3 = Color3.fromRGB(37, 44, 57),
            LayoutOrder = i
        }, List)
        round(Row, 5)
        create("TextLabel", {
            Size = UDim2.new(1, -85, 1, 0),
            Position = UDim2.fromOffset(8, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = Color3.fromRGB(225, 232, 245),
            TextSize = 11,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd
        }, Row)
        local ZoneBtn = create("TextButton", {
            Size = UDim2.fromOffset(24, 20),
            Position = UDim2.new(1, -80, 0.5, -10),
            BackgroundColor3 = isIgnoring and Color3.fromRGB(65, 115, 210) or Color3.fromRGB(80, 80, 90),
            Text = "Z",
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 10,
            Font = Enum.Font.GothamBold
        }, Row)
        round(ZoneBtn, 4)
        ZoneBtn.MouseButton1Click:Connect(function()
            ItemIgnoreZones[name] = not ItemIgnoreZones[name]
            ZoneBtn.BackgroundColor3 = ItemIgnoreZones[name] and Color3.fromRGB(65, 115, 210) or Color3.fromRGB(80, 80, 90)
            saveConfig()
        end)
        local Toggle = create("TextButton", {
            Size = UDim2.new(0, 48, 0, 20),
            Position = UDim2.new(1, -52, 0.5, -10),
            BackgroundColor3 = isSelected and Color3.fromRGB(35, 145, 85) or Color3.fromRGB(120, 45, 50),
            Text = isSelected and "ON" or "OFF",
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 10,
            Font = Enum.Font.GothamBold
        }, Row)
        round(Toggle, 4)
        Toggle.MouseButton1Click:Connect(function()
            if SelectedNames[name] then 
                SelectedNames[name] = nil
                SelectedIDs[id] = nil
                Toggle.BackgroundColor3 = Color3.fromRGB(120, 45, 50)
                Toggle.Text = "OFF"
            else 
                SelectedNames[name] = true
                SelectedIDs[id] = true
                Toggle.BackgroundColor3 = Color3.fromRGB(35, 145, 85)
                Toggle.Text = "ON" 
            end
            saveConfig()
        end)
    end
end
SearchBar:GetPropertyChangedSignal("Text"):Connect(function() refreshItemsList() end)
ClearBtn.MouseButton1Click:Connect(function() 
    purgeCollectibles()
    Footer.Text = "Collectibles cleared." 
end)
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
        local enabled = isFieldEnabled(name)
        local Row = create("Frame", {
            Size = UDim2.new(1, -2, 0, 26),
            BackgroundColor3 = Color3.fromRGB(37, 44, 57),
            LayoutOrder = index
        }, FieldsList)
        round(Row, 5)
        create("TextLabel", {
            Size = UDim2.new(1, -58, 1, 0),
            Position = UDim2.fromOffset(8, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = Color3.fromRGB(225, 232, 245),
            TextSize = 11,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left
        }, Row)
        local Toggle = create("TextButton", {
            Size = UDim2.fromOffset(48, 20),
            Position = UDim2.new(1, -52, 0.5, -10),
            BackgroundColor3 = enabled and Color3.fromRGB(35, 145, 85) or Color3.fromRGB(120, 45, 50),
            Text = enabled and "ON" or "OFF",
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 10,
            Font = Enum.Font.GothamBold
        }, Row)
        round(Toggle, 4)
        Toggle.MouseButton1Click:Connect(function()
            local nowEnabled = not isFieldEnabled(name)
            fieldSelection[name] = nowEnabled
            Toggle.BackgroundColor3 = nowEnabled and Color3.fromRGB(35, 145, 85) or Color3.fromRGB(120, 45, 50)
            Toggle.Text = nowEnabled and "ON" or "OFF"
            saveConfig()
        end)
    end
end
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
                table.insert(zones, bounds) 
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
        local bounds = getBounds(zone)
        if bounds then
            if playerPos.X >= bounds.minX and playerPos.X <= bounds.maxX and playerPos.Z >= bounds.minZ and playerPos.Z <= bounds.maxZ then
                table.insert(result, {bounds = bounds, name = zone.Name})
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
        local overlapX = objectBounds.minX <= zone.maxX and objectBounds.maxX >= zone.minX
        local overlapZ = objectBounds.minZ <= zone.maxZ and objectBounds.maxZ >= zone.minZ
        if overlapX and overlapZ then 
            return true 
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
    local currentFields = nil
    local currentFieldName = nil
    if CurrentFieldOnly then
        currentFields = getCurrentFields(root.Position)
        if #currentFields == 0 then
            Footer.Text = "Not on any field."
            return
        end
        currentFieldName = currentFields[1].name
    end
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
            if id and SelectedIDs[id] then
                matchedID = matchedID + 1
                local cf = getTargetCFrame(object)
                if cf then 
                    local targetPos = cf.Position
                    if isFinite(targetPos.X) and isFinite(targetPos.Y) and isFinite(targetPos.Z) and targetPos.Y > -50 and targetPos.Y < 500 then
                        local dist = (targetPos - root.Position).Magnitude
                        if isFinite(dist) and dist < 3000 then
                            local shouldCollect = false
                            if CurrentFieldOnly then
                                local inField = isPointInAnyField(targetPos, currentFields)
                                if inField then shouldCollect = true end
                            else
                                local itemName = IDToName[id]
                                local ignoreThis = itemName and ItemIgnoreZones[itemName]
                                if ignoreThis or intersectsFlowerZone(object, zones) then
                                    shouldCollect = true
                                end
                            end
                            if shouldCollect then
                                table.insert(targets, {object = object, cf = cf}) 
                            end
                        end
                    end
                end
            end
        end
    end
    if #targets == 0 then 
        if CurrentFieldOnly then
            Footer.Text = string.format("None on %s | scan %d", currentFieldName or "?", scanned)
        else
            Footer.Text = string.format("None | scan %d, id %d", scanned, matchedID) 
        end
        return 
    end
    HomePosition = root.CFrame
    if CurrentFieldOnly then
        Footer.Text = string.format("%d on %s...", #targets, currentFieldName or "?")
    else
        Footer.Text = "Flying to " .. #targets .. " target(s)..."
    end
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
        
        local holdEndTime = os.clock() + HOVER_AT_TARGET
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
        Content.Visible = false
        TabBar.Visible = false
        SettingsPanel.Visible = false
        Main.Size = UDim2.fromOffset(280, 40)
        Minimize.Text = "+"
    end
end
refreshSpeedUI()
refreshHoldUI()
updateStatus()
refreshItemsList()
Footer.Text = "Ready."
print("[Sprout Collector] Loaded strictly with Fallback List.")
