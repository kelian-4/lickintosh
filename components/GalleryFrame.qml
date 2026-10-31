import QtQuick
import QtQuick.Layouts
import qs.components

Rectangle {
    id: root

    property var categories: []
    property string category: "all"
    property string query: ""
    property string searchPlaceholder: "Search"
    property string hint: ""
    property string emptyText: "Nothing Found"
    property bool empty: false
    property color accent: "#a35cf0"
    property var window: null
    property bool showThemes: false
    property string theme: "glass"
    signal themePicked(string theme)
    signal done()

    default property alias content: contentColumn.data

    color: "#0d0d0d"
    clip: true

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Item {
            Layout.preferredWidth: 232
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: card
                anchors.margins: -6
                radius: card.radius + 6
                color: "#40000000"
            }

            Rectangle {
                id: card
                anchors.fill: parent
                anchors.margins: 12
                radius: 18
                color: "#30161616"
                border.width: 1
                border.color: "#20ffffff"
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    WindowControls {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        Layout.topMargin: 16
                        Layout.leftMargin: 16
                        window: root.window
                        onCloseRequested: root.done()
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        Layout.margins: 12

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: "#12ffffff"
                            border.width: searchInput.activeFocus ? 2 : 0
                            border.color: root.accent

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 6

                                CFVI {
                                    icon: "search.svg"
                                    size: 13
                                    gray: true
                                }

                                TextInput {
                                    id: searchInput
                                    Layout.fillWidth: true
                                    focus: true
                                    color: "#ffffff"
                                    clip: true
                                    selectByMouse: true
                                    font.pixelSize: 13
                                    font.family: "SF Pro Text"
                                    renderType: Text.NativeRendering
                                    onTextChanged: root.query = searchInput.text
                                    Keys.onEscapePressed: root.done()

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: searchInput.text === "" && !searchInput.preeditText
                                        text: root.searchPlaceholder
                                        color: Qt.rgba(1, 1, 1, 0.45)
                                        font: searchInput.font
                                        renderType: Text.NativeRendering
                                    }
                                }
                            }
                        }
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: width
                        contentHeight: categoryColumn.implicitHeight + 12
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: categoryColumn
                            x: 10
                            width: parent.width - 20
                            spacing: 2

                            Repeater {
                                model: root.categories

                                delegate: Rectangle {
                                    id: entry
                                    required property var modelData

                                    width: categoryColumn.width
                                    height: 34
                                    radius: 10
                                    color: root.category === entry.modelData.key ? Qt.rgba(1, 1, 1, 0.14) : (entryArea.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 10

                                        Rectangle {
                                            Layout.preferredWidth: 22
                                            Layout.preferredHeight: 22
                                            radius: 6
                                            color: entry.modelData.tint

                                            CFVI {
                                                anchors.centerIn: parent
                                                size: 14
                                                icon: entry.modelData.icon
                                                colorized: entry.modelData.raw !== true
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: entry.modelData.title
                                            elide: Text.ElideRight
                                            color: "#ffffff"
                                            font.pixelSize: 13
                                            font.weight: Font.Medium
                                            font.family: "SF Pro Text"
                                            renderType: Text.NativeRendering
                                        }
                                    }

                                    MouseArea {
                                        id: entryArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.category = entry.modelData.key
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 18
                contentWidth: width
                contentHeight: contentColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: contentColumn
                    width: parent.width
                    spacing: 20

                    Text {
                        Layout.fillWidth: true
                        visible: root.empty
                        horizontalAlignment: Text.AlignHCenter
                        text: root.emptyText
                        color: Qt.rgba(1, 1, 1, 0.5)
                        font.pixelSize: 14
                        font.family: "SF Pro Text"
                        renderType: Text.NativeRendering
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.rgba(1, 1, 1, 0.10)
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                Layout.leftMargin: 18
                Layout.rightMargin: 18

                Text {
                    Layout.fillWidth: true
                    text: root.hint
                    elide: Text.ElideRight
                    color: Qt.rgba(1, 1, 1, 0.75)
                    font.pixelSize: 12
                    font.family: "SF Pro Text"
                    renderType: Text.NativeRendering
                }

                Rectangle {
                    visible: root.showThemes
                    Layout.preferredWidth: 168
                    Layout.preferredHeight: 28
                    radius: 14
                    color: "#14ffffff"

                    Row {
                        anchors.fill: parent

                        Repeater {
                            model: [{ key: "glass", title: "Glass" }, { key: "light", title: "Light" }, { key: "dark", title: "Dark" }]

                            delegate: Rectangle {
                                id: themeOption
                                required property var modelData

                                width: 56
                                height: 28
                                radius: 14
                                color: root.theme === themeOption.modelData.key ? Qt.rgba(1, 1, 1, 0.22) : "transparent"

                                Behavior on color {
                                    ColorAnimation { duration: 140 }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: themeOption.modelData.title
                                    color: "#ffffff"
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    font.family: "SF Pro Rounded"
                                    renderType: Text.NativeRendering
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.themePicked(themeOption.modelData.key)
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 68
                    Layout.preferredHeight: 28
                    radius: 14
                    color: root.accent

                    Text {
                        anchors.centerIn: parent
                        text: "Done"
                        color: "#ffffff"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        font.family: "SF Pro Text"
                        renderType: Text.NativeRendering
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.done()
                    }
                }
            }
        }
    }
}
