import QtQuick
import qs.services

Item {
    id: root

    required property string fileName
    required property string filePath
    required property bool fileIsDir

    readonly property bool selected: DesktopFiles.selected === root.filePath
    readonly property bool editing: DesktopFiles.renaming === root.filePath
    readonly property bool thumbnail: !root.fileIsDir && DesktopFiles.isImage(root.fileName)

    width: 96
    height: 104

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
        font.family: "SF Pro Rounded"
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
            font.family: "SF Pro Rounded"
            renderType: Text.NativeRendering
            onAccepted: {
                DesktopFiles.rename(root.filePath, renameInput.text)
                DesktopFiles.renaming = ""
            }
            Keys.onEscapePressed: DesktopFiles.renaming = ""
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.editing
        onPressed: DesktopFiles.selected = root.filePath
        onDoubleClicked: DesktopFiles.open(root.filePath, root.fileName)
    }
}
