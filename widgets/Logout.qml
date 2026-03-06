import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import qs.Config as Config

WrapperMouseArea {
    cursorShape: Qt.PointingHandCursor

    Text {
        color: Config.Style.colors.negative
        font {
            family: Config.Style.fontFamily.icon
            pixelSize: Config.Style.fontSize.large
        }
        text: "\ue8ac"
    }

    Process {
        id: wleave
        command: ['uwsm', 'app', '--', 'wleave']
        running: false
    }

    onClicked: wleave.running = true
}
