import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class PcdApp extends Application.AppBase {
    private var _view as PcdView?;

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        Settings.load();
        var view = new PcdView();
        _view = view;
        return [view, new PcdDelegate(view)];
    }

    // Phone settings changed (Connect IQ / Garmin Connect app).
    function onSettingsChanged() as Void {
        Settings.load();
        if (_view != null) { (_view as PcdView).applySettings(); }
        WatchUi.requestUpdate();
    }
}
