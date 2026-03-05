import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.services
import qs.Config as Config
import qs.Modules as Modules

WrapperMouseArea {
    id: clockWidget

    hoverEnabled: true
    implicitWidth: clockText.implicitWidth
    implicitHeight: clockText.implicitHeight

    Text {
        id: clockText
        text: Time.format("h:mm ap")
        color: Config.Style.colors.fg
        font.family: Config.Style.fontFamily.mono
        font.pixelSize: Config.Style.fontSize.normal
    }
    Modules.Tooltip {
        id: dateTip
        anchorTo: clockWidget
        Text {
            text: Time.format("dddd MMMM d, yyyy")
            color: Config.Style.colors.fg
            font.family: Config.Style.fontFamily.mono
        }
    }

    onEntered: dateTip.open = true
    onExited: dateTip.open = false
}
