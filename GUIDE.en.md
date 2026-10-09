# PCD Cockpit reading guide

How to read each element of the face (Chinese version: [GUIDE.md](GUIDE.md); keep both in sync when editing). Technical spec: [requirements.md](requirements.md); build notes: [README.md](README.md).

```
              wind barb
               \
      ☂  22    ◔    1013          ← station model: weather symbol · temp/dew point · sky cover · pressure
         14
           SUN      八月
          09/27     十七           ← left: weekday, month/day   right: lunar month, day
  ├                         ┤
 ┌┼─┐                10M ┌──┼┐
 │HR│     2 3 4 1        │ALT│  ← left: heart-rate tape   middle: time (24-hour)   right: altitude tape
 │62│                    │125│
 └┼─┘                    └──┼┘
  ├                         ┤
      BB>     SPO2>    ACT MIN>    ← data windows
      74      97%      95/150
   STR ▮▮▮▮▮▮▯▯▯▯ 62              ← stress gauge (fēnix-size watches)
            SS> 1856               ← bottom row: sunset/sunrise, or a warning
```

## 1. Station model (top)

This is the "station model" from aviation weather charts: a sky-cover circle in the middle with the readings arranged around it.

| Position | Shows |
|---|---|
| Centre circle | Sky cover |
| Upper left of the circle | Temperature °C (°F with imperial units, see section 5.2) |
| Lower left of the circle | Dew point, same unit. The closer it is to the temperature, the more humid the air and the likelier fog |
| Further left | Current weather symbol |
| Right of the circle | Sea-level pressure, hPa (imperial: inches of mercury, e.g. `29.92`) |
| Staff from the circle | Wind direction and speed |

### 1.1 Sky-cover circle

| Circle | Meaning |
|---|---|
| Open ○ | Clear, 0–5% |
| ¼ filled | Few clouds, 6–25% |
| ½ filled | Scattered, 26–50% |
| ¾ filled | Broken, 51–87% |
| Filled ● | Overcast, ≥ 88% |
| ✕ inside the circle | Sky obscured (fog, smoke, sandstorm or volcanic ash with visibility under 1 km) |

The wedges fill clockwise from 12 o'clock.

### 1.2 Wind barb

- **Direction:** the staff points to where the wind **comes from**. A staff pointing up and to the right is a north-east wind.
- **Speed:** in knots (kt, 1 kt ≈ 1.85 km/h). Add up the marks at the end of the staff:

| Mark | Worth |
|---|---|
| Short (half) barb | 5 kt |
| Long barb | 10 kt |
| Filled pennant | 50 kt |

  - Example: one pennant + one long barb + one short barb = 50 + 10 + 5 = **65 kt**.
  - Speed is rounded to the nearest 5 kt. Count the marks; their length does not matter.
- **Calm** (< 3 kt): no staff; an extra ring is drawn around the sky-cover circle instead.
- **No wind data:** neither a staff nor a ring. The same when the wind is 3 kt or more but has no direction.

### 1.3 Weather symbols

The symbols follow aviation weather-chart conventions. White means it is happening now. **Gray** means "chance of" (a forecast). Light and heavy are shown by the number of dots or stars; no `-` or `+` is written.

| Symbol | Weather |
|---|---|
| 2 dots | Light rain |
| 3 dots (triangle) | Rain |
| 4 dots (diamond) | Heavy rain |
| Two dots with tails | Drizzle |
| Downward triangle with a dot above | Rain showers |
| 1 star | Light snow |
| 2 stars | Snow |
| 3 stars | Heavy snow |
| Downward triangle with a star above | Snow showers (flurries) |
| A dot above a star | Rain and snow mixed |
| A dot and a wavy line | Freezing rain |
| Open triangle with a dot inside | Ice pellets, sleet |
| Filled triangle | Hail |
| Zig-zag with an arrowhead (lightning) | Thunderstorm |
| Three horizontal lines | Fog |
| Two horizontal lines | Mist |
| ∞ | Haze |
| Curling rising smoke | Smoke, volcanic ash |
| S-curve with a vertical line | Dust, sand |
| S-curve with an arrow to the right | Sandstorm |
| Peak ∧ | Squall |
| Two facing arcs )( | Tornado |
| Circle with two spiral arms (filled / open centre) | Hurricane / tropical storm |
| A dot and a question mark | Unknown precipitation |

No symbol is drawn for clear, few, partly cloudy, mostly cloudy, overcast, or windy (the barb already shows wind); read the sky-cover circle.

### 1.4 Missing or old data

- **No weather data:** just an empty circle, no numbers.
- **Weather more than 3 hours old:** the whole station model is dimmed, so you know it is stale.
- **One reading missing:** shown as a gray `--`.

## 2. Above the time: lunar and calendar date

Two columns above the time: the calendar date on the left (weekday on top, `month/day` below), the lunar date on the right (month on top, day below).

- **Calendar date:** white, e.g. `SUN` over `09/27` (27 September; month first).
- **Lunar date:** magenta, e.g. `八月` over `十七` (8th month, 17th day). A leap month starts with `闰`; days 1–10 are `初X`, days 21–29 are `廿X`, day 30 is `三十`.

The right column can later be switched to other data in the settings; it then reads like a data window (section 5).

## 3. Time

Green, 24-hour, with no colon by default: `2341` is 23:41 (a colon can be switched on: `23:41`).

## 4. Vertical tapes (left and right)

Modelled on the airspeed and altitude tapes of a fighter HUD, either side of the time (9 and 3 o'clock): a vertical line is the tape; it runs up and down to the edge of the screen, behind the reading box, its ticks point towards the bezel and scroll up and down with the value. The box shows the current reading, and the box's centre is the current position on the tape.

### 4.1 Left: heart rate (HR)

- The box shows the current heart rate (bpm). The tape has a short tick every 5 bpm and a long (thicker) tick every 10 bpm; about ±30 bpm is visible.
- **Zone colour band:** a 4 px colour band on the inner side of the tape (towards the time) marks the heart-rate zone boundaries nearby, taken from the zones set on the watch:

| Colour | Zone |
|---|---|
| Gray | Z1 warm-up |
| Cyan | Z2 easy |
| Green | Z3 aerobic |
| Amber | Z4 threshold |
| Red | Z5 maximum |

- The colour of your current zone is also used for the **box outline and number**, so the box colour tells you your zone at a glance. Below Z1 the box is green.
- The band scrolls with the ticks: higher heart rates are further up. When the current position is close to a colour change, you are about to enter the next zone.

### 4.2 Right: altitude (ALT)

- **Units are tens of metres:** `125` in the box means 1,250 m. The small gray `10M` just above the ALT box, on the side towards the time, is the reminder.
- A short tick every 20 m, a long tick every 100 m; about ±180 m is visible.
- Shows at most `999` (9,990 m).
- **Imperial** (section 5.2): units are hundreds of feet, like a flight level: `41` in the box means 4,100 ft, and the small label above the box reads `100` over `FT`. A short tick every 100 ft, a long tick every 500 ft; about ±900 ft is visible; at most `999` (99,900 ft).

## 5. Data windows

| Window | Meaning |
|---|---|
| `BB>` | Body Battery (0–100) |
| `SPO2>` | Blood oxygen % |
| `ACT MIN>` | Intensity minutes this week / weekly goal (only the minutes if both do not fit) |

Each window has a cyan underlined header on top, the white value below and the unit in small gray. If they do not fit, the unit is left out, e.g. `150/150` shows as `150`. The `>` after each header imitates the soft-key arrows on a cockpit display: tap to open the matching page (see section 8).

### 5.1 Choosing what the windows show

In the Connect IQ / Garmin Connect app (face installed from the store): face → Settings. Five places can be changed: the three data windows, the date block's right column (lunar date by default) and the bottom row (sunrise/sunset by default).  The two left data windows are narrow; the right data window, the date block's right column and the bottom row are the wide places. Progress bars can also be turned on: a thin bar under the value for fields with a goal. The font can be switched too: small rounded corners (default), chamfered corners or large rounded corners. Units can be metric or imperial (section 5.2).

| Header | Meaning |
|---|---|
| `BB>` `SPO2>` `STRESS>` | Body Battery, blood oxygen %, stress |
| `RHR>` | Resting heart rate |
| `SLEEP>` | Sleep score (0–100) |
| `STEPS>` | Steps today (bar: step goal; wide places only) |
| `DIST>` | Distance today, km (imperial: miles) |
| `KCAL>` | Calories today, including resting (wide places only) |
| `FLOORS>` / `FL DN>` | Floors climbed (bar: floor goal) / descended today |
| `CLIMB>` | Ascent today, metres (imperial: feet) |
| `ACT DAY>` / `ACT MIN>` | Intensity minutes today / this week (bar: weekly goal; `ACT MIN>` only in the right data window or the date block, where its goal fits) |
| `VO2>` / `VO2 BIKE>` | VO2 max, running / cycling |
| `RUN WK>` / `BIKE WK>` | Running / cycling distance this week, km (imperial: miles) |
| `POP>` | Chance of precipitation, % |
| `VIS>` | Visibility, km (imperial: `SM`, statute miles as in aviation) |
| `SR>` / `SS>` | Next sunrise / sunset (wide places only) |
| `UTC>` | UTC time with `Z` ("Zulu"), as used in aviation (wide places only) |
| `BAT>` | Watch battery % |

Where space is short (the two narrow windows, the bottom row) long values are shortened: `23456` steps show as `23.5K` or `23K`, `12.4` km as `12`; long headers too (`STRESS>` → `STR>`, `STEPS>` → `STP>`, `SLEEP>` → `SLP>`, `KCAL>` → `CAL>`, `FLOORS>` → `FLR>`, `FL DN>` → `FLD>`, `CLIMB>` → `CLB>`, `ACT MIN>` → `ACT>`, `ACT DAY>` → `ACTD>`, `VO2 BIKE>` → `VO2B>`, `RUN WK>` → `RUN>`, `BIKE WK>` → `BIKE>`, `UTC>` → `Z>`). `--` means the watch has no value (for example cycling VO2 max without a power meter).

### 5.2 Units

Chosen on the same settings page (the watch's own unit setting is not used):

| | Metric (default) | Imperial |
|---|---|---|
| Temperature, dew point | °C | °F |
| Pressure | hPa (`1013`) | inHg (`29.92`) |
| Altitude tape | tens of metres (`10M`) | hundreds of feet (`100` over `FT`) |
| Distance | `KM` | `MI` |
| Visibility | `KM` | `SM` (statute miles) |
| Climb | `M` | `FT` |

Wind speed is in knots either way (section 1.2), as in aviation.

## 6. Bottom: stress gauge, sunrise/sunset and warnings

### 6.1 Stress gauge (fēnix-size watches)

On the fēnix 8 and the other 454 px watches, a gauge above the bottom row shows your stress (0–100), styled after the segmented gauges on a fighter-jet cockpit display:

- `STR` on the left, the number on the right, and 10 segments of 10 points in between. The last segment fills in part, so 62 is six full segments and a fifth of the seventh.
- Colour: cyan 0–25 (rest), green 26–50, amber 51–75, red 76–100.
- The bottom row only changes for BINGO (low battery; section 6.2).
- What the gauge shows can be changed in the settings (section 5.1): `STR` stress, `BB` Body Battery, `BAT` watch battery, `O2` blood oxygen, `SLP` sleep score, or `STP` / `FLR` / `ACT` steps, floors or weekly intensity minutes as % of the goal (the bar stops full at 100 %, the number keeps counting). Body Battery and battery turn amber and red as they run low, sleep score amber under 60.

### 6.2 Bottom row

Normally this row reads like a data window, with the header and value side by side (no frame), and shows the next sun event:

- `SS> 1856`: sunset today at 18:56 (shown during the day).
- `SR> 0703`: sunrise at 07:03 (shown after sunset).

What it shows can be changed in the settings (section 5.1).

**BINGO**: when the battery is at 10% or less, the row becomes a square box: a red border filled with dimmed 45° red stripes (like hazard tape), with white `BINGO`. "Bingo fuel" is the aviation term for "only enough fuel to get home"; here, charge the watch. Once charged above 10%, the row goes back to what it showed.

## 7. Always-on (screen off)

- Shows only the time (thin, dim green), the date (gray) and the lunar date (dim magenta), in the same places as in active mode. Weather, tapes, data windows, the stress gauge and the bottom row are hidden.
- To prevent AMOLED burn-in, the whole layer shifts by 3–5 px every minute, so a slight movement while the screen is off is normal.

## 8. Taps

Tapping an element opens the watch's own matching page:

| Tap | Opens |
|---|---|
| Left heart-rate box | Heart rate |
| Right altitude box | Altimeter |
| Station model | Weather |
| Data windows, date block field | The page of what they show (BB → Body Battery, SPO2 → Pulse Ox, ACT MIN → intensity minutes, STEPS → steps, …; UTC opens nothing) |
| Gauge | The page of what it shows (stress by default) |
| Bottom row | What it shows (sunrise/sunset by default); battery while BINGO is showing |
