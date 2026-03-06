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

    property AnimationCurves animationCurves: AnimationCurves {}

    // Material Design 3 easing curves (as used by Caelestia shell)
    component AnimationCurves: QtObject {
        // Spring-like overshoot — main Caelestia signature; use for open/enter
        readonly property list<real> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
        // Faster spring — for smaller/quicker elements
        readonly property list<real> expressiveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
        // Decelerates into place — secondary enter curve
        readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        // Accelerates away — use for close/exit
        readonly property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        // Smooth standard curve
        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
    }
}
