import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.Config as Config
import qs.Modules as Modules
import qs.services

Modules.AnimatedPopupWindow {
    id: mainWindow

    topMargin: 12
    rightMargin: 16
    bottomMargin: 12
    leftMargin: 16

    readonly property var repoUpdates: Updates.updateData.filter(u => u.source === "repo")
    readonly property var aurUpdates: Updates.updateData.filter(u => u.source === "aur")

    // Smoothly complete the current rotation when checking finishes.
    Connections {
        target: Updates
        function onCheckingChanged() {
            if (Updates.checking) {
                refreshIcon.rotation = 0;
                spinAnimation.restart();
            } else {
                spinAnimation.stop();
                let current = refreshIcon.rotation % 360;
                let remaining = current > 0 ? (360 - current) / 360 : 0;
                if (remaining > 0.01) {
                    landAnimation.duration = Math.round(remaining * spinAnimation.duration);
                    landAnimation.from = current;
                    landAnimation.to = 360;
                    landAnimation.start();
                } else {
                    refreshIcon.rotation = 0;
                }
            }
        }
    }

    ColumnLayout {
        spacing: 0

        // Repo updates section
        ColumnLayout {
            visible: mainWindow.repoUpdates.length > 0
            spacing: 0

            RowLayout {
                spacing: 6
                Layout.bottomMargin: 6

                Rectangle {
                    width: 3
                    height: 12
                    radius: 2
                    color: Config.Style.colors.accent
                }

                Text {
                    text: "Official (" + mainWindow.repoUpdates.length + ")"
                    color: Config.Style.colors.accent
                    font {
                        pixelSize: Config.Style.fontSize.small
                        family: Config.Style.fontFamily.sans
                    }
                }
            }

            Repeater {
                model: mainWindow.repoUpdates
                delegate: UpdateRow {
                    pkg: modelData
                }
            }
        }

        // Spacer between sections
        Item {
            visible: mainWindow.repoUpdates.length > 0 && mainWindow.aurUpdates.length > 0
            Layout.preferredHeight: 10
        }

        // AUR updates section
        ColumnLayout {
            visible: mainWindow.aurUpdates.length > 0
            spacing: 0

            RowLayout {
                spacing: 6
                Layout.bottomMargin: 6

                Rectangle {
                    width: 3
                    height: 12
                    radius: 2
                    color: Config.Style.colors.info
                }

                Text {
                    text: "AUR (" + mainWindow.aurUpdates.length + ")"
                    color: Config.Style.colors.info
                    font {
                        pixelSize: Config.Style.fontSize.small
                        family: Config.Style.fontFamily.sans
                    }
                }
            }

            Repeater {
                model: mainWindow.aurUpdates
                delegate: UpdateRow {
                    pkg: modelData
                }
            }
        }

        // Empty state
        Text {
            visible: !Updates.checking && Updates.updateData.length === 0 && Updates.lastCheck.getTime() > 0
            text: "Up to date"
            color: Config.Style.colors.positive
            font {
                pixelSize: Config.Style.fontSize.normal
                family: Config.Style.fontFamily.sans
            }
        }

        // Footer: last checked + refresh button
        Item {
            Layout.topMargin: mainWindow.repoUpdates.length > 0 || mainWindow.aurUpdates.length > 0 ? 10 : 0
            Layout.preferredHeight: refreshButton.implicitHeight
            Layout.fillWidth: true
            Layout.minimumWidth: lastCheckedLabel.implicitWidth + refreshButton.implicitWidth + 16

            Text {
                id: lastCheckedLabel
                anchors.verticalCenter: parent.verticalCenter
                color: Config.Style.colors.fg
                opacity: 0.5
                font {
                    family: Config.Style.fontFamily.sans
                    pixelSize: Config.Style.fontSize.small
                }
                text: Updates.checking
                    ? "Checking…"
                    : "Next check at " + Qt.formatDateTime(Updates.nextCheck, "h:mm ap")
            }

            WrapperMouseArea {
                id: refreshButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                enabled: !Updates.checking
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                Text {
                    id: refreshIcon
                    color: Config.Style.colors.accent
                    opacity: refreshButton.enabled ? 1 : 0.4
                    font {
                        family: Config.Style.fontFamily.icon
                        pixelSize: Config.Style.fontSize.larger
                    }
                    text: "\ue627"

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Config.Style.animationDuration.fast
                        }
                    }

                    NumberAnimation on rotation {
                        id: spinAnimation
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                        running: false
                    }

                    NumberAnimation on rotation {
                        id: landAnimation
                        easing.type: Easing.OutCubic
                    }
                }

                onClicked: Updates.refresh()
            }
        }
    }

    // Reusable row for a single package entry
    component UpdateRow: Item {
        property var pkg

        readonly property var _parts: (pkg?.version ?? "").split(" → ")
        readonly property string _oldVer: _parts[0]
        readonly property bool _hasArrow: _parts.length > 1
        readonly property string _newVer: _hasArrow ? _parts[1] : ""

        Layout.preferredHeight: pkgName.implicitHeight + 6
        Layout.fillWidth: true
        Layout.minimumWidth: pkgName.implicitWidth + versionDisplay.implicitWidth + 40

        Text {
            id: pkgName
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: pkg?.name ?? ""
            color: Config.Style.colors.fg
            font {
                bold: true
                pixelSize: Config.Style.fontSize.normal
                family: Config.Style.fontFamily.sans
            }
        }

        Row {
            id: versionDisplay
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Text {
                text: _oldVer
                color: Config.Style.colors.overlay
                font {
                    pixelSize: Config.Style.fontSize.small
                    family: Config.Style.fontFamily.mono
                }
            }

            Text {
                visible: _hasArrow
                text: "→"
                color: Config.Style.colors.overlay
                font {
                    pixelSize: Config.Style.fontSize.small
                    family: Config.Style.fontFamily.mono
                }
            }

            Text {
                visible: _hasArrow
                text: _newVer
                color: Config.Style.colors.positive
                font {
                    pixelSize: Config.Style.fontSize.small
                    family: Config.Style.fontFamily.mono
                    bold: true
                }
            }
        }
    }
}
