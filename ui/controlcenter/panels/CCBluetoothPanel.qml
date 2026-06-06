// ui/controlcenter/panels/CCBluetoothPanel.qml
// Quickshell.Bluetooth natif — même API qu'eqsh
// Deux sections : "Connectés" | "Disponibles"
// Hauteur entièrement explicite — pas de binding loop

import QtQuick
import QtQuick.VectorImage
import QtQuick.Effects
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import "../../components/glass"

Item {
    id: root

    BoxGlass {
    anchors.fill: parent
    radius: 20
    color: Qt.rgba(1, 1, 1, 0.06)
    light: Qt.rgba(1, 1, 1, 0.22)
    rimStrength: 0.6
    rimSize: 0.012
    }

    // Adapter natif
    property var  adapter:    Bluetooth.defaultAdapter
    property bool btOn:       adapter ? adapter.enabled : false

    // Tous les appareils avec nom
    property var allDevices: {
        if (!adapter) return []
            return adapter.devices.values.filter(function(d) { return d.name !== "" })
    }

    // Séparation en deux listes
    property var connected: {
        var res = []
        for (var i = 0; i < allDevices.length; i++) {
            if (allDevices[i].connected) res.push(allDevices[i])
        }
        return res
    }
    property var available: {
        var res = []
        for (var i = 0; i < allDevices.length; i++) {
            if (!allDevices[i].connected) res.push(allDevices[i])
        }
        return res
    }

    // Hauteurs constantes
    readonly property int _headerH:  54
    readonly property int _rowH:     46
    readonly property int _labelH:   28
    readonly property int _sepH:     1
    readonly property int _footerH:  44

    // Hauteur totale explicite
    height: {
        var h = _headerH + _sepH
        if (!btOn) return h + 48 + _footerH + 16
            // Section connectés
            if (connected.length > 0) h += _labelH + connected.length * _rowH + 8
                // Section disponibles
                if (available.length > 0) h += _labelH + available.length * _rowH + 8
                    if (connected.length === 0 && available.length === 0) h += 48
                        h += _sepH + _footerH + 8
                        return h
    }

    // ── En-tête + switch ──────────────────────────────────
    Item {
        id: _header
        anchors.top:   parent.top
        anchors.left:  parent.left
        anchors.right: parent.right
        height: root._headerH

        Text {
            anchors.left:           parent.left
            anchors.leftMargin:     18
            anchors.verticalCenter: parent.verticalCenter
            text: "Bluetooth"
            font.pixelSize: 16
            font.weight: Font.Bold
            font.family: "SF Pro Display"
            color: "#fff"
        }

        Rectangle {
            anchors.right:          parent.right
            anchors.rightMargin:    18
            anchors.verticalCenter: parent.verticalCenter
            width: 50; height: 28; radius: 14
            color: root.btOn ? "#1C7AFF" : Qt.rgba(1,1,1,0.22)
            Behavior on color { ColorAnimation { duration: 200 } }

            Rectangle {
                width: 22; height: 22; radius: 11; color: "white"
                anchors.verticalCenter: parent.verticalCenter
                x: root.btOn ? parent.width - width - 3 : 3
                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (root.adapter) root.adapter.enabled = !root.adapter.enabled
                }
            }
        }
    }

    Rectangle {
        id: _sep1
        anchors.top:              _header.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 36
        height: 0
        color: "transparent"
    }

    // ── Contenu ───────────────────────────────────────────
    Column {
        anchors.top:   _sep1.bottom
        anchors.left:  parent.left
        anchors.right: parent.right
        spacing: 0

        // BT désactivé
        Item {
            width: parent.width
            height: !root.btOn ? 48 : 0
            visible: !root.btOn
            Text {
                anchors.centerIn: parent
                text: "Activez Bluetooth pour voir les appareils"
                font.pixelSize: 12
                font.family: "SF Pro Display"
                color: Qt.rgba(1,1,1,0.35)
            }
        }

        // ── Section : Connectés ───────────────────────────
        Item {
            width: parent.width
            height: root.btOn && root.connected.length > 0 ? root._labelH : 0
            visible: root.btOn && root.connected.length > 0

            Text {
                anchors.left:           parent.left
                anchors.leftMargin:     18
                anchors.verticalCenter: parent.verticalCenter
                text: "Connectés"
                font.pixelSize: 11
                font.weight: Font.Medium
                font.family: "SF Pro Display"
                color: Qt.rgba(1,1,1,0.50)
            }
        }

        Repeater {
            model: root.btOn ? root.connected : []
            delegate: BtRow {
                required property var modelData
                width: parent.width
                height: root._rowH
                devName:   modelData.name
                connected: true
                onToggle: modelData.disconnect()
            }
        }

        // Padding entre sections
        Item {
            width: parent.width
            height: root.btOn && root.connected.length > 0 && root.available.length > 0 ? 8 : 0
        }

        // ── Section : Disponibles ─────────────────────────
        Item {
            width: parent.width
            height: root.btOn && root.available.length > 0 ? root._labelH : 0
            visible: root.btOn && root.available.length > 0

            Text {
                anchors.left:           parent.left
                anchors.leftMargin:     18
                anchors.verticalCenter: parent.verticalCenter
                text: "Disponibles"
                font.pixelSize: 11
                font.weight: Font.Medium
                font.family: "SF Pro Display"
                color: Qt.rgba(1,1,1,0.50)
            }
        }

        Repeater {
            model: root.btOn ? root.available : []
            delegate: BtRow {
                required property var modelData
                width: parent.width
                height: root._rowH
                devName:   modelData.name
                connected: false
                onToggle: modelData.connect()
            }
        }

        // Aucun appareil
        Item {
            width: parent.width
            height: root.btOn && root.allDevices.length === 0 ? 48 : 0
            visible: root.btOn && root.allDevices.length === 0
            Text {
                anchors.centerIn: parent
                text: "Aucun appareil trouvé"
                font.pixelSize: 12
                font.family: "SF Pro Display"
                color: Qt.rgba(1,1,1,0.35)
            }
        }

        Item { width: 1; height: 8 }

        Rectangle {
            width: parent.width - 36
            height: 0
            x: 18
            color: Qt.rgba(1,1,1,0.10)
        }

        // ── Paramètres ────────────────────────────────────
        Item {
            width: parent.width
            height: root._footerH

            Text {
                anchors.left:           parent.left
                anchors.leftMargin:     18
                anchors.verticalCenter: parent.verticalCenter
                text: "Paramètres Bluetooth…"
                font.pixelSize: 13
                font.family: "SF Pro Display"
                color: Qt.rgba(1,1,1,0.65)
            }

            Process {
                id: _btSettings
                command: ["blueman-manager"]
            }

            MouseArea {
                anchors.fill: parent
                onClicked:  _btSettings.running = true
                onPressed:  parent.opacity = 0.6
                onReleased: parent.opacity = 1.0
            }
        }
    }

    // ── Composant rangée appareil BT ──────────────────────
    component BtRow: Item {
        id: _br
        property string devName:   ""
        property bool   connected: false
        property bool   _hov:      false
        property bool   _loading:  false

        signal toggle()

        Rectangle {
            anchors.top:         parent.top
            anchors.bottom:      parent.bottom
            anchors.left:        parent.left
            anchors.right:       parent.right
            anchors.leftMargin:  10
            anchors.rightMargin: 10
            radius: 10
            color: _br._hov ? Qt.rgba(1,1,1,0.08) : "transparent"
            Behavior on color { ColorAnimation { duration: 100 } }
        }

        // Cercle icône BT
        Rectangle {
            id: _btIc
            anchors.left:        parent.left
            anchors.leftMargin:  14
            anchors.top:         parent.top
            anchors.topMargin:   8
            width: 30; height: 30; radius: 15
            color: _br.connected ? "#1C7AFF" : Qt.rgba(1,1,1,0.16)
            Behavior on color { ColorAnimation { duration: 200 } }

            VectorImage {
                anchors.centerIn: parent
                width: 16; height: 20
                source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/icons/bluetooth/bluetooth.svg")
                preferredRendererType: VectorImage.CurveRenderer
                layer.enabled: true
                layer.effect: MultiEffect { colorization: 1; colorizationColor: "#ffffff" }
            }
        }

        // Nom + statut
        Column {
            anchors.left:           _btIc.right
            anchors.leftMargin:     10
            anchors.verticalCenter: _btIc.verticalCenter
            spacing: 2

            Text {
                text: _br.devName
                font.pixelSize: 13
                font.family: "SF Pro Display"
                color: "#fff"
                elide: Text.ElideRight
                width: _br.width - 120
            }
            Text {
                visible: _br.connected
                text: _br._loading ? "Déconnexion…" : "Connecté"
                font.pixelSize: 10
                font.family: "SF Pro Display"
                color: Qt.rgba(1,1,1,0.50)
            }
            Text {
                visible: !_br.connected && _br._loading
                text: "Connexion…"
                font.pixelSize: 10
                font.family: "SF Pro Display"
                color: Qt.rgba(1,1,1,0.50)
            }
        }

        // ✓ connecté
        Text {
            anchors.right:          parent.right
            anchors.rightMargin:    16
            anchors.verticalCenter: _btIc.verticalCenter
            visible: _br.connected && !_br._loading
            text: "✓"
            font.pixelSize: 15
            font.weight: Font.Bold
            color: "#1C7AFF"
        }

        // Spinner chargement
        Text {
            anchors.right:          parent.right
            anchors.rightMargin:    16
            anchors.verticalCenter: _btIc.verticalCenter
            visible: _br._loading
            text: "···"
            font.pixelSize: 16
            color: Qt.rgba(1,1,1,0.45)
            SequentialAnimation on opacity {
                running: _br._loading
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 500 }
                NumberAnimation { to: 1.0; duration: 500 }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: _br._hov = true
            onExited:  _br._hov = false
            onClicked: {
                _br._loading = true
                _resetTimer.restart()
                _br.toggle()
            }
        }

        Timer {
            id: _resetTimer
            interval: 4000
            running: false
            repeat: false
            onTriggered: _br._loading = false
        }
    }
}
