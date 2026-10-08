import Toybox.Lang;

// A place on the face that shows one Field (requirements §3.5): the data row's three cells, the date
// block's right column, the bottom row and (454 px layout, Layout.GAUGE) the gauge above it.
// Layout.slots lists them per device; PcdView draws them and PcdDelegate hit-tests them from the same
// list, so drawing and tapping always agree. `field` comes from the phone settings (Settings.mc).
//
// Four styles:
//   NARROW, WIDE  header over value, centred in a cell of the narrow / wide data window width
//   ROW           header beside the value, both top-aligned (the sunset line)
//   GAUGE         label, 10-segment bar w px wide centred on x, value; for 0..100 fields (Field.gauge)
class Slot {
    enum { NARROW, WIDE, ROW, GAUGE }

    var style as Number;
    var field as Number;          // Field id (Field.LUNAR only in the date block)
    var x as Number;              // centre x, relative to the screen centre
    var w as Number;              // cell width (NARROW / WIDE; a value + unit wider than this drops the unit), bar width (GAUGE)
    var hb as Number;             // header baseline (NARROW / WIDE)
    var vb as Number;             // value baseline (GAUGE: label, bar and value share it)
    var hit as Array<Number>;     // tap rectangle [x0, y0, x1, y1], relative to the screen centre
    var bar as Boolean;           // may show a progress bar under the value (Settings.showBars)
    var warn as Boolean;          // the BINGO warning replaces this slot while active

    function initialize(style_ as Number, field_ as Number, x_ as Number, w_ as Number, hb_ as Number,
                        vb_ as Number, hit_ as Array<Number>, bar_ as Boolean, warn_ as Boolean) {
        style = style_; field = field_; x = x_; w = w_; hb = hb_; vb = vb_;
        hit = hit_; bar = bar_; warn = warn_;
    }
}

// Fitting a field into its slot (pure: no drawing, so the unit tests can check every field in every slot).
// Widths come from Stroke.width at the layout's text sizes.
module Fit {
    // Header over value (NARROW / WIDE cells, w px wide): [header, value, unit]. A header within 10 px of
    // the cell width uses its short form; a value + unit wider than w - 12 drops the unit, then tries the
    // shorter forms of the value in order (Stroke.width omits the stroke overhang; keep ~4 px clear).
    function cell(id as Number, hdr as String, val as String?, unit as String, alts as Array<String>?,
                  w as Number, L as Layout) as Array {
        if (Stroke.width(hdr, L.hdrH) > w - 10) {
            var sh = Field.shortHeader(id);
            if (sh != null) { hdr = sh; }
        }
        if (val == null) { return [hdr, null, ""]; }
        var room = w - 12;
        var vw = Stroke.width(val, L.valH);
        if (vw + unitWidth(unit, L) > room) {
            unit = "";
            for (var i = 0; vw > room && alts != null && i < alts.size(); i++) {
                val = alts[i];
                vw = Stroke.width(val, L.valH);
            }
        }
        return [hdr, val, unit];
    }

    // Header beside value (ROW, the bottom row; at most L.rowW px so it stays inside the bezel):
    // [header, value, unit]. Tries the value with its unit, without it, then its shorter forms, each with
    // the full header and then the short one; falls back to the shortest combination.
    function row(id as Number, hdr as String, val as String?, unit as String, alts as Array<String>?,
                 L as Layout) as Array {
        var hdrs = [hdr];
        var sh = Field.shortHeader(id);
        if (sh != null) { hdrs.add(sh); }
        var v = val != null ? val : "--";
        var vals = [[v, unit], [v, ""]];
        for (var i = 0; val != null && alts != null && i < alts.size(); i++) { vals.add([alts[i], ""]); }
        var best = null;
        for (var i = 0; i < vals.size(); i++) {
            for (var j = 0; j < hdrs.size(); j++) {
                var c = [hdrs[j], vals[i][0], vals[i][1]];
                if (rowWidth(c, L) <= L.rowW) { return c; }
                best = c;
            }
        }
        return best as Array;
    }

    // Width of a ROW: header, 8 px gap, value, unit (as PcdView.drawRow lays it out).
    function rowWidth(c as Array, L as Layout) as Number {
        return Stroke.width(c[0] as String, L.hdrH) + 8 + Stroke.width(c[1] as String, L.valH) + unitWidth(c[2] as String, L);
    }

    function unitWidth(unit as String, L as Layout) as Number {
        return unit.length() > 0 ? Stroke.width(unit, L.unitH) + 4 : 0;
    }
}
