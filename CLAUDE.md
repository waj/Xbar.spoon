# Xbar Spoon

Hammerspoon Spoon that replaces the dead xbar macOS app. Runs xbar-compatible plugin scripts and renders their output as menubar items.

## Structure

Single-file Spoon: `Xbar.spoon/init.lua` (~710 lines). All logic in one file per Hammerspoon convention.

## Key Design Decisions

- **Forward declaration**: `refreshPlugin` is forward-declared (`local refreshPlugin`) because it's referenced in closures before its definition. Uses assignment syntax (`refreshPlugin = function(...)`) instead of `local function`.
- **Function ordering matters**: Lua requires `local function` to be defined before call sites (not closures). `buildMenuItem` must come before `buildMenuItems`.
- **Async execution**: Plugins run via `hs.task.new()` (non-blocking). Overlap prevention: skips execution if previous task is still running.
- **Dynamic menus**: `menubar:setMenu(callback)` is used so menu content is built at open-time, enabling alt-key detection for alternate items.

## xbar Plugin Format

Filename: `{name}.{time}{unit}.{ext}` (e.g., `date.1m.sh`). Units: s/m/h/d.

Output: Lines before first `---` are title lines (cycled in menubar). Lines after are dropdown items. Params via ` | key=value key2=value2`. Submenu depth via leading `--` pairs.

## Testing

No automated tests (Hammerspoon API not available outside the app). Test manually:
1. Create executable script in plugin dir matching filename format
2. Load spoon in Hammerspoon: `hs.loadSpoon("Xbar"); spoon.Xbar:start()`

## Reference Documentation

- xbar plugin API: https://github.com/matryer/xbar-plugins/blob/main/CONTRIBUTING.md
- xbar plugin browser (examples): https://xbarapp.com/docs/plugins/overview.html
- Hammerspoon API docs: https://www.hammerspoon.org/docs/
- Key modules: [hs.menubar](https://www.hammerspoon.org/docs/hs.menubar.html), [hs.task](https://www.hammerspoon.org/docs/hs.task.html), [hs.styledtext](https://www.hammerspoon.org/docs/hs.styledtext.html), [hs.image](https://www.hammerspoon.org/docs/hs.image.html), [hs.pathwatcher](https://www.hammerspoon.org/docs/hs.pathwatcher.html)
- Spoon conventions: https://github.com/Hammerspoon/hammerspoon/blob/master/SPOONS.md

## Syntax Check

```sh
luac -p Xbar.spoon/init.lua
```
