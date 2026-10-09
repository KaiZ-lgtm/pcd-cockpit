import Toybox.Lang;
import Toybox.Math;

// Units of what is drawn (phone setting units, Settings.imperial). Data stays in SI units (Data.mc); only
// the strings and the altitude tape scale change. Wind stays in knots either way (barbs, as in aviation).
module Units {
    const FT_PER_M = 3.28084;
    const M_PER_MI = 1609.344;
    const PA_PER_INHG = 3386.389;

    // Station model temperature / dew point: whole °C, or whole °F.
    function temp(c as Numeric?, imp as Boolean) as String {
        if (c == null) { return "--"; }
        var v = c.toFloat();
        if (imp) { v = v * 1.8 + 32; }
        return Math.round(v).toNumber().toString();
    }

    // Sea-level pressure: whole hPa ("1013", as METAR's Q1013), or inHg with two decimals ("29.92", as
    // the US altimeter setting A2992).
    function pressure(pa as Numeric?, imp as Boolean) as String {
        if (pa == null) { return "--"; }
        if (imp) { return (pa.toFloat() / PA_PER_INHG).format("%.2f"); }
        return (pa.toFloat() / 100.0 + 0.5).toNumber().toString();
    }

    // Altitude tape: [value in box units or null, minor tick, major tick (box units), unit label above the
    // box (two words stack)]. Metric: tens of metres, a tick every 20 m, a long one every 100 m. Imperial:
    // hundreds of feet (like a flight level), a tick every 100 ft, a long one every 500 ft. Clamped to
    // -99..999 (the box holds 3 characters).
    function altTape(m as Float?, imp as Boolean) as Array {
        var v = null;
        if (m != null) {
            v = imp ? m * FT_PER_M / 100.0 : m / 10.0;
            if (v > 999) { v = 999.0; }
            if (v < -99) { v = -99.0; }
        }
        return imp ? [v, 1, 5, "100 FT"] : [v, 2, 10, "10M"];
    }

    // Distance in metres as km, or statute miles (MI; visibility SM, as in US METARs): one decimal under
    // 100 ("8.4", shorter form "8"), whole from 100 up. [value or null, unit, null, shorter forms or null]
    // as Field.read.
    function dist(m as Float?, imp as Boolean, vis as Boolean) as Array {
        var unit = imp ? (vis ? "SM" : "MI") : "KM";
        if (m == null) { return [null, unit, null, null]; }
        var k = m / (imp ? M_PER_MI : 1000.0);
        var whole = (k + 0.5).toNumber().toString();
        if (k < 99.95) { return [k.format("%.1f"), unit, null, [whole]]; }
        return [whole, unit, null, null];
    }

    // Climb in metres as whole metres (M) or feet (FT); [value or null, unit].
    function climb(m as Float?, imp as Boolean) as Array {
        var unit = imp ? "FT" : "M";
        if (m == null) { return [null, unit]; }
        return [((imp ? m * FT_PER_M : m) + 0.5).toNumber(), unit];
    }
}
