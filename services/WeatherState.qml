pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    reloadableId: "weatherState"

    property bool available: false
    property string city: ""
    property string loc: ""

    property real tempC: 0
    property real feelsLikeC: 0
    property string description: ""
    property int weatherCode: 0
    property int humidity: 0
    property real windSpeed: 0
    property string sunrise: ""
    property string sunset: ""

    property bool isDay: true
    property var forecast: []
    property var hourly: []

    readonly property string iconFile: root._iconFor(root.weatherCode)

    readonly property string kind: root._kindFor(root.weatherCode, root.isDay)

    function _kindFor(code, day) {
        if (code === 0 || code === 1) return day ? "sun" : "moon"
        if (code === 2) return day ? "partly" : "partlyNight"
        if (code === 45 || code === 48) return "fog"
        if (code >= 51 && code <= 67) return "rain"
        if (code >= 80 && code <= 82) return "rain"
        if ((code >= 71 && code <= 77) || code === 85 || code === 86) return "snow"
        if (code === 95 || code === 96 || code === 99) return "storm"
        return "cloud"
    }

    function _iconFor(code) {
        if (code === 0 || code === 1) return "weather/sun.svg"
        if (code === 2) return "weather/cloud-sun.svg"
        if (code === 3 || code === 45 || code === 48) return "weather/clouds.svg"
        if (code === 51 || code === 53 || code === 55 || code === 56 || code === 57) return "notch/cloud-drizzle.svg"
        if (code >= 61 && code <= 67) return "weather/cloud-rain.svg"
        if (code === 80 || code === 81 || code === 82) return "weather/cloud-rain.svg"
        if ((code >= 71 && code <= 77) || code === 85 || code === 86) return "weather/cloud-snow.svg"
        if (code === 95 || code === 96 || code === 99) return "notch/cloud-lightning.svg"
        return "weather/clouds.svg"
    }

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
                root._fetchWeather()
            })
        }
    }

    function _fetchWeather() {
        if (!root.loc) return
        var parts = root.loc.split(",")
        var lat = parts[0], lon = parts[1]
        var url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon
                 + "&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,is_day"
                 + "&hourly=temperature_2m,weather_code,is_day"
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
            root.isDay       = json.current.is_day !== 0

            if (json.hourly && json.hourly.time) {
                var hrs = []
                var cur = String(json.current.time || "").substring(0, 13)
                var start = 0
                for (var h = 0; h < json.hourly.time.length; h++) {
                    if (json.hourly.time[h].substring(0, 13) === cur) { start = h; break }
                }
                for (var j = start; j < json.hourly.time.length && hrs.length < 6; j++) {
                    hrs.push({
                        time:  json.hourly.time[j],
                        temp:  Math.round(json.hourly.temperature_2m[j]),
                        code:  json.hourly.weather_code[j],
                        isDay: json.hourly.is_day[j] !== 0
                    })
                }
                root.hourly = hrs
            }
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
        interval: 3600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.reload()
    }

    Timer {
        interval: 30000
        running: !root.available
        repeat: true
        onTriggered: root.reload()
    }
}
