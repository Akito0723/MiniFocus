# MiniFocus 实现说明

## 当前范围

MiniFocus 当前只适配 NDui 的“Shift+左键快速焦点”功能，不扫描或修改暴雪框架、
Clique、其他 oUF 布局或其他插件的点击绑定。

插件不创建新的焦点快捷键。只有 NDui 已启用快速焦点时，MiniFocus 才会为该动作
追加用户选择的团队标记。

## 文件结构

- `MiniFocus.toc`：插件元数据，并通过 `OptionalDeps: NDui` 保证 NDui 优先加载。
- `MiniFocus.lua`：设置页面、适配器调度和焦点施法语音。
- `Locales/`：英文默认文本和简体中文覆盖翻译。
- `Adapters/NDui.lua`：NDui Shift+左键快速焦点适配。
- `Media/focus_interrupt_cast.ogg`：焦点施法语音文件。

## 核心与适配器

核心文件不包含框架扫描逻辑。适配器通过 `MiniFocus:RegisterAdapter` 注册，并接收：

- `OnLogin`
- `OnGroupUpdate`
- `OnCombatEnd`

新增其他框架支持时，应创建新的适配器文件，不在核心中加入框架判断。

## 设置页面

插件在“选项 → 插件 → MiniFocus”注册原生设置页面，配置保存在账号级
`MiniFocusDB`：

### 标记

- `启用`：默认开启。关闭时恢复 NDui 原始快速焦点属性；战斗中修改会在脱战后应用。
- `标记图标选择`：可选择星形、圆形、菱形、三角、月亮、方块、十字或骷髅，
  默认使用 `[3] = "{菱形}"`。战斗中修改会在脱战后更新安全宏。

### 语音播报

- `启用`：默认开启。关闭后立即停止播放 `focus_interrupt_cast.ogg`。
- `钢条判断`：实验性功能，默认关闭。开启后，焦点目标的普通施法明确无法打断时
  不播放语音。该判断通过隐藏状态条的 `SetAlphaFromBoolean` 接收施法状态，再读取
  `GetAlpha()` 的结果完成。未开启该设置，或判断过程受到秘密值限制、发生错误、
  无法得出明确结果时，仍正常播放语音。

设置页面维护英文和简体中文两套文本，其他客户端语言回退到英文。

## NDui 单位框架

NDui 为单位按钮设置：

```lua
frame:SetAttribute("shift-type1", "focus")
```

NDui 适配器只识别这个固定属性。识别成功后，将同一个 Shift+左键动作改为：

```text
/focus [@mouseover,exists]
/tm [@mouseover,harm,exists] 3
```

对应安全属性为：

```lua
shift-type1 = "macro"
shift-macrotext1 = "..."
```

没有 `shift-type1 = "focus"` 的按钮不会被修改。

## NDui 全局 FocuserButton

NDui 创建 `FocuserButton`，并将全局 `SHIFT-BUTTON1` 重定向到该安全按钮：

```lua
type1 = "macro"
macrotext = "/focus mouseover"
```

适配器确认按钮和宏内容完全符合 NDui 当前实现后，设置左键专用宏：

```lua
macrotext1 = "/focus mouseover\n/tm [@mouseover,harm,exists] 3"
```

NDui 的覆盖绑定保持不变，仍然是：

```text
SHIFT-BUTTON1 -> FocuserButton
```

MiniFocus 不创建第二个覆盖绑定。

`harm` 条件由安全宏系统在玩家点击时判断：友方单位仍可被设置为焦点，但不会增加
标记；只有玩家可攻击的敌对单位会执行团队标记命令。

## 动态按钮与战斗锁定

适配器扫描 NDui 的 `oUF.objects`，并监听 NDui 同样关注的命名
`SecureUnitButtonTemplate` 创建过程。队伍变化时会重新扫描 NDui 单位框架。

安全属性不能在战斗中修改。战斗中发现的按钮会进入队列，在
`PLAYER_REGEN_ENABLED` 后处理。战斗前已经增强的按钮可以在战斗中正常执行。

团队标记需要玩家拥有标记权限。没有权限时，焦点动作仍会执行，标记可能设置失败。
清除焦点不会清除旧标记。

## 焦点施法语音

核心为 `focus` 注册 `UNIT_SPELLCAST_START`。敌对焦点触发该事件时立即播放语音，
不再等待施法进入可打断状态。

事件参数不会被比较、格式化或保存，因此即使施法信息包含秘密值也不会读取它。

播放前使用 `UnitCanAttack("player", "focus")` 判断焦点是否为玩家可攻击的敌对
单位。友方、中立且不可攻击或不存在的焦点不会播放。当前不处理引导和蓄力施法。

声音通过 `Master` 声道播放：

```text
Interface\AddOns\MiniFocus\Media\focus_interrupt_cast.ogg
```

替换占位 OGG 文件后即可播放实际语音。

## 手工测试

1. 禁用 NDui 快速焦点，确认 MiniFocus 不新增 Shift+左键功能。
2. 启用 NDui 快速焦点，确认 NDui 单位框架的 Shift+左键同时设置焦点和所选标记。
3. Shift+左键友方单位，确认可以设置焦点但不会增加标记。
4. 在 NDui 支持的世界鼠标悬停或3D模型场景测试全局 `FocuserButton`。
5. 在战斗前完成增强后进入战斗，确认敌对焦点和所选标记仍能执行。
6. 测试敌对焦点开始普通施法时播放语音，无论该施法是否可打断。
7. 测试引导和蓄力施法不会播放语音。
8. 将友方单位设为焦点，确认其施法不会播放语音。
