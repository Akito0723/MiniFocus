local _, MiniFocus = ...

local NDUI_ADDON_NAME = "NDui"
local FOCUS_TYPE_ATTRIBUTE = "shift-type1"
local FOCUS_MACRO_ATTRIBUTE = "shift-macrotext1"
local FOCUS_MACRO_NAME_ATTRIBUTE = "shift-macro1"

local adapter = {
	pending = {},
	originalAttributes = {},
	enabled = false,
	settingsPending = false,
}

local function IsNDuiLoaded()
	return C_AddOns.IsAddOnLoaded(NDUI_ADDON_NAME) and type(_G.NDui) == "table"
end

local function GetMarkerIcon()
	local markerIcon = tonumber(MiniFocus:GetSetting("markerIcon")) or 3
	return math.max(1, math.min(8, math.floor(markerIcon)))
end

local function GetMarkerArgument()
	local markerIcon = GetMarkerIcon()
	if MiniFocus:GetSetting("preserveExistingMarker") then
		return "~" .. markerIcon
	end
	return tostring(markerIcon)
end

local function GetUnitMarkerMacro()
	return string.format(
		"/focus [@mouseover,exists]\n/tm [@mouseover,harm,exists] %s",
		GetMarkerArgument()
	)
end

local function GetGlobalMarkerMacro()
	return string.format(
		"/focus mouseover\n/tm [@mouseover,harm,exists] %s",
		GetMarkerArgument()
	)
end

function adapter:EnhanceUnitButton(frame)
	if not frame or not frame.GetAttribute or not frame.SetAttribute then
		return
	end
	if frame.IsForbidden and frame:IsForbidden() then
		return
	end
	if self.originalAttributes[frame] then
		return
	end
	if frame:GetAttribute(FOCUS_TYPE_ATTRIBUTE) ~= "focus" then
		return
	end
	if InCombatLockdown() then
		self.pending[frame] = "unit"
		return
	end

	self.pending[frame] = nil
	self.originalAttributes[frame] = {
		kind = "unit",
		type = frame:GetAttribute(FOCUS_TYPE_ATTRIBUTE),
		macro = frame:GetAttribute(FOCUS_MACRO_NAME_ATTRIBUTE),
		macrotext = frame:GetAttribute(FOCUS_MACRO_ATTRIBUTE),
	}
	frame:SetAttribute(FOCUS_MACRO_NAME_ATTRIBUTE, nil)
	frame:SetAttribute(FOCUS_MACRO_ATTRIBUTE, GetUnitMarkerMacro())
	frame:SetAttribute(FOCUS_TYPE_ATTRIBUTE, "macro")
end

function adapter:EnhanceGlobalButton()
	local frame = _G.FocuserButton
	if not frame or not frame.GetAttribute or not frame.SetAttribute then
		return
	end
	if self.originalAttributes[frame] then
		return
	end
	if frame:GetAttribute("type1") ~= "macro" then
		return
	end

	local macroText = frame:GetAttribute("macrotext")
	if type(macroText) ~= "string" or not macroText:lower():match("^%s*/focus%s+mouseover%s*$") then
		return
	end
	if InCombatLockdown() then
		self.pending[frame] = "global"
		return
	end

	self.pending[frame] = nil
	self.originalAttributes[frame] = {
		kind = "global",
		macro = frame:GetAttribute("macro1"),
		macrotext = frame:GetAttribute("macrotext1"),
	}
	frame:SetAttribute("macro1", nil)
	frame:SetAttribute("macrotext1", GetGlobalMarkerMacro())
end

function adapter:UpdateMarkerMacros()
	if InCombatLockdown() then
		self.settingsPending = true
		return
	end

	for frame, attributes in pairs(self.originalAttributes) do
		if not frame.IsForbidden or not frame:IsForbidden() then
			if attributes.kind == "unit" then
				frame:SetAttribute(FOCUS_MACRO_ATTRIBUTE, GetUnitMarkerMacro())
			else
				frame:SetAttribute("macrotext1", GetGlobalMarkerMacro())
			end
		end
	end
end

function adapter:RestoreButtons()
	if InCombatLockdown() then
		self.settingsPending = true
		return
	end

	self.settingsPending = false
	for frame, attributes in pairs(self.originalAttributes) do
		if not frame.IsForbidden or not frame:IsForbidden() then
			if attributes.kind == "unit" then
				frame:SetAttribute(FOCUS_TYPE_ATTRIBUTE, attributes.type)
				frame:SetAttribute(FOCUS_MACRO_NAME_ATTRIBUTE, attributes.macro)
				frame:SetAttribute(FOCUS_MACRO_ATTRIBUTE, attributes.macrotext)
			else
				frame:SetAttribute("macro1", attributes.macro)
				frame:SetAttribute("macrotext1", attributes.macrotext)
			end
		end
		self.originalAttributes[frame] = nil
		self.pending[frame] = nil
	end
end

function adapter:ScanNDuiFrames()
	if not self.enabled or not MiniFocus:GetSetting("enableMarker") then
		return
	end

	self:EnhanceGlobalButton()

	local ns = _G.NDui
	local oUF = ns and ns.oUF
	if oUF and oUF.objects then
		for _, frame in next, oUF.objects do
			self:EnhanceUnitButton(frame)
		end
	end
end

function adapter:OnLogin()
	if not IsNDuiLoaded() then
		return
	end

	self.enabled = true
	self:ScanNDuiFrames()

	hooksecurefunc("CreateFrame", function(_, name, _, template)
		if name and template == "SecureUnitButtonTemplate" then
			self:EnhanceUnitButton(_G[name])
		end
	end)

	C_Timer.After(1, function()
		self:ScanNDuiFrames()
	end)
end

function adapter:OnGroupUpdate()
	self:ScanNDuiFrames()
end

function adapter:OnSettingChanged(key, value)
	if key == "markerIcon" or key == "preserveExistingMarker" then
		if MiniFocus:GetSetting("enableMarker") then
			self:UpdateMarkerMacros()
		end
		return
	end
	if key ~= "enableMarker" then
		return
	end

	if value then
		if InCombatLockdown() then
			self.settingsPending = true
		else
			self:ScanNDuiFrames()
		end
	else
		self:RestoreButtons()
	end
end

function adapter:OnCombatEnd()
	if self.settingsPending then
		self.settingsPending = false
		if MiniFocus:GetSetting("enableMarker") then
			self:UpdateMarkerMacros()
			self:ScanNDuiFrames()
		else
			self:RestoreButtons()
		end
	end

	if MiniFocus:GetSetting("enableMarker") then
		for frame, kind in pairs(self.pending) do
			if kind == "global" then
				self:EnhanceGlobalButton()
			else
				self:EnhanceUnitButton(frame)
			end
		end
	else
		wipe(self.pending)
	end
	self:ScanNDuiFrames()
end

MiniFocus:RegisterAdapter(NDUI_ADDON_NAME, adapter)
