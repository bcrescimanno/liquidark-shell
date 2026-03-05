import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Config as Config

PopupWindow {
    id: root
    visible: false
    color: "transparent"

    implicitWidth: body.implicitWidth + body.border.width * 2
    implicitHeight: body.implicitHeight === 0 ? 1 : body.implicitHeight + body.border.width * 2

    property bool open: false
    property bool opened: false
    property int delay: 0
    property int speed: Config.Style.animationDuration.normal

    default property alias content: body.data

    property alias topMargin: body.topMargin
    property alias bottomMargin: body.bottomMargin
    property alias leftMargin: body.leftMargin
    property alias rightMargin: body.rightMargin
    property alias border: body.border

    onOpenChanged: showTimer.running = true

    onOpenedChanged: {
        if (opened) {
            if (!closeAnim.running) {
                body.y = -body.height;
                body.opacity = 0;
            }
            closeAnim.stop();
            visible = true;
            body.focus = true;
            openAnim.start();
        } else {
            openAnim.stop();
            closeAnim.start();
        }
    }

    Timer {
        id: showTimer
        interval: delay
        repeat: false
        running: false
        onTriggered: opened = open
    }

    ClippingWrapperRectangle {
        id: body
        color: Config.Style.colors.panelBg
        y: 0
        opacity: 0
        radius: Config.Style.radius.normal
        topLeftRadius: 0
        topRightRadius: 0

        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape && root.opened) {
                root.open = false;
            }
        }
    }

    ParallelAnimation {
        id: openAnim
        NumberAnimation {
            target: body
            property: "y"
            to: 0
            duration: root.speed
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: body
            property: "opacity"
            to: 1
            duration: root.speed
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: closeAnim
        NumberAnimation {
            target: body
            property: "y"
            to: -body.height
            duration: root.speed
            easing.type: Easing.InCubic
        }
        NumberAnimation {
            target: body
            property: "opacity"
            to: 0
            duration: root.speed
            easing.type: Easing.InCubic
        }
        onFinished: root.visible = false
    }
}
