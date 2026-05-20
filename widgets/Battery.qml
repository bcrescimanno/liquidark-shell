import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Config as Config
import qs.services
import qs.Modules as Modules

WrapperMouseArea {
    id: batteryWidget

    visible: Battery.hasBattery
    hoverEnabled: true
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: 4

        Text {
            id: batteryIcon
            anchors.verticalCenter: parent.verticalCenter
            font.family: Config.Style.fontFamily.icon
            font.pixelSize: Config.Style.fontSize.larger
            color: batteryWidget._color()
            text: batteryWidget._icon()
        }

        Text {
            id: batteryText
            anchors.verticalCenter: parent.verticalCenter
            font.family: Config.Style.fontFamily.mono
            font.pixelSize: Config.Style.fontSize.normal
            color: batteryWidget._color()
            text: Battery.percent + "%"
        }
    }

    Modules.Tooltip {
        id: batteryTip
        anchorTo: batteryWidget
        Text {
            text: batteryWidget._tooltip()
            color: Config.Style.colors.fg
            font.family: Config.Style.fontFamily.mono
        }
    }

    onEntered: batteryTip.open = true
    onExited: batteryTip.open = false

    function _isCharging(): bool {
        return Battery.state === "charging" || Battery.state === "pending-charge";
    }

    function _isFull(): bool {
        return Battery.state === "fully-charged" || Battery.state === "not-charging"
            || (Battery.state !== "discharging" && Battery.percent >= Battery.chargeLimit);
    }

    function _color(): color {
        if (_isCharging() || _isFull())
            return Config.Style.colors.fg;
        if (Battery.percent >= 50)
            return Config.Style.colors.positive;
        if (Battery.percent >= 20)
            return Config.Style.colors.warning;
        return Config.Style.colors.negative;
    }

    // Material Symbols battery glyphs.
    // Discharging: battery_0_bar .. battery_6_bar (7 fill levels, non-sequential codepoints).
    // Charging:    battery_charging_{20,30,50,60,80,90} + battery_charging_full.
    function _icon(): string {
        if (_isCharging()) {
            // Available charging levels; pick the one nearest the current percent.
            let levels = [[20, 0xF0A2], [30, 0xF0A3], [50, 0xF0A4],
                          [60, 0xF0A5], [80, 0xF0A6], [90, 0xF0A7], [100, 0xE1A3]];
            let best = levels[0];
            for (let lv of levels)
                if (Math.abs(lv[0] - Battery.percent) < Math.abs(best[0] - Battery.percent))
                    best = lv;
            return String.fromCharCode(best[1]);
        }
        // Discharging or full/at-limit: bar icon with no charging bolt.
        let bars = [0xEBDC, 0xEBD9, 0xEBE0, 0xEBDD, 0xEBE2, 0xEBD4, 0xEBD2];
        let idx = Math.min(6, Math.max(0, Math.round(Battery.percent / 100 * 6)));
        return String.fromCharCode(bars[idx]);
    }

    function _tooltip(): string {
        if (_isFull()) {
            return Battery.chargeLimit < 100
                ? "Charged to " + Battery.chargeLimit + "%"
                : "Fully charged";
        }
        if (_isCharging()) {
            let t = Battery.timeToFullMinutes;
            if (t <= 0) return "Charging…";
            let label = Battery.chargeLimit < 100
                ? "until " + Battery.chargeLimit + "%"
                : "until full";
            return _formatTime(t) + " " + label;
        }
        let t = Battery.timeToEmptyMinutes;
        if (t <= 0) return Battery.percent + "% remaining";
        return _formatTime(t) + " remaining";
    }

    function _formatTime(minutes: int): string {
        let h = Math.floor(minutes / 60);
        let m = minutes % 60;
        if (h === 0) return m + "m";
        if (m === 0) return h + "h";
        return h + "h " + m + "m";
    }
}
