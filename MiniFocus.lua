local addonName, MiniFocus = ...
local L = MiniFocus.L

local SOUND_FILE = "Interface\\AddOns\\" .. addonName .. "\\Media\\focus_interrupt_cast.ogg"
local SOUND_CHANNEL = "Master"
local MARKER_ICON_FORMAT = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%d:18:18|t"

local defaults = {
	enableMarker = true,
	markerIcon = 3,
	preserveExistingMarker = false,
	enableCastAudio = true,
	enableInterruptCheck = false,
}

local adapters = {}
local lastSoundAt = 0
local eventFrame = CreateFrame("Frame")
local alphaProbeBar = CreateFrame("StatusBar", nil, UIParent)
alphaProbeBar:SetSize(1, 1)
alphaProbeBar:SetMinMaxValues(0, 1)
alphaProbeBar:SetValue(1)
alphaProbeBar:SetAlpha(1)
alphaProbeBar:Hide()

MiniFocusDB = MiniFocusDB or {}
for key, value in pairs(defaults) do
	if MiniFocusDB[key] == nil then
		MiniFocusDB[key] = value
	end
end

function MiniFocus:RegisterAdapter(name, adapter)
	if type(name) ~= "string" or type(adapter) ~= "table" then
		return
	end
	adapters[name] = adapter
end

local function Dispatch(method, ...)
	for _, adapter in pairs(adapters) do
		local callback = adapter[method]
		if callback then
			callback(adapter, ...)
		end
	end
end

function MiniFocus:GetSetting(key)
	return MiniFocusDB[key]
end

local function RegisterSettings()
	local category, layout = Settings.RegisterVerticalLayoutCategory(L.SettingsCategory)
	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.MarkerSection))

	local markerSetting = Settings.RegisterAddOnSetting(
		category,
		"MINIFOCUS_ENABLE_MARKER",
		"enableMarker",
		MiniFocusDB,
		Settings.VarType.Boolean,
		L.Enable,
		defaults.enableMarker
	)
	markerSetting:SetValueChangedCallback(function(_, value)
		Dispatch("OnSettingChanged", "enableMarker", value)
	end)
	local markerInitializer = Settings.CreateCheckbox(
		category,
		markerSetting,
		L.MarkerEnableTooltip
	)

	local markerIconSetting = Settings.RegisterAddOnSetting(
		category,
		"MINIFOCUS_MARKER_ICON",
		"markerIcon",
		MiniFocusDB,
		Settings.VarType.Number,
		L.MarkerIcon,
		defaults.markerIcon
	)
	markerIconSetting:SetValueChangedCallback(function(_, value)
		Dispatch("OnSettingChanged", "markerIcon", value)
	end)

	local function GetMarkerOptions()
		local container = Settings.CreateControlTextContainer()
		for index = 1, 8 do
			local icon = string.format(MARKER_ICON_FORMAT, index)
			container:Add(index, icon)
		end
		return container:GetData()
	end

	local markerIconInitializer = Settings.CreateDropdown(
		category,
		markerIconSetting,
		GetMarkerOptions,
		L.MarkerIconTooltip
	)
	markerIconInitializer:SetParentInitializer(markerInitializer)

	local preserveExistingMarkerSetting = Settings.RegisterAddOnSetting(
		category,
		"MINIFOCUS_PRESERVE_EXISTING_MARKER",
		"preserveExistingMarker",
		MiniFocusDB,
		Settings.VarType.Boolean,
		L.PreserveExistingMarker,
		defaults.preserveExistingMarker
	)
	preserveExistingMarkerSetting:SetValueChangedCallback(function(_, value)
		Dispatch("OnSettingChanged", "preserveExistingMarker", value)
	end)
	local preserveExistingMarkerInitializer = Settings.CreateCheckbox(
		category,
		preserveExistingMarkerSetting,
		L.PreserveExistingMarkerTooltip
	)
	preserveExistingMarkerInitializer:SetParentInitializer(markerInitializer)

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.AudioSection))

	local audioSetting = Settings.RegisterAddOnSetting(
		category,
		"MINIFOCUS_ENABLE_CAST_AUDIO",
		"enableCastAudio",
		MiniFocusDB,
		Settings.VarType.Boolean,
		L.Enable,
		defaults.enableCastAudio
	)
	Settings.CreateCheckbox(
		category,
		audioSetting,
		L.AudioEnableTooltip
	)

	local interruptCheckSetting = Settings.RegisterAddOnSetting(
		category,
		"MINIFOCUS_ENABLE_INTERRUPT_CHECK",
		"enableInterruptCheck",
		MiniFocusDB,
		Settings.VarType.Boolean,
		L.InterruptCheck,
		defaults.enableInterruptCheck
	)
	Settings.CreateCheckbox(
		category,
		interruptCheckSetting,
		L.InterruptCheckTooltip
	)

	Settings.RegisterAddOnCategory(category)
end

local function IsFocusCastUninterruptible()
	local notInterruptible = select(8, UnitCastingInfo("focus"))
	if notInterruptible == nil or not alphaProbeBar.SetAlphaFromBoolean then
		return false
	end

	alphaProbeBar:SetAlphaFromBoolean(notInterruptible, 0, 1)
	local alpha = alphaProbeBar:GetAlpha()
	return alpha == 0
end

local function ShouldSuppressFocusCastSound()
	if not MiniFocusDB.enableInterruptCheck then
		return false
	end

	local success, uninterruptible = pcall(IsFocusCastUninterruptible)
	if not success then
		return false
	end
	if issecretvalue and issecretvalue(uninterruptible) then
		return false
	end
	return uninterruptible == true
end

local function PlayFocusCastSound()
	if not MiniFocusDB.enableCastAudio then
		return
	end
	if not UnitCanAttack("player", "focus") then
		return
	end
	if ShouldSuppressFocusCastSound() then
		return
	end

	local now = GetTime()
	if now - lastSoundAt < 0.1 then
		return
	end
	lastSoundAt = now
	PlaySoundFile(SOUND_FILE, SOUND_CHANNEL)
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
	if event == "PLAYER_LOGIN" then
		eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "focus")
		RegisterSettings()
		Dispatch("OnLogin")
	elseif event == "PLAYER_REGEN_ENABLED" then
		Dispatch("OnCombatEnd")
	elseif event == "GROUP_ROSTER_UPDATE" then
		Dispatch("OnGroupUpdate")
	elseif event == "UNIT_SPELLCAST_START" then
		PlayFocusCastSound()
	else
		Dispatch("OnEvent", event, ...)
	end
end)

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
