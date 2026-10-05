# PCD Cockpit — Connect IQ Store listing (draft)

Draft text for the store page, plus the submission steps. Nothing here has been submitted yet.

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

**Short description:** Fighter-jet cockpit style watch face: HR and altitude tapes, aviation weather, lunar date.

**Description:**

A watch face in the style of a fighter-jet cockpit display and HUD.

- Heart-rate and altitude tapes at 9 and 3 o'clock, scrolling like a HUD speed and altitude scale. The heart-rate box and tape take the colour of your current HR zone.
- Aviation weather "station model" at the top: sky cover circle, temperature, dew point, sea-level pressure (hPa), wind barb and present-weather symbols as on weather charts.
- Large 24-hour time, weekday and date, and the Chinese lunar date.
- Data windows: Body Battery, SpO2 and weekly intensity minutes, plus the next sunset or sunrise.
- A segmented stress gauge above the bottom row (fēnix-size watches), turning amber and red as stress rises; BINGO warning when the battery is at 10% or less (on the Venu 3S, a STRESS warning replaces the gauge).
- Tap an element to open the matching page on the watch (heart rate, altitude, weather, Body Battery, SpO2, intensity minutes, sunrise/sunset, battery, stress).
- Always-on mode shows only the time, date and lunar date with thin strokes, and shifts every minute to protect the AMOLED screen.

Units are fixed: °C, hPa and metres (altitude shown in tens of metres).

Supported: fēnix 8 and fēnix 8 Pro 47 / 51 mm (also tactix 8 and quatix 8), epix Pro (Gen 2) 51 mm, Forerunner 965 / 970, Venu 3, Venu 3S, Venu 4 45 mm. AMOLED only.

**Permissions:** location is used only to work out sunrise and sunset; sensor history and your user profile (heart-rate zones) are used only to draw the face. Nothing is stored off the watch or sent anywhere.

## 中文

**名称：** PCD Cockpit（中文副名可选：座舱表盘）

**简短介绍：** 战斗机座舱风格表盘：心率带、高度带、航空天气图、农历。

**详细介绍：**

仿照战斗机座舱多功能显示器和平视显示器（HUD）设计的表盘。

- 9 点和 3 点方向是心率带和高度带，像 HUD 上的速度带、高度带一样上下滚动。心率框和色带会显示你当前所在的心率区间颜色。
- 顶部是航空天气图的"站点模型"：云量圆、气温、露点、海平面气压（hPa）、风羽和天气符号。
- 大号 24 小时制时间，星期和日期，以及农历。
- 数据窗：身体电量、血氧、本周强度活动分钟，以及下一次日落或日出时间。
- 底部上方有分段式压力条（fēnix 尺寸的表），压力升高时变成琥珀色和红色；电量 ≤ 10% 时显示 BINGO 警告（Venu 3S 没有压力条，改为显示 STRESS 警告）。
- 点击表盘上的元素可打开手表对应的页面（心率、高度计、天气、身体电量、血氧、强度活动分钟、日出日落、电量、压力）。
- 息屏时只显示细线条的时间、日期和农历，并且每分钟平移一次，防止 AMOLED 烧屏。

单位固定：摄氏度、百帕、米（高度以十米为单位显示）。

支持：fēnix 8 和 fēnix 8 Pro 47 / 51 mm（含 tactix 8、quatix 8）、epix Pro（第二代）51 mm、Forerunner 965 / 970、Venu 3、Venu 3S、Venu 4 45 mm，仅限 AMOLED 屏幕。

**权限说明：** 位置信息只用来计算日出日落；传感器历史和用户资料（心率区间）只用来绘制表盘。所有数据只在手表上使用，不会上传或保存到别处。
