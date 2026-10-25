import QtQuick
import QtQuick.Layouts
import qs.services
import qs.ui.widgets

Item {
    id: root

    property string size: "s"

    readonly property color tint: "#ff9f0a"
    readonly property real freeGb: Math.max(0, ResourcesState.storageTotalGb - ResourcesState.storageUsedGb)

    ResourceTitle {
        id: title
        title: root.size === "s" ? "Storage" : "Storage Status"
        tint: root.tint
    }

    Text {
        anchors.top: parent.top
        anchors.right: parent.right
        visible: root.size === "m"
        text: title.updated
        color: Qt.rgba(1, 1, 1, 0.55)
        font.pixelSize: 11
        font.family: "SF Pro Rounded"
        renderType: Text.NativeRendering
    }

    ResourceRing {
        visible: root.size === "s"
        anchors.top: title.bottom
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        width: 92
        height: 92
        percent: ResourcesState.storagePercent
        tint: root.tint
        caption: "used"
        thickness: 8
        valueSize: 20
    }

    RowLayout {
        visible: root.size === "m"
        anchors.top: title.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 16

        ResourceRing {
            Layout.preferredWidth: 92
            Layout.preferredHeight: 92
            Layout.alignment: Qt.AlignVCenter
            percent: ResourcesState.storagePercent
            tint: root.tint
            caption: "used"
            thickness: 8
            valueSize: 20
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            ResourceStat { label: "Total"; value: ResourcesState.storageTotalGb.toFixed(0) + " GB" }
            ResourceStat { label: "Used"; value: ResourcesState.storageUsedGb.toFixed(0) + " GB"; tint: root.tint }
            ResourceStat { label: "Free"; value: root.freeGb.toFixed(0) + " GB"; tint: root.tint }
        }
    }
}
