import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Weather;

// Station-model weather mapping and drawing (requirements §6).
module Wx {
    // Sky cover codes.
    enum { CLR, FEW, SCT, BKN, OVC, OBSCURABLE, EMPTY, OBSCURED }

    // Present-weather symbols.
    enum {
        NONE, RA_L, RA, RA_H, DZ, SHRA, SN_L, SN, SN_H, SHSN, RASN, FZRA, PL, GR,
        TS, FG, BR, HZ, FU, DU, SS, SQ, FC, TC_FILLED, TC_OPEN, UP
    }

    // Per Garmin condition id 0..53: symbol + 32 * chance(gray) + 64 * fallback cover.
    const CONDITIONS = [
        0, 128, 192, 258, 263, 128, 270, 266, 335, 81,          //  0-9
        269, 133, 142, 281, 257, 259, 262, 264, 266, 266,       // 10-19
        256, 266, 128, 64, 133, 197, 197, 165, 174, 208,        // 20-29
        83, 260, 278, 338, 268, 83, 213, 340, 338, 81,          // 30-39
        64, 279, 280, 231, 234, 290, 295, 298, 201, 267,        // 40-49
        268, 268, 64, 384                                       // 50-53
    ] as Array<Number>;

    function entry(cond as Number?) as Number {
        if (cond == null || cond < 0 || cond >= CONDITIONS.size()) { return CONDITIONS[53]; }
        return CONDITIONS[cond];
    }

    function symbolOf(cond as Number?) as Number { return entry(cond) & 31; }
    function isChance(cond as Number?) as Boolean { return (entry(cond) & 32) != 0; }

    function coverFromPercent(pc as Numeric) as Number {
        if (pc <= 5) { return CLR; }
        if (pc <= 25) { return FEW; }
        if (pc <= 50) { return SCT; }
        if (pc <= 87) { return BKN; }
        return OVC;
    }

    // §6.1: cloudCover preferred, fallback by condition, X for obscuring weather in low visibility.
    function cover(cond as Number?, pc as Numeric?, vis as Numeric?) as Number {
        var fb = entry(cond) >> 6;
        if (fb == OBSCURABLE) {
            if (vis == null || vis < 1000) { return OBSCURED; }
            return pc != null ? coverFromPercent(pc) : OVC;
        }
        if (pc != null) { return coverFromPercent(pc); }
        return fb;
    }

    // Sky-cover circle; pie wedges clockwise from 12 o'clock.
    function drawSky(dc as Dc, x as Numeric, y as Numeric, r as Numeric, code as Number, col as Number) as Void {
        if (code == OVC) { Gfx.disc(dc, x, y, r, col); return; }
        Gfx.disc(dc, x, y, r, Graphics.COLOR_BLACK);
        Gfx.circle(dc, x, y, r, col, 2);
        if (code == OBSCURED) {
            var d = r * 0.7;
            Gfx.line(dc, x - d, y - d, x + d, y + d, col, 1.8);
            Gfx.line(dc, x - d, y + d, x + d, y - d, col, 1.8);
            return;
        }
        var f = code == FEW ? 0.25 : code == SCT ? 0.5 : code == BKN ? 0.75 : 0.0;
        if (f == 0.0) { return; }
        var steps = (f * 24).toNumber();
        var pts = [x, y] as Array<Numeric>;
        for (var i = 0; i <= steps; i++) {
            var a = 2 * Math.PI * f * i / steps;
            pts.add(x + r * Math.sin(a));
            pts.add(y - r * Math.cos(a));
        }
        Gfx.fillPoly(dc, pts, col);
    }

    // Wind barb in knots; dir = direction the wind blows FROM (degrees).
    function drawBarb(dc as Dc, x as Numeric, y as Numeric, r as Numeric, dir as Numeric, kt as Numeric,
                      len as Numeric, col as Number) as Void {
        if (kt < 3) { Gfx.circle(dc, x, y, r + 4, col, 1.6); return; }
        var a = Math.toRadians(dir);
        var dx = Math.sin(a), dy = -Math.cos(a);
        var px = -dy, py = dx;
        var tx = x + dx * (r + len), ty = y + dy * (r + len);
        Gfx.line(dc, x + dx * r, y + dy * r, tx, ty, col, 1.8);
        var k5 = (Math.round(kt / 5.0) * 5).toNumber();
        var p = 0.0;
        var fl = 10, step = 4.5;
        while (k5 >= 50) {
            var bx = tx - dx * p, by = ty - dy * p;
            Gfx.fillPoly(dc, [bx, by, bx + px * fl, by + py * fl, bx - dx * 5, by - dy * 5], col);
            p += 6.5; k5 -= 50;
        }
        while (k5 >= 10) {
            var bx = tx - dx * p, by = ty - dy * p;
            Gfx.line(dc, bx, by, bx + px * fl + dx * 3, by + py * fl + dy * 3, col, 1.8);
            p += step; k5 -= 10;
        }
        if (k5 >= 5) {
            if (p == 0.0) { p = step; }
            var bx = tx - dx * p, by = ty - dy * p;
            Gfx.line(dc, bx, by, bx + px * fl * 0.55 + dx * 1.6, by + py * fl * 0.55 + dy * 1.6, col, 1.8);
        }
    }

    // Draws symbols in unit coordinates (§6.3) scaled by k around (ox, oy).
    class SymPen {
        private var _dc as Dc;
        private var _ox as Float;
        private var _oy as Float;
        private var _k as Float;
        private var _col as Number;
        private const SW = 2.3;

        function initialize(dc as Dc, ox as Numeric, oy as Numeric, k as Numeric, col as Number) {
            _dc = dc; _ox = ox.toFloat(); _oy = oy.toFloat(); _k = k.toFloat(); _col = col;
        }

        private function X(u as Numeric) as Float { return _ox + u * _k; }
        private function Y(v as Numeric) as Float { return _oy + v * _k; }

        function dot(u as Numeric, v as Numeric, r as Numeric) as Void {
            Gfx.disc(_dc, X(u), Y(v), r * _k, _col);
        }

        function ring(u as Numeric, v as Numeric, r as Numeric, filled as Boolean) as Void {
            if (filled) { Gfx.disc(_dc, X(u), Y(v), r * _k, _col); }
            else { Gfx.circle(_dc, X(u), Y(v), r * _k, _col, SW); }
        }

        function star(u as Numeric, v as Numeric, r as Numeric) as Void {
            for (var i = 0; i < 3; i++) {
                var a = i * Math.PI / 3 + Math.PI / 2;
                var c = r * Math.cos(a), s = r * Math.sin(a);
                Gfx.line(_dc, X(u - c), Y(v - s), X(u + c), Y(v + s), _col, SW);
            }
        }

        // Unit-space polyline [u0, v0, u1, v1, ...].
        function poly(uv as Array<Numeric>, closed as Boolean) as Void {
            Gfx.poly(_dc, map(uv), _col, SW, closed);
        }

        function fill(uv as Array<Numeric>) as Void {
            Gfx.fillPoly(_dc, map(uv), _col);
        }

        private function map(uv as Array<Numeric>) as Array<Numeric> {
            var out = new Array<Numeric>[uv.size()];
            for (var i = 0; i + 1 < uv.size(); i += 2) {
                out[i] = X(uv[i]);
                out[i + 1] = Y(uv[i + 1]);
            }
            return out;
        }

        // Quadratic Bézier p0 -> p2 with control p1, flattened.
        function quad(x0 as Numeric, y0 as Numeric, x1 as Numeric, y1 as Numeric, x2 as Numeric, y2 as Numeric) as Void {
            var pts = [] as Array<Numeric>;
            for (var i = 0; i <= 10; i++) {
                var t = i / 10.0, m = 1 - t;
                pts.add(m * m * x0 + 2 * m * t * x1 + t * t * x2);
                pts.add(m * m * y0 + 2 * m * t * y1 + t * t * y2);
            }
            poly(pts, false);
        }

        // Cubic Bézier, flattened.
        function cubic(x0 as Numeric, y0 as Numeric, x1 as Numeric, y1 as Numeric,
                       x2 as Numeric, y2 as Numeric, x3 as Numeric, y3 as Numeric) as Void {
            var pts = [] as Array<Numeric>;
            for (var i = 0; i <= 14; i++) {
                var t = i / 14.0, m = 1 - t;
                var a = m * m * m, b = 3 * m * m * t, c = 3 * m * t * t, d = t * t * t;
                pts.add(a * x0 + b * x1 + c * x2 + d * x3);
                pts.add(a * y0 + b * y1 + c * y2 + d * y3);
            }
            poly(pts, false);
        }

        // DU / SS S-curve: M(6,-7) C(-2,-12) (-10,-6) (-2,0) S(7,10) (-6,7).
        function sCurve() as Void {
            cubic(6, -7, -2, -12, -10, -6, -2, 0);
            cubic(-2, 0, 6, 6, 7, 10, -6, 7);
        }
    }

    // Draw present-weather symbol `sym` centred at (x, y) with scale k.
    function drawSymbol(dc as Dc, sym as Number, x as Numeric, y as Numeric, k as Numeric, col as Number) as Void {
        if (sym == NONE) { return; }
        var p = new SymPen(dc, x, y, k, col);
        var tri = [-7, -5, 7, -5, 0, 8] as Array<Numeric>;
        switch (sym) {
            case RA_L: p.dot(-5, 0, 2.6); p.dot(5, 0, 2.6); break;
            case RA: p.dot(0, -6, 2.6); p.dot(-6, 4, 2.6); p.dot(6, 4, 2.6); break;
            case RA_H: p.dot(0, -8, 2.6); p.dot(-7, 0, 2.6); p.dot(7, 0, 2.6); p.dot(0, 8, 2.6); break;
            case DZ:
                for (var c = -5; c <= 5; c += 10) {
                    p.dot(c, -2, 2.6);
                    p.quad(c + 2.4, -2, c + 2.4, 4, c - 2, 6);
                }
                break;
            case SHRA: p.dot(0, -11, 2.6); p.poly(tri, true); break;
            case SN_L: p.star(0, 0, 5); break;
            case SN: p.star(-6, 0, 5); p.star(6, 0, 5); break;
            case SN_H: p.star(0, -6, 4.5); p.star(-7, 5, 4.5); p.star(7, 5, 4.5); break;
            case SHSN: p.star(0, -11, 4); p.poly(tri, true); break;
            case RASN: p.dot(0, -7, 2.6); p.star(0, 6, 4.5); break;
            case FZRA:
                // M(-12,3) Q(-6,-9) (0,1) T(12,-2)
                p.dot(-2, 0, 2.6);
                p.quad(-12, 3, -6, -9, 0, 1);
                p.quad(0, 1, 6, 11, 12, -2);
                break;
            case PL: p.poly([-7, 6, 7, 6, 0, -7], true); p.dot(0, 2, 2); break;
            case GR: p.fill([-7, 6, 7, 6, 0, -7]); break;
            case TS:
                p.poly([-9, 9, -9, -8, 6, -8, 1, 0, 7, 0, 1, 9], false);
                p.poly([-2, 6, 1, 9, 4, 5], false);
                break;
            case FG: p.poly([-10, -6, 10, -6], false); p.poly([-10, 0, 10, 0], false); p.poly([-10, 6, 10, 6], false); break;
            case BR: p.poly([-10, -3, 10, -3], false); p.poly([-10, 3, 10, 3], false); break;
            case HZ:
                // ∞: M(0,0) C(-5,-7)(-12,-7)(-12,0) S(-5,7)(0,0) C(5,-7)(12,-7)(12,0) S(5,7)(0,0)
                p.cubic(0, 0, -5, -7, -12, -7, -12, 0);
                p.cubic(-12, 0, -12, 7, -5, 7, 0, 0);
                p.cubic(0, 0, 5, -7, 12, -7, 12, 0);
                p.cubic(12, 0, 12, 7, 5, 7, 0, 0);
                break;
            case FU:
                // M(-4,10) Q(-9,3) (-3,-2) T(0,-10)
                p.quad(-4, 10, -9, 3, -3, -2);
                p.quad(-3, -2, 3, -7, 0, -10);
                break;
            case DU: p.sCurve(); p.poly([0, -11, 0, 11], false); break;
            case SS: p.sCurve(); p.poly([-12, 0, 12, 0], false); p.poly([8, -3, 12, 0, 8, 3], false); break;
            case SQ: p.poly([-8, 8, 0, -8, 8, 8], false); break;
            case FC: p.quad(-8, -10, -2, 0, -8, 10); p.quad(8, -10, 2, 0, 8, 10); break;
            case TC_FILLED:
            case TC_OPEN:
                p.ring(0, 0, 5, sym == TC_FILLED);
                p.quad(5, -2, 6, -11, -4, -12);
                p.quad(-5, 2, -6, 11, 4, 12);
                break;
            case UP:
                // dot (-7,0); ?: M(1,-5) Q(2,-9)(5,-9) Q(9,-9)(8,-5) Q(7,-2)(5,-1) L(5,2); dot (5,6) r 1.5
                p.dot(-7, 0, 2.6);
                p.quad(1, -5, 2, -9, 5, -9);
                p.quad(5, -9, 9, -9, 8, -5);
                p.quad(8, -5, 7, -2, 5, -1);
                p.poly([5, -1, 5, 2], false);
                p.dot(5, 6, 1.5);
                break;
        }
    }
}
