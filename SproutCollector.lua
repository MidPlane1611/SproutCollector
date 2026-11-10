--==================================================
-- SPR0UT COLLECTOR
-- GitHub-compatible client script
-- with persistent config saving
--==================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS
--==================================================

local SCAN_INTERVAL = 1
local TELEPORT_DELAY = 0.1

local EXCLUDED_ZONES = {
    ["Ant Field"] = true,
    ["Blue Brick Field"] = true,
    ["Hub Field"] = true,
    ["Mixed Brick Field"] = true,
    ["Red Brick Field"] = true,
    ["White Brick Field"] = true
}

--==================================================
-- CLEAN OLD GUI
--==================================================

local oldGui = PlayerGui:FindFirstChild("SproutCollectorGUI")

if oldGui then
    oldGui:Destroy()
end

--==================================================
-- PERSISTENCE (forward declarations)
--==================================================

local SAVE_FOLDER = "SproutCollector"
local SAVE_FILE = SAVE_FOLDER .. "/config.json"

local saveConfig
local loadedData

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
    Name = "Main",
    Size = UDim2.fromOffset(320, 390),
    Position = UDim2.new(0.5, -160, 0.5, -195),
    BackgroundColor3 = Color3.fromRGB(20, 23, 31),
    BorderSizePixel = 0
}, ScreenGui)

round(Main, 12)
stroke(Main, Color3.fromRGB(65, 75, 95))

--==================================================
-- HEADER
--==================================================

local Header = create("Frame", {
    Size = UDim2.new(1, 0, 0, 45),
    BackgroundColor3 = Color3.fromRGB(28, 33, 44),
    BorderSizePixel = 0
}, Main)

round(Header, 12)

local HeaderCover = create("Frame", {
    Size = UDim2.new(1, 0, 0, 12),
    Position = UDim2.new(0, 0, 1, -12),
    BackgroundColor3 = Header.BackgroundColor3,
    BorderSizePixel = 0
}, Header)

local Title = create("TextLabel", {
    Size = UDim2.new(1, -90, 1, 0),
    Position = UDim2.fromOffset(14, 0),
    BackgroundTransparency = 1,
    Text = "SPROUT COLLECTOR",
    TextColor3 = Color3.fromRGB(235, 240, 250),
    TextSize = 15,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, Header)

local Minimize = create("TextButton", {
    Size = UDim2.fromOffset(28, 28),
    Position = UDim2.new(1, -38, 0, 8),
    BackgroundColor3 = Color3.fromRGB(48, 57, 73),
    Text = "−",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 20,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = true
}, Header)

round(Minimize, 7)

--==================================================
-- CONTENT
--==================================================

local Content = create("Frame", {
    Size = UDim2.new(1, -24, 1, -57),
    Position = UDim2.fromOffset(12, 51),
    BackgroundTransparency = 1
}, Main)

--==================================================
-- STATUS BUTTON
--==================================================

local Status = create("TextButton", {
    Size = UDim2.new(1, 0, 0, 38),
    BackgroundColor3 = Color3.fromRGB(150, 45, 50),
    Text = "OFF",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 15,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false
}, Content)

round(Status, 8)

--==================================================
-- INPUT
--==================================================

local Input = create("TextBox", {
    Size = UDim2.new(1, -85, 0, 35),
    Position = UDim2.fromOffset(0, 50),
    BackgroundColor3 = Color3.fromRGB(32, 38, 50),
    TextColor3 = Color3.fromRGB(240, 240, 240),
    PlaceholderColor3 = Color3.fromRGB(125, 135, 155),
    PlaceholderText = "Enter asset ID...",
    Text = "",
    TextSize = 13,
    Font = Enum.Font.Gotham,
    ClearTextOnFocus = false
}, Content)

round(Input, 7)
stroke(Input, Color3.fromRGB(55, 65, 82))

local Add = create("TextButton", {
    Size = UDim2.new(0, 75, 0, 35),
    Position = UDim2.new(1, -75, 0, 50),
    BackgroundColor3 = Color3.fromRGB(65, 115, 210),
    Text = "ADD",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 13,
    Font = Enum.Font.GothamBold
}, Content)

round(Add, 7)

--==================================================
-- ID LIST HEADER
--==================================================

local ListHeader = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 25),
    Position = UDim2.fromOffset(0, 96),
    BackgroundTransparency = 1,
    Text = "SAVED IDS",
    TextColor3 = Color3.fromRGB(155, 170, 195),
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, Content)

local Counter = create("TextLabel", {
    Size = UDim2.fromOffset(65, 25),
    Position = UDim2.new(1, -65, 0, 96),
    BackgroundTransparency = 1,
    Text = "0 IDs",
    TextColor3 = Color3.fromRGB(110, 170, 255),
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Right
}, Content)

--==================================================
-- SCROLLING ID LIST
--==================================================

local List = create("ScrollingFrame", {
    Size = UDim2.new(1, 0, 0, 155),
    Position = UDim2.fromOffset(0, 122),
    BackgroundColor3 = Color3.fromRGB(27, 32, 42),
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Color3.fromRGB(100, 120, 155),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y
}, Content)

round(List, 8)

local ListLayout = create("UIListLayout", {
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder
}, List)

create("UIPadding", {
    PaddingTop = UDim.new(0, 6),
    PaddingBottom = UDim.new(0, 6),
    PaddingLeft = UDim.new(0, 6),
    PaddingRight = UDim.new(0, 6)
}, List)

--==================================================
-- FOOTER STATUS
--==================================================

local Footer = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 40),
    Position = UDim2.new(0, 0, 1, -40),
    BackgroundTransparency = 1,
    Text = "Waiting...",
    TextColor3 = Color3.fromRGB(135, 150, 175),
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left
}, Content)

--==================================================
-- GUI DRAG
--==================================================

local dragging = false
local dragInput
local dragStart
local startPosition

Header.InputBegan:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = Main.Position

        input.Changed:Connect(function()

            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                saveConfig()
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

    if minimized then
        Main.Size = UDim2.fromOffset(320, 45)
        Minimize.Text = "+"
    else
        Main.Size = UDim2.fromOffset(320, 390)
        Minimize.Text = "−"
    end

    saveConfig()

end)

--==================================================
-- SAVED IDS
--==================================================

local SavedIDs = {}
local IDOrder = {}

local function normalizeID(id)

    id = tostring(id):gsub("^0+", "")

    if id == "" then
        return "0"
    end

    return id

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

if loadedData and type(loadedData.ids) == "table" then
    for _, rawID in ipairs(loadedData.ids) do
        local id = normalizeID(rawID)
        if id ~= "0" and not SavedIDs[id] then
            SavedIDs[id] = true
            table.insert(IDOrder, id)
        end
    end
end

saveConfig = function()
    if type(writefile) ~= "function" then
        return
    end

    if type(makefolder) == "function" and type(isfolder) == "function" then
        pcall(function()
            if not isfolder(SAVE_FOLDER) then
                makefolder(SAVE_FOLDER)
            end
        end)
    end

    local data = {
        ids = IDOrder,
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

local function updateCounter()

    Counter.Text = tostring(#IDOrder) .. " IDs"

end

local function refreshList()

    for _, child in ipairs(List:GetChildren()) do

        if child:IsA("Frame") then
            child:Destroy()
        end

    end

    for index, id in ipairs(IDOrder) do

        local Row = create("Frame", {
            Size = UDim2.new(1, -2, 0, 32),
            BackgroundColor3 = Color3.fromRGB(37, 44, 57),
            BorderSizePixel = 0,
            LayoutOrder = index
        }, List)

        round(Row, 6)

        create("TextLabel", {
            Size = UDim2.new(1, -48, 1, 0),
            Position = UDim2.fromOffset(9, 0),
            BackgroundTransparency = 1,
            Text = id,
            TextColor3 = Color3.fromRGB(225, 232, 245),
            TextSize = 12,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left
        }, Row)

        local Remove = create("TextButton", {
            Size = UDim2.fromOffset(28, 25),
            Position = UDim2.new(1, -32, 0.5, -12),
            BackgroundColor3 = Color3.fromRGB(145, 48, 55),
            Text = "X",
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 11,
            Font = Enum.Font.GothamBold
        }, Row)

        round(Remove, 5)

        Remove.MouseButton1Click:Connect(function()

            SavedIDs[id] = nil

            for i, savedID in ipairs(IDOrder) do

                if savedID == id then
                    table.remove(IDOrder, i)
                    break
                end

            end

            refreshList()
            saveConfig()

        end)

    end

    updateCounter()

end

-- Numbers only

Input:GetPropertyChangedSignal("Text"):Connect(function()

    local filtered = Input.Text:gsub("%D", "")

    if Input.Text ~= filtered then
        Input.Text = filtered
    end

end)

-- Add ID

Add.MouseButton1Click:Connect(function()

    local id = normalizeID(Input.Text)

    if id == "" or id == "0" then
        Footer.Text = "Enter a valid ID."
        return
    end

    if SavedIDs[id] then
        Footer.Text = "This ID already exists."
        return
    end

    SavedIDs[id] = true

    table.insert(IDOrder, id)

    Input.Text = ""

    refreshList()
    saveConfig()

    Footer.Text = "ID added successfully."

end)

--==================================================
-- OBJECT BOUNDS
--==================================================

local function getBounds(object)

    local cf
    local size

    if object:IsA("BasePart") then

        cf = object.CFrame
        size = object.Size

    elseif object:IsA("Model") then

        local success, boxCF, boxSize = pcall(function()
            return object:GetBoundingBox()
        end)

        if not success then
            return nil
        end

        cf = boxCF
        size = boxSize

    else
        return nil
    end

    local xExtent =
        math.abs(cf.RightVector.X) * size.X / 2 +
        math.abs(cf.UpVector.X) * size.Y / 2 +
        math.abs(cf.LookVector.X) * size.Z / 2

    local zExtent =
        math.abs(cf.RightVector.Z) * size.X / 2 +
        math.abs(cf.UpVector.Z) * size.Y / 2 +
        math.abs(cf.LookVector.Z) * size.Z / 2

    return {
        minX = cf.Position.X - xExtent,
        maxX = cf.Position.X + xExtent,
        minZ = cf.Position.Z - zExtent,
        maxZ = cf.Position.Z + zExtent
    }

end

--==================================================
-- FLOWER ZONES
--==================================================

local function getFlowerZones()

    local folder = Workspace:FindFirstChild("FlowerZones")
    local zones = {}

    if not folder then
        return zones
    end

    for _, zone in ipairs(folder:GetChildren()) do

        if not EXCLUDED_ZONES[zone.Name] then

            local bounds = getBounds(zone)

            if bounds then
                table.insert(zones, bounds)
            end

        end

    end

    return zones

end

--==================================================
-- INTERSECTION
--==================================================

local function intersectsFlowerZone(object, zones)

    local objectBounds = getBounds(object)

    if not objectBounds then
        return false
    end

    for _, zone in ipairs(zones) do

        local overlapX =
            objectBounds.minX <= zone.maxX and
            objectBounds.maxX >= zone.minX

        local overlapZ =
            objectBounds.minZ <= zone.maxZ and
            objectBounds.maxZ >= zone.minZ

        if overlapX and overlapZ then
            return true
        end

    end

    return false

end

--==================================================
-- COLOR MAP ID
--==================================================

local function getColorMapID(object)

    local backDecal = object:FindFirstChild("BackDecal")

    if not backDecal then
        return nil
    end

    local success, colorMap = pcall(function()
        return tostring(backDecal.ColorMap)
    end)

    if not success then
        return nil
    end

    local id = colorMap:match("%d+")

    if id then
        return normalizeID(id)
    end

    return nil

end

--==================================================
-- TELEPORT HELPERS
--==================================================

local function getTargetCFrame(object)

    if object:IsA("BasePart") then
        return object.CFrame
    end

    if object:IsA("Model") then
        return object:GetPivot()
    end

    return nil

end

local function teleportTo(root, object)

    if not root or not root.Parent then
        return false
    end

    if not object or not object.Parent then
        return false
    end

    local target = getTargetCFrame(object)

    if not target then
        return false
    end

    root.CFrame = target

    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    return true

end

--==================================================
-- SCANNER
--==================================================

local Enabled = false
local RunToken = 0
local ActiveCycle = nil

local function isRunning(token)

    return Enabled and RunToken == token

end

local function restorePosition(cycle)

    if not cycle or cycle.restored then
        return
    end

    cycle.restored = true

    local root = cycle.root

    if root and root.Parent then

        root.CFrame = cycle.origin

        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero

    end

    if ActiveCycle == cycle then
        ActiveCycle = nil
    end

end

local function scanPass(token)

    local character = Player.Character

    if not character then
        return
    end

    local root = character:FindFirstChild("HumanoidRootPart")

    if not root then
        return
    end

    local zones = getFlowerZones()

    if not isRunning(token) then
        return
    end

    local cycle = {
        root = root,
        origin = root.CFrame,
        restored = false
    }

    ActiveCycle = cycle

    local collectiblesFolder =
        Workspace:FindFirstChild("Collectibles")

    local objects = {}

    if collectiblesFolder then
        objects = collectiblesFolder:GetChildren()
    end

    local targets = {}

    for _, object in ipairs(objects) do

        if not isRunning(token) then
            break
        end

        if object.Name == "C" then

            local id = getColorMapID(object)

            if id and SavedIDs[id] then

                if intersectsFlowerZone(object, zones) then
                    table.insert(targets, object)
                end

            end

        end

    end

    Footer.Text = "Found " .. tostring(#targets) .. " matching Sprouts."

    for index, object in ipairs(targets) do

        if not isRunning(token) then
            break
        end

        if Player.Character ~= character then
            break
        end

        if not root.Parent then
            break
        end

        if teleportTo(root, object) then

            Footer.Text =
                "Visiting Sprout " ..
                tostring(index) ..
                " / " ..
                tostring(#targets)

            task.wait(TELEPORT_DELAY)

        end

    end

    restorePosition(cycle)

    if isRunning(token) then
        Footer.Text = "Waiting for next scan..."
    end

end

--==================================================
-- ON / OFF
--==================================================

local function updateStatus()

    if Enabled then

        Status.Text = "●  COLLECTOR ACTIVE"

        Status.BackgroundColor3 =
            Color3.fromRGB(35, 145, 85)

    else

        Status.Text = "●  COLLECTOR OFF"

        Status.BackgroundColor3 =
            Color3.fromRGB(150, 45, 50)

    end

end

Status.MouseButton1Click:Connect(function()

    Enabled = not Enabled

    RunToken += 1

    updateStatus()

    if Enabled then

        local token = RunToken

        Footer.Text = "Starting scanner..."

        task.spawn(function()

            while isRunning(token) do

                local started = os.clock()

                local success, errorMessage =
                    pcall(scanPass, token)

                if not success then

                    warn("[Sprout Collector]", errorMessage)

                    restorePosition(ActiveCycle)

                    Footer.Text = "Scanner error. Check console."

                end

                local remaining =
                    SCAN_INTERVAL - (os.clock() - started)

                if remaining > 0 and isRunning(token) then
                    task.wait(remaining)
                end

            end

        end)

    else

        restorePosition(ActiveCycle)

        Footer.Text = "Collector stopped."

    end

end)

--==================================================
-- RESTORE GUI STATE
--==================================================

if loadedData then

    if type(loadedData.guiPosition) == "table" then
        local p = loadedData.guiPosition
        if type(p.xScale) == "number"
            and type(p.xOffset) == "number"
            and type(p.yScale) == "number"
            and type(p.yOffset) == "number" then
            Main.Position = UDim2.new(p.xScale, p.xOffset, p.yScale, p.yOffset)
        end
    end

    if loadedData.minimized == true then
        minimized = true
        Content.Visible = false
        Main.Size = UDim2.fromOffset(320, 45)
        Minimize.Text = "+"
    end

end

--==================================================
-- INITIALIZE
--==================================================

updateStatus()
refreshList()

if #IDOrder > 0 then
    Footer.Text = "Loaded " .. tostring(#IDOrder) .. " saved ID(s)."
else
    Footer.Text = "Ready. Add Sprout IDs to begin."
end

print("[Sprout Collector] GUI loaded successfully.")
