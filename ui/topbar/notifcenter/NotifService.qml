pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    readonly property var server: _server

    readonly property var systemApps: ["NetworkManager", "udisks", "udisks2", "systemd", "polkit", "upower", "gnome-power-manager"]

    function isSystemNotif(n) {
        if (!n) return false
        if (n.urgency === NotificationUrgency.Critical) return true
        for (var i = 0; i < root.systemApps.length; i++) {
            if (n.appName === root.systemApps[i]) return true
        }
        return false
    }

    function findDefaultAction(n) {
        if (!n) return null
        var acts = n.actions
        for (var i = 0; i < acts.length; i++) {
            if (acts[i].identifier === "default") return acts[i]
        }
        return null
    }

    function groupByApp(list) {
        var keys   = []
        var groups = {}
        for (var i = list.length - 1; i >= 0; i--) {
            var n   = list[i]
            var key = n.appName || "Unknown"
            if (!groups[key]) { groups[key] = []; keys.push(key) }
            groups[key].push(n)
        }
        var out = []
        for (var j = 0; j < keys.length; j++) {
            out.push({ appName: keys[j], items: groups[keys[j]] })
        }
        return out
    }

    property int  trackedCount:     0
    property var  systemGroupsList: []
    property var  appGroupsList:    []

    function rebuild() {
        var allArr = []
        for (var k = 0; k < _centerModel.count; k++) {
            allArr.push(_centerModel.get(k).notifObj)
        }
        root.trackedCount = allArr.length
        var sys = []
        var app = []
        for (var i = 0; i < allArr.length; i++) {
            if (root.isSystemNotif(allArr[i])) sys.push(allArr[i])
            else app.push(allArr[i])
        }
        root.systemGroupsList = root.groupByApp(sys)
        root.appGroupsList    = root.groupByApp(app)
    }

    function removeFromCenter(notifObj) {
        for (var i = 0; i < _centerModel.count; i++) {
            if (_centerModel.get(i).notifObj === notifObj) {
                _centerModel.remove(i)
                root.rebuild()
                return
            }
        }
    }

    function dismissAll() {
        var allArr = []
        for (var k = 0; k < _centerModel.count; k++) {
            allArr.push(_centerModel.get(k).notifObj)
        }
        for (var i = allArr.length - 1; i >= 0; i--) {
            allArr[i].dismiss()
        }
    }

    function dismissGroup(items) {
        if (!items) return
        for (var i = items.length - 1; i >= 0; i--) {
            items[i].dismiss()
        }
    }

    readonly property alias popupModel: _popupModel
    property int  dismissGen:   0
    property bool centerOpened: false

    function pushPopup(notification) {
        _centerModel.append({ notifObj: notification })
        root.rebuild()

        if (!root.centerOpened) {
            _popupModel.append({ notifObj: notification })
            _groupTimer.stop()
            _groupTimer.start()
        }
    }

    function stopGroupTimer() {
        _groupTimer.stop()
    }

    function restartGroupTimer() {
        _groupTimer.stop()
        _groupTimer.start()
    }

    function removePopup(notifObj) {
        for (var i = 0; i < _popupModel.count; i++) {
            if (_popupModel.get(i).notifObj === notifObj) {
                _popupModel.remove(i)
                return
            }
        }
    }

    function remindLater(notification, minutes) {
        if (!notification) return
        root.removeFromCenter(notification)
        root.removePopup(notification)

        var t = _remindTimerComponent.createObject(root, {
            "notifObj": notification,
            "interval": Math.max(1, minutes) * 60000
        })
        t.start()
    }

    Component {
        id: _remindTimerComponent
        Timer {
            property var notifObj: null
            repeat: false
            onTriggered: {
                root.pushPopup(notifObj)
                destroy()
            }
        }
    }

    function openAppOptions(notification) {
        if (!notification) return
        var name = notification.appName || ""
        if (name === "") return
        var de = DesktopEntries.heuristicLookup(name)
        if (de) {
            de.execute()
        }
    }

    NotificationServer {
        id: _server
        keepOnReload: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: function(notification) {
            notification.tracked = true

            notification.closed.connect(function() {
                root.removeFromCenter(notification)
                root.removePopup(notification)
            })

            root.pushPopup(notification)
        }
    }

    ListModel {
        id: _centerModel
    }

    ListModel {
        id: _popupModel
    }

    Timer {
        id: _groupTimer
        interval: 5000
        running: false
        repeat: false
        triggeredOnStart: false
        onTriggered: {
            root.dismissGen = root.dismissGen + 1
        }
    }
}
