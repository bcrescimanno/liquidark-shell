import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Config as Config
import qs.services

WrapperMouseArea {
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    readonly property int updateCount: Updates.updateData.length
    readonly property bool hasUpdates: updateCount > 0

    Rectangle {
        id: buttonBg
        implicitWidth: archIcon.implicitWidth + 64
        implicitHeight: archIcon.implicitHeight
        radius: Config.Style.radius.normal
        color: hasUpdates ? Qt.rgba(Config.Style.colors.info.r, Config.Style.colors.info.g, Config.Style.colors.info.b, 0.15) : Config.Style.colors.surface

        Behavior on color {
            ColorAnimation {
                duration: Config.Style.animationDuration.normal
            }
        }

        Text {
            id: archIcon
            anchors.centerIn: parent
            text: "\u{f08c7}"
            color: hasUpdates ? Config.Style.colors.info : Config.Style.colors.fg
            opacity: hasUpdates ? 1 : 0.7
            font.pixelSize: Config.Style.fontSize.larger
            font.family: Config.Style.fontFamily.nerd

            Behavior on color {
                ColorAnimation {
                    duration: Config.Style.animationDuration.normal
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: Config.Style.animationDuration.normal
                    easing.type: Easing.OutCubic
                }
            }
        }

        // Notification badge
        Rectangle {
            visible: hasUpdates
            anchors.bottom: archIcon.bottom
            anchors.right: archIcon.right
            anchors.rightMargin: -15
            width: Math.max(badgeText.implicitWidth + 8, 18)
            height: 18
            radius: Config.Style.radius.normal
            color: Updates.checking ? Config.Style.colors.overlay : Config.Style.colors.info
            opacity: 0.7

            Behavior on color {
                ColorAnimation {
                    duration: Config.Style.animationDuration.normal
                }
            }

            Text {
                id: badgeText
                anchors.centerIn: parent
                text: Updates.checking ? "…" : (updateCount > 99 ? "99+" : updateCount.toString())
                color: Config.Style.colors.bg
                font {
                    pixelSize: Config.Style.fontSize.smaller
                    family: Config.Style.fontFamily.sans
                    bold: true
                }
            }
        }
    }
}
