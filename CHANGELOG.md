# Changelog

All notable changes to HEOS Menu Bar will be documented in this file.

## [Unreleased]

### Fixed

- Open Settings with `SettingsLink` on modern macOS versions.
- Allow entering a HEOS IP address directly from the disconnected menu.
- Stop stalled TCP connection attempts after eight seconds with an actionable error.
- Resolve the Bonjour host but connect to the HEOS CLI on port 1255 instead of the advertised communications port.
- Clear invalid Bonjour service names saved as hostnames by version 0.1.0.
- Prefer the resolved HEOS IPv4 address to avoid `.local` connections choosing an unreachable interface.

### Changed

- Migrated the runnable app from a package executable to a native macOS Xcode application project.
- Added a bundle identifier, app `Info.plist`, Bonjour declaration, Local Network description, and sandbox network entitlement.
- Added a custom waveform template icon for the menu bar and a blue waveform application icon.
- Increased the visible size of the menu bar waveform.
- Added persistent per-player control toggles that prevent accidental volume and mute changes.
- Replaced an unavailable empty-state SF Symbol.
- Replaced the menu bar waveform with the clearer supplied variant.
- Switched the application icon to the supplied `AppIcon.icns` resource.
- Fixed the transparent menu bar icon and keep the Settings window above normal windows.
- Added persistent drag-and-drop ordering for players in the menu bar.
- Replaced system drag-and-drop with a direct drag gesture that works inside `MenuBarExtra`.
- Added minus and plus buttons for precise 1% per-click volume adjustments.

## [0.1.0] - 2026-08-03

### Added

- Native macOS menu bar interface and settings window.
- HEOS TCP client with streaming JSON response parsing.
- Automatic Bonjour discovery and manual host configuration.
- Player discovery, volume control, and mute control.
- Live HEOS change events and automatic reconnect.
- Swift Package structure, protocol tests, and project documentation.
