pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

/*
    Météo — approche reprise de caelestia-dots/shell (services/Weather.qml,
    GPLv3) : géolocalisation IP via ip-api.com, données météo via
    Open-Meteo (api.open-meteo.com), aucune clé API. Réimplémenté ici
    avec XMLHttpRequest (JS natif Qt Quick) au lieu de leur wrapper
    interne "Requests" (dépend de leur plugin C++ Caelestia.Config).
    Étendu avec les prévisions 7 jours + lever/coucher du soleil pour
    la page Weather complète (cf. WeatherTab.qml de caelestia).
*/
Singleton {
    id: root

    reloadableId: "weatherState"

    property bool available: false
    property string city: ""
    property string loc: ""       // "lat,lon"

    property real tempC: 0
    property real feelsLikeC: 0
    property string description: ""
    property int weatherCode: 0
    property int humidity: 0
    property real windSpeed: 0
    property string sunrise: ""
    property string sunset: ""

    property var forecast: []     // [{ date, weekday, code, tempMax, tempMin }]

    function _get(url, onDone) {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                onDone(xhr.responseText)
            }
        }
        xhr.open("GET", url)
        xhr.send()
    }

    function reload() {
        if (root.loc) {
            _fetchWeather()
        } else {
            _get("http://ip-api.com/json?fields=status,message,city,lat,lon", function(text) {
                var res
                try { res = JSON.parse(text) } catch (e) { return }
                if (res.status !== "success") return
                root.city = res.city || ""
                root.loc  = res.lat + "," + res.lon
            })
        }
    }

    function _fetchWeather() {
        if (!root.loc) return
        var parts = root.loc.split(",")
        var lat = parts[0], lon = parts[1]
        var url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon
                 + "&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m"
                 + "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset"
                 + "&timezone=auto&forecast_days=7"

        _get(url, function(text) {
            var json
            try { json = JSON.parse(text) } catch (e) { return }
            if (!json.current) return

            root.tempC       = json.current.temperature_2m
            root.feelsLikeC  = json.current.apparent_temperature
            root.humidity    = json.current.relative_humidity_2m
            root.windSpeed   = json.current.wind_speed_10m
            root.weatherCode = json.current.weather_code
            root.description = root._conditionFor(json.current.weather_code)
            root.available   = true

            if (json.daily && json.daily.time) {
                var days = []
                for (var i = 0; i < json.daily.time.length; i++) {
                    days.push({
                        date:     json.daily.time[i],
                        code:     json.daily.weather_code[i],
                        tempMax:  Math.round(json.daily.temperature_2m_max[i]),
                        tempMin:  Math.round(json.daily.temperature_2m_min[i])
                    })
                }
                root.forecast = days
                if (json.daily.sunrise && json.daily.sunrise[0]) root.sunrise = json.daily.sunrise[0].split("T")[1]
                if (json.daily.sunset  && json.daily.sunset[0])  root.sunset  = json.daily.sunset[0].split("T")[1]
            }
        })
    }

    // Table de correspondance WMO weather_code -> description, reprise
    // de caelestia (services/Weather.qml, getWeatherCondition()).
    function _conditionFor(code) {
        const conditions = {
            0: "Ciel dégagé", 1: "Ciel dégagé", 2: "Partiellement nuageux", 3: "Couvert",
            45: "Brouillard", 48: "Brouillard givrant",
            51: "Bruine légère", 53: "Bruine", 55: "Bruine forte",
            56: "Bruine verglaçante", 57: "Bruine verglaçante",
            61: "Pluie légère", 63: "Pluie", 65: "Pluie forte",
            66: "Pluie verglaçante", 67: "Pluie verglaçante forte",
            71: "Neige légère", 73: "Neige", 75: "Neige forte", 77: "Neige en grains",
            80: "Averses légères", 81: "Averses", 82: "Averses fortes",
            85: "Averses de neige légères", 86: "Averses de neige fortes",
            95: "Orage", 96: "Orage avec grêle", 99: "Orage avec grêle forte"
        }
        return conditions[code] || "Inconnu"
    }

    Timer {
        interval: 3600000 // 1h, comme caelestia
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.reload()
    }
}
