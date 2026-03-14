# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A custom desktop top panel/shell for Linux (Wayland + Hyprland), written in QML and powered by the [Quickshell](https://quickshell.outfoxxed.me/) framework. It displays workspaces, system tray, volume, weather, clock, package updates, a music player, and a logout button.

## Running

```sh
quickshell -p /home/brian/code/liquidark-shell
```

Quickshell interprets QML directly — there is no compile step. The entry point is `shell.qml`.

## Architecture

```
shell.qml              ← ShellRoot; instantiates TopPanel + all singletons
TopPanel.qml           ← PanelWindow anchored top-left-right; 3-pane layout
Config/Style.qml       ← Singleton design system (colors, fonts, radii, animation durations)
services/              ← Singleton wrappers around system services
  Audio.qml            ←   Pipewire audio via Quickshell.Services.Pipewire
  Time.qml             ←   SystemClock via Quickshell.Services
  Updates.qml          ←   Runs `checkupdates`; exposes package list + count
  Music.qml            ←   MPRIS player via Quickshell.Services.Mpris; position polling,
                            duration from mpris:length metadata, CAVA spectrum data
widgets/               ← Self-contained UI components (each reads from services/)
Modules/               ← Reusable primitives (AnimatedPopupWindow, Tooltip)
CheckUpdates/          ← Feature-specific components (Indicator badge + UpdateWindow popup)
MusicPlayer/           ← Feature-specific components for music player
  Indicator.qml        ←   Topbar widget: 5-bar CAVA spectrum + artist/title text
  PlayerWindow.qml     ←   Popup: album art, metadata, scrubber, transport controls
```

### Key conventions

- **Singletons** (`pragma Singleton`): `Config/Style.qml` and all `services/*.qml`. Import them with `import "../Config"` / `import "../services"` and access as `Style.*` / `Audio.*`, etc.
- **Widgets** are leaf components that read reactive service properties and call service methods. They do not hold significant state themselves.
- **`AnimatedPopupWindow`** (`Modules/`) is the standard base for any popup. It handles fade + scale animation.
- **Hyprland integration** uses `Quickshell.Hyprland` (workspace switching in `WorkspaceIndicators.qml`).
- **External processes** are run via `Quickshell.Io.Process` (see `services/Updates.qml`, `widgets/Weather.qml`).

### System dependencies

| Dependency | Purpose |
|---|---|
| `checkupdates` | Arch Linux pending update list |
| `yay` | AUR update list |
| `wleave` | Session-exit UI launched by Logout widget |
| `uwsm app` | Systemd user-session app launcher |
| `~/dotfiles/.config/bin/weather.sh` | Weather data provider |
| Pipewire | Audio control |
| Hyprland | Window manager (workspace data) |
| `cava` | Spectrum analyzer in Music Player indicator (optional; `sudo pacman -S cava`) |
| `ffprobe` | Audio bitrate detection for lossy files in Music Player (optional) |
