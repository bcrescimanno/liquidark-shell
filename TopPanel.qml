import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.Config as Config

PanelWindow {
    anchors {
        top: true
        left: true
        right: true
    }

    color: "transparent"

    default property alias left: leftPane.data
    property alias right: rightPane.data
    property alias center: centerPane.data
    property alias backgroundColor: background.color

    Rectangle {
        id: background
        anchors.fill: parent
        radius: Config.Style.radius.normal
        opacity: 0
        transform: Translate { id: barSlide; y: -20 }

        Component.onCompleted: barEnter.start()

        ParallelAnimation {
            id: barEnter
            NumberAnimation {
                target: background; property: "opacity"
                from: 0; to: 1
                duration: Config.Style.animationDuration.slower
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Config.Style.animationCurves.emphasizedDecel
            }
            NumberAnimation {
                target: barSlide; property: "y"
                from: -20; to: 0
                duration: Config.Style.animationDuration.slower
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Config.Style.animationCurves.expressiveDefaultSpatial
            }
        }

        RowLayout {
            id: leftPane
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 20
        }

        RowLayout {
            id: centerPane
            anchors.centerIn: parent
            anchors.verticalCenter: parent.verticalCenter
            spacing: 20
        }

        RowLayout {
            id: rightPane
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 20
        }
    }
}
