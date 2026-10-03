import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    spacing: 20

    Repeater {
        model: SystemTray.items

        WrapperMouseArea {
            id: trayItem
            required property SystemTrayItem modelData

            acceptedButtons: Qt.AllButtons
            IconImage {
                implicitHeight: 16
                implicitWidth: 16
                anchors.fill: parent
                source: trayItem.modelData.icon
            }

            // Anchor the menu to the icon itself rather than a hardcoded offset
            // into a named panel window, so it works on any output/panel instance.
            QsMenuAnchor {
                id: menuAnchor
                menu: trayItem.modelData.menu
                anchor.item: trayItem
                anchor.edges: Edges.Bottom
                anchor.gravity: Edges.Bottom
            }

            onClicked: event => {
                const item = trayItem.modelData;
                if (event.button === Qt.LeftButton && !item.onlyMenu) {
                    item.activate();
                } else if (event.button === Qt.MiddleButton) {
                    item.secondaryActivate();
                } else if (item.hasMenu) {
                    menuAnchor.open();
                }
            }
        }
    }
}
