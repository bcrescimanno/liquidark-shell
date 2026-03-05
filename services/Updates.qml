pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var updateData: []
    property date lastCheck
    property bool checking: false

    // Run on startup and repeat hourly.
    Timer {
        interval: 3600 * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    function refresh() {
        if (checking) return;
        checking = true;
        pending.repoData = undefined;
        pending.aurData = undefined;
        repoProcess.running = true;
        aurProcess.running = true;
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
