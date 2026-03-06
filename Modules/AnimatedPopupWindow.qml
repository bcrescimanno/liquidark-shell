import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Config as Config

PopupWindow {
    id: root
    visible: false
    color: "transparent"

    // Window height tracks revealHeight, which uses the spring curve and can
    // overshoot. The body clip is capped at targetHeight so content never
    // stretches — only the background fills the overshoot space.
    implicitWidth: body.implicitWidth + body.border.width * 2
    implicitHeight: revealHeight <= 0 ? 1 : revealHeight + body.border.width * 2

    property bool open: false
    property bool opened: false
    property int delay: 0
    property int speed: Config.Style.animationDuration.slow
    property int closeSpeed: Config.Style.animationDuration.normal

    property real revealHeight: 0
    property real targetHeight: 0

    default property alias content: body.data

    property alias topMargin: body.topMargin
    property alias bottomMargin: body.bottomMargin
    property alias leftMargin: body.leftMargin
    property alias rightMargin: body.rightMargin
    property alias border: body.border

    onOpenChanged: showTimer.running = true

    onOpenedChanged: {
        if (opened) {
            if (!closeAnim.running)
                revealHeight = 0;
            closeAnim.stop();
            visible = true;
            body.focus = true;
            root.targetHeight = body.implicitHeight;
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

    // Fills the full animated window height (including spring overshoot) so
    // the popup background color is visible even beyond the content area.
    Rectangle {
        anchors.fill: parent
        color: Config.Style.colors.panelBg
        radius: Config.Style.radius.normal
        topLeftRadius: 0
        topRightRadius: 0
    }

    ClippingWrapperRectangle {
        id: body
        color: "transparent"

        // Cap at targetHeight: content is progressively revealed as the window
        // opens, but never pushed/stretched by the spring overshoot.
        height: Math.min(root.revealHeight, root.targetHeight)

        radius: Config.Style.radius.normal
        topLeftRadius: 0
        topRightRadius: 0

        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape && root.opened)
                root.open = false;
        }
    }

    // Spring open: window overshoots, background fills the excess, content stays put.
    NumberAnimation {
        id: openAnim
        target: root
        property: "revealHeight"
        from: 0
        to: root.targetHeight
        duration: root.speed
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Config.Style.animationCurves.expressiveDefaultSpatial
    }

    // Snap closed: accelerating so it feels intentional.
    SequentialAnimation {
        id: closeAnim
        NumberAnimation {
            target: root
            property: "revealHeight"
            to: 0
            duration: root.closeSpeed
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Config.Style.animationCurves.emphasizedAccel
        }
        ScriptAction { script: root.visible = false }
    }
}
