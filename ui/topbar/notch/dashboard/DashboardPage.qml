import QtQuick.Layouts

/*
    Port fidele de modules/dashboard/Dash.qml (caelestia-dots/shell,
    GPLv3) a l'origine, largement adapte depuis suite aux retours
    explicites de l'utilisateur (voir ci-dessous) : la disposition en
    GridLayout 6 colonnes x 2 lignes est conservee (c'est ce qui a
    resolu le probleme d'espace disproportionne — cf. historique git),
    mais son contenu a change :

      col:      0              1   2   3   4        5
      row 0:  [--- ActiveApp ---][----- User -----][ Media  ]
      row 1:  [--------- Calendar ---------][Resources][ (suite) ]

    Changements demandes explicitement :
    - DateTimeModule RETIRE (plus dans la grille, fichier supprime du
      depot — plus aucune reference nulle part). Calendar recupere cette
      colonne (columnSpan 3 -> 4, column 1 -> 0) au lieu de laisser un
      trou.
    - WeatherModule REMPLACE par ActiveAppModule ("le mode actuellement
      actif" = l'application/fenetre active, comme le montre deja
      ui/topbar/menubar/activewindows/ActiveWindow.qml dans la topbar).
      WeatherModule.qml n'est pas supprime (toujours utilise par l'onglet
      Weather separement, WeatherPage.qml), seulement retire d'ici.

    Point crucial toujours valable (verifie sur le fichier source reel,
    a l'origine de plusieurs erreurs precedentes) : SEUL Calendar a
    Layout.fillWidth parmi les modules de la grille. anchors.fill: parent
    sur la racine reste necessaire (un GridLayout charge par un Loader ne
    se redimensionne pas tout seul, contrairement a un Item simple).
    rowSpacing/columnSpacing a 0 : espaces noirs entre cartes non voulus.
*/
GridLayout {
    id: root
    anchors.fill: parent
    rowSpacing: 0
    columnSpacing: 0

    ActiveAppModule {
        Layout.row: 0
        Layout.columnSpan: 2
        Layout.preferredWidth: 165
        Layout.preferredHeight: 90
        Layout.fillHeight: true
    }

    UserModule {
        Layout.column: 2
        Layout.columnSpan: 3
        Layout.preferredWidth: 205
        Layout.fillHeight: true
    }

    MediaModule {
        Layout.row: 0
        Layout.column: 5
        Layout.rowSpan: 2
        Layout.preferredWidth: 150
        Layout.fillHeight: true
    }

    CalendarModule {
        Layout.row: 1
        Layout.column: 0
        Layout.columnSpan: 4
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: 230
    }

    ResourcesModule {
        Layout.row: 1
        Layout.column: 4
        Layout.preferredWidth: 60
        Layout.fillHeight: true
    }
}
