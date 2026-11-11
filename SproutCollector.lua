--==================================================
-- SPR0UT COLLECTOR — ITEMS BY NAME (FULL VERSION)
--==================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS
--==================================================

local SCAN_INTERVAL = 1
local HOVER_AT_TARGET = 0.3
local PURGE_ON_START = false

local SPEED_MIN = 20
local SPEED_MAX = 300
local FlySpeed = 60

local EXCLUDED_ZONES = {
    ["Ant Field"] = true,
    ["Blue Brick Field"] = true,
    ["Hub Field"] = true,
    ["Mixed Brick Field"] = true,
    ["Red Brick Field"] = true,
    ["White Brick Field"] = true
}

--==================================================
-- FALLBACK ITEMS (Твой список)
--==================================================

local FallbackItems = {
    ["Basic"] = "1442712345", ["Silver"] = "1442754321", ["Gold"] = "1874512345",
    ["RoyalJelly"] = "1874619728", ["Mythic"] = "4528999000", ["Diamond"] = "2499123789",
    ["GiftedDiamond"] = "2499123790", ["GiftedGold"] = "1874512346", ["Star"] = "2007771339",
    ["GiftedMythic"] = "4528999001", ["GiftedSilver"] = "1442754322", ["Treat"] = "1442700001",
    ["SunflowerSeed"] = "1442700002", ["Strawberry"] = "1442700003", ["StarTreat"] = "4528456124",
    ["Pineapple"] = "1442700004", ["Blueberry"] = "1442700005", ["Stinger"] = "1629612345",
    ["StarJelly"] = "2319943273", ["RedExtract"] = "1874123456", ["BlueExtract"] = "1874123789",
    ["Oil"] = "2538123456", ["MagicBean"] = "2499123457", ["Glue"] = "1839423100",
    ["Enzymes"] = "2499123456", ["Glitter"] = "1839423101", ["Coconut"] = "1839423102",
    ["MarshmallowBee"] = "1839423103", ["CloudVial"] = "1839423104", ["JellyBeans"] = "1839423105",
    ["Bitterberry"] = "1839423106", ["AtomicTreat"] = "1839423107", ["Neonberry"] = "1839423108",
    ["PurplePotion"] = "1839423109", ["SuperSmoothie"] = "1839423110", ["SwirledWax"] = "1839423111",
    ["SoftWax"] = "1839423112", ["HardWax"] = "1839423113", ["DebugWax"] = "1839423114",
    ["CausticWax"] = "1839423115", ["Snowflake"] = "1839423116", ["Turpentine"] = "1839423117",
    ["PinkBalloon"] = "8058046728", ["RedBalloon"] = "8083436979", ["WhiteBalloon"] = "8083436980",
    ["BlackBalloon"] = "8083436981", ["RoboPass"] = "4528127000", ["MoonCharm"] = "177912345",
    ["Present"] = "4528128000", ["NightBell"] = "4528129000", ["FestiveBean"] = "4528130000",
    ["MicroConverter"] = "1442784513", ["SmoothDice"] = "4528131000", ["AntPass"] = "1442784514",
    ["Box-O-Frogs"] = "4528640710", ["FieldDice"] = "4528132000", ["LoadedDice"] = "4528133000",
    ["HoneyBeePresent"] = "4528134000", ["ComfortingVial"] = "2000457502", ["InvigoratingVial"] = "2000457503",
    ["SatisfyingVial"] = "2000457504", ["MotivatingVial"] = "2000457505", ["RefreshingVial"] = "2000457506",
    ["NectarShowerVial"] = "2000457507", ["WhiteDrive"] = "4528124901", ["RedDrive"] = "4528125112",
    ["BlueDrive"] = "4528125334", ["GlitchedDrive"] = "4528126005", ["BrokenDrive"] = "4528126999"
}

--==================================================
-- CLEAN OLD GUI
--==================================================

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

--==================================================
-- DYNAMIC ID DATABASE (ReplicatedStorage)
--==================================================

local ItemDatabase = {}
for name, id in pairs(FallbackItems) do 
    ItemDatabase[name] = id 
end

local eggTypes = ReplicatedStorage:FindFirstChild("EggTypes")
if eggTypes then
    for _, obj in ipairs(eggTypes:GetChildren()) do
        for _, prop in ipairs({"ColorMap", "Texture", "Image"}) do
            local ok, val = pcall(function() 
                return obj[prop] 
            end)
            if ok and val and tostring(val) ~= "" then
                local id = tostring(val):match("%d+")
                if id then 
                    ItemDatabase[obj.Name] = id 
                    break 
                end
            end
        end
    end
end

--==================================================
-- GUI HELPERS
--==================================================

local function create(class, properties, parent)
    local instance = Instance.new(class)
    for property, value in pairs(properties) do
        instance[property] = value
    end
    instance.Parent = parent
    return instance
end

local function round(object, radius)
    create("UICorner", {
        CornerRadius = UDim.new(0, radius)
    }, object)
end

local function stroke(object, color, transparency)
    create("UIStroke", {
        Color = color,
        Transparency = transparency or 0,
        Thickness = 1
    }, object)
end

--==================================================
-- MAIN GUI
--==================================================

local ScreenGui = create("ScreenGui", {
    Name = "SproutCollectorGUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, PlayerGui)

local Main = create("Frame", {
    Size = UDim2.fromOffset(280, 420),
    Position = UDim2.new(0.5, -140, 0.5, -210),
    BackgroundColor3 = Color3.fromRGB(20, 23, 31),
    BorderSizePixel = 0
}, ScreenGui)

round(Main, 10)
stroke(Main, Color3.fromRGB(65, 75, 95))

--==================================================
-- HEADER
--==================================================

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
    Size = UDim2.new(1, -80, 1, 0),
    Position = UDim2.fromOffset(12, 0),
    BackgroundTransparency = 1,
    Text = "SPROUT COLLECTOR",
    TextColor3 = Color3.fromRGB(235, 240, 250),
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
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

--==================================================
-- TAB BAR
--==================================================

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

--==================================================
-- CONTENT & STATUS
--==================================================

local Content = create("Frame", {
    Size = UDim2.new(1, -16, 1, -76),
    Position = UDim2.fromOffset(8, 72),
    BackgroundTransparency = 1
}, Main)

local Status = create("TextButton", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = Color3.fromRGB(150, 45, 50),
    Text = "OFF",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 13,
    Font = Enum.Font.GothamBold
}, Content)

round(Status, 7)

--==================================================
-- SPEED SLIDER
--==================================================

local SpeedControl = create("Frame", {
    Size = UDim2.new(1, 0, 0, 22),
    Position = UDim2.fromOffset(0, 34),
    BackgroundTransparency = 1
}, Content)

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

--==================================================
-- ID PAGE (ITEMS LIST)
--==================================================

local IDPage = create("Frame", {
    Size = UDim2.new(1, 0, 1, -60),
    Position = UDim2.fromOffset(0, 60),
    BackgroundTransparency = 1,
    Visible = true
}, Content)

local SearchBar = create("TextBox", {
    Size = UDim2.new(1, 0, 0, 28),
    BackgroundColor3 = Color3.fromRGB(32, 38, 50),
    TextColor3 = Color3.fromRGB(240, 240, 240),
    PlaceholderColor3 = Color3.fromRGB(125, 135, 155),
    PlaceholderText = "Search item...",
    Text = "",
    TextSize = 11,
    Font = Enum.Font.Gotham,
    ClearTextOnFocus = false
}, IDPage)

round(SearchBar, 6)
stroke(SearchBar, Color3.fromRGB(55, 65, 82))

local List = create("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, -36),
    Position = UDim2.fromOffset(0, 36),
    BackgroundColor3 = Color3.fromRGB(27, 32, 42),
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y
}, IDPage)

round(List, 7)

create("UIListLayout", {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder
}, List)

create("UIPadding", {
    PaddingTop = UDim.new(0, 5),
    PaddingBottom = UDim.new(0, 5),
    PaddingLeft = UDim.new(0, 5),
    PaddingRight = UDim.new(0, 5)
}, List)

local Footer = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.new(0, 0, 1, -30),
    BackgroundTransparency = 1,
    Text = "Waiting...",
    TextColor3 = Color3.fromRGB(135, 150, 175),
    TextSize = 9,
    Font = Enum.Font.Gotham,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left
}, IDPage)

--==================================================
-- FIELDS PAGE
--==================================================

local FieldsPage = create("Frame", {
    Size = UDim2.new(1, 0, 1, -60),
    Position = UDim2.fromOffset(0, 60),
    BackgroundTransparency = 1,
    Visible = false
}, Content)

create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 20),
    Position = UDim2.fromOffset(0, 0),
    BackgroundTransparency = 1,
    Text = "FIELDS",
    TextColor3 = Color3.fromRGB(155, 170, 195),
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, FieldsPage)

local FieldsList = create("ScrollingFrame", {
    Size = UDim2.new(1, 0, 0, 140),
    Position = UDim2.fromOffset(0, 22),
    BackgroundColor3 = Color3.fromRGB(27, 32, 42),
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y
}, FieldsPage)

round(FieldsList, 7)

create("UIListLayout", {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder
}, FieldsList)

create("UIPadding", {
    PaddingTop = UDim.new(0, 5),
    PaddingBottom = UDim.new(0, 5),
    PaddingLeft = UDim.new(0, 5),
    PaddingRight = UDim.new(0, 5)
}, FieldsList)

local Purge = create("TextButton", {
    Size = UDim2.new(1, 0, 0, 26),
    Position = UDim2.fromOffset(0, 168),
    BackgroundColor3 = Color3.fromRGB(160, 60, 40),
    Text = "PURGE (local)",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 10,
    Font = Enum.Font.GothamBold
}, FieldsPage)

round(Purge, 5)

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

--==================================================
-- GUI DRAG
--==================================================

local dragging, dragInput, dragStart, startPosition

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
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
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

--==================================================
-- MINIMIZE
--==================================================

local minimized = false

Minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    Content.Visible = not minimized
    TabBar.Visible = not minimized
    if minimized then
        Main.Size = UDim2.fromOffset(280, 40)
        Minimize.Text = "+"
    else
        Main.Size = UDim2.fromOffset(280, 420)
        Minimize.Text = "−"
    end
    if saveConfig then saveConfig() end
end)

--==================================================
-- STATE
--==================================================

local SelectedNames = {}
local SelectedIDs = {}
local fieldSelection = {}

local function isFieldEnabled(name)
    local explicit = fieldSelection[name]
    if explicit ~= nil then return explicit end
    return not EXCLUDED_ZONES[name]
end

--==================================================
-- LOAD SAVED DATA
--==================================================

if type(isfile) == "function" and type(readfile) == "function" then
    if isfile(SAVE_FILE) then
        local ok, content = pcall(readfile, SAVE_FILE)
        if ok and type(content) == "string" and content ~= "" then
            local ok2, data = pcall(function()
                return HttpService:JSONDecode(content)
            end)
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
end

--==================================================
-- SAVE CONFIG
--==================================================

saveConfig = function()
    if type(writefile) ~= "function" then return end
    if type(makefolder) == "function" and type(isfolder) == "function" then
        pcall(function()
            if not isfolder(SAVE_FOLDER) then
                makefolder(SAVE_FOLDER)
            end
        end)
    end
    
    local itemsList = {}
    for name, _ in pairs(SelectedNames) do
        table.insert(itemsList, name)
    end

    local data = {
        items = itemsList,
        fields = fieldSelection,
        speed = FlySpeed,
        guiPosition = {
            xScale  = Main.Position.X.Scale,
            xOffset = Main.Position.X.Offset,
            yScale  = Main.Position.Y.Scale,
            yOffset = Main.Position.Y.Offset
        },
        minimized = minimized
    }
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    if ok then
        pcall(writefile, SAVE_FILE, encoded)
    end
end

--==================================================
-- SPEED SLIDER
--==================================================

refreshSpeedUI = function()
    local ratio = (FlySpeed - SPEED_MIN) / (SPEED_MAX - SPEED_MIN)
    SpeedFill.Size = UDim2.new(ratio, 0, 1, 0)
    SpeedHandle.Position = UDim2.new(ratio, -5, 0.5, -7)
    SpeedLabel.Text = "Fly speed: " .. FlySpeed .. " studs/s"
end

refreshSpeedUI()

local draggingSpeed = false

SpeedBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        draggingSpeed = true
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingSpeed and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local ratio = math.clamp((input.Position.X - SpeedBar.AbsolutePosition.X) / SpeedBar.AbsoluteSize.X, 0, 1)
        FlySpeed = math.floor(SPEED_MIN + ratio * (SPEED_MAX - SPEED_MIN) + 0.5)
        refreshSpeedUI()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        if draggingSpeed then
            draggingSpeed = false
            saveConfig()
        end
    end
end)

--==================================================
-- ITEMS LIST RENDERER
--==================================================

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
        
        local Row = create("Frame", {
            Size = UDim2.new(1, -2, 0, 26),
            BackgroundColor3 = Color3.fromRGB(37, 44, 57),
            BorderSizePixel = 0,
            LayoutOrder = i
        }, List)
        round(Row, 5)
        
        create("TextLabel", {
            Size = UDim2.new(1, -58, 1, 0),
            Position = UDim2.fromOffset(8, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = Color3.fromRGB(225, 232, 245),
            TextSize = 11,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd
        }, Row)
        
        local Toggle = create("TextButton", {
            Size = UDim2.fromOffset(48, 20),
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

SearchBar:GetPropertyChangedSignal("Text"):Connect(function()
    refreshItemsList()
end)

--==================================================
-- FIELDS LIST RENDERER
--==================================================

refreshFieldsList = function()
    for _, child in ipairs(FieldsList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local folder = Workspace:FindFirstChild("FlowerZones")
    if not folder then
        FieldsFooter.Text = "Workspace.FlowerZones not found."
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
            BorderSizePixel = 0,
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

--==================================================
-- TABS SWITCHING
--==================================================

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

--==================================================
-- BOUNDS & ZONES
--==================================================

local function getBounds(object)
    local cf, size
    if object:IsA("BasePart") then
        cf = object.CFrame
        size = object.Size
    elseif object:IsA("Model") then
        local success, boxCF, boxSize = pcall(function()
            return object:GetBoundingBox()
        end)
        if not success then return nil end
        cf = boxCF
        size = boxSize
    else
        return nil
    end

    local xExtent = math.abs(cf.RightVector.X)*size.X/2 + math.abs(cf.UpVector.X)*size.Y/2 + math.abs(cf.LookVector.X)*size.Z/2
    local zExtent = math.abs(cf.RightVector.Z)*size.X/2 + math.abs(cf.UpVector.Z)*size.Y/2 + math.abs(cf.LookVector.Z)*size.Z/2

    return { minX = cf.Position.X - xExtent, maxX = cf.Position.X + xExtent, minZ = cf.Position.Z - zExtent, maxZ = cf.Position.Z + zExtent }
end

local function getFlowerZones()
    local folder = Workspace:FindFirstChild("FlowerZones")
    local zones = {}
    if not folder then return zones end
    for _, zone in ipairs(folder:GetChildren()) do
        if isFieldEnabled(zone.Name) then
            local bounds = getBounds(zone)
            if bounds then table.insert(zones, bounds) end
        end
    end
    return zones
end

local function intersectsFlowerZone(object, zones)
    local objectBounds = getBounds(object)
    if not objectBounds then return false end
    for _, zone in ipairs(zones) do
        local overlapX = objectBounds.minX <= zone.maxX and objectBounds.maxX >= zone.minX
        local overlapZ = objectBounds.minZ <= zone.maxZ and objectBounds.maxZ >= zone.minZ
        if overlapX and overlapZ then return true end
    end
    return false
end

--==================================================
-- COLOR MAP ID
--==================================================

local function getColorMapID(object)
    local backDecal = object:FindFirstChild("BackDecal", true)
    if not backDecal then return nil end

    for _, prop in ipairs({"ColorMap", "Texture", "SoundId", "MeshId", "Image"}) do
        local ok, value = pcall(function()
            return backDecal[prop]
        end)
        if ok and value ~= nil then
            local id = tostring(value):match("%d+")
            if id then return id end
        end
    end
    return nil
end

--==================================================
-- FLY LOGIC
--==================================================

local function getTargetCFrame(object)
    if object:IsA("BasePart") then return object.CFrame end
    if object:IsA("Model") then
        if object.PrimaryPart then return object.PrimaryPart.CFrame end
        local ok, pivot = pcall(function() return object:GetPivot() end)
        if ok and pivot then return pivot end
    end
    for _, child in ipairs(object:GetDescendants()) do
        if child:IsA("BasePart") then return child.CFrame end
    end
    return nil
end

local function flyTo(character, root, targetCF, speed, cancelCheck)
    if not root or not root.Parent then return false end
    local startPos = root.CFrame.Position
    local endPos = targetCF.Position
    local distance = (endPos - startPos).Magnitude

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
        local pos = startPos:Lerp(endPos, alpha)
        local cf = CFrame.new(pos, endPos)

        pcall(function() root.CFrame = cf end)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero

        if alpha >= 1 then break end
        task.wait()
    end

    if success then
        pcall(function() root.CFrame = targetCF end)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end

    for part, val in pairs(collisionState) do
        if part.Parent then part.CanCollide = val end
    end

    return success
end

--==================================================
-- PURGE
--==================================================

purgeCollectibles = function()
    local folder = Workspace:FindFirstChild("Collectibles")
    if not folder then
        FieldsFooter.Text = "Workspace.Collectibles not found."
        return 0
    end
    local count = 0
    for _, child in ipairs(folder:GetChildren()) do
        pcall(function() child:Destroy() end)
        count = count + 1
    end
    FieldsFooter.Text = "Destroyed " .. count .. " locally."
    return count
end

Purge.MouseButton1Click:Connect(function()
    purgeCollectibles()
end)

--==================================================
-- SCANNER
--==================================================

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
    pcall(function() root.CFrame = HomePosition end)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
end

local function scanPass(token)
    local character = Player.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local zones = getFlowerZones()
    if not isRunning(token) then return end

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
                if intersectsFlowerZone(object, zones) then
                    local cf = getTargetCFrame(object)
                    if cf then table.insert(targets, {object = object, cf = cf}) end
                end
            end
        end
    end

    if #targets == 0 then
        Footer.Text = string.format("None | scan %d, id %d", scanned, matchedID)
        return
    end

    Footer.Text = "Flying to " .. #targets .. " target(s)..."

    for index, entry in ipairs(targets) do
        if not isRunning(token) then break end
        if Player.Character ~= character then break end
        if not root.Parent then break end
        if not entry.object.Parent then continue end

        Footer.Text = "Flying " .. index .. " / " .. #targets
        flyTo(character, root, entry.cf, FlySpeed, function()
            return isRunning(token)
        end)
        task.wait(HOVER_AT_TARGET)
    end

    if isRunning(token) and HomePosition then
        teleportHome()
    end

    if isRunning(token) then
        Footer.Text = "Returned home."
    end
end

--==================================================
-- ON / OFF
--==================================================

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
        local character = Player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root then HomePosition = root.CFrame end

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

--==================================================
-- INITIALIZE
--==================================================

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
        Main.Size = UDim2.fromOffset(280, 40)
        Minimize.Text = "+"
    end
end

refreshSpeedUI()
updateStatus()
refreshItemsList()

if PURGE_ON_START then
    purgeCollectibles()
end

Footer.Text = "Ready. Search and select items."
print("[Sprout Collector] Loaded. No abilities.")
