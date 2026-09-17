import QtQuick.Layouts

/*
    Port de modules/dashboard/Dash.qml (caelestia-dots/shell, GPLv3).
    Grille reelle (6 colonnes x 2 lignes) reconstruite avec des
    RowLayout/ColumnLayout imbriques plutot qu'un GridLayout a spans
    (equivalent visuel, plus simple a lire) :

      ligne 0 : [ Weather (2 col) ][   User (3 col)    ][ Media  ]
      ligne 1 : [DateTime][      Calendar (3 col)     ][Resources][ (suite)]

    Point important corrige par rapport a la version precedente :
    DateTime n'occupe QUE la ligne du bas (meme hauteur que Calendar/
    Resources) dans le vrai code, pas toute la hauteur de la notch —
    seul Media (Layout.rowSpan: 2 chez eux) s'etend sur les deux lignes.
*/
RowLayout {
    id: root
    spacing: 10

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10
            WeatherModule {}
            UserModule {}
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10
            DateTimeModule {}
            CalendarModule {}
            ResourcesModule {}
        }
    }

    MediaModule {}
}
