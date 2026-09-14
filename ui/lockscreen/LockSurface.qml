pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components
import qs.components.glass
import qs.services

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property LockContext context

    readonly property bool unlocking: unlockAnim.running
    readonly property bool reduceMotion: ShellConfig.options.appearance.reduceMotion

    color: "transparent"

    Component.onCompleted: {
        console.log("[LockSurface]", Date.now() + "ms:", "WlSessionLockSurface created for screen", root.screen)
    }

    // Construction d'URL file:// encodées correctement : centralisée
    // dans LockContext.toFileUrl() (singleton partagé entre LockScreen,
    // LockSurface), pas dupliquée ici.

    // -----------------------------------------------------------------
    // Horloge / date — recalculées à la seconde près, une seule fois
    // pour toutes les surfaces n'est pas possible ici (chaque écran a
    // son propre WlSessionLockSurface / QML tree), mais le coût d'un
    // SystemClock par écran est négligeable.
    // -----------------------------------------------------------------
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    readonly property string timeText: Qt.formatTime(clock.date, "h:mm")
    readonly property string dateText: Qt.formatDate(clock.date, "ddd d MMM")

    // Avatar/wallpaper détectés et calculés dans LockContext (singleton
    // partagé, chargé dès le démarrage du shell) — pas ici, pour éviter
    // un délai visible d'apparition au moment du lock. Voir
    // LockContext.avatarSource / avatarUrl / wallpaperSource.

    // -----------------------------------------------------------------
    // Déverrouillage : joue l'anim de sortie puis notifie le contexte.
    // Appelé depuis LockScreen quand context.unlocking() se déclenche
    // (le PAM a déjà validé le mot de passe à ce stade).
    // -----------------------------------------------------------------
    function playUnlock() {
        if (unlockAnim.running) return
        unlockAnim.start()
    }

    Connections {
        target: root.context
        function onUnlocking() { root.playUnlock() }
    }

    SequentialAnimation {
        id: unlockAnim

        ParallelAnimation {
            NumberAnimation { target: content; property: "opacity"; to: 0; duration: root.reduceMotion ? 1 : root.context.unlockAnimDuration - 100; easing.type: Easing.InQuad }
            NumberAnimation { target: content; property: "scale"; to: 0.96; duration: root.reduceMotion ? 1 : root.context.unlockAnimDuration - 100; easing.type: Easing.InQuad }
            NumberAnimation { target: background; property: "opacity"; to: 0; duration: root.reduceMotion ? 1 : root.context.unlockAnimDuration; easing.type: Easing.InQuad }
        }
    }

    // -----------------------------------------------------------------
    // Fond : wallpaper courant + blur progressif, identique à l'esprit
    // macOS (le fond est net au boot de l'écran puis se floute très
    // légèrement au premier rendu — ici on part flouté direct, plus
    // simple et sans scintillement).
    //
    // Source calculée dans LockContext (context.wallpaperSource), pas
    // recalculée ici : LockScreen précharge une Image avec cette même
    // URL avant même que la surface existe (voir LockScreen.qml), donc
    // réutiliser l'URL identique ici permet à Qt de servir depuis son
    // cache interne au lieu de relire/redécoder le fichier depuis le
    // disque au moment où l'écran de verrouillage apparaît.
    // -----------------------------------------------------------------
    Item {
        id: background
        anchors.fill: parent
        opacity: 0

        // Filet de sécurité seulement : en temps normal, cette Image sert
        // déjà le résultat du préchargement (LockScreen attend que
        // wallpaperPreloader/avatarPreloader terminent avant de poser
        // lock.locked = true — voir LockScreen.readyForLock), donc status
        // est déjà Ready dès la première frame et ce fondu ne se voit
        // presque jamais. Il ne s'active réellement que si le timeout de
        // sécurité de 800ms (LockScreen.lockTimeoutTimer) a forcé le
        // verrouillage avant la fin du décodage — coupe court à une
        // opacity: 1 déclarée nue, dont l'à-coup serait visible dans ce
        // cas limite.
        Behavior on opacity {
            NumberAnimation { duration: root.reduceMotion ? 1 : 200; easing.type: Easing.OutCubic }
        }

        Image {
            id: wallpaperImage
            anchors.fill: parent
            source: root.context.wallpaperSource
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            smooth: true
            visible: false
            layer.enabled: true
            // Décoder l'image à la taille d'affichage réelle plutôt qu'à
            // sa résolution native complète (souvent 4K/5K pour un
            // wallpaper) : c'est ce qui coûte le plus cher en temps de
            // décodage, largement plus que la simple lecture disque.
            // Comme le fond est de toute façon flouté juste après
            // (MultiEffect), la perte de netteté est invisible — c'est
            // exactement la stratégie utilisée par caelestia/CachingImage.
            sourceSize: Qt.size(root.width * (root.screen?.devicePixelRatio ?? 1),
                                 root.height * (root.screen?.devicePixelRatio ?? 1))

            // Ne révèle le fond qu'une fois le décodage terminé (Ready),
            // jamais avant : c'est ce binding qui déclenche le fondu
            // ci-dessus au bon moment, plutôt qu'un opacity fixe à 1 qui
            // laisse voir le "pop" au moment exact où Qt finit de décoder.
            onStatusChanged: {
                console.log("[LockSurface]", Date.now() + "ms:", "wallpaperImage.status ->", status,
                    "(0=Null,1=Ready,2=Loading,3=Error) source=" + source + " sourceSize=" + sourceSize)
                if (status === Image.Ready) background.opacity = 1
            }
            Component.onCompleted: {
                console.log("[LockSurface]", Date.now() + "ms:", "wallpaperImage created, initial status =", status,
                    "source=" + source)
            }
        }

        MultiEffect {
            id: wallpaperBlur
            anchors.fill: parent
            source: wallpaperImage
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1.0
            blurMax: 48
            blurMultiplier: 1
            // Léger zoom d'entrée, style eqsh (backgroundImageBlur.scale
            // part de "zoom" > 1 et redescend à 1) : accompagne
            // visuellement l'apparition du contenu plutôt que d'avoir un
            // fond parfaitement statique pendant que le reste s'anime.
            scale: root.reduceMotion ? 1 : 1.04
            Component.onCompleted: wallpaperBlur.scale = 1
            Behavior on scale {
                NumberAnimation { duration: root.reduceMotion ? 1 : 900; easing.type: Easing.OutCubic }
            }
        }

        // Léger voile sombre pour garantir la lisibilité du texte quel
        // que soit le fond choisi par l'utilisateur.
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.12
        }
    }

    // -----------------------------------------------------------------
    // Contenu interactif (horloge, avatar, champ mot de passe)
    // -----------------------------------------------------------------
    Item {
        id: content
        anchors.fill: parent
        // Style eqsh : dézoom en entrant (scale part de 1.06, plus grand
        // que 1) plutôt qu'un zoom depuis plus petit — combiné à une
        // translation verticale légère (translateY de -24 à 0), donne
        // une impression de contenu qui "se pose" plutôt que de
        // simplement apparaître en fondu.
        opacity: reduceMotion ? 1 : 0
        scale: reduceMotion ? 1 : 1.06

        transform: Translate {
            id: contentTranslate
            y: root.reduceMotion ? 0 : -24
            Behavior on y {
                NumberAnimation { duration: root.reduceMotion ? 1 : 480; easing.type: Easing.OutCubic }
            }
        }

        Component.onCompleted: {
            content.opacity = 1
            content.scale = 1
            contentTranslate.y = 0
        }
        Behavior on opacity {
            NumberAnimation { duration: root.reduceMotion ? 1 : 380; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: root.reduceMotion ? 1 : 380; easing.type: Easing.OutCubic }
        }

        // --- Statut système (batterie/wifi/bluetooth), haut droite ----
        // Mini Control Center en lecture seule, façon macOS — voir
        // LockStatusIndicators.qml pour le détail des sources d'état.
        LockStatusIndicators {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 20
            anchors.rightMargin: 24
        }

        // --- Date -------------------------------------------------
        Text {
            id: dateLabel
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Math.round(parent.height * 0.06)
            text: root.dateText
            color: "#ffffff"
            opacity: 0.85
            font.family: "SF Pro Display"
            font.pixelSize: 16
            font.weight: Font.Medium
            renderType: Text.NativeRendering
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#40000000"
                shadowBlur: 0.6
            }
        }

        // --- Heure ----------------------------------------------------
        // Effet "verre dépoli" façon eqsh : le fond déjà flouté
        // (wallpaperBlur) est capturé une seconde fois, seulement dans
        // le rectangle exact occupé par l'horloge, puis reflouté et
        // masqué par la forme du texte (maskSource: clockRow) — ça donne
        // un texte translucide qui laisse deviner le mouvement du fond
        // en dessous, plutôt qu'un simple texte blanc avec ombre portée.
        // clockRow.textColor reste blanc semi-transparent en-dessous :
        // sans lui, les zones où le fond est très sombre rendraient le
        // texte presque invisible.
        //
        // clockRow est déclaré en premier (pas les effets qui en
        // dépendent) : sourceRect ci-dessous a besoin de sa géométrie
        // déjà calculée (mapToItem, width, height) pour capturer la
        // bonne zone dès le premier rendu, plutôt que de dépendre d'un
        // item pas encore positionné.
        Row {
            id: clockRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: dateLabel.bottom
            anchors.topMargin: 4
            spacing: 0
            // Nécessaire pour que MultiEffect.maskSource (ci-dessous)
            // puisse utiliser clockRow comme texture de masque — sans
            // layer.enabled, ni un ShaderEffectSource ni un item
            // directement utilisable comme texture, le masque échoue
            // silencieusement (warning "ShaderEffect: 'source' does not
            // have a matching property", déjà rencontré ailleurs dans ce
            // projet pour la même raison).
            layer.enabled: true
            // layer.smooth: true est nécessaire pour un antialiasing
            // correct des bords du masque (confirmé par retour
            // d'expérience Qt Forum sur ce shader précis) — sans lui,
            // même avec les bons maskThresholdMin/maskSpreadAtMin, les
            // bords du masque restent visiblement crénelés.
            layer.smooth: true

            readonly property int digitSize: Math.round(Math.min(root.width * 0.09, 92))
            readonly property var timeParts: root.timeText.split(":")
            // Blanc quasi-opaque (pas #ccffffff comme avant, trop
            // transparent) : le texte doit rester clairement lisible en
            // toutes circonstances, l'effet "verre" vient surtout du
            // léger flou du fond visible au travers, pas d'une forte
            // transparence du texte lui-même.
            readonly property color textColor: "#f2ffffff"

            Text {
                text: clockRow.timeParts[0] ?? ""
                color: clockRow.textColor
                font.family: "SF Pro Display"
                font.pixelSize: clockRow.digitSize
                font.weight: Font.Black
                renderType: Text.NativeRendering
            }

            Text {
                text: ":"
                color: clockRow.textColor
                font.family: "SF Pro Display"
                // Plus large et plus gras que les chiffres pour que le
                // séparateur soit massif, comme sur l'écran de
                // verrouillage macOS (référence visuelle du projet).
                font.pixelSize: Math.round(clockRow.digitSize * 1.12)
                font.weight: Font.Black
                renderType: Text.NativeRendering
                topPadding: -Math.round(clockRow.digitSize * 0.06)
            }

            Text {
                text: clockRow.timeParts[1] ?? ""
                color: clockRow.textColor
                font.family: "SF Pro Display"
                font.pixelSize: clockRow.digitSize
                font.weight: Font.Black
                renderType: Text.NativeRendering
            }
        }

        ShaderEffectSource {
            id: clockBackdropSource
            anchors.fill: clockRow
            sourceItem: background
            sourceRect: Qt.rect(
                clockRow.mapToItem(content, 0, 0).x,
                clockRow.mapToItem(content, 0, 0).y,
                clockRow.width,
                clockRow.height
            )
            hideSource: false
            live: true
            visible: false
        }

        MultiEffect {
            id: clockBackdropBlur
            anchors.fill: clockRow
            source: clockBackdropSource
            blurEnabled: true
            blur: 1.0
            blurMax: 64
            blurMultiplier: 1.2
            brightness: 0.15
            autoPaddingEnabled: false
            maskEnabled: true
            maskSource: clockRow
            // Valeurs éprouvées pour un bord de masque net et lisse
            // (source : retour d'expérience Qt Forum sur ce shader précis)
            // — mes valeurs initiales (0.1/0.1) laissaient des bords en
            // dents de scie / "résidus" visibles autour des lettres.
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }

        // --- Mini lecteur média, au-dessus du bloc de connexion ------
        // N'occupe de la place que si un lecteur MPRIS est actif
        // (LockMediaPlayer.implicitHeight vaut 0 sinon) — ancré
        // indépendamment de loginArea pour ne jamais perturber le
        // positionnement de l'avatar/mot de passe selon sa présence.
        LockMediaPlayer {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: loginArea.top
            anchors.bottomMargin: hasPlayer ? 20 : 0
        }

        // --- Bloc bas : avatar / nom / mot de passe ------------------
        Column {
            id: loginArea
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Math.round(parent.height * 0.09)
            spacing: 8

            Item {
                id: avatarWrap
                anchors.horizontalCenter: parent.horizontalCenter
                width: 56
                height: 56

                CFClippingRect {
                    anchors.fill: parent
                    radius: width / 2

                    Image {
                        id: avatarImg
                        anchors.fill: parent
                        source: root.context.avatarUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                        cache: true
                        opacity: status === Image.Ready ? 1 : 0
                        // Avatar affiché à 56px seulement : inutile de
                        // décoder un fichier source potentiellement bien
                        // plus grand (ex: photo de profil haute
                        // résolution). Même stratégie que le wallpaper.
                        sourceSize: Qt.size(56 * (root.screen?.devicePixelRatio ?? 1), 56 * (root.screen?.devicePixelRatio ?? 1))

                        Component.onCompleted: {
                            console.log("[LockSurface]", Date.now() + "ms:", "avatarImg created, initial status =", status, "source=" + source)
                        }
                        onStatusChanged: {
                            console.log("[LockSurface]", Date.now() + "ms:", "avatarImg.status ->", status, "source=" + source)
                        }

                        // Fondu croisé avec le repli (initiale) ci-dessous
                        // plutôt qu'un basculement instantané au moment
                        // exact où le décodage se termine — même principe
                        // que le fond d'écran : masquer le temps de
                        // chargement par un mouvement plutôt que de
                        // chercher à l'annuler complètement.
                        Behavior on opacity {
                            NumberAnimation { duration: root.reduceMotion ? 1 : 150; easing.type: Easing.OutCubic }
                        }
                    }

                    // Repli si aucun avatar détecté (ou en attendant la
                    // détection) : initiale sur fond glass. Reste monté
                    // (visible piloté par opacity, pas par une bascule
                    // dure) pour que le fondu croisé avec avatarImg soit
                    // fluide plutôt qu'un pop.
                    Rectangle {
                        anchors.fill: parent
                        opacity: avatarImg.status === Image.Ready ? 0 : 1
                        color: Qt.rgba(1, 1, 1, 0.14)

                        Behavior on opacity {
                            NumberAnimation { duration: root.reduceMotion ? 1 : 150; easing.type: Easing.OutCubic }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: (Quickshell.env("USER") || "?").charAt(0).toUpperCase()
                            color: "#ffffff"
                            font.family: "SF Pro Display"
                            font.pixelSize: 22
                            font.weight: Font.DemiBold
                            renderType: Text.NativeRendering
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.color: Qt.rgba(1, 1, 1, 0.35)
                    border.width: 1
                }
            }

            // --- Nom (par défaut) <-> pilule mot de passe (au clic/frappe) ---
            // Comportement voulu : au repos, le nom d'utilisateur est
            // affiché ; dès que l'utilisateur clique ou appuie sur une
            // touche, il s'efface en fondu et la pilule glass apparaît à
            // sa place (les deux sont superposés au même endroit). Le
            // focus clavier est pris dès le chargement (pour pouvoir
            // taper sans cliquer, comme macOS), mais ça ne suffit pas à
            // révéler la pilule à soi seul — voir passHasInteracted. Le
            // sous-titre "Touch ID or Enter Password" reste un troisième
            // bloc distinct en dessous, toujours visible.
            Item {
                id: passField
                anchors.horizontalCenter: parent.horizontalCenter
                width: 220
                height: 34

                readonly property bool active: passHasInteracted || passInput.text.length > 0

                // Distingue le focus clavier technique (toujours actif,
                // pour pouvoir taper sans cliquer) de l'interaction
                // utilisateur réelle : sans ce flag, passInput.focus:
                // true ferait passer active à true dès le chargement de
                // la surface, affichant la pilule immédiatement au lieu
                // du nom.
                property bool passHasInteracted: false

                Text {
                    anchors.centerIn: parent
                    text: Quickshell.env("USER") || ""
                    color: "#ffffff"
                    font.family: "SF Pro Display"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    renderType: Text.NativeRendering
                    opacity: passField.active ? 0 : 1

                    Behavior on opacity {
                        NumberAnimation { duration: 180; easing.type: Easing.InOutQuad }
                    }
                }

                CFClippingRect {
                    id: pill
                    anchors.fill: parent
                    radius: height / 2
                    opacity: passField.active ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 180; easing.type: Easing.InOutQuad }
                    }

                    BoxGlass {
                        anchors.fill: parent
                        radius: pill.radius
                        color: Qt.rgba(1, 1, 1, 0.14)
                        light: Qt.rgba(1, 1, 1, 0.32)
                        rimStrength: 0.8
                        highlightEnabled: true
                    }

                    TextInput {
                        id: passInput
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 34
                        verticalAlignment: Text.AlignVCenter
                        color: "#ffffff"
                        font.family: "SF Pro Display"
                        // Taille dédiée aux points du mot de passe : plus
                        // grands que le texte normal (13px) pour qu'ils
                        // soient bien visibles et espacés, comme sur
                        // macOS/caelestia — un simple "•" à 13px paraît
                        // petit et serré. Le placeholder ("Enter Password"
                        // dans le champ, avant toute frappe) utilise sa
                        // propre taille séparée, plus petite, via le Text
                        // ci-dessous.
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        font.letterSpacing: 4
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        passwordMaskDelay: 0
                        clip: true
                        renderType: Text.NativeRendering
                        selectionColor: Qt.rgba(1, 1, 1, 0.35)
                        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                        enabled: !root.context.unlockInProgress

                        // Le champ garde le focus clavier en permanence
                        // tant que la surface est visible : on peut taper
                        // directement sans cliquer (comme macOS), et si
                        // le focus est perdu pour une raison quelconque
                        // (ex: un autre Item l'a volé), on le reprend
                        // immédiatement — un lockscreen ne doit jamais
                        // rester sans capture clavier utilisable.
                        focus: true
                        onActiveFocusChanged: {
                            if (!activeFocus && !root.unlocking)
                                passInput.forceActiveFocus()
                        }

                        // Toute frappe (même une touche qui ne modifie
                        // pas text, ex: flèches) compte comme une
                        // interaction réelle et révèle la pilule.
                        Keys.onPressed: event => {
                            passField.passHasInteracted = true
                        }

                        // Ne synchronise depuis passInput vers le contexte
                        // que lors d'une frappe utilisateur réelle. Un
                        // flag interne évite de rappeler updateText() (et
                        // donc de réinitialiser showFailure) quand c'est
                        // la synchro inverse ci-dessous qui modifie text
                        // programmatiquement après un échec PAM.
                        property bool _syncingFromContext: false

                        onTextChanged: {
                            if (!_syncingFromContext)
                                root.context.updateText(text)
                        }
                        onAccepted: root.context.tryUnlock()

                        Connections {
                            target: root.context
                            function onCurrentTextChanged() {
                                if (passInput.text === root.context.currentText)
                                    return
                                passInput._syncingFromContext = true
                                passInput.text = root.context.currentText
                                passInput._syncingFromContext = false
                            }
                            function onFailed() { wiggleAnim.restart() }
                        }

                        // Placeholder affiché à l'intérieur du champ
                        // lui-même quand il est vide — pas un Text séparé
                        // superposé qui se cache/affiche.
                        Text {
                            anchors.fill: parent
                            visible: passInput.text.length === 0
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            text: qsTr("Enter Password")
                            color: Qt.rgba(1, 1, 1, 0.55)
                            font.family: "SF Pro Display"
                            font.pixelSize: 13
                            renderType: Text.NativeRendering
                        }
                    }

                    // Flèche de validation à droite, façon macOS —
                    // n'apparaît que si du texte a été saisi. Cliquer
                    // dessus tente le déverrouillage, comme Entrée.
                    Rectangle {
                        id: submitRing
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        width: 26
                        height: 26
                        radius: width / 2
                        color: Qt.rgba(1, 1, 1, 0.18)
                        opacity: passInput.text.length === 0 ? 0 : 1
                        visible: !root.context.unlockInProgress

                        Behavior on opacity {
                            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "\u2192"
                            color: "#ffffff"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            renderType: Text.NativeRendering
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.context.tryUnlock()
                        }
                    }

                    // Petit indicateur d'activité pendant la vérif PAM,
                    // à la place de la flèche.
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.context.unlockInProgress
                        text: "…"
                        color: Qt.rgba(1, 1, 1, 0.6)
                        font.pixelSize: 13
                        renderType: Text.NativeRendering
                    }
                }

                // Zone cliquable invisible : révèle la pilule et donne
                // le focus au champ quand on clique n'importe où sur la
                // zone (utile surtout avant toute interaction, quand la
                // pilule n'est pas encore visible et donc pas cliquable
                // directement).
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -10
                    z: -1
                    onClicked: {
                        passField.passHasInteracted = true
                        passInput.forceActiveFocus()
                    }
                }

                // Wiggle façon macOS quand le mot de passe est refusé.
                // Désactivé si reduceMotion est actif (le changement de
                // couleur/texte du sous-titre reste le seul retour visuel).
                SequentialAnimation {
                    id: wiggleAnim
                    loops: 1
                    running: false

                    PropertyAction { target: passField; property: "x"; value: 0 }
                    NumberAnimation { target: passField; property: "x"; to: root.reduceMotion ? 0 : -8; duration: 60; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: passField; property: "x"; to: root.reduceMotion ? 0 : 8; duration: 60; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: passField; property: "x"; to: root.reduceMotion ? 0 : -5; duration: 60; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: passField; property: "x"; to: root.reduceMotion ? 0 : 5; duration: 60; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: passField; property: "x"; to: 0; duration: 60; easing.type: Easing.InOutQuad }
                }
            }

            // --- Sous-titre permanent, sous la pilule --------------------
            // Toujours visible (contrairement à l'ancienne version où ce
            // texte remplaçait le placeholder du champ) : c'est un
            // troisième bloc distinct dans la Column, comme sur la
            // référence macOS. Reflète aussi le fingerprint / les échecs /
            // les messages PAM (pam_faillock, etc.).
            Text {
                id: subtitleLabel
                anchors.horizontalCenter: parent.horizontalCenter
                width: passField.width + 16
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                text: root.context.lockMessage.length > 0
                    ? root.context.lockMessage
                    : (root.context.showFailure
                        ? qsTr("Wrong Password")
                        : (root.context.fprintActive
                            ? qsTr("Scanning fingerprint…")
                            : qsTr("Touch ID or Enter Password")))
                color: root.context.showFailure || root.context.lockMessage.length > 0
                    ? "#ffb4ab"
                    : Qt.rgba(1, 1, 1, 0.65)
                font.family: "SF Pro Display"
                font.weight: Font.DemiBold
                font.pixelSize: 11
                renderType: Text.NativeRendering
            }
        }
    }
}