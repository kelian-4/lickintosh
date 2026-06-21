import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

RowLayout {
    id: root
    spacing: 8
    
    Repeater {
        model: SystemTray.items
        delegate: SysTrayItem {
            required property var modelData
            item: modelData
        }
    }
}
