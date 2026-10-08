import Toybox.Application;
import Toybox.Lang;

// Phone settings (resources/settings/, SETTINGS.md): what each slot shows and the progress bars. The
// values are Field ids stored in the wearer's settings, so Field enum values must never be renumbered.
// Anything missing, of the wrong type or not allowed in its slot falls back to the default, which is
// the look of the build before settings existed.
module Settings {
    // Slots that take a field, in KEYS order: data row left / middle / right, date block right column,
    // bottom row, gauge (454 px layout only; ignored on the Venu 3S).
    enum { DATA1, DATA2, DATA3, DATE, BOTTOM, GAUGE }
    const KEYS = ["field1", "field2", "field3", "dateField", "bottomField", "gaugeField"] as Array<String>;
    const DEFAULTS = [Field.BB, Field.SPO2, Field.ACT_MIN, Field.LUNAR, Field.SUN, Field.STRESS] as Array<Number>;

    var fields as Array<Number> = [Field.BB, Field.SPO2, Field.ACT_MIN, Field.LUNAR, Field.SUN, Field.STRESS] as Array<Number>;
    var showBars as Boolean = false;
    // Font style: 0 = D chamfered, 1 = G small rounded (default), 2 = E large rounded (PcdView.fontIds).
    var fontStyle as Number = 1;

    function load() as Void {
        var f = [] as Array<Number>;
        for (var i = 0; i < KEYS.size(); i++) { f.add(pick(i, read(KEYS[i]))); }
        fields = f;
        var b = read("showBars");
        showBars = b instanceof Boolean ? b : false;
        fontStyle = pickStyle(read("fontStyle"));
    }

    function pickStyle(v as PropertyValueType?) as Number {
        return v instanceof Number && v >= 0 && v <= 2 ? v : 1;
    }

    function read(key as String) as PropertyValueType? {
        try {
            return Properties.getValue(key);
        } catch (e) {
            return null;
        }
    }

    // The saved value if it is a field this slot can show, else the slot's default.
    function pick(slot as Number, v as PropertyValueType?) as Number {
        if (v instanceof Number && allowed(slot, v)) { return v; }
        return DEFAULTS[slot];
    }

    // The lunar date only fits the date block; fields whose value needs a wide cell stay out of the two
    // narrow data windows; the gauge takes 0..100 fields and % of a goal (Field.gaugeable).
    function allowed(slot as Number, id as Number) as Boolean {
        if (id == Field.LUNAR) { return slot == DATE; }
        if (id < 0 || id >= Field.COUNT) { return false; }
        if (slot == GAUGE) { return Field.gaugeable(id); }
        if (slot == BOTTOM) { return Field.rowOk(id); }
        if (slot == DATA1 || slot == DATA2) { return !Field.wide(id); }
        return true;
    }
}
