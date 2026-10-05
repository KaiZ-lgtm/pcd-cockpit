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
| Upper left of the circle | Temperature °C (always Celsius, whatever the watch setting) |
| Lower left of the circle | Dew point °C. The closer it is to the temperature, the more humid the air and the likelier fog |
| Further left | Current weather symbol |
| Right of the circle | Sea-level pressure, hPa |
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

## 5. Data windows

| Window | Meaning |
|---|---|
| `BB>` | Body Battery (0–100) |
| `SPO2>` | Blood oxygen % |
| `ACT MIN>` | Intensity minutes this week / weekly goal (only the minutes if both do not fit) |

Each window has a cyan underlined header on top, the white value below and the unit in small gray. If they do not fit, the unit is left out, e.g. `150/150` shows as `150`. The `>` after each header imitates the soft-key arrows on a cockpit display: tap to open the matching page (see section 8).

What the three windows show can later be changed in the settings; so can the date block's right column and the bottom row.

## 6. Bottom: stress gauge, sunrise/sunset and warnings

### 6.1 Stress gauge (fēnix-size watches)

On the fēnix 8 and the other 454 px watches, a gauge above the bottom row shows your stress (0–100), styled after the segmented gauges on a fighter-jet cockpit display:

- `STR` on the left, the number on the right, and 10 segments of 10 points in between. The last segment fills in part, so 62 is six full segments and a fifth of the seventh.
- Colour: cyan 0–25 (rest), green 26–50, amber 51–75, red 76–100.
- On these watches the gauge takes over from the STRESS warning below: the bottom row only changes for BINGO.
- What the gauge shows can later be changed in the settings (battery or Body Battery, for example).

### 6.2 Bottom row

Normally this row reads like a data window, with the header and value side by side (no frame), and shows the next sun event:

- `SS> 1856`: sunset today at 18:56 (shown during the day).
- `SR> 0703`: sunrise at 07:03 (shown after sunset).

When a warning is active, the row becomes a square box: a full-colour border filled with dimmed 45° stripes (like hazard tape), with white text. Highest priority first:

| Priority | Shows | When | Style | Meaning |
|---|---|---|---|---|
| 1 | `BINGO` | battery ≤ 10% | red stripes | Aviation term for "only enough fuel to get home"; here, charge the watch |
| 2 | `STRESS` | stress ≥ 76 | red stripes | High stress (Venu 3S only; see 6.1) |
| 3 | `STRESS` | stress 51–75 | amber stripes | Elevated stress (Venu 3S only) |

- If several apply, only the highest priority is shown.
- When the warning clears, the row goes back to sunrise/sunset.

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
| BB | Body Battery |
| SPO2 | Pulse Ox |
| ACT MIN | Intensity minutes |
| Stress gauge | Stress |
| Bottom row | Sunrise/sunset; battery while BINGO is showing, stress while STRESS is showing |
