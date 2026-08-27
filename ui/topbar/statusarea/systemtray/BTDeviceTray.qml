import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.components
import qs.ui.osd

RowLayout {
    id: root
    spacing: 8

    Repeater {
        model: Bluetooth.connectedDevices
        delegate: Item {
            required property var modelData
            id: _item

            property real  _pct:      modelData.battery ? modelData.battery.percentage * 100 : -1
            property bool  _hasBatt:  _pct >= 0
            property bool  _hovered:  false

            implicitWidth:  _row.implicitWidth
            implicitHeight: 20
            Layout.alignment: Qt.AlignVCenter

            RowLayout {
                id: _row
                anchors.centerIn: parent
                spacing: 4

                CFVI {
                    icon:  _item._deviceIcon()
                    size:  16
                    color: "#ffffff"
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text:           _item._hasBatt ? Math.round(_item._pct) + "%" : ""
                    font.pixelSize: 11
                    font.family:    "SF Pro Rounded"
                    font.weight:    Font.Medium
                    color:          _item._battColor()
                    renderType:     Text.NativeRendering
                    visible:        _item._hasBatt
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            function _deviceIcon() {
                var t = modelData.icon || ""
                if (t.indexOf("headset") !== -1 || t.indexOf("headphone") !== -1) return "notch/headphones.svg"
                if (t.indexOf("phone") !== -1)    return "notch/phone.svg"
                if (t.indexOf("keyboard") !== -1) return "devices/keyboard.svg"
                if (t.indexOf("mouse") !== -1)    return "devices/mouse.svg"
                if (t.indexOf("computer") !== -1) return "devices/computer.svg"
                return "bluetooth/bluetooth.svg"
            }

            function _battColor() {
                if (_pct <= 10) return "#FF453A"
                if (_pct <= 20) return "#FF9F0A"
                return "#ffffff"
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onEntered:    _item._hovered = true
                onExited:     _item._hovered = false
                onClicked: {
                    _popup.deviceName = modelData.name || "Appareil"
                    _popup.pct        = _item._hasBatt ? Math.round(_item._pct) : -1
                    _popup.isCharging = false
                    _popup.toggle()
                }
            }
        }
    }

    BTBatteryPopup {
        id: _popup
    }
}
