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
    property int retryCount: 0
    readonly property int maxRetries: 5

    Component.onCompleted: {
        nextCheck = new Date(Date.now() + checkTimer.interval);
        refresh();
    }

    // Public entry point: resets retry state and restarts the hourly timer.
    function refresh() {
        if (checking) return;
        retryCount = 0;
        wakeTimer.stop();
        retryTimer.stop();
        checkTimer.restart();
        nextCheck = new Date(Date.now() + checkTimer.interval);
        _startCheck();
    }

    // Internal: launches both check processes. Used by refresh() and retries.
    function _startCheck() {
        if (checking) return;
        checking = true;
        pending.repoData = undefined;
        pending.aurData = undefined;
        pending.hasError = false;
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

    // Retry timer for failed checks (exponential backoff).
    Timer {
        id: retryTimer
        repeat: false
        running: false
        onTriggered: root._startCheck()
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
                console.log("Updates: resume detected (skew " + (skew / 1000).toFixed(0) + " s), next check in " + (timeUntilNext / 1000).toFixed(0) + " s");
                if (timeUntilNext <= 0) {
                    // Next check is overdue (nextCheck is in the past) — refresh immediately.
                    root.refresh();
                } else if (timeUntilNext > 30000) {
                    // Don't stop checkTimer — if refresh() is blocked (checking=true), checkTimer
                    // must keep running or no future checks will ever fire.
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
        property bool hasError: false

        function tryFinalize() {
            if (repoData === undefined || aurData === undefined) return;

            if (hasError) {
                root.checking = false;
                if (root.retryCount < root.maxRetries) {
                    root.retryCount++;
                    // Exponential backoff: 15 s, 30 s, 60 s, 120 s, 240 s
                    let delay = Math.min(15000 * Math.pow(2, root.retryCount - 1), 300000);
                    console.warn("Updates: check failed, retrying in " + (delay / 1000).toFixed(0) + " s (attempt " + root.retryCount + "/" + root.maxRetries + ")");
                    retryTimer.interval = delay;
                    retryTimer.start();
                } else {
                    console.error("Updates: check failed after " + root.maxRetries + " retries, keeping previous data");
                }
                // Don't overwrite updateData — preserve the last known good data.
            } else {
                root.updateData = repoData.concat(aurData);
                root.lastCheck = new Date();
                root.checking = false;
                console.log("Updates: check complete — " + root.updateData.length + " update(s) available");
            }

            repoData = undefined;
            aurData = undefined;
        }
    }

    Process {
        id: repoProcess
        command: ['checkupdates', '--nocolor']
        running: false

        // exit 0 = updates available, 1 = error (network etc.), 2 = no updates
        onExited: exitCode => {
            if (exitCode === 0) {
                pending.repoData = parseUpdates(repoStdout.text, "repo");
            } else if (exitCode === 2) {
                pending.repoData = [];
            } else {
                console.error("checkupdates exited with code:", exitCode);
                pending.hasError = true;
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

        // exit 0 = updates available; non-zero = no updates OR error.
        // Distinguish via stderr: yay writes to stderr on error, not on clean "no updates".
        onExited: exitCode => {
            if (exitCode === 0) {
                pending.aurData = parseUpdates(aurStdout.text, "aur");
            } else if (aurStderr.text.trim()) {
                console.error("yay --aur exited with code " + exitCode + ": " + aurStderr.text.trim());
                pending.hasError = true;
                pending.aurData = [];
            } else {
                pending.aurData = [];
            }
            pending.tryFinalize();
        }

        stdout: StdioCollector { id: aurStdout }
        stderr: StdioCollector { id: aurStderr }
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
