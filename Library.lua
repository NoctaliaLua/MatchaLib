local cloneref = (cloneref or clonereference or function(instance: any)
	return instance
end)
local InputService: UserInputService = cloneref(game:GetService("UserInputService"))
local TextService: TextService = cloneref(game:GetService("TextService"))
local CoreGui: CoreGui = cloneref(game:GetService("CoreGui"))
local Teams: Teams = cloneref(game:GetService("Teams"))
local Players: Players = cloneref(game:GetService("Players"))
local RunService: RunService = cloneref(game:GetService("RunService"))
local TweenService: TweenService = cloneref(game:GetService("TweenService"))
local Lighting: Lighting = cloneref(game:GetService("Lighting"))
local SoundService: SoundService = cloneref(game:GetService("SoundService"))

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse = cloneref(LocalPlayer:GetMouse())

local DrawingLib = { drawing_replaced = true, new = function(...) error("Drawing is not supported.") end }
local IsBadDrawingLib = false

if typeof(getgenv) == "function" and typeof(getgenv().Drawing) == "table" then
    DrawingLib = getgenv().Drawing
end

local setclipboard = setclipboard or nil
local getgenv = getgenv or function()
	return shared
end
local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end
local GetHUI = gethui or function()
	return CoreGui
end

local assert = function(condition, errorMessage)
	if not condition then
		error(if errorMessage then errorMessage else "assert failed", 3)
	end
end

local function SafeParentUI(Instance: Instance, Parent: Instance | () -> Instance)
	local success, _error = pcall(function()
		if not Parent then
			Parent = CoreGui
		end

		local DestinationParent
		if typeof(Parent) == "function" then
			DestinationParent = Parent()
		else
			DestinationParent = Parent
		end

		Instance.Parent = DestinationParent
	end)

	if not (success and Instance.Parent) then
		Instance.Parent = LocalPlayer:WaitForChild("PlayerGui", math.huge)
	end
end

local function ParentUI(UI: Instance, SkipHiddenUI: boolean?)
	if SkipHiddenUI then
		SafeParentUI(UI, CoreGui)
		return
	end

	pcall(ProtectGui, UI)
	SafeParentUI(UI, GetHUI)
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.DisplayOrder = 999
ScreenGui.ResetOnSpawn = false
ParentUI(ScreenGui)

local ModalElement = Instance.new("TextButton")
ModalElement.BackgroundTransparency = 1
ModalElement.Modal = false
ModalElement.Size = UDim2.fromScale(0, 0)
ModalElement.AnchorPoint = Vector2.zero
ModalElement.Text = ""
ModalElement.ZIndex = -999
ModalElement.Parent = ScreenGui

local LibraryMainOuterFrame = nil
local LibraryMainInnerFrame = nil

local Toggles = {}
local Options = {}
local Labels = {}
local Buttons = {}
local Tooltips = {}
local Dialogues = {}

-- https://github.com/deividcomsono/Obsidian/blob/main/Library.lua#L30
local BaseURL = "https://raw.githubusercontent.com/NoctaliaLua/NoctaliaLib/refs/heads/main/"
local CustomImageManager = {}
local CustomImageManagerAssets = {
    Cursor = {
        RobloxId = 9619665977,
        Path = "NoctaliaLib/assets/Cursor.png",
        URL = BaseURL .. "assets/Cursor.png",

        Id = nil,
    },

    DropdownArrow = {
        RobloxId = 6282522798,
        Path = "NoctaliaLib/assets/DropdownArrow.png",
        URL = BaseURL .. "assets/DropdownArrow.png",

        Id = nil,
    },

    Checker = {
        RobloxId = 12977615774,
        Path = "NoctaliaLib/assets/Checker.png",
        URL = BaseURL .. "assets/Checker.png",

        Id = nil,
    },

    CheckerLong = {
        RobloxId = 12978095818,
        Path = "NoctaliaLib/assets/CheckerLong.png",
        URL = BaseURL .. "assets/CheckerLong.png",

        Id = nil,
    },

    SaturationMap = {
        RobloxId = 4155801252,
        Path = "NoctaliaLib/assets/SaturationMap.png",
        URL = BaseURL .. "assets/SaturationMap.png",

        Id = nil,
    }
}
do
    local function RecursiveCreatePath(Path: string, IsFile: boolean?)
        if not isfolder or not makefolder then
            return
        end

        local Segments = Path:split("/")
        local TraversedPath = ""

        if IsFile then
            table.remove(Segments, #Segments)
        end

        for _, Segment in ipairs(Segments) do
            if not isfolder(TraversedPath .. Segment) then
                makefolder(TraversedPath .. Segment)
            end

            TraversedPath = TraversedPath .. Segment .. "/"
        end

        return TraversedPath
    end

    function CustomImageManager.AddAsset(AssetName: string, RobloxAssetId: number, URL: string, ForceRedownload: boolean?)
        if CustomImageManagerAssets[AssetName] ~= nil then
            error(string.format("Asset %q already exists", AssetName))
        end

        assert(typeof(RobloxAssetId) == "number", "RobloxAssetId must be a number")

        CustomImageManagerAssets[AssetName] = {
            RobloxId = RobloxAssetId,
            Path = string.format("Obsidian/custom_assets/%s", AssetName),
            URL = URL,

            Id = nil,
        }

        CustomImageManager.DownloadAsset(AssetName, ForceRedownload)
    end

    function CustomImageManager.GetAsset(AssetName: string)
        if not CustomImageManagerAssets[AssetName] then
            return nil
        end

        local AssetData = CustomImageManagerAssets[AssetName]
        if AssetData.Id then
            return AssetData.Id
        end

        local AssetID = string.format("rbxassetid://%s", AssetData.RobloxId)

        if getcustomasset then
            local Success, NewID = pcall(getcustomasset, AssetData.Path)

            if Success and NewID then
                AssetID = NewID
            end
        end

        AssetData.Id = AssetID
        return AssetID
    end

    function CustomImageManager.DownloadAsset(AssetName: string, ForceRedownload: boolean?)
        if not getcustomasset or not writefile or not isfile then
            return false, "missing functions"
        end

        local AssetData = CustomImageManagerAssets[AssetName]

        RecursiveCreatePath(AssetData.Path, true)

        if ForceRedownload ~= true and isfile(AssetData.Path) then
            return true, nil
        end

        local success, errorMessage = pcall(function()
            writefile(AssetData.Path, game:HttpGet(AssetData.URL))
        end)

        return success, errorMessage
    end

    for AssetName, _ in CustomImageManagerAssets do
        CustomImageManager.DownloadAsset(AssetName)
    end
end

local DPIScale = 1;
local Library = {
    Registry = {};
    RegistryMap = {};
    HudRegistry = {};

    -- colors and font --
    FontColor = Color3.fromRGB(240, 240, 244);
    MainColor = Color3.fromRGB(22, 22, 27);
    BackgroundColor = Color3.fromRGB(12, 12, 16);

    AccentColor = Color3.fromRGB(205, 205, 214);
    DisabledAccentColor = Color3.fromRGB(95, 95, 104);

    OutlineColor = Color3.fromRGB(36, 36, 43);
    DisabledOutlineColor = Color3.fromRGB(30, 30, 36);

    DisabledTextColor = Color3.fromRGB(95, 95, 104);

    RiskColor = Color3.fromRGB(255, 70, 70);
    OnlineColor = Color3.fromRGB(64, 200, 110);

    Black = Color3.new(0, 0, 0);
    Font = Enum.Font.Gotham;

    -- panel style --
    GlassTransparency = 0.04;
    ElementTransparency = 0;
    GroupboxTransparency = 0;
    BlurEnabled = false;
    BlurSize = 30;
    WindowClosedScale = 0.5;
    KeybindNotification = false;

    -- sounds --
    InterfaceSoundId = "rbxassetid://139658322785649";
    InterfaceSoundVolume = 1;
    UISound = true;
    KeybindSound = false;

    -- frames --
    OpenedFrames = {};
    DependencyBoxes = {};
    DependencyGroupboxes = {};

    -- signals --
    UnloadSignals = {};
    Signals = {};

    -- gui --
    ActiveTab = nil;
    TotalTabs = 0;

    ScreenGui = ScreenGui;
    KeybindFrame = nil;
    KeybindContainer = nil;
    Window = { Holder = nil; Tabs = {}; };

    -- variables --
    VideoLink = "";
    
    Toggled = false;
    ToggleKeybind = nil;

    IsMobile = false;
    DevicePlatform = Enum.Platform.None;

    CanDrag = true;
    CantDragForced = false;

    Unloaded = false;

    -- notification --
    Notify = nil;
    NotifySide = "Left";
    ShowCustomCursor = true;
    ShowToggleFrameInKeybinds = true;
    NotifyOnError = false; -- true = Library:Notify for SafeCallback (still warns in the developer console)

    -- addons --
    SaveManager = nil;
    ThemeManager = nil;

    -- for better usage --
    Toggles = Toggles;
    Options = Options;
    Labels = Labels;
    Buttons = Buttons;
    Dialogues = Dialogues;
    ActiveDialog = nil;

    ImageManager = CustomImageManager;
    ShowCursorBinding = string.sub(tostring({}), 10);
}

if RunService:IsStudio() then
   Library.IsMobile = InputService.TouchEnabled and not InputService.MouseEnabled 
else
    pcall(function() Library.DevicePlatform = InputService:GetPlatform() end) -- For safety so the UI library doesn't error.
    Library.IsMobile = (Library.DevicePlatform == Enum.Platform.Android or Library.DevicePlatform == Enum.Platform.IOS)
end

Library.MinSize = if Library.IsMobile then Vector2.new(550, 200) else Vector2.new(550, 300)

--// Functions \\--
local function ApplyDPIScale(Position)
    return UDim2.new(Position.X.Scale, Position.X.Offset * DPIScale, Position.Y.Scale, Position.Y.Offset * DPIScale)
end

local function ApplyTextScale(TextSize)
    return TextSize * DPIScale
end

local function GetTableSize(t)
    local n = 0
    for _, _ in pairs(t) do
        n = n + 1
    end
    return n
end

local function GetPlayers(ExcludeLocalPlayer, ReturnInstances)
    local PlayerList = Players:GetPlayers()

    if ExcludeLocalPlayer then
        local Idx = table.find(PlayerList, LocalPlayer)

        if Idx then
            table.remove(PlayerList, Idx)
        end
    end

    table.sort(PlayerList, function(Player1, Player2)
        return Player1.Name:lower() < Player2.Name:lower()
    end)

    if ReturnInstances == true then
        return PlayerList
    end

    local FixedPlayerList = {}
    for _, player in next, PlayerList do
        FixedPlayerList[#FixedPlayerList + 1] = player.Name
    end

    return FixedPlayerList
end

local function GetTeams(ReturnInstances)
    local TeamList = Teams:GetTeams()

    table.sort(TeamList, function(Team1, Team2)
        return Team1.Name:lower() < Team2.Name:lower()
    end)

    if ReturnInstances == true then
        return TeamList
    end

    local FixedTeamList = {}
    for _, team in next, TeamList do
        FixedTeamList[#FixedTeamList + 1] = team.Name
    end

    return FixedTeamList
end

local function Trim(Text: string)
    return Text:match("^%s*(.-)%s*$")
end

--// Icon Module \\--
type Icon = {
    Url: string,
    Id: number,
    IconName: string,
    ImageRectOffset: Vector2,
    ImageRectSize: Vector2,
}

type IconModule = {
    Icons: { string },
    GetAsset: (Name: string) -> Icon?,
}

local FetchIcons, Icons = pcall(function()
    return (loadstring(
        game:HttpGet("https://raw.githubusercontent.com/NoctaliaLua/lucide-roblox-direct/refs/heads/main/source.lua")
    ) :: () -> IconModule)()
end)

function IsValidCustomIcon(Icon: string)
    return typeof(Icon) == "string"
        and (Icon:match("rbxasset") or Icon:match("roblox%.com/asset/%?id=") or Icon:match("rbxthumb://type="))
end

function Library:GetIcon(IconName: string)
    if not FetchIcons or not Icons then
        return
    end

    local Success, Icon = pcall(Icons.GetAsset, IconName)
    if not Success then
        return
    end

    return Icon
end

function Library:GetCustomIcon(IconName: string)
    if not IsValidCustomIcon(IconName) then
        return Library:GetIcon(IconName)
    else
        return {
            Url = IconName,
            ImageRectOffset = Vector2.zero,
            ImageRectSize = Vector2.zero,
            Custom = true,
        }
    end
end

function Library:SetIconModule(module: IconModule)
    FetchIcons = true
    Icons = module
end

function Library:GetBetterColor(Color: Color3, Add: number): Color3
    Add = Add * 2
    return Color3.fromRGB(
        math.clamp(Color.R * 255 + Add, 0, 255),
        math.clamp(Color.G * 255 + Add, 0, 255),
        math.clamp(Color.B * 255 + Add, 0, 255)
    )
end

--// Library Functions \\--
function Library:Validate(Table: { [string]: any }, Template: { [string]: any }): { [string]: any }
    if typeof(Table) ~= "table" then
        return Template
    end

    for k, v in pairs(Template) do
        if typeof(k) == "number" then
            continue
        end

        if typeof(v) == "table" then
            Table[k] = Library:Validate(Table[k], v)
        elseif Table[k] == nil then
            Table[k] = v
        end
    end

    return Table
end

function Library:SetDPIScale(value: number) 
    assert(type(value) == "number", "Expected type number for DPI scale but got " .. typeof(value))
    
    DPIScale = value / 100
    Library.MinSize = (if Library.IsMobile then Vector2.new(550, 200) else Vector2.new(550, 300)) * DPIScale
end

function Library:SafeCallback(Func, ...)
    -- https://github.com/deividcomsono/Obsidian/blob/main/Library.lua#L1100
    if not (Func and typeof(Func) == "function") then
        return
    end

    local Result = table.pack(xpcall(Func, function(Error)
        task.defer(error, debug.traceback(Error, 2))
        if Library.NotifyOnError then
            Library:Notify(Error)
        end

        return Error
    end, ...))

    if not Result[1] then
        return nil
    end

    return table.unpack(Result, 2, Result.n)
end

function Library:AttemptSave()
    if (not Library.SaveManager) then return end
    Library.SaveManager:Save()
end

function Library:Create(Class, Properties)
    local _Instance = Class

    if typeof(Class) == "string" then
        _Instance = Instance.new(Class)

        if _Instance:IsA("GuiObject") then
            _Instance.BorderSizePixel = 0
        end

        -- frames that only act as a structural shell (black / unpainted) stay invisible
        if Class == "Frame" and Properties.BackgroundTransparency == nil and (Properties.BackgroundColor3 == nil or Properties.BackgroundColor3 == Library.Black) then
            _Instance.BackgroundTransparency = 1
        end
    end

    for Property, Value in next, Properties do
        if Property == "Corner" then
            Library:AddCorner(_Instance, Value)
            continue
        elseif Property == "BorderSizePixel" or Property == "TextStrokeTransparency" then
            continue
        end

        if (Property == "Size" or Property == "Position") then
            Value = ApplyDPIScale(Value)
        elseif Property == "TextSize" then
            Value = ApplyTextScale(Value)
        end

        local success, err = pcall(function()
            _Instance[Property] = Value
        end)

        if (not success) then
            warn(err)
        end
    end

    return _Instance
end

function Library:AddCorner(Instance, Radius)
    return Library:Create("UICorner", {
        CornerRadius = UDim.new(0, Radius);
        Parent = Instance;
    })
end

-- 1px border; the color follows a library color so themes recolor it
function Library:AddStroke(Instance, ColorIdx, Transparency)
    local Stroke = Library:Create("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
        Color = Library[ColorIdx or "OutlineColor"];
        Thickness = 1;
        Transparency = Transparency or 0;
        Parent = Instance;
    })

    Library:AddToRegistry(Stroke, {
        Color = ColorIdx or "OutlineColor";
    })

    return Stroke
end

-- slightly lighter than the window, used for the cards the groupboxes sit on
function Library:GetCardColor()
    return Library.BackgroundColor:Lerp(Library.MainColor, 0.4)
end

-- secondary text: the font color pulled toward the background
function Library:GetDimColor()
    return Library.FontColor:Lerp(Library.BackgroundColor, 0.42)
end

function Library:DimLabel(Label)
    Library:RemoveFromRegistry(Label)
    Label.TextColor3 = Library:GetDimColor()
    Library:AddToRegistry(Label, {
        TextColor3 = function()
            return Library:GetDimColor()
        end;
    })

    return Label
end

function Library:PlayInterfaceSound()
    pcall(function()
        local Sound = Instance.new("Sound")
        Sound.SoundId = Library.InterfaceSoundId
        Sound.Volume = Library.InterfaceSoundVolume
        Sound.Parent = SoundService

        Sound.Ended:Once(function()
            Sound:Destroy()
        end)
        task.delay(10, Sound.Destroy, Sound)

        Sound:Play()
    end)
end

function Library:PlayKeybindSound()
    if Library.KeybindSound and not Library.Unloaded then
        Library:PlayInterfaceSound()
    end
end

local FadeCache = setmetatable({}, { __mode = "k" })
local FadeTweens = setmetatable({}, { __mode = "k" })

local function GetFadeProps(Inst)
    local Props = {}

    if Inst:IsA("UIStroke") then
        table.insert(Props, "Transparency")
    elseif Inst:IsA("GuiObject") then
        table.insert(Props, "BackgroundTransparency")

        if Inst:IsA("TextLabel") or Inst:IsA("TextButton") or Inst:IsA("TextBox") then
            table.insert(Props, "TextTransparency")
        elseif Inst:IsA("ImageLabel") or Inst:IsA("ImageButton") then
            table.insert(Props, "ImageTransparency")
        elseif Inst:IsA("ScrollingFrame") then
            table.insert(Props, "ScrollBarImageTransparency")
        end
    end

    return Props
end

local function FadeInstances(Root)
    local List = Root:GetDescendants()
    table.insert(List, Root)
    return List
end

-- remembers the current transparency of every object under Root so it can be faded and restored
function Library:CaptureFade(Root)
    for _, Inst in next, FadeInstances(Root) do
        local Cache = FadeCache[Inst] or {}
        FadeCache[Inst] = Cache

        for _, Prop in next, GetFadeProps(Inst) do
            Cache[Prop] = Inst[Prop]
        end
    end
end

-- Alpha 1 = fully visible, 0 = fully faded. Every object under Root is faded, not just Root.
function Library:SetFade(Root, Alpha, Info)
    for _, Inst in next, FadeInstances(Root) do
        local Cache = FadeCache[Inst] or {}
        FadeCache[Inst] = Cache

        local Active = FadeTweens[Inst]
        if Active then
            for _, ActiveTween in next, Active do
                ActiveTween:Cancel()
            end
            FadeTweens[Inst] = nil
        end

        local Goals = {}
        local Has = false

        for _, Prop in next, GetFadeProps(Inst) do
            if Cache[Prop] == nil then
                Cache[Prop] = Inst[Prop]
            end

            if Cache[Prop] < 1 then
                Goals[Prop] = 1 - (1 - Cache[Prop]) * Alpha
                Has = true
            end
        end

        if Has then
            if Info then
                local FadeTween = TweenService:Create(Inst, Info, Goals)
                FadeTweens[Inst] = { FadeTween }
                FadeTween:Play()
            else
                for Prop, Goal in next, Goals do
                    Inst[Prop] = Goal
                end
            end
        end
    end
end

function Library:TweenColor(Inst, Color, Time)
    TweenService:Create(Inst, TweenInfo.new(Time or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = Color }):Play()
end

-- quick accent flash used when a button is clicked
function Library:FlashButton(Inner)
    if not Inner or not Inner.Parent then
        return
    end

    TweenService:Create(Inner, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = Library.AccentColor }):Play()

    task.delay(0.08, function()
        if not Inner.Parent then
            return
        end

        local Back = Inner:GetAttribute("HoverColor") or Library:GetRegistryColor(Inner, "BackgroundColor3")
        TweenService:Create(Inner, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = Back }):Play()
    end)
end

-- turns every glass panel solid (or back) and keeps the fade cache in sync
function Library:SetTransparency(Enabled)
    Library.TransparencyEnabled = Enabled

    local Glass = 0.04

    Library.GlassTransparency = Enabled and Glass or 0
    Library.ElementTransparency = 0
    Library.GroupboxTransparency = 0

    for _, Inst in next, ScreenGui:GetDescendants() do
        if not Inst:IsA("GuiObject") then
            continue
        end

        local Current = Inst.BackgroundTransparency
        local Saved = Inst:GetAttribute("GlassOriginal")

        if not Enabled and not Saved and math.abs(Current - Glass) < 0.005 then
            Inst:SetAttribute("GlassOriginal", Current)
            Inst.BackgroundTransparency = 0

            if FadeCache[Inst] then
                FadeCache[Inst].BackgroundTransparency = 0
            end
        elseif Enabled and Saved then
            Inst:SetAttribute("GlassOriginal", nil)
            Inst.BackgroundTransparency = Saved

            if FadeCache[Inst] then
                FadeCache[Inst].BackgroundTransparency = Saved
            end
        end
    end
end

function Library:PreloadFont()    pcall(function()
        local Probe = Instance.new("TextLabel")
        Probe.Font = Library.Font
        Probe.Text = "AaBbCc 0123456789 []<>"
        Probe.TextSize = 14
        game:GetService("ContentProvider"):PreloadAsync({ Probe })
        Probe:Destroy()
    end)
end

function Library:SetBlur(Enabled)
    Library.BlurEnabled = Enabled

    if Library.Blur and Library.Toggled then
        Library.Blur.Enabled = true
        TweenService:Create(Library.Blur, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = Enabled and Library.BlurSize or 0 }):Play()
    end
end

function Library:NotifyKeybind(KeyPicker, Name, State)
    if not Library.KeybindNotification or Library.Unloaded or KeyPicker == Library.ToggleKeybind then
        return
    end

    Library:Notify(string.format("[%s] %s: %s", tostring(KeyPicker.DisplayValue), tostring(Name), State), 2)
end

function Library:CreateLabel(Properties, IsHud)
    local _Instance = Library:Create("TextLabel", {
        BackgroundTransparency = 1;
        Font = Library.Font;
        TextColor3 = Library.FontColor;
        TextSize = 16;
    })

    Library:AddToRegistry(_Instance, {
        TextColor3 = "FontColor";
    }, IsHud)

    return Library:Create(_Instance, Properties)
end

-- the window trails the cursor slightly instead of snapping to it
local function SmoothDrag(Target, ObjPos)
    local function GetGoal()
        return Vector2.new(
            Mouse.X - ObjPos.X + (Target.Size.X.Offset * Target.AnchorPoint.X),
            Mouse.Y - ObjPos.Y + (Target.Size.Y.Offset * Target.AnchorPoint.Y)
        )
    end

    local Goal = GetGoal()
    local Current = Goal
    local Delta = 0.016

    while true do
        local Pressed = InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        if Pressed then
            Goal = GetGoal()
        elseif (Goal - Current).Magnitude < 0.5 then
            break
        end

        Current = Current:Lerp(Goal, 1 - math.exp(-(tonumber(Delta) or 0.016) * 22))
        Target.Position = UDim2.new(0, Current.X, 0, Current.Y)

        Delta = RunService.RenderStepped:Wait()
    end

    Target.Position = UDim2.new(0, Goal.X, 0, Goal.Y)
end

function Library:MakeDraggable(Instance, Cutoff, IsMainWindow)
    Instance.Active = true

    if Library.IsMobile == false then
        Instance.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                if IsMainWindow == true and Library.CantDragForced == true then
                    return
                end
           
                local ObjPos = Vector2.new(
                    Mouse.X - Instance.AbsolutePosition.X,
                    Mouse.Y - Instance.AbsolutePosition.Y
                )

                if ObjPos.Y > (Cutoff or 40) then
                    return
                end

                SmoothDrag(Instance, ObjPos)
            end
        end)
    else
        local Dragging, DraggingInput, DraggingStart, StartPosition

        InputService.TouchStarted:Connect(function(Input)
            if IsMainWindow == true and Library.CantDragForced == true then
                Dragging = false
                return
            end

            if not Dragging and Library:MouseIsOverFrame(Instance, Input) and (IsMainWindow == true and (Library.CanDrag == true and Library.Window.Holder.Visible == true) or true) then
                DraggingInput = Input
                DraggingStart = Input.Position
                StartPosition = Instance.Position

                local OffsetPos = Input.Position - DraggingStart
                if OffsetPos.Y > (Cutoff or 40) then
                    Dragging = false
                    return
                end

                Dragging = true
            end
        end)
        InputService.TouchMoved:Connect(function(Input)
            if IsMainWindow == true and Library.CantDragForced == true then
                Dragging = false
                return
            end

            if Input == DraggingInput and Dragging and (IsMainWindow == true and (Library.CanDrag == true and Library.Window.Holder.Visible == true) or true) then
                local OffsetPos = Input.Position - DraggingStart

                Instance.Position = UDim2.new(
                    StartPosition.X.Scale,
                    StartPosition.X.Offset + OffsetPos.X,
                    StartPosition.Y.Scale,
                    StartPosition.Y.Offset + OffsetPos.Y
                )
            end
        end)
        InputService.TouchEnded:Connect(function(Input)
            if Input == DraggingInput then 
                Dragging = false
            end
        end)
    end
end

function Library:MakeDraggableUsingParent(Instance, Parent, Cutoff, IsMainWindow)
    Instance.Active = true

    if Library.IsMobile == false then
        Instance.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                if IsMainWindow == true and Library.CantDragForced == true then
                    return
                end
  
                local ObjPos = Vector2.new(
                    Mouse.X - Parent.AbsolutePosition.X,
                    Mouse.Y - Parent.AbsolutePosition.Y
                )

                if ObjPos.Y > (Cutoff or 40) then
                    return
                end

                SmoothDrag(Parent, ObjPos)
            end
        end)
    else  
        Library:MakeDraggable(Parent, Cutoff, IsMainWindow)
    end
end

function Library:MakeResizable(Instance, MinSize, VisualParent)
    if Library.IsMobile then
        return
    end

    VisualParent = VisualParent or Instance

    Instance.Active = true
    
    local ResizerImage_Size = 25 * DPIScale
    local ResizerImage_HoverTransparency = 0.5

    local Resizer = Library:Create("Frame", {
        SizeConstraint = Enum.SizeConstraint.RelativeXX;
        BackgroundColor3 = Color3.new(0, 0, 0);
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        Size = UDim2.new(0, 30, 0, 30);
        Position = UDim2.new(1, -30, 1, -30);
        Visible = true;
        ClipsDescendants = true;
        ZIndex = 1;
        Parent = VisualParent;
    })

    local ResizerImage = Library:Create("ImageButton", {
        BackgroundColor3 = Library.AccentColor;
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        Size = UDim2.new(2, 0, 2, 0);
        Position = UDim2.new(1, -30, 1, -30);
        ZIndex = 2;
        Parent = Resizer;
    })

    local ResizerImageUICorner = Library:Create("UICorner", {
        CornerRadius = UDim.new(0.5, 0);
        Parent = ResizerImage;
    })

    Library:AddToRegistry(ResizerImage, { BackgroundColor3 = "AccentColor"; })

    Resizer.Size = UDim2.fromOffset(ResizerImage_Size, ResizerImage_Size)
    Resizer.Position = UDim2.new(1, -ResizerImage_Size, 1, -ResizerImage_Size)
    MinSize = MinSize or Library.MinSize

    local OffsetPos
    Resizer.Parent = VisualParent

    local function FinishResize(Transparency)
        ResizerImage.Position = UDim2.new()
        ResizerImage.Size = UDim2.new(2, 0, 2, 0)
        ResizerImage.Parent = Resizer
        ResizerImage.BackgroundTransparency = Transparency
        ResizerImageUICorner.Parent = ResizerImage
        OffsetPos = nil
    end

    ResizerImage.MouseButton1Down:Connect(function()
        if not OffsetPos then
            OffsetPos = Vector2.new(Mouse.X - (Instance.AbsolutePosition.X + Instance.AbsoluteSize.X), Mouse.Y - (Instance.AbsolutePosition.Y + Instance.AbsoluteSize.Y))

            ResizerImage.BackgroundTransparency = 1
            ResizerImage.Size = UDim2.fromOffset(Library.ScreenGui.AbsoluteSize.X, Library.ScreenGui.AbsoluteSize.Y)
            ResizerImage.Position = UDim2.new()
            ResizerImageUICorner.Parent = nil
            ResizerImage.Parent = Library.ScreenGui
        end
    end)

    ResizerImage.MouseMoved:Connect(function()
        if OffsetPos then		
            local MousePos = Vector2.new(Mouse.X - OffsetPos.X, Mouse.Y - OffsetPos.Y)
            local FinalSize = Vector2.new(math.clamp(MousePos.X - Instance.AbsolutePosition.X, MinSize.X, math.huge), math.clamp(MousePos.Y - Instance.AbsolutePosition.Y, MinSize.Y, math.huge))
            Instance.Size = UDim2.fromOffset(FinalSize.X, FinalSize.Y)
        end
    end)

    ResizerImage.MouseEnter:Connect(function()
        FinishResize(ResizerImage_HoverTransparency)
    end)

    ResizerImage.MouseLeave:Connect(function()
        FinishResize(1)
    end)

    ResizerImage.MouseButton1Up:Connect(function()
        FinishResize(ResizerImage_HoverTransparency)
    end)
end

function Library:AddToolTip(InfoStr, DisabledInfoStr, HoverInstance)
    InfoStr = typeof(InfoStr) == "string" and InfoStr or nil
    DisabledInfoStr = typeof(DisabledInfoStr) == "string" and DisabledInfoStr or nil

    local Tooltip = Library:Create("Frame", {
        BackgroundColor3 = Library.MainColor;
        BackgroundTransparency = Library.GlassTransparency;
        Corner = 5;

        ZIndex = 100;
        Parent = Library.ScreenGui;

        Visible = false;
    })

    local Label = Library:CreateLabel({
        Position = UDim2.fromOffset(3, 1);
        
        TextSize = 14;
        Text = InfoStr;
        TextColor3 = Library.FontColor;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = Tooltip.ZIndex + 1;

        Parent = Tooltip;
    })

    Library:AddToRegistry(Tooltip, {
        BackgroundColor3 = "MainColor";
    })

    Library:AddToRegistry(Label, {
        TextColor3 = "FontColor",
    })

    local TooltipTable = {
        Tooltip = Tooltip;
        Disabled = false;

        Signals = {};
    }
    local IsHovering = false

    local function UpdateText(Text)
        if Text == nil then return end

        local X, Y = Library:GetTextBounds(Text, Library.Font, 14 * DPIScale)

        Label.Text = Text
        Tooltip.Size = UDim2.fromOffset(X + 5, Y + 4)
        Label.Size = UDim2.fromOffset(X, Y)
    end

    local function GiveSignal(Connection: RBXScriptConnection | RBXScriptSignal)
        local ConnectionType = typeof(Connection)
        if Connection and (ConnectionType == "RBXScriptConnection" or ConnectionType == "RBXScriptSignal") then
            table.insert(TooltipTable.Signals, Connection)
        end

        return Connection
    end

    UpdateText(InfoStr)

    GiveSignal(HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then
            Tooltip.Visible = false
            return
        end

        if not TooltipTable.Disabled then
            if InfoStr == nil or InfoStr == "" then
                Tooltip.Visible = false
                return
            end

            if Label.Text ~= InfoStr then
                UpdateText(InfoStr)
            end
        else
            if DisabledInfoStr == nil or DisabledInfoStr == "" then
                Tooltip.Visible = false
                return
            end

            if Label.Text ~= DisabledInfoStr then 
                UpdateText(DisabledInfoStr)
            end
        end

        IsHovering = true

        Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        Tooltip.Visible = true

        while IsHovering do
            if TooltipTable.Disabled == true and DisabledInfoStr == nil then break end

            RunService.Heartbeat:Wait()
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        end

        IsHovering = false
        Tooltip.Visible = false
    end))

    GiveSignal(HoverInstance.MouseLeave:Connect(function()
        IsHovering = false
        Tooltip.Visible = false
    end))
    
    if LibraryMainOuterFrame then
        GiveSignal(LibraryMainOuterFrame:GetPropertyChangedSignal("Visible"):Connect(function()
            if LibraryMainOuterFrame.Visible == false then
                IsHovering = false
                Tooltip.Visible = false
            end
        end))
    end

    function TooltipTable:Destroy()
        for Idx = #TooltipTable.Signals, 1, -1 do
            local Connection = table.remove(TooltipTable.Signals, Idx)
            if Connection and Connection.Connected then
                Connection:Disconnect()
            end
        end

        Tooltip:Destroy()
    end

    table.insert(Tooltips, TooltipTable)
    return TooltipTable
end

function Library:MouseIsOverFrame(Frame, Input)
    local Pos = Mouse
    if Library.IsMobile and Input then 
        Pos = Input.Position
    end

    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
    if Pos.X >= AbsPos.X and Pos.X <= AbsPos.X + AbsSize.X
        and Pos.Y >= AbsPos.Y and Pos.Y <= AbsPos.Y + AbsSize.Y then

        return true
    end

    return false
end

function Library:IsFrameInsideDialog(Frame)
    if not Library.ActiveDialog then return false end

    local Pos = Frame.AbsolutePosition
    local AbsPos, AbsSize = Library.ActiveDialog.Container.AbsolutePosition, Library.ActiveDialog.Container.AbsoluteSize
   
    if Pos.X >= AbsPos.X and Pos.X <= AbsPos.X + AbsSize.X
        and Pos.Y >= AbsPos.Y and Pos.Y <= AbsPos.Y + AbsSize.Y then

        return true
    end

    return false
end

function Library:MouseIsOverOpenedFrame(Input)
    -- Inside active dialog
    if Library.ActiveDialog then
        if Library:MouseIsOverFrame(Library.ActiveDialog.Container, Input) then
            return false
        end

        return true
    end

    -- Inside opened frames
    for Frame, _ in next, Library.OpenedFrames do
        if Library:MouseIsOverFrame(Frame, Input) then
            return true
        end
    end

    return false
end

function Library:GetRegistryColor(Instance, Property)
    local Reg = Library.RegistryMap[Instance]
    local ColorIdx = Reg and Reg.Properties[Property]

    if typeof(ColorIdx) == "string" and Library[ColorIdx] then
        return Library[ColorIdx]
    elseif typeof(ColorIdx) == "function" then
        return ColorIdx()
    end

    return Instance[Property]
end

local HoverTweenInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local ArrowTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local ListTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function GetHoverTarget(Instance)
    if Instance.BackgroundTransparency < 1 or Instance:GetAttribute("HoverRow") then
        return Instance
    end

    return Instance:FindFirstChildWhichIsA("GuiObject")
end

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault, condition)
    local HoverGoal = nil
    local HoverBase = nil

    -- outlines are gone, so a border highlight is shown as a tint on the element's body instead
    local function setHover(Target, Color)
        if not Target then
            return
        end

        local IsRow = Target:GetAttribute("HoverRow") == true

        if Color == nil then
            if HoverGoal == nil then
                return
            end

            HoverGoal = nil

            if IsRow then
                TweenService:Create(Target, HoverTweenInfo, { BackgroundTransparency = 1 }):Play()
            else
                local Base = Library.RegistryMap[Target] and Library:GetRegistryColor(Target, "BackgroundColor3") or HoverBase
                Target:SetAttribute("HoverColor", nil)
                TweenService:Create(Target, HoverTweenInfo, { BackgroundColor3 = Base }):Play()
            end

            return
        end

        if IsRow then
            if HoverGoal ~= Color then
                HoverGoal = Color
                TweenService:Create(Target, HoverTweenInfo, { BackgroundColor3 = Color, BackgroundTransparency = 0.85 }):Play()
            end

            return
        end

        if HoverGoal == nil then
            HoverBase = Target.BackgroundColor3
        end

        local Base = Library.RegistryMap[Target] and Library:GetRegistryColor(Target, "BackgroundColor3") or HoverBase
        local Goal = Library:GetBetterColor(Base:Lerp(Color, 0.12), 5)

        if HoverGoal ~= Goal then
            HoverGoal = Goal
            Target:SetAttribute("HoverColor", Goal)
            TweenService:Create(Target, HoverTweenInfo, { BackgroundColor3 = Goal }):Play()
        end
    end

    local function undoHighlight()
        local Reg = Library.RegistryMap[Instance]

        for Property, ColorIdx in next, PropertiesDefault do
            if Property == "BorderColor3" then
                setHover(GetHoverTarget(Instance), nil)
                continue
            end

            Instance[Property] = Library[ColorIdx] or ColorIdx

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx
            end
        end
    end

    local function doHighlight()
        if condition and not condition() then
            undoHighlight()
            return
        end

        if Library.ActiveDialog and not Library:IsFrameInsideDialog(Instance) then
            undoHighlight()
            return
        end

        local Reg = Library.RegistryMap[Instance]

        for Property, ColorIdx in next, Properties do
            if Property == "BorderColor3" then
                setHover(GetHoverTarget(Instance), Library[ColorIdx] or ColorIdx)
                continue
            end

            Instance[Property] = Library[ColorIdx] or ColorIdx

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx
            end
        end
    end

    HighlightInstance.MouseEnter:Connect(doHighlight)
    HighlightInstance.MouseMoved:Connect(doHighlight)
    HighlightInstance.MouseLeave:Connect(undoHighlight)
end

function Library:UpdateDependencyBoxes()
    for _, Depbox in next, Library.DependencyBoxes do
        Depbox:Update()
    end
end

function Library:UpdateDependencyGroupboxes()
    for _, Depbox in next, Library.DependencyGroupboxes do
        Depbox:Update()
    end
end

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB
end

function Library:GetTextBounds(Text, Font, Size, Resolution)
    -- Ignores rich text formatting --
    if typeof(Resolution) == "number" then
        Resolution = Vector2.new(Resolution, 10000)
    end

    local Bounds = TextService:GetTextSize(Text:gsub("<%/?[%w:]+[^>]*>", ""), Size, Font, Resolution or Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color)
    return Color3.fromHSV(H, S, V / 1.5)
end
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Idx = #Library.Registry + 1
    local Data = {
        Instance = Instance;
        Properties = Properties;
        Idx = Idx;
    }

    table.insert(Library.Registry, Data)
    Library.RegistryMap[Instance] = Data

    if IsHud then
        table.insert(Library.HudRegistry, Data)
    end
end

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance]

    if Data then
        for Idx = #Library.Registry, 1, -1 do
            if Library.Registry[Idx] == Data then
                table.remove(Library.Registry, Idx)
            end
        end

        for Idx = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[Idx] == Data then
                table.remove(Library.HudRegistry, Idx)
            end
        end

        Library.RegistryMap[Instance] = nil
    end
end

function Library:UpdateColorsUsingRegistry()
    -- TODO: Could have an "active" list of objects
    -- where the active list only contains Visible objects.

    -- IMPL: Could setup .Changed events on the AddToRegistry function
    -- that listens for the "Visible" propert being changed.
    -- Visible: true => Add to active list, and call UpdateColors function
    -- Visible: false => Remove from active list.

    -- The above would be especially efficient for a rainbow menu color or live color-changing.

    for Idx, Object in next, Library.Registry do
        for Property, ColorIdx in next, Object.Properties do
            if typeof(ColorIdx) == "string" then
                Object.Instance[Property] = Library[ColorIdx]
            elseif typeof(ColorIdx) == "function" then
                Object.Instance[Property] = ColorIdx()
            end
        end
    end
end

function Library:GiveSignal(Connection: RBXScriptConnection | RBXScriptSignal) -- Only used for signals not attached to library instances, as those should be cleaned up on object destruction by Roblox
    local ConnectionType = typeof(Connection)
    if Connection and (ConnectionType == "RBXScriptConnection" or ConnectionType == "RBXScriptSignal") then
        table.insert(Library.Signals, Connection)
    end

    return Connection
end

function Library:Unload()
    for Idx = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Idx)
        if Connection and Connection.Connected then
            Connection:Disconnect()
        end
    end

    for _, UnloadCallback in Library.UnloadSignals do
        Library:SafeCallback(UnloadCallback)
    end

    for _, Tooltip in Tooltips do
        Library:SafeCallback(Tooltip.Destroy, Tooltip)
    end

    Library.Unloaded = true

    if Library.Blur then
        Library.Blur:Destroy()
        Library.Blur = nil
    end

    ScreenGui:Destroy()

    getgenv().Noctalia = nil
end

function Library:OnUnload(Callback)
    table.insert(Library.UnloadSignals, Callback)
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.Unloaded then
        return
    end

    if Library.RegistryMap[Instance] then
        Library:RemoveFromRegistry(Instance)
    end
end))

--// Templates \\--
local Templates = { -- TO-DO: do it for missing elements.
    --// Window \\--
    Window = {
        Title = "No Title",
        Subtitle = "",
        Badge = "",
        Username = LocalPlayer.Name,
        FooterLeft = "",
        FooterCenter = "",
        FooterRightLabel = "",
        FooterRightValue = "",
        AutoShow = false,
        Position = UDim2.fromOffset(175, 50),
        Size = UDim2.fromOffset(0, 0),
        AnchorPoint = Vector2.zero,
        TabPadding = 8,
        MenuFadeTime = 0.2,
        NotifySide = "Left",
        ShowCustomCursor = true,
        UnlockMouseWhileOpen = true,
        Center = false
    },

    --// Elements \\--
    Video = {
        Video = "",
        Looped = false,
        Playing = false,
        Volume = 1,
        Height = 200,
        Visible = true,
    },
    UIPassthrough = {
        Instance = nil,
        Height = 24,
        Visible = true,
    }
}

--// Addons \\--
local BaseAddons = {}
do
    local BaseAddonsFuncs = {}

        function BaseAddonsFuncs:AddKeyPicker(Idx, Info)
        local ParentObj = self
        local ToggleLabel = self.TextLabel
        --local Container = self.Container;

        assert(Info.Default, string.format("AddKeyPicker (IDX: %s): Missing default value.", tostring(Idx)))

        local KeyPicker = {
            Value = nil; -- Key
            Modifiers = {}; -- Modifiers
            DisplayValue = nil; -- Picker Text

            Toggled = false;
            Mode = Info.Mode or "Toggle"; -- Always, Toggle, Hold, Press
            Type = "KeyPicker";
            Callback = Info.Callback or function(Value) end;
            ChangedCallback = Info.ChangedCallback or function(New) end;
            SyncToggleState = Info.SyncToggleState or false;
        }

        if KeyPicker.Mode == "Press" then
            assert(ParentObj.Type == "Label", "KeyPicker with the mode \"Press\" can be only applied on Labels.")
            
            KeyPicker.SyncToggleState = false
            Info.Modes = { "Press" }
            Info.Mode = "Press"
        end

        if KeyPicker.SyncToggleState then
            Info.Modes = { "Toggle", "Hold" }

            if not table.find(Info.Modes, Info.Mode) then
                Info.Mode = "Toggle"
            end
        end

        local Picking = false

        -- Special Keys
        local SpecialKeys = {
            ["MB1"] = Enum.UserInputType.MouseButton1,
            ["MB2"] = Enum.UserInputType.MouseButton2,
            ["MB3"] = Enum.UserInputType.MouseButton3
        }

        local SpecialKeysInput = {
            [Enum.UserInputType.MouseButton1] = "MB1",
            [Enum.UserInputType.MouseButton2] = "MB2",
            [Enum.UserInputType.MouseButton3] = "MB3"
        }

        -- Modifiers
        local Modifiers = {
            ["LAlt"] = Enum.KeyCode.LeftAlt,
            ["RAlt"] = Enum.KeyCode.RightAlt,

            ["LCtrl"] = Enum.KeyCode.LeftControl,
            ["RCtrl"] = Enum.KeyCode.RightControl,

            ["LShift"] = Enum.KeyCode.LeftShift,
            ["RShift"] = Enum.KeyCode.RightShift,

            ["Tab"] = Enum.KeyCode.Tab,
            ["CapsLock"] = Enum.KeyCode.CapsLock
        }

        local ModifiersInput = {
            [Enum.KeyCode.LeftAlt] = "LAlt",
            [Enum.KeyCode.RightAlt] = "RAlt",

            [Enum.KeyCode.LeftControl] = "LCtrl",
            [Enum.KeyCode.RightControl] = "RCtrl",

            [Enum.KeyCode.LeftShift] = "LShift",
            [Enum.KeyCode.RightShift] = "RShift",

            [Enum.KeyCode.Tab] = "Tab",
            [Enum.KeyCode.CapsLock] = "CapsLock"
        }

        local IsModifierInput = function(Input)
            return Input.UserInputType == Enum.UserInputType.Keyboard and ModifiersInput[Input.KeyCode] ~= nil
        end

        local GetActiveModifiers = function()
            local ActiveModifiers = {}

            for Name, Input in Modifiers do
                if table.find(ActiveModifiers, Name) then continue end
                if not InputService:IsKeyDown(Input) then continue end

                table.insert(ActiveModifiers, Name)
            end

            return ActiveModifiers
        end

        local AreModifiersHeld = function(Required)
            if not (typeof(Required) == "table" and GetTableSize(Required) > 0) then 
                return true
            end

            local ActiveModifiers = GetActiveModifiers()
            local Holding = true

            for _, Name in Required do
                if table.find(ActiveModifiers, Name) then continue end

                Holding = false
                break
            end

            return Holding
        end

        local IsInputDown = function(Input)
            if not Input then 
                return false
            end

            if SpecialKeysInput[Input.UserInputType] ~= nil then
                return InputService:IsMouseButtonPressed(Input.UserInputType) and not InputService:GetFocusedTextBox()
            elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                return InputService:IsKeyDown(Input.KeyCode) and not InputService:GetFocusedTextBox()
            else
                return false
            end
        end

        local ConvertToInputModifiers = function(CurrentModifiers)
            local InputModifiers = {}

            for _, name in CurrentModifiers do
                table.insert(InputModifiers, Modifiers[name])
            end

            return InputModifiers
        end

        local VerifyModifiers = function(CurrentModifiers)
            if typeof(CurrentModifiers) ~= "table" then
                return {}
            end

            local ValidModifiers = {}

            for _, name in CurrentModifiers do
                if not Modifiers[name] then continue end

                table.insert(ValidModifiers, name)
            end

            return ValidModifiers
        end

        -- the chip shows short lowercase names (rmb, e, lshift + q)
        local ChipNames = { MB1 = "lmb"; MB2 = "rmb"; MB3 = "mmb"; None = "none" }

        local function FormatChip(Text)
            Text = tostring(Text or "")

            return (Text:gsub("[%w]+", function(Word)
                return ChipNames[Word] or Word:lower()
            end))
        end

        local PickOuter = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 38, 0, 20);
            ZIndex = 6;
            Parent = ToggleLabel;
        })

        local PickInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BackgroundTransparency = Library.ElementTransparency;
            Corner = 10;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 7;
            Parent = PickOuter;
        })

        Library:AddToRegistry(PickInner, {
            BackgroundColor3 = "MainColor";
        })
        Library:AddStroke(PickInner, "OutlineColor")

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 11;
            Text = FormatChip(Info.Default);
            TextWrapped = true;
            ZIndex = 8;
            Parent = PickInner;
        })
        Library:DimLabel(DisplayLabel)

        -- Keybinds Text
        local KeybindsToggle = {}
        do
            local KeybindsToggleContainer = Library:Create("Frame", {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 18);
                Visible = false;
                ZIndex = 110;
                Parent = Library.KeybindContainer;
            })

            local KeybindsToggleOuter = Library:Create("Frame", {
                BackgroundColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(0, 13, 0, 13);
                Position = UDim2.new(0, 0, 0, 6);
                Visible = true;
                ZIndex = 110;
                Parent = KeybindsToggleContainer;
            })

            Library:AddToRegistry(KeybindsToggleOuter, {
                BorderColor3 = "Black";
            })

            local KeybindsToggleInner = Library:Create("Frame", {
                BackgroundColor3 = Library.MainColor;
                BackgroundTransparency = Library.ElementTransparency;
                Corner = 5;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 111;
                Parent = KeybindsToggleOuter;
            })

            Library:AddToRegistry(KeybindsToggleInner, {
                BackgroundColor3 = "MainColor";
                BorderColor3 = "OutlineColor";
            })

            local KeybindsToggleLabel = Library:CreateLabel({
                BackgroundTransparency = 1;
                Size = UDim2.new(0, 216, 1, 0);
                Position = UDim2.new(1, 6, 0, -1);
                TextSize = 14;
                Text = "";
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 111;
                Parent = KeybindsToggleInner;
            })

            Library:Create("UIListLayout", {
                Padding = UDim.new(0, 4);
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right;
                VerticalAlignment = Enum.VerticalAlignment.Center;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = KeybindsToggleLabel;
            })

            local KeybindsToggleRegion = Library:Create("Frame", {
                BackgroundTransparency = 1;
                Size = UDim2.new(0, 170, 1, 0);
                ZIndex = 113;
                Parent = KeybindsToggleOuter;
            })

            Library:OnHighlight(KeybindsToggleRegion, KeybindsToggleOuter,
                { BorderColor3 = "AccentColor" },
                { BorderColor3 = "Black" },
                function()
                    return true
                end
            )

            function KeybindsToggle:Display(State)
                KeybindsToggleInner.BackgroundColor3 = State and Library.AccentColor or Library.MainColor
                KeybindsToggleInner.BorderColor3 = State and Library.AccentColorDark or Library.OutlineColor
                KeybindsToggleLabel.TextColor3 = State and Library.AccentColor or Library.FontColor

                Library.RegistryMap[KeybindsToggleInner].Properties.BackgroundColor3 = State and "AccentColor" or "MainColor"
                Library.RegistryMap[KeybindsToggleInner].Properties.BorderColor3 = State and "AccentColorDark" or "OutlineColor"
                Library.RegistryMap[KeybindsToggleLabel].Properties.TextColor3 = State and "AccentColor" or "FontColor"
            end

            function KeybindsToggle:SetText(Text)
                KeybindsToggleLabel.Text = Text
            end

            function KeybindsToggle:SetVisibility(bool)
                KeybindsToggleContainer.Visible = bool
            end

            function KeybindsToggle:SetNormal(bool)
                KeybindsToggle.Normal = bool

                KeybindsToggleInner.BackgroundTransparency = if KeybindsToggle.Normal then 1 else Library.ElementTransparency

                KeybindsToggleLabel.Position = if KeybindsToggle.Normal then UDim2.new(1, -13, 0, -1) else UDim2.new(1, 6, 0, -1)
            end

            KeyPicker.DoClick = function(...) end --// make luau lsp shut up
            Library:GiveSignal(KeybindsToggleRegion.InputBegan:Connect(function(Input)
                if Library.Unloaded then
                    return
                end

                if KeybindsToggle.Normal then return end
                                        
                if (Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame()) or Input.UserInputType == Enum.UserInputType.Touch then
                    KeyPicker.Toggled = not KeyPicker.Toggled
                    KeyPicker:DoClick()
                end
            end))

            KeybindsToggle.Loaded = true
        end

        local ModeSelectOuter = Library:Create("Frame", {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 80, 0, 0);
            Visible = false;
            ZIndex = 14;
            Parent = ScreenGui;
        })

        -- the mode menu hangs off the bottom right corner of the chip
        local function UpdateMenuOuterPos()
            ModeSelectOuter.Position = UDim2.fromOffset(
                PickOuter.AbsolutePosition.X + PickOuter.AbsoluteSize.X - ModeSelectOuter.Size.X.Offset,
                PickOuter.AbsolutePosition.Y + PickOuter.AbsoluteSize.Y + 4
            )
        end

        UpdateMenuOuterPos()
        ToggleLabel:GetPropertyChangedSignal("AbsolutePosition"):Connect(UpdateMenuOuterPos)
        PickOuter:GetPropertyChangedSignal("AbsolutePosition"):Connect(UpdateMenuOuterPos)
        PickOuter:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateMenuOuterPos)

        local ModeSelectInner = Library:Create("Frame", {
            BackgroundColor3 = Library.BackgroundColor;
            BackgroundTransparency = Library.GlassTransparency;
            Corner = 5;
            Size = UDim2.new(1, 0, 0, 3);
            ZIndex = 15;
            Parent = ModeSelectOuter;
        })

        Library:AddToRegistry(ModeSelectInner, {
            BackgroundColor3 = "BackgroundColor";
            BorderColor3 = "OutlineColor";
        })

        Library:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ModeSelectInner;
        })

        local Modes = Info.Modes or { "Always", "Toggle", "Hold" }
        local ModeButtons = {}
        local UnbindButton = {}

        for Idx, Mode in next, Modes do
            local ModeButton = {}

            local Label = Library:CreateLabel({
                Active = false;
                Size = UDim2.new(1, 0, 0, 15);
                TextSize = 13;
                Text = Mode;
                ZIndex = 16;
                Parent = ModeSelectInner;
            })
            ModeSelectInner.Size = ModeSelectInner.Size + UDim2.new(0, 0, 0, 15)
            ModeSelectOuter.Size = ModeSelectOuter.Size + UDim2.new(0, 0, 0, 18)

            function ModeButton:Select()
                for _, Button in next, ModeButtons do
                    Button:Deselect()
                end

                KeyPicker.Mode = Mode

                Label.TextColor3 = Library.AccentColor
                Library.RegistryMap[Label].Properties.TextColor3 = "AccentColor"

                ModeSelectOuter.Visible = false
            end

            function ModeButton:Deselect()
                KeyPicker.Mode = nil

                Label.TextColor3 = Library.FontColor
                Library.RegistryMap[Label].Properties.TextColor3 = "FontColor"
            end

            Label.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    ModeButton:Select()
                end
            end)

            if Mode == KeyPicker.Mode then
                ModeButton:Select()
            end

            ModeButtons[Mode] = ModeButton
        end

        -- Create Unbind button --
        do
            local UnbindInner = Library:Create("Frame", {
                BackgroundColor3 = Library.BackgroundColor;
                BackgroundTransparency = Library.GlassTransparency;
                Corner = 5;
                Position = UDim2.new(0, 0, 0, ModeSelectInner.Size.Y.Offset + 3);
                Size = UDim2.new(1, 0, 0, 18);
                ZIndex = 15;
                Parent = ModeSelectOuter;
            })

            ModeSelectOuter.Size = ModeSelectOuter.Size + UDim2.new(0, 0, 0, 18)

            Library:AddToRegistry(UnbindInner, {
                BackgroundColor3 = "BackgroundColor";
                BorderColor3 = "OutlineColor";
            })

            local UnbindLabel = Library:CreateLabel({
                Active = false;
                Size = UDim2.new(1, 0, 0, 15);
                TextSize = 13;
                Text = "Unbind Key";
                ZIndex = 16;
                Parent = UnbindInner;
            })

            KeyPicker.SetValue = function(...) end --// make luau lsp shut up
            function UnbindButton:UnbindKey()
                KeyPicker:SetValue({ nil, KeyPicker.Mode, {} })
                ModeSelectOuter.Visible = false
            end

            UnbindLabel.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    UnbindButton:UnbindKey()
                end
            end)
        end

        function KeyPicker:Display(Text)
            DisplayLabel.Text = FormatChip(Text or KeyPicker.DisplayValue)

            PickOuter.Size = UDim2.new(0, 999999, 0, 20)
            RunService.RenderStepped:Wait()
            PickOuter.Size = UDim2.new(0, math.max(38, DisplayLabel.TextBounds.X + 18), 0, 20)
        end

        function KeyPicker:Update()
            if Info.NoUI then
                return
            end

            local State = KeyPicker:GetState()
            local ShowToggle = Library.ShowToggleFrameInKeybinds and KeyPicker.Mode == "Toggle"

            if KeyPicker.SyncToggleState and ParentObj.Value ~= State then
                ParentObj:SetValue(State)
            end

            if KeybindsToggle.Loaded then
                KeybindsToggle:SetNormal(not ShowToggle)

                KeybindsToggle:SetVisibility(true)
                KeybindsToggle:SetText(string.format("[%s] %s (%s)", tostring(KeyPicker.DisplayValue), Info.Text, KeyPicker.Mode))
                KeybindsToggle:Display(State)
            end

            local YSize = 0
            local XSize = 0

            for _, Frame in next, Library.KeybindContainer:GetChildren() do
                if Frame:IsA("Frame") and Frame.Visible then
                    YSize = YSize + 18
                    local Label = Frame:FindFirstChild("TextLabel", true)
                    if not Label then continue end
                    
                    local LabelSize = Label.TextBounds.X + 20
                    if (LabelSize > XSize) then
                        XSize = LabelSize
                    end
                end
            end

            Library.KeybindFrame.Size = UDim2.new(0, math.max(XSize + 10, 220), 0, (YSize + 23 + 6) * DPIScale)
            UpdateMenuOuterPos()
        end

        function KeyPicker:GetState()
            if KeyPicker.Mode == "Always" then
                return true
            
            elseif KeyPicker.Mode == "Hold" then
                local Key = KeyPicker.Value
                if Key == "None" then
                    return false
                end

                if not AreModifiersHeld(KeyPicker.Modifiers) then
                    return false
                end

                if SpecialKeys[Key] ~= nil then
                    return InputService:IsMouseButtonPressed(SpecialKeys[Key]) and not InputService:GetFocusedTextBox()
                else
                    return InputService:IsKeyDown(Enum.KeyCode[Key]) and not InputService:GetFocusedTextBox()
                end

            else
                return KeyPicker.Toggled
            end
        end

        function KeyPicker:SetValue(Data, SkipCallback)
            local Key, Mode, Modifiers = Data[1], Data[2], Data[3]

            local IsKeyValid, UserInputType = pcall(function()
                if Key == "None" then
                    Key = nil
                    return nil
                end
                
                if SpecialKeys[Key] == nil then 
                    return Enum.KeyCode[Key]
                end

                return SpecialKeys[Key]
            end)

            if Key == nil then
                KeyPicker.Value = "None"
            elseif IsKeyValid then
                KeyPicker.Value = Key
            else
                KeyPicker.Value = "Unknown"
            end

            KeyPicker.Modifiers = VerifyModifiers(if typeof(Modifiers) == "table" then Modifiers else KeyPicker.Modifiers)
            KeyPicker.DisplayValue = if GetTableSize(KeyPicker.Modifiers) > 0 then (table.concat(KeyPicker.Modifiers, " + ") .. " + " .. KeyPicker.Value) else KeyPicker.Value

            DisplayLabel.Text = FormatChip(KeyPicker.DisplayValue)

            if Mode ~= nil and ModeButtons[Mode] ~= nil then
                ModeButtons[Mode]:Select()
            end

            KeyPicker:Display()
            KeyPicker:Update()

            if SkipCallback == true then return end
            local NewModifiers = ConvertToInputModifiers(KeyPicker.Modifiers)
            Library:SafeCallback(KeyPicker.ChangedCallback, UserInputType, NewModifiers)
            Library:SafeCallback(KeyPicker.Changed, UserInputType, NewModifiers)
        end

        function KeyPicker:OnClick(Callback)
            KeyPicker.Clicked = Callback
        end

        function KeyPicker:OnChanged(Callback)
            KeyPicker.Changed = Callback
            -- Callback(KeyPicker.Value)
        end

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
        end

        function KeyPicker:DoClick()
            if KeyPicker.Mode == "Press" then
                if KeyPicker.Toggled and Info.WaitForCallback == true then
                    return
                end

                KeyPicker.Toggled = true
            end

            if KeyPicker ~= Library.ToggleKeybind then
                Library:PlayKeybindSound()

                local KeyName = ParentObj.Type == "Toggle" and ParentObj.Text or Info.Text or Idx
                local State = KeyPicker.Mode == "Press" and "Pressed" or (KeyPicker.Toggled and "Enabled" or "Disabled")
                Library:NotifyKeybind(KeyPicker, KeyName, State)
            end

            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)

            if KeyPicker.Mode == "Press" then
                KeyPicker.Toggled = false
            end
        end

        function KeyPicker:SetModePickerVisibility(bool)
            ModeSelectOuter.Visible = bool
        end

        function KeyPicker:GetModePickerVisibility()
            return ModeSelectOuter.Visible
        end

        PickOuter.InputBegan:Connect(function(PickerInput)
            if PickerInput.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Picking = true

                KeyPicker:Display("...")

                -- Wait for an non modifier key --
                local Input
                local ActiveModifiers = {}

                local GetInput = function()
                    Input = InputService.InputBegan:Wait()
                    if InputService:GetFocusedTextBox() then
                        return true
                    end

                    return false
                end

                repeat
                    task.wait()

                    -- Wait for any input --
                    KeyPicker:Display("...")

                    if GetInput() then
                        Picking = false
                        KeyPicker:Update()
                        return
                    end

                    -- Escape --
                    if Input.KeyCode == Enum.KeyCode.Escape then
                        break
                    end

                    -- Handle modifier keys --
                    if IsModifierInput(Input) then
                        local StopLoop = false

                        repeat
                            task.wait()
                            if InputService:IsKeyDown(Input.KeyCode) then
                                task.wait(0.075)

                                if InputService:IsKeyDown(Input.KeyCode) then
                                    -- Add modifier to the key list --
                                    if not table.find(ActiveModifiers, ModifiersInput[Input.KeyCode]) then
                                        ActiveModifiers[#ActiveModifiers + 1] = ModifiersInput[Input.KeyCode]
                                        KeyPicker:Display(table.concat(ActiveModifiers, " + ") .. " + ...")
                                    end

                                    -- Wait for another input --
                                    if GetInput() then
                                        StopLoop = true
                                        break -- Invalid Input
                                    end

                                    -- Escape --
                                    if Input.KeyCode == Enum.KeyCode.Escape then
                                        break
                                    end

                                    -- Stop loop if its a normal key --
                                    if not IsModifierInput(Input) then
                                        break
                                    end
                                else
                                    if not table.find(ActiveModifiers, ModifiersInput[Input.KeyCode]) then
                                        break -- Modifier is meant to be used as a normal key --
                                    end
                                end
                            end
                        until false

                        if StopLoop then
                            Picking = false
                            KeyPicker:Update()
                            return
                        end
                    end

                    break -- Input found, end loop
                until false

                local Key = "Unknown"
                if SpecialKeysInput[Input.UserInputType] ~= nil then
                    Key = SpecialKeysInput[Input.UserInputType]
                elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                    Key = Input.KeyCode == Enum.KeyCode.Escape and "None" or Input.KeyCode.Name
                end

                ActiveModifiers = if Input.KeyCode == Enum.KeyCode.Escape or Key == "Unknown" then {} else ActiveModifiers

                KeyPicker.Toggled = false
                KeyPicker:SetValue({ Key, KeyPicker.Mode, ActiveModifiers })

                -- RunService.RenderStepped:Wait()
                repeat task.wait() until not IsInputDown(Input) or InputService:GetFocusedTextBox()
                Picking = false

            elseif PickerInput.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                local visible = KeyPicker:GetModePickerVisibility()
                
                if visible == false then
                    for _, option in next, Options do
                        if option.Type == "KeyPicker" then
                            option:SetModePickerVisibility(false)
                        end
                    end
                end

                KeyPicker:SetModePickerVisibility(not visible)
            end
        end)

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if Library.Unloaded then
                return
            end

            if KeyPicker.Value == "Unknown" then return end
        
            if (not Picking) and (not InputService:GetFocusedTextBox()) then
                local Key = KeyPicker.Value
                local HoldingModifiers = AreModifiersHeld(KeyPicker.Modifiers)
                local HoldingKey = false

                if HoldingModifiers then
                    if Input.UserInputType == Enum.UserInputType.Keyboard then
                        if Input.KeyCode.Name == Key then
                            HoldingKey = true
                        end
                    elseif SpecialKeysInput[Input.UserInputType] == Key then
                        HoldingKey = true
                    end
                end

                if KeyPicker.Mode == "Toggle" then
                    if HoldingKey then
                        KeyPicker.Toggled = not KeyPicker.Toggled
                        KeyPicker:DoClick()
                    end
                elseif KeyPicker.Mode == "Press" then
                    if HoldingKey then
                        KeyPicker:DoClick()
                    end
                elseif KeyPicker.Mode == "Hold" then
                    if HoldingKey and KeyPicker ~= Library.ToggleKeybind then
                        Library:PlayKeybindSound()
                        Library:NotifyKeybind(KeyPicker, ParentObj.Type == "Toggle" and ParentObj.Text or Info.Text or Idx, "Held")
                    end
                end

                KeyPicker:Update()
            end

            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsPos, AbsSize = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    KeyPicker:SetModePickerVisibility(false)
                end
            end
        end))

        Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
            if Library.Unloaded then
                return
            end

            if (not Picking) then
                KeyPicker:Update()
            end
        end))
        
        KeyPicker:SetValue({ Info.Default, Info.Mode or "Toggle", Info.DefaultModifiers }, true)
        KeyPicker.DisplayFrame = PickOuter

        KeyPicker.Default = KeyPicker.Value
        KeyPicker.DefaultModifiers = table.clone(KeyPicker.Modifiers or {})

        Options[Idx] = KeyPicker

        return self
    end

    function BaseAddonsFuncs:AddColorPicker(Idx, Info)
        local ParentObj = self
        local ToggleLabel = self.TextLabel
        --local Container = self.Container;

        assert(Info.Default, string.format("AddColorPicker (IDX: %s): Missing default value.", tostring(Idx)))

        local ColorPicker = {
            Value = Info.Default;

            Transparency = Info.Transparency or 0;
            Type = "ColorPicker";
            Title = typeof(Info.Title) == "string" and Info.Title or "Color picker",
            Callback = Info.Callback or function(Color) end;
            Changed = nil,
        }

        local PreviousValues = {
            Value = nil,
            Transparency = nil
        }

        local function RunCallback()
            local NewValue = ColorPicker.Value
            local NewTransparency = ColorPicker.Transparency

            if NewValue == PreviousValues.Value and NewTransparency == PreviousValues.Transparency then
                return
            end

            PreviousValues.Value = ColorPicker.Value
            PreviousValues.Transparency = ColorPicker.Transparency

            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value, ColorPicker.Transparency)
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value, ColorPicker.Transparency)
        end

        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color:ToHSV()

            ColorPicker.Hue = H
            ColorPicker.Sat = S
            ColorPicker.Vib = V
        end

        ColorPicker:SetHSVFromRGB(ColorPicker.Value)

        local DisplayFrame = Library:Create("Frame", {
            BackgroundColor3 = ColorPicker.Value;
            BackgroundTransparency = ColorPicker.Transparency;
            Corner = 5;
            Size = UDim2.new(0, 28, 0, 15);
            ZIndex = 6;
            Parent = ToggleLabel;
        })

        -- Transparency image taken from https://github.com/matas3535/SplixPrivateDrawingLibrary/blob/main/Library.lua cus i'm lazy
        -- local CheckerFrame =
        Library:Create("ImageLabel", {
            BackgroundTransparency = 1;
            Corner = 5;
            Size = UDim2.new(0, 28, 0, 15);
            ZIndex = 5;
            Image = CustomImageManager.GetAsset("Checker");
            Visible = not not Info.Transparency;
            Parent = DisplayFrame;
        })

        -- 1/16/23
        -- Rewrote this to be placed inside the Library ScreenGui
        -- There was some issue which caused RelativeOffset to be way off
        -- Thus the color picker would never show

        local PickerFrameOuter = Library:Create("Frame", {
            Name = "Color";
            BackgroundTransparency = 1;
            Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18),
            Size = UDim2.fromOffset(230, Info.Transparency and 271 or 253);
            Visible = false;
            ZIndex = 15;
            Parent = ScreenGui,
        })

        DisplayFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18)
        end)

        local PickerFrameInner = Library:Create("Frame", {
            ClipsDescendants = true;
            BackgroundColor3 = Library.BackgroundColor;
            BackgroundTransparency = Library.GlassTransparency;
            Corner = 5;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 16;
            Parent = PickerFrameOuter;
        })

        local SatVibMapOuter = Library:Create("Frame", {
            Position = UDim2.new(0, 4, 0, 25);
            Size = UDim2.new(0, 200, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        })

        local SatVibMapInner = Library:Create("Frame", {
            BackgroundColor3 = Library.BackgroundColor;
            BackgroundTransparency = Library.ElementTransparency;
            Corner = 5;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = SatVibMapOuter;
        })

        local SatVibMap = Library:Create("ImageLabel", {
            Corner = 5;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Image = CustomImageManager.GetAsset("SaturationMap");
            Parent = SatVibMapInner;
        })

        local CursorOuter = Library:Create("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5);
            Size = UDim2.new(0, 6, 0, 6);
            BackgroundTransparency = 1;
            Image = CustomImageManager.GetAsset("Cursor");
            ImageColor3 = Color3.new(0, 0, 0);
            ZIndex = 19;
            Parent = SatVibMap;
        })

        -- local CursorInner = 
        Library:Create("ImageLabel", {
            Size = UDim2.new(0, CursorOuter.Size.X.Offset - 2, 0, CursorOuter.Size.Y.Offset - 2);
            Position = UDim2.new(0, 1, 0, 1);
            BackgroundTransparency = 1;
            Image = CustomImageManager.GetAsset("Cursor");
            ZIndex = 20;
            Parent = CursorOuter;
        })

        local HueSelectorOuter = Library:Create("Frame", {
            Position = UDim2.new(0, 208, 0, 25);
            Size = UDim2.new(0, 15, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        })

        local HueSelectorInner = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1);
            Corner = 5;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = HueSelectorOuter;
        })

        local HueCursor = Library:Create("Frame", { 
            BackgroundColor3 = Color3.new(1, 1, 1);
            AnchorPoint = Vector2.new(0, 0.5);
            Size = UDim2.new(1, 0, 0, 1);
            ZIndex = 18;
            Parent = HueSelectorInner;
        })

        local HueBoxOuter = Library:Create("Frame", {
            Position = UDim2.fromOffset(4, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            ZIndex = 18,
            Parent = PickerFrameInner;
        })

        local HueBoxInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BackgroundTransparency = Library.ElementTransparency;
            Corner = 5;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18,
            Parent = HueBoxOuter;
        })

        local HueBox = Library:Create("TextBox", {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = "Hex color",
            Text = "#FFFFFF",
            TextColor3 = Library.FontColor;
            TextSize = 14;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 20,
            Parent = HueBoxInner;
        })

        local RgbBoxBase = Library:Create(HueBoxOuter:Clone(), {
            Position = UDim2.new(0.5, 2, 0, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            Parent = PickerFrameInner
        })

        local RgbBox = Library:Create(RgbBoxBase.Frame:FindFirstChild("TextBox"), {
            Text = "255, 255, 255",
            PlaceholderText = "RGB color",
            TextColor3 = Library.FontColor
        })

        local TransparencyBoxOuter, TransparencyBoxInner, TransparencyCursor
        
        if Info.Transparency then 
            TransparencyBoxOuter = Library:Create("Frame", {
                Position = UDim2.fromOffset(4, 251);
                Size = UDim2.new(1, -8, 0, 15);
                ZIndex = 19;
                Parent = PickerFrameInner;
            })

            TransparencyBoxInner = Library:Create("Frame", {
                BackgroundColor3 = ColorPicker.Value;
                BackgroundTransparency = 0;
                Corner = 5;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 19;
                Parent = TransparencyBoxOuter;
            })

            Library:Create("ImageLabel", {
                BackgroundTransparency = 1;
                Corner = 5;
                Size = UDim2.new(1, 0, 1, 0);
                Image = CustomImageManager.GetAsset("CheckerLong");
                ZIndex = 20;
                Parent = TransparencyBoxInner;
            })

            TransparencyCursor = Library:Create("Frame", { 
                BackgroundColor3 = Color3.new(1, 1, 1);
                AnchorPoint = Vector2.new(0.5, 0);
                Size = UDim2.new(0, 1, 1, 0);
                ZIndex = 21;
                Parent = TransparencyBoxInner;
            })
        end

        -- local DisplayLabel = 
        Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 14);
            Position = UDim2.fromOffset(5, 5);
            TextXAlignment = Enum.TextXAlignment.Left;
            TextSize = 14;
            Text = ColorPicker.Title,--Info.Default;
            TextWrapped = false;
            ZIndex = 16;
            Parent = PickerFrameInner;
        })

        local ContextMenu = {}
        do
            ContextMenu.Options = {}
            ContextMenu.Container = Library:Create("Frame", {
                ZIndex = 14,

                Visible = false,
                Parent = ScreenGui
            })

            ContextMenu.Inner = Library:Create("Frame", {
                BackgroundColor3 = Library.BackgroundColor;
                BackgroundTransparency = Library.GlassTransparency;
                Corner = 5;
                Size = UDim2.fromScale(1, 1);
                ZIndex = 15;
                Parent = ContextMenu.Container;
            })

            Library:Create("UIListLayout", {
                Name = "Layout",
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = ContextMenu.Inner;
            })

            Library:Create("UIPadding", {
                Name = "Padding",
                PaddingLeft = UDim.new(0, 4),
                Parent = ContextMenu.Inner,
            })

            local function updateMenuPosition()
                ContextMenu.Container.Position = UDim2.fromOffset(
                    (DisplayFrame.AbsolutePosition.X + DisplayFrame.AbsoluteSize.X) + 4,
                    DisplayFrame.AbsolutePosition.Y + 1
                )
            end

            local function updateMenuSize()
                local menuWidth = 60
                for i, label in next, ContextMenu.Inner:GetChildren() do
                    if label:IsA("TextLabel") then
                        menuWidth = math.max(menuWidth, label.TextBounds.X)
                    end
                end

                ContextMenu.Container.Size = UDim2.fromOffset(
                    menuWidth + 8,
                    ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 4
                )
            end

            DisplayFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(updateMenuPosition)
            ContextMenu.Inner.Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateMenuSize)

            task.spawn(updateMenuPosition)
            task.spawn(updateMenuSize)

            Library:AddToRegistry(ContextMenu.Inner, {
                BackgroundColor3 = "BackgroundColor";
                BorderColor3 = "OutlineColor";
            })

            function ContextMenu:Show()
                if Library.IsMobile then
                    Library.CanDrag = false
                end

                self.Container.Visible = true
            end

            function ContextMenu:Hide()
                if Library.IsMobile then
                    Library.CanDrag = true
                end
                
                self.Container.Visible = false
            end

            function ContextMenu:AddOption(Str, Callback)
                if typeof(Callback) ~= "function" then
                    Callback = function() end
                end

                local Button = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, 0, 0, 15);
                    TextSize = 13;
                    Text = Str;
                    ZIndex = 16;
                    Parent = self.Inner;
                    TextXAlignment = Enum.TextXAlignment.Left,
                })

                Library:OnHighlight(Button, Button, 
                    { TextColor3 = "AccentColor" },
                    { TextColor3 = "FontColor" }
                )

                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.MouseButton1 or Input.UserInputType ~= Enum.UserInputType.Touch then
                        return
                    end

                    Callback()
                end)
            end

            ContextMenu:AddOption("Copy color", function()
                Library.ColorClipboard = ColorPicker.Value
                Library:Notify("Copied color!", 2)
            end)

            ColorPicker.SetValueRGB = function(...) end --// make luau lsp shut up
            ContextMenu:AddOption("Paste color", function()
                if not Library.ColorClipboard then
                    Library:Notify("You have not copied a color!", 2)
                    return
                end

                ColorPicker:SetValueRGB(Library.ColorClipboard)
            end)

            ContextMenu:AddOption("Copy HEX", function()
                pcall(setclipboard, ColorPicker.Value:ToHex())
                Library:Notify("Copied hex code to clipboard!", 2)
            end)

            ContextMenu:AddOption("Copy RGB", function()
                pcall(setclipboard, table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ", "))
                Library:Notify("Copied RGB values to clipboard!", 2)
            end)
        end
        ColorPicker.ContextMenu = ContextMenu

        Library:AddToRegistry(PickerFrameInner, { BackgroundColor3 = "BackgroundColor"; BorderColor3 = "OutlineColor"; })
        Library:AddToRegistry(SatVibMapInner, { BackgroundColor3 = "BackgroundColor"; BorderColor3 = "OutlineColor"; })

        Library:AddToRegistry(HueBoxInner, { BackgroundColor3 = "MainColor"; BorderColor3 = "OutlineColor"; })
        Library:AddToRegistry(RgbBoxBase.Frame, { BackgroundColor3 = "MainColor"; BorderColor3 = "OutlineColor"; })
        Library:AddToRegistry(RgbBox, { TextColor3 = "FontColor", })
        Library:AddToRegistry(HueBox, { TextColor3 = "FontColor", })

        local SequenceTable = {}

        for Hue = 0, 1, 0.1 do
            table.insert(SequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)))
        end

        -- local HueSelectorGradient =
        Library:Create("UIGradient", {
            Color = ColorSequence.new(SequenceTable);
            Rotation = 90;
            Parent = HueSelectorInner;
        })

        function ColorPicker:Display()
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib)
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1)

            Library:Create(DisplayFrame, {
                BackgroundColor3 = ColorPicker.Value;
                BackgroundTransparency = ColorPicker.Transparency;
            })

            if TransparencyBoxInner then
                TransparencyBoxInner.BackgroundColor3 = ColorPicker.Value
                TransparencyCursor.Position = UDim2.new(1 - ColorPicker.Transparency, 0, 0, 0)
            end

            CursorOuter.Position = UDim2.new(ColorPicker.Sat, 0, 1 - ColorPicker.Vib, 0)
            HueCursor.Position = UDim2.new(0, 0, ColorPicker.Hue, 0)

            HueBox.Text = "#" .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ", ")
        end

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func
        end

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, ColorPicker)
        end

        function ColorPicker:Show()
            for Frame, Val in next, Library.OpenedFrames do
                if Frame.Name == "Color" then
                    Frame.Visible = false
                    Library.OpenedFrames[Frame] = nil
                end
            end

            PickerFrameOuter.Visible = true
            Library.OpenedFrames[PickerFrameOuter] = true
        end

        function ColorPicker:Hide()
            PickerFrameOuter.Visible = false
            Library.OpenedFrames[PickerFrameOuter] = nil
        end

        function ColorPicker:SetValue(HSV, Transparency)
            if typeof(HSV) == "Color3" then
                ColorPicker:SetValueRGB(HSV, Transparency)
                return
            end

            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3])

            ColorPicker.Transparency = Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Display()

            RunCallback()
        end

        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Display()

            RunCallback()
        end

        HueBox.FocusLost:Connect(function(enter)
            if enter then
                local success, result = pcall(Color3.fromHex, HueBox.Text)
                if success and typeof(result) == "Color3" then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(result)
                end
            end

            ColorPicker:Display()
        end)

        RgbBox.FocusLost:Connect(function(enter)
            if enter then
                local r, g, b = RgbBox.Text:match("(%d+),%s*(%d+),%s*(%d+)")
                if r and g and b then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(Color3.fromRGB(r, g, b))
                end
            end

            ColorPicker:Display()
        end)

        SatVibMap.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1 or Enum.UserInputType.Touch) do
                    local MinX = SatVibMap.AbsolutePosition.X
                    local MaxX = MinX + SatVibMap.AbsoluteSize.X
                    local MouseX = math.clamp(Mouse.X, MinX, MaxX)

                    local MinY = SatVibMap.AbsolutePosition.Y
                    local MaxY = MinY + SatVibMap.AbsoluteSize.Y
                    local MouseY = math.clamp(Mouse.Y, MinY, MaxY)

                    ColorPicker.Sat = (MouseX - MinX) / (MaxX - MinX)
                    ColorPicker.Vib = 1 - ((MouseY - MinY) / (MaxY - MinY))
                    ColorPicker:Display()

                    RunCallback()

                    RunService.RenderStepped:Wait()
                end

                Library:AttemptSave()
            end
        end)

        HueSelectorInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1 or Enum.UserInputType.Touch) do
                    local MinY = HueSelectorInner.AbsolutePosition.Y
                    local MaxY = MinY + HueSelectorInner.AbsoluteSize.Y
                    local MouseY = math.clamp(Mouse.Y, MinY, MaxY)

                    ColorPicker.Hue = ((MouseY - MinY) / (MaxY - MinY))
                    ColorPicker:Display()

                    RunCallback()

                    RunService.RenderStepped:Wait()
                end

                Library:AttemptSave()
            end
        end)

        DisplayFrame.InputBegan:Connect(function(Input)
            if Library:MouseIsOverOpenedFrame(Input) then
                return
            end

            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                if PickerFrameOuter.Visible then
                    ColorPicker:Hide()
                else
                    ContextMenu:Hide()
                    ColorPicker:Show()
                end
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                ContextMenu:Show()
                ColorPicker:Hide()
            end
        end)

        if TransparencyBoxInner then
            TransparencyBoxInner.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1 or Enum.UserInputType.Touch) do
                        local MinX = TransparencyBoxInner.AbsolutePosition.X
                        local MaxX = MinX + TransparencyBoxInner.AbsoluteSize.X
                        local MouseX = math.clamp(Mouse.X, MinX, MaxX)

                        ColorPicker.Transparency = 1 - ((MouseX - MinX) / (MaxX - MinX))
                        ColorPicker:Display()

                        RunCallback()

                        RunService.RenderStepped:Wait()
                    end

                    Library:AttemptSave()
                end
            end)
        end

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if Library.Unloaded then
                return
            end

            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local AbsPos, AbsSize = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    ColorPicker:Hide()
                end

                if not Library:MouseIsOverFrame(ContextMenu.Container) then
                    ContextMenu:Hide()
                end
            end

            if Input.UserInputType == Enum.UserInputType.MouseButton2 and ContextMenu.Container.Visible then
                if not Library:MouseIsOverFrame(ContextMenu.Container) and not Library:MouseIsOverFrame(DisplayFrame) then
                    ContextMenu:Hide()
                end
            end
        end))

        ColorPicker:Display()
        ColorPicker.DisplayFrame = DisplayFrame

        ColorPicker.Default = ColorPicker.Value

        Options[Idx] = ColorPicker

        return self
    end

    function BaseAddonsFuncs:AddDropdown(Idx, Info)
        Info.ReturnInstanceInstead = if typeof(Info.ReturnInstanceInstead) == "boolean" then Info.ReturnInstanceInstead else false

        if Info.SpecialType == "Player" then
            Info.ExcludeLocalPlayer = if typeof(Info.ExcludeLocalPlayer) == "boolean" then Info.ExcludeLocalPlayer else false

            Info.Values = GetPlayers(Info.ExcludeLocalPlayer, Info.ReturnInstanceInstead)
            Info.AllowNull = true
        elseif Info.SpecialType == "Team" then
            Info.Values = GetTeams(Info.ReturnInstanceInstead)
            Info.AllowNull = true
        end

        assert(Info.Values, string.format("AddDropdown (IDX: %s): Missing dropdown value list.", tostring(Idx)))
        if not (Info.AllowNull or Info.Default) then
            Info.Default = 1
            warn(string.format("AddDropdown (IDX: %s): Missing default value, selected the first index instead. Pass `AllowNull` as true if this was intentional.", tostring(Idx)))
        end

        Info.Searchable = if typeof(Info.Searchable) == "boolean" then Info.Searchable else false
        Info.FormatDisplayValue = if typeof(Info.FormatDisplayValue) == "function" then Info.FormatDisplayValue else nil
        Info.FormatListValue = if typeof(Info.FormatListValue) == "function" then Info.FormatListValue else nil

        local Dropdown = {
            Values = Info.Values;
            Value = Info.Multi and {};
            DisabledValues = Info.DisabledValues or {};

            Multi = Info.Multi;
            Type = "Dropdown";
            SpecialType = Info.SpecialType; -- can be either "Player" or "Team"
            Visible = if typeof(Info.Visible) == "boolean" then Info.Visible else true;
            Disabled = if typeof(Info.Disabled) == "boolean" then Info.Disabled else false;
            Callback = Info.Callback or function(Value) end;
            Changed = Info.Changed or function(Value) end;

            OriginalText = Info.Text; Text = Info.Text;
            ExcludeLocalPlayer = Info.ExcludeLocalPlayer;
            ReturnInstanceInstead = Info.ReturnInstanceInstead;
        }

        local Tooltip

        local ParentObj = self
        local ToggleLabel = self.TextLabel
        local Container = self.Container

        local RelativeOffset = 0

        for _, Element in next, Container:GetChildren() do
            if not Element:IsA("UIListLayout") then
                RelativeOffset = RelativeOffset + Element.Size.Y.Offset
            end
        end

        local DropdownOuter = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 60, 0, 18);
            Visible = Dropdown.Visible;
            ZIndex = 6;
            Parent = ToggleLabel;
        })

        Library:AddToRegistry(DropdownOuter, {
            BorderColor3 = "Black";
        })

        local DropdownInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BackgroundTransparency = Library.ElementTransparency;
            Corner = 5;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DropdownOuter;
        })

        Library:AddToRegistry(DropdownInner, {
            BackgroundColor3 = "MainColor";
            BorderColor3 = "OutlineColor";
        })

        local DropdownInnerSearch
        if Info.Searchable then
            DropdownInnerSearch = Library:Create("TextBox", {
                BackgroundTransparency = 1;
                Visible = false;

                Position = UDim2.new(0, 5, 0, 0);
                Size = UDim2.new(0.9, -5, 1, 0);

                Font = Library.Font;
                PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
                PlaceholderText = "Search...";

                Text = "";
                TextColor3 = Library.FontColor;
                TextSize = 14;
                TextXAlignment = Enum.TextXAlignment.Left;

                ClearTextOnFocus = false;

                ZIndex = 7;
                Parent = DropdownOuter;
            })

            Library:AddToRegistry(DropdownInnerSearch, {
                TextColor3 = "FontColor";
            })
        end

        local DropdownArrow = Library:Create("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5);
            BackgroundTransparency = 1;
            Position = UDim2.new(1, -16, 0.5, 0);
            Size = UDim2.new(0, 12, 0, 12);
            Image = CustomImageManager.GetAsset("DropdownArrow");
            ZIndex = 8;
            Parent = DropdownInner;
        })

        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            TextSize = 14;
            Text = "--";
            TextXAlignment = Enum.TextXAlignment.Left;
            TextWrapped = false;
            TextTruncate = Enum.TextTruncate.AtEnd;
            RichText = true;
            ZIndex = 7;
            Parent = DropdownInner;
        })

        Library:OnHighlight(DropdownOuter, DropdownOuter,
            { BorderColor3 = "AccentColor" },
            { BorderColor3 = "Black" },
            function()
                return not Dropdown.Disabled
            end
        )

        if typeof(Info.Tooltip) == "string" or typeof(Info.DisabledTooltip) == "string" then
            Tooltip = Library:AddToolTip(Info.Tooltip, Info.DisabledTooltip, DropdownOuter)
            Tooltip.Disabled = Dropdown.Disabled
        end

        local MAX_DROPDOWN_ITEMS = if typeof(Info.MaxVisibleDropdownItems) == "number" then math.clamp(Info.MaxVisibleDropdownItems, 4, 16) else 8

        local ListOuter = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0);
            ZIndex = 20;
            Visible = false;
            Parent = ScreenGui;
        })

        local OpenedXSizeForList = 0

        local ListToken = 0

        local function RecalculateListPosition()
            ListOuter.Position = UDim2.fromOffset(DropdownOuter.AbsolutePosition.X, DropdownOuter.AbsolutePosition.Y + DropdownOuter.Size.Y.Offset + 1)
        end

        local function RecalculateListSize(YSize)
            local Y = YSize or math.clamp(GetTableSize(Dropdown.Values) * (20 * DPIScale), 0, MAX_DROPDOWN_ITEMS * (20 * DPIScale)) + 1
            ListOuter.Size = UDim2.fromOffset(ListOuter.Visible and OpenedXSizeForList or DropdownOuter.AbsoluteSize.X + 0.5, Y)
        end

        RecalculateListPosition()
        RecalculateListSize()

        DropdownOuter:GetPropertyChangedSignal("AbsolutePosition"):Connect(RecalculateListPosition)
        DropdownOuter:GetPropertyChangedSignal("AbsoluteSize"):Connect(RecalculateListSize)

        local ListInner = Library:Create("Frame", {
            ClipsDescendants = true;
            BackgroundColor3 = Library.MainColor;
            BackgroundTransparency = 0;
            Corner = 5;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListOuter;
        })

        Library:AddToRegistry(ListInner, {
            BackgroundColor3 = "MainColor";
            BorderColor3 = "OutlineColor";
        })

        local Scrolling = Library:Create("ScrollingFrame", {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            CanvasSize = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListInner;

            TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",

            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor,
        })

        Library:AddToRegistry(Scrolling, {
            ScrollBarImageColor3 = "AccentColor"
        })

        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 0);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Scrolling;
        })

        function Dropdown:UpdateColors()
            ItemList.TextColor3 = Dropdown.Disabled and Library.DisabledAccentColor or Library.FontColor
            DropdownArrow.ImageColor3 = Dropdown.Disabled and Library.DisabledAccentColor or Library.FontColor
        end

        function Dropdown:GenerateDisplayText(SelectedValue)
            local Str = ""

            if Info.Multi and typeof(SelectedValue) == "table" then
                for Idx, Value in next, Dropdown.Values do
                    if SelectedValue[Value] then
                        Str = Str .. tostring(Info.FormatDisplayValue and Info.FormatDisplayValue(Value) or Value) .. ", "
                    end
                end

                Str = Str:sub(1, #Str - 2)
                Str = (Str == "" and "--" or Str)
            else
                if not SelectedValue then
                    return "--"
                end

                Str = tostring(Info.FormatDisplayValue and Info.FormatDisplayValue(SelectedValue) or SelectedValue)
            end

            return Str
        end

        function Dropdown:Display()
            local Str = Dropdown:GenerateDisplayText(Dropdown.Value)
            ItemList.Text = Str

            local X = ListOuter.Visible and OpenedXSizeForList or Library:GetTextBounds(ItemList.Text, Library.Font, ItemList.TextSize, Vector2.new(ToggleLabel.AbsoluteSize.X, math.huge)) + 26
            DropdownOuter.Size = UDim2.new(0, X, 0, 18)
        end

        function Dropdown:GetActiveValues()
            if Info.Multi then
                local T = {}

                for Value, Bool in next, Dropdown.Value do
                    table.insert(T, Value)
                end

                return T
            else
                return Dropdown.Value and 1 or 0
            end
        end

        function Dropdown:BuildDropdownList()
            local Values = Dropdown.Values
            local DisabledValues = Dropdown.DisabledValues
            local Buttons = {}

            for _, Element in next, Scrolling:GetChildren() do
                if not Element:IsA("UIListLayout") then
                    Element:Destroy()
                end
            end

            local Count = 0
            OpenedXSizeForList = DropdownOuter.AbsoluteSize.X + 0.5

            for Idx, Value in next, Values do
                local StringValue = tostring(Info.FormatListValue and Info.FormatListValue(Value) or Value)
                if Info.Searchable and not string.lower(StringValue):match(string.lower(DropdownInnerSearch.Text)) then
                    continue
                end

                local IsDisabled = table.find(DisabledValues, StringValue)
                local Table = {}

                Count = Count + 1

                local Button = Library:Create("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = Library.MainColor;
                    BackgroundTransparency = 1;
                    Corner = 5;
                    Size = UDim2.new(1, -1, 0, 20);
                    Text = "";
                    ZIndex = 23;
                    Parent = Scrolling;
                })

                Library:AddToRegistry(Button, {
                    BackgroundColor3 = "MainColor";
                    BorderColor3 = "OutlineColor";
                })

                local ButtonLabel = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, -6, 1, 0);
                    Position = UDim2.new(0, 6, 0, 0);
                    TextSize = 14;
                    Text = Info.FormatDisplayValue and tostring(Info.FormatDisplayValue(StringValue)) or StringValue;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    RichText = true;
                    ZIndex = 25;
                    Parent = Button;
                })

                Button:SetAttribute("HoverRow", true)

                Library:OnHighlight(Button, Button,
                    { BorderColor3 = IsDisabled and "DisabledAccentColor" or "AccentColor", ZIndex = 24 },
                    { BorderColor3 = "OutlineColor", ZIndex = 23 }
                )

                local Selected

                if Info.Multi then
                    Selected = Dropdown.Value[Value]
                else
                    Selected = Dropdown.Value == Value
                end

                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value]
                    else
                        Selected = Dropdown.Value == Value
                    end

                    ButtonLabel.TextColor3 = Selected and Library.AccentColor or (IsDisabled and Library.DisabledAccentColor or Library.FontColor)
                    Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and "AccentColor" or (IsDisabled and "DisabledAccentColor" or "FontColor")
                end

                if not IsDisabled then
                    Button.MouseButton1Click:Connect(function(Input)
                        local Try = not Selected

                        if Dropdown:GetActiveValues() == 1 and (not Try) and (not Info.AllowNull) then
                        else
                            if Info.Multi then
                                Selected = Try

                                if Selected then
                                    Dropdown.Value[Value] = true
                                else
                                    Dropdown.Value[Value] = nil
                                end
                            else
                                Selected = Try

                                if Selected then
                                    Dropdown.Value = Value
                                else
                                    Dropdown.Value = nil
                                end

                                for _, OtherButton in next, Buttons do
                                    OtherButton:UpdateButton()
                                end
                            end

                            Table:UpdateButton()
                            Dropdown:Display()
                            
                            Library:UpdateDependencyBoxes()
                            Library:UpdateDependencyGroupboxes()
                            Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                            Library:SafeCallback(Dropdown.Changed, Dropdown.Value)

                            Library:AttemptSave()
                        end
                    end)
                end

                Table:UpdateButton()
                Dropdown:Display()

                local Str = Dropdown:GenerateDisplayText(Value)
                local X = Library:GetTextBounds(Str, Library.Font, ItemList.TextSize, Vector2.new(ToggleLabel.AbsoluteSize.X, math.huge)) + 26
                if X > OpenedXSizeForList then
                    OpenedXSizeForList = X
                end

                Buttons[Button] = Table
            end
            
            Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * (20 * DPIScale)) + 1)

            -- Workaround for silly roblox bug - not sure why it happens but sometimes the dropdown list will be empty
            -- ... and for some reason refreshing the Visible property fixes the issue??????? thanks roblox!
            Scrolling.Visible = false
            Scrolling.Visible = true

            local Y = math.clamp(Count * (20 * DPIScale), 0, MAX_DROPDOWN_ITEMS * (20 * DPIScale)) + 1
            RecalculateListSize(Y)
        end

        function Dropdown:SetValues(NewValues)
            if NewValues then
                Dropdown.Values = NewValues
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddValues(NewValues)
            if typeof(NewValues) == "table" then
                for _, val in pairs(NewValues) do
                    table.insert(Dropdown.Values, val)
                end
            elseif typeof(NewValues) == "string" then
                table.insert(Dropdown.Values, NewValues)
            else
                return
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetDisabledValues(NewValues)
            if NewValues then
                Dropdown.DisabledValues = NewValues
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddDisabledValues(DisabledValues)
            if typeof(DisabledValues) == "table" then
                for _, val in pairs(DisabledValues) do
                    table.insert(Dropdown.DisabledValues, val)
                end
            elseif typeof(DisabledValues) == "string" then
                table.insert(Dropdown.DisabledValues, DisabledValues)
            else
                return
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetVisible(Visibility)
            Dropdown.Visible = Visibility

            DropdownOuter.Visible = Dropdown.Visible
            if not Dropdown.Visible then 
                Dropdown:CloseDropdown()
            end
        end

        function Dropdown:SetDisabled(Disabled)
            Dropdown.Disabled = Disabled

            if Tooltip then
                Tooltip.Disabled = Disabled
            end

            if Disabled then
                Dropdown:CloseDropdown()
            end

            Dropdown:Display()
            Dropdown:UpdateColors()
        end

        function Dropdown:OpenDropdown()
            if Dropdown.Disabled then
                return
            end

            if Library.IsMobile then
                Library.CanDrag = false
            end

            if Info.Searchable then
                ItemList.Visible = false
                DropdownInnerSearch.Text = ""
                DropdownInnerSearch.Visible = true
            end
            
            ListOuter.Visible = true
            Library.OpenedFrames[ListOuter] = true

            ListToken = ListToken + 1
            TweenService:Create(DropdownArrow, ArrowTweenInfo, { Rotation = 180 }):Play()

            Dropdown:Display()
            RecalculateListSize()

            local FullSize = ListOuter.Size
            ListOuter.Size = UDim2.fromOffset(FullSize.X.Offset, 0)
            TweenService:Create(ListOuter, ListTweenInfo, { Size = FullSize }):Play()
        end

        function Dropdown:CloseDropdown()
            if Library.IsMobile then         
                Library.CanDrag = true
            end

            if Info.Searchable then
                DropdownInnerSearch.Text = ""
                DropdownInnerSearch.Visible = false
                ItemList.Visible = true
            end
        
            Library.OpenedFrames[ListOuter] = nil

            Dropdown:Display()

            ListToken = ListToken + 1
            local Token = ListToken
            TweenService:Create(DropdownArrow, ArrowTweenInfo, { Rotation = 0 }):Play()

            if ListOuter.Visible then
                TweenService:Create(ListOuter, ListTweenInfo, { Size = UDim2.fromOffset(ListOuter.Size.X.Offset, 0) }):Play()

                task.delay(0.2, function()
                    if Token == ListToken then
                        ListOuter.Visible = false
                        RecalculateListSize()
                    end
                end)
            else
                RecalculateListSize()
            end
        end

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func

            -- if Dropdown.Disabled then
            --     return;
            -- end;

            -- Library:SafeCallback(Func, Dropdown.Value);
        end

        function Dropdown:SetValue(Value)
            if Dropdown.Multi then
                local Table = {}

                for Val, Active in pairs(Value or {}) do
                    if typeof(Active) ~= "boolean" then
                        Table[Active] = true
                    elseif Active and table.find(Dropdown.Values, Val) then
                        Table[Val] = true
                    end
                end

                Dropdown.Value = Table
            else
                if table.find(Dropdown.Values, Value) then
                    Dropdown.Value = Value
                elseif not Value then
                    Dropdown.Value = nil
                end
            end

            Dropdown:BuildDropdownList()

            if not Dropdown.Disabled then
                Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
            end
        end

        function Dropdown:SetText(...)
            -- This is an Compat dropdown for Toggles, it doesn't have an TextLabel --
            return
        end

        DropdownOuter.InputBegan:Connect(function(Input)
            if Dropdown.Disabled then
                return
            end

            if (Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame()) or Input.UserInputType == Enum.UserInputType.Touch then
                if ListOuter.Visible then
                    Dropdown:CloseDropdown()
                else
                    Dropdown:OpenDropdown()
                end
            end
        end)

        if Info.Searchable then
            DropdownInnerSearch:GetPropertyChangedSignal("Text"):Connect(function()
                Dropdown:BuildDropdownList()
            end)
        end

        InputService.InputBegan:Connect(function(Input)
            if Dropdown.Disabled then
                return
            end

            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local AbsPos, AbsSize = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - (20 * DPIScale) - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    Dropdown:CloseDropdown()
                end
            end
        end)

        Dropdown:BuildDropdownList()
        Dropdown:Display()

        local Defaults = {}

        if typeof(Info.Default) == "string" then
            local DefaultIdx = table.find(Dropdown.Values, Info.Default)
            if DefaultIdx then
                table.insert(Defaults, DefaultIdx)
            end

        elseif typeof(Info.Default) == "table" then
            for _, Value in next, Info.Default do
                local DefaultIdx = table.find(Dropdown.Values, Value)
                if DefaultIdx then
                    table.insert(Defaults, DefaultIdx)
                end
            end

        elseif typeof(Info.Default) == "number" and Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end

        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i]
                if Info.Multi then
                    Dropdown.Value[Dropdown.Values[Index]] = true
                else
                    Dropdown.Value = Dropdown.Values[Index]
                end

                if (not Info.Multi) then break end
            end

            Dropdown:BuildDropdownList()
            Dropdown:Display()
        end

        task.delay(0.1, Dropdown.UpdateColors, Dropdown)

        Dropdown.DisplayFrame = DropdownOuter
        if ParentObj.Addons then
            table.insert(ParentObj.Addons, Dropdown)
        end

        Dropdown.Default = Defaults
        Dropdown.DefaultValues = Dropdown.Values

        Options[Idx] = Dropdown

        return self
    end

    BaseAddons.__index = BaseAddonsFuncs
    BaseAddons.__namecall = function(Table, Key, ...)
        return BaseAddonsFuncs[Key](...)
    end
end

--// Groupbox Addons \\--
local BaseGroupbox = {}
do
    local BaseGroupboxFuncs = {}

    function BaseGroupboxFuncs:AddBlank(Size, Visible)
        local Groupbox = self
        local Container = Groupbox.Container

        return Library:Create("Frame", {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, Size);
            Visible = if typeof(Visible) == "boolean" then Visible else true;
            ZIndex = 1;
            Parent = Container;
        })
    end

    function BaseGroupboxFuncs:AddDivider(...)
        local Params = select(1, ...)
        local Text
        local MarginTop = 2
        local MarginBottom = 9

        if typeof(Params) == "table" then
            Text = Params.Text
            MarginTop = Params.MarginTop or Params.Margin or 2
            MarginBottom = Params.MarginBottom or Params.Margin or 9
        elseif typeof(Params) == "string" then
            Text = Params
        end

        local Groupbox = self
        local Container = self.Container

        Groupbox:AddBlank(MarginTop)

        local DividerOuter
        if Text then
            DividerOuter = Library:Create("Frame", {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, -4, 0, 14);
                ZIndex = 5;
                Parent = Container;
            })

            Library:CreateLabel({
                AutomaticSize = Enum.AutomaticSize.X;
                BackgroundTransparency = 1;
                Position = UDim2.fromScale(0.5, 0.5);
                AnchorPoint = Vector2.new(0.5, 0.5);
                Size = UDim2.fromScale(1, 0);
                Text = Text;
                TextSize = 12;
                TextTransparency = 0.2;
                TextXAlignment = Enum.TextXAlignment.Center;
                ZIndex = 6;
                Parent = DividerOuter;
                RichText = true;
            })

            local X = select(1, Library:GetTextBounds(Text, Library.Font, 12 * DPIScale))
            local SizeX = math.floor(X / 2) + (10 * DPIScale)

            local LeftLine = Library:Create("Frame", {
                AnchorPoint = Vector2.new(0, 0.5);
                BackgroundColor3 = Library.OutlineColor;
                Position = UDim2.fromScale(0, 0.5);
                Size = UDim2.new(0.5, -SizeX, 0, 1);
                ZIndex = 6;
                Parent = DividerOuter;
            })

            local RightLine = Library:Create("Frame", {
                AnchorPoint = Vector2.new(1, 0.5);
                BackgroundColor3 = Library.OutlineColor;
                Position = UDim2.fromScale(1, 0.5);
                Size = UDim2.new(0.5, -SizeX, 0, 1);
                ZIndex = 6;
                Parent = DividerOuter;
            })

            Library:AddToRegistry(LeftLine, { BackgroundColor3 = "OutlineColor"; })
            Library:AddToRegistry(RightLine, { BackgroundColor3 = "OutlineColor"; })
        else
            DividerOuter = Library:Create("Frame", {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, -4, 0, 1);
                ZIndex = 5;
                Parent = Container;
            })

            local DividerLine = Library:Create("Frame", {
                BackgroundColor3 = Library.OutlineColor;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 6;
                Parent = DividerOuter;
            })

            Library:AddToRegistry(DividerLine, {
                BackgroundColor3 = "OutlineColor";
            })
        end

        Groupbox:AddBlank(MarginBottom)
        Groupbox:Resize()

        table.insert(Groupbox.Elements, {
            Holder = DividerOuter,
            Type = "Divider",
        })
    end

    function BaseGroupboxFuncs:AddLabel(...)
        local Data = {}

        if select(2, ...) ~= nil and typeof(select(2, ...)) == "table" then
            if select(1, ...) ~= nil then
                assert(typeof(select(1, ...)) == "string", "Expected string for Idx, got " .. typeof(select(1, ...)))
            end
            
            local Params = select(2, ...)

            Data.Text = Params.Text or ""
            Data.DoesWrap = Params.DoesWrap or false
            Data.Idx = select(1, ...)
        else
            Data.Text = select(1, ...) or ""
            Data.DoesWrap = select(2, ...) or false
            Data.Idx = select(3, ...) or nil
        end

        Data.OriginalText = Data.Text
        
        local Label = {
            Type = "Label"
        }

        -- local Blank = nil
        local Groupbox = self
        local Container = Groupbox.Container

        local TextLabel = Library:CreateLabel({
            Size = UDim2.new(1, -4, 0, 18);
            TextSize = 12;
            Text = Data.Text;
            TextWrapped = Data.DoesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
            RichText = true;
        })
        Library:DimLabel(TextLabel)

        if Data.DoesWrap then
            local Y = select(2, Library:GetTextBounds(Data.Text, Library.Font, 12 * DPIScale, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
            TextLabel.Size = UDim2.new(1, -4, 0, Y)
        else
            Library:Create("UIListLayout", {
                Padding = UDim.new(0, 4 * DPIScale);
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right;
                VerticalAlignment = Enum.VerticalAlignment.Center;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TextLabel;
            })
        end

        Label.TextLabel = TextLabel
        Label.Container = Container

        function Label:SetText(Text)
            TextLabel.Text = Text

            if Data.DoesWrap then
                local Y = select(2, Library:GetTextBounds(Text, Library.Font, 12 * DPIScale, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
                TextLabel.Size = UDim2.new(1, -4, 0, Y)
            end

            Groupbox:Resize()
        end

        if (not Data.DoesWrap) then
            setmetatable(Label, BaseAddons)
        end

        -- Blank =
        Groupbox:AddBlank(8)
        Groupbox:Resize()

        table.insert(Groupbox.Elements, Label)
        
        if Data.Idx then
            -- Options[Data.Idx] = Label;
            Labels[Data.Idx] = Label
        else
            table.insert(Labels, Label)
        end

        return Label
    end
    
    function BaseGroupboxFuncs:AddButton(...)
        local Button = typeof(select(1, ...)) == "table" and select(1, ...) or {
            Text = select(1, ...),
            Func = select(2, ...)
        }
        Button.OriginalText = Button.Text
        Button.Func = Button.Func or Button.Callback
        assert(typeof(Button.Func) == "function", "AddButton: `Func` callback is missing.")

        local Blank = nil
        local Groupbox = self
        local Container = Groupbox.Container
        local IsVisible = if typeof(Button.Visible) == "boolean" then Button.Visible else true

        local function CreateBaseButton(Button)
            local Outer = Library:Create("Frame", {
                BackgroundColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -4, 0, 28);
                Visible = IsVisible;
                ZIndex = 5;
            })

            local Inner = Library:Create("Frame", {
                BackgroundColor3 = Library.MainColor;
                BackgroundTransparency = Library.ElementTransparency;
                Corner = 8;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 6;
                Parent = Outer;
            })

            local Label = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0);
                TextSize = 12;
                Text = Button.Text;
                ZIndex = 6;
                Parent = Inner;
                RichText = true;
            })

            Library:AddToRegistry(Outer, {
                BorderColor3 = "Black";
            })

            Library:AddToRegistry(Inner, {
                BackgroundColor3 = "MainColor";
                BorderColor3 = "OutlineColor";
            })
            Library:AddStroke(Inner, "OutlineColor")

            Library:OnHighlight(Outer, Outer,
                { BorderColor3 = "AccentColor" },
                { BorderColor3 = "Black" }
            )

            return Outer, Inner, Label
        end

        local function InitEvents(Button)
            local function WaitForEvent(event, timeout, validator)
                local bindable = Instance.new("BindableEvent")
                local connection = event:Once(function(...)

                    if typeof(validator) == "function" and validator(...) then
                        bindable:Fire(true)
                    else
                        bindable:Fire(false)
                    end
                end)
                task.delay(timeout, function()
                    connection:disconnect()
                    bindable:Fire(false)
                end)
                return bindable.Event:Wait()
            end

            local function ValidateClick(Input)
                if Library:MouseIsOverOpenedFrame(Input) then
                    return false
                end

                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    return true
                elseif Input.UserInputType == Enum.UserInputType.Touch then
                    return true
                else
                    return false
                end
            end

            Button.Outer.InputBegan:Connect(function(Input)
                if Button.Disabled then
                    return
                end

                if not ValidateClick(Input) then return end
                if Button.Locked then return end

                Library:FlashButton(Button.Inner)

                if Button.DoubleClick then
                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = "AccentColor" })

                    Button.Label.TextColor3 = Library.AccentColor
                    Button.Label.Text = "Are you sure?"
                    Button.Locked = true

                    local clicked = WaitForEvent(Button.Outer.InputBegan, 0.5, ValidateClick)

                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = "FontColor" })

                    Button.Label.TextColor3 = Library.FontColor
                    Button.Label.Text = Button.Text
                    task.defer(rawset, Button, "Locked", false)

                    if clicked then
                        Library:SafeCallback(Button.Func)
                    end

                    return
                end

                Library:SafeCallback(Button.Func)
            end)
        end

        Button.Outer, Button.Inner, Button.Label = CreateBaseButton(Button)
        Button.Outer.Parent = Container

        InitEvents(Button)

        function Button:AddButton(...)
            local SubButton = typeof(select(1, ...)) == "table" and select(1, ...) or {
                Text = select(1, ...),
                Func = select(2, ...)
            }
            SubButton.OriginalText = SubButton.Text
            SubButton.Func = SubButton.Func or SubButton.Callback
            assert(typeof(SubButton.Func) == "function", "AddButton: `Func` callback is missing.")

            self.Outer.Size = UDim2.new(0.5, -2, 0, 28 * DPIScale)

            SubButton.Outer, SubButton.Inner, SubButton.Label = CreateBaseButton(SubButton)

            SubButton.Outer.Position = UDim2.new(1, 3, 0, 0)
            SubButton.Outer.Size = UDim2.new(1, -3, 0, self.Outer.AbsoluteSize.Y)
            SubButton.Outer.Parent = self.Outer

            function SubButton:UpdateColors()
                SubButton.Label.TextColor3 = SubButton.Disabled and Library.DisabledAccentColor or Library.FontColor
            end

            function SubButton:AddToolTip(tooltip, disabledTooltip)
                if typeof(tooltip) == "string" or typeof(disabledTooltip) == "string" then
                    if SubButton.TooltipTable then
                        SubButton.TooltipTable:Destroy()
                    end
                
                    SubButton.TooltipTable = Library:AddToolTip(tooltip, disabledTooltip, self.Outer)
                    SubButton.TooltipTable.Disabled = SubButton.Disabled
                end

                return SubButton
            end

            function SubButton:SetDisabled(Disabled)
                SubButton.Disabled = Disabled

                if SubButton.TooltipTable then
                    SubButton.TooltipTable.Disabled = Disabled
                end

                SubButton:UpdateColors()
            end

            function SubButton:SetText(Text)
                if typeof(Text) == "string" then
                    SubButton.Text = Text
                    SubButton.Label.Text = SubButton.Text
                end
            end

            if typeof(SubButton.Tooltip) == "string" or typeof(SubButton.DisabledTooltip) == "string" then
                SubButton.TooltipTable = SubButton:AddToolTip(SubButton.Tooltip, SubButton.DisabledTooltip, SubButton.Outer)
                SubButton.TooltipTable.Disabled = SubButton.Disabled
            end

            task.delay(0.1, SubButton.UpdateColors, SubButton)
            InitEvents(SubButton)

            table.insert(Buttons, SubButton)
            return SubButton
        end

        function Button:UpdateColors()
            Button.Label.TextColor3 = Button.Disabled and Library.DisabledAccentColor or Library.FontColor
        end

        function Button:AddToolTip(tooltip, disabledTooltip)
            if typeof(tooltip) == "string" or typeof(disabledTooltip) == "string" then
                if Button.TooltipTable then
                    Button.TooltipTable:Destroy()
                end

                Button.TooltipTable = Library:AddToolTip(tooltip, disabledTooltip, self.Outer)
                Button.TooltipTable.Disabled = Button.Disabled
            end

            return Button
        end

        if typeof(Button.Tooltip) == "string" or typeof(Button.DisabledTooltip) == "string" then
            Button.TooltipTable = Button:AddToolTip(Button.Tooltip, Button.DisabledTooltip, Button.Outer)
            Button.TooltipTable.Disabled = Button.Disabled
        end

        function Button:SetVisible(Visibility)
            IsVisible = Visibility

            Button.Outer.Visible = IsVisible
            if Blank then Blank.Visible = IsVisible end

            Groupbox:Resize()
        end

        function Button:SetText(Text)
            if typeof(Text) == "string" then
                Button.Text = Text
                Button.Label.Text = Button.Text
            end
        end

        function Button:SetDisabled(Disabled)
            Button.Disabled = Disabled

            if Button.TooltipTable then
                Button.TooltipTable.Disabled = Disabled
            end

            Button:UpdateColors()
        end

        task.delay(0.1, Button.UpdateColors, Button)
        Blank = Groupbox:AddBlank(8, IsVisible)
        Groupbox:Resize()

        table.insert(Groupbox.Elements, Button)
        table.insert(Buttons, Button)

        return Button
    end

    function BaseGroupboxFuncs:AddInput(Idx, Info)
        assert(Info.Text, string.format("AddInput (IDX: %s): Missing `Text` string.", tostring(Idx)))

        Info.ClearTextOnFocus = if typeof(Info.ClearTextOnFocus) == "boolean" then Info.ClearTextOnFocus else true

        local Textbox = {
            Value = Info.Default or "";
            Numeric = Info.Numeric or false;
            Finished = Info.Finished or false;
            Visible = if typeof(Info.Visible) == "boolean" then Info.Visible else true;
            Disabled = if typeof(Info.Disabled) == "boolean" then Info.Disabled else false;
            AllowEmpty = if typeof(Info.AllowEmpty) == "boolean" then Info.AllowEmpty else true;
            EmptyReset = if typeof(Info.EmptyReset) == "string" then Info.EmptyReset else "---";
            Type = "Input";

            Callback = Info.Callback or function(Value) end;
        }

        local Groupbox = self
        local Container = Groupbox.Container
        local Blank

        local InputLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 14);
            TextSize = 12;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        })
        Library:DimLabel(InputLabel)

        Groupbox:AddBlank(5)

        local TextBoxOuter = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 30);
            ZIndex = 5;
            Parent = Container;
        })

        local TextBoxInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BackgroundTransparency = Library.ElementTransparency;
            Corner = 8;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = TextBoxOuter;
        })

        Library:AddToRegistry(TextBoxInner, {
            BackgroundColor3 = "MainColor";
            BorderColor3 = "OutlineColor";
        })
        Library:AddStroke(TextBoxInner, "OutlineColor")

        Library:OnHighlight(TextBoxOuter, TextBoxOuter,
            { BorderColor3 = "AccentColor" },
            { BorderColor3 = "Black" }
        )

        local TooltipTable
        if typeof(Info.Tooltip) == "string" or typeof(Info.DisabledTooltip) == "string" then
            TooltipTable = Library:AddToolTip(Info.Tooltip, Info.DisabledTooltip, TextBoxOuter)
            TooltipTable.Disabled = Textbox.Disabled
        end

        local TextBoxContainer = Library:Create("Frame", {
            BackgroundTransparency = 1;
            ClipsDescendants = true;

            Position = UDim2.new(0, 10, 0, 0);
            Size = UDim2.new(1, -20, 1, 0);

            ZIndex = 7;
            Parent = TextBoxInner;
        })

        local Box = Library:Create("TextBox", {
            BackgroundTransparency = 1;

            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromScale(5, 1),

            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(110, 110, 120);
            PlaceholderText = Info.Placeholder or "";

            Text = Info.Default or (if Textbox.AllowEmpty == false then Textbox.EmptyReset else "---");
            TextColor3 = Library.FontColor;
            TextSize = 12;
            TextXAlignment = Enum.TextXAlignment.Left;

            TextEditable = not Textbox.Disabled;
            ClearTextOnFocus = not Textbox.Disabled and Info.ClearTextOnFocus;

            ZIndex = 7;
            Parent = TextBoxContainer;
        })

        Library:AddToRegistry(Box, {
            TextColor3 = "FontColor";
        })

        function Textbox:OnChanged(Func)
            Textbox.Changed = Func

            -- if Textbox.Disabled then
            --     return;
            -- end;

            -- Library:SafeCallback(Func, Textbox.Value);
        end

        function Textbox:UpdateColors()
            Box.TextColor3 = Textbox.Disabled and Library.DisabledAccentColor or Library.FontColor

            Library.RegistryMap[Box].Properties.TextColor3 = Textbox.Disabled and "DisabledAccentColor" or "FontColor"
        end

        function Textbox:Display()
            TextBoxOuter.Visible = Textbox.Visible
            InputLabel.Visible = Textbox.Visible
            if Blank then Blank.Visible = Textbox.Visible end

            Groupbox:Resize()
        end

        function Textbox:SetValue(Text)
            if not Textbox.AllowEmpty and Trim(Text) == "" then
                Text = Textbox.EmptyReset
            end

            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength)
            end

            if Textbox.Numeric then
                if #tostring(Text) > 0 and not tonumber(Text) then
                    Text = Textbox.Value
                end
            end

            Textbox.Value = Text
            Box.Text = Text

            if not Textbox.Disabled then
                Library:SafeCallback(Textbox.Callback, Textbox.Value)
                Library:SafeCallback(Textbox.Changed, Textbox.Value)
            end
        end

        function Textbox:SetVisible(Visibility)
            Textbox.Visible = Visibility

            Textbox:Display()
        end

        function Textbox:SetDisabled(Disabled)
            Textbox.Disabled = Disabled

            Box.TextEditable = not Disabled
            Box.ClearTextOnFocus = not Disabled and Info.ClearTextOnFocus

            if TooltipTable then
                TooltipTable.Disabled = Disabled
            end

            Textbox:UpdateColors()
        end

        if Textbox.Finished then
            Box.FocusLost:Connect(function(enter)
                if not enter then return end

                Textbox:SetValue(Box.Text)
                Library:AttemptSave()
            end)
        else
            Box:GetPropertyChangedSignal("Text"):Connect(function()
                Textbox:SetValue(Box.Text)
                Library:AttemptSave()
            end)
        end

        -- https://devforum.roblox.com/t/how-to-make-textboxes-follow-current-cursor-position/1368429/6
        -- thank you nicemike40 :)

        local function Update()
            local PADDING = 2
            local reveal = TextBoxContainer.AbsoluteSize.X

            if not Box:IsFocused() or Box.TextBounds.X <= reveal - 2 * PADDING then
                -- we aren't focused, or we fit so be normal
                Box.Position = UDim2.new(0, PADDING, 0, 0)
            else
                -- we are focused and don't fit, so adjust position
                local cursor = Box.CursorPosition
                if cursor ~= -1 then
                    -- calculate pixel width of text from start to cursor
                    local subtext = string.sub(Box.Text, 1, cursor-1)
                    local width = TextService:GetTextSize(subtext, Box.TextSize, Box.Font, Vector2.new(math.huge, math.huge)).X

                    -- check if we're inside the box with the cursor
                    local currentCursorPos = Box.Position.X.Offset + width

                    -- adjust if necessary
                    if currentCursorPos < PADDING then
                        Box.Position = UDim2.fromOffset(PADDING-width, 0)
                    elseif currentCursorPos > reveal - PADDING - 1 then
                        Box.Position = UDim2.fromOffset(reveal-width-PADDING-1, 0)
                    end
                end
            end
        end

        task.spawn(Update)

        Box:GetPropertyChangedSignal("Text"):Connect(Update)
        Box:GetPropertyChangedSignal("CursorPosition"):Connect(Update)
        Box.FocusLost:Connect(Update)
        Box.Focused:Connect(Update)

        Blank = Groupbox:AddBlank(10, Textbox.Visible)
        task.delay(0.1, Textbox.UpdateColors, Textbox)
        Textbox:Display()
        Groupbox:Resize()

        Textbox.Default = Textbox.Value

        table.insert(Groupbox.Elements, Textbox)
        Options[Idx] = Textbox

        return Textbox
    end

    function BaseGroupboxFuncs:AddToggle(Idx, Info)
        assert(Info.Text, string.format("AddInput (IDX: %s): Missing `Text` string.", tostring(Idx)))

        local Toggle = {
            Value = Info.Default or false;
            Type = "Toggle";
            Visible = if typeof(Info.Visible) == "boolean" then Info.Visible else true;
            Disabled = if typeof(Info.Disabled) == "boolean" then Info.Disabled else false;
            Risky = if typeof(Info.Risky) == "boolean" then Info.Risky else false;
            OriginalText = Info.Text; Text = Info.Text;

            Callback = Info.Callback or function(Value) end;
            Addons = {};
        }

        local Blank
        local Tooltip
        local Groupbox = self
        local Container = Groupbox.Container

        local ToggleContainer = Library:Create("Frame", {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, -4, 0, 18);
            Visible = Toggle.Visible;
            ZIndex = 5;
            Parent = Container;
        })

        local ToggleOuter = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 18, 0, 18);
            Visible = Toggle.Visible;
            ZIndex = 5;
            Parent = ToggleContainer;
        })

        Library:AddToRegistry(ToggleOuter, {
            BorderColor3 = "Black";
        })

        local ToggleInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BackgroundTransparency = Library.ElementTransparency;
            Corner = 5;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = ToggleOuter;
        })

        Library:AddToRegistry(ToggleInner, {
            BackgroundColor3 = "MainColor";
        })

        local ToggleStroke = Library:AddStroke(ToggleInner, "OutlineColor")

        -- tick shown while the toggle is on: a lucide check when the icon module loaded, a small dot otherwise
        local CheckIcon = Library:GetIcon("check")
        local CheckMark
        local CheckProp

        if CheckIcon then
            CheckProp = "ImageTransparency"
            CheckMark = Library:Create("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5);
                BackgroundTransparency = 1;
                Image = CheckIcon.Url;
                ImageColor3 = Library.BackgroundColor;
                ImageRectOffset = CheckIcon.ImageRectOffset;
                ImageRectSize = CheckIcon.ImageRectSize;
                ImageTransparency = 1;
                Position = UDim2.fromScale(0.5, 0.5);
                Size = UDim2.fromOffset(12, 12);
                ZIndex = 7;
                Parent = ToggleInner;
            })

            Library:AddToRegistry(CheckMark, {
                ImageColor3 = "BackgroundColor";
            })
        else
            CheckProp = "BackgroundTransparency"
            CheckMark = Library:Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5);
                BackgroundColor3 = Library.BackgroundColor;
                BackgroundTransparency = 1;
                Corner = 2;
                Position = UDim2.fromScale(0.5, 0.5);
                Size = UDim2.fromOffset(8, 8);
                ZIndex = 7;
                Parent = ToggleInner;
            })

            Library:AddToRegistry(CheckMark, {
                BackgroundColor3 = "BackgroundColor";
            })
        end

        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(1, -28, 1, 0); -- size of toggle box (18) + gap (10)
            Position = UDim2.new(0, 28, 0, 0);
            TextSize = 12;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 6;
            Parent = ToggleContainer;
            RichText = true;
        })

        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 6);
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            VerticalAlignment = Enum.VerticalAlignment.Center;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ToggleLabel;
        })

        -- small "?" badge on the right with a hover tooltip
        local HelpBadge
        if typeof(Info.Help) == "string" then
            HelpBadge = Library:Create("Frame", {
                BackgroundColor3 = Library.MainColor;
                Corner = 8;
                LayoutOrder = 100;
                Size = UDim2.fromOffset(16, 16);
                ZIndex = 6;
                Parent = ToggleLabel;
            })

            Library:AddToRegistry(HelpBadge, {
                BackgroundColor3 = "MainColor";
            })
            Library:AddStroke(HelpBadge, "OutlineColor")

            Library:DimLabel(Library:CreateLabel({
                Size = UDim2.fromScale(1, 1);
                Text = "?";
                TextSize = 10;
                ZIndex = 7;
                Parent = HelpBadge;
            }))

            Library:AddToolTip(Info.Help, nil, HelpBadge)
        end

        local ToggleRegion = Library:Create("Frame", {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 8;
            Parent = ToggleContainer;
        })

        Library:OnHighlight(ToggleRegion, ToggleOuter,
            { BorderColor3 = "AccentColor" },
            { BorderColor3 = "Black" },
            function()
                if Toggle.Disabled then
                    return false
                end

                for _, Addon in next, Toggle.Addons do
                    if Library:MouseIsOverFrame(Addon.DisplayFrame) then return false end
                end
                return true
            end
        )

        function Toggle:UpdateColors()
            Toggle:Display()
        end

        if typeof(Info.Tooltip) == "string" or typeof(Info.DisabledTooltip) == "string" then
            Tooltip = Library:AddToolTip(Info.Tooltip, Info.DisabledTooltip, ToggleRegion)
            Tooltip.Disabled = Toggle.Disabled
        end

        local ToggleReady = false

        -- the box fades between its off / on colors instead of snapping
        local function SetToggleColor(Color)
            if ToggleReady then
                ToggleInner:SetAttribute("HoverColor", nil)
                Library:TweenColor(ToggleInner, Color, 0.2)
            else
                ToggleInner.BackgroundColor3 = Color
            end
        end

        local function SetCheck(Visible)
            local Goal = Visible and 0 or 1

            if ToggleReady then
                TweenService:Create(CheckMark, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { [CheckProp] = Goal }):Play()
            else
                CheckMark[CheckProp] = Goal
            end
        end

        local function DimColor()
            return Library:GetDimColor()
        end

        function Toggle:Display()
            if Toggle.Disabled then
                ToggleLabel.TextColor3 = Library.DisabledTextColor

                SetToggleColor(Toggle.Value and Library.DisabledAccentColor or Library.MainColor)
                SetCheck(Toggle.Value)
                ToggleStroke.Color = Library.DisabledOutlineColor

                Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = Toggle.Value and "DisabledAccentColor" or "MainColor"
                Library.RegistryMap[ToggleStroke].Properties.Color = "DisabledOutlineColor"
                Library.RegistryMap[ToggleLabel].Properties.TextColor3 = "DisabledTextColor"

                return
            end

            -- off rows are dim, on rows read at full brightness
            if Toggle.Risky then
                ToggleLabel.TextColor3 = Library.RiskColor
                Library.RegistryMap[ToggleLabel].Properties.TextColor3 = "RiskColor"
            elseif Toggle.Value then
                ToggleLabel.TextColor3 = Library.FontColor
                Library.RegistryMap[ToggleLabel].Properties.TextColor3 = "FontColor"
            else
                ToggleLabel.TextColor3 = Library:GetDimColor()
                Library.RegistryMap[ToggleLabel].Properties.TextColor3 = DimColor
            end

            SetToggleColor(Toggle.Value and Library.AccentColor or Library.MainColor)
            SetCheck(Toggle.Value)
            ToggleStroke.Color = Toggle.Value and Library.AccentColor or Library.OutlineColor

            Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = Toggle.Value and "AccentColor" or "MainColor"
            Library.RegistryMap[ToggleStroke].Properties.Color = Toggle.Value and "AccentColor" or "OutlineColor"
        end

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func

            -- if Toggle.Disabled then
            --     return;
            -- end;

            -- Library:SafeCallback(Func, Toggle.Value);
        end

        function Toggle:SetValue(Bool)
            if Toggle.Disabled then
                return
            end

            Bool = (not not Bool)

            Toggle.Value = Bool
            Toggle:Display()

            for _, Addon in next, Toggle.Addons do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon.Toggled = Bool
                    Addon:Update()
                end
            end

            if not Toggle.Disabled then
                Library:SafeCallback(Toggle.Callback, Toggle.Value)
                Library:SafeCallback(Toggle.Changed, Toggle.Value)
            end

            Library:UpdateDependencyBoxes()
            Library:UpdateDependencyGroupboxes()
        end

        function Toggle:SetVisible(Visibility)
            Toggle.Visible = Visibility

            ToggleOuter.Visible = Toggle.Visible
            if Blank then Blank.Visible = Toggle.Visible end

            Groupbox:Resize()
        end

        function Toggle:SetDisabled(Disabled)
            Toggle.Disabled = Disabled

            if Tooltip then
                Tooltip.Disabled = Disabled
            end

            Toggle:Display()
        end

        function Toggle:SetText(Text)
            if typeof(Text) == "string" then
                Toggle.Text = Text
                ToggleLabel.Text = Toggle.Text
            end
        end

        ToggleRegion.InputBegan:Connect(function(Input)
            if Toggle.Disabled then
                return
            end

            if (Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame()) or Input.UserInputType == Enum.UserInputType.Touch then
                for _, Addon in next, Toggle.Addons do
                    if Library:MouseIsOverFrame(Addon.DisplayFrame) then return end
                end

                if HelpBadge and Library:MouseIsOverFrame(HelpBadge) then return end

                Toggle:SetValue(not Toggle.Value) -- Why was it not like this from the start?
                Library:AttemptSave()
            end
        end)

        if Toggle.Risky == true then
            Library:RemoveFromRegistry(ToggleLabel)

            ToggleLabel.TextColor3 = Library.RiskColor
            Library:AddToRegistry(ToggleLabel, { TextColor3 = "RiskColor" })
        end

        Toggle:Display()
        ToggleReady = true
        Blank = Groupbox:AddBlank(Info.BlankSize or 8, Toggle.Visible)
        Groupbox:Resize()

        Toggle.TextLabel = ToggleLabel
        Toggle.Container = Container
        setmetatable(Toggle, BaseAddons)

        Toggle.Default = Toggle.Value

        table.insert(Groupbox.Elements, Toggle)
        Toggles[Idx] = Toggle

        Library:UpdateDependencyBoxes()
        Library:UpdateDependencyGroupboxes()

        return Toggle
    end

    function BaseGroupboxFuncs:AddSlider(Idx, Info)
        assert(Info.Default,    string.format("AddSlider (IDX: %s): Missing default value.", tostring(Idx)))
        assert(Info.Text,       string.format("AddSlider (IDX: %s): Missing slider text.", tostring(Idx)))
        assert(Info.Min,        string.format("AddSlider (IDX: %s): Missing minimum value.", tostring(Idx)))
        assert(Info.Max,        string.format("AddSlider (IDX: %s): Missing maximum value.", tostring(Idx)))
        assert(Info.Rounding,   string.format("AddSlider (IDX: %s): Missing rounding value.", tostring(Idx)))

        local Slider = {
            Value = Info.Default;

            Min = Info.Min;
            Max = Info.Max;
            Rounding = Info.Rounding;
            MaxSize = 232;
            Type = "Slider";
            Visible = if typeof(Info.Visible) == "boolean" then Info.Visible else true;
            Disabled = if typeof(Info.Disabled) == "boolean" then Info.Disabled else false;
            OriginalText = Info.Text; Text = Info.Text;

            Prefix = typeof(Info.Prefix) == "string" and Info.Prefix or "";
            Suffix = typeof(Info.Suffix) == "string" and Info.Suffix or "";

            Callback = Info.Callback or function(Value) end;
        }

        local Blanks = {}
        local Groupbox = self
        local Container = Groupbox.Container
        local Tooltip

        -- name on the left, value on the right
        local Header = Library:Create("Frame", {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, -4, 0, 14);
            Visible = Slider.Visible;
            ZIndex = 5;
            Parent = Container;
        })

        local SliderText = Library:CreateLabel({
            Size = UDim2.new(1, -60, 1, 0);
            TextSize = 12;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Header;
            RichText = true;
        })
        Library:DimLabel(SliderText)

        local DisplayLabel = Library:CreateLabel({
            AnchorPoint = Vector2.new(1, 0);
            Position = UDim2.new(1, 0, 0, 0);
            Size = UDim2.new(0, 120, 1, 0);
            TextSize = 12;
            Text = "Infinite";
            TextXAlignment = Enum.TextXAlignment.Right;
            ZIndex = 5;
            Parent = Header;
            RichText = true;
        })
        Library:DimLabel(DisplayLabel)

        table.insert(Blanks, Groupbox:AddBlank(4, Slider.Visible))

        local SliderOuter = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 12);
            Visible = Slider.Visible;
            ZIndex = 5;
            Parent = Container;
        })

        Library:AddToRegistry(SliderOuter, {
            BorderColor3 = "Black";
        })

        -- thin track, inset so the knob never leaves the row at either end
        local SliderInner = Library:Create("Frame", {
            BackgroundColor3 = Library.OutlineColor;
            BackgroundTransparency = Library.ElementTransparency;
            Corner = 2;
            AnchorPoint = Vector2.new(0, 0.5);
            Position = UDim2.new(0, 5, 0.5, 0);
            Size = UDim2.new(1, -10, 0, 4);
            ZIndex = 6;
            Parent = SliderOuter;
        })

        Library:AddToRegistry(SliderInner, {
            BackgroundColor3 = "OutlineColor";
        })

        SliderInner:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            Slider.MaxSize = SliderInner.AbsoluteSize.X
        end)

        local Fill = Library:Create("Frame", {
            BackgroundColor3 = Library.AccentColor;
            BackgroundTransparency = Library.ElementTransparency;
            Corner = 2;
            Size = UDim2.new(0, 0, 1, 0);
            ZIndex = 7;
            Parent = SliderInner;
        })

        Library:AddToRegistry(Fill, {
            BackgroundColor3 = "AccentColor";
        })

        local Knob = Library:Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5);
            BackgroundColor3 = Library.AccentColor;
            Corner = 5;
            Position = UDim2.new(0, 0, 0.5, 0);
            Size = UDim2.fromOffset(10, 10);
            ZIndex = 8;
            Parent = SliderInner;
        })

        Library:AddToRegistry(Knob, {
            BackgroundColor3 = "AccentColor";
        })

        Library:OnHighlight(SliderOuter, SliderOuter,
            { BorderColor3 = "AccentColor" },
            { BorderColor3 = "Black" },
            function()
                return not Slider.Disabled
            end
        )

        if typeof(Info.Tooltip) == "string" or typeof(Info.DisabledTooltip) == "string" then
            Tooltip = Library:AddToolTip(Info.Tooltip, Info.DisabledTooltip, SliderOuter)
            Tooltip.Disabled = Slider.Disabled
        end

        function Slider:UpdateColors()
            if Slider.Disabled then
                SliderText.TextColor3 = Library.DisabledTextColor
                DisplayLabel.TextColor3 = Library.DisabledTextColor

                Library.RegistryMap[SliderText].Properties.TextColor3 = "DisabledTextColor"
                Library.RegistryMap[DisplayLabel].Properties.TextColor3 = "DisabledTextColor"
            else
                SliderText.TextColor3 = Library:GetDimColor()
                DisplayLabel.TextColor3 = Library.FontColor

                Library.RegistryMap[SliderText].Properties.TextColor3 = function()
                    return Library:GetDimColor()
                end
                Library.RegistryMap[DisplayLabel].Properties.TextColor3 = "FontColor"
            end

            Fill.BackgroundColor3 = Slider.Disabled and Library.DisabledAccentColor or Library.AccentColor
            Knob.BackgroundColor3 = Slider.Disabled and Library.DisabledAccentColor or Library.AccentColor

            Library.RegistryMap[Fill].Properties.BackgroundColor3 = Slider.Disabled and "DisabledAccentColor" or "AccentColor"
            Library.RegistryMap[Knob].Properties.BackgroundColor3 = Slider.Disabled and "DisabledAccentColor" or "AccentColor"
        end

        function Slider:Display()
            local CustomDisplayText = nil
            if Info.FormatDisplayValue then
                CustomDisplayText = Info.FormatDisplayValue(Slider, Slider.Value)
            end

            if CustomDisplayText then
                DisplayLabel.Text = tostring(CustomDisplayText)
            else
                -- keeps trailing zeros so a 2 decimal slider reads 1.00 instead of 1
                local FormattedValue
                if Slider.Rounding > 0 then
                    FormattedValue = string.format("%." .. Slider.Rounding .. "f", Slider.Value)
                else
                    FormattedValue = (Slider.Value == 0 or Slider.Value == -0) and "0" or tostring(Slider.Value)
                end

                if Info.ShowMax then
                    DisplayLabel.Text = string.format("%s%s%s/%s%s%s",
                        Slider.Prefix, FormattedValue, Slider.Suffix,
                        Slider.Prefix, tostring(Slider.Max), Slider.Suffix)
                else
                    DisplayLabel.Text = string.format("%s%s%s", Slider.Prefix, FormattedValue, Slider.Suffix)
                end
            end

            local X = Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, 1)
            Fill.Size = UDim2.new(X, 0, 1, 0)
            Knob.Position = UDim2.new(X, 0, 0.5, 0)
        end

        function Slider:OnChanged(Func)
            Slider.Changed = Func

            -- if Slider.Disabled then
            --     return;
            -- end;
            
            -- Library:SafeCallback(Func, Slider.Value);
        end

        local function Round(Value)
            if Slider.Rounding == 0 then
                return math.floor(Value)
            end

            return tonumber(string.format("%." .. Slider.Rounding .. "f", Value))
        end

        function Slider:GetValueFromXScale(X)
            return Round(Library:MapValue(X, 0, 1, Slider.Min, Slider.Max))
        end
        
        function Slider:SetMax(Value)
            assert(Value > Slider.Min, "Max value cannot be less than the current min value.")
            
            Slider.Value = math.clamp(Slider.Value, Slider.Min, Value)
            Slider.Max = Value
            Slider:Display()
        end
        
        function Slider:SetMin(Value)
            assert(Value < Slider.Max, "Min value cannot be greater than the current max value.")

            Slider.Value = math.clamp(Slider.Value, Value, Slider.Max)
            Slider.Min = Value
            Slider:Display()
        end

        function Slider:SetValue(Str)
            if Slider.Disabled then
                return
            end

            local Num = tonumber(Str)

            if (not Num) then
                return
            end

            Num = math.clamp(Num, Slider.Min, Slider.Max)

            Slider.Value = Num
            Slider:Display()

            if not Slider.Disabled then
                Library:SafeCallback(Slider.Callback, Slider.Value)
                Library:SafeCallback(Slider.Changed, Slider.Value)
            end
        end

        function Slider:SetVisible(Visibility)
            Slider.Visible = Visibility

            Header.Visible = Slider.Visible
            SliderOuter.Visible = Slider.Visible

            for _, Blank in pairs(Blanks) do
                Blank.Visible = Slider.Visible
            end

            Groupbox:Resize()
        end

        function Slider:SetDisabled(Disabled)
            Slider.Disabled = Disabled

            if Tooltip then
                Tooltip.Disabled = Disabled
            end

            Slider:UpdateColors()
        end

        function Slider:SetText(Text)
            if typeof(Text) == "string" then
                Slider.Text = Text

                SliderText.Text = Slider.Text
                Slider:Display()
            end
        end

        function Slider:SetPrefix(Prefix)
            if typeof(Prefix) == "string" then
                Slider.Prefix = Prefix
                Slider:Display()
            end
        end

        function Slider:SetSuffix(Suffix)
            if typeof(Suffix) == "string" then
                Slider.Suffix = Suffix
                Slider:Display()
            end
        end

        SliderOuter.InputBegan:Connect(function(Input)
            if Slider.Disabled then
                return
            end

            if (Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame()) or Input.UserInputType == Enum.UserInputType.Touch then
                if Library.IsMobile then
                    Library.CanDrag = false
                end

                local Sides = {}
                if Library.Window then
                    Sides = Library.Window.Tabs[Library.ActiveTab]:GetSides()
                end

                for _, Side in pairs(Sides) do
                    if typeof(Side) == "Instance" then
                        if Side:IsA("ScrollingFrame") then
                            Side.ScrollingEnabled = false
                        end
                    end
                end

                local mPos = Mouse.X
                local gPos = Fill.AbsoluteSize.X
                local Diff = mPos - (Fill.AbsolutePosition.X + gPos)

                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1 or Enum.UserInputType.Touch) do
                    local nMPos = Mouse.X
                    local nXOffset = math.clamp(gPos + (nMPos - mPos) + Diff, 0, Slider.MaxSize) -- what in tarnation are these variable names
                    local nXScale = Library:MapValue(nXOffset, 0, Slider.MaxSize, 0, 1)

                    local nValue = Slider:GetValueFromXScale(nXScale)
                    local OldValue = Slider.Value
                    Slider.Value = nValue

                    Slider:Display()

                    if nValue ~= OldValue then
                        Library:SafeCallback(Slider.Callback, Slider.Value)
                        Library:SafeCallback(Slider.Changed, Slider.Value)
                    end

                    RunService.RenderStepped:Wait()
                end

                if Library.IsMobile then
                    Library.CanDrag = true
                end
                
                for _, Side in pairs(Sides) do
                    if typeof(Side) == "Instance" then
                        if Side:IsA("ScrollingFrame") then
                            Side.ScrollingEnabled = true
                        end
                    end
                end

                Library:AttemptSave()
            end
        end)

        task.delay(0.1, Slider.UpdateColors, Slider)
        Slider:Display()
        table.insert(Blanks, Groupbox:AddBlank(Info.BlankSize or 8, Slider.Visible))
        Groupbox:Resize()

        Slider.Default = Slider.Value

        table.insert(Groupbox.Elements, Slider)
        Options[Idx] = Slider

        return Slider
    end

    function BaseGroupboxFuncs:AddDropdown(Idx, Info)
        Info.ReturnInstanceInstead = if typeof(Info.ReturnInstanceInstead) == "boolean" then Info.ReturnInstanceInstead else false

        if Info.SpecialType == "Player" then
            Info.ExcludeLocalPlayer = if typeof(Info.ExcludeLocalPlayer) == "boolean" then Info.ExcludeLocalPlayer else false

            Info.Values = GetPlayers(Info.ExcludeLocalPlayer, Info.ReturnInstanceInstead)
            Info.AllowNull = true
        elseif Info.SpecialType == "Team" then
            Info.Values = GetTeams(Info.ReturnInstanceInstead)
            Info.AllowNull = true
        end

        assert(Info.Values, string.format("AddDropdown (IDX: %s): Missing dropdown value list.", tostring(Idx)))
        if not (Info.AllowNull or Info.Default) then
            Info.Default = 1
            warn(string.format("AddDropdown (IDX: %s): Missing default value, selected the first index instead. Pass `AllowNull` as true if this was intentional.", tostring(Idx)))
        end
        
        Info.Searchable = if typeof(Info.Searchable) == "boolean" then Info.Searchable else false
        Info.FormatDisplayValue = if typeof(Info.FormatDisplayValue) == "function" then Info.FormatDisplayValue else nil
        Info.FormatListValue = if typeof(Info.FormatListValue) == "function" then Info.FormatListValue else nil

        if (not Info.Text) then
            Info.Compact = true
        end

        local Dropdown = {
            Values = Info.Values;
            Value = Info.Multi and {};
            DisabledValues = Info.DisabledValues or {};

            Multi = Info.Multi;
            Type = "Dropdown";
            SpecialType = Info.SpecialType; -- can be either "Player" or "Team"
            Visible = if typeof(Info.Visible) == "boolean" then Info.Visible else true;
            Disabled = if typeof(Info.Disabled) == "boolean" then Info.Disabled else false;
            Callback = Info.Callback or function(Value) end;
            Changed = Info.Changed or function(Value) end;

            OriginalText = Info.Text; Text = Info.Text;
            ExcludeLocalPlayer = Info.ExcludeLocalPlayer;
            ReturnInstanceInstead = Info.ReturnInstanceInstead;
        }

        local DropdownLabel
        local Blank
        local CompactBlank
        local Tooltip
        local Groupbox = self
        local Container = Groupbox.Container

        local RelativeOffset = 0

        if not Info.Compact then
            DropdownLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 14);
                TextSize = 12;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                Visible = Dropdown.Visible;
                ZIndex = 5;
                Parent = Container;
                RichText = true;
            })
            Library:DimLabel(DropdownLabel)

            CompactBlank = Groupbox:AddBlank(5, Dropdown.Visible)
        end

        for _, Element in next, Container:GetChildren() do
            if not Element:IsA("UIListLayout") then
                RelativeOffset = RelativeOffset + Element.Size.Y.Offset
            end
        end

        local DropdownOuter = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 30);
            Visible = Dropdown.Visible;
            ZIndex = 5;
            Parent = Container;
        })

        Library:AddToRegistry(DropdownOuter, {
            BorderColor3 = "Black";
        })

        local DropdownInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BackgroundTransparency = Library.ElementTransparency;
            Corner = 8;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DropdownOuter;
        })

        Library:AddToRegistry(DropdownInner, {
            BackgroundColor3 = "MainColor";
        })
        Library:AddStroke(DropdownInner, "OutlineColor")

        local DropdownInnerSearch
        if Info.Searchable then
            DropdownInnerSearch = Library:Create("TextBox", {
                BackgroundTransparency = 1;
                Visible = false;

                Position = UDim2.new(0, 12, 0, 0);
                Size = UDim2.new(0.9, -12, 1, 0);

                Font = Library.Font;
                PlaceholderColor3 = Color3.fromRGB(110, 110, 120);
                PlaceholderText = "Search...";

                Text = "";
                TextColor3 = Library.FontColor;
                TextSize = 12;
                TextXAlignment = Enum.TextXAlignment.Left;

                ClearTextOnFocus = false;

                ZIndex = 7;
                Parent = DropdownOuter;
            })

            Library:AddToRegistry(DropdownInnerSearch, {
                TextColor3 = "FontColor";
            })
        end

        local DropdownArrow = Library:Create("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5);
            BackgroundTransparency = 1;
            Position = UDim2.new(1, -22, 0.5, 0);
            Size = UDim2.new(0, 12, 0, 12);
            Image = CustomImageManager.GetAsset("DropdownArrow");
            ImageTransparency = 0.35;
            ZIndex = 8;
            Parent = DropdownInner;
        })

        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 12, 0, 0);
            Size = UDim2.new(1, -38, 1, 0);
            TextSize = 12;
            Text = "--";
            TextXAlignment = Enum.TextXAlignment.Left;
            TextWrapped = false;
            TextTruncate = Enum.TextTruncate.AtEnd;
            RichText = true;
            ZIndex = 7;
            Parent = DropdownInner;
        })

        Library:OnHighlight(DropdownOuter, DropdownOuter,
            { BorderColor3 = "AccentColor" },
            { BorderColor3 = "Black" },
            function()
                return not Dropdown.Disabled
            end
        )

        if typeof(Info.Tooltip) == "string" or typeof(Info.DisabledTooltip) == "string" then
            Tooltip = Library:AddToolTip(Info.Tooltip, Info.DisabledTooltip, DropdownOuter)
            Tooltip.Disabled = Dropdown.Disabled
        end

        local MAX_DROPDOWN_ITEMS = if typeof(Info.MaxVisibleDropdownItems) == "number" then math.clamp(Info.MaxVisibleDropdownItems, 4, 16) else 8

        local ListOuter = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0);
            ZIndex = 20;
            Visible = false;
            Parent = ScreenGui;
        })

        local ListToken = 0

        local function RecalculateListPosition()
            ListOuter.Position = UDim2.fromOffset(DropdownOuter.AbsolutePosition.X, DropdownOuter.AbsolutePosition.Y + DropdownOuter.Size.Y.Offset + 4)
        end

        local function RecalculateListSize(YSize)
            local Y = YSize or math.clamp(GetTableSize(Dropdown.Values) * (24 * DPIScale), 0, MAX_DROPDOWN_ITEMS * (24 * DPIScale)) + 1
            ListOuter.Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X + 0.5, Y)
        end

        RecalculateListPosition()
        RecalculateListSize()

        DropdownOuter:GetPropertyChangedSignal("AbsolutePosition"):Connect(RecalculateListPosition)

        local ListInner = Library:Create("Frame", {
            ClipsDescendants = true;
            BackgroundColor3 = Library.MainColor;
            BackgroundTransparency = 0;
            Corner = 8;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListOuter;
        })

        Library:AddToRegistry(ListInner, {
            BackgroundColor3 = "MainColor";
        })
        Library:AddStroke(ListInner, "OutlineColor")

        local Scrolling = Library:Create("ScrollingFrame", {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            CanvasSize = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListInner;

            TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",

            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor,
        })

        Library:AddToRegistry(Scrolling, {
            ScrollBarImageColor3 = "AccentColor"
        })

        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 0);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Scrolling;
        })

        function Dropdown:UpdateColors()
            if DropdownLabel then
                if Dropdown.Disabled then
                    DropdownLabel.TextColor3 = Library.DisabledTextColor
                    Library.RegistryMap[DropdownLabel].Properties.TextColor3 = "DisabledTextColor"
                else
                    DropdownLabel.TextColor3 = Library:GetDimColor()
                    Library.RegistryMap[DropdownLabel].Properties.TextColor3 = function()
                        return Library:GetDimColor()
                    end
                end
            end

            ItemList.TextColor3 = Dropdown.Disabled and Library.DisabledTextColor or Library.FontColor
            DropdownArrow.ImageColor3 = Dropdown.Disabled and Library.DisabledTextColor or Library.FontColor
        end

        function Dropdown:Display()
            local Values = Dropdown.Values
            local Str = ""

            if Info.Multi then
                for Idx, Value in next, Values do
                    if Dropdown.Value[Value] then
                        Str = Str .. tostring(Info.FormatDisplayValue and Info.FormatDisplayValue(Value) or Value) .. ", "
                    end
                end

                Str = Str:sub(1, #Str - 2)
                ItemList.Text = (Str == "" and "--" or Str)
            else
                if not Dropdown.Value then
                    ItemList.Text = "--"
                    return
                end

                ItemList.Text = tostring(Info.FormatDisplayValue and Info.FormatDisplayValue(Dropdown.Value) or Dropdown.Value)
            end
        end

        function Dropdown:GetActiveValues()
            if Info.Multi then
                local T = {}

                for Value, Bool in next, Dropdown.Value do
                    table.insert(T, Value)
                end

                return T
            else
                return Dropdown.Value and 1 or 0
            end
        end

        function Dropdown:BuildDropdownList()
            local Values = Dropdown.Values
            local DisabledValues = Dropdown.DisabledValues
            local Buttons = {}

            for _, Element in next, Scrolling:GetChildren() do
                if not Element:IsA("UIListLayout") then
                    Element:Destroy()
                end
            end

            local Count = 0
            for Idx, Value in next, Values do
                local StringValue = tostring(Info.FormatListValue and Info.FormatListValue(Value) or Value)
                if Info.Searchable and not string.lower(StringValue):match(string.lower(DropdownInnerSearch.Text)) then
                    continue
                end

                local IsDisabled = table.find(DisabledValues, StringValue)
                local Table = {}

                Count = Count + 1

                local Button = Library:Create("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = Library.MainColor;
                    BackgroundTransparency = 1;
                    Corner = 6;
                    Size = UDim2.new(1, -1, 0, 24);
                    Text = "";
                    ZIndex = 23;
                    Parent = Scrolling;
                })

                Library:AddToRegistry(Button, {
                    BackgroundColor3 = "MainColor";
                    BorderColor3 = "OutlineColor";
                })

                local ButtonLabel = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, -12, 1, 0);
                    Position = UDim2.new(0, 12, 0, 0);
                    TextSize = 12;
                    Text = Info.FormatDisplayValue and tostring(Info.FormatDisplayValue(StringValue)) or StringValue;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    RichText = true;
                    ZIndex = 25;
                    Parent = Button;
                })

                Button:SetAttribute("HoverRow", true)

                Library:OnHighlight(Button, Button,
                    { BorderColor3 = IsDisabled and "DisabledAccentColor" or "AccentColor", ZIndex = 24 },
                    { BorderColor3 = "OutlineColor", ZIndex = 23 }
                )

                local Selected

                if Info.Multi then
                    Selected = Dropdown.Value[Value]
                else
                    Selected = Dropdown.Value == Value
                end

                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value]
                    else
                        Selected = Dropdown.Value == Value
                    end

                    -- the picked row is bright, the rest are dim
                    ButtonLabel.TextColor3 = Selected and Library.FontColor or (IsDisabled and Library.DisabledTextColor or Library:GetDimColor())
                    Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and "FontColor" or (IsDisabled and "DisabledTextColor" or function() return Library:GetDimColor() end)
                end

                if not IsDisabled then
                    Button.MouseButton1Click:Connect(function(Input)
                        local Try = not Selected

                        if Dropdown:GetActiveValues() == 1 and (not Try) and (not Info.AllowNull) then
                        else
                            if Info.Multi then
                                Selected = Try

                                if Selected then
                                    Dropdown.Value[Value] = true
                                else
                                    Dropdown.Value[Value] = nil
                                end
                            else
                                Selected = Try

                                if Selected then
                                    Dropdown.Value = Value
                                else
                                    Dropdown.Value = nil
                                end

                                for _, OtherButton in next, Buttons do
                                    OtherButton:UpdateButton()
                                end
                            end

                            Table:UpdateButton()
                            Dropdown:Display()
                            
                            Library:UpdateDependencyBoxes()
                            Library:UpdateDependencyGroupboxes()
                            Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                            Library:SafeCallback(Dropdown.Changed, Dropdown.Value)

                            Library:AttemptSave()
                        end
                    end)
                end

                Table:UpdateButton()
                Dropdown:Display()

                Buttons[Button] = Table
            end

            Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * (24 * DPIScale)) + 1)

            -- Workaround for silly roblox bug - not sure why it happens but sometimes the dropdown list will be empty
            -- ... and for some reason refreshing the Visible property fixes the issue??????? thanks roblox!
            Scrolling.Visible = false
            Scrolling.Visible = true

            local Y = math.clamp(Count * (24 * DPIScale), 0, MAX_DROPDOWN_ITEMS * (24 * DPIScale)) + 1
            RecalculateListSize(Y)
        end

        function Dropdown:SetValues(NewValues)
            if NewValues then
                Dropdown.Values = NewValues
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddValues(NewValues)
            if typeof(NewValues) == "table" then
                for _, val in pairs(NewValues) do
                    table.insert(Dropdown.Values, val)
                end
            elseif typeof(NewValues) == "string" then
                table.insert(Dropdown.Values, NewValues)
            else
                return
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetDisabledValues(NewValues)
            if NewValues then
                Dropdown.DisabledValues = NewValues
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddDisabledValues(DisabledValues)
            if typeof(DisabledValues) == "table" then
                for _, val in pairs(DisabledValues) do
                    table.insert(Dropdown.DisabledValues, val)
                end
            elseif typeof(DisabledValues) == "string" then
                table.insert(Dropdown.DisabledValues, DisabledValues)
            else
                return
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetVisible(Visibility)
            Dropdown.Visible = Visibility

            DropdownOuter.Visible = Dropdown.Visible
            if DropdownLabel then DropdownLabel.Visible = Dropdown.Visible end

            if Blank then Blank.Visible = Dropdown.Visible end
            if CompactBlank then CompactBlank.Visible = Dropdown.Visible end

            if not Dropdown.Visible then Dropdown:CloseDropdown() end

            Groupbox:Resize()
        end

        function Dropdown:SetDisabled(Disabled)
            Dropdown.Disabled = Disabled

            if Tooltip then
                Tooltip.Disabled = Disabled
            end

            if Disabled then
                Dropdown:CloseDropdown()
            end

            Dropdown:Display()
            Dropdown:UpdateColors()
        end

        function Dropdown:OpenDropdown()
            if Dropdown.Disabled then
                return
            end

            if Library.IsMobile then
                Library.CanDrag = false
            end

            if Info.Searchable then
                ItemList.Visible = false
                DropdownInnerSearch.Text = ""
                DropdownInnerSearch.Visible = true
            end

            ListOuter.Visible = true
            Library.OpenedFrames[ListOuter] = true

            ListToken = ListToken + 1
            TweenService:Create(DropdownArrow, ArrowTweenInfo, { Rotation = 180 }):Play()

            RecalculateListSize()

            local FullSize = ListOuter.Size
            ListOuter.Size = UDim2.fromOffset(FullSize.X.Offset, 0)
            TweenService:Create(ListOuter, ListTweenInfo, { Size = FullSize }):Play()
        end

        function Dropdown:CloseDropdown()
            if Library.IsMobile then            
                Library.CanDrag = true
            end

            if Info.Searchable then
                DropdownInnerSearch.Text = ""
                DropdownInnerSearch.Visible = false
                ItemList.Visible = true
            end

            Library.OpenedFrames[ListOuter] = nil

            ListToken = ListToken + 1
            local Token = ListToken
            TweenService:Create(DropdownArrow, ArrowTweenInfo, { Rotation = 0 }):Play()

            if ListOuter.Visible then
                TweenService:Create(ListOuter, ListTweenInfo, { Size = UDim2.fromOffset(ListOuter.Size.X.Offset, 0) }):Play()

                task.delay(0.2, function()
                    if Token == ListToken then
                        ListOuter.Visible = false
                        RecalculateListSize()
                    end
                end)
            else
                RecalculateListSize()
            end
        end

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func

            -- if Dropdown.Disabled then
            --     return;
            -- end;

            -- Library:SafeCallback(Func, Dropdown.Value);
        end

        function Dropdown:SetValue(Value)
            if Dropdown.Multi then
                local Table = {}

                for Val, Active in pairs(Value or {}) do
                    if typeof(Active) ~= "boolean" then
                        Table[Active] = true
                    elseif Active and table.find(Dropdown.Values, Val) then
                        Table[Val] = true
                    end
                end

                Dropdown.Value = Table
            else
                if table.find(Dropdown.Values, Value) then
                    Dropdown.Value = Value
                elseif not Value then
                    Dropdown.Value = nil
                end
            end

            Dropdown:BuildDropdownList()

            if not Dropdown.Disabled then
                Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
            end
        end

        function Dropdown:SetText(Text)
            if typeof(Text) == "string" then
                if Info.Compact then Info.Compact = false end
                Dropdown.Text = Text

                if DropdownLabel then DropdownLabel.Text = Dropdown.Text end
                Dropdown:Display()
            end
        end

        DropdownOuter.InputBegan:Connect(function(Input)
            if Dropdown.Disabled then
                return
            end

            if (Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame()) or Input.UserInputType == Enum.UserInputType.Touch then
                if ListOuter.Visible then
                    Dropdown:CloseDropdown()
                else
                    Dropdown:OpenDropdown()
                end
            end
        end)

        if Info.Searchable then
            DropdownInnerSearch:GetPropertyChangedSignal("Text"):Connect(function()
                Dropdown:BuildDropdownList()
            end)
        end

        InputService.InputBegan:Connect(function(Input)
            if Dropdown.Disabled then
                return
            end

            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local AbsPos, AbsSize = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - (30 * DPIScale) - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    Dropdown:CloseDropdown()
                end
            end
        end)

        Dropdown:BuildDropdownList()
        Dropdown:Display()

        local Defaults = {}

        if typeof(Info.Default) == "string" then
            local DefaultIdx = table.find(Dropdown.Values, Info.Default)
            if DefaultIdx then
                table.insert(Defaults, DefaultIdx)
            end
        elseif typeof(Info.Default) == "table" then
            for _, Value in next, Info.Default do
                local DefaultIdx = table.find(Dropdown.Values, Value)
                if DefaultIdx then
                    table.insert(Defaults, DefaultIdx)
                end
            end
        elseif typeof(Info.Default) == "number" and Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end

        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i]
                if Info.Multi then
                    Dropdown.Value[Dropdown.Values[Index]] = true
                else
                    Dropdown.Value = Dropdown.Values[Index]
                end

                if (not Info.Multi) then break end
            end

            Dropdown:BuildDropdownList()
            Dropdown:Display()
        end

        task.delay(0.1, Dropdown.UpdateColors, Dropdown)
        Blank = Groupbox:AddBlank(Info.BlankSize or 10, Dropdown.Visible)
        Groupbox:Resize()

        Dropdown.Default = Defaults
        Dropdown.DefaultValues = Dropdown.Values

        table.insert(Groupbox.Elements, Dropdown)
        Options[Idx] = Dropdown

        return Dropdown
    end

    function BaseGroupboxFuncs:AddViewport(Idx, Info)
        local Dragging, Pinching = false, false
        local LastMousePos, LastPinchDist = nil, 0

        local Viewport = {
            Object = if Info.Clone then Info.Object:Clone() else Info.Object,
            Camera = if not Info.Camera then Instance.new("Camera") else Info.Camera,
            Interactive = Info.Interactive,
            AutoFocus = Info.AutoFocus,
            Height = if typeof(Info.Height) == "number" and Info.Height > 0 then Info.Height else 200,
            Visible = Info.Visible,
            Type = "Viewport",
        }

        assert(
            typeof(Viewport.Object) == "Instance" and (Viewport.Object:IsA("BasePart") or Viewport.Object:IsA("Model")),
            "Instance must be a BasePart or Model."
        )

        assert(
            typeof(Viewport.Camera) == "Instance" and Viewport.Camera:IsA("Camera"),
            "Camera must be a valid Camera instance."
        )

        local function GetModelSize(model)
            if model:IsA("BasePart") then
                return model.Size
            end

            return select(2, model:GetBoundingBox())
        end

        local function FocusCamera()
            local ModelSize = GetModelSize(Viewport.Object)
            local MaxExtent = math.max(ModelSize.X, ModelSize.Y, ModelSize.Z)
            local CameraDistance = MaxExtent * 2
            local ModelPosition = Viewport.Object:GetPivot().Position

            Viewport.Camera.CFrame =
                CFrame.new(ModelPosition + Vector3.new(0, MaxExtent / 2, CameraDistance), ModelPosition)
        end

        local Blank = nil
        local Groupbox = self
        local Container = Groupbox.Container

        local Holder = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -4, 0, Info.Height),
            Visible = Viewport.Visible,
            Parent = Container,
        })

        local Box = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor,
            BackgroundTransparency = Library.ElementTransparency,
            Corner = 5,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 6,
            Parent = Holder,
        })

        Library:AddToRegistry(Box, {
            BackgroundColor3 = "MainColor";
            BorderColor3 = "OutlineColor";
        })

        Library:Create("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local ViewportFrame = Library:Create("ViewportFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = Box,
            CurrentCamera = Viewport.Camera,
            Active = Viewport.Interactive,
            ZIndex = 7
        })

        ViewportFrame.MouseEnter:Connect(function()
            if not Viewport.Interactive then
                return
            end
            
            for _, Side in pairs(Library.Window.Tabs[Library.ActiveTab]:GetSides()) do
                if typeof(Side) == "Instance" then
                    if Side:IsA("ScrollingFrame") then
                        Side.ScrollingEnabled = false
                    end
                end
            end
        end)

        ViewportFrame.MouseLeave:Connect(function()
            if not Viewport.Interactive then
                return
            end

            for _, Side in pairs(Library.Window.Tabs[Library.ActiveTab]:GetSides()) do
                if typeof(Side) == "Instance" then
                    if Side:IsA("ScrollingFrame") then
                        Side.ScrollingEnabled = true
                    end
                end
            end
        end)

        ViewportFrame.InputBegan:Connect(function(input)
            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                Dragging = true
                LastMousePos = input.Position
            elseif input.UserInputType == Enum.UserInputType.Touch and not Pinching then
                Dragging = true
                LastMousePos = input.Position
            end
        end)

        Library:GiveSignal(InputService.InputEnded:Connect(function(input)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                Dragging = false
            elseif input.UserInputType == Enum.UserInputType.Touch then
                Dragging = false
            end
        end))

        Library:GiveSignal(InputService.InputChanged:Connect(function(input)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive or not Dragging or Pinching then
                return
            end

            if
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            then
                local MouseDelta = input.Position - LastMousePos
                LastMousePos = input.Position

                local Position = Viewport.Object:GetPivot().Position
                local Camera = Viewport.Camera

                local RotationY = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), -MouseDelta.X * 0.01)
                Camera.CFrame = CFrame.new(Position) * RotationY * CFrame.new(-Position) * Camera.CFrame

                local RotationX = CFrame.fromAxisAngle(Camera.CFrame.RightVector, -MouseDelta.Y * 0.01)
                local PitchedCFrame = CFrame.new(Position) * RotationX * CFrame.new(-Position) * Camera.CFrame

                if PitchedCFrame.UpVector.Y > 0.1 then
                    Camera.CFrame = PitchedCFrame
                end
            end
        end))

        ViewportFrame.InputChanged:Connect(function(input)
            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseWheel then
                local ZoomAmount = input.Position.Z * 2
                Viewport.Camera.CFrame += Viewport.Camera.CFrame.LookVector * ZoomAmount
            end
        end)

        Library:GiveSignal(InputService.TouchPinch:Connect(function(touchPositions, scale, velocity, state)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive or not Library:MouseIsOverFrame(ViewportFrame, touchPositions[1]) then
                return
            end

            if state == Enum.UserInputState.Begin then
                Pinching = true
                Dragging = false
                LastPinchDist = (touchPositions[1] - touchPositions[2]).Magnitude
            elseif state == Enum.UserInputState.Change then
                local currentDist = (touchPositions[1] - touchPositions[2]).Magnitude
                local delta = (currentDist - LastPinchDist) * 0.1
                LastPinchDist = currentDist
                Viewport.Camera.CFrame += Viewport.Camera.CFrame.LookVector * delta
            elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
                Pinching = false
            end
        end))

        Viewport.Object.Parent = ViewportFrame
        if Viewport.AutoFocus then
            FocusCamera()
        end

        function Viewport:SetObject(Object: Instance, Clone: boolean?)
            assert(Object, "Object cannot be nil.")

            if Clone then
                Object = Object:Clone()
            end

            if Viewport.Object then
                Viewport.Object:Destroy()
            end

            Viewport.Object = Object
            Viewport.Object.Parent = ViewportFrame

            Groupbox:Resize()
        end

        function Viewport:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")
            Viewport.Height = Height

            Holder.Size = UDim2.new(1, -4, 0, Viewport.Height)
            Groupbox:Resize()
        end

        function Viewport:Focus()
            if not Viewport.Object then
                return
            end

            FocusCamera()
        end

        function Viewport:SetCamera(Camera: Instance)
            assert(
                Camera and typeof(Camera) == "Instance" and Camera:IsA("Camera"),
                "Camera must be a valid Camera instance."
            )

            Viewport.Camera = Camera
            ViewportFrame.CurrentCamera = Camera
        end

        function Viewport:SetInteractive(Interactive: boolean)
            Viewport.Interactive = Interactive
            ViewportFrame.Active = Interactive
        end

        function Viewport:SetVisible(Visible: boolean)
            Viewport.Visible = Visible

            Holder.Visible = Viewport.Visible
            if Blank then Blank.Visible = Viewport.Visible end

            Groupbox:Resize()
        end

        Viewport:SetHeight(Viewport.Height)

        Blank = Groupbox:AddBlank(10, Viewport.Visible)
        Groupbox:Resize()

        Viewport.Holder = Holder
        Viewport.Container = Container

        table.insert(Groupbox.Elements, Viewport)
        Options[Idx] = Viewport

        Library:UpdateDependencyBoxes()
        Library:UpdateDependencyGroupboxes()

        return Viewport
    end

    function BaseGroupboxFuncs:AddImage(Idx, Info)
        local Image = {
            Image = Info.Image,
            Color = Info.Color,
            RectOffset = Info.RectOffset,
            RectSize = Info.RectSize,
            Height = if typeof(Info.Height) == "number" and Info.Height > 0 then Info.Height else 200,
            ScaleType = Info.ScaleType,
            Transparency = Info.Transparency,
            BackgroundTransparency = tonumber(Info.BackgroundTransparency) or 0,

            Visible = Info.Visible,
            Type = "Image",
        }

        local Blank = nil
        local Groupbox = self
        local Container = Groupbox.Container

        local Holder = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -4, 0, Info.Height),
            Visible = Image.Visible,
            Parent = Container,
        })

        local Box = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor,
            BackgroundTransparency = Image.BackgroundTransparency,
            Corner = 5,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 6,
            Parent = Holder,
        })

        Library:AddToRegistry(Box, {
            BackgroundColor3 = "MainColor";
            BorderColor3 = "OutlineColor";
        })

        Library:Create("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local ImageProperties = {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Image = Image.Image,
            ImageTransparency = Image.Transparency,
            ImageColor3 = Image.Color,
            ImageRectOffset = Image.RectOffset,
            ImageRectSize = Image.RectSize,
            ScaleType = Image.ScaleType,
            ZIndex = 7,
            Parent = Box,
        }

        local Icon = Library:GetCustomIcon(ImageProperties.Image)
        assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

        ImageProperties.Image = Icon.Url
        ImageProperties.ImageRectOffset = Icon.ImageRectOffset
        ImageProperties.ImageRectSize = Icon.ImageRectSize

        local ImageLabel = Library:Create("ImageLabel", ImageProperties)

        function Image:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")
            Image.Height = Height

            Holder.Size = UDim2.new(1, -4, 0, Image.Height)
            Groupbox:Resize()
        end

        function Image:SetImage(NewImage: string)
            assert(typeof(NewImage) == "string", "Image must be a string.")

            local Icon = Library:GetCustomIcon(NewImage)
            assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

            NewImage = Icon.Url
            Image.RectOffset = Icon.ImageRectOffset
            Image.RectSize = Icon.ImageRectSize

            ImageLabel.Image = NewImage
            Image.Image = NewImage
        end

        function Image:SetColor(Color: Color3)
            assert(typeof(Color) == "Color3", "Color must be a Color3 value.")

            ImageLabel.ImageColor3 = Color
            Image.Color = Color
        end

        function Image:SetRectOffset(RectOffset: Vector2)
            assert(typeof(RectOffset) == "Vector2", "RectOffset must be a Vector2 value.")

            ImageLabel.ImageRectOffset = RectOffset
            Image.RectOffset = RectOffset
        end

        function Image:SetRectSize(RectSize: Vector2)
            assert(typeof(RectSize) == "Vector2", "RectSize must be a Vector2 value.")

            ImageLabel.ImageRectSize = RectSize
            Image.RectSize = RectSize
        end

        function Image:SetScaleType(ScaleType: Enum.ScaleType)
            assert(
                typeof(ScaleType) == "EnumItem" and ScaleType:IsA("ScaleType"),
                "ScaleType must be a valid Enum.ScaleType."
            )

            ImageLabel.ScaleType = ScaleType
            Image.ScaleType = ScaleType
        end

        function Image:SetTransparency(Transparency: number)
            assert(typeof(Transparency) == "number", "Transparency must be a number between 0 and 1.")
            assert(Transparency >= 0 and Transparency <= 1, "Transparency must be between 0 and 1.")

            ImageLabel.ImageTransparency = Transparency
            Image.Transparency = Transparency
        end

        function Image:SetVisible(Visible: boolean)
            Image.Visible = Visible

            Holder.Visible = Image.Visible
            if Blank then Blank.Visible = Image.Visible end

            Groupbox:Resize()
        end

        Image:SetHeight(Image.Height)

        Blank = Groupbox:AddBlank(10, Image.Visible)
        Groupbox:Resize()

        Image.Holder = Holder
        Image.Container = Container

        table.insert(Groupbox.Elements, Image)
        Options[Idx] = Image

        Library:UpdateDependencyBoxes()
        Library:UpdateDependencyGroupboxes()

        return Image
    end

    function BaseGroupboxFuncs:AddVideo(Idx, Info)
        Info = Library:Validate(Info, Templates.Video)

        local Blank = nil
        local Groupbox = self
        local Container = Groupbox.Container

        local Video = {
            Video = Info.Video,
            Looped = Info.Looped,
            Playing = Info.Playing,
            Volume = Info.Volume,
            Height = Info.Height,
            Visible = Info.Visible,

            Type = "Video",
        }

        local Holder = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -4, 0, Info.Height),
            Visible = Video.Visible,
            Parent = Container,
        })

        local Box = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor,
            BackgroundTransparency = Library.ElementTransparency,
            Corner = 5,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 6,
            Parent = Holder,
        })

        Library:AddToRegistry(Box, {
            BackgroundColor3 = "MainColor";
            BorderColor3 = "OutlineColor";
        })

        Library:Create("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local VideoFrameInstance = Library:Create("VideoFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Video = Video.Video,
            Looped = Video.Looped,
            Volume = Video.Volume,
            ZIndex = 7,
            Parent = Box,
        })

        VideoFrameInstance.Playing = Video.Playing

        function Video:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Video.Height = Height
            Holder.Size = UDim2.new(1, -4, 0, Height)
            Groupbox:Resize()
        end

        function Video:SetVideo(NewVideo: string)
            assert(typeof(NewVideo) == "string", "Video must be a string.")

            VideoFrameInstance.Video = NewVideo
            Video.Video = NewVideo
        end

        function Video:SetLooped(Looped: boolean)
            assert(typeof(Looped) == "boolean", "Looped must be a boolean.")

            VideoFrameInstance.Looped = Looped
            Video.Looped = Looped
        end

        function Video:SetVolume(Volume: number)
            assert(typeof(Volume) == "number", "Volume must be a number between 0 and 10.")

            VideoFrameInstance.Volume = Volume
            Video.Volume = Volume
        end

        function Video:SetPlaying(Playing: boolean)
            assert(typeof(Playing) == "boolean", "Playing must be a boolean.")

            VideoFrameInstance.Playing = Playing
            Video.Playing = Playing
        end

        function Video:Play()
            VideoFrameInstance.Playing = true
            Video.Playing = true
        end

        function Video:Pause()
            VideoFrameInstance.Playing = false
            Video.Playing = false
        end

        function Video:SetVisible(Visible: boolean)
            Video.Visible = Visible

            Holder.Visible = Video.Visible
            if Blank then Blank.Visible = Video.Visible end

            Groupbox:Resize()
        end

        Video:SetHeight(Video.Height)

        Blank = Groupbox:AddBlank(10, Video.Visible)
        Groupbox:Resize()

        Video.Holder = Holder
        Video.Container = Container
        Video.VideoFrame = VideoFrameInstance

        table.insert(Groupbox.Elements, Video)
        Options[Idx] = Video

        Library:UpdateDependencyBoxes()
        Library:UpdateDependencyGroupboxes()

        return Video
    end

    function BaseGroupboxFuncs:AddUIPassthrough(Idx, Info)
        Info = Library:Validate(Info, Templates.UIPassthrough)

        local Blank = nil
        local Groupbox = self
        local Container = Groupbox.Container

        assert(Info.Instance, "Instance must be provided.")
        assert(
            typeof(Info.Instance) == "Instance" and Info.Instance:IsA("GuiBase2d"),
            "Instance must inherit from GuiBase2d."
        )
        assert(typeof(Info.Height) == "number" and Info.Height > 0, "Height must be a number greater than 0.")

        local Passthrough = {
            Instance = Info.Instance,
            Height = Info.Height,
            Visible = Info.Visible,

            Type = "UIPassthrough",
        }

        local Holder = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -4, 0, Info.Height),
            Visible = Passthrough.Visible,
            Parent = Container,
        })

        Passthrough.Instance.Parent = Holder
        pcall(function() Passthrough.Instance.ZIndex = 7 end)

        function Passthrough:SetHeight(Height: number)
            assert(typeof(Height) == "number" and Height > 0, "Height must be a number greater than 0.")

            Passthrough.Height = Height
            Holder.Size = UDim2.new(1, -4, 0, Height)
            Groupbox:Resize()
        end

        function Passthrough:SetInstance(Instance: Instance)
            assert(Instance, "Instance must be provided.")
            assert(
                typeof(Instance) == "Instance" and Instance:IsA("GuiBase2d"),
                "Instance must inherit from GuiBase2d."
            )

            if Passthrough.Instance then
                Passthrough.Instance.Parent = nil
            end

            Passthrough.Instance = Instance
            Passthrough.Instance.Parent = Holder
            pcall(function() Passthrough.Instance.ZIndex = 7 end)
        end

        function Passthrough:SetVisible(Visible: boolean)
            Passthrough.Visible = Visible

            Holder.Visible = Passthrough.Visible
            if Blank then Blank.Visible = Passthrough.Visible end

            Groupbox:Resize()
        end

        Passthrough:SetHeight(Passthrough.Height)

        Blank = Groupbox:AddBlank(10, Passthrough.Visible)
        Groupbox:Resize()

        Passthrough.Holder = Holder
        Passthrough.Container = Container

        table.insert(Groupbox.Elements, Passthrough)
        Options[Idx] = Passthrough

        Library:UpdateDependencyBoxes()
        Library:UpdateDependencyGroupboxes()

        return Passthrough
    end

    function BaseGroupboxFuncs:AddDependencyBox()
        local Depbox = {
            Elements = {};
            Dependencies = {};
            TableType = "DepBox";
        }

        local Groupbox = self
        local Container = Groupbox.Container

        local Holder = Library:Create("Frame", {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 0);
            Visible = false;
            Parent = Container;
        })

        local Frame = Library:Create("Frame", {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            Visible = true;
            Parent = Holder;
        })

        local Layout = Library:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Frame;
        })

        function Depbox:Resize()
            Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y)
            Groupbox:Resize()
        end

        Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Depbox:Resize()
        end)

        Holder:GetPropertyChangedSignal("Visible"):Connect(function()
            Depbox:Resize()
        end)

        function Depbox:Update()
            for _, Dependency in next, Depbox.Dependencies do
                local Elem = Dependency[1]
                local Value = Dependency[2]

                if if Elem.Multi then not table.find(Elem:GetActiveValues(), Value) else Elem.Value ~= Value then
                    Holder.Visible = false
                    Depbox:Resize()
                    return
                end
            end

            Holder.Visible = true
            Depbox:Resize()
        end

        function Depbox:SetupDependencies(Dependencies)
            for _, Dependency in next, Dependencies do
                assert(typeof(Dependency) == "table", "SetupDependencies: Dependency is not of type `table`.")
                assert(Dependency[1], "SetupDependencies: Dependency is missing element argument.")
                assert(Dependency[2] ~= nil, "SetupDependencies: Dependency is missing value argument.")
            end

            Depbox.Dependencies = Dependencies
            Depbox:Update()
        end

        Depbox.Container = Frame

        setmetatable(Depbox, BaseGroupbox)

        table.insert(Groupbox.Elements, Depbox)
        table.insert(Library.DependencyBoxes, Depbox)

        return Depbox
    end

    function BaseGroupboxFuncs:AddDependencyGroupbox()
        local ParentGroupbox = self
        local Tab = ParentGroupbox.Tab

        local DepGroupbox = {
            Elements = {};
            Dependencies = {};
            TableType = "DepGroupbox";
        }

        local BoxOuter = Library:Create("Frame", {
            ClipsDescendants = true;
            BackgroundColor3 = Library:GetCardColor();
            BackgroundTransparency = Library.GroupboxTransparency;
            Corner = 10;
            Size = UDim2.new(1, 0, 0, 507 + 2);
            ZIndex = 2;
        })

        Tab:AttachBox(BoxOuter, ParentGroupbox.Side)

        Library:AddToRegistry(BoxOuter, {
            BackgroundColor3 = function()
                return Library:GetCardColor()
            end;
        })
        Library:AddStroke(BoxOuter, "OutlineColor")

        local BoxInner = Library:Create("Frame", {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            Position = UDim2.new(0, 0, 0, 0);
            ZIndex = 4;
            Parent = BoxOuter;
        })


        local Container = Library:Create("Frame", {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 14, 0, 14);
            Size = UDim2.new(1, -24, 1, -14);
            ZIndex = 1;
            Parent = BoxInner;
        })

        Library:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Container;
        })

        function DepGroupbox:Resize()
            local Size = 0

            for _, Element in next, DepGroupbox.Container:GetChildren() do
                if (not Element:IsA("UIListLayout")) and Element.Visible then
                    Size = Size + Element.Size.Y.Offset
                end
            end

            BoxOuter.Size = UDim2.new(1, 0, 0, (14 * DPIScale + Size) + 6)
        end

        function DepGroupbox:Update()
            for _, Dependency in next, DepGroupbox.Dependencies do
                local Elem = Dependency[1]
                local Value = Dependency[2]

                if if Elem.Multi then not table.find(Elem:GetActiveValues(), Value) else Elem.Value ~= Value then
                    BoxOuter.Visible = false
                    DepGroupbox:Resize()
                    return
                end
            end

            BoxOuter.Visible = true
            DepGroupbox:Resize()
        end

        function DepGroupbox:SetupDependencies(Dependencies)
            for _, Dependency in pairs(Dependencies) do
                assert(typeof(Dependency) == "table", "Dependency should be a table.")
                assert(Dependency[1] ~= nil, "Dependency is missing element.")
                assert(Dependency[2] ~= nil, "Dependency is missing expected value.")
            end

            DepGroupbox.Dependencies = Dependencies
            DepGroupbox:Update()
        end

        DepGroupbox.Container = Container
        setmetatable(DepGroupbox, BaseGroupbox)

        DepGroupbox:Resize()

        table.insert(Tab.DependencyGroupboxes, DepGroupbox)
        table.insert(Library.DependencyGroupboxes, DepGroupbox)

        return DepGroupbox
    end

    BaseGroupbox.__index = BaseGroupboxFuncs
    BaseGroupbox.__namecall = function(Table, Key, ...)
        return BaseGroupboxFuncs[Key](...)
    end
end

--// Keybinds UI \\--
do
    local KeybindOuter = Library:Create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5);
        Position = UDim2.new(0, 10, 0.5, 0);
        Size = UDim2.new(0, 210, 0, 20);
        Visible = false;
        ZIndex = 100;
        Parent = ScreenGui;
    })

    local KeybindInner = Library:Create("Frame", {
        ClipsDescendants = true;
        BackgroundColor3 = Library.MainColor;
        BackgroundTransparency = Library.GlassTransparency;
        Corner = 5;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = KeybindOuter;
    })

    Library:AddToRegistry(KeybindInner, {
        BackgroundColor3 = "MainColor";
    }, true)

    local ColorFrame = Library:Create("Frame", {
        BackgroundColor3 = Library.AccentColor;
        BackgroundTransparency = Library.GlassTransparency;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(0, 3, 1, 0);
        ZIndex = 102;
        Parent = KeybindInner;
    })

    Library:AddToRegistry(ColorFrame, {
        BackgroundColor3 = "AccentColor";
    }, true)

    local _KeybindLabel = Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, 20);
        Position = UDim2.fromOffset(0, 2),
        TextXAlignment = Enum.TextXAlignment.Center,

        Text = "Keybinds";
        ZIndex = 104;
        Parent = KeybindInner;
    })
    Library:MakeDraggable(KeybindOuter)

    local KeybindContainer = Library:Create("Frame", {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 1, -20);
        Position = UDim2.new(0, 0, 0, 20);
        ZIndex = 1;
        Parent = KeybindInner;
    })

    Library:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = KeybindContainer;
    })

    Library:Create("UIPadding", {
        PaddingLeft = UDim.new(0, 9),
        Parent = KeybindContainer,
    })

    Library.KeybindFrame = KeybindOuter
    Library.KeybindContainer = KeybindContainer
    Library:MakeDraggable(KeybindOuter)
end

--// Watermark \\--
do
    local WatermarkOuter = Library:Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0);
        Position = UDim2.new(0.5, 0, 0, 15);
        Size = UDim2.new(0, 260, 0, 34);
        ZIndex = 200;
        Visible = false;
        Parent = ScreenGui;
    })

    local WatermarkInner = Library:Create("Frame", {
        ClipsDescendants = true;
        BackgroundColor3 = Library.MainColor;
        BackgroundTransparency = Library.GlassTransparency;
        Corner = 5;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 201;
        Parent = WatermarkOuter;
    })

    Library:AddToRegistry(WatermarkInner, {
        BackgroundColor3 = "MainColor";
    })


    local InnerFrame = Library:Create("Frame", {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 202;
        Parent = WatermarkInner;
    })

    local WatermarkLabel = Library:CreateLabel({
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0);
        TextSize = 16;
        TextXAlignment = Enum.TextXAlignment.Center;
        TextYAlignment = Enum.TextYAlignment.Center;
        ZIndex = 203;
        Parent = InnerFrame;
    })

    Library.Watermark = WatermarkOuter
    Library.WatermarkText = WatermarkLabel
    Library:MakeDraggable(Library.Watermark)

    function Library:SetWatermarkVisibility(Bool)
        Library.Watermark.Visible = Bool
    end

    function Library:SetWatermark(Text)
        local X, Y = Library:GetTextBounds(Text, Library.Font, 16 * DPIScale)
        Library.Watermark.Size = UDim2.new(0, X + 40, 0, Y + 18)
        Library.WatermarkText.Text = Text
    end
end

--// Notifications \\--
do
    Library.LeftNotificationArea = Library:Create("Frame", {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 0, 0, 40);
        Size = UDim2.new(0, 300, 0, 200);
        ZIndex = 11000;
        Parent = ScreenGui;
    })

    Library:Create("UIListLayout", {
        Padding = UDim.new(0, 4);
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = Library.LeftNotificationArea;
    })


    Library.RightNotificationArea = Library:Create("Frame", {
        AnchorPoint = Vector2.new(1, 0);
        BackgroundTransparency = 1;
        Position = UDim2.new(1, 0, 0, 40);
        Size = UDim2.new(0, 300, 0, 200);
        ZIndex = 11000;
        Parent = ScreenGui;
    })

    Library:Create("UIListLayout", {
        Padding = UDim.new(0, 4);
        FillDirection = Enum.FillDirection.Vertical;
        HorizontalAlignment = Enum.HorizontalAlignment.Right;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = Library.RightNotificationArea;
    })
        
    function Library:SetNotifySide(Side: string)
        Library.NotifySide = Side
    end

    function Library:Notify(...)
        local Data = {}
        local Info = select(1, ...)

        if typeof(Info) == "table" then
            Data.Title = Info.Title and tostring(Info.Title) or ""
            Data.Description = tostring(Info.Description)
            Data.Time = Info.Time or 5
            Data.SoundId = Info.SoundId
            Data.Steps = Info.Steps
            Data.Persist = Info.Persist
            Data.Icon = Info.Icon
            Data.IconColor = Info.IconColor
        else
            Data.Title = ""
            Data.Description = tostring(Info)
            Data.Time = select(2, ...) or 5
            Data.SoundId = select(3, ...)
        end
        Data.Destroyed = false

        local DeletedInstance = false
        local DeleteConnection = nil
        if typeof(Data.Time) == "Instance" then
            DeleteConnection = Data.Time.Destroying:Connect(function()
                DeletedInstance = true
                DeleteConnection:Disconnect()
                DeleteConnection = nil
            end)
        end

        local Side = string.lower(Library.NotifySide)
        local XSize, YSize = Library:GetTextBounds(Data.Description, Library.Font, 14)
        YSize = YSize + 7

        local NotifyOuter = Library:Create("Frame", {
            Size = UDim2.new(0, 0, 0, YSize);
            ClipsDescendants = true;
            ZIndex = 11000;
            Visible = false;
            Name = "Notif";
            Parent = Side == "left" and Library.LeftNotificationArea or Library.RightNotificationArea;
        })

        local NotifyInner = Library:Create("Frame", {
            ClipsDescendants = true;
            BackgroundColor3 = Library.MainColor;
            AnchorPoint = Side == "left" and Vector2.new(1, 0) or Vector2.new(0, 0);
            BackgroundTransparency = Library.GlassTransparency;
            Corner = 5;
            Position = Side == "left" and UDim2.new(1, 0, 0, 0) or UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(0, 0, 1, 0);
            ZIndex = 11001;
            Parent = NotifyOuter;
        })

        Library:AddToRegistry(NotifyInner, {
            BackgroundColor3 = "MainColor";
        }, true)

        local InnerFrame = Library:Create("Frame", {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 1, 0, 1);
            Size = UDim2.new(1, -2, 1, -2);
            ZIndex = 11002;
            Parent = NotifyInner;
        })

        local ExtraWidth = 0
        local TextPosition = Side == "left" and UDim2.new(0, 4, 0, 0) or UDim2.new(1, -4, 0, 0)
        local TextSizeOffsetX = -4
        local TextSizeOffsetY = 0

        local IconLabel
        if Data.Icon then
            local ParsedIcon = Library:GetCustomIcon(Data.Icon)
            if ParsedIcon then
                ExtraWidth = ExtraWidth + 20
                TextSizeOffsetX = TextSizeOffsetX - 20
                TextSizeOffsetY = TextSizeOffsetY - 2

                if Side == "left" then
                    TextPosition = UDim2.new(0, 24, 0, 0)
                end

                IconLabel = Library:Create("ImageLabel", {
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = if Side == "left" then UDim2.new(0, 6, 0.5, 0) else UDim2.new(0, 4, 0.5, 0),
                    Size = UDim2.fromOffset(14, 14),
                    Image = ParsedIcon.Url,
                    ImageColor3 = Data.IconColor or Library.FontColor,
                    ImageRectOffset = ParsedIcon.ImageRectOffset,
                    ImageRectSize = ParsedIcon.ImageRectSize,
                    ZIndex = 11004,
                    Parent = InnerFrame,
                })
                
                if not Data.IconColor then
                    Library:AddToRegistry(IconLabel, {
                        ImageColor3 = "FontColor";
                    }, true)
                end
                
                if Side == "right" then
                    TextPosition = UDim2.new(1, -8, 0, 0)
                end
            end
        end

        local NotifyLabel = Library:CreateLabel({
            AnchorPoint = Side == "left" and Vector2.new(0, 0) or Vector2.new(1, 0);
            Position = TextPosition;
            Size = UDim2.new(1, TextSizeOffsetX, 1, TextSizeOffsetY);
            Text = (Data.Title == "" and "" or "[" .. Data.Title .. "] ") .. tostring(Data.Description);
            TextXAlignment = Side == "left" and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right;
            TextSize = 14;
            ZIndex = 11003;
            RichText = true;
            Parent = InnerFrame;
        })

        local SideColor = Library:Create("Frame", {
            AnchorPoint = Side == "left" and Vector2.new(0, 0) or Vector2.new(1, 0);
            Position = Side == "left" and UDim2.new(0, 0, 0, 0) or UDim2.new(1, 0, 0, 0);
            BackgroundColor3 = Library.AccentColor;
            BackgroundTransparency = Library.GlassTransparency;
            Size = UDim2.new(0, 3, 1, 0);
            ZIndex = 11004;
            Parent = NotifyInner;
        })

        Library:AddToRegistry(SideColor, {
            BackgroundColor3 = "AccentColor";
        }, true)

        function Data:Resize()
            XSize, YSize = Library:GetTextBounds(NotifyLabel.Text, Library.Font, 14)
            YSize = YSize + 7
            NotifyInner.Size = UDim2.new(0, XSize * DPIScale + 8 + 4 + ExtraWidth, 1, 0)
            
            pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, XSize * DPIScale + 8 + 4 + ExtraWidth, 0, YSize), "Out", "Quad", 0.4, true)
        end

        function Data:ChangeTitle(NewText)
            NewText = NewText == nil and "" or tostring(NewText)
            Data.Title = NewText
            NotifyLabel.Text = (Data.Title == "" and "" or "[" .. Data.Title .. "] ") .. tostring(Data.Description)
            Data:Resize()
        end

        function Data:ChangeDescription(NewText)
            if NewText == nil then return end
            NewText = tostring(NewText)
            Data.Description = NewText
            NotifyLabel.Text = (Data.Title == "" and "" or "[" .. Data.Title .. "] ") .. tostring(Data.Description)
            Data:Resize()
        end

        function Data:ChangeStep(...)
        end

        function Data:Destroy()
            Data.Destroyed = true

            if typeof(Data.Time) == "Instance" then
                pcall(Data.Time.Destroy, Data.Time)
            end
            
            if DeleteConnection then
                DeleteConnection:Disconnect()
            end

            pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, 0, 0, YSize), "Out", "Quad", 0.4, true)
            task.wait(0.4)
            NotifyOuter:Destroy()
        end

        Data:Resize()

        if Data.SoundId then
            Library:Create("Sound", {
                SoundId = "rbxassetid://" .. tostring(Data.SoundId):gsub("rbxassetid://", "");
                Volume = 3;
                PlayOnRemove = true;
                Parent = game:GetService("SoundService");
            }):Destroy()
        end

        NotifyOuter.Visible = true
        pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, XSize * DPIScale + 8 + 4 + ExtraWidth, 0, YSize), "Out", "Quad", 0.4, true)

        task.delay(0.4, function()
            if Data.Persist then
                return
            elseif typeof(Data.Time) == "Instance" then
                repeat
                    task.wait()
                until DeletedInstance or Data.Destroyed
            else
                task.wait(Data.Time or 5)
            end

            if not Data.Destroyed then
                Data:Destroy()
            end
        end)

        return Data
    end
end

--// Window \\--
function Library:CreateWindow(...)
    local Arguments = { ... }
    local WindowInfo = Templates.Window

    if typeof(Arguments[1]) == "table" then
        WindowInfo = Library:Validate(Arguments[1], Templates.Window)
    else
        WindowInfo = Library:Validate({
            Title = Arguments[1],
            AutoShow = Arguments[2] or false
        }, Templates.Window)
    end

    -- load the font before any text exists so nothing re-renders after the window appears
    Library:PreloadFont()

    local ViewportSize: Vector2 = workspace.CurrentCamera.ViewportSize
    if RunService:IsStudio() and ViewportSize.X <= 5 and ViewportSize.Y <= 5 then
        repeat
            ViewportSize = workspace.CurrentCamera.ViewportSize
            task.wait()
        until ViewportSize.X > 5 and ViewportSize.Y > 5
    end

    if WindowInfo.Size == UDim2.fromOffset(0, 0) then
        WindowInfo.Size = if Library.IsMobile then UDim2.fromOffset(620, math.clamp(ViewportSize.Y - 35, 200, 640)) else UDim2.fromOffset(620, 640)
    end

    Library.NotifySide = WindowInfo.NotifySide
    Library.ShowCustomCursor = WindowInfo.ShowCustomCursor

    if WindowInfo.TabPadding <= 0 then WindowInfo.TabPadding = 1 end
    if WindowInfo.Center then WindowInfo.Position = UDim2.new(0.5, -WindowInfo.Size.X.Offset / 2, 0.5, -WindowInfo.Size.Y.Offset / 2) end

    local Window = {
        Tabs = {};

        OriginalTitle = WindowInfo.Title; 
        Title = WindowInfo.Title;
    }

    local Outer = Library:Create("Frame", {
        AnchorPoint = WindowInfo.AnchorPoint;
        BackgroundTransparency = 1;
        Position = WindowInfo.Position;
        Size = WindowInfo.Size;
        Visible = false;
        ZIndex = 1;
        Parent = ScreenGui;
        Name = "Window";
    })
    LibraryMainOuterFrame = Outer
    Library:MakeDraggable(Outer, 54, true)

    -- the visible window; everything inside it is faded together by Library:SetFade
    local Inner = Library:Create("Frame", {
        ClipsDescendants = true;
        AnchorPoint = Vector2.new(0.5, 0.5);
        BackgroundColor3 = Library.BackgroundColor;
        BackgroundTransparency = Library.GlassTransparency;
        Corner = 14;
        Position = UDim2.fromScale(0.5, 0.5);
        Size = UDim2.fromScale(1, 1);
        ZIndex = 1;
        Parent = Outer;
    })
    Library:AddStroke(Inner, "OutlineColor")
    LibraryMainInnerFrame = Inner
    if WindowInfo.Resizable then Library:MakeResizable(Outer, Library.MinSize, Inner) end

    local WindowScale = Library:Create("UIScale", {
        Scale = 1;
        Parent = Inner;
    })

    Library:AddToRegistry(Inner, {
        BackgroundColor3 = "BackgroundColor";
    })

    local WindowBlur = Instance.new("BlurEffect")
    WindowBlur.Name = "NoctaliaBlur"
    WindowBlur.Enabled = false
    WindowBlur.Size = 0
    pcall(function() WindowBlur.Parent = Lighting end)
    Library.Blur = WindowBlur

    -- header: title, subtitle, a badge and the username on the right
    local HeaderHeight = 54
    local TabRowHeight = 30
    local FooterHeight = 32

    local HeaderLeft = Library:Create("Frame", {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 20, 0, 0);
        Size = UDim2.new(1, -150, 0, HeaderHeight);
        ZIndex = 1;
        Parent = Inner;
    })

    Library:Create("UIListLayout", {
        Padding = UDim.new(0, 8);
        FillDirection = Enum.FillDirection.Horizontal;
        SortOrder = Enum.SortOrder.LayoutOrder;
        VerticalAlignment = Enum.VerticalAlignment.Center;
        Parent = HeaderLeft;
    })

    local WindowLabel = Library:CreateLabel({
        AutomaticSize = Enum.AutomaticSize.X;
        Font = Enum.Font.GothamBold;
        LayoutOrder = 1;
        Size = UDim2.fromOffset(0, 20);
        Text = WindowInfo.Title or "";
        TextSize = 13;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 1;
        Parent = HeaderLeft;
    })

    local WindowSubtitle = Library:CreateLabel({
        AutomaticSize = Enum.AutomaticSize.X;
        LayoutOrder = 2;
        Size = UDim2.fromOffset(0, 20);
        Text = WindowInfo.Subtitle or "";
        TextSize = 13;
        TextXAlignment = Enum.TextXAlignment.Left;
        Visible = (WindowInfo.Subtitle or "") ~= "";
        ZIndex = 1;
        Parent = HeaderLeft;
    })
    Library:DimLabel(WindowSubtitle)

    local WindowBadge = Library:Create("Frame", {
        AutomaticSize = Enum.AutomaticSize.X;
        BackgroundColor3 = Library.MainColor;
        Corner = 8;
        LayoutOrder = 3;
        Size = UDim2.fromOffset(0, 20);
        Visible = (WindowInfo.Badge or "") ~= "";
        ZIndex = 1;
        Parent = HeaderLeft;
    })
    Library:AddToRegistry(WindowBadge, {
        BackgroundColor3 = "MainColor";
    })
    Library:AddStroke(WindowBadge, "OutlineColor")

    Library:Create("UIPadding", {
        PaddingLeft = UDim.new(0, 9);
        PaddingRight = UDim.new(0, 9);
        Parent = WindowBadge;
    })

    local WindowBadgeLabel = Library:CreateLabel({
        AutomaticSize = Enum.AutomaticSize.X;
        Size = UDim2.new(0, 0, 1, 0);
        Text = WindowInfo.Badge or "";
        TextSize = 11;
        ZIndex = 1;
        Parent = WindowBadge;
    })

    local WindowUser = Library:CreateLabel({
        AnchorPoint = Vector2.new(1, 0.5);
        Position = UDim2.new(1, -20, 0, HeaderHeight / 2);
        Size = UDim2.fromOffset(120, 20);
        Text = WindowInfo.Username or "";
        TextSize = 12;
        TextXAlignment = Enum.TextXAlignment.Right;
        ZIndex = 1;
        Parent = Inner;
    })
    Library:DimLabel(WindowUser)

    local MainSectionOuter = Library:Create("Frame", {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = Inner;
    })

    local MainSectionInner = Library:Create("Frame", {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = MainSectionOuter;
    })

    local TabArea = Library:Create("ScrollingFrame", {
        ScrollingDirection = Enum.ScrollingDirection.X;
        CanvasSize = UDim2.new(0, 0, 2, 0);
        HorizontalScrollBarInset = Enum.ScrollBarInset.Always;
        AutomaticCanvasSize = Enum.AutomaticSize.XY;
        ScrollBarThickness = 0;
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 20 - WindowInfo.TabPadding, 0, HeaderHeight);
        Size = UDim2.new(1, -(40 - WindowInfo.TabPadding), 0, TabRowHeight);
        ZIndex = 1;
        Parent = MainSectionInner;
    })

    local TabListLayout = Library:Create("UIListLayout", {
        Padding = UDim.new(0, WindowInfo.TabPadding);
        FillDirection = Enum.FillDirection.Horizontal;
        SortOrder = Enum.SortOrder.LayoutOrder;
        VerticalAlignment = Enum.VerticalAlignment.Center;
        Parent = TabArea;
    })

    Library:Create("Frame", {
        Size = UDim2.new(0, 0, 0, 0);
        LayoutOrder = -1;
        BackgroundTransparency = 1;
        ZIndex = 1;
        Parent = TabArea;
    })
    Library:Create("Frame", {
        Size = UDim2.new(0, 0, 0, 0);
        LayoutOrder = 9999999;
        BackgroundTransparency = 1;
        ZIndex = 1;
        Parent = TabArea;
    })

    -- the tab pages sit under the pill row; the footer (when used) takes the bottom strip
    local TabContainer = Library:Create("Frame", {
        BackgroundColor3 = Library.MainColor;
        BackgroundTransparency = 1;
        Corner = 10;
        Position = UDim2.new(0, 16, 0, HeaderHeight + TabRowHeight + 10);
        Size = UDim2.new(1, -32, 1, -(HeaderHeight + TabRowHeight + 10 + FooterHeight + 6));
        ZIndex = 2;
        Parent = MainSectionInner;
    })

    local InnerVideoBackground = Library:Create("VideoFrame", {
        BackgroundTransparency = 1;
        Corner = 10;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 2;
        Visible = false;
        Volume = 0;
        Looped = true;
        Parent = TabContainer;
    })
    Library.InnerVideoBackground = InnerVideoBackground

    local BackgroundImage = Library:Create("ImageLabel", {
        Image = "";
        Corner = 10;
        Position = UDim2.fromScale(0, 0);
        Size = UDim2.fromScale(1, 1);
        ScaleType = Enum.ScaleType.Stretch;
        ZIndex = 2;
        BackgroundTransparency = 1;
        ImageTransparency = 0.75;
        Parent = TabContainer;
        Visible = false;
    })

    Library:AddToRegistry(TabContainer, {
        BackgroundColor3 = "MainColor";
    })

    -- footer: status on the left, a link / note in the middle, build info on the right
    local FooterHolder = Library:Create("Frame", {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 0, 1, -FooterHeight);
        Size = UDim2.new(1, 0, 0, FooterHeight);
        Visible = false;
        ZIndex = 1;
        Parent = Inner;
    })

    local FooterLine = Library:Create("Frame", {
        BackgroundColor3 = Library.OutlineColor;
        BackgroundTransparency = 0.5;
        Position = UDim2.new(0, 16, 0, 0);
        Size = UDim2.new(1, -32, 0, 1);
        ZIndex = 1;
        Parent = FooterHolder;
    })
    Library:AddToRegistry(FooterLine, {
        BackgroundColor3 = "OutlineColor";
    })

    local FooterLeft = Library:Create("Frame", {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 20, 0, 1);
        Size = UDim2.new(0.4, 0, 1, -1);
        ZIndex = 1;
        Parent = FooterHolder;
    })

    Library:Create("UIListLayout", {
        Padding = UDim.new(0, 7);
        FillDirection = Enum.FillDirection.Horizontal;
        SortOrder = Enum.SortOrder.LayoutOrder;
        VerticalAlignment = Enum.VerticalAlignment.Center;
        Parent = FooterLeft;
    })

    local FooterDot = Library:Create("Frame", {
        BackgroundColor3 = Library.OnlineColor;
        Corner = 4;
        LayoutOrder = 1;
        Size = UDim2.fromOffset(6, 6);
        ZIndex = 1;
        Parent = FooterLeft;
    })
    Library:AddToRegistry(FooterDot, {
        BackgroundColor3 = "OnlineColor";
    })

    local FooterLeftLabel = Library:CreateLabel({
        AutomaticSize = Enum.AutomaticSize.X;
        LayoutOrder = 2;
        Size = UDim2.fromOffset(0, 16);
        TextSize = 11;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 1;
        Parent = FooterLeft;
    })
    Library:DimLabel(FooterLeftLabel)

    local FooterCenterLabel = Library:CreateLabel({
        AnchorPoint = Vector2.new(0.5, 0.5);
        Position = UDim2.new(0.5, 0, 0.5, 1);
        Size = UDim2.new(0.3, 0, 0, 16);
        TextSize = 11;
        TextXAlignment = Enum.TextXAlignment.Center;
        ZIndex = 1;
        Parent = FooterHolder;
    })
    Library:DimLabel(FooterCenterLabel)

    local FooterRight = Library:Create("Frame", {
        AnchorPoint = Vector2.new(1, 0);
        BackgroundTransparency = 1;
        Position = UDim2.new(1, -20, 0, 1);
        Size = UDim2.new(0.4, 0, 1, -1);
        ZIndex = 1;
        Parent = FooterHolder;
    })

    Library:Create("UIListLayout", {
        Padding = UDim.new(0, 4);
        FillDirection = Enum.FillDirection.Horizontal;
        HorizontalAlignment = Enum.HorizontalAlignment.Right;
        SortOrder = Enum.SortOrder.LayoutOrder;
        VerticalAlignment = Enum.VerticalAlignment.Center;
        Parent = FooterRight;
    })

    local FooterRightLabel = Library:CreateLabel({
        AutomaticSize = Enum.AutomaticSize.X;
        LayoutOrder = 1;
        Size = UDim2.fromOffset(0, 16);
        TextSize = 11;
        ZIndex = 1;
        Parent = FooterRight;
    })
    Library:DimLabel(FooterRightLabel)

    local FooterRightValue = Library:CreateLabel({
        AutomaticSize = Enum.AutomaticSize.X;
        Font = Enum.Font.GothamMedium;
        LayoutOrder = 2;
        Size = UDim2.fromOffset(0, 16);
        TextSize = 11;
        ZIndex = 1;
        Parent = FooterRight;
    })

    function Window:SetWindowTitle(Title)
        if typeof(Title) == "string" then
            Window.Title = Title
            WindowLabel.Text = Window.Title
        end
    end

    function Window:SetSubtitle(Text)
        Text = typeof(Text) == "string" and Text or ""

        WindowSubtitle.Text = Text
        WindowSubtitle.Visible = Text ~= ""
    end

    function Window:SetBadge(Text)
        Text = typeof(Text) == "string" and Text or ""

        WindowBadgeLabel.Text = Text
        WindowBadge.Visible = Text ~= ""
    end

    function Window:SetUsername(Text)
        WindowUser.Text = typeof(Text) == "string" and Text or ""
    end

    -- Info = { Left = "9096 online", Center = "discord.gg/...", RightLabel = "Build:", RightValue = "Jun 19 2026" }
    -- the strip only shows up when at least one of them is set
    function Window:SetFooter(Info)
        Info = typeof(Info) == "table" and Info or {}

        local Left = typeof(Info.Left) == "string" and Info.Left or ""
        local Center = typeof(Info.Center) == "string" and Info.Center or ""
        local RightLabel = typeof(Info.RightLabel) == "string" and Info.RightLabel or ""
        local RightValue = typeof(Info.RightValue) == "string" and Info.RightValue or ""

        FooterLeftLabel.Text = Left
        FooterDot.Visible = Left ~= "" and Info.Dot ~= false
        FooterLeft.Visible = Left ~= ""

        FooterCenterLabel.Text = Center

        FooterRightLabel.Text = RightLabel
        FooterRightLabel.Visible = RightLabel ~= ""
        FooterRightValue.Text = RightValue
        FooterRight.Visible = RightLabel ~= "" or RightValue ~= ""

        local HasFooter = Left ~= "" or Center ~= "" or RightLabel ~= "" or RightValue ~= ""
        FooterHolder.Visible = HasFooter

        if HasFooter then
            TabContainer.Size = UDim2.new(1, -32, 1, -(HeaderHeight + TabRowHeight + 10 + FooterHeight + 6))
        else
            TabContainer.Size = UDim2.new(1, -32, 1, -(HeaderHeight + TabRowHeight + 10 + 16))
        end
    end

    Window:SetFooter({
        Left = WindowInfo.FooterLeft;
        Center = WindowInfo.FooterCenter;
        RightLabel = WindowInfo.FooterRightLabel;
        RightValue = WindowInfo.FooterRightValue;
    })

    function Window:SetBackgroundImage(NewImage)
        if tonumber(NewImage) then
            NewImage = "rbxassetid://" .. NewImage
        end

        assert(typeof(NewImage) == "string", "Image must be a string.")

        local Icon = Library:GetCustomIcon(NewImage)
        if not Icon then
            BackgroundImage.Visible = false
            return
        end

        assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

        BackgroundImage.Image = Icon.Url
        BackgroundImage.ImageRectOffset = Icon.ImageRectOffset
        BackgroundImage.ImageRectSize = Icon.ImageRectSize

        BackgroundImage.Visible = true
    end

    -- tabs are pills now, there is no sliding indicator; kept so older scripts that call it don't break
    function Window:MoveTabIndicator() end

    function Window:AddDialog(Idx, Info)
        assert(Info.Title, "AddDialog: Missing `Title` string.")
        assert(Info.Description, "AddDialog: Missing `Description` string.")

        local DialogFrame
        local DialogOverlay
        local DialogContainer
        local ButtonsHolder
        local FooterButtonsList = {}

        DialogOverlay = Library:Create("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            Active = false,
            ZIndex = 9000,
            Visible = true,
            Parent = LibraryMainInnerFrame,
        })
        TweenService:Create(DialogOverlay, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.5,
        }):Play()

        DialogFrame = Library:Create("TextButton", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(300, 0),
            ZIndex = 9001,
            Visible = true,
            Parent = DialogOverlay,
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = "",
            AutoButtonColor = false,
        })

        local DialogInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor,
            BackgroundTransparency = Library.GlassTransparency,
            Corner = 10,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 9002,
            Parent = DialogFrame,
        })

        Library:AddToRegistry(DialogInner, {
            BackgroundColor3 = "MainColor",
        })

        local InnerContainer = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 9003,
            Parent = DialogInner,
        })
        local DialogScale = Library:Create("UIScale", {
            Scale = 0.95,
            Parent = DialogFrame,
        })
        TweenService:Create(DialogScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Scale = 1
        }):Play()

        Library:Create("UIPadding", {
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 15),
            PaddingRight = UDim.new(0, 15),
            PaddingTop = UDim.new(0, 15),
            Parent = InnerContainer,
        })
        local _InnerListLayout = Library:Create("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = InnerContainer,
        })

        local HeaderContainer = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 1,
            ZIndex = 9003,
            Parent = InnerContainer,
        })
        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = HeaderContainer,
        })
        Library:Create("UIPadding", {
            PaddingBottom = UDim.new(0, 5),
            Parent = HeaderContainer,
        })

        local TitleRow = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 1,
            ZIndex = 9003,
            Parent = HeaderContainer,
        })
        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 6),
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = TitleRow,
        })

        local TitleLabel = Library:CreateLabel({
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = Info.Title or "Dialog",
            TextSize = 18,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 9003,
            Parent = TitleRow,
            RichText = true,
        })
        if Info.TitleColor then
            TitleLabel.TextColor3 = Info.TitleColor
        else
            Library:AddToRegistry(TitleLabel, { TextColor3 = "FontColor" })
        end

        local DescriptionLabel = Library:CreateLabel({
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = Info.Description or "Description",
            TextSize = 14,
            TextTransparency = Info.DescriptionColor and 0 or 0.2,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            ZIndex = 9003,
            LayoutOrder = 2,
            Parent = HeaderContainer,
            RichText = true,
        })
        if Info.DescriptionColor then
            DescriptionLabel.TextColor3 = Info.DescriptionColor
        else
            Library:AddToRegistry(DescriptionLabel, { TextColor3 = "FontColor" })
        end

        DialogContainer = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 4,
            Visible = false,
            ZIndex = 9003,
            Parent = InnerContainer,
        })
        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 1),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = DialogContainer,
        })
        
        local _Sep2 = Library:Create("Frame", {
            BackgroundColor3 = Library.OutlineColor,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
            LayoutOrder = 5,
            ZIndex = 9003,
            Parent = InnerContainer,
        })
        Library:AddToRegistry(_Sep2, {
            BackgroundColor3 = "OutlineColor",
        })

        ButtonsHolder = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 6,
            ZIndex = 9002,
            Parent = InnerContainer,
        })
        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Wraps = true,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = ButtonsHolder,
        })
        Library:Create("UIPadding", {
            PaddingTop = UDim.new(0, 0),
            Parent = ButtonsHolder,
        })

        local Dialog = {
            Elements = {},
            Container = DialogContainer,
        }

        function Dialog:Resize()
            local MaxWidth = LibraryMainOuterFrame.AbsoluteSize.X * 0.75
            local MinWidth = 400 * DPIScale

            local TotalButtonWidth = 0
            local ButtonCount = 0
            local HasButtons = false

            for _, BtnWrap in pairs(FooterButtonsList) do
                HasButtons = true
                ButtonCount = ButtonCount + 1
                TotalButtonWidth = TotalButtonWidth + BtnWrap.Container.Size.X.Offset
            end

            local TargetWidth = MinWidth
            if HasButtons then
                local RequiredWidth = TotalButtonWidth + ((ButtonCount - 1) * 8 * DPIScale) + (30 * DPIScale)
                TargetWidth = math.max(MinWidth, math.min(RequiredWidth, MaxWidth))
            end

            local DescY = select(2, Library:GetTextBounds(DescriptionLabel.Text, Library.Font, 14 * DPIScale, TargetWidth - (30 * DPIScale)))
            DescriptionLabel.Size = UDim2.new(1, 0, 0, DescY)

            local HasElements = false
            for _, v in pairs(DialogContainer:GetChildren()) do
                if not v:IsA("UIListLayout") and not v:IsA("UIPadding") then
                    HasElements = true
                    break
                end
            end

            if HasElements then
                for _, v in pairs(DialogContainer:GetDescendants()) do
                    if not v:IsA("GuiObject") then continue end
                    if v:GetAttribute("ZIndexApplied") then continue end
                    
                    v:SetAttribute("ZIndexApplied", true)
                    v.ZIndex = v.ZIndex + 9003
                end
            end

            DialogContainer.Visible = HasElements

            ButtonsHolder.Visible = HasButtons
            _Sep2.Visible = HasButtons

            DialogFrame.Size = UDim2.fromOffset(TargetWidth, 0)
        end

        function Dialog:SetTitle(Title)
            TitleLabel.Text = Title
            Dialog:Resize()
        end

        function Dialog:SetDescription(Description)
            DescriptionLabel.Text = Description
            Dialog:Resize()
        end

        function Dialog:Dismiss()
            TweenService:Create(DialogScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.95 }):Play()
            TweenService:Create(DialogOverlay, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
            
            task.delay(0.1, function()
                DialogOverlay:Destroy()
            end)

            if Library.Dialogues then Library.Dialogues[Idx] = nil end
            Library.ActiveDialog = nil
        end

        DialogOverlay.MouseButton1Click:Connect(function()
            if Info.OutsideClickDismiss then
                Dialog:Dismiss()
            end
        end)

        function Dialog:RemoveFooterButton(ButtonIdx)
            if FooterButtonsList[ButtonIdx] then
                FooterButtonsList[ButtonIdx].Container:Destroy()
                FooterButtonsList[ButtonIdx] = nil
            end
        end

        function Dialog:SetButtonDisabled(ButtonIdx, Disabled)
            if FooterButtonsList[ButtonIdx] and type(FooterButtonsList[ButtonIdx].SetDisabled) == "function" then
                FooterButtonsList[ButtonIdx]:SetDisabled(Disabled)
            end
        end

        function Dialog:SetButtonOrder(ButtonIdx, Order)
            if FooterButtonsList[ButtonIdx] and FooterButtonsList[ButtonIdx].Container then
                FooterButtonsList[ButtonIdx].Container.LayoutOrder = Order
            end
        end

        function Dialog:AddFooterButton(ButtonIdx, ButtonInfo)
            Dialog:RemoveFooterButton(ButtonIdx)

            local WaitTime = ButtonInfo.WaitTime or 0
            local Variant = ButtonInfo.Variant or "Primary"

            local BtnInnerColor = Library.MainColor
            local DestructiveColor = Color3.fromRGB(220, 38, 38)

            if Variant == "Primary" then
                BtnInnerColor = Library.AccentColor
            elseif Variant == "Secondary" then
                BtnInnerColor = Library.BackgroundColor
            elseif Variant == "Destructive" then
                BtnInnerColor = DestructiveColor
            end

            local LabelX = select(1, Library:GetTextBounds(ButtonInfo.Title or ButtonIdx, Library.Font, 14 * DPIScale))
            local BtnW = LabelX + (24 * DPIScale)
            local BtnH = 20 * DPIScale

            local ButtonContainer = Library:Create("Frame", {
                BackgroundColor3 = Color3.new(0, 0, 0),
                Size = UDim2.fromOffset(BtnW, BtnH),
                LayoutOrder = ButtonInfo.Order or 0,
                ZIndex = 9003,
                Parent = ButtonsHolder,
            })

            local TextBtn = Library:Create("TextButton", {
                BackgroundColor3 = BtnInnerColor,
                BackgroundTransparency = WaitTime > 0 and 0.5 or Library.GlassTransparency,
                Corner = 5,
                Size = UDim2.new(1, 0, 1, 0),
                Text = "",
                AutoButtonColor = false,
                ZIndex = 9004,
                Parent = ButtonContainer,
            })

            if Variant == "Primary" then
                Library:AddToRegistry(TextBtn, { BackgroundColor3 = "AccentColor" })
            elseif Variant == "Secondary" then
                Library:AddToRegistry(TextBtn, { BackgroundColor3 = "BackgroundColor" })
            elseif Variant == "Ghost" then
                Library:AddToRegistry(TextBtn, { BackgroundColor3 = "MainColor" })
            end

            local function GetBaseColor()
                return Library.RegistryMap[TextBtn] and Library:GetRegistryColor(TextBtn, "BackgroundColor3") or BtnInnerColor
            end

            ButtonContainer.MouseEnter:Connect(function()
                TweenService:Create(TextBtn, HoverTweenInfo, { BackgroundColor3 = Library:GetBetterColor(GetBaseColor(), 5) }):Play()
            end)
            ButtonContainer.MouseLeave:Connect(function()
                TweenService:Create(TextBtn, HoverTweenInfo, { BackgroundColor3 = GetBaseColor() }):Play()
            end)

            local TextColor = Library.FontColor
            if Variant == "Destructive" then
                TextColor = Color3.new(1, 1, 1)
            end

            local BtnLabel = Library:CreateLabel({
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = ButtonInfo.Title or ButtonIdx,
                TextColor3 = TextColor,
                TextTransparency = WaitTime > 0 and 0.5 or 0,
                TextSize = 14 * DPIScale,
                ZIndex = 9005,
                Parent = TextBtn,
            })

            if Variant ~= "Destructive" then
                Library:AddToRegistry(BtnLabel, { TextColor3 = "FontColor" })
            end

            local ProgressBar
            if WaitTime > 0 then
                ProgressBar = Library:Create("Frame", {
                    BackgroundColor3 = Library.AccentColor,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 1, -2),
                    Size = UDim2.new(0, 0, 0, 2),
                    ZIndex = 2,
                    Parent = TextBtn,
                })
                Library:AddToRegistry(ProgressBar, { BackgroundColor3 = "AccentColor" })
            end

            local IsActive = WaitTime <= 0

            local ButtonWrap = {
                Container = ButtonContainer,
                SetDisabled = function(self, Disabled)
                    IsActive = not Disabled
                    if Disabled then
                        TweenService:Create(TextBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.5 }):Play()
                        TweenService:Create(BtnLabel, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0.5 }):Play()
                    else
                        TweenService:Create(TextBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = Library.GlassTransparency }):Play()
                        TweenService:Create(BtnLabel, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
                    end
                end
            }

            TextBtn.MouseButton1Click:Connect(function()
                if not IsActive then return end

                if ButtonInfo.Callback then
                    ButtonInfo.Callback(Dialog)
                end

                if Info.AutoDismiss ~= false then
                    Dialog:Dismiss()
                end
            end)

            if WaitTime > 0 then
                TweenService:Create(ProgressBar, TweenInfo.new(WaitTime, Enum.EasingStyle.Linear), {
                    Size = UDim2.new(1, 0, 0, 2)
                }):Play()
                
                task.delay(WaitTime, function()
                    ButtonWrap:SetDisabled(false)

                    if ProgressBar then
                        TweenService:Create(ProgressBar, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 1
                        }):Play()
                    end
                end)
            end

            FooterButtonsList[ButtonIdx] = ButtonWrap
        end

        if Info.FooterButtons then
            for BIdx, BInfo in pairs(Info.FooterButtons) do
                if type(BIdx) == "number" and BInfo.Id then BIdx = BInfo.Id end
                Dialog:AddFooterButton(BIdx, BInfo)
            end
        end

        setmetatable(Dialog, BaseGroupbox)

        Library.Dialogues[Idx] = Dialog
        Library.ActiveDialog = Dialog

        Dialog:Resize()

        return Dialog
    end

    function Window:AddTab(Name)
        local Tab = {
            Groupboxes = {};
            Tabboxes = {};
            DependencyGroupboxes = {};
            AnimatedBoxes = {};
            ShowTweens = {};
            ShowToken = 0;
            WarningBox = {
                Bottom = false,
                IsNormal = false,
                LockSize = false,
                Visible = false,
                Title = "WARNING",
                Text = ""
            };
            OriginalName = Name;
            Name = Name;
            TableType = "Tab";
        }

        local TabButtonWidth = Library:GetTextBounds(Tab.Name, Library.Font, 12)

        -- pill: filled + outlined while selected, bare text otherwise
        local TabButton = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BackgroundTransparency = 1;
            Corner = 14;
            Size = UDim2.new(0, TabButtonWidth + 32, 0, 28);
            ZIndex = 1;
            Parent = TabArea;
        })

        Library:AddToRegistry(TabButton, {
            BackgroundColor3 = "MainColor";
        })

        local TabButtonStroke = Library:AddStroke(TabButton, "OutlineColor", 1)

        local TabButtonLabel = Library:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            Text = Tab.Name;
            TextSize = 12;
            ZIndex = 1;
            Parent = TabButton;
        })
        Library:DimLabel(TabButtonLabel)

        local TabActive = false
        local TabHovered = false
        local TabStateInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

        local function RefreshTabButton()
            TweenService:Create(TabButton, TabStateInfo, { BackgroundTransparency = TabActive and 0 or 1 }):Play()
            TweenService:Create(TabButtonStroke, TabStateInfo, { Transparency = TabActive and 0 or 1 }):Play()

            local Bright = TabActive or TabHovered
            TweenService:Create(TabButtonLabel, TabStateInfo, { TextColor3 = Bright and Library.FontColor or Library:GetDimColor() }):Play()

            local Reg = Library.RegistryMap[TabButtonLabel]
            if Reg then
                Reg.Properties.TextColor3 = Bright and "FontColor" or function()
                    return Library:GetDimColor()
                end
            end
        end

        TabButton.MouseEnter:Connect(function()
            TabHovered = true
            RefreshTabButton()
        end)

        TabButton.MouseLeave:Connect(function()
            TabHovered = false
            RefreshTabButton()
        end)

        local TabFrame = Library:Create("Frame", {
            Name = "TabFrame",
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            Visible = false;
            ZIndex = 2;
            Parent = TabContainer;
        })

        local TopBarHighlight
        local TopBar, TopBarInner, TopBarLabel, TopBarTextLabel, TopBarScrollingFrame
do
            TopBar = Library:Create("Frame", {
                Position = UDim2.new(0, 7, 0, 7);
                Size = UDim2.new(1, -13, 0, 0);
                ZIndex = 2;
                Parent = TabFrame;
                Visible = false;
            })

            TopBarInner = Library:Create("Frame", {
                ClipsDescendants = true;
                BackgroundColor3 = Color3.fromRGB(117, 22, 17);
                BackgroundTransparency = Library.GlassTransparency;
                Corner = 10;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 4;
                Parent = TopBar;
            })

            TopBarHighlight = Library:Create("Frame", {
                BackgroundColor3 = Color3.fromRGB(255, 75, 75);
                BackgroundTransparency = Library.GlassTransparency;
                Position = UDim2.new(0, 10, 0, 0);
                Size = UDim2.new(1, -20, 0, 2);
                ZIndex = 5;
                Parent = TopBarInner;
            })

            TopBarScrollingFrame = Library:Create("ScrollingFrame", {
                BackgroundTransparency = 1;
                BorderSizePixel = 0;
                Size = UDim2.new(1, -8, 1, 0);
                CanvasSize = UDim2.new(0, 0, 0, 0);
                AutomaticCanvasSize = Enum.AutomaticSize.Y;
                ScrollBarThickness = 3;
                ZIndex = 5;
                Parent = TopBarInner;
            })

            TopBarLabel = Library:Create("TextLabel", {
                BackgroundTransparency = 1;
                Font = Library.Font;
                RichText = true;

                Size = UDim2.new(1, 0, 0, 18);
                Position = UDim2.new(0, 4, 0, 2);
                TextSize = 14;
                Text = "Text";
                TextXAlignment = Enum.TextXAlignment.Left;
                TextColor3 = Color3.fromRGB(255, 55, 55);
                ZIndex = 5;
                Parent = TopBarScrollingFrame;
            })

            TopBarTextLabel = Library:CreateLabel({
                RichText = true;
                Position = UDim2.new(0, 4, 0, 20);
                Size = UDim2.new(1, 0, 0, 14);
                TextSize = 14;
                Text = "Text";
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Top;
                ZIndex = 5;
                Parent = TopBarScrollingFrame;
            })
            
            Library:Create("Frame", {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 5);
                Visible = true;
                ZIndex = 1;
                Parent = TopBarInner;
            })
        end
        
        local LeftSide = Library:Create("ScrollingFrame", {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(0.5, -5, 1, 0);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = "";
            TopImage = "";
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = TabFrame;
        })

        local RightSide = Library:Create("ScrollingFrame", {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0.5, 5, 0, 0);
            Size = UDim2.new(0.5, -5, 1, 0);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = "";
            TopImage = "";
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = TabFrame;
        })

        Tab.LeftSideFrame = LeftSide
        Tab.RightSideFrame = RightSide

        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 10);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = LeftSide;
        })

        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 10);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = RightSide;
        })

        if Library.IsMobile then
            local SidesValues = {
                ["Left"] = tick(),
                ["Right"] = tick(),
            }

            LeftSide:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
                Library.CanDrag = false

                local ChangeTick = tick()
                SidesValues.Left = ChangeTick
                task.wait(0.15)

                if SidesValues.Left == ChangeTick then
                    Library.CanDrag = true
                end
            end)

            RightSide:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
                Library.CanDrag = false

                local ChangeTick = tick()
                SidesValues.Right = ChangeTick
                task.wait(0.15)
                
                if SidesValues.Right == ChangeTick then
                    Library.CanDrag = true
                end
            end)
        end

        for _, Side in next, { LeftSide, RightSide } do
            Side:WaitForChild("UIListLayout"):GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                Side.CanvasSize = UDim2.fromOffset(0, Side.UIListLayout.AbsoluteContentSize.Y)
            end)
        end

        function Tab:Resize()
            if TopBar.Visible == true then
                local MaximumSize = math.floor(TabFrame.AbsoluteSize.Y / 3.25)
                local Size = 27 + select(2, Library:GetTextBounds(TopBarTextLabel.Text, Library.Font, 14, Vector2.new(TopBarTextLabel.AbsoluteSize.X, math.huge)))

                if Tab.WarningBox.LockSize == true and Size >= MaximumSize then 
                    Size = MaximumSize
                end

                if Tab.WarningBox.Bottom == true then
                    TopBar.Position = UDim2.new(0, 0, 1, -Size)
                else
                    TopBar.Position = UDim2.new(0, 0, 0, 0)
                end

                TopBar.Size = UDim2.new(1, 0, 0, Size)
                Size = Size + 10

                if TopBar.Position.Y.Offset > 0 then
                    LeftSide.Position = UDim2.new(0, 0, 0, Size)
                    LeftSide.Size = UDim2.new(0.5, -5, 1, -Size)

                    RightSide.Position = UDim2.new(0.5, 5, 0, Size)
                    RightSide.Size = UDim2.new(0.5, -5, 1, -Size)
                else
                    LeftSide.Position = UDim2.new(0, 0, 0, 0)
                    LeftSide.Size = UDim2.new(0.5, -5, 1, -Size)

                    RightSide.Position = UDim2.new(0.5, 5, 0, 0)
                    RightSide.Size = UDim2.new(0.5, -5, 1, -Size)
                end
            else
                LeftSide.Position = UDim2.new(0, 0, 0, 0)
                LeftSide.Size = UDim2.new(0.5, -5, 1, 0)

                RightSide.Position = UDim2.new(0.5, 5, 0, 0)
                RightSide.Size = UDim2.new(0.5, -5, 1, 0)
            end
        end

        function Tab:UpdateWarningBox(Info)
            if typeof(Info.Bottom) == "boolean"     then Tab.WarningBox.Bottom      = Info.Bottom end
            if typeof(Info.IsNormal) == "boolean"   then Tab.WarningBox.IsNormal      = Info.IsNormal end
            if typeof(Info.LockSize) == "boolean"   then Tab.WarningBox.LockSize    = Info.LockSize end
            if typeof(Info.Visible) == "boolean"    then Tab.WarningBox.Visible     = Info.Visible end
            if typeof(Info.Title) == "string"       then Tab.WarningBox.Title       = Info.Title end
            if typeof(Info.Text) == "string"        then Tab.WarningBox.Text        = Info.Text end

            TopBar.Visible = Tab.WarningBox.Visible
            TopBarLabel.Text = Tab.WarningBox.Title
            TopBarTextLabel.Text = Tab.WarningBox.Text
            if TopBar.Visible then Tab:Resize()
end

            TopBarInner.BackgroundColor3 = Tab.WarningBox.IsNormal == true and Library.BackgroundColor or Color3.fromRGB(117, 22, 17)
            TopBarHighlight.BackgroundColor3 = Tab.WarningBox.IsNormal == true and Library.AccentColor or Color3.fromRGB(255, 75, 75)

            TopBarLabel.TextColor3 = Tab.WarningBox.IsNormal == true and Library.FontColor or Color3.fromRGB(255, 55, 55)

            if not Library.RegistryMap[TopBarInner] then Library:AddToRegistry(TopBarInner, {}) end
            if not Library.RegistryMap[TopBarHighlight] then Library:AddToRegistry(TopBarHighlight, {}) end
            if not Library.RegistryMap[TopBarLabel] then Library:AddToRegistry(TopBarLabel, {}) end

            Library.RegistryMap[TopBarInner].Properties.BackgroundColor3 = Tab.WarningBox.IsNormal == true and "BackgroundColor" or nil
            Library.RegistryMap[TopBarHighlight].Properties.BackgroundColor3 = Tab.WarningBox.IsNormal == true and "AccentColor" or nil

            Library.RegistryMap[TopBarLabel].Properties.TextColor3 = Tab.WarningBox.IsNormal == true and "FontColor" or nil
        end

        -- groupboxes and tabboxes sit inside a holder so their layout slot stays put while they animate in
        function Tab:AttachBox(BoxOuter, Side)
            local Holder = Library:Create("Frame", {
                BackgroundTransparency = 1;
                ZIndex = 2;
                Parent = Side == 1 and LeftSide or RightSide;
            })
            Holder.Size = BoxOuter.Size

            BoxOuter.Parent = Holder

            BoxOuter:GetPropertyChangedSignal("Size"):Connect(function()
                Holder.Size = BoxOuter.Size
            end)

            BoxOuter:GetPropertyChangedSignal("Visible"):Connect(function()
                Holder.Visible = BoxOuter.Visible
            end)

            table.insert(Tab.AnimatedBoxes, { Holder = Holder; Outer = BoxOuter; Side = Side; })
        end

        local function ResetBoxes()
            Tab.ShowToken = Tab.ShowToken + 1

            for _, ShowTween in next, Tab.ShowTweens do
                ShowTween:Cancel()
            end
            Tab.ShowTweens = {}

            for _, Box in next, Tab.AnimatedBoxes do
                Box.Outer.Position = UDim2.new()

                if Box.Faded then
                    Box.Faded = false
                    Library:SetFade(Box.Outer, 1)
                end
            end
        end

        -- every box starts 10px above its slot and falls into place while fading in, one after another
        function Tab:PlayShowAnimation()
            ResetBoxes()

            local Token = Tab.ShowToken
            local Ranks = { [1] = 0; [2] = 0; }

            for _, Box in next, Tab.AnimatedBoxes do
                if not Box.Holder.Visible then
                    continue
                end

                local Rank = Ranks[Box.Side]
                Ranks[Box.Side] = Rank + 1

                Box.Outer.Position = UDim2.fromOffset(0, -10)
                Library:CaptureFade(Box.Outer)
                Library:SetFade(Box.Outer, 0)
                Box.Faded = true

                local Delay = math.min(Rank * 2 + (Box.Side == 2 and 1 or 0), 8) * 0.04

                task.delay(Delay, function()
                    if Token ~= Tab.ShowToken then
                        return
                    end

                    local ShowInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                    local ShowTween = TweenService:Create(Box.Outer, ShowInfo, { Position = UDim2.new(); })

                    table.insert(Tab.ShowTweens, ShowTween)
                    ShowTween:Play()
                    Library:SetFade(Box.Outer, 1, ShowInfo)

                    task.delay(0.32, function()
                        if Token == Tab.ShowToken then
                            Box.Faded = false
                        end
                    end)
                end)
            end
        end

        function Tab:ShowTab()
            local WasActive = Library.ActiveTab == Name

            Library.ActiveTab = Name
            for _, Tab in next, Window.Tabs do
                Tab:HideTab()
            end

            TabActive = true
            RefreshTabButton()
            TabFrame.Visible = true

            Tab:Resize()

            if not WasActive and Outer.Visible and Library.TotalTabs > 1 then
                Tab:PlayShowAnimation()
            end
        end
        Tab.Show = Tab.ShowTab

        function Tab:HideTab()
            TabActive = false
            RefreshTabButton()
            TabFrame.Visible = false
            ResetBoxes()
        end
        Tab.Hide = Tab.HideTab

        function Tab:SetLayoutOrder(Position)
            TabButton.LayoutOrder = Position
            TabListLayout:ApplyLayout()
        end

        function Tab:GetSides()
            return { ["Left"] = LeftSide, ["Right"] = RightSide }
        end

        function Tab:SetName(Name)
            if typeof(Name) == "string" then
                Tab.Name = Name

                local TabButtonWidth = Library:GetTextBounds(Tab.Name, Library.Font, 12)

                TabButton.Size = UDim2.new(0, TabButtonWidth + 32, 0, 28)
                TabButtonLabel.Text = Tab.Name
            end
        end

        function Tab:AddGroupbox(Info)
            local Groupbox = {
                Elements = {};
                Side = Info.Side;
                Tab = Tab;
                TableType = "Groupbox";
            }

            -- a card: title on top, a thin rule under it, then the elements
            local BoxOuter = Library:Create("Frame", {
                ClipsDescendants = true;
                BackgroundColor3 = Library:GetCardColor();
                BackgroundTransparency = Library.GroupboxTransparency;
                Corner = 10;
                Size = UDim2.new(1, 0, 0, 507 + 2);
                ZIndex = 2;
            })

            Tab:AttachBox(BoxOuter, Info.Side)

            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = function()
                    return Library:GetCardColor()
                end;
            })
            Library:AddStroke(BoxOuter, "OutlineColor")

            local BoxInner = Library:Create("Frame", {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 1, 0);
                Position = UDim2.new(0, 0, 0, 0);
                ZIndex = 4;
                Parent = BoxOuter;
            })

            Library:CreateLabel({
                Size = UDim2.new(1, -28, 0, 30);
                Position = UDim2.new(0, 14, 0, 0);
                TextSize = 12;
                TextTransparency = 0.1;
                Text = Info.Name;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 5;
                Parent = BoxInner;
            })

            local TitleRule = Library:Create("Frame", {
                BackgroundColor3 = Library.OutlineColor;
                Position = UDim2.new(0, 14, 0, 30);
                Size = UDim2.new(1, -28, 0, 1);
                ZIndex = 5;
                Parent = BoxInner;
            })
            Library:AddToRegistry(TitleRule, {
                BackgroundColor3 = "OutlineColor";
            })

            local Container = Library:Create("Frame", {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 14, 0, 38);
                Size = UDim2.new(1, -24, 1, -38);
                ZIndex = 1;
                Parent = BoxInner;
            })

            Library:Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = Container;
            })

            function Groupbox:Resize()
                local Size = 0

                for _, Element in next, Groupbox.Container:GetChildren() do
                    if (not Element:IsA("UIListLayout")) and Element.Visible then
                        Size = Size + Element.Size.Y.Offset
                    end
                end

                -- header (38) + rows + a little room at the bottom
                BoxOuter.Size = UDim2.new(1, 0, 0, (38 * DPIScale + Size) + 6)
            end

            Groupbox.Container = Container
            setmetatable(Groupbox, BaseGroupbox)

            Groupbox:Resize()

            Tab.Groupboxes[Info.Name] = Groupbox

            return Groupbox
        end

        function Tab:AddLeftGroupbox(Name)
            return Tab:AddGroupbox({ Side = 1; Name = Name; })
        end

        function Tab:AddRightGroupbox(Name)
            return Tab:AddGroupbox({ Side = 2; Name = Name; })
        end

        function Tab:AddTabbox(Info)
            local Tabbox = {
                Tabs = {};
            }

            -- a card whose header is a row of text tabs; the picked one gets a filled pill
            local BoxOuter = Library:Create("Frame", {
                ClipsDescendants = true;
                BackgroundColor3 = Library:GetCardColor();
                BackgroundTransparency = Library.GroupboxTransparency;
                Corner = 10;
                Size = UDim2.new(1, 0, 0, 0);
                ZIndex = 2;
            })

            Tab:AttachBox(BoxOuter, Info.Side)

            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = function()
                    return Library:GetCardColor()
                end;
            })
            Library:AddStroke(BoxOuter, "OutlineColor")

            local BoxInner = Library:Create("Frame", {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 1, 0);
                Position = UDim2.new(0, 0, 0, 0);
                ZIndex = 4;
                Parent = BoxOuter;
            })


            local TabboxButtons = Library:Create("Frame", {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 10, 0, 9);
                Size = UDim2.new(1, -20, 0, 24);
                ZIndex = 5;
                Parent = BoxInner;
            })

            Library:Create("UIListLayout", {
                Padding = UDim.new(0, 2);
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Left;
                SortOrder = Enum.SortOrder.LayoutOrder;
                VerticalAlignment = Enum.VerticalAlignment.Center;
                Parent = TabboxButtons;
            })

            function Tabbox:AddTab(Name)
                local Tab = {
                    Elements = {};
                    Container = nil;
                    TableType = "TabboxTab";
                }

                local ButtonWidth = Library:GetTextBounds(Name, Library.Font, 12)
                local ButtonHovered = false
                local ButtonActive = false
                local ButtonInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

                local Button = Library:Create("Frame", {
                    BackgroundColor3 = Library.MainColor;
                    BackgroundTransparency = 1;
                    Corner = 7;
                    Size = UDim2.new(0, ButtonWidth + 22, 1, 0);
                    ZIndex = 6;
                    Parent = TabboxButtons;
                })

                Library:AddToRegistry(Button, {
                    BackgroundColor3 = "MainColor";
                })

                local ButtonLabel = Library:CreateLabel({
                    Size = UDim2.new(1, 0, 1, 0);
                    TextSize = 12;
                    Text = Name;
                    TextXAlignment = Enum.TextXAlignment.Center;
                    ZIndex = 7;
                    Parent = Button;
                    RichText = true;
                })
                Library:DimLabel(ButtonLabel)

                local function RefreshButton()
                    TweenService:Create(Button, ButtonInfo, { BackgroundTransparency = ButtonActive and 0 or 1 }):Play()

                    local Bright = ButtonActive or ButtonHovered
                    TweenService:Create(ButtonLabel, ButtonInfo, { TextColor3 = Bright and Library.FontColor or Library:GetDimColor() }):Play()

                    local Reg = Library.RegistryMap[ButtonLabel]
                    if Reg then
                        Reg.Properties.TextColor3 = Bright and "FontColor" or function()
                            return Library:GetDimColor()
                        end
                    end
                end

                Button.MouseEnter:Connect(function()
                    ButtonHovered = true
                    RefreshButton()
                end)

                Button.MouseLeave:Connect(function()
                    ButtonHovered = false
                    RefreshButton()
                end)

                local Container = Library:Create("Frame", {
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 14, 0, 47);
                    Size = UDim2.new(1, -24, 1, -47);
                    ZIndex = 1;
                    Visible = false;
                    Parent = BoxInner;
                })

                Library:Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    Parent = Container;
                })

                function Tab:Show()
                    for _, Tab in next, Tabbox.Tabs do
                        Tab:Hide()
                    end

                    Container.Visible = true
                    ButtonActive = true
                    RefreshButton()

                    Tab:Resize()
                end

                function Tab:Hide()
                    Container.Visible = false
                    ButtonActive = false
                    RefreshButton()
                end

                function Tab:Resize()
                    if (not Container.Visible) then
                        return
                    end

                    local Size = 0

                    for _, Element in next, Tab.Container:GetChildren() do
                        if (not Element:IsA("UIListLayout")) and Element.Visible then
                            Size = Size + Element.Size.Y.Offset
                        end
                    end

                    -- header (47) + rows + a little room at the bottom
                    BoxOuter.Size = UDim2.new(1, 0, 0, (47 * DPIScale + Size) + 6)
                end

                Button.InputBegan:Connect(function(Input)
                    if (Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame()) or Input.UserInputType == Enum.UserInputType.Touch then
                        Tab:Show()
                        Tab:Resize()
                    end
                end)

                Tab.Container = Container
                Tabbox.Tabs[Name] = Tab

                setmetatable(Tab, BaseGroupbox)

                Tab:Resize()

                -- Show first tab (number is 2 cus of the UIListLayout that also sits in that instance)
                if #TabboxButtons:GetChildren() == 2 then
                    Tab:Show()
                end

                return Tab
            end

            Tab.Tabboxes[Info.Name or ""] = Tabbox

            return Tabbox
        end

        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 1; })
        end

        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 2; })
        end

        TabButton.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Tab:ShowTab()
            end
        end)

        TopBar:GetPropertyChangedSignal("Visible"):Connect(function()
            Tab:Resize()
        end)

        local function RefreshIndicator()
            if Library.ActiveTab == Name then
                Window:MoveTabIndicator(TabButton, true)
            end
        end

        TabButton:GetPropertyChangedSignal("AbsolutePosition"):Connect(RefreshIndicator)
        TabButton:GetPropertyChangedSignal("AbsoluteSize"):Connect(RefreshIndicator)

        -- This was the first tab added, so we show it by default.
        Library.TotalTabs = Library.TotalTabs + 1
        if Library.TotalTabs == 1 then
            Tab:ShowTab()
        end

        Window.Tabs[Name] = Tab
        return Tab
    end

    local Toggled = false
    local Fading = false

    function Window:Toggle(Toggling)
        if typeof(Toggling) == "boolean" and Toggling == Toggled then return end
        if Fading then return end

        local FadeTime = WindowInfo.MenuFadeTime
        Fading = true
        Toggled = (not Toggled)

        Library.Toggled = Toggled
        if WindowInfo.UnlockMouseWhileOpen then
            ModalElement.Modal = Library.Toggled
        end

        if Library.UISound then
            Library:PlayInterfaceSound()
        end

        if Toggled then
            -- we want to show the frame immediately so that the fade is visible.
            Outer.Visible = true

            if DrawingLib.drawing_replaced ~= true and IsBadDrawingLib ~= true then
                IsBadDrawingLib = not (pcall(function()
                    local Cursor = DrawingLib.new("Triangle")
                    Cursor.Thickness = 1
                    Cursor.Filled = true
                    Cursor.Visible = Library.ShowCustomCursor

                    local CursorOutline = DrawingLib.new("Triangle")
                    CursorOutline.Thickness = 1
                    CursorOutline.Filled = false
                    CursorOutline.Color = Color3.new(0, 0, 0)
                    CursorOutline.Visible = Library.ShowCustomCursor
                    
                    local OldMouseIconState = InputService.MouseIconEnabled
                    local ShowCursorBinding = Library.ShowCursorBinding
                    pcall(function() RunService:UnbindFromRenderStep(ShowCursorBinding) end)
                    RunService:BindToRenderStep(ShowCursorBinding, Enum.RenderPriority.Camera.Value - 1, function()
                        InputService.MouseIconEnabled = not Library.ShowCustomCursor
                        local mPos = InputService:GetMouseLocation()
                        local X, Y = mPos.X, mPos.Y
                        Cursor.Color = Library.AccentColor
                        Cursor.PointA = Vector2.new(X, Y)
                        Cursor.PointB = Vector2.new(X + 16, Y + 6)
                        Cursor.PointC = Vector2.new(X + 6, Y + 16)
                        Cursor.Visible = Library.ShowCustomCursor
                        CursorOutline.PointA = Cursor.PointA
                        CursorOutline.PointB = Cursor.PointB
                        CursorOutline.PointC = Cursor.PointC
                        CursorOutline.Visible = Library.ShowCustomCursor

                        if not Toggled or (not ScreenGui or not ScreenGui.Parent) then
                            InputService.MouseIconEnabled = OldMouseIconState
                            if Cursor then Cursor:Destroy() end
                            if CursorOutline then CursorOutline:Destroy() end
                            RunService:UnbindFromRenderStep(ShowCursorBinding)
                        end
                    end)
                end))
            end
        end

        for _, Option in Options do
            task.spawn(function()
                if Option.Type == "Dropdown" then
                    Option:CloseDropdown()

                elseif Option.Type == "KeyPicker" then
                    Option:SetModePickerVisibility(false)

                elseif Option.Type == "ColorPicker" then
                    Option.ContextMenu:Hide()
                    Option:Hide()
                end
            end)
        end

        -- fast -> slow: the scale and the fade of every object ease out together
        local AnimationInfo = TweenInfo.new(FadeTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

        if Toggled then
            Library:SetFade(Inner, 0)
            WindowScale.Scale = Library.WindowClosedScale
        else
            Library:CaptureFade(Inner)
        end

        Library:SetFade(Inner, Toggled and 1 or 0, AnimationInfo)
        TweenService:Create(WindowScale, AnimationInfo, { Scale = Toggled and 1 or Library.WindowClosedScale }):Play()

        if Library.Blur then
            if Toggled and Library.BlurEnabled then
                Library.Blur.Enabled = true
            end

            TweenService:Create(Library.Blur, AnimationInfo, { Size = (Toggled and Library.BlurEnabled) and Library.BlurSize or 0 }):Play()
        end
        task.wait(FadeTime)
        Outer.Visible = Toggled

        if not Toggled then
            WindowScale.Scale = 1
        end

        if Library.Blur and not Toggled then
            Library.Blur.Enabled = false
        end

        Fading = false
    end

    function Library:Toggle(Toggling)
        return Window:Toggle(Toggling)
    end

    Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed) -- :sob:
        if Library.Unloaded then
            return
        end
        
        if typeof(Library.ToggleKeybind) == "table" and Library.ToggleKeybind.Type == "KeyPicker" then
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind.Value then
                task.spawn(Library.Toggle)
            end

        elseif Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and (not Processed)) then
            task.spawn(Library.Toggle)
        end
    end))

    if Library.IsMobile then
        local ToggleUIOuter = Library:Create("Frame", {
            Position = UDim2.new(0.008, 0, 0.018, 0);
            Size = UDim2.new(0, 77, 0, 30);
            ZIndex = 200;
            Visible = true;
            Parent = ScreenGui;
        })
    
        local ToggleUIInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BackgroundTransparency = Library.GlassTransparency;
            Corner = 5;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 201;
            Parent = ToggleUIOuter;
        })
    
        Library:AddToRegistry(ToggleUIInner, {
            BackgroundColor3 = "MainColor";
        })
    
        local ToggleUIInnerFrame = Library:Create("Frame", {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 1, 0, 1);
            Size = UDim2.new(1, -2, 1, -2);
            ZIndex = 202;
            Parent = ToggleUIInner;
        })
    
        local ToggleUIButton = Library:Create("TextButton", {
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -4, 1, 0);
            BackgroundTransparency = 1;
            Font = Library.Font;
            Text = "Toggle UI";
            TextColor3 = Library.FontColor;
            TextSize = 14;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 203;
            Parent = ToggleUIInnerFrame;
        })
    
        Library:MakeDraggableUsingParent(ToggleUIButton, ToggleUIOuter)

        ToggleUIButton.MouseButton1Down:Connect(function()
            Library:Toggle()
        end)

        -- Lock
        local LockUIOuter = Library:Create("Frame", {
            Position = UDim2.new(0.008, 0, 0.075, 0);
            Size = UDim2.new(0, 77, 0, 30);
            ZIndex = 200;
            Visible = true;
            Parent = ScreenGui;
        })
    
        local LockUIInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BackgroundTransparency = Library.GlassTransparency;
            Corner = 5;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 201;
            Parent = LockUIOuter;
        })
    
        Library:AddToRegistry(LockUIInner, {
            BackgroundColor3 = "MainColor";
        })
    
        local LockUIInnerFrame = Library:Create("Frame", {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 1, 0, 1);
            Size = UDim2.new(1, -2, 1, -2);
            ZIndex = 202;
            Parent = LockUIInner;
        })
    
        local LockUIButton = Library:Create("TextButton", {
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -4, 1, 0);
            BackgroundTransparency = 1;
            Font = Library.Font;
            Text = "Lock UI";
            TextColor3 = Library.FontColor;
            TextSize = 14;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 203;
            Parent = LockUIInnerFrame;
        })
    
        Library:MakeDraggableUsingParent(LockUIButton, LockUIOuter)
        
        LockUIButton.MouseButton1Down:Connect(function()
            Library.CantDragForced = not Library.CantDragForced
            LockUIButton.Text = Library.CantDragForced and "Unlock UI" or "Lock UI"
        end)
    end

    Window:SetBackgroundImage(WindowInfo.BackgroundImage or "")
    if WindowInfo.AutoShow then task.spawn(Library.Toggle) end

    Window.Holder = Outer
    Library.Window = Window

    return Window
end

local function OnPlayerChange()
    if Library.Unloaded then
        return
    end

    local PlayerList, ExcludedPlayerList = GetPlayers(false, true), GetPlayers(true, true)
    local StringPlayerList, StringExcludedPlayerList = GetPlayers(false, false), GetPlayers(true, false)

    for _, Value in next, Options do
        if Value.SetValues and Value.Type == "Dropdown" and Value.SpecialType == "Player" then
            Value:SetValues(
                if Value.ReturnInstanceInstead then
                    (if Value.ExcludeLocalPlayer then ExcludedPlayerList else PlayerList)
                else
                    (if Value.ExcludeLocalPlayer then StringExcludedPlayerList else StringPlayerList)
            )
        end
    end
end

local function OnTeamChange()
    if Library.Unloaded then
        return
    end
    
    local TeamList = GetTeams(false)
    local StringTeamList = GetTeams(true)

    for _, Value in next, Options do
        if Value.SetValues and Value.Type == "Dropdown" and Value.SpecialType == "Team" then
            Value:SetValues(if Value.ReturnInstanceInstead then TeamList else StringTeamList)
        end
    end
end

Library:GiveSignal(Players.PlayerAdded:Connect(OnPlayerChange))
Library:GiveSignal(Players.PlayerRemoving:Connect(OnPlayerChange))

Library:GiveSignal(Teams.ChildAdded:Connect(OnTeamChange))
Library:GiveSignal(Teams.ChildRemoved:Connect(OnTeamChange))

--// Rainbow Handler \\--
local RainbowStep = 0
local Hue = 0

Library:GiveSignal(RunService.RenderStepped:Connect(function(Delta)
    if Library.Unloaded then
        return
    end

    RainbowStep = RainbowStep + Delta
    if RainbowStep >= (1 / 60) then
        RainbowStep = 0

        Hue = Hue + (1 / 400)

        if Hue > 1 then
            Hue = 0
        end

        Library.CurrentRainbowHue = Hue
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1)
    end
end))

----
getgenv().Noctalia = Library
if getgenv().skip_getgenv_noctalia ~= true then getgenv().Library = Library end
return Library
