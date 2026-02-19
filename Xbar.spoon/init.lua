--- === Xbar ===
---
--- xbar-compatible menubar plugin runner for Hammerspoon.
--- Reads executable scripts from a plugin directory, parses their output,
--- and renders menubar items with dropdowns, styling, and actions.

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Xbar"
obj.version = "1.0"
obj.author = "waj"
obj.license = "MIT"

--- Xbar.pluginDirectory
--- Variable
--- Path to the directory containing xbar plugin scripts.
--- Defaults to `~/Library/Application Support/xbar/plugins`.
obj.pluginDirectory = os.getenv("HOME") .. "/Library/Application Support/xbar/plugins"

local log = hs.logger.new("Xbar", "info")

-- X11 named colors (subset commonly used in xbar plugins)
local x11Colors = {
  aliceblue = "#F0F8FF", antiquewhite = "#FAEBD7", aqua = "#00FFFF",
  aquamarine = "#7FFFD4", azure = "#F0FFFF", beige = "#F5F5DC",
  bisque = "#FFE4C4", black = "#000000", blanchedalmond = "#FFEBCD",
  blue = "#0000FF", blueviolet = "#8A2BE2", brown = "#A52A2A",
  burlywood = "#DEB887", cadetblue = "#5F9EA0", chartreuse = "#7FFF00",
  chocolate = "#D2691E", coral = "#FF7F50", cornflowerblue = "#6495ED",
  cornsilk = "#FFF8DC", crimson = "#DC143C", cyan = "#00FFFF",
  darkblue = "#00008B", darkcyan = "#008B8B", darkgoldenrod = "#B8860B",
  darkgray = "#A9A9A9", darkgreen = "#006400", darkgrey = "#A9A9A9",
  darkkhaki = "#BDB76B", darkmagenta = "#8B008B", darkolivegreen = "#556B2F",
  darkorange = "#FF8C00", darkorchid = "#9932CC", darkred = "#8B0000",
  darksalmon = "#E9967A", darkseagreen = "#8FBC8F", darkslateblue = "#483D8B",
  darkslategray = "#2F4F4F", darkslategrey = "#2F4F4F", darkturquoise = "#00CED1",
  darkviolet = "#9400D3", deeppink = "#FF1493", deepskyblue = "#00BFFF",
  dimgray = "#696969", dimgrey = "#696969", dodgerblue = "#1E90FF",
  firebrick = "#B22222", floralwhite = "#FFFAF0", forestgreen = "#228B22",
  fuchsia = "#FF00FF", gainsboro = "#DCDCDC", ghostwhite = "#F8F8FF",
  gold = "#FFD700", goldenrod = "#DAA520", gray = "#808080",
  green = "#008000", greenyellow = "#ADFF2F", grey = "#808080",
  honeydew = "#F0FFF0", hotpink = "#FF69B4", indianred = "#CD5C5C",
  indigo = "#4B0082", ivory = "#FFFFF0", khaki = "#F0E68C",
  lavender = "#E6E6FA", lavenderblush = "#FFF0F5", lawngreen = "#7CFC00",
  lemonchiffon = "#FFFACD", lightblue = "#ADD8E6", lightcoral = "#F08080",
  lightcyan = "#E0FFFF", lightgoldenrodyellow = "#FAFAD2", lightgray = "#D3D3D3",
  lightgreen = "#90EE90", lightgrey = "#D3D3D3", lightpink = "#FFB6C1",
  lightsalmon = "#FFA07A", lightseagreen = "#20B2AA", lightskyblue = "#87CEFA",
  lightslategray = "#778899", lightslategrey = "#778899", lightsteelblue = "#B0C4DE",
  lightyellow = "#FFFFE0", lime = "#00FF00", limegreen = "#32CD32",
  linen = "#FAF0E6", magenta = "#FF00FF", maroon = "#800000",
  mediumaquamarine = "#66CDAA", mediumblue = "#0000CD", mediumorchid = "#BA55D3",
  mediumpurple = "#9370DB", mediumseagreen = "#3CB371", mediumslateblue = "#7B68EE",
  mediumspringgreen = "#00FA9A", mediumturquoise = "#48D1CC",
  mediumvioletred = "#C71585", midnightblue = "#191970", mintcream = "#F5FFFA",
  mistyrose = "#FFE4E1", moccasin = "#FFE4B5", navajowhite = "#FFDEAD",
  navy = "#000080", oldlace = "#FDF5E6", olive = "#808000",
  olivedrab = "#6B8E23", orange = "#FFA500", orangered = "#FF4500",
  orchid = "#DA70D6", palegoldenrod = "#EEE8AA", palegreen = "#98FB98",
  paleturquoise = "#AFEEEE", palevioletred = "#DB7093", papayawhip = "#FFEFD5",
  peachpuff = "#FFDAB9", peru = "#CD853F", pink = "#FFC0CB",
  plum = "#DDA0DD", powderblue = "#B0E0E6", purple = "#800080",
  rebeccapurple = "#663399", red = "#FF0000", rosybrown = "#BC8F8F",
  royalblue = "#4169E1", saddlebrown = "#8B4513", salmon = "#FA8072",
  sandybrown = "#F4A460", seagreen = "#2E8B57", seashell = "#FFF5EE",
  sienna = "#A0522D", silver = "#C0C0C0", skyblue = "#87CEEB",
  slateblue = "#6A5ACD", slategray = "#708090", slategrey = "#708090",
  snow = "#FFFAFA", springgreen = "#00FF7F", steelblue = "#4682B4",
  tan = "#D2B48C", teal = "#008080", thistle = "#D8BFD8",
  tomato = "#FF6347", turquoise = "#40E0D0", violet = "#EE82EE",
  wheat = "#F5DEB3", white = "#FFFFFF", whitesmoke = "#F5F5F5",
  yellow = "#FFFF00", yellowgreen = "#9ACD32",
}

--------------------------------------------------------------------------------
-- Filename Parser
--------------------------------------------------------------------------------

local function parseFilename(filename)
  local name, timeStr, unit, ext = filename:match("^(.+)%.(%d+)([smhd])%.(.+)$")
  if not name then return nil end
  local multipliers = { s = 1, m = 60, h = 3600, d = 86400 }
  local interval = tonumber(timeStr) * multipliers[unit]
  return { name = name, interval = interval, ext = ext }
end

--------------------------------------------------------------------------------
-- Output Parser
--------------------------------------------------------------------------------

local function parseParams(paramStr)
  local params = {}
  -- Parse key=value pairs, handling quoted values
  local i = 1
  while i <= #paramStr do
    -- skip whitespace
    i = paramStr:match("^%s*()", i)
    if i > #paramStr then break end

    -- match key
    local key, eqPos = paramStr:match("^(%w+)=()", i)
    if not key then break end
    i = eqPos

    local value
    local ch = paramStr:sub(i, i)
    if ch == '"' then
      -- quoted value
      local closing = paramStr:find('"', i + 1, true)
      if closing then
        value = paramStr:sub(i + 1, closing - 1)
        i = closing + 1
      else
        value = paramStr:sub(i + 1)
        i = #paramStr + 1
      end
    elseif ch == "'" then
      local closing = paramStr:find("'", i + 1, true)
      if closing then
        value = paramStr:sub(i + 1, closing - 1)
        i = closing + 1
      else
        value = paramStr:sub(i + 1)
        i = #paramStr + 1
      end
    else
      -- unquoted value: read until next space
      local val, nextPos = paramStr:match("^(%S+)()", i)
      value = val or ""
      i = nextPos or (#paramStr + 1)
    end

    params[key] = value
  end
  return params
end

local function parseLine(line)
  -- Split on " | " to separate display text from params
  local text, paramStr = line:match("^(.-)%s+|%s+(.+)$")
  if not text then
    text = line
    paramStr = nil
  end
  local params = paramStr and parseParams(paramStr) or {}
  return text, params
end

local function parseSubmenuLevel(text)
  -- Count leading "--" pairs
  local dashes = text:match("^(%-%-+)")
  if not dashes then return 0, text end
  local level = math.floor(#dashes / 2)
  local stripped = text:sub(level * 2 + 1)
  return level, stripped
end

local function parseOutput(stdout)
  local lines = {}
  for line in (stdout .. "\n"):gmatch("(.-)\n") do
    table.insert(lines, line)
  end
  -- Remove trailing empty line from the split
  if #lines > 0 and lines[#lines] == "" then
    table.remove(lines)
  end

  local titles = {}
  local menuItems = {}
  local inMenu = false

  for _, line in ipairs(lines) do
    if not inMenu then
      if line == "---" then
        inMenu = true
      else
        local text, params = parseLine(line)
        table.insert(titles, { text = text, params = params })
      end
    else
      if line == "---" then
        table.insert(menuItems, { separator = true, level = 0 })
      else
        local text, params = parseLine(line)
        local level, stripped = parseSubmenuLevel(text)
        table.insert(menuItems, {
          text = stripped,
          params = params,
          level = level,
        })
      end
    end
  end

  -- If no titles parsed, provide a fallback
  if #titles == 0 then
    table.insert(titles, { text = "…", params = {} })
  end

  return titles, menuItems
end

--------------------------------------------------------------------------------
-- Color Helper
--------------------------------------------------------------------------------

local function resolveColor(colorStr)
  if not colorStr then return nil end
  -- Hex color
  if colorStr:sub(1, 1) == "#" then
    return { hex = colorStr }
  end
  -- X11 named color
  local hex = x11Colors[colorStr:lower()]
  if hex then
    return { hex = hex }
  end
  -- Try as-is (Hammerspoon may understand some names)
  return { hex = colorStr }
end

--------------------------------------------------------------------------------
-- Styled Text Builder
--------------------------------------------------------------------------------

local function buildStyledText(text, params)
  local attrs = {}

  if params.color then
    attrs.color = resolveColor(params.color)
  end

  local fontAttrs = {}
  if params.font then fontAttrs.name = params.font end
  if params.size then fontAttrs.size = tonumber(params.size) end
  if next(fontAttrs) then attrs.font = fontAttrs end

  -- Apply trim
  if params.trim == "true" or params.trim == nil then
    text = text:match("^%s*(.-)%s*$")
  end

  -- Apply length truncation
  if params.length then
    local maxLen = tonumber(params.length)
    if maxLen and #text > maxLen then
      text = text:sub(1, maxLen) .. "…"
    end
  end

  if next(attrs) then
    return hs.styledtext.new(text, attrs)
  end
  return text
end

--------------------------------------------------------------------------------
-- Image Helper
--------------------------------------------------------------------------------

local function buildImage(params)
  local imgData = params.image or params.templateImage
  if not imgData then return nil end

  local img = hs.image.imageFromURL("data:image/png;base64," .. imgData)
  if img and params.templateImage then
    img:template(true)
  end
  return img
end

--------------------------------------------------------------------------------
-- Menu Item Construction
--------------------------------------------------------------------------------

local function buildMenuItem(item, pluginCtx)
  local params = item.params or {}
  local entry = {}

  -- Title with styling
  entry.title = buildStyledText(item.text, params)

  -- Image
  local img = buildImage(params)
  if img then entry.image = img end

  -- Disabled
  if params.disabled == "true" then
    entry.disabled = true
  end

  -- alternate (shown when Option is held)
  if params.alternate == "true" then
    entry.alternate = true
  end

  -- Action: href
  if params.href then
    entry.fn = function()
      hs.urlevent.openURL(params.href)
      if params.refresh == "true" then
        pluginCtx.refresh()
      end
    end
  -- Action: shell
  elseif params.shell then
    entry.fn = function()
      -- Collect param1..paramN
      local args = {}
      local n = 1
      while params["param" .. n] do
        table.insert(args, params["param" .. n])
        n = n + 1
      end

      if params.terminal == "true" then
        -- Run in Terminal via osascript
        local cmdParts = { params.shell }
        for _, a in ipairs(args) do
          table.insert(cmdParts, "'" .. a:gsub("'", "'\\''") .. "'")
        end
        local shellCmd = table.concat(cmdParts, " ")
        local script = string.format(
          'tell application "Terminal"\nactivate\ndo script %q\nend tell',
          shellCmd
        )
        hs.osascript.applescript(script)
        if params.refresh == "true" then
          pluginCtx.refresh()
        end
      else
        -- Run silently via hs.task
        local t = hs.task.new(params.shell, function()
          if params.refresh == "true" then
            pluginCtx.refresh()
          end
        end, args)
        t:start()
      end
    end
  -- Action: refresh only
  elseif params.refresh == "true" then
    entry.fn = function()
      pluginCtx.refresh()
    end
  end

  return entry
end

local function buildMenuItems(flatItems, pluginCtx)
  -- Build nested menu tree from flat list using a stack
  local root = {}
  local stack = { { items = root, level = -1 } }

  for _, item in ipairs(flatItems) do
    if item.separator then
      -- Pop stack back to root level for separators
      while #stack > 1 and stack[#stack].level >= 0 do
        table.remove(stack)
      end
      local parent = stack[#stack]
      table.insert(parent.items, { title = "-" })
    else
      local level = item.level
      -- Pop stack back to the correct parent level
      while #stack > 1 and stack[#stack].level >= level do
        table.remove(stack)
      end

      local menuEntry = buildMenuItem(item, pluginCtx)
      local parent = stack[#stack]
      table.insert(parent.items, menuEntry)

      -- Push this entry as potential parent for deeper items
      if not menuEntry.menu then
        menuEntry.menu = {}
      end
      table.insert(stack, { items = menuEntry.menu, level = level })
    end
  end

  -- Clean up empty submenus
  local function cleanMenus(items)
    for _, entry in ipairs(items) do
      if entry.menu then
        if #entry.menu == 0 then
          entry.menu = nil
        else
          cleanMenus(entry.menu)
        end
      end
    end
  end
  cleanMenus(root)

  return root
end

--------------------------------------------------------------------------------
-- Plugin Execution
--------------------------------------------------------------------------------

local function isDarkMode()
  local _, result = hs.osascript.applescript(
    'tell application "System Events" to tell appearance preferences to return dark mode'
  )
  return result and "true" or "false"
end

local function loadVarsFile(pluginPath)
  local varsPath = pluginPath .. ".vars.json"
  local f = io.open(varsPath, "r")
  if not f then return {} end
  local content = f:read("*a")
  f:close()
  local ok, decoded = pcall(hs.json.decode, content)
  if not ok or type(decoded) ~= "table" then
    log.w("Failed to parse vars file: " .. varsPath)
    return {}
  end
  local vars = {}
  for k, v in pairs(decoded) do
    vars[tostring(k)] = tostring(v)
  end
  return vars
end

local function executePlugin(plugin, callback)
  -- Skip if previous task still running
  if plugin.task and plugin.task:isRunning() then
    log.d("Skipping " .. plugin.name .. ": previous task still running")
    return
  end

  local env = {
    XBARDarkMode = isDarkMode(),
    PATH = os.getenv("PATH") or "/usr/local/bin:/usr/bin:/bin",
    HOME = os.getenv("HOME") or "",
    SHELL = os.getenv("SHELL") or "/bin/zsh",
  }

  for k, v in pairs(loadVarsFile(plugin.path)) do
    env[k] = v
  end

  plugin.task = hs.task.new(plugin.path, function(exitCode, stdOut, stdErr)
    plugin.task = nil
    callback(exitCode, stdOut or "", stdErr or "")
  end)

  plugin.task:setEnvironment(env)

  if not plugin.task:start() then
    log.e("Failed to start task for " .. plugin.name)
    plugin.task = nil
  end
end

--------------------------------------------------------------------------------
-- Relative Time Formatter
--------------------------------------------------------------------------------

local function relativeTime(timestamp)
  if not timestamp then return nil end
  local diff = os.time() - timestamp
  if diff < 10 then return "just now" end
  if diff < 60 then return diff .. "s ago" end
  if diff < 3600 then return math.floor(diff / 60) .. "m ago" end
  if diff < 86400 then return math.floor(diff / 3600) .. "h ago" end
  return math.floor(diff / 86400) .. "d ago"
end

--------------------------------------------------------------------------------
-- Plugin Lifecycle
--------------------------------------------------------------------------------

local refreshPlugin -- forward declaration
local function updateMenubar(plugin)
  if not plugin.menubar then return end

  local titles = plugin.titles or {}
  local menuItems = plugin.menuItems or {}

  -- Stop existing cycle timer
  if plugin.cycleTimer then
    plugin.cycleTimer:stop()
    plugin.cycleTimer = nil
  end

  -- Set initial title
  plugin.cycleIndex = 1
  local function applyTitle(idx)
    local t = titles[idx]
    if not t then return end
    local text = t.text
    if plugin.lastError then
      text = text .. " ⚠"
    end
    local styled = buildStyledText(text, t.params)
    plugin.menubar:setTitle(styled)
    local img = buildImage(t.params)
    if img then
      plugin.menubar:setIcon(img)
    else
      plugin.menubar:setIcon(nil)
    end
  end

  applyTitle(1)

  -- Title cycling
  if #titles > 1 then
    plugin.cycleTimer = hs.timer.doEvery(4, function()
      plugin.cycleIndex = (plugin.cycleIndex % #titles) + 1
      applyTitle(plugin.cycleIndex)
    end)
  end

  -- Dynamic menu callback
  plugin.menubar:setMenu(function()
    local pluginCtx = {
      refresh = function() refreshPlugin(plugin) end
    }

    -- Check for alt key to support alternate items
    local mods = hs.eventtap.checkKeyboardModifiers()
    local items = buildMenuItems(menuItems, pluginCtx)

    local result
    if mods.alt then
      -- Show alternate items, hide non-alternate items that have an alternate sibling
      result = items
    else
      -- Filter out alternate items
      local function filterAlternates(menuList)
        local filtered = {}
        for _, entry in ipairs(menuList) do
          if not entry.alternate then
            if entry.menu then
              entry.menu = filterAlternates(entry.menu)
            end
            table.insert(filtered, entry)
          end
        end
        return filtered
      end
      result = filterAlternates(items)
    end

    -- Append status footer
    table.insert(result, { title = "-" })
    local statusText
    if plugin.lastRefresh then
      statusText = plugin.name .. " · Updated " .. relativeTime(plugin.lastRefresh)
    else
      statusText = plugin.name .. " · Loading..."
    end
    table.insert(result, {
      title = hs.styledtext.new(statusText, { color = { hex = "#888888" }, font = { size = 11 } }),
      disabled = true,
    })
    if plugin.lastError then
      local errDisplay = plugin.lastError
      if #errDisplay > 80 then
        errDisplay = errDisplay:sub(1, 80) .. "…"
      end
      table.insert(result, {
        title = hs.styledtext.new("⚠ " .. errDisplay, { color = { hex = "#CC6666" }, font = { size = 11 } }),
        disabled = true,
      })
    end
    table.insert(result, {
      title = "Refresh",
      shortcut = "r",
      fn = function() refreshPlugin(plugin) end,
    })

    return result
  end)
end

refreshPlugin = function(plugin)
  executePlugin(plugin, function(exitCode, stdOut, stdErr)
    if exitCode ~= 0 then
      log.w(plugin.name .. " exited with code " .. tostring(exitCode))
      local errMsg = "Error (exit code " .. tostring(exitCode) .. ")"
      if stdErr and #stdErr > 0 then
        errMsg = errMsg .. ": " .. stdErr:sub(1, 200):gsub("\n", " ")
      end
      plugin.lastError = errMsg
      if #plugin.menuItems == 0 then
        -- Never loaded successfully — show error in menu
        plugin.titles = { { text = plugin.name .. " ⚠", params = {} } }
        plugin.menuItems = {
          { text = errMsg, params = { disabled = "true" }, level = 0 },
        }
      end
      -- Otherwise keep existing titles/menuItems, footer will show the error
    else
      local ok, titles, menuItems = pcall(parseOutput, stdOut)
      if ok then
        plugin.titles = titles
        plugin.menuItems = menuItems
        plugin.lastRefresh = os.time()
        plugin.lastError = nil
      else
        log.e("Parse error for " .. plugin.name .. ": " .. tostring(titles))
        local errMsg = "Parse error: " .. tostring(titles):sub(1, 200)
        plugin.lastError = errMsg
        if #plugin.menuItems == 0 then
          plugin.titles = { { text = plugin.name .. " ⚠", params = {} } }
          plugin.menuItems = {
            { text = errMsg, params = { disabled = "true" }, level = 0 },
          }
        end
      end
    end
    updateMenubar(plugin)
  end)
end

--------------------------------------------------------------------------------
-- Directory Scanner
--------------------------------------------------------------------------------

local function isExecutable(path)
  local attrs = hs.fs.attributes(path)
  if not attrs or attrs.mode ~= "file" then return false end
  -- Check execute permission via hs.fs.attributes permissions field
  local perms = attrs.permissions
  if perms then
    return perms:sub(3, 3) == "x" or perms:sub(6, 6) == "x" or perms:sub(9, 9) == "x"
  end
  -- Fallback: try os.execute
  local ok = os.execute('test -x "' .. path .. '"')
  return ok == true
end

local function scanDirectory(self)
  local dir = self.pluginDirectory
  local found = {}

  local iter, dirObj = hs.fs.dir(dir)
  if not iter then
    log.e("Cannot scan directory: " .. dir)
    return
  end

  for filename in iter, dirObj do
    if filename:sub(1, 1) ~= "." then
      local parsed = parseFilename(filename)
      if parsed then
        local fullPath = dir .. "/" .. filename
        if isExecutable(fullPath) then
          found[fullPath] = parsed
        end
      end
    end
  end

  -- Remove plugins that no longer exist
  for path, plugin in pairs(self.plugins) do
    if not found[path] then
      log.i("Removing plugin: " .. plugin.name)
      if plugin.timer then plugin.timer:stop() end
      if plugin.cycleTimer then plugin.cycleTimer:stop() end
      if plugin.task and plugin.task:isRunning() then plugin.task:terminate() end
      if plugin.menubar then plugin.menubar:delete() end
      self.plugins[path] = nil
    end
  end

  -- Add or update plugins
  for path, parsed in pairs(found) do
    if not self.plugins[path] then
      log.i("Adding plugin: " .. parsed.name .. " (interval: " .. parsed.interval .. "s)")
      local plugin = {
        path = path,
        name = parsed.name,
        interval = parsed.interval,
        menubar = hs.menubar.new(true, parsed.name),
        timer = nil,
        cycleTimer = nil,
        task = nil,
        titles = { { text = parsed.name, params = {} } },
        menuItems = {},
        cycleIndex = 1,
        lastRefresh = nil,
        lastError = nil,
      }
      self.plugins[path] = plugin

      -- Set initial title
      plugin.menubar:setTitle(parsed.name)

      -- Initial execution
      refreshPlugin(plugin)

      -- Periodic refresh
      if parsed.interval > 0 then
        plugin.timer = hs.timer.doEvery(parsed.interval, function()
          refreshPlugin(plugin)
        end)
      end
    end
  end
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Xbar:init()
--- Method
--- Initialize the Spoon.
function obj:init()
  self.plugins = {}
  self.watcher = nil
  return self
end

--- Xbar:start()
--- Method
--- Start scanning the plugin directory and rendering menubar items.
function obj:start()
  log.i("Starting Xbar with plugin directory: " .. self.pluginDirectory)

  -- Ensure plugin directory exists
  local attrs = hs.fs.attributes(self.pluginDirectory)
  if not attrs then
    log.w("Plugin directory does not exist, creating: " .. self.pluginDirectory)
    hs.fs.mkdir(self.pluginDirectory)
  end

  -- Initial scan
  scanDirectory(self)

  -- Watch for changes
  self.watcher = hs.pathwatcher.new(self.pluginDirectory, function(paths, flagTables)
    log.i("Plugin directory changed, rescanning...")
    scanDirectory(self)
  end)
  self.watcher:start()

  return self
end

--- Xbar:stop()
--- Method
--- Stop all plugins, timers, and watchers.
function obj:stop()
  log.i("Stopping Xbar")

  if self.watcher then
    self.watcher:stop()
    self.watcher = nil
  end

  for path, plugin in pairs(self.plugins) do
    if plugin.timer then plugin.timer:stop() end
    if plugin.cycleTimer then plugin.cycleTimer:stop() end
    if plugin.task and plugin.task:isRunning() then plugin.task:terminate() end
    if plugin.menubar then plugin.menubar:delete() end
  end
  self.plugins = {}

  return self
end

--- Xbar:refreshAll()
--- Method
--- Force refresh all plugins immediately.
function obj:refreshAll()
  for _, plugin in pairs(self.plugins) do
    refreshPlugin(plugin)
  end
  return self
end

--- Xbar:bindHotkeys(mapping)
--- Method
--- Bind hotkeys for Xbar actions.
---
--- Parameters:
---  * mapping - A table with action names as keys and hotkey specs as values.
---    Supported actions: "refresh" (refresh all plugins)
function obj:bindHotkeys(mapping)
  if mapping.refresh then
    hs.hotkey.bind(mapping.refresh[1], mapping.refresh[2], function()
      self:refreshAll()
    end)
  end
  return self
end

return obj
