pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // Coordinates for weather data (wttr.in format: "lat,lon")
    readonly property string weatherLocation: "37.22141,-121.87575"
}
