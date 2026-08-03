# HEOS Menu Bar

A fast, native macOS menu bar controller for Denon HEOS players. Version 0.1 focuses on the controls you use most: discover players, change volume, mute, and stay connected.

## Features

- Native SwiftUI `MenuBarExtra`
- HEOS CLI connection over TCP (port 1255)
- Bonjour device discovery plus manual host configuration
- Player discovery through the HEOS protocol
- Per-player volume and mute controls
- Live volume/mute/player-change events
- Automatic reconnect with exponential backoff
- Persistent connection settings

## Requirements

- macOS 13 Ventura or newer
- Swift 6 toolchain or Xcode 16+
- A Mac and HEOS device on the same local network

## Run

Clone the repository and open `Package.swift` in Xcode. Select the **HEOSMenuBar** scheme and press Run.

You can also build and test from Terminal:

```sh
swift build
swift test
swift run HEOSMenuBar
```

The first launch may trigger macOS's Local Network permission prompt. If automatic discovery does not find a device, open **Settings…** and enter the IP address of any HEOS player or receiver. One connection can enumerate all players in the HEOS system.

## Project structure

```text
Sources/HEOSMenuBar/
├── App/          App entry point and menu bar scene
├── Models/       Player and device models
├── Networking/   TCP transport and line buffering
├── Protocol/     HEOS commands and JSON responses
├── Services/     Bonjour discovery
├── Store/        Application state and reconnect logic
└── Views/        SwiftUI menu and settings views
```

## HEOS protocol

HEOS devices expose a JSON command-line interface on TCP port 1255. Commands are UTF-8 lines terminated by CRLF. This app registers for change events after connecting and refreshes its local state when players are added or removed.

## Roadmap

- Playback and transport controls
- Now-playing metadata and artwork
- Group management
- Favorites and source selection
- Global keyboard shortcuts
- Signed, notarized app releases

## Contributing

Issues and pull requests are welcome. Please run `swift test` before submitting changes.

## License

See [LICENSE](LICENSE).
