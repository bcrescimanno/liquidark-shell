import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Config as Config
import qs.services

WrapperMouseArea {
    id: indicator
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    visible: Music.hasPlayer

    Row {
        id: row
        spacing: 6

        // Mini spectrum analyzer — bars driven by CAVA audio frequency data
        Row {
            id: spectrum
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter

            readonly property int barWidth: 3
            readonly property int maxBarHeight: 16
            readonly property int minBarHeight: 3
            readonly property var barColors: [
                Config.Style.colors.cyan,
                Config.Style.colors.purple,
                Config.Style.colors.pink,
                Config.Style.colors.green,
                Config.Style.colors.orange
            ]

            Repeater {
                model: 5
                delegate: Item {
                    width: spectrum.barWidth
                    height: spectrum.maxBarHeight
                    anchors.verticalCenter: parent.verticalCenter

                    property real barHeight: {
                        let v = Music.spectrumBars[index] ?? 0;
                        return spectrum.minBarHeight + v * (spectrum.maxBarHeight - spectrum.minBarHeight);
                    }

                    Behavior on barHeight {
                        NumberAnimation {
                            duration: 30
                            easing.type: Easing.Linear
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: parent.barHeight
                        radius: 1
                        color: spectrum.barColors[index]
                        anchors.bottom: parent.bottom
                    }
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                let artist = Music.trackArtist || "Unknown Artist";
                let title = Music.trackTitle || "No Track";
                return artist + " — " + title;
            }
            color: Config.Style.colors.fg
            font {
                family: Config.Style.fontFamily.sans
                pixelSize: Config.Style.fontSize.normal
            }
            elide: Text.ElideRight
            width: Math.min(implicitWidth, 300)
        }
    }
}
