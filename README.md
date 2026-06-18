# MiniFocus

## 中文

MiniFocus 是一个《魔兽世界》焦点增强插件，用于扩展受支持界面框架已有的快速焦点功能。

当前支持 **NDui 的 Shift+左键快速焦点**。MiniFocus 不会创建新的焦点快捷键，也不会修改其他点击绑定。

### 功能

- 保留 NDui 原有的 Shift+左键设置焦点功能
- 仅为敌对焦点添加用户选择的团队标记
- 在设置下拉框中直接显示暴雪团队标记图标
- 敌对焦点开始普通施法时播放语音
- 提供实验性的“钢条判断”，可在明确判断为不可打断时禁止语音
- 使用暴雪原生插件设置界面
- 支持英文、简体中文和繁体中文客户端

### 设置

在游戏中打开：

```text
选项 → 插件 → MiniFocus
```

可用设置：

- **标记 → 启用**：启用敌对焦点团队标记，默认开启
- **标记图标选择**：选择星形、圆形、菱形、三角、月亮、方块、十字或骷髅，默认菱形
- **语音播报 → 启用**：敌对焦点开始普通施法时播放语音，默认开启
- **语音播报 → 钢条判断**：实验性功能；明确判断读条无法打断时不播放语音，默认关闭

“钢条判断”关闭时，只要敌对焦点开始普通施法就会播放语音。开启后，如果判断受到秘密值限制、发生错误或无法得到明确结果，仍会正常播放语音。

### 安装

1. 下载或克隆本项目。
2. 确保插件目录名称为 `MiniFocus`。
3. 将目录放入《魔兽世界》正式服插件目录：

   ```text
   World of Warcraft/_retail_/Interface/AddOns/
   ```

4. 重启游戏，或在角色选择界面重新加载插件列表。

### 支持范围

- 《魔兽世界》正式服
- NDui

NDui 必须已启用快速焦点功能。MiniFocus 不支持暴雪默认单位框架、Clique、其他 oUF 布局或其他插件的点击绑定。

设置团队标记需要相应的队伍或团队权限。没有标记权限时，设置焦点仍会正常执行。

---

## English

MiniFocus is a World of Warcraft focus enhancement addon that extends the existing quick-focus feature of supported UI frameworks.

It currently supports **NDui's Shift+Left Click quick focus**. MiniFocus does not create a new focus keybind or modify unrelated click bindings.

### Features

- Preserves NDui's existing Shift+Left Click focus action
- Adds the selected raid marker only to hostile focus targets
- Displays Blizzard raid-marker textures directly in the settings dropdown
- Plays a voice alert when a hostile focus starts a normal cast
- Provides an experimental interruptibility check that can suppress alerts for casts known to be uninterruptible
- Uses Blizzard's native AddOns settings panel
- Supports English, Simplified Chinese, and Traditional Chinese clients

### Settings

Open the following page in game:

```text
Options > AddOns > MiniFocus
```

Available settings:

- **Marker > Enable**: Enables hostile-focus raid markers; enabled by default
- **Marker Icon**: Selects Star, Circle, Diamond, Triangle, Moon, Square, Cross, or Skull; Diamond by default
- **Voice Alert > Enable**: Plays a voice alert when a hostile focus starts a normal cast; enabled by default
- **Voice Alert > Interrupt Check**: Experimental; suppresses the alert when the cast is known to be uninterruptible; disabled by default

When Interrupt Check is disabled, every normal cast started by a hostile focus triggers the voice alert. When enabled, the alert still plays if the check is restricted by secret values, raises an error, or cannot produce a definitive result.

### Installation

1. Download or clone this project.
2. Make sure the addon directory is named `MiniFocus`.
3. Place the directory in your World of Warcraft Retail addon folder:

   ```text
   World of Warcraft/_retail_/Interface/AddOns/
   ```

4. Restart the game, or reload the addon list from the character selection screen.

### Supported Scope

- World of Warcraft Retail
- NDui

NDui's quick-focus feature must be enabled. MiniFocus does not support Blizzard's default unit frames, Clique, other oUF layouts, or click bindings owned by other addons.

Applying raid markers requires the appropriate party or raid permissions. The focus action still works when the player does not have permission to set a marker.
