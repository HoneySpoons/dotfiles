-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- ── Voice ─────────────────────────────────────────────────────────────
-- voxtype: local push-to-talk speech-to-text (installed 2026-08-22).
-- Daemon was already running and feeding the bar; nothing could reach it.
o.bind("SUPER + H", "Voice to text", "voxtype record toggle")
o.bind("SUPER + SHIFT + H", "Mic kill switch", "/home/honeyspoons/.local/bin/mic-killswitch")

-- ── Web search ────────────────────────────────────────────────────────
-- PowerToys-Run style: pop a prompt, type a question, it opens in Chromium.
-- Bare domains (github.com) and full URLs go straight there instead.
-- Also reachable from SUPER+SPACE by typing "??".
o.bind("SUPER + Q", "Search the web", "omarchy-web-search")

-- ── Fullscreen ────────────────────────────────────────────────────────
-- SUPER+F now fills the screen WITHOUT sending the fullscreen state to the
-- client, so Chromium keeps its tabs and address bar. Wayland normally
-- propagates that state to the app, which is why the stock SUPER+F behaved
-- exactly like F11. True chrome-hiding fullscreen is still F11 in the browser.
hl.unbind("SUPER + F")
o.bind("SUPER + F", "Full screen (keep app chrome)",
  hl.dsp.window.fullscreen_state({ internal = 2, client = 0, action = "toggle" }))

-- ── Bash reference ────────────────────────────────────────────────────
-- SUPER+B pops a floating, searchable bash cheat sheet over whatever you're
-- doing. Sheets are plain markdown in ~/.local/share/bashref/ -- drop another
-- NN-name.md in there and it appears; nothing to rebuild.
-- Inside it: / searches, n = next hit, q = quit.
-- Routed through omarchy-launch-tui so it follows the default terminal.
o.bind("SUPER + B", "Bash reference",
  "omarchy-launch-tui --app-id=TUI.bashref /home/honeyspoons/.local/bin/bashref")
