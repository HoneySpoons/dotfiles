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
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- Float the bash reference (SUPER+B) over the current window instead of
-- tiling it, so it never disturbs the terminal you're working in.
-- TUI.* already carries Omarchy's terminal tag, so it inherits the theme.
o.window("TUI\\.bashref", { float = true, center = true })
-- Pixels, not percentages: percentage strings are silently ignored by this
-- rule form on Hyprland 0.56 (verified -- the window fell back to ghostty's
-- own 800x600). Sized for this panel's 1280x800 logical space; on a smaller
-- display Hyprland clamps, which is the graceful direction to fail.
o.window("TUI\\.bashref", { size = { 1040, 660 } })
