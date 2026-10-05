# Watch-face settings — design

Status: design only, nothing below is built yet. Today every option is a compile-time constant; this doc plans how they become user settings.
Related: [requirements.md](requirements.md) (what the face shows), [README.md](README.md) (build and source layout).

## 1. Goals

- Let the wearer change a few look-and-feel choices without rebuilding: font style, time colon, what each slot shows, progress bars, STRESS warning, the gauge.
- Settings are changed in the phone app (Connect IQ / Garmin Connect), which needs the face to be installed from the Connect IQ Store. The face will be published there; until then it stays sideloaded and uses the defaults.
- Keep the current look as the default, so a watch with no saved settings looks exactly like today's build.
- Keep memory and draw time as they are: only the chosen font style is loaded, and nothing is re-read on every frame.

Not goals: changing units (°C, hPa and metres stay fixed by design), changing colours, per-device layouts.

## 2. Options that already exist as constants

| Constant | Where | Values | Default |
|---|---|---|---|
| `FONT_STYLE` | `PcdView.mc` | 0 = D chamfered, 1 = G small rounded, 2 = E large rounded | 1 (G) |
| `TIME_COLON` | `PcdView.mc` | on / off (with the colon the time is wider and can touch the tape boxes) | off |
| `SHOW_BARS` | `PcdView.mc` | on / off (bar only for fields with a goal) | off |
| `STRESS_WARN` | `Data.mc` | on / off (BINGO always stays on); also off while the gauge shows stress | on |
| `GAUGE` | `Layout.mc` | on / off (454 px layout only) | on |
| `GAUGE_FIELD` | `Layout.mc` | a field with a `Field.gauge` case (STRESS, BB, BATTERY, SPO2) | STRESS |
| `Slot.field` | `Layout.mc` (`slots`) | the `Field` each slot shows | data row BB · SPO2 · ACT MIN; date block lunar date; bottom row sun event; gauge stress |

Each one is read in exactly one place, so turning it into a setting only changes where the value comes from. The slots were built for this: `Layout.slots` lists every place that shows a field, and both drawing and tapping read `Slot.field` from it.

## 3. How the wearer changes settings

Connect IQ offers two routes:

| Route | How | Works when sideloaded? |
|---|---|---|
| Phone (Connect IQ / Garmin Connect app) | `resources/settings/properties.xml` + `settings.xml`; the phone shows the form and sends the values; the app gets `onSettingsChanged()` | No — per the Garmin developer forums, phone settings need the app installed from the Connect IQ Store (a private beta listing is enough) |
| On the watch | `AppBase.getSettingsView()` returns a `WatchUi.Menu2` and its delegate; the watch shows it under the watch face's settings entry | Yes |

**Decision:** the phone app is the route. The face will be published on the Connect IQ Store (a private beta listing first is enough to test settings on the real watches). All settings, including the font style, live in the phone form. An on-watch menu is not planned; if one is wanted later, it can write the same properties.

Publishing notes:
- The store build must be signed with the same developer key as every later update (`developer_key` in the project folder; keep a backup).
- Keep the app id in `manifest.xml` unchanged. To be safe, delete the sideloaded `.prg` from `GARMIN\APPS` before installing the store version, so the watch does not end up with two copies (not yet checked how the watch handles both).

## 4. Settings list

| Key (property id) | Type | Choices | Default | Replaces |
|---|---|---|---|---|
| `fontStyle` | number (list) | D chamfered / G small rounded / E large rounded | 1 (G) | `FONT_STYLE` |
| `timeColon` | boolean | on / off | false | `TIME_COLON` |
| `field1`, `field2`, `field3` | number (list of `Field` ids) | see §6 | BB, SPO2, ACT_MIN | data row slots' `field` |
| `dateField` | number (list) | Lunar date, or any field from §6 | lunar | date block slot's `field` |
| `bottomField` | number (list) | Sun event, or any field from §6 | sun event | bottom row slot's `field` |
| `showBars` | boolean | on / off | false | `SHOW_BARS` |
| `gauge` | boolean | on / off (ignored on the Venu 3S) | true | `GAUGE` (the layout is rebuilt: the bottom row moves) |
| `gaugeField` | number (list) | Stress, Battery, Body Battery, SpO2 (fields with a gauge case) | stress | the gauge slot's `field` |
| `stressWarn` | boolean | on / off | true | `STRESS_WARN` (a gauge showing stress still turns it off) |

Order in the phone form: Font style → Time colon → Date block field → Data window 1 / 2 / 3 → Gauge → Gauge field → Bottom row field → Progress bars → STRESS warning. Labels and list entries are strings in `resources/strings/strings.xml`, in English like the rest of the face; field names use the same words as on the face (`BB`, `SPO2`, `ACT MIN`).

Candidates for later (not in the first version): BINGO threshold (10 / 15 / 20 %).

## 5. Code design

1. **`resources/settings/properties.xml` (new):** declares every key with its default. **`resources/settings/settings.xml` (new):** the phone form — a list for `fontStyle` and each field key, a toggle for each boolean, each bound to its property with `propertyKey="@Properties.<key>"`.
2. **`source/Settings.mc` (new):** a module holding the current values as module variables, filled by `Settings.load()` from `Application.Properties.getValue(key)`. Every read falls back to the default above if the key is missing or has the wrong type (first run, or an older saved version). The rest of the code reads `Settings.fontStyle` etc. instead of the constants. Called once at start.
3. **Applying a change:** `PcdApp.onSettingsChanged()` calls `Settings.load()`, then `PcdView.applySettings()`, then `WatchUi.requestUpdate()`.
   - Font style changed → drop the current fonts (set the `_f*` fields to null) *before* loading the new style, so two styles are never in memory at once; then run the same loading code as `onLayout`.
   - Fields changed → set `field` on the matching slots in `Layout.slots` (positions and widths stay fixed, §6).
   - Gauge on / off → rebuild the `Layout` (it moves the bottom row), then set `Data.stressWarn` again as `onLayout` does.
   - The rest (colon, bars, stress) is read at draw time from `Settings`; nothing to rebuild.
4. **Unchanged:** the always-on layer, burn-in shift, tap targets (the delegate already reads `Slot.field` from `Layout.slots`), and the demo build (demo data ignores settings except the ones it exercises).

## 6. Slots: choosing fields

Five slots in three styles, plus the gauge on the 454 px layout (requirements §3.5): the data row is narrow · narrow · wide cells (fēnix 100 / 100 / 144 px, Venu 80 / 80 / 132 px, `Layout.winN` / `winW`), the date block's right column is a wide cell, the bottom row is a row (header beside the value), and the gauge is a 10-segment bar for 0–100 fields. Positions and widths stay fixed whatever is chosen:

- Short values (`100`, `97%`) fit any slot; values with a goal or many digits (`150/150`, steps) belong in a wide slot.
- In a cell, if value + unit does not fit, the unit is dropped (e.g. `150/150` in a narrow slot shows `150`). The bottom row has room for any value.
- The lunar date is only offered for the date block; the warnings (BINGO / STRESS) keep replacing the bottom row whatever it shows.
- The phone form can offer every field in every slot; its help text says which ones read best in the wide slots.
- The same field may be picked twice; nothing breaks.

- The gauge only offers fields with a `Field.gauge` case (a 0–100 scale); a 0–100 field added later (sleep score, for example) needs one case there as well.

New fields to offer, each = one enum value plus a case in `header`, `read` and `complication` in `Fields.mc` (Stress and Battery are already there, as `STRESS>` and `BAT>`):

| Field | Header | Widest text | Bar (has goal) | Note |
|---|---|---|---|---|
| Steps | `STEPS>` | `99.9K` | yes (step goal) | Under 10,000 shown in full (`9876`); from 10,000 as thousands with one decimal (`12.3K`). The value font needs `.` and `K` added in FontGen |
| Floors | `FLOORS>` | `99/10` | yes | |
| Resting HR | `RHR>` | `100` | no | |
| Respiration | `RESP>` | `30` | no | |
| Sleep score | `SLP>` | `100` | no | From the `SLEEP_SCORE` complication; 0–100, so also a gauge field. The closest readable stand-in for Training Readiness, which Connect IQ does not expose |
| Calories | `KCAL>` | `4500` | yes, if a goal exists | |

## 7. Testing

- Simulator: set values with its app-settings editor (it reads `settings.xml`), check each option on both watches, and check that a missing or wrong-typed value falls back to the default.
- Memory: switch font style back and forth in the simulator and watch peak memory; it must stay about where it is today (one style loaded).
- Real watches: install the private beta from the store, change each setting from the phone, and check that the face updates and the values survive a reboot.
- Burn-in and always-on are not touched; no need to re-run the 24-hour heat map unless the always-on layer changes.

## 8. Decisions

- Settings route: phone app, after publishing on the Connect IQ Store (private beta first).
- Font style: in the phone settings.
- Steps: `12.3K` from 10,000 up.
