# MiniFocus Agent Guide

## Language Rules

- Keep this `AGENTS.md` file in English.
- Keep Markdown documents under `docs/` in Simplified Chinese.
- User-facing addon strings must live in locale files, not in core or adapter code.
- Add default UI strings to `Locales/enUS.lua` first, then provide Chinese overrides in
  `Locales/zhCN.lua`.

## Documentation Rules

- Treat `docs/` as the source of truth for concrete feature implementation details.
- Put behavior notes, implementation rationale, restrictions, and manual test scenarios in
  `docs/Implementation.md` or another focused document under `docs/`.
- Keep this file limited to agent-facing workflow, conventions, validation, and project
  boundaries.
- Do not duplicate detailed implementation behavior in this file; link or refer to the
  relevant document under `docs/` instead.

## Project Boundaries

- MiniFocus is a World of Warcraft Retail addon.
- The addon extends supported UI framework quick-focus actions and does not create its own
  focus keybind.
- Keep framework-specific behavior out of `MiniFocus.lua`.
- Add framework-specific support through files under `Adapters/`, loaded after
  `MiniFocus.lua` in the TOC.
- Do not modify third-party addon source files.

## Repository Map

- `MiniFocus.toc`: addon metadata, load order, optional dependencies, and saved variables.
- `MiniFocus.lua`: saved-variable defaults, native settings UI, adapter dispatch, and shared
  runtime behavior.
- `Adapters/`: framework-specific integrations.
- `Locales/`: default English strings and Chinese locale overrides.
- `docs/`: Chinese implementation documentation and manual test notes.
- `Media/`: bundled media assets.

## Coding Conventions

- Target Lua 5.1 syntax.
- Use tabs for Lua indentation.
- Keep code files ASCII unless localized user-facing text requires Unicode.
- Prefer small, backward-compatible changes.
- Keep comments short and limited to behavior that is not obvious from the code.
- Avoid broad frame enumeration or support for unlisted frameworks.

## Secure Action Constraints

- World of Warcraft secure-button attributes cannot be changed during combat.
- Apply secure attribute changes only outside combat.
- Queue required secure changes during combat and apply them after combat ends.
- Preserve original framework-owned attributes before replacing them.
- Restore original attributes when an enhancement is disabled.

## Validation

Run syntax validation after Lua changes:

```bash
luac -p Locales/enUS.lua Locales/zhCN.lua MiniFocus.lua Adapters/NDui.lua
```

For behavior validation, update and follow the manual scenarios documented under `docs/`.
