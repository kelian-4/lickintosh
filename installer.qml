//@ pragma IconTheme MacTahoe-dark
//@ pragma UseQApplication
//@ pragma ShellId installer-app
//@ pragma AppId installer-app
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import qs.components.glass
import qs.components
import qs.services
import qs.ui.installer.widgets
import qs.ui.installer.pages

FloatingWindow {
    id: root

    visible: true
    title: I18n.tr("Installateur Lickintosh")
    implicitWidth: 900
    implicitHeight: 620
    minimumSize: Qt.size(860, 560)
    color: "transparent"

    Connections {
        target: Quickshell
        function onReloadCompleted() { Quickshell.watchFiles = false }
    }
    Connections {
        target: InstallerState
        function onPageRequested(page) {
            for (var i = 0; i < root.flatItems.length; i++)
                if (root.flatItems[i].component === page) { root.navigateTo(i); return }
        }
    }
    Component.onCompleted: {
        Quickshell.watchFiles = false
        Theme.applyToCompositor = false
        InstallerState.runPlan()
        var wanted = Quickshell.env("LICKINTOSH_INSTALLER_PAGE")
        if (wanted) {
            for (var i = 0; i < root.flatItems.length; i++) {
                if (root.flatItems[i].component === wanted) {
                    root.currentIndex = i
                    root._navHistory = [i]
                    break
                }
            }
        }
    }

    readonly property var sections: [
        {
            title: "",
            items: [
                { name: I18n.tr("Installation"),  icon: "settings/launchpad.svg", component: "InstallPage",      implemented: true },
                { name: I18n.tr("Dépendances"),   icon: "settings/widgets.svg",   component: "DependenciesPage", implemented: true }
            ]
        },
        {
            title: I18n.tr("Maintenance"),
            items: [
                { name: I18n.tr("Mises à jour"),  icon: "settings/update.svg",    component: "UpdatesPage",      implemented: true },
                { name: I18n.tr("Diagnostic"),    icon: "settings/accessibility.svg", component: "DoctorPage",   implemented: true },
                { name: I18n.tr("Outils"),        icon: "settings/general.svg",   component: "ToolsPage",        implemented: true },
                { name: I18n.tr("Désinstaller"),  icon: "settings/dock.svg",      component: "UninstallPage",    implemented: true }
            ]
        },
        {
            title: "",
            items: [
                { name: I18n.tr("À propos"),      icon: "settings/dialogs.svg",   component: "AboutPage",        implemented: true }
            ]
        }
    ]

    readonly property var flatItems: {
        var out = []
        for (var g = 0; g < sections.length; g++) {
            for (var i = 0; i < sections[g].items.length; i++) {
                out.push(sections[g].items[i])
            }
        }
        return out
    }

    property int currentIndex: 0
    readonly property var currentItem: flatItems.length > 0 ? flatItems[currentIndex] : null

    property var _navHistory: [0]
    property int _navPos: 0
    readonly property bool canGoBack: _navPos > 0

    readonly property bool canGoForward: _navPos < _navHistory.length - 1

    function navigateTo(index) {
        if (index === root.currentIndex) return
        var hist = root._navHistory.slice(0, root._navPos + 1)
        hist.push(index)
        root._navHistory = hist
        root._navPos = hist.length - 1
        root.currentIndex = index
    }

    function navigateBack() {
        if (!root.canGoBack) return
        root._navPos -= 1
        root.currentIndex = root._navHistory[root._navPos]
    }

    function navigateForward() {
        if (!root.canGoForward) return
        root._navPos += 1
        root.currentIndex = root._navHistory[root._navPos]
    }

    Rectangle {
        id: _windowCard
        anchors.fill: parent
        color: Theme.window
        clip: true

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Item {
                Layout.preferredWidth: 240 + 12
                Layout.fillHeight: true
                Layout.topMargin: 12
                Layout.bottomMargin: 12
                Layout.leftMargin: 12

                Rectangle {
                    id: _sidebarShadow
                    anchors.fill: _sidebarRoot
                    anchors.margins: -6
                    radius: _sidebarRoot.radius + 6
                    color: Theme.shadow
                }

                Rectangle {
                    id: _sidebarRoot
                    width: 240
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    radius: 18
                    color: Theme.panel
                    border.color: Theme.panelRim
                    border.width: 1
                    clip: true

                property string searchQuery: ""

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    Item {
                        id: _trafficLights
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        Layout.topMargin: 16
                        Layout.leftMargin: 16

                        property bool _hovered: false

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            onPressed: function(mouse) { root.startSystemMove() }
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            Rectangle {
                                width: 13
                                height: 13
                                radius: 7
                                color: "#FF5F57"

                                CFVI {
                                    anchors.centerIn: parent
                                    icon: "x-bold.svg"
                                    size: 8
                                    visible: _trafficLights._hovered
                                    color: "#801A0000"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: _trafficLights._hovered = true
                                    onExited:  _trafficLights._hovered = false
                                    onClicked: Qt.quit()
                                }
                            }

                            Rectangle {
                                width: 13
                                height: 13
                                radius: 7
                                color: "#FEBC2E"

                                CFVI {
                                    anchors.centerIn: parent
                                    icon: "windows/minimize.svg"
                                    size: 8
                                    visible: _trafficLights._hovered
                                    color: "#80663D00"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: _trafficLights._hovered = true
                                    onExited:  _trafficLights._hovered = false
                                    onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.window.move({ workspace = \"special:minimized\" })"])
                                }
                            }

                            Rectangle {
                                width: 13
                                height: 13
                                radius: 7
                                color: "#28C840"

                                CFVI {
                                    anchors.centerIn: parent
                                    icon: "maximize.svg"
                                    size: 7
                                    visible: _trafficLights._hovered
                                    color: "#80006B0E"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: _trafficLights._hovered = true
                                    onExited:  _trafficLights._hovered = false
                                    onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.window.fullscreen({ mode = \"maximized\", action = \"toggle\" })"])
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        Layout.margins: 12
                        Layout.topMargin: 16

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: Theme.fillSubtle

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
                                    id: _searchField
                                    Layout.fillWidth: true
                                    color: Theme.textPrimary
                                    font.pixelSize: 13
                                    clip: true
                                    selectByMouse: true
                                    onTextChanged: _sidebarRoot.searchQuery = text

                                    CFText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: I18n.tr("Rechercher")
                                        font.pixelSize: 13
                                        gray: true
                                        visible: _searchField.text.length === 0
                                    }
                                }
                            }
                        }
                    }

                    ScrollView {
                        id: _sidebarScroll
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.topMargin: 4
                        clip: true
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                        ColumnLayout {
                            width: _sidebarScroll.width - 24
                            x: 12
                            spacing: 4

                            Repeater {
                                model: root.sections

                                ColumnLayout {
                                    id: _group
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    Layout.topMargin: _group.index > 0 ? 16 : 0
                                    spacing: 2

                                    readonly property bool _hasVisibleItems: {
                                        var q = _sidebarRoot.searchQuery.toLowerCase()
                                        if (q.length === 0) return true
                                        for (var i = 0; i < _group.modelData.items.length; i++) {
                                            if (_group.modelData.items[i].name.toLowerCase().indexOf(q) !== -1) return true
                                        }
                                        return false
                                    }
                                    visible: _hasVisibleItems

                                    CFText {
                                        text: _group.modelData.title
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                        gray: true
                                        visible: _group.modelData.title.length > 0
                                        Layout.leftMargin: 10
                                        Layout.bottomMargin: 4
                                    }

                                    Repeater {
                                        model: _group.modelData.items

                                        Rectangle {
                                            id: _row
                                            required property var modelData
                                            required property int index

                                            readonly property int _flatIndex: {
                                                var count = 0
                                                for (var g = 0; g < root.sections.length; g++) {
                                                    if (g === _group.index) return count + _row.index
                                                    count += root.sections[g].items.length
                                                }
                                                return count
                                            }
                                            readonly property bool _selected: root.currentIndex === _row._flatIndex
                                            readonly property bool _matchesSearch: {
                                                var q = _sidebarRoot.searchQuery.toLowerCase()
                                                return q.length === 0 || _row.modelData.name.toLowerCase().indexOf(q) !== -1
                                            }

                                            Layout.fillWidth: true
                                            height: _matchesSearch ? 36 : 0
                                            visible: _matchesSearch
                                            radius: 8
                                            color: _row._selected ? Theme.accent : (_mouse.containsMouse ? Theme.fillHover : "transparent")
                                            Behavior on color { ColorAnimation { duration: 100 } }

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 8
                                                anchors.rightMargin: 8
                                                spacing: 8
                                                visible: _row.height > 0

                                                Item {
                                                    Layout.preferredWidth: 24
                                                    Layout.preferredHeight: 24

                                                    CFVI {
                                                        anchors.centerIn: parent
                                                        icon: _row.modelData.icon
                                                        size: 22
                                                        colorized: false
                                                    }
                                                }

                                                CFText {
                                                    text: _row.modelData.name
                                                    font.pixelSize: 14
                                                    color: _row._selected ? Theme.onAccent : Theme.textPrimary
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            MouseArea {
                                                id: _mouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.navigateTo(_row._flatIndex)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Item {
                    anchors.fill: parent
                    anchors.margins: 20
                    anchors.topMargin: 20

                    RowLayout {
                        id: _pageHeader
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 12

                        Item {
                            width: 76
                            height: 32

                            Rectangle {
                                anchors.fill: _navBg
                                anchors.margins: -4
                                radius: _navBg.radius + 4
                                color: Theme.shadow
                            }

                            Rectangle {
                                id: _navBg
                                anchors.fill: parent
                                radius: 16
                                color: Theme.fillControl
                                border.color: Theme.controlRim
                                border.width: 1

                            Row {
                                anchors.fill: parent
                                spacing: 0

                                Item {
                                    width: parent.width / 2
                                    height: parent.height

                                    CFVI {
                                        anchors.centerIn: parent
                                        icon: "chevron-left-bold.svg"
                                        size: 14
                                        gray: !root.canGoBack
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: root.canGoBack
                                        cursorShape: root.canGoBack ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: root.navigateBack()
                                    }
                                }

                                Rectangle {
                                    width: 1
                                    height: 18
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Theme.separator
                                }

                                Item {
                                    width: parent.width / 2 - 1
                                    height: parent.height

                                    CFVI {
                                        anchors.centerIn: parent
                                        icon: "chevron-right-bold.svg"
                                        size: 14
                                        gray: !root.canGoForward
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: root.canGoForward
                                        cursorShape: root.canGoForward ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: root.navigateForward()
                                    }
                                }
                            }
                            }
                        }

                        CFText {
                            text: root.currentItem ? root.currentItem.name : ""
                            font.pixelSize: 22
                            font.weight: Font.Bold
                            color: Theme.textPrimary
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    Loader {
                        anchors.top: _pageHeader.bottom
                        anchors.topMargin: 16
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom

                        sourceComponent: {
                            if (!root.currentItem) return _placeholderComp
                            if (!root.currentItem.implemented) return _placeholderComp
                            switch (root.currentItem.component) {
                                case "InstallPage":      return _installComp
                                case "DependenciesPage": return _depsComp
                                case "UpdatesPage":      return _updatesComp
                                case "DoctorPage":       return _doctorComp
                                case "ToolsPage":        return _toolsComp
                                case "UninstallPage":    return _uninstallComp
                                case "AboutPage":        return _aboutComp
                                default:                 return _placeholderComp
                            }
                        }
                    }
                }
            }
        }
    }

    Component { id: _placeholderComp; Item {} }
    Component { id: _installComp;   InstallPage {} }
    Component { id: _depsComp;      DependenciesPage {} }
    Component { id: _updatesComp;   UpdatesPage {} }
    Component { id: _doctorComp;    DoctorPage {} }
    Component { id: _toolsComp;     ToolsPage {} }
    Component { id: _uninstallComp; UninstallPage {} }
    Component { id: _aboutComp;     AboutPage {} }
}
