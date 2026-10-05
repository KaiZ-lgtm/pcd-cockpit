import Toybox.Lang;

// A place on the face that shows one Field (requirements §3.5): the data row's three cells, the date
// block's right column, the bottom row and (454 px layout, Layout.GAUGE) the gauge above it.
// Layout.slots lists them per device; PcdView draws them and PcdDelegate hit-tests them from the same
// list, so drawing and tapping always agree. `field` is what a settings page would change.
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
    var bar as Boolean;           // may show a progress bar under the value (PcdView.SHOW_BARS)
    var warn as Boolean;          // BINGO / STRESS warnings replace this slot while active

    function initialize(style_ as Number, field_ as Number, x_ as Number, w_ as Number, hb_ as Number,
                        vb_ as Number, hit_ as Array<Number>, bar_ as Boolean, warn_ as Boolean) {
        style = style_; field = field_; x = x_; w = w_; hb = hb_; vb = vb_;
        hit = hit_; bar = bar_; warn = warn_;
    }
}
