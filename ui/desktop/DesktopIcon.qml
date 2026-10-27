import QtQuick
import qs.services

Item {
    id: root

    required property string fileName
    required property string filePath
    required property bool fileIsDir
    required property real cellX
    required property real cellY
    required property real cellWidth
    required property real cellHeight

    property real followX: 0
    property real followY: 0
    property bool instant: false
    readonly property bool dragActive: area.drag.active

    signal dragMoved(real dx, real dy)
    signal dropped(real centerX, real centerY)
    signal contextRequested(real x, real y)

    readonly property bool selected: DesktopFiles.selection.indexOf(root.filePath) >= 0
    readonly property bool editing: DesktopFiles.renaming === root.filePath
    readonly property bool thumbnail: !root.fileIsDir && DesktopFiles.isImage(root.fileName)

    x: root.cellX + root.followX
    y: root.cellY + root.followY
    width: root.cellWidth
    height: root.cellHeight
    z: area.drag.active ? 100 : 0

    onXChanged: {
        if (area.drag.active) root.dragMoved(root.x - root.cellX, root.y - root.cellY)
    }

    onYChanged: {
        if (area.drag.active) root.dragMoved(root.x - root.cellX, root.y - root.cellY)
    }

    Behavior on x {
        enabled: !area.drag.active && !root.instant
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    Behavior on y {
        enabled: !area.drag.active && !root.instant
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    function resetPosition() {
        root.x = Qt.binding(function() { return root.cellX + root.followX })
        root.y = Qt.binding(function() { return root.cellY + root.followY })
    }

    function startEditing() {
        renameInput.text = root.fileName
        renameInput.forceActiveFocus()
        renameInput.selectAll()
    }

    onEditingChanged: {
        if (root.editing) root.startEditing()
    }

    Component.onCompleted: {
        if (root.editing) root.startEditing()
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: 10
        color: Qt.rgba(1, 1, 1, 0.18)
        visible: root.selected
    }

    Image {
        id: glyph
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 8
        width: 56
        height: 56
        source: root.thumbnail ? "file://" + root.filePath : DesktopFiles.iconPathFor(root.fileName, root.fileIsDir)
        sourceSize: Qt.size(112, 112)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
    }

    Text {
        anchors.top: glyph.bottom
        anchors.topMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        visible: !root.editing
        horizontalAlignment: Text.AlignHCenter
        text: DesktopFiles.labelFor(root.fileName)
        wrapMode: Text.Wrap
        maximumLineCount: 2
        elide: Text.ElideRight
        color: "#ffffff"
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.55)
        font.pixelSize: 12
        font.family: "SF Pro Text"
        renderType: Text.NativeRendering
    }

    Rectangle {
        anchors.top: glyph.bottom
        anchors.topMargin: 2
        anchors.left: parent.left
        anchors.right: parent.right
        height: 22
        radius: 6
        color: "#59000000"
        border.width: 1
        border.color: "#60ffffff"
        visible: root.editing

        TextInput {
            id: renameInput
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            verticalAlignment: TextInput.AlignVCenter
            color: "#ffffff"
            selectionColor: "#a35cf0"
            selectedTextColor: "#ffffff"
            clip: true
            selectByMouse: true
            font.pixelSize: 12
            font.family: "SF Pro Text"
            renderType: Text.NativeRendering
            onAccepted: {
                DesktopFiles.rename(root.filePath, renameInput.text)
                DesktopFiles.renaming = ""
            }
            Keys.onEscapePressed: DesktopFiles.renaming = ""
            onActiveFocusChanged: {
                if (renameInput.activeFocus || !root.editing) return
                DesktopFiles.rename(root.filePath, renameInput.text)
                DesktopFiles.renaming = ""
            }
        }
    }

    MouseArea {
        id: area

        property bool moved: false
        property bool ctrlPressed: false

        anchors.fill: parent
        enabled: !root.editing
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        drag.target: pressedButtons === Qt.LeftButton ? root : null
        drag.threshold: 6

        onPressed: function(mouse) {
            if (mouse.button === Qt.LeftButton && (mouse.modifiers & Qt.ControlModifier)) {
                DesktopFiles.toggleSelected(root.filePath)
                ctrlPressed = true
            } else if (!root.selected) {
                DesktopFiles.selectOnly(root.filePath)
            }
        }
        onPositionChanged: {
            if (drag.active) moved = true
        }
        onReleased: function(mouse) {
            if (!moved) {
                if (mouse.button === Qt.LeftButton && !ctrlPressed && DesktopFiles.selection.length > 1) DesktopFiles.selectOnly(root.filePath)
                ctrlPressed = false
                return
            }
            ctrlPressed = false
            moved = false
            root.dropped(root.x + root.width / 2, root.y + root.height / 2)
            root.resetPosition()
        }
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) root.contextRequested(root.x + mouse.x, root.y + mouse.y)
        }
        onDoubleClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) DesktopFiles.open(root.filePath, root.fileName)
        }
    }
}
