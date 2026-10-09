import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class PcdView extends WatchUi.WatchFace {
    const DAYS = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"] as Array<String>;
    // AOD burn-in shift (§4): every minute x and y each jump 3-5 px (more than the widest AOD
    // stroke), so no pixel stays lit for consecutive minutes. Periods 7 and 5 are coprime, so the
    // combined path repeats only every 35 minutes and never moves parallel to a stroke for long.
    const ORBIT_X = [-3, 0, 3, -1, 2, -2, 1] as Array<Number>;
    const ORBIT_Y = [-3, 0, 3, -1, 2] as Array<Number>;
    // 8-neighbour offsets for the BINGO text halo.
    const HALO_X = [-1, 0, 1, -1, 1, -1, 0, 1] as Array<Number>;
    const HALO_Y = [-1, -1, -1, 0, 0, 1, 1, 1] as Array<Number>;

    var lay as Layout?;
    var data as Data = new Data();
    private var _cx as Number = 0;
    private var _cy as Number = 0;
    private var _w as Number = 0;
    private var _style as Number = -1;   // font style loaded (Settings.fontStyle); -1 = none yet
    private var _sleeping as Boolean = false;
    private var _lunarKey as Number = -1;
    private var _lunarMonth as String? = null;   // e.g. 八月 / 闰六月
    private var _lunarDay as String? = null;     // e.g. 十八 / 初一
    // Baked mockup glyph atlases (tools/FontGen.java), loaded once.
    private var _fTime as StrokeFont?, _fTimeAod as StrokeFont?, _fText as StrokeFont?, _fDate as StrokeFont?, _fDateAod as StrokeFont?;
    private var _fTapeVal as StrokeFont?, _fTapeLbl as StrokeFont?, _fTapeUnit as StrokeFont?, _fGaugeVal as StrokeFont?;
    private var _fHdr as StrokeFont?, _fVal as StrokeFont?, _fUnit as StrokeFont?;
    private var _fTabWarn as StrokeFont?, _fLunar as StrokeFont?;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Dc) as Void {
        _w = dc.getWidth();
        _cx = dc.getWidth() / 2;
        _cy = dc.getHeight() / 2;
        applySettings();
    }

    // Apply Settings: at start and when the phone settings change (PcdApp). Rebuilds the layout (slot
    // positions never change, only their fields) and loads the fonts when the font style changed.
    function applySettings() as Void {
        if (_w == 0) { return; }
        lay = new Layout(_w);
        if (Settings.fontStyle != _style) { loadFonts(Settings.fontStyle); }
    }

    // Glyph atlases of one font style (tools/FontGen.java STYLES), all condensed with the F-35 PCD glyph
    // shapes: 0 = D chamfered corners, 1 = G small rounded corners (default), 2 = E large rounded corners.
    // The old style is dropped first, so two styles are never in memory at once.
    private function loadFonts(style as Number) as Void {
        _fTime = null; _fTimeAod = null; _fText = null; _fDate = null; _fDateAod = null;
        _fTapeVal = null; _fTapeLbl = null; _fTapeUnit = null; _fGaugeVal = null;
        _fHdr = null; _fVal = null; _fUnit = null; _fTabWarn = null; _fLunar = null;
        var ids = fontIds(style);
        var g = WatchUi.loadResource(ids[0]) as Dictionary;
        Stroke.setAdvances(g["_adv"] as Array);
        _fTime = font(ids[1], g, "FTime");
        _fTimeAod = font(ids[2], g, "FTimeAod");
        _fText = font(ids[3], g, "FText");
        _fDate = font(ids[4], g, "FDate");
        _fDateAod = font(ids[5], g, "FDateAod");
        _fTapeVal = font(ids[6], g, "FTapeVal");
        _fTapeLbl = font(ids[7], g, "FTapeLbl");
        _fTapeUnit = font(ids[8], g, "FTapeUnit");
        _fGaugeVal = font(ids[9], g, "FGaugeVal");
        _fHdr = font(ids[10], g, "FHdr");
        _fVal = font(ids[11], g, "FVal");
        _fUnit = font(ids[12], g, "FUnit");
        _fTabWarn = font(ids[13], g, "FTabWarn");
        _fLunar = font(Rez.Drawables.FLunar, g, "FLunar");
        _style = style;
    }

    // [glyph table, FTime, FTimeAod, FText, FDate, FDateAod, FTapeVal, FTapeLbl, FTapeUnit, FGaugeVal,
    //  FHdr, FVal, FUnit, FTabWarn] resource ids of a font style.
    private function fontIds(style as Number) as Array<ResourceId> {
        if (style == 0) {
            return [Rez.JsonData.Glyphs_D, Rez.Drawables.FTime_D, Rez.Drawables.FTimeAod_D, Rez.Drawables.FText_D,
                    Rez.Drawables.FDate_D, Rez.Drawables.FDateAod_D, Rez.Drawables.FTapeVal_D, Rez.Drawables.FTapeLbl_D,
                    Rez.Drawables.FTapeUnit_D, Rez.Drawables.FGaugeVal_D, Rez.Drawables.FHdr_D, Rez.Drawables.FVal_D,
                    Rez.Drawables.FUnit_D, Rez.Drawables.FTabWarn_D];
        }
        if (style == 2) {
            return [Rez.JsonData.Glyphs_E, Rez.Drawables.FTime_E, Rez.Drawables.FTimeAod_E, Rez.Drawables.FText_E,
                    Rez.Drawables.FDate_E, Rez.Drawables.FDateAod_E, Rez.Drawables.FTapeVal_E, Rez.Drawables.FTapeLbl_E,
                    Rez.Drawables.FTapeUnit_E, Rez.Drawables.FGaugeVal_E, Rez.Drawables.FHdr_E, Rez.Drawables.FVal_E,
                    Rez.Drawables.FUnit_E, Rez.Drawables.FTabWarn_E];
        }
        return [Rez.JsonData.Glyphs_G, Rez.Drawables.FTime_G, Rez.Drawables.FTimeAod_G, Rez.Drawables.FText_G,
                Rez.Drawables.FDate_G, Rez.Drawables.FDateAod_G, Rez.Drawables.FTapeVal_G, Rez.Drawables.FTapeLbl_G,
                Rez.Drawables.FTapeUnit_G, Rez.Drawables.FGaugeVal_G, Rez.Drawables.FHdr_G, Rez.Drawables.FVal_G,
                Rez.Drawables.FUnit_G, Rez.Drawables.FTabWarn_G];
    }

    private function font(id as ResourceId, glyphs as Dictionary, name as String) as StrokeFont {
        return new StrokeFont(WatchUi.loadResource(id) as BitmapResource, glyphs[name] as Dictionary);
    }

    function onEnterSleep() as Void { _sleeping = true; WatchUi.requestUpdate(); }
    function onExitSleep() as Void { _sleeping = false; WatchUi.requestUpdate(); }

    function onUpdate(dc as Dc) as Void {
        var L = lay as Layout;
        if (dc has :setAntiAlias) { dc.setAntiAlias(true); }
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var now = Time.now();
        var t = Gregorian.info(now, Time.FORMAT_SHORT);
        var minuteKey = t.hour * 60 + t.min;
        data.refresh(now, minuteKey);
        updateLunar(t);

        // No colon: "23:41" does not fit between the tape boxes (SETTINGS.md §1).
        var timeStr = t.hour.format("%02d") + t.min.format("%02d");
        var wday = DAYS[t.day_of_week - 1];
        var mmdd = (t.month as Number).format("%02d") + "/" + t.day.format("%02d");

        if (isAod(now.value())) {
            drawAod(dc, L, timeStr, wday, mmdd, minuteKey);
            return;
        }

        drawStation(dc, L);
        drawTapes(dc, L);
        Stroke.draw(dc, timeStr, _cx, _cy + L.boxY + L.timeH / 2, L.timeH, Col.HUD, Stroke.MIDDLE, _fTime as StrokeFont);
        drawDates(dc, L, wday, mmdd, 0, 0, Col.WHITE, _fDate as StrokeFont);
        drawDividers(dc, L);
        drawSlots(dc, L);
    }

    // ---- Always-on ----------------------------------------------------------------------

    (:live)
    private function isAod(sec as Number) as Boolean { return _sleeping; }

    // Demo build: alternate active / always-on every 15 s, regardless of the simulator's sleep state.
    (:demo)
    private function isAod(sec as Number) as Boolean { return (sec / 15) % 2 == 1; }

    private function drawAod(dc as Dc, L as Layout, timeStr as String, wday as String, mmdd as String, minuteKey as Number) as Void {
        var ox = ORBIT_X[minuteKey % ORBIT_X.size()];
        var oy = ORBIT_Y[minuteKey % ORBIT_Y.size()];
        Stroke.draw(dc, timeStr, _cx + ox, _cy + oy + L.boxY + L.timeH / 2, L.timeH, Col.AOD_TIME, Stroke.MIDDLE, _fTimeAod as StrokeFont);
        drawDates(dc, L, wday, mmdd, ox, oy, Col.AOD_DATE, _fDateAod as StrokeFont);
        // Of the slots only the lunar date stays on (dimmed); data fields are hidden.
        var slots = L.slots;
        for (var i = 0; i < slots.size(); i++) {
            if (slots[i].field == Field.LUNAR) { drawLunar(dc, L, slots[i], ox, oy, Col.AOD_LUNAR); }
        }
    }

    // ---- Date and lunar date ------------------------------------------------------------

    private function updateLunar(t as Gregorian.Info) as Void {
        var key = t.year * 400 + t.month * 32 + t.day;
        if (key != _lunarKey) {
            _lunarKey = key;
            var s = Lunar.format(t.year, t.month as Number, t.day);
            _lunarMonth = null; _lunarDay = null;
            if (s != null) {
                var i = s.find("月");
                if (i != null) {
                    _lunarMonth = s.substring(0, i + 1);
                    _lunarDay = s.substring(i + 1, s.length());
                }
            }
        }
    }

    // Date block, left column: weekday over MM/DD, centred on x = -dsX. The right column is a slot
    // (the lunar date by default). The centre stays free for a wind barb pointing down.
    private function drawDates(dc as Dc, L as Layout, wday as String, mmdd as String, ox as Number, oy as Number,
                               col as Number, f as StrokeFont) as Void {
        var xl = _cx + ox - L.dsX;
        Stroke.draw(dc, wday, xl, _cy + oy + L.dsY1, L.dateH, col, Stroke.MIDDLE, f);
        Stroke.draw(dc, mmdd, xl, _cy + oy + L.dsY2, L.dateH, col, Stroke.MIDDLE, f);
    }

    // Lunar month over lunar day in the date block's right column (stroke-style CJK; glyphs sit slightly
    // below the Latin baseline like a CJK font), 8 px between the lines.
    private function drawLunar(dc as Dc, L as Layout, s as Slot, ox as Number, oy as Number, col as Number) as Void {
        if (_lunarMonth == null) { return; }
        var fl = _fLunar as StrokeFont;
        var x = _cx + ox + s.x;
        var yDay = _cy + oy + s.vb + 2;
        Stroke.draw(dc, _lunarMonth as String, x, yDay - L.lunH - 8, L.lunH, col, Stroke.MIDDLE, fl);
        Stroke.draw(dc, _lunarDay as String, x, yDay, L.lunH, col, Stroke.MIDDLE, fl);
    }

    // ---- Station model ------------------------------------------------------------------

    private function drawStation(dc as Dc, L as Layout) as Void {
        var x = _cx, y = _cy + L.stY, r = L.stR, h = L.stH;
        var d = data;
        if (!d.wxOk) {
            Wx.drawSky(dc, x, y, r, Wx.EMPTY, Col.WHITE);
            return;
        }
        var dim = d.wxStale;
        var fg = dim ? 0x707070 : Col.WHITE;
        var barbCol = dim ? 0x505050 : Col.BARB;

        // Calm needs no direction (the weather service may send no bearing when calm).
        var kt = d.wxWindKt;
        if (kt != null && (d.wxWindDir != null || kt < 3)) {
            Wx.drawBarb(dc, x, y, r, d.wxWindDir != null ? d.wxWindDir : 0, kt, L.barb, barbCol);
        }
        Wx.drawSky(dc, x, y, r, d.wxCover, fg);

        var tStr = Units.temp(d.wxTemp, Settings.imperial);
        var dStr = Units.temp(d.wxDew, Settings.imperial);
        var tr = x - L.clear;
        Stroke.draw(dc, tStr, tr, y - 5, h, tStr.equals("--") ? Col.UNIT : fg, Stroke.END, _fText as StrokeFont);
        Stroke.draw(dc, dStr, tr, y + 5 + h, h, dStr.equals("--") ? Col.UNIT : fg, Stroke.END, _fText as StrokeFont);
        var tw = Stroke.width(tStr, h);
        var dw = Stroke.width(dStr, h);
        if (dw > tw) { tw = dw; }

        var sym = Wx.symbolOf(d.wxCond);
        var symCol = Wx.isChance(d.wxCond) ? (dim ? 0x404040 : Col.CHANCE) : fg;
        // symDy px below the circle centre: level with the upper corner, a tall symbol clips on the bezel.
        Wx.drawSymbol(dc, sym, tr - tw - L.symGap, y + L.symDy, L.symK, symCol);

        // Pressure in whole hPa, 3 or 4 digits (as METAR's Q1013, not the station model's coded 132: easier
        // to read), or inHg as 29.92.
        var p = d.wxPressure;
        var pStr = Units.pressure(p, Settings.imperial);
        Stroke.draw(dc, pStr, x + L.clear, y + h / 2, h, p != null ? fg : Col.UNIT, Stroke.START, _fText as StrokeFont);
    }

    // ---- Tapes --------------------------------------------------------------------------

    private function drawTapes(dc as Dc, L as Layout) as Void {
        var hr = data.hr;
        // HR: tick 5 bpm every L.hrTickPx px, long tick 10 bpm (about ±30 bpm visible).
        drawTape(dc, L, -1, hr != null ? hr.toFloat() : null, 5, 10, L.hrTickPx, "HR", data.zones, null);
        // ALT in tens of metres (tick 20 m, long tick 100 m) or hundreds of feet (tick 100 ft, long tick
        // 500 ft), one tick every L.tickPx px.
        var a = Units.altTape(data.altitude, Settings.imperial);
        drawTape(dc, L, 1, a[0] as Float?, a[1] as Number, a[2] as Number, L.tickPx, "ALT", null, a[3] as String);
    }

    private function zoneColor(v as Numeric, z as Array<Number>?) as Number {
        if (z == null || z.size() < 5) { return Col.HUD; }
        var cols = [Col.UNIT, Col.CYAN, Col.HUD, Col.AMBER, Col.RED];
        for (var i = 4; i >= 0; i--) {
            if (v >= z[i]) { return cols[i]; }
        }
        return Col.HUD;
    }

    const ZONE_W = 4;     // HR zone colour band width

    // Straight vertical scrolling tape at 3 / 9 o'clock (§3.4). The value box sits at the bezel and the
    // spine runs behind it (the box covers the middle; its centre marks the current value); ticks point
    // outward from the spine (towards the bezel) and the HR zone band runs along its inner side.
    private function drawTape(dc as Dc, L as Layout, side as Number, val as Float?,
                              minor as Number, major as Number, px as Number, label as String,
                              z as Array<Number>?, unit as String?) as Void {
        var bw = L.boxW, bh = L.boxH;
        var bo = _cx + side * L.boxOut;
        var bi = _cx + side * (L.boxOut - bw);
        var s = _cx + side * L.tapeX;              // spine x
        var cy = _cy + L.boxY;
        var half = L.tapeHalf;

        // Spine: 2 px, pixel-aligned, centred on s.
        dc.setColor(Col.HUD, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(s - 1, cy - half, 2, 2 * half);

        var zc = Col.HUD;
        if (val != null) {
            var v = val;
            var k = px.toFloat() / minor;          // px per unit
            var mLo = v - half / k, mHi = v + half / k;
            if (z != null && z.size() >= 5) {
                zc = zoneColor(v, z);
                var zcols = [Col.UNIT, Col.CYAN, Col.HUD, Col.AMBER, Col.RED];
                var xa = s - side * 2, xb = s - side * (2 + ZONE_W);
                for (var zi = 0; zi < 5; zi++) {
                    var a = z[zi].toFloat();
                    var b = zi < 4 ? z[zi + 1].toFloat() : 999.0;
                    if (a < mLo) { a = mLo; }
                    if (b > mHi) { b = mHi; }
                    // Whole-pixel edges, like the ticks.
                    var y1 = Math.round(cy - (b - v) * k).toNumber(), y2 = Math.round(cy - (a - v) * k).toNumber();
                    if (y2 > y1) {
                        dc.setColor(zcols[zi], Graphics.COLOR_TRANSPARENT);
                        dc.fillRectangle(xa < xb ? xa : xb, y1, ZONE_W, y2 - y1);
                    }
                }
            }
            // Ticks: bars snapped to whole pixels, pointing outward; long ticks 3 px, short 2 px.
            // (Anti-aliased bars at fractional y looked 2 or 3 px thick depending on where they sat;
            // snapped, every tick of a kind has the same weight and the tape scrolls in 1 px steps.)
            // They slide under the value box, whose black fill (drawn next) covers the overlap.
            dc.setColor(Col.HUD, Graphics.COLOR_TRANSPARENT);
            var m = Math.ceil(mLo / minor).toNumber() * minor;
            while (m <= mHi) {
                var y = Math.round(cy - (m - v) * k).toNumber();
                var isLong = m % major == 0;
                var len = isLong ? L.tickMajor : L.tickMinor;
                dc.fillRectangle(side > 0 ? s : s - len, y - 1, len, isLong ? 3 : 2);
                m += minor;
            }
        }

        // Value box (no pointer: the box centre is the current value).
        var bx = bo < bi ? bo : bi;
        var by = cy - bh / 2;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(bx, by, bw, bh);
        // Border: 3 px, pixel-aligned solid rectangles (box corners are whole pixels), crisp; from 1 px
        // inside the box edge to 2 px outside it.
        dc.setColor(zc, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(bx - 2, by - 2, bw + 4, 3);
        dc.fillRectangle(bx - 2, by + bh - 1, bw + 4, 3);
        dc.fillRectangle(bx - 2, by - 2, 3, bh + 4);
        dc.fillRectangle(bx + bw - 1, by - 2, 3, bh + 4);

        var mid = (bo + bi) / 2.0;
        var fv = _fTapeVal as StrokeFont;
        Stroke.draw(dc, label, mid, by + 14, 11, Col.CYAN, Stroke.MIDDLE, _fTapeLbl as StrokeFont);
        if (val != null) {
            Stroke.draw(dc, Math.round(val).toNumber().toString(), mid, by + bh - 7, L.boxV, zc, Stroke.MIDDLE, fv);
        } else {
            Stroke.draw(dc, "--", mid, by + bh - 7, L.boxV, Col.UNIT, Stroke.MIDDLE, fv);
        }
        if (unit != null) {
            // Above the box, starting 1 px inside its inner edge: clear of the spine and of the time. Two
            // words stack, the last one lowest ("100" over "FT": "100FT" in one line would cross the spine).
            var sp = unit.find(" ");
            var lines = sp == null ? [unit] : [unit.substring(sp + 1, unit.length()), unit.substring(0, sp)];
            for (var i = 0; i < lines.size(); i++) {
                Stroke.draw(dc, lines[i] as String, bi - side, by - 5 - i * (L.tapeUnitH + 3), L.tapeUnitH, Col.UNIT,
                            side > 0 ? Stroke.START : Stroke.END, _fTapeUnit as StrokeFont);
            }
        }
    }

    // ---- Slots: data row, date block right column, bottom row ---------------------------

    // Thin progress bar under a data row value (Settings.showBars), drawn only for fields that have a goal
    // (Field.read returns a progress value; e.g. ACT MIN). The layout keeps room for it (bar sits ~17 px
    // above the bottom row).

    // Data row frame: divider line above, vertical dividers between the cells.
    private function drawDividers(dc as Dc, L as Layout) as Void {
        var cw = L.cellW;
        var dy = _cy + L.pY - 6;
        Gfx.line(dc, _cx - L.pX, dy, _cx + L.pX, dy, Col.DIVIDER, 1);
        var xi = _cx - L.pX;
        for (var i = 0; i < cw.size() - 1; i++) {
            xi += cw[i];
            Gfx.line(dc, xi, dy + 8, xi, _cy + L.pY + L.pH, Col.DIVIDER, 1);
        }
    }

    private function drawSlots(dc as Dc, L as Layout) as Void {
        var slots = L.slots;
        for (var i = 0; i < slots.size(); i++) {
            var s = slots[i];
            if (s.warn && data.bingo()) { drawWarning(dc, L); continue; }
            if (s.field == Field.LUNAR) { drawLunar(dc, L, s, 0, 0, Col.LUNAR); continue; }
            if (s.style == Slot.GAUGE) { drawGauge(dc, L, s); continue; }
            var r = Field.read(s.field, data);
            var hdr = Field.header(s.field, data);
            var val = r[0] as String?;
            if (s.style == Slot.ROW) {
                var f = Fit.row(s.field, hdr, val, r[1] as String, r[3] as Array<String>?, L);
                drawRow(dc, L, f[0] as String, val != null ? f[1] as String : null, f[2] as String, _cx + s.x, _cy + s.vb);
            } else {
                var f = Fit.cell(s.field, hdr, val, r[1] as String, r[3] as Array<String>?, s.w, L);
                cellText(dc, L, _cx + s.x, f[0] as String, f[1] as String?, f[2] as String, _cy + s.hb, _cy + s.vb);
                if (Settings.showBars && s.bar && r[2] != null) { drawBar(dc, _cx + s.x, s.w, _cy + s.vb + 9, r[2] as Float); }
            }
        }
    }

    // ROW style: cyan underlined header top-aligned with a white value at the data-window value size and
    // an optional gray unit, centred on x (value baseline b).
    private function drawRow(dc as Dc, L as Layout, hdr as String, val as String?, unit as String, x as Numeric, b as Numeric) as Void {
        var v = val != null ? val : "--";
        var hw = Stroke.width(hdr, L.hdrH), vw = Stroke.width(v, L.valH), gap = 8;
        var uw = unit.length() > 0 ? Stroke.width(unit, L.unitH) + 4 : 0;
        var x0 = x - (hw + gap + vw + uw) / 2.0;
        Stroke.header(dc, hdr, x0 + hw / 2.0, b - L.valH + L.hdrH, L.hdrH, _fHdr as StrokeFont);
        Stroke.draw(dc, v, x0 + hw + gap, b, L.valH, val != null ? Col.WHITE : Col.UNIT, Stroke.START, _fVal as StrokeFont);
        if (uw > 0) {
            Stroke.draw(dc, unit, x0 + hw + gap + vw + 4, b, L.unitH, Col.UNIT, Stroke.START, _fUnit as StrokeFont);
        }
    }

    // NARROW / WIDE style: cyan underlined header (baseline hb) over a white value with an optional gray
    // unit (baseline vb), centred on xc. Header, value and unit already fitted to the cell (Fit.cell).
    private function cellText(dc as Dc, L as Layout, xc as Numeric, lab as String,
                              val as String?, unit as String, hb as Numeric, vb as Numeric) as Void {
        Stroke.header(dc, lab, xc, hb, L.hdrH, _fHdr as StrokeFont);
        if (val == null) {
            Stroke.draw(dc, "--", xc, vb, L.valH, Col.UNIT, Stroke.MIDDLE, _fVal as StrokeFont);
            return;
        }
        var vw = Stroke.width(val, L.valH);
        var uw = Fit.unitWidth(unit, L);
        var vx = xc - (vw + uw) / 2.0;
        Stroke.draw(dc, val, vx, vb, L.valH, Col.WHITE, Stroke.START, _fVal as StrokeFont);
        if (unit.length() > 0) {
            Stroke.draw(dc, unit, vx + vw + 4, vb, L.unitH, Col.UNIT, Stroke.START, _fUnit as StrokeFont);
        }
    }

    // GAUGE style, after the F-35 PCD's segmented engine / fuel gauges: cyan label (same font and size as
    // the value) right-aligned left of the bar, 10 segments of 10 % in the field's status colour (the last one filled
    // in proportion, e.g. 62 = 6 full + 20 % of the 7th; empty ones as dim outlines), end marks, and the
    // value in the status colour right of it. The bar's bottom is on s.vb; label and value hang from the
    // bar's top edge. Everything is pixel-aligned.
    private function drawGauge(dc as Dc, L as Layout, s as Slot) as Void {
        var g = Field.gauge(s.field, data);
        var v = g[1] as Number?, col = g[2] as Number;
        var x0 = _cx + s.x - s.w / 2, b = _cy + s.vb;
        var segW = (s.w + 1) / 10, bh = 6, by = b - bh;
        Stroke.draw(dc, g[0] as String, x0 - 6, by + L.gValH, L.gValH, Col.CYAN, Stroke.END, _fGaugeVal as StrokeFont);
        dc.setColor(Col.DIVIDER, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x0 - 2, by - 3, 1, bh + 3);
        dc.fillRectangle(x0 + s.w + 1, by - 3, 1, bh + 3);
        var pct = v == null ? 0 : v < 0 ? 0 : v > 100 ? 100 : v;
        for (var i = 0; i < 10; i++) {
            var sx = x0 + i * segW;
            var fill = pct - i * 10;   // this segment's share, 0..10
            if (fill < 10) {
                dc.setColor(Col.GAUGE_OFF, Graphics.COLOR_TRANSPARENT);
                dc.drawRectangle(sx, by, segW - 1, bh);
            }
            if (fill > 0) {
                dc.setColor(col, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(sx, by, fill >= 10 ? segW - 1 : ((segW - 1) * fill + 5) / 10, bh);
            }
        }
        Stroke.draw(dc, v != null ? v.toString() : "--", x0 + s.w + 6, by + L.gValH, L.gValH, v != null ? col : Col.UNIT,
                    Stroke.START, _fGaugeVal as StrokeFont);
    }

    // Progress bar (0..1) under a cell value, 3 px tall at y.
    private function drawBar(dc as Dc, xc as Numeric, w as Number, y as Numeric, frac as Float) as Void {
        if (frac < 0) { frac = 0.0; }
        if (frac > 1) { frac = 1.0; }
        var bx = xc - w / 2.0 + 10, bw = w - 20, by = y;
        dc.setColor(Col.BAR_BG, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(bx, by, bw, 3);
        if (frac > 0) {
            dc.setColor(Col.HUD, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(bx, by, bw * frac, 3);
        }
    }

    // ---- Warning box (replaces the bottom row while a warning is active) --------------------

    // 45° "/" warning stripes filling the box (bx, by, bw, bh); the clip cuts them at the edges.
    // Hazard-tape look: wide stripes, gap wider than the stripe.
    private function hatch(dc as Dc, bx as Number, by as Number, bw as Number, bh as Number, col as Number, big as Boolean) as Void {
        var period = big ? 16.0 : 14.0, half = big ? 3.0 : 2.6;   // perpendicular period, half stripe width
        var step = period * 1.41421;
        dc.setClip(bx, by, bw, bh);
        dc.setColor(col, Graphics.COLOR_TRANSPARENT);
        // Lines x + y = c, from the bottom edge to the top edge.
        var y1 = (by + bh + 4).toFloat(), y2 = (by - 4).toFloat();
        var c0 = bx + bw / 2.0 + by + bh / 2.0;
        var n = ((bw + bh) / step).toNumber() / 2 + 1;
        for (var i = -n; i <= n; i++) {
            var c = c0 + i * step;
            Gfx.seg(dc, c - y1, y1, c - y2, y2, half);
        }
        dc.clearClip();
    }

    // BINGO: square-cornered red box with a 2 px pixel-aligned border (like the tape value boxes), dimmed
    // hazard stripes and the white label.
    private function drawWarning(dc as Dc, L as Layout) as Void {
        var label = "BINGO";
        var y = _cy + L.botY, h = L.botH, hw = L.botW / 2;
        var x = _cx;
        var base = y + (h + L.tabH) / 2;
        var bx = x - hw - 4, bw = 2 * hw + 8;
        hatch(dc, bx, y, bw, h, Col.RED_DIM, L.big);
        dc.setColor(Col.RED, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(bx - 1, y - 1, bw + 2, 2);
        dc.fillRectangle(bx - 1, y + h - 1, bw + 2, 2);
        dc.fillRectangle(bx - 1, y - 1, 2, h + 2);
        dc.fillRectangle(bx + bw - 1, y - 1, 2, h + 2);
        // 1 px black halo so the white letters stay whole where they cross a stripe.
        var f = _fTabWarn as StrokeFont;
        for (var i = 0; i < 8; i++) {
            Stroke.draw(dc, label, x + HALO_X[i], base + HALO_Y[i], L.tabH, Graphics.COLOR_BLACK, Stroke.MIDDLE, f);
        }
        Stroke.draw(dc, label, x, base, L.tabH, Col.WHITE, Stroke.MIDDLE, f);
    }
}
