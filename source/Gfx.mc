import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

// Colours (requirements §2).
module Col {
    const HUD = 0x33FF66;
    const WHITE = 0xFFFFFF;
    const CYAN = 0x33E0FF;
    const AMBER = 0xFFC21A;
    const RED_DIM = 0xB02222;
    const RED = 0xFF3030;
    const DIVIDER = 0x5A5A5A;
    const UNIT = 0x8A8A8A;
    const BARB = 0xA0A0A0;
    const CHANCE = 0x6F6F6F;
    const BAR_BG = 0x1C1C1C;
    const GAUGE_OFF = 0x3A3A3A;   // empty gauge segments (outline)
    const AOD_TIME = 0x28C050;    // always-on time (was 0x1FA045)
    const AOD_DATE = 0xA8A8A8;    // always-on date (was the 0x8A8A8A unit gray)
    const LUNAR = 0xE040E0;       // magenta (F-35 PCD route / cue colour), lunar date
    const AOD_LUNAR = 0x8A2A8A;   // dimmed magenta for always-on (0x4A4A4A gray was too dark to read)
}

// Low-level drawing helpers. All coordinates are absolute screen pixels.
module Gfx {
    // Device pen widths are whole pixels; the mockup's fractional widths round to nearest.
    function pen(sw as Numeric) as Number {
        var p = (sw + 0.5).toNumber();
        return p < 1 ? 1 : p;
    }

    // Strokes thinner than this are drawn as 1 px hairlines (ticks, spine, dividers).
    const HAIRLINE = 1.5;
    // Strokes at least this wide are filled polygons; thinner ones use native drawLine
    // (one call, no allocation - polygons for everything exceed the watchdog budget).
    const WIDE = 3.5;

    // Start a stroke run: returns the half-width for seg(), or a negative value meaning
    // "use drawLine" (the pen width has then been set). Colour must already be set.
    function strokeMode(dc as Dc, sw as Numeric) as Float {
        if (sw >= WIDE) { return sw / 2.0; }
        dc.setPenWidth(pen(sw));
        return -1.0;
    }

    // Segment in the mode returned by strokeMode().
    function segOrLine(dc as Dc, x1 as Numeric, y1 as Numeric, x2 as Numeric, y2 as Numeric, hw as Float) as Void {
        if (hw < 0) { dc.drawLine(x1, y1, x2, y2); } else { seg(dc, x1, y1, x2, y2, hw); }
    }

    // Wide strokes are filled polygons of exact (fractional) width. drawLine + fillCircle
    // joints cannot be matched on device (the AA line renders thinner than its pen and small
    // circle radii round up), which leaves bumps at every vertex.

    // One segment of half-width hw with half-octagon end caps, as a single polygon, so
    // consecutive segments overlap cleanly at joints (no separate joint shapes needed).
    // Colour must already be set.
    function seg(dc as Dc, x1 as Numeric, y1 as Numeric, x2 as Numeric, y2 as Numeric, hw as Float) as Void {
        var dx = x2 - x1, dy = y2 - y1;
        var len = Math.sqrt(dx * dx + dy * dy);
        if (len < 0.01) { return; }
        var ux = dx / len, uy = dy / len;
        var nx = -uy * hw, ny = ux * hw;          // normal, full half-width
        var ex = ux * hw, ey = uy * hw;            // cap depth
        var cx = -uy * hw * 0.414, cy = ux * hw * 0.414;   // chamfer offset (octagon side)
        dc.fillPolygon([
            [x1 + nx, y1 + ny], [x2 + nx, y2 + ny],
            [x2 + cx + ex, y2 + cy + ey], [x2 - cx + ex, y2 - cy + ey],
            [x2 - nx, y2 - ny], [x1 - nx, y1 - ny],
            [x1 - cx - ex, y1 - cy - ey], [x1 + cx - ex, y1 + cy - ey]
        ]);
    }

    function line(dc as Dc, x1 as Numeric, y1 as Numeric, x2 as Numeric, y2 as Numeric, col as Number, sw as Numeric) as Void {
        poly(dc, [x1, y1, x2, y2], col, sw, false);
    }

    // Polyline through flat [x0, y0, x1, y1, ...].
    function poly(dc as Dc, pts as Array<Numeric>, col as Number, sw as Numeric, closed as Boolean) as Void {
        dc.setColor(col, Graphics.COLOR_TRANSPARENT);
        var n = pts.size();
        var hw = strokeMode(dc, sw < HAIRLINE ? 1 : sw);
        for (var i = 2; i + 1 < n; i += 2) {
            segOrLine(dc, pts[i - 2], pts[i - 1], pts[i], pts[i + 1], hw);
        }
        if (closed && n >= 4) { segOrLine(dc, pts[n - 2], pts[n - 1], pts[0], pts[1], hw); }
    }

    function fillPoly(dc as Dc, pts as Array<Numeric>, col as Number) as Void {
        var n = pts.size() / 2;
        var arr = new Array<Array<Numeric> >[n];
        for (var i = 0; i < n; i++) {
            arr[i] = [pts[2 * i], pts[2 * i + 1]];
        }
        dc.setColor(col, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(arr as Array<Graphics.Point2D>);
    }

    function circle(dc as Dc, x as Numeric, y as Numeric, r as Numeric, col as Number, sw as Numeric) as Void {
        dc.setColor(col, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(pen(sw));
        dc.drawCircle(x, y, r);
    }

    function disc(dc as Dc, x as Numeric, y as Numeric, r as Numeric, col as Number) as Void {
        dc.setColor(col, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, r);
    }
}

// One baked glyph atlas (tools/FontGen.java): a white, fully anti-aliased PNG bitmap plus its
// glyph table. Glyph cells are `cellH` tall; the glyph grid origin sits `pad` px inside the cell.
class StrokeFont {
    var bmp as WatchUi.BitmapResource;
    var chars as String;
    var xs as Array<Number>;
    var ys as Array<Number>;
    var ws as Array<Number>;
    var cellH as Number;
    var pad as Number;

    function initialize(bitmap as WatchUi.BitmapResource, table as Dictionary) {
        bmp = bitmap;
        chars = table["c"] as String;
        xs = table["x"] as Array<Number>;
        ys = table["y"] as Array<Number>;
        ws = table["w"] as Array<Number>;
        cellH = table["ch"] as Number;
        pad = table["p"] as Number;
    }
}

// The mockup's single-line vector font. Positioning follows the mockup's S(): monospaced advances
// on an 8 x 12 grid (CJK 12 x 12), h = cap height in px. Glyphs come from StrokeFont atlases and
// are drawn with drawBitmap2 (cropped to the glyph cell, tinted to the text colour).
module Stroke {
    enum { START = -1, MIDDLE = 0, END = 1 }

    // Advances in grid units for Latin, '-', ' ', ':' and '.' (glyphs.json "_adv"; condensed styles are
    // narrower). Set once by setAdvances before drawing.
    var advLatin as Float = 11.0, advDash as Float = 9.0, advSpace as Float = 6.0, advColon as Float = 4.0, advDot as Float = 3.7;

    function setAdvances(a as Array) as Void {
        advLatin = (a[0] as Numeric).toFloat();
        advDash = (a[1] as Numeric).toFloat();
        advSpace = (a[2] as Numeric).toFloat();
        advColon = (a[3] as Numeric).toFloat();
        advDot = a.size() > 4 ? (a[4] as Numeric).toFloat() : advColon;
    }

    function adv(c as Char) as Float {
        if (c.toNumber() >= 0x2E80) { return 15.0; }   // CJK: 12-unit square cell + gap
        if (c == ' ') { return advSpace; }
        if (c == '-') { return advDash; }
        if (c == ':') { return advColon; }
        if (c == '.') { return advDot; }
        return advLatin;
    }

    // Advance in whole pixels: every glyph starts on a pixel boundary (the atlases are hinted
    // for that), and equal characters get equal spacing.
    function advPx(c as Char, h as Numeric) as Number {
        return (adv(c) * h / 12.0 + 0.5).toNumber();
    }

    // Rendered width in pixels at cap height h (ink of the last glyph, not its trailing gap).
    function width(str as String, h as Numeric) as Number {
        var w = 0;
        var cs = str.toCharArray();
        for (var i = 0; i < cs.size(); i++) {
            w += advPx(cs[i], h);
        }
        return w - (3 * h / 12.0 + 0.5).toNumber();
    }

    // Draw str with its baseline at `base`; align is START / MIDDLE / END around x.
    // `font` must be baked at cap height h.
    function draw(dc as Dc, str as String, x as Numeric, base as Numeric, h as Numeric,
                  col as Number, align as Number, font as StrokeFont) as Void {
        var x0 = x.toFloat();
        if (align == MIDDLE) { x0 -= width(str, h) / 2.0; }
        else if (align == END) { x0 -= width(str, h); }
        var xi = (x0 + 0.5).toNumber();
        var y = (base - h - font.pad + 0.5).toNumber();
        var cs = str.toCharArray();
        for (var i = 0; i < cs.size(); i++) {
            var c = cs[i];
            var idx = c == ' ' ? null : font.chars.find(c.toString());
            if (idx != null) {
                // drawBitmap2 places a cropped region at (x + bitmapX, y + bitmapY), so offset by
                // the cell's atlas position to put the cell's corner at the requested point.
                var gx = font.xs[idx], gy = font.ys[idx];
                dc.drawBitmap2(xi - font.pad - gx, y - gy, font.bmp, {
                    :bitmapX => gx, :bitmapY => gy,
                    :bitmapWidth => font.ws[idx], :bitmapHeight => font.cellH,
                    :tintColor => col
                });
            }
            xi += advPx(c, h);
        }
    }

    // Cyan header with underline and soft-key arrow (mockup `hdr`).
    function header(dc as Dc, str as String, x as Numeric, y as Numeric, h as Numeric, font as StrokeFont) as Void {
        var w = width(str, h);
        var x0 = x - w / 2;
        draw(dc, str, x, y, h, Col.CYAN, MIDDLE, font);
        Gfx.line(dc, x0 - 1, y + 4, x0 + w + 1, y + 4, Col.CYAN, 1);
    }
}
