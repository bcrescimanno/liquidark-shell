import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Config as Config
import qs.services
import qs.Modules as Modules

WrapperMouseArea {
    id: wifiWidget

    hoverEnabled: true
    implicitWidth: wifiIcon.implicitWidth
    implicitHeight: wifiIcon.implicitHeight

    Text {
        id: wifiIcon
        anchors.verticalCenter: parent.verticalCenter
        font.family: Config.Style.fontFamily.icon
        font.pixelSize: Config.Style.fontSize.larger
        color: Network.connected ? Config.Style.colors.fg : Config.Style.colors.overlay
        text: wifiWidget._icon()
    }

    Modules.Tooltip {
        id: wifiTip
        anchorTo: wifiWidget
        Text {
            text: wifiWidget._tooltip()
            color: Config.Style.colors.fg
            font.family: Config.Style.fontFamily.mono
        }
    }

    onEntered: wifiTip.open = true
    onExited: wifiTip.open = false

    // Material Symbols wifi signal ramp; signal_wifi_off when nothing is connected.
    function _icon(): string {
        if (!Network.connected)
            return String.fromCharCode(0xE1DA);     // signal_wifi_off
        let s = Network.strength;
        if (s >= 80) return String.fromCharCode(0xE1D8); // signal_wifi_4_bar
        if (s >= 60) return String.fromCharCode(0xEBE1); // network_wifi_3_bar
        if (s >= 40) return String.fromCharCode(0xEBD6); // network_wifi_2_bar
        if (s >= 20) return String.fromCharCode(0xEBE4); // network_wifi_1_bar
        return String.fromCharCode(0xF0B0);         // signal_wifi_0_bar
    }

    function _tooltip(): string {
        if (!Network.connected)
            return "No connection";
        return "SSID: " + (Network.ssid || "Unknown network")
            + "\nIP:   " + (Network.ipAddress || "—");
    }
}
