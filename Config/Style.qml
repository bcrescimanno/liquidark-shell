pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var colors: Theme.colors
    property Radius radius: Radius {}
    property FontFamily fontFamily: FontFamily {}
    property FontSize fontSize: FontSize {}
    property AnimationDuration animationDuration: AnimationDuration {}

    component Radius: QtObject {
        property int normal: 8
    }

    component FontFamily: QtObject {
        property string mono: "JetBrains Mono Nerd Font"
        property string sans: "Inter Variable"
        property string icon: "Material Symbols Outlined"
        property string nerd: "JetBrains Mono Nerd Font"
    }

    component FontSize: QtObject {
        property int smaller: 11
        property int small: 13
        property int normal: 16
        property int large: 18
        property int larger: 24
    }

    component AnimationDuration: QtObject {
        property int fast: 120
        property int normal: 240
        property int slow: 360
        property int slower: 480
    }
}
