import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.Position;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.UserProfile;
import Toybox.Weather;

// Snapshot of everything the face shows (requirements §5).
class Data {
    var hr as Number? = null;
    var zones as Array<Number>? = null;
    var altitude as Float? = null;        // metres
    var bodyBattery as Number? = null;
    var spo2 as Number? = null;
    var stress as Number? = null;
    var actMin as Number? = null;
    var actGoal as Number? = null;
    var battery as Float = 100.0;
    // Weather (null wxOk = no weather at all).
    var wxOk as Boolean = false;
    var wxStale as Boolean = false;
    var wxCond as Number? = null;
    var wxCover as Number = 0;
    var wxTemp as Float? = null;          // °C
    var wxDew as Float? = null;           // °C
    var wxPressure as Float? = null;      // Pa
    var wxWindDir as Number? = null;      // degrees, from
    var wxWindKt as Float? = null;
    var sunIsSet as Boolean = true;       // true: next event is sunset (SS)
    var sunTime as String? = null;       // "HHMM"
    // Slot-only fields (Fields.mc), read once a minute; null = not available on this watch / no data.
    var steps as Number? = null, stepGoal as Number? = null;
    var floors as Number? = null, floorsGoal as Number? = null, floorsDn as Number? = null;
    var kcal as Number? = null;
    var distM as Float? = null;           // today, metres
    var actDay as Number? = null;         // intensity minutes today
    var climbM as Float? = null;          // metres climbed today
    var vo2Run as Number? = null, vo2Bike as Number? = null;
    var runWkM as Float? = null, bikeWkM as Float? = null;   // this week, metres
    var rhr as Number? = null;
    var sleepScore as Number? = null;
    var visM as Float? = null;            // weather visibility, metres
    var pop as Number? = null;            // chance of precipitation, %
    var utcTime as String? = null;        // "HHMM"

    private var _slowMinute as Number = -1;

    // Fast values (every update) plus slow values once per minute.
    function refresh(now as Time.Moment, minuteKey as Number) as Void {
        var info = Activity.getActivityInfo();
        hr = null;
        altitude = null;
        if (info != null) {
            hr = info.currentHeartRate;
            if (info.altitude != null) { altitude = info.altitude.toFloat(); }
        }
        if (hr == null) { hr = lastHr(); }
        if (minuteKey != _slowMinute) {
            _slowMinute = minuteKey;
            refreshSlow(now, info);
        }
        applyDemo(now.value() / 3);
    }

    (:live)
    private function applyDemo(step as Number) as Void {}

    // Demo build (build.ps1 -Demo): cycle synthetic scenarios every 3 s to exercise every
    // weather symbol, wind barb, HR zone and warning in the simulator.
    (:demo)
    private function applyDemo(step as Number) as Void {
        var i = step % 540;
        wxOk = i % 13 != 12;
        wxStale = i % 11 == 10;
        wxCond = i % 54;
        var pc = (i / 54) % 2 == 0 ? null : (i * 7) % 100;
        wxCover = Wx.cover(wxCond, pc, i % 2 == 0 ? 500 : 5000);
        var cold = (i / 4) % 2 == 1;
        wxTemp = cold ? -12.0 : 22.0;
        wxDew = cold ? -18.0 : 14.0;
        wxPressure = 101300.0;
        wxWindDir = (i * 45) % 360;
        wxWindKt = [0.0, 5.0, 15.0, 35.0, 65.0][i % 5];
        hr = [62, 128, 158, 176][(i / 2) % 4];
        zones = [93, 112, 130, 149, 167, 185];
        altitude = 1250.0 + (i % 20) * 7;
        battery = [80.0, 25.0, 10.0][(i / 5) % 3];
        stress = [28, 62, 84][(i / 7) % 3];        bodyBattery = [74, 100][i % 2];   // odd steps: widest values in every data window
        spo2 = [97, 100][i % 2];
        actMin = [95, 150][i % 2];   // 3 digits exercise the widest ACT MIN cell
        actGoal = 150;
        sunIsSet = true;
        sunTime = "1856";
        // Slot-only fields; odd steps: the widest values (shortened forms in the narrow windows).
        var wide = i % 2 == 1;
        steps = wide ? 23456 : 8642; stepGoal = 10000;
        floors = wide ? 128 : 7; floorsGoal = 10; floorsDn = wide ? 99 : 5;
        kcal = wide ? 3456 : 1840;
        distM = wide ? 123400.0 : 8420.0;
        actDay = wide ? 240 : 35;
        climbM = wide ? 2345.0 : 312.0;
        vo2Run = wide ? 65 : 48; vo2Bike = i % 3 == 0 ? null : 52;
        runWkM = wide ? 112300.0 : 23400.0; bikeWkM = wide ? 312000.0 : 0.0;
        rhr = wide ? 104 : 48;
        sleepScore = wide ? 100 : 82;
        visM = wide ? 50000.0 : 4800.0;
        pop = wide ? 100 : 40;
        utcTime = wide ? "2359" : "0242";
        System.println("demo " + i + " cond " + wxCond + " cover " + wxCover + " wind " + wxWindDir + "/" + wxWindKt);
    }

    private function refreshSlow(now as Time.Moment, info as Activity.Info?) as Void {
        battery = System.getSystemStats().battery;

        zones = null;
        try {
            zones = UserProfile.getHeartRateZones(UserProfile.getCurrentSport());
        } catch (e) {
        }

        if (altitude == null) {
            var e = latest(SensorHistory has :getElevationHistory ? SensorHistory.getElevationHistory({ :period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST }) : null);
            if (e != null) { altitude = e.toFloat(); }
        }

        bodyBattery = toNum(latest(SensorHistory has :getBodyBatteryHistory
            ? SensorHistory.getBodyBatteryHistory({ :period => 5, :order => SensorHistory.ORDER_NEWEST_FIRST }) : null));

        spo2 = null;
        if (info != null && info has :currentOxygenSaturation && info.currentOxygenSaturation != null) {
            spo2 = info.currentOxygenSaturation;
        }
        if (spo2 == null) {
            spo2 = toNum(latest(SensorHistory has :getOxygenSaturationHistory
                ? SensorHistory.getOxygenSaturationHistory({ :period => 5, :order => SensorHistory.ORDER_NEWEST_FIRST }) : null));
        }

        var am = ActivityMonitor.getInfo();
        stress = (am has :stressScore) ? am.stressScore : null;
        if (stress == null) {
            stress = toNum(latest(SensorHistory has :getStressHistory
                ? SensorHistory.getStressHistory({ :period => 5, :order => SensorHistory.ORDER_NEWEST_FIRST }) : null));
        }
        actMin = am.activeMinutesWeek != null ? am.activeMinutesWeek.total : null;
        actGoal = am.activeMinutesWeekGoal;
        readActivity(am);
        readProfile();

        var wx = Weather.getCurrentConditions();
        readWeather(now, wx);
        refreshSun(now, info, wx);
        var u = Gregorian.utcInfo(now, Time.FORMAT_SHORT);
        utcTime = u.hour.format("%02d") + u.min.format("%02d");
    }

    private function readActivity(am as ActivityMonitor.Info) as Void {
        steps = am.steps;
        stepGoal = am.stepGoal;
        floors = (am has :floorsClimbed) ? am.floorsClimbed : null;
        floorsGoal = (am has :floorsClimbedGoal) ? am.floorsClimbedGoal : null;
        floorsDn = (am has :floorsDescended) ? am.floorsDescended : null;
        kcal = am.calories;
        distM = am.distance != null ? am.distance / 100.0 : null;   // cm
        actDay = am.activeMinutesDay != null ? am.activeMinutesDay.total : null;
        climbM = (am has :metersClimbed && am.metersClimbed != null) ? am.metersClimbed.toFloat() : null;
        runWkM = complicationFloat(Complications.COMPLICATION_TYPE_WEEKLY_RUN_DISTANCE);
        bikeWkM = complicationFloat(Complications.COMPLICATION_TYPE_WEEKLY_BIKE_DISTANCE);
        var sl = complicationFloat(42 as Complications.Type);   // COMPLICATION_TYPE_SLEEP_SCORE (API 6.0.2)
        sleepScore = sl != null ? (sl + 0.5).toNumber() : null;
    }

    private function readProfile() as Void {
        var p = UserProfile.getProfile();
        vo2Run = (p has :vo2maxRunning) ? p.vo2maxRunning : null;
        vo2Bike = (p has :vo2maxCycling) ? p.vo2maxCycling : null;
        rhr = (p has :restingHeartRate) ? p.restingHeartRate : null;
    }

    // Numeric value of a system complication; null if the watch does not have it or it has no value.
    private function complicationFloat(t as Complications.Type) as Float? {
        try {
            var v = Complications.getComplication(new Complications.Id(t)).value;
            return v instanceof Number || v instanceof Float || v instanceof Long || v instanceof Double ? v.toFloat() : null;
        } catch (e) {
            return null;
        }
    }

    private function readWeather(now as Time.Moment, wx as Weather.CurrentConditions?) as Void {
        wxOk = wx != null;
        wxStale = false;
        visM = null;
        pop = null;
        if (wx == null) { return; }
        visM = (wx has :visibility && wx.visibility != null) ? wx.visibility.toFloat() : null;
        pop = wx.precipitationChance;
        if (wx.observationTime != null) {
            wxStale = now.value() - wx.observationTime.value() > 3 * 3600;
        }
        wxCond = wx.condition;
        wxTemp = wx.temperature != null ? wx.temperature.toFloat() : null;
        wxDew = (wx has :dewPoint && wx.dewPoint != null) ? wx.dewPoint.toFloat() : null;
        wxPressure = (wx has :pressure && wx.pressure != null) ? wx.pressure.toFloat() : null;
        wxWindDir = wx.windBearing;
        wxWindKt = wx.windSpeed != null ? wx.windSpeed * 1.943844 : null;
        wxCover = Wx.cover(wxCond,
            (wx has :cloudCover) ? wx.cloudCover : null,
            (wx has :visibility) ? wx.visibility : null);
    }

    // Next sun event: sunset during the day, sunrise otherwise.
    private function refreshSun(now as Time.Moment, info as Activity.Info?, wx as Weather.CurrentConditions?) as Void {
        sunTime = null;
        var loc = location(info, wx);
        if (loc == null) { return; }
        var rise = Weather.getSunrise(loc, now);
        var set = Weather.getSunset(loc, now);
        if (rise == null || set == null) { return; }
        var ev = null;
        if (now.compare(rise) < 0) {
            sunIsSet = false; ev = rise;
        } else if (now.compare(set) < 0) {
            sunIsSet = true; ev = set;
        } else {
            sunIsSet = false;
            ev = Weather.getSunrise(loc, now.add(new Time.Duration(Gregorian.SECONDS_PER_DAY)));
        }
        if (ev != null) {
            var t = Gregorian.info(ev, Time.FORMAT_SHORT);
            sunTime = t.hour.format("%02d") + t.min.format("%02d");
        }
    }

    // Weather observation position, else current activity position, else last known (persisted).
    private function location(info as Activity.Info?, wx as Weather.CurrentConditions?) as Position.Location? {
        var loc = null;
        if (wx != null && wx.observationLocationPosition != null) { loc = wx.observationLocationPosition; }
        if (loc == null && info != null && info.currentLocation != null) { loc = info.currentLocation; }
        if (loc != null) {
            var deg = loc.toDegrees();
            if (deg[0] != 0.0 || deg[1] != 0.0) {
                Application.Storage.setValue("loc", [deg[0].toFloat(), deg[1].toFloat()]);
                return loc;
            }
        }
        var saved = Application.Storage.getValue("loc");
        if (saved instanceof Array && saved.size() == 2) {
            return new Position.Location({ :latitude => saved[0], :longitude => saved[1], :format => :degrees });
        }
        return null;
    }

    // BINGO warning (§3.6): replaces the bottom row at 10 % battery or less.
    function bingo() as Boolean {
        return battery <= 10;
    }

    private function lastHr() as Number? {
        var it = ActivityMonitor.getHeartRateHistory(1, true);
        var s = it.next();
        if (s != null && s.heartRate != null && s.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
            return s.heartRate;
        }
        return null;
    }

    // First non-null sample value from a SensorHistory iterator.
    private function latest(it as SensorHistory.SensorHistoryIterator?) as Numeric? {
        if (it == null) { return null; }
        var s = it.next();
        while (s != null) {
            if (s.data != null) { return s.data; }
            s = it.next();
        }
        return null;
    }

    private function toNum(v as Numeric?) as Number? {
        return v == null ? null : (v + 0.5).toNumber();
    }
}
