import QtQuick
import QtQml
import Quickshell
import Quickshell.Widgets
import QtQuick.Layouts
import qs.Config as Config
import qs.services

WrapperMouseArea {
    RowLayout {
        Text {
            text: "\u{f08c7}"
            color: Config.Style.colors.fg
            opacity: Updates.updateData.length > 0 ? 1 : 0.5
            font.pixelSize: Config.Style.fontSize.larger
            font.family: Config.Style.fontFamily.nerd

            Behavior on opacity {
                NumberAnimation {
                    duration: Config.Style.animationDuration.fast
                    easing.type: Easing.OutCubic
                }
            }
        }

        Text {
            color: Config.Style.colors.fg
            font.pixelSize: Config.Style.fontSize.normal
            font.family: Config.Style.fontFamily.nerd
            opacity: Updates.updateData.length > 0 ? 1 : 0.5
            text: Updates.checking ? "…" : (Updates.updateData.length > 0 ? Updates.updateData.length : "")

            Behavior on opacity {
                NumberAnimation {
                    duration: Config.Style.animationDuration.fast
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    hoverEnabled: true
}
