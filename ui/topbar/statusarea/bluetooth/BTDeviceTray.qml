import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.ui.primitives

RowLayout {
    id: root
    spacing: 8

    property var _devices: {
        var adapter = Bluetooth.defaultAdapter
        if (!adapter || !adapter.enabled) return []
        return adapter.devices.values.filter(function(d) {
            return d.connected && d.name !== ""
        })
    }

    visible: _devices.length > 0

    function _isAirpods(dev) {
        var n  = (dev.name || "").toLowerCase()
        var ic = (dev.icon || "").toLowerCase()
        return n.indexOf("airpods") !== -1
               || ic.indexOf("airpods") !== -1
               || ic.indexOf("headset") !== -1
               || ic.indexOf("headphone") !== -1
               || ic.indexOf("audio") !== -1
    }

    function _deviceIcon(dev) {
        var ic = dev.icon || ""
        if (ic.indexOf("phone") !== -1)    return "notch/phone.svg"
        if (ic.indexOf("keyboard") !== -1) return "devices/keyboard.svg"
        if (ic.indexOf("mouse") !== -1)    return "devices/mouse.svg"
        if (ic.indexOf("computer") !== -1) return "devices/computer.svg"
        return "bluetooth/bluetooth.svg"
    }

    BTBatteryPopup {
        id: _popup
    }

    Repeater {
        model: root._devices
        delegate: Item {
            required property var modelData
            id: _item

            property real _pct: modelData.batteryAvailable ? modelData.battery * 100 : -1

            implicitWidth:  _row.implicitWidth
            implicitHeight: 20
            Layout.alignment: Qt.AlignVCenter

            RowLayout {
                id: _row
                anchors.centerIn: parent
                spacing: 4

                Image {
                    source:            Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/devices/airpods.png")
                    width:             10
                    height:            8
                    fillMode:          Image.PreserveAspectFit
                    sourceSize.width:  20
                    sourceSize.height: 20
                    Layout.alignment:  Qt.AlignVCenter
                    visible:           root._isAirpods(_item.modelData)
                }

                CFVI {
                    icon:             root._deviceIcon(_item.modelData)
                    size:             16
                    color:            "#ffffff"
                    Layout.alignment: Qt.AlignVCenter
                    visible:          !root._isAirpods(_item.modelData)
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onClicked: {
                    _popup.deviceName = _item.modelData.name || "Appareil"
                    _popup.pct        = _item._pct
                    _popup._isAirpods = root._isAirpods(_item.modelData)
                    _popup.xPos       = _item.mapToItem(null, 0, 0).x
                    _popup.toggle()
                }
            }
        }
    }
}
