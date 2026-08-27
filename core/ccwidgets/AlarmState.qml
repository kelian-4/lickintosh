pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    reloadableId: "alarmState"

    readonly property string filePath: "$HOME/.config/quickshell/core/alarms.json"
    property alias alarms: alarmAdapter.list

    property string firingAlarmId: ""
    property int _lastCheckedMinute: -1

    FileView {
        id: alarmFileView
        path: root.filePath
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: function(error) {
            if (error === FileViewError.FileNotFound) writeAdapter()
        }

        JsonAdapter {
            id: alarmAdapter
            property list<var> list: []
        }
    }

    function addAlarm(hour, minute, label, repeatDays) {
        var list = root.alarms.slice()
        list.push({
            id: "alarm_" + Date.now(),
            hour: hour,
            minute: minute,
            label: label || "",
            repeatDays: repeatDays || [],
            enabled: true
        })
        root.alarms = list
    }

    function removeAlarm(id) {
        root.alarms = root.alarms.filter(function(a) { return a.id !== id })
    }

    function setAlarmEnabled(id, enabled) {
        var list = root.alarms.slice()
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === id) {
                list[i] = Object.assign({}, list[i], { enabled: enabled })
                root.alarms = list
                return
            }
        }
    }

    function dismissFiringAlarm() {
        root.firingAlarmId = ""
    }

    function snoozeFiringAlarm(minutes) {
        root.firingAlarmId = ""
        var now = new Date()
        now.setMinutes(now.getMinutes() + (minutes || 9))
        root.addAlarm(now.getHours(), now.getMinutes(), "Rappel", [])
    }

    function _checkAlarms() {
        var now = new Date()
        var curMinute = now.getHours() * 60 + now.getMinutes()
        if (curMinute === root._lastCheckedMinute) return
        root._lastCheckedMinute = curMinute

        var curDay = now.getDay()
        for (var i = 0; i < root.alarms.length; i++) {
            var a = root.alarms[i]
            if (!a.enabled) continue
            if (a.hour !== now.getHours() || a.minute !== now.getMinutes()) continue
            if (a.repeatDays.length > 0 && a.repeatDays.indexOf(curDay) === -1) continue
            root.firingAlarmId = a.id
            _alarmSoundProc.running = true
            if (a.repeatDays.length === 0) root.setAlarmEnabled(a.id, false)
        }
    }

    Process {
        id: _alarmSoundProc
        command: ["sh", "-c",
            "command -v canberra-gtk-play >/dev/null 2>&1 && canberra-gtk-play -i alarm-clock-elapsed 2>/dev/null || " +
            "command -v paplay >/dev/null 2>&1 && paplay /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga 2>/dev/null || true"]
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root._checkAlarms()
    }

    Component.onCompleted: root._checkAlarms()
}
