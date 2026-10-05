import QtQuick
import QtQuick.Layouts

/*
    Refonte complete demandee par l'utilisateur (resultat juge decevant
    de la version precedente, inspiree de caelestia-dots/shell) : cette
    fois calquee sur l'app macOS "Nook" (captures fournies). Changement
    fondamental de philosophie : plus de GridLayout a 6 colonnes avec
    des cartes individuelles (fond + coins arrondis) par module — juste
    un fond continu (celui du dashboard/de la notch) avec de simples
    traits verticaux semi-transparents pour separer les sections,
    comme sur les captures de reference.

    Trois sections, de gauche a droite :
    - MediaModule (pochette + titre/album/artiste + controles)
    - CalendarModule (bande de jours centree sur aujourd'hui + agenda)
    - ProfilePhotoModule (photo de profil circulaire, seule a
      l'extremite droite comme sur "Nook" — pas de badges/texte autour,
      contrairement a l'ancien UserModule retire)

    Modules retires de cette page (plus dans les captures de reference,
    demande explicite "on retire les widgets actuels") : WeatherModule,
    ActiveAppModule, UserModule (version avec badges), ResourcesModule,
    StatusChipsRow (deja inutilise avant ce changement) — fichiers
    supprimes du depot, plus rien ne les utilise. Verifie explicitement
    que WeatherModule n'etait PAS repris par l'onglet Weather
    (WeatherPage.qml a sa propre logique independante) avant de le
    supprimer, pour ne pas casser cet onglet par erreur.
*/
Item {
    id: root

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        MediaModule {}

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            color: "#262626"
        }

        CalendarModule {}

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            color: "#262626"
        }

        ProfilePhotoModule {}
    }
}
