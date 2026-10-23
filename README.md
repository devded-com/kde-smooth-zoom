# Smooth Zoom for KDE Plasma

**Apple-like desktop zoom. Hold `Super` and scroll. One command to install.**

[![Release](https://img.shields.io/github/v/release/devded-com/kde-smooth-zoom?style=flat-square)](https://github.com/devded-com/kde-smooth-zoom/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)
[![KDE Plasma 6](https://img.shields.io/badge/KDE%20Plasma-6.8%2B-1d99f3?style=flat-square)](https://kde.org/plasma-desktop/)

Smooth Zoom is a small, opinionated **fork of the KDE Zoom preset**: a one-command
installer plus a Plasma applet that configures KWin's native **Zoom** effect for
the macOS-like feel:

- `Super` + scroll up/down to zoom
- the point under the pointer stays put (proportional tracking)
- smooth compositor-level animation, 1.15× per wheel step
- `Super+0` to return to 100%
- a panel applet with toggle, zoom step, tracking, modifier and reset
- native Wayland, multi-monitor, and Accessibility integration

> **This is not a custom compositor plugin.** KWin already ships the hard part:
> a native, color-managed, multi-output magnifier with accessibility hooks.
> Reimplementing that as a third-party C++ effect would mean chasing KWin's
> private ABI on every Plasma release. Smooth Zoom is a UX/installer fork of the
> native preset, not a fork of KWin itself.

Package id: `com.devded.kde-smooth-zoom`

---

## ติดตั้งด้วยคำสั่งเดียว

```bash
curl -fsSL https://raw.githubusercontent.com/devded-com/kde-smooth-zoom/main/install.sh | bash
```

สคริปต์จะติดตั้งทั้งหมดลงใน `~/.local` **ไม่ต้องใช้ sudo**:

- `~/.local/bin/smooth-zoom` — CLI
- `~/.local/share/applications/com.devded.kde-smooth-zoom.desktop` — ไอคอนเปิด/ปิด
- `~/.local/share/plasma/plasmoids/com.devded.kde-smooth-zoom/` — panel applet
- ตั้งค่า KWin เป็น `Super + scroll`, pointer-anchored, 1.15×

หลังติดตั้ง:

| การใช้งาน | ผล |
|---|---|
| `Super` + scroll ขึ้น/ลง | Zoom in / out |
| `Super` + `0` | กลับ 100% |
| คลิกไอคอน **Smooth Zoom** ใน launcher | เปิด/ปิด effect |
| คลิกขวา panel → Enter Edit Mode → Add Widgets… → **Smooth Zoom** | เพิ่ม widget บนแผง |

ถ้าไม่ต้องการ applet:

```bash
curl -fsSL https://raw.githubusercontent.com/devded-com/kde-smooth-zoom/main/install.sh | bash -s -- --no-applet
```

---

## One-click applet install

If you only want the panel applet, download the `.plasmoid` from the
[latest release](https://github.com/devded-com/kde-smooth-zoom/releases/latest/download/com.devded.kde-smooth-zoom.plasmoid)
and use **Install from File…** in the widget explorer, or:

```bash
kpackagetool6 -t Plasma/Applet -i ~/Downloads/com.devded.kde-smooth-zoom.plasmoid
```

Then add **Smooth Zoom** to a panel. The applet bundles its own helper script,
so it works without the CLI. Select **Super** under *Scroll modifier* and
**1.15×** to get the same preset.

---

## Settings

### GUI

**System Settings → Accessibility → Zoom**

- **Zoom:** Full screen
- **Pointer tracking:** Proportional (macOS-like) or Centered / Centered (Strict)
- **Zoom factor:** 1.15
- **Scroll gesture modifier keys:** Meta (press the Windows key)
- **Configure Shortcuts…** for `Zoom In`, `Zoom Out`, `Actual Size` (defaults: `Meta++`, `Meta+-`, `Meta+0`)

The same page is available from the applet's **Settings** button.

### CLI

```bash
smooth-zoom status
smooth-zoom status --json
smooth-zoom preset apple          # Super + wheel, proportional, 1.15x
smooth-zoom preset default        # Meta+Ctrl + wheel, KDE default modifier
smooth-zoom set --factor 1.10
smooth-zoom set --tracking centered
smooth-zoom set --modifier Meta+Alt
smooth-zoom reset
smooth-zoom toggle
smooth-zoom settings              # opens Accessibility → Zoom
```

Valid tracking values: `proportional`, `centered`, `centered-strict`, `push`,
`disabled`. Modifiers: `Meta`, `Meta+Control`, `Meta+Alt`, `Control+Alt`, etc.
Factor range: `1.05`–`4.00`.

### Panel applet

- master switch (on/off)
- zoom step slider (1.05×–4.00×)
- pointer tracking selector
- scroll modifier selector
- reset to 100%
- open Accessibility settings

---

## Requirements

- **KDE Plasma 6.8+** (tested on 6.8; the Accessibility scroll-modifier UI and
  the `view_actual_size` reset action used here are present there)
- KWin on **Wayland or X11**
- `kreadconfig6`, `kwriteconfig6`, `qdbus6`, `kpackagetool6`
- No root; everything is user-local

Older Plasma 6 releases may have the native Zoom effect but not the scroll
modifier setting. Check **Accessibility → Zoom → Scroll gesture modifier keys**.

---

## How it works

Smooth Zoom writes only these keys under `~/.config/kwinrc`:

```ini
[Plugins]
zoomEnabled=true

[Effect-zoom]
ZoomFactor=1.15
MouseTracking=0
PointerAxisGestureModifiers=Meta
UsePatternUpscaler=true
InitialZoom=1.0
```

Then it asks KWin to reload the effect over D-Bus:

```bash
qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.reconfigureEffect zoom
```

The applet and CLI use the same small helper. No background daemon runs, so the
idle cost is zero. `smooth-zoom reset` invokes KWin's own `view_actual_size`
action, which avoids the `InitialZoom` save race you get from unloading and
reloading the effect.

### Why not a C++ effect?

KWin's Zoom effect is built into the compositor as a static library. It handles
offscreen rendering, color descriptions, multi-output viewports, cursor tracking,
pinch gestures, and accessibility. A third-party binary effect would duplicate
thousands of lines and need a rebuild for every KWin ABI change. The native
effect already provides the smooth animation; this project packages the
Apple-like preset and makes it pleasant to install and toggle.

---

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/devded-com/kde-smooth-zoom/main/install.sh | bash -s -- --uninstall
```

This removes the CLI, launchers, icon and applet, but keeps the KWin preset.
To restore the settings that were saved before the first install:

```bash
curl -fsSL https://raw.githubusercontent.com/devded-com/kde-smooth-zoom/main/install.sh | bash -s -- --uninstall --restore
```

Local checkout:

```bash
./install.sh --uninstall
./install.sh --uninstall --restore
```

---

## Troubleshooting

**Super + scroll does nothing**

```bash
smooth-zoom status
qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.isEffectLoaded zoom
```

Check **System Settings → Accessibility → Zoom**:
- Zoom is **Full screen**
- Scroll gesture modifier keys is **Meta**
- Zoom factor is not 1.0

**Super opens Overview while zooming**

On some Plasma configurations a bare Meta shortcut is bound to Overview via
`kwinrc [ModifierOnlyShortcuts]`. In **System Settings → Shortcuts**, set
**Overview** to `Meta+W` (or remove the bare-Meta binding). Smooth Zoom only
binds the scroll axis; it does not touch the Meta key.

**Applet is missing from Add Widgets**

```bash
kpackagetool6 -t Plasma/Applet -l | grep com.devded
```

If it is not listed, reinstall:

```bash
./install.sh --no-apply
```

**Desktop icon does nothing**

```bash
~/.local/bin/smooth-zoom toggle
```

If that works but the icon does not, refresh the menu cache:

```bash
kbuildsycoca6 --noincremental
```

**I want the pointer to stay in the middle of the screen**

In **Accessibility → Zoom → Pointer tracking**, choose **Centered (Strict)**.
**Proportional** is the macOS-like behavior: the content under the pointer stays
under the pointer.

---

## Development

```bash
git clone https://github.com/devded-com/kde-smooth-zoom.git
cd kde-smooth-zoom

make check          # bash -n + qmllint
make applet         # dist/com.devded.kde-smooth-zoom.plasmoid
make install        # run the installer from the checkout
make uninstall
```

Preview the applet:

```bash
plasmoidviewer -a com.devded.kde-smooth-zoom
```

Layout:

```text
bin/smooth-zoom                 CLI + applet helper (single source)
install.sh                      one-command installer / uninstaller
desktop/                        launchers (Exec path templated by installer)
icons/                          app icon
plasma/applet/                  Plasma 6 applet package
scripts/sync-applet.sh          copies the CLI into the applet package
```

The applet keeps a copy of `bin/smooth-zoom` under `contents/code/` so the
`.plasmoid` is self-contained. `make check` verifies the copy is in sync.

---

## Credits

- The KWin team for the native **Zoom** effect and the Accessibility settings page.
- The KDE Plasma and Kirigami communities.
- [DePerto](https://github.com/dennisguim/deperto) for the GNOME counterpart.

Not affiliated with KDE e.V.

## License

MIT. See [LICENSE](LICENSE).
