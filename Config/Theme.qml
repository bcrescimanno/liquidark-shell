pragma Singleton

import QtQuick
import QtCore
import Quickshell

Singleton {
    id: root

    property int _activeIndex: 0

    ThemeDracula { id: _dracula }
    ThemeCatppuccinMocha { id: _catppuccinMocha }

    readonly property var all: [_dracula, _catppuccinMocha]
    readonly property var colors: all[_activeIndex]

    Settings {
        id: settings
        location: StandardPaths.writableLocation(StandardPaths.GenericConfigLocation) + "/liquidark-shell/settings.ini"
        property string themeName: "dracula"
    }

    Component.onCompleted: {
        let idx = root.all.findIndex(t => t.id === settings.themeName)
        if (idx >= 0) root._activeIndex = idx
    }

    function setTheme(id) {
        let idx = root.all.findIndex(t => t.id === id)
        if (idx >= 0) {
            root._activeIndex = idx
            settings.themeName = id
        }
    }
}
