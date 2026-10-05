import Toybox.Lang;

// Chinese lunar date, computed on the watch (requirements §5).
module Lunar {
    const FIRST_YEAR = 1899;

    // One entry per lunar year 1899..2100, generated from the ICU Chinese calendar
    // and checked against it for every day 1900-01-01 .. 2100-12-31.
    //   bits 0-3   leap month (0 = none)
    //   bits 4-15  months 12..1 (bit 15 = month 1): 1 = 30 days, 0 = 29 days
    //   bit 16     leap month has 30 days
    //   bits 17+   0-based Gregorian day of year of lunar New Year in year Y
    const TABLE = [
        0x50ab50, 0x3c4bd8, 0x624ae0, 0x4ca570, 0x3854d5, 0x5cd260, 0x44d950, 0x316554,
        0x5656a0, 0x409ad0, 0x2a55d2, 0x504ae0, 0x3aa5b6, 0x60a4d0, 0x48d250, 0x33d255,
        0x58b540, 0x42d6a0, 0x2d8da3, 0x5295b0, 0x3f4977, 0x644970, 0x4ca4b0, 0x37b0b6,
        0x5c6a50, 0x466d40, 0x2fab54, 0x562b60, 0x409570, 0x2c52f2, 0x504970, 0x3a6566,
        0x5ed4a0, 0x48ea50, 0x336a95, 0x585ad0, 0x442b60, 0x2f86e3, 0x5292e0, 0x3dc8d7,
        0x62c950, 0x4cd4a0, 0x35d8a6, 0x5ab550, 0x4656a0, 0x31a5b4, 0x5625d0, 0x4092d0,
        0x2ad2b2, 0x50a950, 0x38b557, 0x5e6ca0, 0x48b550, 0x355355, 0x584db0, 0x4425b0,
        0x2f8573, 0x5452b0, 0x3ca9a8, 0x60e950, 0x4c6aa0, 0x36aea6, 0x5aab50, 0x464b60,
        0x30aae4, 0x56a570, 0x405260, 0x28f263, 0x4ed950, 0x3a5b57, 0x5e56a0, 0x4896d0,
        0x344dd5, 0x5a4ad0, 0x42a4d0, 0x2cd4d4, 0x52d250, 0x3cd558, 0x60b540, 0x4ab6a0,
        0x3795a6, 0x5c95b0, 0x4649b0, 0x30a974, 0x56a4b0, 0x40b27a, 0x646a50, 0x4e6d40,
        0x39ad47, 0x5eab60, 0x489570, 0x344af5, 0x5a4970, 0x4464b0, 0x2c74a3, 0x50ea50,
        0x3c6b58, 0x625ac0, 0x4aab60, 0x3696e5, 0x5c92e0, 0x46c960, 0x2ed954, 0x54d4a0,
        0x3eda50, 0x2a7552, 0x4e56a0, 0x38abb7, 0x6025d0, 0x4a92d0, 0x32cab5, 0x58a950,
        0x42b4a0, 0x2cbca4, 0x50ad50, 0x3c55d9, 0x624ba0, 0x4ca5b0, 0x375176, 0x5c5270,
        0x46a930, 0x307954, 0x546aa0, 0x3ead50, 0x2a5b52, 0x504b60, 0x38a6e6, 0x5ea4f0,
        0x4a5260, 0x32ea65, 0x56d520, 0x40daa0, 0x2c76a3, 0x5296d0, 0x3c4afb, 0x624ad0,
        0x4ca4d0, 0x37d0b6, 0x5ad250, 0x44d520, 0x2edd45, 0x54b5a0, 0x3e56d0, 0x2a55b2,
        0x5049b0, 0x3aa577, 0x5ea4b0, 0x48aa50, 0x33b255, 0x586d20, 0x40ada0, 0x2d4b63,
        0x529370, 0x3e49f8, 0x624970, 0x4c64b0, 0x3768a6, 0x5aea50, 0x446b20, 0x2fa6c4,
        0x54aae0, 0x4092e0, 0x28d2e3, 0x4ec960, 0x38d557, 0x5ed4a0, 0x46da50, 0x325d55,
        0x5856a0, 0x42a6d0, 0x2c55d4, 0x5292d0, 0x3ca9b8, 0x62a950, 0x4ab4a0, 0x34b6a6,
        0x5aad50, 0x4655a0, 0x2eaba4, 0x54a5b0, 0x4052b0, 0x2ab273, 0x4e6930, 0x387337,
        0x5e6aa0, 0x48ad50, 0x334b55, 0x584b60, 0x42a570, 0x2e54e4, 0x50d160, 0x3ae968,
        0x60d520, 0x4adaa0, 0x356aa6, 0x5a56d0, 0x464ae0, 0x30a9d4, 0x54a2d0, 0x3ed150,
        0x28f252, 0x4ed520
    ] as Array<Number>;

    const DIGITS = "一二三四五六七八九十";
    const CUM_DAYS = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334] as Array<Number>;

    function isLeapYear(y as Number) as Boolean {
        return (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;
    }

    // Returns [month 1..12, day 1..30, isLeapMonth] or null outside 1900..2100.
    function fromGregorian(y as Number, m as Number, d as Number) as Array? {
        if (y < FIRST_YEAR + 1 || y > FIRST_YEAR + TABLE.size() - 1) { return null; }
        var doy = CUM_DAYS[m - 1] + d - 1;
        if (m > 2 && isLeapYear(y)) { doy += 1; }
        var v = TABLE[y - FIRST_YEAR];
        var off = doy - (v >> 17);
        if (off < 0) {
            var py = y - 1;
            v = TABLE[py - FIRST_YEAR];
            off = doy + (isLeapYear(py) ? 366 : 365) - (v >> 17);
        }
        var leapMonth = v & 0xF;
        for (var mo = 1; mo <= 12; mo++) {
            var n = ((v >> (16 - mo)) & 1) == 1 ? 30 : 29;
            if (off < n) { return [mo, off + 1, false]; }
            off -= n;
            if (mo == leapMonth) {
                var n2 = ((v >> 16) & 1) == 1 ? 30 : 29;
                if (off < n2) { return [mo, off + 1, true]; }
                off -= n2;
            }
        }
        return null;
    }

    function digit(n as Number) as String {
        return DIGITS.substring(n - 1, n) as String;
    }

    // e.g. 八月十六, 闰六月初一, 正月廿九, 腊月三十
    function format(y as Number, m as Number, d as Number) as String? {
        var l = fromGregorian(y, m, d);
        if (l == null) { return null; }
        var mo = l[0] as Number;
        var day = l[1] as Number;
        var s = (l[2] as Boolean) ? "闰" : "";
        if (mo == 1) { s += "正"; }
        else if (mo == 11) { s += "冬"; }
        else if (mo == 12) { s += "腊"; }
        else { s += digit(mo); }
        s += "月";
        if (day <= 10) { s += "初" + digit(day); }
        else if (day < 20) { s += "十" + digit(day - 10); }
        else if (day == 20) { s += "二十"; }
        else if (day < 30) { s += "廿" + digit(day - 20); }
        else { s += "三十"; }
        return s;
    }
}
