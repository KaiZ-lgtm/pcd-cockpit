import Toybox.Complications;
import Toybox.Lang;

// What a Slot can show (requirements §3.5). Adding a field = one enum value plus a case in each function
// below (and in gauge() if it is a 0-100 value); a settings page would only change Slot.field in Layout.slots.
module Field {
    enum { BB, SPO2, ACT_MIN, SUN, STRESS, BATTERY }

    // Lunar date: only valid in the date block's right column (drawn in CJK, not as header + value).
    const LUNAR = -1;

    // Header with the soft-key arrow, e.g. "BB>".
    function header(id as Number, d as Data) as String {
        switch (id) {
            case BB: return "BB>";
            case SPO2: return "SPO2>";
            case ACT_MIN: return "ACT MIN>";
            case STRESS: return "STRESS>";
            case BATTERY: return "BAT>";
        }
        return d.sunIsSet ? "SS>" : "SR>";
    }

    // [value string or null, unit string, progress 0..1 or null (no goal: no bar)].
    function read(id as Number, d as Data) as Array {
        switch (id) {
            case BB:
                return [d.bodyBattery != null ? d.bodyBattery.toString() : null, "", null];
            case SPO2:
                return [d.spo2 != null ? d.spo2.toString() : null, "%", null];
            case ACT_MIN:
                var am = d.actMin, goal = d.actGoal;
                var frac = null;
                if (am != null && goal != null && goal > 0) { frac = am.toFloat() / goal; }
                return [am != null ? am.toString() : null, goal != null ? "/" + goal.toString() : "", frac];
            case STRESS:
                return [d.stress != null ? d.stress.toString() : null, "", null];
            case BATTERY:
                return [batteryPct(d).toString(), "%", null];
        }
        return [d.sunTime, "", null];
    }

    // GAUGE slots: [label, value 0..100 or null, colour]. Only fields with a 0..100 scale have a case; any
    // other field returns a null value (the gauge shows "--"). Colours: STRESS rises into amber / red at
    // the STRESS warning thresholds; BB and BATTERY fall into amber / red (battery red = BINGO).
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
        }
        return ["", null, Col.UNIT];
    }

    function batteryPct(d as Data) as Number {
        return (d.battery + 0.5).toNumber();
    }

    // Native page opened when the slot is tapped (null: not tappable).
    function complication(id as Number, d as Data) as Complications.Type? {
        switch (id) {
            case BB: return Complications.COMPLICATION_TYPE_BODY_BATTERY;
            case SPO2: return Complications.COMPLICATION_TYPE_PULSE_OX;
            case ACT_MIN: return Complications.COMPLICATION_TYPE_INTENSITY_MINUTES;
            case SUN: return d.sunIsSet ? Complications.COMPLICATION_TYPE_SUNSET : Complications.COMPLICATION_TYPE_SUNRISE;
            case STRESS: return Complications.COMPLICATION_TYPE_STRESS;
            case BATTERY: return Complications.COMPLICATION_TYPE_BATTERY;
        }
        return null;
    }
}
