# MiniFocus Development Guide

## Project Overview

MiniFocus is a World of Warcraft addon targeting retail interface version
`120005`.

The addon extends supported UI framework quick-focus actions. It does not
create its own focus keybind. Current framework support is limited to NDui.

Main features:

- Add a configurable raid marker when NDui quick-focus targets a hostile unit.
- Play `Media/focus_interrupt_cast.ogg` when a hostile focus starts casting.
- Provide settings through the native WoW AddOns settings panel.

## Repository Structure

- `MiniFocus.toc`: addon metadata, load order, optional dependencies, and saved
  variables.
- `MiniFocus.lua`: saved-variable defaults, native settings UI, adapter
  dispatch, and focus cast audio.
- `Adapters/NDui.lua`: NDui-specific secure-button integration.
- `Locales/enUS.lua`: default English strings.
- `Locales/zhCN.lua`: Chinese strings.
- `docs/Implementation.md`: implementation details, restrictions, and manual
  test scenarios.
- `Media/focus_interrupt_cast.ogg`: focus interrupt alert audio file.

## Architecture

Keep framework-specific behavior out of `MiniFocus.lua`.

Adapters register through:

```lua
MiniFocus:RegisterAdapter(name, adapter)
```

Supported adapter callbacks:

- `OnLogin`
- `OnGroupUpdate`
- `OnCombatEnd`
- `OnSettingChanged`
- `OnEvent`

Add future framework support in a new file under `Adapters/` and add it to the
TOC after `MiniFocus.lua`.

## Secure Action Rules

WoW secure-button attributes cannot be changed during combat.

- Apply secure attribute changes only when `InCombatLockdown()` is false.
- Queue required changes during combat and apply them after
  `PLAYER_REGEN_ENABLED`.
- Preserve original framework attributes before replacing them.
- Restore original attributes when an enhancement is disabled.
- Do not create a competing global keybind when a framework already owns the
  binding.

NDui support must remain limited to its existing Shift+Left Click quick-focus
behavior:

- Unit frames: `shift-type1 = "focus"`.
- Global helper: `SHIFT-BUTTON1` redirects to `FocuserButton`.

The marker macro must keep focus available for friendly units while marking
only hostile units:

```text
/focus [@mouseover,exists]
/tm [@mouseover,harm,exists] <markerIndex>
```

## Focus Cast Audio

The audio handler may use:

```lua
UnitCanAttack("player", "focus")
```

Play the audio directly from `UNIT_SPELLCAST_START` for `focus`. Do not read,
compare, format, or persist spellcast event values, because they may be secret
in restricted situations.

## Settings and Localization

Account-wide settings are stored in `MiniFocusDB`.

Current settings:

- `enableMarker`
- `markerIcon`
- `enableCastAudio`
- `enableInterruptCheck`

Use the native `Settings` API. Marker controls belong under the marker section,
and audio controls belong under the voice-alert section.

English is the default locale. Add all UI strings to `Locales/enUS.lua` first,
then provide Chinese overrides in `Locales/zhCN.lua`. Do not hardcode
user-visible text in core or adapter files.

## Coding Conventions

- Target Lua 5.1 syntax.
- Use tabs for Lua indentation.
- Keep files ASCII unless localized user-facing text requires Unicode.
- Keep comments short and limited to non-obvious secure-action behavior.
- Avoid generic frame enumeration or support for unlisted frameworks.
- Do not modify NDui source files.

## Validation

Run syntax validation after Lua changes:

```bash
luac -p Locales/enUS.lua Locales/zhCN.lua MiniFocus.lua Adapters/NDui.lua
```

Manual client checks should cover:

1. NDui quick focus disabled: MiniFocus adds no focus behavior.
2. NDui quick focus enabled: Shift+Left Click keeps its original focus action.
3. Hostile focus receives the selected raid marker.
4. Friendly focus is set without receiving a marker.
5. Marker settings changed during combat apply after combat.
6. Disabling marker support restores NDui's original attributes.
7. Hostile focus casts play audio when enabled, whether interruptible or not.
8. Friendly focus casts and disabled audio do not play sound.
9. English and Chinese settings text displays correctly.
