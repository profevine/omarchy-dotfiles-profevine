-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.appearance")
require("hypr.autostart")

-- Settings for this machine only (bindings, apps, tweaks). Versioned in the
-- dotfiles as host.<hostname>.lua, so the shared files stay the same everywhere.
do local path = os.getenv("HOME") .. "/.config/hypr/host.lua"; local file = io.open(path, "r"); if file then file:close(); dofile(path) end end

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- Hide Wine/Steam/xembedsniproxy systray helper windows
o.window(
  {
    class = "^$",
    title = "^$",
    xwayland = true,
    float = true,
  },
  {
    opacity = "0.0 override",
    no_focus = true,
    no_blur = true,
    no_shadow = true,
    no_anim = true,
    border_size = 0,
    rounding = 0,
    decorate = false,
  }
)

o.window(
  {
    class = "steam_app_default",
    title = "^$",
    xwayland = true,
    float = true,
  },
  {
    opacity = "0.0 override",
    no_focus = true,
    no_blur = true,
    no_shadow = true,
    no_anim = true,
    border_size = 0,
    rounding = 0,
    decorate = false,
  }
)

-- Added by hyprmoncfg: its generated monitor rules load last, so nothing before this can override the applied layout.
do local path = os.getenv("HOME") .. "/.config/hypr/hyprmoncfg-monitors.lua"; local file = io.open(path, "r"); if file then file:close(); dofile(path) end end
