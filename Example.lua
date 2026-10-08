local repo = "https://raw.githubusercontent.com/NoctaliaLua/MatchaLib/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Players = game:GetService("Players")

Library.ShowToggleFrameInKeybinds = true
Library.NotifySide = "Left"

local MarketplaceService = game:GetService("MarketplaceService")

local GameName = "Unknown"

local Success, Info = pcall(function()
    return MarketplaceService:GetProductInfo(game.PlaceId)
end)

if Success and Info and Info.Name then
    GameName = Info.Name
end

if GameName == "Unknown" or GameName == "Ugc" then
    pcall(function()
        local Data = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games?universeIds=" .. game.GameId))
        if Data and Data.data and Data.data[1] and Data.data[1].name then
            GameName = Data.data[1].name
        end
    end)
end

local Window = Library:CreateWindow({
	Title = "Matcha",
	Subtitle = "Interface",
	Badge = "Pro",

	-- Username defaults to the local player's name; pass `Username = "..."` to override it
	FooterLeft = "Connected",
	FooterCenter = GameName,
	FooterRightLabel = "Build:",
	FooterRightValue = os.date("%b ") .. tonumber(os.date("%d")) .. os.date(" %Y"),

	Size = UDim2.fromOffset(605, 970),
	Center = true,
	AutoShow = true,
	Resizable = true,
	UnlockMouseWhileOpen = true,
	NotifySide = "Left",
	TabPadding = 8,
	MenuFadeTime = 0.2
})

local Tabs = {
	Combat = Window:AddTab("Combat"),
	Configs = Window:AddTab("Configs"),
}

--// Combat \\--
local HitParts = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso" }

-- left card: Aimbot | Prediction | Smoothness | FOV
local AimTabbox = Tabs.Combat:AddLeftTabbox()

local Aimbot = AimTabbox:AddTab("Aimbot")

Aimbot:AddToggle("AimbotEnabled", { Text = "Enabled" }):AddKeyPicker("AimbotKey", {
	Default = "MB2",
	Mode = "Hold",
	Text = "Aimbot",
})

Aimbot:AddToggle("AimbotTeamCheck", { Text = "Team Check" })
Aimbot:AddToggle("AimbotVisibleCheck", { Text = "Visible Check" })
Aimbot:AddToggle("AimbotHealthCheck", { Text = "Health Check" })
Aimbot:AddToggle("AimbotSticky", { Text = "Sticky Aim" })

Aimbot:AddSlider("AimbotDistance", {
	Text = "Distance",
	Default = 500,
	Min = 0,
	Max = 5000,
	Rounding = 0,
})

Aimbot:AddSlider("AimbotSensitivity", {
	Text = "Sensitivity",
	Default = 0.4,
	Min = 0,
	Max = 2,
	Rounding = 2,
})

Aimbot:AddDropdown("AimbotHitPart", {
	Text = "Hit Part",
	Values = HitParts,
	Default = 1,
})

Aimbot:AddDropdown("AimbotAimType", {
	Text = "Aim Type",
	Values = { "Mouse", "Camera" },
	Default = 1,
})

Aimbot:AddToggle("AimbotRage", {
	Text = "Rage Method",
	Help = "Snaps straight onto the target instead of easing towards it.",
})

Aimbot:AddDropdown("AimbotRageType", {
	Text = "Type",
	Values = { "Camera Teleport", "Mouse Teleport" },
	Default = 1,
})

local AimbotPrediction = AimTabbox:AddTab("Prediction")
AimbotPrediction:AddToggle("AimbotPredictionEnabled", { Text = "Enabled" })
AimbotPrediction:AddSlider("AimbotPredictionX", { Text = "Horizontal", Default = 0.13, Min = 0, Max = 1, Rounding = 2 })
AimbotPrediction:AddSlider("AimbotPredictionY", { Text = "Vertical", Default = 0.13, Min = 0, Max = 1, Rounding = 2 })

local AimbotSmoothness = AimTabbox:AddTab("Smoothness")
AimbotSmoothness:AddToggle("AimbotSmoothingEnabled", { Text = "Enabled", Default = true })
AimbotSmoothness:AddSlider("AimbotSmoothing", { Text = "Amount", Default = 5, Min = 1, Max = 20, Rounding = 0 })
AimbotSmoothness:AddDropdown("AimbotEasing", {
	Text = "Easing",
	Values = { "Linear", "Quad", "Sine", "Quint" },
	Default = 1,
})

local AimbotFOV = AimTabbox:AddTab("FOV")
AimbotFOV:AddToggle("AimbotShowFOV", { Text = "Show Circle" }):AddColorPicker("AimbotFOVColor", {
	Default = Color3.fromRGB(205, 205, 214),
	Title = "FOV color",
})
AimbotFOV:AddSlider("AimbotFOVRadius", { Text = "Radius", Default = 120, Min = 10, Max = 600, Rounding = 0 })

local Misc = Tabs.Combat:AddLeftGroupbox("Misc")
Misc:AddToggle("Resolver", { Text = "Resolver" })

-- right card: Silent Aim | Prediction | FOV
local SilentTabbox = Tabs.Combat:AddRightTabbox()

local SilentAim = SilentTabbox:AddTab("Silent Aim")

SilentAim:AddToggle("SilentEnabled", { Text = "Enabled" }):AddKeyPicker("SilentKey", {
	Default = "E",
	Mode = "Toggle",
	Text = "Silent Aim",
})

SilentAim:AddToggle("SilentTeamCheck", { Text = "Team Check" })
SilentAim:AddToggle("SilentVisibleCheck", { Text = "Visible Check" })
SilentAim:AddToggle("SilentHealthCheck", { Text = "Health Check" })
SilentAim:AddToggle("SilentSticky", { Text = "Sticky Aim" })

SilentAim:AddSlider("SilentDistance", {
	Text = "Distance",
	Default = 500,
	Min = 0,
	Max = 5000,
	Rounding = 0,
})

SilentAim:AddDropdown("SilentHitPart", {
	Text = "Hit Part",
	Values = HitParts,
	Default = 1,
})

SilentAim:AddDropdown("SilentMethod", {
	Text = "Method",
	Values = { "Experimental", "Raycast", "FindPartOnRay", "Mouse.Hit" },
	Default = 1,
})

local SilentPrediction = SilentTabbox:AddTab("Prediction")
SilentPrediction:AddToggle("SilentPredictionEnabled", { Text = "Enabled" })
SilentPrediction:AddSlider("SilentPredictionAmount", { Text = "Amount", Default = 0.13, Min = 0, Max = 1, Rounding = 2 })

local SilentFOV = SilentTabbox:AddTab("FOV")
SilentFOV:AddToggle("SilentShowFOV", { Text = "Show Circle" }):AddColorPicker("SilentFOVColor", {
	Default = Color3.fromRGB(205, 205, 214),
	Title = "FOV color",
})
SilentFOV:AddSlider("SilentFOVRadius", { Text = "Radius", Default = 150, Min = 10, Max = 600, Rounding = 0 })

local TriggerBot = Tabs.Combat:AddRightGroupbox("Trigger Bot")

TriggerBot:AddToggle("TriggerEnabled", { Text = "Enabled" }):AddKeyPicker("TriggerKey", {
	Default = "Q",
	Mode = "Hold",
	Text = "Trigger Bot",
})

TriggerBot:AddToggle("TriggerVisibleCheck", { Text = "Visible Check" })
TriggerBot:AddToggle("TriggerTeamCheck", { Text = "Team Check" })

TriggerBot:AddSlider("TriggerHitbox", { Text = "Hitbox Mul", Default = 1, Min = 1, Max = 10, Rounding = 2 })
TriggerBot:AddSlider("TriggerDelay", { Text = "Delay (ms)", Default = 1, Min = 1, Max = 500, Rounding = 0 })
TriggerBot:AddSlider("TriggerRelease", { Text = "Release (ms)", Default = 10, Min = 10, Max = 500, Rounding = 0 })

Toggles.AimbotEnabled:OnChanged(function()
	print("Aimbot enabled:", Toggles.AimbotEnabled.Value)
end)

Options.AimbotSensitivity:OnChanged(function()
	print("Aimbot sensitivity:", Options.AimbotSensitivity.Value)
end)

Options.AimbotKey:OnClick(function()
	print("Aimbot key state:", Options.AimbotKey:GetState())
end)

--// Watermark \\--
local StartTime = tick()

local FrameTimer = tick()
local FrameCounter = 0;
local FPS = 60;
local LastUpdate = 0
local GetPing = (function() return math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) end)
local CanDoPing = pcall(function() return GetPing(); end)

local function IsOn(Idx)
	return Toggles[Idx] ~= nil and Toggles[Idx].Value == true
end

local function FormatUptime(Seconds)
	Seconds = math.floor(Seconds)
	return ("%02d %02d %02d"):format(math.floor(Seconds / 3600), math.floor(Seconds / 60) % 60, Seconds % 60)
end

Library:SetWatermarkTitle("Matcha", "Pro")

local WatermarkConnection = game:GetService("RunService").RenderStepped:Connect(function()
	FrameCounter += 1;

	if (tick() - FrameTimer) >= 1 then
		FPS = FrameCounter;
		FrameTimer = tick();
		FrameCounter = 0;
	end;

	if (tick() - LastUpdate) < 0.2 then
		return
	end
	LastUpdate = tick()

	local Segments = {}

	if IsOn("WatermarkUser") then table.insert(Segments, { Text = Players.LocalPlayer.Name, Bold = true }) end
	if IsOn("WatermarkGame") then table.insert(Segments, GameName) end
	if IsOn("WatermarkFps") then table.insert(Segments, { Text = tostring(math.floor(FPS)), Suffix = "FPS", Color = "OnlineColor" }) end
	if IsOn("WatermarkPing") and CanDoPing then table.insert(Segments, { Text = tostring(GetPing()), Suffix = "ms" }) end
	if IsOn("WatermarkTime") then table.insert(Segments, os.date("%H %M %S")) end
	if IsOn("WatermarkUptime") then table.insert(Segments, FormatUptime(tick() - StartTime)) end

	Library:SetWatermarkVisibility(IsOn("WatermarkEnabled"))
	Library:SetWatermarkSegments(Segments)
end);
Library:OnUnload(function()
	WatermarkConnection:Disconnect()

	print("Unloaded!")
	Library.Unloaded = true
end)

--// Configs \\--
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("MyScriptHub")
SaveManager:SetFolder("MyScriptHub/specific-game")
SaveManager:SetSubFolder("specific-place")

-- built first so the Configuration box sits at the top of the right column
SaveManager:BuildConfigSection(Tabs.Configs)

local MenuGroup = Tabs.Configs:AddLeftGroupbox("Menu")

MenuGroup:AddToggle("KeybindMenuOpen", { Default = Library.KeybindFrame.Visible, Text = "Open Keybind Menu", Callback = function(value) Library.KeybindFrame.Visible = value end})
MenuGroup:AddToggle("KeybindNotification", {Text = "Keybind notification", Default = false, Callback = function(Value) Library.KeybindNotification = Value end})
MenuGroup:AddToggle("BlurEnabled", {Text = "Blur", Default = false, Callback = function(Value) Library:SetBlur(Value) end})
MenuGroup:AddToggle("DarkOverlay", {Text = "Dark", Default = true, Callback = function(Value) Library:SetDark(Value) end})
MenuGroup:AddToggle("SnowEffect", {Text = "Snow", Default = true, Callback = function(Value) Library:SetSnow(Value) end})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
MenuGroup:AddButton("Unload", function() Library:Unload() end)

Library.ToggleKeybind = Options.MenuKeybind

local SoundGroup = Tabs.Configs:AddRightGroupbox("Sounds")

SoundGroup:AddToggle("UISound", {
	Text = "Ui sound",
	Default = true,
	Callback = function(Value)
		Library.UISound = Value
	end
})

SoundGroup:AddToggle("KeybindSound", {
	Text = "Keybind sound",
	Default = false,
	Callback = function(Value)
		Library.KeybindSound = Value
	end
})

local WatermarkGroup = Tabs.Configs:AddRightGroupbox("Watermark")

for _, Entry in ipairs({
	{ "WatermarkEnabled", "Enabled", true },
	{ "WatermarkUser", "User", true },
	{ "WatermarkGame", "Game", false },
	{ "WatermarkFps", "Fps", true },
	{ "WatermarkPing", "Ping", false },
	{ "WatermarkTime", "Time", true },
	{ "WatermarkUptime", "Uptime", false },
}) do
	WatermarkGroup:AddToggle(Entry[1], { Text = Entry[2], Default = Entry[3] })
end

ThemeManager:ApplyToTab(Tabs.Configs)

SaveManager:LoadAutoloadConfig()
