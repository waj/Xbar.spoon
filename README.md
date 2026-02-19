# Xbar.spoon

Hammerspoon Spoon that runs [xbar](https://xbarapp.com)-compatible plugin scripts as macOS menubar items.

xbar (formerly BitBar) is a popular macOS app that lets you put the output of any script in the menubar. This Spoon brings the same functionality to [Hammerspoon](https://www.hammerspoon.org), so you can use your existing xbar plugins without needing the xbar app.

## Installation

Clone this repo into your Hammerspoon Spoons directory:

```sh
git clone https://github.com/waj/xbar-spoon.git ~/.hammerspoon/Spoons/Xbar.spoon
```

Then add to your `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("Xbar")
spoon.Xbar:start()
```

Reload your Hammerspoon config and any plugins in the plugin directory will appear in your menubar.

## Configuration

By default, plugins are loaded from `~/Library/Application Support/xbar/plugins`. To use a different directory:

```lua
spoon.Xbar.pluginDirectory = "/path/to/your/plugins"
spoon.Xbar:start()
```

You can also bind a hotkey to refresh all plugins:

```lua
spoon.Xbar:bindHotkeys({ refresh = { {"cmd", "shift"}, "r" } })
```

## Plugins

Plugins use the [xbar plugin format](https://github.com/matryer/xbar-plugins/blob/main/CONTRIBUTING.md). Any executable script named `{name}.{time}{unit}.{ext}` (e.g., `cpu.5s.sh`, `weather.30m.py`) will be picked up automatically.

Browse the [xbar plugin directory](https://xbarapp.com/docs/plugins/overview.html) for hundreds of ready-to-use plugins.

## License

MIT
