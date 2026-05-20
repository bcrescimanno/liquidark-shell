pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root

    // Bind to the physical battery device, not UPower's synthetic DisplayDevice:
    // the DisplayDevice doesn't emit PropertiesChanged, so Quickshell wouldn't see
    // plug/unplug promptly. The real device pushes events, so updates are immediate.
    readonly property var dev: {
        let list = UPower.devices ? UPower.devices.values : [];
        return list.find(d => d.isLaptopBattery) ?? null;
    }

    readonly property bool hasBattery: !!dev && dev.ready
    readonly property int percent: dev ? Math.round(dev.percentage * 100) : 0
    readonly property string state: _stateString(dev ? dev.state : UPowerDeviceState.Unknown)
    readonly property int timeToEmptyMinutes: dev ? Math.round(dev.timeToEmpty / 60) : 0
    readonly property int timeToFullMinutes: dev ? Math.round(dev.timeToFull / 60) : 0

    // charge-end-threshold isn't exposed by the UPower service; read from sysfs.
    // Changes only when the user alters their charge policy, so we read at startup
    // and whenever the charge state changes rather than on a timer.
    property int chargeLimit: 100

    function _stateString(s): string {
        switch (s) {
        case UPowerDeviceState.Charging: return "charging";
        case UPowerDeviceState.Discharging: return "discharging";
        case UPowerDeviceState.FullyCharged: return "fully-charged";
        case UPowerDeviceState.PendingCharge: return "pending-charge";
        case UPowerDeviceState.PendingDischarge: return "pending-discharge";
        case UPowerDeviceState.Empty: return "empty";
        default: return "unknown";
        }
    }

    Component.onCompleted: limitProcess.running = true
    onStateChanged: limitProcess.running = true

    Process {
        id: limitProcess
        command: ['sh', '-c', 'cat /sys/class/power_supply/*/charge_control_end_threshold 2>/dev/null | head -1']
        running: false
        stdout: StdioCollector { id: limitOut }
        onExited: code => {
            let v = parseInt(limitOut.text.trim());
            root.chargeLimit = (code === 0 && v > 0 && v <= 100) ? v : 100;
        }
    }
}
