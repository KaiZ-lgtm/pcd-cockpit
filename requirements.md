# PCD Cockpit — F-35 inspired watch face: requirements

Status: approved 2026-09-26; kept in step with the build (last revised 2026-09-29: larger station model, stress gauge above the bottom row on the 454 px layout; 2026-09-28: tapes at 3 / 9 o'clock, two-column date block, slots). The first design mockup (not in the repository) was the reference for the weather symbols and the original glyph table; the layout has moved on from it.

## 1. Targets and platform

| | fēnix 8 47mm (AMOLED) | Venu 3S |
|---|---|---|
| Connect IQ product id | `fenix847mm` | `venu3s` |
| Screen | 454 × 454 round AMOLED | 390 × 390 round AMOLED |
| API level | 6.0 | 5.2 |

The layout is designed on these two. Other 454 px round AMOLED watches use the fēnix layout and fonts unchanged (`monkey.jungle` adds `resources-fenix847mm` to their resource path); their SDK profiles have the same screen and watch-face memory (128 kB), and they were checked in the simulator only (2026-09-28):

| Product id | Watches | API level |
|---|---|---|
| `fenix847mm` | also fēnix 8 51mm, tactix 8 / quatix 8 47 and 51 mm | 6.0 |
| `fenix8pro47mm` | fēnix 8 Pro 47 / 51 mm and MicroLED, quatix 8 Pro | 6.0 |
| `fr970` | Forerunner 970 | 6.0 |
| `venu445mm` | Venu 4 45mm, D2 Air X15 | 6.0 |
| `fr965` | Forerunner 965 | 5.2 |
| `venu3` | Venu 3 | 5.2 |
| `epix2pro51mm` | epix Pro (Gen 2) 51mm, D2 Mach 1 Pro, tactix 7 AMOLED | 5.2 |

Not supported: the fēnix 7 family (MIP screens, 240–280 px; would need its own colours and layout) and 416 px AMOLED watches such as the epix (Gen 2) and epix Pro 47mm (would need a third layout).

- AMOLED only (no Solar/MIP build). Min API 5.1 (needed for weather cloud cover, dew point, pressure, visibility).
- Both screens are ~12.8 px/mm, so a given pixel size is the same physical size on both.
- 24-hour time, no seconds. Phone settings (store installs): font, units, what each slot shows and the progress bars ([SETTINGS.md](SETTINGS.md)); the other options below are compile-time constants.
- Units: a phone setting, not the watch's unit setting. Metric (default): temperature °C, pressure hPa, altitude and climb m, distance and visibility km. Imperial: °F, inHg (`29.92`), altitude tape in hundreds of feet (`100` over `FT`), climb ft, distance mi, visibility SM. Wind is in knots either way (barbs only).

## 2. Visual style

- Inspiration: F-35 panoramic cockpit display (PCD) + HUD/HMD symbology, per the reference screenshot.
- Background: true black. Thin gray (#5A5A5A) divider lines instead of boxed windows.
- Palette: HUD green #33FF66 (time, tapes) · white #FFFFFF (values, date, weather) · cyan #33E0FF (labels, underlined headers with ">" soft-key arrows) · amber #FFC21A (caution) · red #FF3030 (warning) · gray #8A8A8A (units) · light gray #A0A0A0 (wind barb).
- Font: all Latin letters, digits and symbols drawn as single-line vector strokes (custom glyph set on an 8 × 12 grid, monospaced), shaped after the F-35 PCD font: slashed zero (letter O stays plain), 3 / 8 / S / B with a smaller top bowl, shallow M middle, W with near-vertical legs and a low middle peak, A with a flat top and straight legs, condensed to 0.85 of the mockup width. Three corner styles are built in, chosen by `FONT_STYLE` (later a setting): D = 45° chamfers, G = small rounded corners (default), E = large rounded corners. Baked from these vector paths into anti-aliased glyph atlases (round caps and joins, whole-pixel stroke widths, stems snapped to the pixel grid). The Chinese lunar date uses the same single-line vector stroke style (HUD symbology), 17 custom glyphs on a 12 × 12 grid: 一二三四五六七八九十正冬腊月初廿闰.
- Text sizes: every number is at least 16 px tall (~1.25 mm) and main values 18 px or more; the only smaller text is the tape labels (HR / ALT, 11 px) and `10M` / `100` over `FT` (11 / 10 px). The tapes have no scale numbers.

## 3. Layout (top to bottom)

Coordinates are pixels relative to the screen centre, x right and y down; where two values are given they are fēnix / Venu. All of them live in `source/Layout.mc`.

1. **Station model (top cap).**
   - Sky-cover circle centred at x=0 (fēnix y −174, r 13; Venu y −152, r 11).
   - A clear zone of radius `clear` (46 / 38) is reserved around the circle for the wind barb (staff 25 / 20 px beyond the circle).
   - Temperature (upper-left) and dew point (lower-left), right-aligned at x = −clear. The dew point baseline sits 10 px above the weekday (y −144 / −126).
   - Present-weather symbol 22 / 18 px left of the temperatures and 10 / 8 px below the circle centre (level with the circle, a tall symbol such as the thunderstorm clipped on the bezel), scaled 1.6× on the fēnix and 1.35× on the Venu with 2.3 px strokes.
   - Pressure in whole hPa (`1013`, `998`, as in METAR's `Q1013`; not the station model's coded `132`, which is harder to read) upper-right at x = +clear. Imperial: inHg with two decimals (`29.92`, as the US altimeter setting `A2992`).
   - Numbers are 25 px on the fēnix and 21 px on the Venu.
   - Checked in the simulator at the widest cases (`-12` / `-18`, thunderstorm and freezing-rain symbols, 65 kt barbs up, left, right and down-left, 4-digit pressure): nothing touches the bezel or the date block.
   - Wind barb in knots from `windBearing` + `windSpeed` (m/s → kt): half barb 5 kt, full 10 kt, pennant 50 kt. Calm (< 3 kt) is an outer ring, also when no bearing is given. No wind speed (or a wind ≥ 3 kt with no bearing): nothing is drawn.
2. **Date block** — two columns above the time, centred on x = ∓74 (fēnix) / ∓62 (Venu), so the centre stays free for a wind barb pointing down. Line baselines y −104 / −62 (fēnix), −86 / −51 (Venu); the `MM/DD` bottom clears the time top by 16 / 15 px.
   - Left: weekday (`MON`) over `MM/DD` (`09/28`), white, 30 / 25 px with 3 px strokes.
   - Right: lunar month (e.g. 八月, 闰六月) over lunar day (e.g. 十八, 初一), magenta #E040E0, 36 / 29 px with 4 / 3 px strokes, 8 px between the lines. The CJK glyphs sit 2 px below the Latin baseline (lunar day at y −60 / −49), leaving 14 / 13 px to the time.
   - The right column is a slot (see 5): it shows the lunar date by default, or any data field as a wide cell with the value on the `MM/DD` baseline.
3. **Middle row: time between the two tapes**, all centred on y = +1.
   - Time: `HHMM`, 24-hour, no colon ("23:41" would not fit between the tape boxes), stroke font, green. fēnix h 94 with 6 px strokes, Venu h 74 with 5 px; the digits span about ±145 / ±114 px, leaving ~10 px to the tape boxes.
   - Digits are monospaced and every glyph fills its full cell (the `1` has a full-width base), so all four digits are the same width with equal gaps, centred on x = 0.
4. **Tapes at 9 (HR) and 3 (ALT) o'clock** — straight vertical tapes, slim, with no scale numbers.
   - Value box against the bezel, centred on the middle row: outer edge x ±216 (fēnix) / ±184 (Venu); fēnix 60 × 50 with 20 px value, Venu 58 × 46 with 18 px value (room for 3 digits), 3 px border (1 px inside the box edge, 2 px outside); the value stroke is 1 px wider than the mockup default (3 px). `10M` sits 5 px above the box top. The label (HR / ALT, 11 px) is inside the box above the value. No pointer: the box centre marks the current value.
   - Spine: a vertical 2 px line at x ±184 / ±156 that runs behind the box (the box's black fill covers the middle) up and down to the bezel, where the round display cuts it off (visible about ±133 / ±117 px from the centre), past the date block and beside the data row. Ticks point outward from the spine towards the bezel (fēnix major 12 px, minor 7 px; Venu 10 / 6), one every 22 / 19 px on the heart-rate tape and every 15 / 13 px on the altitude tape; ticks and zone bands are snapped to whole pixels (major ticks 3 px thick, minor 2 px), so every tick of a kind has the same weight and the tape scrolls in 1 px steps.
   - **Left: heart rate.** Scrolling, about ±30 bpm visible (4.4 / 3.8 px per bpm), tick every 5 bpm (major every 10). Zone colour band (4 px) along the inner side of the spine, where zones are in view: Z1 gray, Z2 cyan, Z3 green, Z4 amber, Z5 red. The box outline and value turn to the current zone colour. Zones come from `UserProfile.getHeartRateZones()`.
   - **Right: altitude in tens of metres.** 1,250 m shows as `125`, with a small gray `10M` (11/10 px) directly above the ALT box, starting 1 px inside the box's inner edge (clear of the spine and the time). About ±180 m visible, tick every 20 m (major every 100 m). Clamp at `999`. Imperial: hundreds of feet (4,100 ft shows as `41`, like a flight level) with `100` over `FT` above the box (one line would cross the spine), tick every 100 ft (major every 500 ft), the same px per tick (about ±900 ft visible).
5. **Slots** — every place that shows one data field (`Slot` in `Slots.mc`, listed per device in `Layout.slots`; the field definitions are in `Fields.mc`). Drawing and tap targets both come from this one list. Four styles:

   | Style | Look | Width (fēnix / Venu) | Used by |
   |---|---|---|---|
   | Narrow cell | header over value, centred | 100 / 80 px | data row: BB, SPO2 |
   | Wide cell | header over value, centred | 144 / 132 px | data row: ACT MIN; date block right column |
   | Row | header beside the value, tops aligned | — | bottom row: sun event |
   | Gauge | label, 10-segment bar, value | 199 px / — | above the bottom row: stress by default, a setting (454 px layout only) |

   - Header: cyan, underlined, ending in the soft-key arrow `>` (16 px). Value: white (34 / 29 px), with an optional gray unit (16 px). No value: gray `--`. In a cell, a value plus unit too wide for the cell drops the unit (`%`, `/goal`).
   - Fields: `BB` (Body Battery), `SPO2` (%), `ACT MIN` (weekly intensity minutes `/goal` from `activeMinutesWeekGoal`), `SS` / `SR` (next sunset during the day, sunrise after sunset), `STRESS` (0–100), `BAT` (watch battery %). The lunar date is a special field for the date block's right column only. A gauge can show any field with a 0–100 scale (`Field.gauge`: STRESS, BB, BAT, SPO2 now); others show `--`.
   - Which field each slot shows is a phone setting (defaults below; fields and slot rules in [SETTINGS.md](SETTINGS.md) §3–4). Values too wide for a cell drop the unit, then use a shorter form; long headers have a short form for the narrow cells.
   - Always-on: slots are hidden, except the lunar date (dimmed).

   **Data row** (divider line above at y = pY − 6, vertical dividers between the cells): narrow · narrow · wide = `BB>` · `SPO2>` · `ACT MIN>`, spanning ±172 / ±146 px from y +72 / +60. Header baseline 21 / 19 px and value baseline 70 / 62 px below the row top (~10 px between the header underline and the value). fēnix fits BB `100`, SPO2 `100%` and `150/150`; Venu fits `100` and `150/150`, and SPO2 `100` drops the `%`.
   - Optional thin progress bar under a data row value, only for fields with a goal (ACT MIN, STEPS, FLOORS). Off by default (phone setting `showBars`); the layout keeps ~17 px free above the bottom row for it.

   **Date block right column**: see 2 (wide cell, value on the `MM/DD` baseline, header 14 px above the value top).

   **Gauge** (454 px layout only, `Layout.GAUGE`, on by default; field: phone setting `gaugeField` ([SETTINGS.md](SETTINGS.md) §3), stress by default). Styled after the F-35 PCD's segmented engine and fuel gauges, between the data row and the bottom row:
   - Bar: 10 segments of 19 px with 1 px gaps (199 px, centred), 6 px tall, bottom at y +170. Each segment is 10 points; the last one fills in proportion (62 = 6 full segments and 20 % of the 7th). Filled parts are in the status colour; empty segments are dim #3A3A3A outlines. A 1 px gray end mark at each end, 3 px taller than the bar. No quarter ticks.
   - Label left of the bar (cyan; `STR`, `BB`, `BAT`, `O2`), value right of it (status colour), both in the same 14 px font (the tape value glyphs), 6 px from the bar and top-aligned with it. Labels are 3 characters at most: a longer one would reach the bezel.
   - Status colours: STRESS ≤ 25 cyan, 26–50 green, 51–75 amber, ≥ 76 red (Garmin's rest / low / medium / high); BB red ≤ 10, amber ≤ 25; BAT red ≤ 10 (BINGO), amber ≤ 20; otherwise green.
   - The gauge is the only stress warning: the STRESS warning boxes were removed (0.2.0). BINGO still replaces the bottom row.

6. **Bottom row** — a row-style slot, the sun event by default: `SS> 1856` / `SR> 0703`, centred, value baseline y +212 on the 454 px layout with the gauge (as far down as it goes: the value's lower right corner is ~3 px inside the bezel; +203 without the gauge) / +177 on the Venu.
   - BINGO (battery ≤ 10%, red stripes) replaces it; otherwise it shows the slot's field in row style, no frame.

     BINGO style: a square-cornered box (fēnix 132 × 30 at y +177 with the gauge, +168 without; Venu 128 × 28 at y +150) with a 2 px red border, filled with 45° `/` hazard stripes in dimmed red #B02222 (stripe 6 px wide every 16 px on fēnix, 5.2 px every 14 px on Venu), clipped at the box edges. White text at the tape-value size (20 / 18 px) with a 1 px black halo so letters stay whole across the stripes.
7. **Missing data** — shown as `--` in gray.
   - Weather missing: an empty circle with no numbers.
   - Weather observation older than 3 h: the whole station model is dimmed.

## 4. Always-on (low power) mode

- Shows only the date (2 px strokes, gray #A8A8A8), the lunar date (same glyphs as active: 4 / 3 px, dimmed magenta #8A2A8A) and the time (2.5 px strokes, dim green #28C050), at exactly their active-mode positions and sizes. Widths and colours were raised from 1.6 / 1.2 px and darker colours after the first 24-hour simulator test showed only 0.86% peak luminance; the next test gave 1.41% (fēnix) / 1.6% (Venu), no burn-in (2026-09-27, previous layout). With the 2026-09-28 layout a single always-on frame lights 4.2% of the fēnix screen (was 4.8%), and the 24-hour test on the fēnix gave 1.5% peak, no burn-in. The station model and the gauge are not drawn in always-on, so the 2026-09-29 changes do not affect it.
- No slots (except the lunar date) and no warnings.
- Burn-in compliance (Garmin: ≤ 10% of pixels lit, no pixel lit > 3 min): the whole AOD layer shifts 3–5 px in x and y every minute (x period 7 min, y period 5 min). Verify with the simulator heat map.
- Update once per minute; weather, tapes and windows are not drawn.

## 5. Data sources (Connect IQ)

| Item | API |
|---|---|
| Heart rate | `Activity.getActivityInfo().currentHeartRate` (fallback: `ActivityMonitor.getHeartRateHistory`) |
| HR zones | `UserProfile.getHeartRateZones(getCurrentSport())` |
| Altitude | `Activity.Info.altitude` (m); always metres |
| Body Battery, SpO2, stress | `SensorHistory` (bodyBattery, oxygenSaturation, stress) / `ActivityMonitor.Info.stressScore` (API 5.0) |
| Active minutes | `ActivityMonitor.Info.activeMinutesWeek.total`, `activeMinutesWeekGoal` |
| Battery | `System.getSystemStats().battery` |
| Weather | `Weather.getCurrentConditions()`: condition, temperature, dewPoint, pressure (Pa → hPa), cloudCover, visibility, windBearing, windSpeed |
| Sun events | `Weather.getSunrise/getSunset(location, date)` |
| Lunar date | Computed on the watch from a 1900–2100 lunar table (no network) |

Permissions: `SensorHistory`, `UserProfile` (HR zones), `Positioning` (sunrise/sunset location), `ComplicationSubscriber` (tap targets).

## 6. Weather mapping

### 6.1 Sky cover

1. **From `cloudCover`** (preferred):

   | Cloud cover | Code |
   |---|---|
   | 0–5% | CLR |
   | 6–25% | FEW |
   | 26–50% | SCT |
   | 51–87% | BKN |
   | ≥ 88% | OVC |

2. **Fallback:** if `cloudCover` is null, use the fallback cover in the table below.
3. **Obscured (X):** for fog, smoke, sandstorm and volcanic ash (marked X* in the table), draw X when `visibility` is under 1,000 m or is null. Otherwise use the `cloudCover` code, or OVC if that is null too.

Circle drawing: CLR = open circle; FEW = ¼ filled; SCT = ½; BKN = ¾ (pie wedges clockwise from 12 o'clock); OVC = filled; X = open circle with a diagonal cross.

### 6.2 Condition table

Symbols marked "(gray)" are "chance of" forecasts and are drawn in #6F6F6F instead of white. Light and heavy variants never show a `-` or `+` on the watch; the symbol itself (dot or star count) carries the intensity.

| ID | Garmin condition | Symbol | Fallback cover |
|---|---|---|---|
| 0 | `CLEAR` | none | CLR |
| 1 | `PARTLY_CLOUDY` | none | SCT |
| 2 | `MOSTLY_CLOUDY` | none | BKN |
| 3 | `RAIN` | RA | OVC |
| 4 | `SNOW` | SN | OVC |
| 5 | `WINDY` | none (barb shows it) | SCT |
| 6 | `THUNDERSTORMS` | TS | OVC |
| 7 | `WINTRY_MIX` | RASN | OVC |
| 8 | `FOG` | FG | X* |
| 9 | `HAZY` | HZ | FEW |
| 10 | `HAIL` | GR | OVC |
| 11 | `SCATTERED_SHOWERS` | SHRA | SCT |
| 12 | `SCATTERED_THUNDERSTORMS` | TS | SCT |
| 13 | `UNKNOWN_PRECIPITATION` | UP | OVC |
| 14 | `LIGHT_RAIN` | -RA | OVC |
| 15 | `HEAVY_RAIN` | +RA | OVC |
| 16 | `LIGHT_SNOW` | -SN | OVC |
| 17 | `HEAVY_SNOW` | +SN | OVC |
| 18 | `LIGHT_RAIN_SNOW` | RASN | OVC |
| 19 | `HEAVY_RAIN_SNOW` | RASN | OVC |
| 20 | `CLOUDY` | none | OVC |
| 21 | `RAIN_SNOW` | RASN | OVC |
| 22 | `PARTLY_CLEAR` | none | SCT |
| 23 | `MOSTLY_CLEAR` | none | FEW |
| 24 | `LIGHT_SHOWERS` | SHRA | SCT |
| 25 | `SHOWERS` | SHRA | BKN |
| 26 | `HEAVY_SHOWERS` | SHRA | BKN |
| 27 | `CHANCE_OF_SHOWERS` | SHRA (gray) | SCT |
| 28 | `CHANCE_OF_THUNDERSTORMS` | TS (gray) | SCT |
| 29 | `MIST` | BR | BKN |
| 30 | `DUST` | DU | FEW |
| 31 | `DRIZZLE` | DZ | OVC |
| 32 | `TORNADO` | FC | OVC |
| 33 | `SMOKE` | FU | X* |
| 34 | `ICE` | PL | OVC |
| 35 | `SAND` | DU | FEW |
| 36 | `SQUALL` | SQ | BKN |
| 37 | `SANDSTORM` | SS | X* |
| 38 | `VOLCANIC_ASH` | FU | X* |
| 39 | `HAZE` | HZ | FEW |
| 40 | `FAIR` | none | FEW |
| 41 | `HURRICANE` | TC (filled centre) | OVC |
| 42 | `TROPICAL_STORM` | TC (open centre) | OVC |
| 43 | `CHANCE_OF_SNOW` | SN (gray) | BKN |
| 44 | `CHANCE_OF_RAIN_SNOW` | RASN (gray) | BKN |
| 45 | `CLOUDY_CHANCE_OF_RAIN` | RA (gray) | OVC |
| 46 | `CLOUDY_CHANCE_OF_SNOW` | SN (gray) | OVC |
| 47 | `CLOUDY_CHANCE_OF_RAIN_SNOW` | RASN (gray) | OVC |
| 48 | `FLURRIES` | SHSN | BKN |
| 49 | `FREEZING_RAIN` | FZRA | OVC |
| 50 | `SLEET` | PL | OVC |
| 51 | `ICE_SNOW` | PL | OVC |
| 52 | `THIN_CLOUDS` | none | FEW |
| 53 | `UNKNOWN` | none | empty circle |

### 6.3 Symbol shapes

- **Coordinates:** units relative to the symbol centre, x right and y down. Multiply every coordinate by the scale k (fēnix 1.4, Venu 1.2).
- **Strokes:** white, 2.3 px (not scaled).
- **Dots:** filled circles of radius 2.6k.
- **Stars:** three lines through the centre at 90°, 30° and 150°, half-length r.
- `Q` / `C` / `T` / `S` are SVG quadratic and cubic curves. Flatten them into short line segments on the watch.

| Symbol | Shape |
|---|---|
| `-RA` | dots (−5,0), (5,0) |
| `RA` | dots (0,−6), (−6,4), (6,4) |
| `+RA` | dots (0,−8), (−7,0), (7,0), (0,8) |
| `DZ` | for x = −5 and 5: dot (x,−2), plus tail from (x+2.4,−2) curving Q(x+2.4,4) to (x−2,6) |
| `SHRA` | dot (0,−11); open triangle (−7,−5), (7,−5), (0,8) |
| `-SN` | one star at (0,0), r 5 |
| `SN` | stars at (−6,0) and (6,0), r 5 |
| `+SN` | stars at (0,−6), (−7,5), (7,5), r 4.5 |
| `SHSN` | star (0,−11), r 4; open triangle (−7,−5), (7,−5), (0,8) |
| `RASN` | dot (0,−7); star (0,6), r 4.5 |
| `FZRA` | dot (−2,0); wave M(−12,3) Q(−6,−9) (0,1) T(12,−2) |
| `PL` | open triangle (−7,6), (7,6), (0,−7); dot (0,2), r 2k |
| `GR` | filled triangle (−7,6), (7,6), (0,−7) |
| `TS` | polyline (−9,9) → (−9,−8) → (6,−8) → (1,0) → (7,0) → (1,9); arrowhead (−2,6) → (1,9) → (4,5) |
| `FG` | lines from x −10 to 10 at y −6, 0 and 6 |
| `BR` | lines from x −10 to 10 at y −3 and 3 |
| `HZ` | ∞: M(0,0) C(−5,−7) (−12,−7) (−12,0) S(−5,7) (0,0) C(5,−7) (12,−7) (12,0) S(5,7) (0,0) |
| `FU` | M(−4,10) Q(−9,3) (−3,−2) T(0,−10) |
| `DU` | S-curve M(6,−7) C(−2,−12) (−10,−6) (−2,0) S(7,10) (−6,7); vertical line (0,−11) → (0,11) |
| `SS` | the DU S-curve; horizontal line (−12,0) → (12,0); arrowhead (8,−3) → (12,0) → (8,3) |
| `SQ` | (−8,8) → (0,−8) → (8,8) |
| `FC` | M(−8,−10) Q(−2,0) (−8,10); M(8,−10) Q(2,0) (8,10) |
| `TC` | circle r 5 at centre (filled for hurricane, open for tropical storm); arms M(5,−2) Q(6,−11) (−4,−12) and M(−5,2) Q(−6,11) (4,12) |
| `UP` | dot (−7,0); question mark: M(1,−5) Q(2,−9) (5,−9) Q(9,−9) (8,−5) Q(7,−2) (5,−1) L(5,2), plus dot (5,6), r 1.5k |

## 7. Taps (WatchFaceDelegate.onPress → Complications.exitTo)

Implemented with `Complications.Id(type)`. Slot taps use each slot's tap rectangle from `Layout.slots`, so they follow the slot's field. Checked on the real watch 2026-09-29, including the gauge and the moved bottom row. A missing complication is ignored.

| Tap target | Opens |
|---|---|
| HR tape | Heart rate (`HEART_RATE`) |
| ALT tape | Altimeter (`ALTITUDE`) |
| Station model | Weather (`CURRENT_WEATHER`) |
| A slot showing BB | Body Battery (`BODY_BATTERY`) |
| A slot showing SPO2 | Pulse Ox (`PULSE_OX`) |
| A slot showing ACT MIN | Intensity minutes (`INTENSITY_MINUTES`) |
| A slot showing SS / SR | `SUNSET` / `SUNRISE` |
| A slot or gauge showing STRESS / BAT | `STRESS` / `BATTERY` |
| Bottom row while BINGO shows | `BATTERY` |
| Date block right column with the lunar date | nothing |

## 8. Open items

- Optional: re-run the 24-hour burn-in simulation on the Venu 3S for the current layout (View > View Screen Heat Map, release build, low power mode).
- Done: every tap target re-checked on the real watch with the current layout, the gauge and the moved bottom row included (2026-09-29); always-on burn-in with the current layout on the fēnix 8 (1.5% peak luminance, no burn-in, 2026-09-28) and with the previous layout (1.41% / 1.6% on fēnix / Venu, 2026-09-27); altitude clamps at `999`; null weather shows an empty circle, observations older than 3 h dim the station model.

## 9. Distribution

- For now, the watch face is sideloaded onto the user's own watches.
- Published on the Connect IQ Store as "PCD Cockpit" (0.1.0 submitted 2026-10-05; listing in [STORE.md](STORE.md)); store installs get the phone settings ([SETTINGS.md](SETTINGS.md)).
- China: there is no separate upload. Apps approved on the global store (apps.garmin.com) are copied to the China store (apps.garmin.cn) under the same app id; forum reports say the copy can lag behind. A beta app is only visible to the developer's global account, so a watch paired with a China-region account cannot install it: test by sideloading, then publish the release version.
- Package: `.\build.ps1 -Export` writes `bin\PcdCockpit.iq` (every product in the manifest, release build, signed with the developer key). Every store update must be signed with the same key.
