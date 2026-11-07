import QtQuick

QtObject {
    id: root

    property string theme: "glass"

    readonly property bool light: root.theme === "light"
    readonly property bool dark: root.theme === "dark"
    readonly property bool glass: root.theme !== "light" && root.theme !== "dark"

    readonly property color primary: root.light ? "#1c1c1e" : "#ffffff"
    readonly property color secondary: root.light ? Qt.rgba(0, 0, 0, 0.6) : Qt.rgba(1, 1, 1, 0.6)
    readonly property color tertiary: root.light ? Qt.rgba(0, 0, 0, 0.4) : Qt.rgba(1, 1, 1, 0.4)
    readonly property color track: root.light ? Qt.rgba(0, 0, 0, 0.10) : Qt.rgba(1, 1, 1, 0.14)
    readonly property color surface: root.light ? Qt.rgba(0, 0, 0, 0.05) : Qt.rgba(1, 1, 1, 0.08)
    readonly property color hover: root.light ? Qt.rgba(0, 0, 0, 0.12) : Qt.rgba(1, 1, 1, 0.22)
    readonly property color divider: root.light ? Qt.rgba(0, 0, 0, 0.12) : Qt.rgba(1, 1, 1, 0.2)

    readonly property color background: root.light ? "#f6f6f8" : (root.dark ? "#1c1c1e" : "transparent")
    readonly property color rim: root.light ? "#22000000" : (root.dark ? "#26ffffff" : "#60ffffff")

    readonly property color faceColor: root.dark ? "#2a2a2d" : "#f4f4f6"
    readonly property color faceInk: root.dark ? "#f2f2f7" : "#1c1c1f"
    readonly property color faceTick: root.dark ? "#d8d8de" : "#2b2b30"

    readonly property color skyTop: root.light ? "#3d8fe6" : (root.dark ? "#0a1a38" : "#0d3f9e")
    readonly property color skyBottom: root.light ? "#8ec8ff" : (root.dark ? "#17315f" : "#1f6fd6")
}
