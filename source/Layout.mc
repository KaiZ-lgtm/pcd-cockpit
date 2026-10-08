import Toybox.Lang;

// Pixel layout per device, relative to the screen centre (requirements §3). Started from `PF` / `PV` in
// mockup_final.html; the tapes, time row and date block have since moved and no longer match the mockup.
class Layout {
    var big as Boolean;
    // Station model (top cap): circle at y = stY, text stH px, barb length, text clear of the circle centre,
    // weather symbol scale symK, symGap left of the temperatures and symDy below the circle centre.
    var stY as Number, stR as Number, stH as Number, barb as Number, clear as Number, symK as Float, symGap as Number,
        symDy as Number;
    // Date block above the time: two columns centred on x = ∓dsX, line baselines dsY1 / dsY2. Left: weekday
    // over MM/DD (dateH px). Right: a slot, the lunar date by default (lunH px).
    var dateH as Number, lunH as Number, dsY1 as Number, dsY2 as Number, dsX as Number;
    // Middle row: the time and both tape boxes are centred at y = boxY. Tape value box outer edge at
    // x = ±boxOut (near the bezel); the vertical spine runs at x = ±tapeX, behind the box (the box covers
    // it), ±tapeHalf px around boxY: past the bezel, so the round display cuts it off at the edge. One tick
    // every tickPx px (altitude) or hrTickPx px (heart rate).
    var timeH as Number;
    var boxY as Number, boxOut as Number, boxW as Number, boxH as Number, boxV as Number, tapeUnitH as Number;
    var tapeX as Number, tapeHalf as Number, tickPx as Number, hrTickPx as Number, tickMajor as Number, tickMinor as Number;
    // Data row: top y pY, height pH, spanning ±pX; cells of the two data window widths (narrow winN,
    // wide winW). Text sizes: header hdrH (baseline hdrB below pY), value valH, unit unitH.
    var pY as Number, pH as Number, pX as Number, hdrB as Number, valH as Number, hdrH as Number, unitH as Number;
    var winN as Number, winW as Number;
    var cellW as Array<Number>;   // data row cell widths, left to right (sum = 2 * pX); dividers sit between
    // Bottom: warning box (botY, botH, botW; label tabH px) and the sun row's value baseline sunB.
    var botY as Number, botH as Number, botW as Number, tabH as Number, sunB as Number;
    // Widest bottom row (header + value + unit) that stays inside the bezel: the sun row "SS>1856" is
    // 146 px on the fēnix (its lower right corner ~2 px inside the bezel) and 132 px on the Venu 3S (Fit.row).
    var rowW as Number = 150;
    // Everything that shows a Field (Slots.mc), in tap-test order. The fields come from Settings; the
    // layout is rebuilt when they change (PcdView.applySettings).
    var slots as Array<Slot>;

    // Gauge row between the data row and the bottom row (454 px layout only; the 390 px Venu 3S has no room).
    // On: the bottom row moves down towards the bezel and the gauge takes its old place. Its field is the
    // phone setting gaugeField (Field.gaugeable, stress by default).
    const GAUGE = true;
    var gauge as Boolean = false;
    // Gauge geometry: bar bottom gB, bar gW px wide; label and value gValH px, top-aligned with the bar. The
    // label's left end must stay inside the bezel: at most 3 characters.
    var gB as Number = 0, gW as Number = 0, gValH as Number = 14;

    function initialize(width as Number) {
        big = width >= 420;
        if (big) {
            // fēnix 8 47mm, 454 px
            stY = -174; stR = 13; stH = 25; barb = 25; clear = 46; symK = 1.6; symGap = 22; symDy = 10;
            dateH = 30; lunH = 36; dsY1 = -104; dsY2 = -62; dsX = 74;
            timeH = 94;
            boxY = 1; boxOut = 216; boxW = 60; boxH = 50; boxV = 20; tapeUnitH = 11;
            tapeX = 184; tapeHalf = 140; tickPx = 15; hrTickPx = 22; tickMajor = 12; tickMinor = 7;
            pY = 72; pH = 86; pX = 172; hdrB = 21; valH = 34; hdrH = 16; unitH = 16;
            winN = 100; winW = 144;   // condensed fonts: BB "100", SPO2 "100%", ACT MIN "150/150" all fit
            botY = 168; botH = 30; botW = 124; tabH = 20; sunB = 203;
        } else {
            // Venu 3S, 390 px
            stY = -152; stR = 11; stH = 21; barb = 20; clear = 38; symK = 1.35; symGap = 18; symDy = 8;
            dateH = 25; lunH = 29; dsY1 = -86; dsY2 = -51; dsX = 62;
            timeH = 74;
            boxY = 1; boxOut = 184; boxW = 58; boxH = 46; boxV = 18; tapeUnitH = 10;
            tapeX = 156; tapeHalf = 124; tickPx = 13; hrTickPx = 19; tickMajor = 10; tickMinor = 6;
            pY = 60; pH = 78; pX = 146; hdrB = 19; valH = 29; hdrH = 16; unitH = 16;
            winN = 80; winW = 132;    // condensed fonts: BB "100", ACT MIN "150/150"; SPO2 "100" drops the %
            botY = 150; botH = 28; botW = 120; tabH = 18; sunB = 177;
            rowW = 140;
        }
        cellW = [winN, winN, winW];

        gauge = GAUGE && big;
        var cellsEnd = botY - 6;   // bottom of the data cells' tap areas
        var rowTop = botY - 6;     // top of the bottom row's tap area
        if (gauge) {
            // Bottom row down 9 px, as far as it goes: the value's lower right corner is ~2 px inside the
            // bezel. The warning box follows it (same offset to the value as before). The gauge sits in the
            // freed band.
            sunB = 212; botY = 177;
            gB = 170; gW = 199;    // bar bottom; 10 segments of 19 px with 1 px gaps
            cellsEnd = pY + pH;
            rowTop = sunB - valH - 2;
        }

        // Bottom row first: its tap area reaches below the data row.
        var fields = Settings.fields;
        slots = [new Slot(Slot.ROW, fields[Settings.BOTTOM], 0, 0, 0, sunB,
                          [-botW / 2 - 12, rowTop, botW / 2 + 12, 999], false, true)] as Array<Slot>;
        if (gauge) {
            slots.add(new Slot(Slot.GAUGE, fields[Settings.GAUGE], 0, gW, 0, gB, [-130, cellsEnd, 130, rowTop], false, false));
        }
        // Data row: narrow, narrow, wide.
        var styles = [Slot.NARROW, Slot.NARROW, Slot.WIDE];
        var left = -pX;
        for (var i = 0; i < 3; i++) {
            var w = cellW[i];
            slots.add(new Slot(styles[i], fields[Settings.DATA1 + i], left + w / 2, w, pY + hdrB, pY + pH - 16,
                               [left, pY - 6, left + w, cellsEnd], true, false));
            left += w;
        }
        // Date block right column: a wide cell whose value sits on the MM/DD baseline.
        slots.add(new Slot(Slot.WIDE, fields[Settings.DATE], dsX, winW, dsY2 - valH - 14, dsY2,
                           [1, dsY2 - valH - 34, dsX + winW / 2, dsY2 + 9], false, false));
    }
}
