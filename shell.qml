//@ pragma UseQApplication
import Quickshell
import QtQuick
import qs.CheckUpdates as CheckUpdates
import qs.Config as Config
import qs.MusicPlayer as MusicPlayer
import qs.services
import qs.widgets as Widgets

ShellRoot {
    TopPanel {
        id: topPanel
        margins {
            top: 10
            left: 20
            right: 20
        }

        implicitHeight: 40
        backgroundColor: Config.Style.colors.panelBg

        focusable: true

        left: [
            CheckUpdates.Indicator {
                id: updatesIndicator
                focus: true
                onClicked: () => {
                    if (Updates.updateData.length > 0 || Updates.lastCheck.getTime() > 0) {
                        archUpdates.open = !archUpdates.open;
                    } else {
                        Updates.refresh();
                    }
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape && archUpdates.open) {
                        archUpdates.open = false;
                    }
                }

                CheckUpdates.UpdateWindow {
                    id: archUpdates
                    anchor.window: topPanel
                    anchor.rect.y: topPanel.implicitHeight
                    anchor.rect.x: Config.Style.radius.normal
                }
            },
            Widgets.WorkspaceIndicators {},
            MusicPlayer.Indicator {
                id: musicIndicator
                onClicked: musicPlayer.open = !musicPlayer.open
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape && musicPlayer.open)
                        musicPlayer.open = false;
                }

                MusicPlayer.PlayerWindow {
                    id: musicPlayer
                    anchor.window: topPanel
                    anchor.rect.y: topPanel.implicitHeight
                    anchor.rect.x: musicIndicator.x + musicIndicator.parent.x
                }
            }
        ]

        right: [
            Widgets.Volume {},
            Widgets.SystemTray {},
            Widgets.Weather {},
            Widgets.ThemePicker {},
            Widgets.Clock {},
            Widgets.Logout {}
        ]
    }
}
