// Bakes the mockup's single-line vector font into glyph atlases (PNG bitmaps + a JSON glyph table).
//
//   java -Dfile.encoding=UTF-8 tools\FontGen.java [previewDir]
//   (run from the pcd folder)
//
// Every style in STYLES is baked (see there). Glyphs come from GL2, shaped after the F-35 PCD font:
// slashed zero, 3 / 8 / S / B with a smaller top bowl, shallow M, near-vertical W legs; corners are 45°
// chamfers or circular arcs; K scales Latin widths (condensed) and the advances follow. The
// mockup's original GL table is kept for reference (STYLE "orig").
//
// Latin glyphs are the mockup's `GL` table (mockup_final.html), drawn exactly like the mockup's SVG:
// round caps and joins, at the mockup's fractional stroke widths, anti-aliased. CJK glyphs for the
// lunar date are single-line HUD-style skeletons in the same style.
//
// Every glyph image is placed so that the glyph grid origin (0,0) sits `pad` px right of and below
// the image corner. The watch draws a glyph with dc.drawBitmap2 (cropped to its cell, tinted) at
// (x - pad, baseline - h - pad). Advances are applied by Stroke.draw. Atlases are declared as
// PNG-packed bitmaps: Connect IQ font resources reduce anti-aliasing to ~4 alpha levels.
//
// Output: resources-<device>/fonts/<Id>.png, glyphs.json and fonts.xml.

import java.awt.*;
import java.awt.geom.*;
import java.awt.image.BufferedImage;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.util.*;
import java.util.List;
import javax.imageio.ImageIO;

public class FontGen {

    // ---- Mockup GL table (8 x 12 grid) --------------------------------------------------
    static final Map<Character, String> GL = new LinkedHashMap<>();
    static {
        String[][] t = {
            {"A", "M0,12L4,0L8,12M1.5,8L6.5,8"}, {"B", "M0,12L0,0L6,0L8,2L8,4L6,6L0,6M6,6L8,8L8,10L6,12L0,12"},
            {"C", "M8,2L6,0L2,0L0,2L0,10L2,12L6,12L8,10"}, {"D", "M0,0L0,12L5,12L8,9L8,3L5,0Z"},
            {"E", "M8,0L0,0L0,12L8,12M0,6L6,6"}, {"F", "M8,0L0,0L0,12M0,6L6,6"},
            {"G", "M8,2L6,0L2,0L0,2L0,10L2,12L6,12L8,10L8,7L5,7"}, {"H", "M0,0L0,12M8,0L8,12M0,6L8,6"},
            {"I", "M2,0L6,0M4,0L4,12M2,12L6,12"}, {"J", "M8,0L8,10L6,12L2,12L0,10"},
            {"K", "M0,0L0,12M8,0L0,7M3,5L8,12"}, {"L", "M0,0L0,12L8,12"}, {"M", "M0,12L0,0L4,7L8,0L8,12"},
            {"N", "M0,12L0,0L8,12L8,0"}, {"O", "M2,0L6,0L8,2L8,10L6,12L2,12L0,10L0,2Z"},
            {"P", "M0,12L0,0L6,0L8,2L8,4L6,6L0,6"}, {"Q", "M2,0L6,0L8,2L8,10L6,12L2,12L0,10L0,2ZM5,9L8,12"},
            {"R", "M0,12L0,0L6,0L8,2L8,4L6,6L0,6M5,6L8,12"},
            {"S", "M8,2L6,0L2,0L0,2L0,4L2,6L6,6L8,8L8,10L6,12L2,12L0,10"}, {"T", "M0,0L8,0M4,0L4,12"},
            {"U", "M0,0L0,10L2,12L6,12L8,10L8,0"}, {"V", "M0,0L4,12L8,0"}, {"W", "M0,0L2,12L4,6L6,12L8,0"},
            {"X", "M0,0L8,12M8,0L0,12"}, {"Y", "M0,0L4,6L8,0M4,6L4,12"}, {"Z", "M0,0L8,0L0,12L8,12"},
            {"0", "M2,0L6,0L8,2L8,10L6,12L2,12L0,10L0,2Z"}, {"1", "M1,2L4,0L4,12M0,12L8,12"},
            {"2", "M0,2L2,0L6,0L8,2L8,4L0,12L8,12"}, {"3", "M0,2L2,0L6,0L8,2L8,4L6,6L3,6M6,6L8,8L8,10L6,12L2,12L0,10"},
            {"4", "M6,12L6,0L0,8L8,8"}, {"5", "M8,0L0,0L0,5L6,5L8,7L8,10L6,12L2,12L0,10"},
            {"6", "M7,0L3,0L0,4L0,10L2,12L6,12L8,10L8,7L6,5L0,5"}, {"7", "M0,0L8,0L3,12"},
            {"8", "M2,0L6,0L8,2L8,4L6,6L2,6L0,4L0,2ZM2,6L0,8L0,10L2,12L6,12L8,10L8,8L6,6"},
            {"9", "M8,7L2,7L0,5L0,2L2,0L6,0L8,2L8,8L5,12L1,12"},
            {"/", "M0,12L8,0"}, {"-", "M1,6L7,6"}, {">", "M0,1L8,6L0,11"},
            {"%", "M0,12L8,0M0,0L2,0L2,2L0,2ZM6,10L8,10L8,12L6,12Z"},
        };
        for (String[] e : t) GL.put(e[0].charAt(0), e[1]);
    }

    // ---- F-35 PCD-inspired table (8 x 12 grid, skeleton notation: "x,y~r" = corner of radius r,
    // drawn as a 45° chamfer or an arc depending on the style; ";" separates strokes; "Z" closes).
    static final Map<Character, String> GL2 = new LinkedHashMap<>();
    static {
        String[][] t = {
            {"A", "0,12 0,4~1.2 2.8,0~0.8 5.2,0~0.8 8,4~1.2 8,12; 0,6.6 8,6.6"},   // F-35: flat top, straight legs
            {"B", "0,12 0,0 7,0~1.7 7,5.2~1.7 0,5.2; 0,5.2 8,5.2~2.3 8,12~2.3 0,12"},
            {"C", "8,2.4 8,0~2 0,0~2 0,12~2 8,12~2 8,9.6"},
            {"D", "0,0 8,0~3 8,12~3 0,12 Z"},
            {"E", "8,0 0,0 0,12 8,12; 0,6 6,6"}, {"F", "8,0 0,0 0,12; 0,6 6,6"},
            {"G", "8,2.4 8,0~2 0,0~2 0,12~2 8,12~2 8,7 5,7"}, {"H", "0,0 0,12; 8,0 8,12; 0,6 8,6"},
            {"I", "2,0 6,0; 4,0 4,12; 2,12 6,12"}, {"J", "8,0 8,12~2 0,12~2 0,9.6"},
            {"K", "0,0 0,12; 8,0 0,7; 3,5 8,12"}, {"L", "0,0 0,12 8,12"},
            {"M", "0,12 0,0 4,5 8,0 8,12"},                                   // shallow middle
            {"N", "0,12 0,0 8,12 8,0"},
            {"O", "0,0~2.5 8,0~2.5 8,12~2.5 0,12~2.5 Z"},
            {"P", "0,12 0,0 8,0~2 8,6~2 0,6"},
            {"Q", "0,0~2.5 8,0~2.5 8,12~2.5 0,12~2.5 Z; 5,9 8,12"},
            {"R", "0,12 0,0 8,0~2 8,6~2 0,6; 5,6 8,12"},
            {"S", "7.2,2.1 7.2,0~1.7 0.8,0~1.7 0.8,5.2~1.7 8,5.2~2.3 8,12~2.3 0,12~2.3 0,9.7"},
            {"T", "0,0 8,0; 4,0 4,12"}, {"U", "0,0 0,12~2 8,12~2 8,0"}, {"V", "0,0 4,12 8,0"},
            {"W", "0,0 0.4,12 4,8.3 7.6,12 8,0"},                             // near-vertical legs, low middle peak
            {"X", "0,0 8,12; 8,0 0,12"}, {"Y", "0,0 4,6 8,0; 4,6 4,12"}, {"Z", "0,0 8,0 0,12 8,12"},
            {"0", "0,0~2.5 8,0~2.5 8,12~2.5 0,12~2.5 Z; 1.4,10.1 6.6,1.9"},   // slashed
            {"1", "1,2 4,0 4,12; 0,12 8,12"},
            {"2", "0,2.4 0,0~2 8,0~2 8,4.2~1.5 0,12 8,12"},
            {"3", "0.8,2.1 0.8,0~1.7 7.2,0~1.7 7.2,5.2~1.7 3,5.2; 5.5,5.2 8,5.2~2.3 8,12~2.3 0,12~2.3 0,9.7"},
            {"4", "6,12 6,0 0,8 8,8"},
            {"5", "8,0 0,0 0,5 8,5~2.2 8,12~2.2 0,12~2.2 0,9.8"},
            {"6", "7.2,0 0,0~3 0,12~2.2 8,12~2.2 8,5~2.2 0,5"},
            {"7", "0,0 8,0 3,12"},
            {"8", "0.8,0~1.7 7.2,0~1.7 7.2,5.2~1.7 0.8,5.2~1.7 Z; 0,5.2~2.3 8,5.2~2.3 8,12~2.3 0,12~2.3 Z"},
            {"9", "8,7 0,7~2.2 0,0~2.2 8,0~2.2 8,12~3 0.8,12"},
            {"/", "0,12 8,0"}, {"-", "1,6 7,6"}, {">", "0,1 8,6 0,11"},
            {"%", "0,12 8,0; 0,0 2,0 2,2 0,2 Z; 6,10 8,10 8,12 6,12 Z"},
            {":", "1.5,3.6 1.5,4.4; 1.5,8.6 1.5,9.4"},                        // time colon, centred in its advance
        };
        for (String[] e : t) GL2.put(e[0].charAt(0), e[1]);
    }

    static String STYLE = "orig";   // orig | chamfer | round
    static double K = 1.0;          // Latin width factor
    static double RMUL = 1.25;      // corner radius factor for the round style (smaller = tighter corners)

    // ---- Lunar-date CJK skeletons (12 x 12 grid; "x,y~r" = rounded corner, "Z" = closed) ---
    static final Map<Character, String> CJK = new LinkedHashMap<>();
    static {
        String[][] t = {
            {"一", "1,6 11,6"},
            {"二", "2,3 10,3; 0.5,10 11.5,10"},
            {"三", "2,1.5 10,1.5; 3,6 9,6; 0.5,10.5 11.5,10.5"},
            {"四", "1,1.5 11,1.5 11,11 1,11 Z; 4.5,1.5 4.5,5 3,8.5; 7.5,1.5 7.5,7~1.5 9.5,7"},
            {"五", "1.5,1 10.5,1; 5,1 4,11; 2,5.5 9.5,5.5~1 9.5,11; 0.5,11 11.5,11"},
            {"六", "5.5,0.5 6.5,2.5; 0.5,4 11.5,4; 4.5,6.5 2,11; 7.5,6.5 10,11"},
            {"七", "0.5,5.5 11.5,4; 5,0.5 5,11.5~2 11.5,11.5~1 11.5,9.5"},
            {"八", "4.5,1.5 4,6.5~4 0.5,11; 7,2 8,7~4 11.5,11"},
            {"九", "1,4.5 8,4.5~1 8,11.5~1.5 11.5,11.5~1 11.5,9.5; 4.5,0.5 4.5,6~3 1,11.5"},
            {"十", "0.5,5 11.5,5; 6,0.5 6,11.5"},
            {"正", "1,1 11,1; 6,1 6,11; 6,6 10,6; 2.5,6 2.5,11; 0.5,11 11.5,11"},
            {"冬", "4.6,0.3 3.6,1.6 2.4,3 1,4.3; 3.8,1.4 10.2,1.4 8.6,3 6.6,4.4 4.2,5.7 0.5,7; "
                 + "3.4,2.8 5,3.9 7,5 9,5.9 11.5,6.6; 4,7.8 8.2,8.9; 2.5,10.2 8.5,11.4"},
            {"腊", "1.5,1 1.5,8.5~2 0.3,11.5; 1.5,1 4.8,1~1 4.8,11.5~1 3.8,11.5; 1.5,4.5 4.8,4.5; 1.5,7.5 4.8,7.5; "
                 + "6,3 12,3; 7.5,0.5 7.5,5; 10.5,0.5 10.5,5; 5.8,5 12,5; 7,6.5 11,6.5 11,11.5 7,11.5 Z; 7,9 11,9"},
            {"月", "3,1 3,8~3 1,11.5; 3,1 10,1~1 10,10.5~1.5 8.5,11.5; 3,4.5 10,4.5; 3,8 10,8"},
            {"初", "2,0.5 3,1.9; 0.5,3 4.3,3 0.6,7.3; 2.6,5.4 2.6,11.5; 4.7,5 3.7,5.9; 3.7,7.2 4.8,8.1;"
                 + "5.8,1.5 11.5,1.5~1 11.5,10.5~1.5 10,11.5; 8,1.5 8,5~3 5.8,11.5"},
            {"廿", "0.5,4.5 11.5,4.5; 3.5,1 3.5,11 8.5,11 8.5,1"},
            {"闰", "2,0.5 3,1.5; 1.5,3 1.5,11.5; 4,1.5 11,1.5~1 11,10.5~1.5 9.5,11.5; "
                 + "4,4 8.5,4; 4.5,7 8,7; 3.5,10 9,10; 6.25,4 6.25,10"},
        };
        for (String[] e : t) CJK.put(e[0].charAt(0), e[1]);
    }
    static final String CJK_CHARS = "一二三四五六七八九十正冬腊月初廿闰";

    /** Mockup default stroke width: max(1.4, h / 10.5). */
    static double def(double h) { return Math.max(1.4, h / 10.5); }

    record Spec(String id, double h, double sw, String chars) {}

    static final String AZ = "ABCDEFGHIJKLMNOPQRSTUVWXYZ", DIG = "0123456789";

    // Sizes and stroke widths from mockup_final.html (PF / PV and the S(...) calls); lunar = CJK.
    static List<Spec> specs(boolean big) {
        List<Spec> s = new ArrayList<>();
        double timeH = big ? 94 : 74, textH = big ? 25 : 21, tapeV = big ? 20 : 18, hdr = 16,
               val = big ? 34 : 29, unit = 16, tab = tapeV, lun = big ? 36 : 29, date = big ? 30 : 25;
        s.add(new Spec("FTime", timeH, big ? 6 : 5, DIG + ":"));         // about the old weight ratio (106 / 7, 86 / 6)
        s.add(new Spec("FTimeAod", timeH, 2.5, DIG + ":"));              // always-on: thin but readable
        s.add(new Spec("FText", textH, def(textH), DIG + "-"));           // station model numbers
        s.add(new Spec("FDate", date, 3, AZ + DIG + "/"));               // weight of the earlier 32 / 27 px date
        s.add(new Spec("FDateAod", date, 2, AZ + DIG + "/"));
        s.add(new Spec("FTapeVal", tapeV, def(tapeV) + 1, DIG + "-"));   // 1 px heavier than the default
        s.add(new Spec("FTapeLbl", 11, 1.3, "HRALT"));
        s.add(new Spec("FGaugeVal", 14, 2, AZ + DIG + "-"));              // gauge label and value: the tape value glyphs, smaller
        s.add(new Spec("FTapeUnit", big ? 11 : 10, 1.2, "10M"));
        s.add(new Spec("FHdr", hdr, 1.5, AZ + DIG + ">"));
        s.add(new Spec("FVal", val, def(val), DIG + "-"));
        s.add(new Spec("FUnit", unit, 1.5, DIG + "%/"));
        s.add(new Spec("FTabWarn", tab, def(tab), "BINGOSTRE"));
        s.add(new Spec("FLunar", lun, big ? 4 : 3, CJK_CHARS));                      // active and always-on
        return s;
    }

    /** Advance in grid units: glyph width + 3-unit gap (Latin width scales with K). */
    static double adv(char c) { return c >= 0x2E80 ? 15 : c == ' ' ? 6 * K : c == '-' ? 6 * K + 3 : c == ':' ? 3 * K + 3 : 8 * K + 3; }

    /** Advance in whole pixels (same rounding as Stroke.advPx on the watch). */
    static int advPx(char c, double h) { return (int) Math.round(adv(c) * h / 12.0); }

    // ---- geometry -----------------------------------------------------------------------

    /** Mockup SVG path (M/L/Z, grid units) -> Path2D scaled by s. */
    static Path2D svgPath(String d, double s) {
        Path2D p = new Path2D.Double();
        java.util.regex.Matcher m = java.util.regex.Pattern.compile("([MLZ])([^MLZ]*)").matcher(d);
        while (m.find()) {
            String cmd = m.group(1);
            if (cmd.equals("Z")) { p.closePath(); continue; }
            String[] xy = m.group(2).split(",");
            double x = Double.parseDouble(xy[0]) * s, y = Double.parseDouble(xy[1]) * s;
            if (cmd.equals("M")) p.moveTo(x, y); else p.lineTo(x, y);
        }
        return p;
    }

    /** CJK skeleton -> Path2D (fillets expanded), scaled by s. */
    static Path2D skeletonPath(String spec, double s) {
        Path2D p = new Path2D.Double();
        for (String pl : spec.split(";")) {
            List<double[]> pts = expand(pl);
            for (int i = 0; i < pts.size(); i++) {
                double x = pts.get(i)[0] * s, y = pts.get(i)[1] * s;
                if (i == 0) p.moveTo(x, y); else p.lineTo(x, y);
            }
        }
        return p;
    }

    static final int ARC_STEPS = 8;

    /** Expands one polyline skeleton ("x,y~r ... [Z]") into points with arc fillets (grid units). */
    static List<double[]> expand(String spec) { return expand(spec, false, 1.0, 1.0); }

    /** As above; chamfer = straight cut between the tangent points, rMul scales radii, k scales x. */
    static List<double[]> expand(String spec, boolean chamfer, double rMul, double xk) {
        spec = spec.trim();
        boolean closed = spec.endsWith("Z");
        if (closed) spec = spec.substring(0, spec.length() - 1).trim();
        String[] toks = spec.split("\\s+");
        int n = toks.length;
        double[][] p = new double[n][];
        double[] r = new double[n];
        for (int i = 0; i < n; i++) {
            String[] parts = toks[i].split("~");
            String[] xy = parts[0].split(",");
            p[i] = new double[]{Double.parseDouble(xy[0]) * xk, Double.parseDouble(xy[1])};
            r[i] = parts.length > 1 ? Double.parseDouble(parts[1]) * rMul : 0;
        }
        List<double[]> out = new ArrayList<>();
        for (int i = 0; i < n; i++) {
            boolean interior = closed || (i > 0 && i < n - 1);
            if (r[i] <= 0 || !interior) { out.add(p[i]); continue; }
            int ia = (i - 1 + n) % n, ib = (i + 1) % n;
            double[] a = p[ia], b = p[ib], v = p[i];
            double l1 = Math.hypot(a[0] - v[0], a[1] - v[1]), l2 = Math.hypot(b[0] - v[0], b[1] - v[1]);
            double u1x = (a[0] - v[0]) / l1, u1y = (a[1] - v[1]) / l1;
            double u2x = (b[0] - v[0]) / l2, u2y = (b[1] - v[1]) / l2;
            double theta = Math.acos(Math.max(-1, Math.min(1, u1x * u2x + u1y * u2y)));
            if (theta < 0.05 || theta > Math.PI - 0.05) { out.add(v); continue; }
            double d = r[i] / Math.tan(theta / 2);
            boolean aRound = r[ia] > 0 && (closed || ia > 0);
            boolean bRound = r[ib] > 0 && (closed || ib < n - 1);
            d = Math.min(d, Math.min(l1 * (aRound ? 0.5 : 1), l2 * (bRound ? 0.5 : 1)));
            double rr = d * Math.tan(theta / 2);
            double t1x = v[0] + u1x * d, t1y = v[1] + u1y * d, t2x = v[0] + u2x * d, t2y = v[1] + u2y * d;
            double bx = u1x + u2x, by = u1y + u2y, bl = Math.hypot(bx, by);
            double cd = rr / Math.sin(theta / 2);
            double cx = v[0] + bx / bl * cd, cy = v[1] + by / bl * cd;
            if (chamfer) { out.add(new double[]{t1x, t1y}); out.add(new double[]{t2x, t2y}); continue; }
            double a1 = Math.atan2(t1y - cy, t1x - cx), a2 = Math.atan2(t2y - cy, t2x - cx);
            double sw = a2 - a1;
            while (sw > Math.PI) sw -= 2 * Math.PI;
            while (sw < -Math.PI) sw += 2 * Math.PI;
            for (int k = 0; k <= ARC_STEPS; k++) {
                double ang = a1 + sw * k / ARC_STEPS;
                out.add(new double[]{cx + rr * Math.cos(ang), cy + rr * Math.sin(ang)});
            }
        }
        if (closed) out.add(out.get(0));
        return out;
    }

    // ---- rendering ----------------------------------------------------------------------

    static Graphics2D g2(BufferedImage img) {
        Graphics2D g = img.createGraphics();
        g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        g.setRenderingHint(RenderingHints.KEY_STROKE_CONTROL, RenderingHints.VALUE_STROKE_PURE);
        g.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
        return g;
    }

    static Path2D glyphPath(char c, double h) {
        double s = h / 12.0;
        if (GL.containsKey(c)) return svgPath(GL.get(c), s);
        if (CJK.containsKey(c)) return skeletonPath(CJK.get(c), s);
        throw new IllegalArgumentException("no glyph for " + c);
    }

    /** Glyph as polylines in grid units (closed polylines repeat their first point). */
    static List<List<double[]>> polylines(char c) {
        List<List<double[]>> out = new ArrayList<>();
        if (!STYLE.equals("orig") && GL2.containsKey(c)) {
            for (String pl : GL2.get(c).split(";")) out.add(expand(pl, STYLE.equals("chamfer"), STYLE.equals("round") ? RMUL : 1.0, K));
        } else if (GL.containsKey(c)) {
            List<double[]> cur = null;
            java.util.regex.Matcher m = java.util.regex.Pattern.compile("([MLZ])([^MLZ]*)").matcher(GL.get(c));
            while (m.find()) {
                String cmd = m.group(1);
                if (cmd.equals("Z")) { cur.add(cur.get(0)); continue; }
                String[] xy = m.group(2).split(",");
                double[] p = {Double.parseDouble(xy[0]) * K, Double.parseDouble(xy[1])};
                if (cmd.equals("M")) { cur = new ArrayList<>(); out.add(cur); }
                cur.add(p);
            }
        } else if (CJK.containsKey(c)) {
            for (String pl : CJK.get(c).split(";")) out.add(expand(pl));
        } else {
            throw new IllegalArgumentException("no glyph for " + c);
        }
        return out;
    }

    /**
     * Pixel-grid hinting. Every coordinate value that carries a vertical stem (for x) or a
     * horizontal bar (for y) is moved so that the stroke of integer width W covers whole pixels:
     * centre on a pixel centre for odd W, on a pixel boundary for even W. All other coordinates
     * (diagonals, chamfers, curves) are interpolated between the neighbouring snapped stems, so
     * the glyph shape is kept while straight strokes render crisp instead of as grey double lines.
     */
    static double[][] hintMap(List<List<double[]>> pls, int axis, double s, double off, int W, double... always) {
        TreeMap<Double, Double> stems = new TreeMap<>();
        for (List<double[]> pl : pls)
            for (int i = 1; i < pl.size(); i++) {
                double[] a = pl.get(i - 1), b = pl.get(i);
                if (Math.abs(a[1 - axis] - b[1 - axis]) > 1e-6 && Math.abs(a[axis] - b[axis]) < 1e-6) stems.put(a[axis], 0.0);
            }
        for (double u : always) stems.put(u, 0.0);
        for (Map.Entry<Double, Double> e : stems.entrySet()) {
            double px = off + e.getKey() * s;
            double snapped = (W % 2 == 1) ? Math.floor(px) + 0.5 : Math.round(px);
            e.setValue(snapped - px);
        }
        double[][] m = new double[stems.size()][];
        int i = 0;
        for (Map.Entry<Double, Double> e : stems.entrySet()) m[i++] = new double[]{e.getKey(), e.getValue()};
        return m;
    }

    static double mapped(double u, double[][] m, double s, double off) {
        double d = 0;
        if (m.length > 0) {
            if (u <= m[0][0]) d = m[0][1];
            else if (u >= m[m.length - 1][0]) d = m[m.length - 1][1];
            else for (int i = 1; i < m.length; i++) if (u <= m[i][0]) {
                double t = (u - m[i - 1][0]) / (m[i][0] - m[i - 1][0]);
                d = m[i - 1][1] + t * (m[i][1] - m[i - 1][1]);
                break;
            }
        }
        return off + u * s + d;
    }

    /** Hinted glyph outline path in cell pixel coordinates (grid origin at (pad, pad)). */
    static Path2D hintedPath(char c, double h, int W, int pad) {
        double s = h / 12.0;
        List<List<double[]>> pls = polylines(c);
        double[][] mx = hintMap(pls, 0, s, pad, W);
        double[][] my = hintMap(pls, 1, s, pad, W, 0.0, 12.0);   // cap line and baseline always crisp
        Path2D p = new Path2D.Double();
        for (List<double[]> pl : pls)
            for (int i = 0; i < pl.size(); i++) {
                double x = mapped(pl.get(i)[0], mx, s, pad), y = mapped(pl.get(i)[1], my, s, pad);
                if (i == 0) p.moveTo(x, y); else p.lineTo(x, y);
            }
        return p;
    }

    /** Stroke width actually baked: the mockup width rounded to whole pixels (min 1) for crisp stems. */
    static int bakedWidth(Spec sp) { return Math.max(1, (int) Math.round(sp.sw)); }

    /** Pen width actually drawn: the whole-pixel width, except always-on fonts keep their exact width
     *  (2.5 px time) and are hinted as for the rounded width. */
    static float drawWidth(Spec sp) { return sp.id().endsWith("Aod") ? (float) sp.sw : bakedWidth(sp); }

    /** Renders the atlas PNG and returns its glyph table as a JSON object. */
    static String bake(Spec sp, Path dir, String file) throws IOException {
        int W = bakedWidth(sp);
        int pad = (int) Math.ceil(W / 2.0) + 1;
        int cellH = (int) Math.ceil(sp.h) + 2 * pad;
        String chars = sp.chars;
        int[] cw = new int[chars.length()];
        int totalW = 0;
        for (int i = 0; i < chars.length(); i++) {
            double gw = chars.charAt(i) >= 0x2E80 ? 12 : 8 * K;
            cw[i] = (int) Math.ceil(gw * sp.h / 12.0) + 2 * pad;
            totalW += cw[i] + 1;
        }
        // Wrap into rows no wider than 512 px.
        int maxW = 512, x = 0, y = 0, rowW = 0;
        int[] gx = new int[chars.length()], gy = new int[chars.length()];
        for (int i = 0; i < chars.length(); i++) {
            if (x + cw[i] > maxW) { x = 0; y += cellH + 1; }
            gx[i] = x; gy[i] = y; x += cw[i] + 1; rowW = Math.max(rowW, x);
        }
        BufferedImage img = new BufferedImage(Math.max(rowW, 1), y + cellH, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = g2(img);
        g.setColor(Color.WHITE);
        g.setStroke(new BasicStroke(drawWidth(sp), BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
        StringJoiner xs = new StringJoiner(","), ys = new StringJoiner(","), ws = new StringJoiner(",");
        for (int i = 0; i < chars.length(); i++) {
            char c = chars.charAt(i);
            AffineTransform keep = g.getTransform();
            g.translate(gx[i], gy[i]);
            g.draw(hintedPath(c, sp.h, W, pad));
            g.setTransform(keep);
            xs.add("" + gx[i]); ys.add("" + gy[i]); ws.add("" + cw[i]);
        }
        g.dispose();
        ImageIO.write(img, "png", dir.resolve(file + ".png").toFile());
        return "\"" + sp.id + "\":{\"c\":\"" + chars + "\",\"x\":[" + xs + "],\"y\":[" + ys + "],\"w\":[" + ws
            + "],\"ch\":" + cellH + ",\"p\":" + pad + "}";
    }

    /** Preview: every font's character set on black, at 2x, for review. */
    static void preview(List<Spec> specs, Path file) throws IOException {
        int z = 2, W = 0, H = 10;
        for (Spec sp : specs) { W = Math.max(W, (int) (sp.chars.length() * 15 * sp.h / 12) + 20); H += (int) (sp.h * 1.5) + 8; }
        BufferedImage img = new BufferedImage(Math.min(W, 1400) * z, H * z, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = g2(img);
        g.scale(z, z);
        double y = 8;
        for (Spec sp : specs) {
            g.setColor(new Color(0x33FF66));
            g.setStroke(new BasicStroke(drawWidth(sp), BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
            int x = 10;
            for (char c : sp.chars.toCharArray()) {
                if (x > 1380) break;
                AffineTransform keep = g.getTransform();
                g.translate(x, (int) y);
                g.draw(hintedPath(c, sp.h, bakedWidth(sp), 0));
                g.setTransform(keep);
                x += advPx(c, sp.h);
            }
            y += sp.h * 1.5 + 8;
        }
        g.dispose();
        ImageIO.write(img, "png", file.toFile());
    }

    /**
     * Styles baked into the app, selectable at run time (PcdView.FONT_STYLE, later a setting).
     * Each style gets its own atlases (<Id>_<tag>.png) and glyph table (Glyphs_<tag>); the lunar
     * CJK font does not depend on the style and is baked once.
     */
    static final String[][] STYLES = {
        // tag, style, width k, radius factor
        {"D", "chamfer", "0.85", "1.0"},    // chamfered corners, condensed
        {"G", "round", "0.85", "0.7"},      // small rounded corners, condensed (default)
        {"E", "round", "0.85", "1.25"},     // large rounded corners, condensed
    };

    public static void main(String[] argv) throws Exception {
        String previewDir = argv.length > 0 ? argv[0] : null;
        for (String dev : new String[]{"fenix847mm", "venu3s"}) {
            boolean big = dev.startsWith("fenix");
            Path dir = Paths.get("resources-" + dev, "fonts");
            Files.createDirectories(dir);
            try (DirectoryStream<Path> old = Files.newDirectoryStream(dir, "*.{png,json}")) { for (Path p : old) Files.delete(p); }
            // PNG packing without palette keeps the full 8-bit alpha (font resources keep ~4 levels).
            StringBuilder xml = new StringBuilder("<resources>\n    <!-- GENERATED by tools/FontGen.java -->\n    <drawables>\n");
            StringBuilder data = new StringBuilder();
            Set<String> cjkDone = new HashSet<>();
            for (String[] st : STYLES) {
                STYLE = st[1]; K = Double.parseDouble(st[2]); RMUL = Double.parseDouble(st[3]);
                StringJoiner json = new StringJoiner(",\n", "{\n", "\n}\n");
                // Advances in grid units for Stroke on the watch: [Latin, '-', ' ', ':'].
                json.add("\"_adv\":[" + adv('A') + "," + adv('-') + "," + adv(' ') + "," + adv(':') + "]");
                for (Spec sp : specs(big)) {
                    boolean cjk = sp.id().startsWith("FLunar");
                    String file = cjk ? sp.id() : sp.id() + "_" + st[0];
                    json.add(bake(sp, dir, file));
                    if (cjk && !cjkDone.add(sp.id())) continue;
                    xml.append("        <bitmap id=\"").append(file).append("\" filename=\"").append(file)
                       .append(".png\" packingFormat=\"png\" dithering=\"none\" automaticPalette=\"false\"/>\n");
                }
                String jf = "glyphs_" + st[0] + ".json";
                Files.write(dir.resolve(jf), json.toString().getBytes(StandardCharsets.UTF_8));
                data.append("        <jsonData id=\"Glyphs_").append(st[0]).append("\" filename=\"").append(jf).append("\"/>\n");
                if (previewDir != null) preview(specs(big), Paths.get(previewDir, "fonts-" + dev + "-" + st[0] + ".png"));
            }
            xml.append("    </drawables>\n    <jsonDataResources>\n").append(data).append("    </jsonDataResources>\n</resources>\n");
            Files.write(dir.resolve("fonts.xml"), xml.toString().getBytes(StandardCharsets.UTF_8));
            System.out.println("baked " + STYLES.length + " styles for " + dev);
        }
    }
}