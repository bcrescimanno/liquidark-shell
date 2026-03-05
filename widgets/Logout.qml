import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import qs.Config as Config

WrapperMouseArea {
    cursorShape: Qt.PointingHandCursor

    Text {
        color: Config.Style.colors.fg
        font {
            family: Config.Style.fontFamily.icon
            pixelSize: Config.Style.fontSize.large
        }
        text: "\ue9ba"
    }

    Process {
        id: wleave
        command: ['uwsm', 'app', '--', 'wleave']
        running: false
    }

    onClicked: wleave.running = true
}
