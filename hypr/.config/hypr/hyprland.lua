-- Hyprland config, Lua format (Hyprland 0.55+).
--
-- Ported from the old hyprland.conf, which 0.56 still loads with a deprecation
-- notice and 0.57 stops reading. If both files exist, this one wins.
--
-- Every hl.* call and option name here was checked against the Hyprland
-- v0.56.2 source (example/hyprland.lua and src/config/lua/bindings/) and the
-- hyprland-wiki "Configuring" pages.
--   Wiki:  https://wiki.hypr.land/Configuring/
--   Type stubs for a Lua language server: /usr/share/hypr/stubs/
--   Upstream example: /usr/share/hypr/hyprland.lua


------------------
---- MONITORS ----
------------------

-- Auto-detect monitors (works on any system)
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "foot"
local fileManager = "thunar"
local menu        = "rofi -show drun"


-------------------
---- AUTOSTART ----
-------------------

-- hyprland.start fires once at launch, so this is the old exec-once.
-- Commands run through /bin/sh -c, so `&` and pipes work as before.
hl.on("hyprland.start", function()
    hl.exec_cmd("waybar & hyprpaper & mako & hypridle")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

    -- Workspace presets. The second argument is a window rule for the
    -- launched process (the old `exec-once = [workspace N] ...`). It follows
    -- the PID, so the window rules at the bottom also pin firefox/discord.
    hl.exec_cmd(terminal,              { workspace = "1" })
    hl.exec_cmd("firefox",             { workspace = "2" })
    hl.exec_cmd("discord",             { workspace = "3" })
    hl.exec_cmd(terminal .. " -e btop", { workspace = "3" })
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_THEME", "Nordzy-cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
-- JetBrains IDE workarounds for Wayland/VM
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")
hl.env("_JAVA_OPTIONS", "-Dsun.java2d.opengl=false")


-----------------------
----- PERMISSIONS -----
-----------------------

-- Permission changes need a Hyprland restart, not just a reload.
-- hl.config({ ecosystem = { enforce_permissions = true } })
-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    -- XWayland for X11 apps (JetBrains IDEs, etc.): no blurry upscaling
    xwayland = {
        force_zero_scaling = true,
    },

    general = {
        gaps_in  = 5,
        gaps_out = 20,

        border_size = 2,

        col = {
            active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        -- true = resize windows by dragging borders and gaps
        resize_on_border = false,

        -- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ first
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        -- Transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a, -- was rgba(1a1a1aee): same colour, AARRGGBB
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Curves (the stock defaults)
hl.curve("easeOutQuint",   { type = "bezier", points = { { 0.23, 1 },    { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear",         { type = "bezier", points = { { 0, 0 },       { 1, 1 } } })
hl.curve("almostLinear",   { type = "bezier", points = { { 0.5, 0.5 },   { 0.75, 1 } } })
hl.curve("quick",          { type = "bezier", points = { { 0.15, 0 },    { 0.1, 1 } } })

-- Animations (the stock pre-0.55 set: all beziers, no springs)
hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })

-- "Smart gaps" / no gaps when only one window. Uncomment all to use.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })

hl.config({
    -- The old `pseudotile = true` master switch is gone: 0.56.2 has no
    -- dwindle:pseudotile option, and SUPER+P (window.pseudo) works without it.
    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = -1,    -- 0 or 1 disables the anime mascot wallpapers
        disable_hyprland_logo   = false, -- true disables the random logo / anime girl background
        focus_on_activate       = false, -- don't let apps steal focus by asking for it
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        -- Danish and US, cycled with Alt+Shift (why the modifier is SUPER,
        -- not alt: see doc/hyprland.md)
        kb_layout  = "dk,us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "grp:alt_shift_toggle",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 to 1.0, 0 means no modification

        touchpad = {
            natural_scroll = false,
        },
    },
})

-- Three-finger horizontal swipe switches workspace
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

-- Example per-device config (`hyprctl devices` lists names)
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- the "Windows" key

-- `hyprctl binds` (the SUPER+F1 cheatsheet) shows Lua binds as
-- "dispatcher: __lua", so every bind carries a description to stay readable.
local function bind(keys, dispatcher, description, opts)
    opts = opts or {}
    opts.description = description
    return hl.bind(keys, dispatcher, opts)
end

local screenshotFile = "~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png"

bind(mainMod .. " + Q",         hl.dsp.exec_cmd(terminal),                 "Terminal")
bind(mainMod .. " + C",         hl.dsp.window.close(),                     "Close window")
bind(mainMod .. " + M",         hl.dsp.exit(),                             "Exit Hyprland")
bind(mainMod .. " + E",         hl.dsp.exec_cmd(fileManager),              "File manager")
bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(terminal .. " -e mc"),     "Midnight Commander")
bind(mainMod .. " + V",         hl.dsp.window.float({ action = "toggle" }), "Toggle floating")
bind(mainMod .. " + R",         hl.dsp.exec_cmd(menu),                     "App launcher")
bind(mainMod .. " + P",         hl.dsp.window.pseudo(),                    "Pseudotile (dwindle)")
-- SUPER+T, not SUPER+J: J is focus-down, to match AeroSpace/GlazeWM hjkl
bind(mainMod .. " + T",         hl.dsp.layout("togglesplit"),              "Toggle split (dwindle)")
bind(mainMod .. " + B",         hl.dsp.layout("preselect d"),              "Next window opens below")
bind(mainMod .. " + N",         hl.dsp.layout("preselect r"),              "Next window opens right")
bind(mainMod .. " + SHIFT + V",
    hl.dsp.exec_cmd('cliphist list | rofi -dmenu -p "Clipboard" | cliphist decode | wl-copy && notify-send "Clipboard" "Copied to clipboard"'),
    "Clipboard history")
-- SUPER+CTRL+L: plain SUPER+L is focus-right
bind(mainMod .. " + CTRL + L",  hl.dsp.exec_cmd("hyprlock"),               "Lock screen")
bind(mainMod .. " + Escape",    hl.dsp.exec_cmd("wlogout"),                "Logout menu")

-- Screenshots
bind("Print",
    hl.dsp.exec_cmd("grim " .. screenshotFile .. ' && notify-send "Screenshot" "Saved to ~/Pictures/Screenshots"'),
    "Screenshot: full screen to file")
bind(mainMod .. " + SHIFT + S",
    hl.dsp.exec_cmd('grim -g "$(slurp)" ' .. screenshotFile .. ' && notify-send "Screenshot" "Saved to ~/Pictures/Screenshots"'),
    "Screenshot: region to file")
bind(mainMod .. " + SHIFT + A",
    hl.dsp.exec_cmd('grim -g "$(slurp)" - | satty --filename - --fullscreen --output-filename ' .. screenshotFile),
    "Screenshot: region, annotate in satty")
bind(mainMod .. " + SHIFT + C",
    hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy && notify-send "Screenshot" "Copied to clipboard"'),
    "Screenshot: region to clipboard")

-- Screen recording (wf-recorder)
bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("~/.config/hypr/record.sh toggle"),        "Record screen (toggle)")
bind(mainMod .. " + CTRL + R",  hl.dsp.exec_cmd("~/.config/hypr/record.sh toggle region"), "Record region (toggle)")

-- Help menus
bind(mainMod .. " + F1",         hl.dsp.exec_cmd('hyprctl binds | rofi -dmenu -p "Keybinds"'), "Keybind cheatsheet")
bind(mainMod .. " + F2",         hl.dsp.exec_cmd("~/.config/hypr/commands-menu.sh"),           "Useful commands menu")
bind(mainMod .. " + F3",         hl.dsp.exec_cmd("~/.config/hypr/nvim-keys.sh"),               "Neovim keybindings")
bind(mainMod .. " + SHIFT + F3", hl.dsp.exec_cmd("~/.config/hypr/restart-hyprlock.sh"),        "Restart hyprlock if crashed")

-- Resize window to an exact 1080x1080 square (relative = false is "exact")
bind(mainMod .. " + equal", hl.dsp.window.resize({ x = 1080, y = 1080, relative = false }), "Resize window to 1080x1080")

-- Move focus with mainMod + hjkl (matches AeroSpace and GlazeWM) or arrow keys,
-- and move the focused window with mainMod + SHIFT + the same keys
local directions = {
    { "H", "left",  "left" },
    { "J", "down",  "down" },
    { "K", "up",    "up" },
    { "L", "right", "right" },
    { "left",  "left",  "left" },
    { "right", "right", "right" },
    { "up",    "up",    "up" },
    { "down",  "down",  "down" },
}
for _, d in ipairs(directions) do
    bind(mainMod .. " + " .. d[1], hl.dsp.focus({ direction = d[2] }), "Focus " .. d[3])
end
for _, d in ipairs(directions) do
    bind(mainMod .. " + SHIFT + " .. d[1], hl.dsp.window.move({ direction = d[2] }), "Move window " .. d[3])
end

-- Switch workspaces with mainMod + [0-9], move the active window there with
-- mainMod + SHIFT + [0-9]. Key 0 is workspace 10.
for i = 1, 10 do
    local key = i % 10
    bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }),       "Workspace " .. i)
    bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), "Move window to workspace " .. i)
end

-- Special workspace (scratchpad). toggle_special takes the bare name.
bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"),            "Toggle scratchpad")
bind(mainMod .. " + SHIFT + W", hl.dsp.window.move({ workspace = "special:magic" }), "Move window to scratchpad")

-- Scroll through existing workspaces with mainMod + scroll
bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), "Next workspace")
bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), "Previous workspace")

-- Move/resize windows with mainMod + LMB/RMB and dragging (the old bindm)
bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   "Drag window",   { mouse = true })
bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), "Resize window", { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
-- (the old bindel: works while locked, repeats when held)
local lockedRepeat = function() return { locked = true, repeating = true } end
bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), "Volume up",       lockedRepeat())
bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      "Volume down",     lockedRepeat())
bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     "Mute",            lockedRepeat())
bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   "Mute microphone", lockedRepeat())
bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  "Brightness up",   lockedRepeat())
bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  "Brightness down", lockedRepeat())

-- Media keys, require playerctl (the old bindl: works while locked)
bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       "Next track",     { locked = true })
bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), "Play/pause",     { locked = true })
bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), "Play/pause",     { locked = true })
bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   "Previous track", { locked = true })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Workspace assignments: these apps always open on their workspace
hl.window_rule({
    name      = "firefox-on-2",
    match     = { class = "^(firefox)$" },
    workspace = "2",
})
hl.window_rule({
    name      = "discord-on-3",
    match     = { class = "^(discord)$" },
    workspace = "3",
})

-- Ignore maximize requests from apps
hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})
