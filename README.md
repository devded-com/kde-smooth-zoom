# Smooth Zoom for KDE Plasma

**ซูมเดสก์ท็อปแบบ Apple-like — กด `Super` ค้างแล้วเลื่อนล้อ**

[![Release](https://img.shields.io/github/v/release/devded-com/kde-smooth-zoom?style=flat-square)](https://github.com/devded-com/kde-smooth-zoom/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)

เป็น Plasma applet + installer สำหรับเปิดใช้ **Zoom effect ของ KWin**
ให้ซูมตามจุดใต้เมาส์ ลื่น ๆ และกด `Super+0` กลับ 100%

ติดตั้งง่าย ไม่ต้อง compile ไม่ต้อง sudo

---

## ติดตั้ง 1 คำสั่ง

```bash
curl -fsSL https://raw.githubusercontent.com/devded-com/kde-smooth-zoom/main/install.sh | bash
```

ติดตั้งให้ทั้งหมด:

- CLI `smooth-zoom`
- Panel applet **Smooth Zoom**
- ไอคอน **Smooth Zoom** ใน launcher (คลิกเปิด/ปิด)
- ตั้งค่า `Super + scroll`, 1.15×, zoom ตามเมาส์ ให้เลย

ถ้าอยากให้เพิ่ม widget ลง panel อัตโนมัติ:

```bash
curl -fsSL https://raw.githubusercontent.com/devded-com/kde-smooth-zoom/main/install.sh | bash -s -- --add-to-panel
```

ถ้าไม่เอา applet:

```bash
curl -fsSL https://raw.githubusercontent.com/devded-com/kde-smooth-zoom/main/install.sh | bash -s -- --no-applet
```

---

## ใช้งาน

| ทำอะไร | ได้อะไร |
|---|---|
| `Super` + เลื่อนล้อขึ้น | ซูมเข้า |
| `Super` + เลื่อนล้อลง | ซูมออก |
| `Super` + `0` | กลับ 100% |
| คลิกไอคอน **Smooth Zoom** | เปิด/ปิด effect |

เพิ่ม widget: คลิกขวา panel → **Enter Edit Mode** → **Add Widgets…** → **Smooth Zoom**

---

## ติดตั้งเฉพาะ applet (one-click)

ดาวน์โหลดไฟล์นี้:

[com.devded.kde-smooth-zoom.plasmoid](https://github.com/devded-com/kde-smooth-zoom/releases/latest/download/com.devded.kde-smooth-zoom.plasmoid)

แล้วไปที่ **Add Widgets… → Install from File…** หรือใช้คำสั่ง:

```bash
kpackagetool6 -t Plasma/Applet -i ~/Downloads/com.devded.kde-smooth-zoom.plasmoid
```

จากนั้นเลือก **Super** ในช่อง Scroll modifier และตั้ง Zoom step เป็น **1.15×**

---

## ตั้งค่า

ใน applet มี:

- เปิด/ปิด effect
- Zoom step (1.05×–4.00×)
- Pointer tracking
- Scroll modifier
- Reset 100%
- ปุ่มเปิด Settings

หรือตั้งละเอียดที่:

**System Settings → Accessibility → Zoom**

- **Zoom:** Full screen
- **Pointer tracking:** Proportional (แบบ macOS) หรือ Centered
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

## ต้องมีอะไร

- KDE Plasma **6.8+**
- Wayland หรือ X11
- ไม่ต้อง root

---

## ถอนการติดตั้ง

```bash
curl -fsSL https://raw.githubusercontent.com/devded-com/kde-smooth-zoom/main/install.sh | bash -s -- --uninstall
```

คืนค่าเดิมของ KWin ด้วย:

```bash
curl -fsSL https://raw.githubusercontent.com/devded-com/kde-smooth-zoom/main/install.sh | bash -s -- --uninstall --restore
```

---

## ถ้าใช้งานไม่ได้

**`Super + scroll` ไม่ทำงาน**

```bash
smooth-zoom status
```

แล้วเช็ก **Accessibility → Zoom** ว่าเปิด Full screen, modifier เป็น Meta และ zoom factor ไม่ใช่ 1.0

**อยากให้ pointer อยู่กลางจอ**

เลือก **Pointer tracking → Centered (Strict)**
ส่วน **Proportional** คือแบบ macOS: จุดใต้เมาส์อยู่กับที่

**หา applet ไม่เจอ**

```bash
kpackagetool6 -t Plasma/Applet -l | grep com.devded
```

ถ้าไม่เจอ ให้ติดตั้งใหม่:

```bash
curl -fsSL https://raw.githubusercontent.com/devded-com/kde-smooth-zoom/main/install.sh | bash -s -- --no-apply
```

---

## หมายเหตุ

โปรเจกต์นี้ใช้ **Zoom effect ที่มีอยู่ใน KWin** แล้วทำตัวติดตั้งกับ applet
ไม่ได้เขียน compositor effect ใหม่ จึงเสถียรและตาม Plasma update ได้ง่าย

## License

MIT — ดู [LICENSE](LICENSE)
