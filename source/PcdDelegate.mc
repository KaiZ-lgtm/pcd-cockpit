import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Tap targets (requirements §7): open the matching native page via Complications.exitTo.
class PcdDelegate extends WatchUi.WatchFaceDelegate {
    private var _view as PcdView;

    function initialize(view as PcdView) {
        WatchFaceDelegate.initialize();
        _view = view;
    }

    function onPress(evt as WatchUi.ClickEvent) as Boolean {
        var L = _view.lay;
        if (L == null) { return false; }
        var ds = System.getDeviceSettings();
        var xy = evt.getCoordinates();
        var x = xy[0] - ds.screenWidth / 2;
        var y = xy[1] - ds.screenHeight / 2;
        var type = hitTest(L, x, y);
        if (type == null) { return false; }
        try {
            Complications.exitTo(new Complications.Id(type));
            return true;
        } catch (e) {
            return false;
        }
    }

    private function hitTest(L as Layout, x as Number, y as Number) as Complications.Type? {
        var d = _view.data;
        // Slots (the same list PcdView draws): bottom row, data row, date block right column.
        var slots = L.slots;
        for (var i = 0; i < slots.size(); i++) {
            var s = slots[i];
            var r = s.hit;
            if (x < r[0] || x > r[2] || y < r[1] || y >= r[3]) { continue; }
            if (s.warn && d.bingo()) { return Complications.COMPLICATION_TYPE_BATTERY; }
            var t = Field.complication(s.field, d);
            if (t != null) { return t; }
        }
        // Tapes: the value box plus a margin.
        if ((y - L.boxY).abs() <= L.boxH / 2 + 16 && x.abs() >= L.boxOut - L.boxW - 12) {
            return x < 0 ? Complications.COMPLICATION_TYPE_HEART_RATE : Complications.COMPLICATION_TYPE_ALTITUDE;
        }
        // Station model (top cap)
        if (y <= L.stY + 40 && x.abs() <= 120) {
            return Complications.COMPLICATION_TYPE_CURRENT_WEATHER;
        }
        return null;
    }
}
