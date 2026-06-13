#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Speeding Bullet — Install / Uninstall / Reload helper
# Usage: ./install.sh [install|uninstall|reload]
# Default action: install
# ─────────────────────────────────────────────────────────────────────────────

PLUGIN_ID="com.github.dip.speedingbullet"
WIDGET_SRC="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$HOME/.local/share/plasma/plasmoids/$PLUGIN_ID"

ACTION="${1:-install}"

case "$ACTION" in
# ── Install ───────────────────────────────────────────────────────────────
install)
    echo "📦  Installing Speeding Bullet..."
    mkdir -p "$INSTALL_DIR"
    rsync -a --delete "$WIDGET_SRC/" "$INSTALL_DIR/"
    echo "✅  Installed to: $INSTALL_DIR"
    echo ""
    echo "Next steps:"
    echo "  1. Test in a window:  plasmawindowed $PLUGIN_ID"
    echo "  2. Or restart shell:  kquitapp6 plasmashell && kstart plasmashell"
    echo "  3. Then right-click your panel → Add Widgets → search 'Speeding Bullet'"
    ;;

# ── Uninstall ─────────────────────────────────────────────────────────────
uninstall)
    echo "🗑️   Removing Speeding Bullet..."
    rm -rf "$INSTALL_DIR"
    echo "✅  Removed: $INSTALL_DIR"
    ;;

# ── Reload (hot-reload during dev) ────────────────────────────────────────
reload)
    echo "🔄  Syncing files..."
    mkdir -p "$INSTALL_DIR"
    rsync -a --delete "$WIDGET_SRC/" "$INSTALL_DIR/"
    echo ""
    echo "✅  Files synced. To see changes:"
    echo "   Test safely:  plasmawindowed $PLUGIN_ID"
    echo "   (Do NOT restart plasmashell — close & re-add the widget to panel instead)"
    ;;

*)
    echo "Usage: $0 [install|uninstall|reload]"
    exit 1
    ;;
esac
