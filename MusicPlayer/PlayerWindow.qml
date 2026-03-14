import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Config as Config
import qs.Modules as Modules
import qs.services

Modules.AnimatedPopupWindow {
    id: root

    readonly property int popupWidth: 280

    topMargin: 12
    rightMargin: 16
    bottomMargin: 16
    leftMargin: 16

    ColumnLayout {
        spacing: 12
        Layout.alignment: Qt.AlignHCenter

        // Album art
        Rectangle {
            Layout.preferredWidth: root.popupWidth
            Layout.preferredHeight: root.popupWidth
            radius: Config.Style.radius.normal
            color: Config.Style.colors.surface
            clip: true

            Image {
                id: albumArt
                anchors.fill: parent
                source: Music.trackArtUrl
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }

            // Placeholder when no art
            Text {
                anchors.centerIn: parent
                visible: !albumArt.visible
                text: "\ue405"
                color: Config.Style.colors.overlay
                font {
                    family: Config.Style.fontFamily.icon
                    pixelSize: 64
                }
            }
        }

        // Track metadata
        ColumnLayout {
            spacing: 2
            Layout.preferredWidth: root.popupWidth

            Text {
                text: Music.trackTitle || "No Track"
                color: Config.Style.colors.fg
                font {
                    family: Config.Style.fontFamily.sans
                    pixelSize: Config.Style.fontSize.large
                    bold: true
                }
                elide: Text.ElideRight
                Layout.maximumWidth: root.popupWidth
            }

            Text {
                text: Music.trackArtist || "Unknown Artist"
                color: Config.Style.colors.fg
                font {
                    family: Config.Style.fontFamily.sans
                    pixelSize: Config.Style.fontSize.normal
                }
                elide: Text.ElideRight
                Layout.maximumWidth: root.popupWidth
            }

            Text {
                visible: Music.trackAlbum !== ""
                text: {
                    let parts = Music.trackAlbum;
                    if (Music.trackYear)
                        parts += " · " + Music.trackYear;
                    return parts;
                }
                color: Config.Style.colors.overlay
                font {
                    family: Config.Style.fontFamily.sans
                    pixelSize: Config.Style.fontSize.small
                }
                elide: Text.ElideRight
                Layout.maximumWidth: root.popupWidth
            }
        }

        // Scrubber
        ColumnLayout {
            spacing: 4
            Layout.preferredWidth: root.popupWidth

            // Track bar
            Item {
                Layout.preferredWidth: root.popupWidth
                Layout.preferredHeight: 16

                property bool dragging: false
                property real dragFraction: 0

                Rectangle {
                    id: trackBg
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 4
                    radius: 2
                    color: Config.Style.colors.surface

                    Rectangle {
                        id: trackFill
                        height: parent.height
                        radius: parent.radius
                        color: Config.Style.colors.accent
                        width: {
                            let fraction = parent.parent.dragging ? parent.parent.dragFraction : (Music.duration > 0 ? Music.position / Music.duration : 0);
                            return Math.max(0, Math.min(1, fraction)) * parent.width;
                        }
                    }

                    // Knob
                    Rectangle {
                        visible: Music.canSeek
                        width: 12
                        height: 12
                        radius: 6
                        color: Config.Style.colors.accent
                        x: trackFill.width - width / 2
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: Music.canSeek
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                    onPressed: mouse => {
                        parent.dragging = true;
                        parent.dragFraction = Math.max(0, Math.min(1, mouse.x / width));
                    }

                    onPositionChanged: mouse => {
                        if (parent.dragging)
                            parent.dragFraction = Math.max(0, Math.min(1, mouse.x / width));
                    }

                    onReleased: {
                        if (parent.dragging) {
                            Music.seekTo(parent.dragFraction * Music.duration);
                            parent.dragging = false;
                        }
                    }
                }
            }

            // Time labels
            RowLayout {
                Layout.preferredWidth: root.popupWidth

                Text {
                    text: formatTime(Music.position)
                    color: Config.Style.colors.overlay
                    font {
                        family: Config.Style.fontFamily.mono
                        pixelSize: Config.Style.fontSize.smaller
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: formatTime(Music.duration, "--:--")
                    color: Config.Style.colors.overlay
                    font {
                        family: Config.Style.fontFamily.mono
                        pixelSize: Config.Style.fontSize.smaller
                    }
                }
            }
        }

        // Transport controls
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 24

            // Previous
            WrapperMouseArea {
                enabled: Music.canPrevious
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: Music.previous()

                Text {
                    text: "\ue045"
                    color: Config.Style.colors.fg
                    opacity: Music.canPrevious ? 1 : 0.3
                    font {
                        family: Config.Style.fontFamily.icon
                        pixelSize: Config.Style.fontSize.larger
                    }
                }
            }

            // Play/Pause
            WrapperMouseArea {
                enabled: Music.isPlaying ? Music.canPause : Music.canPlay
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: Music.togglePlaying()

                Text {
                    text: Music.isPlaying ? "\ue034" : "\ue037"
                    color: Config.Style.colors.fg
                    font {
                        family: Config.Style.fontFamily.icon
                        pixelSize: 32
                    }
                }
            }

            // Next
            WrapperMouseArea {
                enabled: Music.canNext
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: Music.next()

                Text {
                    text: "\ue044"
                    color: Config.Style.colors.fg
                    opacity: Music.canNext ? 1 : 0.3
                    font {
                        family: Config.Style.fontFamily.icon
                        pixelSize: Config.Style.fontSize.larger
                    }
                }
            }
        }

        // Format label
        Text {
            visible: Music.formatLabel !== ""
            text: Music.formatLabel
            color: Config.Style.colors.overlay
            Layout.alignment: Qt.AlignHCenter
            font {
                family: Config.Style.fontFamily.mono
                pixelSize: Config.Style.fontSize.smaller
            }
        }
    }

    function formatTime(seconds, fallback) {
        if (isNaN(seconds) || seconds <= 0)
            return fallback ?? "0:00";
        let totalSec = Math.floor(seconds);
        let m = Math.floor(totalSec / 60);
        let s = totalSec % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }
}
