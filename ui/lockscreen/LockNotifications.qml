pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.components.glass
import qs.services
import qs.ui.topbar.statusarea.notifcenter

/*
    LockNotifications — pile de notifications de l'écran de verrouillage,
    en lecture seule (aucune action possible verrouillé : même principe
    que LockStatusIndicators).

    Idée reprise du lockscreen d'eqsh (eq-desktop/eqsh, abandonné) : des
    cartes en verre avec icône, titre, extrait et heure relative, plus un
    résumé "+ N" quand il y a trop de notifications. On n'en reprend PAS
    l'architecture, qui fuit :
      - eqsh crée ses notifications et leurs Timer par createObject() et
        garde une liste qui grossit + une persistance JSON ;
      - ici on lit simplement NotifService (déjà la source de vérité du
        centre de notifications), aucun objet n'est créé dynamiquement.
        NotifService/le protocole de notifications ne portent aucune date
        d'arrivée (NotifItem.qml, dans le centre existant, a le même
        besoin et s'en tire pareil : Date.now() lu au moment du rendu).
        On fait donc pareil ici, dans arrivals : un Map local, écrit une
        seule fois par notification (première fois qu'elle est vue), lu
        ensuite pour le libellé relatif ; purgé quand la notification
        n'est plus dans root.all pour ne pas grossir indéfiniment.
*/
Item {
    id: root

    readonly property var cfg: ShellConfig.options.lockscreen

    // Nombre max de cartes affichées ; le reste est résumé en "+ N".
    property int maxShown: 3

    // Toutes les notifications suivies, les plus récentes d'abord.
    // Se réévalue quand NotifService reconstruit ses groupes.
    readonly property var all: {
        const groups = NotifService.appGroupsList.concat(NotifService.systemGroupsList)
        const out = []
        for (let g = 0; g < groups.length; g++) {
            for (let i = 0; i < groups[g].items.length; i++)
                out.push(groups[g].items[i])
        }
        // Pas de date d'arrivée sur l'objet notification (voir arrivals
        // ci-dessous) : l'id, croissant à l'émission, sert d'ordre.
        out.sort((a, b) => b.id - a.id)
        return out
    }
    readonly property var shown: root.all.slice(0, root.maxShown)
    readonly property int hiddenCount: Math.max(0, root.all.length - root.maxShown)

    // Heure de premiere apparition de chaque notification suivie (aucun
    // champ de ce genre n'existe sur l'objet notification lui-meme). Cle
    // = notifObj.id, valeur = timestamp ms. Purge des entrees dont la
    // notification a disparu, pour ne pas grossir indefiniment.
    property var arrivals: ({})
    onAllChanged: {
        const next = {}
        for (let i = 0; i < root.all.length; i++) {
            const id = root.all[i].id
            next[id] = (id in root.arrivals) ? root.arrivals[id] : Date.now()
        }
        root.arrivals = next
    }

    // Heure de référence des libellés relatifs. Mise à jour seulement
    // tant que la pile est visible (pas de Timer qui tourne pour rien).
    property double now: Date.now()
    onVisibleChanged: if (visible) root.now = Date.now()
    Timer {
        interval: 30000
        repeat: true
        running: root.visible
        onTriggered: root.now = Date.now()
    }

    function relTime(notifId) {
        const ts = root.arrivals[notifId]
        if (!ts) return ""
        const s = Math.max(0, Math.floor((root.now - ts) / 1000))
        if (s < 60) return qsTr("maintenant")
        const m = Math.floor(s / 60)
        if (m < 60) return qsTr("il y a %1 min").arg(m)
        const h = Math.floor(m / 60)
        if (h < 24) return qsTr("il y a %1 h").arg(h)
        return qsTr("hier")
    }

    // Le corps peut contenir du balisage (le serveur annonce
    // bodyMarkupSupported) : on le réduit à du texte brut, jamais
    // interprété (pas de liens cliquables sur un écran verrouillé).
    function plain(s) {
        return (s || "").replace(/<[^>]*>/g, "")
            .replace(/&lt;/g, "<").replace(/&gt;/g, ">")
            .replace(/&quot;/g, "\"").replace(/&#39;/g, "'")
            .replace(/&amp;/g, "&")
    }

    visible: root.cfg.showNotifications && root.shown.length > 0
    implicitWidth: 360
    implicitHeight: root.visible ? stack.implicitHeight : 0

    opacity: root.visible ? 1 : 0
    Behavior on opacity {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    Column {
        id: stack
        width: parent.width
        spacing: 8

        Repeater {
            model: root.shown

            delegate: Item {
                id: card

                required property var modelData

                // Une notification fermée peut disparaître avant que le
                // modèle soit reconstruit : on ne suppose jamais qu'elle
                // existe encore.
                readonly property bool valid: card.modelData !== null && card.modelData !== undefined

                readonly property string appName: card.valid ? (card.modelData.appName || "") : ""
                readonly property string title: card.valid
                    ? (root.cfg.showNotificationPreviews
                        ? (card.modelData.summary || card.appName)
                        : (card.appName.length > 0 ? card.appName : qsTr("Notification")))
                    : ""
                readonly property string body: (card.valid && root.cfg.showNotificationPreviews)
                    ? root.plain(card.modelData.body)
                    : ""

                width: stack.width
                height: Math.max(58, textCol.implicitHeight + 22)

                CFClippingRect {
                    anchors.fill: parent
                    radius: 16

                    BoxGlass {
                        anchors.fill: parent
                        radius: 16
                        color: Qt.rgba(1, 1, 1, 0.10)
                        light: Qt.rgba(1, 1, 1, 0.28)
                        rimStrength: 0.7
                        highlightEnabled: true
                    }
                }

                Item {
                    id: iconBox
                    x: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 34
                    height: 34

                    NotifIcon {
                        id: notifIcon
                        anchors.fill: parent
                        size: 34
                        icon: card.valid ? (card.modelData.appIcon || "") : ""
                        appName: card.appName
                    }

                    // Repli quand l'application n'a aucune icône résolvable.
                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: Qt.rgba(1, 1, 1, 0.14)
                        visible: notifIcon.resolvedSource === ""

                        CFVI {
                            anchors.centerIn: parent
                            icon: "settings/notifications.svg"
                            size: 18
                            gray: true
                        }
                    }
                }

                Column {
                    id: textCol
                    anchors.left: iconBox.right
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Item {
                        width: parent.width
                        height: titleText.implicitHeight

                        Text {
                            id: titleText
                            anchors.left: parent.left
                            anchors.right: timeText.left
                            anchors.rightMargin: 8
                            text: card.title
                            color: "#f2ffffff"
                            font.family: "SF Pro Display"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            renderType: Text.NativeRendering
                        }

                        Text {
                            id: timeText
                            anchors.right: parent.right
                            anchors.verticalCenter: titleText.verticalCenter
                            text: card.valid ? root.relTime(card.modelData.id) : ""
                            color: "#99ffffff"
                            font.family: "SF Pro Display"
                            font.pixelSize: 11
                            renderType: Text.NativeRendering
                        }
                    }

                    Text {
                        width: parent.width
                        visible: text.length > 0
                        text: card.body
                        color: "#ccffffff"
                        font.family: "SF Pro Display"
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                    }
                }
            }
        }

        Text {
            width: parent.width
            visible: root.hiddenCount > 0
            horizontalAlignment: Text.AlignHCenter
            text: root.hiddenCount === 1
                ? qsTr("+ 1 autre notification")
                : qsTr("+ %1 autres notifications").arg(root.hiddenCount)
            color: "#b3ffffff"
            font.family: "SF Pro Display"
            font.pixelSize: 12
            font.weight: Font.Medium
            renderType: Text.NativeRendering
        }
    }
}
