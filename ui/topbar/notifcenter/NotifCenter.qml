import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.ui.glass
import qs.ui.primitives
import qs.ui.topbar.notifcenter

Scope {
    id: root

    property bool opened: false
    property var  notifServer: null
    signal closing()

    onOpenedChanged: NotifService.centerOpened = root.opened

    readonly property int panelWidth:   320
    readonly property int panelMarginR: 10
    readonly property int topOffset:    48
    readonly property int animDur:      320

    property real   lat:          0
    property real   lon:          0
    property string cityName:     ""
    property int    currentTemp:  0
    property string currentIcon:  "weather/a/clouds.svg"
    property string currentDesc:  ""
    property var    hourlyData:   []
    property bool   weatherReady: false

    function wmoToIcon(code) {
        if (code === 0)               return "weather/a/sun.svg"
        if (code >= 1 && code <= 2)   return "weather/a/cloud-sun.svg"
        if (code === 3)               return "weather/a/clouds.svg"
        if (code >= 51 && code <= 67) return "weather/a/cloud-rain.svg"
        if (code >= 71 && code <= 77) return "weather/a/cloud-snow.svg"
        if (code >= 80 && code <= 82) return "weather/a/cloud-rain.svg"
        if (code >= 85 && code <= 86) return "weather/a/cloud-snow.svg"
        if (code >= 95)               return "weather/a/cloud-lightning.svg"
        return "weather/a/clouds.svg"
    }

    function wmoToDesc(code) {
        if (code === 0)               return "Clear Sky"
        if (code >= 1 && code <= 2)   return "Partly Cloudy"
        if (code === 3)               return "Overcast"
        if (code >= 51 && code <= 67) return "Rain"
        if (code >= 71 && code <= 77) return "Snow"
        if (code >= 80 && code <= 82) return "Showers"
        if (code >= 95)               return "Thunderstorm"
        return "Cloudy"
    }

    Process {
        id: _geoProc
        command: ["curl", "-s", "--max-time", "5", "http://ip-api.com/json/"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var j = JSON.parse(text.trim())
                    root.lat      = j.lat
                    root.lon      = j.lon
                    root.cityName = j.city || ""
                    _weatherProc.running = true
                } catch(e) {}
            }
        }
    }

    Process {
        id: _weatherProc
        command: [
            "curl", "-s", "--max-time", "8",
            "https://api.open-meteo.com/v1/forecast?latitude=" + root.lat +
            "&longitude=" + root.lon +
            "&current=temperature_2m,weather_code,is_day" +
            "&hourly=temperature_2m,weather_code" +
            "&forecast_days=1&timezone=auto"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var w     = JSON.parse(text.trim())
                    root.currentTemp = Math.round(w.current.temperature_2m)
                    root.currentIcon = root.wmoToIcon(w.current.weather_code)
                    root.currentDesc = root.wmoToDesc(w.current.weather_code)
                    var hrs   = []
                    var times = w.hourly.time
                    var temps = w.hourly.temperature_2m
                    var codes = w.hourly.weather_code
                    var nowH  = new Date().getHours()
                    for (var i = 0; i < times.length && hrs.length < 6; i++) {
                        var h = new Date(times[i]).getHours()
                        if (h < nowH && hrs.length === 0) continue
                        hrs.push({
                            label: hrs.length === 0 ? "Now" : Qt.formatTime(new Date(times[i]), "h AP"),
                            temp:  Math.round(temps[i]),
                            icon:  root.wmoToIcon(codes[i])
                        })
                    }
                    root.hourlyData   = hrs
                    root.weatherReady = true
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: _geoProc.running = true
    }

    Loader {
        active: root.opened
        sourceComponent: Component {
            PanelWindow {
                id: ncWin

                screen: {
                    var m = Hyprland.focusedMonitor
                    if (m) {
                        var s = Quickshell.screens.find(function(sc) { return sc.name === m.name })
                        if (s) return s
                    }
                    return Quickshell.screens[0]
                }

                WlrLayershell.namespace:     "quickshell:notifcenter"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
                WlrLayershell.layer:         WlrLayer.Overlay
                color:         "transparent"
                exclusiveZone: -1
                anchors { top: true; right: true; bottom: true; left: true }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.closing()
                }

                Item {
                    id: panel
                    width:  root.panelWidth
                    anchors.top:         parent.top
                    anchors.right:       parent.right
                    anchors.bottom:      parent.bottom
                    anchors.topMargin:   root.topOffset
                    anchors.rightMargin: root.panelMarginR

                    property bool vis: root.opened

                    transform: Translate {
                        x: panel.vis ? 0 : root.panelWidth + root.panelMarginR
                        Behavior on x {
                            NumberAnimation {
                                duration: root.animDur
                                easing.type: Easing.OutBack
                                easing.overshoot: 0.55
                            }
                        }
                    }
                    opacity: panel.vis ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation { duration: root.animDur / 2 }
                    }

                    MouseArea {
                        anchors.fill: parent
                        propagateComposedEvents: false
                        onClicked: function(e) { e.accepted = true }
                    }

                    Flickable {
                        anchors.fill: parent
                        contentWidth:  width
                        contentHeight: _col.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: _col
                            width: parent.width
                            spacing: 8

                            ColumnLayout {
                                id: _notifsBlock
                                Layout.fillWidth: true
                                spacing: 8

                                SequentialAnimation {
                                    id: _clearAnim
                                    NumberAnimation { target: _notifsBlock; property: "opacity"; to: 0; duration: 220; easing.type: Easing.InCubic }
                                    ScriptAction { script: NotifService.dismissAll() }
                                    PauseAnimation { duration: 20 }
                                    NumberAnimation { target: _notifsBlock; property: "opacity"; to: 1; duration: 1 }
                                }

                                Repeater {
                                    model: NotifService.systemGroupsList
                                    delegate: NotifStack {
                                        Layout.fillWidth: true
                                        Layout.topMargin: index === 0 ? 8 : 0
                                        appName: modelData.appName
                                        items:   modelData.items

                                        onContextMenuRequested: function(x, y, notif, stackFlag) {
                                            _ctxMenu.notification = notif
                                            _ctxMenu.isStack      = stackFlag
                                            _ctxMenu.stackItems   = modelData.items
                                            _ctxMenu.openAt(x, y)
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.topMargin:   8
                                    Layout.leftMargin:  2
                                    Layout.rightMargin: 2

                                    Text {
                                        Layout.fillWidth: true
                                        text: "Notification Center"
                                        font.pixelSize: 13
                                        font.weight: Font.Bold
                                        font.family: "SF Pro Rounded"
                                        color: "#ffffff"
                                        renderType: Text.NativeRendering
                                    }

                                    Rectangle {
                                        width:  20
                                        height: 20
                                        radius: 10
                                        color:  Qt.rgba(1, 1, 1, 0.18)
                                        visible: NotifService.trackedCount > 0

                                        Text {
                                            anchors.centerIn: parent
                                            text: "×"
                                            font.pixelSize: 15
                                            font.family: "SF Pro Rounded"
                                            color: "#ffffff"
                                            renderType: Text.NativeRendering
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                _clearAnim.start()
                                            }
                                        }
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 36
                                    visible: NotifService.trackedCount === 0

                                    Text {
                                        anchors.centerIn: parent
                                        text: "No Notifications"
                                        font.pixelSize: 12
                                        font.family: "SF Pro Rounded"
                                        color: Qt.rgba(1, 1, 1, 0.40)
                                        renderType: Text.NativeRendering
                                    }
                                }

                                Repeater {
                                    model: NotifService.appGroupsList
                                    delegate: NotifStack {
                                        Layout.fillWidth: true
                                        appName: modelData.appName
                                        items:   modelData.items

                                        onContextMenuRequested: function(x, y, notif, stackFlag) {
                                            _ctxMenu.notification = notif
                                            _ctxMenu.isStack      = stackFlag
                                            _ctxMenu.stackItems   = modelData.items
                                            _ctxMenu.openAt(x, y)
                                        }
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 10
                                    visible: NotifService.trackedCount > 0
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: _wbody.implicitHeight + 36
                                radius: 20
                                clip: true
                                color: "transparent"

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 20
                                    gradient: Gradient {
                                        orientation: Gradient.Vertical
                                        GradientStop { position: 0.0; color: "#0d3f9e" }
                                        GradientStop { position: 1.0; color: "#1f6fd6" }
                                    }
                                }

                                ColumnLayout {
                                    id: _wbody
                                    anchors.left:        parent.left
                                    anchors.right:       parent.right
                                    anchors.top:         parent.top
                                    anchors.leftMargin:  16
                                    anchors.rightMargin: 16
                                    anchors.topMargin:   14
                                    spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        ColumnLayout {
                                            spacing: 0

                                            Text {
                                                text: root.cityName !== "" ? root.cityName : "Weather"
                                                font.pixelSize: 14
                                                font.weight: Font.Medium
                                                font.family: "SF Pro Rounded"
                                                color: "#ffffff"
                                                renderType: Text.NativeRendering
                                            }

                                            Text {
                                                text: root.weatherReady ? root.currentTemp + "°" : "--°"
                                                font.pixelSize: 46
                                                font.weight: Font.Thin
                                                font.family: "SF Pro Rounded"
                                                color: "#ffffff"
                                                renderType: Text.NativeRendering
                                            }
                                        }

                                        Item { Layout.fillWidth: true }

                                        ColumnLayout {
                                            Layout.alignment: Qt.AlignTop | Qt.AlignRight
                                            spacing: 4

                                            CFVI {
                                                Layout.alignment: Qt.AlignRight
                                                size: 32
                                                colorized: false
                                                icon: root.currentIcon
                                            }

                                            Text {
                                                visible: root.weatherReady
                                                text: root.currentDesc
                                                font.pixelSize: 10
                                                font.family: "SF Pro Rounded"
                                                color: Qt.rgba(1, 1, 1, 0.80)
                                                renderType: Text.NativeRendering
                                                horizontalAlignment: Text.AlignRight
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 1
                                        color: Qt.rgba(1, 1, 1, 0.20)
                                        visible: root.weatherReady && root.hourlyData.length > 0
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        visible: root.weatherReady && root.hourlyData.length > 0

                                        Repeater {
                                            model: root.hourlyData
                                            delegate: ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 6

                                                Text {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    text: modelData.label
                                                    font.pixelSize: 10
                                                    font.family: "SF Pro Rounded"
                                                    color: Qt.rgba(1, 1, 1, 0.75)
                                                    renderType: Text.NativeRendering
                                                }
                                                CFVI {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    size: 18
                                                    colorized: false
                                                    icon: modelData.icon
                                                }
                                                Text {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    text: modelData.temp + "°"
                                                    font.pixelSize: 11
                                                    font.weight: Font.Bold
                                                    font.family: "SF Pro Rounded"
                                                    color: "#ffffff"
                                                    renderType: Text.NativeRendering
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 10
                            }
                        }
                    }
                }

                NotifContextMenu {
                    id: _ctxMenu
                    anchors.fill: parent
                    onClearRequested: {
                        if (_ctxMenu.isStack) {
                            NotifService.dismissGroup(_ctxMenu.stackItems)
                        } else if (_ctxMenu.notification) {
                            _ctxMenu.notification.dismiss()
                        }
                    }
                    onRemindRequested: function(minutes) {
                        NotifService.remindLater(_ctxMenu.notification, minutes)
                    }
                    onOptionsRequested: {
                        NotifService.openAppOptions(_ctxMenu.notification)
                    }
                }
            }
        }
    }
}
