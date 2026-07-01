# MiniFocus 实现说明

## 当前范围

MiniFocus 当前只适配 NDui 的“Shift+左键快速焦点”功能，不扫描或修改暴雪默认单位
框架、Clique、其他 oUF 布局或其他插件的点击绑定。

插件不创建新的焦点快捷键。只有 NDui 已启用快速焦点时，MiniFocus 才会为该动作
追加团队标记增强。

## 文件结构

- `MiniFocus.toc`：插件元数据、接口版本、加载顺序、可选依赖和保存变量。
- `Locales/enUS.lua`：默认英文文本。
- `Locales/zhCN.lua`：简体中文和繁体中文客户端覆盖文本。
- `MiniFocus.lua`：保存变量默认值、原生设置页面、适配器调度和焦点施法语音。
- `Adapters/NDui.lua`：NDui Shift+左键快速焦点适配。
- `Media/focus_interrupt_cast.ogg`：焦点施法语音文件。

`MiniFocus.toc` 通过 `OptionalDeps: NDui` 让 NDui 优先加载。核心文件先加载，适配器
文件后加载，保证适配器可以通过 `MiniFocus:RegisterAdapter` 注册。

## 核心与适配器

核心文件不包含框架扫描逻辑。框架专属行为集中在 `Adapters/` 下，适配器通过以下
接口注册：

```lua
MiniFocus:RegisterAdapter(name, adapter)
```

当前适配器回调包括：

- `OnLogin`
- `OnGroupUpdate`
- `OnCombatEnd`
- `OnSettingChanged`
- `OnEvent`

`MiniFocus.lua` 使用 `Dispatch(method, ...)` 将事件和设置变化分发给已注册适配器。
新增框架支持时，应新增适配器文件，不要把框架判断写进核心文件。

## 保存变量与设置页面

账号级配置保存在 `MiniFocusDB`，当前默认值如下：

```lua
enableMarker = true
markerIcon = 3
preserveExistingMarker = false
enableCastAudio = true
enableInterruptCheck = false
```

插件在“选项 → 插件 → MiniFocus”注册原生设置页面。

### 标记设置

- `enableMarker`：默认开启。关闭时恢复 NDui 原始快速焦点属性；战斗中修改会延后到
  脱战后应用。
- `markerIcon`：默认值为 `3`，也就是菱形。设置页使用暴雪团队标记贴图直接展示
  `1` 到 `8` 的可选图标。
- `preserveExistingMarker`：默认关闭。开启后使用 12.0.7 后新增的 `/tm ~<markerIndex>`
  语法；如果目标已经有标记，不会覆盖现有标记。

`markerIcon` 在生成宏前会转为数字，并限制在 `1` 到 `8`。非法值会回退到默认菱形。

### 语音播报设置

- `enableCastAudio`：默认开启。关闭后不再播放 `focus_interrupt_cast.ogg`。
- `enableInterruptCheck`：实验性功能，默认关闭。开启后，普通施法被明确判断为无法
  打断时不播放语音。

“钢条判断”通过隐藏 `StatusBar` 的 `SetAlphaFromBoolean` 接收
`UnitCastingInfo("focus")` 的 `notInterruptible` 值，再读取 `GetAlpha()` 的结果。
如果 API 不存在、判断过程报错、结果为 secret value，或无法得到明确结果，插件会
继续播放语音，避免静默漏报。

## NDui 单位框架适配

NDui 单位框架快速焦点按钮使用：

```lua
shift-type1 = "focus"
```

适配器只增强拥有该属性的按钮。识别成功后，适配器保存原始属性，并将同一个
Shift+左键动作替换为安全宏：

```text
/focus [@mouseover,exists]
/tm [@mouseover,harm,exists] <markerIndex>
```

当 `preserveExistingMarker` 开启时，标记参数改为：

```text
/tm [@mouseover,harm,exists] ~<markerIndex>
```

对应安全属性变为：

```lua
shift-type1 = "macro"
shift-macrotext1 = "..."
```

没有 `shift-type1 = "focus"` 的按钮不会被修改。已经增强过的按钮不会重复增强。

## NDui 全局 FocuserButton 适配

NDui 还会使用全局 `FocuserButton`，并把 `SHIFT-BUTTON1` 重定向到该安全按钮。
适配器只在按钮满足以下条件时增强它：

```lua
type1 = "macro"
macrotext = "/focus mouseover"
```

增强后设置左键专用宏：

```lua
macrotext1 = "/focus mouseover\n/tm [@mouseover,harm,exists] <markerIndex>"
```

当 `preserveExistingMarker` 开启时，`macrotext1` 中的标记参数同样改为
`~<markerIndex>`。

NDui 原有覆盖绑定保持不变：

```text
SHIFT-BUTTON1 -> FocuserButton
```

MiniFocus 不创建第二个覆盖绑定。

`harm` 条件由安全宏系统在玩家点击时判断：友方单位仍可被设置为焦点，但不会增加
标记；只有玩家可攻击的敌对单位会执行团队标记命令。

## 动态按钮与战斗锁定

适配器会扫描 NDui 的 `oUF.objects`，并通过 `hooksecurefunc("CreateFrame", ...)`
监听命名的 `SecureUnitButtonTemplate` 创建过程。队伍变化时会重新扫描 NDui 单位
框架。

安全属性不能在战斗中修改。战斗中发现的按钮会进入 `pending` 队列，在
`PLAYER_REGEN_ENABLED` 后处理。战斗前已经增强的按钮可以在战斗中正常执行。

设置变更也遵循同一规则：

- 修改 `markerIcon`：非战斗中立即更新已增强按钮的宏；战斗中延后到脱战后更新。
- 修改 `preserveExistingMarker`：非战斗中立即更新已增强按钮的宏；战斗中延后到
  脱战后更新。
- 开启 `enableMarker`：非战斗中立即扫描增强；战斗中延后到脱战后扫描。
- 关闭 `enableMarker`：非战斗中立即恢复原始属性；战斗中延后到脱战后恢复。

团队标记需要玩家拥有标记权限。没有权限时，焦点动作仍会执行，标记可能设置失败。
清除焦点不会清除旧标记。

## 焦点施法语音

核心在 `PLAYER_LOGIN` 后为 `focus` 注册 `UNIT_SPELLCAST_START`。敌对焦点触发普通
施法开始事件时立即播放语音，不等待施法进入可打断状态。

播放前会检查：

1. `enableCastAudio` 是否开启。
2. `UnitCanAttack("player", "focus")` 是否为真。
3. `enableInterruptCheck` 开启时，当前施法是否被明确判断为不可打断。
4. 距离上次播放是否至少经过 `0.1` 秒，避免同一时刻重复触发。

事件参数不会被读取、比较、格式化或保存，因此即使施法事件参数包含 secret value，
也不会触碰这些值。

当前只处理普通施法开始，不处理引导和蓄力施法。声音通过 `Master` 声道播放：

```text
Interface\AddOns\MiniFocus\Media\focus_interrupt_cast.ogg
```

## 本地化

英文是默认语言。新增用户可见文本时，先加入 `Locales/enUS.lua`，再在
`Locales/zhCN.lua` 中提供中文覆盖。

`Locales/zhCN.lua` 当前同时覆盖 `zhCN` 和 `zhTW`。除 `Locales/` 文件外，不要在
核心或适配器代码中硬编码用户可见文本。

## 手工测试

1. 禁用 NDui 快速焦点，确认 MiniFocus 不新增 Shift+左键焦点行为。
2. 启用 NDui 快速焦点，确认 NDui 单位框架的 Shift+左键同时设置焦点和所选标记。
3. Shift+左键友方单位，确认可以设置焦点但不会增加标记。
4. 在 NDui 支持的世界鼠标悬停或 3D 模型场景测试全局 `FocuserButton`。
5. 在战斗前完成增强后进入战斗，确认敌对焦点和所选标记仍能执行。
6. 开启“不覆盖已有标记”后，Shift+左键已有标记的敌对单位，确认不会覆盖现有标记。
7. 关闭“不覆盖已有标记”后，Shift+左键已有标记的敌对单位，确认会应用当前选择的标记。
8. 战斗中修改标记图标或“不覆盖已有标记”，脱战后确认已增强按钮使用新宏。
9. 战斗中关闭标记增强，脱战后确认恢复 NDui 原始快速焦点属性。
10. 测试敌对焦点开始普通施法时播放语音。
11. 测试 `enableCastAudio` 关闭后不播放语音。
12. 测试友方、不可攻击或不存在的焦点施法时不播放语音。
13. 测试引导和蓄力施法不会播放语音。
14. 开启“钢条判断”后，确认明确不可打断的普通施法不播放语音；判断失败或无法明确
    判断时仍播放语音。
15. 确认英文、简体中文和繁体中文客户端的设置文本显示正确。
