pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/*
    Détecte si une application capture la caméra et/ou le micro.
    Pas d'API caméra native dans Quickshell : sondage direct de
    PipeWire via `pw-dump` (dépendance de fait sous Hyprland). Best-
    effort par polling, pas un flux d'évènements.
*/
Singleton {
    id: root

    reloadableId: "mediaCaptureState"

    property bool cameraActive: false
    property bool micActive:    false
    property var  cameraApps:   []
    property var  micApps:      []

    Process {
        id: _dump
        command: ["pw-dump"]
        stdout: StdioCollector {
            onStreamFinished: root._parse(text)
        }
    }

    function _parse(jsonText) {
        var nodes
        try {
            nodes = JSON.parse(jsonText)
        } catch (e) {
            return
        }
        if (!Array.isArray(nodes)) return

        var camApps = []
        var micApps = []

        for (var i = 0; i < nodes.length; i++) {
            var n = nodes[i]
            if (!n.info || !n.info.props) continue

            var props      = n.info.props
            var mediaClass = props["media.class"] || ""
            var state      = n.info.state || ""
            if (state !== "running") continue

            var appName = props["application.name"] || props["node.description"] || props["node.name"] || "Application"

            if (mediaClass.indexOf("Video") !== -1 && mediaClass.indexOf("Input") !== -1) {
                if (camApps.indexOf(appName) === -1) camApps.push(appName)
            } else if (mediaClass === "Stream/Input/Audio") {
                if (micApps.indexOf(appName) === -1) micApps.push(appName)
            }
        }

        root.cameraApps   = camApps
        root.micApps      = micApps
        root.cameraActive = camApps.length > 0
        root.micActive    = micApps.length > 0
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!_dump.running) _dump.running = true
    }
}
