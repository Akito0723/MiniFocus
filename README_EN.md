# MiniFocus

[中文](README.md) | **English**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

MiniFocus is a World of Warcraft focus enhancement addon that extends the existing quick-focus feature of supported UI frameworks.

It currently supports **NDui's Shift+Left Click quick focus**. MiniFocus does not create a new focus keybind or modify unrelated click bindings.

## Features

- Preserves NDui's existing Shift+Left Click focus action
- Adds the selected raid marker only to hostile focus targets
- Displays Blizzard raid-marker textures directly in the settings dropdown
- Plays a voice alert when a hostile focus starts a normal cast
- Provides an experimental interruptibility check that can suppress alerts for casts known to be uninterruptible
- Uses Blizzard's native AddOns settings panel
- Supports English, Simplified Chinese, and Traditional Chinese clients

## Settings

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

## Installation

1. Download or clone this project.
2. Make sure the addon directory is named `MiniFocus`.
3. Place the directory in your World of Warcraft Retail addon folder:

   ```text
   World of Warcraft/_retail_/Interface/AddOns/
   ```

4. Restart the game, or reload the addon list from the character selection screen.

## Supported Scope

- World of Warcraft Retail
- NDui

NDui's quick-focus feature must be enabled. MiniFocus does not support Blizzard's default unit frames, Clique, other oUF layouts, or click bindings owned by other addons.

Applying raid markers requires the appropriate party or raid permissions. The focus action still works when the player does not have permission to set a marker.

## License

This project is licensed under the [MIT License](LICENSE).
