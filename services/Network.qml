pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

Singleton {
    id: root

    readonly property bool connected: !!_activeNet
    readonly property string ssid: _activeNet ? _activeNet.name : ""
    readonly property int strength: _activeNet ? Math.round(_activeNet.signalStrength * 100) : 0
    property string ipAddress: ""

    // First wifi device, and its currently-connected network (if any). Both are
    // reactive: Quickshell.Networking emits change signals as devices/networks
    // connect and signal strength updates, so the properties above track live.
    readonly property var _wifiDev: {
        let list = Networking.devices ? Networking.devices.values : [];
        return list.find(d => d.type === DeviceType.Wifi) ?? null;
    }
    readonly property var _activeNet: {
        if (!_wifiDev) return null;
        let nets = _wifiDev.networks ? _wifiDev.networks.values : [];
        return nets.find(n => n.connected) ?? null;
    }

    // Quickshell.Networking doesn't expose IP addresses, so read the active
    // interface's IPv4 with `ip`. Refresh on connect/network change and on a slow
    // timer (DHCP may not have assigned an address the instant we connect).
    onConnectedChanged: _refreshIp()
    onSsidChanged: _refreshIp()
    Component.onCompleted: _refreshIp()

    Timer {
        interval: 15000
        repeat: true
        running: root.connected
        onTriggered: root._refreshIp()
    }

    function _refreshIp() {
        if (!connected || !_wifiDev) {
            ipAddress = "";
            return;
        }
        ipProc.iface = _wifiDev.name;
        ipProc.running = true;
    }

    Process {
        id: ipProc
        property string iface: ""
        running: false
        command: ["ip", "-4", "-o", "addr", "show", "dev", iface]
        stdout: StdioCollector { id: ipOut }
        onExited: {
            let m = ipOut.text.match(/inet (\d+\.\d+\.\d+\.\d+)/);
            root.ipAddress = m ? m[1] : "";
        }
    }
}
