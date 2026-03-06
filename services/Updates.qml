pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var updateData: []
    property date lastCheck
    property date nextCheck: new Date()
    property bool checking: false

    Component.onCompleted: {
        nextCheck = new Date(Date.now() + checkTimer.interval);
        refresh();
    }

    function refresh() {
        if (checking) return;
        wakeTimer.stop();
        checkTimer.restart();
        nextCheck = new Date(Date.now() + checkTimer.interval);
        checking = true;
        pending.repoData = undefined;
        pending.aurData = undefined;
        repoProcess.running = true;
        aurProcess.running = true;
    }

    // Hourly check timer. No triggeredOnStart — initial check is in Component.onCompleted
    // so that restart() here (e.g. after wake) doesn't fire immediately.
    Timer {
        id: checkTimer
        interval: 3600 * 1000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    // Fired 30 s after a resume-from-sleep event is detected.
    Timer {
        id: wakeTimer
        interval: 30000
        repeat: false
        running: false
        onTriggered: root.refresh()
    }

    // Heartbeat: fires every 10 s and compares actual elapsed time to the expected
    // interval. If the skew exceeds 15 s the system almost certainly resumed from
    // sleep. When that happens, if the next scheduled check is still more than 30 s
    // away we cap the wait to 30 s via wakeTimer.
    Timer {
        id: heartbeat
        interval: 10000
        repeat: true
        running: true

        property real lastBeat: Date.now()

        onTriggered: {
            let now = Date.now();
            let skew = now - lastBeat - interval;
            lastBeat = now;

            if (skew > 15000 && !wakeTimer.running) {
                let timeUntilNext = root.nextCheck.getTime() - now;
                if (timeUntilNext > 30000) {
                    checkTimer.stop();
                    root.nextCheck = new Date(now + 30000);
                    wakeTimer.restart();
                }
            }
        }
    }

    // Collects partial results and finalizes once both processes complete.
    QtObject {
        id: pending
        property var repoData
        property var aurData

        function tryFinalize() {
            if (repoData !== undefined && aurData !== undefined) {
                root.updateData = repoData.concat(aurData);
                root.lastCheck = new Date();
                root.checking = false;
                repoData = undefined;
                aurData = undefined;
            }
        }
    }

    Process {
        id: repoProcess
        command: ['checkupdates', '--nocolor']
        running: false

        // exit 0 = updates available, 1 = up to date, 2+ = error
        onExited: exitCode => {
            if (exitCode === 0 || exitCode === 1) {
                pending.repoData = parseUpdates(repoStdout.text, "repo");
            } else {
                console.error("checkupdates exited with code:", exitCode);
                pending.repoData = [];
            }
            pending.tryFinalize();
        }

        stdout: StdioCollector { id: repoStdout }
    }

    Process {
        id: aurProcess
        command: ['yay', '-Qu', '--aur']
        running: false

        // exit 0 = updates available, 1 = up to date, 2+ = error
        onExited: exitCode => {
            if (exitCode === 0 || exitCode === 1) {
                pending.aurData = parseUpdates(aurStdout.text, "aur");
            } else {
                console.error("yay --aur exited with code:", exitCode);
                pending.aurData = [];
            }
            pending.tryFinalize();
        }

        stdout: StdioCollector { id: aurStdout }
    }

    function parseUpdates(text, source) {
        if (!text.trim()) return [];
        return text.trim().split("\n").map(line => {
            line = line.replace(/->/g, "→");
            let idx = line.indexOf(" ");
            if (idx === -1) return null;
            return { name: line.slice(0, idx), version: line.slice(idx + 1), source };
        }).filter(Boolean);
    }
}
