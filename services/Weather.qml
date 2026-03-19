pragma Singleton

import QtQuick
import Quickshell
import qs.Config as Config

Singleton {
    id: root

    property string text: ""
    property bool loading: false
    property int retryCount: 0

    Timer {
        interval: 15 * 60 * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        id: retryTimer
        repeat: false
        running: false
        onTriggered: root.refresh()
    }

    function refresh() {
        if (loading) return;
        loading = true;

        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    text = parseWeather(xhr.responseText.trim());
                    retryCount = 0;
                    retryTimer.stop();
                } else {
                    console.error("Weather fetch failed:", xhr.status, "— retry", retryCount + 1);
                    var delay = Math.min(15000 * Math.pow(2, retryCount), 5 * 60 * 1000);
                    retryCount++;
                    retryTimer.interval = delay;
                    retryTimer.restart();
                }
                loading = false;
            }
        };
        xhr.open("GET", "https://wttr.in/" + Config.Settings.weatherLocation + "?format=%c+%C+%t+%S+%s&u");
        xhr.send();
    }

    function parseWeather(raw) {
        var fields = raw.trim().split(/\s+/);
        if (fields.length < 3) return raw;

        var sunrise = fields[fields.length - 2];
        var sunset  = fields[fields.length - 1];

        var now = new Date();
        var sunriseTime = parseTime(sunrise);
        var sunsetTime  = parseTime(sunset);

        if (sunriseTime && sunsetTime && (now < sunriseTime || now > sunsetTime))
            fields[0] = toNightEmoji(fields[0]);

        return fields.slice(0, -2).join(" ").replace(/\+/g, "");
    }

    // Returns a Date with today's date and the parsed HH:MM[:SS] time, or null if
    // the string doesn't look like a time (guards against malformed API responses).
    function parseTime(timeStr) {
        if (!timeStr || !/^\d{1,2}:\d{2}/.test(timeStr)) return null;
        var parts = timeStr.split(":");
        var d = new Date();
        d.setHours(parseInt(parts[0]), parseInt(parts[1]), parseInt(parts[2] || 0), 0);
        return d;
    }

    // wttr.in always returns daytime condition emojis regardless of time of day.
    // This maps the ones that look wrong at night to more appropriate alternatives.
    // Keys cover both variation-selector and bare forms since wttr.in is inconsistent.
    function toNightEmoji(emoji) {
        var map = {
            // Clear / mostly clear → moon
            "☀️": "🌙", "☀":  "🌙",
            "🌤️": "🌙", "🌤": "🌙",
            "⛅️": "🌙", "⛅": "☁️",
            // Mostly cloudy → plain cloud (no sun to remove)
            "🌥️": "☁️", "🌥": "☁️",
            // Sun + rain → rain (remove the sun)
            "🌦️": "🌧", "🌦": "🌧",
            // Rainbow → moon (rainbows don't happen at night)
            "🌈": "🌙"
        };
        return map[emoji] !== undefined ? map[emoji] : emoji;
    }
}
