import QtQuick
import QtQuick.Layouts

// Barre d'onglets calquée sur modules/dashboard/Tabs.qml de caelestia :
// 4 onglets, icône + libellé, indicateur actif souligné.
RowLayout {
    id: root
    property int currentIndex: 0
    readonly property var tabs: [
        { label: "Dashboard",   icon: "▦" },
        { label: "Media",       icon: "♪" },
        { label: "Performance", icon: "◈" },
        { label: "Weather",     icon: "☁" }
    ]

    Layout.fillWidth: true
    spacing: 0

    Repeater {
        model: root.tabs

        // Le délégué racine DOIT être un simple Item (pas un Layout) :
        // un MouseArea avec anchors.fill à l'intérieur d'un Layout
        // entre en conflit avec la gestion de géométrie du Layout
        // (warning "Detected anchors on an item that is managed by a
        // layout"). Le ColumnLayout interne, lui, est un pur enfant de
        // cet Item (anchors.fill), pas un enfant géré par un Layout
        // parent — donc pas de conflit.
        delegate: Item {
            id: tabDelegate
            required property var modelData
            required property int index
            Layout.fillWidth: true
            implicitHeight: content.implicitHeight

            ColumnLayout {
                id: content
                anchors.fill: parent
                spacing: 4

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 5
                    Text {
                        text: tabDelegate.modelData.icon
                        color: root.currentIndex === tabDelegate.index ? "#1C7AFF" : "#8A8A8A"
                        font.pixelSize: 12
                    }
                    Text {
                        text: tabDelegate.modelData.label
                        color: root.currentIndex === tabDelegate.index ? "#FFFFFF" : "#8A8A8A"
                        font.pixelSize: 11
                        font.bold: root.currentIndex === tabDelegate.index
                        font.family: "SF Pro Rounded"
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 2
                    radius: 1
                    color: root.currentIndex === tabDelegate.index ? "#1C7AFF" : "#2A2A2A"
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.currentIndex = tabDelegate.index
            }
        }
    }
}
