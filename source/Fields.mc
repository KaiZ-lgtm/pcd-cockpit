import Toybox.Complications;
import Toybox.Lang;

// What a Slot can show (requirements §3.5). Adding a field = one enum value (before COUNT), an entry in
// each table below, a case in read() (and in gauge() if it is a 0-100 value), a list entry in
// resources/settings/settings.xml and its name in strings.xml. The ids are stored in the wearer's settings
// (Settings.mc): append new fields, never renumber.
module Field {
    enum {
        BB, SPO2, ACT_MIN, SUN, STRESS, BATTERY,
        STEPS, FLOORS, FLOORS_DN, KCAL, DIST, ACT_DAY, CLIMB, VO2_RUN, VO2_BIKE, RUN_WK, BIKE_WK,
        RHR, SLEEP, UTC, VIS, POP,
        COUNT
    }

    // Lunar date: only valid in the date block's right column (drawn in CJK, not as header + value).
    const LUNAR = -1;

    const SLEEP_SCORE = 42 as Complications.Type;   // Complications.COMPLICATION_TYPE_SLEEP_SCORE (API 6.0.2)

    // Fields kept out of the two narrow data windows: 4 digits that cannot be shortened (sun event, UTC),
    // or values that lose what matters when shortened (steps and calories would be 9K / 2K on the
    // Venu 3S, ACT MIN would lose its /goal).
    function wide(id as Number) as Boolean {
        return id == SUN || id == UTC || id == STEPS || id == KCAL || id == ACT_MIN;
    }

    // Fields kept out of the bottom row (header beside value, at most Layout.rowW): ACT MIN would lose
    // its /goal there too. Steps and calories keep one decimal (8.6K) on both layouts.
    function rowOk(id as Number) as Boolean {
        return id != ACT_MIN;
    }

    // Per field, in enum order (unit test testFieldTables). SUN's header and page depend on the next
    // event (header(), complication()).
    // Header with the soft-key arrow.
    const HEADERS = [
        "BB>", "SPO2>", "ACT MIN>", null, "STRESS>", "BAT>",
        "STEPS>", "FLOORS>", "FL DN>", "KCAL>", "DIST>", "ACT DAY>", "CLIMB>", "VO2>", "VO2 BIKE>", "RUN WK>",
        "BIKE WK>", "RHR>", "SLEEP>", "UTC>", "VIS>", "POP>"
    ] as Array<String?>;
    // Shorter header where the full one does not fit (Fit.cell / Fit.row); null: the full one always fits.
    const SHORTS = [
        null, null, "ACT>", null, "STR>", null,
        "STP>", "FLR>", "FLD>", "CAL>", null, "ACTD>", "CLB>", null, "VO2B>", "RUN>",
        "BIKE>", null, "SLP>", "Z>", null, null   // Z: Zulu, as in aviation
    ] as Array<String?>;
    // Native page opened when the slot is tapped (null: not tappable).
    const TAPS = [
        Complications.COMPLICATION_TYPE_BODY_BATTERY, Complications.COMPLICATION_TYPE_PULSE_OX,
        Complications.COMPLICATION_TYPE_INTENSITY_MINUTES, null, Complications.COMPLICATION_TYPE_STRESS,
        Complications.COMPLICATION_TYPE_BATTERY,
        Complications.COMPLICATION_TYPE_STEPS, Complications.COMPLICATION_TYPE_FLOORS_CLIMBED,
        Complications.COMPLICATION_TYPE_FLOORS_CLIMBED, Complications.COMPLICATION_TYPE_CALORIES,
        Complications.COMPLICATION_TYPE_STEPS, Complications.COMPLICATION_TYPE_INTENSITY_MINUTES,
        Complications.COMPLICATION_TYPE_FLOORS_CLIMBED, Complications.COMPLICATION_TYPE_VO2MAX_RUN,
        Complications.COMPLICATION_TYPE_VO2MAX_BIKE, Complications.COMPLICATION_TYPE_WEEKLY_RUN_DISTANCE,
        Complications.COMPLICATION_TYPE_WEEKLY_BIKE_DISTANCE, Complications.COMPLICATION_TYPE_HEART_RATE,
        SLEEP_SCORE, null, Complications.COMPLICATION_TYPE_CURRENT_WEATHER,
        Complications.COMPLICATION_TYPE_CURRENT_WEATHER
    ] as Array<Complications.Type?>;

    function header(id as Number, d as Data) as String {
        if (id == SUN) { return d.sunIsSet ? "SS>" : "SR>"; }
        return HEADERS[id] as String;
    }

    function shortHeader(id as Number) as String? {
        return SHORTS[id];
    }

    function complication(id as Number, d as Data) as Complications.Type? {
        if (id == SUN) {
            return d.sunIsSet ? Complications.COMPLICATION_TYPE_SUNSET : Complications.COMPLICATION_TYPE_SUNRISE;
        }
        return id >= 0 && id < COUNT ? TAPS[id] : null;
    }

    // [value string or null, unit string, progress 0..1 or null (no goal: no bar), shorter forms of the
    // value or null]. A cell too narrow for the value tries the shorter forms in order (PcdView.cellText).
    function read(id as Number, d as Data) as Array {
        switch (id) {
            case BB:
                return [str(d.bodyBattery), "", null, null];
            case SPO2:
                return [str(d.spo2), "%", null, null];
            case ACT_MIN:
                var am = d.actMin, goal = d.actGoal;
                return [str(am), goal != null ? "/" + goal.toString() : "", progress(am, goal), null];
            case STRESS:
                return [str(d.stress), "", null, null];
            case BATTERY:
                return [batteryPct(d).toString(), "%", null, null];
            case STEPS:
                return [str(d.steps), "", progress(d.steps, d.stepGoal), kilo(d.steps)];
            case FLOORS:
                return [str(d.floors), "", progress(d.floors, d.floorsGoal), null];
            case FLOORS_DN:
                return [str(d.floorsDn), "", null, null];
            case KCAL:
                return [str(d.kcal), "", null, kilo(d.kcal)];
            case DIST:
                return km(d.distM);
            case ACT_DAY:
                return [str(d.actDay), "", null, null];
            case CLIMB:
                var c = d.climbM != null ? (d.climbM + 0.5).toNumber() : null;
                return [str(c), "M", null, kilo(c)];
            case VO2_RUN:
                return [str(d.vo2Run), "", null, null];
            case VO2_BIKE:
                return [str(d.vo2Bike), "", null, null];
            case RUN_WK:
                return km(d.runWkM);
            case BIKE_WK:
                return km(d.bikeWkM);
            case RHR:
                return [str(d.rhr), "", null, null];
            case SLEEP:
                return [str(d.sleepScore), "", null, null];
            case UTC:
                return [d.utcTime, "Z", null, null];
            case VIS:
                return km(d.visM);
            case POP:
                return [str(d.pop), "%", null, null];
        }
        return [d.sunTime, "", null, null];
    }

    function str(n as Number?) as String? {
        return n != null ? n.toString() : null;
    }

    function progress(v as Number?, goal as Number?) as Float? {
        return v != null && goal != null && goal > 0 ? v.toFloat() / goal : null;
    }

    // Shorter forms of a count from 1,000 up: 23456 -> ["23.5K", "23K"].
    function kilo(n as Number?) as Array<String>? {
        if (n == null || n < 1000) { return null; }
        return [(n / 1000.0).format("%.1f") + "K", ((n + 500) / 1000).toString() + "K"];
    }

    // Metres as km: one decimal under 100 km ("8.4", shorter form "8"), whole km from 100 up.
    function km(m as Float?) as Array {
        if (m == null) { return [null, "KM", null, null]; }
        var k = m / 1000.0;
        var whole = (k + 0.5).toNumber().toString();
        if (k < 99.95) { return [k.format("%.1f"), "KM", null, [whole]]; }
        return [whole, "KM", null, null];
    }

    // GAUGE slots: [label, value 0..100 or null, colour]. Only fields with a 0..100 scale have a case; any
    // other field returns a null value (the gauge shows "--"). Colours: STRESS rises into amber / red at
    // 51 / 76 (Garmin's medium and high stress); BB and BATTERY fall into amber / red (battery red = BINGO).
    function gauge(id as Number, d as Data) as Array {
        var v = null;
        var col = Col.HUD;
        switch (id) {
            case STRESS:
                v = d.stress;
                if (v != null) { col = v >= 76 ? Col.RED : v >= 51 ? Col.AMBER : v >= 26 ? Col.HUD : Col.CYAN; }
                return ["STR", v, col];
            case BB:
                v = d.bodyBattery;
                if (v != null) { col = v <= 10 ? Col.RED : v <= 25 ? Col.AMBER : Col.HUD; }
                return ["BB", v, col];
            case BATTERY:
                v = batteryPct(d);
                col = v <= 10 ? Col.RED : v <= 20 ? Col.AMBER : Col.HUD;
                return ["BAT", v, col];
            case SPO2:
                return ["O2", d.spo2, Col.HUD];   // gauge labels: 3 characters at most
            case SLEEP:
                v = d.sleepScore;
                if (v != null && v < 60) { col = Col.AMBER; }   // Garmin: under 60 = poor
                return ["SLP", v, col];
            case STEPS:
                return ["STP", percent(d.steps, d.stepGoal), Col.HUD];
            case FLOORS:
                return ["FLR", percent(d.floors, d.floorsGoal), Col.HUD];
            case ACT_MIN:
                return ["ACT", percent(d.actMin, d.actGoal), Col.HUD];
        }
        return ["", null, Col.UNIT];
    }

    // Fields the gauge can show (a gauge() case above): 0..100 values and % of a goal.
    function gaugeable(id as Number) as Boolean {
        return id == STRESS || id == BB || id == BATTERY || id == SPO2 || id == SLEEP
            || id == STEPS || id == FLOORS || id == ACT_MIN;
    }

    // Whole percent of a goal (may pass 100: the bar stops full, the number keeps counting).
    function percent(v as Number?, goal as Number?) as Number? {
        return v != null && goal != null && goal > 0 ? (v * 100 + goal / 2) / goal : null;
    }

    function batteryPct(d as Data) as Number {
        return (d.battery + 0.5).toNumber();
    }
}
