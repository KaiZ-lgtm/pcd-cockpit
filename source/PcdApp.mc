import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class PcdApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view = new PcdView();
        return [view, new PcdDelegate(view)];
    }
}
