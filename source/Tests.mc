import Toybox.Lang;
import Toybox.Math;
import Toybox.Test;

// Unit tests (.\build.ps1 -Test). Compiled only with --unit-test, never into the watch builds.
// The pixel regression test (tools\regress.ps1) covers what the face looks like.

(:test)
function testSettingsDefaultsKeepOldLook(logger as Logger) as Boolean {
    var d = Settings.DEFAULTS;
    return d[Settings.DATA1] == Field.BB && d[Settings.DATA2] == Field.SPO2 && d[Settings.DATA3] == Field.ACT_MIN
        && d[Settings.DATE] == Field.LUNAR && d[Settings.BOTTOM] == Field.SUN && d[Settings.GAUGE] == Field.STRESS;
}

(:test)
function testSettingsPickFallsBack(logger as Logger) as Boolean {
    var ok = true;
    // Missing, wrong type, unknown id: default.
    ok = ok && Settings.pick(Settings.DATA1, null) == Field.BB;
    ok = ok && Settings.pick(Settings.DATA1, "4") == Field.BB;
    ok = ok && Settings.pick(Settings.DATA1, 4.0) == Field.BB;
    ok = ok && Settings.pick(Settings.DATA1, 999) == Field.BB;
    ok = ok && Settings.pick(Settings.DATA1, -7) == Field.BB;
    // Valid choice is kept.
    ok = ok && Settings.pick(Settings.DATA1, Field.STRESS) == Field.STRESS;
    ok = ok && Settings.pick(Settings.BOTTOM, Field.BATTERY) == Field.BATTERY;
    return ok;
}

(:test)
function testSettingsSlotRules(logger as Logger) as Boolean {
    var ok = true;
    // Lunar date: date block only.
    ok = ok && Settings.allowed(Settings.DATE, Field.LUNAR);
    ok = ok && !Settings.allowed(Settings.DATA3, Field.LUNAR) && !Settings.allowed(Settings.BOTTOM, Field.LUNAR);
    // Wide fields stay out of the narrow windows.
    ok = ok && !Settings.allowed(Settings.DATA1, Field.SUN) && !Settings.allowed(Settings.DATA2, Field.SUN);
    ok = ok && Settings.allowed(Settings.DATA3, Field.SUN) && Settings.allowed(Settings.DATE, Field.SUN);
    ok = ok && Settings.pick(Settings.DATA2, Field.SUN) == Field.SPO2;
    ok = ok && !Settings.allowed(Settings.DATA1, Field.STEPS) && !Settings.allowed(Settings.DATA2, Field.KCAL);
    ok = ok && !Settings.allowed(Settings.DATA1, Field.ACT_MIN) && Settings.allowed(Settings.DATA3, Field.STEPS);
    ok = ok && Settings.allowed(Settings.BOTTOM, Field.KCAL) && Settings.allowed(Settings.DATA1, Field.DIST);
    ok = ok && !Settings.allowed(Settings.BOTTOM, Field.ACT_MIN) && Settings.allowed(Settings.DATE, Field.ACT_MIN);
    ok = ok && Settings.pick(Settings.DATA3, Field.LUNAR) == Field.ACT_MIN;
    // Gauge: 0..100 fields and % of a goal only.
    ok = ok && Settings.allowed(Settings.GAUGE, Field.SLEEP) && Settings.allowed(Settings.GAUGE, Field.STEPS);
    ok = ok && !Settings.allowed(Settings.GAUGE, Field.DIST) && !Settings.allowed(Settings.GAUGE, Field.LUNAR);
    ok = ok && Settings.pick(Settings.GAUGE, Field.UTC) == Field.STRESS;
    return ok;
}

// Every field id listed in the phone form must be one Settings accepts somewhere, and the enum must not
// have been renumbered (ids are stored in the wearer's settings).
(:test)
function testFieldIdsStable(logger as Logger) as Boolean {
    return Field.BB == 0 && Field.SPO2 == 1 && Field.ACT_MIN == 2 && Field.SUN == 3 && Field.STRESS == 4
        && Field.BATTERY == 5 && Field.STEPS == 6 && Field.FLOORS == 7 && Field.FLOORS_DN == 8 && Field.KCAL == 9
        && Field.DIST == 10 && Field.ACT_DAY == 11 && Field.CLIMB == 12 && Field.VO2_RUN == 13
        && Field.VO2_BIKE == 14 && Field.RUN_WK == 15 && Field.BIKE_WK == 16 && Field.RHR == 17
        && Field.SLEEP == 18 && Field.UTC == 19 && Field.VIS == 20 && Field.POP == 21 && Field.COUNT == 22
        && Field.LUNAR == -1;
}

function sameStrings(a as Array<String>?, b as Array<String>?) as Boolean {
    if (a == null || b == null) { return a == null && b == null; }
    if (a.size() != b.size()) { return false; }
    for (var i = 0; i < a.size(); i++) { if (!a[i].equals(b[i])) { return false; } }
    return true;
}

(:test)
function testFieldFormats(logger as Logger) as Boolean {
    var ok = true;
    // Counts: shorter forms only from 1,000 up.
    ok = ok && Field.kilo(null) == null && Field.kilo(999) == null;
    ok = ok && sameStrings(Field.kilo(9876), ["9.9K", "10K"]);
    ok = ok && sameStrings(Field.kilo(23456), ["23.5K", "23K"]);
    // Distances: one decimal under 100 km, shorter form whole km.
    var k = Units.dist(8420.0, false, false);
    ok = ok && "8.4".equals(k[0]) && "KM".equals(k[1]) && sameStrings(k[3] as Array<String>?, ["8"]);
    k = Units.dist(123400.0, false, false);
    ok = ok && "123".equals(k[0]) && k[3] == null;
    ok = ok && Units.dist(null, false, false)[0] == null;
    // Steps value, goal progress and shorter forms.
    var d = new Data();
    d.steps = 12345; d.stepGoal = 10000;
    var r = Field.read(Field.STEPS, d);
    ok = ok && "12345".equals(r[0]) && (r[2] as Float) > 1.2 && sameStrings(r[3] as Array<String>?, ["12.3K", "12K"]);
    // No data: null value (drawn as "--"), no bar.
    d.steps = null;
    r = Field.read(Field.STEPS, d);
    ok = ok && r[0] == null && r[2] == null;
    // UTC: value plus Z.
    d.utcTime = "1442";
    r = Field.read(Field.UTC, d);
    ok = ok && "1442".equals(r[0]) && "Z".equals(r[1]);
    return ok;
}

// The widest values each field can show (as the demo build's odd steps). Distances just under 100 km or
// 100 mi (one decimal), 1,000 a week by bike.
function widestData(imp as Boolean) as Data {
    var d = new Data();
    d.bodyBattery = 100; d.spo2 = 100; d.stress = 100; d.actMin = 999; d.actGoal = 150; d.battery = 100.0;
    d.sunIsSet = true; d.sunTime = "2359";
    // Steps from 99,500 would shorten to 100K, too wide for a narrow cell: not a real day.
    d.steps = 99499; d.stepGoal = 10000; d.floors = 999; d.floorsGoal = 10; d.floorsDn = 999; d.kcal = 9999;
    var u = imp ? Units.M_PER_MI : 1000.0;
    d.distM = 99.94 * u; d.actDay = 999; d.climbM = 9999.0; d.vo2Run = 99; d.vo2Bike = 99;
    d.runWkM = 99.94 * u; d.bikeWkM = 999.4 * u; d.rhr = 199; d.sleepScore = 100; d.visM = 99.94 * u; d.pop = 100;
    d.utcTime = "2359";
    return d;
}

// Every field fits every slot it is allowed in, on both layouts and in both unit systems, with its widest
// value: cell header within w - 10, value + unit within w - 12; bottom row within Layout.rowW. Uses the
// condensed G advances.
(:test)
function testEveryFieldFits(logger as Logger) as Boolean {
    Stroke.setAdvances([9.8, 8.1, 5.1, 5.55, 3.7]);
    var ok = true;
    var lays = [new Layout(454), new Layout(390)];
    for (var u = 0; u < 2; u++) {
        Settings.imperial = u == 1;
        var d = widestData(Settings.imperial);
        for (var li = 0; li < lays.size(); li++) { ok = fieldsFit(logger, lays[li], d) && ok; }
    }
    Settings.imperial = false;
    return ok;
}

function fieldsFit(logger as Logger, L as Layout, d as Data) as Boolean {
    var ok = true;
    var tag = Settings.imperial ? " (imperial)" : "";
    for (var id = 0; id < Field.COUNT; id++) {
        var r = Field.read(id, d);
        var hdr = Field.header(id, d);
        var cells = Field.wide(id) ? [L.winW] : [L.winN, L.winW];
        for (var c = 0; c < cells.size(); c++) {
            var w = cells[c];
            var f = Fit.cell(id, hdr, r[0] as String?, r[1] as String, r[3] as Array<String>?, w, L);
            var hw = Stroke.width(f[0] as String, L.hdrH);
            var vw = Stroke.width(f[1] as String, L.valH) + Fit.unitWidth(f[2] as String, L);
            if (hw > w - 10 || vw > w - 12) {
                logger.error("field " + id + tag + " in a " + w + " px cell: " + f[0] + " " + f[1] + f[2] + " (" + hw + " / " + vw + " px)");
                ok = false;
            }
        }
        var f = Fit.row(id, hdr, r[0] as String?, r[1] as String, r[3] as Array<String>?, L);
        var rw = Fit.rowWidth(f, L);
        if (rw > L.rowW) {
            logger.error("field " + id + tag + " in the bottom row (" + L.rowW + " px): " + f[0] + " " + f[1] + f[2] + " (" + rw + " px)");
            ok = false;
        }
    }
    return ok;
}

// The default bottom row (sun event) keeps its full header and value: the look before settings existed.
(:test)
function testDefaultRowUnchanged(logger as Logger) as Boolean {
    Stroke.setAdvances([9.8, 8.1, 5.1, 5.55, 3.7]);
    var d = new Data();
    d.sunIsSet = true; d.sunTime = "1856";
    var ok = true;
    var lays = [new Layout(454), new Layout(390)];
    for (var i = 0; i < lays.size(); i++) {
        var f = Fit.row(Field.SUN, "SS>", "1856", "", null, lays[i]);
        ok = ok && "SS>".equals(f[0]) && "1856".equals(f[1]) && "".equals(f[2]);
    }
    return ok;
}

(:test)
function testLayoutDefaultSlots(logger as Logger) as Boolean {
    var ok = true;
    Settings.fields = Settings.DEFAULTS;   // not whatever the simulator's saved settings loaded
    var big = new Layout(454);
    var sm = new Layout(390);
    // fēnix: bottom row, gauge, three data windows, date block.
    var want = [Field.SUN, Field.STRESS, Field.BB, Field.SPO2, Field.ACT_MIN, Field.LUNAR];
    ok = ok && big.slots.size() == want.size();
    for (var i = 0; ok && i < want.size(); i++) { ok = big.slots[i].field == want[i]; }
    // Venu 3S: no gauge.
    var want2 = [Field.SUN, Field.BB, Field.SPO2, Field.ACT_MIN, Field.LUNAR];
    ok = ok && sm.slots.size() == want2.size();
    for (var i = 0; ok && i < want2.size(); i++) { ok = sm.slots[i].field == want2[i]; }
    if (!ok) { logger.error("default slot fields changed"); }
    return ok;
}

(:test)
function testLunarDates(logger as Logger) as Boolean {
    var cases = [
        [2026, 9, 29, "八月十九"],
        [2026, 12, 9, "冬月初一"],
        [2027, 1, 8, "腊月初一"],
        [2027, 2, 5, "腊月廿九"],    // 2026 / 2027 correction (Lunar.mc): ICU had 02-06 = 腊月三十
        [2027, 2, 6, "正月初一"],
        [2027, 3, 7, "正月三十"],
        [2027, 3, 8, "二月初一"],
        [2028, 1, 26, "正月初一"],
        [2025, 7, 25, "闰六月初一"],
        [2026, 12, 31, "冬月廿三"]
    ];
    var ok = true;
    for (var i = 0; i < cases.size(); i++) {
        var c = cases[i];
        var got = Lunar.format(c[0] as Number, c[1] as Number, c[2] as Number);
        logger.debug(c[0] + "-" + c[1] + "-" + c[2] + " -> " + got);
        if (got == null || !got.equals(c[3])) { logger.error("want " + c[3]); ok = false; }
    }
    return ok;
}

// Every gaugeable field has a label of at most 3 characters (its left end must stay inside the bezel) and
// a value with the widest data; % of a goal may pass 100.
(:test)
function testGaugeFields(logger as Logger) as Boolean {
    var d = widestData(false);
    var ok = true;
    for (var id = 0; id < Field.COUNT; id++) {
        if (!Field.gaugeable(id)) { continue; }
        var g = Field.gauge(id, d);
        var lab = g[0] as String;
        if (lab.length() == 0 || lab.length() > 3 || g[1] == null) {
            logger.error("gauge field " + id + ": label '" + lab + "', value " + g[1]);
            ok = false;
        }
    }
    ok = ok && Field.percent(8642, 10000) == 86 && Field.percent(12345, 10000) == 123 && Field.percent(5, null) == null;
    return ok;
}

// The per-field tables have one entry per field; every field but SUN (dynamic) has a header.
(:test)
function testFieldTables(logger as Logger) as Boolean {
    var ok = Field.HEADERS.size() == Field.COUNT && Field.SHORTS.size() == Field.COUNT && Field.TAPS.size() == Field.COUNT;
    for (var id = 0; ok && id < Field.COUNT; id++) {
        if (id != Field.SUN && Field.HEADERS[id] == null) { logger.error("no header for field " + id); ok = false; }
    }
    // Spot checks against the order of the enum.
    ok = ok && "KCAL>".equals(Field.HEADERS[Field.KCAL]) && "Z>".equals(Field.SHORTS[Field.UTC]) && Field.TAPS[Field.UTC] == null;
    return ok;
}

// Units setting: metric unless the stored value is 1; every drawn unit converts, wind does not (knots).
(:test)
function testUnits(logger as Logger) as Boolean {
    var ok = !Settings.pickImperial(null) && !Settings.pickImperial(0) && Settings.pickImperial(1)
        && !Settings.pickImperial(2) && !Settings.pickImperial("1") && !Settings.pickImperial(true);
    // Station model: whole degrees, pressure 1013 hPa / 29.92 inHg.
    ok = ok && "18".equals(Units.temp(18.0, false)) && "64".equals(Units.temp(18.0, true));
    ok = ok && "-12".equals(Units.temp(-12.0, false)) && "10".equals(Units.temp(-12.0, true));
    ok = ok && "-40".equals(Units.temp(-40.0, true)) && "--".equals(Units.temp(null, true));
    ok = ok && "1013".equals(Units.pressure(101325.0, false)) && "29.92".equals(Units.pressure(101325.0, true));
    ok = ok && "--".equals(Units.pressure(null, true));
    // Altitude tape: tens of metres (125 = 1,250 m) or hundreds of feet (41 = 4,100 ft), clamped.
    var a = Units.altTape(1250.0, false);
    ok = ok && (a[0] as Float) == 125.0 && a[1] == 2 && a[2] == 10 && "10M".equals(a[3]);
    a = Units.altTape(1250.0, true);
    ok = ok && Math.round(a[0] as Float).toNumber() == 41 && a[1] == 1 && a[2] == 5 && "100 FT".equals(a[3]);
    ok = ok && (Units.altTape(99999.0, true)[0] as Float) == 999.0 && Units.altTape(null, true)[0] == null;
    // Distances in miles, visibility in statute miles, climb in feet.
    var k = Units.dist(8420.0, true, false);
    ok = ok && "5.2".equals(k[0]) && "MI".equals(k[1]) && sameStrings(k[3] as Array<String>?, ["5"]);
    k = Units.dist(16093.44, true, true);
    ok = ok && "10.0".equals(k[0]) && "SM".equals(k[1]);
    ok = ok && "MI".equals(Units.dist(null, true, false)[1]);
    var c = Units.climb(312.0, true);
    ok = ok && c[0] == 1024 && "FT".equals(c[1]) && Units.climb(312.0, false)[0] == 312;
    // Through Field.read with the setting on.
    var d = new Data();
    d.climbM = 312.0; d.visM = 4800.0;
    Settings.imperial = true;
    var r = Field.read(Field.CLIMB, d);
    ok = ok && "1024".equals(r[0]) && "FT".equals(r[1]);
    r = Field.read(Field.VIS, d);
    ok = ok && "3.0".equals(r[0]) && "SM".equals(r[1]);
    Settings.imperial = false;
    r = Field.read(Field.CLIMB, d);
    ok = ok && "312".equals(r[0]) && "M".equals(r[1]);
    return ok;
}

(:test)
function testFontStyleFallback(logger as Logger) as Boolean {
    return Settings.pickStyle(null) == 1 && Settings.pickStyle(0) == 0 && Settings.pickStyle(2) == 2
        && Settings.pickStyle(3) == 1 && Settings.pickStyle(-1) == 1 && Settings.pickStyle("2") == 1;
}
