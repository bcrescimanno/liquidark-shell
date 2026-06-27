pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property bool connected: _state === "connected"
    property string ssid: ""
    property int strength: 0          // 0–100, NetworkManager's SIGNAL
    property string ipAddress: ""

    property string _state: ""

    function refresh() {
        if (!poll.running) poll.running = true;
    }

    // Periodic refresh keeps the signal-strength reading current.
    Timer {
        interval: 10000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // Quickshell ships no NetworkManager service, so `nmcli monitor` is our push
    // channel: it emits a line on every connectivity change. A connect/disconnect
    // produces a burst of lines, so debounce before re-polling to read the
    // settled state once rather than mid-transition.
    Process {
        id: monitor
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: debounce.restart()
        }
    }

    Timer {
        id: debounce
        interval: 500
        repeat: false
        onTriggered: root.refresh()
    }

    Process {
        id: poll
        running: false
        // Emits one line per field: state, ssid, signal, ip. Only double quotes
        // and bracket-escapes inside so the whole script can be single-quoted here.
        command: ["sh", "-c", 'dev=$(nmcli -t -f DEVICE,TYPE,STATE dev | grep ":wifi:connected" | cut -d: -f1 | head -1); if [ -z "$dev" ]; then echo disconnected; exit 0; fi; echo connected; nmcli -g GENERAL.CONNECTION dev show "$dev"; sig=$(nmcli -t -f IN-USE,SIGNAL dev wifi list ifname "$dev" | grep "^[*]:" | cut -d: -f2 | head -1); echo "$sig"; ip=$(nmcli -g IP4.ADDRESS dev show "$dev" | cut -d/ -f1 | head -1); echo "$ip"']
        stdout: StdioCollector { id: out }
        onExited: {
            let lines = out.text.split("\n");
            root._state = (lines[0] || "").trim();
            root.ssid = (lines[1] || "").trim();
            root.strength = parseInt(lines[2]) || 0;
            root.ipAddress = (lines[3] || "").trim();
        }
    }
}
