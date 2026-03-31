pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property MprisPlayer player: {
        let players = Mpris.players.values;
        if (players.length === 0) return null;
        return players.find(p => p.isPlaying) ?? players[0];
    }
    readonly property bool hasPlayer: player !== null
    readonly property bool isPlaying: player?.isPlaying ?? false

    readonly property string trackTitle: player?.trackTitle ?? ""
    readonly property string trackArtist: player?.trackArtist ?? ""
    readonly property string trackAlbum: player?.trackAlbum ?? ""
    readonly property string trackArtUrl: player?.trackArtUrl ?? ""
    readonly property string trackYear: {
        let created = player?.metadata["xesam:contentCreated"] ?? "";
        return created.length >= 4 ? created.substring(0, 4) : "";
    }

    property real position: 0
    property real duration: 0

    readonly property bool canNext: player?.canGoNext ?? false
    readonly property bool canPrevious: player?.canGoPrevious ?? false
    readonly property bool canSeek: player?.canSeek ?? false
    readonly property bool canPlay: player?.canPlay ?? false
    readonly property bool canPause: player?.canPause ?? false

    property string formatLabel: ""
    property var spectrumBars: [0, 0, 0, 0, 0]

    // CAVA process for real audio frequency data.
    // Runs only while playing; bars reset to zero on exit.
    Process {
        id: cavaProcess
        running: root.isPlaying
        command: [
            "bash", "-c",
            "printf '[general]\\nbars = 5\\nframerate = 60\\n\\n[output]\\nmethod = raw\\nraw_target = /dev/stdout\\ndata_format = ascii\\nascii_max_range = 100\\nchannels = mono\\n\\n[input]\\nmethod = pipewire\\nsource = auto\\n' > /tmp/liquidark-cava.conf && exec cava -p /tmp/liquidark-cava.conf"
        ]

        onExited: root.spectrumBars = [0, 0, 0, 0, 0]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                let vals = data.trim().split(";");
                if (vals.length < 5) return;
                let bars = [];
                for (let i = 0; i < 5; i++) {
                    let v = parseInt(vals[i]);
                    bars.push(isNaN(v) ? 0 : Math.min(1.0, v / 100.0));
                }
                root.spectrumBars = bars;
            }
        }
    }

    function togglePlaying() {
        if (player)
            player.togglePlaying();
    }

    function next() {
        if (player)
            player.next();
    }

    function previous() {
        if (player)
            player.previous();
    }

    function seekTo(seconds) {
        if (player && canSeek)
            player.position = seconds;
    }

    // Position is not reactive in Quickshell MPRIS by design — poll it.
    Timer {
        id: positionTimer
        interval: 1000
        repeat: true
        running: root.isPlaying
        triggeredOnStart: true
        onTriggered: {
            if (!root.player) return;
            root.player.positionChanged();
            root.position = root.player.position;
        }
    }

    // Format detection on track change
    property string _lastTrackUrl: ""

    onTrackTitleChanged: {
        position = 0;
        duration = 0;
        _detectFormat();
    }
    onPlayerChanged: {
        position = 0;
        duration = 0;
        _detectFormat();
    }

    Connections {
        target: root.player
        enabled: root.player !== null
        function onMetadataChanged() {
            let us = root.player.metadata["mpris:length"] ?? 0;
            if (us > 0) {
                root.duration = us / 1000000.0;
            } else if (root.player.lengthSupported) {
                root.duration = root.player.length;
            }
        }
    }

    readonly property list<string> _losslessExtensions: ["flac", "wav", "alac", "ape", "aiff", "aif", "wv", "dsf", "dff"]

    function _detectFormat() {
        let url = player?.metadata["xesam:url"] ?? "";
        if (url === _lastTrackUrl)
            return;
        _lastTrackUrl = url;
        formatLabel = "";

        if (!url)
            return;

        if (url.startsWith("file://")) {
            let path = decodeURIComponent(url.substring(7));
            let dotIdx = path.lastIndexOf(".");
            if (dotIdx !== -1) {
                let ext = path.substring(dotIdx + 1).toLowerCase();
                if (_losslessExtensions.indexOf(ext) !== -1) {
                    formatLabel = "Lossless";
                    return;
                }
            }
            // Run ffprobe for lossy files
            ffprobeProcess.command = ["ffprobe", "-v", "quiet", "-show_entries", "format=bit_rate", "-of", "default=noprint_wrappers=1:nokey=1", path];
            ffprobeProcess.running = true;
        }
    // HTTP URLs or missing → leave empty
    }

    Process {
        id: ffprobeProcess
        running: false

        onExited: exitCode => {
            if (exitCode === 0) {
                let bitrate = parseInt(ffprobeStdout.text.trim());
                if (!isNaN(bitrate) && bitrate > 0) {
                    root.formatLabel = Math.round(bitrate / 1000) + " kbps";
                }
            }
        }

        stdout: StdioCollector {
            id: ffprobeStdout
        }
    }
}
