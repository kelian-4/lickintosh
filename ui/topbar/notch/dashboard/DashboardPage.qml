import QtQuick.Layouts

/*
    Port fidele de modules/dashboard/Dash.qml (caelestia-dots/shell,
    GPLv3), relu integralement (pas depuis la memoire) : un vrai
    GridLayout a 6 colonnes x 2 lignes, PAS des RowLayout/ColumnLayout
    imbriques comme la version precedente (qui approximait la
    disposition mais ne partageait pas la largeur des colonnes entre
    la ligne du haut et celle du bas -> agrandir la notch faisait
    grossir UserModule de facon disproportionnee au lieu de profiter a
    Calendar/Resources, et laissait un enorme espace vide inutilise).

    Repartition EXACTE du fichier reel (Layout.row/column/columnSpan/
    rowSpan) :
      col:      0        1        2   3   4        5
      row 0:  [--- Weather ---][----- User -----][ Media  ]
      row 1:  [DateTime][------ Calendar ------][Resources][ (suite) ]

    Point crucial verifie sur le fichier source (source de plusieurs
    erreurs precedentes) : SEUL Calendar a Layout.fillWidth. Tous les
    autres (Weather, User, DateTime, Resources, Media) ont une largeur
    FIXE (Layout.preferredWidth), pas fillWidth -> c'est ce qui evite
    l'espace vide disproportionne et donne a Calendar tout l'espace
    horizontal restant. Layout.fillHeight : User/DateTime/Resources/
    Media l'ont, Weather et Calendar ne l'ont PAS (hauteur basee sur
    leur propre contenu, via Layout.preferredHeight ici plutot que
    l'implicitHeight de leur contenu interne comme chez eux, plus
    previsible sans environnement de rendu pour verifier).

    Valeurs de largeur/hauteur mises a l'echelle (x0.6, meme facteur
    qu'UserModule) depuis les vraies valeurs Tokens.sizes.dashboard :
    userWidth 340->205, weatherWidth 275->165. DateTime/Resources/Media
    et les hauteurs de Weather/Calendar n'ont pas d'equivalent Tokens
    direct (bases sur l'implicitHeight de leur contenu chez eux) ->
    valeurs raisonnables choisies pour la taille de notch actuelle.
*/
GridLayout {
    id: root
    rowSpacing: 10
    columnSpacing: 10

    WeatherModule {
        Layout.row: 0
        Layout.columnSpan: 2
        Layout.preferredWidth: 165
        Layout.preferredHeight: 90
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

    DateTimeModule {
        Layout.row: 1
        Layout.preferredWidth: 70
        Layout.fillHeight: true
    }

    CalendarModule {
        Layout.row: 1
        Layout.column: 1
        Layout.columnSpan: 3
        Layout.fillWidth: true
        Layout.preferredHeight: 190
    }

    ResourcesModule {
        Layout.row: 1
        Layout.column: 4
        Layout.preferredWidth: 60
        Layout.fillHeight: true
    }
}
