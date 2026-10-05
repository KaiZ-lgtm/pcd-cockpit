# PCD Cockpit — Connect IQ Store listing (draft)

Text for the store page, plus the submission steps.

**Submitted 2026-10-05** as version 0.1.0 (developer name `PCDCockpit`, category Digital, free, English + 简体中文, source link to GitHub): https://apps.garmin.com/apps/dfd968c1-9d33-4d44-a191-c6de0fa0d4e6 — pending review. Updates go through "Upload New Version" on that page, signed with the same `developer_key`.

The listing avoids "F-35" and other aircraft or maker names: the App Review Guidelines ask developers to be careful with other companies' brand names, and "F-35" is a Lockheed Martin trademark. "Fighter-jet HUD / cockpit display style" says the same thing. The code comments and internal docs are not affected.

## Submission steps

1. Sign in to [developer.garmin.com](https://developer.garmin.com/connect-iq/submit-an-app/) with a **global** (not China-region) Garmin account and accept the developer agreement.
2. `.\build.ps1 -Export` → `bin\PcdCockpit.iq` (all 8 products in the manifest, requirements §1; release build, signed with `developer_key` in the project folder). Keep the key: every update must be signed with it.
3. Submit an App → upload the `.iq` → fill in the text below, the screenshots and the icon; category Watch Face; free.
4. Review: usually within 72 hours. The Connect IQ team emails the reasons if it is rejected.
5. China: once approved, the app is copied to apps.garmin.cn under the same app id (no separate upload; the copy can lag behind). Check `https://apps.garmin.cn/zh-CN/apps/<app id>` after a few days.

Checks for the current layout are done: tap targets on the real watch (2026-09-29, gauge included), and the 24-hour burn-in simulation on the fēnix 8 (1.5% peak, 2026-09-28; always-on has not changed since).

## Assets (`store/`)

Store limits (Garmin brand guidelines and the store's upload checks): icon 500 × 500 sRGB, max 300 KB, no black or transparent background, no text, at least 10 px padding; screenshots max 150 KB; hero 1440 × 720; on-device icon 128 × 128.

| File | Size | Content |
|---|---|---|
| `icon-500.png` | 500 × 500, 52 KB | Store icon: the fēnix face on dark navy #1C3350 (23 px padding) |
| `icon-128.png` | 128 × 128, 8 KB | On-device store icon (AMOLED), optional |
| `hero.png` | 1440 × 720, 132 KB | Hero: fēnix active, fēnix always-on, Venu 3S, on the same navy; no text, so one image serves every language |
| `screenshot-1-fenix8.png` | 500 × 500, 47 KB | fēnix 8, active, stress gauge at 28 |
| `screenshot-2-always-on.png` | 500 × 500, 17 KB | fēnix 8, always-on |
| `screenshot-3-bingo.png` | 500 × 500, 47 KB | fēnix 8, BINGO warning |
| `screenshot-4-venu3s.png` | 500 × 500, 36 KB | Venu 3S, active (no gauge) |

They are real simulator frames (demo build with fixed data: 10:42, light rain, broken cloud, 15 kt NE wind, HR 128 in zone 2, 1,250 m, BB 74, SpO2 97%, 95/150 intensity minutes, sunset 18:56), with the round display masked; nothing is painted in. `.\tools\storeassets.ps1` remakes them after a layout change (captures into `store\raw\`, then composes; about 5 minutes, it takes over the simulator and rebuilds the release `.prg` files at the end).

Version for the first upload: 0.1.0.

Privacy: the listing text below states what data is used. If the store asks for a privacy policy link, a short page with the same text is enough, since nothing leaves the watch.

## English

**Name:** PCD Cockpit

**Short description:** Fighter-jet cockpit watch face: HUD heart-rate and altitude tapes, wind-barb weather station model, BINGO warning.

**Description:**

A watch face built like a fighter-jet cockpit display. Read your body and the weather the way a pilot reads the instruments.

HUD TAPES
- Heart rate at 9 o'clock, altitude at 3 o'clock: vertical tapes that scroll behind a fixed reading box, like the airspeed and altitude scales on a head-up display.
- Heart-rate tape: a tick every 5 bpm, with a colour band marking your HR zone boundaries. The box takes the colour of your current zone, so you see your zone at a glance.
- Altitude tape: a tick every 20 m; the box reads in tens of metres (125 = 1,250 m).

WEATHER STATION MODEL
- The top of the face is a station model, the symbol pilots and forecasters read on surface weather charts.
- Sky-cover circle from clear to overcast, temperature and dew point, sea-level pressure in hPa, and present-weather symbols (rain, snow, showers, thunderstorm, fog and more).
- Wind barb: the staff points to where the wind blows from; a half barb is 5 knots, a full barb 10 knots, a pennant 50 knots. Calm wind draws a ring around the circle.

BINGO
- "Bingo fuel" is the pilot's call for just enough fuel to get home. When the battery reaches 10%, the bottom row turns into a red-striped BINGO warning box: time to charge.
- On the Venu 3S, a STRESS warning box appears the same way when stress is high.

ALSO ON THE FACE
- Large 24-hour time, weekday, date and the Chinese lunar date.
- Data windows: Body Battery, SpO2, weekly intensity minutes and the next sunrise or sunset.
- Segmented stress gauge in cockpit style on fēnix-size watches, turning amber and red as stress rises.
- Tap any element to open the matching page on the watch.
- Always-on mode shows only the time, date and lunar date in thin strokes, shifted every minute to protect the AMOLED screen.

Units are fixed: °C, hPa, knots and metres.

Supported: fēnix 8 and fēnix 8 Pro 47 / 51 mm (also tactix 8 and quatix 8), epix Pro (Gen 2) 51 mm, Forerunner 965 / 970, Venu 3, Venu 3S, Venu 4 45 mm. AMOLED only.

**Permissions:** location is used only to work out sunrise and sunset; sensor history and your user profile (heart-rate zones) are used only to draw the face. Nothing is stored off the watch or sent anywhere.

## 中文

**名称：** PCD Cockpit（中文副名可选：座舱表盘）

**简短介绍：** 战斗机座舱表盘：HUD 心率带和高度带、带风羽的航空天气站点模型、BINGO 警告。

**详细介绍：**

按战斗机座舱显示器设计的表盘，像飞行员看仪表一样看自己的身体状态和天气。

HUD 刻度带
- 9 点方向是心率带，3 点方向是高度带：竖直的刻度带在固定读数框后面上下滚动，就像平视显示器上的空速带和高度带。
- 心率带每 5 bpm 一个刻度，旁边的色带标出心率区间的分界；读数框的颜色就是你当前所在的区间，一眼就能看出。
- 高度带每 20 米一个刻度；读数框以十米为单位（125 = 1250 米）。

航空天气站点模型
- 表盘顶部是"站点模型"，就是飞行员和预报员在地面天气图上看的那种符号。
- 云量圆（从晴到阴天）、气温和露点、海平面气压（百帕），以及天气现象符号（雨、雪、阵雨、雷暴、雾等）。
- 风羽：杆指向风吹来的方向；短羽 5 节，长羽 10 节，三角旗 50 节。无风时在云量圆外多画一圈。

BINGO
- "Bingo fuel"是飞行员的术语，意思是剩下的油刚好够返航。电量降到 10% 时，底部一行变成红色斜纹的 BINGO 警告框：该充电了。
- Venu 3S 上，压力高时也会以同样的方式显示 STRESS 警告框。

表盘上还有
- 大号 24 小时制时间、星期、日期和农历。
- 数据窗：身体电量、血氧、本周强度活动分钟，以及下一次日出或日落时间。
- fēnix 尺寸的表上有座舱风格的分段压力条，压力升高时变成琥珀色和红色。
- 点击表盘上的任何元素，都能打开手表上对应的页面。
- 息屏时只显示细线条的时间、日期和农历，并且每分钟平移一次，防止 AMOLED 烧屏。

单位固定：摄氏度、百帕、节、米。

支持：fēnix 8 和 fēnix 8 Pro 47 / 51 mm（含 tactix 8、quatix 8）、epix Pro（第二代）51 mm、Forerunner 965 / 970、Venu 3、Venu 3S、Venu 4 45 mm，仅限 AMOLED 屏幕。

**权限说明：** 位置信息只用来计算日出日落；传感器历史和用户资料（心率区间）只用来绘制表盘。所有数据只在手表上使用，不会上传或保存到别处。
