import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Config as Config
import qs.services

WrapperMouseArea {
    id: weatherWidget
    hoverEnabled: true

    implicitWidth: children[0].implicitWidth
    implicitHeight: children[0].implicitHeight

    Text {
        text: Weather.loading ? "..." : (Weather.text || "—")
        color: Config.Style.colors.fg
        font.family: Config.Style.fontFamily.sans
        font.pixelSize: Config.Style.fontSize.normal
    }

    onClicked: Weather.refresh()

    cursorShape: Qt.CursorShape.PointingHandCursor
}
