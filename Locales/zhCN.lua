local _, MiniFocus = ...

local locale = GetLocale()
if locale ~= "zhCN" and locale ~= "zhTW" then
	return
end

local L = MiniFocus.L
L.MarkerSection = "标记"
L.AudioSection = "语音播报"
L.Enable = "启用"
L.MarkerEnableTooltip = "增强 NDui 的 Shift+左键快速焦点，只为敌对单位添加团队标记。"
L.MarkerIcon = "标记图标选择"
L.MarkerIconTooltip = "选择敌对焦点使用的团队标记图标。"
L.AudioEnableTooltip = "敌对焦点开始施法时播放语音"
L.InterruptCheck = "钢条判断"
L.InterruptCheckTooltip = "实验性功能，当焦点目标的读条无法打断时，不进行语音播报"
