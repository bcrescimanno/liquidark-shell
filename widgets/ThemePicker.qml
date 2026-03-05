import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.Config as Config
import qs.Modules as Modules

WrapperMouseArea {
    id: root

    implicitWidth: paletteIcon.implicitWidth
    implicitHeight: paletteIcon.implicitHeight

    cursorShape: Qt.PointingHandCursor

    Text {
        id: paletteIcon
        text: "\ue40a"
        color: Config.Style.colors.accent
        font {
            family: Config.Style.fontFamily.icon
            pixelSize: Config.Style.fontSize.larger
        }
    }

    onClicked: popup.open = !popup.open

    Modules.AnimatedPopupWindow {
        id: popup

        anchor.item: root
        anchor.rect.y: root.implicitHeight - Config.Style.radius.normal

        topMargin: 8
        rightMargin: 12
        bottomMargin: 8
        leftMargin: 12

        ColumnLayout {
            spacing: 2

            Repeater {
                model: Config.Theme.all

                delegate: Item {
                    id: themeRow
                    readonly property var themeData: modelData

                    implicitWidth: rowContent.implicitWidth
                    implicitHeight: rowContent.implicitHeight + 8

                    RowLayout {
                        id: rowContent
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Row {
                            spacing: 3
                            Repeater {
                                model: [themeRow.themeData.accent, themeRow.themeData.positive, themeRow.themeData.info]
                                delegate: Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: modelData
                                }
                            }
                        }

                        Text {
                            text: themeRow.themeData.displayName
                            color: Config.Style.colors.fg
                            font {
                                pixelSize: Config.Style.fontSize.small
                                family: Config.Style.fontFamily.sans
                            }
                        }

                        Text {
                            visible: Config.Theme.colors === themeRow.themeData
                            text: "\ue5ca"
                            color: Config.Style.colors.accent
                            font {
                                family: Config.Style.fontFamily.icon
                                pixelSize: Config.Style.fontSize.small
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Config.Theme.setTheme(themeRow.themeData.id)
                            popup.open = false
                        }
                    }
                }
            }
        }
    }
}
