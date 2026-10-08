# Watch-face settings

Status: built (2026-10-08) for the next store version (0.2.0); not yet released. Phone settings only.
Related: [requirements.md](requirements.md) (what the face shows), [README.md](README.md) (build, tests and source layout).

## 1. Scope

The wearer can choose the font style, what each of the five slots and the gauge show, and turn the progress bars on. Everything else stays fixed:

| Not a setting | Why |
|---|---|
| Time colon | Does not fit: "23:41" is ~328 px wide on the fēnix (room between the tape boxes ~308 px) and ~255 px on the Venu 3S (~248 px) |
| STRESS warning | Removed (stress shows in the gauge on fēnix-size watches, or in any slot) |
| Gauge on / off | Always on (454 px layout); what it shows is a setting (§3) |
| Units, colours | °C, hPa, km, m and the colour meanings stay fixed |

The defaults are the look of the build before settings existed (checked pixel for pixel, §6), except that the STRESS warning box no longer appears on the Venu 3S.

## 2. How the wearer changes settings

Phone only: Connect IQ / Garmin Connect app (or Garmin Express) → the face → Settings. This needs the face installed from the Connect IQ Store; a sideloaded `.prg` always uses the defaults.

Not used:
- **Native watch-face editor** (`WatchFaceConfig`, API 5.1: long-press the face → Edit): only fēnix 8 / 8 Pro, FR970 and Venu 4 among our watches, and it only offers styles, complications and colours. Parked.
- **On-watch settings menu** (`AppBase.getSettingsView`): would duplicate the phone form.

## 3. Settings

| Property | Slot | Default | Choices |
|---|---|---|---|
| `fontStyle` | — (all text) | 1, G | 0 = D chamfered corners, 1 = G small rounded corners, 2 = E large rounded corners (`Settings.fontStyle`; only the chosen style is loaded, the old one is dropped first) |
| `field1` | Data window 1 (left, narrow) | BB | any field from §4 except the **wide only** ones |
| `field2` | Data window 2 (middle, narrow) | SPO2 | same as `field1` |
| `field3` | Data window 3 (right, wide) | ACT MIN | any field from §4 |
| `dateField` | Date block, right column (wide) | Lunar date | Lunar date or any field from §4 |
| `bottomField` | Bottom row (header beside value, at most 150 / 140 px) | Sun event | any field from §4 except ACT MIN (`Field.rowOk`: it would lose its goal). BINGO / STRESS warnings still replace it |
| `gaugeField` | Gauge above the bottom row (454 px layout; ignored on the Venu 3S) | Stress | `STR` stress, `BB` Body Battery, `BAT` battery, `O2` SpO2, `SLP` sleep score, `STP` / `FLR` / `ACT` steps, floors, weekly intensity minutes as % of goal (`Field.gaugeable`). Showing stress turns the STRESS warning off |
| `showBars` | — | off | Progress bar under data window values that have a goal (ACT MIN, STEPS, FLOORS) |

Values are `Field` ids (`source/Fields.mc`). They are stored in the wearer's settings, so ids are only ever appended, never renumbered (unit test `testFieldIdsStable`). A missing, wrongly typed or not-allowed value falls back to the slot's default (`Settings.pick`).

## 4. Fields

In the phone lists in this order (`resources/settings/settings.xml`; each list starts with its slot's default):

| Id | Header (short form) | Shows | Source | Bar | Tap opens |
|---|---|---|---|---|---|
| 0 | `BB>` | Body Battery | SensorHistory | | Body Battery |
| 1 | `SPO2>` | Pulse Ox, `97%` | Activity / SensorHistory | | Pulse Ox |
| 4 | `STRESS>` (`STR>`) | Stress | ActivityMonitor / SensorHistory | | Stress |
| 17 | `RHR>` | Resting heart rate | UserProfile | | Heart rate |
| 18 | `SLEEP>` (`SLP>`) | Sleep score 0–100 | Complication (API 6.0.2) | | Sleep score |
| 6 | `STEPS>` (`STP>`) | Steps today — **wide only** (in a narrow cell it would be `9K` on the Venu 3S) | ActivityMonitor | step goal | Steps |
| 10 | `DIST>` | Distance today, `8.4 KM` | ActivityMonitor | | Steps |
| 9 | `KCAL>` (`CAL>`) | Calories today (incl. resting) — **wide only** | ActivityMonitor | | Calories |
| 7 | `FLOORS>` (`FLR>`) | Floors climbed today | ActivityMonitor | floor goal | Floors |
| 8 | `FL DN>` (`FLD>`) | Floors descended today | ActivityMonitor | | Floors |
| 12 | `CLIMB>` (`CLB>`) | Ascent today, `312 M` | ActivityMonitor | | Floors |
| 11 | `ACT DAY>` (`ACTD>`) | Intensity minutes today | ActivityMonitor | | Intensity minutes |
| 2 | `ACT MIN>` (`ACT>`) | Intensity minutes this week, `95/150` — **wide windows only**, not the bottom row (both would drop the goal) | ActivityMonitor | weekly goal | Intensity minutes |
| 13 | `VO2>` | VO2 max, running | UserProfile | | VO2 max (run) |
| 14 | `VO2 BIKE>` (`VO2B>`) | VO2 max, cycling (needs a power meter) | UserProfile | | VO2 max (bike) |
| 15 | `RUN WK>` (`RUN>`) | Running distance this week, km | Complication | | Weekly run distance |
| 16 | `BIKE WK>` (`BIKE>`) | Cycling distance this week, km | Complication | | Weekly bike distance |
| 21 | `POP>` | Chance of precipitation, % | Weather | | Weather |
| 20 | `VIS>` | Visibility, km | Weather | | Weather |
| 3 | `SR>` / `SS>` | Next sunrise or sunset, `1856` — **wide only** | Weather | | Sunrise / sunset |
| 19 | `UTC>` (`Z>`) | UTC (Zulu) time, `1442Z` — **wide only** | clock | | — |
| 5 | `BAT>` | Watch battery, % | System | | Battery |
| -1 | (CJK) | Lunar date — **date block only** | Lunar.mc | | — |

Fitting (`Fit` in `Slots.mc`). In a cell: a header within 10 px of the cell width uses the short form in brackets; a value + unit wider than the cell drops the unit, then tries the field's shorter forms in order. Counts from 1,000 up: `23456` → `23.5K` → `23K`; km under 100: `12.4` → `12`. In the bottom row (at most `Layout.rowW`: 150 px fēnix, 140 px Venu 3S, as wide as the original `SS>1856`): value with unit, without, then the shorter forms, each with the full and then the short header. Unit test `testEveryFieldFits` checks every field in every slot it is allowed in, on both layouts, with its widest value. Narrow cells hold 3 digits, or `8.6K` on the fēnix (100 px; Venu 3S 80 px); the wide-only fields have 4 digits that cannot be shortened.

Fonts: the value font has `.` and `K`, the unit font `K`, `M` and `Z` (FontGen). `.` has its own narrow advance (2K + 2 grid units, `_adv[4]`).

Availability differs per watch and is only known at run time (e.g. cycling VO2 max, sleep score on older firmware): no value shows `--`.

Later, as small icons in free space rather than fields: unread notifications, alarms, phone connection.

## 5. Code

| File | Does |
|---|---|
| `resources/settings/properties.xml` | Keys and defaults |
| `resources/settings/settings.xml` | The phone form: one list per slot, the bars toggle |
| `resources/strings/strings.xml` | Setting titles and field names (English, as on the face) |
| `source/Settings.mc` | `load()` reads the properties with fallbacks; `allowed()` = which fields each slot takes |
| `source/Fields.mc` | Per field: header, short header, value / unit / progress / shorter forms, tap target |
| `source/Data.mc` | Reads the new values once a minute (`readActivity`, `readProfile`, weather, UTC) |
| `source/Layout.mc` | Builds the slots from `Settings.fields` |
| `source/PcdApp.mc` | `onSettingsChanged()` → `Settings.load()`, `PcdView.applySettings()` (rebuilds the layout; reloads the fonts only if the style changed) |

## 6. Testing

- **Unit tests** (`.\build.ps1 -Test`, `source/Tests.mc`): settings fallbacks and slot rules, default slots per layout, field ids, value formats, header widths, lunar dates (including the 2027 Spring Festival correction).
- **Pixel regression** (`.\tools\regress.ps1`): fixed data, time and date; fēnix 8 and Venu 3S × everyday / BINGO / amber stress × active / always-on, compared with `tests/golden/`. With default settings every capture must match exactly.
- **Showcase** (`.\tools\regress.ps1 -Show <5 field ids> [-Bars] [-Wide]`): captures with chosen fields, for eyeballing new fields; no comparison.
- **Simulator settings editor**: File > Edit Persistent Storage > Edit Application.Properties data.
- **Real watches**: phone settings only work for store installs. Before release, upload a **beta** (Connect IQ "Beta App" checkbox) built with a separate app id in `manifest.xml`, install it from the store, change each setting from the phone, check the face updates and survives a reboot; then switch the app id back for the release upload.

## 7. Release checklist (0.2.0)

1. Unit tests and regression pass.
2. Beta test on the fēnix 8 and the Venu 3S (§6).
3. App id back to the production id; `.\build.ps1 -Export`; upload as a new version of the existing store app (same `developer_key`).
4. Update the store text (settings, new fields) and the GitHub link (`KaiZ-lgtm`).
