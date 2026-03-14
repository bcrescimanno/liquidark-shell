# liquidark-shell

A custom desktop top panel for Linux (Wayland + Hyprland), written in QML and powered by the [Quickshell](https://quickshell.outfoxxed.me/) framework.

Features: workspaces, system tray, volume control, weather, clock, package updates, music player with spectrum analyzer, and a logout button.

## Running

```sh
quickshell -p /home/brian/code/liquidark-shell
```

Quickshell interprets QML directly — there is no compile step.

## Dependencies

### Required

| Package | Purpose |
|---|---|
| `quickshell` | QML shell framework |
| `pipewire` | Audio control (Volume widget) |
| `hyprland` | Window manager (workspace data) |
| `wleave` | Session-exit UI (Logout widget) |
| `uwsm` | Systemd user-session app launcher (Logout widget) |
| `checkupdates` | Arch Linux pending update list (Updates widget) |
| `yay` | AUR update list (Updates widget) |

### Optional

| Package | Purpose |
|---|---|
| `cava` | Real-time spectrum analyzer in Music Player indicator (`sudo pacman -S cava`) |
| `ffprobe` (ffmpeg) | Audio bitrate detection for lossy formats in Music Player |

### Runtime

| Item | Purpose |
|---|---|
| `~/dotfiles/.config/bin/weather.sh` | Weather data provider |
| An MPRIS-compatible media player | Music Player widget (Firefox, mpv, Spotify, etc.) |
