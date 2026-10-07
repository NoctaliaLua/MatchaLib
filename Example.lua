local repo = "https://raw.githubusercontent.com/NoctaliaLua/NoctaliaLib/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Players = game:GetService("Players")

Library.ShowToggleFrameInKeybinds = true
Library.ShowCustomCursor = true
Library.NotifySide = "Left"

local Window = Library:CreateWindow({
	Title = "Matcha",
	Subtitle = "Interface",
	Badge = "Pro",

	-- Username defaults to the local player's name; pass `Username = "..."` to override it
	FooterLeft = "9096 online",
	FooterCenter = "matcha.pink/discord",
	FooterRightLabel = "Build:",
	FooterRightValue = "Jun 19 2026",

	Size = UDim2.fromOffset(620, 700),
	Center = true,
	AutoShow = true,
	Resizable = true,
	ShowCustomCursor = true,
	UnlockMouseWhileOpen = true,
	NotifySide = "Left",
	TabPadding = 8,
	MenuFadeTime = 0.2
})

local Tabs = {
	Combat = Window:AddTab("Combat"),
	Visuals = Window:AddTab("Visuals"),
	World = Window:AddTab("World"),
	Character = Window:AddTab("Character"),
	Options = Window:AddTab("Options"),
	Configs = Window:AddTab("Configs"),
	NPC = Window:AddTab("NPC"),
	Teams = Window:AddTab("Teams"),
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
SilentFOV:AddToggle("SilentShowFOV", { Text = "Show Circle" })
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
TriggerBot:AddSlider("TriggerRelease", { Text = "Release (ms)", Default = 10, Min = 1, Max = 500, Rounding = 0 })

Toggles.AimbotEnabled:OnChanged(function()
	print("Aimbot enabled:", Toggles.AimbotEnabled.Value)
end)

Options.AimbotSensitivity:OnChanged(function()
	print("Aimbot sensitivity:", Options.AimbotSensitivity.Value)
end)

Options.AimbotKey:OnClick(function()
	print("Aimbot key state:", Options.AimbotKey:GetState())
end)

--// Visuals \\--
local ESPGroup = Tabs.Visuals:AddLeftGroupbox("ESP")

ESPGroup:AddToggle("ESPEnabled", { Text = "Enabled" })
ESPGroup:AddToggle("ESPBoxes", { Text = "Boxes" }):AddColorPicker("ESPBoxColor", {
	Default = Color3.fromRGB(255, 255, 255),
	Title = "Box color",
})
ESPGroup:AddToggle("ESPNames", { Text = "Names" })
ESPGroup:AddToggle("ESPHealth", { Text = "Health Bar" })
ESPGroup:AddToggle("ESPTracers", { Text = "Tracers" }):AddColorPicker("ESPTracerColor", {
	Default = Color3.fromRGB(205, 205, 214),
	Title = "Tracer color",
	Transparency = 0,
})

ESPGroup:AddSlider("ESPDistance", { Text = "Max Distance", Default = 1500, Min = 0, Max = 5000, Rounding = 0 })
ESPGroup:AddDropdown("ESPBoxStyle", { Text = "Box Style", Values = { "2D", "Corner", "3D" }, Default = 1 })

local ChamsGroup = Tabs.Visuals:AddRightGroupbox("Chams")

ChamsGroup:AddToggle("ChamsEnabled", { Text = "Enabled" })
ChamsGroup:AddLabel("Fill"):AddColorPicker("ChamsFill", { Default = Color3.fromRGB(255, 80, 80), Title = "Fill color", Transparency = 0.5 })
ChamsGroup:AddLabel("Outline"):AddColorPicker("ChamsOutline", { Default = Color3.fromRGB(255, 255, 255), Title = "Outline color" })
ChamsGroup:AddDropdown("ChamsParts", {
	Text = "Body Parts",
	Values = { "Head", "Torso", "Arms", "Legs" },
	Default = { "Head", "Torso" },
	Multi = true,
})

--// World \\--
local LightingGroup = Tabs.World:AddLeftGroupbox("Lighting")

LightingGroup:AddToggle("Fullbright", { Text = "Fullbright" })
LightingGroup:AddSlider("TimeOfDay", { Text = "Time of Day", Default = 14, Min = 0, Max = 24, Rounding = 1 })
LightingGroup:AddLabel("Ambient"):AddColorPicker("AmbientColor", { Default = Color3.fromRGB(128, 128, 128), Title = "Ambient color" })

local WorldMisc = Tabs.World:AddRightGroupbox("Misc")

WorldMisc:AddToggle("NoFog", { Text = "Remove Fog" })
WorldMisc:AddToggle("NoShadows", { Text = "Remove Shadows" })
WorldMisc:AddButton({
	Text = "Notify",
	Func = function()
		Library:Notify("This is a notification")
	end,
	Tooltip = "Shows a notification",
})

--// Character \\--
local MovementGroup = Tabs.Character:AddLeftGroupbox("Movement")

MovementGroup:AddToggle("SpeedEnabled", { Text = "Speed" }):AddKeyPicker("SpeedKey", {
	Default = "LeftShift",
	Mode = "Toggle",
	Text = "Speed",
})
MovementGroup:AddSlider("WalkSpeed", { Text = "Walk Speed", Default = 16, Min = 16, Max = 200, Rounding = 0 })
MovementGroup:AddToggle("FlyEnabled", { Text = "Fly" })
MovementGroup:AddSlider("FlySpeed", { Text = "Fly Speed", Default = 50, Min = 1, Max = 300, Rounding = 0 })

local CharacterMisc = Tabs.Character:AddRightGroupbox("Misc")

CharacterMisc:AddToggle("InfiniteJump", { Text = "Infinite Jump" })
CharacterMisc:AddInput("CharacterName", {
	Text = "Display name",
	Default = "",
	Placeholder = "Type something",
	Finished = true,
})
CharacterMisc:AddButton({
	Text = "Reset Character",
	Func = function()
		local Humanoid = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if Humanoid then
			Humanoid.Health = 0
		end
	end,
	DoubleClick = true,
	Tooltip = "Double click to reset",
})

--// NPC \\--
local NPCGroup = Tabs.NPC:AddLeftGroupbox("NPC ESP")

NPCGroup:AddToggle("NPCEnabled", { Text = "Enabled" })
NPCGroup:AddToggle("NPCNames", { Text = "Names" })
NPCGroup:AddSlider("NPCDistance", { Text = "Max Distance", Default = 800, Min = 0, Max = 3000, Rounding = 0 })

--// Teams \\--
local TeamGroup = Tabs.Teams:AddLeftGroupbox("Targets")

TeamGroup:AddDropdown("TeamList", { SpecialType = "Team", Text = "Team" })
TeamGroup:AddDropdown("PlayerList", { SpecialType = "Player", ExcludeLocalPlayer = true, Text = "Player" })

local DependencyGroup = Tabs.Teams:AddRightGroupbox("Dependencies")

DependencyGroup:AddToggle("ControlToggle", { Text = "Dependency box toggle" })

local Depbox = DependencyGroup:AddDependencyBox()
Depbox:AddToggle("DepboxToggle", { Text = "Sub-dependency box toggle" })

local SubDepbox = Depbox:AddDependencyBox()
SubDepbox:AddSlider("DepboxSlider", { Text = "Slider", Default = 50, Min = 0, Max = 100, Rounding = 0 })
SubDepbox:AddDropdown("DepboxDropdown", { Text = "Dropdown", Default = 1, Values = { "a", "b", "c" } })

Depbox:SetupDependencies({
	{ Toggles.ControlToggle, true }
})

SubDepbox:SetupDependencies({
	{ Toggles.DepboxToggle, true }
})

--// Watermark \\--
local StartTime = tick()
local GameName = tostring(game.Name)

task.spawn(function()
	local Success, Info = pcall(function()
		return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
	end)

	if Success and Info then
		GameName = Info.Name
	end
end)

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
	return ("%02d:%02d:%02d"):format(math.floor(Seconds / 3600), math.floor(Seconds / 60) % 60, Seconds % 60)
end

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

	local Parts = {}

	if IsOn("WatermarkNoctalia") then table.insert(Parts, "NoctaliaLib demo") end
	if IsOn("WatermarkGame") then table.insert(Parts, GameName) end
	if IsOn("WatermarkUser") then table.insert(Parts, Players.LocalPlayer.Name) end
	if IsOn("WatermarkFps") then table.insert(Parts, ("%d fps"):format(math.floor(FPS))) end
	if IsOn("WatermarkPing") and CanDoPing then table.insert(Parts, ("%d ms"):format(GetPing())) end
	if IsOn("WatermarkTime") then table.insert(Parts, os.date("%I:%M %p"):lower()) end
	if IsOn("WatermarkUptime") then table.insert(Parts, FormatUptime(tick() - StartTime)) end

	Library:SetWatermarkVisibility(IsOn("WatermarkEnabled") and #Parts > 0)

	if #Parts > 0 then
		Library:SetWatermark(table.concat(Parts, " | "))
	end
end);
Library:OnUnload(function()
	WatermarkConnection:Disconnect()

	print("Unloaded!")
	Library.Unloaded = true
end)

--// Options \\--
local MenuGroup = Tabs.Options:AddLeftGroupbox("Menu")

MenuGroup:AddToggle("KeybindMenuOpen", { Default = Library.KeybindFrame.Visible, Text = "Open Keybind Menu", Callback = function(value) Library.KeybindFrame.Visible = value end})
MenuGroup:AddToggle("ShowCustomCursor", {Text = "Custom Cursor", Default = true, Callback = function(Value) Library.ShowCustomCursor = Value end})
MenuGroup:AddToggle("KeybindNotification", {Text = "Keybind notification", Default = false, Callback = function(Value) Library.KeybindNotification = Value end})
MenuGroup:AddToggle("BlurEnabled", {Text = "Blur", Default = false, Callback = function(Value) Library:SetBlur(Value) end})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
MenuGroup:AddButton("Unload", function() Library:Unload() end)

Library.ToggleKeybind = Options.MenuKeybind

local SoundGroup = Tabs.Options:AddRightGroupbox("Sounds")

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

local WatermarkGroup = Tabs.Options:AddRightGroupbox("Watermark")

for _, Entry in ipairs({
	{ "WatermarkEnabled", "Enabled", true },
	{ "WatermarkNoctalia", "Noctalia", true },
	{ "WatermarkGame", "Game", false },
	{ "WatermarkUser", "User", false },
	{ "WatermarkFps", "Fps", true },
	{ "WatermarkPing", "Ping", true },
	{ "WatermarkTime", "Time", false },
	{ "WatermarkUptime", "Uptime", false },
}) do
	WatermarkGroup:AddToggle(Entry[1], { Text = Entry[2], Default = Entry[3] })
end

--// Configs \\--
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()

SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("MyScriptHub")
SaveManager:SetFolder("MyScriptHub/specific-game")
SaveManager:SetSubFolder("specific-place")

SaveManager:BuildConfigSection(Tabs.Configs)

ThemeManager:ApplyToTab(Tabs.Configs)

SaveManager:LoadAutoloadConfig()
