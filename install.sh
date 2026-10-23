#!/usr/bin/env bash
#
# com.devded.kde-smooth-zoom — one-command installer
#
#   curl -fsSL https://raw.githubusercontent.com/devded-com/kde-smooth-zoom/main/install.sh | bash
#
# Installs:
#   - ~/.local/bin/smooth-zoom
#   - a "Smooth Zoom" launcher (one-click toggle)
#   - the "Smooth Zoom" Plasma applet
#   - the Apple-like preset: Super + wheel, pointer-anchored, 1.15x
#
# SPDX-License-Identifier: MIT
#
set -euo pipefail

APP_ID="com.devded.kde-smooth-zoom"
REPO="devded-com/kde-smooth-zoom"
REF="${SMOOTH_ZOOM_REF:-main}"
VERSION="1.0.0"

PREFIX="${PREFIX:-$HOME/.local}"
BIN_DIR="$PREFIX/bin"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
APPS_DIR="$DATA_DIR/applications"
ICON_DIR="$DATA_DIR/icons/hicolor/scalable/apps"
STATE_DIR="$DATA_DIR/$APP_ID"
BACKUP_FILE="$STATE_DIR/backup.env"

DO_APPLET=1
DO_APPLY=1
DO_UNINSTALL=0
DO_RESTORE=0
DO_ADD_PANEL=0
DRY_RUN=0
FORCE=0

TMP_DIR=""
SRC_DIR=""

say()  { printf '  %s\n' "$*"; }
step() { printf '\n==> %s\n' "$*"; }
warn() { printf '\033[33mwarning:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

run() {
    if [ "$DRY_RUN" = 1 ]; then
        printf '  + %s\n' "$*"
    else
        "$@"
    fi
}

cleanup() {
    if [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR"
    fi
}
trap cleanup EXIT

usage() {
    cat <<EOF
Smooth Zoom $VERSION installer

Usage:
  install.sh [options]

Options:
  --no-applet        Do not install the Plasma applet
  --no-apply         Install files, but do not change KWin settings
  --add-to-panel     Add the applet to the first Plasma panel
  --uninstall        Remove the applet, CLI, launchers and icon
  --restore          With --uninstall, restore the KWin settings saved at install
  --dry-run          Print what would be done
  --force            Continue even if the desktop does not look like KDE
  --ref <ref>        Git ref to download when run remotely (default: main)
  -h, --help         Show this help

One-command install:
  curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash

Uninstall:
  curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash -s -- --uninstall

After install:
  Hold Super (Meta) and scroll up/down to zoom.
  Press Super+0 to return to 100%.
EOF
}

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --no-applet)    DO_APPLET=0 ;;
            --no-apply)     DO_APPLY=0 ;;
            --add-to-panel) DO_ADD_PANEL=1 ;;
            --uninstall)    DO_UNINSTALL=1 ;;
            --restore)      DO_RESTORE=1 ;;
            --dry-run)      DRY_RUN=1 ;;
            --force)        FORCE=1 ;;
            --ref)
                [ $# -ge 2 ] || die "--ref requires a value"
                REF="$2"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            --version)
                printf '%s %s\n' "$APP_ID" "$VERSION"
                exit 0
                ;;
            *)
                die "unknown option: $1 (try --help)"
                ;;
        esac
        shift
    done
}

resolve_source() {
    local local_root
    local_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd || true)"

    if [ -f "$local_root/bin/smooth-zoom" ] && [ -f "$local_root/plasma/applet/metadata.json" ]; then
        SRC_DIR="$local_root"
        return
    fi

    command -v curl >/dev/null 2>&1 || die "curl is required for the remote installer"
    command -v tar  >/dev/null 2>&1 || die "tar is required for the remote installer"

    local url="https://github.com/$REPO/archive/$REF.tar.gz"

    step "Downloading $url"
    if ! curl -fsSL "$url" | tar -xz -C "$TMP_DIR"; then
        die "could not download or unpack $url"
    fi

    SRC_DIR="$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
    [ -n "$SRC_DIR" ] && [ -f "$SRC_DIR/bin/smooth-zoom" ] || die "unexpected archive layout"
}

check_environment() {
    case "${XDG_CURRENT_DESKTOP:-}" in
        *KDE*|*Plasma*) : ;;
        *)
            if [ "$FORCE" != 1 ]; then
                warn "this does not look like a KDE Plasma session (XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-unset})"
                warn "use --force to continue anyway"
            fi
            ;;
    esac

    local cmd
    for cmd in kreadconfig6 kwriteconfig6 qdbus6; do
        command -v "$cmd" >/dev/null 2>&1 || die "$cmd not found. KDE Plasma 6 is required."
    done

    if [ "$DO_APPLET" = 1 ]; then
        command -v kpackagetool6 >/dev/null 2>&1 || die "kpackagetool6 not found (install kpackage)"
    fi
}

read_kwin() {
    kreadconfig6 --file kwinrc --group "$1" --key "$2" 2>/dev/null || true
}

write_kwin() {
    kwriteconfig6 --file kwinrc --group "$1" --key "$2" "$3"
}

delete_kwin() {
    kwriteconfig6 --file kwinrc --group "$1" --key "$2" --delete '' 2>/dev/null || true
}

backup_config() {
    if [ "$DRY_RUN" = 1 ]; then
        say "would save current KWin settings to $BACKUP_FILE"
        return
    fi

    if [ -f "$BACKUP_FILE" ]; then
        return
    fi

    mkdir -p "$STATE_DIR"

    {
        printf 'BACKUP_ZOOM_ENABLED=%q\n' "$(read_kwin Plugins zoomEnabled)"
        printf 'BACKUP_FACTOR=%q\n' "$(read_kwin Effect-zoom ZoomFactor)"
        printf 'BACKUP_TRACKING=%q\n' "$(read_kwin Effect-zoom MouseTracking)"
        printf 'BACKUP_MODIFIER=%q\n' "$(read_kwin Effect-zoom PointerAxisGestureModifiers)"
        printf 'BACKUP_UPSCALER=%q\n' "$(read_kwin Effect-zoom UsePatternUpscaler)"
        printf 'BACKUP_INITIAL=%q\n' "$(read_kwin Effect-zoom InitialZoom)"
    } > "$BACKUP_FILE"

    chmod 600 "$BACKUP_FILE" 2>/dev/null || true
}

restore_config() {
    if [ "$DRY_RUN" = 1 ]; then
        say "would restore KWin settings from $BACKUP_FILE"
        return
    fi

    if [ ! -f "$BACKUP_FILE" ]; then
        warn "no settings backup found at $BACKUP_FILE; leaving KWin config untouched"
        return
    fi

    # shellcheck disable=SC1090
    . "$BACKUP_FILE"

    local loaded="false"
    if command -v qdbus6 >/dev/null 2>&1; then
        loaded="$(qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.isEffectLoaded zoom 2>/dev/null || true)"
    fi

    if [ "$loaded" = "true" ]; then
        qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.unloadEffect zoom >/dev/null 2>&1 || true
    fi

    if [ -n "${BACKUP_ZOOM_ENABLED:-}" ]; then
        write_kwin Plugins zoomEnabled "$BACKUP_ZOOM_ENABLED"
    else
        delete_kwin Plugins zoomEnabled
    fi

    if [ -n "${BACKUP_FACTOR:-}" ]; then
        write_kwin Effect-zoom ZoomFactor "$BACKUP_FACTOR"
    else
        delete_kwin Effect-zoom ZoomFactor
    fi

    if [ -n "${BACKUP_TRACKING:-}" ]; then
        write_kwin Effect-zoom MouseTracking "$BACKUP_TRACKING"
    else
        delete_kwin Effect-zoom MouseTracking
    fi

    if [ -n "${BACKUP_MODIFIER:-}" ]; then
        write_kwin Effect-zoom PointerAxisGestureModifiers "$BACKUP_MODIFIER"
    else
        delete_kwin Effect-zoom PointerAxisGestureModifiers
    fi

    if [ -n "${BACKUP_UPSCALER:-}" ]; then
        write_kwin Effect-zoom UsePatternUpscaler "$BACKUP_UPSCALER"
    else
        delete_kwin Effect-zoom UsePatternUpscaler
    fi

    if [ -n "${BACKUP_INITIAL:-}" ]; then
        write_kwin Effect-zoom InitialZoom "$BACKUP_INITIAL"
    else
        delete_kwin Effect-zoom InitialZoom
    fi

    if [ "$loaded" = "true" ] || [ "${BACKUP_ZOOM_ENABLED:-true}" = "true" ]; then
        qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.loadEffect zoom >/dev/null 2>&1 || true
        qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
    fi

    say "restored KWin settings from $BACKUP_FILE"
}

install_files() {
    step "Installing CLI and launchers into $PREFIX"

    run install -d "$BIN_DIR" "$APPS_DIR" "$ICON_DIR"
    run install -m 755 "$SRC_DIR/bin/smooth-zoom" "$BIN_DIR/smooth-zoom"

    local escaped_bin="${BIN_DIR//&/\\&}/smooth-zoom"
    local desktop_tmp="$TMP_DIR/$APP_ID.desktop"
    sed "s|@SMOOTH_ZOOM_BIN@|$escaped_bin|g" \
        "$SRC_DIR/desktop/$APP_ID.desktop" > "$desktop_tmp"
    run install -m 644 "$desktop_tmp" "$APPS_DIR/$APP_ID.desktop"

    run install -m 644 "$SRC_DIR/desktop/$APP_ID-settings.desktop" "$APPS_DIR/$APP_ID-settings.desktop"
    run install -m 644 "$SRC_DIR/icons/$APP_ID.svg" "$ICON_DIR/$APP_ID.svg"

    if [ "$DRY_RUN" = 0 ]; then
        if command -v update-desktop-database >/dev/null 2>&1; then
            update-desktop-database "$APPS_DIR" >/dev/null 2>&1 || true
        fi
        if command -v gtk-update-icon-cache >/dev/null 2>&1; then
            gtk-update-icon-cache -f -t "$DATA_DIR/icons/hicolor" >/dev/null 2>&1 || true
        fi
        if command -v kbuildsycoca6 >/dev/null 2>&1; then
            kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
        fi
    fi
}

install_applet() {
    if [ "$DO_APPLET" != 1 ]; then
        say "skipping Plasma applet (--no-applet)"
        return
    fi

    step "Installing the Smooth Zoom Plasma applet"

    local pkg="$TMP_DIR/pkg-$APP_ID"

    rm -rf "$pkg"
    mkdir -p "$pkg"
    cp -a "$SRC_DIR/plasma/applet/." "$pkg/"
    install -m 755 "$SRC_DIR/bin/smooth-zoom" "$pkg/contents/code/smooth-zoom"
    if [ -f "$SRC_DIR/LICENSE" ]; then
        cp "$SRC_DIR/LICENSE" "$pkg/LICENSE"
    fi

    if [ "$DRY_RUN" = 1 ]; then
        run kpackagetool6 -t Plasma/Applet -i "$pkg"
        return
    fi

    if kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -qx "$APP_ID"; then
        kpackagetool6 -t Plasma/Applet -u "$pkg"
    else
        kpackagetool6 -t Plasma/Applet -i "$pkg"
    fi

    if [ "$DO_ADD_PANEL" = 1 ]; then
        step "Adding the applet to the first panel"
        local script="var p = panels()[0]; if (p) { p.addWidget(\"$APP_ID\"); }"
        qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$script" \
            >/dev/null 2>&1 || warn "could not add the applet automatically; add it from Add Widgets"
    fi
}

apply_preset() {
    if [ "$DO_APPLY" != 1 ]; then
        say "skipping KWin preset (--no-apply)"
        return
    fi

    step "Applying the Apple-like preset (Super + wheel, 1.15x, pointer-anchored)"

    if [ "$DRY_RUN" = 1 ]; then
        run "$BIN_DIR/smooth-zoom" preset apple
        return
    fi

    if ! "$BIN_DIR/smooth-zoom" status >/dev/null 2>&1; then
        warn "KWin is not reachable right now; settings will be applied on the next login"
        return
    fi

    "$BIN_DIR/smooth-zoom" preset apple
}

uninstall() {
    step "Uninstalling $APP_ID"

    if [ "$DO_RESTORE" = 1 ]; then
        restore_config
    fi

    if command -v kpackagetool6 >/dev/null 2>&1; then
        if kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -qx "$APP_ID"; then
            run kpackagetool6 -t Plasma/Applet -r "$APP_ID"
        fi
    fi

    run rm -f "$BIN_DIR/smooth-zoom"
    run rm -f "$APPS_DIR/$APP_ID.desktop"
    run rm -f "$APPS_DIR/$APP_ID-settings.desktop"
    run rm -f "$ICON_DIR/$APP_ID.svg"

    if [ "$DO_RESTORE" != 1 ] && [ -d "$STATE_DIR" ]; then
        say "keeping the KWin preset; use --restore to put the old settings back"
    fi

    if [ "$DRY_RUN" = 0 ]; then
        rm -rf "$STATE_DIR"
        if command -v update-desktop-database >/dev/null 2>&1; then
            update-desktop-database "$APPS_DIR" >/dev/null 2>&1 || true
        fi
        if command -v kbuildsycoca6 >/dev/null 2>&1; then
            kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
        fi
    fi

    say "done"
}

print_done() {
    cat <<EOF

Smooth Zoom is ready.

  Use:       hold Super (Meta) and scroll up/down
  Reset:     Super+0
  Toggle:    "Smooth Zoom" in the application launcher
  Settings:  System Settings → Accessibility → Zoom

  Add the panel widget:
    right-click the panel → Enter Edit Mode → Add Widgets… → Smooth Zoom

  CLI:
    $BIN_DIR/smooth-zoom status
    $BIN_DIR/smooth-zoom preset apple
    $BIN_DIR/smooth-zoom set --factor 1.10 --tracking centered
EOF
}

main() {
    parse_args "$@"

    TMP_DIR="$(mktemp -d)"

    if [ "$DO_UNINSTALL" = 1 ]; then
        uninstall
        return
    fi

    if [ "$DO_RESTORE" = 1 ]; then
        restore_config
        return
    fi

    resolve_source
    check_environment

    step "Installing $APP_ID $VERSION"
    backup_config
    install_files
    install_applet
    apply_preset
    print_done
}

main "$@"
