import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.ui.primitives

Item {
    id: root
    signal closeRequested()
    property bool needsKeyboard: false
    implicitHeight: content.implicitHeight + 24

    readonly property bool onBattery: UPower.onBattery
    readonly property real batPercentage: UPower.displayDevice.isLaptopBattery ? UPower.displayDevice.percentage : 1
    readonly property bool charging: onBattery ? (UPower.displayDevice.state === 1) : true
    readonly property string powerSourceText: onBattery ? "Battery" : "Power Adapter"
    property string currentProfile: ""

    readonly property var profiles: [
        { id: "balanced", label: "Automatic", icon: "battery/battery-100.svg" },
        { id: "power-saver", label: "Low Power", icon: "battery/battery-010.svg" },
        { id: "performance", label: "High Power", icon: "battery/battery-100-charging.svg" }
    ]

    function setProfile(profileId) {
        root.currentProfile = profileId
        setProfileProc.command = ["powerprofilesctl", "set", profileId]
        setProfileProc.running = true
    }

    property var previousSample: ({})
    property double previousTimestamp: 0
    property double memTotalKb: 1
    property var iconCache: ({})
    property var iconQueue: []
    property var topConsumers: []

    function enqueueIconLookup(appkey) {
        if (root.iconCache[appkey] !== undefined) return
        if (root.iconQueue.indexOf(appkey) !== -1) return
        var q = root.iconQueue.slice()
        q.push(appkey)
        root.iconQueue = q
        processIconQueue()
    }

    function processIconQueue() {
        if (iconLookupProc.running) return
        if (root.iconQueue.length === 0) return
        var next = root.iconQueue[0]
        var q = root.iconQueue.slice()
        q.shift()
        root.iconQueue = q
        iconLookupProc.targetKey = next
        iconLookupProc.command = ["bash", Quickshell.shellDir + "/tools/energy-usage/find-app-icon.sh", next]
        iconLookupProc.running = true
    }

    Component.onCompleted: {
        memTotalProc.running = true
        sampleProc.running = true
    }

    Process {
        id: getProfileProc
        command: ["powerprofilesctl", "get"]
        running: true
        stdout: SplitParser {
            onRead: data => root.currentProfile = data.trim()
        }
    }

    Process {
        id: setProfileProc
    }

    Process {
        id: memTotalProc
        command: ["bash", "-c", "awk '/^MemTotal:/{print $2}' /proc/meminfo"]
        stdout: SplitParser {
            onRead: data => {
                var v = parseFloat(data.trim())
                if (v > 0) root.memTotalKb = v
            }
        }
    }

     function formatMemory(mb) {
        if (mb >= 1024) return (mb / 1024).toFixed(1) + " GB"
        return Math.round(mb) + " MB"
    }

    Process {
        id: sampleProc
        command: ["bash", Quickshell.shellDir + "/tools/energy-usage/sample-processes.sh"]
        property var pending: ({})
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (line.length === 0) return
                var parts = line.split(";")
                if (parts.length === 4) {
                    sampleProc.pending[parts[0]] = {
                        cpu: parseFloat(parts[1]),
                        rss: parseFloat(parts[2]),
                        swap: parseFloat(parts[3])
                    }
                }
            }
        }
        onExited: {
            var now = Date.now()
            var current = sampleProc.pending
            sampleProc.pending = ({})

            if (root.previousTimestamp > 0) {
                var elapsedSec = (now - root.previousTimestamp) / 1000
                if (elapsedSec > 0.2) {
                    var results = []
                    for (var key in current) {
                        var prev = root.previousSample[key]
                        if (prev) {
                            var deltaTicks = current[key].cpu - prev.cpu
                            if (deltaTicks < 0) deltaTicks = 0
                            var cpuPct = (deltaTicks / 100) / elapsedSec * 100
                            var rssMb = current[key].rss / 1024
                            var swapMb = current[key].swap / 1024
                            if (cpuPct > 0.3 || rssMb > 50) {
                                results.push({
                                    name: key,
                                    cpu: cpuPct,
                                    rssMb: rssMb,
                                    swap: swapMb
                                })
                            }
                        }
                    }
                    results.sort(function(a, b) { return b.cpu - a.cpu })
                    var top = results.slice(0, 3)

                    for (var i = 0; i < top.length; i++) {
                        var appkey = top[i].name
                        top[i].icon = root.iconCache[appkey] !== undefined ? root.iconCache[appkey] : ""
                        root.enqueueIconLookup(appkey)
                    }

                    root.topConsumers = top
                }
            }

            root.previousSample = current
            root.previousTimestamp = now
        }
    }


    Process {
        id: iconLookupProc
        property string targetKey: ""
        stdout: SplitParser {
            onRead: data => {
                var path = data.trim()
                var cache = root.iconCache
                cache[iconLookupProc.targetKey] = path
                root.iconCache = cache
            }
        }
        onExited: {
            if (root.iconCache[iconLookupProc.targetKey] === undefined) {
                var cache = root.iconCache
                cache[iconLookupProc.targetKey] = ""
                root.iconCache = cache
            }
            var updated = root.topConsumers.slice()
            for (var i = 0; i < updated.length; i++) {
                if (updated[i].name === iconLookupProc.targetKey) {
                    updated[i].icon = root.iconCache[iconLookupProc.targetKey]
                }
            }
            root.topConsumers = updated
            root.processIconQueue()
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            if (!sampleProc.running) sampleProc.running = true
        }
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 12
        spacing: 12

        RowLayout {
            Layout.fillWidth: true

            CFText {
                text: "Battery"
                font.pixelSize: 15
                font.weight: Font.Bold
            }

            Item {
                Layout.fillWidth: true
            }

            CFText {
                text: Math.round(root.batPercentage * 100) + "%"
                font.pixelSize: 15
                font.weight: Font.Bold
            }
        }

        CFText {
            text: "Power Source: " + root.powerSourceText
            gray: true
            font.pixelSize: 12
            font.weight: Font.Bold
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#20ffffff"
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            CFText {
                text: "Energy Mode"
                gray: true
                font.pixelSize: 11
                font.weight: Font.Bold
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Repeater {
                    model: root.profiles

                    Rectangle {
                        id: profileRow
                        Layout.fillWidth: true
                        height: 40
                        radius: 8
                        color: rowMouse.containsMouse ? "#14ffffff" : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Rectangle {
                                width: 28
                                height: 28
                                radius: 14
                                color: modelData.id === root.currentProfile ? "#1C7AFF" : "transparent"
                                Layout.alignment: Qt.AlignVCenter

                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }

                                CFVI {
                                    anchors.centerIn: parent
                                    icon: modelData.icon
                                    size: 16
                                    color: "#ffffff"
                                }
                            }

                            CFText {
                                text: modelData.label
                                font.pixelSize: 13
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Item {
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setProfile(modelData.id)
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#20ffffff"
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            CFText {
                text: "Energy Usage"
                gray: true
                font.pixelSize: 11
                font.weight: Font.Bold
            }

            CFText {
                visible: root.topConsumers.length === 0
                text: "No Apps Using Significant Energy"
                gray: true
                font.pixelSize: 12
            }

            ColumnLayout {
                visible: root.topConsumers.length > 0
                Layout.fillWidth: true
                spacing: 2

                Repeater {
                    model: root.topConsumers.slice(0, 3)

                    Rectangle {
                        id: usageRow
                        Layout.fillWidth: true
                        height: 48
                        radius: 8
                        color: usageMouse.containsMouse ? "#14ffffff" : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Rectangle {
                                width: 28
                                height: 28
                                radius: 14
                                color: "#20ffffff"
                                Layout.alignment: Qt.AlignVCenter
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    visible: modelData.icon.length > 0
                                    source: modelData.icon.length > 0 ? "file://" + modelData.icon : ""
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                }

                                CFText {
                                    anchors.centerIn: parent
                                    visible: modelData.icon.length === 0
                                    text: modelData.name.length > 0 ? modelData.name.charAt(0).toUpperCase() : "?"
                                    font.pixelSize: 13
                                    font.weight: Font.Bold
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                CFText {
                                    text: modelData.name
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

				CFText {
                                    text: "CPU " + modelData.cpu.toFixed(1) + "%  ·  RAM " + root.formatMemory(modelData.rssMb) + "  ·  Swap " + modelData.swap.toFixed(1) + " MB"
                                    gray: true
                                    font.pixelSize: 11
                                }

                            }
                        }

                        MouseArea {
                            id: usageMouse
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#20ffffff"
        }

        MouseArea {
            Layout.fillWidth: true
            height: 24
            cursorShape: Qt.PointingHandCursor
            onClicked: root.closeRequested()

            CFText {
                anchors.verticalCenter: parent.verticalCenter
                text: "Battery Settings..."
                font.pixelSize: 13
            }
        }
    }
}
