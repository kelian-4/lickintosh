import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root

    property var look: null

    property string size: "s"
    property bool adding: false

    readonly property real k: Math.min(root.width / (root.size === "s" ? 140 : 330), root.height / (root.size === "l" ? 326 : 140))
    readonly property color blue: "#0a84ff"
    readonly property var ordered: TasksState.pending.concat(TasksState.done)

    function openEditor() {
        root.adding = true
        WidgetState.typing = true
        newInput.forceActiveFocus()
    }

    function closeEditor() {
        root.adding = false
        newInput.text = ""
        WidgetState.typing = false
    }

    function commit() {
        TasksState.addTask(newInput.text)
        newInput.text = ""
    }

    Component.onDestruction: {
        if (root.adding) WidgetState.typing = false
    }

    HoverHandler { id: headHover }

    MouseArea {
        anchors.fill: parent
        onPressed: function(mouse) {
            root.forceActiveFocus()
            mouse.accepted = false
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6 * root.k

        RowLayout {
            Layout.fillWidth: true
            spacing: 8 * root.k

            Text {
                Layout.fillWidth: true
                text: I18n.tr("Tasks")
                elide: Text.ElideRight
                color: root.blue
                font.pixelSize: 14 * root.k
                font.weight: Font.Bold
                font.family: "SF Pro Display"
                renderType: Text.NativeRendering
            }

            Rectangle {
                Layout.preferredWidth: 20 * root.k
                Layout.preferredHeight: 20 * root.k
                radius: 10 * root.k
                opacity: (headHover.hovered || root.adding) ? 1 : 0
                visible: opacity > 0.01
                color: addArea.containsMouse ? Qt.rgba(root.blue.r, root.blue.g, root.blue.b, 0.22) : "transparent"
                rotation: root.adding ? 45 : 0
                scale: addArea.pressed ? 0.88 : 1

                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on rotation { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 2 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }

                Rectangle { anchors.centerIn: parent; width: 11 * root.k; height: 1.7 * root.k; radius: 1; color: root.blue }
                Rectangle { anchors.centerIn: parent; width: 1.7 * root.k; height: 11 * root.k; radius: 1; color: root.blue }

                MouseArea {
                    id: addArea
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.adding ? root.closeEditor() : root.openEditor()
                }
            }

            Text {
                text: TasksState.pending.length
                color: root.blue
                font.pixelSize: 22 * root.k
                font.weight: Font.Bold
                font.family: "SF Pro Display"
                renderType: Text.NativeRendering
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.adding ? 22 * root.k : 0
            visible: Layout.preferredHeight > 0.5
            clip: true
            opacity: root.adding ? 1 : 0

            Behavior on Layout.preferredHeight { NumberAnimation { duration: 280; easing.type: Easing.OutQuint } }
            Behavior on opacity { NumberAnimation { duration: 220 } }

            Rectangle {
                id: newCircle
                width: 16 * root.k
                height: width
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                color: "transparent"
                border.width: 1.5
                border.color: root.look.secondary
            }

            TextInput {
                id: newInput
                anchors.left: newCircle.right
                anchors.leftMargin: 8 * root.k
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                clip: true
                color: root.look.primary
                selectByMouse: false
                font.pixelSize: 13 * root.k
                font.family: "SF Pro Text"
                renderType: Text.NativeRendering
                onAccepted: root.commit()
                onActiveFocusChanged: {
                    if (!newInput.activeFocus && root.adding) root.closeEditor()
                }
                Keys.onEscapePressed: root.closeEditor()

                Text {
                    visible: newInput.text === "" && !newInput.preeditText
                    text: I18n.tr("New Task")
                    color: root.look.tertiary
                    font: newInput.font
                    renderType: Text.NativeRendering
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.ordered.length === 0 && !root.adding
            text: I18n.tr("Nothing to do")
            color: root.look.secondary
            font.pixelSize: 13 * root.k
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: tasksColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height + 2

            ColumnLayout {
                id: tasksColumn
                width: parent.width
                spacing: 7 * root.k

                Repeater {
                    model: root.ordered

                    delegate: RowLayout {
                        id: taskRow
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 8 * root.k

                        HoverHandler { id: rowHover }

                        Rectangle {
                            id: tick
                            Layout.preferredWidth: 16 * root.k
                            Layout.preferredHeight: 16 * root.k
                            radius: width / 2
                            readonly property bool checked: taskRow.modelData.done
                            property real fill: tick.checked ? 1 : 0
                            property real press: 0
                            color: Qt.rgba(root.blue.r, root.blue.g, root.blue.b, tick.fill)
                            border.width: 1.5
                            border.color: tick.checked ? root.blue : root.look.secondary
                            scale: 1 - 0.18 * tick.press

                            Behavior on fill { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 2.4 } }
                            Behavior on border.color { ColorAnimation { duration: 300 } }

                            SequentialAnimation {
                                id: tickPop
                                NumberAnimation { target: tick; property: "press"; to: 1; duration: 90; easing.type: Easing.OutCubic }
                                NumberAnimation { target: tick; property: "press"; to: 0; duration: 420; easing.type: Easing.OutBack; easing.overshoot: 3.0 }
                            }

                            Canvas {
                                anchors.centerIn: parent
                                width: 11 * root.k
                                height: width
                                property real draw: tick.fill
                                onDrawChanged: requestPaint()
                                onWidthChanged: requestPaint()
                                onPaint: {
                                    var c = getContext("2d")
                                    c.reset()
                                    if (draw <= 0.01) return
                                    var s = width / 11
                                    c.scale(s, s)
                                    c.strokeStyle = "white"
                                    c.lineWidth = 1.9
                                    c.lineCap = "round"
                                    c.lineJoin = "round"
                                    var p = [[1.6, 5.6], [4.3, 8.4], [9.4, 2.6]]
                                    var d = Math.max(0, Math.min(1, (draw - 0.15) / 0.85))
                                    c.beginPath()
                                    c.moveTo(p[0][0], p[0][1])
                                    var t1 = Math.min(1, d / 0.4)
                                    c.lineTo(p[0][0] + (p[1][0] - p[0][0]) * t1, p[0][1] + (p[1][1] - p[0][1]) * t1)
                                    if (d > 0.4) {
                                        var t2 = (d - 0.4) / 0.6
                                        c.lineTo(p[1][0] + (p[2][0] - p[1][0]) * t2, p[1][1] + (p[2][1] - p[1][1]) * t2)
                                    }
                                    c.stroke()
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    tickPop.restart()
                                    TasksState.toggleTask(taskRow.modelData.id)
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: taskRow.modelData.text
                            elide: Text.ElideRight
                            font.strikeout: taskRow.modelData.done
                            color: taskRow.modelData.done ? root.look.secondary : root.look.primary
                            font.pixelSize: 13 * root.k
                            font.family: "SF Pro Text"
                            renderType: Text.NativeRendering
                        }

                        Text {
                            text: "×"
                            opacity: rowHover.hovered ? 1 : 0
                            color: delArea.containsMouse ? "#ff453a" : root.look.tertiary
                            font.pixelSize: 15 * root.k
                            font.family: "SF Pro Text"
                            renderType: Text.NativeRendering

                            Behavior on opacity { NumberAnimation { duration: 140 } }

                            MouseArea {
                                id: delArea
                                anchors.fill: parent
                                anchors.margins: -5
                                enabled: rowHover.hovered
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: TasksState.removeTask(taskRow.modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
