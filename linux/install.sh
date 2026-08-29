#!/usr/bin/env bash
# Restore this Omarchy setup onto a fresh machine.
#
# Run AFTER a stock Omarchy install, from inside the cloned repo:
#     ./linux/install.sh
#
# Safe to re-run. Never overwrites without keeping a timestamped .bak.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%s)"
DRY="${DRY_RUN:-0}"

say()  { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
run()  { [ "$DRY" = "1" ] && { info "(dry-run) $*"; return 0; }; "$@"; }

# Copy a file, preserving anything already there.
place() {
  local src="$1" dst="$2"
  [ -e "$src" ] || { info "skip (missing in repo): $src"; return 0; }
  run mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && ! cmp -s "$src" "$dst"; then
    info "backup: $dst -> $dst.bak.$STAMP"
    run cp -a "$dst" "$dst.bak.$STAMP"
  fi
  run cp -a "$src" "$dst"
  info "placed: $dst"
}

command -v pacman >/dev/null || { echo "This expects an Arch-based system (Omarchy)."; exit 1; }
command -v omarchy >/dev/null || info "WARNING: 'omarchy' not found — install Omarchy first for the theme/plugin steps."

say "1/6  Packages  ($(wc -l < "$HERE/packages.txt") explicit, all from official repos — no AUR)"
run sudo pacman -S --needed --noconfirm - < "$HERE/packages.txt" || info "some packages failed; continuing"

say "2/6  Config files"
for f in autostart.lua bindings.lua hyprland.lua input.lua looknfeel.lua monitors.lua hyprsunset.conf xdph.conf .luarc.json; do
  place "$HERE/config/hypr/$f" "$HOME/.config/hypr/$f"
done
place "$HERE/config/omarchy/shell.json"                    "$HOME/.config/omarchy/shell.json"
place "$HERE/config/omarchy/branding/about.txt"            "$HOME/.config/omarchy/branding/about.txt"
place "$HERE/config/omarchy/branding/screensaver.txt"      "$HOME/.config/omarchy/branding/screensaver.txt"
place "$HERE/config/omarchy/defaults/agent"                "$HOME/.config/omarchy/defaults/agent"
place "$HERE/config/omarchy/extensions/omarchy-menu.jsonc" "$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
place "$HERE/config/mise-config.toml"                      "$HOME/.config/mise/config.toml"

say "3/6  Own scripts -> ~/.local/bin"
run mkdir -p "$HOME/.local/bin"
for s in "$HERE"/bin/*; do
  place "$s" "$HOME/.local/bin/$(basename "$s")"
  run chmod +x "$HOME/.local/bin/$(basename "$s")"
done

say "4/6  mise tools  (this regenerates the ~/.local/bin shims — they are NOT stored in git)"
if command -v mise >/dev/null; then
  run mise install
  info "shims regenerate on first use of each tool"
else
  info "mise not installed; skipping. Install it, then re-run."
fi

say "5/6  Themes  (cloned, not vendored — 111 MB stays out of the repo)"
grep -v '^#' "$HERE/themes.txt" | grep -v '^[[:space:]]*$' | while read -r url name; do
  dst="$HOME/.config/omarchy/themes/$name"
  if [ -d "$dst/.git" ]; then info "already present: $name"
  else info "cloning $name"; run git clone --depth 1 "$url" "$dst" || info "failed: $name"; fi
done

say "6/6  Omarchy plugins"
grep -v '^#' "$HERE/plugins.txt" | grep -v '^[[:space:]]*$' | while read -r url _; do
  info "omarchy plugin add $url --enable"
  run omarchy plugin add "$url" --enable || info "failed or already installed: $url"
done

cat <<'DONE'

==> Done. What this DELIBERATELY does not restore:

    Credentials, and it never should.
      - gh auth login          (GitHub)
      - tailscale up           (same Google account, or you get a second tailnet)
      - Syncthing device pairing + folder paths  ** type paths explicitly **
      - any API keys

    Also manual:
      - see tools.txt: clone omarchy-web-search and symlink it into ~/.local/bin
      - hardware-specific: monitors.lua may need editing for a different display
      - log out and back in for Hyprland config to take effect

DONE
