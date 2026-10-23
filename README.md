# Smooth Zoom for KDE Plasma

**Apple-like desktop zoom. Hold `Super` and scroll.**

[![Release](https://img.shields.io/github/v/release/devded-com/kde-smooth-zoom?style=flat-square)](https://github.com/devded-com/kde-smooth-zoom/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)

Smooth Zoom is a Plasma applet and one-command installer for KWin's built-in
**Zoom** effect. It zooms into the point under your mouse, feels smooth, and
resets with `Super+0`.

No compiling. No root. No background daemon.

---

## Install (one command)

```bash
curl -fsSL https://raw.githubusercontent.com/devded-com/kde-smooth-zoom/main/install.sh | bash
```

This installs:

- the `smooth-zoom` CLI
- the **Smooth Zoom** panel applet
- a **Smooth Zoom** launcher (click to toggle)
- the Apple-like preset: `Super + scroll`, 1.15×, pointer-anchored

Want the widget added to your panel automatically?

```bash
curl -fsSL https://raw.githubusercontent.com/devded-com/kde-smooth-zoom/main/install.sh | bash -s -- --add-to-panel
```

Install without the applet:

```bash
curl -fsSL https://raw.githubusercontent.com/devded-com/kde-smooth-zoom/main/install.sh | bash -s -- --no-applet
```

---

## Use

| Action | Result |
|---|---|
| `Super` + scroll up | Zoom in |
| `Super` + scroll down | Zoom out |
| `Super` + `0` | Back to 100% |
| Click **Smooth Zoom** in the launcher | Toggle the effect |

Add the widget: right-click the panel → **Enter Edit Mode** →
**Add Widgets…** → **Smooth Zoom**

---

## Install only the applet (one click)

Download:

[com.devded.kde-smooth-zoom.plasmoid](https://github.com/devded-com/kde-smooth-zoom/releases/latest/download/com.devded.kde-smooth-zoom.plasmoid)

Then use **Add Widgets… → Install from File…**, or:

```bash
kpackagetool6 -t Plasma/Applet -i ~/Downloads/com.devded.kde-smooth-zoom.plasmoid
```

After adding it, choose **Super** under *Scroll modifier* and set the zoom step
to **1.15×**.

---

## Settings

The applet includes:

- on/off switch
- zoom step (1.05×–4.00×)
- pointer tracking
- scroll modifier
- reset to 100%
- button to open the system settings

For the full settings page:

**System Settings → Accessibility → Zoom**

- **Zoom:** Full screen
- **Pointer tracking:** Proportional (macOS-like) or Centered
- **Zoom factor:** 1.15
- **Scroll gesture modifier keys:** Meta

### CLI

```bash
smooth-zoom status
smooth-zoom preset apple
smooth-zoom set --factor 1.10 --tracking centered
smooth-zoom reset
smooth-zoom toggle
```

---

## Requirements

- KDE Plasma **6.8+**
- Wayland or X11
- No root required

---

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/devded-com/kde-smooth-zoom/main/install.sh | bash -s -- --uninstall
```

Restore the KWin settings saved before the first install:

```bash
curl -fsSL https://raw.githubusercontent.com/devded-com/kde-smooth-zoom/main/install.sh | bash -s -- --uninstall --restore
```

---

## Troubleshooting

**`Super + scroll` does nothing**

```bash
smooth-zoom status
```

Then check **Accessibility → Zoom**: the effect is enabled, **Full screen** is
selected, the modifier is **Meta**, and the zoom factor is not 1.0.

**I want the pointer to stay in the center**

Choose **Pointer tracking → Centered (Strict)**.
**Proportional** is the macOS-like behavior: the content under the pointer stays
under the pointer.

**The applet is missing from Add Widgets**

```bash
kpackagetool6 -t Plasma/Applet -l | grep com.devded
```

If it is not listed, reinstall:

```bash
curl -fsSL https://raw.githubusercontent.com/devded-com/kde-smooth-zoom/main/install.sh | bash -s -- --no-apply
```

---

## Good to know

Smooth Zoom uses the **native Zoom effect already included in KWin**. It does not
ship a custom compositor effect, so it stays stable across Plasma updates.

## License

MIT — see [LICENSE](LICENSE).
